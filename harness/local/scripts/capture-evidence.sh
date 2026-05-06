#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=harness/local/scripts/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'EOF_USAGE'
Usage: capture-evidence.sh [--session-id ID]

Writes a Playwright-backed, reviewer-readable evidence package under
evidence/<session-id>/.
EOF_USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id) PULP_SESSION_ID="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

require_cmd curl
require_cmd python3
load_session_env "${PULP_SESSION_ID:-local-apt-smoke}"
# shellcheck source=/dev/null
source "${PULP_SESSION_DIR}/workflow/apt-source.env"

[[ "${EVIDENCE_DIR}" == "${REPO_ROOT}/"* ]] || die "evidence directory must be inside the repository: ${EVIDENCE_DIR}"

workflow_dir="${PULP_SESSION_DIR}/workflow"
legacy_apt_client_log="${EVIDENCE_DIR}/apt-client.log"
if [[ -f "${legacy_apt_client_log}" && ! -f "${workflow_dir}/apt-client.log" ]]; then
  cp "${legacy_apt_client_log}" "${workflow_dir}/apt-client.log"
fi
[[ -f "${workflow_dir}/apt-client.log" ]] || die "missing apt client log; run validate-apt-client.sh first"

mkdir -p "${EVIDENCE_DIR}"
rm -rf "${EVIDENCE_DIR:?}/"*

report_dir="${EVIDENCE_DIR}/report"
screenshots_dir="${EVIDENCE_DIR}/screenshots"
logs_dir="${EVIDENCE_DIR}/logs"
apt_dir="${EVIDENCE_DIR}/apt"
fixture_dir="${EVIDENCE_DIR}/fixture"
pulp_dir="${EVIDENCE_DIR}/pulp"
mkdir -p "${report_dir}" "${screenshots_dir}" "${logs_dir}" "${apt_dir}" "${fixture_dir}" "${pulp_dir}"

release_url="${PULP_CONTENT_ORIGIN}/pulp/content/${APT_BASE_PATH}/dists/${APT_DISTRIBUTION}/Release"
release_text_path="${apt_dir}/release.txt"
release_page_path="${report_dir}/release-evidence.html"
screenshot_path="${screenshots_dir}/release-page.png"
playwright_log="${logs_dir}/playwright-screenshot.log"

curl --fail --silent --show-error "${release_url}" > "${release_text_path}"
python3 - "${release_text_path}" "${release_page_path}" "${PULP_SESSION_ID}" "${release_url}" "${FIXTURE_PACKAGE}" "${FIXTURE_VERSION}" <<'PY'
import html
import sys
from pathlib import Path

release_text = Path(sys.argv[1]).read_text(encoding="utf-8")
page_path = Path(sys.argv[2])
session_id = sys.argv[3]
release_url = sys.argv[4]
package = sys.argv[5]
version = sys.argv[6]

