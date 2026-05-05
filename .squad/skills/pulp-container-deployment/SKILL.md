---
name: "pulp-container-deployment"
description: "Deploy Pulp as a single bundled container for local, smoke, and pre-Azure validation workflows"
domain: "deployment"
confidence: "low"
source: "Official Pulp OCI images quickstart, first captured for this project on 2026-05-05T01:45:46.172+00:00"
---

## Context

Use this skill when an agent needs to stand up a working Pulp instance quickly from the bundled OCI image. It applies to:

- Local development on a workstation or build host.
- Smoke testing Pulp plugin behavior before adding Azure infrastructure.
- Single-node validation where persistent local directories are acceptable.
- Pre-Azure validation of Pulp API, content, worker, and storage assumptions.
- Harness bootstrapping before low-side/high-side bundle import workflows exist.
- Disconnected transfer rehearsals where the image is already available locally or in an internal registry.

This is not a production topology for Azure. Treat it as the fastest verifiable deployment pattern for Pulp workflow automation and bundle-transfer tests.

## Patterns

### 1. Pick a runtime through the harness pattern

For project automation, do not hardcode `podman` or `docker`. Source the harness common script and use `resolve_container_runtime` from `container-runtime-harness`:

```bash
# From repository root, in scripts that live under harness/local/scripts/.
# shellcheck source=harness/local/scripts/common.sh
source "$(dirname "$0")/common.sh"
resolve_container_runtime
runtime="${PULP_CONTAINER_RUNTIME}"
```

For one-off manual commands, set a shell variable explicitly:

```bash
runtime=podman   # preferred on Linux hosts with SELinux support
# runtime=docker # use when Docker is the available local runtime
```

### 2. Create the directory scaffold

Create the deployment work directory and persistent subdirectories before starting the container:

```bash
mkdir -p pulp-single-container
cd pulp-single-container
mkdir -p settings/certs pulp_storage pgsql containers container_build
```

Directory purposes:

| Path | Container mount | Persistence | Purpose |
| --- | --- | --- | --- |
| `settings/` | `/etc/pulp` | Critical | Pulp settings, generated cert material, `SECRET_KEY`, and database encrypted-field key material where applicable. |
| `settings/certs/` | under `/etc/pulp` | Critical | TLS or plugin certificate material. Keep private keys protected. |
| `pulp_storage/` | `/var/lib/pulp` | Critical | Pulp application data, artifact storage, repository content, exports, imports, and uploaded files. |
| `pgsql/` | `/var/lib/pgsql` | Critical | Bundled PostgreSQL database state. Losing it loses Pulp state. |
| `containers/` | `/var/lib/containers` | Recommended for `pulp_container` | Container registry storage used by `pulp_container`. Less critical than the database/content/config set, but preserve it for stability and recoverability when container repositories are in use. |
| `container_build/` | `/var/lib/pulp/.local/share/containers` | Recommended for `pulp_container` | Buildah/container build cache used by `pulp_container`. Less critical than the database/content/config set, but preserve it when diagnosing or recovering container workflows. |

Back up `settings/`, `pulp_storage/`, and `pgsql/` together. They are a mandatory consistency set. Preserve `containers/` and `container_build/` when `pulp_container` workflows matter, especially before upgrades or recovery work.

### 3. Define deployment variables

Set the externally reachable endpoint once and reuse it in `settings.py`, run commands, status checks, and `pulp-cli` profiles. Do not derive reusable automation from `$(hostname)` or a hardcoded FQDN.

HTTP localhost smoke test:

```bash
PULP_SCHEME=http
PULP_HOST=localhost
PULP_HTTP_HOST_PORT=8080
PULP_CONTAINER_HTTP_PORT=80
PULP_CONTENT_ORIGIN="${PULP_SCHEME}://${PULP_HOST}:${PULP_HTTP_HOST_PORT}"
PULP_CONTAINER_NAME=pulp
```

HTTPS localhost smoke test:

```bash
PULP_SCHEME=https
PULP_HOST=localhost
PULP_HTTPS_HOST_PORT=8443
PULP_CONTAINER_HTTPS_PORT=443
PULP_CONTENT_ORIGIN="${PULP_SCHEME}://${PULP_HOST}:${PULP_HTTPS_HOST_PORT}"
PULP_CONTAINER_NAME=pulp
```

