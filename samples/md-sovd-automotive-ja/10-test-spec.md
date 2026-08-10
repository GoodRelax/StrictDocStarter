# SOVD テスト仕様 (Test Specification / Strategy)

**Grammar**: sovd-grammar.sgra
**UID**: DOC-SOVD-TESTSPEC
**Version**: 1.0

本書は SOVD の **テスト仕様** である。 V 字の右側として各レベル (単体 / 結合 / システム /
受入) のテストを定義し、 検証対象へ ``Verifies`` 関係でトレースする。

**粒度ルール: 1 振る舞い = 1 シナリオ = 1 テスト = 1 判定。** これにより「関連する 1 つが
PASS、 1 つが FAIL」 を個別に記録できる (Cucumber/ISTQB の test case 粒度)。 同一振る舞いの
データ違いだけは ``Scenario Outline`` + ``Examples`` で 1 テストに集約する。 各テストは
具体的な入力・期待結果を持つ実行可能な Gherkin で記述する。 テスト結果は
`11-test-results.md` に分離 (1 仕様 : N 実行)。

## 5.1 テスト戦略 (Test Strategy)

**Type**: SECTION

| レベル | 対象成果物 | Verifies 先 | 方針 |
|---|---|---|---|
| 単体 (Unit) | コンポーネント / クラス (08) | COMPONENT | 各コンポの振る舞いごとに 1 シナリオ。 分岐・境界網羅 |
| 結合 (Integration) | モジュール間 (L2) | L2 要求 | 主要ブリッジ / フローの結合点 |
| システム (System) | システム要求 (L1) | L1 要求 | 主要機能の end-to-end |
| 受入 (Acceptance) | ステークホルダ / API (L0 / 09) | L0 要求 / API | 全ユースケース |

固定データ: DID ``0xF40C`` = エンジン回転数 (rpm, Engine ECU addr ``0x10``)、
``0xF40D`` = 車速、 DTC ``P0301`` = 失火。

## 5.2 単体テスト (Unit Tests)

**Type**: SECTION

### TokenVerifier — 有効な JWT は受理される

**Type**: TEST
**UID**: UT-001
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: TokenVerifier の JWT 検証
  Scenario: 有効な JWT は valid=true
    Given OEM 公開鍵が信頼ストアにある
    And exp=現在+30分 / scope="read:did" / 正しい署名 の JWT
    When verify(jwt) を呼ぶ
    Then valid=true、 claims.scope に "read:did" を含む
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-005`
  **Role**: `Verifies`

### TokenVerifier — 署名改ざんは拒否される

**Type**: TEST
**UID**: UT-002
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: TokenVerifier の JWT 検証
  Scenario: 署名改ざんは valid=false
    Given ペイロードを 1 バイト書き換え署名と不整合にした JWT
    When verify(jwt) を呼ぶ
    Then valid=false、 reason="invalid_signature"
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-005`
  **Role**: `Verifies`

### TokenVerifier — 期限切れは拒否される

**Type**: TEST
**UID**: UT-003
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: TokenVerifier の JWT 検証
  Scenario: 期限切れは valid=false
    Given exp=現在-1分 の JWT
    When verify(jwt) を呼ぶ
    Then valid=false、 reason="expired"
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-005`
  **Role**: `Verifies`

### TokenCache — 容量超過で最古を追い出す

**Type**: TEST
**UID**: UT-004
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: TokenCache の LRU
  Scenario: 1025 件目で最古が落ちる
    Given 空の TokenCache (上限 1024 件 / 256 KB)
    When 相異なるトークンを 1025 件 put する
    Then 件数は 1024、 1 件目は get で miss、 メモリは 256 KB 以内
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-006`
  **Role**: `Verifies`

### TokenCache — 保持中はヒットする

**Type**: TEST
**UID**: UT-005
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: TokenCache の参照
  Scenario: put 済みトークンは hit
    Given トークン T を put 済み
    When get(T) を呼ぶ
    Then 検証済み結果を hit で返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-006`
  **Role**: `Verifies`

### ScopeAuthorizer — スコープ充足/不足の判定

**Type**: TEST
**UID**: UT-006
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: ScopeAuthorizer の認可判定
  Scenario Outline: 充足は許可・不足は理由付き拒否
    Given required=<required> / token_scopes=<scopes>
    When authorize(required, scopes) を呼ぶ
    Then 結果は <decision> (拒否時 reason=<reason>)

    Examples:
      | required  | scopes            | decision | reason             |
      | read:did  | read:did read:dtc | allow    | -                  |
      | read:did  | read:dtc          | deny     | insufficient_scope |
      | write:dtc | read:dtc          | deny     | insufficient_scope |
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-002`
  **Role**: `Verifies`

