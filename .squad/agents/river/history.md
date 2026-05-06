# Project Context

- **Owner:** adamdost-0
- **Project:** This solution helps deliver the Pulp Project in Azure Commercial and Azure Government AirGap environments.
- **Stack:** Azure Commercial, Azure Government, AirGap operations, Pulp, Azure 1P PaaS, IaC/automation and customer setup guidance.
- **Created:** 2026-05-04T15:03:33.394+00:00

## Core Context

River owns validation for Azure deployment, Pulp bundle workflows, manual removable-media transfer, and customer setup paths.

## Learnings

- 2026-05-05T01:45:46.172+00:00: Built deployment-skill review checklist for single bundled Pulp OCI container coverage. Validation must fail if the skill stops at container health, uses unpinned/latest images in automation, hardcodes CONTENT_ORIGIN, omits SECRET_KEY/admin reset/deploy-check/worker/plugin checks, ignores SELinux/FUSE/permission/name/port/disk/migration failures, or allows public pulls in air-gap mode. Battle-ready review evidence should include pinned image identity, redacted settings, run command, status JSON, deploy-check output, worker state, CLI auth verification, plugin setup, bundle import smoke evidence, and negative-test findings.

Initial setup complete.
- 2026-05-05T01:42:22.430+00:00: Phase 1 DoD review found partial automation only. `phase1_validation.py` validates evidence file shape, manifest integrity, one-way semantics, and harness static contracts, but does not automatically verify most control assertions, issue-specific capability proofs, or the backbone’s negative matrix execution evidence. #14 gate wording is strong, yet testability needs explicit dual-side pass criteria and executable checks proving low-side and high-side can each fail independently.
- 2026-05-05T01:40:36.497+00:00: Added P1-A2 contract-first validation artifacts: new `tests/phase1/test_p1a2_execution.py` and deterministic fixtures under `tests/fixtures/p1a2/` covering execute-export parser/help, dry-run expectations, low-side-only boundary, feedback rejection, Pulp precondition handling, task failure/timeout propagation, evidence containment, and no high-to-low receipt fields. Full suite now intentionally blocks on missing `execute-export` implementation (`invalid choice: execute-export`), providing clear failure targets for Wash.
- 2026-05-05T01:40:36.497+00:00: Closed P1-A2 validation lane after Wash landed `execute-export`. Tightened contract checks to require deterministic precondition/task exit codes (`3` and `4`), added fake-Pulp success validation for required evidence artifacts, and added explicit rejection coverage for non-`low-to-high` transfer direction.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to River; decisions.md updated.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to River; decisions.md updated.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to River; decisions.md updated.
- 2026-05-05T04:36:44.030+00:00: Local harness static validation passes on Docker hosts (`validate-static.sh`), but disposable-session setup currently blocks at admin reset because `pulpcore-manager reset-admin-password` in `pulp/pulp:3.21` rejects `--username`; without `session.env`, downstream run/validate/capture scripts fail immediately and no `evidence/local-apt-smoke/` artifacts are created.
[2026-05-05T04:36:44Z] river: Appended inbox decision and reported reset-admin-password compatibility block.

- **2026-05-05T04:42:06.081Z**: Scribe: created orchestration log and session log for pulpcli-requirements-planning; merged inbox (none present) and recorded per-agent notes.
- 2026-05-06T05:33:10.822+00:00: Drafted `.squad/agents/river/phase-2-validation-planning-memo.md` to define Phase 2 validation gates across low/high disposable sessions, export/import rehearsal, high-side apt client validation, negative matrix, structured evidence package requirements (`evidence/<session-id>/` + `validate-evidence-structure.sh`), CI feasibility tiers, and 100% line/branch coverage discipline.

# 2026-05-06T05:33:10.822+00:00 - Phase 2 planning inbox merged into .squad/decisions.md

- Scribe: merged phase-2 planning inbox into .squad/decisions.md
- 2026-05-06T20:27:01.226+00:00: Drafted `docs/proposals/p2.0-p2.1-validation-gates.md` to make P2.0 command-contract checks and P2.1 manifest/custody controls immediately testable, including mandatory negatives (direction, traversal, checksum, symlink escape, missing export file, high-side egress, signature/waiver failures), Playwright evidence rules, and PR-static vs disconnected e2e lane split.

- 2026-05-06T20:26:13.550+00:00: Scribe: merged your inbox decision into .squad/decisions/decisions.md and recorded orchestration logs.
