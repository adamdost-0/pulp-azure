# Disposable Pulp Session Runbook

This runbook creates a local Pulp session from code, configures it through
`pulp-cli`, validates a package pull through `apt-get`, and writes evidence under
`evidence/`.

## Prerequisites

- Docker or Podman.
- Python 3.
- Network access to install `pulp-cli` and pull configured container images, or
  preloaded images with pull policies set to `never`.
- Playwright CLI or `npx` for evidence capture.

Do not edit host apt sources. The harness uses an isolated apt client container.

## Safe Defaults

Start from [harness/local/.env.example](../harness/local/.env.example). The
scripts read environment variables, but they do not require a live `.env` file.
Keep secrets out of committed files.

The default session uses:

- Pulp endpoint: `http://localhost:18080`
- Upstream fixture server: port `18081`
- Solution file: [solutions/local-apt-smoke.json](../solutions/local-apt-smoke.json)
- Evidence root: `evidence/`

## Run

From the repository root:

```bash
harness/local/scripts/validate-static.sh
```

Then run the disposable session workflow:

```bash
harness/local/scripts/setup-pulp-session.sh --session-id local-apt-smoke --recreate
harness/local/scripts/run-pulp-solution.sh --session-id local-apt-smoke --solution solutions/local-apt-smoke.json
harness/local/scripts/validate-apt-client.sh --session-id local-apt-smoke
harness/local/scripts/capture-evidence.sh --session-id local-apt-smoke
```

The same flow is wrapped by:

```bash
tests/e2e/pulp-local-apt-smoke.sh
```

## Evidence

Each run writes a package under `evidence/<session-id>/`:

- `description.md` explains the event and proof points.
- `index.json` lists artifacts.
- `pulp-status.json` records readiness and plugin versions.
- `fixture-metadata.json` records package metadata and SHA-256.
- `deb-sync.json`, `deb-publication.json`, and `deb-distribution.json` record
  Pulp CLI outputs.
- `apt-client.log` records apt-get update and install output.
- `pulp-release-page.png` is captured by the Playwright CLI.

## Teardown

Runtime state is disposable:

```bash
harness/local/scripts/destroy-pulp-session.sh --session-id local-apt-smoke --force
```

Evidence is preserved unless removed manually.

## Troubleshooting

If setup fails before Pulp is ready, inspect `.runtime/pulp-sessions/<session-id>/logs/`.

If `pulp_deb` is missing, choose a Pulp image that includes the Debian plugin and
rerun setup with `PULP_IMAGE=<image> --recreate`.

If the apt client cannot reach Pulp, check whether the selected runtime supports
the configured host alias. Docker uses `host.docker.internal`; Podman uses
`host.containers.internal`.

If Playwright evidence capture fails, install the Playwright CLI or ensure `npx`
can run it before claiming test completion.