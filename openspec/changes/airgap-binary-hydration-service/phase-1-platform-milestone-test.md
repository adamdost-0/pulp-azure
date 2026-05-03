# Phase 1 Platform Milestone Test

## Scope

This artifact aligns GitHub issue #14 with the OpenSpec design. The platform
milestone is the integrated gate from Phase 1 into Phase 2 repository workflow
implementation. It is not a basic smoke test.

Issue #14 depends on successful completion of issues #8 through #13 or explicit
approved waivers.

## Test objectives

The milestone test MUST prove:

1. Low-side Azure Commercial deployment starts using private service access.
2. High-side Azure Government Secret deployment starts using private ACR and
   private service access only.
3. Pulp API, Pulp workers, Pulp content serving, PostgreSQL-compatible state,
   Storage, Key Vault, ACR, diagnostics, and private networking are healthy.
4. High-side runtime has no observed public dependencies.
5. Results are documented as the authorization gate into Phase 2.

## Required evidence inputs

| Input | Source issue |
| --- | --- |
| Azure resource foundation evidence | #8 |
| Pulp runtime topology and health evidence | #9 |
| PostgreSQL state, backup/restore, and transition evidence | #10 |
| Image BOM and private ACR import evidence | #11 |
| Private endpoint, DNS, and no-public-dependency evidence | #12 |
| Diagnostics, retention, and operational drill evidence | #13 |

## Milestone validation sequence

1. Confirm target environment metadata and resource inventory.
2. Confirm approved image BOM entries are imported into private ACR.
3. Deploy or validate low-side Container Apps using private service access.
4. Deploy or validate high-side Container Apps using private ACR and private
   service access only.
5. Run component health checks:
   - Pulp API
   - Pulp workers
   - Pulp content serving
   - PostgreSQL-compatible DB
   - Storage
   - Key Vault
   - ACR
   - diagnostics
   - private DNS and private endpoints
6. Run no-public-runtime-dependency validation on high-side configuration and
   runtime observations.
7. Run required negative tests inherited from the evidence backbone.
8. Collect sanitized evidence package and issue links.
9. Record Phase 2 authorization decision for the validated deployment scope.

## Pass/fail criteria

The milestone passes only when:

- Every required component is healthy.
- High-side runtime uses only private ACR and private service endpoints.
- No public registry, package source, DNS resolver, service endpoint, or
  commercial endpoint hardcoding is present in high-side runtime configuration.
- Required diagnostics and audit events are emitted.
- Backup/restore and operational evidence from #10 and #13 is linked.
- All unresolved gaps have approved fallback or waiver records.

The milestone fails when any required component is unhealthy, any high-side
public runtime dependency is observed, or any required evidence package is
missing.

## Phase 2 authorization record

The final #14 evidence package must include a decision record with:

- Validated cloud/environment scope.
- GitHub issues and evidence packages included.
- Known limitations.
- Approved waivers, if any.
- Decision: `authorize-phase-2`, `authorize-limited-phase-2`, or `block`.
- Decision owner and timestamp.

## Validation evidence for issue #14

Issue #14 can close only when its evidence package proves:

1. #8 through #13 are closed or explicitly waived.
2. Low-side and high-side platform startup succeeds in the validated scope.
3. Required component health checks pass.
4. High-side no-public-runtime-dependency validation passes.
5. Phase 2 authorization decision is recorded.
