## Why

Customers operating Azure Government Secret and other disconnected high-side networks need a repeatable way to move Linux package binaries from commercial update infrastructure into isolated environments without relying on operator memory or ad hoc snapshot tracking. The service must make low-side collection, manual transfer, and high-side publication auditable, resumable, and deployable with the same Azure architecture on both sides.

## What Changes

- Introduce a Pulp-based binary hydration service that runs in Azure Commercial on Azure Container Apps with Azure Storage-backed persistence and 1P Azure services for scheduling, identity, observability, and operations.
- Define a parity deployment model for Azure Government Secret that runs the same service shape without public internet access and pulls all container images from a private Azure Container Registry.
- Add snapshot state tracking for low-side collection and high-side import so operators can determine exactly which repository snapshots were collected, transferred, imported, and published.
- Add transfer package generation that creates manual hard-drive-ready payloads with manifests, checksums, signatures, and provenance metadata.
- Add high-side import/export behavior that validates transferred payloads, imports them into Pulp, and publishes curated repositories for downstream disconnected consumers.
- Identify design and operational gaps that must be closed before implementation, including upstream repository entitlement, image mirroring, schema compatibility, media handling, security controls, and failure recovery.

## Capabilities

### New Capabilities

- `repository-hydration-orchestration`: Low-side scheduling and orchestration of Pulp syncs from commercial Linux package sources into centralized managed repositories.
- `snapshot-state-tracking`: Persistent state model for repository snapshots, transfer batches, import status, publication status, provenance, and audit history across low-side and high-side deployments.
- `transfer-package-manifest`: Transfer package format for manual media movement, including repository snapshot contents, manifests, checksums, signatures, metadata, and verification rules.
- `high-side-import-publication`: High-side validation, import, promotion, and publication of transferred repository snapshots into disconnected Azure Government Secret networks.
- `airgap-deployment-parity`: Azure Commercial and Azure Government Secret deployment parity for Container Apps, Storage, ACR image sourcing, identity, private networking, diagnostics, and operations.

### Modified Capabilities

None.

## Impact

- Azure infrastructure for both sides: Azure Container Apps, Azure Storage, Azure Container Registry, Key Vault, managed identity, private networking, diagnostics, and scheduling services.
- Pulp repository orchestration for Ubuntu, Red Hat, and other Linux binary sources, including entitlement and metadata handling.
- New APIs or operator workflows for configuring upstream repositories, triggering hydration, creating transfer batches, validating imports, and viewing state.
- Security and compliance controls for FedRAMP High / IL6-style environments, including private endpoints, CMK encryption, narrow RBAC, signed manifests, audit trails, and no public high-side dependencies.
- Build and release process changes to mirror service images and dependencies into high-side ACR before deployment.
