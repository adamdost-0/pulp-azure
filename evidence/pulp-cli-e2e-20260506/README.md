# Evidence: Disposable Pulp Apt Session

## Executive Summary

| Field | Value |
| --- | --- |
| Result | PASS |
| Session ID | `pulp-cli-e2e-20260506` |
| Pulp endpoint | `http://localhost:18180` |
| Distribution URL | `http://localhost:18180/pulp/content/apt/local-smoke/` |
| Release URL | `http://localhost:18180/pulp/content/apt/local-smoke/dists/stable/Release` |
| Fixture package | `pulp-smoke 0.1.0 (amd64)` |
| Repository latest version | `/pulp/api/v3/repositories/deb/apt/3343d55a-58df-4771-951f-3e28e3ddc353/versions/1/` |
| Online workers | `2` |

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
| Remote | `/pulp/api/v3/remotes/deb/apt/57908149-33b9-442d-8b0d-8921edf4d793/` |
| Repository | `/pulp/api/v3/repositories/deb/apt/3343d55a-58df-4771-951f-3e28e3ddc353/` |
| Repository version | `/pulp/api/v3/repositories/deb/apt/3343d55a-58df-4771-951f-3e28e3ddc353/versions/1/` |
| Publication | `/pulp/api/v3/publications/deb/apt/99e5f1a6-520b-4348-90dd-3041c70b82f9/` |
| Distribution | `/pulp/api/v3/distributions/deb/apt/2e315877-a255-4ead-93f4-e3c9c2f5cef1/` |

## Synced Content Summary

deb.package: 1, deb.package_index: 1, deb.package_release_component: 1, deb.release: 1, deb.release_architecture: 1, deb.release_component: 1, deb.release_file: 1

| Package | Version | Architecture | Relative path | SHA-256 |
| --- | --- | --- | --- | --- |
| pulp-smoke | 0.1.0 | amd64 | pool/main/p/pulp-smoke/pulp-smoke_0.1.0_amd64.deb | cd00fdf14a8aef3974d4a121a967c74b3405c2a3b93cc3f6b64e6bc988a59c0e |

## Apt Client Install Excerpt

```text
Get:1 http://deb.debian.org/debian bookworm InRelease [151 kB]
Get:2 http://deb.debian.org/debian bookworm-updates InRelease [55.4 kB]
Get:3 http://deb.debian.org/debian-security bookworm-security InRelease [48.0 kB]
Get:5 http://host.docker.internal:18180/pulp/content/apt/local-smoke stable Release [1282 B]
Get:7 http://host.docker.internal:18180/pulp/content/apt/local-smoke stable/main amd64 Packages [255 B]
Get:8 http://deb.debian.org/debian bookworm/main amd64 Packages [8792 kB]
Get:9 http://deb.debian.org/debian bookworm-updates/main amd64 Packages [6924 B]
Get:10 http://deb.debian.org/debian-security bookworm-security/main amd64 Packages [299 kB]
  pulp-smoke
Get:1 http://host.docker.internal:18180/pulp/content/apt/local-smoke stable/main amd64 pulp-smoke amd64 0.1.0 [660 B]
Selecting previously unselected package pulp-smoke.
Preparing to unpack .../pulp-smoke_0.1.0_amd64.deb ...
Unpacking pulp-smoke (0.1.0) ...
Setting up pulp-smoke (0.1.0) ...
pulp-smoke 0.1.0 generated for disposable Pulp apt validation.
```

## Published Release Excerpt

```text
Origin: Pulp 3
Suite: stable
Codename: stable
Date: Wed, 06 May 2026 05:14:37 +0000
Architectures: amd64 all
Components: main
SHA256:
 121b0085af49ba4c467e33507a7f3d1932b7617ec8cb8974d7219c74251d1d48              305 main/binary-amd64/Packages
 3ffccdeaa7df5549d0ee9d4b21131e3a9d0ed8f4d67fa22c528be64218163452              255 main/binary-amd64/Packages.gz
 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855                0 main/binary-all/Packages
 5aed8120cb86c4047c9d9d3da1acefa642e93287dfb5ed3cbe2fb90be0e9520d               29 main/binary-all/Packages.gz
SHA512:
```

## Pulp Plugin Versions

- pulpcore 3.21.34 (core)
- pulp-rpm 3.19.12 (rpm)
- pulp-python 3.7.3 (python)
- pulp-maven 0.3.3 (maven)
- pulp-file 1.11.3 (file)
- pulp_deb 2.20.4 (deb)
- pulp-container 2.14.16 (container)
- pulp-certguard 1.6.6 (certguard)
- pulp-ansible 0.16.4 (ansible)

## Artifact Directory

### Human report
Start with the root README, then review the Playwright-rendered HTML release evidence.
| Artifact | Purpose | Size |
| --- | --- | ---: |
| [report/release-evidence.html](report/release-evidence.html) | HTML page rendered by Playwright for the screenshot. | 2212 bytes |

### Screenshots
Visual evidence generated by Playwright CLI.
| Artifact | Purpose | Size |
| --- | --- | ---: |
| [screenshots/release-page.png](screenshots/release-page.png) | Screenshot of the generated release evidence page. | 108653 bytes |

### Apt client evidence
APT source configuration and published Release metadata consumed by the isolated client.
| Artifact | Purpose | Size |
| --- | --- | ---: |
| [apt/sources.list](apt/sources.list) | APT source line used by the isolated client container. | 93 bytes |
| [apt/release.txt](apt/release.txt) | Live published apt Release endpoint body. | 1282 bytes |
| [logs/apt-client.log](logs/apt-client.log) | apt-get update/install log from the isolated client. | 2274 bytes |

### Pulp CLI evidence
Raw Pulp status and Pulp CLI JSON outputs grouped by resource type.
| Artifact | Purpose | Size |
| --- | --- | ---: |
| [pulp/status.json](pulp/status.json) | Pulp readiness and plugin versions. | 1321 bytes |
| [pulp/pulp-cli-status.json](pulp/pulp-cli-status.json) | Pulp CLI status output. | 1414 bytes |
| [pulp/deb-remote.json](pulp/deb-remote.json) | Created deb remote. | 779 bytes |
| [pulp/deb-repository-created.json](pulp/deb-repository-created.json) | Created deb repository before sync. | 525 bytes |
| [pulp/deb-repository-after-sync.json](pulp/deb-repository-after-sync.json) | Repository metadata after sync. | 525 bytes |
| [pulp/deb-repository-versions.json](pulp/deb-repository-versions.json) | Repository versions and content summary. | 3399 bytes |
| [pulp/deb-package-content.json](pulp/deb-package-content.json) | Synced deb package content. | 1365 bytes |
| [pulp/deb-publication.json](pulp/deb-publication.json) | Created apt publication. | 395 bytes |
| [pulp/deb-distribution.json](pulp/deb-distribution.json) | Created apt distribution. | 421 bytes |
| [logs/deb-sync.log](logs/deb-sync.log) | Pulp CLI sync task progress output. | 88 bytes |

### Fixture evidence
Deterministic input package metadata.
| Artifact | Purpose | Size |
| --- | --- | ---: |
| [fixture/metadata.json](fixture/metadata.json) | Generated fixture package metadata and hashes. | 906 bytes |

### Tooling logs
Evidence capture tool output.
| Artifact | Purpose | Size |
| --- | --- | ---: |
| [logs/playwright-screenshot.log](logs/playwright-screenshot.log) | Playwright CLI screenshot command log. | 227 bytes |


