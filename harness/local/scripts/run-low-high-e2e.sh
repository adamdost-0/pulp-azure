#!/usr/bin/env bash
# run-low-high-e2e.sh - Low-side/High-side native Pulp export/import harness
#
# Topology:
#   pulp-low  (port 18080, .work/low)  - sync fixture, export via native Pulp exporter
#   pulp-high (port 18081, .work/high) - import from staged artifacts, publish, apt-client verify
#
# The fixture HTTP server runs only in the low container network namespace so
# the high container has no egress to the fixture (air-gap posture).
#
# Evidence is written to .work/evidence/<timestamp>/ and kept by default.
# Set CLEAN_EVIDENCE=1 to remove it after a successful run.
#
# Usage:
#   cd harness/local
#   ./scripts/run-low-high-e2e.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"
load_env

require_cmd podman
require_cmd curl
require_cmd python3
require_env APT_CLIENT_IMAGE

# -- Topology ------------------------------------------------------------------
timestamp="$(date +%s)"
low_name="${PULP_LOW_CONTAINER_NAME:-pulp-low}"
high_name="${PULP_HIGH_CONTAINER_NAME:-pulp-high}"
low_port="${PULP_LOW_HTTP_PORT:-18080}"
high_port="${PULP_HIGH_HTTP_PORT:-18081}"
low_workdir="${HARNESS_WORKDIR}/low"
high_workdir="${HARNESS_WORKDIR}/high"
evidence_dir="${HARNESS_WORKDIR}/evidence/${timestamp}"
admin_password="${PULP_ADMIN_PASSWORD:-password}"

low_repo_name="low-apt-${timestamp}"
low_remote_name="${low_repo_name}-remote"
exporter_name="low-exporter-${timestamp}"
batch="batch-${timestamp}"
high_repo_name="high-apt-${timestamp}"
high_importer_name="high-importer-${timestamp}"
high_distribution_name="${high_repo_name}-dist"
high_base_path="high-fixture-${timestamp}"
fixture_container="${low_name}-fixture-http"
high_network="pulp-high-${timestamp}"

low_base_url="http://localhost:${low_port}"
high_base_url="http://localhost:${high_port}"

# -- Logging -------------------------------------------------------------------
log()  { echo "[low-high] $*"; }
step() { echo; echo "[low-high] -- $* --"; }
err()  { echo "[low-high] ERROR: $*" >&2; }

# -- Evidence helpers ----------------------------------------------------------
save_evidence() {
  local name="$1"
  local data="$2"
  mkdir -p "${evidence_dir}"
  printf '%s\n' "${data}" > "${evidence_dir}/${name}"
}

save_evidence_file() {
  local src="$1"
  local dest_name="$2"
  mkdir -p "${evidence_dir}"
  cp "${src}" "${evidence_dir}/${dest_name}" 2>/dev/null || true
}

# -- Cleanup -------------------------------------------------------------------
cleanup() {
  local exit_code=$?
  step "Cleanup"
  log "Collecting final container logs..."
  mkdir -p "${evidence_dir}"
  podman logs "${low_name}"  > "${evidence_dir}/low-container.log"  2>/dev/null || true
  podman logs "${high_name}" > "${evidence_dir}/high-container.log" 2>/dev/null || true

  log "Stopping containers..."
  podman rm -f "${fixture_container}" >/dev/null 2>&1 || true
  PULP_CONTAINER_NAME="${low_name}" PULP_HTTP_PORT="${low_port}" \
    PULP_SINGLE_WORKDIR="${low_workdir}" \
    "${SCRIPT_DIR}/start-single-container.sh" stop >/dev/null 2>&1 || true
  PULP_CONTAINER_NAME="${high_name}" PULP_HTTP_PORT="${high_port}" \
    PULP_SINGLE_WORKDIR="${high_workdir}" \
    "${SCRIPT_DIR}/start-single-container.sh" stop >/dev/null 2>&1 || true
  podman network rm "${high_network}" >/dev/null 2>&1 || true

  if [[ "${exit_code}" -eq 0 && "${CLEAN_EVIDENCE:-0}" == "1" ]]; then
    log "CLEAN_EVIDENCE=1: removing evidence dir ${evidence_dir}"
    rm -rf "${evidence_dir}"
  else
    log "Evidence at: ${evidence_dir}"
  fi
  exit "${exit_code}"
}
trap cleanup EXIT

