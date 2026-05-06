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

Use the sandbox when inspecting or validating Pulp CLI tooling so `pulp-cli`,
`pulp-cli-deb`, ShellCheck, Ruff, MyPy, Pytest, and Coverage do not need to be
installed on the host:

```bash
harness/sandbox/scripts/validate-sandbox.sh --rebuild
harness/sandbox/scripts/run-sandbox.sh -- pulp deb remote create --help
```

Do not edit host apt sources. The harness uses an isolated apt client container.

## Safe Defaults

Start from [harness/local/.env.example](../../harness/local/.env.example). The
scripts read environment variables, but they do not require a live `.env` file.
Keep secrets out of committed files.

The default session uses:

- Pulp endpoint: `http://localhost:18080`
- Upstream fixture server: port `18081`
- Runtime storage root: `/home/adamdost/synology/appconfig/pulp-azure`
- Pulp session root: `/home/adamdost/synology/appconfig/pulp-azure/pulp-sessions`
- Solution file: [solutions/local-apt-smoke.json](../../solutions/local-apt-smoke.json)
- Evidence root: `evidence/`

The harness intentionally stores disposable Pulp volumes on the NAS-backed
storage root instead of the repository checkout or host-local `.runtime/`.
Override `PULP_STORAGE_ROOT` to move all development runtime state together, or
override `PULP_SESSION_ROOT` when only Pulp session directories need a custom
location. Relative overrides are resolved under the repository root; absolute
overrides are used as-is.

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

- `README.md` is the human-readable review entry point with the proof chain,
  key resource hrefs, content summary, apt install excerpt, and artifact table.
- `manifest.json` is the machine-readable artifact manifest grouped by purpose.
- `pulp/` stores Pulp readiness and Pulp CLI resource JSON.
- `apt/` stores the source list and published Release endpoint body.
- `fixture/` stores deterministic package metadata and hashes.
- `logs/` stores apt client, Pulp sync, and Playwright command logs.
- `report/` stores the HTML evidence page rendered by Playwright.
- `screenshots/` stores Playwright screenshots.

Validate the package shape before sharing or committing evidence:

```bash
harness/local/scripts/validate-evidence-structure.sh
```

Repository hooks can run this gate locally before commits:

```bash
git config core.hooksPath .githooks
```

## Teardown

Runtime state is disposable:

```bash
harness/local/scripts/destroy-pulp-session.sh --session-id local-apt-smoke --force
```

Evidence is preserved unless removed manually.

## Troubleshooting

If setup fails before Pulp is ready, inspect
`/home/adamdost/synology/appconfig/pulp-azure/pulp-sessions/<session-id>/logs/`
or the equivalent custom `PULP_SESSION_ROOT`.

If `pulp_deb` is missing, choose a Pulp image that includes the Debian plugin and
rerun setup with `PULP_IMAGE=<image> --recreate`.

If the apt client cannot reach Pulp, check whether the selected runtime supports
the configured host alias. Docker uses `host.docker.internal`; Podman uses
`host.containers.internal`.

If Playwright evidence capture fails, install the Playwright CLI or ensure `npx`
can run it before claiming test completion.
