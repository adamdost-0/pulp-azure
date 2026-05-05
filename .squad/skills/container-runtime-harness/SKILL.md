---
name: "container-runtime-harness"
description: "Keep local container harness scripts portable across Podman and Docker"
domain: "automation"
confidence: "high"
source: "Wash and Kaylee local Pulp harness reviews, 2026-05-04T21:08:34.767+00:00"
---

## Pattern

Centralize container runtime selection in the harness common script. Use `PULP_CONTAINER_RUNTIME=auto` to choose Podman first and Docker when Podman is unavailable. Individual scripts should call `resolve_container_runtime`, store `runtime="${PULP_CONTAINER_RUNTIME}"`, and execute container commands through that variable.

## Required Practices

- Do not hardcode bare `podman` or `docker` calls in harness scripts.
- Use shared helpers for runtime-specific operations, such as `runtime_compose` and `runtime_network_exists`.
- Launch Compose through the harness scripts so `common.sh` exports host-native `SUPPORT_PLATFORM`; direct Compose use must set it explicitly.
- For Docker no-egress simulation, start the high-side container on the internal network with `PULP_CONTAINER_PRIMARY_NETWORK`; use secondary `PULP_CONTAINER_NETWORK` only when a runtime needs the default bridge plus an extra network.
- Validate with `bash -n`, `git diff --check`, a Docker/Podman status smoke, internal network create/inspect/remove, and Compose config parsing.
- Keep `PULP_PULL_POLICY=never` for default/repeatable air-gap work; only use pulling in explicitly connected local testing.

## Anti-Patterns

- Reintroducing `require_cmd podman` in scripts that should run on Docker hosts.
- Assuming `podman network exists`; use inspect-based checks that work across Docker and Podman.
- Pulling public images during smoke validation when private image references are not configured.
