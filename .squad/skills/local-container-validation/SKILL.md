---
name: "local-container-validation"
description: "Validate local Pulp container harnesses without confusing daemon health for workflow readiness"
domain: "quality"
confidence: "medium"
last_updated: "2026-05-04T21:42:09.450+00:00"
---

## Context

Use this skill when validating local container harnesses for Pulp, air-gap transfer flows, or other disconnected-workflow simulations. The goal is to prove the customer workflow, not only that a container can start once.

## Validation Ladder

1. **Host prerequisites:** Confirm Docker daemon and Docker Compose are available. Confirm required host tools for the path under test. Fixture and manifest scripts require `python3`; do not require host `ar` because fixture `.deb` archives are built with Python stdlib.
2. **Static container config:** Render Compose configuration with explicit environment values. Treat unresolved variables, public high-side image references, and tag-only references as failures.
3. **Single-service readiness:** Start with unique container names and ports. Verify localhost health endpoints, online workers, and expected application/plugin versions. Stop and clean up containers and workdirs after the check.
4. **Workflow smoke:** Run deterministic fixture generation, manifest generation, checksum validation, sync, publish, and client-consumption checks.
5. **Disconnected path:** Run separate low-side/high-side instances. Verify export, staged transfer, checksum manifest, import-check, import, publish, and high-side APT client consumption with no fixture egress.
6. **Negative tests:** Prove failures for missing images, public/tag-only image references, digest mismatch, missing prerequisites, checksum mismatch, high-side egress, import-check failure, duplicate import, task failure, and client publication failure.
7. **Evidence:** Keep command logs, status JSON, task JSON, manifests, import-check output, container logs, and client verification output. Sanitize before committing or sharing.

## Docker-Specific Guidance

- Prefer runtime variables such as `PULP_CONTAINER_RUNTIME=docker`; do not require Podman when Docker is the project-local runtime.
- Use unique container names and ports for validation to avoid disrupting another agent's containers.
- Use `--pull=never` for offline or repeatability checks unless the test is explicitly connected-mode.
- If Docker creates root-owned workdir files, clean them through a one-off Docker container mounted to the specific workdir, then remove the host directory.

## Phase 1 Image-Free Foundation

- Keep a standard-library validation layer for checks that do not need private images: env template classification, tag-plus-digest image reference rules, manifest/evidence shape, one-way low-to-high boundaries, shell syntax, and Compose config rendering.
- Treat placeholder private image values as `external_configuration`, not runtime failures. Real high-side image references must fail validation when they are public, tag-only, digest-mismatched, or not private high-side ACR.
- Exercise the local fixture plus manifest scripts in tests before container e2e. This catches checksum, traversal, and manifest-shape failures without pulling Pulp or APT client images.
- Preserve `direction: low-to-high` and `feedbackToLowAllowed: false` in generated transfer manifests and evidence indexes so manual media handoff has an executable one-way contract.

## Anti-Patterns

- Declaring readiness from `docker --version` or a single `/status/` response.
- Running high-side validation with public registry pulls or public package source access.
- Leaving Podman hard-coding in scripts intended to validate Docker localhost paths.
- Treating generated runtime evidence as committed project documentation without sanitization.
