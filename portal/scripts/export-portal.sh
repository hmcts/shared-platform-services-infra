#!/usr/bin/env bash
# export-portal.sh — Export APIM developer portal customizations to source-controlled artifacts.
#
# DESCRIPTION
#   Connects to an existing Azure API Management instance and exports all developer
#   portal content (pages, layouts, styles, templates, media) to portal/artifacts
#   for source control and subsequent promotion through environments.
#
#   Requires only the Azure CLI (az) — no additional tooling needed.
#
# USAGE
#   ./export-portal.sh -e <env> -s <subscription-id> -g <resource-group> -n <apim-name> [-o <output-path>]
#
# OPTIONS
#   -e  Environment name (e.g. sbox, dev, test, stg, prod) — used for metadata only
#   -s  Azure subscription ID containing the APIM instance
#   -g  Resource group name containing the APIM instance
#   -n  APIM service name (e.g. sps-api-mgmt-sbox)
#   -o  Output path for artifacts (default: ../artifacts relative to this script)
#   -h  Show this help message
#
# PREREQUISITES
#   - Azure CLI 2.30 or later: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
#   - Authenticated: az login (or service principal via env vars)
#   - API Management Service Contributor role on the APIM instance
#   - Storage Blob Data Reader on the APIM-associated storage account (for media export)
#
# EXAMPLE
#   az login
#   az account set --subscription "bd2864ed-4f3e-45ed-9c6a-8d179674bab1"
#
#   ./export-portal.sh \
#     -e sbox \
#     -s "bd2864ed-4f3e-45ed-9c6a-8d179674bab1" \
#     -g "rg-sps-platform-sbox" \
#     -n "sps-api-mgmt-sbox"
#
# After running, review and commit the artifacts:
#   git diff portal/artifacts
#   git add portal/artifacts
#   git commit -m "chore: update APIM developer portal artifacts"
#   git push

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
OUTPUT_PATH=""

while getopts ":e:s:g:n:o:h" opt; do
  case $opt in
    e) ENVIRONMENT="$OPTARG" ;;
    s) SUBSCRIPTION_ID="$OPTARG" ;;
    g) RESOURCE_GROUP="$OPTARG" ;;
    n) APIM_NAME="$OPTARG" ;;
    o) OUTPUT_PATH="$OPTARG" ;;
    h) usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Validate required arguments
for var in ENVIRONMENT SUBSCRIPTION_ID RESOURCE_GROUP APIM_NAME; do
  if [[ -z "${!var}" ]]; then
    echo "Error: -${var:0:1} is required. Run with -h for usage." >&2
    exit 1
  fi
done

# Default output path: ../artifacts relative to this script
if [[ -z "$OUTPUT_PATH" ]]; then
  OUTPUT_PATH="$(dirname "$SCRIPT_DIR")/artifacts"
fi

# ── Setup ───────────────────────────────────────────────────────────────────────
CONTENT_DIR="$OUTPUT_PATH/content"
MEDIA_DIR="$OUTPUT_PATH/media"
API_VERSION="2022-08-01"
BASE_URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}"

mkdir -p "$CONTENT_DIR" "$MEDIA_DIR"

echo "=== APIM Developer Portal Export ==="
echo "Environment    : $ENVIRONMENT"
echo "Subscription   : $SUBSCRIPTION_ID"
echo "Resource Group : $RESOURCE_GROUP"
echo "APIM Name      : $APIM_NAME"
echo "Output Path    : $OUTPUT_PATH"
echo ""

# ── Helper: call APIM ARM REST API ──────────────────────────────────────────────
apim_rest() {
  local method="${1:-GET}"
  local uri="$2"
  az rest --method "$method" --uri "$uri" --output json
}

