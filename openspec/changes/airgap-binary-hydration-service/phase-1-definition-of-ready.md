# Phase 1 Definition of Ready

## Purpose

This document is the planning-gate evidence for GitHub issue #7. It records
the Phase 0 local proof outcome, the selected baseline decisions for Phase 1
planning, the security controls required before Azure deployment, and the
evidence criteria for GitHub issues #8 through #14.

This is not approval to skip target-environment validation. The service/SKU
parity matrix records that the selected service roles have no known parity delta
across Azure Commercial, Azure Government, and Azure Government Secret, while
the exact target tenant, region, SKU, network mode, and security controls still
require Phase 1 validation evidence.

## Inputs and evidence

| Item | Evidence |
| --- | --- |
| Issue #6 closeout | Issue #6 is closed by commit `483a7de` (`feat(harness): add low/high e2e script and close issue #6`). |
| Local harness script | `harness/local/scripts/run-low-high-e2e.sh` runs the low-side sync/export and high-side import/publish path. |
| Harness documentation | `harness/local/README.md` documents the low/high topology and evidence layout. |
| Azure parity evidence | `openspec/changes/airgap-binary-hydration-service/azure-service-parity-matrix.md`. |

### Issue #6 local harness pass summary

Commit `483a7de` records Phase 0.6 acceptance evidence from e2e run
`1777781838` at `2026-05-03T04:24`:

- Low side: pulpcore 3.110.0 and pulp_deb 3.8.1.
- High side: pulpcore 3.110.0 and pulp_deb 3.8.1.
- Sync completed against the deterministic Ubuntu-style APT fixture
  (repository version 1, 7 content units).
- Native Pulp export completed and produced a TOC plus tar payload
  (TOC sha256 prefix `c1bd6cc5`, tar CRC `45057cc7`).
- Staged transfer artifacts were checksum-verified with `MANIFEST.sha256`.
- High-side `import-check` returned valid TOC evidence and the import task
  group was accepted.
- High-side publication completed (`AptPublication 019dec1b-17d5`).
- The disposable apt client resolved `airgap-fixture` candidate `1.0.0` from
  `pulp-high:80`.

The tracked harness writes evidence under
`harness/local/.work/evidence/<timestamp>/` by default. That runtime evidence is
not committed; the commit message and tracked harness files are the repo
evidence for issue #6 closeout.

## Selected Phase 1 baselines

### Pulp baseline

- Local validated source image for the Phase 0 harness:
  `docker.io/pulp/pulp:latest`.
- Validated application versions:
  - pulpcore 3.110.0
  - pulp_deb 3.8.1
- First-release plugin scope remains `pulp_deb` only. `pulp_container` is not
  part of the MVP repository system of record.
- Production and high-side deployments must not pull this public source image.
  Release engineering must mirror the approved image to private ACR and deploy
  only with tag-plus-digest references.

### PostgreSQL-compatible database

- Preferred managed database: Azure Database for PostgreSQL Flexible Server,
  if it is available with required private access, backup/restore, diagnostics,
  encryption, maintenance, and SKU support in the target cloud and region.
- The selected service role has no known cloud-service parity delta. Phase 1
  must still validate the exact target-region/SKU behavior for private access,
  CMK, backup, maintenance, HA, diagnostics, and support operations.
- If target-environment validation discovers that the preferred managed service
  cannot satisfy a required control, Phase 1 must select an approved fallback.
  Candidate fallback patterns must be explicitly reviewed for operations,
  backup/restore, encryption, patching, diagnostics, and support ownership
  before use.

### Image mirroring method

The selected image supply-chain path for Phase 1 planning is:

1. Resolve and approve all required images on the connected side.
2. Export images as OCI tarballs for transfer.
3. Move OCI tarballs through the approved offline media/CDS process.
4. Import the tarballs into high-side private ACR.
5. Publish an image bill of materials that records source image, target ACR
   image, tag, digest, approval state, import status, and validation result.
6. Deploy using tag-plus-digest image references only.

High-side validation must reject public registry references, tag-only image
references, missing images, and digest mismatches.

## Required security controls checklist

Phase 1 issues #8 through #14 must retain the following controls unless an
approved control exception is recorded:

- [ ] Private endpoints and private DNS for supported PaaS services.
- [ ] Public network access disabled for supported PaaS services.
- [ ] No public high-side runtime dependency on internet, public DNS, public
      package sources, public container registries, or public service endpoints.
