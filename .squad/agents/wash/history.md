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

## 20260505T000000Z - Verified local pulp CLI
