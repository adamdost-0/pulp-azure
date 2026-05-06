---
name: "structured-evidence"
description: "Capture reviewer-readable validation evidence without flat artifact dumps"
domain: "quality"
confidence: "high"
source: "E2E Pulp CLI apt validation evidence framework, 2026-05-06T05:24:41.098+00:00"
---

## Context

Use this skill whenever a task runs tests, Pulp validation, local container
checks, e2e flows, Playwright captures, or any workflow that writes files under
`evidence/`.

Evidence is not a scratch folder. It is an audit package that a reviewer must be
able to consume without reconstructing the command history.

## Required Layout

Every run-owned evidence package must use this structure:

```text
evidence/<session-id>/
├── README.md
├── manifest.json
├── apt/
├── fixture/
├── logs/
├── pulp/
├── report/
└── screenshots/
```

## Patterns

- Make `README.md` the first file a reviewer opens.
- Include an executive summary, proof chain, key resource IDs or hrefs, synced
  content summary, relevant excerpts, plugin or component versions, and an
  artifact table.
- Make `manifest.json` the machine-readable index for every non-root artifact.
  Group artifacts by purpose and include a short description for each path.
- Put Playwright-rendered HTML under `report/` and screenshots under
  `screenshots/`.
- Put client logs and command logs under `logs/`.
- Put Pulp status and Pulp CLI JSON under `pulp/`.
- Put apt source and Release metadata under `apt/`.
- Put deterministic fixture package metadata under `fixture/`.
- Run `harness/local/scripts/validate-evidence-structure.sh` before claiming the
  evidence package is complete.

## Examples

For the Pulp CLI apt smoke path:

```bash
harness/local/scripts/validate-apt-client.sh --session-id <session-id>
harness/local/scripts/capture-evidence.sh --session-id <session-id>
harness/local/scripts/validate-evidence-structure.sh
```

The generated package should start at:

```text
evidence/<session-id>/README.md
```

## Anti-Patterns

- Writing flat files directly into `evidence/` or `evidence/<session-id>/`.
- Capturing a screenshot without a human-readable report that explains what the
  screenshot proves.
- Leaving artifacts unreferenced by `manifest.json`.
- Calling evidence complete before Playwright output and client validation logs
  are both present.
