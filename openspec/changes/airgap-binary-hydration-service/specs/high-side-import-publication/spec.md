## ADDED Requirements

### Requirement: Offline package intake
The high-side service SHALL accept transfer packages from operator-provided offline media without requiring public internet access.

#### Scenario: Intake package from mounted media
- **WHEN** an operator submits a mounted transfer package path
- **THEN** the high-side service stages the package from the local or private storage location for validation

#### Scenario: Public endpoint unavailable
- **WHEN** the high-side network has no public internet route
- **THEN** package intake, validation, import, and publication MUST continue using only private high-side services

### Requirement: Pre-import validation
The high-side service MUST validate JSON manifest schema, compatibility version, checksums, duplicate status, predecessor rules, and approval metadata before invoking Pulp import.

#### Scenario: Validation succeeds
- **WHEN** a package passes schema, integrity, duplicate, predecessor, and approval checks without compatibility warnings
- **THEN** the high-side service marks the package ready for Pulp import

#### Scenario: Checksum validation fails
- **WHEN** a manifest or payload checksum validation fails
- **THEN** the high-side service rejects the entire transfer package

#### Scenario: Compatibility warning requires override
- **WHEN** a package passes integrity validation but has a Pulp or `pulp_deb` compatibility warning
- **THEN** the high-side service prevents import until a privileged operator supplies an audited override

### Requirement: Pulp import orchestration
The high-side service SHALL invoke native Pulp import for validated transfer packages and track task progress through completion or failure.

#### Scenario: Import completes
- **WHEN** Pulp completes an import task successfully
- **THEN** the high-side system records imported repository versions and marks the transfer batch publication-ready

#### Scenario: Import fails
- **WHEN** Pulp reports an import failure
- **THEN** the system records failure details and MUST NOT mark the batch as publication-ready

### Requirement: Controlled internal HTTPS APT publication
The high-side service SHALL publish imported Ubuntu APT repository snapshots to internal HTTPS endpoints using internal PKI only after successful validation, import, and operator promotion.

#### Scenario: Promote imported batch to channel
- **WHEN** an operator promotes a successfully imported batch to a test or prod channel
- **THEN** the high-side service publishes the corresponding repository versions to stable internal HTTPS APT endpoints

#### Scenario: Publish immutable snapshot URL
- **WHEN** a repository snapshot is imported successfully
- **THEN** the high-side service exposes or records an immutable snapshot URL for that repository version

#### Scenario: Supersede previous publication
- **WHEN** a newer snapshot is promoted for a repository
- **THEN** the high-side service records the previous publication as superseded while retaining rollback metadata

### Requirement: Rollback publication
The high-side service SHALL allow an explicitly approved rollback by republishing a previous known-good repository version to the same stable client endpoint.

#### Scenario: Roll back bad publication
- **WHEN** an operator approves rollback for a published repository channel
- **THEN** the high-side service republishes the previous known-good repository version to the same stable endpoint and records the rollback in audit history
