# Wash's Test Evidence

**Decision Date:** 2026-05-05Z
**Role:** River (Tester)

Following the new user directive for documented proof, Playwright CLI attempt was made for the Pulp repository. Mock/Fallback CLI capture was completed and saved in the `evidence/` directory because of rendering constraints. Moving forward, all validation scripts will include mandatory Playwright screenshot artifacts or standard output streams to `evidence/`.---
date: "2026-05-05T00:00:00Z"
context: "User requested that all test events show evidence for clear system validation."
decision: "All tests must capture evidence using the Playwright CLI and log it into the \`evidence/\` folder with a clear description. This rule has been codified in agent instructions and team guidelines."
---

---
date: "2026-05-06T20:27:01.226+00:00"
author: "river"
topic: "p2.0-p2.1 validation gate lane split"
---

# Decision: P2.0 or P2.1 validation requires dual-lane gating

To keep Wash and Simon outputs immediately reviewable while preserving disconnected realism, P2.0 or P2.1 validation is split into two enforced lanes:

1. PR-static lane for contract/schema/policy checks that can fail fast in pull requests.
2. Disconnected/local e2e lane for runtime import or publish or apt-consumption proof plus denied-egress evidence.

Signature controls are fail-closed: missing or invalid signature blocks import unless an approved waiver includes expiry and compensating controls, and waiver usage is captured in append-only audit evidence.


---
date: "2026-05-06T20:27:01.226+00:00"
author: "simon"
topic: "p2 transfer manifest custody"
status: "proposed-contract"
---

# Decision: P2.1 transfer manifest is a boundary and custody contract

Phase 2 should validate a top-level `schemas/transfer-manifest.schema.json` contract for low-side to high-side rehearsal manifests. The manifest must remain thin: it records batch identity, `low-to-high` direction, no-feedback controls, file inventory, hashes, signing or waiver state, custody linkage, and evidence references while native Pulp outputs remain the content authority.

Detached manifest signatures are the target control. If signing is deferred for local Phase 2 only, a waiver is acceptable only when it records approver role, rationale, expiry, compensating controls, and `productionBlocker: true`.

High-side import must fail closed before Pulp `import-check` when direction, custody, signature or waiver, path containment, symlink rejection, size, SHA-256, expected file inventory, or high-side no-egress controls fail.


---
date: "2026-05-06T20:26:13.550+00:00"
author: "wash"
topic: "ci pipeline rollout for oss trust"
---

# Decision: Adopt a six-lane CI model with staged enforcement

We should adopt six named pipelines with explicit ownership and rollout order:

1. `ci-quality.yml` (required PR gate): ruff, mypy, pytest+coverage, shellcheck in sandbox container with coverage artifact.
2. `ci-static.yml` (required PR gate): static script validation, evidence-structure validation, solution schema validation, and contract checks; force repo-local `PULP_STORAGE_ROOT` in CI to avoid NAS-path mkdir failures.
3. `ci-container.yml` (required on container changes): build sandbox image, enforce pinned base image digest, scan with Trivy, push to GHCR on `main`.
4. `ci-e2e-smoke.yml` (initially non-blocking, then promote): run `tests/e2e/pulp-local-apt-smoke.sh`, validate structured evidence, upload evidence artifact.
5. `ci-audit.yml` (weekly + dependency changes): pip-audit, SBOM generation, and license report artifacts.
6. `ci-release-integrity.yml` (release tags): checksum manifest, artifact signing, provenance attestation, and verification artifacts aligned to low-to-high transfer custody.

Reference implementation details, YAML snippets, runner/tooling requirements, estimated runtime, and local-equivalent commands are captured in `docs/proposals/ci-pipelines.md`.


---
date: "2026-05-06T20:26:13.550+00:00"
author: "zoe"
topic: "ci strategy for oss trust"
status: "proposed"
---

# Decision: Use tiered CI to build OSS and enterprise trust

## Context

The repository has one meaningful project-specific CI workflow, `.github/workflows/squad-ci.yml`, plus several workflow files that look like scaffold or dead release plumbing. The local Pulp harness, static validation, evidence validation, and sandbox are real assets, but public trust is diluted by placeholder and branch-mismatched workflows.

## Decision

Adopt the CI plan in `docs/proposals/ci-strategy.md`:

1. **Tier 1 — Foundation:** keep and require `squad-ci.yml`, remove dead project workflows, document local-first CI, use the sandbox as the supported parity path, and add dependency and secret scanning posture.
2. **Tier 2 — Confidence:** add scheduled or trusted-branch live Pulp e2e with structured evidence, sandbox parity CI, security regression tests for path containment, and real docs checks.
3. **Tier 3 — Enterprise trust:** add SBOMs, signatures, provenance, container scanning, license inventory, offline build rehearsal, and isolated high-side no-egress validation.

## Workflows to remove or repurpose

Remove now unless immediately rewritten with real gates:

- `.github/workflows/squad-docs.yml`
- `.github/workflows/squad-preview.yml`
- `.github/workflows/squad-insider-release.yml`
- `.github/workflows/squad-promote.yml`

Keep `squad-ci.yml` as the foundation PR gate. Keep or repurpose `squad-release.yml` only as the seed for future release integrity; a source manifest alone is not enough for enterprise trust.

## Rationale

OSS contributors trust visible, reproducible checks more than workflow count. Enterprise evaluators need supply-chain evidence, offline reproducibility, and AirGap-specific no-egress proof. A tiered plan lets the team clean the current signal quickly without pretending that release integrity and high-side validation already exist.

## Review gates

- Zoe approves architecture scope and release-readiness claims.
- River approves test credibility and evidence gates.
- Simon approves security scanning, path containment, and AirGap controls.
- Wash approves sandbox and container runtime parity.
- Book approves contributor and operator documentation.