Alternate-port example when `8080` is occupied:

```bash
PULP_SCHEME=http
PULP_HOST=localhost
PULP_HTTP_HOST_PORT=18080
PULP_CONTAINER_HTTP_PORT=80
PULP_CONTENT_ORIGIN="${PULP_SCHEME}://${PULP_HOST}:${PULP_HTTP_HOST_PORT}"
PULP_CONTAINER_NAME=pulp-smoke-18080
```

For customer or CI automation, set `PULP_HOST` to the operator-provided DNS name, reverse-proxy name, or localhost binding that clients actually use. If the host port changes, update `PULP_CONTENT_ORIGIN`, curl checks, and `pulp-cli --base-url` in the same change.

### 4. Generate `settings/settings.py`

The quickstart settings below are minimal. They are not the complete production configuration. Use the Pulpcore settings documentation for the full settings list and version-specific behavior: <https://pulpproject.org/pulpcore/docs/admin/reference/settings/>.

Generate a unique secret from an approved local secret source and write settings from the variables above:

```bash
: "${PULP_CONTENT_ORIGIN:?set PULP_CONTENT_ORIGIN first}"
PULP_SECRET_KEY="$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(64))
PY
)"

cat > settings/settings.py <<EOF_SETTINGS
CONTENT_ORIGIN='${PULP_CONTENT_ORIGIN}'
SECRET_KEY='${PULP_SECRET_KEY}'
EOF_SETTINGS
chmod 600 settings/settings.py
unset PULP_SECRET_KEY
```

Operational notes:

- `SECRET_KEY` must be unique, unpredictable, and persistent per deployment. Generate it once per environment; do not regenerate it on every restart.
- Back up `settings/settings.py` with `settings/`, `pulp_storage/`, and `pgsql/`. Losing or changing secret/key material can break encrypted-field access and invalidate existing state.
- Keep generated key material for database encrypted fields, plugin certificates, TLS certificates, and container signing/authentication under `settings/` or `settings/certs/` so it survives container replacement.
- Put persistent Pulp settings in `settings/settings.py`; keep environment-only runtime toggles in the container command.
- Plugin settings belong here when they must survive restarts.
- Keep `CONTENT_ORIGIN` aligned with how clients reach Pulp. If clients use a reverse proxy, alternate port, HTTPS endpoint, or localhost-only endpoint, set `PULP_CONTENT_ORIGIN` accordingly.
- Never commit `settings/settings.py`, generated private keys, admin passwords, or CLI profiles.

Non-leaking `SECRET_KEY` verification:

```bash
python3 - <<'PY'
from pathlib import Path
import ast
path = Path('settings/settings.py')
module = ast.parse(path.read_text())
values = {}
for node in module.body:
    if isinstance(node, ast.Assign):
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id in {'SECRET_KEY', 'CONTENT_ORIGIN'}:
                values[target.id] = ast.literal_eval(node.value)
secret = values.get('SECRET_KEY', '')
blocked = {'', 'replace-with-a-unique-unpredictable-secret', 'changeme', 'change-me', 'secret', 'sample', 'default'}
if secret.strip().lower() in blocked or len(secret) < 50:
    raise SystemExit('BLOCK: SECRET_KEY is missing, too short, or a documented placeholder')
if not values.get('CONTENT_ORIGIN', '').startswith(('http://', 'https://')):
    raise SystemExit('BLOCK: CONTENT_ORIGIN must be an explicit http(s) URL')
print('OK: settings.py contains explicit CONTENT_ORIGIN and a non-placeholder SECRET_KEY; secret value not printed')
PY
```

Do not print the `SECRET_KEY` in logs or evidence. To compare environments without leaking it, record only a local, access-controlled fingerprint when policy allows:

```bash
python3 - <<'PY'
from pathlib import Path
import ast, hashlib
module = ast.parse(Path('settings/settings.py').read_text())
secret = None
for node in module.body:
    if isinstance(node, ast.Assign):
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == 'SECRET_KEY':
                secret = ast.literal_eval(node.value)
if not secret:
    raise SystemExit('BLOCK: SECRET_KEY missing')
print('SECRET_KEY fingerprint:', hashlib.sha256(secret.encode()).hexdigest()[:12])
PY
```

