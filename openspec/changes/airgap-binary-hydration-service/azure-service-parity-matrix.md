# Azure Service/SKU Parity Matrix - Phase 1

## Purpose

This matrix supports GitHub issue #7, the Phase 1 Definition of Ready. It validates whether the proposed Azure/Pulp platform foundation can be built with equivalent service roles in Azure Commercial, Azure Government, and Azure Government Secret while preserving the air-gapped security posture.

Phase 1 deployment should not begin for the high-side environment until every Azure Government Secret row marked `Confirm with Microsoft/account team` is resolved to an approved service/SKU or an approved fallback.

## Source posture

- Microsoft documents Azure Government endpoint differences and service availability guidance for Azure Government, but the public Azure Government comparison documentation states that its lists and tables do **not** include feature or bundle availability in Azure Government Secret or Azure Government Top Secret clouds. For those air-gapped clouds, availability must be confirmed with the Microsoft account team.
- Azure Container Apps networking documentation states that workload profile environments support UDR, NAT Gateway egress, and private endpoints. Consumption-only environments do not support UDR, NAT Gateway egress, or custom egress. Phase 1 must therefore use workload profile environments for private-network validation.
- Azure Government endpoint suffixes differ from commercial endpoints. Phase 1 IaC must parameterize cloud environment and private DNS zone suffixes instead of hardcoding commercial `azure.com` or `windows.net` values.

## Decision summary

| Environment | Phase 1 readiness | PM decision |
| --- | --- | --- |
| Azure Commercial low side | Approved for Phase 1 planning and implementation once #7 is closed | Core services are available in commercial Azure; validate selected regions/SKUs during IaC work. |
| Azure Government | Conditionally approved for Phase 1 planning | Public docs show government endpoints/service categories, but target region/SKU details still require validation. |
| Azure Government Secret high side | Blocked pending Microsoft/account-team confirmation | Public docs do not confirm Gov Secret feature/bundle availability; do not assume parity. |

## Service/SKU matrix

| Service role | Azure Commercial | Azure Government | Azure Government Secret | Required Phase 1 assurance |
| --- | --- | --- | --- | --- |
| Azure Container Apps | Selected. Use workload profile environment, internal ingress, private endpoints where applicable, and no public runtime ingress. | Expected, needs target region/SKU confirmation. Confirm workload profile environment support, private endpoints, UDR, internal ingress, and diagnostics in selected USGov region. | Confirm with Microsoft/account team. | Must support private runtime, private ACR pulls, controlled egress, health probes, revision operations, and diagnostics without public dependencies. Consumption-only environments are not acceptable for high-side design. |
| Azure Container Registry | Selected. Use Premium where private endpoints, CMK, and network restrictions are required. | Expected, needs Premium/private endpoint/CMK confirmation in target region. Government registry suffix is `.azurecr.us`. | Confirm with Microsoft/account team. | High side must import all images before deployment, reject public registries, and deploy using tag-plus-digest references only. |
| Azure Storage | Selected. Required for Pulp content/export/import payloads and transfer staging where applicable. | Expected, needs account kind, private endpoint, CMK, diagnostic, and redundancy confirmation in target region. Blob suffix is `.blob.core.usgovcloudapi.net`. | Confirm with Microsoft/account team. | Public network access disabled, TLS 1.2 or higher, private endpoints/private DNS, CMK where required, diagnostics, backup/restore or replication strategy, and no public blob endpoints. |
| PostgreSQL-compatible database | Selected conceptually; exact product/SKU still open. Azure Database for PostgreSQL Flexible Server is the preferred managed option if available. | Expected, but exact Flexible Server availability, HA, private access, backup, CMK, and SKU support must be confirmed. Endpoint suffix is `.postgres.database.usgovcloudapi.net` for government PostgreSQL. | Confirm with Microsoft/account team. | Must provide private access, strong consistency for lifecycle transitions, backup/restore, diagnostics, encryption controls, least-privilege access, and migration/rollback support. |
| Key Vault | Selected for secrets, CMK material, and configuration references. | Expected, needs private endpoint, RBAC model, CMK, diagnostics, and purge-protection feature confirmation. Vault suffix is `.vault.usgovcloudapi.net`. | Confirm with Microsoft/account team. | Public network access disabled, private endpoints/private DNS, RBAC or access policy decision, purge protection where required, diagnostic events, and no hardcoded secrets. |
| Diagnostics/logging | Selected. Azure Monitor/Log Analytics is preferred where available; local/private export fallback required for air-gapped differences. | Expected, needs Log Analytics, Application Insights, AMPLS/private link, retention, export, and region confirmation. Government endpoints include `*.opinsights.azure.us`, `*.monitor.azure.us`, and related USGov suffixes. | Confirm with Microsoft/account team. | Logs, metrics, audit events, retention, private diagnostics access, and private/local export fallback must be documented and tested. |
| Private endpoints/private DNS | Selected for all supported PaaS services. | Expected, but private DNS zone names and service-specific endpoint support must be confirmed per target service/region. | Confirm with Microsoft/account team. | IaC must parameterize cloud-specific private DNS zones and fail validation on public endpoints, public DNS resolvers, or public service endpoint references in high-side config. |
| Managed identity / Entra ID | Selected for Azure service access. Commercial token endpoint is `login.microsoftonline.com`. | Expected. Government token endpoint is `login.microsoftonline.us`; exact managed identity behavior in target region must be validated. | Confirm with Microsoft/account team. | All service-to-service Azure access must use managed identity with least-privilege RBAC scoped to the narrowest feasible resource scope. No service principal passwords or connection-string secrets. |

## Required Gov Secret confirmations

Before closing #7 as a full Phase 1 Definition of Ready for high-side deployment, obtain written confirmation or approved environment documentation for:

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

#7 can close only when the project records one of these outcomes:

- **Pass:** all selected high-side services/SKUs are confirmed and Phase 1 can proceed to implementation.
- **Pass with scoped waiver:** a service/SKU is not confirmed, but Phase 1 is limited to low-side, Azure Government, or planning-only work with an approved fallback decision and documented risk owner.
- **Block:** any high-side required service remains unknown with no approved fallback.

The current state is **block high-side Azure Government Secret deployment work, allow low-side and planning refinement** until the confirmations above are complete.

## Evidence expected in Phase 1 issues

- #8 Azure Platform Foundation: IaC plan/apply evidence, required tags, private endpoints, public access disabled, CMK where required, managed identity/RBAC assignments, diagnostics.
- #9 Pulp Runtime and Container Apps Topology: selected topology, image/version/digest, persistence mapping, health/startup probes, scaling/failure behavior, no `pulp_container` in first release.
- #10 PostgreSQL State Foundation: private connectivity proof, backup/restore proof, migration/rollback approach, diagnostics, encryption/access controls, strong transition test.
- #11 Image Mirroring and ACR Supply Chain: image BOM, OCI export/import evidence, high-side ACR import evidence, tag-plus-digest references, rejection tests for public/tag-only/missing/digest-mismatch images.
- #12 Private Networking and DNS Validation: private DNS proof, no public endpoint references, no public runtime dependency proof, failure tests for public references.
- #13 Diagnostics and Operational Baseline: logs, metrics, audit events, private diagnostics access, retention, backup/restore drills, private/local export fallback.
- #14 Platform Milestone Test: integrated low-side and high-side startup, Pulp/PostgreSQL/storage/Key Vault/ACR/diagnostics health, and no-public-runtime-dependency proof.

