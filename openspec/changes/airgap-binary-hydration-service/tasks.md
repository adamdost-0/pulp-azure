## 1. Phase 0 - MVP Contract and Local Capability Proof

- [x] 1.1 Align OpenSpec scope and non-goals with GitHub issue #1: Ubuntu public APT/deb only, ACR for containers, and deferred Red Hat/RPM/SUSE/Debian/OCI-in-Pulp/CDS/client-configuration work.
- [x] 1.2 Align compliance and control boundaries with GitHub issue #2: app-owned checksum/package verification, state tracking, private access, audit events, and externally owned malware scanning/CDS transfer.
- [x] 1.3 Align transfer contract with GitHub issue #3: JSON batch manifest, per-repository entries, checksums only, whole-batch rejection on checksum failure, and compatibility warning with privileged override.
- [x] 1.4 Align state and authority model with GitHub issue #4: PostgreSQL-compatible state, strong lifecycle transitions, append-only audit history, and high-side-authoritative state after transfer.
- [x] 1.5 Align publication contract with GitHub issue #5: internal HTTPS APT endpoints, internal PKI, stable channel URLs, immutable snapshot URLs, test/prod/snapshot channels, and no client auth beyond network isolation.
- [x] 1.6 Build and validate the local Pulp capability test harness from GitHub issue #6: Podman Compose, pinned Pulp 3.x and `pulp_deb`, generated Ubuntu-style APT fixture, local low/high Pulp stacks, bundle staging, manifest validation, publication, Ubuntu 22.04 apt client consumption, and isolated high-side no-egress simulation.
- [ ] 1.7 Define Phase 1 Definition of Ready from GitHub issue #7: Azure service/SKU parity, selected Pulp/PostgreSQL/image-mirroring methods, local harness pass, required controls, and Phase 1 milestone criteria.

## 2. Phase 1 - Azure/Pulp Platform Foundation

- [ ] 2.1 Align Azure platform foundation with GitHub issue #8: Container Apps, ACR, Storage, PostgreSQL-compatible DB, Key Vault, diagnostics, private networking, CMK, tags, managed identity, and least-privilege RBAC.
- [ ] 2.2 Align Pulp runtime and Container Apps topology with GitHub issue #9: Pulp API, workers, content serving, scheduled jobs, identical Pulp 3.x/`pulp_deb` versions, no `pulp_container`, health checks, scaling, and failure behavior.
- [ ] 2.3 Align PostgreSQL state foundation with GitHub issue #10: private access, CMK, backups, restore path, diagnostics, access controls, schema migration, and strongly consistent state transitions.
- [ ] 2.4 Align image mirroring and ACR supply chain with GitHub issue #11: OCI tarball transfer, high-side ACR import, production image BOM, tag-plus-digest references, and deployment validation.
- [ ] 2.5 Align private networking and DNS validation with GitHub issue #12: private endpoints, private DNS, no public internet/DNS/registry/service endpoint dependencies, and validation failure on public references.
- [ ] 2.6 Align diagnostics and operational baseline with GitHub issue #13: logs, metrics, audit events, private diagnostics access, retention, backup/restore tests, and private/local export fallback.
- [ ] 2.7 Align platform milestone test with GitHub issue #14: low-side and high-side private startup, Pulp/PostgreSQL/storage/Key Vault/diagnostics health, and no high-side public runtime dependencies.

## 3. Later Roadmap Milestones

- [ ] 3.1 Keep Phase 2 - Repository Workflow Foundation as a GitHub milestone placeholder until detailed acceptance criteria are authorized.
- [ ] 3.2 Keep Phase 3 - High-Side Import, Publication, and Operations as a GitHub milestone placeholder until detailed acceptance criteria are authorized.
- [ ] 3.3 Keep Phase 4 - Verification, Pilot, and Stable Rollout as a GitHub milestone placeholder until detailed acceptance criteria are authorized.
- [ ] 3.4 Keep Future - Ecosystem Expansion as a GitHub milestone placeholder for Red Hat/RPM, Ubuntu Pro/ESM, additional distributions, OCI content mirroring in Pulp, richer UI, and advanced compliance integrations.
