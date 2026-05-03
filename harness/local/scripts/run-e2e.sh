#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"
load_env

require_cmd podman
require_cmd curl
require_cmd python3
require_env APT_CLIENT_IMAGE

project="${PROJECT:-pulp-e2e}"
port="${PULP_HTTP_PORT:-18080}"
base_url="http://localhost:${port}"
network="${project}_default"
fixture_name="${project}-fixture-http"
mode="${PULP_E2E_MODE:-single}"
timestamp="$(date +%s)"
repo_name="ubuntu-jammy-fixture-${timestamp}"
remote_name="${repo_name}-remote"
distribution_name="${repo_name}-distribution"
base_path="ubuntu-fixture-${timestamp}"
admin_password="${PULP_ADMIN_PASSWORD:-password}"
pulp_container="${PULP_E2E_CONTAINER_NAME:-${project}-pulp}"
fixture_image="${PULP_FIXTURE_IMAGE:-${PULP_SINGLE_IMAGE:-${PULP_IMAGE:-}}}"
client_host="${PULP_CLIENT_HOST:-pulp.local}"

if [[ -z "${fixture_image}" ]]; then
  echo "Required environment variable is not set: PULP_FIXTURE_IMAGE, PULP_SINGLE_IMAGE, or PULP_IMAGE" >&2
  exit 1
fi

cleanup() {
  podman rm -f "${fixture_name}" >/dev/null 2>&1 || true
  case "${mode}" in
    single)
      PULP_CONTAINER_NAME="${pulp_container}" "${SCRIPT_DIR}/start-single-container.sh" stop >/dev/null 2>&1 || true
      ;;
    compose)
      podman compose --project-name "${project}" -f "${HARNESS_DIR}/compose.pulp.yaml" down -v >/dev/null 2>&1 || true
      ;;
  esac
}
trap cleanup EXIT

"${SCRIPT_DIR}/generate-fixture.sh"

cleanup
case "${mode}" in
  single)
    export PULP_CONTAINER_NAME="${pulp_container}"
    export PULP_SINGLE_WORKDIR="${PULP_SINGLE_WORKDIR:-${HARNESS_WORKDIR}/single-container-e2e}"
    "${SCRIPT_DIR}/start-single-container.sh" start
    fixture_network_args=(--network "container:${pulp_container}")
    fixture_url="http://127.0.0.1:8000"
    api_probe_container="${pulp_container}"
    ;;
  compose)
    require_env PULP_IMAGE
    require_env PULP_WEB_IMAGE
    require_env POSTGRES_IMAGE
    require_env REDIS_IMAGE
    "${SCRIPT_DIR}/init-assets.sh"
    podman compose --project-name "${project}" -f "${HARNESS_DIR}/compose.pulp.yaml" up -d
    fixture_network_args=(--network "${network}")
    fixture_url="http://${fixture_name}:8000"
    api_probe_container="${project}-pulp_api-1"
    ;;
  *)
    echo "Unsupported PULP_E2E_MODE=${mode}; expected single or compose" >&2
    exit 2
    ;;
esac

echo "Waiting for Pulp API at ${base_url}/pulp/api/v3/status/"
for _ in $(seq 1 120); do
  if curl --fail --silent "${base_url}/pulp/api/v3/status/" >/dev/null; then
    break
  fi
  sleep 5
done
curl --fail --silent "${base_url}/pulp/api/v3/status/" >/dev/null

podman run -d --rm \
  --pull="${PULP_PULL_POLICY:-never}" \
  --name "${fixture_name}" \
  "${fixture_network_args[@]}" \
  --platform "${PULP_PLATFORM}" \
  -v "${HARNESS_WORKDIR}/fixture:/srv:ro" \
  "${fixture_image}" \
  python3 -m http.server 8000 --directory /srv >/dev/null

podman exec "${fixture_name}" test -f /srv/dists/jammy/Release
podman exec "${api_probe_container}" \
  python3 -c "import urllib.request; urllib.request.urlopen('${fixture_url}/dists/jammy/Release', timeout=10).read()" >/dev/null

api() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  if [[ -n "${data}" ]]; then
    curl --fail --silent --show-error -u "admin:${admin_password}" \
      -H "Content-Type: application/json" \
      -X "${method}" \
      --data "${data}" \
      "${base_url}${path}"
  else
    curl --fail --silent --show-error -u "admin:${admin_password}" -X "${method}" "${base_url}${path}"
  fi
}

wait_task() {
  local task_href="$1"
  local state
  for _ in $(seq 1 120); do
    state="$(api GET "${task_href}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["state"])')"
    case "${state}" in
      completed) return 0 ;;
      failed|canceled)
        api GET "${task_href}" | python3 -m json.tool
        return 1
        ;;
    esac
    sleep 5
  done
  echo "Timed out waiting for task ${task_href}" >&2
  return 1
}

repo_href="$(api POST /pulp/api/v3/repositories/deb/apt/ "{\"name\":\"${repo_name}\"}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["pulp_href"])')"
remote_href="$(api POST /pulp/api/v3/remotes/deb/apt/ "{\"name\":\"${remote_name}\",\"url\":\"${fixture_url}\",\"distributions\":\"jammy\",\"components\":\"main\",\"architectures\":\"amd64\",\"policy\":\"immediate\"}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["pulp_href"])')"
sync_task="$(api POST "${repo_href}sync/" "{\"remote\":\"${remote_href}\"}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["task"])')"
wait_task "${sync_task}"

repo_version="$(api GET "${repo_href}versions/" | python3 -c 'import json,sys; print(json.load(sys.stdin)["results"][0]["pulp_href"])')"
publication_task="$(api POST /pulp/api/v3/publications/deb/apt/ "{\"repository_version\":\"${repo_version}\",\"simple\":true}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["task"])')"
wait_task "${publication_task}"
publication_href="$(api GET "${publication_task}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["created_resources"][0])')"
distribution_task="$(api POST /pulp/api/v3/distributions/deb/apt/ "{\"name\":\"${distribution_name}\",\"base_path\":\"${base_path}\",\"publication\":\"${publication_href}\"}" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("task", ""))')"
if [[ -n "${distribution_task}" ]]; then
  wait_task "${distribution_task}"
fi

run_apt_client() {
  local host="$1"
  local add_host="${2:-}"
  local -a add_host_args=()
  if [[ -n "${add_host}" ]]; then
    add_host_args=(--add-host "${host}:${add_host}")
  fi

  podman run --rm \
    --pull="${PULP_PULL_POLICY:-never}" \
    --platform "${APT_CLIENT_PLATFORM}" \
    "${add_host_args[@]}" \
    "${APT_CLIENT_IMAGE}" \
    /bin/sh -lc "set -e; rm -f /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null || true; echo 'deb [trusted=yes] http://${host}:${port}/pulp/content/${base_path}/ jammy main' > /etc/apt/sources.list; apt-get update >/var/log/apt-update.log || { cat /var/log/apt-update.log; exit 1; }; apt-cache policy airgap-fixture | tee /root/apt-policy.log; grep -q 'Candidate: 1.0.0' /root/apt-policy.log"
}

if ! run_apt_client "${client_host}" "${PULP_CLIENT_HOST_GATEWAY:-host-gateway}"; then
  echo "APT client could not reach ${client_host} via host-gateway; retrying container runtime host aliases" >&2
  run_apt_client "host.containers.internal" || run_apt_client "host.docker.internal"
fi

echo "e2e-ok ${repo_name} ${base_url}/pulp/content/${base_path}/"
