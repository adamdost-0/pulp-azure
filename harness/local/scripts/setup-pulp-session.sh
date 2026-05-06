#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=harness/local/scripts/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: setup-pulp-session.sh [--session-id ID] [--recreate]

Creates a disposable local Pulp session, installs an isolated pulp-cli, resets
the admin password for this session, and verifies Pulp readiness.
EOF_USAGE
}

recreate=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id) PULP_SESSION_ID="$2"; shift 2 ;;
    --recreate) recreate=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

require_cmd python3
require_cmd curl
resolve_container_runtime
session_defaults

if [[ -d "${PULP_SESSION_DIR}" && "${recreate}" -eq 0 ]]; then
  die "session already exists: ${PULP_SESSION_DIR}; pass --recreate or destroy it first"
fi

if [[ "${recreate}" -eq 1 ]]; then
  "${SCRIPT_DIR}/destroy-pulp-session.sh" --session-id "${PULP_SESSION_ID}" --force >/dev/null 2>&1 || true
fi

mkdir -p \
  "${PULP_SESSION_DIR}/settings/certs" \
  "${PULP_SESSION_DIR}/pulp_storage" \
  "${PULP_SESSION_DIR}/pgsql" \
  "${PULP_SESSION_DIR}/containers" \
  "${PULP_SESSION_DIR}/container_build" \
  "${PULP_SESSION_DIR}/logs" \
  "${PULP_SESSION_DIR}/upstream-repo" \
  "${PULP_SESSION_DIR}/workflow"

python3 - "${PULP_CONTENT_ORIGIN}" "${PULP_SESSION_DIR}/settings/settings.py" <<'PY'
import secrets
import sys
from pathlib import Path

origin = sys.argv[1]
path = Path(sys.argv[2])
secret = secrets.token_urlsafe(64)
path.write_text(f"CONTENT_ORIGIN='{origin}'\nSECRET_KEY='{secret}'\n", encoding="utf-8")
path.chmod(0o600)
PY

admin_password="$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(32))
PY
)"
printf '%s' "${admin_password}" > "${PULP_ADMIN_PASSWORD_FILE}"
chmod 600 "${PULP_ADMIN_PASSWORD_FILE}"

volume_suffix="$(runtime_volume_suffix)"
run_args=(run --detach "$(runtime_pull_arg "${PULP_PULL_POLICY}")" --name "${PULP_CONTAINER_NAME}" --publish "${PULP_HTTP_HOST_PORT}:${PULP_CONTAINER_HTTP_PORT}")
while IFS= read -r arg; do
  [[ -n "${arg}" ]] && run_args+=("${arg}")
done < <(runtime_add_host_args)
if [[ -e /dev/fuse ]]; then
  run_args+=(--device /dev/fuse)
fi
run_args+=(
  --volume "${PULP_SESSION_DIR}/settings:/etc/pulp${volume_suffix}"
  --volume "${PULP_SESSION_DIR}/pulp_storage:/var/lib/pulp${volume_suffix}"
  --volume "${PULP_SESSION_DIR}/pgsql:/var/lib/pgsql${volume_suffix}"
  --volume "${PULP_SESSION_DIR}/containers:/var/lib/containers${volume_suffix}"
  --volume "${PULP_SESSION_DIR}/container_build:/var/lib/pulp/.local/share/containers${volume_suffix}"
  "${PULP_IMAGE}"
)

log "starting ${PULP_CONTAINER_NAME} from ${PULP_IMAGE} on ${PULP_CONTENT_ORIGIN}"
"${PULP_CONTAINER_RUNTIME}" "${run_args[@]}" > "${PULP_SESSION_DIR}/container.id"

status_url="${PULP_CONTENT_ORIGIN}/pulp/api/v3/status/"
for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "${status_url}" > "${PULP_SESSION_DIR}/workflow/status.json" 2>"${PULP_SESSION_DIR}/logs/status-wait.err"; then
    break
  fi
  sleep 5
done
curl --fail --silent --show-error "${status_url}" > "${PULP_SESSION_DIR}/workflow/status.json"

log "running Pulp deploy check"
"${PULP_CONTAINER_RUNTIME}" exec "${PULP_CONTAINER_NAME}" bash -lc 'pulpcore-manager check --deploy' \
  > "${PULP_SESSION_DIR}/logs/deploy-check.log" 2>&1

log "resetting disposable admin password"
# shellcheck disable=SC2016
"${PULP_CONTAINER_RUNTIME}" exec -e PULP_ADMIN_PASSWORD="${admin_password}" "${PULP_CONTAINER_NAME}" \
  bash -lc 'pulpcore-manager reset-admin-password --username admin --password "$PULP_ADMIN_PASSWORD"' \
  > "${PULP_SESSION_DIR}/logs/reset-admin-password.log" 2>&1

python3 - "${PULP_SESSION_DIR}/workflow/status.json" <<'PY'
import json
import sys
from pathlib import Path

status = json.loads(Path(sys.argv[1]).read_text())
versions = status.get("versions", {})
if isinstance(versions, dict):
  plugins = set(versions)
elif isinstance(versions, list):
  plugins = {item.get("package") or item.get("component") for item in versions if isinstance(item, dict)}
else:
  plugins = set()
workers = status.get("online_workers") or status.get("workers") or []
if "pulp_deb" not in plugins:
  raise SystemExit(f"pulp_deb plugin not available; found plugins: {sorted(plugin for plugin in plugins if plugin)}")
if isinstance(workers, list) and not workers:
    raise SystemExit("no online Pulp workers reported by status endpoint")
print("readiness: pulp_deb present and workers reported")
PY

log "creating isolated pulp-cli environment"
python3 -m venv "${PULP_CLI_VENV}"
"${PULP_CLI_VENV}/bin/python" -m pip install --upgrade pip > "${PULP_SESSION_DIR}/logs/pip-install.log" 2>&1
"${PULP_CLI_VENV}/bin/python" -m pip install 'pulp-cli[pygments]' pulp-cli-deb >> "${PULP_SESSION_DIR}/logs/pip-install.log" 2>&1

"${PULP_CLI_BIN}" config create \
  --location "${PULP_CONFIG_FILE}" \
  --overwrite \
  --base-url "${PULP_CONTENT_ORIGIN}" \
  --username admin \
  --password "${admin_password}" \
  --plugin deb \
  --plugin core \
  > "${PULP_SESSION_DIR}/logs/pulp-config-create.log" 2>&1
chmod 600 "${PULP_CONFIG_FILE}"

write_session_env
pulp_cmd status > "${PULP_SESSION_DIR}/workflow/pulp-status.json"

cat <<EOF_READY
Disposable Pulp session is ready.
Session: ${PULP_SESSION_ID}
Endpoint: ${PULP_CONTENT_ORIGIN}
Session directory: ${PULP_SESSION_DIR}
Next: harness/local/scripts/run-pulp-solution.sh --session-id ${PULP_SESSION_ID}
EOF_READY
