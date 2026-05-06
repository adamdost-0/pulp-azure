#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: run-pulp-solution.sh [--session-id ID] [--solution FILE]

Runs a declarative local Pulp solution against an already prepared disposable
session. The v1 solution syncs a generated apt repository through pulp-cli.
EOF_USAGE
}

solution_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id) PULP_SESSION_ID="$2"; shift 2 ;;
    --solution) solution_file="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

require_cmd python3
resolve_container_runtime
load_session_env "${PULP_SESSION_ID:-local-apt-smoke}"
solution_file="${solution_file:-${REPO_ROOT}/${PULP_SOLUTION_FILE}}"
[[ -f "${solution_file}" ]] || die "solution file not found: ${solution_file}"

eval "$(python3 - "${solution_file}" <<'PY'
import json
import shlex
import sys
from pathlib import Path

solution = json.loads(Path(sys.argv[1]).read_text())
fields = {
    "SOLUTION_NAME": solution["name"],
    "SOLUTION_DESCRIPTION": solution.get("description", ""),
    "PULP_REPOSITORY_NAME": solution["pulp"]["repositoryName"],
    "PULP_REMOTE_NAME": solution["pulp"]["remoteName"],
    "PULP_PUBLICATION_NAME": solution["pulp"]["publicationName"],
    "PULP_DISTRIBUTION_NAME": solution["pulp"]["distributionName"],
    "PULP_REQUIRED_PLUGINS": " ".join(solution["pulp"]["requiredPlugins"]),
    "FIXTURE_PACKAGE": solution["fixture"]["package"],
    "FIXTURE_VERSION": solution["fixture"]["version"],
    "FIXTURE_ARCHITECTURE": solution["fixture"]["architecture"],
    "FIXTURE_SUMMARY": solution["fixture"]["summary"],
    "APT_DISTRIBUTION": solution["apt"]["distribution"],
    "APT_COMPONENT": solution["apt"]["component"],
    "APT_BASE_PATH": solution["apt"]["basePath"],
    "APT_TRUSTED": str(solution["apt"]["trusted"]).lower(),
    "EVIDENCE_ROOT": solution["evidence"]["directory"],
}
for key, value in fields.items():
    print(f"{key}={shlex.quote(value)}")
PY
)"

workflow_dir="${PULP_SESSION_DIR}/workflow"
upstream_root="${PULP_SESSION_DIR}/upstream-repo"
evidence_dir="${REPO_ROOT}/${EVIDENCE_ROOT}/${PULP_SESSION_ID}"
mkdir -p "${workflow_dir}" "${upstream_root}" "${evidence_dir}"

log "generating deterministic apt fixture repository"
"${SCRIPT_DIR}/generate-deb-fixture.py" \
  --repo-root "${upstream_root}" \
  --package "${FIXTURE_PACKAGE}" \
  --version "${FIXTURE_VERSION}" \
  --architecture "${FIXTURE_ARCHITECTURE}" \
  --distribution "${APT_DISTRIBUTION}" \
  --component "${APT_COMPONENT}" \
  --summary "${FIXTURE_SUMMARY}" \
  --metadata "${workflow_dir}/fixture-metadata.json" \
  > "${workflow_dir}/fixture-generation.json"

if [[ -f "${PULP_SESSION_DIR}/upstream-http.pid" ]]; then
  old_pid="$(cat "${PULP_SESSION_DIR}/upstream-http.pid")"
  if kill -0 "${old_pid}" >/dev/null 2>&1; then
    kill "${old_pid}" || true
  fi
fi

log "starting local apt fixture HTTP server on port ${PULP_UPSTREAM_PORT}"
python3 -m http.server "${PULP_UPSTREAM_PORT}" --bind 0.0.0.0 --directory "${upstream_root}" \
  > "${PULP_SESSION_DIR}/logs/upstream-http.log" 2>&1 &
echo "$!" > "${PULP_SESSION_DIR}/upstream-http.pid"
sleep 2

remote_url="http://${PULP_UPSTREAM_HOST_ALIAS}:${PULP_UPSTREAM_PORT}/"
log "configuring Pulp deb remote ${PULP_REMOTE_NAME} -> ${remote_url}"
pulp_cmd deb remote create \
  --name "${PULP_REMOTE_NAME}" \
  --url "${remote_url}" \
  --distribution "${APT_DISTRIBUTION}" \
  --component "${APT_COMPONENT}" \
  --architecture "${FIXTURE_ARCHITECTURE}" \
  --policy immediate \
  > "${workflow_dir}/deb-remote.json"

log "creating Pulp deb repository ${PULP_REPOSITORY_NAME}"
pulp_cmd deb repository create \
  --name "${PULP_REPOSITORY_NAME}" \
  --remote "${PULP_REMOTE_NAME}" \
  --retain-repo-versions 3 \
  > "${workflow_dir}/deb-repository.json"

log "syncing repository through pulp-cli"
pulp_cmd deb repository sync \
  --name "${PULP_REPOSITORY_NAME}" \
  --remote "${PULP_REMOTE_NAME}" \
  --mirror \
  --no-optimize \
  > "${workflow_dir}/deb-sync.json"

log "publishing immutable repository version"
pulp_cmd deb publication create \
  --repository "${PULP_REPOSITORY_NAME}" \
  --structured \
  > "${workflow_dir}/deb-publication.json"

publication_href="$(python3 - "${workflow_dir}/deb-publication.json" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
href = data.get("pulp_href")
if not href:
    resources = data.get("created_resources") or data.get("pulp_created_resources") or []
    if resources:
        href = resources[0]
if not href:
    raise SystemExit("publication href not found in deb-publication.json")
print(href)
PY
)"

log "creating apt distribution at ${APT_BASE_PATH}"
pulp_cmd deb distribution create \
  --name "${PULP_DISTRIBUTION_NAME}" \
  --base-path "${APT_BASE_PATH}" \
  --publication "${publication_href}" \
  > "${workflow_dir}/deb-distribution.json"

apt_source_url="http://${PULP_CLIENT_HOST_ALIAS}:${PULP_HTTP_HOST_PORT}/pulp/content/${APT_BASE_PATH}"
cat > "${workflow_dir}/apt-source.env" <<EOF_APT
SOLUTION_NAME='${SOLUTION_NAME}'
SOLUTION_DESCRIPTION='${SOLUTION_DESCRIPTION}'
FIXTURE_PACKAGE='${FIXTURE_PACKAGE}'
FIXTURE_VERSION='${FIXTURE_VERSION}'
FIXTURE_ARCHITECTURE='${FIXTURE_ARCHITECTURE}'
APT_DISTRIBUTION='${APT_DISTRIBUTION}'
APT_COMPONENT='${APT_COMPONENT}'
APT_BASE_PATH='${APT_BASE_PATH}'
APT_TRUSTED='${APT_TRUSTED}'
APT_SOURCE_URL='${apt_source_url}'
PUBLICATION_HREF='${publication_href}'
EVIDENCE_DIR='${evidence_dir}'
EOF_APT

cat <<EOF_DONE
Pulp solution configured.
Session: ${PULP_SESSION_ID}
Repository: ${PULP_REPOSITORY_NAME}
Distribution: ${PULP_CONTENT_ORIGIN}/pulp/content/${APT_BASE_PATH}
Next: harness/local/scripts/validate-apt-client.sh --session-id ${PULP_SESSION_ID}
EOF_DONE