---
date: "2026-05-05T00:00:00Z"
context: "Local integration testing with Pulp via CLI."
decision: "Automated test clients interacting with Pulp must install pulp-cli in an isolated venv and require an explicit pre-requisite step of resetting the admin password inside the container since the default images don't yield a known default."
---

---
date: "2026-05-05T00:00:00Z"
context: "Initial implementation of disposable local Pulp solution-as-code harness."
decision: "Use dependency-free JSON solution definitions for v1, execute Pulp repository workflows through native pulp-cli commands, validate package consumption with apt-get inside an isolated client container, and require Playwright CLI evidence under evidence/<session-id>/. Do not create a custom Pulp API wrapper or mutate host apt configuration during automated tests."
---

---
date: "2026-05-05T04:36:44.030+00:00"
author: "river"
topic: "local harness setup blocker"
---

# Decision: Treat reset-admin-password CLI compatibility as a hard gate

During validation, `harness/local/scripts/setup-pulp-session.sh` failed on `pulp/pulp:3.21` because `pulpcore-manager reset-admin-password` rejected `--username`. We should treat admin-reset command compatibility with the target Pulp image as a required preflight gate before declaring local harness readiness.

Implication: if setup cannot write `session.env`, the remaining operator flow (`run-pulp-solution.sh`, `validate-apt-client.sh`, `capture-evidence.sh`) is expected to fail, and no evidence package should be considered valid.

---
title: "Book Phase 2 Planning"
author: Book
created: 2026-05-06T05:33:10.822+00:00
---

Proposal

Approve Phase 2 customer enablement scope: low-side setup, high-side setup, manual transfer checklist, evidence review, troubleshooting, operator prerequisites, and acceptance criteria as described in docs/runbooks/phase-2-planning.md.

Decision Needed

- Team to confirm owners for each artifact and whether a CI validation job will be created to gate runbook changes.

Notes

- Private-image mirroring (ACR) is a known blocker; workarounds must be documented.
- Evidence structure is required for all validation lanes.

Action

Please reply in this inbox with: `ACK owner=<name> artifact=<artifact-path>` to claim ownership.

---
date: "2026-05-06T05:24:41.098+00:00"
author: "copilot"
topic: "structured evidence framework"
---

# Decision: Structured evidence is the required run artifact format

Every future validation or e2e run that writes under `evidence/` must produce a
reviewer-readable package rooted at `evidence/<session-id>/README.md`, with
`manifest.json` indexing every non-root artifact.

Required run package directories are:

```text
apt/
fixture/
logs/
pulp/
report/
screenshots/
```

Flat, unindexed artifact dumps are not valid evidence. CI, static validation,
and the repository pre-commit hook must run
`harness/local/scripts/validate-evidence-structure.sh` to enforce the framework.

---
date: "2026-05-06T05:33:10.822+00:00"
author: "wash"
topic: "phase 2 planning boundary and execution contract"
---

# Decision: Phase 2 starts with native Pulp core export/import rehearsal under strict one-way custody controls

Phase 2 implementation will prioritize a low-side/high-side rehearsal that uses native `pulp-cli` commands (deb + generic core exporter/importer) as the automation boundary. We will not introduce a custom Pulp API wrapper.

Required workflow outcomes are immutable repository version capture, checksum-backed transfer manifest and custody handoff, idempotent create/update semantics for mutable resources, deterministic failure classes, and structured evidence proving high-side publish and apt client consumption.

This decision keeps transfer automation verifiable and replayable while preserving low-to-high boundary discipline.

---
date: "2026-05-06T05:33:10.822+00:00"
author: "zoe"
topic: "phase 2 planning"
---

# Decision: Phase 2 is local low-to-high export/import rehearsal

Phase 2 should prove disconnected Pulp export/import locally before any Azure
implementation resumes. The smallest coherent objective is two disposable Pulp
sessions: low side exports a pinned apt repository version, transfer staging
validates a thin custody manifest, high side runs native import-check/import,
publishes/distributes the imported content, validates apt client consumption, and
captures structured evidence.