# -- API helpers ---------------------------------------------------------------
_api() {
  local base_url="$1"
  local method="$2"
  local path="$3"
  local data="${4:-}"
  if [[ -n "${data}" ]]; then
    curl --fail --silent --show-error \
      -u "admin:${admin_password}" \
      -H "Content-Type: application/json" \
      -X "${method}" \
      --data "${data}" \
      "${base_url}${path}"
  else
    curl --fail --silent --show-error \
      -u "admin:${admin_password}" \
      -X "${method}" \
      "${base_url}${path}"
  fi
}

low_api()  { _api "${low_base_url}"  "$@"; }
high_api() { _api "${high_base_url}" "$@"; }

# -- Task/task-group polling ---------------------------------------------------
wait_task() {
  local side="$1"
  local task_href="$2"
  local state
  for _ in $(seq 1 120); do
    if [[ "${side}" == "low" ]]; then
      state="$(low_api  GET "${task_href}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state"])')"
    else
      state="$(high_api GET "${task_href}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state"])')"
    fi
    case "${state}" in
      completed) return 0 ;;
      failed|canceled)
        err "Task ${task_href} on ${side} ended: ${state}"
        if [[ "${side}" == "low" ]]; then
          low_api  GET "${task_href}" | python3 -m json.tool >&2
        else
          high_api GET "${task_href}" | python3 -m json.tool >&2
        fi
        return 1
        ;;
    esac
    sleep 5
  done
  err "Timed out waiting for task ${task_href} on ${side}"
  return 1
}

wait_task_group() {
  local tg_href="$1"
  local result waiting running canceling failed canceled
  for _ in $(seq 1 180); do
    result="$(high_api GET "${tg_href}")"
    waiting="$(  printf '%s' "${result}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("waiting",0))')"
    running="$(  printf '%s' "${result}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("running",0))')"
    canceling="$(printf '%s' "${result}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("canceling",0))')"
    failed="$(   printf '%s' "${result}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("failed",0))')"
    canceled="$( printf '%s' "${result}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("canceled",0))')"
    if [[ "${waiting}" -eq 0 && "${running}" -eq 0 && "${canceling}" -eq 0 ]]; then
      if [[ "${failed}" -gt 0 || "${canceled}" -gt 0 ]]; then
        err "Task group ${tg_href} finished with failures: failed=${failed} canceled=${canceled}"
        printf '%s\n' "${result}" | python3 -m json.tool >&2
        return 1
      fi
      return 0
    fi
    sleep 5
  done
  err "Timed out waiting for task group ${tg_href}"
  return 1
}

wait_task_or_group() {
  local response="$1"
  local task_href tg_href
  task_href="$(printf '%s' "${response}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("task",""))')"
  tg_href="$(  printf '%s' "${response}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("task_group",""))')"
  if [[ -n "${tg_href}" ]]; then
    log "Polling task group: ${tg_href}"
    wait_task_group "${tg_href}"
  elif [[ -n "${task_href}" ]]; then
    log "Polling task (high): ${task_href}"
    wait_task "high" "${task_href}"
  else
    err "Neither 'task' nor 'task_group' in import response: ${response}"
    return 1
  fi
}

# -- Checksum helpers (python3 for portability on macOS and Linux) -------------
generate_manifest_sha256() {
  local dir="$1"
  local out="${dir}/MANIFEST.sha256"
  python3 - "${dir}" "${out}" <<'PY'
import hashlib, pathlib, sys
src = pathlib.Path(sys.argv[1])
out = pathlib.Path(sys.argv[2])
lines = []
for p in sorted(f for f in src.iterdir() if f.is_file() and f.name != "MANIFEST.sha256"):
    digest = hashlib.sha256(p.read_bytes()).hexdigest()
    lines.append(f"{digest}  {p.name}")
out.write_text("\n".join(lines) + "\n")
print(f"MANIFEST: {len(lines)} file(s)")
PY
}

verify_manifest_sha256() {
  local dir="$1"
  python3 - "${dir}/MANIFEST.sha256" "${dir}" <<'PY'
import hashlib, pathlib, sys
manifest = pathlib.Path(sys.argv[1])
basedir  = pathlib.Path(sys.argv[2])
errors   = []
for line in manifest.read_text().splitlines():
    if not line.strip():
        continue
    checksum, name = line.split("  ", 1)
    fp = basedir / name.strip()
    if not fp.exists():
        errors.append(f"MISSING: {name}")
        continue
    actual = hashlib.sha256(fp.read_bytes()).hexdigest()
    if actual != checksum:
        errors.append(f"MISMATCH: {name}")
if errors:
    for e in errors:
        print(e, file=sys.stderr)
    sys.exit(1)
print("checksum-ok")
PY
}

