# SOVD Stakeholder Requirements

**Grammar**: sovd-grammar.sgra \
**UID**: DOC-SOVD-STAKEHOLDER \
**Version**: 1.0

This document defines the **stakeholder requirements (L0)** of the SOVD vehicle diagnostics system in EARS notation.
With the top-level requirement SYS-L0-001 at its apex, the requirements of each functional domain (authentication / data / DTC / OTA)
converge toward it. Each domain connects to SYS-L0-001 through a domain (aggregate) requirement (AUTH/DATA/DTC/SWU-L0-000), and the individual functional requirements are laid out in parallel directly beneath it. For background, see `00-overview.md`; for actors and usage scenarios (use cases), see
`02-usecases.md`; for the system requirements (L1) and below of each domain, refer to the respective domain document.

**Distinction between requirements and use cases (IEEE 29148 / A-SPICE):** This document deals with "the conditions the system must satisfy"
(requirements, EARS). "How actors use it" (use cases, scenarios) is
separated into `02-usecases.md`, where each UC realizes a requirement of this document via Parent, and acceptance tests
verify the UC.

## 0. Top-Level Requirement (System Goal)

**Type**: SECTION

### Remote diagnostics and updates of vehicles by authorized parties

**Type**: REQUIREMENT \
**UID**: SYS-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder

**Statement**: The SOVD remote diagnostics system shall provide an integrated mechanism that allows mechanics, OEM engineers, and fleet operators
to remotely and safely diagnose and update target vehicles within their authorized scope.

**VERIFICATION**: The four primary use cases (authenticated access, data read, DTC diagnostics, OTA update) can be executed remotely by authorized
parties, and unauthorized access is rejected.

### Concurrent access by multiple parties

**Type**: REQUIREMENT \
**UID**: SYS-L0-002 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SYS-L0-001`

**Statement**: The system shall be able to process remote diagnostic access from multiple authorized parties concurrently at the vehicle gateway.

**Rationale**: Assuming fleet operations and diagnostics from multiple sites, the system-wide concurrent access capability is required at the top level (the specific concurrent-connection limit is specified in a domain requirement, e.g., DATA-L2-008).

## Authentication & Authorization

**Type**: SECTION

### Authentication and authorization domain

**Type**: REQUIREMENT \
**UID**: AUTH-L0-000 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SYS-L0-001`

**Statement**: The system shall provide authentication, authorization, channel protection, and auditing for remote SOVD clients as a domain, so that only authorized parties can access diagnostics and updates.

**Rationale**: A domain requirement that aggregates the individual authentication and authorization functions (providing access, restricting privileges, maintaining confidentiality, rejecting unauthenticated access, standards compliance, auditing). Each function is laid out in parallel directly beneath it.

### Provision of authenticated diagnostic access

**Type**: REQUIREMENT \
**UID**: AUTH-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `AUTH-L0-000`

**Statement**: When a mechanic requests diagnostic access via authentication from a remote SOVD client,
the system shall provide access to the target vehicle's diagnostic data within the authorized scope.

**VERIFICATION**: A GET on a diagnostic resource with an authenticated client returns HTTP 200, and the target data
can be retrieved.

### Restriction of diagnostic privileges by role

**Type**: REQUIREMENT \
**UID**: AUTH-L0-002 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `AUTH-L0-000`

**Statement**: The system shall restrict the available diagnostic functions (read / write) according to the user's role
(mechanic / OEM engineer / fleet operator).

**Rationale**: Excessive privilege grants directly lead to misuse and abuse of safety-related operations.

**VERIFICATION**: In accordance with the per-role permitted-operations matrix, out-of-privilege operation requests are rejected with HTTP 403.

### Confidentiality of credentials

**Type**: REQUIREMENT \
**UID**: AUTH-L0-003 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `AUTH-L0-000`

**Statement**: The system shall not leak the credentials used for authenticating diagnostic access (passwords / tokens /
certificates) to third parties, either in transit on the channel or at rest in storage.

**Rationale**: SOVD is HTTP-based, and the risk of data leakage before authentication and authorization is higher than with conventional UDS.

**VERIFICATION**: Confirm that all diagnostic communication is encrypted with TLS and that stored credentials are not in plaintext.

### Rejection of unauthenticated access

**Type**: REQUIREMENT \
**UID**: AUTH-L0-004 \
**TYPE**: Restriction \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `AUTH-L0-000`

**Statement**: If an unauthenticated client invokes a SOVD service, then the system shall
not perform any processing, including reading diagnostic data, and shall reject the request.