### TlsTerminator — 起動時に信頼ストアをロードする

**Type**: TEST
**UID**: UT-007
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: TlsTerminator の信頼ストア
  Scenario: 起動でロードされる
    Given 信頼ストアに CA 証明書が 1 件ある
    When loadTrustStore() (起動) を実行する
    Then ロード済み CA 数 = 1
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-001`
  **Role**: `Verifies`

### TlsTerminator — 不正証明書で失敗イベントを通知する

**Type**: TEST
**UID**: UT-008
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: TlsTerminator のハンドシェイク
  Scenario: 期限切れ証明書は失敗通知
    Given 期限切れのサーバ証明書
    When TLS 1.3 ハンドシェイクを試みる
    Then 失敗し、 上位へ "handshake_failed" を通知する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-001`
  **Role**: `Verifies`

### UdsClient — 正常応答を返す

**Type**: TEST
**UID**: UT-009
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: UdsClient の送受信
  Scenario: 正常応答
    Given スタブ ECU が 0x22 F40C に 0x62 F40C 0338 を返す
    When readDataByIdentifier(0x10, 0xF40C) を呼ぶ
    Then 戻り値のバイト列は 0338 (=824)
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-003`
  **Role**: `Verifies`

### UdsClient — 無応答はリトライ後タイムアウト

**Type**: TEST
**UID**: UT-010
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: UdsClient のタイムアウト
  Scenario: 無応答
    Given スタブ ECU が応答しない (P2=50ms)
    When send(frame) を呼ぶ
    Then 規定回数リトライ後に Timeout エラーを返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-003`
  **Role**: `Verifies`

### UdsClient — NRC を伝播する

**Type**: TEST
**UID**: UT-011
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: UdsClient の NRC 処理
  Scenario: NRC 0x31
    Given スタブ ECU が NRC 0x31 (requestOutOfRange) を返す
    When send(frame) を呼ぶ
    Then NRC=0x31 を呼び出し元へ伝播する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-003`
  **Role**: `Verifies`

### JsonSerializer — 各型を ASAM JSON へ変換する

**Type**: TEST
**UID**: UT-012
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: JsonSerializer の型変換
  Scenario Outline: 型ごとの出力
    Given 値 <in> (型 <type>)
    When serialize(値) を呼ぶ
    Then 出力 JSON は <out>

    Examples:
      | type   | in        | out    |
      | int    | 824       | 824    |
      | float  | 12.5      | 12.5   |
      | float  | NaN       | null   |
      | float  | Infinity  | null   |
      | bytes  | 0x03 0x38 | "0338" |
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-004`
  **Role**: `Verifies`

### DidResolver — 既知 DID を解決する

**Type**: TEST
**UID**: UT-013
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: DidResolver の解決
  Scenario: 既知 DID
    Given マッピング 0xF40C -> Engine ECU (addr 0x10)
    When resolve(0xF40C) を呼ぶ
    Then addr 0x10 を返す (ハッシュ 1 回, O(1))
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-008`
  **Role**: `Verifies`

### DidResolver — 未知 DID はエラー

**Type**: TEST
**UID**: UT-014
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: DidResolver の解決
  Scenario: 未知 DID
    Given 0x9999 は未登録
    When resolve(0x9999) を呼ぶ
    Then NotFound を返し、 クラッシュしない
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-008`
  **Role**: `Verifies`

### DataCache — TTL 内はヒットする

**Type**: TEST
**UID**: UT-015
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: DataCache の TTL
  Scenario: TTL 内
    Given TTL=100ms に (0xF40C -> 824) を put 済み
    When 50ms 後に get(0xF40C) を呼ぶ
    Then 824 を hit で返す (ECU 通信なし)
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-009`
  **Role**: `Verifies`

### DataCache — TTL 経過でミスする

**Type**: TEST
**UID**: UT-016
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: DataCache の TTL
  Scenario: TTL 経過
    Given TTL=100ms に (0xF40C -> 824) を put 済み
    When 150ms 後に get(0xF40C) を呼ぶ
    Then miss となり ECU へ再取得する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-009`
  **Role**: `Verifies`

### DtcParser — 1 件の DTC を解析する

