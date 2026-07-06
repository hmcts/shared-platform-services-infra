# shared-platform-services-infra

Infrastructure-as-code for the Shared Platform Services (SPS) Azure environment,
managed with Terraform and deployed via Azure DevOps.

## Repository structure

| Path | Purpose |
|---|---|
| `components/` | Terraform components deployed per environment (core, apim, apim_appgw) |
| `environments/` | Per-environment `.tfvars` files |
| `modules/` | Shared local Terraform modules |
| `portal/` | APIM developer portal artifacts, scripts, and documentation |
| `azure-pipeline.yaml` | Azure DevOps pipeline definition |

## Developer portal

APIM developer portal customizations (pages, layouts, styles, media) are managed
separately from the Terraform infrastructure. See [`portal/README.md`](portal/README.md)
for full documentation including:

- How to export portal customizations from a live APIM instance
- Where artifacts are stored and how to commit them
- CI/CD deployment flow (post-APIM Terraform stage)
- Required permissions
- Environment-specific configuration
- Rollback guidance