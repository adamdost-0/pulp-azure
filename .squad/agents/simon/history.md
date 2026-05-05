# Project Context

- **Owner:** adamdost-0
- **Project:** This solution helps deliver the Pulp Project in Azure Commercial and Azure Government AirGap environments.
- **Stack:** Azure Commercial, Azure Government, AirGap operations, Pulp, Azure 1P PaaS, IaC/automation and customer setup guidance.
- **Created:** 2026-05-04T15:03:33.394+00:00

## Core Context

Simon owns security, compliance, and AirGap boundary review for a customer accelerator that transfers Pulp bundles from Azure Commercial into disconnected government environments using removable media.

## Learnings

### 2026-05-04 — Phase 1 Control Review Complete

**Date:** 2026-05-04T21:42:09.450+00:00
**Status:** CONTROL_FINDINGS
**Scope:** Application-first direction validation for Phase 1 (issues #8–#14)

**Key Findings:**

#### Control Architecture Sound
- Phase 1 design (`design.md`) correctly separates secrets (Key Vault), images (private ACR), transfers (one-way low→high), and audit (PostgreSQL append-only)
- Evidence contract (`phase-1-evidence-backbone.md`) is prescriptive and actionable
- Phase 1 issue specs (#8–#14) align with control requirements

#### Blocking Controls (No Override, No Warning)
1. Public registry pull in runtime config → AirGap boundary
2. Checksum validation failure → batch rejected entirely
3. Embedded credentials in code/IaC → incident
4. Bidirectional sync → violates transfer design
5. State machine bypass (e.g., publish without import) → data integrity
6. Duplicate import success → idempotency violation

#### Warned + Audited Controls (Override Allowed)
1. Pulp version mismatch (low-high compatibility) → warn, require override with audit entry
2. Ubuntu expansion beyond 22.04 (MVP scope) → warn, require override
3. Plugin version mismatch → warn, require override

#### Ownership Model Clear
- **Wash (automation/app):** Application state machine, manifest validation, startup guards, Pulp task error handling, audit logging, Key Vault secret integration
- **River (validation):** Startup failure tests, state machine concurrency tests, private networking validation, manifest checksum failure injection, duplicate import rejection, backup/restore drill, endpoint DNS validation
- **Book (IaC):** PostgreSQL schema (audit table immutability, state transitions, constraints), private endpoints, private DNS, endpoint suffix parameterization, Key Vault access policy, RBAC, tags, CMK configuration

#### No Python Wrapper Required
- Confirmed design explicitly prohibits external Python wrapper around Pulp API
- All Pulp interactions via orchestration layer; no external library calls
- Audit trail enforced in-application only

#### Critical Files Reviewed
- `openspec/changes/airgap-binary-hydration-service/design.md` — decision anchors
- `phase-1-evidence-backbone.md` — evidence contract and controls.json schema
- `phase-1-{azure-platform-foundation,image-supply-chain,private-networking-dns,postgresql-foundation,diagnostics-operations,pulp-runtime-topology,platform-milestone-test}.md` — issue-specific requirements
- `harness/local/README.md` and `env.example` — Phase 0 proof baseline; .env placeholder pattern confirmed safe
- `.squad/decisions.md` — Phase 0 and Phase 1 decision history
- `.copilot/skills/secret-handling/SKILL.md` — credential leak prevention pattern confirmed

**Risks Mitigated:**
- No hardcoded secrets if Key Vault integration is validated in River tests
- No public image pulls if ACR-only deployment is validated in River tests
- No data loss if PostgreSQL transaction enforcement and backup/restore tested in River
- No high-side internet access if NSG/UDR rules validated in River
- No lost audit if database immutability enforced in schema

**Decision Required:**
- Confirm Wash, River, Book ownership model and evidence responsibilities before Phase 1 start
- Explicit approval of "warn + override" vs "hard block" classification for version mismatches

**Output Artifact:**
- `.squad/decisions/inbox/simon-phase1-control-review.md` — full control matrix with evidence requirements

### 2026-05-05 — Phase 1 Control Accuracy Review

**Date:** 2026-05-05T01:26:57.473+00:00
**Status:** CONTROL_CORRECTIONS_APPLIED
**Scope:** Phase 1 bundle tools, local harness, tests, docs, and OpenSpec control alignment

**Learnings:**
- Inline local harness credentials must remain operator-supplied in uncommitted `.env`; committed examples may document variable names but must not provide reusable password values.
- One-way boundary checks must reject both explicit high-to-low fields and any `feedbackToLowAllowed` value other than `false`, including nested workflow-boundary metadata.
- Manifest path containment must treat symlinks as invalid, not merely reject absolute paths or `..`, because removable-media payloads need auditable file boundaries.
- Phase 1 documentation may cite public images only as connected-side source baselines; high-side and air-gap validation evidence must use pre-loaded/private mirror or private ACR tag-plus-digest references.


### 2026-05-05 — Phase 1 Definition of Done Security Review

**Date:** 2026-05-05T01:42:22.430+00:00
**Status:** BLOCKERS_IDENTIFIED
**Scope:** Phase 1 definition of done / definition of ready security and compliance assessment for low-side and high-side Pulp delivery

**Key Findings:**
- Phase 1 is architecturally on the right path: private ACR, private endpoints, Key Vault, managed identity, CMK-aware services, append-only audit, and negative public-reference tests are all appropriate foundations.
- The current DoD is not sufficient for FedRAMP High / IL4-IL6 closeout because checksum-only transfer validation does not prove authenticity or non-repudiation across removable-media/CDS movement.
- High-side “zero public dependency” proof needs runtime DNS, route, flow-log, denied-egress, and proxy/package-manager fallback evidence, not only static configuration scans.
- Data boundary controls need an explicit transfer record covering classification, custody, media handling, release/scanning reference, operator approvals, evidence redaction, and final media disposition.
- Identity, RBAC, Key Vault, and CMK controls need machine-readable matrices with exact scopes, key lifecycle, backup/restore inheritance, waiver owner, and waiver expiry.
- Auditor readiness requires FedRAMP/NIST/DoD SRG control mapping, shared-responsibility statements, SSP-ready diagrams, waiver/POA&M handling, and an auditor-facing README in evidence packages.

**Decision Artifact:**
- `.squad/decisions/inbox/simon-phase1-security-review.md`

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to Simon; decisions.md updated.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to Simon; decisions.md updated.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to Simon; decisions.md updated.

### 2026-05-05 — P1-A2 Execute-Export Control Review

**Date:** 2026-05-05T01:40:36.497+00:00
**Status:** ACCEPTED_WITH_CONTROL_CORRECTIONS
**Scope:** `bundle_tools execute-export`, tests, and operator documentation

**Learnings:**
- P1-A2 is acceptable only as a low-side, image-free execution lane; it does not prove high-side import/publish, no-egress behavior, G2, or G3 readiness.
- Dry-run must still prove the local low-side Pulp status precondition. Treating an unreachable Pulp endpoint as planned success masks a boundary/control failure.
- Operator-supplied URLs are secret surfaces. Reject embedded credentials in `--pulp-url` and `upstreamUrl`, and redact Pulp error bodies before writing evidence or summaries.
- Plan-file inputs need the same symlink-escape posture as evidence directories because imported plans can alter boundary semantics before execution.

**Decision Artifact:**
- `.squad/decisions/inbox/simon-p1-a2-control-review.md`
