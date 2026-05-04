# Phase 1 Image Mirroring and ACR Supply Chain

## Scope

This artifact aligns GitHub issue #11 with the OpenSpec design. Azure Container
Registry is the system of record for deployment images. Pulp is not used for OCI
image distribution in the MVP.

High-side deployment must pull all runtime, support, admin, and operational
images from private high-side ACR. Public image pulls are not allowed at
runtime.

## Image BOM schema

Production releases MUST publish an image bill of materials with one entry per
required image:

| Field | Requirement |
| --- | --- |
| `component` | Service or operational component that consumes the image. |
| `sourceImage` | Connected-side source image used for approval. |
| `sourceDigest` | Source digest at approval time. |
| `targetRegistry` | Private target ACR login server. |
| `targetImage` | Target repository/name in ACR. |
| `targetTag` | Release tag imported into ACR. |
| `targetDigest` | Digest observed in target ACR after import. |
| `architecture` | Required architecture such as `linux/amd64`. |
| `approvalState` | `pending`, `approved`, `rejected`, or `waived`. |
| `importStatus` | `not-imported`, `imported`, `verified`, or `failed`. |
| `validatedAt` | Timestamp of target ACR validation. |
| `evidence` | Evidence artifact path or issue link. |

Initial BOM categories:

- Pulp runtime image(s) containing pulpcore 3.110.0 and pulp_deb 3.8.1 unless a
  later approved baseline replaces them.
- Application/service images for the hydration orchestration service.
- Administrative and operational job images.
- Validation/helper images required in the target environment.
- Runtime dependency images required by Container Apps deployment.

## Transfer and import flow

1. Resolve approved images and source digests on the connected side.
2. Export images as OCI tarballs.
3. Generate image BOM and checksum manifest.
4. Move tarballs through the approved offline media/CDS process.
5. Import tarballs into high-side private ACR.
6. Read back target ACR manifests and record target digests.
7. Deploy using tag-plus-digest references only.

## ACR validation procedure

The high-side validation procedure MUST:

1. Authenticate to high-side ACR using managed identity or an approved
   operational identity without embedding credentials.
2. Confirm each BOM target repository and tag exists in private ACR.
3. Read the target manifest digest from ACR.
4. Compare the target digest to the approved BOM digest.
5. Confirm deployment manifests reference the private ACR login server and the
   approved digest.
6. Confirm no public registry hostnames are present in deployment configuration.
7. Record validation results in the issue #11 evidence package.

## Evidence threshold

Issue #11 evidence MUST include:

| Artifact | Requirement |
| --- | --- |
| Image BOM | JSON or table containing every required field in this document for each image. |
| Source digest capture | Command output or registry metadata proving each approved source digest. |
| OCI export log | Command output showing each approved image exported to an OCI archive. |
| Transfer checksum manifest | Checksums for each OCI archive and BOM artifact. |
| High-side import log | Command output or API result showing each image imported into private ACR. |
| Target digest capture | Command output or ACR metadata proving each target digest after import. |
| Deployment reference scan | Machine-readable or command output proof that deployment references use private ACR tag-plus-digest references only. |
| Rejection test results | One result per required rejection test with expected result, actual result, and final status. |

Command logs alone are not sufficient unless they include the image name, tag,
digest, target registry, validation result, and timestamp needed to correlate
the result back to the BOM.

## Deployment reference rule

Production and high-side image references MUST use:

```text
<acr-name>.azurecr.us/<repository>:<tag>@sha256:<digest>
```

Commercial low-side deployments may use the commercial ACR suffix for their
private ACR, but must still use tag-plus-digest references for production
deployments.

## Required rejection tests

Validation MUST fail before promotion when:

- An image reference points to Docker Hub, Microsoft Container Registry, GHCR,
  Quay, or any other public registry.
- An image reference uses a mutable tag without a digest.
- The digest in deployment configuration does not match the approved BOM.
- The image is missing from target ACR.
- The BOM approval state is not `approved`.
- The target digest cannot be verified from private ACR.

## Validation evidence for issue #11

Issue #11 can close only when its evidence package proves:

1. Image BOM schema and initial image inventory are complete.
2. OCI tarball export/import procedure is documented and tested.
3. High-side ACR import validation records target digests.
4. Deployment configuration uses tag-plus-digest references.
5. Public registry, tag-only, missing image, digest mismatch, and unapproved
   image rejection tests pass.
