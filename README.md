# pulp-azure
Roadmap and planning for a Pulp-based air-gap binary hydration service for Azure Government environments.

## Local Disposable Pulp Harness

This repository now includes the first implementation slice for building Pulp
solutions through code. The local harness creates a disposable Pulp session,
configures it with `pulp-cli`, publishes a deterministic Debian package, proves
client consumption with `apt-get`, and captures Playwright evidence.

Start here:

```bash
harness/local/scripts/setup-pulp-session.sh --session-id local-apt-smoke --recreate
harness/local/scripts/run-pulp-solution.sh --session-id local-apt-smoke --solution solutions/local-apt-smoke.json
harness/local/scripts/validate-apt-client.sh --session-id local-apt-smoke
harness/local/scripts/capture-evidence.sh --session-id local-apt-smoke
```

For the full operator flow, see [docs/pulp-disposable-session.md](docs/pulp-disposable-session.md).

The architecture rationale is in [docs/proposals/pulp-solution-as-code.md](docs/proposals/pulp-solution-as-code.md).

Static validation for the harness is available with:

```bash
harness/local/scripts/validate-static.sh
```
