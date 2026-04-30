## ADDED Requirements

### Requirement: Ubuntu APT source configuration
The system SHALL allow operators to configure low-side Ubuntu public APT/deb repository sources with release, architecture, component, pocket, sync interval, and enabled status.

#### Scenario: Configure Ubuntu 22.04 source
- **WHEN** an operator configures an Ubuntu 22.04 APT source with supported architecture, component, and pocket values
- **THEN** the system persists the source configuration as a first-release-supported source

#### Scenario: Reject non-MVP repository family
- **WHEN** an operator attempts to configure Red Hat, RPM, SUSE, Debian expansion, Ubuntu Pro/ESM, or OCI-in-Pulp content for the first release
- **THEN** the system rejects the source as out of MVP scope

#### Scenario: Disable a source
- **WHEN** an operator disables an Ubuntu APT source
- **THEN** scheduled hydration MUST skip that source until it is enabled again

### Requirement: Scheduled Ubuntu APT hydration
The system SHALL run hydration jobs at configured intervals and orchestrate Pulp sync tasks for enabled Ubuntu APT sources using pinned Pulp 3.x and `pulp_deb` versions.

#### Scenario: Scheduled sync starts
- **WHEN** a configured sync interval elapses for an enabled Ubuntu APT source
- **THEN** the system starts a Pulp sync task and records the hydration run identifier

#### Scenario: Source sync fails
- **WHEN** Pulp reports a failed sync task
- **THEN** the system records the failure details and MUST NOT mark a new snapshot as transfer-eligible

### Requirement: Immutable repository snapshot creation
The system SHALL create or identify an immutable Pulp repository version after each successful Ubuntu APT hydration run.

#### Scenario: Successful sync creates snapshot
- **WHEN** a Pulp sync completes successfully and repository content changes
- **THEN** the system records the resulting Pulp repository version as an immutable snapshot

#### Scenario: No content change
- **WHEN** a Pulp sync completes successfully without content changes
- **THEN** the system records the run outcome without creating a duplicate transfer-eligible snapshot

### Requirement: Snapshot eligibility
The system MUST determine whether an Ubuntu APT repository snapshot is eligible for export based on sync success, content immutability, policy checks, and whether the snapshot has already been included in an approved transfer batch.

#### Scenario: New eligible snapshot
- **WHEN** a repository snapshot passes policy checks and has not been batched
- **THEN** the system marks the snapshot as eligible for transfer batch selection

#### Scenario: Already batched snapshot
- **WHEN** a repository snapshot was already included in an approved transfer batch
- **THEN** the system MUST NOT include it in a new batch unless an operator explicitly creates a replacement batch

### Requirement: Local capability test harness
The system SHALL define a local low-side/high-side Pulp capability harness that proves Ubuntu APT sync, immutable snapshot creation, native export/import, publication, and apt client consumption before Azure deployment begins.

#### Scenario: Local end-to-end test passes
- **WHEN** the local harness runs with a deterministic Ubuntu-style APT fixture and staged transfer bundle
- **THEN** it proves low-side sync, transfer bundle staging, high-side import, high-side publication, and Ubuntu 22.04-compatible apt client consumption without requiring Azure resources
