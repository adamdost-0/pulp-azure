# River Phase 2 Validation Planning Memo

- Author: River (Tester / Validation Engineer)
- Date: 2026-05-06T05:33:10.822+00:00
- Context: Phase 1 changes are on `main`; planning Phase 2 validation gates before implementation.

## Mission

Phase 2 is approved only when we can repeatedly prove low-side and high-side disposable Pulp workflows, manual transfer custody, and apt client outcomes under success, failure, and recovery paths with structured evidence.

## Phase 2 Validation Gates

1. **Disposable Session Gate (Low-Side):**
   - Run disposable low-side session setup, solution execution, and publication path.
   - Require reproducible fixture + repository sync + publication outputs.
2. **Export Rehearsal Gate (Low-Side):**
   - Execute export workflow and generate transfer manifest/checksums.
   - Fail on direction violations, path traversal, checksum mismatch, or missing artifacts.
3. **Manual Handoff Gate (Disconnected Transfer):**
   - Rehearse removable-media transfer as an explicit operator step.
   - Verify one-way low-to-high contract and custody evidence.
4. **Import + Publish Gate (High-Side):**
   - Run high-side import-check, import, publication/distribution, and repository inspection.
   - Enforce no public egress for high-side automation.
5. **Apt Client Gate (High-Side):**
   - Validate isolated apt client install from high-side publication only.
   - Reject host apt mutations and reject fallback to public sources.
6. **Negative Matrix Gate:**
   - Mandatory failures: checksum mismatch, duplicate import, import-check rejection, task failure/timeout, missing prerequisites, high-side egress attempt, publication failure.
7. **Evidence Package Gate:**
   - Every run must produce `evidence/<session-id>/` with `README.md`, `manifest.json`, and grouped `apt/`, `fixture/`, `logs/`, `pulp/`, `report/`, `screenshots/`.
   - Playwright CLI capture is required for every test case; run `harness/local/scripts/validate-evidence-structure.sh` before claiming completion.
8. **Coverage + CI Gate:**
   - 100% line and branch coverage for Phase 2 application code.
   - CI path must split into feasible tiers: static/contract checks always-on, full disconnected e2e on self-hosted/nightly when private images or air-gap constraints apply.

## Validation Matrix

| ID | Scenario | Path Type | Expected Result | Required Evidence |
| --- | --- | --- | --- | --- |
| P2-VAL-01 | Low-side disposable setup + sync + publish | Connected/disposable | PASS | `pulp/` resource JSON, sync logs, Playwright screenshot/report |
| P2-VAL-02 | Low-side export rehearsal | Connected/disposable | PASS | export manifest/checksum artifacts in `logs/` + `fixture/` + README proof chain |
| P2-VAL-03 | Manual media handoff rehearsal | Manual/disconnected | PASS | custody steps + transfer manifest validation evidence in README + manifest index |
| P2-VAL-04 | High-side import-check + import + publish | Disconnected/disposable | PASS | import-check/import outputs, task state evidence, publication/distribution artifacts |
| P2-VAL-05 | High-side apt client install from published repo | Disconnected/client | PASS | `apt/sources.list`, `apt/release.txt`, `logs/apt-client.log`, Playwright evidence |
| P2-NEG-01 | Checksum mismatch on transfer bundle | Negative | FAIL (blocked import) | explicit failure logs + error classification in README |
| P2-NEG-02 | Duplicate import replay | Negative | FAIL (idempotency guard) | import rejection/task output + operator recovery note |
| P2-NEG-03 | High-side public egress attempt | Negative | FAIL (policy gate) | denied pull/source evidence + policy assertion |
| P2-NEG-04 | Task failure/timeout during sync/import | Negative | FAIL | task JSON/log evidence + retry/recovery outcome |
| P2-NEG-05 | Publication/distribution missing when client validates | Negative | FAIL | apt client failure evidence + missing publication proof |
| P2-COV-01 | Coverage discipline check | Quality gate | PASS only at 100% line+branch | CI coverage report + gate status |
| P2-CI-01 | CI feasibility tiers (PR vs nightly) | Operational gate | PASS | documented mapping of runnable PR checks vs deferred environment checks |

## Acceptance Criteria

1. All matrix items execute with deterministic commands/runbooks and produce structured evidence packages.
2. Low-side and high-side disposable sessions are both validated independently; success on one side cannot mask failure on the other.
3. Export/import rehearsal includes explicit manual handoff proof and one-way transfer integrity verification.
4. High-side apt client validation proves package consumption without host apt mutation or public-source dependence.
5. Negative tests are first-class release blockers, not advisory checks.
6. Every test has Playwright CLI evidence and passes `validate-evidence-structure.sh`.
7. Phase 2 code merges are blocked unless 100% line and branch coverage is met.
8. CI strategy is executable in real constraints (private images/air-gap) with no silent gaps between PR and full-environment validation.

## CI Feasibility Notes

- **PR-required (always runnable):** static validation, schema/contract tests, shell syntax, unit/integration tests that do not require private disconnected environments.
- **Nightly/self-hosted required:** full low/high disconnected rehearsal, manual handoff simulation, and high-side apt client e2e against staged private images.
- **Release gate:** no release promotion unless latest full disconnected suite and evidence package validation are green.

## Execution Discipline for Phase 2

- Treat “works once” as non-compliant.
- Require repeat runs with unique session IDs and comparable outputs.
- Keep evidence reviewer-first: README proof chain + machine index + grouped artifacts.
- Fail fast on boundary violations (directionality, containment, checksum, egress policy).
