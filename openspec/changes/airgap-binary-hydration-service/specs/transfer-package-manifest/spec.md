## ADDED Requirements

### Requirement: Transfer package contents
The system SHALL generate transfer packages that contain Pulp export artifacts, a machine-readable manifest, checksums, signature material, provenance metadata, and operator-readable transfer instructions.

#### Scenario: Create package for approved snapshots
- **WHEN** an operator creates a transfer package from approved snapshots
- **THEN** the package contains all Pulp export artifacts and a manifest describing every included repository snapshot

#### Scenario: Exclude unapproved snapshot
- **WHEN** a snapshot has not been approved for transfer
- **THEN** the system MUST NOT include it in a transfer package

### Requirement: Manifest schema
The transfer manifest SHALL include schema version, batch identifier, source environment identity, repository names, distribution metadata, architectures, Pulp repository versions, content counts, content digests, export artifact references, generated timestamp, approval metadata, and compatibility constraints.

#### Scenario: Manifest generated
- **WHEN** the system generates a transfer manifest
- **THEN** all required schema fields are present and refer to immutable repository snapshots

#### Scenario: Incompatible manifest schema
- **WHEN** a high-side importer receives a manifest with an unsupported schema version
- **THEN** the importer rejects the package before reading repository payloads

### Requirement: Integrity verification
The system MUST produce and verify cryptographic checksums for every manifest and payload artifact in a transfer package.

#### Scenario: Payload checksum mismatch
- **WHEN** high-side validation computes a payload checksum that differs from the manifest value
- **THEN** the system rejects the transfer package and records the validation failure

#### Scenario: All checksums match
- **WHEN** high-side validation confirms every checksum in the manifest
- **THEN** the system marks the package integrity check as passed

### Requirement: Manifest signing
The system SHALL sign transfer manifests on the low side and verify signatures on the high side using a configured trust chain available in both environments.

#### Scenario: Valid signature
- **WHEN** the high-side service validates a manifest signed by a trusted low-side signing certificate
- **THEN** the signature verification succeeds and the package may proceed to import validation

#### Scenario: Untrusted signature
- **WHEN** the manifest signature cannot be verified against the configured high-side trust chain
- **THEN** the system MUST reject the transfer package

### Requirement: Batch sizing
The system SHALL estimate transfer package size before export and support splitting eligible snapshots into multiple batches.

#### Scenario: Batch exceeds capacity
- **WHEN** selected snapshots exceed the configured transfer media capacity
- **THEN** the system prevents package generation until the selection is reduced or split
