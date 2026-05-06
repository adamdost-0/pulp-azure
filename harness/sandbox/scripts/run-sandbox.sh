#!/usr/bin/env bash
set -euo pipefail

SANDBOX_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_DIR="$(cd "${SANDBOX_SCRIPT_DIR}/.." && pwd)"

# shellcheck source=harness/local/scripts/common.sh
source "${SANDBOX_DIR}/../local/scripts/common.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: run-sandbox.sh [--rebuild] [--image IMAGE] [-- COMMAND...]

Builds when needed and runs the repo-contained Pulp CLI tooling sandbox. The
workspace is mounted read/write at /workspace. Sandbox home/cache state is
mounted from PULP_STORAGE_ROOT/sandbox-home so command execution does not write
to the container layer or host-local .runtime.
EOF_USAGE
}

rebuild=0
sandbox_image="${PULP_SANDBOX_IMAGE:-pulp-azure/pulp-cli-sandbox:local}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild) rebuild=1; shift ;;
    --image) sandbox_image="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    *) break ;;
  esac
done

command_args=("$@")
if [[ "${#command_args[@]}" -eq 0 ]]; then
  command_args=(bash)
fi

resolve_container_runtime
PULP_STORAGE_ROOT="${PULP_STORAGE_ROOT:-${DEFAULT_PULP_STORAGE_ROOT}}"
PULP_STORAGE_ROOT="$(resolve_repo_path "${PULP_STORAGE_ROOT}")"
PULP_SANDBOX_HOME="${PULP_SANDBOX_HOME:-${PULP_STORAGE_ROOT}/sandbox-home}"
mkdir -p "${PULP_SANDBOX_HOME}"

if [[ "${rebuild}" -eq 1 ]] || ! runtime_image_exists "${sandbox_image}"; then
  log "building sandbox image ${sandbox_image}"
  "${PULP_CONTAINER_RUNTIME}" build \
    --tag "${sandbox_image}" \
    --file "${SANDBOX_DIR}/Dockerfile" \
    "${SANDBOX_DIR}"
fi

volume_suffix="$(runtime_volume_suffix)"
run_args=(run --rm --workdir /workspace)
if [[ -t 0 && -t 1 ]]; then
  run_args+=(--interactive --tty)
fi
while IFS= read -r arg; do
  [[ -n "${arg}" ]] && run_args+=("${arg}")
done < <(runtime_add_host_args)
run_args+=(
  --user "$(id -u):$(id -g)"
  --env HOME=/sandbox-home
  --env PULP_STORAGE_ROOT=/sandbox-home/pulp-azure
  --env PULP_SESSION_ROOT=/sandbox-home/pulp-azure/pulp-sessions
  --volume "${REPO_ROOT}:/workspace${volume_suffix}"
  --volume "${PULP_SANDBOX_HOME}:/sandbox-home${volume_suffix}"
  "${sandbox_image}"
  "${command_args[@]}"
)

"${PULP_CONTAINER_RUNTIME}" "${run_args[@]}"
