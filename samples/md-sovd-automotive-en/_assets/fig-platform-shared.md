# Figure - shared units of the common platform

**UID**: DOC-FIG-PLATFORM-SHARED

```mermaid
flowchart TB
    subgraph FEAT["Functional domains (L2 requirements)"]
        A["03 Auth"]
        D["04 Data Access"]
        T["05 DTC"]
    end
    subgraph PLAT["Common platform (L3 shared units)"]
        TLS["TlsTerminator<br/>PLAT-L3-003"]
        SCOPE["ScopeAuthorizer<br/>PLAT-L3-002"]
        UDS["UdsClient<br/>PLAT-L3-001"]
        JSON["JsonSerializer<br/>PLAT-L3-004"]
    end
    A --> TLS
    A --> SCOPE
    D --> SCOPE
    D --> UDS
    D --> JSON
    T --> UDS
    T --> JSON
```
