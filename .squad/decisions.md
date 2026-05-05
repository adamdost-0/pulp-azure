# Decisions

## 2026-05-04 — Phase 0 Docker-Local Burndown APPROVED

**Date:** 2026-05-04T21:08:34Z
**Author:** Zoe (Lead / Solution Architect)
**Status:** APPROVED — Phase 0 Docker-compatibility reviewer gate passed.
**Scope:** Local Pulp harness Docker runtime support for development when Podman unavailable.

### Verdict: APPROVE

The Phase 0 Docker-local burndown satisfies the original request: "use localhost Docker because Podman is missing."

### Implementation Summary

#### Runtime Portability (✅ PASS)
- All scripts use `resolve_container_runtime` → `$runtime` pattern; no bare `podman` calls
- `common.sh` helpers: `runtime_compose()`, `runtime_network_exists()`, `resolve_pulp_single_image()` — all runtime-agnostic
- `env.example` defaults to `PULP_CONTAINER_RUNTIME=auto` (resolves Podman first, falls back to Docker)

#### Script Updates (✅ PASS)
- `run-e2e.sh`: Replaced `require_cmd podman` with `require_cmd "${PULP_CONTAINER_RUNTIME}"`; all 8 bare `podman` calls → `${PULP_CONTAINER_RUNTIME}`
- `run-low-high-e2e.sh`: Replaced `require_cmd podman` with runtime check; 10 bare `podman` calls → `${PULP_CONTAINER_RUNTIME}`; network branching at step 7 (PRIMARY_NETWORK vs CONTAINER_NETWORK) is runtime-correct
- `validate-amd64.sh`, `validate-no-egress.sh`: Runtime-agnostic; `--internal` network flag supported by both Docker and Podman
- `init-assets.sh`, `generate-manifest.sh`: No bare runtime assumptions

#### Fixture Generation (✅ PASS)
- `generate-fixture.sh` builds deterministic local APT fixture with Python stdlib (no host `ar` dependency)
- Docker-only harness hosts no longer blocked by missing `ar` utility

#### Documentation (✅ PASS)
- README documents auto-detect behavior, Docker path, low/high topology, evidence layout
- `docs/local-dev-docker-backlog.md` accurately reflects current state
- SKILL.md documents both skills (low-single, low-high-export) with anti-patterns

#### Environment Defaults (✅ PASS)
- `PULP_CONTAINER_RUNTIME=auto` — auto-detection
- `PULP_PULL_POLICY=missing` — correct for local dev with public images
- `PULP_SINGLE_IMAGE`, `APT_CLIENT_IMAGE` — placeholders; real values required for full e2e

### Remaining External Blockers (Not actionable without private registry access)

1. **Full e2e execution** — `run-e2e.sh` and `run-low-high-e2e.sh` require real `PULP_SINGLE_IMAGE` and `APT_CLIENT_IMAGE` values (internal ACR or private registry with digests)
2. **Compose-mode validation** — `PULP_E2E_MODE=compose` path requires `PULP_IMAGE`, `PULP_WEB_IMAGE`, `POSTGRES_IMAGE`, `REDIS_IMAGE` configuration

### Scope Safety

No scope creep detected. Burndown stayed within harness scripts + documentation. No application code written or modified. No Azure infrastructure touched.

---

## 2026-05-04 — Local Harness Supports Docker Fallback

**Date:** 2026-05-04T21:08:34.767+00:00
**Owner:** Kaylee (Platform)
**Decision:** Phase 0 local Pulp harness supports `PULP_CONTAINER_RUNTIME=auto`, selecting Podman when installed and Docker when Podman unavailable.

**Rationale:** Active development host has Docker 29.3.1 and Docker Compose v5.1.1 available, while Podman is missing. Hardcoded Podman calls block local validation, so runtime selection belongs in `harness/local/scripts/common.sh` and callers avoid bare `podman`/`docker` assumptions.

**Validation:** Shell syntax check, Docker runtime auto-detection, Docker Compose config parsing for `harness/local/compose.pulp.yaml`, Docker internal no-egress network behavior validated.

---

## 2026-05-04 — Docker Local Automation Support

**Date:** 2026-05-04T21:08:34.767+00:00
**Owner:** Wash (Automation)
**Decision:** Phase 0 local Pulp harness supports `PULP_CONTAINER_RUNTIME=auto`, resolving Podman first and falling back to Docker when unavailable.

**Consequences:**
- Harness scripts call resolved runtime variable or shared helpers instead of bare `podman`/`docker` commands
- Compose operations use `${PULP_CONTAINER_RUNTIME} compose` through `runtime_compose()` helper
- Full Pulp container e2e remains gated on private/internal image references in `harness/local/.env`

---

## 2026-05-04 — Portable Fixture Generation Avoids Host ar

**Date:** 2026-05-04T21:08:34.767+00:00
**Owner:** Wash (Automation)
**Decision:** `harness/local/scripts/generate-fixture.sh` builds the deterministic local APT fixture archive with Python stdlib instead of calling host `ar`.

**Rationale:** Docker-only harness hosts may not include `ar`, and fixture generation must be repeatable before local Pulp E2E workflows start.

**Impact:** Fixture workflow maintains same generated package/repository shape while relying on script's existing Python requirement for archive assembly.

---

## 2026-05-04 — River Local Validation Decision

**Date:** 2026-05-04T21:08:34.767+00:00
**Owner:** River (Validation)
**Scope:** Phase 0-2 local Docker-on-localhost validation for Pulp Core development.

**Decision:** Local development readiness requires multi-gate validation:
1. Docker daemon and Docker Compose availability
2. Compose config rendering for `harness/local/compose.pulp.yaml` with private/tag-plus-digest image references
3. Single-container Pulp readiness on `localhost`, including `/pulp/api/v3/status/`, online workers, expected versions
4. Runtime-agnostic Phase 0 script execution (Docker, not Podman-only)
5. Low/high export-import evidence from `run-low-high-e2e.sh` or Docker equivalent
6. Negative checks: missing images, public/tag-only refs, checksum mismatch, high-side egress, import failure, duplicate import, publication/APT client failure

**Evidence Observed:**
- `harness/local/README.md` documents harness, low/high topology, evidence layout
- `harness/local/compose.pulp.yaml` renders successfully with Docker Compose
- `start-single-container.sh` accepts `PULP_CONTAINER_RUNTIME=docker`, reaches localhost Pulp status
- e2e/validation scripts updated to use runtime variable instead of bare `podman`
- Host missing `ar` no longer blocks fixture generation (Python solution implemented)

---

## 2026-05-04 — Local Development Documentation Review

**Date:** 2026-05-04T21:08:34.767+00:00
**Owner:** Book (Customer Enablement Writer)
**Status:** COMPLETE
**Scope:** Phase 0-2 local dev documentation reconciliation after Docker/Podman runtime-aware fixes.

**Summary:** Phase 0-2 docs assumed Podman. README and validation scripts hardcoded Podman requirements. Infrastructure supports Docker on localhost if scripts respect `PULP_CONTAINER_RUNTIME` configuration variable.

**Actions Completed:**
1. Updated README to acknowledge Docker Desktop as supported alternative
2. Added Docker Desktop quick-start for macOS/Windows
3. Documented `PULP_CONTAINER_RUNTIME` variable usage
4. Separated platform-specific guidance into organized sections
5. Created `docs/local-dev-docker-backlog.md` reflecting current validated state

**Technical Feasibility:** ✅ PASS — `compose.pulp.yaml` uses v3+ standard syntax (compatible with both runtimes); most `podman` CLI commands have direct `docker` equivalents; FUSE device mounts work on Docker Desktop.

---

## 2026-05-04 — Application Architecture First — Defer Azure Deployment

**Date:** 2026-05-04T00:00:00Z
**Source:** adamdost-0 (User Directive)
**Decision:** Phase 1 focus 100% on application configuration and verifying APT package export/import via air-gap-like local means. Do NOT rush to Azure/Bicep deployment.

**Rationale:** Build strong foundational application architecture before migrating to Azure. Empty `src/bundle-tools/`, empty `tests/e2e/`, and no orchestration/state management means team is not ready for cloud deployment.

---

## 2026-05-04 — One-Way Transfers, No Python Wrapper Over Pulp

**Date:** 2026-05-04T00:00:00Z
**Source:** adamdost-0 (User Directive)
**Decision:** Transfers always one-way (low→high). No feedback from high to low. Do NOT build Python wrapper around Pulp's API.

**Rationale:** Pulp already has `pulp-cli` and REST API. Application layer orchestrates Pulp's existing tools, not re-wrapping them. Avoid unnecessary abstraction; focus on workflow orchestration using proven Pulp capabilities.

---

## 2026-05-04 — Project Structure and Layout

**Date:** 2026-05-04T00:00:00Z
**Author:** Zoe (Lead / Solution Architect)
**Decision:** Foundational structure for Pulp Azure Commercial and AirGap accelerator:
- `infra/bicep/`: Azure 1P PaaS deployment templates (Bicep prioritized)
- `docs/architecture/` & `docs/runbooks/`: Operator docs and design references
- `src/bundle-tools/`: Data hydration and export tooling crossing AirGap boundary
- `tests/e2e/`: Validation and security testing

**Implications:** Explicit separation between control plane definition (infra), data gravity tooling (src), and human-in-the-loop workflows (docs).

---

## 2026-05-04 — Pulp Capability Analysis — What We Build vs. What Pulp Gives Us

**Date:** 2026-05-04T00:00:00Z
**Author:** Zoe (Lead / Solution Architect)
**Summary:** Pulp already covers checksum generation, state tracking, incremental exports, chunking, and publication. Custom code should NOT replicate these.

**Key Findings:**
- **Checksum**: Pulp's TOC + import verification ensures file integrity end-to-end. Custom wrapper unnecessary.
- **State Tracking**: Pulp IS the state store. `GET /exporters/.../exports/` and `GET /importers/.../imports/` provide full history. No separate persistence layer needed.
- **Incremental Exports**: `POST .../exports/ with full=false` exports only artifacts since `last_export`. Free capability.
- **Chunked Exports**: Pulp handles splitting large exports into manageable files natively.

**Application Layer (What We Build):**
- Automated scheduling (sync/export on cron/interval)
- Transfer manifest generation (JSON batch descriptor + SHA256 for media transfer)
- Transfer manifest validation on high side before import
- State tracking ACROSS air gap (batch IDs, statuses, timestamps in operator format)
- Operator visibility (batch status, history, pending items)
- Evidence generation (structured audit trail)

**Verdict:** Do NOT build custom Pulp client. Call `pulp-cli` or REST API directly. Thin orchestration shell only.

---

## 2026-05-04 — Revised Milestones — No Pulp Wrapper, Lean Orchestration

**Date:** 2026-05-04T00:00:00Z
**Author:** Zoe (Lead / Solution Architect)
**Decision:** Replace heavy M1–M6 with lean orchestration shell around Pulp's existing tools.

**Why Previous Wrapper Was Wrong:**
1. Pulp already ships `pulp-cli` (maintained, typed CLI covering all REST endpoints)
2. REST API stable and well-documented; `pulp-cli` or `pulpcore-client` (auto-generated) exist
3. `run-low-high-e2e.sh` proves workflow with nothing but `curl` calls — no custom wrapper needed
4. Custom wrapper becomes maintenance liability; `pulp-cli` tracks Pulp releases

**New Architecture — Thin Orchestration Shell:**
Operator CLI (`bundle_tools`) + orchestration scripts call `pulp-cli`/REST API, never reimplementing Pulp capabilities. Manifest, state tracker, and evidence generation tools wrap Pulp's output in operator-friendly format.

---

## 2026-05-04 — Phase 1 Redirect — Application-First Burndown

**Date:** 2026-05-04T00:00:00Z
**Author:** Zoe (Lead / Solution Architect)
**Directive:** All Azure Bicep/IaC work deferred. Immediate focus: application layer blockers.

**Immediate Blockers Fixed:**
- ✅ `run-low-high-e2e.sh` no longer hardcodes `podman` (runtime variable support)
- ✅ Local `.env` created with Docker Hub defaults for dev
- ✅ All `harness/local/scripts/*.sh` audited and updated

**Phase 0-2 Local Dev Backlog Priority:**
0.1–0.5 (Kaylee, parallel) → 0.7 (Wash) → 0.6 (River, gate) → Phase 1.1–1.8 (sequential) → Phase 2.1+ (deferred until Phase 1 passes)

---

## 2026-05-04T00:00:00Z - Project Structure
Created foundational project structure including infra, src, docs, and test directories as per user setup request.
# Phase 1 Application-First Breakdown

**Date:** 2026-05-04T21:42:09Z
**Author:** Zoe (Lead / Solution Architect)
**Status:** APPROVED
**Scope:** Reconcile OpenSpec Phase 1 files with app-first directive; produce actionable backlog.

---

## Decision

Phase 1 is split into two tracks:

