#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"
load_env

runtime="${PULP_CONTAINER_RUNTIME:-podman}"
name="${PULP_CONTAINER_NAME:-pulp}"
port="${PULP_HTTP_PORT:-18080}"
workdir="${PULP_SINGLE_WORKDIR:-${HARNESS_WORKDIR}/single-container}"
case "${workdir}" in
  /*) ;;
  *) workdir="${HARNESS_DIR}/${workdir}" ;;
esac
settings_dir="${workdir}/settings"
admin_password="${PULP_ADMIN_PASSWORD:-password}"
base_url="http://localhost:${port}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [start|stop|restart|status|logs]

Starts the Pulp OCI single-container quickstart with persistent data under:
  ${workdir}
EOF
}

write_settings() {
  mkdir -p \
    "${settings_dir}" \
    "${settings_dir}/certs" \
    "${workdir}/pulp_storage" \
    "${workdir}/pgsql" \
    "${workdir}/containers" \
    "${workdir}/container_build"

  python3 - "${settings_dir}/settings.py" "${base_url}" <<'PY'
import pathlib
import sys

settings_path = pathlib.Path(sys.argv[1])
content_origin = sys.argv[2]
existing = settings_path.read_text() if settings_path.exists() else ""
lines = [line for line in existing.splitlines() if not line.startswith(("CONTENT_ORIGIN", "SECRET_KEY", "ANALYTICS"))]
lines.extend([
    f"CONTENT_ORIGIN = {content_origin!r}",
    "SECRET_KEY = 'local-single-container-harness-only'",
    "ANALYTICS = False",
])
settings_path.write_text("\n".join(lines).rstrip() + "\n")
PY
}

container_running() {
  "${runtime}" inspect -f '{{.State.Running}}' "${name}" 2>/dev/null | grep -q true
}

remove_container() {
  if "${runtime}" inspect "${name}" >/dev/null 2>&1; then
    echo "Removing stale Pulp container ${name}"
    "${runtime}" rm -f "${name}" >/dev/null
  fi
}

print_diagnostics() {
  echo "Pulp container diagnostics:" >&2
  "${runtime}" ps -a --filter "name=${name}" >&2 || true
  "${runtime}" logs --tail 200 "${name}" >&2 || true
}

wait_for_status() {
  echo "Waiting for Pulp API at ${base_url}/pulp/api/v3/status/"
  for _ in $(seq 1 "${PULP_START_TIMEOUT_ATTEMPTS:-180}"); do
    if curl --fail --silent "${base_url}/pulp/api/v3/status/" >/dev/null; then
      echo "Pulp API is ready at ${base_url}"
      return 0
    fi
    if ! container_running; then
      echo "Pulp container ${name} stopped before the status endpoint became ready" >&2
      print_diagnostics
      return 1
    fi
    sleep "${PULP_START_WAIT_SECONDS:-5}"
  done
  echo "Timed out waiting for ${base_url}/pulp/api/v3/status/" >&2
  print_diagnostics
  return 1
}

reset_admin_password() {
  echo "Setting admin password for disposable local harness user"
  if "${runtime}" exec -e PULP_DEFAULT_ADMIN_PASSWORD="${admin_password}" "${name}" \
    /bin/sh -lc 'command -v set_init_password.sh >/dev/null 2>&1 && set_init_password.sh' >/dev/null 2>&1; then
    return 0
  fi

  if "${runtime}" exec "${name}" pulpcore-manager reset-admin-password \
    --username admin --password "${admin_password}" >/dev/null 2>&1; then
    return 0
  fi

  if printf '%s\n%s\n' "${admin_password}" "${admin_password}" | \
    "${runtime}" exec -i "${name}" pulpcore-manager reset-admin-password >/dev/null; then
    return 0
  fi

  echo "Unable to reset admin password non-interactively in ${name}" >&2
  print_diagnostics
  return 1
}

start_container() {
  require_cmd curl
  require_cmd python3
  local image
  image="$(resolve_pulp_single_image)"
  write_settings
  remove_container

  local volume_suffix="${PULP_VOLUME_SUFFIX:-}"
  local -a run_args=()
  run_args=(run --detach --pull="${PULP_PULL_POLICY:-never}")
  if [[ -n "${PULP_PLATFORM:-}" ]]; then
    run_args+=(--platform "${PULP_PLATFORM}")
  fi
  run_args+=(
    --publish "${port}:80"
    --name "${name}"
    --volume "${settings_dir}:/etc/pulp${volume_suffix}"
    --volume "${workdir}/pulp_storage:/var/lib/pulp${volume_suffix}"
    --volume "${workdir}/pgsql:/var/lib/pgsql${volume_suffix}"
    --volume "${workdir}/containers:/var/lib/containers${volume_suffix}"
    --volume "${workdir}/container_build:/var/lib/pulp/.local/share/containers${volume_suffix}"
  )
  if [[ -e /dev/fuse ]]; then
    run_args+=(--device /dev/fuse)
  else
    echo "Warning: /dev/fuse is not available on this host; starting without a fuse device." >&2
  fi
  run_args+=("${image}")

  echo "Starting Pulp single-container as ${name} on ${base_url}"
  "${runtime}" "${run_args[@]}" >/dev/null

  wait_for_status
  reset_admin_password
  curl --fail --silent -u "admin:${admin_password}" "${base_url}/pulp/api/v3/status/" >/dev/null
  echo "single-container-ok ${base_url}"
}

stop_container() {
  remove_container
}

command="${1:-start}"

case "${command}" in
  -h|--help|help)
    usage
    exit 0
    ;;
esac

require_cmd "${runtime}"

case "${command}" in
  start)
    start_container
    ;;
  stop)
    stop_container
    ;;
  restart)
    stop_container
    start_container
    ;;
  status)
    if container_running; then
      curl --fail --silent "${base_url}/pulp/api/v3/status/"
    else
      echo "Container ${name} is not running" >&2
      exit 1
    fi
    ;;
  logs)
    "${runtime}" logs -f "${name}"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