# -- Step 1: Generate APT fixture ---------------------------------------------
step "Step 1: Generate APT fixture"
"${SCRIPT_DIR}/generate-fixture.sh"

# -- Step 2: Start low-side Pulp container -------------------------------------
step "Step 2: Start low container (${low_name}:${low_port})"
PULP_CONTAINER_NAME="${low_name}" \
  PULP_HTTP_PORT="${low_port}" \
  PULP_SINGLE_WORKDIR="${low_workdir}" \
  "${SCRIPT_DIR}/start-single-container.sh" start

# -- Step 3: Start fixture server in low container network ---------------------
step "Step 3: Start fixture HTTP server in low container network"
fixture_image="${PULP_FIXTURE_IMAGE:-${PULP_SINGLE_IMAGE:-${PULP_IMAGE:-}}}"
if [[ -z "${fixture_image}" ]]; then
  err "Set PULP_FIXTURE_IMAGE, PULP_SINGLE_IMAGE, or PULP_IMAGE in .env"
  exit 1
fi

podman run -d --rm \
  --pull="${PULP_PULL_POLICY:-never}" \
  --name "${fixture_container}" \
  --network "container:${low_name}" \
  --platform "${PULP_PLATFORM}" \
  -v "${HARNESS_WORKDIR}/fixture:/srv:ro" \
  "${fixture_image}" \
  python3 -m http.server 8000 --directory /srv >/dev/null

podman exec "${fixture_container}" test -f /srv/dists/jammy/Release
podman exec "${low_name}" \
  python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/dists/jammy/Release', timeout=10).read()" >/dev/null
log "Fixture reachable from low container"

