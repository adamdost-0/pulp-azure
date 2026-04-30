## ADDED Requirements

### Requirement: Upstream repository source configuration
The system SHALL allow operators to configure low-side Linux repository sources with distribution, repository family, architecture, component/channel, sync interval, entitlement reference, and enabled status.

#### Scenario: Configure an entitled Red Hat source
- **WHEN** an operator configures a Red Hat repository source with a Key Vault entitlement reference and supported architecture
- **THEN** the system persists the source configuration without storing entitlement secrets in application configuration

#### Scenario: Disable a source
- **WHEN** an operator disables a repository source
- **THEN** scheduled hydration MUST skip that source until it is enabled again

### Requirement: Scheduled hydration
The system SHALL run hydration jobs at configured intervals and orchestrate Pulp sync tasks for enabled repository sources.

#### Scenario: Scheduled sync starts
- **WHEN** a configured sync interval elapses for an enabled source
- **THEN** the system starts a Pulp sync task and records the hydration run identifier

#### Scenario: Source sync fails
- **WHEN** Pulp reports a failed sync task
- **THEN** the system records the failure details and MUST NOT mark a new snapshot as transfer-eligible

### Requirement: Immutable repository snapshot creation
The system SHALL create or identify an immutable Pulp repository version after each successful hydration run.

#### Scenario: Successful sync creates snapshot
- **WHEN** a Pulp sync completes successfully and repository content changes
- **THEN** the system records the resulting Pulp repository version as an immutable snapshot

#### Scenario: No content change
- **WHEN** a Pulp sync completes successfully without content changes
- **THEN** the system records the run outcome without creating a duplicate transfer-eligible snapshot

### Requirement: Snapshot eligibility
The system MUST determine whether a repository snapshot is eligible for export based on sync success, content immutability, policy checks, and whether the snapshot has already been included in an approved transfer batch.

#### Scenario: New eligible snapshot
- **WHEN** a repository snapshot passes policy checks and has not been batched
- **THEN** the system marks the snapshot as eligible for transfer batch selection

#### Scenario: Already batched snapshot
- **WHEN** a repository snapshot was already included in an approved transfer batch
- **THEN** the system MUST NOT include it in a new batch unless an operator explicitly creates a replacement batch
