## ADDED Requirements

### Requirement: PostgreSQL-compatible state model
The system SHALL use a PostgreSQL-compatible database to track repository sources, hydration runs, immutable snapshots, transfer batches, export jobs, high-side staging, high-side imports, publications, supersession history, compatibility overrides, and audit events.

#### Scenario: Track low-side snapshot lifecycle
- **WHEN** a hydration run produces an immutable repository snapshot
- **THEN** the system records the source, snapshot identifier, Pulp repository version, content summary, and eligibility state

#### Scenario: Track high-side import lifecycle
- **WHEN** the high-side service imports a transfer batch
- **THEN** the high-side system records the import result, imported repository versions, validation outcome, and publication readiness

### Requirement: High-side authority after transfer
The high-side system SHALL be authoritative for staged, validated, imported, published, rejected, rollback, and supersession states after a transfer bundle reaches the high-side environment.

#### Scenario: High-side state changes do not require low-side reconciliation
- **WHEN** a high-side operator validates, imports, publishes, rejects, or supersedes a transfer batch
- **THEN** the state change is authoritative on the high side and does not require a receipt-driven low-side reconciliation loop

### Requirement: Deterministic identifiers
The system SHALL assign deterministic identifiers to repository snapshots and transfer batches so low-side manifests and high-side staged/imported records can refer to the same batch without a return path.

#### Scenario: Generate transfer batch identifier
- **WHEN** the low-side service creates a transfer batch
- **THEN** the batch identifier includes or derives from immutable snapshot identifiers and manifest content

#### Scenario: Stage transfer batch high-side
- **WHEN** the high-side service stages a transfer batch
- **THEN** the staged record references the transfer batch identifier from the JSON manifest

### Requirement: State transition enforcement
The system MUST enforce valid state transitions and reject duplicate, incomplete, or out-of-order operations.

#### Scenario: Reject duplicate import
- **WHEN** a high-side operator attempts to import a batch that was already successfully imported
- **THEN** the system rejects the duplicate import and preserves the original high-side import state

#### Scenario: Reject publication before validation
- **WHEN** an operator attempts to publish a batch before manifest validation and Pulp import succeed
- **THEN** the system MUST reject the publication request

### Requirement: Audit history
The system SHALL retain append-only audit history for state changes, including actor, timestamp, previous state, new state, reason, related manifest identifier, and privileged override details when applicable.

#### Scenario: Approval state recorded
- **WHEN** an operator approves a transfer batch for export
- **THEN** the system records the actor, approval timestamp, prior state, approved state, and batch identifier

#### Scenario: Compatibility override recorded
- **WHEN** a privileged operator overrides a Pulp or plugin compatibility warning
- **THEN** the system records the actor, timestamp, warning details, justification, and affected transfer batch identifier
