# SOVD Diagnostic Trouble Codes (DTC) Requirements Specification (Diagnostic Trouble Codes)

**Grammar**: sovd-grammar.sgra
**UID**: DOC-SOVD-DTC
**Version**: 1.0

This document defines the read and clear requirements for SOVD **fault diagnostics
(DTC and freeze frame)** at L1 through L3. Internally, SOVD wraps the ISO 14229
(UDS) 0x19 family (ReadDTCInformation) / 0x14 (ClearDiagnosticInformation). For
stakeholder requirements (L0) and use cases see `01-stakeholder-requirements.md`;
for the shared front matter see `00-overview.md`; authentication and
authorization assume `03-auth.md`.

**Reading** DTCs is not a safety function, so it is **ASIL=QM** as a rule. However,
because **"clearing a safety-related DTC while the vehicle is moving" could affect
the functional-safety assessment**, the running-state guard on a clear is set to
**ASIL C**. The privilege over "who may clear" is a security matter, so a **CAL**
is assigned.

## L1 - System Requirements

**Type**: SECTION

**L1 representative sequence: reading DTCs, and a clear gated by running state**

The read bridges to UDS 0x19 and the clear bridges to UDS 0x14. The clear is
executed only when vehicle speed can be confirmed to be zero; while the vehicle is
moving it is rejected with 409.

**This figure lives in its own document** -> [LINK: DOC-FIG-DTC-GUARD]

### DTC list retrieval API

**Type**: REQUIREMENT
**UID**: DTC-L1-001
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L1_System

**Statement**: The vehicle shall provide GET /components/{ecu}/faults and allow filtering by
status mask (active/pending/confirmed/permanent).

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L0-001`

### Freeze frame retrieval API

**Type**: REQUIREMENT
**UID**: DTC-L1-002
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L1_System

**Statement**: At GET /components/{ecu}/faults/{code}/freeze-frame, the vehicle shall return, in
JSON, the freeze frame (the DID value snapshot at the time of occurrence) for the
specified DTC.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L0-002`

### DTC clear API

**Type**: REQUIREMENT
**UID**: DTC-L1-003
**TYPE**: Functional
**ASIL**: QM
**CAL**: CAL2
**LAYER**: L1_System

**Statement**: The vehicle shall allow clearing a DTC via DELETE /components/{ecu}/faults/{code}
and shall require the write:dtc scope.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L0-003`

### Zero-speed check before clear

**Type**: REQUIREMENT
**UID**: DTC-L1-004
**TYPE**: Functional
**ASIL**: C
**LAYER**: L1_System

**Statement**: When a DTC clear request is received, the vehicle shall read the current vehicle speed (DID 0xF40D) and, if it is not 0 km/h, return HTTP 409 Conflict. If the vehicle speed cannot be obtained, the vehicle shall also fail safe and reject the clear without executing it.

**VERIFICATION**: A clear request at vehicle speed > 0 shall be rejected with 409, and shall succeed
only at vehicle speed 0.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L0-004`

### Bulk clear-all DTC API

**Type**: REQUIREMENT
**UID**: DTC-L1-005
**TYPE**: Functional
**ASIL**: QM
**CAL**: CAL2
**LAYER**: L1_System

**Statement**: The vehicle shall allow clearing all DTCs in bulk via DELETE
/components/{ecu}/faults (the zero-speed condition is the same as DTC-L1-004).

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L0-003`
- **Type**: `Parent`
  **ID**: `DTC-L0-004`

### DTC response time

**Type**: REQUIREMENT
**UID**: DTC-L1-006
**TYPE**: Non-Functional
**ASIL**: QM
**LAYER**: L1_System

**Statement**: The vehicle's DTC list retrieval shall respond within 1 second at the 95th
percentile.

**VERIFICATION**: Under representative load, the p95 of DTC list retrieval shall be within 1 second.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-001`

### DTC occurrence history

**Type**: REQUIREMENT
**UID**: DTC-L1-007
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L1_System

**Statement**: The vehicle shall retain the most recent 1,024 entries of DTC occurrence history
(roughly equivalent to 24 hours) and make them retrievable at GET
/components/{ecu}/faults/history.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L0-001`

### Privilege verification for safety-related DTC clear

**Type**: REQUIREMENT
**UID**: DTC-L1-008
**TYPE**: Functional
**ASIL**: QM
**CAL**: CAL2
**LAYER**: L1_System

**Statement**: If clearing a safety-related DTC is requested, then the vehicle shall verify the
write:dtc:safety scope and return HTTP 403 if it is missing.

**VERIFICATION**: Clearing a safety-related DTC shall be 403 with a token holding only write:dtc, and
shall be permitted when accompanied by write:dtc:safety.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L0-006`