Azure Commercial and Azure Government topology work remains deferred until this
Phase 2 evidence gate passes and product-owner questions are answered for scale,
package ecosystems, signing, media custody, identity/RBAC, retention, private
image digests, and target high-side platform.

Implications for specialists:

- Wash owns native Pulp exporter/importer command research and plugin/version
  gates.
- Simon owns transfer manifest security controls and no high-side public egress
  invariants.
- Kaylee owns thin workflow/CLI planning around native Pulp commands.
- River owns positive/negative validation and structured evidence acceptance.
- Book owns the operator runbook and review checklist.

---
date: "2026-05-06T05:33:10.822+00:00"
author: "simon"
topic: "phase 2 airgap security planning"
status: "planning-control-gates"
---

# Simon Phase 2 Planning Memo: AirGap Security and Compliance Gates

## Scope

Phase 2 should move from the disposable single-session apt proof into disconnected low-side to high-side bundle movement. This memo covers security and compliance requirements for one-way transfer, custody records, signing, `gpgkey` and `signing-service`, secret handling, high-side no-egress proof, private image constraints, evidence integrity, and threat-model checkpoints.

## Allowed

- Low-side export and removable-media transfer toward the high side only.
- High-side import, validation, publication, and client proof from pre-positioned bundle content.
- Native Pulp export/import and `pulp_deb` behavior as the content authority.
- Public upstream package and image access only on the connected low side or build side, never from high-side runtime automation.
- Operator-managed signing keys or managed signing services when key custody, rotation, and audit trails are explicit.

## Assumed

- Apt remains the first package ecosystem for Phase 2 unless the user explicitly expands scope.
- Phase 2 is planning and design first; implementation starts only after user decisions on custody, signing authority, and high-side topology.
- Removable media is manually carried across the boundary and can be represented by signed custody records.
- High-side Pulp and container images are preloaded from a private registry or offline image archive with pinned digests.
- Evidence packages may be written on both sides, but no automated high-to-low receipt or callback is permitted.

## Must Be Proven

1. **One-way transfer:** manifests and workflow plans must encode `low-to-high` direction and reject any high-to-low receipt, callback, telemetry, or synchronization field.
2. **Custody records:** every exported bundle needs a custody record with bundle ID, media ID, operator approvals, classification/handling label, malware/release scan reference, hash list, transfer timestamps, receiving operator, import disposition, and media disposition.
3. **Manifest authenticity:** SHA-256 alone is not enough. Phase 2 needs detached signature verification for transfer manifests and evidence indexes before high-side import.
4. **Repository trust:** low-side apt remote sync must support upstream Release verification with `--gpgkey`; high-side publication must support apt repository signing through `--signing-service` or an approved offline signing path.
5. **Secret handling:** no committed inline passwords, tokens, CLI profiles, private keys, generated Pulp settings, or signing material. Runtime wiring must use managed identity, Key Vault or managed HSM where available, or operator-injected secret references.
6. **No high-side public egress:** prove with static config checks and runtime evidence: DNS, routes, NSG/UDR, flow logs or equivalent, denied external fetch attempts, package-manager fallback checks, and absence of public upstream URLs in high-side plans.
7. **Private image constraints:** high-side images must reference private registry or offline imported images by tag plus digest. Public registry names, floating tags, and pull-through behavior are hard blocks.
8. **Evidence integrity:** evidence packages must keep the structured `README.md` and `manifest.json` model, include hashes for artifacts, record tool versions, and be signed or included in a signed evidence index.
9. **Import safety:** high-side import must validate path containment, symlink rejection, declared size, SHA-256, signatures, plugin compatibility, repository version immutability, and duplicate import behavior before publish.
10. **Auditability:** every override, waiver, signing decision, custody handoff, rejected import, and publication action must create an append-only audit record.

## Hard Blockers

- Any automated high-side to low-side communication path.
- High-side plan, config, container, or script that references public package sources or public registries.
- Missing or failed manifest signature verification before high-side import.
- Missing custody record for removable-media movement.
- Inline secrets, private keys, signing passphrases, generated admin passwords, or CLI profiles in committed files or evidence.
- Unsigned high-side apt publication unless the user explicitly accepts a documented waiver with expiry and compensating controls.
- Bundle import after checksum mismatch, path traversal, symlink escape, size mismatch, unexpected file, or duplicate import conflict.
- Evidence package without machine-readable manifest, artifact hashes, and integrity protection.

