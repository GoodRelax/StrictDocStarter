# SOVD Test Results (Test Results / Execution Records)

**Grammar**: sovd-grammar.sgra \
**UID**: DOC-SOVD-TESTRESULTS \
**Version**: 1.0

This document is the **execution record** of each test in `10-test-spec.md`. Each result traces
to the corresponding test specification via the ``ResultOf`` relation. Since the specification is
stable while results grow with each execution (1 specification : N results), they are separated
into a distinct document. Each result's TITLE begins with the verdict, so OK/NG is visible at a
glance even in the tree.

Summary (aggregate): 75 entries total - PASS 66 / CONDITIONAL 5 / FAIL 1 / SKIP 3 (an example
execution record for this sample). Since 1 scenario = 1 test = 1 result, "one related test PASSed
while another FAILed/SKIPped" can be expressed individually (e.g. for PackageDownloader, resume=PASS
but duplicate-request=FAIL).

## Unit Test Results (Unit)

**Type**: SECTION

### [PASS] TokenVerifier - a valid JWT is accepted

**Type**: TEST_RESULT \
**UID**: TR-UT-001 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-001` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, gcc + unity)

### [PASS] TokenVerifier - a tampered signature is rejected

**Type**: TEST_RESULT \
**UID**: TR-UT-002 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-002` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] TokenVerifier - an expired token is rejected

**Type**: TEST_RESULT \
**UID**: TR-UT-003 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-003` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] TokenCache - evicts the oldest entry on capacity overflow

**Type**: TEST_RESULT \
**UID**: TR-UT-004 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-004` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] TokenCache - hits while retained

**Type**: TEST_RESULT \
**UID**: TR-UT-005 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-005` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] ScopeAuthorizer - decides scope sufficiency/insufficiency

**Type**: TEST_RESULT \
**UID**: TR-UT-006 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-006` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] TlsTerminator - loads the trust store at startup

**Type**: TEST_RESULT \
**UID**: TR-UT-007 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-007` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL mock)

### [PASS] TlsTerminator - notifies a failure event on an invalid certificate

**Type**: TEST_RESULT \
**UID**: TR-UT-008 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-008` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL mock)

### [PASS] UdsClient - returns a normal response

**Type**: TEST_RESULT \
**UID**: TR-UT-009 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-009` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, UDS stub)

### [PASS] UdsClient - times out after retries when there is no response

**Type**: TEST_RESULT \
**UID**: TR-UT-010 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-010` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, UDS stub)

### [PASS] UdsClient - propagates the NRC

**Type**: TEST_RESULT \
**UID**: TR-UT-011 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-011` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, UDS stub)

### [PASS] JsonSerializer - converts each type to ASAM JSON

**Type**: TEST_RESULT \
**UID**: TR-UT-012 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-012` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] DidResolver - resolves a known DID

**Type**: TEST_RESULT \
**UID**: TR-UT-013 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-013` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] DidResolver - an unknown DID is an error

**Type**: TEST_RESULT \
**UID**: TR-UT-014 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-014` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] DataCache - hits within TTL

**Type**: TEST_RESULT \
**UID**: TR-UT-015 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-015` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] DataCache - misses after TTL elapses

**Type**: TEST_RESULT \
**UID**: TR-UT-016 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-016` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] DtcParser - parses a single DTC

**Type**: TEST_RESULT \
**UID**: TR-UT-017 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-017` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] DtcParser - an empty response yields an empty list

**Type**: TEST_RESULT \
**UID**: TR-UT-018 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-018` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] FreezeFrameDecoder - decodes to (did,value)

**Type**: TEST_RESULT \
**UID**: TR-UT-019 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-019` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [PASS] SpeedReader - reflects the latest vehicle speed within 10ms

**Type**: TEST_RESULT \
**UID**: TR-UT-020 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-020` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL (ASIL C task timing)

### [PASS] DtcHistoryStore - overwrites the oldest entry on capacity overflow

**Type**: TEST_RESULT \
**UID**: TR-UT-021 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-021` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

### [CONDITIONAL] DtcHistoryStore - stays consistent under concurrent reads

**Type**: TEST_RESULT \
**UID**: TR-UT-022 \
**RESULT**: CONDITIONAL
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-022` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, TSan)

**REMARK**: A single producer PASSes. Boundary coverage of high-load concurrent reads is incomplete.

### [PASS] PackageDownloader - resumes from a mid-transfer failure and completes

