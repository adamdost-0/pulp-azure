# Pulp Solution-As-Code Harness

## Problem Statement

The current local Pulp setup is useful for exploration, but it is not yet a
repeatable disposable development harness. The top-level Compose file uses a
floating image tag, named volumes, and manual credential setup. Recent tests also
proved package access with one-off commands instead of a reusable solution
definition that can be recreated on every run.

We need a local harness that treats Pulp as disposable infrastructure, while
still using Pulp's native CLI and plugins as the source of truth.

## Proposed Architecture

Create a local harness under `harness/local/` that accepts a declarative solution
file from `solutions/`, creates a fresh Pulp session under `.runtime/`, configures
Pulp through `pulp-cli`, validates client consumption through `apt-get`, and
writes Playwright-backed evidence under `evidence/`.

The v1 workflow is deliberately small:

1. Start one disposable Pulp container with generated settings and local storage.
2. Generate a deterministic apt repository containing one tiny `.deb` package.
3. Use `pulp deb remote`, `pulp deb repository sync`, `pulp deb publication`, and
   `pulp deb distribution` to publish that package.
4. Run `apt-get` from an isolated client container against the generated sources
   list.
5. Capture status, task output, apt logs, fixture metadata, and a Playwright CLI
   screenshot into a session evidence package.

## What Changes

- Pulp sessions become disposable by default.
- Solution definitions live in `solutions/` and are validated against a schema in
  `schemas/`.
- Harness scripts centralize runtime selection and avoid direct host apt changes.
- Evidence is a required output, not an afterthought.

## What Stays the Same

- Pulp remains the system of record for repository, publication, distribution,
  export, and import state.
- The project does not introduce a custom Pulp API wrapper.
- Native `pulp-cli` and plugin commands remain the automation boundary.
- Disconnected low-side/high-side workflows remain one-way and are deferred until
  the single-session apt path is stable.

## Key Decisions

1. **Solution format:** JSON for v1. This keeps validation and parsing in Python
   standard library and avoids adding YAML dependencies before the command
   contract stabilizes.
2. **Fixture source:** local deterministic apt repository. This keeps v1 fast,
   repeatable, and independent of upstream Debian sync size.
3. **Client validation:** apt client container. This proves apt semantics without
   modifying `/etc/apt` on the host.
4. **Evidence:** Playwright CLI must capture a published Pulp endpoint for every
   e2e run, alongside machine-readable evidence artifacts.

## Risks and Mitigations

### Risk: Selected Pulp image lacks `pulp_deb`

Likelihood: Medium. Impact: High.

Mitigation: setup gates fail before workflow execution if `pulp_deb` is missing
from the Pulp status endpoint.

### Risk: Container cannot reach the host fixture server

Likelihood: Medium. Impact: Medium.

Mitigation: runtime helpers set Docker or Podman host aliases and record the
remote URL in workflow evidence.

### Risk: Playwright is missing on the host

Likelihood: Medium. Impact: Medium.

Mitigation: evidence capture fails loudly and documents the requirement. Static
checks do not claim e2e success without Playwright artifacts.

### Risk: Generated runtime files become root-owned

Likelihood: Medium. Impact: Low.

Mitigation: teardown falls back to a scoped cleanup container and preserves
evidence separately from runtime state.

## Scope

### In v1

- Disposable single Pulp session.
- Deterministic local apt fixture repository.
- Pulp CLI setup, sync, publication, and distribution.
- apt-get validation in an isolated client container.
- Per-session Playwright evidence package.

### Deferred

- Low-side/high-side disconnected export/import.
- Azure topology and managed service deployment.
- Packaged operator CLI.
- Signed apt repositories and production TLS.