## Assumptions to Verify With User

1. Which boundary process governs removable-media movement: customer manual process, CDS, courier, or another transfer authority?
2. What custody record fields are mandatory for the target environment and who signs them?
3. Which signing authority owns apt repository signing: customer GPG key, managed HSM-backed signing service, offline signing station, or project-provided key ceremony?
4. Are manifest and evidence signatures required to use GPG, Sigstore/cosign, Azure Key Vault keys, managed HSM, or customer PKI?
5. Is apt still the only required ecosystem for Phase 2, or must rpm, Python, generic file, or container content be planned now?
6. What Azure Government classification boundary and control baseline apply, including retention, redaction, and auditor access requirements?
7. Which private image path is allowed on the high side: private ACR, disconnected registry mirror, OCI archive import, or preinstalled node images?
8. What runtime evidence is acceptable to prove no high-side public egress in the customer environment?
9. Can high-side evidence leave the boundary manually as a signed audit export, or must it remain high-side only?
10. What waiver process exists for unsigned upstream content, version mismatch, plugin mismatch, or emergency import?

## Threat-Model Checkpoints

- **Before export design freeze:** identify trust boundaries, release authority, upstream trust anchors, signing keys, and low-side compromise assumptions.
- **Before media workflow approval:** review tampering, loss, substitution, replay, duplicate import, custody repudiation, malware scanning, and media sanitization.
- **Before high-side import design:** review path traversal, symlink escape, archive bombs, checksum/signature mismatch, plugin incompatibility, and Pulp task failure semantics.
- **Before high-side publish:** review signing-service behavior, apt metadata correctness, repository version immutability, client trust bootstrap, and rollback conditions.
- **Before Azure Government deployment:** review private networking, no public egress evidence, private image source, managed identity scopes, Key Vault or HSM access, CMK inheritance, and audit retention.
- **Before Phase 2 closeout:** perform negative tests for public egress, public image pull, missing signature, tampered manifest, missing custody record, duplicate import, path escape, secret leakage, and unsigned evidence.

## Planning Decision

Simon recommends treating Phase 2 as blocked from implementation until the user confirms custody authority, signing authority, high-side private image source, no-egress evidence standard, and whether high-side evidence can be exported. Once confirmed, the implementation plan can be split into security gates: transfer manifest, signing and custody, high-side import preflight, private image/no-egress validation, signed evidence, and threat-model test cases.

---
date: "2026-05-06T05:33:10.822+00:00"
author: "kaylee"
topic: "phase-2-platform-decision-order"
---

# Decision: Use AKS-first and capability-matrix-gated Phase 2 planning for Azure Commercial/Government

Phase 2 will proceed with an AKS-first platform recommendation and treat Azure Commercial/Government capability validation as a hard gate before architecture freeze. Storage, managed PostgreSQL, ACR, private endpoints/DNS, and observability must be designed as explicit IaC modules with no hidden public dependency.

Rationale: Phase 1 highlighted risk in assuming Azure Container Apps Government parity. Front-loading a capability matrix and private data plane validation reduces redesign risk and keeps the deployable accelerator path dependable for both clouds.

Implementation note: Local NAS-backed harness paths remain valid for developer disposable workflows, but production accelerator plans must use cloud storage and managed persistence contracts.

---
date: "2026-05-06T05:33:10.822+00:00"
author: "river"
topic: "phase-2 validation gates"
---

# Decision: Phase 2 exits only on dual-side evidence-complete validation

Phase 2 should be treated as validation-complete only when low-side and high-side disposable workflows both pass, export/import manual handoff is rehearsed, high-side apt client consumption is proven, and mandatory negative tests fail in expected controlled ways.

This decision sets structured evidence (`README.md`, `manifest.json`, grouped artifact directories, Playwright captures, and `harness/local/scripts/validate-evidence-structure.sh`) plus 100% line/branch coverage as non-negotiable gates, with CI split into PR-feasible checks and self-hosted/nightly disconnected e2e execution.