**Type**: TEST
**UID**: UT-017
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: DtcParser の解析
  Scenario: 1 件
    Given 応答 "59 02 FF 43 01 21 2F" (P0301 / status 0x2F)
    When parse(bytes) を呼ぶ
    Then [(code="P0301", status=0x2F)] を返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-010`
  **Role**: `Verifies`

### DtcParser — 空応答は空リスト

**Type**: TEST
**UID**: UT-018
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: DtcParser の解析
  Scenario: 0 件
    Given DTC 0 件の応答 "59 02 FF"
    When parse(bytes) を呼ぶ
    Then 空リストを返す (エラーにしない)
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-010`
  **Role**: `Verifies`

### FreezeFrameDecoder — (did,value) へ復号する

**Type**: TEST
**UID**: UT-019
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: FreezeFrameDecoder の復号
  Scenario: 復号
    Given 0x19/04 ペイロード (0xF40C=0x0C80, 0xF40D=0x00)
    When decode(payload) を呼ぶ
    Then [(0xF40C, 3200), (0xF40D, 0)] を返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-011`
  **Role**: `Verifies`

### SpeedReader — 最新車速を 10ms 以内に反映する

**Type**: TEST
**UID**: UT-020
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: SpeedReader の周期更新
  Scenario: 最新値
    Given CAN の車速が 0 km/h に変化
    When 10ms 後に currentSpeed() を呼ぶ
    Then 0 km/h を返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-012`
  **Role**: `Verifies`

### DtcHistoryStore — 容量超過で最古を上書きする

**Type**: TEST
**UID**: UT-021
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: DtcHistoryStore のリングバッファ
  Scenario: 上書き
    Given 容量 1024 の空ストア
    When 1025 件 push する
    Then 件数は 1024、 1 件目は read で取得できない
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-013`
  **Role**: `Verifies`

### DtcHistoryStore — 並行読取でも整合する

**Type**: TEST
**UID**: UT-022
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: DtcHistoryStore の並行性
  Scenario: 並行 read
    Given 1 プロデューサが push 中
    When 複数コンシューマが同時に read する
    Then 各 read は破損のない完全なエントリを返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-013`
  **Role**: `Verifies`

### PackageDownloader — 途中失敗から再開して完走する

**Type**: TEST
**UID**: UT-023
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: PackageDownloader の再開
  Scenario: 再開
    Given 3MB (1MB×3)、 2 個目が初回だけ失敗
    When download(url) を呼ぶ
    Then 指数バックオフで再取得し 3MB 完走する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-014`
  **Role**: `Verifies`

### PackageDownloader — バックオフ上限で二重要求しない

**Type**: TEST
**UID**: UT-024
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: PackageDownloader のバックオフ
  Scenario: 二重要求なし
    Given 全チャンクが失敗し続ける
    When download(url) を呼ぶ
    Then バックオフは 30s で頭打ち、 同一チャンクの未完了要求が同時に 2 つ存在しない
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-014`
  **Role**: `Verifies`

### SignatureVerifier — ECDSA 正署名は true

**Type**: TEST
**UID**: UT-025
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: SignatureVerifier の署名検証
  Scenario: ECDSA P-256 正署名
    Given P-256 鍵で署名した data と sig
    When verify(data, sig) を呼ぶ
    Then true を返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-015`
  **Role**: `Verifies`

### SignatureVerifier — RSA-PSS 正署名は true

**Type**: TEST
**UID**: UT-026
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: SignatureVerifier の署名検証
  Scenario: RSA-PSS 2048 正署名
    Given RSA-PSS 2048 鍵で署名した data と sig
    When verify(data, sig) を呼ぶ
    Then true を返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-015`
  **Role**: `Verifies`

### SignatureVerifier — 改ざんは false

**Type**: TEST
**UID**: UT-027
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: SignatureVerifier の署名検証
  Scenario: 改ざん検知
    Given data を 1 バイト改ざんした
    When verify(data, sig) を呼ぶ
    Then false を返す (内部状態を変えない純粋関数)
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-015`
  **Role**: `Verifies`

### FlashSectorWriter — 正常書込は事前消去 + CRC 一致

**Type**: TEST
**UID**: UT-028
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: FlashSectorWriter の書込
  Scenario: 正常書込
    Given 64KB セクタ 0 と書込データ D
    When write(0, D) を呼ぶ
    Then 書込前にセクタ消去、 書込後 CRC32 が D と一致し成功を返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-016`
  **Role**: `Verifies`

### FlashSectorWriter — CRC 不一致は ERROR

