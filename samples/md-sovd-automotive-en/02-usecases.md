# SOVD Use Cases

**Grammar**: sovd-grammar.sgra
**UID**: DOC-SOVD-USECASES
**Version**: 1.0

This document defines the **use cases** of the SOVD vehicle diagnostics system (usage
scenarios in which an actor uses the system to achieve a goal). **A UC here is the parent
of the requirements.** The domain requirements in `01-stakeholder-requirements.md` point
at a UC via `Parent`, and an acceptance test (the AT series in `10-test-spec.md`)
verifies the UC.

**Distinguishing requirements from use cases (ISO/IEC/IEEE 29148 / A-SPICE):** a "condition the
system must satisfy" is a requirement (EARS, `01-stakeholder-requirements.md`), whereas
"how an actor uses it" belongs in this document (scenarios). 29148 treats a use case as a
technique for expressing stakeholder requirements and derives the system requirements from
it, so the lines run requirement -> UC (derivation) and acceptance test -> UC
(verification). **`Parent` always runs from the concrete to the abstract.**

**Actors**

| Actor                   | RBAC role       | Description / main concern                                                                                                                        |
| ----------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Mechanic                | `Mechanic`      | Diagnoses the vehicle remotely from the field or the workshop. Performs data reads and DTC retrieval / clearing.                                  |
| OEM engineer            | `OEMEngineer`   | In addition to all diagnostic functions, can access DIDs containing personal data and perform OTA updates.                                        |
| Fleet operator          | `FleetOperator` | Remotely monitors the status of many vehicles in bulk (mainly read).                                                                              |
| OEM backend             | (system)        | External system responsible for token issuance, revocation-list distribution, update-package signing / distribution, and DTC master provisioning. |
| Attacker (threat actor) | (none)          | Attempts spoofing, eavesdropping, and tampering. The target defended against by authentication, authorization, and cryptography (UC-001).         |

**Use case diagram (actors and use cases)**

**This figure lives in its own document** -> [LINK: DOC-FIG-USECASE-MAP]

UC-001 is the "authentication / authorization foundation" that all other UCs presuppose.
Attacker threats (spoofing, etc.) are defended in UC-001, and the OEM backend supplies the
trust anchor for tokens, revocation, and signatures.

**Use case list (from UC to the requirements derived from it)**

| UC     | Use case                               | Primary actor              | Requirements derived from it |
| ------ | -------------------------------------- | -------------------------- | ---------------------------- |
| UC-001 | Remote authenticated diagnostic access | Mechanic / OEM engineer    | AUTH-L0-001 to 006           |
| UC-002 | Remote read of vehicle data            | Mechanic / OEM / Fleet     | DATA-L0-001 to 005           |
| UC-003 | Fault diagnostics (retrieve / clear)   | Mechanic / OEM engineer    | DTC-L0-001 to 003 / 005      |
| UC-004 | OTA remote software update             | OEM engineer / OEM backend | SWU-L0-001 to 008            |

**All of those requirements live in `01-stakeholder-requirements.md`.** The L1 and lower
requirements of each domain document grow from there.

**The four hang together as one thread.** Something goes wrong on the vehicle, a stakeholder
authenticates remotely (UC-001), and the system decides the authorization scope for their role.
The stakeholder then reads vehicle data (UC-002) or retrieves fault codes (UC-003) to find the
cause, and where needed clears a fault code (UC-003) or updates the software remotely (UC-004).
This presumes the vehicle can reach the cloud through its TCU and that the stakeholder holds
valid credentials. The vehicle's problem gets settled without a workshop visit - that is what
`SYS-L0-001` means by "provision".

**There is no kite-level use case that wraps the others.** Rolling the four into one only
restates the thread above and adds a level for nothing. This document stays at sea level (the
height at which one user goal completes). `SYS-L0-001` and the thread above carry the whole
picture.

## UC-001 Authentication & Authorization

**Type**: SECTION

### Remote authenticated diagnostic access by a mechanic

**Type**: REQUIREMENT
**UID**: UC-001
**TYPE**: UseCase
**ASIL**: QM
**LAYER**: L0_Stakeholder

**Statement**:

**Actors:** Mechanic (primary), Driver, OEM backend (token issuance), SOVD system.

**Preconditions:** The mechanic holds valid credentials, and the vehicle is reachable remotely.

**Main success scenario:**

