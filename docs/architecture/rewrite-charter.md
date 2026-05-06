# Pulp Azure Rewrite Charter

This charter captures the product behavior found in this repository and the
engineering rules that govern the ground-up rewrite. Treat it as binding until a
formal product owner decision replaces it.

## Product Surface Found in This Repository

The checked-out repository is a roadmap and local harness, not a complete
production service. The implemented behavior is:

1. Create disposable local Pulp sessions with generated settings and credentials.
2. Configure Pulp through native `pulp-cli` commands.
3. Generate deterministic Debian apt fixture repositories.
4. Sync, publish, and distribute Debian content through Pulp.
5. Validate client consumption with `apt-get` inside an isolated container.
6. Capture Playwright-backed structured evidence packages under
   `evidence/<session-id>/`.
7. Preserve evidence while destroying disposable runtime state.

The intended but deferred product behavior is:

1. Low-side to high-side disconnected export/import.
2. One-way transfer manifests with path containment, size, and SHA-256 checks.
3. Manual media custody, import-check, import, publish, and high-side evidence gates.
4. Azure Commercial and Azure Government deployment topology.
5. Private image references with pinned digests and no high-side public egress.
6. Production TLS, repository signing, evidence signing, and key custody.
7. Operator CLI or service orchestration for idempotent workflows.

## Autonomous Decisions

The live interview could not proceed, so these decisions unblock implementation:

1. Use this repository plus product-owner interview follow-up as the source of
   truth until the production implementation source is provided.
2. Preserve Pulp as the system of record for repository, publication,
   distribution, export, and import state.
3. Keep native Pulp behavior authoritative; do not reimplement repository
   semantics in application code.
4. Treat low-side to high-side as strictly one-way. No receipt, status callback,
   telemetry, or automated feedback channel may cross back to low-side.
5. Treat current apt support as the first mandatory package ecosystem. Other
   ecosystems require explicit requirements before implementation.

## Recommended Target Stack

Use a Rust-first architecture:

| Layer | Standard |
| --- | --- |
| Core workflow engine | Rust workspace with explicit domain types |
| API service | `axum`, `tokio`, generated OpenAPI contracts |
| Operator CLI | Rust `clap`, same types as the service |
| Persistence | PostgreSQL for workflow metadata and idempotency |
| Artifact storage | Azure Blob Storage or ADLS with immutable retention where required |
| Secrets and signing | Azure Key Vault or managed HSM |
| Observability | Structured JSON logs, `tracing`, OpenTelemetry |
| Admin UI | Strict TypeScript React only if a UI is required |
| IaC | Terraform or OpenTofu modules for Azure resources |
| Container supply chain | ACR, pinned digests, SBOMs, signatures, provenance |

Rust is the default because the rewrite is correctness-sensitive: manifests,
hashes, transfer direction, side boundaries, task states, and evidence indexes
must be encoded as types instead of ad hoc strings.

## Interview Backlog

The next product-owner interview must close these gaps before production design
is frozen:

1. Confirm whether the full production legacy source exists elsewhere.
2. Confirm active package ecosystems: apt only, rpm, Python, NuGet, container
   images, generic files, or others.
3. Define user personas: platform operator, release engineer, auditor, customer
   administrator, and support engineer.
4. Define scale: repository count, artifact count, artifact sizes, sync cadence,
   concurrent workflows, retention windows, and expected recovery time.
5. Define Azure topology: AKS, Container Apps, VMs, private endpoints, ACR,
   managed PostgreSQL, storage account layout, and network isolation.
6. Define authentication and authorization: Entra ID, managed identities, local
   break-glass accounts, RBAC roles, approval gates, and audit requirements.
7. Define signing: apt repository signing, manifest signing, evidence signing,
   key rotation, custody, and revocation.
8. Define failure semantics: retry policy, resume points, duplicate import
   behavior, task cancellation, rollback, and operator notifications.
9. Define compliance evidence: artifact retention, redaction, immutable storage,
   audit export format, and chain-of-custody requirements.
10. Define migration: existing production data, cutover strategy, compatibility
    window, rollback plan, and acceptance tests.