**Type**: TEST
**UID**: UT-029
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: FlashSectorWriter の検証
  Scenario: CRC 不一致
    Given 書込中にビット化けが起きる
    When write(0, D) を呼ぶ
    Then ERROR_FLASH_VERIFY を返す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-016`
  **Role**: `Verifies`

### VehicleStateMonitor — 全条件成立時のみ許可

**Type**: TEST
**UID**: UT-030
**TEST_LEVEL**: Unit

**Statement**:

```gherkin
Feature: VehicleStateMonitor の判定
  Scenario Outline: フラッシュ許可
    Given 車速=<spd> / PKB=<pkb> / シフト=<shift> / IG=<ig>
    When isFlashAllowed() を呼ぶ
    Then 結果は <allowed>

    Examples:
      | spd | pkb | shift | ig  | allowed |
      | 0   | ON  | P     | ACC | true    |
      | 5   | ON  | P     | ACC | false   |
      | 0   | OFF | P     | ACC | false   |
      | 0   | ON  | D     | ACC | false   |
```

**Relations**:

- **Type**: `Parent`
  **ID**: `ARCH-C-017`
  **Role**: `Verifies`

## 5.3 結合テスト (Integration Tests)

**Type**: SECTION

### 認証フロー結合 (token -> verify -> scope)

**Type**: TEST
**UID**: IT-001
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: 認証フローの結合
  Scenario: 発行から認可まで一貫
    Given 認証EP + TokenVerifier + ScopeAuthorizer を結合
    And 有効な認可コードと code_verifier
    When POST /auth/token を呼ぶ
    Then JWT (exp/scope/sub を含む) が発行され、 read:did で検証成功 → allow となる
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L2-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `AUTH-L1-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `AUTH-L1-003`
  **Role**: `Verifies`

### DID 読出ブリッジ結合 (SOVD -> UDS -> JSON)

**Type**: TEST
**UID**: IT-002
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: DID 読出ブリッジ
  Scenario: rpm 読出が変換される
    Given DataReadUseCase + DidResolver + UdsClient + JsonSerializer
    And read:did 認可済み、 Engine ECU が 0x62 F40C 0338 を返す
    When read("engine", 0xF40C) を呼ぶ
    Then UDS 0x22 F40C へ変換され {"rpm": 824} で返る
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L2-002`
  **Role**: `Verifies`

### DTC 読出ブリッジ結合 (UDS 0x19 -> Parser)

**Type**: TEST
**UID**: IT-003
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: DTC 読出ブリッジ
  Scenario: 集約して返す
    Given UdsClient + DtcParser、 Engine が P0301 / Brake が C0040
    When 集約読出を実行する
    Then 各 ECU へ UDS 0x19/02 が発行され、 集約 JSON で返る
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L2-001`
  **Role**: `Verifies`

### DTC クリア — 走行中はガードで阻止

**Type**: TEST
**UID**: IT-004
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: クリアの車速ガード
  Scenario: 走行中
    Given SpeedReader が 30 km/h を返す
    When DELETE /components/engine/faults/P0301 を実行
    Then VehicleSpeedGuard が阻止し、 UDS 0x14 は発行されない (409)
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L2-003`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `DTC-L2-004`
  **Role**: `Verifies`

### DTC クリア — 停車中は実行

**Type**: TEST
**UID**: IT-005
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: クリアの実行
  Scenario: 停車中
    Given SpeedReader が 0 km/h を返す
    When 同じクリアを実行する
    Then UDS 0x14 が発行され成功する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L2-003`
  **Role**: `Verifies`

### OTA — 正常パッケージは検証を通る

**Type**: TEST
**UID**: IT-006
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: ダウンロード + 署名検証
  Scenario: 正常
    Given SHA-256 一致・OEM 署名が正しいパッケージ
    When ダウンロードを実行する
    Then 整合チェック成功 → 署名 valid → Verifying から Installing へ進む
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L2-001`
  **Role**: `Verifies`

### OTA — 改ざんパッケージは破棄

**Type**: TEST
**UID**: IT-007
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: 署名検証
  Scenario: 改ざん
    Given 署名が不正なパッケージ
    When ダウンロードを実行する
    Then 署名検証失敗で破棄され Installing に進まない
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L2-002`
  **Role**: `Verifies`

### OTA フラッシュ + 状態ガードの緊急中断

