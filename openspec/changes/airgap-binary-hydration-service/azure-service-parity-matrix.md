# Azure Service/SKU Parity Matrix - Phase 1

## Purpose

This matrix supports GitHub issue #7, the Phase 1 Definition of Ready. It records the parity position for the Azure service roles selected by this design and separates service-role parity from target-environment validation evidence.

For the Azure services used by this design, there is no known service-role parity delta between Azure Commercial, Azure Government, and Azure Government Secret. Phase 1 deployment still requires target-environment validation for the exact tenant, region, SKU, network mode, and security controls before any high-side rollout.

## Source posture

- Microsoft documents Azure Government endpoint differences and service availability guidance for Azure Government, but the public Azure Government comparison documentation states that its lists and tables do **not** include feature or bundle availability in Azure Government Secret or Azure Government Top Secret clouds. This public-documentation gap is not being treated as a known service-parity delta for the services selected here; it is treated as a target-environment validation requirement.
- Azure Container Apps networking documentation states that workload profile environments support UDR, NAT Gateway egress, and private endpoints. Consumption-only environments do not support UDR, NAT Gateway egress, or custom egress. Phase 1 must therefore use workload profile environments for private-network validation.
- Azure Government endpoint suffixes differ from commercial endpoints. Phase 1 IaC must parameterize cloud environment and private DNS zone suffixes instead of hardcoding commercial `azure.com` or `windows.net` values.

## Decision summary

| Environment | Phase 1 readiness | PM decision |
| --- | --- | --- |
| Azure Commercial low side | Approved for Phase 1 planning and implementation once #7 is closed | Validate selected regions, SKUs, private networking, CMK, diagnostics, identity, and image supply-chain controls during IaC work. |
| Azure Government | Approved for Phase 1 planning and implementation once #7 is closed | Validate selected USGov regions, SKUs, endpoint suffixes, private DNS, and security controls during IaC work. |
| Azure Government Secret high side | Service-role parity accepted for selected services; deployment requires target-environment validation evidence | Do not block on a presumed service-parity delta. Validate the exact high-side tenant/region/SKU/control configuration before rollout. |

## Service/SKU matrix

| Service role | Azure Commercial | Azure Government | Azure Government Secret | Required Phase 1 assurance |
| --- | --- | --- | --- | --- |
| Azure Container Apps | Selected. Use workload profile environment, internal ingress, private endpoints where applicable, and no public runtime ingress. | Selected. Validate target USGov region/SKU, workload profile environment, private endpoints, UDR, internal ingress, and diagnostics. | Selected service role. Validate the exact high-side environment supports workload profiles, private ACR pulls, internal ingress, private endpoints, controlled egress, and diagnostics. | Must support private runtime, private ACR pulls, controlled egress, health probes, revision operations, and diagnostics without public dependencies. Consumption-only environments are not acceptable for high-side design. |
| Azure Container Registry | Selected. Use Premium where private endpoints, CMK, and network restrictions are required. | Selected. Validate Premium/private endpoint/CMK support in target region. Government registry suffix is `.azurecr.us`. | Selected service role. Validate high-side private endpoint, CMK, network restrictions, and OCI import workflow. | High side must import all images before deployment, reject public registries, and deploy using tag-plus-digest references only. |
| Azure Storage | Selected. Required for Pulp content/export/import payloads and transfer staging where applicable. | Selected. Validate account kind, private endpoint, CMK, diagnostics, and redundancy in target region. Blob suffix is `.blob.core.usgovcloudapi.net`. | Selected service role. Validate private endpoints, private DNS, CMK, diagnostics, TLS settings, and approved redundancy options. | Public network access disabled, TLS 1.2 or higher, private endpoints/private DNS, CMK where required, diagnostics, backup/restore or replication strategy, and no public blob endpoints. |
| PostgreSQL-compatible database | Selected conceptually; exact product/SKU still open. Azure Database for PostgreSQL Flexible Server is the preferred managed option. | Selected conceptually. Validate Flexible Server, HA, private access, backup, CMK, and SKU support in target region. Endpoint suffix is `.postgres.database.usgovcloudapi.net` for government PostgreSQL. | Selected service role. Validate the exact managed PostgreSQL-compatible product/SKU, private access, backups, HA options, encryption controls, diagnostics, and maintenance behavior. | Must provide private access, strong consistency for lifecycle transitions, backup/restore, diagnostics, encryption controls, least-privilege access, and migration/rollback support. |
| Key Vault | Selected for secrets, CMK material, and configuration references. | Selected. Validate private endpoint, RBAC model, CMK, diagnostics, and purge-protection features. Vault suffix is `.vault.usgovcloudapi.net`. | Selected service role. Validate private endpoint, RBAC/access-policy model, CMK support, purge protection, and diagnostics. | Public network access disabled, private endpoints/private DNS, RBAC or access policy decision, purge protection where required, diagnostic events, and no hardcoded secrets. |
| Diagnostics/logging | Selected. Azure Monitor/Log Analytics is preferred where available; local/private export fallback required for air-gapped differences. | Selected. Validate Log Analytics, Application Insights, AMPLS/private link, retention, export, and region configuration. Government endpoints include `*.opinsights.azure.us`, `*.monitor.azure.us`, and related USGov suffixes. | Selected service role. Validate Azure Monitor/Log Analytics or approved private diagnostics fallback, private link/AMPLS where applicable, retention, and export behavior. | Logs, metrics, audit events, retention, private diagnostics access, and private/local export fallback must be documented and tested. |
| Private endpoints/private DNS | Selected for all supported PaaS services. | Selected. Validate private DNS zone names and service-specific endpoint support per target service/region. | Selected service role. Validate private DNS zone names, endpoint suffixes, and resolver behavior for the selected high-side services. | IaC must parameterize cloud-specific private DNS zones and fail validation on public endpoints, public DNS resolvers, or public service endpoint references in high-side config. |
| Managed identity / Entra ID | Selected for Azure service access. Commercial token endpoint is `login.microsoftonline.com`. | Selected. Government token endpoint is `login.microsoftonline.us`; validate target-region managed identity behavior. | Selected service role. Validate managed identity and Entra token endpoint behavior in the target high-side environment. | All service-to-service Azure access must use managed identity with least-privilege RBAC scoped to the narrowest feasible resource scope. No service principal passwords or connection-string secrets. |

