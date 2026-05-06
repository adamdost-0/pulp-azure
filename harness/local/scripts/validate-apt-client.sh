#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: validate-apt-client.sh [--session-id ID]

Validates the published Pulp distribution with apt-get inside an isolated
client container. The host apt configuration is never modified.
EOF_USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id) PULP_SESSION_ID="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

resolve_container_runtime
load_session_env "${PULP_SESSION_ID:-local-apt-smoke}"
source "${PULP_SESSION_DIR}/workflow/apt-source.env"
mkdir -p "${EVIDENCE_DIR}"

trusted_option=""
if [[ "${APT_TRUSTED}" == "true" ]]; then
  trusted_option="[trusted=yes] "
fi
sources_line="deb ${trusted_option}${APT_SOURCE_URL} ${APT_DISTRIBUTION} ${APT_COMPONENT}"
printf '%s\n' "${sources_line}" > "${PULP_SESSION_DIR}/workflow/pulp-local.sources.list"

client_args=(run --rm "$(runtime_pull_arg "${PULP_APT_CLIENT_PULL_POLICY}")")
while IFS= read -r arg; do
  [[ -n "${arg}" ]] && client_args+=("${arg}")
done < <(runtime_add_host_args)
client_args+=("${PULP_APT_CLIENT_IMAGE}" bash -lc "
set -euo pipefail
printf '%s\n' '${sources_line}' > /etc/apt/sources.list.d/pulp-local.list
rm -f /etc/apt/sources.list
apt-get update
apt-get install -y --no-install-recommends '${FIXTURE_PACKAGE}'
test -f '/usr/share/${FIXTURE_PACKAGE}/message.txt'
cat '/usr/share/${FIXTURE_PACKAGE}/message.txt'
")

log "validating apt-get client consumption in ${PULP_APT_CLIENT_IMAGE}"
"${PULP_CONTAINER_RUNTIME}" "${client_args[@]}" 2>&1 | tee "${EVIDENCE_DIR}/apt-client.log"

python3 - "${EVIDENCE_DIR}/apt-client.log" "${FIXTURE_PACKAGE}" <<'PY'
import sys
from pathlib import Path

log_path = Path(sys.argv[1])
package = sys.argv[2]
content = log_path.read_text(errors="replace")
if f"Setting up {package}" not in content and f"{package} " not in content:
    raise SystemExit(f"apt evidence does not show package installation: {package}")
print(f"apt evidence includes package installation: {package}")
PY

cat <<EOF_DONE
apt-get validation completed.
Evidence log: ${EVIDENCE_DIR}/apt-client.log
Next: harness/local/scripts/capture-evidence.sh --session-id ${PULP_SESSION_ID}
EOF_DONE