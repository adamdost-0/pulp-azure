#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

require_cmd python3

batch_id="${1:?Usage: generate-manifest.sh <batch-id> <payload-dir> <media-dir>}"
payload_dir="${2:?Usage: generate-manifest.sh <batch-id> <payload-dir> <media-dir>}"
media_dir="${3:?Usage: generate-manifest.sh <batch-id> <payload-dir> <media-dir>}"

mkdir -p "${media_dir}"
python3 - "$batch_id" "$payload_dir" "$media_dir" <<'PY'
import hashlib
import json
import os
import pathlib
import shutil
import sys
from datetime import datetime, timezone

batch_id, payload_dir, media_dir = sys.argv[1:4]
payload = pathlib.Path(payload_dir)
media = pathlib.Path(media_dir)
if not payload.exists():
    raise SystemExit(f"payload directory does not exist: {payload}")

target = media / "payload"
if target.exists():
    shutil.rmtree(target)
shutil.copytree(payload, target)

artifacts = []
for path in sorted(p for p in target.rglob("*") if p.is_file()):
    blob = path.read_bytes()
    artifacts.append({
        "path": path.relative_to(media).as_posix(),
        "size": len(blob),
        "sha256": hashlib.sha256(blob).hexdigest(),
    })

manifest = {
    "schemaVersion": "0.1.0",
    "batchId": batch_id,
    "sourceEnvironmentId": "local-low",
    "generatedAt": datetime.now(timezone.utc).isoformat(),
    "repositories": [{
        "name": "ubuntu-jammy-main-amd64-fixture",
        "distribution": "ubuntu",
        "release": "jammy",
        "architecture": "amd64",
        "components": ["main"],
        "pockets": ["release"],
        "pulpRepositoryVersion": "local-fixture",
        "packageCount": 1,
        "payloadSize": sum(a["size"] for a in artifacts),
        "artifacts": artifacts,
    }],
    "compatibility": {
        "pulp": "validated-by-local-harness",
        "pulpDeb": "validated-by-local-harness",
    },
}
(media / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
manifest_bytes = (media / "manifest.json").read_bytes()
(media / "manifest.sha256").write_text(f"{hashlib.sha256(manifest_bytes).hexdigest()}  manifest.json\n")
PY

echo "Generated transfer manifest at ${media_dir}/manifest.json"
