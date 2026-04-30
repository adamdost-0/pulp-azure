## ADDED Requirements

### Requirement: Parity Azure deployment shape
The system SHALL provide low-side and high-side deployments with matching Azure resource roles for container hosting, storage, PostgreSQL-compatible state, container registry, secrets, identity, diagnostics, private networking, and scheduling where the target cloud supports those services.

#### Scenario: Deploy low-side service
- **WHEN** the low-side deployment is applied in Azure Commercial
- **THEN** it provisions the service using Azure Container Apps, Azure Storage, PostgreSQL-compatible database, Azure Container Registry, Key Vault, managed identity, private networking, diagnostics, and Container Apps jobs

#### Scenario: Deploy high-side service
- **WHEN** the high-side deployment is applied in Azure Government Secret
- **THEN** it provisions the same service roles using government cloud endpoints and private access only

### Requirement: No public high-side dependencies
The high-side deployment MUST NOT require public internet, public package registries, public container registries, public DNS resolvers, or public service endpoints at runtime.

#### Scenario: High-side runtime starts
- **WHEN** high-side Container Apps start
- **THEN** all images are pulled from private high-side Azure Container Registry and all service calls use private high-side endpoints

#### Scenario: Public dependency configured
- **WHEN** a high-side deployment references a public registry, public DNS resolver, public service endpoint, or internet-based package source
- **THEN** deployment validation MUST fail before resources are promoted

### Requirement: Tag-plus-digest image mirroring
The release process SHALL publish a bill of materials for production releases and mirror required container images into high-side Azure Container Registry using tag-plus-digest references.

#### Scenario: Mirror service image
- **WHEN** a service image is approved for production release
- **THEN** the release process records its source image, target ACR image, tag, digest, approval state, and import status before high-side deployment

#### Scenario: Mutable tag-only reference
- **WHEN** high-side deployment configuration references an image tag without a digest
- **THEN** deployment validation MUST reject the configuration

### Requirement: Managed identity and private secrets
The deployment SHALL use managed identity for Azure service access and Key Vault references for secrets in both low-side and high-side environments.

#### Scenario: Access storage
- **WHEN** the service accesses Azure Storage
- **THEN** it authenticates with managed identity and narrow-scope RBAC rather than embedded connection strings

#### Scenario: Resolve low-side source credential
- **WHEN** the low-side service needs a configured repository credential
- **THEN** it retrieves the credential through Key Vault-backed configuration without logging the secret value

### Requirement: Required compliance controls
The deployment SHALL disable public network access for supported PaaS services, require TLS 1.2 or higher, enable diagnostic settings, apply required compliance tags, and configure customer-managed keys for required data-at-rest services.

#### Scenario: Provision storage
- **WHEN** Azure Storage is provisioned for the service
- **THEN** public network access is disabled, TLS 1.2 or higher is required, diagnostics are enabled, CMK is configured when required, and compliance tags are applied

#### Scenario: Provision PostgreSQL-compatible state
- **WHEN** PostgreSQL-compatible state storage is provisioned for the service
- **THEN** it is reachable only over private networking, configured with required encryption controls, protected by least-privilege access, and included in backup/restore planning

### Requirement: Local-to-Azure authorization gate
The system SHALL require the local Pulp capability harness to pass before Phase 1 Azure deployment begins.

#### Scenario: Local harness blocks Azure deployment
- **WHEN** the local low-side/high-side Pulp capability harness has not passed end-to-end
- **THEN** Phase 1 Azure deployment work is not authorized to begin
