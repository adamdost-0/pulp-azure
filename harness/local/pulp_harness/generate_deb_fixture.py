"""Generate deterministic apt fixture repositories for disposable Pulp sessions."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import json
import sys
import tarfile
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO, TypedDict, cast

FIXED_TIMESTAMP = 0
HASH_CHUNK_SIZE = 1024 * 1024
AR_LONG_NAME_THRESHOLD = 15


class DebMetadata(TypedDict):
    """Machine-readable metadata for the generated Debian package."""

    path: str
    relativePath: str
    size: int
    sha256: str


class FixtureMetadata(TypedDict):
    """Machine-readable metadata for the generated apt repository."""

    package: str
    version: str
    architecture: str
    distribution: str
    component: str
    deb: DebMetadata
    indexes: list[str]


@dataclass(frozen=True)
class FixtureRequest:
    """Inputs required to generate one deterministic apt fixture repository."""

    repo_root: Path
    package: str
    version: str
    architecture: str
    distribution: str
    component: str
    summary: str
    metadata: Path


def ar_member(name: str, payload: bytes, mode: str = "100644") -> bytes:
    """Return one ar archive member with deterministic metadata."""
    member_name = f"{name}/" if len(name) > AR_LONG_NAME_THRESHOLD else name
    header = (
        f"{member_name:<16}{FIXED_TIMESTAMP:<12}{0:<6}{0:<6}{mode:<8}{len(payload):<10}`\n"
    ).encode("ascii")
    data = header + payload
    if len(payload) % 2:
        data += b"\n"
    return data


def tar_gz(files: Mapping[str, bytes]) -> bytes:
    """Return a deterministic gzip-compressed tar archive."""
    buffer = io.BytesIO()
    with (
        gzip.GzipFile(fileobj=buffer, mode="wb", mtime=FIXED_TIMESTAMP) as gzip_handle,
        tarfile.open(fileobj=cast(BinaryIO, gzip_handle), mode="w|") as archive,
    ):
        for path, payload in files.items():
            info = tarfile.TarInfo(path)
            info.size = len(payload)
            info.mtime = FIXED_TIMESTAMP
            info.uid = 0
            info.gid = 0
            info.uname = "root"
            info.gname = "root"
            archive.addfile(info, io.BytesIO(payload))
    return buffer.getvalue()


def build_deb(package: str, version: str, architecture: str, summary: str) -> bytes:
    """Build a tiny deterministic .deb package payload."""
    control = f"""Package: {package}
Version: {version}
Section: utils
Priority: optional
Architecture: {architecture}
Maintainer: Pulp Azure Local Harness
Description: {summary}
""".encode()
    data_message = f"{package} {version} generated for disposable Pulp apt validation.\n".encode()
    control_tar = tar_gz({"./control": control})
    data_tar = tar_gz({f"./usr/share/{package}/message.txt": data_message})
    return b"!<arch>\n" + b"".join(
        [
            ar_member("debian-binary", b"2.0\n"),
            ar_member("control.tar.gz", control_tar),
            ar_member("data.tar.gz", data_tar),
        ],
    )


def sha256(path: Path) -> str:
    """Return the SHA-256 digest for a file."""
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(HASH_CHUNK_SIZE), b""):
            digest.update(chunk)
    return digest.hexdigest()


def hash_block(paths: Sequence[Path], root: Path, algorithm: str) -> str:
    """Return an apt Release hash block for the provided index files."""
    lines: list[str] = []
    for path in paths:
        payload = path.read_bytes()
        digest = hashlib.new(algorithm, payload).hexdigest()
        rel = path.relative_to(root).as_posix()
        lines.append(f" {digest} {len(payload):16d} {rel}")
    return "\n".join(lines)


def generate_fixture(request: FixtureRequest) -> FixtureMetadata:
    """Generate the fixture repository and write its metadata file."""
    root = request.repo_root.resolve()
    pool_dir = root / "pool" / request.component / request.package[0] / request.package
    packages_dir = (
        root / "dists" / request.distribution / request.component / f"binary-{request.architecture}"
    )
    pool_dir.mkdir(parents=True, exist_ok=True)
    packages_dir.mkdir(parents=True, exist_ok=True)

    deb_name = f"{request.package}_{request.version}_{request.architecture}.deb"
    deb_path = pool_dir / deb_name
    deb_path.write_bytes(
        build_deb(request.package, request.version, request.architecture, request.summary),
    )
    deb_rel = deb_path.relative_to(root).as_posix()
    deb_size = deb_path.stat().st_size
    deb_digest = sha256(deb_path)

    packages_payload = f"""Package: {request.package}
