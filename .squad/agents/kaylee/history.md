# Project Context

- **Owner:** adamdost-0
- **Project:** This solution helps deliver the Pulp Project in Azure Commercial and Azure Government AirGap environments.
- **Stack:** Azure Commercial, Azure Government, AirGap operations, Pulp, Azure 1P PaaS, IaC/automation and customer setup guidance.
- **Created:** 2026-05-04T15:03:33.394+00:00

## Core Context

Kaylee owns Azure platform design and deployment automation for a customer accelerator that uses Azure Commercial as the central update and binary location for AirGap Pulp instances.

## Learnings

Initial setup complete.
- **2026-05-04T21:08:34.767+00:00**: Phase 0 local Pulp container work lives under `harness/local/`. Current localhost has Docker 29.3.1 with Docker Compose v5.1.1 and no Podman, so local scripts should use `PULP_CONTAINER_RUNTIME=auto` or `docker` instead of bare Podman assumptions.
- **2026-05-04T21:08:34.767+00:00**: Docker validation path: `bash -n harness/local/scripts/*.sh`, runtime auto-detect should resolve to Docker when Podman is absent, `docker compose -f harness/local/compose.pulp.yaml config --quiet` should parse with local image placeholders, and `validate-no-egress.sh` can run with `PULP_CONTAINER_RUNTIME=docker` plus a connected test APT image.
- **2026-05-04T21:08:34Z**: **Phase 0 complete.** All harness runtime-awareness delivered. Decisions consolidated to decisions.md. Ready for Phase 1 application scaffolding.
- **2026-05-05T01:42:22.430+00:00**: Phase 1 platform review shows a likely risk in assuming Azure Container Apps workload-profile parity for Azure Government and especially Azure Government Secret without tenant/region proof; this can become a blocker if only consumption-only environments are available.
- **2026-05-05T01:42:22.430+00:00**: Endpoint parameterization is strong for ACR/Storage/Key Vault/PostgreSQL/Entra/ARM, but diagnostics endpoints and private DNS requirements for Azure Monitor/Log Analytics should be explicit IaC parameters to avoid hidden commercial defaults in high side.
- **2026-05-05T01:42:22.430+00:00**: Diagnostics design is directionally correct (`AMPLS/private link or local export fallback`) and should be treated as a mandatory dual-path implementation requirement in Phase 1 evidence, not an optional operational enhancement.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to Kaylee; decisions.md updated.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to Kaylee; decisions.md updated.

- **2026-05-05T01:42:22Z**: Scribe merged decision inbox items related to Kaylee; decisions.md updated.