**Type**: TEST
**UID**: IT-008
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: 書込中の状態ガード
  Scenario: 条件崩れで中断
    Given Installing 中 (FlashSectorWriter 書込開始)
    When 車速が 0 -> 5 km/h に変化する
    Then VehicleStateGuard が 50ms 周期で検知し書込を緊急中断、 安全側へ遷移
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L2-004`
  **Role**: `Verifies`

### 認証エンドポイントが要求を受理する

**Type**: TEST
**UID**: IT-009
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: 認証エンドポイント
  Scenario: Token Request 受理
    Given ゲートウェイ起動済み
    When POST /auth/token (OAuth2 Token Request) を受信する
    Then 受理し処理する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L2-001`
  **Role**: `Verifies`

### 起動時に証明書ストアの整合性を検証する

**Type**: TEST
**UID**: IT-010
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: 証明書ストア
  Scenario: 整合性検証
    Given CA チェーンが不揮発領域にある
    When 起動する
    Then 整合性検証が実行され、 破損時は起動を異常通知する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L2-005`
  **Role**: `Verifies`

### 失効リストを定期同期する

**Type**: TEST
**UID**: IT-011
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: 失効リスト同期
  Scenario: 起動時/1時間ごと
    Given OEM 認証サーバに失効リスト
    When 起動時および 1 時間ごとの契機が来る
    Then ローカル失効キャッシュが更新される
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L2-007`
  **Role**: `Verifies`

### WebSocket で複数 DID を同時購読する

**Type**: TEST
**UID**: IT-012
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: WebSocket 購読
  Scenario: 32 DID 同時
    Given WebSocket エンドポイント
    When 32 個の DID を購読する
    Then 各 DID が周期配信され、 32 同時まで受理される
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L2-004`
  **Role**: `Verifies`

### バルクダウンロードを gzip 圧縮で返す

**Type**: TEST
**UID**: IT-013
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: バルク圧縮
  Scenario: gzip
    Given Accept-Encoding: gzip のバルク要求
    When ダウンロードを実行する
    Then Content-Encoding: gzip で圧縮転送される
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L2-005`
  **Role**: `Verifies`

### 全 DTC を一括クリアする

**Type**: TEST
**UID**: IT-014
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: 一括クリア
  Scenario: 停車中の全クリア
    Given 複数 DTC が記録、 車速 0 km/h
    When DELETE /components/engine/faults (全クリア) を呼ぶ
    Then 車速ガード通過後に全 DTC がクリアされる
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-005`
  **Role**: `Verifies`

### 応答に DTC マスタ情報を同梱する

**Type**: TEST
**UID**: IT-015
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: DTC マスタ
  Scenario: 説明同梱
    Given OEM DTC マスタテーブルが NVRAM にある
    When DTC 一覧を取得する
    Then 各 DTC に説明・推奨対処が同梱される
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L2-005`
  **Role**: `Verifies`

### ロールバックがブートローダ切替で実行される

**Type**: TEST
**UID**: IT-016
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: ロールバック実行
  Scenario: 切替
    Given 前バージョンのパーティション情報を保持
    When ロールバックを要求する
    Then ブートローダパラメータが書き換わり再起動が要求される
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L2-005`
  **Role**: `Verifies`

### 進捗イベントが配信される

**Type**: TEST
**UID**: IT-017
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: 進捗イベントバス
  Scenario: SSE 配信
    Given 更新が進行中
    When 各フェーズ (download/verify/write/finalize) が進む
    Then ProgressEventBus 経由で SSE に進捗が配信される
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L2-006`
  **Role**: `Verifies`

### 電源断後に最後の安全状態から再開する

**Type**: TEST
**UID**: IT-018
**TEST_LEVEL**: Integration

**Statement**:

```gherkin
Feature: 再開可能ステートマシン
  Scenario: 電源断再開
    Given 更新状態が不揮発領域に保存されている
    When 電源断後に再起動する
    Then 最後の安全状態から再開する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L2-007`
  **Role**: `Verifies`

## 5.4 システムテスト (System Tests)

**Type**: SECTION

### 認証付きデータ読出 (end-to-end)

**Type**: TEST
**UID**: ST-001
**TEST_LEVEL**: System

**Statement**:

```gherkin
Feature: 認証付き DID 読出 E2E
  Scenario: クラウドから rpm を取得
    Given 実車相当 (TCU+GW+Engine ECU)、 read:did トークン取得済み
    When GET /components/engine/data/rpm を Bearer で呼ぶ
    Then 200 と {"rpm": <値>}、 単一 DID p95 が 500ms 以内
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L1-001`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `AUTH-L1-001`
  **Role**: `Verifies`

### 周期データストリーム

**Type**: TEST
**UID**: ST-002
**TEST_LEVEL**: System

