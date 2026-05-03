#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"
load_env

require_cmd podman
require_env APT_CLIENT_IMAGE

network="pulp-high-no-egress"
created_network=false
if ! podman network exists "${network}" >/dev/null 2>&1; then
  podman network create --internal "${network}" >/dev/null
  created_network=true
fi
cleanup() {
  if [[ "${created_network}" == "true" ]]; then
    podman network rm "${network}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if podman run --rm --pull="${PULP_PULL_POLICY:-never}" --platform "${APT_CLIENT_PLATFORM}" --network "${network}" "${APT_CLIENT_IMAGE}" \
  /bin/sh -lc 'getent hosts example.com >/dev/null 2>&1 || ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1'; then
  echo "No-egress validation failed: external network access succeeded" >&2
  exit 1
fi

echo "no-egress-ok"
