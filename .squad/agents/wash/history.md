# Project Context

- **Owner:** adamdost-0
- **Project:** This solution helps deliver the Pulp Project in Azure Commercial and Azure Government AirGap environments.
- **Stack:** Azure Commercial, Azure Government, AirGap operations, Pulp, Azure 1P PaaS, IaC/automation and customer setup guidance.
- **Created:** 2026-05-04T15:03:33.394+00:00

## Core Context

Wash owns Pulp bundle release, automation, and transfer workflows for customers moving updates and binaries from Azure Commercial to AirGap Pulp instances using removable media.

## Learnings

Initial setup complete.
- **2026-05-04T21:08:34.767+00:00**: Phase 0-2 local harness automation now resolves `PULP_CONTAINER_RUNTIME=auto` through `harness/local/scripts/common.sh` (Podman first, Docker fallback). Runtime-sensitive scripts are `start-single-container.sh`, `run-e2e.sh`, `run-low-high-e2e.sh`, `validate-no-egress.sh`, and `validate-amd64.sh`; full Pulp e2e still requires private image refs in `harness/local/.env`.
- **2026-05-04T21:08:34.767+00:00**: Portable fixture generation uses Python stdlib archive writers in `harness/local/scripts/generate-fixture.sh` to build deterministic control/data tarballs and the `.deb` ar container without requiring host `ar`.
- **2026-05-04T21:08:34Z**: **Phase 0 complete.** Harness automation fully runtime-aware and portable. Decisions consolidated. Ready for Phase 1.
- **2026-05-04T21:42:09.450+00:00**: Phase 1 bundle tools foundation now lives under `src/bundle-tools/` with stdlib Python modules for config loading, one-way low→high workflow plans, manifest checksum validation, and evidence index conventions. Tests in `tests/test_bundle_tools_foundation.py` exercise config boundaries, native Pulp REST operation planning, no-feedback manifest rejection, and CLI validation without wrapping Pulp.
- **2026-05-05T01:26:57.473+00:00**: Phase 1 accuracy review found and fixed a manifest-validation hardening gap: non-integer `payloadSize`/artifact `size` values now raise `ManifestError` instead of uncaught `ValueError`, preserving deterministic CLI failure behavior for malformed transfer manifests.
- **2026-05-05T01:40:36.497+00:00**: P1-A2 surface audit identified existing extension seams for operator workflow execution: `bundle_tools.__main__` command wiring, `workflow.py` operation schema, `manifest.py` and `evidence.py` integrity/evidence primitives, and `harness/local/scripts/run-low-high-e2e.sh` as executable reference flow for low sync/export, staged handoff, high import/publish, and high-side-only evidence.
- **2026-05-05T01:42:22.430+00:00**: Phase 1 integration/automation coverage review: platform and image-mirroring controls are strong, but Phase 2 readiness is under-scoped for executable operator runbooks (idempotent job contract, retry/resume semantics, artifact custody handoff, and low→high evidence packaging contract).
- **2026-05-05T01:42:22.430+00:00**: Bundle-tools foundation is directionally correct (one-way boundary, manifest integrity, evidence index), but Phase 1 DoD does not yet require CI enforcement (bundle-tools tests + phase1_validation gates + deployment reference scans) that Phase 2 implementation will depend on.
- **2026-05-05T01:42:22.430+00:00**: Harness-to-Azure transition still needs explicit equivalence checks in DoD: Pulp export/import filesystem mappings, Container Apps job/worker concurrency policy, and Azure private-endpoint DNS behavior validated against local low/high flow assumptions.
- **2026-05-05T01:40:36.497+00:00**: Implemented `bundle_tools execute-export` as a thin low-side executor over native Pulp REST primitives with deterministic exit codes (2 validation, 3 precondition, 4 Pulp task/operation, 5 evidence I/O), required low-side evidence outputs, and a plan-aware `--dry-run` path that preserves one-way boundaries without mutating Pulp.
- **2026-05-05T01:45:46.172+00:00**: Authored `.squad/skills/pulp-container-deployment/SKILL.md` as the team playbook for single bundled Pulp container deployments, covering persistent directory scaffold, runtime-aware Podman/Docker variants, HTTPS, image pinning, post-deploy checks, `pulp-cli`, Compose alternative, and disconnected image handling.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to Wash; decisions.md updated.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to Wash; decisions.md updated.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to Wash; decisions.md updated.

