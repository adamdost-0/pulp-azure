# Phase 1 Diagnostics and Operational Baseline

## Scope

This artifact aligns GitHub issue #13 with the OpenSpec design. Phase 1 must
prove operational visibility, auditability, retention, and recovery paths before
the integrated platform milestone can pass.

## Required telemetry

| Component | Required telemetry |
| --- | --- |
| Pulp API | Requests, errors, auth/authorization failures, task submission, health probes. |
| Pulp workers | Task lifecycle, sync/export/import/publish task status, failures, retries, queue depth where available. |
| Pulp content serving | Publication availability, content request failures, latency where available. |
| Hydration service | Source configuration changes, schedule triggers, state transitions, approvals, overrides, manifest generation, package validation, import/publish requests. |
| PostgreSQL-compatible DB | Availability, connection failures, backup status, restore events, migration events, query/resource metrics. |
| Storage | Availability, access failures, capacity, object operations relevant to content/export/import payloads. |
| Key Vault | Secret/key access events, denied access, CMK/key lifecycle events. |
| ACR | Image import events, pull failures, digest validation failures, denied access. |
| Networking/DNS | Private endpoint status, DNS validation results, rejected public references. |

## Audit events

The application MUST emit append-only audit events for:

- Repository source create/update/disable.
- Hydration start/success/failure.
- Snapshot eligibility changes.
- Transfer batch create/approve/reject/export.
- Manifest generation and checksum validation.
- High-side staging, validation, import, publish, supersede, rollback, and
  rejection.
- Privileged compatibility overrides.
- Administrative configuration changes.

Audit events must include actor, timestamp, action, prior state, new state,
reason, related manifest/batch/snapshot ID, and result.

## Private diagnostics access

Diagnostics access must use:

- Private link/AMPLS where supported by the target cloud and service.
- Approved private diagnostics sinks where Azure-native private link is not
  available.
- Local/private export fallback for disconnected high-side operations.

Diagnostics must not require high-side public internet access.

## Retention

Minimum retention is one year for audit history unless superseded by customer
policy. Operational logs and metrics should use the rollout environment's
approved retention policy, with export paths documented for evidence packages
and incident review.

## Failure drills

Phase 1 operational validation MUST include drills or documented tests for:

- Pulp task failure.
- Database connectivity failure.
- Storage/private endpoint failure.
- Key Vault access failure.
- ACR image pull failure.
- Diagnostics sink unavailable.
- Backup restore execution.
- Private/local log export fallback.

## Backup and restore drill pass criteria

Issue #13 backup/restore validation MUST cover Pulp content, PostgreSQL state,
and critical configuration.

| Area | Pass criteria |
| --- | --- |
| Pulp content | Restored content can serve a known repository snapshot through the expected internal publication path, and checksum/sample package validation matches pre-backup evidence. |
| PostgreSQL state | Restored state preserves lifecycle state, deterministic identifiers, and append-only audit history; duplicate/out-of-order operation rejection still works after restore. |
| Critical configuration | Restored Key Vault references, app settings, private endpoint/DNS bindings, image references, and diagnostics settings match the approved configuration or have documented differences. |
| Evidence | Drill output includes command logs, validation JSON or equivalent structured result, timestamps, actor/operator, source backup identifier, target restore environment, and pass/fail status. |
| Recovery objective | Evidence records the rollout environment's RTO/RPO or explicitly states that formal RTO/RPO is not yet authorized for the Phase 1 validation scope. |

## Operational failure drill pass criteria

Each failure drill passes only when the platform detects the failure, prevents a
false-success state, emits the required diagnostic/audit event, and recovers or
documents the operator action needed to recover. For disconnected high-side
operations, evidence must be retrievable through private diagnostics access or
the approved local/private export fallback.

## Validation evidence for issue #13

Issue #13 can close only when its evidence package proves:

1. Logs, metrics, and audit event inventory is complete.
2. Diagnostics are accessible without public endpoints or have an approved
   private/local fallback.
3. Retention policy is documented and configured for the rollout environment.
4. Backup/restore paths for Pulp content, PostgreSQL state, and critical
   configuration are documented and tested.
5. Failure drills are documented with expected and actual results.
6. Private/local log export fallback is documented for air-gapped operations.