Use the fingerprint only to confirm two deployments are not accidentally sharing the same key. Do not publish it in customer-facing evidence unless the evidence policy permits it.

### 5. Pin the image

The official image defaults to `pulp/pulp:stable` or `pulp/pulp:latest` depending on invocation. Do not use floating tags in automation.

Manual smoke test:

```bash
PULP_IMAGE="pulp/pulp:3.21"
```

Repeatable automation:

```bash
PULP_IMAGE="registry.example.internal/pulp/pulp:3.21@sha256:<digest>"
```

Rules:

- Pin at least to an explicit version tag, such as `pulp/pulp:3.21`.
- Prefer tag-plus-digest references in CI and disconnected harnesses.
- Record the image reference with test evidence.
- Use `latest` only for disposable exploration where reproducibility does not matter.

### 5. Run with Podman on SELinux-enabled hosts

Use `:Z` on host volume mounts so SELinux labels allow container access:

```bash
runtime=podman
PULP_IMAGE="pulp/pulp:3.21"

"${runtime}" run --detach \
  --publish 8080:80 \
  --name pulp \
  --volume "$(pwd)/settings":/etc/pulp:Z \
  --volume "$(pwd)/pulp_storage":/var/lib/pulp:Z \
  --volume "$(pwd)/pgsql":/var/lib/pgsql:Z \
  --volume "$(pwd)/containers":/var/lib/containers:Z \
  --volume "$(pwd)/container_build":/var/lib/pulp/.local/share/containers:Z \
  --device /dev/fuse \
  "${PULP_IMAGE}"
```

### 6. Run with Podman when SELinux is disabled

Drop `:Z` from the persistent mounts. Keep the `container_build` mount shape from the upstream quickstart:

```bash
runtime=podman
PULP_IMAGE="pulp/pulp:3.21"

"${runtime}" run --detach \
  --publish 8080:80 \
  --name pulp \
  --volume "$(pwd)/settings":/etc/pulp \
  --volume "$(pwd)/pulp_storage":/var/lib/pulp \
  --volume "$(pwd)/pgsql":/var/lib/pgsql \
  --volume "$(pwd)/containers":/var/lib/containers \
  --volume "$(pwd)/container_build":/var/lib/pulp/.local/share/containers:Z \
  --device /dev/fuse \
  "${PULP_IMAGE}"
```

### 7. Run with Docker

Substitute Docker for Podman and omit SELinux labels from the persistent mounts. If Docker rejects `:Z` on `container_build` for the target host, remove it consistently for that host and document the reason in the harness evidence.

```bash
runtime=docker
PULP_IMAGE="pulp/pulp:3.21"

"${runtime}" run --detach \
  --publish 8080:80 \
  --name pulp \
  --volume "$(pwd)/settings":/etc/pulp \
  --volume "$(pwd)/pulp_storage":/var/lib/pulp \
  --volume "$(pwd)/pgsql":/var/lib/pgsql \
  --volume "$(pwd)/containers":/var/lib/containers \
  --volume "$(pwd)/container_build":/var/lib/pulp/.local/share/containers:Z \
  --device /dev/fuse \
  "${PULP_IMAGE}"
```

Docker Desktop notes:

- `/dev/fuse` must be available to the Docker environment for `pulp_container` storage paths.
- Root-owned files can appear in mounted directories. Clean them through a targeted one-off container rather than broad host deletes.

### 8. Run with HTTPS enabled

Set `PULP_HTTPS=true`, publish host port `8080` to container port `443`, and set `CONTENT_ORIGIN` to `https://...`.

Podman SELinux HTTPS example:

```bash
runtime=podman
PULP_IMAGE="pulp/pulp:3.21"

"${runtime}" run --detach \
  --publish 8080:443 \
  --env PULP_HTTPS=true \
  --name pulp \
  --volume "$(pwd)/settings":/etc/pulp:Z \
  --volume "$(pwd)/pulp_storage":/var/lib/pulp:Z \
  --volume "$(pwd)/pgsql":/var/lib/pgsql:Z \
  --volume "$(pwd)/containers":/var/lib/containers:Z \
  --volume "$(pwd)/container_build":/var/lib/pulp/.local/share/containers:Z \
  --device /dev/fuse \
  "${PULP_IMAGE}"
```

