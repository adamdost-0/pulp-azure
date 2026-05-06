# Documentation

Pulp Azure is a roadmap and local harness for a Pulp-based air-gap binary
hydration service targeting Azure Government environments. This index organizes
project documentation by purpose so each audience finds what they need without
scanning a flat file list.

## Architecture

Project governance, engineering standards, and the binding charter that defines
product behavior and autonomous decisions.

| Document | Purpose |
|---|---|
| [Rewrite Charter](architecture/rewrite-charter.md) | Product surface, deferred L2H behavior, recommended target stack, and interview backlog. |
| [Engineering Standards](architecture/engineering-standards.md) | Type safety, testing, CI/CD gates, and air-gap invariants. |

## Proposals

Design proposals that describe architectural changes. Each proposal captures the
problem, proposed solution, key decisions, risks, and scope boundaries.

| Document | Purpose |
|---|---|
| [Solution-As-Code Harness](proposals/pulp-solution-as-code.md) | Declarative solution files, disposable sessions, NAS-backed storage, and Playwright evidence as a first-class output. |
| [Phase 2 Planning Memo](proposals/phase-2-planning.md) | Local low-to-high export/import rehearsal scope, decisions, gates, sequencing, and delegation plan. |

## Runbooks

Step-by-step operator workflows. Each runbook is self-contained with
prerequisites, commands, evidence expectations, and troubleshooting.

| Document | Purpose |
|---|---|
| [Disposable Session](runbooks/disposable-session.md) | Create a local Pulp session, configure it with `pulp-cli`, validate with `apt-get`, capture evidence, and tear down. |
| [Apt 0-to-100](runbooks/apt-0-to-100.md) | Target 13-step flow from sandbox preparation through export/import rehearsal, with acceptance criteria and known gaps. |

## Reference

Research notes, upstream plugin analysis, and technical assets used across
documents.

| Document | Purpose |
|---|---|
| [Pulp CLI Deb Deep Dive](reference/pulp-cli-deb-deep-dive.md) | Upstream `pulp-cli-deb` plugin contracts for remote, repository, publication, distribution, content, and export/import implications. |
| [Pulp CLI Flow Diagram](reference/assets/pulp-cli-flow.svg) | Visual flow of the `pulp-cli` configuration steps. |

## Reading Order

For a new contributor:

1. [Rewrite Charter](architecture/rewrite-charter.md) — understand what the
   project is and what is deferred.
2. [Engineering Standards](architecture/engineering-standards.md) — understand
   the quality bar.
3. [Solution-As-Code Proposal](proposals/pulp-solution-as-code.md) — understand
   the harness design.
4. [Disposable Session Runbook](runbooks/disposable-session.md) — run your first
   local session.
5. [Apt 0-to-100](runbooks/apt-0-to-100.md) — see the full target flow and gaps.
6. [Deb Deep Dive](reference/pulp-cli-deb-deep-dive.md) — reference when
   extending Pulp CLI automation.
