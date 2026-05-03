# Local Pulp Capability Harness

This harness supports Phase 0 issue #6: prove the core Pulp APT/deb workflow locally before Azure deployment.

The committed files do not hardcode public registries. Configure images through `.env` or exported environment variables. Connected local development may use public images for exploration, but Phase 1 high-side deployment requires mirrored private ACR images.

## What this harness validates

- Podman Compose can run amd64 images on an arm64 workstation using `platform: linux/amd64`.
- A local Pulp OCI single-container quickstart can start with pinned Pulp 3.x and `pulp_deb`.
- A deterministic Ubuntu-style APT fixture can be generated without Azure.
- Transfer manifests can be generated with checksums.
- A high-side no-egress network can be created for offline import/publication tests.

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
