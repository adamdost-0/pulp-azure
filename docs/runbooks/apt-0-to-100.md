# Pulp CLI Apt 0-to-100 Configuration Runbook

This runbook defines the target Pulp CLI flow for a clean disposable Pulp
session becoming a fully configured apt repository service with validation
evidence.

## Storage and Tooling Boundary

Development runtime state defaults to NAS-backed storage:

```text
/home/adamdost/synology/appconfig/pulp-azure
```

Use the sandbox for Pulp CLI inspection and validation tooling instead of
installing tooling on the host:

```bash
harness/sandbox/scripts/validate-sandbox.sh --rebuild
harness/sandbox/scripts/run-sandbox.sh -- pulp deb --help
```

The host still needs Docker or Podman to run containers.

## Target Flow

```text
0. Prepare sandbox tooling
1. Start disposable Pulp session
2. Discover plugin versions and capabilities
3. Configure admin CLI profile
4. Create or update apt remote
5. Create or update apt repository
6. Sync repository
7. Capture repository version and content metadata
8. Create apt publication
9. Create or update apt distribution
10. Validate apt client consumption
11. Capture Playwright evidence
12. Optional: export/import rehearsal
```

## Command Skeleton

The current local harness covers the central path:

```bash
harness/local/scripts/setup-pulp-session.sh --session-id local-apt-smoke --recreate
harness/local/scripts/run-pulp-solution.sh --session-id local-apt-smoke --solution solutions/local-apt-smoke.json
harness/local/scripts/validate-apt-client.sh --session-id local-apt-smoke
harness/local/scripts/capture-evidence.sh --session-id local-apt-smoke
```

The eventual idempotent Pulp CLI implementation should expand to:

```bash
pulp status
pulp debug has-plugin --name deb
pulp deb remote show --name "$REMOTE" || pulp deb remote create ...
pulp deb remote update --name "$REMOTE" ...
pulp deb repository show --name "$REPO" || pulp deb repository create ...
pulp deb repository sync --name "$REPO" --remote "$REMOTE" --mirror
pulp deb repository version show --repository "$REPO"
pulp deb content --type package list --repository-version "$VERSION_HREF"
pulp deb content --type release list --repository-version "$VERSION_HREF"
pulp deb publication create --repository "$REPO" --structured
pulp deb distribution show --name "$DIST" || pulp deb distribution create ...
pulp deb distribution update --name "$DIST" --publication "$PUBLICATION_HREF"
```

## Acceptance Criteria

1. All Pulp runtime volumes live under `PULP_STORAGE_ROOT` by default.
2. Pulp CLI and validation tooling are available through the sandbox image.
3. The configured Pulp instance reports `pulp_deb`.
4. Apt remote, repository, publication, and distribution outputs are captured.
5. Repository version and content metadata are captured after sync.
6. An isolated apt client installs the expected package.
7. Evidence includes Pulp status, task outputs, fixture metadata, apt client log,
   sources list, and Playwright screenshot.
8. Re-running the flow is either idempotent or fails with a clear precondition
   error that identifies the existing resource.

## Known Gaps Before Production

1. Signed upstream Release verification through remote `--gpgkey`.
2. Apt publication signing through `--signing-service`.
3. Multi-distribution/component/architecture solution schema.
4. Plugin-version gates for `--optimize` and checkpoint options.
5. Idempotent resource reconciliation.
6. Core Pulp export/import command research and low/high validation.

