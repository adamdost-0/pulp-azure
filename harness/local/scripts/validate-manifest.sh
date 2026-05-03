#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

require_cmd python3

media_dir="${1:?Usage: validate-manifest.sh <media-dir>}"
python3 - "$media_dir" <<'PY'
import hashlib
import json
import pathlib
import sys

media = pathlib.Path(sys.argv[1])
manifest = json.loads((media / "manifest.json").read_text())
required = {"schemaVersion", "batchId", "sourceEnvironmentId", "generatedAt", "repositories", "compatibility"}
missing = required - set(manifest)
if missing:
    raise SystemExit(f"manifest missing fields: {sorted(missing)}")
for repo in manifest["repositories"]:
    for artifact in repo["artifacts"]:
        path = media / artifact["path"]
        if not path.exists():
            raise SystemExit(f"missing artifact: {artifact['path']}")
        blob = path.read_bytes()
        digest = hashlib.sha256(blob).hexdigest()
        if digest != artifact["sha256"]:
            raise SystemExit(f"checksum mismatch: {artifact['path']}")
print("manifest-ok")
PY
