# Local Pulp Capability Harness

This harness supports Phase 0 issue #6: prove the core Pulp APT/deb workflow locally before Azure deployment.

The committed files do not hardcode public registries. Configure images through `.env` or exported environment variables. Connected local development may use public images for exploration, but Phase 1 high-side deployment requires mirrored private ACR images.

## What this harness validates

- Podman Compose can run amd64 images on an arm64 workstation using `platform: linux/amd64`.
- A local Pulp OCI single-container quickstart can start with pinned Pulp 3.x and `pulp_deb`.
- A deterministic Ubuntu-style APT fixture can be generated without Azure.
- Transfer manifests can be generated with checksums.
- A high-side no-egress network can be created for offline import/publication tests.
- Native Pulp export/import (pulpcore `exporters/core/pulp`) works end-to-end across isolated
  low and high containers (Phase 0 export/import closeout).

## Quick start: single-container Pulp

```sh
cd harness/local
cp env.example .env
# edit .env image references to internal/private mirrors

./scripts/validate-amd64.sh
./scripts/generate-fixture.sh
./scripts/generate-manifest.sh low-to-high-demo .work/fixture .work/media
./scripts/validate-no-egress.sh
```

On macOS, start the Podman VM first with `podman machine start`. Linux hosts
with SELinux enforcing can set `PULP_VOLUME_SUFFIX=:Z`; on macOS the relabel
flag is normally unnecessary because containers run inside the Podman VM.

Start the default rapid local Pulp harness using the Pulp OCI single-container
quickstart shape:

```sh
./scripts/start-single-container.sh
curl --fail http://localhost:${PULP_HTTP_PORT:-18080}/pulp/api/v3/status/
./scripts/start-single-container.sh stop
```

The script creates persistent quickstart directories under
`${PULP_SINGLE_WORKDIR:-.work/single-container}`:

- `settings` mounted at `/etc/pulp`
  - `settings/certs` is created for image-generated certificates and keys
- `pulp_storage` mounted at `/var/lib/pulp`
- `pgsql` mounted at `/var/lib/pgsql`
- `containers` mounted at `/var/lib/containers`
- `container_build` mounted at `/var/lib/pulp/.local/share/containers`

It removes stale containers with the same name, maps `${PULP_HTTP_PORT:-18080}`
to container port 80, uses `--device /dev/fuse` when the host exposes it, waits
for `/pulp/api/v3/status/`, and resets the local admin password to
`${PULP_ADMIN_PASSWORD:-password}` when the image supports non-interactive reset.
`PULP_PULL_POLICY=never` is the default so missing images fail instead of
pulling from public registries; set a different policy only for connected local
testing.

The generated `SECRET_KEY`, admin password, and HTTP endpoint are disposable
local-test values only. Do not reuse them in any Azure, high-side, or shared
environment; deployed Pulp instances must use environment-specific secrets,
internal HTTPS, and `pulpcore-manager check --deploy`.

Run the full local workflow against the single-container service:

```sh
./scripts/run-e2e.sh
```

`run-e2e.sh` generates the APT fixture, starts Pulp, syncs/publishes the fixture
through `pulp_deb`, and verifies the published content from an amd64 APT client
container. The default `PULP_E2E_MODE=single` is the Phase 0 rapid path.

## Legacy compose path

The previous multi-container Compose stack remains available for comparison:

```sh
PULP_E2E_MODE=compose ./scripts/run-e2e.sh
```

Use different `PULP_HTTP_PORT` values, container names, and Compose project names
for low-side and high-side stacks.

## Low-side / high-side export/import harness

`run-low-high-e2e.sh` proves the full native Pulp export/import workflow across
two isolated local containers - the Phase 0 export/import closeout path.

### Topology

| Role | Container | Port | Workdir |
|------|-----------|------|---------|
| Low (source) | `pulp-low` | 18080 | `.work/low` |
| High (air-gapped destination) | `pulp-high` | 18081 | `.work/high` |

The APT fixture HTTP server is started **only inside the low container network
namespace** so the high container has no outbound access to the fixture -
preserving the air-gap posture.

### What it does

1. Generates the APT fixture.
2. Starts `pulp-low`, syncs the fixture via `pulp_deb`.
3. Creates a native Pulp exporter (`/pulp/api/v3/exporters/core/pulp/`) and
   triggers a full export; polls the task until complete.
4. Copies the exported `.tar.gz` + TOC file from `.work/low/exports/` to
   `.work/high/imports/<batch>/`; generates and verifies `MANIFEST.sha256`.
5. Starts `pulp-high` (no fixture server in its network).
6. Calls the Pulp `import-check` API against the staged TOC.
7. Pre-creates the destination repository, creates a `PulpImporter` with an
   explicit `repo_mapping`, and triggers the import; polls the task/task-group.
8. Publishes the imported repository version and creates an APT distribution.
9. Runs an amd64 APT client container against the high-side endpoint and
   verifies `airgap-fixture 1.0.0` is resolvable.
10. Writes evidence under `.work/evidence/<timestamp>/` (status JSON, task JSON,
    manifest, import-check, container logs, apt-policy).

### Quick start

```sh
cd harness/local
cp env.example .env
# Set PULP_SINGLE_IMAGE (or PULP_IMAGE) and APT_CLIENT_IMAGE to internal/private
# mirror references; set PULP_PULL_POLICY=missing for connected local testing.

./scripts/run-low-high-e2e.sh
```

### Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `PULP_LOW_CONTAINER_NAME` | `pulp-low` | Low container name |
| `PULP_HIGH_CONTAINER_NAME` | `pulp-high` | High container name |
| `PULP_LOW_HTTP_PORT` | `18080` | Low API port |
| `PULP_HIGH_HTTP_PORT` | `18081` | High API port |
| `PULP_CONTAINER_NETWORK` | _(unset)_ | Optional network for either container |
| `CLEAN_EVIDENCE` | `0` | Set to `1` to remove evidence after success |

All other variables (`PULP_SINGLE_IMAGE`, `APT_CLIENT_IMAGE`, `PULP_PULL_POLICY`,
etc.) are shared with `run-e2e.sh` and sourced from `.env`.

### Settings written to each container

`start-single-container.sh` now writes the following to every container's
`settings.py` and mounts the corresponding host directories:

```python
ALLOWED_EXPORT_PATHS = ['/var/lib/pulp/exports']
ALLOWED_IMPORT_PATHS = ['/var/lib/pulp/imports']
```

Host mounts:

- `${PULP_SINGLE_WORKDIR}/exports` to `/var/lib/pulp/exports`
- `${PULP_SINGLE_WORKDIR}/imports` to `/var/lib/pulp/imports`

These settings are also written for the rapid `run-e2e.sh` single-container
path so export/import is available there without extra configuration.

### Evidence layout

```
.work/evidence/<timestamp>/
  low-status.json           Pulp status from low container
  high-status.json          Pulp status from high container
  low-sync-task.json        Sync task result
  low-export-info.json      Export resource (includes toc_info)
  low-export-task.json      Export task result
  import-manifest.sha256    SHA-256 manifest of staged artifacts
  high-import-check.json    import-check API response
  high-import-response.json Import task/task-group response
  high-publication-task.json Publication task result
  apt-policy.txt            apt-cache policy output from APT client
  low-container.log         Low container logs
  high-container.log        High container logs
```
