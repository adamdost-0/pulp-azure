# Wash Phase 2 Planning Memo: Pulp-Native Transfer Automation

Date: 2026-05-06T05:33:10.822+00:00
Owner: Wash (Integration & Automation)

## Scope and Assumptions

- Phase 1 local apt sandbox + structured evidence are complete on `main`.
- Phase 2 starts with disconnected transfer rehearsal, not Azure platform redesign.
- Automation boundary stays at native `pulp-cli` + existing harness/bundle tooling (no custom Pulp API wrapper).

## Phase 2 Goal

Deliver a repeatable low-side to high-side rehearsal that proves: immutable repository version capture, generic Pulp core export/import, transfer manifest + custody handoff, idempotent reruns, and high-side publish/consume validation.

## Planned Workstreams

### 1) Generic Pulp core exporter/importer research and command contract

1. Confirm exact core CLI verbs/flags for exporter/importer lifecycle against target plugin/core versions.
2. Define minimal portable command set for low-side export and high-side import-check/import.
3. Record version-gated options and failure modes (unsupported flags, plugin mismatch, missing export path).

Deliverable: version-aware command matrix and execution contract embedded into runbook and bundle workflow plan.

### 2) Low-side/high-side rehearsal workflow

1. Stand up isolated low and high disposable sessions.
2. Low side: sync apt repo, capture immutable repository version href, run core export, stage transfer payload.
3. Transfer boundary: package payload + manifest + checksums + custody metadata for manual media handoff.
4. High side: run import-check, import, publish distribution, validate apt client consumption.
5. Capture structured evidence on both sides with one-way contract preserved.

Deliverable: executable rehearsal runbook flow and evidence package proving end-to-end transfer.

### 3) Repository version capture as first-class artifact

1. Persist `latest_version_href` and associated publication/distribution hrefs in manifested evidence.
2. Bind export payload metadata to exact repository version (never mutable "latest" semantics).
3. Require replay to reference captured immutable identifiers.

Deliverable: deterministic version-pinned transfer record for audit and repeatability.

### 4) Manifest and custody handoff contract

1. Extend transfer manifest contract with explicit custody fields (operator, timestamp, media identifier, checksum set).
2. Keep direction fixed: `low-to-high`; `feedbackToLowAllowed=false`.
3. Validate path containment, payload sizes, hashes, and schema before high-side import.
4. Keep custody handoff steps explicit for manual drive transfer while script-checkable.

Deliverable: operator-usable and machine-validated custody manifest contract.

### 5) Idempotent create/update semantics

1. For remotes/repos/distributions: `show -> create if absent -> update/reconcile if present`.
2. For publication/import operations: treat immutable outputs as new resources; prevent accidental overwrite.
3. Define deterministic exit classes for: validation/precondition/task failure/retryable transient.
4. Require rerun behavior documentation for partially completed workflows.

Deliverable: rerunnable workflow contract with predictable outcomes and explicit precondition errors.

## Pulp CLI Automation Boundary (Non-Negotiable)

- Orchestration may add validation, sequencing, manifests, and evidence.
- Content operations must remain native `pulp-cli` (deb + core exporter/importer).
- No custom Pulp REST wrapper layer introduced in Phase 2.

## Acceptance Criteria

1. A documented command contract exists for generic Pulp core export/import, including version gates and unsupported-option handling.
2. A full low-side/high-side rehearsal completes using native `pulp-cli` operations and produces structured evidence packages.
3. Every transfer run captures and persists immutable repository version href(s), export/import task href(s), and publication/distribution href(s).
4. Transfer manifests include checksum-verified payload index + custody metadata and are validated before import.
5. Re-running the same workflow on existing resources is idempotent (reconcile/update or explicit precondition failure), with deterministic exit classes.
6. High-side validation proves published content is consumable by isolated apt client without requiring high-side upstream egress.
7. One-way boundary is preserved: no high-to-low status feedback channel in automation behavior.
8. Evidence packages pass `harness/local/scripts/validate-evidence-structure.sh` and clearly map proof chain from sync/export to import/publish/consume.

## Phase 2 Risks and Mitigations

1. **Core export/import CLI option drift by Pulp version**  
   Mitigation: version discovery gate + command matrix + fail-fast unsupported-flag checks.
2. **Replay ambiguity from mutable resource references**  
   Mitigation: enforce immutable repository version capture and manifest pinning.
3. **Manual transfer custody gaps**  
   Mitigation: mandatory custody fields + hash verification at both staging and import.
4. **Non-idempotent reruns causing duplicate or divergent resources**  
   Mitigation: create/update reconciliation logic and immutable output handling rules.
5. **Boundary erosion via helper abstractions**  
   Mitigation: enforce native `pulp-cli` as content workflow boundary in code review gates.
6. **Evidence incompleteness across two environments**  
   Mitigation: structured evidence validation gate and runbook-required artifact checklist.

## Immediate Next Actions

1. Finalize core exporter/importer command research outputs for target Pulp versions.
2. Convert low/high rehearsal into an explicit executable checklist with failure-class mapping.
3. Define manifest custody schema additions and validation rules before implementation starts.
4. Align with River on validation gates and Simon on custody/boundary-sensitive transfer controls.