**Rationale**: Prevents data leakage before authentication and authorization. SOVD has a higher risk of direct external connection than UDS.

**VERIFICATION**: Every endpoint invocation without a token returns HTTP 401.

### Compliance with ASAM SOVD authentication requirements

**Type**: REQUIREMENT \
**UID**: AUTH-L0-005 \
**TYPE**: Constraint \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `AUTH-L0-000`

**Statement**: The system's authentication and authorization functions shall comply with the authentication requirements of
ASAM SOVD v1.0 (Part 1: Common).

### Audit trail of authentication and authorization

**Type**: REQUIREMENT \
**UID**: AUTH-L0-006 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `AUTH-L0-000`

**Statement**: The system shall record access attempts related to authentication and authorization (successes and failures) as a traceable audit trail.

**Rationale**: For after-the-fact tracing (forensics) of spoofing and unauthorized access. The foundation for the threat countermeasures in §1.2.

## Vehicle Data Access

**Type**: SECTION

### Vehicle data access domain

**Type**: REQUIREMENT \
**UID**: DATA-L0-000 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SYS-L0-001`

**Statement**: The system shall provide, as a domain, the capability for authorized parties to remotely read vehicle data (current state, periodic, snapshot, large-volume).

**Rationale**: A domain requirement that aggregates the individual data-access functions (one-shot read, periodic, snapshot, bulk, privilege separation).

### Provision of remote read of vehicle state data

**Type**: REQUIREMENT \
**UID**: DATA-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DATA-L0-000`

**Statement**: When a mechanic or OEM engineer requests the current vehicle state (odometer,
battery voltage, per-ECU temperatures, etc.) from a remote SOVD client, the system shall return
that data within the authorized scope.

**VERIFICATION**: A representative set of DIDs can be retrieved with an authorized client, and unauthorized items are not returned.

### Periodic data sampling

**Type**: REQUIREMENT \
**UID**: DATA-L0-002 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DATA-L0-000`

**Statement**: The system shall allow continuous acquisition of a user-specified DID list at a period of 100 ms to 60 s.

### Bulk acquisition of a snapshot

**Type**: REQUIREMENT \
**UID**: DATA-L0-003 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DATA-L0-000`

**Statement**: The system shall allow acquisition of a snapshot of all DID values of the vehicle at a specific point in time in a single transaction.

### Resumable transfer of large data with interruption support

**Type**: REQUIREMENT \
**UID**: DATA-L0-004 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DATA-L0-000`

**Statement**: The system shall be able to transfer data on the order of several hundred MB, such as logging data and recorded frames, in an interruptible and resumable manner.

### Separation of read and write privileges

**Type**: REQUIREMENT \
**UID**: DATA-L0-005 \
**TYPE**: Restriction \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DATA-L0-000`

**Statement**: If a write of a DID value (equivalent to writeDataByIdentifier) is requested with a read-only token,
then the system shall reject it.

**Rationale**: Read and write are managed under separate scopes to prevent erroneous writes and abuse. In this sample the DID write API is out of scope, so this requirement is retained as a guard policy for future write operations and is assured through review.

## Fault Diagnostics (DTC)

**Type**: SECTION

### Fault diagnostics domain

**Type**: REQUIREMENT \
**UID**: DTC-L0-000 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SYS-L0-001`

**Statement**: The system shall provide, as a domain, remote acquisition and clearing of fault codes (DTCs) and freeze frames.

**Rationale**: A domain requirement that aggregates the individual DTC functions (acquisition, freeze frame, clearing, compliance).

### Remote acquisition of fault codes

**Type**: REQUIREMENT \
**UID**: DTC-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-000`

**Statement**: When a mechanic requests the list of fault codes from a remote SOVD client, the system shall
return all DTCs recorded in the vehicle together with their status masks.

**VERIFICATION**: Representative DTCs can be retrieved with their status (active/pending/confirmed/permanent).

### Acquisition of freeze frame data

**Type**: REQUIREMENT \
**UID**: DTC-L0-002 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-000`

**Statement**: The system shall allow acquisition of the snapshot at the time of DTC occurrence (freeze frame).

### Clearing of DTCs

**Type**: REQUIREMENT \
**UID**: DTC-L0-003 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-000`

**Statement**: When a mechanic requests clearing of a target DTC after completing a repair, the system shall clear it after verifying the write:dtc scope.

**Rationale**: Prevents concealment of fault information through unauthorized or erroneous DTC clearing.

### Prohibition of DTC clearing while moving

