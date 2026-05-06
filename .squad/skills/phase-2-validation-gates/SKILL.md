---
name: "phase-2-validation-gates"
description: "Plan and gate disconnected low/high Pulp workflow validation with audit-grade evidence"
domain: "quality"
confidence: "high"
source: "River Phase 2 planning memo, 2026-05-06T05:33:10.822+00:00"
---

## Context

Use this skill when planning or reviewing Phase 2 work for disconnected Pulp bundle workflows. It applies when success criteria must cover low-side disposable sessions, manual transfer custody, high-side import/publish, and apt client consumption with enforceable evidence.

## Patterns

- Define gates in sequence: low-side disposable workflow, export rehearsal, manual handoff, high-side import/publish, high-side apt validation, negative matrix, evidence package validation, coverage/CI.
- Keep one-way low-to-high semantics explicit and testable in both happy-path and negative-path checks.
- Require Playwright CLI output for every test case and validate package shape with `harness/local/scripts/validate-evidence-structure.sh`.
- Treat negative tests as release-blocking checks (checksum mismatch, duplicate import, import-check failure, task failure/timeout, high-side egress, publication/client failures).
- Enforce 100% line and branch coverage for application code and separate PR-feasible checks from disconnected nightly/self-hosted suites.

## Examples

- Matrix IDs:
  - `P2-VAL-*` for positive dual-side workflow checks.
  - `P2-NEG-*` for mandatory failure-mode checks.
  - `P2-COV-*` and `P2-CI-*` for quality/operational gates.
- Evidence package baseline:
  - `evidence/<session-id>/README.md`
  - `evidence/<session-id>/manifest.json`
  - grouped `apt/`, `fixture/`, `logs/`, `pulp/`, `report/`, `screenshots/`.

## Anti-Patterns

- Declaring Phase 2 readiness from low-side-only or status-only checks.
- Capturing artifacts without a reviewer-readable proof chain in README.
- Allowing public high-side egress in validation runs.
- Treating coverage thresholds below 100% as acceptable for merge.
