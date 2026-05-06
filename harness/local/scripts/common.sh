#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${HARNESS_DIR}/../.." && pwd)"
DEFAULT_PULP_STORAGE_ROOT="/home/adamdost/synology/appconfig/pulp-azure"

log() {
  printf '[pulp-harness] %s\n' "$*" >&2
}

die() {
  printf '[pulp-harness] ERROR: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

safe_id() {
  local value="$1"
  [[ "${value}" =~ ^[a-zA-Z0-9_.-]+$ ]] || die "unsafe identifier: ${value}"
}

resolve_repo_path() {
  local path="$1"
  if [[ "${path}" = /* ]]; then
    printf '%s' "${path}"
  else
    printf '%s/%s' "${REPO_ROOT}" "${path}"
  fi
}

resolve_container_runtime() {
  local requested="${PULP_CONTAINER_RUNTIME:-auto}"
  if [[ "${requested}" == "auto" ]]; then
    if command -v podman >/dev/null 2>&1; then
      PULP_CONTAINER_RUNTIME=podman
    elif command -v docker >/dev/null 2>&1; then
      PULP_CONTAINER_RUNTIME=docker
    else
      die "neither podman nor docker is available"
    fi
  else
    command -v "${requested}" >/dev/null 2>&1 || die "container runtime unavailable: ${requested}"
    PULP_CONTAINER_RUNTIME="${requested}"
  fi
  export PULP_CONTAINER_RUNTIME
}

runtime_host_alias() {
  case "${PULP_CONTAINER_RUNTIME}" in
    docker) printf 'host.docker.internal' ;;
    podman) printf 'host.containers.internal' ;;
    *) die "container runtime is not resolved" ;;
  esac
}

runtime_add_host_args() {
  case "${PULP_CONTAINER_RUNTIME}" in
    docker) printf '%s\n' '--add-host=host.docker.internal:host-gateway' ;;
    podman) true ;;
    *) die "container runtime is not resolved" ;;
  esac
}

runtime_volume_suffix() {
  case "${PULP_CONTAINER_RUNTIME}" in
    podman)
      if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce 2>/dev/null || true)" == "Enforcing" ]]; then
        printf ':Z'
      fi
      ;;
    docker) true ;;
    *) die "container runtime is not resolved" ;;
  esac
}

runtime_pull_arg() {
  local policy="${1:-missing}"
  case "${policy}" in
    never|missing|always) printf '%s' "--pull=${policy}" ;;
    *) die "unsupported pull policy: ${policy}" ;;
  esac
}

runtime_image_exists() {
  "${PULP_CONTAINER_RUNTIME}" image inspect "$1" >/dev/null 2>&1
}

session_defaults() {
  PULP_SESSION_ID="${PULP_SESSION_ID:-local-apt-smoke}"
  safe_id "${PULP_SESSION_ID}"
  PULP_STORAGE_ROOT="${PULP_STORAGE_ROOT:-${DEFAULT_PULP_STORAGE_ROOT}}"
  PULP_STORAGE_ROOT="$(resolve_repo_path "${PULP_STORAGE_ROOT}")"
  PULP_SESSION_ROOT="${PULP_SESSION_ROOT:-${PULP_STORAGE_ROOT}/pulp-sessions}"
  PULP_SESSION_ROOT="$(resolve_repo_path "${PULP_SESSION_ROOT}")"
  PULP_SESSION_DIR="${PULP_SESSION_ROOT}/${PULP_SESSION_ID}"
  PULP_CONTAINER_NAME="${PULP_CONTAINER_NAME:-pulp-${PULP_SESSION_ID}}"
  PULP_SCHEME="${PULP_SCHEME:-http}"
  PULP_HOST="${PULP_HOST:-localhost}"
  PULP_HTTP_HOST_PORT="${PULP_HTTP_HOST_PORT:-18080}"
  PULP_CONTAINER_HTTP_PORT="${PULP_CONTAINER_HTTP_PORT:-80}"
  PULP_CONTENT_ORIGIN="${PULP_CONTENT_ORIGIN:-${PULP_SCHEME}://${PULP_HOST}:${PULP_HTTP_HOST_PORT}}"
  PULP_IMAGE="${PULP_IMAGE:-pulp/pulp:3.21}"
  PULP_PULL_POLICY="${PULP_PULL_POLICY:-missing}"
  PULP_UPSTREAM_PORT="${PULP_UPSTREAM_PORT:-18081}"
  PULP_APT_CLIENT_IMAGE="${PULP_APT_CLIENT_IMAGE:-debian:bookworm-slim}"
  PULP_APT_CLIENT_PULL_POLICY="${PULP_APT_CLIENT_PULL_POLICY:-missing}"
  PULP_CLEANUP_IMAGE="${PULP_CLEANUP_IMAGE:-busybox:1.36}"
  PULP_EVIDENCE_ROOT="${PULP_EVIDENCE_ROOT:-evidence}"
  PULP_SOLUTION_FILE="${PULP_SOLUTION_FILE:-solutions/local-apt-smoke.json}"
  PULP_CONFIG_FILE="${PULP_SESSION_DIR}/pulp-cli.toml"
  PULP_CLI_VENV="${PULP_SESSION_DIR}/pulp-cli-venv"
  PULP_CLI_BIN="${PULP_CLI_VENV}/bin/pulp"
  PULP_ADMIN_PASSWORD_FILE="${PULP_SESSION_DIR}/admin-password"
  PULP_UPSTREAM_HOST_ALIAS="${PULP_UPSTREAM_HOST_ALIAS:-$(runtime_host_alias)}"
  PULP_CLIENT_HOST_ALIAS="${PULP_CLIENT_HOST_ALIAS:-$(runtime_host_alias)}"
  export PULP_STORAGE_ROOT PULP_SESSION_ROOT PULP_SESSION_ID PULP_SESSION_DIR
  export PULP_CONTAINER_NAME PULP_CONTENT_ORIGIN
  export PULP_IMAGE PULP_PULL_POLICY PULP_UPSTREAM_PORT PULP_UPSTREAM_HOST_ALIAS
  export PULP_APT_CLIENT_IMAGE PULP_APT_CLIENT_PULL_POLICY PULP_CLIENT_HOST_ALIAS
  export PULP_CONFIG_FILE PULP_CLI_VENV PULP_CLI_BIN PULP_ADMIN_PASSWORD_FILE
}

write_session_env() {
  mkdir -p "${PULP_SESSION_DIR}"
  cat > "${PULP_SESSION_DIR}/session.env" <<EOF_SESSION
PULP_SESSION_ID='${PULP_SESSION_ID}'
PULP_STORAGE_ROOT='${PULP_STORAGE_ROOT}'
PULP_SESSION_ROOT='${PULP_SESSION_ROOT}'
PULP_SESSION_DIR='${PULP_SESSION_DIR}'
PULP_CONTAINER_NAME='${PULP_CONTAINER_NAME}'
PULP_CONTAINER_RUNTIME='${PULP_CONTAINER_RUNTIME}'
PULP_IMAGE='${PULP_IMAGE}'
PULP_PULL_POLICY='${PULP_PULL_POLICY}'
PULP_CONTENT_ORIGIN='${PULP_CONTENT_ORIGIN}'
PULP_HTTP_HOST_PORT='${PULP_HTTP_HOST_PORT}'
PULP_UPSTREAM_PORT='${PULP_UPSTREAM_PORT}'
PULP_UPSTREAM_HOST_ALIAS='${PULP_UPSTREAM_HOST_ALIAS}'
PULP_CLIENT_HOST_ALIAS='${PULP_CLIENT_HOST_ALIAS}'
PULP_CONFIG_FILE='${PULP_CONFIG_FILE}'
PULP_CLI_VENV='${PULP_CLI_VENV}'
PULP_CLI_BIN='${PULP_CLI_BIN}'
PULP_ADMIN_PASSWORD_FILE='${PULP_ADMIN_PASSWORD_FILE}'
PULP_EVIDENCE_ROOT='${PULP_EVIDENCE_ROOT}'
PULP_SOLUTION_FILE='${PULP_SOLUTION_FILE}'
PULP_APT_CLIENT_IMAGE='${PULP_APT_CLIENT_IMAGE}'
PULP_APT_CLIENT_PULL_POLICY='${PULP_APT_CLIENT_PULL_POLICY}'
PULP_CLEANUP_IMAGE='${PULP_CLEANUP_IMAGE}'
EOF_SESSION
  chmod 600 "${PULP_SESSION_DIR}/session.env"
}

load_session_env() {
  local session_id="${1:-${PULP_SESSION_ID:-local-apt-smoke}}"
  safe_id "${session_id}"
  PULP_SESSION_ID="${session_id}"
  PULP_STORAGE_ROOT="${PULP_STORAGE_ROOT:-${DEFAULT_PULP_STORAGE_ROOT}}"
  PULP_STORAGE_ROOT="$(resolve_repo_path "${PULP_STORAGE_ROOT}")"
  PULP_SESSION_ROOT="${PULP_SESSION_ROOT:-${PULP_STORAGE_ROOT}/pulp-sessions}"
  PULP_SESSION_ROOT="$(resolve_repo_path "${PULP_SESSION_ROOT}")"
  PULP_SESSION_DIR="${PULP_SESSION_ROOT}/${PULP_SESSION_ID}"
  [[ -f "${PULP_SESSION_DIR}/session.env" ]] || die "missing session env: ${PULP_SESSION_DIR}/session.env"
  # shellcheck source=/dev/null
  source "${PULP_SESSION_DIR}/session.env"
}

pulp_cmd() {
  [[ -x "${PULP_CLI_BIN}" ]] || die "pulp CLI is not installed for this session: ${PULP_CLI_BIN}"
  "${PULP_CLI_BIN}" --config "${PULP_CONFIG_FILE}" --format json "$@"
}
