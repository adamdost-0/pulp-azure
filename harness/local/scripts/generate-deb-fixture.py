#!/usr/bin/env python3
import argparse
import gzip
import hashlib
import io
import json
import tarfile
from pathlib import Path


def ar_member(name: str, payload: bytes, mode: str = "100644") -> bytes:
    if len(name) > 15:
        name = name + "/"
    header = (
        f"{name:<16}"
        f"{0:<12}"
        f"{0:<6}"
        f"{0:<6}"
        f"{mode:<8}"
        f"{len(payload):<10}"
        "`\n"
    ).encode("ascii")
    data = header + payload
    if len(payload) % 2:
        data += b"\n"
    return data


def tar_gz(files: dict[str, bytes]) -> bytes:
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w:gz") as archive:
        for path, payload in files.items():
            info = tarfile.TarInfo(path)
            info.size = len(payload)
            info.mtime = 0
            info.uid = 0
            info.gid = 0
            info.uname = "root"
            info.gname = "root"
            archive.addfile(info, io.BytesIO(payload))
    return buffer.getvalue()


def build_deb(package: str, version: str, arch: str, summary: str) -> bytes:
    control = f"""Package: {package}
Version: {version}
Section: utils
Priority: optional
Architecture: {arch}
Maintainer: Pulp Azure Local Harness
Description: {summary}
""".encode("utf-8")
    data_message = f"{package} {version} generated for disposable Pulp apt validation.\n".encode("utf-8")
    control_tar = tar_gz({"./control": control})
    data_tar = tar_gz({f"./usr/share/{package}/message.txt": data_message})
    return b"!<arch>\n" + b"".join(
        [
            ar_member("debian-binary", b"2.0\n"),
            ar_member("control.tar.gz", control_tar),
            ar_member("data.tar.gz", data_tar),
        ]
    )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def hash_block(paths: list[Path], root: Path, algorithm: str) -> str:
    lines = []
    for path in paths:
        payload = path.read_bytes()
        digest = hashlib.new(algorithm, payload).hexdigest()
        rel = path.relative_to(root).as_posix()
        lines.append(f" {digest} {len(payload):16d} {rel}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate a deterministic local apt repository with one tiny .deb package.")
    parser.add_argument("--repo-root", required=True)
    parser.add_argument("--package", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--architecture", required=True)
    parser.add_argument("--distribution", required=True)
    parser.add_argument("--component", required=True)
    parser.add_argument("--summary", required=True)
    parser.add_argument("--metadata", required=True)
    args = parser.parse_args()

    root = Path(args.repo_root).resolve()
    pool_dir = root / "pool" / args.component / args.package[0] / args.package
    packages_dir = root / "dists" / args.distribution / args.component / f"binary-{args.architecture}"
    pool_dir.mkdir(parents=True, exist_ok=True)
    packages_dir.mkdir(parents=True, exist_ok=True)

    deb_name = f"{args.package}_{args.version}_{args.architecture}.deb"
    deb_path = pool_dir / deb_name
    deb_path.write_bytes(build_deb(args.package, args.version, args.architecture, args.summary))
    deb_rel = deb_path.relative_to(root).as_posix()
    deb_size = deb_path.stat().st_size
    deb_digest = sha256(deb_path)

    packages_payload = f"""Package: {args.package}
Version: {args.version}
Architecture: {args.architecture}
Maintainer: Pulp Azure Local Harness
Filename: {deb_rel}
Size: {deb_size}
SHA256: {deb_digest}
Description: {args.summary}
"""
    packages_path = packages_dir / "Packages"
    packages_path.write_text(packages_payload, encoding="utf-8")
    with (packages_dir / "Packages.gz").open("wb") as raw_handle:
        with gzip.GzipFile(fileobj=raw_handle, mode="wb", mtime=0) as handle:
            handle.write(packages_payload.encode("utf-8"))

    index_paths = [packages_path, packages_dir / "Packages.gz"]
    release_path = root / "dists" / args.distribution / "Release"
    release_path.write_text(
        "\n".join(
            [
                "Origin: Pulp Azure Local Harness",
                "Label: Pulp Azure Local Harness",
                f"Suite: {args.distribution}",
                f"Codename: {args.distribution}",
                "Date: Thu, 01 Jan 1970 00:00:00 UTC",
                f"Architectures: {args.architecture}",
                f"Components: {args.component}",
                "MD5Sum:",
                hash_block(index_paths, root / "dists" / args.distribution, "md5"),
                "SHA1:",
                hash_block(index_paths, root / "dists" / args.distribution, "sha1"),
                "SHA256:",
                hash_block(index_paths, root / "dists" / args.distribution, "sha256"),
                "",
            ]
        ),
        encoding="utf-8",
    )

    metadata = {
        "package": args.package,
        "version": args.version,
        "architecture": args.architecture,
        "distribution": args.distribution,
        "component": args.component,
        "deb": {
            "path": str(deb_path),
            "relativePath": deb_rel,
            "size": deb_size,
            "sha256": deb_digest,
        },
        "indexes": [str(path) for path in index_paths + [release_path]],
    }
    Path(args.metadata).write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(metadata, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())