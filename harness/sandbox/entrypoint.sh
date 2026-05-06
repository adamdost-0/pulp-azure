#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/workspace/.runtime/pulp-sandbox-home}"
mkdir -p "${HOME}"

if [[ $# -eq 0 ]]; then
  set -- bash
fi

exec "$@"

