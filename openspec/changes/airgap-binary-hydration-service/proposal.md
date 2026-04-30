## Why

Customers operating Azure Government Secret and other disconnected high-side networks need a repeatable way to move Ubuntu package binaries from Azure Commercial-connected sources into isolated environments without relying on operator memory or ad hoc snapshot tracking. Phase 0 and Phase 1 must establish a stable MVP contract, local Pulp proof, and Azure platform foundation before advanced repository workflows are authorized.

## What Changes

- Narrow the first release to Ubuntu public APT/deb repository hydration, transfer, import, and publication.
- Defer Red Hat, RPM-based repositories, SUSE, Debian expansion, Ubuntu Pro/ESM, OCI mirrors in Pulp, malware scanning ownership, CDS automation, and downstream client configuration management.
- Use Pulp with `pulp_deb` as the repository system of record for Ubuntu APT content; Azure Container Registry remains the system of record for all deployment/container images.
- Track roadmap execution through GitHub milestones and epics, with Phase 0 and Phase 1 acceptance criteria aligned to OpenSpec requirements.
- Define Phase 0 authorization gates: MVP scope, compliance/control boundary, transfer contract, state/authority model, publication contract, local Pulp capability harness, and Phase 1 Definition of Ready.
- Define Phase 1 authorization gates: Azure platform foundation, Pulp runtime topology, PostgreSQL-compatible state foundation, image mirroring/ACR supply chain, private networking/DNS validation, diagnostics/operations baseline, and platform milestone testing.

## Capabilities

### New Capabilities

- `repository-hydration-orchestration`: Low-side scheduling and orchestration of Pulp syncs from Ubuntu public APT/deb sources into centralized managed repositories.
- `snapshot-state-tracking`: PostgreSQL-backed state model for repository snapshots, transfer batches, import status, publication status, provenance, override actions, and audit history across low-side and high-side deployments.
- `transfer-package-manifest`: JSON transfer package manifest format for manual media movement, including repository snapshot contents, checksums, metadata, compatibility warnings, and verification rules.
- `high-side-import-publication`: High-side validation, import, promotion, rollback, and internal HTTPS APT publication of transferred Ubuntu repository snapshots.
- `airgap-deployment-parity`: Azure Commercial, Azure Government, and Azure Government Secret deployment parity for Container Apps, PostgreSQL-compatible state, Storage, ACR image sourcing, Key Vault, identity, private networking, diagnostics, and operations.

### Modified Capabilities

None.

## Impact

- Azure infrastructure for both sides: Azure Container Apps, Azure Storage, Azure Container Registry, PostgreSQL-compatible database, Key Vault, managed identity, private networking, diagnostics, and Container Apps jobs.
- Pulp repository orchestration for Ubuntu public APT/deb content using pinned, identical Pulp 3.x and `pulp_deb` versions across low side and high side.
- New operator workflows for configuring Ubuntu APT sources, triggering hydration, creating transfer batches, validating imports, publishing channels, rolling back publications, and viewing state.
- Security and compliance controls for FedRAMP High / IL6-style environments, including private endpoints, customer-managed keys, narrow RBAC, audit trails, checksum validation, and no public high-side dependencies.
- Build and release process changes to mirror all required images into high-side ACR using OCI tarballs and tag-plus-digest references.