# ── 1. Portal settings (sign-in, sign-up, delegation) ──────────────────────────
echo "Exporting portal settings..."
settings_file="$CONTENT_DIR/portalsettings.json"
if az rest --method GET \
     --uri "${BASE_URL}/portalsettings/signin?api-version=${API_VERSION}" \
     --output json > /tmp/apim_signin.json 2>/dev/null \
   && az rest --method GET \
     --uri "${BASE_URL}/portalsettings/signup?api-version=${API_VERSION}" \
     --output json > /tmp/apim_signup.json 2>/dev/null \
   && az rest --method GET \
     --uri "${BASE_URL}/portalsettings/delegation?api-version=${API_VERSION}" \
     --output json > /tmp/apim_delegation.json 2>/dev/null; then

  jq -n \
    --slurpfile signin     /tmp/apim_signin.json \
    --slurpfile signup     /tmp/apim_signup.json \
    --slurpfile delegation /tmp/apim_delegation.json \
    '{signin: $signin[0], signup: $signup[0], delegation: $delegation[0]}' \
    > "$settings_file"
  echo "  Portal settings exported."
else
  echo "  Warning: could not export portal settings (non-fatal)."
fi

# ── 2. Content types and their items (pages, layouts, widgets, styles, etc.) ────
echo "Exporting content types and items..."

content_types_json=$(az rest \
  --method GET \
  --uri "${BASE_URL}/contentTypes?api-version=${API_VERSION}" \
  --output json)

content_type_ids=$(echo "$content_types_json" | jq -r '.value[].id | split("/contentTypes/") | .[1]')
content_type_count=$(echo "$content_type_ids" | grep -c . || true)

# Build a combined JSON object: { "<contentTypeId>": { contentType: {...}, items: [...] }, ... }
combined_content="{}"
while IFS= read -r ct_id; do
  [[ -z "$ct_id" ]] && continue
  echo "  Content type: $ct_id"

  ct_json=$(echo "$content_types_json" | jq --arg id "$ct_id" '.value[] | select(.id | endswith("/contentTypes/" + $id))')
  items_json=$(az rest \
    --method GET \
    --uri "${BASE_URL}/contentTypes/${ct_id}/contentItems?api-version=${API_VERSION}" \
    --output json | jq '.value')

  combined_content=$(echo "$combined_content" | jq \
    --arg ctId "$ct_id" \
    --argjson ctJson "$ct_json" \
    --argjson items "$items_json" \
    '. + {($ctId): {contentType: $ctJson, items: $items}}')
done <<< "$content_type_ids"

echo "$combined_content" > "$CONTENT_DIR/content.json"
echo "  Exported ${content_type_count} content type(s)."

# ── 3. Media / blob storage assets ─────────────────────────────────────────────
echo "Exporting media files..."
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

    echo "  Downloading media from storage account: ${storage_account} / container: ${container_name}"
    if az storage blob download-batch \
         --destination "$MEDIA_DIR" \
         --source      "$container_name" \
         --account-name "$storage_account" \
         --sas-token    "?${sas_token}" \
         --output none 2>/dev/null; then
      media_count=$(find "$MEDIA_DIR" -type f | wc -l | tr -d ' ')
      echo "  Media export complete (${media_count} file(s))."
    else
      echo "  Warning: media download encountered errors; some assets may be missing."
    fi
  else
    echo "  Warning: could not parse media SAS URL (non-fatal)."
  fi
else
  echo "  Warning: could not retrieve media SAS URL (non-fatal)."
fi

# ── 4. Export metadata ──────────────────────────────────────────────────────────
jq -n \
  --arg exportedAt    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --arg environment   "$ENVIRONMENT" \
  --arg subscriptionId "$SUBSCRIPTION_ID" \
  --arg resourceGroup "$RESOURCE_GROUP" \
  --arg apimName      "$APIM_NAME" \
  '{exportedAt: $exportedAt, environment: $environment, subscriptionId: $subscriptionId, resourceGroup: $resourceGroup, apimName: $apimName}' \
  > "$OUTPUT_PATH/export-metadata.json"

echo ""
echo "Export complete. Artifacts written to: $OUTPUT_PATH"
echo "Next steps:"
echo "  git diff portal/artifacts    # review what changed"
echo "  git add portal/artifacts"
echo "  git commit -m 'chore: update APIM developer portal artifacts'"
echo "  git push                     # CI/CD will promote to other environments"
