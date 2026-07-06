#!/usr/bin/env bash
# deploy-portal.sh — Deploy APIM developer portal customizations from source-controlled artifacts.
#
# DESCRIPTION
#   Imports developer portal content from portal/artifacts into a target Azure API
#   Management instance, then optionally publishes the portal.
#
#   Designed for non-interactive execution inside Azure DevOps pipelines via the
#   AzureCLI@2 task (which handles authentication automatically). Can also be run
#   locally after 'az login'.
#
# USAGE
#   ./deploy-portal.sh -e <env> -g <resource-group> -n <apim-name> [-s <subscription-id>]
#                      [-a <artifacts-path>] [-c <config-path>] [-p]
#
# OPTIONS
#   -e  Environment name (e.g. sbox, dev, test, stg, prod)
#   -g  Resource group name containing the target APIM instance
#   -n  APIM service name (e.g. sps-api-mgmt-sbox)
#   -s  Azure subscription ID (defaults to current az account)
#   -a  Artifacts directory path (default: ../artifacts relative to this script)
#   -c  Config directory path (default: ../config relative to this script)
#   -p  Publish the portal after importing content
#   -h  Show this help message
#
# PREREQUISITES
#   - Azure CLI 2.30 or later: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
#   - jq: https://stedolan.github.io/jq/ (brew install jq / apt install jq)
#   - Authenticated: az login (or service principal via env vars / AzureCLI@2 task)
#   - API Management Service Contributor role on the APIM instance
#   - Storage Blob Data Contributor on the APIM-associated storage account (for media)
#
# EXAMPLE (local)
#   az login
#   ./deploy-portal.sh \
#     -e sbox \
#     -s "bd2864ed-4f3e-45ed-9c6a-8d179674bab1" \
#     -g "rg-sps-platform-sbox" \
#     -n "sps-api-mgmt-sbox" \
#     -p
#
# ROLLBACK
#   To revert: check out a previous portal/artifacts commit and push to trigger the pipeline,
#   or re-run this script pointing at a previous artifact revision.
#   Portal revisions are also visible in the Azure portal under:
#   APIs → Developer portal → Portal revisions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Argument parsing ────────────────────────────────────────────────────────────
usage() {
  grep '^#' "$0" | grep -v '#!/' | sed 's/^# \{0,1\}//'
  exit 0
}

ENVIRONMENT=""
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
APIM_NAME=""
ARTIFACTS_PATH=""
CONFIG_PATH=""
PUBLISH=false

while getopts ":e:s:g:n:a:c:ph" opt; do
  case $opt in
    e) ENVIRONMENT="$OPTARG" ;;
    s) SUBSCRIPTION_ID="$OPTARG" ;;
    g) RESOURCE_GROUP="$OPTARG" ;;
    n) APIM_NAME="$OPTARG" ;;
    a) ARTIFACTS_PATH="$OPTARG" ;;
    c) CONFIG_PATH="$OPTARG" ;;
    p) PUBLISH=true ;;
    h) usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Validate required arguments
for var in ENVIRONMENT RESOURCE_GROUP APIM_NAME; do
  if [[ -z "${!var}" ]]; then
    echo "Error: required option missing for ${var}. Run with -h for usage." >&2
    exit 1
  fi
done

# Default paths relative to this script
PORTAL_DIR="$(dirname "$SCRIPT_DIR")"
if [[ -z "$ARTIFACTS_PATH" ]]; then ARTIFACTS_PATH="$PORTAL_DIR/artifacts"; fi
if [[ -z "$CONFIG_PATH" ]];    then CONFIG_PATH="$PORTAL_DIR/config"; fi

# Resolve subscription from current az context when not provided
if [[ -z "$SUBSCRIPTION_ID" ]]; then
  SUBSCRIPTION_ID=$(az account show --query id --output tsv 2>/dev/null || true)
  if [[ -z "$SUBSCRIPTION_ID" ]]; then
    echo "Error: could not determine current subscription. Run 'az login' or supply -s." >&2
    exit 1
  fi
fi

API_VERSION="2022-08-01"
BASE_URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}"

echo "=== APIM Developer Portal Deploy ==="
echo "Environment    : $ENVIRONMENT"
echo "Subscription   : $SUBSCRIPTION_ID"
echo "Resource Group : $RESOURCE_GROUP"
echo "APIM Name      : $APIM_NAME"
echo "Artifacts Path : $ARTIFACTS_PATH"
echo "Config Path    : $CONFIG_PATH"
echo "Publish Portal : $PUBLISH"
echo ""

# ── Validate artifacts directory ────────────────────────────────────────────────
if [[ ! -d "$ARTIFACTS_PATH" ]]; then
  echo "Error: artifacts directory not found: $ARTIFACTS_PATH" >&2
  echo "Run portal/scripts/export-portal.sh to populate it, then commit the results." >&2
  exit 1
fi

CONTENT_FILE="$ARTIFACTS_PATH/content/content.json"