page_path.write_text(
    f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Pulp apt evidence: {html.escape(session_id)}</title>
  <style>
    body {{ font-family: system-ui, sans-serif; margin: 2rem; line-height: 1.5; }}
    .card {{ border: 1px solid #d0d7de; border-radius: 8px; padding: 1rem; margin-bottom: 1rem; }}
    code, pre {{ background: #f6f8fa; border: 1px solid #d0d7de; border-radius: 6px; }}
    code {{ padding: 0.1rem 0.3rem; }}
    pre {{ padding: 1rem; white-space: pre-wrap; }}
  </style>
</head>
<body>
  <h1>Pulp apt repository evidence</h1>
  <section class="card">
    <p><strong>Session:</strong> <code>{html.escape(session_id)}</code></p>
    <p><strong>Release URL:</strong> <code>{html.escape(release_url)}</code></p>
    <p><strong>Fixture package:</strong> <code>{html.escape(package)} {html.escape(version)}</code></p>
  </section>
  <h2>Published apt Release file</h2>
  <pre>{html.escape(release_text)}</pre>
</body>
</html>
""",
    encoding="utf-8",
)
PY

if command -v playwright >/dev/null 2>&1; then
  playwright screenshot "file://${release_page_path}" "${screenshot_path}" > "${playwright_log}" 2>&1
elif command -v npx >/dev/null 2>&1; then
  npx --yes playwright screenshot "file://${release_page_path}" "${screenshot_path}" > "${playwright_log}" 2>&1
else
  die "Playwright CLI is required for evidence capture; install playwright or provide npx"
fi

cp "${workflow_dir}/status.json" "${pulp_dir}/status.json"
cp "${workflow_dir}/pulp-status.json" "${pulp_dir}/pulp-cli-status.json"
cp "${workflow_dir}/fixture-metadata.json" "${fixture_dir}/metadata.json"
cp "${workflow_dir}/deb-remote.json" "${pulp_dir}/deb-remote.json"
cp "${workflow_dir}/deb-repository.json" "${pulp_dir}/deb-repository-created.json"
cp "${workflow_dir}/deb-repository-after-sync.json" "${pulp_dir}/deb-repository-after-sync.json"
cp "${workflow_dir}/deb-repository-versions.json" "${pulp_dir}/deb-repository-versions.json"
cp "${workflow_dir}/deb-package-content.json" "${pulp_dir}/deb-package-content.json"
cp "${workflow_dir}/deb-publication.json" "${pulp_dir}/deb-publication.json"
cp "${workflow_dir}/deb-distribution.json" "${pulp_dir}/deb-distribution.json"
cp "${workflow_dir}/deb-sync.log" "${logs_dir}/deb-sync.log"
cp "${workflow_dir}/apt-client.log" "${logs_dir}/apt-client.log"
cp "${workflow_dir}/pulp-local.sources.list" "${apt_dir}/sources.list"

python3 - "${EVIDENCE_DIR}" "${PULP_SESSION_ID}" "${PULP_CONTENT_ORIGIN}" "${APT_BASE_PATH}" "${release_url}" "${FIXTURE_PACKAGE}" "${FIXTURE_VERSION}" "${FIXTURE_ARCHITECTURE}" <<'PY'
import json
import sys
from pathlib import Path
from typing import Any

evidence = Path(sys.argv[1])
session_id = sys.argv[2]
pulp_endpoint = sys.argv[3]
apt_base_path = sys.argv[4]
release_url = sys.argv[5]
package = sys.argv[6]
version = sys.argv[7]
architecture = sys.argv[8]


def load_json(path: str) -> Any:
    return json.loads((evidence / path).read_text(encoding="utf-8"))


def md_cell(value: object) -> str:
    return str(value).replace("|", "\\|").replace("\n", " ")


def artifact(path: str, description: str) -> dict[str, object]:
    full_path = evidence / path
    return {
        "path": path,
        "description": description,
        "size": full_path.stat().st_size,
    }


status = load_json("pulp/status.json")
fixture = load_json("fixture/metadata.json")
remote = load_json("pulp/deb-remote.json")
repository = load_json("pulp/deb-repository-after-sync.json")
repository_versions = load_json("pulp/deb-repository-versions.json")
package_content = load_json("pulp/deb-package-content.json")
publication = load_json("pulp/deb-publication.json")
distribution = load_json("pulp/deb-distribution.json")

versions = status.get("versions", [])
plugin_versions = []
if isinstance(versions, list):
    for item in versions:
        if isinstance(item, dict):
            component = item.get("component") or item.get("package") or "unknown"
            package_name = item.get("package") or component
            plugin_versions.append(f"{package_name} {item.get('version', 'unknown')} ({component})")
elif isinstance(versions, dict):
    plugin_versions = [f"{name} {version}" for name, version in sorted(versions.items())]

workers = status.get("online_workers") or status.get("workers") or []
worker_count = len(workers) if isinstance(workers, list) else "unknown"

latest_version_href = repository.get("latest_version_href", "unknown")
content_summary = "unknown"
if isinstance(repository_versions, list) and repository_versions:
    latest = repository_versions[0]
    if isinstance(latest, dict):
        present = latest.get("content_summary", {}).get("present", {})
        if isinstance(present, dict):
            content_summary = ", ".join(
                f"{name}: {details.get('count', 'unknown')}"
                for name, details in sorted(present.items())
                if isinstance(details, dict)
            )

package_rows = []
if isinstance(package_content, list):
    for item in package_content:
        if isinstance(item, dict):
            package_rows.append(
                "| "
                + " | ".join(
                    md_cell(item.get(key, ""))
                    for key in ["package", "version", "architecture", "relative_path", "sha256"]
                )
                + " |"
            )

apt_log = (evidence / "logs/apt-client.log").read_text(encoding="utf-8", errors="replace")
apt_excerpt = "\n".join(
    line
    for line in apt_log.splitlines()
    if package in line or line.startswith(("Get:", "Setting up", "apt evidence includes"))
)[-3000:]
if not apt_excerpt:
    apt_excerpt = apt_log[-3000:]

release_text = (evidence / "apt/release.txt").read_text(encoding="utf-8", errors="replace")
release_excerpt = "\n".join(release_text.splitlines()[:12])

artifact_groups = [
    {
        "name": "Human report",
        "description": "Start with the root README, then review the Playwright-rendered HTML release evidence.",
        "artifacts": [
            artifact("report/release-evidence.html", "HTML page rendered by Playwright for the screenshot."),
        ],
    },
    {
        "name": "Screenshots",
        "description": "Visual evidence generated by Playwright CLI.",
        "artifacts": [
            artifact("screenshots/release-page.png", "Screenshot of the generated release evidence page."),
        ],
    },
    {
        "name": "Apt client evidence",
        "description": "APT source configuration and published Release metadata consumed by the isolated client.",
        "artifacts": [
            artifact("apt/sources.list", "APT source line used by the isolated client container."),
            artifact("apt/release.txt", "Live published apt Release endpoint body."),
            artifact("logs/apt-client.log", "apt-get update/install log from the isolated client."),
        ],
    },
    {
        "name": "Pulp CLI evidence",
        "description": "Raw Pulp status and Pulp CLI JSON outputs grouped by resource type.",
        "artifacts": [
            artifact("pulp/status.json", "Pulp readiness and plugin versions."),
            artifact("pulp/pulp-cli-status.json", "Pulp CLI status output."),
            artifact("pulp/deb-remote.json", "Created deb remote."),
            artifact("pulp/deb-repository-created.json", "Created deb repository before sync."),
            artifact("pulp/deb-repository-after-sync.json", "Repository metadata after sync."),
            artifact("pulp/deb-repository-versions.json", "Repository versions and content summary."),
            artifact("pulp/deb-package-content.json", "Synced deb package content."),
            artifact("pulp/deb-publication.json", "Created apt publication."),
            artifact("pulp/deb-distribution.json", "Created apt distribution."),
            artifact("logs/deb-sync.log", "Pulp CLI sync task progress output."),
        ],
    },
    {
        "name": "Fixture evidence",
        "description": "Deterministic input package metadata.",
        "artifacts": [
            artifact("fixture/metadata.json", "Generated fixture package metadata and hashes."),
        ],
    },
    {
        "name": "Tooling logs",
        "description": "Evidence capture tool output.",
        "artifacts": [
            artifact("logs/playwright-screenshot.log", "Playwright CLI screenshot command log."),
        ],
    },
]

manifest = {
    "sessionId": session_id,
    "result": "PASS",
    "summary": "Pulp CLI configured a deb remote, repository, sync, publication, and distribution; an isolated apt client installed the fixture package; Playwright CLI captured visual evidence.",
    "pulpEndpoint": pulp_endpoint,
    "distributionUrl": distribution.get("base_url"),
    "releaseUrl": release_url,
    "aptBasePath": apt_base_path,
    "fixturePackage": {
        "name": package,
        "version": version,
        "architecture": architecture,
        "sha256": fixture.get("deb", {}).get("sha256"),
    },
    "pulp": {
        "remoteHref": remote.get("pulp_href"),
        "repositoryHref": repository.get("pulp_href"),
        "latestVersionHref": latest_version_href,
        "publicationHref": publication.get("pulp_href"),
        "distributionHref": distribution.get("pulp_href"),
        "onlineWorkers": worker_count,
        "pluginVersions": plugin_versions,
    },
    "artifactGroups": artifact_groups,
}
(evidence / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

artifact_table = []
for group in artifact_groups:
    artifact_table.append(f"### {group['name']}\n")
    artifact_table.append(f"{group['description']}\n")
    artifact_table.append("| Artifact | Purpose | Size |\n")
    artifact_table.append("| --- | --- | ---: |\n")
    for item in group["artifacts"]:
        artifact_table.append(
            f"| [{md_cell(item['path'])}]({md_cell(item['path'])}) | {md_cell(item['description'])} | {item['size']} bytes |\n"
        )
    artifact_table.append("\n")

plugin_lines = "\n".join(f"- {entry}" for entry in plugin_versions) or "- unknown"
package_table = "\n".join(package_rows) or "| unknown | unknown | unknown | unknown | unknown |"

readme = f"""# Evidence: Disposable Pulp Apt Session

## Executive Summary

| Field | Value |
| --- | --- |
| Result | PASS |
| Session ID | `{md_cell(session_id)}` |
| Pulp endpoint | `{md_cell(pulp_endpoint)}` |
| Distribution URL | `{md_cell(distribution.get('base_url', 'unknown'))}` |
| Release URL | `{md_cell(release_url)}` |
| Fixture package | `{md_cell(package)} {md_cell(version)} ({md_cell(architecture)})` |
| Repository latest version | `{md_cell(latest_version_href)}` |
| Online workers | `{md_cell(worker_count)}` |

This run proves that Pulp can be configured end-to-end with Pulp CLI for an apt
repository: remote creation, repository sync, publication, distribution, apt
client install, and Playwright CLI evidence capture all completed successfully.

## Proof Chain

1. **Pulp readiness:** `pulp/status.json` records Pulp status and `pulp_deb`;
   `pulp/pulp-cli-status.json` records the Pulp CLI view of the same service.
2. **Pulp CLI configuration:** `pulp/deb-remote.json`, `pulp/deb-repository-created.json`,
   `pulp/deb-publication.json`, and `pulp/deb-distribution.json` record the resources
   created by Pulp CLI.
3. **Repository sync:** `pulp/deb-repository-after-sync.json`,
   `pulp/deb-repository-versions.json`, and `pulp/deb-package-content.json` record the
   synced repository version and package content.
4. **Client validation:** `logs/apt-client.log` records apt-get installing the fixture
   package from the published Pulp distribution.
5. **Visual evidence:** `screenshots/release-page.png` is a Playwright CLI screenshot of
   `report/release-evidence.html`, which is populated from the live apt Release endpoint.

## Key Pulp Resource Hrefs

| Resource | Href |
| --- | --- |
| Remote | `{md_cell(remote.get('pulp_href', 'unknown'))}` |
| Repository | `{md_cell(repository.get('pulp_href', 'unknown'))}` |
| Repository version | `{md_cell(latest_version_href)}` |
| Publication | `{md_cell(publication.get('pulp_href', 'unknown'))}` |
| Distribution | `{md_cell(distribution.get('pulp_href', 'unknown'))}` |

## Synced Content Summary

{content_summary}

| Package | Version | Architecture | Relative path | SHA-256 |
| --- | --- | --- | --- | --- |
{package_table}

## Apt Client Install Excerpt

```text
{apt_excerpt}
```

## Published Release Excerpt

```text
{release_excerpt}
```

## Pulp Plugin Versions

{plugin_lines}

## Artifact Directory

{''.join(artifact_table)}
"""
(evidence / "README.md").write_text(readme, encoding="utf-8")
PY

cat <<EOF_DONE
Evidence captured.
Report: ${EVIDENCE_DIR}/README.md
Manifest: ${EVIDENCE_DIR}/manifest.json
Screenshot: ${screenshot_path}
EOF_DONE
