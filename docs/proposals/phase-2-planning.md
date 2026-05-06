# Phase 2 Planning Memo: Low-to-High Export/Import Rehearsal

Date: 2026-05-06T05:33:10.822+00:00  
Owner: Zoe, Lead / Solution Architect

## Executive Summary

Phase 1 proved the local apt path: Pulp CLI can configure a disposable Pulp
session, sync a deterministic apt repository, publish it, validate client
installation, and capture structured evidence. Phase 2 should not jump to Azure
infrastructure yet. The smallest coherent objective is a local two-side
low-to-high rehearsal that proves disconnected Pulp export/import using native
Pulp capabilities and the existing structured evidence standard.

**Recommendation:** Phase 2 is a local air-gap workflow proof, not an Azure
platform build. It must produce a one-way transfer package from a low-side Pulp
session, manually stage it into a high-side Pulp session, run `import-check`,
import, publish, validate apt consumption on the high side, and capture a single
reviewer-readable evidence package.

## Phase 2 Objective

Deliver a repeatable local workflow that proves:

1. Low-side apt content can be exported from a pinned Pulp repository version.
2. Transfer media contents are described by a thin manifest and validated before
   high-side import.
3. High-side automation can import, publish, and distribute the content without
   public package egress.
4. A high-side isolated apt client can install the expected package from the
   imported repository.
5. Evidence links low-side export, transfer manifest validation, high-side
   import-check/import tasks, publication, distribution, and apt client proof.

This is the minimum bridge between Phase 1 local Pulp CLI proof and later Azure
Commercial / Azure Government AirGap architecture.

## Scope Boundaries

### In Scope

- Two disposable local Pulp sessions: low side and high side.
- Native Pulp exporter/importer workflows for apt repositories.
- One-way local transfer staging that simulates manual media movement.
- Thin transfer manifest with batch metadata, expected direction, file inventory,
  sizes, SHA-256 values, and path containment validation.
- High-side `import-check` before import.
- High-side publication, distribution, apt client validation, and structured
  evidence.
- Explicit failure evidence for bad manifest direction, path traversal, checksum
  mismatch, and public high-side upstream configuration.

### Out of Scope

- Azure resources, Terraform/OpenTofu, AKS, Container Apps, VMs, ACR, private
  endpoints, Key Vault, or managed storage.
- Production TLS, repository signing, evidence signing, or HSM-backed custody.
- Additional package ecosystems beyond apt.
- Bidirectional receipts, callbacks, telemetry, or status return from high side
  to low side.
- Replacing Pulp state with a custom state store.
- Custom Pulp REST API wrapper.

## Architectural Decisions Needed

### 1. Phase 2 target shape: local two-side rehearsal

**Decision:** Use two disposable local Pulp sessions as the Phase 2 target.  
**Rationale:** Phase 1 evidence already proves the single-session apt path. The
next operational risk is disconnected export/import, not Azure provisioning.
Local two-side rehearsal isolates that risk without adding cloud, identity, or
networking variables.  
**Alternatives:** Start Azure Commercial deployment now; build operator service
first.  
**Why not:** Both add maintenance burden before the export/import contract is
proven.

### 2. Pulp remains system of record

**Decision:** Use native Pulp exporter/importer/task state as authoritative.  
**Rationale:** Existing decisions and upstream analysis show Pulp already tracks
repository versions, exports, TOCs, checksums, and import history. Phase 2 should
orchestrate and evidence these facts, not duplicate them.  
**Review gate:** Zoe rejects designs that add a custom Pulp API wrapper or a
parallel repository state database.

### 3. Transfer manifest is thin custody metadata

**Decision:** The Phase 2 manifest describes the transfer batch; it does not
reimplement Pulp TOC semantics.  
**Required fields:** batch ID, created timestamp, source side, target side,
repository identifier, repository version href, export href or task href, file
inventory, size, SHA-256, relative paths, and evidence references.  
**Rationale:** Pulp validates its own export payload. The project must add the
AirGap custody controls Pulp does not own: direction, staging path containment,
operator-readable batch identity, and reviewer traceability.

