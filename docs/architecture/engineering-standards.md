# Engineering Standards

This project is production-bound infrastructure for air-gap binary hydration.
Correctness, auditability, and reproducibility outrank delivery speed.

## Type Safety

1. All new application code must be statically typed.
2. Rust is the default implementation language for the rewrite.
3. Production Rust crates must use `#![forbid(unsafe_code)]`.
4. CI must deny warnings and Clippy findings.
5. Production code must not use `unwrap`, `expect`, `panic`, `todo`, or
   `unimplemented`.
6. Transfer direction, side, repository IDs, artifact paths, SHA-256 digests,
   task states, and evidence IDs must be domain types, not plain strings.
7. External contracts must be schema-first and generate typed clients or models.
8. Python that remains in the harness must pass strict `mypy` and `ruff`.
9. Type ignores require an inline rationale and owner approval.

## Testing and Coverage

1. 100% line and branch coverage is required for application code.
2. Coverage failures block merges.
3. Unit tests must cover pure domain logic.
4. Property tests must cover manifest parsing, path containment, hashing,
   canonicalization, idempotency, and state transitions.
5. Integration tests must use disposable Pulp instances and isolated clients.
6. End-to-end tests must capture Playwright evidence as structured packages
   under `evidence/<session-id>/`.
7. Negative tests are mandatory for checksum mismatch, path traversal, public
   high-side egress, missing signatures, duplicate imports, and task failures.
8. Tests may not mutate host apt configuration.

## CI/CD Gates

Every pull request and release candidate must pass:

1. Formatting.
2. Linting.
3. Strict type checks.
4. Unit tests.
5. 100% coverage report.
6. Static harness validation.
7. Shell script syntax and ShellCheck validation.
8. JSON schema and solution validation.
9. Dependency audit.
10. Secret scanning.
11. SBOM generation for release artifacts.
12. Container image scan when images are produced.
13. IaC validation and security scan when infrastructure changes.
14. Signed artifacts and provenance for releases.

## Air-Gap Invariants

1. Low-side to high-side transfer is one-way only.
2. High-side automation must not reference public package sources.
3. High-side automation must not pull public container images.
4. Transfer manifests must validate direction, path containment, size, and
   SHA-256 before import.
5. Evidence must include Pulp task outputs, manifest checks, client validation,
   and Playwright artifacts in the structured `README.md` plus grouped
   `manifest.json`, `apt/`, `fixture/`, `logs/`, `pulp/`, `report/`, and
   `screenshots/` framework.
6. Secrets, admin passwords, CLI profiles, private keys, and generated Pulp
   settings must never be committed.
