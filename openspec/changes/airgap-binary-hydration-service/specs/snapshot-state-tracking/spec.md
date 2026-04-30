## ADDED Requirements

### Requirement: Cross-side state model
The system SHALL track repository sources, hydration runs, immutable snapshots, transfer batches, export jobs, media handoff status, high-side imports, publications, and supersession history as explicit state records.

#### Scenario: Track low-side snapshot lifecycle
- **WHEN** a hydration run produces an immutable repository snapshot
- **THEN** the system records the source, snapshot identifier, Pulp repository version, content summary, and eligibility state

#### Scenario: Track high-side import lifecycle
- **WHEN** the high-side service imports a transfer batch
- **THEN** the system records the import result, imported repository versions, validation outcome, and publication readiness

### Requirement: Deterministic identifiers
The system SHALL assign deterministic identifiers to repository snapshots and transfer batches so low-side manifests and high-side import receipts can be reconciled.

#### Scenario: Generate transfer batch identifier
- **WHEN** the low-side service creates a transfer batch
- **THEN** the batch identifier includes or derives from immutable snapshot identifiers and manifest content

#### Scenario: Reconcile import receipt
- **WHEN** the high-side service produces an import receipt for a batch
- **THEN** the receipt references the same transfer batch identifier from the low-side manifest

### Requirement: Operator state visibility
The system SHALL show operators the latest known state for each repository snapshot and transfer batch on both low side and high side.

#### Scenario: View pending snapshots
- **WHEN** an operator requests snapshots pending transfer
- **THEN** the system lists eligible snapshots that have not been included in an approved transfer batch

#### Scenario: View imported batches
- **WHEN** an operator requests high-side import history
- **THEN** the system lists imported batches with validation, import, publication, and supersession status

### Requirement: State transition enforcement
The system MUST enforce valid state transitions for transfer batches and reject duplicate, incomplete, or out-of-order operations.

#### Scenario: Reject duplicate import
- **WHEN** a high-side operator attempts to import a batch that was already successfully imported
- **THEN** the system rejects the duplicate import and preserves the original receipt

#### Scenario: Reject publication before validation
- **WHEN** an operator attempts to publish a batch before manifest validation and Pulp import succeed
- **THEN** the system MUST reject the publication request

### Requirement: Audit history
The system SHALL retain an audit history for state changes, including actor, timestamp, previous state, new state, reason, and related manifest or receipt identifier.

#### Scenario: Approval state recorded
- **WHEN** an operator approves a transfer batch for export
- **THEN** the system records the actor, approval timestamp, prior state, approved state, and batch identifier