## Learnings
* **2026-05-05T00:00:00Z**: Successfully validated local integration with Pulp by creating a test file distribution. Crucially, the local pulp CLI configuration must be manually set up using `pulp config create` with the correct endpoint, and the admin password verified or reset via container execution (`pulpcore-manager reset-admin-password`) before CLI operations. Avoided inline credentials; standard Python `venv` handles `pulp-cli` flawlessly on local client platforms.
* **2026-05-06T05:33:10.822+00:00**: Authored Phase 2 planning memo at `.squad/agents/wash/phase-2-planning-memo.md` defining the next Pulp-native step after local apt sandbox: generic core exporter/importer research, low/high rehearsal sequence, immutable repository version capture, custody manifest handoff, and idempotent create/update semantics with `pulp-cli` retained as the automation boundary.
* **2026-05-06T05:33:10.822+00:00**: Phase 2 acceptance criteria now explicitly require structured evidence continuity (`evidence/<session-id>/README.md` + `manifest.json` + grouped artifact dirs), one-way low→high boundaries, and deterministic rerun outcomes across export/import/publish validation.
* **2026-05-06T20:26:13.550+00:00**: Produced `docs/proposals/ci-pipelines.md` with six concrete CI lanes (quality, static, container, e2e, audit, release integrity), including ready-to-implement YAML for Pipelines 1/2/3/5, local command parity, runtime requirements, and L2H transfer-integrity linkage.
* **2026-05-06T20:43:11.234+00:00**: Local CI dry-run proved Pipeline 2 static validation passes in sandbox when `PULP_STORAGE_ROOT=/workspace/.runtime/pulp-storage` is set, while Pipeline 1 quality gate fails at `shellcheck` (SC2295, SC2016) in `harness/sandbox/scripts/check-p2-export-import-surface.sh`; CI rollout should gate on fixing those shell lint findings.

## 20260505T000000Z - Verified local pulp CLI

## 2026-05-05T00:00:00Z

Wash configured apt-get for Pulp and ran an apt-get package pull validation.
- **2026-05-05T04:36:44.030+00:00**: Harness audit confirmed static wiring and script help paths are healthy (`harness/local/scripts/validate-static.sh` + script `--help` checks pass), but end-to-end automation is not CI-enforced because `.github/workflows/squad-ci.yml` is still placeholder-only and does not call harness validation or `tests/e2e/pulp-local-apt-smoke.sh`. Additional audit gaps: `validate-static.sh` stages fixtures under `/tmp` (non-repo path) and `evidence/test-evidence-apt.md` references `pulp-apt-deb-repo.png` while the repo only contains `evidence/pulp-apt-deb-repo.txt`.
[2026-05-05T04:36:44Z] wash: Audited harness automation and validate-static; noted CI is placeholder and missing evidence PNG.

- **2026-05-05T04:42:06.081Z**: Scribe: created orchestration log and session log for pulpcli-requirements-planning; merged inbox (none present) and recorded per-agent notes.

# 2026-05-06T05:33:10.822+00:00 - Phase 2 planning inbox merged into .squad/decisions.md

- Scribe: merged phase-2 planning inbox into .squad/decisions.md

- 2026-05-06T20:26:13.550+00:00: Scribe: merged CI inbox items; created orchestration and session logs.
- **2026-05-06T20:27:01.226+00:00**: P2.0 contract proof on `pulp/pulp:3.21` confirms `pulpcore 3.21.34` + `pulp_deb 2.20.4` expose exporter/export/importer surfaces, but baseline blocks native rehearsal because `ALLOWED_EXPORT_PATHS`/`ALLOWED_IMPORT_PATHS` are empty and pinned `pulp-cli 0.37.1` has no import-check/import verbs despite API endpoints.

- 2026-05-06T20:27:01.226+00:00: Scribe: merged decision inbox items into .squad/decisions.md (4 files) and created orchestration/session logs.
