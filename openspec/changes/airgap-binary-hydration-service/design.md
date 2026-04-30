## Context

The target workflow spans a connected low side in Azure Commercial and a disconnected high side in Azure Government Secret. The MVP hydrates Ubuntu public APT/deb repositories on the low side, centralizes content in Pulp, produces transfer-ready bundles for manual media movement, imports those bundles on the high side, and publishes internal HTTPS APT endpoints for Ubuntu servers and golden image pipelines.

Phase 0 defines the MVP contract and local proof strategy. Phase 1 proves the Azure/Pulp platform foundation. Later phases will cover full repository workflow implementation, high-side operations, pilot rollout, and ecosystem expansion.

## Goals / Non-Goals

**Goals:**

- Lock the first release to Ubuntu public APT/deb repository content.
- Use Pulp 3.x with `pulp_deb` as the repository system of record and native Pulp export/import as the primary content transfer mechanism.
- Prove the core Pulp sync/export/import/publish flow locally before deploying to Azure.
- Keep low-side and high-side deployments as close to identical as Azure cloud availability allows, using Azure Container Apps, Azure Storage, Azure Container Registry, PostgreSQL-compatible state, Key Vault, managed identity, private networking, diagnostics, and Container Apps jobs.
- Ensure all high-side runtime dependencies are available from private high-side services, especially deployment images from Azure Container Registry and package payloads from transferred Pulp snapshots.
- Make transfer batches auditable and verifiable through immutable repository versions, JSON manifests, checksums, provenance metadata, and append-only audit history.
- Provide operator workflows that show transfer/import/publication state and prevent duplicate, incomplete, or out-of-order imports.

**Non-Goals:**

- Supporting Red Hat, RPM-based repositories, SUSE, Debian expansion, Ubuntu Pro/ESM, or vendor-entitled repositories in the first release.
- Using Pulp for OCI/container image distribution in the first release; Azure Container Registry owns deployment/container image distribution.
- Automating the physical hard-drive transfer process or managing CDS/cross-domain release procedures.
- Owning malware scanning evidence or scan tooling beyond checksum/package verification performed by this system.
- Transferring vendor credentials to the high side.
- Replacing downstream client configuration management inside the high-side network.

## Decisions

### Use Pulp as the Ubuntu APT repository system of record

Pulp will own Ubuntu APT sync, content-addressed storage, repository versioning, export, import, and publication. The MVP plugin set is `pulp_deb` only. Low side and high side must run identical pinned Pulp 3.x and `pulp_deb` versions selected after validation.

Alternatives considered:

- **Raw blob copy of package mirrors**: simpler storage model, but weak metadata integrity, poor resumability, and limited import/export semantics.
- **Vendor-specific mirroring tools only**: useful for individual ecosystems, but fragments state and operator workflows.
- **Pulp OCI mirroring in MVP**: deferred because ACR is already required for high-side deployment image sourcing.

### Store service state in PostgreSQL-compatible storage

Service-owned state will use a PostgreSQL-compatible database with strong consistency for lifecycle transitions and eventual consistency acceptable for reporting. Pulp content and transfer payloads will use approved private storage. Operational state may be mutable, but all lifecycle changes and privileged overrides must be captured in append-only audit history retained for one year unless superseded by customer policy.

Alternatives considered:

- **Rely only on Pulp task history**: insufficient because it does not represent manual media movement, approval states, compatibility overrides, or high-side publication lifecycle.
- **Azure Storage-only state**: useful for payloads and fixtures, but weaker for strongly consistent lifecycle transitions.

### Use JSON transfer manifests with checksum-only validation

Each transfer batch will reference immutable Pulp repository versions and include a JSON batch manifest containing per-repository entries. Required fields include schema version, transfer batch ID, source environment ID, generated timestamp, repository metadata, Ubuntu distribution/release, architecture, APT components/pockets, Pulp repository version, package count, payload size, checksums, Pulp export artifact references, approval metadata, provenance, and importer compatibility constraints.

Manifest signing is not required in the first release. Any manifest or payload checksum validation failure rejects the entire batch. Pulp or plugin compatibility mismatch produces a warning and requires privileged override with audit history rather than an unconditional block.

Alternatives considered:

- **Signed manifests**: deferred for MVP to reduce first-release complexity.
- **Transfer latest repository state without a manifest**: cannot prove completeness or detect accidental corruption.
- **Transfer every repository on every interval**: operationally expensive and prevents snapshot-only movement.

