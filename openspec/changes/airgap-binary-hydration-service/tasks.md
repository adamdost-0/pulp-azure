## 1. Discovery and Gap Closure

- [ ] 1.1 Confirm first-scope distributions, repository families, architectures, channels, entitlement requirements, and redistribution constraints for Ubuntu, Red Hat, and any additional Linux sources.
- [ ] 1.2 Confirm Azure Commercial and Azure Government Secret service availability, region support, approved SKUs, endpoint suffixes, and parity gaps for Container Apps, Storage, ACR, Key Vault, diagnostics, private endpoints, and managed identity.
- [ ] 1.3 Define cross-domain approval, malware scanning, media custody, signing authority, and audit evidence requirements for manual hard-drive transfer.
- [ ] 1.4 Establish maximum repository sizes, hydration intervals, transfer media capacity, and batch splitting rules.
- [ ] 1.5 Select and pin compatible Pulp versions, plugins, import/export formats, and schema compatibility rules for both low-side and high-side deployments.

## 2. Azure Deployment Foundation

- [ ] 2.1 Create shared IaC modules for low-side and high-side Azure deployments with environment-specific bindings for cloud endpoints, private DNS, identities, storage, ACR, Key Vault, diagnostics, and tags.
- [ ] 2.2 Configure private networking, disabled public access, TLS 1.2 or higher, CMK-capable storage, diagnostic settings, and narrow managed-identity RBAC for all supported Azure resources.
- [ ] 2.3 Define Azure Container Apps workloads for the service layer, Pulp components, background workers, and supporting processes required by the selected Pulp deployment shape.
- [ ] 2.4 Add high-side deployment validation that fails on public endpoints, public registries, mutable image references, missing private DNS, or unsupported Azure service bindings.

## 3. Image and Dependency Mirroring

- [ ] 3.1 Produce a release bill of materials covering service images, Pulp images, support images, IaC dependencies, package manager dependencies, and operational tools.
- [ ] 3.2 Implement digest-pinned image publishing and mirroring into low-side and high-side Azure Container Registry.
- [ ] 3.3 Update deployment configuration so high-side Container Apps pull every image from private high-side ACR by digest.
- [ ] 3.4 Add offline dependency packaging guidance for any build, deployment, or operational artifact needed inside Azure Government Secret.

## 4. Repository Hydration Orchestration

- [ ] 4.1 Implement repository source configuration for distribution, repository family, architecture, component/channel, sync interval, entitlement reference, and enabled status.
- [ ] 4.2 Implement Key Vault-backed entitlement resolution without storing or logging secrets in application configuration.
- [ ] 4.3 Implement scheduled hydration jobs that invoke Pulp sync tasks for enabled sources and record hydration run identifiers.
- [ ] 4.4 Implement sync result handling that records failures, detects no-change runs, and creates transfer-eligible immutable snapshot records only after successful content changes.
- [ ] 4.5 Add policy checks that prevent already-batched or failed snapshots from becoming transfer eligible.

## 5. Snapshot and Transfer State

- [ ] 5.1 Implement the state model for repository sources, hydration runs, snapshots, transfer batches, export jobs, media handoff states, high-side imports, publications, supersession, and audit events.
- [ ] 5.2 Implement deterministic snapshot and transfer batch identifiers that can be reconciled between low-side manifests and high-side receipts.
- [ ] 5.3 Implement valid state transition enforcement for generated, approved, exported, transferred, imported, published, rejected, failed, and superseded batches.
- [ ] 5.4 Implement operator APIs or commands for viewing pending snapshots, approved batches, exported batches, imported batches, publication status, and audit history.

## 6. Transfer Package Generation

- [ ] 6.1 Implement transfer batch selection from eligible snapshots with capacity estimates and batch splitting support.
- [ ] 6.2 Implement Pulp export orchestration for approved immutable repository versions.
- [ ] 6.3 Implement the transfer manifest schema with repository metadata, Pulp repository versions, content counts, digests, export artifact references, approval metadata, provenance, and compatibility constraints.
- [ ] 6.4 Implement checksum generation for every manifest and payload artifact.
- [ ] 6.5 Implement low-side manifest signing using the approved signing authority and produce operator-readable transfer instructions.

## 7. High-Side Import and Publication

- [ ] 7.1 Implement offline package intake from mounted media or private high-side storage without public internet dependencies.
- [ ] 7.2 Implement pre-import validation for manifest schema, compatibility version, checksums, signatures, duplicate batch status, predecessor rules, and approval evidence.
- [ ] 7.3 Implement Pulp import orchestration and task tracking for validated transfer packages.
- [ ] 7.4 Implement controlled publication of imported repository versions to internal high-side endpoints after operator promotion.
- [ ] 7.5 Implement import receipt generation with validation results, imported snapshot identifiers, publication endpoints, timestamps, and signature for low-side reconciliation.

## 8. Verification and Operations

- [ ] 8.1 Add tests for repository source configuration, hydration scheduling, snapshot eligibility, and no-change sync handling.
- [ ] 8.2 Add tests for state transitions, duplicate import rejection, out-of-order publication rejection, and audit event recording.
- [ ] 8.3 Add tests for transfer manifest generation, checksum validation, signature validation, schema compatibility rejection, and batch capacity enforcement.
- [ ] 8.4 Add tests for high-side import, publication, receipt generation, and rollback to last known-good repository versions.
- [ ] 8.5 Add deployment validation tests for government endpoints, private-only access, managed identity, CMK-capable storage, required compliance tags, and digest-pinned ACR references.
- [ ] 8.6 Document operator runbooks for low-side hydration, transfer approval, media preparation, high-side import, publication, receipt reconciliation, failure recovery, and rollback.
