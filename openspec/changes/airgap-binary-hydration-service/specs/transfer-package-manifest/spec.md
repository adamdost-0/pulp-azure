## ADDED Requirements

### Requirement: Transfer package contents
The system SHALL generate transfer packages that contain native Pulp export artifacts, a JSON manifest, checksums, provenance metadata, approval metadata, compatibility metadata, and operator-readable transfer instructions.

#### Scenario: Create package for approved snapshots
- **WHEN** an operator creates a transfer package from approved snapshots
- **THEN** the package contains all Pulp export artifacts and a JSON manifest describing every included repository snapshot

#### Scenario: Exclude unapproved snapshot
- **WHEN** a snapshot has not been approved for transfer
- **THEN** the system MUST NOT include it in a transfer package

### Requirement: JSON manifest schema
The transfer manifest SHALL be JSON and include schema version, transfer batch identifier, source environment identity, generated timestamp, repository names, Ubuntu distribution/release, architectures, APT components/pockets, Pulp repository versions, package counts, payload sizes, content checksums, Pulp export artifact references, approval metadata, provenance metadata, and importer compatibility constraints.

#### Scenario: Manifest generated
- **WHEN** the system generates a transfer manifest
- **THEN** all required schema fields are present and refer to immutable repository snapshots

#### Scenario: Unsupported manifest schema
- **WHEN** a high-side importer receives a manifest with an unsupported schema version
- **THEN** the importer rejects the entire package before reading repository payloads

### Requirement: Checksum-only integrity verification
The system MUST produce and verify cryptographic checksums for every manifest and payload artifact in a transfer package, and manifest signing SHALL NOT be required for the first release.

#### Scenario: Payload checksum mismatch
- **WHEN** high-side validation computes a payload checksum that differs from the manifest value
- **THEN** the system rejects the entire transfer package and records the validation failure

#### Scenario: All checksums match
- **WHEN** high-side validation confirms every checksum in the manifest
- **THEN** the system marks the package integrity check as passed

### Requirement: Compatibility warning and privileged override
The system SHALL warn on Pulp or plugin compatibility mismatches and require a privileged operator override before continuing with import.

#### Scenario: Compatibility warning without override
- **WHEN** high-side validation detects a Pulp or `pulp_deb` compatibility mismatch and no privileged override is provided
- **THEN** the system prevents import and records the warning

#### Scenario: Compatibility warning with override
- **WHEN** a privileged operator supplies an override justification for a compatibility warning
- **THEN** the system allows the import workflow to continue and records the override in audit history

### Requirement: Batch sizing
The system SHALL estimate transfer package size before export and support splitting eligible snapshots into multiple batches.

#### Scenario: Batch exceeds capacity
- **WHEN** selected snapshots exceed the configured transfer media capacity
- **THEN** the system prevents package generation until the selection is reduced or split