**Statement**:

```gherkin
Feature: 周期ストリーム
  Scenario: 32 DID 周期受信
    Given read:did トークン
    When 32 個の DID を SSE/WS で購読する
    Then 各 DID が指定周期で配信され、 32 同時で安定
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L1-002`
  **Role**: `Verifies`

### DTC 一覧取得とクリア

**Type**: TEST
**UID**: ST-003
**TEST_LEVEL**: System

**Statement**:

```gherkin
Feature: DTC 取得とクリア
  Scenario: 取得 -> 停車中クリア -> 履歴
    Given Engine に P0301、 車速 0 km/h
    When 一覧取得 -> DELETE クリア (write:dtc)
    Then 取得・クリアが成功し、 操作が履歴に残る
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L1-001`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `DTC-L1-007`
  **Role**: `Verifies`

### OTA 更新 — 正常更新は新版で起動

**Type**: TEST
**UID**: ST-004
**TEST_LEVEL**: System

**Statement**:

```gherkin
Feature: OTA 正常更新 E2E
  Scenario: 正常
    Given 署名付き新ファーム、 停車・P・PKB-ON
    When POST /updates で投入する
    Then Downloading->Verifying->Installing->Activated と進み、 新版で起動する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-001`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `SWU-L1-003`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `SWU-L1-008`
  **Role**: `Verifies`

### OTA 更新 — 書込失敗で旧版を維持

**Type**: TEST
**UID**: ST-005
**TEST_LEVEL**: System

**Statement**:

```gherkin
Feature: OTA 失敗ロールバック E2E
  Scenario: 書込失敗
    Given Installing 中
    When フラッシュ書込が失敗する
    Then 状態は RolledBack となり、 旧バージョンで起動する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-003`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `SWU-L1-008`
  **Role**: `Verifies`

## 5.5 受入テスト (Acceptance Tests, Gherkin)

**Type**: SECTION

### 認証付き DID 読み出しの成功

**Type**: TEST
**UID**: AT-001
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 認証付き DID 読み出し
  Scenario: 認可された整備士が rpm を読む
    Given 整備士が read:did スコープの有効な JWT を保持
    When GET /components/engine/data/rpm を Bearer で呼ぶ
    Then 200 と rpm 数値、 スコープ検証が DID 読出より前に行われる
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-001`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `DATA-L1-001`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `API-003`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `UC-001`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `UC-002`
  **Role**: `Verifies`

### 未認証アクセスの拒否

**Type**: TEST
**UID**: AT-002
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 未認証アクセスの拒否
  Scenario: トークン無しで要求
    Given Authorization ヘッダを付けない
    When GET /components/engine/data/rpm を呼ぶ
    Then 401、 車両データはボディに一切含まれない
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L0-004`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `AUTH-L1-011`
  **Role**: `Verifies`

### スコープ不足で 403

**Type**: TEST
**UID**: AT-003
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 役割に応じたアクセス制御
  Scenario: read:did で個人情報 DID
    Given Mechanic ロール (read:did) のトークン
    When 個人情報を含む DID を要求する
    Then 403 Forbidden
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L2-003`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `DATA-L1-006`
  **Role**: `Verifies`

### 失効トークンの拒否

**Type**: TEST
**UID**: AT-004
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: トークン失効
  Scenario: 失効後の再アクセス
    Given 有効なトークンを発行済み
    When POST /auth/revoke で失効 -> 同じトークンで GET data
    Then 401 Unauthorized
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-010`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `API-002`
  **Role**: `Verifies`

### 走行中の DTC クリア拒否

**Type**: TEST
**UID**: AT-005
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 走行中の DTC クリア禁止
  Scenario: 車速 > 0
    Given 車速 30 km/h
    When DELETE /components/engine/faults/P0301
    Then 409 Conflict、 DTC はクリアされない
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L0-004`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `DTC-L1-004`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `API-007`
  **Role**: `Verifies`

### 改ざんパッケージの拒否

**Type**: TEST
**UID**: AT-006
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: OTA 改ざん検知
  Scenario: 署名不正
    Given 署名が改ざんされた更新パッケージ
    When POST /updates で投入する
    Then 破棄され Installing に遷移せず Failed になる
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L0-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `SWU-L1-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `SWU-L0-006`
  **Role**: `Verifies`

### 走行中フラッシュ書込の禁止