Docker HTTPS example:

```bash
runtime=docker
PULP_IMAGE="pulp/pulp:3.21"

"${runtime}" run --detach \
  --publish 8080:443 \
  --env PULP_HTTPS=true \
  --name pulp \
  --volume "$(pwd)/settings":/etc/pulp \
  --volume "$(pwd)/pulp_storage":/var/lib/pulp \
  --volume "$(pwd)/pgsql":/var/lib/pgsql \
  --volume "$(pwd)/containers":/var/lib/containers \
  --volume "$(pwd)/container_build":/var/lib/pulp/.local/share/containers:Z \
  --device /dev/fuse \
  "${PULP_IMAGE}"
```

### 9. Post-deploy checklist

Run this sequence every time. Do not declare the deployment ready from container start alone.

1. Confirm the container is running:

   ```bash
   "${runtime}" ps --filter name=pulp
   ```

2. Follow startup logs until services settle:

   ```bash
   "${runtime}" logs --tail 200 pulp
   ```

3. Reset the admin password and store it in an approved local secret store:

   ```bash
   "${runtime}" exec -it pulp bash -c 'pulpcore-manager reset-admin-password'
   ```

   In non-interactive automation, prefer a documented secret injection method approved by the project rather than embedding plaintext in scripts.

4. Check the API status endpoint:

   ```bash
   curl --fail --show-error --silent http://localhost:8080/pulp/api/v3/status/ | python3 -m json.tool
   ```

   For HTTPS:

   ```bash
   curl --fail --show-error --silent --insecure https://localhost:8080/pulp/api/v3/status/ | python3 -m json.tool
   ```

5. Run Pulp's deploy check inside the container:

   ```bash
   "${runtime}" exec pulp bash -c 'pulpcore-manager check --deploy'
   ```

6. Confirm online workers and expected plugin versions from the status JSON. Capture the JSON as evidence when the deployment feeds a test run.

7. Verify persistent mounts by restarting the container and re-checking status:

   ```bash
   "${runtime}" stop pulp
   "${runtime}" start pulp
   curl --fail --show-error --silent http://localhost:8080/pulp/api/v3/status/ | python3 -m json.tool
   ```

8. Only after these checks, run repository, sync, export, import, or publication workflows.

### 10. Install and configure `pulp-cli`

Install the CLI in a virtual environment or controlled tool environment:

```bash
python3 -m venv .venv-pulp-cli
. .venv-pulp-cli/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install 'pulp-cli[pygments]'
```

Create a local CLI profile after the admin password is reset:

```bash
pulp config create \
  --username admin \
  --base-url http://localhost:8080 \
  --password '<admin-password>'
```

For HTTPS with a self-signed certificate during local smoke testing:

```bash
pulp config create \
  --username admin \
  --base-url https://localhost:8080 \
  --password '<admin-password>' \
  --verify-ssl false
```

Validate CLI access:

```bash
pulp status
```

Use `pulp-cli` or native Pulp REST calls for workflow automation. Do not build a custom Pulp API wrapper.

## Integration

- **`container-runtime-harness`:** Use `resolve_container_runtime` and execute through the resolved `runtime` variable. Keep `PULP_CONTAINER_RUNTIME=auto` behavior instead of hardcoding `podman` or `docker` in reusable scripts.
- **`local-container-validation`:** After deploying, follow the validation ladder: host prerequisites, static config, single-service readiness, workflow smoke, disconnected low/high path, negative tests, and evidence capture.
- **`pulp-bundle-workflows`:** Treat this deployed instance as the local target for native Pulp export/import workflows. Bundle tooling should orchestrate Pulp's existing CLI or REST behavior and validate transfer manifests; it should not reimplement Pulp state, checksum, export, or import logic.

## Compose Alternative

Use Compose instead of the single bundled container when the test needs service boundaries, scaled API/content workers, external database behavior, or closer parity with multi-service deployment.

Basic upstream Compose flow:

```bash
git clone https://github.com/pulp/pulp-oci-images.git
cd pulp-oci-images/images/compose
podman-compose up
# or
docker-compose up
```

Scale API and content services when exercising concurrency or routing behavior:

```bash
docker-compose scale pulp_api=4 pulp_content=4
```

