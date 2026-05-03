#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"
load_env

require_cmd podman
require_env APT_CLIENT_IMAGE
require_env PULP_IMAGE

echo "Host architecture: $(uname -m)"
podman run --rm --pull="${PULP_PULL_POLICY:-never}" --platform "${APT_CLIENT_PLATFORM}" "${APT_CLIENT_IMAGE}" \
  /bin/sh -lc 'test "$(uname -m)" = "x86_64"; test "$(dpkg --print-architecture)" = "amd64"; echo "amd64 apt client ok"'

podman run --rm --pull="${PULP_PULL_POLICY:-never}" --platform "${PULP_PLATFORM}" "${PULP_IMAGE}" \
  /bin/sh -lc 'test "$(uname -m)" = "x86_64"; python3 - <<PY
import importlib.metadata as md
print("pulpcore==" + md.version("pulpcore"))
print("pulp-deb==" + md.version("pulp-deb"))
PY'

tmp_dir="${HARNESS_WORKDIR}/tmp/validate-amd64"
rm -rf "${tmp_dir}"
mkdir -p "${tmp_dir}"
cleanup() {
  podman compose -f "${tmp_dir}/compose.yaml" down -v >/dev/null 2>&1 || true
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT
cat > "${tmp_dir}/compose.yaml" <<YAML
services:
  amd64-smoke:
    image: "${APT_CLIENT_IMAGE}"
    platform: "${APT_CLIENT_PLATFORM}"
    command: ["/bin/sh", "-lc", "test \$(uname -m) = x86_64 && test \$(dpkg --print-architecture) = amd64 && echo compose-amd64-ok"]
YAML
podman compose -f "${tmp_dir}/compose.yaml" run --rm amd64-smoke
