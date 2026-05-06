#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

usage() {
  cat <<'EOF_USAGE'
Usage: check-p2-export-import-surface.sh [--rebuild] [--image IMAGE] [--out-dir DIR]

Runs a non-destructive pulp-cli command-surface probe inside the sandbox and
writes outputs under a repo-local directory.
EOF_USAGE
}

runner_args=()
out_dir="harness/sandbox/.runtime/p2-export-import-surface"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild) runner_args+=(--rebuild); shift ;;
    --image) runner_args+=(--image "$2"); shift 2 ;;
    --out-dir) out_dir="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ "${out_dir}" = /* ]] || out_dir="${REPO_ROOT}/${out_dir}"
repo_prefix="${REPO_ROOT}/"
if [[ "${out_dir}" != "${repo_prefix}"* ]]; then
  echo "out-dir must be inside repository: ${out_dir}" >&2
  exit 1
fi
mkdir -p "${out_dir}"
container_out_dir="/workspace/${out_dir#${repo_prefix}}"

"${SCRIPT_DIR}/run-sandbox.sh" "${runner_args[@]}" -- bash -lc '
set -euo pipefail
out_dir="$1"
mkdir -p "${out_dir}"

pulp --version > "${out_dir}/pulp-version.txt"

commands=(
  "exporter --help"
  "exporter pulp --help"
  "exporter pulp create --help"
  "export --help"
  "export pulp --help"
  "export pulp run --help"
  "importer --help"
  "importer pulp --help"
  "importer pulp create --help"
  "import-check --help"
  "import --help"
)

: > "${out_dir}/results.tsv"
for cmd in "${commands[@]}"; do
  file_name="pulp-${cmd// /-}.txt"
  set +e
  pulp ${cmd} > "${out_dir}/${file_name}" 2>&1
  rc=$?
  set -e
  printf "%s\t%s\n" "${rc}" "${cmd}" >> "${out_dir}/results.tsv"
done

python - "${out_dir}/results.tsv" "${out_dir}/summary.txt" <<'"'"'PY'"'"'
import sys
from pathlib import Path

results = {}
for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    rc, cmd = line.split("\t", 1)
    results[cmd] = int(rc)

required_ok = [
    "exporter --help",
    "exporter pulp --help",
    "exporter pulp create --help",
    "export --help",
    "export pulp --help",
    "export pulp run --help",
    "importer --help",
    "importer pulp --help",
    "importer pulp create --help",
]
expected_missing = ["import-check --help", "import --help"]

errors = [cmd for cmd in required_ok if results.get(cmd) != 0]
missing = [cmd for cmd in expected_missing if results.get(cmd) != 2]

lines = []
lines.append("P2 export/import command-surface probe")
lines.append("")
for cmd in required_ok + expected_missing:
    rc = results.get(cmd, "n/a")
    lines.append(f"- rc={rc} :: pulp {cmd}")

if errors:
    lines.append("")
    lines.append("FAIL: required command surface is missing.")
    lines.extend(f"  - {cmd}" for cmd in errors)
if missing:
    lines.append("")
    lines.append("WARN: expected missing commands changed from baseline.")
    lines.extend(f"  - {cmd}" for cmd in missing)
if not errors:
    lines.append("")
    lines.append("PASS: baseline command surface captured.")

Path(sys.argv[2]).write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))
if errors:
    raise SystemExit(1)
PY
' -- "${container_out_dir}"