**Type**: TEST_RESULT \
**UID**: TR-UT-023 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-023` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, network sim)

### [FAIL] PackageDownloader - does not issue duplicate requests at the backoff limit

**Type**: TEST_RESULT \
**UID**: TR-UT-024 \
**RESULT**: FAIL
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-024` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, network sim)

**REMARK**: Duplicate requests are occasionally observed when the backoff limit (30s) is reached. Under fix
(re-test required).

### [PASS] SignatureVerifier - a valid ECDSA signature is true

**Type**: TEST_RESULT \
**UID**: TR-UT-025 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-025` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL)

### [PASS] SignatureVerifier - a valid RSA-PSS signature is true

**Type**: TEST_RESULT \
**UID**: TR-UT-026 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-026` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL)

### [PASS] SignatureVerifier - tampering is false

**Type**: TEST_RESULT \
**UID**: TR-UT-027 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-027` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL)

### [PASS] FlashSectorWriter - a normal write does pre-erase + CRC match

**Type**: TEST_RESULT \
**UID**: TR-UT-028 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-028` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL (flash emulator)

### [PASS] FlashSectorWriter - a CRC mismatch is an ERROR

**Type**: TEST_RESULT \
**UID**: TR-UT-029 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-029` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL (flash emulator)

### [PASS] VehicleStateMonitor - permits only when all conditions hold

**Type**: TEST_RESULT \
**UID**: TR-UT-030 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `UT-030` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL (ASIL D, signal injection)

## Integration Test Results (Integration)

**Type**: SECTION

### [PASS] Authentication flow integration (token -> verify -> scope)

**Type**: TEST_RESULT \
**UID**: TR-IT-001 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-001` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] DID read bridge integration (SOVD -> UDS -> JSON)

**Type**: TEST_RESULT \
**UID**: TR-IT-002 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-002` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] DTC read bridge integration (UDS 0x19 -> Parser)

**Type**: TEST_RESULT \
**UID**: TR-IT-003 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-003` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] DTC clear - blocked by the guard while the vehicle is moving

**Type**: TEST_RESULT \
**UID**: TR-IT-004 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-004` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench (speed inject)

### [PASS] DTC clear - executed while stationary

**Type**: TEST_RESULT \
**UID**: TR-IT-005 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-005` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] OTA - a normal package passes verification

**Type**: TEST_RESULT \
**UID**: TR-IT-006 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-006` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] OTA - a tampered package is discarded

**Type**: TEST_RESULT \
**UID**: TR-IT-007 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-007` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] OTA flash + emergency abort by the state guard

**Type**: TEST_RESULT \
**UID**: TR-IT-008 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-008` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench (state inject)

### [PASS] The authentication endpoint accepts the request

**Type**: TEST_RESULT \
**UID**: TR-IT-009 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-009` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] The certificate store integrity is verified at startup

**Type**: TEST_RESULT \
**UID**: TR-IT-010 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-010` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] The revocation list is synchronized periodically

**Type**: TEST_RESULT \
**UID**: TR-IT-011 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-011` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] Multiple DIDs are subscribed simultaneously over WebSocket

**Type**: TEST_RESULT \
**UID**: TR-IT-012 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-012` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] A bulk download is returned with gzip compression

**Type**: TEST_RESULT \
**UID**: TR-IT-013 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-013` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] All DTCs are cleared at once

**Type**: TEST_RESULT \
**UID**: TR-IT-014 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-014` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench (speed inject)

### [PASS] DTC master information is bundled in the response

**Type**: TEST_RESULT \
**UID**: TR-IT-015 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-015` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] Rollback is executed via a bootloader switch

**Type**: TEST_RESULT \
**UID**: TR-IT-016 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-016` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] Progress events are delivered

**Type**: TEST_RESULT \
**UID**: TR-IT-017 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-017` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

### [PASS] After a power loss, it resumes from the last safe state

**Type**: TEST_RESULT \
**UID**: TR-IT-018 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `IT-018` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench (power cut rig)

## System Test Results (System)

**Type**: SECTION

### [PASS] Authenticated data read (end-to-end)

**Type**: TEST_RESULT \
**UID**: TR-ST-001 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `ST-001` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

### [SKIP] Periodic data stream

**Type**: TEST_RESULT \
**UID**: TR-ST-002 \
**RESULT**: SKIP
**Relations**:
- **Type**: `Parent` \
  **ID**: `ST-002` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**REMARK**: Not run, as the environment for long-duration stability testing of SSE/WS is not yet in place.

### [PASS] DTC list retrieval and clear

**Type**: TEST_RESULT \
**UID**: TR-ST-003 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `ST-003` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

### [PASS] OTA update - a normal update boots on the new version

