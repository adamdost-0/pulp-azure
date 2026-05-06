---
name: "manual-transfer"
description: "Patterns and checklist for manual (air-gapped) artifact transfer and custody"
domain: "operations"
confidence: "medium"
source: "Book Phase 2 planning"
---

## Context

When artifacts must be transferred across an air-gap or via a physically mediated channel (USB, courier, SFTP over isolated link), operators need a reproducible checklist that preserves integrity, auditability, and repeatability.

## Patterns

- Always capture a manifest.json listing artifact paths, sizes, and SHA256 checksums.
- Record custody metadata: operator name, timestamp (ISO8601), transfer medium, and any transport IDs.
- Use detached signatures where available; include signature paths in manifest and evidence README.
- Validate checksums on receipt before attempting import; fail fast and preserve quarantine copies.

## Examples

- Create manifest and checksum on low-side:

  sha256sum artifacts/* > manifest.sha256
  jq -n --arg id "$SESSION" '{session_id:$id, artifacts: (inputs)}' > manifest.json

- Verify on high-side:

  sha256sum -c manifest.sha256

## Anti-Patterns

- Sending artifacts without machine-readable manifests.
- Relying only on filenames or timestamps for validation.
- Overwriting original artifacts on mismatch — preserve quarantine and collect evidence.

