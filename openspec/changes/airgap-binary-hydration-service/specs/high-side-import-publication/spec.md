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
The high-side service MUST validate manifest schema, compatibility version, checksums, signatures, duplicate status, predecessor rules, and operator approval evidence before invoking Pulp import.

#### Scenario: Validation succeeds
- **WHEN** a package passes schema, integrity, signature, duplicate, predecessor, and approval checks
- **THEN** the high-side service marks the package ready for Pulp import

#### Scenario: Missing approval evidence
- **WHEN** a package lacks required approval metadata
- **THEN** the high-side service rejects the package before Pulp import

### Requirement: Pulp import orchestration
The high-side service SHALL invoke Pulp import for validated transfer packages and track task progress through completion or failure.

#### Scenario: Import completes
- **WHEN** Pulp completes an import task successfully
- **THEN** the system records imported repository versions and creates an import receipt for the transfer batch

#### Scenario: Import fails
- **WHEN** Pulp reports an import failure
- **THEN** the system records failure details and MUST NOT mark the batch as publication-ready

### Requirement: Controlled publication
The high-side service SHALL publish imported repository snapshots only after successful validation, import, and operator promotion.

#### Scenario: Promote imported batch
- **WHEN** an operator promotes a successfully imported batch
- **THEN** the high-side service publishes the corresponding repository versions to configured internal endpoints

#### Scenario: Supersede previous publication
- **WHEN** a newer snapshot is promoted for a repository
- **THEN** the high-side service records the previous publication as superseded while retaining rollback metadata

### Requirement: Import receipt export
The high-side service SHALL generate an import receipt that can be carried back to the low side for reconciliation.

#### Scenario: Generate receipt after publication
- **WHEN** a batch is imported and published
- **THEN** the high-side service generates a receipt with batch identifier, imported snapshot identifiers, validation results, publication endpoints, timestamps, and signature