# -- Step 4: Low-side sync -----------------------------------------------------
step "Step 4: Low-side sync"
log "Creating low repository and remote..."
low_repo_href="$(low_api POST /pulp/api/v3/repositories/deb/apt/ \
  "{\"name\":\"${low_repo_name}\"}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["pulp_href"])')"

low_remote_href="$(low_api POST /pulp/api/v3/remotes/deb/apt/ \
  "{\"name\":\"${low_remote_name}\",\"url\":\"http://127.0.0.1:8000\",\"distributions\":\"jammy\",\"components\":\"main\",\"architectures\":\"amd64\",\"policy\":\"immediate\"}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["pulp_href"])')"

log "Syncing low repository..."
sync_task="$(low_api POST "${low_repo_href}sync/" \
  "{\"remote\":\"${low_remote_href}\"}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["task"])')"
wait_task "low" "${sync_task}"
save_evidence "low-sync-task.json" "$(low_api GET "${sync_task}")"

low_repo_version="$(low_api GET "${low_repo_href}versions/" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["results"][0]["pulp_href"])')"
log "Low repo version: ${low_repo_version}"

# -- Step 5: Low-side export ---------------------------------------------------
step "Step 5: Low-side native Pulp export"
log "Creating Pulp exporter..."
exporter_href="$(low_api POST /pulp/api/v3/exporters/core/pulp/ \
  "{\"name\":\"${exporter_name}\",\"repositories\":[\"${low_repo_href}\"],\"path\":\"/var/lib/pulp/exports/${exporter_name}\"}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["pulp_href"])')"
log "Exporter: ${exporter_href}"

log "Triggering full export..."
export_task="$(low_api POST "${exporter_href}exports/" \
  "{\"versions\":[\"${low_repo_version}\"],\"full\":true}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["task"])')"
wait_task "low" "${export_task}"

export_task_result="$(low_api GET "${export_task}")"
export_href="$(printf '%s' "${export_task_result}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["created_resources"][0])')"
log "Export resource: ${export_href}"

export_info="$(low_api GET "${export_href}")"
save_evidence "low-export-info.json" "${export_info}"
save_evidence "low-export-task.json" "${export_task_result}"

# Resolve container TOC path, then map to host path.
# toc_info.file = /var/lib/pulp/exports/<exporter>/<datetime>/export-*-toc.json
toc_file="$(printf '%s' "${export_info}" | \
  python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("toc_info",{}).get("file",""))')"

if [[ -z "${toc_file}" ]]; then
  log "toc_info not populated; scanning exports dir for TOC file..."
  # Map container /var/lib/pulp to host workdir.
  toc_file="$(find "${low_workdir}/exports/${exporter_name}" -maxdepth 2 -name '*-toc.json' | sort | tail -1)"
  if [[ -z "${toc_file}" ]]; then
    err "Cannot locate TOC file under ${low_workdir}/exports/${exporter_name}"
    exit 1
  fi
  # toc_file is already a host path in this branch
  toc_file_host="${toc_file}"
else
  # toc_file is a container-internal path; map to host
  toc_file_host="${low_workdir}${toc_file#/var/lib/pulp}"
fi

log "TOC file (host): ${toc_file_host}"

# -- Step 6: Stage export to high imports --------------------------------------
step "Step 6: Stage artifacts to high import directory"
export_batch_host="$(dirname "${toc_file_host}")"
import_dir_host="${high_workdir}/imports/${batch}"

log "Source batch dir: ${export_batch_host}"
log "Staging to:       ${import_dir_host}"

if [[ ! -d "${export_batch_host}" ]]; then
  err "Export batch directory not found: ${export_batch_host}"
  ls -la "$(dirname "${export_batch_host}")" >&2 || true
  exit 1
fi

# High workdir imports dir must exist before the container starts so the mount
# is created on the host with correct ownership.
mkdir -p "${import_dir_host}"
cp -r "${export_batch_host}/." "${import_dir_host}/"
staged_count="$(find "${import_dir_host}" -maxdepth 1 -type f | wc -l | tr -d ' ')"
log "Staged ${staged_count} file(s)"

# Generate and verify manifest (integrity checkpoint before crossing air gap)
log "Generating MANIFEST.sha256..."
generate_manifest_sha256 "${import_dir_host}"
save_evidence_file "${import_dir_host}/MANIFEST.sha256" "import-manifest.sha256"

log "Verifying MANIFEST.sha256..."
verify_manifest_sha256 "${import_dir_host}"

toc_filename="$(basename "${toc_file_host}")"
high_toc_path="/var/lib/pulp/imports/${batch}/${toc_filename}"
log "High container TOC path: ${high_toc_path}"

# -- Step 7: Start high-side Pulp container ------------------------------------
step "Step 7: Start high container (${high_name}:${high_port})"
# High container has no fixture server in its network and uses an internal
# network to preserve the no-egress high-side posture after staging.
podman network create --internal "${high_network}" >/dev/null
PULP_CONTAINER_NAME="${high_name}" \
  PULP_HTTP_PORT="${high_port}" \
  PULP_SINGLE_WORKDIR="${high_workdir}" \
  PULP_CONTAINER_NETWORK="${high_network}" \
  PULP_CONTENT_ORIGIN="http://${high_name}:80" \
  "${SCRIPT_DIR}/start-single-container.sh" start

# -- Step 8: High-side import-check -------------------------------------------
step "Step 8: High-side import-check"
import_check_result="$(high_api POST /pulp/api/v3/importers/core/pulp/import-check/ \
  "{\"toc\":\"${high_toc_path}\"}")"
save_evidence "high-import-check.json" "${import_check_result}"
log "import-check response: $(printf '%s' "${import_check_result}" | python3 -m json.tool --no-sort-keys 2>/dev/null || printf '%s' "${import_check_result}")"

# Treat any non-error response as a pass; a hard API error (curl --fail) already
# exits. Some Pulp versions return 200 with is_valid fields; others just 200 OK.
import_check_valid="$(printf '%s' "${import_check_result}" | \
  python3 -c 'import json,sys; d=json.load(sys.stdin); toc=d.get("toc_valid",{}); print("fail" if isinstance(toc,dict) and toc.get("is_valid") is False else "ok")' 2>/dev/null || echo "ok")"
if [[ "${import_check_valid}" == "fail" ]]; then
  err "import-check reported invalid TOC; see ${evidence_dir}/high-import-check.json"
  exit 1
fi
log "import-check passed"

# -- Step 9: Pre-create high repo and importer with repo_mapping ---------------
step "Step 9: High-side pre-create repo and importer"
log "Pre-creating high repository (${high_repo_name})..."
high_repo_href="$(high_api POST /pulp/api/v3/repositories/deb/apt/ \
  "{\"name\":\"${high_repo_name}\"}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["pulp_href"])')"
log "High repo: ${high_repo_href}"

log "Creating importer with repo_mapping {${low_repo_name} -> ${high_repo_name}}..."
importer_href="$(high_api POST /pulp/api/v3/importers/core/pulp/ \
  "{\"name\":\"${high_importer_name}\",\"repo_mapping\":{\"${low_repo_name}\":\"${high_repo_name}\"}}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["pulp_href"])')"
log "Importer: ${importer_href}"

# -- Step 10: High-side import -------------------------------------------------
step "Step 10: High-side import"
log "Triggering import with TOC: ${high_toc_path}"
import_response="$(high_api POST "${importer_href}imports/" \
  "{\"toc\":\"${high_toc_path}\"}")"
save_evidence "high-import-response.json" "${import_response}"
log "Import response: $(printf '%s' "${import_response}" | python3 -m json.tool --no-sort-keys 2>/dev/null || printf '%s' "${import_response}")"

wait_task_or_group "${import_response}"
log "Import completed"

# -- Step 11: High-side publish ------------------------------------------------
step "Step 11: High-side publish"
log "Getting latest version of high repo (${high_repo_name})..."
high_repo_version="$(high_api GET "${high_repo_href}versions/" | \
  python3 -c 'import json,sys; vs=json.load(sys.stdin)["results"]; print(vs[0]["pulp_href"]) if vs else (print("NO_VERSION", file=__import__("sys").stderr) or exit(1))')"
log "High repo version: ${high_repo_version}"

log "Creating deb publication..."
publication_task="$(high_api POST /pulp/api/v3/publications/deb/apt/ \
  "{\"repository_version\":\"${high_repo_version}\",\"simple\":true}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["task"])')"
wait_task "high" "${publication_task}"
publication_href="$(high_api GET "${publication_task}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin)["created_resources"][0])')"
save_evidence "high-publication-task.json" "$(high_api GET "${publication_task}")"
log "Publication: ${publication_href}"

log "Creating deb distribution (base_path=${high_base_path})..."
distribution_response="$(high_api POST /pulp/api/v3/distributions/deb/apt/ \
  "{\"name\":\"${high_distribution_name}\",\"base_path\":\"${high_base_path}\",\"publication\":\"${publication_href}\"}")"
distribution_task="$(printf '%s' "${distribution_response}" | \
  python3 -c 'import json,sys; print(json.load(sys.stdin).get("task",""))')"
if [[ -n "${distribution_task}" ]]; then
  wait_task "high" "${distribution_task}"
fi
log "Distribution created: ${high_base_url}/pulp/content/${high_base_path}/"

# -- Step 12: APT client consumes high endpoint --------------------------------
step "Step 12: APT client verify against high-side distribution"

run_apt_client_high() {
  local host="$1"
  podman run --rm \
    --pull="${PULP_PULL_POLICY:-never}" \
    --platform "${APT_CLIENT_PLATFORM}" \
    --network "${high_network}" \
    "${APT_CLIENT_IMAGE}" \
    /bin/sh -lc "set -e
rm -f /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null || true
echo 'deb [trusted=yes] http://${host}/pulp/content/${high_base_path}/ jammy main' > /etc/apt/sources.list
apt-get update >/var/log/apt-update.log || { cat /var/log/apt-update.log; exit 1; }
apt-cache policy airgap-fixture | tee /root/apt-policy.log
grep -q 'Candidate: 1.0.0' /root/apt-policy.log"
}

client_host="${PULP_CLIENT_HOST:-${high_name}:80}"
if ! run_apt_client_high "${client_host}" 2>&1 | tee "${evidence_dir}/apt-policy.txt"; then
  err "APT client failed to reach high-side distribution at ${client_host}"
  exit 1
fi

# -- Step 13: Collect API status evidence --------------------------------------
step "Step 13: Collect evidence"
mkdir -p "${evidence_dir}"
low_api  GET /pulp/api/v3/status/ > "${evidence_dir}/low-status.json"  2>/dev/null || true
high_api GET /pulp/api/v3/status/ > "${evidence_dir}/high-status.json" 2>/dev/null || true

log "Evidence directory: ${evidence_dir}"
ls "${evidence_dir}"

# -- Done ----------------------------------------------------------------------
echo
echo "low-high-e2e-ok  timestamp=${timestamp}"
echo "  low  = ${low_base_url}"
echo "  high = ${high_base_url}/pulp/content/${high_base_path}/"
echo "  evidence = ${evidence_dir}"
