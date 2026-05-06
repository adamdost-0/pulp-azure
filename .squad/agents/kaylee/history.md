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

- **2026-05-05T04:42:06.081Z**: Scribe: created orchestration log and session log for pulpcli-requirements-planning; merged inbox (none present) and recorded per-agent notes.
- **2026-05-06T05:33:10.822+00:00**: Phase 2 planning memo added at `docs/proposals/kaylee-phase-2-platform-planning-memo.md` defining required Azure Commercial/Government decisions for storage, PostgreSQL Flexible, AKS-first hosting, private endpoint/DNS topology, ACR digest-pinned private images, observability dual-path, NAS-to-cloud transition contract, and IaC module boundaries.
- **2026-05-06T05:33:10.822+00:00**: Proposed spike order is capability matrix -> hosting proof -> private data plane -> private image supply chain -> observability dual-path -> NAS-to-cloud cutover rehearsal; this sequence reduces Government parity risk before deep workload investment.

# 2026-05-06T05:33:10.822+00:00 - Phase 2 planning inbox merged into .squad/decisions.md

- Scribe: merged phase-2 planning inbox into .squad/decisions.md
