# SOVD Common Platform / Shared Components Requirements

**Grammar**: sovd-grammar.sgra \
**UID**: DOC-SOVD-PLATFORM \
**Version**: 1.0

This document consolidates the unit requirements for the gateway platform that
multiple functional domains (03-auth / 04-data-access / 05-dtc-diagnostics /
06-sw-update) **reuse in common**. The requirements of each functional domain
(L2_ECU_SW) converge (N->1) onto the platform units defined here.

**Dependency direction:** one-way, function -> platform. This avoids the unhealthy
coupling where "one function depends on the document of another function (a
sibling)", and fixes the responsibility and location of shared parts in a single
place (corresponding to the dependency direction / SoC/SRP of Clean Architecture
and the platform-element management of A-SPICE).

For the shared front matter (terminology, notation, the ASIL/CAL split), see
`00-overview.md`.

**Component convergence diagram (function -> common platform)**

**This figure lives in its own document** -> [LINK: DOC-FIG-PLATFORM-SHARED]

Note: TlsTerminator terminates the external communication of all functional
domains, but because the TLS requirements are consolidated, as the representative,
in 03-auth (AUTH-L1-005 / AUTH-L2-004), the diagram shows only the dependency from
Auth. Also, because 06-sw-update has its own group of update-related units, its
convergence onto the common platform does not appear in the diagram.

## Shared Platform Units

**Type**: SECTION

### UdsClient unit (shared UDS transport)

**Type**: REQUIREMENT \
**UID**: PLAT-L3-001 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `DATA-L2-002`
- **Type**: `Parent` \
  **ID**: `DTC-L2-001`
- **Type**: `Parent` \
  **ID**: `DTC-L2-003`

**Statement**: The UdsClient unit shall handle the sending and receiving of ISO 14229-1-compliant
UDS frames and shall provide timeout, retry, and NRC handling.

**Rationale**: The shared UDS transport within the gateway. Reused both by the data-access
ReadDataByIdentifier bridge (DATA-L2-002) and by the DTC 0x19 read (DTC-L2-001)
and 0x14 clear (DTC-L2-003). One unit realizes the higher-level requirements of
multiple domains - convergence (N->1).

### ScopeAuthorizer unit (shared authorization)

**Type**: REQUIREMENT \
**UID**: PLAT-L3-002 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `AUTH-L2-003`
- **Type**: `Parent` \
  **ID**: `DATA-L2-006`

**Statement**: The ScopeAuthorizer unit shall take (required_scope, token_scopes) as input and
return allow/deny, and on denial shall return a reason code (insufficient_scope /
expired, etc.).

**Rationale**: A shared unit reused for scope verification both in authentication (AUTH-L2-003)
and in vehicle data access (DATA-L2-006). One lower-level requirement realizes the
higher-level requirements of multiple domains - convergence (N->1).

### TlsTerminator unit (shared TLS termination)

**Type**: REQUIREMENT \
**UID**: PLAT-L3-003 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `AUTH-L2-004`

**Statement**: The TlsTerminator unit shall provide OpenSSL-based TLS termination and shall load
the trust store at startup.

**Rationale**: A cross-cutting security foundation that terminates the external communication of
all functional domains. The explicit TLS requirements are in 03-auth (AUTH-L1-005 /
AUTH-L2-004), and this unit implements them.

**VERIFICATION**: On a handshake failure, an error event is notified to the upper layer.

### JsonSerializer unit (shared response encoding)

**Type**: REQUIREMENT \
**UID**: PLAT-L3-004 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `DATA-L2-002`
- **Type**: `Parent` \
  **ID**: `DTC-L2-001`

**Statement**: The JsonSerializer unit shall convert diagnostic data (DID values: integers,
floating-point numbers, strings, byte arrays, DTCs, etc.) into the ASAM SOVD JSON
format.

**Rationale**: A shared unit responsible for SOVD JSON response encoding. Reused from the response
generation of data access (DATA-L2-002) and DTC (DTC-L2-001).
