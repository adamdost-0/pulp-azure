# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Scope, architecture, trade-offs, reviews | Zoe | Azure Commercial/Government topology, solution accelerator boundaries, PaaS fit, reviewer gates |
| Azure platform and infrastructure | Kaylee | Azure 1P PaaS selection, deployment topology, IaC, networking, observability, environment setup |
| Pulp integration and automation | Wash | Bundle release workflows, binary transfer automation, removable media handoff scripts, CI/CD glue |
| Security, compliance, and AirGap controls | Simon | Identity, secrets, data boundary review, government cloud constraints, manual-transfer risk analysis |
| Testing and validation | River | Deployment validation, bundle integrity checks, regression coverage, failure-mode testing |
| Customer enablement and docs | Book | Quickstarts, runbooks, setup guides, architecture explainers, customer adoption guidance |
| Work monitoring and backlog flow | Ralph | Issue queue checks, open PR state, follow-up work detection |
| Session logging | Scribe | Decisions, orchestration logs, cross-agent memory |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Zoe |
| `squad:zoe` | Pick up architecture, planning, and review work | Zoe |
| `squad:kaylee` | Pick up Azure platform and infrastructure work | Kaylee |
| `squad:wash` | Pick up Pulp integration and automation work | Wash |
| `squad:simon` | Pick up security, compliance, and AirGap review work | Simon |
| `squad:river` | Pick up testing and validation work | River |
| `squad:book` | Pick up docs and customer enablement work | Book |
| `squad:ralph` | Pick up monitoring and backlog work | Ralph |

### How Issue Assignment Works

1. When a GitHub issue gets the `squad` label, the **Lead** triages it by analyzing content, assigning the right `squad:{member}` label, and commenting with triage notes.
2. When a `squad:{member}` label is applied, that member picks up the issue in their next session.
3. Members can reassign by removing their label and adding another member's label.
4. The `squad` label is the inbox for untriaged issues waiting for Lead review.

## Rules

1. **Eager by default** - spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts -> coordinator answers directly.** Do not spawn an agent for a direct status check.
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." -> fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** If a feature is being built, spawn River to write test cases from requirements simultaneously.
7. **Issue-labeled work** - when a `squad:{member}` label is applied to an issue, route to that member. Zoe handles all `squad` base-label triage.
