#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=harness/local/scripts/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

evidence_root="${1:-${REPO_ROOT}/evidence}"
require_cmd python3

python3 - "${evidence_root}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
required_root_files = {"README.md", "manifest.json"}
required_dirs = {"apt", "fixture", "logs", "pulp", "report", "screenshots"}
required_readme_sections = {
    "## Executive Summary",
    "## Proof Chain",
    "## Artifact Directory",
}
legacy_root_files = {
    "test-evidence-apt.md",
    "pulp-apt-deb-repo.txt",
}


def fail(message: str) -> None:
    raise SystemExit(f"evidence structure validation failed: {message}")


def relative_artifact_path(package_dir: Path, value: object) -> Path:
    if not isinstance(value, str) or not value:
        fail(f"{package_dir.name}: artifact path must be a non-empty string")
    path = Path(value)
    if path.is_absolute() or ".." in path.parts:
        fail(f"{package_dir.name}: artifact path must be relative and contained: {value}")
    return path


def visible_files(directory: Path) -> set[str]:
    return {path.name for path in directory.iterdir() if path.is_file() and not path.name.startswith(".")}


if not root.exists():
    print(f"evidence structure: no evidence root at {root}")
    raise SystemExit(0)
if not root.is_dir():
    fail(f"evidence root is not a directory: {root}")

unexpected_root_files = sorted(visible_files(root) - legacy_root_files)
if unexpected_root_files:
    fail(f"root-level evidence files are not allowed: {unexpected_root_files}")

package_dirs = sorted(path for path in root.iterdir() if path.is_dir() and not path.name.startswith("."))
if not package_dirs:
    print(f"evidence structure: no evidence packages under {root}")
    raise SystemExit(0)

for package_dir in package_dirs:
    root_files = visible_files(package_dir)
    if root_files != required_root_files:
        fail(
            f"{package_dir.name}: root files must be {sorted(required_root_files)}, "
            f"found {sorted(root_files)}",
        )

    child_dirs = {path.name for path in package_dir.iterdir() if path.is_dir() and not path.name.startswith(".")}
    if child_dirs != required_dirs:
        fail(
            f"{package_dir.name}: evidence dirs must be {sorted(required_dirs)}, "
            f"found {sorted(child_dirs)}",
        )

    readme = (package_dir / "README.md").read_text(encoding="utf-8")
    missing_sections = sorted(section for section in required_readme_sections if section not in readme)
    if missing_sections:
        fail(f"{package_dir.name}: README.md missing sections: {missing_sections}")

    try:
        manifest = json.loads((package_dir / "manifest.json").read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"{package_dir.name}: manifest.json is invalid JSON: {exc}")

    if manifest.get("sessionId") != package_dir.name:
        fail(f"{package_dir.name}: manifest sessionId must match directory name")
    if manifest.get("result") not in {"PASS", "FAIL", "BLOCKED"}:
        fail(f"{package_dir.name}: manifest result must be PASS, FAIL, or BLOCKED")

    artifact_groups = manifest.get("artifactGroups")
    if not isinstance(artifact_groups, list) or not artifact_groups:
        fail(f"{package_dir.name}: manifest artifactGroups must be a non-empty list")

    referenced_paths: set[Path] = set()
    for group in artifact_groups:
        if not isinstance(group, dict):
            fail(f"{package_dir.name}: artifact group must be an object")
        for required_field in ("name", "description", "artifacts"):
            if required_field not in group:
                fail(f"{package_dir.name}: artifact group missing {required_field}")
        artifacts = group["artifacts"]
        if not isinstance(artifacts, list) or not artifacts:
            fail(f"{package_dir.name}: artifact group {group.get('name')} has no artifacts")
        for item in artifacts:
            if not isinstance(item, dict):
                fail(f"{package_dir.name}: artifact entry must be an object")
            artifact_path = relative_artifact_path(package_dir, item.get("path"))
            full_path = package_dir / artifact_path
            if not full_path.is_file():
                fail(f"{package_dir.name}: manifest references missing artifact {artifact_path}")
            if full_path.stat().st_size <= 0:
                fail(f"{package_dir.name}: artifact is empty: {artifact_path}")
            if not item.get("description"):
                fail(f"{package_dir.name}: artifact {artifact_path} needs a description")
            referenced_paths.add(artifact_path)

    actual_artifact_paths = {
        path.relative_to(package_dir)
        for path in package_dir.rglob("*")
        if path.is_file() and path.name not in required_root_files and not path.name.startswith(".")
    }
    unindexed = sorted(str(path) for path in actual_artifact_paths - referenced_paths)
    missing = sorted(str(path) for path in referenced_paths - actual_artifact_paths)
    if unindexed:
        fail(f"{package_dir.name}: artifacts exist but are not in manifest: {unindexed}")
    if missing:
        fail(f"{package_dir.name}: manifest references non-artifacts: {missing}")

print(f"evidence structure: validated {len(package_dirs)} package(s) under {root}")
PY
