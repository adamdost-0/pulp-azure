# Phase 1 Evidence Backbone

## Purpose

This document defines the common evidence contract for Phase 1 GitHub issues
#8 through #14. Phase 1 is authorized to proceed because selected Azure service
roles have no known parity delta across Azure Commercial, Azure Government, and
Azure Government Secret, but each Phase 1 epic must still produce
target-environment validation evidence before it closes.

The evidence backbone exists to prevent each epic from using a different proof
standard. Every Phase 1 issue must produce capability evidence, security
assurance evidence, and failure evidence where the issue defines rejection
behavior.

## Required evidence package layout

Each Phase 1 issue evidence package SHOULD use this structure:

```text
phase-1/<issue-number>-<short-name>/
  README.md
  target-environment.json
  resource-inventory.json
  controls.json
  validation-results.json
  command-log.txt
  failure-tests/
  artifacts/
```

Runtime evidence may live outside the repository when it includes environment
specific values or operational logs. The repository should keep the reusable
validation logic, sanitized summaries, issue comments, and decision records.

## Common evidence fields

`target-environment.json` MUST include:

| Field | Requirement |
| --- | --- |
| `environmentName` | Human-readable deployment environment name. |
| `cloud` | One of `AzureCommercial`, `AzureGovernment`, or `AzureGovernmentSecret`. |
| `azureEnvironment` | Azure SDK/CLI environment value such as `public`, `usgovernment`, or the approved high-side equivalent. |
| `tenantId` | Sanitized or redacted tenant identifier. |
| `subscriptionId` | Sanitized or redacted subscription identifier. |
| `region` | Target Azure region. |
| `classification` | One of `CUI`, `Secret`, or `TopSecret`. |
| `compliance` | One of `FedRAMP-High`, `IL4`, `IL5`, or `IL6`. |
| `networkMode` | Private networking mode used for the validation. |
| `validatedAt` | Timestamp when validation evidence was collected. |

`resource-inventory.json` MUST include every Azure resource role used by the
issue, including resource type, resource name or sanitized identifier, SKU,
region, private endpoint status, public network access status, diagnostic
setting status, CMK status, managed identity assignment, and required tags.

`controls.json` MUST record pass/fail/not-applicable status for:

- Private endpoints and private DNS for supported PaaS services.
- Public network access disabled for supported PaaS services.
- No high-side public internet, public DNS, public registry, public package
  source, or public service endpoint dependency.
- Government endpoint and private DNS suffix parameterization.
- Managed identity for service-to-service Azure access.
- Least-privilege RBAC at the narrowest feasible scope.
- Key Vault references for secrets and configuration.
- CMK for required data-at-rest services.
- TLS 1.2 or higher.
- Internal HTTPS and internal PKI for high-side APT publication.
- Diagnostic settings, logs, metrics, audit events, retention, and export
  fallback.
- Required tags: `Environment`, `ManagedBy`, `Project`, `Owner`,
  `Classification`, and `Compliance`.
- ACR-only image sourcing and tag-plus-digest deployment references.
- Backup, restore, rollback, and failure-mode evidence for stateful services.

`validation-results.json` MUST include every validation command or test,
expected result, actual result, evidence artifact path, and final status.

## Issue-specific evidence requirements

| Issue | Evidence package MUST prove |
| --- | --- |
| #8 Azure Platform Foundation | Container Apps, ACR, Storage, PostgreSQL-compatible DB, Key Vault, diagnostics, private networking, managed identities, RBAC, required tags, public access controls, CMK mappings, and cloud endpoint parameterization are represented in IaC and validated for the target environment. |
| #9 Pulp Runtime and Container Apps Topology | Pulp API, workers, content serving, scheduled jobs, persistence, health/startup probes, scale behavior, failure behavior, and pinned Pulp image/version/digest configuration are defined and validated. `pulp_container` remains out of MVP scope. |
| #10 PostgreSQL State Foundation | PostgreSQL-compatible product/SKU, private access, CMK/encryption, backup/restore, diagnostics, access controls, schema migration/rollback, strong lifecycle transitions, and reporting consistency assumptions are validated. |
| #11 Image Mirroring and ACR Supply Chain | Image BOM, OCI tarball export/import, high-side ACR import, tag-plus-digest references, approval state, import status, digest verification, and rejection tests for public/tag-only/missing/digest-mismatch/unapproved images are validated. |
| #12 Private Networking and DNS Validation | Private endpoints, private DNS zones, government suffixes, resolver behavior, no-public-runtime-dependency checks, and validation failures for public endpoint/DNS/registry/package-source references are proven. |
| #13 Diagnostics and Operational Baseline | Logs, metrics, audit events, private diagnostics access, retention, backup/restore drills, private/local export fallback, and operational failure drills are validated. |
| #14 Platform Milestone Test | Integrated low-side and high-side startup, Pulp/PostgreSQL/storage/Key Vault/ACR/diagnostics/private-network health, no high-side public runtime dependency, and Phase 2 authorization decision evidence are captured. |

## Failure evidence requirements

Phase 1 validation must include negative tests wherever an issue defines
rejection behavior. Required negative tests include:

| Failure condition | Expected result |
| --- | --- |
| High-side image reference uses a public registry. | Deployment validation fails before promotion. |
| High-side image reference uses a mutable tag without a digest. | Deployment validation fails before promotion. |
| High-side image digest does not match the image BOM. | Deployment validation fails before promotion. |
| High-side configuration references a public service endpoint. | Network/config validation fails before promotion. |
| High-side configuration references a public DNS resolver. | Network/config validation fails before promotion. |
| High-side configuration references a public package source. | Network/config validation fails before promotion. |
| Required private endpoint or private DNS link is missing. | Platform validation fails before milestone acceptance. |
| Required managed identity or RBAC assignment is missing. | Platform validation fails before milestone acceptance. |
| Required diagnostics or retention setting is missing. | Operational validation fails before milestone acceptance. |
| Required backup or restore drill is missing for stateful services. | Operational validation fails before milestone acceptance. |

## Phase 1 closeout rule

A Phase 1 issue can close only when all of the following are true:

1. The issue-specific evidence package exists or the sanitized evidence location
   is linked from the issue.
2. Common control evidence is complete for the issue scope.
3. Required negative tests pass.
4. Any discovered service, SKU, endpoint, or control gap has an approved
   fallback or waiver.
5. The GitHub issue comment links the evidence, summarizes capability proof, and
   summarizes security assurance proof.

## Phase 1 gate to Phase 2

Issue #14 is the integrated Phase 1 gate. It cannot close until #8 through #13
are closed or have explicit approved waivers. A #14 pass authorizes Phase 2
repository workflow implementation for the validated deployment scope only.
