# APIM + App Gateway Alignment Plan (Terraform)

## Goal
Align APIM internal-VNet + Application Gateway behavior with Microsoft guidance at:
https://learn.microsoft.com/en-gb/azure/api-management/api-management-howto-integrate-internal-vnet-appgateway

This plan is designed for execution in two scopes:
1. This repository (`shared-platform-services-infra`)
2. The shared module repository (`hmcts/terraform-module-apim-application-gateway`)

## What is already updated in this repository
- `environments/sbox/apim_appgw_config.yaml`
  - Split APIM exposure into explicit endpoint configs for:
    - Gateway (`api`)
    - Developer portal (`amp-portal`)
    - Management (`management`)
  - Added public and private listener definitions for each endpoint (6 app configs total)
  - Added endpoint-specific health paths:
    - Gateway: `/status-0123456789abcdef`
    - Portal: `/signin`
    - Management: `/ServiceStatus`
  - Moved host suffix from `sandbox.platform.hmcts.net` to `sandbox.api.hmcts.net` to align with current certificate naming/domain strategy.

- `environments/sbox/sbox.tfvars`
  - Corrected backend target typing:
    - Use `apim_appgw_backend_pool_ips = ["10.180.0.4"]`
    - Set `apim_appgw_backend_pool_fqdns = []`

## Gap Analysis vs Microsoft Required Pattern

### Aligned (or partially aligned)
- Public and private listener exposure pattern is now represented.
- Dedicated endpoint hostnames and health probe paths are represented.
- WAF_v2 and TLS policy support already exist in current module interface.

### Not yet aligned due to shared module limitations
- Backend protocol and probe protocol are currently hardcoded to HTTP in module logic.
  - Microsoft pattern requires HTTPS backend communication to APIM endpoints.
- Backend HTTP settings are currently fixed to port 80 and request timeout defaults not tuned per endpoint.
  - Microsoft pattern expects HTTPS 443 and higher request timeout behavior for APIM scenarios.
- Trusted root certificate is not wired into backend HTTP settings for APIM TLS backend trust in a way equivalent to Microsoft sample.
- Backend pool targets are global inputs (`backend_pool_ip_addresses`, `backend_pool_fqdns`) and reused across all generated pools.
  - Microsoft pattern uses endpoint-specific backend pools (gateway/portal/management).
- WAF rule disable support (rule-group/ID level) for developer portal compatibility is not exposed.
  - Microsoft guidance lists portal-breaking rules such as `942200` (and others).

## Required Changes in `hmcts/terraform-module-apim-application-gateway`

1. Add per-app backend transport controls in YAML:
- `backend_protocol` (default `Https` for APIM use-case)
- `backend_port` (default `443`)
- `probe_protocol` (default `Https`)
- `probe_interval`, `probe_timeout`, `probe_unhealthy_threshold`
- `request_timeout`

2. Add per-app backend target controls in YAML:
- `backend_pool_ip_addresses` (list)
- `backend_pool_fqdns` (list)

3. Add trusted root support for backend settings:
- Extend module to map one or more trusted root certificates to backend HTTP settings.
- Permit certificate material from Key Vault secret or PEM/CER input (consistent with current module patterns).

4. Add WAF managed rule override support:
- Add variable(s) for disabled rule groups / rule IDs.
- Include capability to disable known APIM developer portal-breaking CRS rules in a controlled way.

5. Simplify public/private listener dual exposure:
- Optional enhancement: support `expose_public = true/false` and `expose_private = true/false` per app config to avoid duplicating app entries in YAML.

6. Release hygiene:
- Replace branch-based module source pin (`ref=DTSPO-31984-waf-changes`) with a version tag or immutable commit SHA after the above changes merge.

## Validation Steps (Agent Runbook)

1. Terraform static checks in this repo:
- `terraform -chdir=components/apim_appgw init`
- `terraform -chdir=components/apim_appgw validate`

2. Plan in `sbox`:
- Ensure expected additions:
  - 6 listeners (public/private x 3 endpoints)
  - 6 routing rules
  - 6 probes with endpoint-specific paths
- Confirm no unexpected AppGW replacement unless intended.

3. Post-apply verification:
- Run backend health check and confirm all pools healthy.
- Verify:
  - `https://api.<domain>/status-0123456789abcdef`
  - `https://amp-portal.<domain>/signin`
  - `https://management.<domain>/ServiceStatus`
- Validate both internal and external DNS resolution paths.

4. WAF hardening step:
- Start in Detection mode while tuning.
- Apply managed rule disables required for portal behavior.
- Move to Prevention mode once clean.

## Suggested Task Breakdown for a Repo-Scoped Agent

1. Implement module enhancements in `hmcts/terraform-module-apim-application-gateway`:
- Backend HTTPS/probe settings
- Per-app backend target lists
- Trusted root wiring
- WAF managed rule override support
- Optional public/private dual exposure flags

2. Publish module release and pin immutable ref.

3. Update this repo to consume released module ref.

4. Simplify `environments/sbox/apim_appgw_config.yaml` once module supports dual exposure flags (remove duplicated public/private entries).

5. Run plan/apply in `sbox` and capture evidence of healthy backend pools and endpoint reachability.