1. The vehicle fails and the warning lamp lights up.
2. The driver asks a mechanic for remote diagnostics.
3. The mechanic authenticates with the SOVD client (OAuth 2.0 PKCE).
4. The system issues an access token (JWT).
5. The mechanic requests a diagnostic resource with the Bearer token attached.
6. The system verifies the token and scope, and grants access within the authorized range.

**Postconditions:** The mechanic can access vehicle diagnostics within the authorized scope.

**Alternative flows:** Unauthenticated -> denied with 401. Insufficient scope -> 403. Revoked token -> 401.

**VERIFICATION**: A GET of a diagnostic resource by an authenticated client returns HTTP 200 and the target
data can be retrieved.

**Relations**:

- **Type**: `Parent`
  **ID**: `SYS-L0-001`

## UC-002 Vehicle Data Access

**Type**: SECTION

### Remote read of vehicle data

**Type**: REQUIREMENT
**UID**: UC-002
**TYPE**: UseCase
**ASIL**: QM
**LAYER**: L0_Stakeholder

**Statement**:

**Actors:** Mechanic / OEM engineer (primary), SOVD system.

**Preconditions:** Authenticated and holding the read:did scope.

**Main success scenario:**

1. The mechanic wants to check the vehicle's current state (odometer, voltage, each ECU's temperature, etc.).
2. The mechanic specifies the target DID and requests a read.
3. The system verifies the scope.
4. The system resolves the DID to the responsible ECU and translates it into a UDS ReadDataByIdentifier.
5. The ECU returns the value.
6. The system converts it into ASAM SOVD JSON and returns it to the mechanic.

**Postconditions:** The mechanic can understand the vehicle data.

**Alternative flows:** A Mechanic accessing a personal-data DID -> 403. Periodic subscription, snapshot, and
bulk transfer follow the same authorization flow.

**VERIFICATION**: A representative set of DIDs can be retrieved by an authorized client, and unauthorized items are not returned.

**Relations**:

- **Type**: `Parent`
  **ID**: `SYS-L0-001`

## UC-003 Fault Diagnostics (DTC)

**Type**: SECTION

### Fault diagnostics (retrieve / clear)

**Type**: REQUIREMENT
**UID**: UC-003
**TYPE**: UseCase
**ASIL**: QM
**LAYER**: L0_Stakeholder

**Statement**:

**Actors:** Mechanic (primary), SOVD system.

**Preconditions:** Authenticated and holding the read:dtc (retrieve) / write:dtc (clear) scope.

**Main success scenario:**

1. The mechanic wants to investigate the fault cause of a vehicle whose warning lamp is lit.
2. The mechanic requests the list of fault codes (DTCs).
3. The system aggregates each ECU's DTCs via UDS 0x19 and returns them with their status.
4. The mechanic identifies the cause and performs the repair.
5. After the repair, the mechanic requests clearing of the target DTC.
6. The system confirms the vehicle speed is zero and clears it via UDS 0x14.

**Postconditions:** The fault codes are retrieved and (if stationary) cleared.

**Alternative flows:** Clearing while the vehicle is moving -> denied with 409. Freeze-frame retrieval follows the same flow.

**VERIFICATION**: Representative DTCs can be retrieved together with their status (active/pending/confirmed/permanent).

**Relations**:

- **Type**: `Parent`
  **ID**: `SYS-L0-001`

## UC-004 Software Update (OTA)

**Type**: SECTION

### OTA remote software update

**Type**: REQUIREMENT
**UID**: UC-004
**TYPE**: UseCase
**ASIL**: QM
**LAYER**: L0_Stakeholder

**Statement**:

**Actors:** OEM engineer / OEM backend (primary), Driver, SOVD system.

**Preconditions:** A signed update package is prepared, and the vehicle can receive the update.

**Main success scenario:**

1. The OEM wants to distribute a defect-fix software to the vehicle.
2. The OEM backend distributes the signed update package.
3. The system downloads the package.
4. The system verifies the signature.
5. The system confirms the driving state (stationary, shift in Park, parking brake) and writes to the inactive side.
6. The new version boots via the bootloader switch, and the progress is notified to the driver.

**Postconditions:** The ECU runs on the new software version.

**Alternative flows:** Signature verification failure -> discard. While moving -> writing is deferred. Write failure -> rollback to the previous version.

**VERIFICATION**: Distribution -> application -> progress check of a signed package can be performed as a
single sequence, and after application it boots on the new version.

**Relations**:

- **Type**: `Parent`
  **ID**: `SYS-L0-001`
