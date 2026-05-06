# Project Context

- **Owner:** adamdost-0
- **Project:** This solution helps deliver the Pulp Project in Azure Commercial and Azure Government AirGap environments.
- **Stack:** Azure Commercial, Azure Government, AirGap operations, Pulp, Azure 1P PaaS, IaC/automation and customer setup guidance.
- **Created:** 2026-05-04T15:03:33.394+00:00

## Core Context

Book owns customer enablement documentation for an Azure-based Pulp accelerator that supports AirGap bundle release and manual transfer workflows.

## Learnings

**2026-05-04T21:08:34.767+00:00 - Local Dev Harness Runtime Review**

Phase 0-2 local harness assumes Podman, but infrastructure supports Docker on localhost if scripts respect `PULP_CONTAINER_RUNTIME` variable. Key findings:

- **README emphasis**: Heavily biased toward Podman VM, macOS Podman machine start, SELinux—no Docker Desktop guidance
- **Scripts hardcoding**: `run-e2e.sh`, `run-low-high-e2e.sh`, `validate-*.sh` all hardcode `require_cmd podman` before checking runtime variable
- **Compose compatibility**: `compose.pulp.yaml` is v3+ format, works with both runtimes—but scripts hardcode `podman compose`
- **Config exists**: `env.example` already has `PULP_CONTAINER_RUNTIME=podman`; changing to `docker` should work with script fixes
- **Scope**: ~900 lines of shell scripts with ~20 hardcoded podman references; non-trivial but feasible refactoring
- **Decision pending**: Zoey to confirm Docker support priority and whether Phase 1 depends on Podman-specific behavior

**Action**: Created backlog doc at `.squad/decisions/inbox/book-local-dev-docs.md` with feasibility assessment and team sign-off recommendations.

**2026-05-04T21:08:34.767+00:00 - Docker Docs Reconciliation Complete**

**Status**: Scripts have been refactored to be runtime-aware. Reconciliation complete.

**Changes made to `docs/local-dev-docker-backlog.md`:**
- Removed stale claims that `run-e2e.sh`, `run-low-high-e2e.sh`, `validate-amd64.sh`, `validate-no-egress.sh` hardcode Podman
- Updated "Known Limitations" section to reflect current capability: all scripts use `resolve_container_runtime()` from `common.sh`
- Clarified that only `generate-fixture.sh` has a host-tool blocker (missing `ar` command), not a runtime issue
- Updated Docker Desktop Quick-Start guidance to note that scripts auto-detect and use configured runtime
- Replaced "Backlog: Script Refactoring" section with "Documentation Status" showing all scripts are runtime-aware

**Verified by script inspection:**
- `common.sh` provides `resolve_container_runtime()` (auto → Podman → Docker)
- `run-e2e.sh`, `run-low-high-e2e.sh`, `validate-amd64.sh`, `validate-no-egress.sh` all call `resolve_container_runtime` at line 9/25
- `runtime_compose()` helper uses `${PULP_CONTAINER_RUNTIME} compose` (no hardcoding)
- README already correctly states it uses `${PULP_CONTAINER_RUNTIME} compose`

**Remaining blockers:** Host `ar` command for fixture generation (Wash in progress). All runtime-awareness issues resolved.

**2026-05-04T21:08:34Z - Phase 0 Documentation Reconciliation Complete**

All stale Podman-hardcode claims have been reconciled against verified script implementations. Decisions consolidated to decisions.md. Ready for Phase 1 operator documentation (operator CLI runbooks, state tracking guides, compliance evidence formatting).

**2026-05-04T21:42:09.450+00:00 - Phase 1 Local Operator Setup Documentation Complete**

**Artifact:** `docs/runbooks/phase-1-local-operator-setup.md`

**Content:** Customer-facing operator runbook bridging Phase 0 local harness to Phase 1 Azure platform foundation. Covers:
- System prerequisites and Docker/Podman runtime setup
- Private image configuration blocker (ACR mirroring deferred; local testing uses public images)
- Step-by-step local export/import workflow (low-side sync → export → high-side import → publish)
- Evidence package structure and validation commands
- Clear delineation: what is proven locally vs. deferred to Azure Phase 1 (Container Apps, PostgreSQL persistence, private networking, diagnostics, operator workflows)
- Troubleshooting for common Docker/Podman/volume/permission issues