**Type**: TEST
**UID**: AT-007
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 走行中の更新禁止
  Scenario: 走行中の Installing
    Given 車速 > 0 または シフトが P でない
    When 更新が Installing に進もうとする
    Then フラッシュ書込は開始されない
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L0-004`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `SWU-L1-004`
  **Role**: `Verifies`

### アクセストークンの有効期限

**Type**: TEST
**UID**: AT-008
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: トークン有効期限
  Scenario: 既定 30 分
    Given 既定設定でトークンを発行
    When exp を確認する
    Then exp は発行から 30 分
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-008`
  **Role**: `Verifies`

### 更新進捗ストリーム (SSE)

**Type**: TEST
**UID**: AT-009
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 更新進捗の通知
  Scenario: 進捗購読
    Given 更新が進行中
    When GET /updates/progress を購読する
    Then 各 ECU の進捗 (0..100%) とフェーズが配信される
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-006`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `API-009`
  **Role**: `Verifies`

### 故障コード一覧の遠隔取得

**Type**: TEST
**UID**: AT-010
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: DTC 一覧の遠隔取得
  Scenario: 出先から取得
    Given read:dtc トークン、 Engine に P0301 (confirmed)
    When GET /components/engine/faults を呼ぶ
    Then 200、 P0301 が status="confirmed" で含まれる
```

**Relations**:

- **Type**: `Parent`
  **ID**: `UC-003`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `DTC-L1-001`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `API-005`
  **Role**: `Verifies`

### フリーズフレームの取得

**Type**: TEST
**UID**: AT-011
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: フリーズフレーム取得
  Scenario: 発生時スナップショット
    Given read:dtc トークン、 P0301 のフリーズフレームが存在
    When GET /components/engine/faults/P0301/freeze-frame を呼ぶ
    Then 200、 発生時の DID 値 (rpm, coolant 等) が含まれる
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DTC-L0-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `DTC-L1-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `API-006`
  **Role**: `Verifies`

### 周期データの遠隔サンプリング

**Type**: TEST
**UID**: AT-012
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 周期サンプリング
  Scenario: 複数 DID 購読
    Given read:did トークン
    When /components/engine/data/stream で rpm と coolant を購読する
    Then 各 DID が 100ms 周期でプッシュ配信される
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L0-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `DATA-L1-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `API-004`
  **Role**: `Verifies`

### スナップショットの一括取得

**Type**: TEST
**UID**: AT-013
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: スナップショット取得
  Scenario: 全 DID を 1 トランザクション
    Given read:did トークン
    When スナップショット取得を要求する
    Then 同一時刻の全 DID 値が 1 応答で返る
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L0-003`
  **Role**: `Verifies`

### 大容量データの中断・再開可能な転送

**Type**: TEST
**UID**: AT-014
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: バルクダウンロード (再開可能)
  Scenario: 切断後に再開
    Given read:did トークンと数百 MB のログ
    When ダウンロード中に切断 -> HTTP Range で続きから再要求
    Then 重複なく全データが取得できる
```

**Relations**:

- **Type**: `Parent`
  **ID**: `DATA-L0-004`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `DATA-L1-003`
  **Role**: `Verifies`

### 役割別アクセス制御 (RBAC)

**Type**: TEST
**UID**: AT-015
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: ロールベースアクセス制御
  Scenario Outline: 役割により可否が変わる
    Given <role> のトークン
    When <operation> を要求する
    Then 結果は <result>

    Examples:
      | role        | operation              | result |
      | Mechanic    | read:did で DID 読出     | 許可   |
      | Mechanic    | write:swupdate で更新投入 | 403    |
      | OEMEngineer | write:swupdate で更新投入 | 許可   |
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L0-002`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `AUTH-L1-004`
  **Role**: `Verifies`

### TLS 1.3 で接続できる

**Type**: TEST
**UID**: AT-016
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 通信路の保護
  Scenario: TLS 1.3 接続
    When クライアントが TLS 1.3 で接続する
    Then ハンドシェイク成立、 診断 API が利用できる
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L0-003`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `AUTH-L1-005`
  **Role**: `Verifies`

### TLS ダウングレードの拒否

**Type**: TEST
**UID**: AT-017
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: ダウングレード拒否
  Scenario: TLS 1.2 要求
    When クライアントが TLS 1.2 へのダウングレードを要求する
    Then 車両は接続を拒否する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-006`
  **Role**: `Verifies`

### 相互 TLS が成立する (OEM 内部)

**Type**: TEST
**UID**: AT-018
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 相互 TLS (mTLS)
  Scenario: 正当なクライアント証明書
    Given OEM 発行の正当なクライアント証明書 (X.509)
    When mTLS 構成で接続する
    Then 双方向認証が成立し接続できる
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-007`
  **Role**: `Verifies`

