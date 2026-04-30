## Context

The target workflow spans a connected low side in Azure Commercial and a disconnected high side in Azure Government Secret. The low side must hydrate Linux package repositories from commercial sources such as Ubuntu and Red Hat update infrastructure, centralize the content in Pulp, and produce transfer-ready snapshots. The high side must run without public internet, import manually transferred media, and publish the same repository content for consumers inside the air-gapped network.

The current proposal depends on several unresolved gaps: upstream entitlement and repository source modeling, deterministic snapshot identifiers, low-side/high-side state reconciliation, transfer media manifest design, image and dependency mirroring into high-side ACR, Pulp import/export compatibility, private Azure deployment parity, cryptographic signing, malware scanning, operator approval gates, failure recovery, and audit evidence suitable for regulated environments.

## Goals / Non-Goals

**Goals:**

- Define a Pulp-centered architecture that can sync, snapshot, export, transfer, import, and publish Linux repository binaries with end-to-end state tracking.
- Keep low-side and high-side deployments as close to identical as Azure cloud availability allows, using Azure Container Apps, Azure Storage, Azure Container Registry, Key Vault, managed identity, private networking, diagnostics, and scheduling services.
- Ensure all high-side runtime dependencies are available from private high-side services, especially container images from Azure Container Registry and package payloads from transferred Pulp snapshots.
- Make transfer batches auditable and verifiable through immutable manifests, checksums, signatures, provenance metadata, and import receipts.
- Provide operator workflows that show what changed since the last successful transfer and prevent duplicate, incomplete, or out-of-order imports.

**Non-Goals:**

- Automating the physical hard-drive transfer process or bypassing required cross-domain approval procedures.
- Providing vendor license entitlements for Red Hat, Ubuntu Pro, or other commercial repositories.
- Building a general-purpose artifact mirror for every package ecosystem; the first scope is Linux binary repository content orchestrated through Pulp.
- Replacing downstream client configuration management inside the high-side network.

## Decisions

### Use Pulp as the repository system of record

Pulp will own repository sync, content-addressed storage, repository versioning, export, import, and publication. The service layer will orchestrate Pulp tasks, persist business state, expose operator APIs, and integrate with Azure services.

Alternatives considered:

- **Raw blob copy of package mirrors**: simpler storage model, but weak metadata integrity, poor resumability, and limited import/export semantics.
- **Vendor-specific mirroring tools only**: useful for individual ecosystems, but fragments state and operator workflows across Ubuntu, Red Hat, and future sources.

### Store service state separately from Pulp content

Azure Storage will hold Pulp content and transfer package payloads, while a service-owned state store will track hydration runs, repository snapshot identities, transfer batches, high-side import receipts, signatures, and publication state. If a relational store is introduced later, it must use private endpoints, managed identity, CMK encryption, and government endpoint support.

Alternatives considered:

- **Rely only on Pulp task history**: insufficient because it does not represent manual media movement, cross-side reconciliation, approval gates, or high-side publication lifecycle.
- **Operator-maintained spreadsheets**: explicitly fails the requirement to avoid manual tracking of what moved last.

### Use deterministic transfer batches with signed manifests

Each transfer batch will reference immutable Pulp repository versions and include a manifest containing repository names, source metadata, package counts, content digests, Pulp export metadata, generated timestamps, source environment identity, approvals, and compatibility version. The manifest will be signed on the low side and verified before high-side import.

Alternatives considered:

- **Transfer latest repository state without a manifest**: cannot prove completeness or detect tampering.
- **Transfer every repository on every interval**: operationally expensive and prevents snapshot-only movement.

### Keep deployment parity but allow environment-specific bindings

Both sides will use the same application containers and IaC modules where possible. Environment-specific configuration will bind cloud endpoints, private DNS, identity IDs, storage accounts, ACR names, Key Vaults, and disabled/enabled upstream connectors. High-side deployment must not depend on public endpoints, public registries, public DNS, or internet-based package restore.

Alternatives considered:

- **Separate high-side application**: increases drift and validation burden.
- **Commercial-only service with exported files**: leaves high-side import/publication state outside the orchestrated workflow.

### Treat image mirroring as a first-class release artifact

Every service image, Pulp image, database/support image if any, and operational image required for deployment must be mirrored into high-side ACR by digest. IaC and Container Apps definitions must reference the private ACR digest in high-side deployments.

Alternatives considered:

- **Pulling from public Microsoft or Docker registries during deployment**: incompatible with Azure Government Secret disconnected operations.
- **Using mutable tags**: weak provenance and repeatability.

## Risks / Trade-offs

- **Vendor entitlement constraints for Red Hat and Ubuntu Pro** -> Validate subscription terms, credential handling, and redistribution boundaries before implementing source connectors.
- **Pulp export/import version mismatch** -> Pin and mirror compatible Pulp versions across low and high side; include schema version in manifests and block incompatible imports.
- **Large transfer batches exceed hard-drive capacity or review windows** -> Support incremental snapshot batching, size estimates, and batch splitting before export.
- **Manual media movement creates ambiguous state** -> Require import receipts and explicit state transitions for generated, approved, exported, transferred, imported, published, rejected, and superseded batches.
- **High-side service availability differs from Azure Commercial** -> Confirm Azure Container Apps, Storage, ACR, Key Vault, private endpoint, diagnostics, and managed identity availability in the target Azure Government Secret region; define fallback patterns only where parity is impossible.
- **Security scans delay transfers** -> Model malware scanning, checksum verification, and approval gates as explicit pre-transfer and pre-import states rather than out-of-band work.
- **Repository metadata changes while a sync is running** -> Export only immutable Pulp repository versions and reject manifests that reference mutable latest state.
- **Operator error during import order** -> Enforce dependency and predecessor checks in the high-side importer before publication.

## Migration Plan

1. Stand up the low-side Azure Commercial deployment with private networking, managed identities, storage, Key Vault, ACR, diagnostics, and Pulp.
2. Configure initial upstream repository sources and credentials through Key Vault-backed references.
3. Run controlled hydration jobs and create signed transfer batches without publishing to production consumers.
4. Mirror all deployment images and IaC dependencies into high-side ACR and approved offline package sources.
5. Stand up the high-side Azure Government Secret deployment from private ACR and private Azure services only.
6. Import a pilot transfer batch, verify manifest integrity, publish to a non-production repository endpoint, and compare state receipts.
7. Promote the workflow to production intervals with documented approval, scanning, backup, and rollback procedures.

Rollback uses immutable repository versions: a failed low-side export remains unapproved, a failed high-side import remains unpublished, and a bad publication can be superseded by republishing the last known-good Pulp repository version.

## Open Questions

- Which exact Linux distributions, repository types, architectures, and entitlement models are in the first implementation scope?
- Which Azure Government Secret regions and service SKUs are approved for Container Apps, Storage, ACR, Key Vault, diagnostics, and private endpoints?
- What cross-domain approval, malware scanning, and media custody evidence must be captured in the transfer manifest versus external systems?
- What is the expected maximum repository size, transfer interval, and hard-drive capacity for batch sizing?
- Which signing authority and certificate chain will be trusted on both low side and high side?
- Should the first release expose an operator UI, API-only workflow, or both?
