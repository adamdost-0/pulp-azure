## ADDED Requirements

### Requirement: Parity Azure deployment shape
The system SHALL provide low-side and high-side deployments with matching Azure resource roles for container hosting, storage, container registry, secrets, identity, diagnostics, private networking, and scheduling where the target cloud supports those services.

#### Scenario: Deploy low-side service
- **WHEN** the low-side deployment is applied in Azure Commercial
- **THEN** it provisions the service using Azure Container Apps, Azure Storage, Azure Container Registry, Key Vault, managed identity, private networking, diagnostics, and scheduler integration

#### Scenario: Deploy high-side service
- **WHEN** the high-side deployment is applied in Azure Government Secret
- **THEN** it provisions the same service roles using government cloud endpoints and private access only

### Requirement: No public high-side dependencies
The high-side deployment MUST NOT require public internet, public package registries, public container registries, public DNS resolvers, or public service endpoints at runtime.

#### Scenario: High-side runtime starts
- **WHEN** high-side Container Apps start
- **THEN** all images are pulled from private high-side Azure Container Registry and all service calls use private high-side endpoints

#### Scenario: Public dependency configured
- **WHEN** a high-side deployment references a public registry or public endpoint
- **THEN** deployment validation MUST fail before resources are promoted

### Requirement: Digest-pinned image mirroring
The release process SHALL publish a bill of materials for all required container images and mirror them into high-side Azure Container Registry using digest-pinned references.

#### Scenario: Mirror service image
- **WHEN** a service image is approved for release
- **THEN** the release process records its digest and mirrors it to high-side Azure Container Registry before high-side deployment

#### Scenario: Mutable tag reference
- **WHEN** high-side deployment configuration references a mutable image tag without a digest
- **THEN** deployment validation MUST reject the configuration

### Requirement: Managed identity and private secrets
The deployment SHALL use managed identity for Azure service access and Key Vault references for secrets in both low-side and high-side environments.

#### Scenario: Access storage
- **WHEN** the service accesses Azure Storage
- **THEN** it authenticates with managed identity and narrow-scope RBAC rather than embedded connection strings

#### Scenario: Resolve upstream entitlement
- **WHEN** the low-side service needs a repository entitlement credential
- **THEN** it retrieves the credential through Key Vault-backed configuration without logging the secret value

### Requirement: Required compliance controls
The deployment SHALL disable public network access for supported PaaS services, require TLS 1.2 or higher, enable diagnostic settings, apply required compliance tags, and support customer-managed keys where applicable.

#### Scenario: Provision storage
- **WHEN** Azure Storage is provisioned for the service
- **THEN** public network access is disabled, TLS 1.2 or higher is required, diagnostics are enabled, CMK is configured when required, and compliance tags are applied