### 不正なクライアント証明書は拒否される

**Type**: TEST
**UID**: AT-019
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 相互 TLS (mTLS)
  Scenario: 信頼チェーン外の証明書
    Given 信頼チェーン外のクライアント証明書
    When mTLS で接続する
    Then 接続が拒否される
```

**Relations**:

- **Type**: `Parent`
  **ID**: `AUTH-L1-007`
  **Role**: `Verifies`

### OTA による遠隔ソフトウェア更新 (ユースケース)

**Type**: TEST
**UID**: AT-020
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: OTA 遠隔更新
  Scenario: 配信して新版で起動
    Given write:swupdate トークンと署名付き新ファーム、 停車・P・PKB-ON
    When POST /updates で投入し進捗を購読する
    Then Activated まで進み、 再起動後に新版で起動する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `UC-004`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `API-008`
  **Role**: `Verifies`

### 前バージョンへのロールバック

**Type**: TEST
**UID**: AT-021
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: ロールバック
  Scenario: 異常で前版へ戻す
    Given 更新後に異常が検出された
    When POST /updates/rollback を呼ぶ
    Then 前バージョンへ即時ロールバック、 中は車両機能を制限する
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L0-003`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `SWU-L1-005`
  **Role**: `Verifies`
- **Type**: `Parent`
  **ID**: `API-010`
  **Role**: `Verifies`

### 更新の中断耐性 (電源断からの再開)

**Type**: TEST
**UID**: AT-022
**TEST_LEVEL**: Acceptance

**Statement**:

```gherkin
Feature: 更新の中断耐性
  Scenario: 電源断再開
    Given Downloading 中に電源断
    When 再起動する
    Then DL は中断地点から再開、 書込中だった場合は最初からやり直す
```

**Relations**:

- **Type**: `Parent`
  **ID**: `SWU-L1-007`
  **Role**: `Verifies`

## 5.6 被覆の考え方 (Coverage Policy)

**Type**: SECTION

要求の検証被覆は次の 3 経路で評価する (マトリクスの「穴」がすべて欠陥ではない)。

- **直接被覆**: テストが要求/コンポーネントを ``Verifies`` する (本書のテスト群)。
- **推移被覆**: 下位の子要求/コンポーネントが検証済みなら、 上位要求はそれにより裏づく
  (DEEP TRACE でたどれる)。
- **レビュー/静的解析で検証**: 実行時テストになじまない Constraint (ASAM SOVD /
  ISO 14229 準拠、 MISRA C、 ASIL D 開発プロセス、 NVRAM 摩耗、 浮動小数点表現 等) は
  設計レビュー・静的解析・プロセス監査で確認する。
- **NFR の一部** (メモリ上限・スレッドモデル 等) はコードレビュー + 計測で確認する。
- **性能 NFR** (レイテンシ・応答時間) は ST-001 等の性能観点で確認する。

本サンプルは全ユースケース (L0) と主要な機能システム要求 (L1)・API を直接被覆し、
残りは推移被覆またはレビュー/静的解析で裏づける方針とする。

**要求の種類と主たる検証手段 (V 字の対応)**

全要求に動的テストを 1 対 1 で付けるのではなく、 性質に応じた手段で検証する
(トレーサビリティは全要求に必要だが、 テストケースは選択的)。 ユースケースは受入テストで、
各層の要求は対応するテストレベルで、 制約や一部 NFR はレビュー・静的解析で裏づける。

| 要求の種類 | 主たる検証手段 | 例 (トレース) |
|---|---|---|
| ユースケース (L0) | 受入テスト (UAT / Gherkin) → 結果 | UC-001 ← AT-001 ← TR-AT-001 |
| システム要求 (L1) | システムテスト (ST) | DATA-L1-001 ← ST-001 |
| ECU SW 要求 (L2) | 結合テスト (IT) | DATA-L2-002 ← IT-002 |
| ユニット / コンポーネント (L3) | 単体テスト (UT) | DidResolver ← UT-013 |
| 制約 (Constraint) | レビュー・静的解析・プロセス監査 | MISRA C / ISO 14229 準拠 / ASIL D プロセス |
| 非機能 (一部) | 計測・コードレビュー | メモリ上限 / スレッドモデル |
| 上位要求 | 推移被覆 (子の検証で裏づく) | L0 は子 L1 群の検証で間接的に担保 |
