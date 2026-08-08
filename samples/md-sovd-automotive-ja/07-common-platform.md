# SOVD 共通プラットフォーム 要求仕様 (Common Platform / Shared Components)

**Grammar**: sovd-grammar.sgra \
**UID**: DOC-SOVD-PLATFORM \
**Version**: 1.0

本書は、 複数の機能ドメイン (03-auth / 04-data-access / 05-dtc-diagnostics /
06-sw-update) が **共通で再利用する** ゲートウェイ基盤のユニット要求を集約する。
各機能ドメインの要求 (L2_ECU_SW) は、 ここに定義する基盤ユニットへ収束 (N→1) する。

**依存方向:** 機能 → 基盤 の一方向。 これにより「ある機能が別の機能 (兄弟) の文書に
依存する」 不健全な結合を避け、 共有部品の責務と所在を一箇所に固定する
(Clean Architecture の依存方向・SoC/SRP、 A-SPICE のプラットフォーム要素管理に対応)。

共有の前付け (用語・表記規約・ASIL/CAL の使い分け) は `00-overview.md` を参照。

**コンポーネント収束図 (機能 → 共通基盤)**

**この図は 16 行を超えるので別文書にしてある** → [LINK: DOC-FIG-PLATFORM-SHARED]

注: TlsTerminator は全機能ドメインの外部通信を終端するが、 TLS 要求は代表として
03-auth (AUTH-L1-005 / AUTH-L2-004) に集約されるため、 図では Auth からの依存のみを
示す。 なお 06-sw-update は独自の更新系ユニット群を持つため、 共通基盤への収束は
図に現れない。

## 共通プラットフォーム ユニット (Shared Platform Units)

**Type**: SECTION

### UdsClient ユニット (共有 UDS トランスポート)

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

**Statement**: UdsClient ユニットは、 ISO 14229-1 準拠の UDS フレーム送受信を担い、 タイムアウト・
リトライ・NRC ハンドリングを提供すること。

**Rationale**: ゲートウェイ内の共有 UDS トランスポート。 データアクセスの ReadDataByIdentifier
ブリッジ (DATA-L2-002) と、 DTC の 0x19 読出 (DTC-L2-001) ・0x14 クリア (DTC-L2-003)
の双方から再利用される。 1 つのユニットが複数ドメインの上位要求を実現する収束 (N→1)。

### ScopeAuthorizer ユニット (共有 認可)

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

**Statement**: ScopeAuthorizer ユニットは、 (required_scope, token_scopes) を入力として許可または
拒否を返すこと。 拒否したとき、 ScopeAuthorizer ユニットは、 理由コード
(insufficient_scope / expired 等) を返すこと。

**Rationale**: 認証 (AUTH-L2-003) と車両データアクセス (DATA-L2-006) の双方でスコープ検証に
再利用される共有ユニット。 1 つの下位要求が複数ドメインの上位要求を実現する収束 (N→1)。

### TlsTerminator ユニット (共有 TLS 終端)

**Type**: REQUIREMENT \
**UID**: PLAT-L3-003 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `AUTH-L2-004`

**Statement**: TlsTerminator ユニットは、 OpenSSL ベースの TLS 終端を提供すること。
起動したとき、 TlsTerminator ユニットは、 信頼ストアをロードすること。

**Rationale**: 全機能ドメインの外部通信を終端する横断的なセキュリティ基盤。 明示的な TLS 要求は
03-auth (AUTH-L1-005 / AUTH-L2-004) にあり、 本ユニットがそれを実装する。

**VERIFICATION**: ハンドシェイク失敗時に、 上位へエラーイベントが通知されること。

### JsonSerializer ユニット (共有 応答エンコード)

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

**Statement**: JsonSerializer ユニットは、 診断データ (DID 値: 整数・浮動小数・文字列・バイト列、
DTC 等) を ASAM SOVD JSON 形式に変換すること。

**Rationale**: SOVD の JSON 応答エンコードを担う共有ユニット。 データアクセス (DATA-L2-002) と
DTC (DTC-L2-001) の応答生成から再利用される。
