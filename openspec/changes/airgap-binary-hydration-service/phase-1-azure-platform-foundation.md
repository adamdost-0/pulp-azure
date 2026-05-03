# Phase 1 Azure Platform Foundation

## Scope

This artifact aligns GitHub issue #8 with the OpenSpec design. It defines the
mandatory Azure resource foundation for both the connected low side and the
disconnected high side.

Both sides use matching resource roles with environment-specific bindings:

- Azure Container Apps workload profile environment.
- Azure Container Registry.
- Azure Storage.
- PostgreSQL-compatible state store.
- Azure Key Vault.
- Diagnostics/logging service or approved private diagnostics fallback.
- Private networking and private DNS.
- Managed identities and least-privilege RBAC.

## Environment parameterization

IaC MUST parameterize:

| Parameter | Requirement |
| --- | --- |
| `cloudEnvironment` | Selects commercial, government, or approved high-side cloud configuration. |
| `location` | Target region validated for the selected cloud. |
| `resourceNamePrefix` | Environment-specific naming prefix. |
| `classification` | One of `CUI`, `Secret`, or `TopSecret`. |
| `compliance` | One of `FedRAMP-High`, `IL4`, `IL5`, or `IL6`. |
| `containerRegistryLoginServer` | Uses `.azurecr.io` for commercial or `.azurecr.us` for government/high side. |
| `storageDnsSuffix` | Uses commercial or `.blob.core.usgovcloudapi.net` suffix as appropriate. |
| `keyVaultDnsSuffix` | Uses commercial or `.vault.usgovcloudapi.net` suffix as appropriate. |
| `postgresDnsSuffix` | Uses commercial or `.postgres.database.usgovcloudapi.net` suffix as appropriate. |
| `tokenAuthorityHost` | Uses commercial Entra ID or `login.microsoftonline.us` for government/high side. |

High-side configuration MUST NOT hardcode public commercial endpoints, public
container registries, public package sources, or public DNS resolvers.

## Required resource controls

| Resource role | Required controls |
| --- | --- |
| Container Apps environment | Workload profiles, internal/private ingress for runtime endpoints, private ACR image pulls, managed identity, diagnostics, controlled egress, and no public high-side runtime dependency. |
| ACR | Premium where private endpoints/CMK/network restrictions are required, private endpoint, public network disabled where supported, CMK where required, diagnostic settings, import workflow for OCI tarballs, and tag-plus-digest image references. |
| Storage | Private endpoint, private DNS, public network disabled, TLS 1.2 minimum, CMK where required, diagnostics, and approved redundancy. |
| PostgreSQL-compatible DB | Private access only, encryption/CMK where required, backup/restore, diagnostics, maintenance and HA decision, managed identity or approved credential path, and least-privilege access. |
| Key Vault | Private endpoint, public network disabled, RBAC/access-policy decision, purge protection where required, diagnostic settings, and CMK/key material lifecycle controls. |
| Diagnostics | Private link/AMPLS where supported or approved private/local export fallback, retention policy, audit events, and export path for air-gapped operations. |
| Private networking/DNS | Private endpoint subnets, private DNS zones, VNet links, resolver behavior, NSG/UDR controls, and validation failure on public references. |

## Required tags

Every Azure resource MUST include:

| Tag | Allowed values |
| --- | --- |
| `Environment` | `dev`, `staging`, or `prod`. |
| `ManagedBy` | `bicep`, `terraform`, or `manual` only for approved manual resources. |
| `Project` | Project identifier for this deployment. |
| `Owner` | Owning team or accountable individual. |
| `Classification` | `CUI`, `Secret`, or `TopSecret`. |
| `Compliance` | `FedRAMP-High`, `IL4`, `IL5`, or `IL6`. |

## RBAC model

Managed identities must be scoped at the narrowest feasible resource scope:

| Identity | Minimum required access |
| --- | --- |
| Pulp API/container app identity | Read required Key Vault references, read/write approved storage paths, connect to PostgreSQL-compatible DB, emit diagnostics. |
| Pulp worker identity | Read required Key Vault references, read/write approved Pulp content/export/import storage paths, connect to PostgreSQL-compatible DB, emit diagnostics. |
| Scheduled job identity | Read source configuration, invoke approved Pulp tasks, write audit/state records, emit diagnostics. |
| Image import/release identity | Import approved OCI tarballs into ACR and read image metadata; no broad subscription owner rights. |
| Diagnostics/export identity | Write diagnostics to approved sinks and export sanitized logs to approved private/local destinations. |

No service-principal passwords, embedded storage keys, or secret-bearing
connection strings are allowed in application configuration.

## Validation evidence for issue #8

Issue #8 can close only when its evidence package proves:

1. Resource roles are represented in IaC for both low side and high side.
2. Environment-specific endpoint suffixes and token authorities are
   parameterized.
3. Required tags are applied to every resource.
4. Public network access is disabled where supported.
5. Private endpoint/private DNS dependencies are declared for supported PaaS
   services.
6. CMK mappings are defined where required.
7. Managed identities and least-privilege RBAC assignments are defined.
8. Diagnostics and retention are defined.
9. High-side validation rejects public endpoints, public registries, public DNS,
   public package sources, and commercial endpoint hardcoding.