**Design decisions reflected:**
- Application-first: focuses on Pulp behavior, not Azure infrastructure
- One-way transfers: low→high only, no feedback loop
- Private images: documented as blocker, not failure
- Evidence-driven: emphasizes JSON output and validation
- Operator-centric: clear instructions for running scripts, interpreting output, troubleshooting

**File paths verified:** All script references (`run-low-high-e2e.sh`, `generate-fixture.sh`, etc.) and documentation links (`phase-1-evidence-backbone.md`, etc.) confirmed to exist.

**Status:** Ready for operator consumption. No Azure-specific configuration or credentials included.

**2026-05-05T01:26:57.473+00:00 - Phase 1 Docs Accuracy Review (Book)**

I performed a Phase 1 runbook accuracy review against implementation, decisions, and validation evidence. Key findings:

- Documentation inconsistency: `PULP_PULL_POLICY` is documented in `docs/runbooks/phase-1-local-operator-setup.md` as `missing`, but the harness defaults and scripts use `never` (see `harness/local/env.example` and `harness/local/scripts/common.sh`). Update docs to reflect `PULP_PULL_POLICY=never` as the default for repeatable, offline testing and document `if-not-present` or `missing` as explicit connected-test options.
- Runtime guidance reconciled: scripts are runtime-aware (`PULP_CONTAINER_RUNTIME=auto`) and use `${PULP_CONTAINER_RUNTIME}` for compose/network commands; docs correctly note auto-detection but some legacy references to Podman-only remain (minor copy cleanup needed).
- Image supply-chain blocker: docs correctly mark private ACR mirroring as a Phase 1 Azure blocker; evidence and implementation show local POC with public images is possible but Azure validation requires tag+digest private references.
- Success/failure criteria: validation commands include expected values, but guidance should call out explicit exit codes, and negative-test expectations (e.g., import-check failure) are currently deferred to Azure; recommend adding explicit negative test cases to Phase 1 checklist.
- Visual validation: there is no rendered docs site or browser UI in the repo, so Playwright visual testing is not required.

Action items recommended to the team: standardize `PULP_PULL_POLICY` guidance, remove remaining Podman-only language, and add explicit negative test expectations to `phase-1-platform-milestone-test.md` or `phase-1-evidence-backbone.md`.

## Learnings

2026-05-05T01:40:36.497+00:00 - P1-A2 runbook updates

- Added operator-facing guidance for the `bundle_tools execute-export` command (flags, dry-run, JSON stdout contract, evidence artifacts, and recommended exit codes).
- Documented that the local Pulp harness precondition is required and that private-image mirroring remains a blocker for live end-to-end runs; --dry-run and image-free tests are acceptable validation lanes.

- **2026-05-05T04:42:06.081Z**: Scribe: created orchestration log and session log for pulpcli-requirements-planning; merged inbox (none present) and recorded per-agent notes.

2026-05-06T05:33:10.822+00:00 - Phase 2 planning started

- Created Phase 2 planning memo at docs/runbooks/phase-2-planning.md
- Created decision inbox note at .squad/decisions/inbox/book-phase-2-planning.md
- Added skill guidance at .squad/skills/manual-transfer/SKILL.md

# 2026-05-06T05:33:10.822+00:00 - Phase 2 planning inbox merged into .squad/decisions.md

- Scribe: merged phase-2 planning inbox into .squad/decisions.md

2026-05-06T20:27:01.226+00:00 - P2.1 manifest & custody review (Book)

- Verdict: APPROVE from Customer Enablement.
- Rationale: Custody fields, waiver representation, evidence outputs and gating are sufficiently defined for operator runbooks. Non-blocking clarifications requested: (1) example custody-record.json and template, (2) explicit waiver approver roles and signature verification procedure ref examples, (3) link custody-record schema and sample in runbooks.
- Action items: create docs/runbooks/phase-2-manual-transfer-checklist.md (custody template), add custody-record example in docs/runbooks, and add waiver sign-off template in docs/runbooks/phase-2-evidence-review.md.

- 2026-05-06T20:27:01.226+00:00: Scribe: merged decision inbox items into .squad/decisions.md (4 files) and created orchestration/session logs.
