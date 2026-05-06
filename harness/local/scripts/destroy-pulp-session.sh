#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: destroy-pulp-session.sh [--session-id ID] [--force]

Stops the disposable Pulp container, stops the local fixture server, and removes
the session workdir. Evidence under evidence/<session-id>/ is preserved.
EOF_USAGE
}

force=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id) PULP_SESSION_ID="$2"; shift 2 ;;
    --force) force=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

resolve_container_runtime
session_id="${PULP_SESSION_ID:-local-apt-smoke}"
safe_id "${session_id}"
PULP_SESSION_ID="${session_id}"
PULP_SESSION_ROOT="${PULP_SESSION_ROOT:-.runtime/pulp-sessions}"
PULP_SESSION_DIR="${REPO_ROOT}/${PULP_SESSION_ROOT}/${PULP_SESSION_ID}"

if [[ "${force}" -ne 1 ]]; then
  read -r -p "Destroy disposable session ${PULP_SESSION_ID}? [y/N] " answer
  [[ "${answer}" == "y" || "${answer}" == "Y" ]] || exit 0
fi

if [[ -f "${PULP_SESSION_DIR}/session.env" ]]; then
  source "${PULP_SESSION_DIR}/session.env"
else
  PULP_CONTAINER_NAME="${PULP_CONTAINER_NAME:-pulp-${PULP_SESSION_ID}}"
  PULP_CLEANUP_IMAGE="${PULP_CLEANUP_IMAGE:-busybox:1.36}"
fi

if [[ -f "${PULP_SESSION_DIR}/upstream-http.pid" ]]; then
  upstream_pid="$(cat "${PULP_SESSION_DIR}/upstream-http.pid")"
  if kill -0 "${upstream_pid}" >/dev/null 2>&1; then
    kill "${upstream_pid}" || true
  fi
fi

"${PULP_CONTAINER_RUNTIME}" rm -f "${PULP_CONTAINER_NAME}" >/dev/null 2>&1 || true

if [[ -d "${PULP_SESSION_DIR}" ]]; then
  if ! rm -rf "${PULP_SESSION_DIR}" 2>/dev/null; then
    log "host cleanup failed; retrying through a scoped cleanup container"
    cleanup_rel="${PULP_SESSION_ROOT}/${PULP_SESSION_ID}"
    "${PULP_CONTAINER_RUNTIME}" run --rm \
      --volume "${REPO_ROOT}:/workspace" \
      "${PULP_CLEANUP_IMAGE}" \
      sh -c "rm -rf '/workspace/${cleanup_rel}'"
  fi
fi

cat <<EOF_DONE
Disposable session removed: ${PULP_SESSION_ID}
Evidence was not removed: ${REPO_ROOT}/${PULP_EVIDENCE_ROOT:-evidence}/${PULP_SESSION_ID}
EOF_DONE