1. **Track A — Application Layer (actionable now):** `bundle_tools` CLI scaffolding, manifest tooling, evidence generation, and local e2e validation using the existing harness.
2. **Track B — Azure Platform Foundation (deferred):** All OpenSpec Phase 1 items (issues #8–#14) remain valid design specs but implementation is blocked until Track A passes its readiness gate.

No Azure/Bicep work begins until the application layer can orchestrate the full low→high workflow locally without bash in the critical path.

---

## Classification of All Phase 1 Items

### ACTIONABLE NOW — Application Layer (Track A)

| ID | Title | Owner | Depends On | Acceptance Gate |
|----|-------|-------|------------|-----------------|
| P1-A1 | `bundle_tools` CLI scaffold + project structure | Kaylee | None | `src/bundle-tools/` exists with CLI entry point (`python3 -m bundle_tools --help` works), zero Pulp reimplementation |
| P1-A2 | `bundle_tools` export workflow execution | Kaylee | P1-A1 | Calls `pulp-cli` or REST API to trigger sync + export; returns export task ID and TOC path; tested against local harness |
| P1-A3 | Transfer manifest generation (`bundle_tools` manifest create) | Kaylee | P1-A2 | Produces JSON batch manifest with batch ID, timestamp, checksums (read from Pulp export `output_file_info`), repo metadata; schema documented |
| P1-A4 | Transfer manifest validation (`bundle_tools` validate-manifest) | Kaylee | P1-A3 | Validates manifest checksums against staged files; returns pass/fail with structured error output; tested with corrupt file negative case |
| P1-A5 | `bundle_tools` import workflow execution | Kaylee | P1-A4 | Calls `import-check` then `import` via REST/CLI; validates manifest first; returns import task ID; tested against local harness |
| P1-A6 | `bundle_tools` publish workflow execution | Kaylee | P1-A5 | Creates AptPublication + AptDistribution via REST/CLI; returns publication URL; tested against local harness |
| P1-A7 | Evidence generation (`bundle_tools` evidence collect) | Kaylee | P1-A6 | Writes structured JSON audit record (batch ID, timestamps, checksums, task IDs, pass/fail) to `evidence/` directory |
| P1-A8 | `bundle_tools` status command — operator visibility | Kaylee | P1-A5 | Queries Pulp export/import history; displays batch state in operator-friendly format (table or JSON) |

### BLOCKED — Private/Internal Image References

| ID | Title | Owner | Blocker | Resolution Path |
|----|-------|-------|---------|-----------------|
| P1-B1 | Full e2e harness execution | River | `PULP_SINGLE_IMAGE` and `APT_CLIENT_IMAGE` require internal ACR or private registry values | Provide real image references in `.env`; until then, Track A tests use mock/stub or public dev images |
| P1-B2 | Compose-mode multi-container validation | River | `PULP_IMAGE`, `PULP_WEB_IMAGE`, `POSTGRES_IMAGE`, `REDIS_IMAGE` unresolved | Deferred until private registry access confirmed |

### DEFERRED — Azure Platform Deployment (Track B)

| OpenSpec File | GitHub Issue | Status | Gate |
|---------------|--------------|--------|------|
| phase-1-azure-platform-foundation.md | #8 | Deferred | Track A readiness gate must pass |
| phase-1-pulp-runtime-topology.md | #9 | Deferred | Track A readiness gate must pass |
| phase-1-postgresql-foundation.md | #10 | Deferred | Track A readiness gate must pass |
| phase-1-image-supply-chain.md | #11 | Deferred | Track A readiness gate must pass |
| phase-1-private-networking-dns.md | #12 | Deferred | Track A readiness gate must pass |
| phase-1-diagnostics-operations.md | #13 | Deferred | Track A readiness gate must pass |
| phase-1-platform-milestone-test.md | #14 | Deferred | Track A readiness gate must pass |

### REVIEWER GATES

| Gate | Criteria | Reviewer |
|------|----------|----------|
| G1: `bundle_tools` scaffold review | P1-A1 merged; `python3 -m bundle_tools --help` works; no Pulp reimplementation; Python project standards met | Zoe |
| G2: Local e2e pass with `bundle_tools` execution | P1-A2 through P1-A6 pass against local harness (single-container mode); evidence collected | River + Zoe |
| G3: Track A readiness (unlocks Track B) | All P1-A items done; full workflow (export→manifest→validate→import→publish→evidence) runs without bash in the critical path; negative tests pass | Zoe |

---

## Dependency Ordering

```
P1-A1 → P1-A2 → P1-A3 → P1-A4 → P1-A5 → P1-A6 → P1-A7
                                      └──→ P1-A8

G1 after P1-A1
G2 after P1-A6
G3 after P1-A7 + P1-A8
Track B (issues #8-#14) after G3
```

---

## Key Constraints (from decisions.md)

1. **No Python wrapper around Pulp API.** `bundle_tools` calls `pulp-cli` or REST directly.
2. **Transfers are one-way (low→high).** No feedback from high to low.
3. **No Azure/Bicep until G3 passes.** Application must own the workflow.
4. **Pulp IS the state store.** No separate PostgreSQL/SQLite for tracking what Pulp already tracks.
5. **Thin orchestration only.** `bundle_tools` adds: manifest generation/validation, evidence, scheduling, operator UX. Nothing else.

---

## Immediate Next Actions

1. **Kaylee:** Begin P1-A2 — wire the `bundle_tools` workflow plan into an executable operator command against a running local Pulp harness.
2. **Wash:** Set up CI syntax-check gate (Python lint + type check on `src/bundle-tools/`).
3. **River:** Define negative test cases for P1-A4 (manifest validation with corrupt/missing files).
4. **Book:** Keep the operator quickstart aligned with `bundle_tools` commands as they land.
5. **Zoe:** Review P1-A1 at G1 gate.
# Wash Phase 1 Bundle Tools Foundation

**Date:** 2026-05-04T21:42:09.450+00:00
**Owner:** Wash
**Status:** Proposed implementation decision

## Decision

Start the Phase 1 application foundation in `src/bundle-tools` as a
standard-library Python package. The package validates JSON configuration,
emits declarative native Pulp REST/CLI workflow plans, validates low→high
transfer manifests, and writes evidence indexes.

## Rationale

This keeps the application layer focused on orchestration and operator evidence
without building a Python wrapper around Pulp. Native Pulp export/import remains
the content workflow, while bundle tools own boundary checks, configuration
shape, manifest integrity, and evidence conventions.

## Consequences

- Low-side configs may define upstream repository URLs for sync.
- High-side configs must not define upstream repository URLs.
- Transfer manifests explicitly carry `direction: low-to-high` and reject
  high-to-low feedback fields.
- Runtime code can later wire these plans to `pulp-cli`, REST calls, Container
  Apps jobs, or the local harness without changing the validation contract.
# River Phase 1 Validation Foundation

**Date:** 2026-05-04T21:42:09.450+00:00
**Owner:** River (Validation)
**Status:** Proposed

## Decision

Phase 1 validation should keep an image-free foundation that runs before private registry values are available. Placeholder private image references are classified as external configuration, while real high-side references fail validation if they are public, mutable tag-only, digest-invalid, or not private high-side ACR.

## Rationale

This lets application-first work validate manifest integrity, evidence shape, one-way low-to-high constraints, and Docker-local harness script gates without pulling Pulp or APT client images. Full container e2e remains a separate gate that depends on external private image configuration.

## Implemented artifacts

- `src/bundle-tools/phase1_validation.py`
- `tests/phase1/test_validation_foundation.py`
- `harness/local/scripts/generate-manifest.sh`
- `harness/local/scripts/validate-manifest.sh`
- `.squad/skills/local-container-validation/SKILL.md`
---
date: 2026-05-04T21:42:09.450+00:00
author: Simon
status: CONTROL_FINDINGS
scope: Phase 1 application-first review for Wash/River/Book
---

# Phase 1 Security & Compliance Control Review

## Purpose

This document records actionable control requirements and blocking/warning classifications for Phase 1 architecture. Controls are derived from:
- **Design:** `design.md` (Pulp as system-of-record, JSON manifests, one-way transfer)
- **Evidence:** `phase-1-evidence-backbone.md` (required fields, controls.json schema)
- **Blueprint specs:** Phase 1 issue artifacts (#8–#14) define Azure platform, private networking, image supply chain, PostgreSQL state, diagnostics, Pulp topology, and platform testing
- **Boundary principles:** AirGap constraints, government cloud isolation, managed identity, private endpoints, audit trails

---

## Critical Security Controls

### 1. Secret Handling & Key Vault

**Control Name:** All secrets flow through Key Vault; no embedded credentials.

**Requirement:**
- Pulp admin password, database credentials, API tokens, and ACR authentication tokens MUST be stored in Azure Key Vault
- `.env` files MUST NEVER be committed to git (confirm `.gitignore` blocks `*.env` and `.env*`)
- Application code MUST read secrets via Key Vault references (Azure Identity SDK or managed identity)
- Startup MUST fail fast if Key Vault is unreachable or required secrets are missing
- No Python wrapper or helper script around Pulp API should embed or pass credentials as environment variables

**Blocking:** Any hardcoded credential, password, or token discovered in source code or IaC is a hard block
**Warning:** None (secrets are binary — present or not)

**Evidence Required:**
- IaC shows Key Vault configuration with RBAC/access policy on managed identity
- Application startup code shows Key Vault reference resolution before service start
- Unit/integration tests confirm startup fails when Key Vault is unavailable
- `.gitignore` proof shows `.env` is excluded

**Ownership:** Wash (application code), Book (IaC), River (test validation)

---

### 2. Image References & ACR Supply Chain

**Control Name:** Private ACR only; tag-plus-digest deployment references; no public registry fallback.

**Requirement:**
- All runtime, support, admin, and operational images MUST be pulled from private ACR only
- Deployment manifests (Container Apps, Bicep, Kubernetes if used) MUST reference images as `<private-acr>/repo:tag@sha256:<digest>`
- No bare `docker.io`, `ghcr.io`, or public registry hostname may appear in deployed configuration
- Image BOM (per `phase-1-image-supply-chain.md`) MUST list source digest, target ACR, target digest, and approval state for every image
- Pulp container image baseline: `pulpcore 3.110.0`, `pulp_deb 3.8.1`; any version change requires re-validation and updated evidence
- OCI tarball export/import workflow MUST verify digest match before deploying

**Blocking:**
- Public registry reference in deployed manifests → hard block
- Mutable tag-only reference (without digest) in high-side deployment → hard block
- Image import without source/target digest verification → hard block

**Warning:** None (image provenance is binary)

**Evidence Required:**
- Image BOM (JSON or table) showing source, source digest, target ACR, target tag, target digest, approval state
- Deployment reference scan (IaC scan or manifest audit) showing all images use tag-plus-digest
- High-side ACR validation log showing import of each required image
- Failed import/digest-mismatch test showing proper rejection

**Ownership:** Wash (IaC templates), Book (release artifact process), River (validation harness)

---

### 3. One-Way Transfer Constraint

**Control Name:** Low-side → high-side only; no bidirectional sync or high-side receipt feedback.

**Requirement:**
- Transfer bundles move low → high via removable media only
- High-side MUST NOT attempt to sync or export back to low-side
- No channel exists for low-side to receive high-side import confirmation or state updates
- High-side is authoritative once a batch is staged; no reconciliation loop
- Application state machine MUST enforce transfer unidirectionality in code and database (e.g., transfer direction field, no reverse-sync logic)

**Blocking:**
- Any code path attempting bidirectional sync or high-side → low-side export → hard block
- Hidden feedback channel (e.g., callback to low-side webhook) → hard block

**Warning:** None (direction is binary)

**Evidence Required:**
- State machine diagram or code review showing transfer direction is enforced one-way
- PostgreSQL schema review showing no provision for reverse transfer
- Test case showing bidirectional sync is rejected or unavailable
- Operational documentation confirming high-side workflow is import/publish/maintenance only

**Ownership:** Wash (application design), River (test matrix for state machine)

---

### 4. Audit Trail & State Transitions

**Control Name:** Append-only audit history; all state transitions logged with actor/timestamp/reason.

**Requirement:**
- PostgreSQL `audit_log` or equivalent table MUST record every state transition (e.g., batch created, approved, exported, imported, published, superseded, rolled back)
- Audit record MUST include: actor (identity), timestamp (UTC), action, prior state, new state, reason, related manifest/batch ID, result
- Failed operations and privilege overrides MUST be logged
- Duplicate import attempt MUST be logged and rejected
- Snapshot already included in approved batch MUST NOT be included in new normal batch (database constraint + audit)
- All privileged operations (rollback, override, cancel) require audit entry with justification
- Audit records MUST NOT be updatable or deletable; append-only only
- Retention: minimum 1 year (unless customer policy mandates longer)

**Blocking:**
- Audit record mutation or deletion → hard block
- State transition without audit entry → hard block
- Incomplete or missing audit context (missing actor, timestamp, reason) → hard block

**Warning:** None (audit is binary)

**Evidence Required:**
- PostgreSQL schema review showing audit table with immutability constraints
- Application code review showing audit entry before/after every state transition
- Test case showing duplicate import rejection with audit log
- Test case showing snapshot re-use rejection with audit log
- Backup/restore test confirming audit history survives restore
- Sample audit log showing proper formatting and actor attribution

**Ownership:** Wash (application code), Book (database schema), River (test validation)

---

### 5. Manifest & Transfer Validation

**Control Name:** JSON manifests with checksums; validation failure rejects entire batch.

**Requirement:**
- Every transfer batch MUST include a JSON manifest with: schema version, batch ID, source environment, timestamp, per-repository entries (distribution, release, architecture, components/pockets, Pulp repository version, package count, payload size, checksums)
- Manifest checksums MUST cover all transfer artifacts (Pulp export TAR, metadata, image tarballs if applicable)
- Checksum validation failure (SHA256 or approved algorithm) rejects the entire batch; no partial import
- High-side import MUST validate manifest before staging
- Pulp or plugin version mismatch produces a warning and requires privileged override (audit logged) rather than unconditional block
- Manifest fields MUST be documented in schema and include evidence binding to GitHub issues

**Blocking:**
- Checksum mismatch → entire batch rejected (hard block, no override)
- Missing manifest fields → batch rejected (hard block)
- Corrupt or invalid JSON → batch rejected (hard block)

**Warning:**
- Pulp version mismatch (low 3.110.0 vs high 3.109.x or similar) → warn, require override with audit
- Plugin version mismatch → warn, require override with audit
- Ubuntu distribution expansion beyond 22.04 → warn (MVP scope is Ubuntu 22.04 only), require override

**Evidence Required:**
- Manifest schema (JSON Schema document or exemplar)
- Validation code showing checksum verification before import
- Test case with intentional checksum error; verify rejection
- Test case with valid manifest; verify acceptance
- Test case with version mismatch; verify warning and override requirement

**Ownership:** Wash (manifest generation/validation), River (test harness)

---

### 6. Private Networking & DNS

**Control Name:** All services behind private endpoints; no public internet access on high-side.

**Requirement:**
- All Azure services (ACR, Storage, PostgreSQL-compatible DB, Key Vault, diagnostics) MUST use private endpoints where supported
- Private DNS zones MUST be created and linked to Container Apps VNet
- High-side Container Apps runtime MUST resolve required service endpoints to private addresses (validate via `nslookup` or DNS probe)
- NSG/UDR controls MUST reject public internet egress from Container Apps on high-side (except approved diagnostics fallback)
- Cloud endpoint suffixes MUST be parameterized in IaC: `.azurecr.us`, `.blob.core.usgovcloudapi.net`, `.vault.usgovcloudapi.net`, `.postgres.database.usgovcloudapi.net` for government/high-side
- Runtime configuration MUST NOT reference commercial suffixes (`.azurecr.io`, `.blob.core.windows.net`, etc.) on high-side
- Diagnostics MUST use private link (AMPLS) or approved private export fallback; no public diagnostics endpoint

**Blocking:**
- Public internet access from high-side Container Apps → hard block
- Public registry/DNS resolver in runtime config → hard block
- Missing private endpoint for required service → hard block
- Unparameterized commercial endpoint suffix in high-side config → hard block

**Warning:** None (private networking is binary)

**Evidence Required:**
- IaC plan showing private endpoints for ACR, Storage, PostgreSQL, Key Vault
- IaC plan showing private DNS zones and VNet links
- Runtime DNS resolution test (Container Apps executing `nslookup` to confirm private IP)
- NSG/UDR rules blocking high-side public egress (negative test)
- Test case showing public registry pull fails on high-side
- Diagnostics fallback procedure (if private link not available)

**Ownership:** Book (IaC, networking), River (DNS/connectivity validation)

---

### 7. PostgreSQL State & Consistency

**Control Name:** Strong transaction enforcement; state machine cannot be violated.

**Requirement:**
- Failed hydration run cannot create transfer-eligible snapshot (database constraint or transaction rollback)
- Snapshot already included in approved transfer batch cannot be re-used in new normal batch (unique constraint or check, audit violations)
- Transfer batch cannot be exported before approval (state transition guard in application code + database constraint)
- High-side staged batch cannot be imported before manifest validation passes (validation gate before state transition)
- Batch cannot be published before Pulp import succeeds (transaction dependency or foreign key constraint)
- Duplicate successful import rejected (unique constraint on batch ID + state, or application check)
- Rollback requires explicit approval and audit history (privileged operation, audit entry mandatory)
- Compatibility override requires justification and audit entry (business logic check + audit)
- Database access from application MUST use managed identity or approved secret path through Key Vault (no embedded DB password)
- Backup/restore procedure documented and tested; restore test confirms state machine still works (e.g., duplicate import rejection after restore)

**Blocking:**
- State transition without database transaction → hard block
- Duplicate import succeeds when it should be rejected → hard block
- State machine bypassed (e.g., publish without import) → hard block

**Warning:** None (state consistency is binary)

**Evidence Required:**
- Database schema review showing constraints/triggers enforcing rules
- Application code review showing transaction wrapping state transitions
- Concurrent access test (two workers attempt same snapshot selection; exactly one wins)
- Concurrent import test (two import requests for same batch; one succeeds, one rejected)
- Restore drill evidence showing backup/restore procedure, and post-restore duplicate import rejection test
- Audit log samples showing all transitions

**Ownership:** Wash (application state machine), Book (schema), River (concurrency tests)

---

### 8. Failure Modes & Startup Guards

**Control Name:** Startup fail-fast; graceful failure with audit; no silent degradation.

**Requirement:**
- Container Apps startup MUST validate:
  - Key Vault reachability and required secret availability
  - PostgreSQL connection and schema version compatibility
  - ACR reachability and ability to pull required images
  - Private endpoint DNS resolution for all required services
  - Storage account connectivity and write access
- Startup MUST fail (exit non-zero, container restart) if any required service is unavailable
- Failed Pulp tasks (sync, export, import, publish) MUST be logged to audit trail with error details
- Failed import/export MUST be recorded in state machine (batch state = failed or rejected)
- Partial failures (e.g., some packages imported, others failed) MUST be detected and the entire batch marked failed (no partial success)
- No Python process should silently catch and ignore Pulp API errors; all failures propagate to state machine and audit
- Diagnostics unavailability should not block core operations if private export fallback is configured; warning logged

**Blocking:**
- Silent failure or degradation (e.g., missing secrets, still starting) → hard block
- Partial success masked as full success → hard block

**Warning:**
- Diagnostics service unavailable (if private fallback configured) → warn, continue
- Degraded replica count (if minimum replicas reached) → warn, log

**Evidence Required:**
- Startup test showing failure when Key Vault/DB/ACR unavailable
- Failure injection test (e.g., kill database) showing task failure captured in audit
- Partial import test showing entire batch marked failed
- Diagnostics fallback test showing warning and private export used

**Ownership:** Wash (startup validation, error handling), River (test harness)

---

## Blocking vs. Warning Classification

### Blocked (No Override, No Warning)

1. **Public registry pull in runtime config** — hard boundary for AirGap
2. **Checksum validation failure** — integrity is non-negotiable
3. **Embedded credentials in code/IaC** — immediate security incident
4. **Bidirectional sync** — violates one-way transfer design
5. **State machine bypass** — data integrity violation
6. **Duplicate import success** — breaks idempotency guarantee
7. **Missing private endpoint for required service** — violates high-side isolation

### Warned + Override Required (Privileged Operation, Audited)

1. **Pulp version mismatch** (low-high compatibility concern) — warn, require approval/override, audit entry mandatory
2. **Plugin version mismatch** — warn, require override, audit entry
3. **Ubuntu distribution expansion** (out of MVP scope) — warn, require override, audit entry
4. **CMK unavailable** (service doesn't support it) — record reason (not-supported, waived, etc.)

### Not Blocked (But Operationally Controlled)

1. **Diagnostics private link unavailable** — use approved fallback (local export, etc.)
2. **Replica scaling** — log warning if below minimum, but do not block startup if replicas can be allocated

---

## No Python Wrapper Principle

**Control:** Hydration orchestration MUST NOT provide a Python wrapper or library that directly calls Pulp REST API from outside the application container.

**Reason:** External Python wrappers:
- Cannot enforce audit logging (no state machine visibility)
- May embed credentials
- Violate one-way transfer if they allow arbitrary API calls
- Hide complexity from the application boundary

**Implementation:** All Pulp API interactions must occur within Wash's orchestration service (or approved jobs), not through external Python scripts or libraries. Operators use application-level workflows (e.g., "import this batch," "publish this snapshot") which internally call Pulp API and record audit trails.

---

## Required Evidence Artifacts

### Phase 1 Issue #8: Azure Platform Foundation

- **IaC plan:** Private endpoints, RBAC, CMK status, tags, endpoint suffixes
- **Controls.json:** Resource-by-resource pass/fail for networking, identity, encryption
- **Resource inventory:** Every resource role, SKU, region, diagnostics status

### Phase 1 Issue #9: Pulp Runtime Topology

- **Runtime matrix:** Replica counts, health probes, failure scenarios
- **Startup validation:** Services checked, fail-fast behavior
- **Scaling evidence:** Max replicas, concurrency limits, failure handling

### Phase 1 Issue #10: PostgreSQL State Foundation

- **Schema review:** Constraints, triggers, audit table
- **State machine tests:** Duplicate rejection, snapshot reuse prevention, rollback
- **Concurrency tests:** Snapshot selection, import, publish races
- **Backup/restore drill:** Procedure, restore evidence, post-restore validation

### Phase 1 Issue #11: Image Supply Chain

- **Image BOM:** Source digest, target digest, approval state for each image
- **ACR validation:** Import logs, digest verification, tag-plus-digest check
- **Deployment scan:** No public registries in manifests

### Phase 1 Issue #12: Private Networking & DNS

- **IaC private endpoints:** ACR, Storage, PostgreSQL, Key Vault
- **DNS resolution test:** Container Apps resolves services to private IPs
- **NSG/UDR rules:** Public egress blocked on high-side
- **Diagnostics fallback:** Procedure if private link unavailable

### Phase 1 Issue #13: Diagnostics & Operations

- **Audit events:** Repository create/update, hydration start/success/failure, batch state changes, overrides, administrative changes
- **Telemetry:** Pulp API, workers, content serving, storage, database, Key Vault, ACR, networking
- **Failure drills:** Pulp task failure, database connectivity, storage failure, ACR pull failure, diagnostics unavailable, backup/restore

### Phase 1 Issue #14: Platform Milestone Test

- **End-to-end scenario:** Low-side sync/export → transfer → high-side import/publish
- **Failure scenario:** Checksum mismatch, duplicate import, version mismatch with override
- **Audit trail evidence:** Full scenario recorded in audit_log

---

## Control Validation Ownership

| Control | Wash | River | Book |
|---------|------|-------|------|
| Key Vault secrets | ✓ (app code) | ✓ (tests) | ✓ (IaC) |
| Image BOM & ACR | ✓ (release) | ✓ (validation) | ✓ (IaC) |
| One-way transfer | ✓ (state machine) | ✓ (tests) | — |
| Audit trail | ✓ (app logging) | ✓ (tests) | ✓ (schema) |
| Manifest validation | ✓ (validation code) | ✓ (tests) | — |
| Private networking | — | ✓ (validation) | ✓ (IaC) |
| PostgreSQL state | ✓ (state machine) | ✓ (concurrency tests) | ✓ (schema) |
| Startup guards | ✓ (app startup) | ✓ (tests) | ✓ (IaC) |

---

## Key Files for Implementation

- **Secret handling:** `.squad/skills/secret-handling/SKILL.md` — never read `.env`, no secrets in `.squad/` commits
- **Local validation:** `.squad/skills/local-container-validation/SKILL.md` — validation harness for Phase 0 proof
- **Container runtime:** `.squad/skills/container-runtime-harness/SKILL.md` — Docker/Podman abstraction
- **Design reference:** `openspec/changes/airgap-binary-hydration-service/design.md`
- **Evidence contract:** `openspec/changes/airgap-binary-hydration-service/phase-1-evidence-backbone.md`
- **Phase 1 specs:** `phase-1-{azure-platform-foundation,image-supply-chain,private-networking-dns,postgresql-foundation,diagnostics-operations,pulp-runtime-topology,platform-milestone-test}.md`

---

## Summary

Phase 1 is architecturally sound for AirGap application-first delivery. Control requirements are explicit:
1. **Secrets** → Key Vault only; fail fast if unavailable
2. **Images** → Private ACR, tag-plus-digest; no public registry fallback
3. **Transfers** → One-way low→high; no bidirectional sync
4. **Audit** → Append-only state machine with actor/timestamp/reason
5. **Networking** → Private endpoints + private DNS; no public internet on high-side
6. **Failures** → Batch rejected on checksum/validation failure; manifest validation before import
7. **No Python wrapper** around Pulp API; orchestration layer only

Wash, River, and Book ownership is clear. Evidence packages are prescriptive. Implementation should follow Phase 1 specs precisely; no deviations without explicit control review.
# Phase 1 Application-First Batch — Reviewer Gate G1

**Date:** 2026-05-04T21:42:09Z
**Author:** Zoe (Lead / Solution Architect)
**Status:** APPROVED
**Gate:** G1 — First application-layer slice

---

## Verdict: APPROVE

The Phase 1 application-first batch satisfies "begin working through Phase 1 items now" for the first slice. All artifacts are consistent with standing decisions, scope is clean, and all 17 tests pass.

---

## Review Criteria Assessment

### 1. Decision Consistency (✅ PASS)

- **No Python wrapper around Pulp** — `bundle_tools` orchestrates native Pulp REST/CLI operations declaratively. No `requests`, `httpx`, or custom Pulp client anywhere in `src/bundle-tools/`. Workflow plans reference Pulp API paths directly.
- **One-way low→high** — `TRANSFER_DIRECTION = "low-to-high"` enforced at config, manifest, evidence, and workflow levels. `FORBIDDEN_FEEDBACK_FIELDS` explicitly blocks high→low receipt patterns.
- **Application-first, defer Azure** — No Bicep, no ARM, no Azure SDK code. Pure Python stdlib application layer.
- **Thin orchestration, no state engine** — Workflow plan is declarative data (`WorkflowOperation` dataclass), not an execution engine. Config uses JSON, not SQLite/Postgres.

### 2. Scope Safety (✅ PASS)

- No infrastructure code introduced
- No external dependencies (stdlib-only Python)
- No secrets in source
- Config actively rejects inline secrets with `_reject_inline_secrets()`
- Image reference validation defers to `external_configuration` status for placeholders — correct boundary

### 3. Interface Clarity (✅ PASS)

- CLI has four clean subcommands: `validate-config`, `plan`, `validate-manifest`, `evidence-index`
- Phase1 validation helper has six focused checks: `env-template`, `manifest`, `local-evidence`, `phase1-evidence`, `one-way-plan`, `harness-static`
- Both produce JSON output suitable for machine consumption and piping
- README documents run-locally commands

### 4. Test Coverage (✅ PASS)

- 17 tests, all green in 0.4s
- Tests cover: config loading, secret rejection, manifest checksum validation, tamper detection, feedback field rejection, workflow plan structure, CLI entrypoint, env template validation, image reference classification, evidence shape, one-way constraints, harness script syntax, compose config rendering
- Tests use filesystem fixtures (no mocking Pulp) — appropriate for image-free foundation

### 5. Documentation (✅ PASS)

- `src/bundle-tools/README.md` — concise, accurate, includes run commands
- `docs/runbooks/phase-1-local-operator-setup.md` — comprehensive operator guide with prerequisites, Docker/Podman setup, and workflow explanation

---

## What Is Now Complete

| Item | Owner | Status |
|------|-------|--------|
| Config loader with secret rejection and side enforcement | Wash | ✅ Done |
| Transfer manifest generation + SHA-256 validation | Wash | ✅ Done |
| Evidence index builder with stage constraints | Wash | ✅ Done |
| Declarative workflow plan (low/high operations) | Wash | ✅ Done |
| CLI entrypoint (`python3 -m bundle_tools`) | Wash | ✅ Done |
| Image-free validation foundation (`phase1_validation.py`) | River | ✅ Done |
| Image reference classification (public/private/placeholder) | River | ✅ Done |
| Test suite (14 tests, all passing) | River | ✅ Done |
| Operator runbook (`phase-1-local-operator-setup.md`) | Book | ✅ Done |

---

## Remaining Blocked (Private/Internal Image Refs Required)

1. **Full e2e harness execution** — `run-e2e.sh` and `run-low-high-e2e.sh` require `PULP_SINGLE_IMAGE` and `APT_CLIENT_IMAGE` from internal ACR
2. **Compose-mode validation** — requires `PULP_IMAGE`, `PULP_WEB_IMAGE`, `POSTGRES_IMAGE`, `REDIS_IMAGE` with real tag+digest refs

These cannot be unblocked without private registry credentials or mirrored images. Not a team failure — external dependency.

---

## Next Actionable Phase 1 Work Item

**P1-A2: Operator CLI scaffolding (`bundle_tools` CLI expansion)**

The foundation is proven. Next step is wiring the declarative workflow plan into an executable operator command that:
1. Reads config, calls `pulp-cli` or REST to execute each operation in sequence
2. Captures evidence artifacts at each step
3. Writes evidence-index.json on completion
4. Reports batch status to operator

This requires a running Pulp instance (harness single-container mode) but does NOT require Azure. Assign to Kaylee (Platform) for scaffold; Wash (Automation) for execution logic.

**Secondary:** Harness README polish and CI syntax-check gate (lightweight, assign to Book).

# Phase 1 Gate G1 Accuracy Review Closeout

**Date:** 2026-05-05T01:32:52Z
**Author:** Zoe-led review fleet
**Status:** APPROVED WITH SCOPE LIMITS
**Gate:** G1 — First application-layer slice only

---

## Verdict

The most recent Phase 1 changes accurately support closing Gate G1 for the first application-first slice. They do not close all of Phase 1, G2/G3, Track A readiness, or Azure deployment.

## Review Findings

- **Lead review:** Gate G1 can stand; P1-A2 remains the next actionable item.
- **Implementation review:** Manifest numeric field validation now raises `ManifestError` consistently; focused unit coverage was added.
- **Validation review:** Image-free checks pass; full runtime e2e remains blocked on private/internal image references.
- **Control review:** Inline secrets, one-way transfer, symlink/path containment, checksum validation, private image guidance, and evidence documentation are aligned.
- **Docs review:** `PULP_PULL_POLICY=never` is the repeatable/offline default; `missing`/`if-not-present` are connected-test overrides only.

## Visual Validation

Playwright was not required or used. The repo has no browser UI, rendered docs site, Playwright config, or HTML application surface to validate visually for this slice.
\n---\n
# Book decision: P1-A2 docs standardization

Date: 2026-05-05T01:40:36.497+00:00
Author: Book (Customer Enablement Writer)

Decision:

- Standardize operator-facing documentation to reference the new `bundle_tools execute-export` command as the P1-A2 low-side operator slice.
- Document required flags, dry-run behavior, JSON stdout summary contract, evidence artifacts, and recommended exit-code mappings in both `src/bundle-tools/README.md` and `docs/runbooks/phase-1-local-operator-setup.md`.
- Mark live evidence as BLOCKED by private/internal image configuration when private ACR references are unavailable; allow image-free validation and --dry-run acceptance lanes.

Rationale:

This decision keeps operator runbooks aligned with Zoe's P1-A2 execution contract and prevents accidental scope creep (no container lifecycle, no high-side actions, no manifest generation). It clarifies how operators should interpret non-zero exit codes and how to report evidence blocked by external configuration.

Impact:

- Operators will follow the documented command surface for P1-A2 testing and validation.
- Validation owners (River) can rely on a consistent evidence shape for acceptance.

\n---\n
# Decision Inbox: book-phase1-docs-accuracy-review

Date: 2026-05-05T01:26:57.473+00:00

Summary

During a documentation accuracy review of Phase 1 runbooks and local harness, I found a mismatch between documentation guidance and implementation for the default container image pull policy. The repo scripts and env.example default to `PULP_PULL_POLICY=never`, while `docs/runbooks/phase-1-local-operator-setup.md` instructs operators to use `PULP_PULL_POLICY=missing` as the safe default for local testing.

Proposal

1. Standardize on `PULP_PULL_POLICY=never` as the repository default for repeatable, air-gap focused local validation. Rationale: `never` prevents accidental public pulls during repeatable offline checks and matches `harness/local/scripts/common.sh` and `env.example`.

2. Update documentation (`docs/runbooks/phase-1-local-operator-setup.md` and any related runbooks) to:
   - Reflect the repo default `PULP_PULL_POLICY=never` and explain usage scenarios for other values:
     - `if-not-present` / `missing` — for connected local exploration when pulling public images is acceptable
     - `always` / explicit pull flags — only for explicit connected CI runs
   - Provide explicit example commands to pre-pull images for connected testing and note expected exit codes for validation commands.

3. Add a short negative-test checklist to `phase-1-platform-milestone-test.md` or `phase-1-evidence-backbone.md` enumerating failure scenarios operators should exercise (missing image, checksum mismatch, import-check failure), with expected outcomes and evidence locations.

Decision Needed

Please review and either:
- Approve the proposal so I can update the docs in a follow-up commit, or
- Suggest an alternate canonical default (e.g., `missing`) and I will adjust the proposal and docs accordingly.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
\n---\n
# Kaylee Phase 1 Platform Review Decision

**Date:** 2026-05-05T01:42:22.430+00:00  
**Owner:** Kaylee (Azure Platform Engineer)  
**Status:** PROPOSED FOR TEAM ADOPTION

## Decision

Treat Azure Container Apps workload-profile availability in Azure Government (and especially Azure Government Secret) as a **hard Phase 1 validation gate**, and define an explicit fallback runtime path if target tenants cannot provide required workload-profile features.

## Why

Phase 1 artifacts correctly separate service-role parity from target-environment proof, but they still assume a workload-profile-based Container Apps design across both sides. Government and air-gapped cloud feature availability can diverge by tenant/region/SKU. Without an explicit fallback decision point, issue #9 can stall late.

## Required Team Follow-Through

1. Add a dated go/no-go checkpoint for Container Apps workload profiles in issue #8/#9 evidence.
2. Pre-authorize fallback patterns (for example, AKS or VM scale-set runtime) with support ownership, patching, diagnostics, and operational implications.
3. Expand IaC parameter set to include diagnostics endpoint suffixes and Azure Monitor private DNS artifacts so high-side deployments cannot inherit commercial defaults.
4. Keep diagnostics dual-path mandatory: AMPLS/private link when available, local/private export fallback when not.

## Impact

This keeps the roadmap viable for both low side and high side by moving the highest cloud-parity uncertainty to an early, explicit gate and avoiding late architecture churn.
\n---\n
# River Decision: P1-A2 execution tests are contract-first

- **Date:** 2026-05-05T01:40:36.497+00:00
- **Owner:** River
- **Scope:** Validation lane for `bundle_tools execute-export`

## Decision

Land the P1-A2 validation suite and deterministic fixtures now as an executable contract, even before executor implementation is wired. Keep assertions strict on command surface, dry-run behavior, low-side-only boundaries, feedback rejection, Pulp precondition handling, failure/timeout propagation, evidence containment, and no high-to-low receipt fields.

## Result

Current failures are expected until `execute-export` is implemented in `bundle_tools.__main__` and wiring satisfies the contract. This keeps acceptance criteria objective and immediately verifiable once Wash lands execution code.
\n---\n
# River Decision: P1-A2 validation closeout

- **Date:** 2026-05-05T01:40:36.497+00:00
- **Owner:** River
- **Scope:** Final validation position for `bundle_tools execute-export`

## Decision

P1-A2 validation is accepted for the image-free lane. The suite now verifies deterministic contract exits for local harness precondition failure (`3`) and task failure (`4`), confirms low-side-only boundary enforcement, and asserts the full required low-side evidence artifact set on a successful fake-Pulp export execution.

## Evidence

- `PYTHONPATH=src/bundle-tools python3 -m unittest discover -s tests -p 'test*.py'`
- `python3 src/bundle-tools/phase1_validation.py harness-static .`
- `PYTHONPATH=src/bundle-tools python3 -m bundle_tools execute-export --help`

All passed after strengthening `tests/phase1/test_p1a2_execution.py` with additional contract edge-case coverage.

## Team impact

Wash and Zoe can treat P1-A2 as validation-complete for image-free acceptance criteria. Runtime proof against private images remains an external-configuration lane and is not claimed by this closeout.
\n---\n
# River — P1-A2 Validation Plan Decision

**Date:** 2026-05-05T01:40:36.497+00:00  
**Owner:** River (Validation)  
**Status:** Proposed

## Decision

For P1-A2 executable workflow behavior, validation coverage must split into two lanes:

1. **Image-free executable checks (required now):** dry-run/plan parity, command construction, subprocess failure propagation, manifest/evidence path containment, one-way low→high guardrails, high-side upstream rejection, and no-public-high-side-reference enforcement.
2. **Real runtime execution checks (externally blocked):** end-to-end Pulp export/import/publish execution that depends on private mirrored image references and environment credentials.

## Rationale

This keeps quality gates executable in current development conditions while still exposing runtime dependencies explicitly. It prevents false confidence where foundational checks pass but private-image runtime prerequisites are missing.

## Test Coverage Targets

- Update `tests/test_bundle_tools_foundation.py` for dry-run/plan contracts and execution-time guardrails.
- Update `tests/phase1/test_validation_foundation.py` for path-handling and external-configuration clarity assertions.
- Add `tests/phase1/test_p1a2_execution.py` for subprocess orchestration success/failure behavior.
- Add deterministic fixtures under `tests/fixtures/p1a2/` for config, plan, subprocess outputs, media manifest, and minimal evidence layout.

## Team Impact

Zoe and Kaylee can treat this as the acceptance template for P1-A2 quality gate definition. River will reject P1-A2 completion claims that do not demonstrate both lane classification and failure propagation evidence.
\n---\n
# River Phase 1 Validation Audit Decision

- Date: 2026-05-05T01:26:57.473+00:00
- Agent: River (Tester / Validation Engineer)
- Status: Accepted with caveat

## Decision
Treat `river-phase1-validation-audit` as functionally validated for non-destructive Phase 1 checks, but record a repository hygiene caveat: `git diff --check` reports pre-existing trailing whitespace in `.squad/decisions.md`.

## Evidence Summary
- Python unit tests: `python3 -m unittest discover -s tests -p 'test*.py'` => 14 passed.
- Shell syntax: `bash -n harness/local/scripts/*.sh` => pass.
- Static harness contract: `python3 src/bundle-tools/phase1_validation.py harness-static /home/adamdost/git/pulp-azure` => pass.
- CLI help: `phase1_validation.py --help` and `python3 -m bundle_tools --help` => pass.
- Workflow integrity checks without private images:
  - one-way plan validation => pass
  - fixture generation + manifest generation/validation => pass
  - local evidence shape validation => pass
- Existing sample artifact caveat: `harness/local/.work/final-validation-media` manifest fails current one-way schema (`direction` missing), so it should not be used as canonical acceptance evidence.

## Playwright Evaluation
No UI/browser surface was found (no Playwright config, no app `package.json`, no HTML/HTM artifacts). Playwright CLI/MCP visual validation is not required for this audit.
\n---\n
# River Phase 1 Validation Review Decision

**Date:** 2026-05-05T01:42:22.430+00:00  
**Owner:** River (Validation)

## Decision

Phase 1 definition-of-done evidence must require executable validation for both low-side and high-side scopes, not only document-level evidence package completeness.

## Why

Current Phase 1 docs define strong controls and failure expectations, but existing automated checks mostly enforce artifact schema/shape and selected static guardrails. This leaves a gap where low-side-only success and manually interpreted high-side evidence could still appear sufficient.

## Required Additions Before Treating #14 as a Strong Phase 2 Gate

1. Add explicit independent pass/fail assertions for low-side and high-side startup/health in `validation-results.json` and gate logic.
2. Add executable checks for all backbone failure conditions with machine-readable expected/actual outcomes, not only narrative logs.
3. Add cross-issue aggregation checks that block #14 pass when any required #8-#13 evidence item is missing, waived without approval, or only manually asserted.

## Impact

This raises confidence that Phase 1 actually proves disconnected and connected platform behavior, rather than proving documentation completeness.
\n---\n
# Simon Phase 1 Control Accuracy Review

**Date:** 2026-05-05T01:26:57.473+00:00  
**Owner:** Simon  
**Status:** Corrections applied  
**Scope:** Phase 1 bundle tools, local harness, docs, and tests

## Decision

Phase 1 controls are treated as enforceable implementation gates, not documentation-only guidance:

1. Committed harness defaults must not include reusable inline credentials. `PULP_ADMIN_PASSWORD` is required from the operator's uncommitted local environment.
2. High-to-low feedback is blocked both by forbidden receipt/return fields and by requiring `feedbackToLowAllowed` to be exactly `false`.
3. Transfer payload validation rejects symlink artifacts in addition to absolute paths, `..`, missing files, size mismatches, and checksum mismatches.
4. Phase 1 high-side and air-gap validation evidence must not rely on public image pulls. Public image references may appear only as connected-side source baselines, while runtime validation uses pre-loaded/private mirror or private ACR tag-plus-digest references.

## Corrections made

- Removed the committed local harness password value from `harness/local/env.example` and script defaults.
- Added required local environment checks before harness workflows authenticate to Pulp.
- Tightened manifest and Phase 1 validation code for nested feedback controls and symlink path containment.
- Added tests for feedback-boundary rejection and symlink artifact rejection.
- Corrected the local operator runbook to remove public high-side dependency claims and fix tag-plus-digest examples.

## Validation

- `PYTHONPATH=src/bundle-tools python3 -m unittest discover -s tests -q`
- `python3 src/bundle-tools/phase1_validation.py env-template harness/local/env.example`
- `python3 src/bundle-tools/phase1_validation.py harness-static .`
- `for f in harness/local/scripts/*.sh; do bash -n "$f" || exit 1; done`

## Blockers

No remaining security blockers were found in the reviewed Phase 1 control surface. Private image references remain external configuration and must be supplied before full high-side runtime validation.
\n---\n
# Simon Phase 1 Security and Compliance Review

**Date:** 2026-05-05T01:42:22.430+00:00  
**Owner:** Simon (Security & Compliance Engineer)  
**Requested by:** Adam  
**Status:** BLOCK — Phase 1 definition of done needs explicit security evidence additions before it can represent FedRAMP High / IL4-IL6 readiness.

## Scope reviewed

- `openspec/changes/airgap-binary-hydration-service/phase-1-definition-of-ready.md`
- `openspec/changes/airgap-binary-hydration-service/phase-1-evidence-backbone.md`
- `openspec/changes/airgap-binary-hydration-service/design.md`
- `openspec/changes/airgap-binary-hydration-service/phase-1-azure-platform-foundation.md`
- `openspec/changes/airgap-binary-hydration-service/phase-1-private-networking-dns.md`
- `openspec/changes/airgap-binary-hydration-service/phase-1-image-supply-chain.md`
- Related Phase 1 issue specs for runtime, PostgreSQL, diagnostics, and milestone evidence.

## Overall assessment

Phase 1 is directionally right for delivering Pulp low side and high side: it uses private ACR, private endpoints, managed identity, Key Vault, CMK-aware platform services, append-only audit, and negative tests for public references. However, the current definition of done is not yet sufficient for FedRAMP High / IL4-IL6 acceptance because several controls are stated as intent rather than auditable proof, and transfer-boundary authenticity is still checksum-only.

I would allow planning and implementation to proceed, but I would not allow Phase 1 closeout or a Phase 2 authorization claim until the blockers below are resolved or formally accepted by the customer authorizing official.

## Findings

### 1. Security controls completeness

**[CONCERN] Baseline controls are good but incomplete for FedRAMP High / IL4-IL6 evidence.**

What is covered:
- Private endpoints, private DNS, disabled public network access.
- No public high-side runtime dependency.
- Managed identity, least-privilege RBAC, Key Vault references.
- CMK status, TLS 1.2+, internal HTTPS/PKI, diagnostics, retention, tags.
- Backup/restore and failure-mode evidence.

Missing or under-specified controls:
- Explicit control mapping to FedRAMP High / NIST SP 800-53 Rev. 5 and DoD SRG IL4/IL5/IL6 overlays.
- Azure Policy or equivalent policy-as-code evidence for deny public access, require private endpoints, require diagnostics, require tags, allowed locations/SKUs, allowed image registries, and CMK enforcement.
- FIPS-validated cryptography posture for high-side TLS, internal PKI, signing keys, and platform cryptographic modules.
- Vulnerability management evidence: image scanning, SBOM, dependency provenance, patch cadence, and waiver/POA&M handling.
- Privileged access controls: PIM/JIT or equivalent approval, MFA/conditional access assumption, break-glass account handling, admin role review, and separation of duties.
- Incident response and audit review procedure for failed imports, suspected tampering, denied Key Vault access, public dependency detection, and rollback.

Recommendation:
- Add a required `compliance-control-mapping.json` or equivalent matrix with control ID, implementation statement, inherited/customer responsibility, evidence artifact, owner, status, waiver, and expiry.
- Add policy-as-code validation to issue #8 and #14 closeout.
- Add vulnerability/SBOM/signature evidence to issue #11.

### 2. AirGap boundary enforcement

**[BLOCKER] The evidence backbone does not yet prove ZERO public high-side dependencies.**

The current evidence requires static scans for public registry, public DNS, public package sources, public service endpoints, commercial suffixes, missing private endpoints, and tag-only images. That is necessary, but not sufficient. It does not require packet/flow evidence, DNS query evidence, denied egress evidence, proxy/environment variable scanning, package-manager restore blocking, or verification that all Container Apps jobs/init/sidecar/admin images follow the same rule.

Recommendation:
- Add a high-side `zero-public-dependency` evidence bundle to issue #12 and #14 with:
  - Effective route table, NSG, UDR, firewall, and DNS resolver configuration.
  - Runtime DNS query logs or controlled resolver evidence showing only private resolution for required services.
  - Flow logs or equivalent network observations showing no public IP egress during startup, health checks, import, publish, diagnostics export, and admin jobs.
  - Explicit negative tests for `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` misuse, public NTP/time sources, public package-manager config, public container image references in every component, and public endpoint fallback behavior.
  - Deny-by-default egress posture or a documented, customer-approved equivalent.

### 3. Identity and secrets

**[CONCERN] Managed identity and Key Vault direction is correct, but the RBAC model is not yet enforceable.**

The platform foundation defines identities and broad minimum access, but it does not yet require an exact role assignment matrix by resource scope, verb, and identity. Phrases such as “read/write approved storage paths” are not enough to prove least privilege in an audit.

Gaps:
- No explicit separation between low-side sync/export identities, high-side import/publish identities, image import/release identities, diagnostics export identities, operator/admin identities, and break-glass identities.
- No Key Vault secret/key access matrix showing which identity can read secrets, unwrap keys, rotate keys, or manage certificates.
- No evidence rule for redacting secrets from command logs, diagnostics exports, issue comments, and sanitized evidence packages.
- No explicit requirement to reject storage account keys, ACR admin user, broad owner/contributor assignments, or secret-bearing connection strings in deployment outputs.

Recommendation:
- Add `identity-rbac-matrix.json` to issue #8 with identity, resource, scope, role/action, justification, expiry/standing access status, and validation result.
- Add negative tests for broad subscription/resource-group owner, ACR admin user enabled, storage keys in app config, Key Vault public access, and unredacted secret-like values in evidence.

### 4. Data boundary controls

**[BLOCKER] Data classification and boundary-crossing controls are not complete enough for removable-media transfer.**

The design correctly keeps transfer one-way low-to-high and states that CDS/media movement and malware scanning tooling are not owned by this system. That boundary is acceptable only if Phase 1 explicitly requires evidence of the approved external process. Today, the DoD does not require chain of custody, media handling, sanitization, or release authorization records.

Gaps:
- No transfer data classification matrix for package payloads, manifests, image tarballs, checksums, logs, and evidence exports.
- No chain-of-custody artifact for removable media or CDS release.
- No required reference to the customer-approved malware/content scanning stage, even if this system does not own the scanner.
- No requirement for encrypted media, media inventory, tamper-evident handling, wipe/disposal, or operator dual-control where policy requires it.
- No explicit evidence-redaction standard for tenant IDs, subscription IDs, private endpoint names, internal DNS, package names, and operational logs.

Recommendation:
- Add `boundary-transfer-record.json` with classification, source, destination, release authority, custody steps, media ID, checksum manifest, scan/release reference, operator approvals, and final disposition.
- Add a sanitized-evidence handling rule and make it part of issue #11, #12, #13, and #14 closeout.

### 5. CMK coverage

**[CONCERN] The CMK matrix is a strong start, but it is not complete or fully enforceable.**

The platform foundation improves on “where required” by requiring each data-at-rest service to report `required-configured`, `not-supported`, `not-required-by-policy`, or `waived`. That is good. It still needs clearer enforcement for key lifecycle and dependent data stores.

Gaps:
- No required proof of key rotation policy, key expiry, key backup/export restrictions, key vault soft delete, purge protection, separation of key administrators from data-plane operators, or break-glass procedure.
- Diagnostics/logging CMK treatment is conditional but lacks an explicit fallback standard for logs exported to storage or local media.
- Backup copies, restored environments, import/export staging, and evidence archives must inherit CMK or have explicit exceptions.
- Container Apps environment and any managed disks/files/shares used by runtime dependencies are not explicitly classified as data-at-rest candidates.

Recommendation:
- Add a `cmk-applicability-matrix.json` with service, data type, key URI, key owner, rotation policy, purge protection, diagnostic evidence, backup coverage, restore coverage, exception owner, and expiry.
- Require negative tests or policy evidence that resources missing required CMK cannot pass promotion.

### 6. Compliance evidence

**[CONCERN] Evidence package structure is useful, but auditors will need more narrative and traceability.**

The evidence backbone defines consistent package layout and validation results, which is good engineering evidence. It is not yet enough for FedRAMP / IL review because it lacks auditor-facing traceability and governance records.

Missing documentation:
- Control implementation statements and inherited/shared/customer-responsibility boundaries.
- SSP-ready diagrams for data flows, trust boundaries, identity paths, network paths, diagnostics paths, and media transfer.
- SAR/POA&M handling for failed controls, waivers, exceptions, and unsupported target SKU behavior.
- Change/release approval records for image BOM, Pulp version, plugin version, CMK changes, network changes, and diagnostics fallback.
- Evidence retention, redaction, and access-control procedure for sanitized and unsanitized evidence.

Recommendation:
- Add an auditor README template to every Phase 1 evidence package with environment scope, control summary, inherited controls, customer-operated controls, exceptions, risks, and links to artifacts.
- Add waiver expiry and authorizing official fields to the closeout rule.

### 7. Threat surface: top 3 unaddressed risks

**[BLOCKER] Risk 1 — Checksum-only transfer authenticity.**

The design says manifest signing is not required in the first release. Checksums detect accidental corruption but do not prove who approved the bundle or whether a malicious actor replaced both payload and checksum before high-side import. This is the most important unaddressed boundary risk.

Recommendation:
- Require signed manifests and signed image/package BOMs, or require explicit approved CDS custody evidence that provides equivalent authenticity and non-repudiation.

**[BLOCKER] Risk 2 — Hidden public dependency through runtime fallback.**

Static configuration checks can miss runtime fallback behavior from SDKs, package managers, base images, proxies, DNS search behavior, diagnostics agents, sidecars, or admin jobs.

Recommendation:
- Require deny-by-default egress and runtime DNS/flow evidence for startup and core workflows before #14 passes.

**[CONCERN] Risk 3 — Over-permissioned identities and evidence leakage.**

Without an exact identity/RBAC and evidence-redaction matrix, operators may accidentally grant broad roles or leak sensitive environment details in logs and issue evidence.

Recommendation:
- Require exact RBAC matrices, secret redaction scans, and negative tests for broad roles and secret-bearing outputs.

## Decision

Phase 1 remains on the right architectural path, but the current definition of done is not sufficient to claim FedRAMP High / IL4-IL6-ready high-side delivery. The team should continue implementation only with the following explicit closeout additions:

1. Signed manifest/BOM or approved equivalent CDS authenticity evidence.
2. Runtime zero-public-dependency proof using DNS, flow, route, and denied-egress evidence.
3. Boundary transfer record for removable media/CDS handling.
4. Exact identity/RBAC and Key Vault access matrix with secret-redaction validation.
5. CMK applicability matrix with key lifecycle, backup/restore, and waiver expiry.
6. FedRAMP/IL control mapping and auditor-facing evidence README.
\n---\n
# Wash Decision: P1-A2 Execute-Export Runtime Contract

- **Date:** 2026-05-05T01:40:36.497+00:00
- **Owner:** Wash
- **Scope:** Low-side `bundle_tools execute-export` command behavior and evidence semantics

## Decision

Implement `execute-export` as a thin orchestration command that executes native Pulp low-side sync/export REST operations directly (no reusable Pulp client abstraction), writes mandatory low-side evidence artifacts on every run, and enforces deterministic failure mapping to fixed CLI exit codes.

## Details

- Enforce low-side-only config + low-to-high boundary validation before execution.
- Preserve one-way boundary guarantees by rejecting feedback-enabled plans and omitting any high-to-low receipt fields from command output and summaries.
- Support `--dry-run` planning that validates config/plan and writes planned evidence without mutating Pulp.
- Require evidence paths to stay inside non-symlink directories to prevent path-escape writes.

## Rationale

This keeps the implementation aligned with Zoe’s P1-A2 contract: executable operator workflow, strict boundary controls, and verifiable evidence while avoiding scope creep into custom client abstractions or high-side behavior.
\n---\n
# Wash Decision: P1-A2 Implementation Map

- **Date:** 2026-05-05T01:40:36.497+00:00
- **Owner:** Wash
- **Scope:** P1-A2 operator workflow execution wiring (no implementation yet)

## Decision

Implement P1-A2 as a thin execution layer that consumes the existing declarative workflow plan and invokes native Pulp interfaces, with CLI subprocess orchestration as the default boundary and REST path metadata retained for traceability and fallback.

## Concrete implementation map

### Files to edit

1. `src/bundle-tools/bundle_tools/__main__.py`
   - Add a new operator-facing subcommand (plan + execute contract).
   - Reuse current `ConfigError`/`ManifestError`/`EvidenceError` exit handling.
2. `src/bundle-tools/bundle_tools/workflow.py`
   - Extend operation metadata to support executable operation payloads without replacing existing REST descriptors.
   - Add operation filtering/grouping helpers by stage/side.
3. `src/bundle-tools/bundle_tools/config.py`
   - Add optional execution/runtime config block (timeouts, retries, evidence strictness, Pulp auth/profile references).
4. `src/bundle-tools/bundle_tools/evidence.py`
   - Add helpers for per-operation evidence write paths and command/task result envelopes.
5. `src/bundle-tools/bundle_tools/manifest.py`
   - Reuse existing manifest validation as pre-import gate; add no new transfer direction semantics.
6. `src/bundle-tools/README.md`
   - Document operator command contract, required inputs, and evidence outputs.
7. `tests/test_bundle_tools_foundation.py`
   - Add unit tests for new command wiring, execution-plan shaping, and failure mapping.
8. `tests/phase1/test_validation_foundation.py`
   - Add validation expectations for any new evidence artifacts emitted by operator execution.

### New functions/classes to add

- `bundle_tools/workflow.py`
  - `ExecutionPolicy` dataclass (timeout/retry/fail-fast defaults).
  - `ExecutableOperation` adapter or helper that maps `WorkflowOperation` to runnable CLI/REST action.
  - `iter_operations(plan, *, side, stage=None)` helper.
- `bundle_tools/__main__.py`
  - `_run_workflow(args)` command handler.
  - `_emit_failure_summary(...)` helper for deterministic non-zero exits.
- `bundle_tools/evidence.py`
  - `operation_evidence_path(evidence_root, op_id)` helper.
  - `write_operation_record(...)` helper for command/task JSON evidence.
- New module recommended: `bundle_tools/executor.py`
  - `WorkflowExecutor` class to keep orchestration out of CLI parser.
  - `run_operation(...)`, `run_plan(...)`, and explicit boundary checks.

### Subprocess/REST boundary recommendation

- **Default execution boundary:** subprocess invocation of native `pulp` CLI using configured `pulp.cli` and optional `pulp.profile`.
- **REST metadata usage:** keep existing REST method/path in workflow plan for auditability, preflight checks, and controlled fallback.
- **Do not build a custom Pulp API wrapper/client layer.**
- **One-way transfer rule remains invariant:** no high-to-low receipt transport introduced by executor.

### Command naming recommendation

- New command: `bundle_tools run-workflow`
  - Required: `--config`, optional `--side` (must match config), optional `--plan-out`, `--evidence-dir`.
  - Execution mode flags (future-ready): `--dry-run`, `--from-op`, `--through-op`.
- Keep current commands unchanged:
  - `validate-config`
  - `plan`
  - `validate-manifest`
  - `evidence-index`

### Configuration inputs to introduce

Extend JSON config with optional `execution` block:

- `execution.mode`: `cli` (default), `rest` (controlled fallback only).
- `execution.failFast`: `true` default.
- `execution.taskPollSeconds`: default 5.
- `execution.taskTimeoutSeconds`: default 600.
- `execution.maxRetries`: default 0 for idempotency safety.
- `execution.captureCommandLog`: `true` default.
- `execution.requireManifestValidationBeforeImport`: `true` default.

These remain additive and backward-compatible with current config shape.

### Evidence artifacts for P1-A2 execution

Use existing stage index plus per-operation files:

- low side:
  - `operation-low-sync-repository.json`
  - `operation-low-run-native-export.json`
  - `pulp-sync-task.json`, `pulp-export-task.json`, `pulp-export-info.json`
  - `manifest.json`, `manifest.sha256`, `manifest-validation.json`
  - `command-log.txt`
- high side:
  - `operation-high-run-import-check.json`
  - `operation-high-run-native-import.json`
  - `operation-high-publish-imported-version.json`
  - `pulp-import-check.json`, `pulp-import-response.json`, `pulp-publication-task.json`
  - `apt-client-check.txt`, `manifest-validation.json`
  - `command-log.txt`

Evidence index remains authoritative directory inventory; no return bundle to low side.

### Failure-handling points

1. **Config load failure** (`ConfigError`) → exit 2 before execution.
2. **Plan/config side mismatch** → hard fail before first operation.
3. **Manifest validation failure before high import** (`ManifestError`) → stop import path.
4. **CLI subprocess non-zero / timeout** → capture stderr/stdout in operation evidence; fail-fast.
5. **Pulp async task failure/canceled** → persist task payload evidence and fail-fast.
6. **Evidence write failure** (`EvidenceError`/I/O) → fail operation; preserve partial log.
7. **Boundary violation detection** (feedback fields/reverse direction) → hard fail, no override.

## Rationale

Current foundation already encodes one-way direction controls, native Pulp REST action intent, and strict manifest/evidence validation. The safest extension is execution wiring that interprets this model, not replacing it with a bespoke client abstraction.
\n---\n
# Wash Decision Inbox — wash-phase1-code-accuracy-review

- **Date:** 2026-05-05T01:26:57.473+00:00
- **Owner:** Wash (Integration & Automation)
- **Decision:** Harden Phase 1 manifest validation so malformed numeric metadata fails with `ManifestError` (typed validation error) instead of uncaught `ValueError`.

## Context
During Phase 1 code-accuracy review, manifest checks were performing raw `int(...)` coercions on `payloadSize` and artifact `size`. Invalid values like `"oops"` caused unhandled exceptions and inconsistent CLI ergonomics.

## Outcome
Validation now enforces non-negative integer parsing via explicit helper checks and reports deterministic `ManifestError` messages. A focused unit test was added to lock the behavior.

## Why this matters
This keeps the bundle layer a thin orchestrator while still enforcing robust contract validation for transfer manifests and preventing false completion claims caused by validator crashes.
\n---\n
# Wash Phase 1 Integration Review Decision Input

- **Date:** 2026-05-05T01:42:22.430+00:00
- **Owner:** Wash (Integration & Automation)
- **Status:** Proposed for squad triage

## Decision Proposal

Treat current Phase 1 as **"platform-ready but workflow-partial"** for Phase 2. Before Phase 2 buildout, add explicit Definition-of-Done acceptance items for executable workflow contracts (sync/export/transfer/import/publish), transfer custody/evidence handoff, and CI enforcement of bundle + image validation gates.

## Why

Phase 1 artifacts clearly define Azure platform controls, Pulp topology intent, and OCI-to-ACR image handling. However, they stop short of requiring executable operator workflow semantics (resume, idempotency, failure classification, and deterministic evidence package promotion) that Phase 2 automation must rely on. Without these guardrails, Phase 2 risks mixing feature delivery with foundational integration plumbing.

## Requested Additions to Phase 1 Closeout Criteria

1. **Workflow execution contract:** required operation state machine, idempotency keys, retry/backoff policy, and partial-failure recovery points for low-side export and high-side import/publish jobs.
2. **Transfer handoff contract:** explicit artifact custody schema (what crosses boundary, checksum scope, acceptance/rejection metadata, and who signs off at each stage).
3. **Automation gate baseline:** CI job that runs bundle-tools unit tests, phase1_validation checks, manifest integrity checks, and deployment-image reference policy scan.
4. **Harness↔Azure equivalence tests:** required evidence mapping local flow assumptions to Azure Container Apps jobs, storage paths, private DNS, and ACR digest pinning behavior.

## Impact

This keeps Phase 2 focused on repository workflow implementation instead of retrofitting core integration scaffolding under schedule pressure.
\n---\n
# Wash — Pulp Single-Container Deployment Skill

**Date:** 2026-05-05T01:45:46.172+00:00
**Owner:** Wash (Integration & Automation)
**Status:** Proposed reference decision

## Decision

Use `.squad/skills/pulp-container-deployment/SKILL.md` as the team reference for standing up Pulp as a single bundled container during local development, smoke testing, pre-Azure validation, harness bootstrapping, and disconnected transfer rehearsals.

## Rationale

The official Pulp OCI quickstart is now captured in a project-specific operational playbook. The skill makes runtime choice explicit, preserves the existing `container-runtime-harness` convention, forbids floating image tags in automation, and requires post-deploy verification before any bundle import/export workflow consumes the instance.

## Consequences

- Agents should use the skill before authoring ad hoc Podman or Docker commands for single-container Pulp.
- Automation should pin Pulp images and use `PULP_PULL_POLICY=never` for repeatable air-gap work unless a test is explicitly connected-mode.
- Local deployment readiness must flow into the `local-container-validation` ladder before being used as evidence for bundle workflows.
\n---\n
# P1-A2 Execution Contract — Local Low-Side Export Command

**Date:** 2026-05-05T01:40:36.497+00:00  
**Author:** Zoe (Lead / Solution Architect)  
**Status:** APPROVED FOR IMPLEMENTATION  
**Scope:** Minimum acceptance contract for wiring the existing declarative `bundle_tools` workflow plan into an executable operator command against the local Pulp harness.

## Decision

P1-A2 is a narrow low-side export execution slice. It must turn the existing `bundle_tools plan` output into one executable operator command that runs the low-side Pulp sync and native export path against an already-running local Pulp harness.

It does **not** complete the full low→high workflow. It does **not** earn G2 or G3 by itself.

## Command Surface

Add one operator-facing command:

```sh
PYTHONPATH=src/bundle-tools python3 -m bundle_tools execute-export \
  --config <low-side-config.json> \
  --pulp-url http://localhost:${PULP_LOW_HTTP_PORT:-18080} \
  --batch-id <operator-batch-id> \
  --evidence-dir <evidence-dir> \
  --output json
```

Minimum required options:

| Option | Required | Contract |
|--------|----------|----------|
| `--config` | Yes | Existing low-side `bundle_tools` config. Must validate with `validate-config`. |
| `--pulp-url` | Yes | Base URL for the already-running local low-side Pulp API. |
| `--batch-id` | Yes | Operator-provided batch identifier used in output and evidence names. |
| `--evidence-dir` | Yes | Directory where command evidence is written. |
| `--output json` | Yes for P1-A2 | Machine-readable operator summary. Text/table output can wait. |

Optional implementation-safe flags:

| Option | Contract |
|--------|----------|
| `--plan-file <path>` | Use a previously generated plan instead of building one from config. The plan must still match the config side and one-way boundary. |
| `--timeout-seconds <n>` | Maximum wait per Pulp task. Default may be conservative for local harness. |
| `--poll-interval-seconds <n>` | Task polling interval. |
| `--dry-run` | Validate config, build plan, and check Pulp status without mutating Pulp. |

## Execution Boundaries

The command may execute only these P1-A2 operations:

1. Validate low-side config and one-way workflow boundary.
2. Check local Pulp status at `--pulp-url`.
3. Create or locate the configured APT remote/repository objects needed for the local fixture sync.
4. Trigger repository sync through native Pulp REST or `pulp-cli`.
5. Poll the sync task to a terminal state.
6. Resolve immutable repository version hrefs.
7. Create or locate a native Pulp exporter.
8. Trigger a native Pulp export.
9. Poll the export task to a terminal state.
10. Read the export resource and return task IDs, repository version hrefs, TOC information, and `output_file_info`.
11. Write P1-A2 evidence.

The command must not:

- Deploy Azure resources.
- Start, stop, or configure containers. The local Pulp harness is a precondition.
- Pull public images or change private image settings.
- Execute high-side import, import-check, publish, APT client validation, or no-egress validation.
- Generate the transfer manifest. That remains P1-A3.
- Validate staged media checksums. That remains P1-A4.
- Add high-to-low receipts, acknowledgements, or any feedback path.
- Build a custom Python Pulp API wrapper. A thin executor may call native REST endpoints or `pulp-cli`, but must not introduce a reusable Pulp client abstraction that mirrors Pulp's API.
- Add SQLite, PostgreSQL, or another state store for Pulp task/export state.

## Required Success Output

On success, stdout must be JSON with at least:

```json
{
  "status": "ok",
  "batchId": "<operator-batch-id>",
  "side": "low",
  "direction": "low-to-high",
  "pulpUrl": "http://localhost:18080",
  "syncTaskHref": "/pulp/api/v3/tasks/<id>/",
  "exportTaskHref": "/pulp/api/v3/tasks/<id>/",
  "exporterHref": "/pulp/api/v3/exporters/core/pulp/<id>/",
  "exportHref": "/pulp/api/v3/exporters/core/pulp/<id>/exports/<id>/",
  "repositoryVersionHrefs": [
    "/pulp/api/v3/repositories/deb/apt/<id>/versions/<n>/"
  ],
  "tocInfo": {},
  "outputFileInfo": {},
  "evidenceDir": "<evidence-dir>"
}
```

`tocInfo` and `outputFileInfo` must be copied from Pulp's native export resource, not recomputed by `bundle_tools`.

## Required Evidence Outputs

The command must write these files under `--evidence-dir`:

| File | Required Content |
|------|------------------|
| `workflow-plan.json` | The exact plan the executor used. |
| `command-log.txt` | Ordered operator-safe log of steps, timings, and terminal status. Secrets must be redacted. |
| `pulp-status.json` | Local low-side Pulp status response. |
| `pulp-sync-task.json` | Terminal sync task response. |
| `pulp-repository-version.json` | Repository version hrefs selected for export. |
| `pulp-exporter.json` | Exporter resource created or reused. |
| `pulp-export-task.json` | Terminal export task response. |
| `pulp-export-info.json` | Export resource including `toc_info` and `output_file_info`. |
| `execution-summary.json` | Same summary contract as stdout plus start/end timestamps. |

P1-A2 evidence is low-side only. It must not contain high-side import status or any high-to-low receipt.

## Failure Behavior

The command must fail fast and preserve partial evidence.

| Condition | Expected Behavior |
|-----------|-------------------|
| Invalid config or side is not `low` | Exit non-zero before calling Pulp; write no mutation evidence. |
| Plan allows feedback to low | Exit non-zero before calling Pulp. |
| Pulp status endpoint unreachable | Exit non-zero with clear precondition failure. |
| Pulp API/CLI call fails | Stop at the failed operation; write response body or sanitized error to `command-log.txt`. |
| Pulp task reaches `failed` or `canceled` | Exit non-zero; write terminal task JSON. |
| Pulp task times out | Exit non-zero; write last observed task JSON. |
| Evidence write fails | Exit non-zero; do not claim export success. |

Recommended exit code meanings:

- `0`: success
- `2`: config, plan, or operator input validation failure
- `3`: local harness/Pulp precondition failure
- `4`: Pulp operation, task failure, or timeout
- `5`: evidence write or output serialization failure

## Validation Gates for P1-A2

P1-A2 can be accepted when all of the following pass:

1. Existing P1-A1 tests remain green.
2. Unit tests prove the command rejects:
   - high-side configs,
   - non-`low-to-high` direction,
   - `feedbackToLowAllowed: true`,
   - missing `--batch-id`,
   - missing or unwritable evidence directory.
3. Image-free executor tests use a local fake Pulp HTTP service or mocked subprocess calls to prove:
   - status check,
   - sync task polling,
   - export task polling,
   - export info extraction,
   - failure on failed task,
   - timeout handling,
   - required evidence file creation.
4. If private image configuration is available, run the command against the local single-container Pulp harness and capture the required evidence files.
5. `python3 -m unittest discover tests` passes.

P1-A2 does not require `run-low-high-e2e.sh` to pass because that remains blocked by private image configuration and covers later high-side slices.

## Reviewer Gates

- **Kaylee implementation review:** command surface, config validation, and executor boundaries.
- **River validation review:** failure cases, evidence shape, and local/fake Pulp test coverage.
- **Zoe architecture review:** no Azure scope creep, no custom Pulp wrapper, no state-store creep, no feedback path.

G2 remains blocked until P1-A2 through P1-A6 pass together against the local harness with evidence collected.

## Blocked by Private Image Configuration

These items remain outside P1-A2 acceptance unless private/internal image references are provided:

- Real execution against `pulp-low` using `PULP_SINGLE_IMAGE`.
- APT client verification using `APT_CLIENT_IMAGE`.
- Full `run-low-high-e2e.sh`.
- High-side no-egress proof.
- Any G2/G3 readiness claim.

If private images are unavailable, P1-A2 may still be implemented and reviewed with image-free tests plus explicit `external_configuration` status for live harness evidence.

## Handoff

Kaylee should implement this command as a thin executor over the existing declarative plan. River should own negative tests and evidence-shape validation. Book should update the operator runbook only after the command behavior lands.
\n---\n
# Phase 1 Completion Review — Gate G1 Only

**Date:** 2026-05-05T01:26:57.473+00:00
**Author:** Zoe (Lead / Solution Architect)
**Status:** Approved with corrections
**Scope:** Review most recent changed deliverables supporting the Phase 1 application-first completion claim.

## Decision

Approve the current completion claim only when phrased as **Phase 1 Gate G1 / first application-first slice is done**. Do not describe full Phase 1, Track A readiness, G2, G3, or Azure deployment as complete.

The application foundation under `src/bundle-tools/`, validation tests under `tests/`, and operator documentation support an image-free first slice: configuration validation, one-way manifest/evidence conventions, declarative native Pulp workflow planning, and static harness validation. This is enough for G1, not enough for executable export/import automation.

## Review Classifications

### Blocking

- None for the narrowed G1 / first application-first slice claim.
- Any statement that shortens this to “Phase 1 is done” is blocking and must be revised to “G1 / first application-first slice is done.”

### Non-blocking corrections

- Standardize CLI naming before P1-A2 starts: earlier backlog language says `hydra`, while the delivered slice exposes `bundle_tools`. P1-A2 remains the next actionable item, but it must explicitly either build on `bundle_tools` or introduce the `hydra` alias/scaffold.
- Correct operator docs that still imply `PULP_PULL_POLICY=missing` or public images are the normal current path. The committed template and validation posture use placeholder private/internal images with `PULP_PULL_POLICY=never`; connected public-image testing must remain explicitly optional and not a high-side/AirGap validation path.
- Clean trailing whitespace in `.squad/decisions.md` before merge hygiene gates are treated as clean.

### External configuration blockers

- Full local Pulp e2e and Compose validation remain blocked on real private/internal tag-plus-digest image references for Pulp, support services, and the APT client.
- Azure deployment remains deferred until Track A reaches G3. No Bicep/ARM/Azure SDK work is approved by this G1 result.

### Unrelated dirty-worktree items

- `.github/copilot-instructions.md`, `.github/agents/agentic-workflows.agent.md`, `.github/agents/squad.agent.md`, `.squad/config.json`, `.squad/templates/skills/model-selection/SKILL.md`, Ralph/Scribe charter edits, health reports, and circuit-breaker files are governance/model-policy or team-state changes. They should not be counted as Phase 1 deliverables.
- The repository model policy changes are valid as governance: allowed models are `gpt-5.5`, `gpt-5.3-codex`, and `gpt-5-mini`; Anthropic/Claude models remain disallowed.

## Validation Evidence

- Python unit tests passed: 14 tests.
- Image-free environment validation returns `external_configuration` for placeholder private image references, not failure.
- Harness static validation passed.
- No browser UI or rendered documentation site exists in this slice, so Playwright visual validation was not required.

## Next Gate

P1-A2 is the next actionable item: wire the delivered workflow plan into an executable operator command against a running local Pulp harness, collect evidence, and keep Azure deployment deferred.
\n---\n
# Phase 1 Scope Review — Azure/Pulp Foundation

**Date:** 2026-05-05T01:42:22.430+00:00
**Owner:** Zoe (Lead / Solution Architect)
**Status:** APPROVED WITH REQUIRED RECONCILIATION
**Scope:** Phase 1 definition of done for issues #8–#14 in `openspec/changes/airgap-binary-hydration-service/`.

## Decision

Phase 1's definition of done is directionally correct for proving the Azure/Pulp platform foundation across low side and high side, but it is not ready to execute as written. The issue set covers the right platform surfaces: Azure foundation, Pulp runtime topology, PostgreSQL-compatible persistence, image mirroring, private networking/DNS, diagnostics/operations, and an integrated milestone test.

Before #8–#14 are treated as executable Azure implementation gates, the spec must be reconciled with current team decisions:

1. Application-first work remains the active Phase 1 path until the G3 gate authorizes Azure deployment work.
2. Pulp remains the repository system of record; custom code should not duplicate Pulp state tracking.
3. Any additional PostgreSQL-backed service state must be justified as workflow/audit state outside Pulp's native authority, not as a replacement for Pulp export/import/publication history.

## Findings

- [OK] Issues #8–#14 collectively cover the right foundation scope for low-side Azure Commercial and high-side Azure Government/AirGap platform proof.
- [OK] The evidence backbone requires target-environment metadata, resource inventory, control evidence, validation results, negative tests, and issue closeout evidence.
- [OK] The #14 milestone gate is correctly positioned as the integrated Phase 1 to Phase 2 authorization decision.
- [CONCERN] Low/high parity is implied through shared controls and version rules, but there is no mandatory parity-diff artifact proving that differences are intentional and environment-specific.
- [CONCERN] The evidence package layout currently says SHOULD. For Phase 1 closure it should be MUST unless a waiver is approved.
- [CONCERN] Dependencies among #8–#13 are implicit. #9 depends on #8/#11/#12; #10 depends on #8/#12/#13; #13 depends on #10/#12; #14 depends on all negative tests and waivers.
- [BLOCKER] The OpenSpec Phase 1 platform definition conflicts with the current app-first sequencing decision if interpreted as immediate Azure implementation work.
- [BLOCKER] The PostgreSQL state foundation needs scope reconciliation with the decision that Pulp is the system of record and that custom workflow code stays thin.

## Required actions

1. Add a required low/high parity comparison artifact to #14 evidence.
2. Change Phase 1 evidence package layout from SHOULD to MUST or require an approved evidence-format waiver.
3. Add explicit dependency links and closure ordering among #8–#13.
4. Clarify that #8–#14 are Azure platform gates authorized after app-first G3, unless Zoe approves a sequencing exception.
5. Clarify PostgreSQL scope as workflow/audit/operational state only where Pulp does not already provide authoritative state.
6. Validate Azure Government/AirGap target regions, SKUs, private link behavior, diagnostics fallback, CMK support, Container Apps limits, and ACR import workflow early.

## Phase 2 readiness position

If reconciled and completed with real target-environment evidence, Phase 1 will authorize Phase 2 repository workflow implementation for the validated deployment scope only. Without reconciliation, Phase 2 risks building workflow/state behavior against an outdated platform contract.
\n---\n
### 2026-05-05T01:45:46.172+00:00: Skill Review — pulp-container-deployment
**Reviewer:** Zoe (Lead)
**Author:** Wash
**Artifact:** .squad/skills/pulp-container-deployment/SKILL.md
**Checklist:** .squad/agents/river/validation-checklist-pulp-deploy-skill.md

**Verdict:** REVISE

The draft is directionally strong and consistent with the team's application-first, runtime-portable, thin-orchestration decisions. It is not ready as an executable skill yet. The main gaps are operational: permissions, secret verification, FUSE troubleshooting, port/container conflicts, upgrade safety, disk sizing, and evidence requirements. Those are real deployment-failure paths, not style issues.

**Checklist Results:**
| # | Item | Result | Notes |
|---|------|--------|-------|
| 1 | Directory scaffold | PASS | Creates and maps `settings`, `pulp_storage`, `pgsql`, `containers`, and `container_build`. |
| 2 | Directory purpose | FAIL | Add that `settings` also stores database encrypted-fields key material where applicable. Keep the current mount-purpose table, but align wording with River's expected data classes. |
| 3 | Persistence requirements | FAIL | Clarify that `settings`, `pulp_storage`, and `pgsql` are mandatory consistency-set backups; `containers` and `container_build` are less critical but should be preserved when using `pulp_container` to improve recoverability/stability. |
| 4 | Ownership and permissions | FAIL | Add preflight ownership/write checks, rootless Podman guidance, `podman unshare chown 700:700` and Docker `sudo chown 700:700` folder-volume patterns where applicable, plus safe recovery for bind-mount permission denied errors. |
| 5 | Templated `CONTENT_ORIGIN` | FAIL | Replace reusable snippets that derive production guidance from `$(hostname)` with `PULP_CONTENT_ORIGIN` or explicit operator-provided FQDN/port variables; keep localhost only in disposable examples. |
| 6 | Settings documentation link | FAIL | Reference Pulpcore settings documentation and state that the quickstart `settings.py` is minimal, not exhaustive production configuration. |
| 7 | `SECRET_KEY` production safety | FAIL | Add persistence and uniqueness verification: reject placeholders/defaults, require per-environment generation, keep it backed up with `settings`, and avoid logging the value. |
| 8 | Podman with SELinux | PASS | Complete Podman SELinux run example includes `:Z`, five mounts, publish/name/image, and `/dev/fuse`. |
| 9 | Podman without SELinux | PASS | Includes a no-SELinux variant and explains when to drop persistent-mount labels. |
| 10 | Docker substitution path | PASS | Includes Docker run path with required mounts/options and notes Docker permission differences. |
| 11 | HTTPS variant | PASS | Covers `PULP_HTTPS=true`, port `443`, `CONTENT_ORIGIN`, and HTTPS CLI profile. |
| 12 | Image pinning policy | PASS | Forbids floating tags in automation and prefers tag-plus-digest for CI/disconnected runs. |
| 13 | `/dev/fuse` explained | FAIL | Explain why FUSE is needed for container/image build workflows, add `[ -e /dev/fuse ]` or equivalent preflight, and document expected failure symptoms/remediation when unavailable. |
| 14 | Admin password reset | PASS | Requires `pulpcore-manager reset-admin-password` before usable setup. |
| 15 | Health check not over-trusted | PASS | Status endpoint is included and explicitly not sufficient by itself. |
| 16 | Deploy check required | PASS | Runs `pulpcore-manager check --deploy` as required readiness evidence. |
| 17 | `SECRET_KEY` uniqueness check | FAIL | Add a repeatable non-leaking check that active `SECRET_KEY` exists and is not `replace-with...`, `changeme`, sample, reused, or empty. |
| 18 | `pulp_container` plugin setup | FAIL | Add concrete key-pair/certificate generation/authentication steps or link to plugin docs; do not leave `pulp_container` readiness as a vague note. |
| 19 | Worker status verification | PASS | Requires online workers and expected plugin versions from status JSON. |
| 20 | `pulp-cli` install | PASS | Includes venv and `pip install 'pulp-cli[pygments]'`. |
| 21 | `pulp-cli` config | PASS | Includes HTTP and HTTPS `pulp config create` examples aligned to base URL. |
| 22 | `pulp-cli` verification | PASS | Includes `pulp status`. |
| 23 | Cross-skill: `container-runtime-harness` | PASS | References runtime helper pattern and air-gap pull policy. |
| 24 | Cross-skill: `local-container-validation` | PASS | Imports the validation ladder and avoids single-health-check readiness. |
| 25 | Cross-skill: `pulp-bundle-workflows` | PASS | Preserves native Pulp export/import, one-way transfer, and manifest validation boundary. |
| 26 | Air-gap pre-pulled images | PASS | Requires pre-pull/save/load or equivalent staging and image identity evidence. |
| 27 | Air-gap no public registry access | PASS | High-side guidance rejects public registry/package access and requires private/internal references. |
| 28 | Air-gap pull policy | PASS | Requires `PULP_PULL_POLICY=never` / `--pull=never` for offline and repeatability checks, with connected-mode exceptions. |
| 29 | Private ACR references | PASS | Supports private/internal registry and high-side digest-pinned references. |
| 30 | Compose tradeoffs | PASS | Distinguishes single-container smoke paths from Compose service-boundary/scale validation. |
| 31 | Compose scaling guidance | FAIL | Add the warning that Compose scaling is local validation only and not equivalent to production Kubernetes/operator/Container Apps scaling. |
| 32 | Compose folder-volume variant | FAIL | Document the folder-volume Compose option with required ownership preparation for existing directories. |
| 33 | Anti-pattern: hardcoded hostnames | FAIL | Add an explicit anti-pattern forbidding hardcoded hostnames in reusable `CONTENT_ORIGIN`, CLI config, and automation examples. |
| 34 | Anti-pattern: skipping password reset | FAIL | Add skipping `pulpcore-manager reset-admin-password` to Anti-Patterns / review-failure list. |
| 35 | Anti-pattern: `latest` in automation | PASS | Explicitly forbids floating tags in CI, release automation, and air-gap rehearsals. |
| 36 | Anti-pattern: ignoring SELinux flags | FAIL | Add an anti-pattern/review failure for SELinux-capable Podman guidance that omits `:Z` without an explicit no-SELinux rationale. |
| 37 | Anti-pattern: pulling in air-gap | PASS | Marks public/disconnected pulls as invalid and requires `--pull=never`. |
| 38 | Anti-pattern: readiness from health alone | FAIL | Strengthen readiness language: `/status/` must be paired with deploy check, worker state, CLI auth, plugin setup, and at least one workflow smoke before declaring ready. |
| 39 | Edge: port conflict | FAIL | Add preflight checks for host ports, alternate host-port strategy, and required updates to `CONTENT_ORIGIN` and CLI config when ports change. |
| 40 | Edge: volume permissions | FAIL | Add symptoms, diagnostics, SELinux-vs-ownership distinction, and safe remediation that preserves persistent data. |
| 41 | Edge: container name conflict | FAIL | Check whether `pulp` already exists; document inspect/reuse, disposable stop/remove, or unique-name choices. |
| 42 | Edge: migrations/upgrades | FAIL | Add image-upgrade guidance: read release notes, back up `settings`/`pulp_storage`/`pgsql`, expect migrations, and run deploy checks after upgrade. |
| 43 | Edge: disk space | FAIL | Add disk preflight for content storage, PostgreSQL, container build/temp paths, and transfer/import growth, plus full-disk failure handling. |
| 44 | Edge: FUSE unavailable | FAIL | Add explicit `/dev/fuse` availability check, host/runtime limitations, and a blocking failure message when container workflows require it. |
| 45 | Validation evidence | FAIL | Define evidence set: pinned image, redacted settings, exact run command, status JSON, deploy-check output, worker status, CLI verification, plugin setup confirmation, bundle import smoke, and negative-test notes. |
| 46 | Manual handoff readiness | PASS | Connects deployed high side to manifest, checksum, import-check, import, publish, evidence, and one-way transfer expectations. |
| 47 | Concrete failure-mode language | FAIL | Several sections use aspirational wording without symptoms or block criteria. Add explicit good/bad criteria for permissions, FUSE, ports, names, upgrades, disk, plugin setup, and evidence. |

**Critical Gaps (must fix):**
- Add ownership/permission preflights and remediation. Bind-mount permission failures are common and will block startup or corrupt operator recovery choices.
- Make `CONTENT_ORIGIN` and port handling variable-driven. Hardcoded host/port assumptions break customer deployments and CLI access.
- Strengthen `SECRET_KEY` handling with non-leaking uniqueness/persistence checks. A placeholder secret in a copied deployment is a real security failure.
- Add `/dev/fuse` preflight and troubleshooting. The skill includes the flag but does not tell operators how to know whether the runtime can support required container workflows.
- Add edge-case gates for port conflict, container name conflict, upgrade migrations, disk capacity, and persistent-volume recovery.
- Define a complete evidence package. Command transcripts alone are not enough for AirGap/customer review.

**Minor Gaps (should fix):**
- Add Pulpcore settings and `pulp_container` documentation references.
- Clarify `containers` and `container_build` as recommended-to-preserve, not simply disposable.
- Add explicit anti-pattern entries for skipped password reset, hardcoded hostnames, and omitted SELinux labels.
- Add Compose folder-volume ownership preparation and a caveat that Compose scaling is not production scaling.

**Strengths:**
- Correctly preserves team constraints: no custom Pulp API wrapper, native Pulp CLI/REST, one-way low-to-high transfer, and application-first validation before Azure.
- Good runtime portability posture: Docker and Podman are both represented, with the harness helper pattern called out.
- Solid baseline deployment sequence: scaffold, settings, pinned image, run variants, HTTPS, status, deploy check, restart, CLI setup, and air-gap image staging.
- AirGap framing is aligned with private/internal registry use and no public high-side package source access.

**Revision Instructions:**
1. Add a "Preflight" section before the run commands covering runtime selection, container name availability, port availability, disk space, `/dev/fuse`, directory ownership/write access, and SELinux detection.
2. Replace reusable `CONTENT_ORIGIN` guidance with explicit variables (`PULP_CONTENT_ORIGIN`, host port variables, scheme) and update HTTP/HTTPS, CLI, and alternate-port examples to use those variables.
3. Expand `settings.py` guidance: link to Pulpcore settings, document encrypted-field key material under `settings`, and add non-leaking `SECRET_KEY` verification and backup rules.
4. Add permissions troubleshooting with safe commands for rootless Podman and Docker folder-volume ownership; explicitly forbid broad chmod/delete recovery on persistent data.
5. Add `/dev/fuse` explanation, check, failure symptoms, and blocking criteria.
6. Add `pulp_container` plugin setup instructions or authoritative links for key/certificate generation and authentication readiness.
7. Expand Compose section with folder-volume ownership prep and a clear "Compose scaling is local validation, not production scaling" caveat.
8. Add edge-case sections for port conflicts, container name conflicts, image upgrades/database migrations, disk-full conditions, and persistent-data-safe recovery.
9. Expand Anti-Patterns with skipped admin reset, hardcoded hostnames in reusable automation, ignored SELinux labels, and readiness from `/status/` alone.
10. Add an Evidence section listing required artifacts and redaction rules: pinned image/digest, redacted settings, exact run command, status JSON, deploy-check output, worker/plugin status, CLI verification, plugin setup confirmation, bundle import smoke, and negative-test notes.

# Simon — P1-A2 Control Review

**Date:** 2026-05-05T01:40:36.497+00:00  
**Owner:** Simon  
**Scope:** `bundle_tools execute-export` implementation, tests, and operator documentation  
**Status:** ACCEPTED WITH CONTROL CORRECTIONS

## Decision

P1-A2 `execute-export` is accepted for the image-free low-side execution lane after applying tightly scoped security/control guardrail fixes.

## Controls Confirmed

- Low-side-only execution: `execute-export` rejects high-side configs and validates low-to-high workflow plans before Pulp calls.
- No high-side import/publish in P1-A2: the command only checks low-side status, syncs repositories, resolves repository versions, creates/reuses an exporter, runs native export, and writes low-side evidence.
- No high-to-low feedback path: plans with feedback enabled fail before execution, and stdout/evidence summaries omit receipt or return-channel fields.
- No Azure deployment creep: implementation is local bundle tooling only; it does not deploy Azure resources or manage containers.
- No public image/dependency pull behavior: `execute-export` does not pull images or install dependencies. Runtime image validation remains in the harness/static validation lane.
- No custom reusable Pulp API wrapper: the implementation uses a private, command-scoped HTTP helper for native Pulp REST calls and does not introduce a reusable Pulp API abstraction or state store.
- Evidence path containment: evidence directories reject symlink escape paths.
- Plan input containment: plan files now reject symlink paths before loading.
- Inline secret controls: config rejects inline secret-shaped fields and now rejects credential-bearing upstream URLs; `--pulp-url` also rejects embedded credentials.
- Output/log redaction: evidence JSON, command logs, and Pulp error strings are redacted before persistence or summary output.
- Deterministic failure behavior: dry-run no longer masks an unreachable Pulp status endpoint; this remains exit code 3 as a precondition failure.
- Documentation scope: docs now state P1-A2 proves only the low-side image-free execution lane and must not be used as G2/G3 or high-side readiness evidence.

## Corrections Applied

1. Rejected embedded credentials in repository `upstreamUrl` and `--pulp-url`.
2. Added redaction for evidence JSON, command log text, and Pulp HTTP error text.
3. Rejected symlink plan-file inputs.
4. Made dry-run with `--plan-file` fail when Pulp status is unreachable instead of returning success.
5. Corrected operator docs to avoid high-side/full-workflow readiness overclaims.
6. Added unit tests for the new guardrails.

## Validation Evidence

- `PYTHONPATH=src/bundle-tools python3 -m unittest discover -s tests -p 'test*.py'` — passed.
- `python3 src/bundle-tools/phase1_validation.py harness-static .` — passed.
- `git --no-pager diff --check` — passed.

## Residual Scope Boundaries

- Live Pulp runtime evidence remains externally blocked until approved private/pre-loaded images and environment-specific credentials are available.
- High-side import, import-check, publish, APT client verification, no-egress proof, and G2/G3 claims remain out of P1-A2 scope.

# Decision: Pulp Validation Failed

**Date:** May 5, 2026
**Owner:** Switch
**Status:** BLOCKED

The requested local Pulp deployment validation on `http://localhost:8080/pulp/api/v3/status/` failed. Pulp is not running, and port 8080 is currently occupied by qBittorrent WebUI. We must deploy the local Pulp container harness on a different port or stop existing services to proceed with automated e2e validation in the future.

# Decision: Pulp API Validation Success

**Date:** May 5, 2026
**Owner:** Switch

The local validation of the Pulp deployment manually started on port `8081` has succeeded. The `/pulp/api/v3/status/` endpoint returned a fully formed JSON object, indicating that the container workers have initialized fully and are ready for requests.

*Note:* Playwright MCP tools were non-functional in the current environment configuration, so CLI `curl` fallback was utilized for validation as stipulated by MCP fallback procedures.

# Decision: Pulp Port Conflict

**Date:** May 5, 2026
**Owner:** Trinity

The local Pulp container deployment encountered a port conflict on port 8080. To proceed with the deployment validation without impacting other running services, the local environment port was shifted to `8081` via the `.env` file (`PULP_HTTPS_PORT=8081`).

# Zoe — P1-A2 Lead Gate Review

**Date:** 2026-05-05T01:40:36.497+00:00
**Owner:** Zoe (Lead / Solution Architect)
**Todo:** `p1-a2-lead-gate-review`
**Status:** APPROVED WITH SCOPE LIMITS

## Verdict

P1-A2 is complete for the narrow low-side `execute-export` slice only.

The implementation satisfies the approved execution contract: one operator-facing `bundle_tools execute-export` command validates low-side config and one-way plan boundaries, checks an already-running low-side Pulp API, runs native Pulp sync/export REST operations, returns sync/export task references plus repository version, TOC, and `output_file_info`, and writes low-side evidence.

## Gate Inputs Reviewed

- Zoe execution contract: approved scope is low-side export execution only.
- Wash implementation map and runtime contract: implementation stays a thin command-scoped native Pulp REST executor and avoids Azure, manifest-generation, import/publish, state-store, and custom Pulp-wrapper scope.
- River validation plan, execution tests, and closeout: image-free validation lane is accepted.
- Simon control review: accepted after control corrections for one-way boundary, path containment, credential rejection, redaction, and dry-run precondition behavior.
- Book docs update: operator docs describe `execute-export` as P1-A2 low-side only and avoid G2/G3 or high-side readiness claims.

## Validation Evidence

- `PYTHONPATH=src/bundle-tools python3 -m unittest discover -s tests -p 'test*.py'` — passed, 34 tests.
- `python3 src/bundle-tools/phase1_validation.py harness-static .` — passed.
- `git --no-pager diff --check` — passed.

## Scope Approved

Approved:

1. Low-side config and one-way boundary validation.
2. Pulp status precondition check against `--pulp-url`.
3. Native Pulp repository/remote sync and task polling.
4. Immutable repository version resolution.
5. Native Pulp exporter creation/reuse and export task polling.
6. Export resource readout using Pulp-native `toc_info` and `output_file_info`.
7. Low-side evidence files for the execution contract.
8. Deterministic failure handling for validation, precondition, Pulp task, timeout, and evidence-write failures.

Not approved or claimed:

- Azure deployment or Track B readiness.
- Full low→high local e2e.
- Transfer manifest generation or staged-media checksum validation.
- High-side import-check, import, publish, APT client validation, or no-egress proof.
- Any high-to-low receipt, acknowledgement, callback, or feedback channel.
- Runtime proof using private/pre-loaded Pulp and APT client images.

## G2 Decision

G2 remains blocked.

Reason: G2 requires P1-A2 through P1-A6 to pass together against the local harness with evidence collected. P1-A2 proves only the low-side `execute-export` command contract in the current image-free lane. Private/internal image configuration and the later manifest/import/publish slices are still required before G2 can unlock.

## Next Actionable Phase 1 Item

Start P1-A3: transfer manifest generation (`bundle_tools manifest create`).

P1-A3 should consume P1-A2 export output/evidence, generate the handoff manifest from Pulp-native export metadata, preserve the low→high boundary, and avoid recomputing what Pulp already records unless needed for the physical media custody manifest.

## Review Closeout

P1-A2 is approved as complete for its narrow low-side slice. Do not broaden this decision into a full Phase 1, G2, G3, Azure, or AirGap readiness claim.