Use the folder-volume Compose variant when persistent host directories must be inspected or archived as evidence.

Prefer single container when:

- The goal is quick API/plugin smoke validation.
- A bundle import/export harness needs one reachable Pulp endpoint.
- The team is proving local workflow logic before Azure topology design.

Prefer Compose when:

- Testing worker/API/content process separation.
- Testing scale-out behavior.
- Testing Compose-specific harness scripts.
- Preparing evidence that depends on service-specific logs.

## Air-Gap Considerations

Disconnected environments must not assume public registry or package-source access.

Required practices:

1. Pre-pull, mirror, or load the Pulp image before the disconnected run:

   ```bash
   docker pull pulp/pulp:3.21
   docker save pulp/pulp:3.21 -o pulp-pulp-3.21.tar
   # transfer tar through the approved media process
   docker load -i pulp-pulp-3.21.tar
   ```

   Use the equivalent `podman pull`, `podman save`, and `podman load` commands on Podman-only hosts.

2. In automation, set pull policy to never unless the test is explicitly connected-mode:

   ```bash
   export PULP_PULL_POLICY=never
   "${runtime}" run --pull=never ... "${PULP_IMAGE}"
   ```

3. Use private/internal registry references with explicit digests for high-side tests:

   ```bash
   PULP_IMAGE="highside.registry.example/pulp/pulp:3.21@sha256:<digest>"
   ```

4. Capture image identity as evidence:

   ```bash
   "${runtime}" image inspect "${PULP_IMAGE}" --format '{{json .RepoDigests}}'
   ```

5. Keep high-side settings free of public upstream package URLs.

6. Treat manual hard-drive transfer as a workflow step with manifest, checksum, custody, import-check, import, publish, and evidence gates.

7. Validate that the high-side deployment can run status, import-check, import, publish, and client consumption without egress.

## Examples

### Recreate a clean local smoke instance

```bash
runtime=docker
PULP_IMAGE="pulp/pulp:3.21"

"${runtime}" rm -f pulp || true
mkdir -p pulp-single-container
cd pulp-single-container
mkdir -p settings/certs pulp_storage pgsql containers container_build
cat > settings/settings.py <<EOF_SETTINGS
CONTENT_ORIGIN='http://localhost:8080'
SECRET_KEY='replace-with-a-unique-unpredictable-secret'
EOF_SETTINGS
chmod 600 settings/settings.py

"${runtime}" run --detach \
  --pull=missing \
  --publish 8080:80 \
  --name pulp \
  --volume "$(pwd)/settings":/etc/pulp \
  --volume "$(pwd)/pulp_storage":/var/lib/pulp \
  --volume "$(pwd)/pgsql":/var/lib/pgsql \
  --volume "$(pwd)/containers":/var/lib/containers \
  --volume "$(pwd)/container_build":/var/lib/pulp/.local/share/containers:Z \
  --device /dev/fuse \
  "${PULP_IMAGE}"

curl --retry 30 --retry-delay 5 --retry-all-errors --fail \
  http://localhost:8080/pulp/api/v3/status/
"${runtime}" exec pulp bash -c 'pulpcore-manager check --deploy'
```

### Stop without deleting state

```bash
"${runtime}" stop pulp
```

### Remove the container but keep persistent data

```bash
"${runtime}" rm pulp
```

### Destroy local state intentionally

Only do this for disposable test data:

```bash
"${runtime}" rm -f pulp || true
rm -rf settings pulp_storage pgsql containers container_build
```

## Anti-Patterns

- Using `latest` or floating `stable` tags in CI, release automation, or air-gap rehearsals.
- Declaring readiness because `podman run` or `docker run` returned a container ID.
- Losing consistency by backing up `pulp_storage/` without `pgsql/` and `settings/`.
- Committing `SECRET_KEY`, admin passwords, generated private keys, or CLI profiles.
- Hardcoding `podman` in project scripts instead of using the runtime harness pattern.
- Pulling from public registries during disconnected validation.
- Treating the single bundled container as the final Azure production topology.
- Building a custom Pulp API client instead of calling `pulp-cli` or native REST endpoints.
- Skipping `pulpcore-manager check --deploy` after startup.
- Letting high-side workflows reach public package sources or public image registries.
