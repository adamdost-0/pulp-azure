# Phase 1 Pulp Runtime and Container Apps Topology

## Scope

This artifact aligns GitHub issue #9 with the OpenSpec design. The local
single-container harness proves Pulp behavior, but it is not the default
production topology. Phase 1 must define the Azure Container Apps runtime shape
deliberately and keep low-side and high-side runtime versions identical.

## Version baseline

The Phase 1 baseline remains:

- pulpcore 3.110.0
- pulp_deb 3.8.1
- First-release plugin scope: `pulp_deb` only
- `pulp_container`: excluded from MVP scope

Any version change requires an updated image BOM, local harness revalidation,
and issue evidence showing low-side/high-side parity.

## Runtime components

| Component | Container Apps role | Notes |
| --- | --- | --- |
| Pulp API | Long-running app | Serves Pulp REST API over internal ingress only in high-side environments. |
| Pulp content | Long-running app | Serves repository content/publications; high-side client access uses internal HTTPS and internal PKI. |
| Pulp workers | Worker app or job-capable app | Executes sync, export, import, publish, and maintenance tasks. |
| Scheduled hydration/export jobs | Container Apps jobs | Low-side scheduled jobs trigger configured Ubuntu APT sync/export workflows. High-side scheduled jobs are limited to local maintenance and validation workflows. |
| Admin/ops jobs | Container Apps jobs | Run approved maintenance, migrations, import checks, diagnostics export, and controlled repair operations. |
| Orchestration service | Long-running app and/or jobs | Tracks state, submits Pulp tasks, validates manifests, and exposes operator workflows. |

## Persistence mapping

| Data | Required backing service |
| --- | --- |
| Pulp database state | PostgreSQL-compatible DB. |
| Service lifecycle state | PostgreSQL-compatible DB. |
| Pulp artifacts/content | Approved private Azure Storage path. |
| Pulp exports/imports | Approved private Azure Storage path with transfer staging controls. |
| Secrets/configuration | Key Vault-backed configuration references. |
| Runtime images | Private ACR only. |
| Audit history | PostgreSQL-compatible DB plus diagnostics/export path. |

## Health and startup probes

Phase 1 validation MUST define probes for:

- Pulp API readiness.
- Pulp content serving readiness.
- Worker task execution readiness.
- PostgreSQL-compatible DB connectivity.
- Storage read/write access.
- Key Vault reference resolution.
- ACR image pull success.
- Diagnostics emission.

Startup must fail rather than silently degrade when required private services,
images, or secrets are unavailable.

## Scaling and failure behavior

Phase 1 evidence MUST document:

- Minimum and maximum replica counts for API/content/worker components.
- Job concurrency limits for sync/export/import/publish operations.
- Expected behavior when a Pulp task fails.
- Expected behavior when storage, database, Key Vault, ACR, or diagnostics are
  unavailable.
- How failed tasks are surfaced in service state and audit history.
- How high-side import/publication avoids public runtime dependencies.

## Required runtime validation matrix

Issue #9 closeout MUST include this matrix with expected result, actual result,
command/log evidence, and pass/fail status:

| Scenario | Pass criteria |
| --- | --- |
| Replica bounds | Declared minimum and maximum replica counts for API, content, and workers are applied in the target environment and reflected in deployed state. |
| Job concurrency | Declared sync/export/import/publish job concurrency limits are applied, and an over-limit submission is queued or rejected according to the documented policy. |
| API startup probe failure | If PostgreSQL, Storage, Key Vault, or required configuration is unavailable, API startup/readiness fails visibly and does not report healthy. |
| Content startup probe failure | If content storage or publication configuration is unavailable, content serving readiness fails visibly and does not report healthy. |
| Worker dependency outage | If PostgreSQL, Storage, or Key Vault is unavailable, worker task execution fails safely, records failure, and does not mark state successful. |
| Pulp task failure | A failed sync/export/import/publish task is captured in service state, emits diagnostics, and writes audit history where applicable. |
| Image pull failure | Missing or mismatched private ACR image prevents startup and is surfaced as a deployment validation or runtime failure. |
| High-side private-only operation | High-side API/content/workers/jobs start and execute validation using private ACR and private service endpoints only. |

## Deployment image rule

Every runtime component must reference an approved private ACR image by tag plus
digest. High-side deployment validation must fail if any component references a
public registry, a tag-only image, a missing ACR image, or a digest that differs
from the approved image BOM.

## Validation evidence for issue #9

Issue #9 can close only when its evidence package proves:

1. Pulp API, workers, content serving, scheduled jobs, admin jobs, and
   orchestration service topology are defined.
2. Low-side and high-side use identical pulpcore and pulp_deb versions.
3. `pulp_container` remains excluded from the first release.
4. Persistence maps to approved private Azure services.
5. Health/startup probes are defined and validated.
6. Scaling and failure behavior are documented.
7. Runtime images use private ACR tag-plus-digest references only.
