# SOVD API Contract Specification (HTTP API Contract)

**Grammar**: sovd-grammar.sgra
**UID**: DOC-SOVD-API
**Version**: 1.0

This document is the **external HTTP API contract** of SOVD. It is the **promise** to SOVD
clients (OEM cloud, workshop tools, in-vehicle apps), and in principle an integration
partner can implement against this document alone.

- Authentication: `Authorization: Bearer <JWT>` (03-auth). Communication is TLS 1.3 (AUTH-L1-005).
- Data model: JSON compliant with ASAM SOVD v1.0 Part 2.
- Each API traces to the requirement it realizes via a `Satisfies` relation.
- METHOD / PATH / SCOPE / RESPONSE are data declarations, while **the STATEMENT describes the behavioral contract in EARS**
  (Ubiquitous = always / Event = nominal / Unwanted = off-nominal).

## Authentication

**Type**: SECTION

### Access token issuance (OAuth2 PKCE)

**Type**: API
**UID**: API-001
**METHOD**: POST
**PATH**: /auth/token

**Statement**:

- (Event) When a client sends a valid authorization code and code_verifier, the API shall
  issue a JWT access token (containing exp / scope / sub).
- (Unwanted) If the code_verifier does not match, then the API shall reject authentication and
  shall not issue a token.

**RESPONSE**: 200 OK
{"access_token": "<JWT>", "token_type": "Bearer", "expires_in": 1800, "scope": "read:did read:dtc"}

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-001`
  **Role**: `Satisfies`

### Token revocation

**Type**: API
**UID**: API-002
**METHOD**: POST
**PATH**: /auth/revoke

**Statement**:

- (Event) When a client sends a revocation request, the API shall revoke the target access
  token.
- (Unwanted) If access is subsequently attempted with a revoked token, then the system shall return 401.

**RESPONSE**: 200 OK

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-009`
  **Role**: `Satisfies`

## Data Access

**Type**: SECTION

### Read of a single DID

**Type**: API
**UID**: API-003
**METHOD**: GET
**PATH**: /components/{ecu}/data/{did}
**SCOPE**: read:did

**Statement**:

- (Ubiquitous) The API shall require the read:did scope.
- (Event) When an authorized client calls the API, it shall return the current value of that
  DID as ASAM SOVD JSON. Example: `GET /components/engine/data/rpm`.
- (Unwanted) If unauthenticated, then the API shall return 401.
- (Unwanted) If the scope is insufficient, then the API shall return 403.
- (Unwanted) If the specified DID does not exist, then the API shall return 404.

**RESPONSE**: 200 OK
{"did": "0xF40C", "name": "rpm", "value": 824, "unit": "1/min"}

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L1-001`
  **Role**: `Satisfies`

### Periodic data stream (SSE)

**Type**: API
**UID**: API-004
**METHOD**: GET
**PATH**: /components/{ecu}/data/stream
**SCOPE**: read:did

**Statement**:

- (Ubiquitous) The API shall require the read:did scope.
- (Event) When a client subscribes to a DID list, the API shall deliver values periodically
  via Server-Sent Events.

**RESPONSE**: 200 OK (text/event-stream)
data: {"did":"0xF40C","value":824}

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L1-002`
  **Role**: `Satisfies`

## Fault Diagnostics (DTC)

**Type**: SECTION

### DTC list retrieval

**Type**: API
**UID**: API-005
**METHOD**: GET
**PATH**: /components/{ecu}/faults
**SCOPE**: read:dtc

**Statement**:

- (Ubiquitous) The API shall require the read:dtc scope.
- (Event) When a client calls with a status mask specified, the API shall return the matching
  list of DTCs as JSON.

**RESPONSE**: 200 OK
[{"code": "P0301", "status": "confirmed"}]

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-001`
  **Role**: `Satisfies`

### Freeze-frame retrieval

**Type**: API
**UID**: API-006
**METHOD**: GET
**PATH**: /components/{ecu}/faults/{code}/freeze-frame
**SCOPE**: read:dtc

**Statement**:

- (Ubiquitous) The API shall require the read:dtc scope.
- (Event) When a client calls it, the API shall return the snapshot at the time of occurrence
  (DID values) for the specified DTC.
- (Unwanted) If the specified DTC is not recorded, then the API shall return 404.

**RESPONSE**: 200 OK
{"code": "P0301", "frame": {"rpm": 3200, "coolant": 95}}

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-002`
  **Role**: `Satisfies`

### DTC clear

**Type**: API
**UID**: API-007
**METHOD**: DELETE
**PATH**: /components/{ecu}/faults/{code}
**SCOPE**: write:dtc

**Statement**:

- (Ubiquitous) The API shall require the write:dtc scope.
- (Event) When a client calls it while the vehicle speed is 0 km/h, the API shall clear the
  target DTC and return 204.
- (Unwanted) If the vehicle speed is not 0 km/h, then the API shall return 409 Conflict and
  shall not clear the DTC.

**RESPONSE**: 204 No Content / 409 Conflict (vehicle moving)

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-003`
  **Role**: `Satisfies`

## Software Update (OTA)

**Type**: SECTION

### Update package submission

**Type**: API
**UID**: API-008
**METHOD**: POST
**PATH**: /updates
**SCOPE**: write:swupdate

**Statement**:

- (Ubiquitous) The API shall require the write:swupdate scope.
- (Event) When a signed package is submitted, the API shall accept the request, start the
  update processing (download -> signature verification -> application), and return 202 Accepted.
- (Unwanted) If the scope is insufficient, then the API shall return 403.
- Signature verification is performed in an asynchronous phase after download, and on failure the update is marked Failed
  (observed via GET /updates/progress; no synchronous error is returned).

**RESPONSE**: 202 Accepted
{"update_id": "u-123", "state": "Downloading"}

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-001`
  **Role**: `Satisfies`

### Update progress stream (SSE)

**Type**: API
**UID**: API-009
**METHOD**: GET
**PATH**: /updates/progress

**Statement**:

- (Event) When a client subscribes while an update is in progress, the API shall deliver each
  ECU's progress (0..100%) and the current phase via Server-Sent Events.

**RESPONSE**: 200 OK (text/event-stream)
data: {"ecu":"engine","phase":"Verifying","percent":40}

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-006`
  **Role**: `Satisfies`

### Rollback

**Type**: API
**UID**: API-010
**METHOD**: POST
**PATH**: /updates/rollback
**SCOPE**: write:swupdate

**Statement**:

- (Ubiquitous) The API shall require the write:swupdate scope.
- (Event) When a client calls it, the API shall roll back to the previous version and return 202.
- (State) While a rollback is being executed, the system shall not accept new update or write operations.

**RESPONSE**: 202 Accepted
{"state": "RolledBack"}

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-005`
  **Role**: `Satisfies`