### 4. Evidence package is the release gate

**Decision:** Phase 2 is complete only when a structured evidence package proves
the full low-to-high chain.  
**Rationale:** Phase 1 succeeded because evidence was reviewer-readable and
machine-indexed. Phase 2 raises the bar by adding transfer and import proof.  
**Required package additions:** `transfer/` for manifest and validation outputs,
`low-side/` and `high-side/` groupings or equivalent manifest group labels,
while preserving `README.md`, `manifest.json`, `apt/`, `fixture/`, `logs/`,
`pulp/`, `report/`, and `screenshots/` expectations.

### 5. Azure planning waits for this gate

**Decision:** Azure Phase 3 planning may begin only after Phase 2 export/import
rehearsal passes and target Azure Government/AirGap SKU questions are answered.  
**Rationale:** Cloud topology choices depend on content flow, custody, signing,
retention, and high-side egress constraints. Those are not yet product-owner
closed.

## Sequencing

### P2.0: Confirm Pulp core export/import contract

Owner: Wash  
Reviewer gates: Zoe, River

- Research exact `pulp-cli` core exporter/importer commands available in the
  selected Pulp image.
- Prove the selected image supports apt `pulpexport` capability.
- Document command contract and plugin/version gates.
- Do not write application code beyond disposable validation scripts if needed.

### P2.1: Define transfer manifest and custody rules

Owner: Simon  
Reviewer gates: Zoe, River, Book

- Define the minimal manifest schema and negative controls.
- Include direction, path containment, size, SHA-256, and no high-to-low feedback
  invariants.
- Define what evidence is required for operator custody.

### P2.2: Build local two-side workflow plan

Owner: Kaylee  
Reviewer gates: Zoe, Wash, Simon

- Extend the existing solution/workflow planning model to represent low-side
  export, transfer staging, high-side import-check, import, publish, and client
  validation.
- Keep orchestration thin around native Pulp CLI.
- Preserve idempotent precondition failures over silent mutation.

### P2.3: Validate high-side behavior and failures

Owner: River  
Reviewer gates: Zoe, Simon

- Run positive e2e validation with two disposable sessions.
- Run negative checks for checksum mismatch, path traversal, wrong direction,
  missing export files, and high-side public source references.
- Validate evidence structure before approval.

### P2.4: Write operator runbook and review checklist

Owner: Book  
Reviewer gates: Zoe, Simon, River

- Write the operator path from low-side export to high-side import validation.
- Include manual transfer assumptions, expected artifacts, rollback/cleanup, and
  evidence review checklist.
- Avoid Azure claims until Phase 2 gate passes.

### P2.5: Architecture closeout

Owner: Zoe  
Reviewer gates: all specialists

- Review evidence and unresolved decisions.
- Decide whether Azure deployment planning can start.
- Create or update ADRs if Phase 2 changes the architecture boundary.

## Gating Criteria

Phase 2 is accepted only when all gates pass:

1. **Export gate:** Low-side export references a specific Pulp repository version
   and captures task/export/TOC or equivalent Pulp output.
2. **Transfer gate:** Manifest validation proves direction, path containment,
   size, SHA-256, and complete file inventory before import.
3. **AirGap gate:** High-side automation uses only staged transfer contents and
   contains no public package source URLs.
4. **Import-check gate:** High side runs Pulp import-check or the closest
   supported native preflight and records the output.
5. **Import gate:** High side imports successfully and records task output,
   repository version, publication, and distribution resources.
6. **Client gate:** Isolated high-side apt client installs the expected package
   from the high-side Pulp distribution without mutating host apt config.
7. **Negative gate:** At least four negative cases fail closed with evidence:
   checksum mismatch, path traversal, wrong direction, and high-side public egress
   configuration.
