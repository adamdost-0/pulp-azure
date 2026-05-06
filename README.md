# pulp-azure
Roadmap and planning for a Pulp-based air-gap binary hydration service for Azure Government environments.

## Local Disposable Pulp Harness

This repository now includes the first implementation slice for building Pulp
solutions through code. The local harness creates a disposable Pulp session,
configures it with `pulp-cli`, publishes a deterministic Debian package, proves
client consumption with `apt-get`, and captures Playwright evidence.

Development runtime volumes default to NAS-backed storage at
`/home/adamdost/synology/appconfig/pulp-azure`, so Pulp session state does not
consume host-local repository or `/tmp` space.

Start here:

```bash
harness/local/scripts/setup-pulp-session.sh --session-id local-apt-smoke --recreate
harness/local/scripts/run-pulp-solution.sh --session-id local-apt-smoke --solution solutions/local-apt-smoke.json
harness/local/scripts/validate-apt-client.sh --session-id local-apt-smoke
harness/local/scripts/capture-evidence.sh --session-id local-apt-smoke
```

For the full operator flow, see [Disposable Session Runbook](docs/runbooks/disposable-session.md).

The architecture rationale is in [Solution-As-Code Proposal](docs/proposals/pulp-solution-as-code.md).

See [docs/README.md](docs/README.md) for the full documentation index, organized by:

- **[Architecture](docs/architecture/)** — charter, engineering standards, and governance.
- **[Runbooks](docs/runbooks/)** — operator workflows for disposable sessions and apt configuration.
- **[Reference](docs/reference/)** — Pulp CLI plugin research and technical assets.
- **[Proposals](docs/proposals/)** — design proposals awaiting or post acceptance.

Pulp CLI tooling can run from the repo-contained sandbox instead of host
packages:

```bash
harness/sandbox/scripts/validate-sandbox.sh --rebuild
harness/sandbox/scripts/run-sandbox.sh -- pulp deb --help
```

Static validation for the harness is available with:

```bash
harness/local/scripts/validate-static.sh
```

Evidence packages are validated separately by:

```bash
harness/local/scripts/validate-evidence-structure.sh
```

Install the repository hooks to keep the same checks local before commits:

```bash
git config core.hooksPath .githooks
```
