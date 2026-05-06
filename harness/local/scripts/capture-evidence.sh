#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: capture-evidence.sh [--session-id ID]

Writes a Playwright-backed evidence package under evidence/<session-id>/.
EOF_USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id) PULP_SESSION_ID="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

load_session_env "${PULP_SESSION_ID:-local-apt-smoke}"
source "${PULP_SESSION_DIR}/workflow/apt-source.env"
mkdir -p "${EVIDENCE_DIR}"

release_url="${PULP_CONTENT_ORIGIN}/pulp/content/${APT_BASE_PATH}/dists/${APT_DISTRIBUTION}/Release"
screenshot_path="${EVIDENCE_DIR}/pulp-release-page.png"
playwright_log="${EVIDENCE_DIR}/playwright-screenshot.log"

if command -v playwright >/dev/null 2>&1; then
  playwright screenshot "${release_url}" "${screenshot_path}" > "${playwright_log}" 2>&1
elif command -v npx >/dev/null 2>&1; then
  npx --yes playwright screenshot "${release_url}" "${screenshot_path}" > "${playwright_log}" 2>&1
else
  die "Playwright CLI is required for evidence capture; install playwright or provide npx"
fi

cp "${PULP_SESSION_DIR}/workflow/status.json" "${EVIDENCE_DIR}/pulp-status.json"
cp "${PULP_SESSION_DIR}/workflow/fixture-metadata.json" "${EVIDENCE_DIR}/fixture-metadata.json"
cp "${PULP_SESSION_DIR}/workflow/deb-sync.json" "${EVIDENCE_DIR}/deb-sync.json"
cp "${PULP_SESSION_DIR}/workflow/deb-publication.json" "${EVIDENCE_DIR}/deb-publication.json"
cp "${PULP_SESSION_DIR}/workflow/deb-distribution.json" "${EVIDENCE_DIR}/deb-distribution.json"
cp "${PULP_SESSION_DIR}/workflow/pulp-local.sources.list" "${EVIDENCE_DIR}/pulp-local.sources.list"

cat > "${EVIDENCE_DIR}/description.md" <<EOF_DESC
# Evidence: Disposable Pulp Apt Session

This evidence package shows a disposable local Pulp session configured through
Pulp CLI and validated with apt-get from an isolated client container.

## Session

- Session ID: ${PULP_SESSION_ID}
- Pulp endpoint: ${PULP_CONTENT_ORIGIN}
- Published apt base path: ${APT_BASE_PATH}
- Fixture package: ${FIXTURE_PACKAGE} ${FIXTURE_VERSION} (${FIXTURE_ARCHITECTURE})

## Proof Points

- `pulp-status.json` records Pulp readiness and plugin versions.
- `fixture-metadata.json` records the deterministic package metadata and SHA-256.
- `deb-sync.json`, `deb-publication.json`, and `deb-distribution.json` record Pulp CLI workflow outputs.
- `apt-client.log` records apt-get update and install output from the isolated client.
- `pulp-release-page.png` is a Playwright CLI screenshot of the published apt Release endpoint.
EOF_DESC

python3 - "${EVIDENCE_DIR}" "${PULP_SESSION_ID}" "${release_url}" <<'PY'
import json
import sys
from pathlib import Path

evidence = Path(sys.argv[1])
session_id = sys.argv[2]
release_url = sys.argv[3]
artifacts = []
for path in sorted(evidence.iterdir()):
    if path.name == "index.json":
        continue
    artifacts.append({"path": path.name, "size": path.stat().st_size})
index = {
    "sessionId": session_id,
    "description": "Disposable local Pulp apt validation using Pulp CLI, apt-get, and Playwright CLI evidence.",
    "releaseUrl": release_url,
    "artifacts": artifacts,
}
(evidence / "index.json").write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
PY

cat <<EOF_DONE
Evidence captured.
Description: ${EVIDENCE_DIR}/description.md
Index: ${EVIDENCE_DIR}/index.json
Screenshot: ${screenshot_path}
EOF_DONE