# ── Load optional environment-specific substitution config ─────────────────────
env_config_file="$CONFIG_PATH/${ENVIRONMENT}.json"
substitutions_json="{}"
if [[ -f "$env_config_file" ]]; then
  echo "Loading environment config: $env_config_file"
  substitutions_json=$(jq -r '.substitutions // {}' "$env_config_file")
else
  echo "No environment config found at $env_config_file (skipping substitutions)."
fi

# ── Helper: apply string substitutions to content ──────────────────────────────
apply_substitutions() {
  local content="$1"
  # jq walk: replace each string value using the substitutions map
  echo "$content" | jq \
    --argjson subs "$substitutions_json" \
    '
      def substitute(s):
        . as $input |
        ($subs | keys_unsorted) |
        reduce .[] as $k (
          $input;
          gsub($k; $subs[$k])
        );
      walk(if type == "string" then substitute(.) else . end)
    '
}

# ── 1. Import portal content items ─────────────────────────────────────────────
if [[ -f "$CONTENT_FILE" ]]; then
  echo "Importing portal content items..."
  raw_content=$(cat "$CONTENT_FILE")

  # Apply substitutions if any are defined
  if [[ "$substitutions_json" != "{}" ]]; then
    raw_content=$(apply_substitutions "$raw_content")
  fi

  content_type_ids=$(echo "$raw_content" | jq -r 'keys[]')

  while IFS= read -r ct_id; do
    [[ -z "$ct_id" ]] && continue
    echo "  Content type: $ct_id"

    items=$(echo "$raw_content" | jq --arg ct "$ct_id" '.[$ct].items // []')
    item_count=$(echo "$items" | jq 'length')

    for i in $(seq 0 $((item_count - 1))); do
      item=$(echo "$items" | jq --argjson idx "$i" '.[$idx]')
      item_id=$(echo "$item" | jq -r '.id | split("/contentItems/") | .[1]')
      item_uri="${BASE_URL}/contentTypes/${ct_id}/contentItems/${item_id}?api-version=${API_VERSION}"
      item_body=$(echo "$item" | jq -c '.')

      az rest \
        --method PUT \
        --uri    "$item_uri" \
        --body   "$item_body" \
        --output none 2>/dev/null || echo "    Warning: failed to upsert item ${item_id} (non-fatal)"
    done
    echo "    Upserted ${item_count} item(s)."
  done <<< "$content_type_ids"

  echo "  Content import complete."
else
  echo "Warning: no content.json found at $CONTENT_FILE. Skipping content import."
fi

# ── 2. Upload media files ───────────────────────────────────────────────────────
MEDIA_DIR="$ARTIFACTS_PATH/media"
if [[ -d "$MEDIA_DIR" ]]; then
  media_count=$(find "$MEDIA_DIR" -type f | wc -l | tr -d ' ')
  if [[ "$media_count" -gt 0 ]]; then
    echo "Uploading ${media_count} media file(s)..."
    media_secrets_json=$(az rest \
      --method POST \
      --uri "${BASE_URL}/portalSettings/mediaContent/listSecrets?api-version=${API_VERSION}" \
      --output json 2>/dev/null || echo "")

    if [[ -n "$media_secrets_json" ]]; then
      sas_url=$(echo "$media_secrets_json" | jq -r '.containerSasUrl // empty')
      if [[ -n "$sas_url" ]]; then
        container_url="${sas_url%%\?*}"
        sas_token="${sas_url#*\?}"
        container_name="${container_url##*/}"
        storage_account="${container_url#*://}"
        storage_account="${storage_account%%.*}"

        if az storage blob upload-batch \
             --source        "$MEDIA_DIR" \
             --destination   "$container_name" \
             --account-name  "$storage_account" \
             --sas-token     "?${sas_token}" \
             --overwrite \
             --output none 2>/dev/null; then
          echo "  Media upload complete."
        else
          echo "  Warning: media upload encountered errors; some assets may be missing from the portal."
        fi
      else
        echo "  Warning: could not parse media SAS URL (non-fatal)."
      fi
    else
      echo "  Warning: could not retrieve media SAS URL (non-fatal)."
    fi
  else
    echo "No media files to upload."
  fi
fi

# ── 3. Publish the portal ───────────────────────────────────────────────────────
if [[ "$PUBLISH" == "true" ]]; then
  echo "Publishing developer portal..."
  revision_id="deploy-$(date -u +"%Y%m%d%H%M%S")"
  publish_body=$(jq -cn \
    --arg desc "Automated deployment from Azure DevOps - environment: ${ENVIRONMENT}" \
    '{properties: {description: $desc, isCurrent: true}}')

  if az rest \
       --method PUT \
       --uri    "${BASE_URL}/portalRevisions/${revision_id}?api-version=${API_VERSION}" \
       --body   "$publish_body" \
       --output none 2>/dev/null; then
    echo "  Portal revision '${revision_id}' created and published."
  else
    echo "  Warning: portal publish step failed. Content was imported but the portal may need to be published manually via the Azure portal."
  fi
fi

echo ""
echo "Developer portal deployment complete."