- [ ] Azure Government endpoint suffixes and private DNS zones parameterized;
      no commercial endpoint hardcoding in high-side configuration.
- [ ] Managed identity for Azure service-to-service authentication.
- [ ] Least-privilege RBAC at the narrowest feasible scope.
- [ ] Key Vault-backed secret/configuration references; no hardcoded secrets or
      service-principal passwords.
- [ ] Customer-managed keys where required for storage, database, registry, and
      other data-at-rest services.
- [ ] TLS 1.2 or higher for supported service endpoints.
- [ ] Internal HTTPS and internal PKI for high-side APT publication.
- [ ] Diagnostic settings, logs, metrics, audit events, retention, and
      private/local export fallback for air-gapped operations.
- [ ] Required resource tags on every Azure resource:
      `Environment`, `ManagedBy`, `Project`, `Owner`, `Classification`, and
      `Compliance`.
- [ ] ACR image sourcing for all deployment images, including Pulp, service,
      support, admin, and runtime dependency images.
- [ ] Tag-plus-digest deployment references for production and high-side image
      configuration.
- [ ] Backup/restore, rollback, and failure-mode evidence for stateful services.

## Phase 1 milestone evidence criteria

| Issue | Evidence required before completion |
| --- | --- |
| #8 Azure Platform Foundation | IaC plan/apply evidence for Container Apps, ACR, Storage, PostgreSQL-compatible DB, Key Vault, diagnostics, private networking, required tags, CMK where required, managed identity, least-privilege RBAC, public access disabled, and selected cloud endpoint suffixes. |
| #9 Pulp Runtime and Container Apps Topology | Pulp API, worker, content-serving, and scheduled-job topology; identical pulpcore 3.110.0 and pulp_deb 3.8.1 versions unless a change is approved; image tag-plus-digest evidence; health/startup probes; scaling and failure behavior; confirmation that `pulp_container` remains out of scope. |
| #10 PostgreSQL State Foundation | Confirmed PostgreSQL-compatible product/SKU or approved fallback; private connectivity proof; backup/restore proof; migration and rollback approach; diagnostics; encryption/access controls; tests for strongly consistent lifecycle transitions. |
| #11 Image Mirroring and ACR Supply Chain | Production image BOM; OCI tarball export evidence; high-side ACR import evidence; tag-plus-digest references; validation failures for public registry, tag-only, missing image, and digest-mismatch references. |
| #12 Private Networking and DNS Validation | Private endpoint and private DNS proof; no public endpoint references; no public DNS resolver or package source dependency; validation failures for public references in high-side configuration. |
| #13 Diagnostics and Operational Baseline | Logs, metrics, audit events, retention, private diagnostics access, backup/restore drill evidence, and private/local export fallback for disconnected operations. |
| #14 Platform Milestone Test | Integrated low-side and high-side startup; health checks for Pulp, PostgreSQL-compatible DB, Storage, Key Vault, ACR, diagnostics, and private networking; proof that the high-side runtime has no public dependencies. |

## Gate model

| Gate result | Meaning | Allowed work |
| --- | --- | --- |
| Pass | Selected service roles have no known parity delta and target-environment validations are complete for the intended deployment scope. | Phase 1 implementation may proceed for the validated scope. |
| Pass with validation required | Selected service roles have no known parity delta, but exact target-region/SKU/control validation remains an implementation milestone criterion. | Phase 1 implementation may proceed, but individual epics cannot close until their validation evidence is produced. |
| Block | Target validation discovers an actual service, SKU, endpoint, or control gap with no approved fallback. | Do not proceed with the affected scope until a fallback or waiver is approved. |

## Current DoR status

Current status: pass with validation required.

Issue #7 can close as a planning gate because:

- The selected service roles have no known parity delta across the target clouds.
- The remaining work is target-environment validation evidence, not a known
  service-availability blocker.
- The selected Pulp baseline, PostgreSQL preference, image mirroring method,
  local harness pass, required controls, and Phase 1 evidence criteria are
  documented here and in the parity matrix.

Phase 1 epics still must produce validation evidence for the target environment:
Container Apps workload profile behavior, ACR private endpoint/CMK/import
workflow, Storage private endpoint/CMK capabilities, PostgreSQL-compatible
managed database SKU, Key Vault private endpoint/CMK/purge protection,
diagnostics/private link or approved fallback, private DNS endpoint suffixes,
managed identity behavior, and cloud-specific service limits or support
constraints.
