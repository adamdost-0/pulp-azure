# Phase 1 PostgreSQL State Foundation

## Scope

This artifact aligns GitHub issue #10 with the OpenSpec design. The
PostgreSQL-compatible database is the service-owned state foundation for
repository sources, hydration runs, snapshots, transfer batches, exports,
high-side staging, imports, publications, supersession, compatibility
overrides, and audit history.

Azure Database for PostgreSQL Flexible Server is the preferred managed service
when it satisfies the required controls in the target cloud, region, and SKU.
If validation discovers an actual target-environment gap, a fallback must be
approved before use.

## Required capabilities

| Capability | Requirement |
| --- | --- |
| Private access | Database is reachable only through private networking. |
| Strong transitions | Lifecycle transitions use transactions or equivalent concurrency controls. |
| Audit history | State changes write append-only audit records with actor, timestamp, prior state, new state, reason, and related manifest/batch IDs. |
| Backup/restore | Backup policy, restore procedure, restore test, and recovery objective assumptions are documented. |
| Migration/rollback | Schema migration and rollback strategy is documented and tested before promotion. |
| Reporting consistency | Reporting paths may tolerate eventual consistency but cannot drive authoritative lifecycle transitions. |
| Encryption | Required encryption and CMK controls are configured where required. |
| Diagnostics | Query/database metrics and audit-relevant events are emitted to the approved diagnostics path. |
| Access control | Application access uses managed identity where available or an approved secret path through Key Vault; broad admin credentials are not embedded in app config. |

## State transition validation

Validation MUST prove that the database enforces at least these lifecycle rules:

- A failed hydration run cannot create a transfer-eligible snapshot.
- A snapshot already included in an approved transfer batch cannot be included
  in a new normal batch.
- A transfer batch cannot be exported before approval.
- A high-side staged batch cannot be imported before manifest validation passes.
- A batch cannot be published before Pulp import succeeds.
- A duplicate successful import is rejected.
- A rollback requires explicit approval and audit history.
- A compatibility warning requires privileged override and justification before
  import continues.

## Required consistency and race tests

Issue #10 closeout MUST include these transition tests with command/log
evidence and final state verification:

| Scenario | Pass criteria |
| --- | --- |
| Concurrent batch selection | Two concurrent attempts to include the same eligible snapshot cannot both create approved normal transfer batches. Exactly one authoritative result is accepted. |
| Concurrent import | Two concurrent import attempts for the same validated high-side batch cannot both succeed. The duplicate preserves the original import state. |
| Publish before import race | A publish request racing with an import task cannot publish until the import success state is committed. |
| Override race | A compatibility override cannot be applied after a conflicting reject/failure terminal state without a new approved workflow. |
| Rollback race | Competing rollback and promote operations produce one authoritative publication result and append complete audit history. |

## Migration and rollback pass criteria

Schema migration validation passes only when:

1. Migration applies cleanly from the previous schema version.
2. Required indexes/constraints for lifecycle transition enforcement exist after
   migration.
3. Existing state and audit history remain readable.
4. Rollback or forward-fix procedure is tested for a failed migration.
5. A failed migration does not leave partially applied authoritative state.

## Backup and restore validation

The evidence package MUST include:

1. Backup configuration.
2. Restore procedure.
3. Restore test result.
4. Validation that restored state preserves lifecycle state, audit history, and
   deterministic identifiers.
5. Operational ownership for restore approval and execution.

The restore drill passes only when restored state can reject a duplicate import,
publish the latest publication-ready batch, and retrieve audit history for the
restored batch/snapshot identifiers. The evidence package must record the
environment-specific recovery objective target or state that the target is not
yet authorized for Phase 1.

## Validation evidence for issue #10

Issue #10 can close only when its evidence package proves:

1. Selected PostgreSQL-compatible product/SKU or approved fallback is recorded.
2. Private connectivity and public access posture are validated.
3. CMK/encryption, diagnostics, backups, restore path, and access controls are
   validated.
4. Schema migration and rollback approach is documented.
5. Strong lifecycle transition tests pass.
6. Reporting paths are explicitly separated from authoritative transition
   enforcement.