Version: {request.version}
Architecture: {request.architecture}
Maintainer: Pulp Azure Local Harness
Filename: {deb_rel}
Size: {deb_size}
SHA256: {deb_digest}
Description: {request.summary}
"""
    packages_path = packages_dir / "Packages"
    packages_path.write_text(packages_payload, encoding="utf-8")
    with (
        (packages_dir / "Packages.gz").open("wb") as raw_handle,
        gzip.GzipFile(fileobj=raw_handle, mode="wb", mtime=FIXED_TIMESTAMP) as handle,
    ):
        handle.write(packages_payload.encode("utf-8"))

    index_paths = [packages_path, packages_dir / "Packages.gz"]
    release_path = root / "dists" / request.distribution / "Release"
    release_path.write_text(
        "\n".join(
            [
                "Origin: Pulp Azure Local Harness",
                "Label: Pulp Azure Local Harness",
                f"Suite: {request.distribution}",
                f"Codename: {request.distribution}",
                "Date: Thu, 01 Jan 1970 00:00:00 UTC",
                f"Architectures: {request.architecture}",
                f"Components: {request.component}",
                "MD5Sum:",
                hash_block(index_paths, root / "dists" / request.distribution, "md5"),
                "SHA1:",
                hash_block(index_paths, root / "dists" / request.distribution, "sha1"),
                "SHA256:",
                hash_block(index_paths, root / "dists" / request.distribution, "sha256"),
                "",
            ],
        ),
        encoding="utf-8",
    )

    metadata: FixtureMetadata = {
        "package": request.package,
        "version": request.version,
        "architecture": request.architecture,
        "distribution": request.distribution,
        "component": request.component,
        "deb": {
            "path": str(deb_path),
            "relativePath": deb_rel,
            "size": deb_size,
            "sha256": deb_digest,
        },
        "indexes": [str(path) for path in [*index_paths, release_path]],
    }
    request.metadata.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return metadata


def parse_args(argv: Sequence[str] | None = None) -> FixtureRequest:
    """Parse CLI arguments into a typed fixture request."""
    parser = argparse.ArgumentParser(
        description="Generate a deterministic local apt repository with one tiny .deb package.",
    )
    parser.add_argument("--repo-root", required=True)
    parser.add_argument("--package", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--architecture", required=True)
    parser.add_argument("--distribution", required=True)
    parser.add_argument("--component", required=True)
    parser.add_argument("--summary", required=True)
    parser.add_argument("--metadata", required=True)
    namespace = parser.parse_args(argv)
    return FixtureRequest(
        repo_root=Path(cast(str, namespace.repo_root)),
        package=cast(str, namespace.package),
        version=cast(str, namespace.version),
        architecture=cast(str, namespace.architecture),
        distribution=cast(str, namespace.distribution),
        component=cast(str, namespace.component),
        summary=cast(str, namespace.summary),
        metadata=Path(cast(str, namespace.metadata)),
    )


def main(argv: Sequence[str] | None = None) -> int:
    """Run the fixture generator CLI."""
    metadata = generate_fixture(parse_args(argv))
    sys.stdout.write(json.dumps(metadata, indent=2) + "\n")
    return 0
