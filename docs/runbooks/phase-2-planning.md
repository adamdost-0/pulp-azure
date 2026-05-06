# Phase 2 — Customer Enablement Planning Memo

Author: Book (Customer Enablement Writer)
Date: 2026-05-06T05:33:10.822+00:00

Purpose

This memo scopes Phase 2 customer enablement deliverables for the Pulp Azure accelerator. Phase 2 focuses on validated AirGap low-side → high-side transfer operations in Azure (commercial and government), manual transfer operator flows, evidence collection and review, and robust troubleshooting/runbooks for operators.

Assumptions

- Phase 1 artifacts and changes are merged to main and available in the repo.
- Local harness and scripts used in Phase 1 are the source of truth for CLI contracts and evidence structure.
- Azure platform automation (IaC) for low/high provisioning may not be complete; Phase 2 docs must support manual operator steps.
- Private image mirroring (ACR) is a known blocker; docs must present both image-mirroring and image-free validation lanes.

Scope (what docs will cover)

- Low-side operator setup (air-gapped build/export environment): prerequisites, preflight, runbook, evidence capture
- High-side operator setup (ingress/import environment): prerequisites, network/credential guidance, import runbook
- Manual transfer checklist and operator playbook for physical or air-gapped file transfers (portable media, SFTP, approved courier)
- Evidence review guide: what to check in evidence packages, how to validate, sample checks and scripts
- Troubleshooting playbook for common failures across the transfer lifecycle (export, transfer, import, publish)
- Operator prerequisites and roles: accounts, tooling, security posture, acceptable baseline
- Alignment controls: how docs stay in sync with validated behavior (validation scripts, CI gating, evidence signoff)

Customer personas

- On-prem operator (low-side): prepares Pulp exports, creates evidence, interacts with offline transfer media
- Cloud operator (high-side): ingests artifacts, runs import scripts, verifies content and publishing
- Security reviewer / compliance auditor: inspects evidence packages and signatures
- Enablement engineer: walks customers through playbooks and collects feedback

Proposed doc artifacts and paths

- docs/runbooks/phase-2-low-side-setup.md — low-side prerequisites, step-by-step export runbook, dry-run examples, expected artifacts
- docs/runbooks/phase-2-high-side-setup.md — high-side preflight, import/runbook, post-import verification, publishing checks
- docs/runbooks/phase-2-manual-transfer-checklist.md — checklist for physical & network transfer, transfer validation steps, custody chain notes
- docs/runbooks/phase-2-evidence-review.md — evidence review checklist, sample jq queries, acceptance checks, common failure patterns
- docs/runbooks/phase-2-troubleshooting.md — triage guide organized by symptom, root-cause checks, remediation commands
- docs/runbooks/phase-2-operator-prereqs.md — accounts, tooling, minimum roles and network ports, install-check scripts
- docs/runbooks/phase-2-acceptance.md — cross-linking acceptance criteria for all artifacts and gating for release

Acceptance criteria (per artifact)

General
- Each runbook must specify preconditions, exact commands, expected JSON outputs, and where evidence is written.
- All runbooks reference the structured evidence format (.squad/skills/structured-evidence/SKILL.md) and include one worked example with a sample session-id.

Low-side setup
- Verify export commands run with --dry-run and --json producing expected keys (export_id, artifact_paths).
- Evidence package created using harness scripts and passes harness/local/scripts/validate-evidence-structure.sh.

High-side setup
- Import runbook contains idempotent commands and verification steps (pulp CLI checks) that return deterministic JSON for automated checks.

Manual-transfer checklist
- Clear custody chain fields: who, when, transfer medium, cryptographic checksums, and validation commands.
- Include sample commands to verify checksum and sample Playwright/HTML report locations in evidence package.

Evidence review
- Provide jq snippets and a minimal script that asserts required keys and hashes exist and match.
- Define a sign-off template (Who, When, Evidence session-id, Pass/Fail, Notes).

Troubleshooting
- Each triage step shows command to run, expected outputs, and next actions. Include at least one example for: permission errors, missing artifacts, checksum mismatch, network failure during import.

Operator prerequisites
- List OS/tooling versions, required binaries, and a preflight script that exits with non‑zero and helpful message if unmet.

How docs will stay aligned with validated behavior

- Link runbooks to exact harness scripts and examples in the repo (use relative paths), e.g., harness/local/scripts/* and evidence/ validation scripts.
- Treat CLI JSON contracts as source-of-truth: when scripts change JSON keys, update runbooks and record a changelog entry in docs/runbooks/CHANGES.md.
- Add a minimal CI job (if possible) that runs harness/local/scripts/validate-evidence-structure.sh on PRs that change runbooks or scripts.
- Require an owner sign-off for each runbook: implementer or engineer that validated the behavior must add an "Owner:" line and a validation date.

Timeline and priorities

- Week 0 (planning): finalize scope and owners — (this memo)
- Week 1: Draft low-side and manual-transfer checklist (high priority)
- Week 2: Draft high-side and evidence-review guides
- Week 3: Draft troubleshooting and operator-prereqs; add acceptance doc and sample scripts
- Week 4: Internal review, validation runs, acceptance testing, and sign-offs

Risks and open questions

- Private-image mirroring (ACR) remains a blocker for fully automated Azure validation; docs must provide alternative image-free validation lanes.
- Transport policy and approved transfer media are customer-specific—runbooks must provide patterns, not enforce policy.
- Automation for CI gating requires a separate ticket if not already in repo.

Next steps (immediate)

- Team: review this memo and assign owners for each artifact
- Book: create skeleton runbooks listed above and mark them "Draft" with owner placeholders
- Operators/Implementers: identify any contract changes to harness scripts; surface them as PRs with evidence

Appendix: quick artifact checklist

- [ ] phase-2-low-side-setup.md — owner, preflight script, example session-id
- [ ] phase-2-manual-transfer-checklist.md — custody template, checksum commands
- [ ] phase-2-high-side-setup.md — import dry-run, validation commands
- [ ] phase-2-evidence-review.md — jq snippets, sign-off template
- [ ] phase-2-troubleshooting.md — symptom → remediation map
- [ ] phase-2-operator-prereqs.md — preflight script
- [ ] phase-2-acceptance.md — acceptance tests and gating