8. **Evidence gate:** Structured evidence package validates and starts with a
   human-readable README plus machine-readable manifest.
9. **Review gate:** Zoe, Simon, River, Wash, Kaylee, and Book either approve or
   record concrete blockers.

## Delegation Plan

| Agent | Delegated responsibility | Zoe review focus |
| --- | --- | --- |
| Wash | Pulp core export/import command research and local runtime feasibility. | Native Pulp usage, no wrapper, image/plugin compatibility. |
| Kaylee | Workflow/CLI planning for executable low-to-high steps. | Thin orchestration, explicit handoffs, no Azure creep. |
| Simon | Security controls for transfer manifest, custody, direction, and no high-side public egress. | Fail-closed behavior and AirGap invariants. |
| River | Validation strategy, positive/negative tests, structured evidence package. | Evidence completeness and reproducibility. |
| Book | Operator runbook, review checklist, and troubleshooting. | Customer setup friction and clear operational handoffs. |

## Assumptions

- Phase 1 changes are merged to `main`; current local status shows work is on
  `main` with an unrelated `.squad/identity/now.md` modification not owned by
  this memo.
- Apt remains the only mandatory Phase 2 package ecosystem.
- The selected local Pulp image includes `pulp_deb` and supports generic Pulp
  export/import for apt repositories, subject to Wash verification.
- Local transfer staging is an acceptable simulation for manual media movement
  during Phase 2.
- Structured evidence remains mandatory for every validation claim.
- Azure deployment planning is desirable but must not precede the export/import
  proof gate.

## Unresolved Product-Owner Questions

1. Is apt-only sufficient for the first customer-facing accelerator, or must rpm,
   Python, NuGet, containers, or generic files enter the Phase 2/3 backlog?
2. What is the target scale: repository count, artifact count, artifact size,
   export size, sync cadence, retention window, and recovery time objective?
3. What physical or logical media custody process must the manifest support?
4. Are manifest signing, evidence signing, and apt repository signing required for
   the next gate or deferred to Azure production hardening?
5. What is the required high-side deployment environment: Azure Government,
   disconnected Azure Stack Hub, customer-managed VMs, AKS, Container Apps, or
   another approved platform?
6. What identities and RBAC roles exist for low-side operator, transfer custodian,
   high-side operator, auditor, and break-glass administrator?
7. What evidence retention, redaction, and immutable storage rules apply?
8. What failure semantics are expected for duplicate imports, partial imports,
   task cancellation, and rollback?
9. Which private image registry and pinned image digests are approved for high-side
   use?
10. What formal reviewer sign-off is required before Azure architecture work
    resumes?

## Risks and Mitigations

### Risk: Pulp export/import CLI support differs from assumptions

Likelihood: Medium. Impact: High.  
Mitigation: Make P2.0 a hard gate before manifest or workflow implementation.

### Risk: Phase 2 expands into Azure too early

Likelihood: Medium. Impact: High.  
Mitigation: Treat Azure work as out of scope until local two-side evidence passes.

### Risk: Manifest duplicates Pulp checksum/TOC behavior

Likelihood: Medium. Impact: Medium.  
Mitigation: Keep the manifest focused on custody, direction, and staging
validation. Reference Pulp outputs instead of replacing them.

### Risk: High-side validation accidentally uses public egress

Likelihood: Medium. Impact: High.  
Mitigation: Add a negative gate for public high-side source URLs and require
River/Simon review before acceptance.

### Risk: Evidence becomes too fragmented for review

Likelihood: Medium. Impact: Medium.  
Mitigation: Preserve the structured evidence pattern and make the README proof
chain the primary review entry point.

## Final Recommendation

Start Phase 2 with a narrow local two-side Pulp export/import rehearsal. Do not
start Azure implementation yet. The next architecture review should happen after
Wash proves the native export/import command contract and Simon/River approve the
manifest and evidence gates.
