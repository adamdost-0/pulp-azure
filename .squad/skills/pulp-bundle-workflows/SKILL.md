---
name: "pulp-bundle-workflows"
description: "Keep bundle automation as thin orchestration around native Pulp export/import"
domain: "automation"
confidence: "medium"
last_updated: "2026-05-06T05:33:10.822+00:00"
---

## Pattern

Bundle tooling under `src/bundle-tools` should validate configuration,
transfer manifests, evidence indexes, and workflow plans. It should not
reimplement Pulp behavior or create a custom Pulp API client.

## Required Practices

- Keep transfers one-way from low to high.
- Do not add high-to-low receipts, acknowledgements, or feedback loops.
- Treat native Pulp export/import, `pulp_deb`, and Pulp repository versions as
  the authoritative content workflow.
- Keep high-side configs free of upstream public package source URLs.
- Keep inline secrets out of JSON config; use profiles, managed identity, or
  environment-variable references in runtime wiring.
- Validate manifests by schema, direction, path containment, size, and SHA-256
  before import.

## Phase 2 Security Gates

For disconnected low-side to high-side planning, require these gates before
implementation:

- Define custody records for removable-media transfer before building import
  automation.
- Require detached signatures for transfer manifests and evidence indexes;
  SHA-256 alone proves integrity, not authenticity.
- Use upstream apt Release verification with `--gpgkey` on the connected side
  and apt publication signing with `--signing-service` or an approved offline
  signing path on the high side.
- Prove no high-side public egress with both static configuration checks and
  runtime denied-egress evidence.
- Require high-side images from private registry or offline image import with
  pinned digests; reject public registries and floating tags.

## Anti-Patterns

- Building a Python wrapper around Pulp's REST API.
- Copying mutable repository "latest" state instead of immutable Pulp
  repository versions.
- Adding a high-side status return path to low-side automation.
- Declaring evidence complete from command logs alone without manifest and
  Pulp task artifacts.