## Required target-environment validations

Before high-side deployment, record validation evidence for the exact target environment:

1. Azure Container Apps availability in the selected Azure Government Secret region, including workload profiles, internal ingress, UDR/custom egress, private endpoints, private ACR pulls, and diagnostics.
2. Azure Container Registry Premium/private endpoint/CMK support and high-side import workflow for OCI tarballs.
3. Azure Storage account capabilities: private endpoints, private DNS, CMK, diagnostics, TLS settings, and approved redundancy options.
4. PostgreSQL-compatible managed database product/SKU, including private access, backup/restore, HA options, encryption controls, diagnostics, and maintenance behavior.
5. Key Vault private endpoint, RBAC/access-policy model, CMK support, purge protection, and diagnostics.
6. Azure Monitor/Log Analytics or approved diagnostics alternative, including private link/AMPLS support and retention/export behavior.
7. Private DNS zone names and endpoint suffixes for all selected high-side services.
8. Managed identity and Entra token endpoint behavior for the target high-side cloud.
9. Any service limits, disconnected-cloud deployment constraints, or support process requirements that affect Container Apps, ACR, Storage, PostgreSQL, Key Vault, diagnostics, or private networking.

## Phase 1 Definition of Ready implication

#7 records the service-role parity position and the evidence expected before Phase 1 implementation milestones close. It should use these gate outcomes:

- **Pass:** selected service roles have no known parity delta, and target-environment validations are complete for the intended deployment scope.
- **Pass with validation required:** selected service roles have no known parity delta, but exact target-region/SKU/control validation remains an implementation milestone criterion.
- **Block:** validation discovers an actual service, SKU, endpoint, or control gap with no approved fallback.

The current state is **pass with validation required**. Do not frame Azure Government Secret as blocked by a known service-parity delta. Instead, require Phase 1 evidence to prove the target high-side configuration satisfies the selected service roles and security controls.

## Evidence expected in Phase 1 issues

- #8 Azure Platform Foundation: IaC plan/apply evidence, required tags, private endpoints, public access disabled, CMK where required, managed identity/RBAC assignments, diagnostics.
- #9 Pulp Runtime and Container Apps Topology: selected topology, image/version/digest, persistence mapping, health/startup probes, scaling/failure behavior, no `pulp_container` in first release.
- #10 PostgreSQL State Foundation: private connectivity proof, backup/restore proof, migration/rollback approach, diagnostics, encryption/access controls, strong transition test.
- #11 Image Mirroring and ACR Supply Chain: image BOM, OCI export/import evidence, high-side ACR import evidence, tag-plus-digest references, rejection tests for public/tag-only/missing/digest-mismatch images.
- #12 Private Networking and DNS Validation: private DNS proof, no public endpoint references, no public runtime dependency proof, failure tests for public references.
- #13 Diagnostics and Operational Baseline: logs, metrics, audit events, private diagnostics access, retention, backup/restore drills, private/local export fallback.
- #14 Platform Milestone Test: integrated low-side and high-side startup, Pulp/PostgreSQL/storage/Key Vault/ACR/diagnostics health, and no-public-runtime-dependency proof.
