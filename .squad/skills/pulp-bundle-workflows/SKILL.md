---
name: "pulp-bundle-workflows"
description: "Keep bundle automation as thin orchestration around native Pulp export/import"
domain: "automation"
confidence: "medium"
last_updated: "2026-05-04T21:42:09.450+00:00"
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

## Anti-Patterns

- Building a Python wrapper around Pulp's REST API.
- Copying mutable repository "latest" state instead of immutable Pulp
  repository versions.
- Adding a high-side status return path to low-side automation.
- Declaring evidence complete from command logs alone without manifest and
  Pulp task artifacts.
