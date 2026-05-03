# Phase 1 Private Networking and DNS Validation

## Scope

This artifact aligns GitHub issue #12 with the OpenSpec design. Runtime traffic
must use private paths. High-side runtime must not depend on public internet,
public DNS, public registries, public package sources, or public service
endpoints.

## Required private connectivity

| Service role | Required private path |
| --- | --- |
| ACR | Private endpoint and private DNS for image pulls and metadata access. |
| Storage | Private endpoint and private DNS for blob/content/export/import paths. |
| PostgreSQL-compatible DB | Private access only; no public database endpoint exposure. |
| Key Vault | Private endpoint and private DNS for secrets, keys, and references. |
| Diagnostics | AMPLS/private link where supported or approved private/local export fallback. |
| Pulp content/API | Internal ingress only for high-side runtime and publication paths. |

## Cloud-specific suffixes

IaC and validation must parameterize endpoint suffixes rather than hardcoding
commercial endpoints.

| Service | Government/high-side suffix |
| --- | --- |
| ACR | `.azurecr.us` |
| Blob Storage | `.blob.core.usgovcloudapi.net` |
| Key Vault | `.vault.usgovcloudapi.net` |
| PostgreSQL | `.postgres.database.usgovcloudapi.net` |
| Entra ID | `login.microsoftonline.us` |
| Azure Resource Manager | `management.usgovcloudapi.net` |

## Validation checks

Validation MUST prove:

1. Required private endpoints exist and are approved.
2. Private DNS zones exist and are linked to the correct VNets.
3. Runtime name resolution resolves required services to private addresses.
4. Container Apps can pull images from private ACR without public registry
   access.
5. Pulp can reach Storage, PostgreSQL-compatible DB, Key Vault, and diagnostics
   through private paths.
6. High-side package intake/import/publication works without public internet.
7. No high-side configuration references public DNS resolvers, public package
   sources, public service endpoints, or commercial endpoint suffixes.

## Required rejection tests

Validation MUST fail when high-side configuration contains:

- Public registry references.
- Public package source URLs.
- Public DNS resolver IPs or resolver hostnames.
- Commercial endpoint suffixes for government/high-side services.
- Missing private DNS zone links for required PaaS services.
- Public network access enabled where the service supports disabling it.

## Validation evidence for issue #12

Issue #12 can close only when its evidence package proves:

1. Private endpoint and private DNS inventory is complete.
2. Runtime DNS resolves required services to private paths.
3. Container Apps starts and operates using private ACR and private services.
4. High-side no-public-runtime-dependency checks pass.
5. Public endpoint, public DNS, public registry, public package source, and
   commercial endpoint hardcoding rejection tests pass.