**Type**: REQUIREMENT \
**UID**: DTC-L0-004 \
**TYPE**: Restriction \
**ASIL**: C \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-003`

**Statement**: If the vehicle speed is not 0 km/h, then the system shall reject the DTC clear request.

**Rationale**: Because clearing a safety-related DTC while the vehicle is moving affects the functional safety assessment during driving.

### Compliance with ISO 14229 semantics

**Type**: REQUIREMENT \
**UID**: DTC-L0-005 \
**TYPE**: Constraint \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-000`

**Statement**: The system's DTC functions shall preserve the semantics of ISO 14229-1 (UDS) Service 0x19 (ReadDTCInformation) and
0x14 (ClearDiagnosticInformation).

### Additional privilege for clearing safety-related DTCs

**Type**: REQUIREMENT \
**UID**: DTC-L0-006 \
**TYPE**: Restriction \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-003`

**Statement**: If clearing of a safety-related DTC is requested, then the system shall require an additional privilege (the write:dtc:safety scope) in addition to the normal write:dtc.

**Rationale**: Because unauthorized or erroneous clearing of safety-related DTCs (DTCs assigned ASIL B to D) affects the functional safety assessment, a higher privilege is required. It is carved out as a constraint independent of the clearing function (DTC-L0-003).

## Software Update (OTA)

**Type**: SECTION

### Software update domain

**Type**: REQUIREMENT \
**UID**: SWU-L0-000 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SYS-L0-001`

**Statement**: The system shall provide, as a domain, OTA updates of vehicle ECU software (distribution, verification, application, rollback, progress visualization).

**Rationale**: A domain requirement that aggregates the individual OTA functions.

### Provision of remote software update via OTA

**Type**: REQUIREMENT \
**UID**: SWU-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SWU-L0-000`

**Statement**: When the OEM wants to distribute defect-fix software, the system shall allow updating the vehicle ECU software over OTA (wireless).

**VERIFICATION**: Distribution of a signed package through to application can be performed as one sequence, and after application the new version boots.

### Tamper detection (signature verification)

**Type**: REQUIREMENT \
**UID**: SWU-L0-002 \
**TYPE**: Functional \
**ASIL**: D \
**CAL**: CAL4 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SWU-L0-000`

**Statement**: The system shall verify the digital signature of the update package and detect tampering and forgery.

**Rationale**: Injection of unauthorized firmware directly leads to loss of function of safety-related ECUs (safety), and the vehicle becomes
an attack target (security). Therefore the highest assurance level is applied for both safety and security.

### Rollback support

**Type**: REQUIREMENT \
**UID**: SWU-L0-003 \
**TYPE**: Functional \
**ASIL**: C \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SWU-L0-000`

**Statement**: If an anomaly is detected after an update, then the system shall be able to roll back to the immediately preceding version automatically or manually.

### Prohibition of updates while moving

**Type**: REQUIREMENT \
**UID**: SWU-L0-004 \
**TYPE**: Restriction \
**ASIL**: D \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SWU-L0-000`

**Statement**: If the vehicle is IG-ON and the vehicle speed > 0, then the system shall not start ECU flash writing.

**Rationale**: Because an interrupted write or a behavior change while moving directly leads to loss of safety functions.

### Update duration

**Type**: REQUIREMENT \
**UID**: SWU-L0-005 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SWU-L0-000`

**Statement**: The system's average update time per ECU (verification + write + reboot) shall be within 5 minutes.

### Non-application of tampered packages

**Type**: REQUIREMENT \
**UID**: SWU-L0-006 \
**TYPE**: Restriction \
**ASIL**: D \
**CAL**: CAL4 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SWU-L0-000`

**Statement**: If signature verification of an update package fails, then the system shall not install the package and shall discard it.

**Rationale**: A safety reaction triggered by the detection result of SWU-L0-002 (tamper detection). Detection and the "do not apply" reaction are
separated, and each is verified independently.

### Allowance of downloads while moving

**Type**: REQUIREMENT \
**UID**: SWU-L0-007 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SWU-L0-000`

**Statement**: WHILE the vehicle is moving, the system shall still be able to download an update package.

**Rationale**: Writing (flashing) is prohibited while moving (SWU-L0-004), but downloading does not affect safety,
so it is allowed, enabling an immediate transition to writing after stopping.

### Visualization of update progress

**Type**: REQUIREMENT \
**UID**: SWU-L0-008 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SWU-L0-000`

**Statement**: The system shall allow the driver to check the progress of an OTA update on the SOVD client.