**Type**: TEST_RESULT \
**UID**: TR-ST-004 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `ST-004` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

### [CONDITIONAL] OTA update - keeps the old version on a write failure

**Type**: TEST_RESULT \
**UID**: TR-ST-005 \
**RESULT**: CONDITIONAL
**Relations**:
- **Type**: `Parent` \
  **ID**: `ST-005` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**REMARK**: The automatic rollback on a write failure was confirmed by manual triggering. Full automation is
incomplete.

## Acceptance Test Results (Acceptance)

**Type**: SECTION

### [PASS] Successful authenticated DID read

**Type**: TEST_RESULT \
**UID**: TR-AT-001 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-001` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (SOVD tester)

### [PASS] Rejection of unauthenticated access

**Type**: TEST_RESULT \
**UID**: TR-AT-002 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-002` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

### [PASS] 403 on insufficient scope

**Type**: TEST_RESULT \
**UID**: TR-AT-003 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-003` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

### [PASS] Rejection of a revoked token

**Type**: TEST_RESULT \
**UID**: TR-AT-004 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-004` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

### [PASS] Rejection of DTC clear while the vehicle is moving

**Type**: TEST_RESULT \
**UID**: TR-AT-005 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-005` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (rolling road)

### [PASS] Rejection of a tampered package

**Type**: TEST_RESULT \
**UID**: TR-AT-006 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-006` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

### [PASS] Prohibition of flash writing while the vehicle is moving

**Type**: TEST_RESULT \
**UID**: TR-AT-007 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-007` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (rolling road)

### [CONDITIONAL] Access token expiry

**Type**: TEST_RESULT \
**UID**: TR-AT-008 \
**RESULT**: CONDITIONAL
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-008` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**REMARK**: The default 30 minutes has been confirmed. The boundary case of the 60-minute limit is not yet run.

### [SKIP] Update progress stream (SSE)

**Type**: TEST_RESULT \
**UID**: TR-AT-009 \
**RESULT**: SKIP
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-009` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**REMARK**: Not run, as the SSE test environment is not yet in place.

### [PASS] Remote retrieval of the fault code list

**Type**: TEST_RESULT \
**UID**: TR-AT-010 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-010` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

### [PASS] Freeze frame retrieval

**Type**: TEST_RESULT \
**UID**: TR-AT-011 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-011` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

### [SKIP] Remote sampling of periodic data

**Type**: TEST_RESULT \
**UID**: TR-AT-012 \
**RESULT**: SKIP
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-012` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**REMARK**: Not run, as the SSE/WS environment is not yet in place (same cause as ST-002).

### [PASS] Bulk snapshot retrieval

**Type**: TEST_RESULT \
**UID**: TR-AT-013 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-013` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

### [PASS] Interruptible, resumable transfer of large data

**Type**: TEST_RESULT \
**UID**: TR-AT-014 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-014` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (link drop sim)

### [PASS] Role-based access control (RBAC)

**Type**: TEST_RESULT \
**UID**: TR-AT-015 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-015` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

### [PASS] Can connect over TLS 1.3

**Type**: TEST_RESULT \
**UID**: TR-AT-016 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-016` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (TLS probe)

### [PASS] Rejection of a TLS downgrade

**Type**: TEST_RESULT \
**UID**: TR-AT-017 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-017` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (TLS probe)

### [PASS] Mutual TLS is established (OEM internal)

**Type**: TEST_RESULT \
**UID**: TR-AT-018 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-018` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: OEM lab (mTLS)

### [PASS] An invalid client certificate is rejected

**Type**: TEST_RESULT \
**UID**: TR-AT-019 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-019` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: OEM lab (mTLS)

### [PASS] Remote software update via OTA (use case)

**Type**: TEST_RESULT \
**UID**: TR-AT-020 \
**RESULT**: PASS
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-020` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

### [CONDITIONAL] Rollback to the previous version

**Type**: TEST_RESULT \
**UID**: TR-AT-021 \
**RESULT**: CONDITIONAL
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-021` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**REMARK**: Manual rollback PASSes. The automatic rollback from anomaly detection is not yet automated.

### [CONDITIONAL] Update interruption tolerance (resume from a power loss)

**Type**: TEST_RESULT \
**UID**: TR-AT-022 \
**RESULT**: CONDITIONAL
**Relations**:
- **Type**: `Parent` \
  **ID**: `AT-022` \
  **Role**: `ResultOf`

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype (power cut rig)

**REMARK**: Resume from a power loss during download PASSes. Recovery from a write interruption was confirmed
only for limited cases.