### Make the high side authoritative after transfer

No low-side receipt reconciliation loop is required for the MVP. Once a transfer bundle is moved to the high side, the high-side service is authoritative for staged, validated, imported, published, rejected, rollback, and supersession state. Low-side state remains authoritative only through export-to-media.

Alternatives considered:

- **Carry high-side receipts back to low side**: adds cross-domain workflow complexity that is not required for MVP authorization.

### Keep deployment parity but allow environment-specific bindings

Both sides will use the same application containers and IaC modules where possible. Environment-specific configuration will bind cloud endpoints, private DNS, identity IDs, storage accounts, ACR names, Key Vaults, PostgreSQL-compatible database endpoints, and disabled/enabled upstream connectors. High-side deployment must not depend on public endpoints, public registries, public DNS, or internet-based package restore.

Container Apps and a PostgreSQL-compatible database are required services. If parity gaps are discovered, fallback patterns will be documented but not implemented until explicitly authorized.

### Treat image mirroring as a first-class release artifact

Every service image, Pulp image, support image, operational/admin image, and Container Apps runtime dependency required for deployment must be available in high-side ACR before high-side deployment. Images move as OCI tarballs on manual media and are imported into high-side ACR. High-side references use tag plus digest. Production releases require an image bill of materials.

Alternatives considered:

- **Pulling from public Microsoft or Docker registries during deployment**: incompatible with Azure Government Secret disconnected operations.
- **Mutable tag-only references**: weak provenance and repeatability.

### Prove Pulp capability locally before Azure deployment

Phase 0 includes a local low-side/high-side Pulp capability harness using pinned Pulp 3.x and `pulp_deb` versions. The harness must prove sync, immutable repository version creation, native Pulp export/import, bundle staging, JSON manifest generation, checksum validation, publication, and Ubuntu 22.04-compatible apt client consumption before Phase 1 Azure deployment begins.

## Risks / Trade-offs

- **Azure Gov Secret service parity/SKU availability** -> Confirm selected services across Azure Commercial, Azure Government, and Azure Government Secret before Phase 1 authorization.
- **Pulp export/import version mismatch** -> Pin identical Pulp and `pulp_deb` versions across low side and high side; warn and require privileged override for compatibility mismatch.
- **Large transfer batches exceed hard-drive capacity or review windows** -> Support size estimates and batch splitting before export.
- **Manual media movement creates ambiguous state** -> Track lifecycle states through export on low side and from staged through published on high side; external CDS custody remains out of scope.
- **Private DNS/private endpoint misconfiguration creates hidden public dependency** -> Make high-side deployment validation fail on public endpoints, public registries, public DNS, missing private DNS, or tag-only images.
- **Repository metadata changes while a sync is running** -> Export only immutable Pulp repository versions and reject manifests that reference mutable latest state.
- **Operator error during import order** -> Enforce duplicate, predecessor, validation, and publication state checks before promotion.

## Migration Plan

1. Align OpenSpec artifacts and GitHub Phase 0 issues to the MVP contract.
2. Build and validate the local Pulp capability harness using an offline Ubuntu-style APT fixture.
3. Select and pin Pulp 3.x, `pulp_deb`, PostgreSQL-compatible database, and image mirroring methods.
4. Confirm Azure service/SKU parity and Phase 1 Definition of Ready.
5. Stand up low-side Azure Commercial and high-side Azure Government Secret platform foundations with private networking, managed identities, storage, PostgreSQL-compatible state, Key Vault, ACR, diagnostics, and Pulp.
6. Mirror all deployment images and IaC dependencies into high-side ACR and approved offline package sources.
7. Run a platform milestone test proving both sides start and operate with private service access only.

Rollback uses immutable repository versions: a failed low-side export remains unapproved, a failed high-side import remains unpublished, and a bad publication can be superseded by republishing the last known-good Pulp repository version to the same stable client endpoint after explicit approval.

## Open Questions

- Which exact Azure Government Secret regions and service SKUs are approved for Container Apps, PostgreSQL-compatible database, Storage, ACR, Key Vault, diagnostics, private endpoints, and managed identity?
- Which exact Pulp 3.x and `pulp_deb` versions will be pinned after validation?
- What repository size, transfer interval, and hard-drive capacity targets should define default batch sizing rules?
- What internal DNS names and internal PKI process will be used for high-side HTTPS APT publication endpoints?
- What local fixture repository shape is sufficient to authorize the local Pulp capability harness?
