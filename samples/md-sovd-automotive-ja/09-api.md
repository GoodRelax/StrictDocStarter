# SOVD API 契約 仕様 (HTTP API Contract)

**Grammar**: sovd-grammar.sgra
**UID**: DOC-SOVD-API
**Version**: 1.0

本書は SOVD の **外部 HTTP API 契約** である。 SOVD クライアント (OEM クラウド・整備
ツール・車載アプリ) との **約束** であり、 連携相手は原則本書だけを見れば実装できる。

- 認証: `Authorization: Bearer <JWT>` (03-auth)。 通信は TLS 1.3 (AUTH-L1-005)。
- データモデル: ASAM SOVD v1.0 Part 2 準拠の JSON。
- 各 API は実現する要求へ `Satisfies` 関係でトレースする。
- METHOD / PATH / SCOPE / RESPONSE はデータ宣言、 **STATEMENT は EARS による振る舞い契約**
  (Ubiquitous=常時 / Event=正常系 / Unwanted=異常系) で記述する。

## 認証 (Authentication)

**Type**: SECTION

### アクセストークン発行 (OAuth2 PKCE)

**Type**: API
**UID**: API-001
**METHOD**: POST
**PATH**: /auth/token

**Statement**:

- (Event) クライアントが有効な認可コードと code_verifier を送信したとき、 本 API は
  JWT アクセストークン (exp / scope / sub を含む) を発行すること。
- (Unwanted) もし code_verifier が一致しない場合、 本 API は認証を拒否し、 トークンを
  発行しないこと。

**RESPONSE**: 200 OK
{"access_token": "<JWT>", "token_type": "Bearer", "expires_in": 1800, "scope": "read:did read:dtc"}

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-001`
  **Role**: `Satisfies`

### トークン失効

**Type**: API
**UID**: API-002
**METHOD**: POST
**PATH**: /auth/revoke

**Statement**:

- (Event) クライアントが失効要求を送信したとき、 本 API は対象アクセストークンを
  失効させること。
- (Unwanted) もし失効済みトークンで以後アクセスした場合、 システムは 401 を返すこと。

**RESPONSE**: 200 OK

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-009`
  **Role**: `Satisfies`

## データアクセス (Data Access)

**Type**: SECTION

### 単一 DID の読み出し

**Type**: API
**UID**: API-003
**METHOD**: GET
**PATH**: /components/{ecu}/data/{did}
**SCOPE**: read:did

**Statement**:

- (Ubiquitous) 本 API は read:did スコープを要求すること。
- (Event) 認可済みクライアントが本 API を呼んだとき、 当該 DID の現在値を ASAM SOVD
  JSON で返すこと。 例: `GET /components/engine/data/rpm`。
- (Unwanted) もし未認証の場合、 本 API は 401 を返すこと。
- (Unwanted) もしスコープが不足する場合、 本 API は 403 を返すこと。
- (Unwanted) もし指定 DID が存在しない場合、 本 API は 404 を返すこと。

**RESPONSE**: 200 OK
{"did": "0xF40C", "name": "rpm", "value": 824, "unit": "1/min"}

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L1-001`
  **Role**: `Satisfies`

### 周期データストリーム (SSE)

**Type**: API
**UID**: API-004
**METHOD**: GET
**PATH**: /components/{ecu}/data/stream
**SCOPE**: read:did

**Statement**:

- (Ubiquitous) 本 API は read:did スコープを要求すること。
- (Event) クライアントが DID リストを購読したとき、 本 API は Server-Sent Events で
  周期的に値を配信すること。

**RESPONSE**: 200 OK (text/event-stream)
data: {"did":"0xF40C","value":824}

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L1-002`
  **Role**: `Satisfies`

## 故障診断 (DTC)

**Type**: SECTION

### DTC リスト取得

**Type**: API
**UID**: API-005
**METHOD**: GET
**PATH**: /components/{ecu}/faults
**SCOPE**: read:dtc

**Statement**:

- (Ubiquitous) 本 API は read:dtc スコープを要求すること。
- (Event) クライアントがステータスマスクを指定して呼んだとき、 本 API は該当する DTC
  一覧を JSON で返すこと。

**RESPONSE**: 200 OK
[{"code": "P0301", "status": "confirmed"}]

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-001`
  **Role**: `Satisfies`

### フリーズフレーム取得

**Type**: API
**UID**: API-006
**METHOD**: GET
**PATH**: /components/{ecu}/faults/{code}/freeze-frame
**SCOPE**: read:dtc

**Statement**:

- (Ubiquitous) 本 API は read:dtc スコープを要求すること。
- (Event) クライアントが呼んだとき、 本 API は指定 DTC の発生時スナップショット (DID 値) を
  返すこと。
- (Unwanted) もし指定 DTC が記録されていない場合、 本 API は 404 を返すこと。

**RESPONSE**: 200 OK
{"code": "P0301", "frame": {"rpm": 3200, "coolant": 95}}

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-002`
  **Role**: `Satisfies`

### DTC クリア

**Type**: API
**UID**: API-007
**METHOD**: DELETE
**PATH**: /components/{ecu}/faults/{code}
**SCOPE**: write:dtc

**Statement**:

- (Ubiquitous) 本 API は write:dtc スコープを要求すること。
- (Event) 車速が 0 km/h のときにクライアントが呼んだとき、 本 API は対象 DTC をクリアし
  204 を返すこと。
- (Unwanted) もし車速が 0 km/h でない場合、 本 API は 409 Conflict を返し、 DTC を
  クリアしないこと。

**RESPONSE**: 204 No Content / 409 Conflict (vehicle moving)

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-003`
  **Role**: `Satisfies`

## ソフトウェア更新 (OTA)

**Type**: SECTION

### 更新パッケージ投入

**Type**: API
**UID**: API-008
**METHOD**: POST
**PATH**: /updates
**SCOPE**: write:swupdate

**Statement**:

- (Ubiquitous) 本 API は write:swupdate スコープを要求すること。
- (Event) 署名付きパッケージが投入されたとき、 本 API は要求を受理して更新処理
  (ダウンロード → 署名検証 → 適用) を開始し、 202 Accepted を返すこと。
- (Unwanted) もしスコープが不足する場合、 本 API は 403 を返すこと。
- 署名検証はダウンロード後の非同期フェーズで行い、 失敗時は更新を Failed とする
  (GET /updates/progress で観測。 同期エラーは返さない)。

**RESPONSE**: 202 Accepted
{"update_id": "u-123", "state": "Downloading"}

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-001`
  **Role**: `Satisfies`

### 更新進捗ストリーム (SSE)

**Type**: API
**UID**: API-009
**METHOD**: GET
**PATH**: /updates/progress

**Statement**:

- (Event) 更新が進行中にクライアントが購読したとき、 本 API は各 ECU の進捗 (0..100%) と
  現フェーズを Server-Sent Events で配信すること。

**RESPONSE**: 200 OK (text/event-stream)
data: {"ecu":"engine","phase":"Verifying","percent":40}

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-006`
  **Role**: `Satisfies`

### ロールバック

**Type**: API
**UID**: API-010
**METHOD**: POST
**PATH**: /updates/rollback
**SCOPE**: write:swupdate

**Statement**:

- (Ubiquitous) 本 API は write:swupdate スコープを要求すること。
- (Event) クライアントが呼んだとき、 本 API は前バージョンへロールバックし 202 を返すこと。
- (State) ロールバックを実行している間、 システムは新規の更新・書込系操作を受け付けないこと。

**RESPONSE**: 202 Accepted
{"state": "RolledBack"}

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-005`
  **Role**: `Satisfies`
