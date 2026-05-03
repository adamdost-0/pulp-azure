#!/usr/bin/env bash
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export HARNESS_DIR
export HARNESS_WORKDIR="${HARNESS_WORKDIR:-${HARNESS_DIR}/.work}"
export PULP_PLATFORM="${PULP_PLATFORM:-${LOCAL_PLATFORM:-linux/amd64}}"
export SUPPORT_PLATFORM="${SUPPORT_PLATFORM:-linux/arm64}"
export APT_CLIENT_PLATFORM="${APT_CLIENT_PLATFORM:-${LOCAL_PLATFORM:-linux/amd64}}"
export PULP_HTTP_PORT="${PULP_HTTP_PORT:-18080}"
export PULP_CONTAINER_RUNTIME="${PULP_CONTAINER_RUNTIME:-podman}"
export PULP_CONTAINER_NAME="${PULP_CONTAINER_NAME:-pulp}"
export PULP_SINGLE_WORKDIR="${PULP_SINGLE_WORKDIR:-${HARNESS_WORKDIR}/single-container}"
export PULP_ADMIN_PASSWORD="${PULP_ADMIN_PASSWORD:-password}"
export PULP_PULL_POLICY="${PULP_PULL_POLICY:-never}"

load_env() {
  if [[ -f "${HARNESS_DIR}/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    . "${HARNESS_DIR}/.env"
    set +a
  fi
  export HARNESS_WORKDIR PULP_PLATFORM SUPPORT_PLATFORM APT_CLIENT_PLATFORM
  export PULP_HTTP_PORT PULP_CONTAINER_RUNTIME PULP_CONTAINER_NAME PULP_SINGLE_WORKDIR PULP_ADMIN_PASSWORD PULP_PULL_POLICY
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Required command not found: $1" >&2
    exit 1
  }
}

resolve_pulp_single_image() {
  local image="${PULP_SINGLE_IMAGE:-${PULP_IMAGE:-}}"
  if [[ -z "${image}" ]]; then
    echo "Required environment variable is not set: PULP_SINGLE_IMAGE or PULP_IMAGE" >&2
    echo "Copy ${HARNESS_DIR}/env.example to ${HARNESS_DIR}/.env and set an internal/private Pulp OCI image reference." >&2
    exit 1
  fi
  printf '%s\n' "${image}"
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Required environment variable is not set: ${name}" >&2
    echo "Copy ${HARNESS_DIR}/env.example to ${HARNESS_DIR}/.env and set image references." >&2
    exit 1
  fi
}
