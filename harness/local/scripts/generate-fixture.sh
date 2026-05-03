#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

require_cmd ar
require_cmd tar
require_cmd gzip
require_cmd python3

fixture_dir="$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).expanduser().resolve())' "${1:-${HARNESS_WORKDIR}/fixture}")"
package_name="airgap-fixture"
version="1.0.0"
arch="amd64"
pool_dir="${fixture_dir}/pool/main/a/${package_name}"
binary_dir="${fixture_dir}/dists/jammy/main/binary-${arch}"
build_dir="${HARNESS_WORKDIR}/build/${package_name}"

rm -rf "${fixture_dir}" "${build_dir}"
mkdir -p "${pool_dir}" "${binary_dir}" "${build_dir}/control" "${build_dir}/data/usr/share/${package_name}"

cat > "${build_dir}/control/control" <<EOF
Package: ${package_name}
Version: ${version}
Section: base
Priority: optional
Architecture: ${arch}
Maintainer: Airgap Harness <noreply@example.invalid>
Description: Tiny deterministic package for local APT fixture testing.
EOF

cat > "${build_dir}/data/usr/share/${package_name}/README" <<EOF
${package_name} ${version}
EOF

printf '2.0\n' > "${build_dir}/debian-binary"
(cd "${build_dir}/control" && tar --format=ustar -czf ../control.tar.gz .)
(cd "${build_dir}/data" && tar --format=ustar -czf ../data.tar.gz .)
(cd "${build_dir}" && ar r "${pool_dir}/${package_name}_${version}_${arch}.deb" debian-binary control.tar.gz data.tar.gz >/dev/null)

python3 - "$fixture_dir" "$package_name" "$version" "$arch" <<'PY'
import gzip
import hashlib
import os
import pathlib
import sys

fixture = pathlib.Path(sys.argv[1])
name, version, arch = sys.argv[2:5]
deb_rel = pathlib.Path("pool/main/a") / name / f"{name}_{version}_{arch}.deb"
deb = fixture / deb_rel
data = deb.read_bytes()
packages = "\n".join([
    f"Package: {name}",
    f"Version: {version}",
    "Section: base",
    "Priority: optional",
    f"Architecture: {arch}",
    "Maintainer: Airgap Harness <noreply@example.invalid>",
    f"Filename: {deb_rel.as_posix()}",
    f"Size: {len(data)}",
    f"MD5sum: {hashlib.md5(data).hexdigest()}",
    f"SHA256: {hashlib.sha256(data).hexdigest()}",
    "Description: Tiny deterministic package for local APT fixture testing.",
    "",
])
binary = fixture / "dists/jammy/main/binary-amd64"
(binary / "Packages").write_text(packages)
with gzip.GzipFile(filename="", mode="wb", fileobj=(binary / "Packages.gz").open("wb"), mtime=0) as fh:
    fh.write(packages.encode())

release_fields = [
    "Origin: Airgap Harness",
    "Label: Airgap Harness",
    "Suite: jammy",
    "Codename: jammy",
    "Version: 22.04",
    "Architectures: amd64",
    "Components: main",
    "Description: Deterministic local APT fixture",
]
hash_lines = ["SHA256:"]
for rel in ["main/binary-amd64/Packages", "main/binary-amd64/Packages.gz"]:
    path = fixture / "dists/jammy" / rel
    blob = path.read_bytes()
    hash_lines.append(f" {hashlib.sha256(blob).hexdigest()} {len(blob)} {rel}")
(fixture / "dists/jammy/Release").write_text("\n".join(release_fields + hash_lines) + "\n")
PY

echo "Generated APT fixture at ${fixture_dir}"
find "${fixture_dir}" -type f | sort