## L2 - ECU Software Requirements

**Type**: SECTION

### UDS 0x19 ReadDTCInformation bridge

**Type**: REQUIREMENT
**UID**: DTC-L2-001
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L2_ECU_SW

**Statement**: When a SOVD GET /faults request is received, the gateway ECU shall issue UDS
Service 0x19 SubFunction 0x02 (reportDTCByStatusMask) to the responsible group of
ECUs and return the aggregated result as JSON.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-001`

### Freeze frame retrieval

**Type**: REQUIREMENT
**UID**: DTC-L2-002
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L2_ECU_SW

**Statement**: The gateway ECU shall retrieve the freeze frame using UDS 0x19 SubFunction 0x04
(reportDTCSnapshotRecordByDTCNumber).

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-002`

### UDS 0x14 ClearDiagnosticInformation

**Type**: REQUIREMENT
**UID**: DTC-L2-003
**TYPE**: Functional
**ASIL**: QM
**CAL**: CAL2
**LAYER**: L2_ECU_SW

**Statement**: In response to a DTC clear request, the gateway ECU shall issue UDS Service 0x14 to
the target ECU after the vehicle speed check (DTC-L2-004) succeeds.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-003`

### VehicleSpeedGuard

**Type**: REQUIREMENT
**UID**: DTC-L2-004
**TYPE**: Functional
**ASIL**: C
**LAYER**: L2_ECU_SW

**Statement**: Before every DTC clear request (whether individual or bulk), the gateway ECU shall
verify, via the VehicleSpeedGuard, that vehicle speed == 0 within 100 ms.

**VERIFICATION**: Confirm that when vehicle speed > 0 the clear is not executed (blocked by the
guard).

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-004`

### DTC master table

**Type**: REQUIREMENT
**UID**: DTC-L2-005
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L2_ECU_SW

**Statement**: The gateway ECU shall hold the OEM-provided DTC master table (code -> description /
recommended action) in NVRAM and include it in the API response.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-001`

### DTC history circular buffer

**Type**: REQUIREMENT
**UID**: DTC-L2-006
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L2_ECU_SW

**Statement**: The gateway ECU shall hold up to 1,024 entries of DTC history in a circular buffer
(one entry being timestamp + DTC + status mask).

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-007`

### UDS timeout

**Type**: REQUIREMENT
**UID**: DTC-L2-007
**TYPE**: Non-Functional
**ASIL**: QM
**LAYER**: L2_ECU_SW

**Statement**: The gateway ECU's UDS request P2 timeout shall be 50 ms and the P2* timeout shall
be 500 ms.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-006`

### NRC handling

**Type**: REQUIREMENT
**UID**: DTC-L2-008
**TYPE**: Constraint
**ASIL**: QM
**LAYER**: L2_ECU_SW

**Statement**: If a UDS Negative Response Code (NRC) is received, then the gateway ECU shall
return HTTP 502 to the SOVD client with the NRC code included in the JSON body.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L2-001`

## L3 - Unit / Software Component Requirements

**Type**: SECTION

### DtcParser unit

**Type**: REQUIREMENT
**UID**: DTC-L3-001
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L3_Unit

**Statement**: The DtcParser unit shall parse the binary response of UDS 0x19 and return a list of
(dtc_code, status_byte).

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L2-001`

### FreezeFrameDecoder unit

**Type**: REQUIREMENT
**UID**: DTC-L3-002
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L3_Unit

**Statement**: The FreezeFrameDecoder unit shall convert the UDS 0x19/0x04 freeze frame payload
into a list of (did, value).

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L2-002`

### SpeedReader unit

**Type**: REQUIREMENT
**UID**: DTC-L3-003
**TYPE**: Functional
**ASIL**: C
**LAYER**: L3_Unit

**Statement**: The SpeedReader unit shall, as an ASIL C certified real-time task, update DID
0xF40D on a 10 ms cycle and provide the latest value via const access.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L2-004`

### DtcHistoryStore unit

**Type**: REQUIREMENT
**UID**: DTC-L3-004
**TYPE**: Functional
**ASIL**: QM
**LAYER**: L3_Unit

**Statement**: The DtcHistoryStore unit shall be implemented as a lock-free ring buffer (Single
Producer Multiple Consumer) and allocate a size of 1,024 in NVRAM.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L2-006`

### NVRAM wear protection

**Type**: REQUIREMENT
**UID**: DTC-L3-005
**TYPE**: Constraint
**ASIL**: QM
**LAYER**: L3_Unit

**Statement**: NVRAM writes of DTC history shall use a wear-leveling algorithm (e.g.,
log-structured) and avoid consecutive writes to the same sector.

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L3-004`
