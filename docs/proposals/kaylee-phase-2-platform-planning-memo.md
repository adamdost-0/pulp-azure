# Kaylee Phase 2 Planning Memo: Local Harness to Deployable Azure Accelerator

**Date:** 2026-05-06T05:33:10.822+00:00
**Author:** Kaylee (Azure Platform Engineer)
**Scope:** Azure Commercial and Azure Government platform decisions required to move from local disposable harness to deployable accelerator.

## 1. Phase 2 Objective

Move from single-host disposable validation to repeatable, auditable Azure deployment patterns that work in both Azure Commercial and Azure Government without hidden cloud assumptions.

## 2. Required Platform Decisions

## 2.1 Storage Strategy (Content, Evidence, and Transfer Artifacts)

### Decision to make
Select cloud storage layout that supports Pulp content, transfer artifacts, evidence retention, and one-way operational boundaries.

### Proposed baseline
- **Content and export/import objects:** Azure Blob Storage (`StorageV2`) with private endpoints, customer-managed keys (CMK optional by environment), lifecycle policies, and immutable retention for evidence when required.
- **Pulp filesystem-like working state:** Use managed persistent volume via container platform storage integration (AKS PV with CSI-backed managed disk/file path), not NAS assumptions.
- **Evidence packages:** Blob containers with immutable policy toggled by compliance profile.

### Commercial/Government parity check
- Confirm Blob features used (immutability settings, private endpoint DNS shape, lifecycle actions) are available in Government target regions.

## 2.2 Managed Database Choice

### Decision to make
Choose managed relational store for workflow metadata/idempotency and platform operations metadata.

### Proposed baseline
- **Azure Database for PostgreSQL Flexible Server** in private network mode.
- Disable public access; require private DNS and private endpoints as applicable.
- Define backup retention and restore objectives by environment class (dev/test/prod).

### Commercial/Government parity check
- Validate SKU/zone availability and maintenance-window behavior in Government regions before finalizing production profile defaults.

## 2.3 Container Hosting Choice

### Decision to make
Select the deployment substrate for Pulp-adjacent services and control-plane components.

### Proposed baseline
- **Primary recommendation:** AKS for predictable networking control, private cluster options, and clearer parity control between Commercial/Government.
- **Defer ACA decision** until explicit Government workload-profile capability proof is collected.

### Why now
Phase 1 already surfaced risk that ACA parity assumptions may block Government rollout.

## 2.4 Networking and Private Endpoints

### Decision to make
Define network topology and DNS model as first-class IaC.

### Proposed baseline
- Hub-spoke (or equivalent segmented VNet) with explicit subnets for platform services.
- Private endpoints for Storage, PostgreSQL, Key Vault, ACR, and observability endpoints where supported.
- Private DNS zones linked explicitly per environment; no reliance on implicit portal wiring.
- Egress control policy (Firewall/NAT) with allowlisted dependencies only.

### Air-gap constraint alignment
No public package or image pulls on high-side deployments.

## 2.5 ACR and Private Images

### Decision to make
Define image sourcing, promotion, and runtime pull policy.

### Proposed baseline
- Dedicated ACR per boundary (or per side) with signed and digest-pinned images.
- No floating tags in deploy manifests.
- Import/promotion path documented and automated (low-side build -> validated import -> high-side pull from private ACR only).
- Managed identity-based pulls; no admin credentials.

## 2.6 Observability

### Decision to make
Define minimum viable observability that works in both clouds and restricted networks.

### Proposed baseline
- OpenTelemetry-native app instrumentation and structured logs.
- Azure Monitor/Log Analytics path with private connectivity where supported.
- Explicit fallback for disconnected/highly restricted environments (local/exported log bundle pattern) captured as a supported mode, not an exception.
- Platform dashboards and alert rules deployed by IaC modules.

## 2.7 NAS-to-Cloud Storage Transition

### Decision to make
Replace local NAS-root assumptions with environment-agnostic cloud storage contracts.

### Proposed transition contract
- Keep local NAS only for developer harness mode.
- Introduce abstraction in deployment config: `storage_mode = local|cloud`.
- Cloud mode writes evidence/artifacts to storage account containers and uses managed persistence for runtime state.
- Migration runbook: local harness outputs remain valid test fixtures; cloud deployment does not depend on NAS paths.

## 2.8 IaC Boundaries and Ownership

### Decision to make
Set module boundaries so teams can iterate independently without cross-cloud drift.

### Proposed module boundaries
1. **foundation/** resource groups, policy hooks, naming, tags.
2. **network/** vnets, subnets, routing, private dns, private endpoints.
3. **data/** storage, postgres, key vault.
4. **compute/** aks (or chosen host), identities, node/workload profiles.
5. **registry/** acr and image pull permissions.
6. **observability/** monitor, log analytics/private scope, alerting.
7. **workload/** pulp-related services, config maps/secrets references, scaling.
8. **evidence/** retention, immutability, export policy wiring.

## 3. Proposed Phase 2 Spike Sequence

1. **Spike 1 - Cloud capability matrix (Commercial vs Government):**
   - Validate feature/SKU parity for AKS, PostgreSQL Flexible, ACR, Blob, private endpoints, and observability path.
   - Deliverable: decision matrix with supported/blocked/conditional per target region.

2. **Spike 2 - Hosting substrate decision proof (AKS-first):**
   - Deploy minimal private AKS footprint + managed identity pull from ACR + private storage/db reachability.
   - Deliverable: reproducible IaC example and latency/operability notes.

3. **Spike 3 - Storage and DB private data plane:**
   - Provision Blob + PostgreSQL private access and validate no public endpoints required.
   - Deliverable: smoke tests and operator runbook updates.

4. **Spike 4 - Private image supply chain:**
   - Build/import/sign/pin image flow into ACR; enforce digest-only deploys.
   - Deliverable: pipeline contract + policy checks.

5. **Spike 5 - Observability dual-path:**
   - Validate Azure Monitor private path and fallback export mode.
   - Deliverable: alerting/log collection baseline with environment switch.

6. **Spike 6 - NAS-to-cloud cutover rehearsal:**
   - Run same logical flow as local harness, but persist evidence/artifacts in cloud storage and managed services.
   - Deliverable: cutover checklist and gap list to close before accelerator GA.

## 4. Top Risks and Mitigations

- **Risk:** Government service feature gaps block chosen architecture.
  - **Mitigation:** Capability matrix is a hard gate before platform freeze.

- **Risk:** Hidden public dependency appears in runtime (images, package feeds, telemetry).
  - **Mitigation:** Egress deny-by-default + explicit dependency allowlist tests.

- **Risk:** Private DNS/endpoint wiring complexity causes brittle deployments.
  - **Mitigation:** Treat DNS and endpoint wiring as tested IaC modules with environment integration tests.

- **Risk:** Observability design works only in Commercial.
  - **Mitigation:** Implement and test dual-path observability in Phase 2, not later phases.

- **Risk:** Local NAS assumptions leak into production configuration.
  - **Mitigation:** Add `local` vs `cloud` storage mode contracts and block production plans that reference local paths.

## 5. Exit Criteria for Phase 2

Phase 2 is complete when:
- Hosting substrate is selected with Government evidence.
- Storage, DB, and ACR are private-only and deployable by IaC in both clouds.
- Observability baseline is validated with a documented restricted-mode fallback.
- NAS-local harness and cloud deployment paths are both supported through explicit configuration contracts.
- Risks above are reduced from unknown/assumed to measured/owned.
