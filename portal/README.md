# APIM Developer Portal

This directory manages developer portal customizations for the Azure API Management
instances in this repository. Portal content (pages, layouts, styles, widgets, and
media assets) is stored here as source-controlled artifacts and promoted through
environments via the Azure DevOps pipeline.

---

## Directory structure

```
portal/
├── artifacts/          # Exported portal content — committed to source control
│   ├── content/
│   │   ├── content.json          # All content types and their items
│   │   └── portalsettings.json   # Sign-in / sign-up / delegation settings
│   ├── media/                    # Uploaded media/image assets
│   └── export-metadata.json      # Traceability metadata from last export
├── config/
│   ├── sbox.json     # Sandbox environment substitution config
│   ├── dev.json
│   ├── test.json
│   ├── ithc.json
│   ├── demo.json
│   ├── stg.json
│   └── prod.json
└── scripts/
    ├── export-portal.ps1   # Extracts portal content from a live APIM instance
    └── deploy-portal.ps1   # Imports portal content into a target APIM instance
```

---

## What is managed here vs Terraform

| Concern | Managed by |
|---|---|
| APIM service, networking, identity, custom domains | Terraform (`components/apim`) |
| Named values, certificates | Terraform (`components/apim`) |
| Developer portal pages / layouts / widgets / styles | This directory + scripts |
| Developer portal media / images | This directory + scripts |
| Portal sign-in / sign-up / delegation settings | This directory + scripts |

**Do not** try to manage portal page content inside Terraform state. Terraform is
responsible for the infrastructure layer only.

---

## Prerequisites

- **Azure CLI** 2.30 or later — `az --version`
- PowerShell Core (pwsh) 7.x — `pwsh --version`
- **API Management Service Contributor** role on the APIM instance (for content and publish)
- **Storage Blob Data Contributor** on the APIM-associated storage account (for media upload)
- **Storage Blob Data Reader** on the APIM-associated storage account (for media export)

For CI/CD, the Azure DevOps service connection identity must hold these roles. The
existing Terraform service principals (e.g. `DTS-SPS-SBOX`) are good candidates since
they already have Contributor access to the resource group.

---

## Local export steps

Use this workflow to capture portal customizations made interactively in the Azure portal.

### 1. Authenticate

```powershell
az login
az account set --subscription "bd2864ed-4f3e-45ed-9c6a-8d179674bab1"  # sbox subscription
```

### 2. Find the APIM instance details

The APIM name and resource group for each environment are available as Terraform outputs:

```bash
# From the repo root (requires Terraform state access):
terraform -chdir=components/apim output apim_name
terraform -chdir=components/apim output resource_group_name
```

For sbox the values are:
- APIM name: `sps-api-mgmt-sbox`
- Resource group: `rg-sps-platform-sbox`

### 3. Run the export script

```powershell
cd portal/scripts

.\export-portal.ps1 `
    -Environment       sbox `
    -SubscriptionId    "bd2864ed-4f3e-45ed-9c6a-8d179674bab1" `
    -ResourceGroupName "rg-sps-platform-sbox" `
    -ApimName          "sps-api-mgmt-sbox"
```

### 4. Review and commit the artifacts

```bash
git diff portal/artifacts      # review what changed
git add portal/artifacts
git commit -m "chore: update APIM developer portal artifacts"
git push
```

Pushing to `main` triggers the pipeline, which deploys the updated content to all
environments where developer portal deployment is enabled.

---

## Environment-specific configuration

The `portal/config/<env>.json` files allow you to apply environment-specific string
substitutions to the exported portal content before importing it into a target APIM
instance. This is useful when portal pages contain environment-specific values such
as API base URLs or display names.

### Example

If your portal content references `https://amp-portal.sandbox.api.hmcts.net` and you
need a different URL in production, add a substitution to `portal/config/prod.json`:

```json
{
  "substitutions": {
    "https://amp-portal.sandbox.api.hmcts.net": "https://amp-portal.api.hmcts.net"
  }
}
```

Substitutions are applied as simple string replacements across the entire `content.json`
before uploading. If no substitutions are needed for an environment, leave the
`substitutions` object empty.

---

## CI/CD deployment flow

```
Developer updates portal in sbox APIM (via Azure portal UI)
    ↓
Run export-portal.ps1 locally
    ↓
git commit + push portal/artifacts
    ↓
Azure DevOps pipeline triggers
    ↓
sbox_apim Terraform stage runs (ensures APIM infra is current)
    ↓
sbox_apim_portal stage runs deploy-portal.ps1
    (imports content, uploads media, publishes portal)
```

The portal deployment stage is **only triggered when**:
- `overrideAction` is `apply`
- the pipeline parameter `deployDeveloperPortal` is set to `true`

This ensures existing Terraform-only runs are not affected by default.

### Enabling portal deployment in the pipeline

When running the pipeline manually in Azure DevOps, set:

```
overrideAction: apply
deployDeveloperPortal: true
```

---

## Running the deploy script locally

```powershell
az login
az account set --subscription "bd2864ed-4f3e-45ed-9c6a-8d179674bab1"

cd portal/scripts

.\deploy-portal.ps1 `
    -Environment       sbox `
    -SubscriptionId    "bd2864ed-4f3e-45ed-9c6a-8d179674bab1" `
    -ResourceGroupName "rg-sps-platform-sbox" `
    -ApimName          "sps-api-mgmt-sbox" `
    -Publish
```

---

## Required permissions summary

| Role | Scope | Purpose |
|---|---|---|
| API Management Service Contributor | APIM resource | Read/write portal content, publish portal |
| Storage Blob Data Contributor | APIM storage account | Upload media files |
| Storage Blob Data Reader | APIM storage account | Export/download media files |

---

## Rollback

To revert a portal deployment:

1. Identify the last known-good commit for `portal/artifacts`:
   ```bash
   git log --oneline portal/artifacts
   ```
2. Check out the previous artifact state:
   ```bash
   git checkout <good-commit-sha> -- portal/artifacts
   git commit -m "revert: roll back APIM developer portal to <good-commit-sha>"
   git push
   ```
3. This triggers the pipeline, which re-deploys the previous portal content.

Alternatively, roll back directly via the Azure portal by selecting a previous portal
revision under **APIs → Developer portal → Portal revisions**.

---

## Extending to additional environments

APIM is currently deployed only to `sbox` (see `environment_components` in
`azure-pipeline.yaml`). When APIM is extended to additional environments:

1. Add the environment to `environment_components` in `azure-pipeline.yaml`.
2. Populate `portal/config/<new-env>.json` with environment-specific values.
3. Add a portal deployment stage to `azure-pipeline.yaml` following the
   `sbox_apim_portal` pattern already present.
