#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF_USAGE'
Usage: validate-sandbox.sh [--rebuild] [--image IMAGE]

Validates that the sandbox contains Pulp CLI deb tooling, strict Python
validation tools, ShellCheck, and enough repository tooling to run static checks.
EOF_USAGE
}

runner_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild) runner_args+=(--rebuild); shift ;;
    --image) runner_args+=(--image "$2"); shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done

"${SCRIPT_DIR}/run-sandbox.sh" "${runner_args[@]}" -- bash -lc '
set -euo pipefail
pulp --version
pulp deb --help >/tmp/pulp-deb-help.txt
pulp deb remote create --help >/tmp/pulp-deb-remote-create-help.txt
pulp deb repository sync --help >/tmp/pulp-deb-repository-sync-help.txt
pulp deb publication create --help >/tmp/pulp-deb-publication-create-help.txt
pulp deb distribution create --help >/tmp/pulp-deb-distribution-create-help.txt
pulp deb content upload --help >/tmp/pulp-deb-content-upload-help.txt
python -m ruff format --check harness/local/pulp_harness harness/local/scripts/generate-deb-fixture.py tests
python -m ruff check harness/local/pulp_harness harness/local/scripts/generate-deb-fixture.py tests
python -m mypy
python -m coverage run -m pytest
python -m coverage report
bash -n harness/local/scripts/*.sh harness/sandbox/scripts/*.sh tests/e2e/*.sh .githooks/*
shellcheck -x harness/local/scripts/*.sh harness/sandbox/scripts/*.sh tests/e2e/*.sh .githooks/*
harness/local/scripts/validate-static.sh
rm -rf .coverage coverage.xml .mypy_cache .pytest_cache .ruff_cache htmlcov
'
