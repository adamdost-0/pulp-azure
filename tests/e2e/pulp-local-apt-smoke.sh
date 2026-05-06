#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SESSION_ID="${PULP_SESSION_ID:-local-apt-smoke-e2e}"

cd "${REPO_ROOT}"

harness/local/scripts/setup-pulp-session.sh --session-id "${SESSION_ID}" --recreate
harness/local/scripts/run-pulp-solution.sh --session-id "${SESSION_ID}" --solution solutions/local-apt-smoke.json
harness/local/scripts/validate-apt-client.sh --session-id "${SESSION_ID}"
harness/local/scripts/capture-evidence.sh --session-id "${SESSION_ID}"

cat <<EOF_DONE
Disposable Pulp apt smoke test completed.
Session: ${SESSION_ID}
Evidence: evidence/${SESSION_ID}/README.md
Teardown: harness/local/scripts/destroy-pulp-session.sh --session-id ${SESSION_ID} --force
EOF_DONE
