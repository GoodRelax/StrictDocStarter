# SOVD テスト結果 (Test Results / Execution Records)

**Grammar**: sovd-grammar.sgra
**UID**: DOC-SOVD-TESTRESULTS
**Version**: 1.0

本書は `10-test-spec.md` の各テストの **実行結果記録** である。 各結果は対応するテスト仕様へ
`ResultOf` 関係でトレースする。 仕様は安定、 結果は実行ごとに増える (1 仕様 : N 結果) ため
別文書に分離する。 各結果の TITLE は判定で始めるので、 ツリーでも OK/NG が一目で分かる。

サマリ (集計): 計 75 件 — PASS 66 / CONDITIONAL 5 / FAIL 1 / SKIP 3 (本サンプルの実行記録例)。
1 シナリオ = 1 テスト = 1 結果なので、 「関連する 1 つが PASS、 1 つが FAIL/SKIP」 を個別に
表現できる (例: PackageDownloader は再開=PASS だが二重要求=FAIL)。

## 単体テスト結果 (Unit)

**Type**: SECTION

### [PASS] TokenVerifier — 有効な JWT は受理される

**Type**: TEST_RESULT
**UID**: TR-UT-001
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, gcc + unity)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-001`
  **Role**: `ResultOf`

### [PASS] TokenVerifier — 署名改ざんは拒否される

**Type**: TEST_RESULT
**UID**: TR-UT-002
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-002`
  **Role**: `ResultOf`

### [PASS] TokenVerifier — 期限切れは拒否される

**Type**: TEST_RESULT
**UID**: TR-UT-003
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-003`
  **Role**: `ResultOf`

### [PASS] TokenCache — 容量超過で最古を追い出す

**Type**: TEST_RESULT
**UID**: TR-UT-004
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-004`
  **Role**: `ResultOf`

### [PASS] TokenCache — 保持中はヒットする

**Type**: TEST_RESULT
**UID**: TR-UT-005
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-005`
  **Role**: `ResultOf`

### [PASS] ScopeAuthorizer — スコープ充足/不足の判定

**Type**: TEST_RESULT
**UID**: TR-UT-006
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-006`
  **Role**: `ResultOf`

### [PASS] TlsTerminator — 起動時に信頼ストアをロードする

**Type**: TEST_RESULT
**UID**: TR-UT-007
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL mock)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-007`
  **Role**: `ResultOf`

### [PASS] TlsTerminator — 不正証明書で失敗イベントを通知する

**Type**: TEST_RESULT
**UID**: TR-UT-008
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL mock)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-008`
  **Role**: `ResultOf`

### [PASS] UdsClient — 正常応答を返す

**Type**: TEST_RESULT
**UID**: TR-UT-009
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, UDS stub)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-009`
  **Role**: `ResultOf`

### [PASS] UdsClient — 無応答はリトライ後タイムアウト

**Type**: TEST_RESULT
**UID**: TR-UT-010
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, UDS stub)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-010`
  **Role**: `ResultOf`

### [PASS] UdsClient — NRC を伝播する

**Type**: TEST_RESULT
**UID**: TR-UT-011
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, UDS stub)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-011`
  **Role**: `ResultOf`

### [PASS] JsonSerializer — 各型を ASAM JSON へ変換する

**Type**: TEST_RESULT
**UID**: TR-UT-012
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-012`
  **Role**: `ResultOf`

### [PASS] DidResolver — 既知 DID を解決する

**Type**: TEST_RESULT
**UID**: TR-UT-013
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-013`
  **Role**: `ResultOf`

### [PASS] DidResolver — 未知 DID はエラー

**Type**: TEST_RESULT
**UID**: TR-UT-014
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-014`
  **Role**: `ResultOf`

### [PASS] DataCache — TTL 内はヒットする

**Type**: TEST_RESULT
**UID**: TR-UT-015
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-015`
  **Role**: `ResultOf`

### [PASS] DataCache — TTL 経過でミスする

**Type**: TEST_RESULT
**UID**: TR-UT-016
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-016`
  **Role**: `ResultOf`

### [PASS] DtcParser — 1 件の DTC を解析する

**Type**: TEST_RESULT
**UID**: TR-UT-017
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-017`
  **Role**: `ResultOf`

### [PASS] DtcParser — 空応答は空リスト

**Type**: TEST_RESULT
**UID**: TR-UT-018
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-018`
  **Role**: `ResultOf`

### [PASS] FreezeFrameDecoder — (did,value) へ復号する

**Type**: TEST_RESULT
**UID**: TR-UT-019
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-019`
  **Role**: `ResultOf`

### [PASS] SpeedReader — 最新車速を 10ms 以内に反映する

**Type**: TEST_RESULT
**UID**: TR-UT-020
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL (ASIL C task timing)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-020`
  **Role**: `ResultOf`

### [PASS] DtcHistoryStore — 容量超過で最古を上書きする

**Type**: TEST_RESULT
**UID**: TR-UT-021
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-021`
  **Role**: `ResultOf`

### [CONDITIONAL] DtcHistoryStore — 並行読取でも整合する

**Type**: TEST_RESULT
**UID**: TR-UT-022
**RESULT**: CONDITIONAL

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, TSan)

**REMARK**: 単一プロデューサは PASS。 高負荷の並行読取の境界網羅が未完。

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-022`
  **Role**: `ResultOf`

### [PASS] PackageDownloader — 途中失敗から再開して完走する

**Type**: TEST_RESULT
**UID**: TR-UT-023
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, network sim)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-023`
  **Role**: `ResultOf`

### [FAIL] PackageDownloader — バックオフ上限で二重要求しない

**Type**: TEST_RESULT
**UID**: TR-UT-024
**RESULT**: FAIL

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, network sim)

**REMARK**: バックオフ上限 (30s) 到達時に稀に二重リクエストを観測。 修正中 (要再テスト)。

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-024`
  **Role**: `ResultOf`

### [PASS] SignatureVerifier — ECDSA 正署名は true

**Type**: TEST_RESULT
**UID**: TR-UT-025
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-025`
  **Role**: `ResultOf`

### [PASS] SignatureVerifier — RSA-PSS 正署名は true

**Type**: TEST_RESULT
**UID**: TR-UT-026
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-026`
  **Role**: `ResultOf`

### [PASS] SignatureVerifier — 改ざんは false

**Type**: TEST_RESULT
**UID**: TR-UT-027
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: CI (host, OpenSSL)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-027`
  **Role**: `ResultOf`

### [PASS] FlashSectorWriter — 正常書込は事前消去 + CRC 一致

**Type**: TEST_RESULT
**UID**: TR-UT-028
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL (flash emulator)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-028`
  **Role**: `ResultOf`

### [PASS] FlashSectorWriter — CRC 不一致は ERROR

**Type**: TEST_RESULT
**UID**: TR-UT-029
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL (flash emulator)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-029`
  **Role**: `ResultOf`

### [PASS] VehicleStateMonitor — 全条件成立時のみ許可

**Type**: TEST_RESULT
**UID**: TR-UT-030
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL (ASIL D, signal injection)

**Relations**:

- **Type**: `Parent`
  **ID**: `UT-030`
  **Role**: `ResultOf`

## 結合テスト結果 (Integration)

**Type**: SECTION

### [PASS] 認証フロー結合

**Type**: TEST_RESULT
**UID**: TR-IT-001
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-001`
  **Role**: `ResultOf`

### [PASS] DID 読出ブリッジ結合

**Type**: TEST_RESULT
**UID**: TR-IT-002
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-002`
  **Role**: `ResultOf`

### [PASS] DTC 読出ブリッジ結合

**Type**: TEST_RESULT
**UID**: TR-IT-003
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-003`
  **Role**: `ResultOf`

### [PASS] DTC クリア — 走行中はガードで阻止

**Type**: TEST_RESULT
**UID**: TR-IT-004
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench (speed inject)

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-004`
  **Role**: `ResultOf`

### [PASS] DTC クリア — 停車中は実行

**Type**: TEST_RESULT
**UID**: TR-IT-005
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-005`
  **Role**: `ResultOf`

### [PASS] OTA — 正常パッケージは検証を通る

**Type**: TEST_RESULT
**UID**: TR-IT-006
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-006`
  **Role**: `ResultOf`

### [PASS] OTA — 改ざんパッケージは破棄

**Type**: TEST_RESULT
**UID**: TR-IT-007
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-007`
  **Role**: `ResultOf`

### [PASS] OTA フラッシュ + 状態ガードの緊急中断

**Type**: TEST_RESULT
**UID**: TR-IT-008
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench (state inject)

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-008`
  **Role**: `ResultOf`

### [PASS] 認証エンドポイントが要求を受理する

**Type**: TEST_RESULT
**UID**: TR-IT-009
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-009`
  **Role**: `ResultOf`

### [PASS] 起動時に証明書ストアの整合性を検証する

**Type**: TEST_RESULT
**UID**: TR-IT-010
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-010`
  **Role**: `ResultOf`

### [PASS] 失効リストを定期同期する

**Type**: TEST_RESULT
**UID**: TR-IT-011
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-011`
  **Role**: `ResultOf`

### [PASS] WebSocket で複数 DID を同時購読する

**Type**: TEST_RESULT
**UID**: TR-IT-012
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-012`
  **Role**: `ResultOf`

### [PASS] バルクダウンロードを gzip 圧縮で返す

**Type**: TEST_RESULT
**UID**: TR-IT-013
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-013`
  **Role**: `ResultOf`

### [PASS] 全 DTC を一括クリアする

**Type**: TEST_RESULT
**UID**: TR-IT-014
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench (speed inject)

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-014`
  **Role**: `ResultOf`

### [PASS] 応答に DTC マスタ情報を同梱する

**Type**: TEST_RESULT
**UID**: TR-IT-015
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-015`
  **Role**: `ResultOf`

### [PASS] ロールバックがブートローダ切替で実行される

**Type**: TEST_RESULT
**UID**: TR-IT-016
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-016`
  **Role**: `ResultOf`

### [PASS] 進捗イベントが配信される

**Type**: TEST_RESULT
**UID**: TR-IT-017
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-017`
  **Role**: `ResultOf`

### [PASS] 電源断後に最後の安全状態から再開する

**Type**: TEST_RESULT
**UID**: TR-IT-018
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: HIL bench (power cut rig)

**Relations**:

- **Type**: `Parent`
  **ID**: `IT-018`
  **Role**: `ResultOf`

## システムテスト結果 (System)

**Type**: SECTION

### [PASS] 認証付きデータ読出 (E2E)

**Type**: TEST_RESULT
**UID**: TR-ST-001
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**Relations**:

- **Type**: `Parent`
  **ID**: `ST-001`
  **Role**: `ResultOf`

### [SKIP] 周期データストリーム

**Type**: TEST_RESULT
**UID**: TR-ST-002
**RESULT**: SKIP

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**REMARK**: SSE/WS の長時間安定試験環境が未整備のため未実施。

**Relations**:

- **Type**: `Parent`
  **ID**: `ST-002`
  **Role**: `ResultOf`

### [PASS] DTC 一覧取得とクリア

**Type**: TEST_RESULT
**UID**: TR-ST-003
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**Relations**:

- **Type**: `Parent`
  **ID**: `ST-003`
  **Role**: `ResultOf`

### [PASS] OTA 更新 — 正常更新は新版で起動

**Type**: TEST_RESULT
**UID**: TR-ST-004
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**Relations**:

- **Type**: `Parent`
  **ID**: `ST-004`
  **Role**: `ResultOf`

### [CONDITIONAL] OTA 更新 — 書込失敗で旧版を維持

**Type**: TEST_RESULT
**UID**: TR-ST-005
**RESULT**: CONDITIONAL

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**REMARK**: 書込失敗の自動ロールバックは手動誘発で確認。 全自動化は未完。

**Relations**:

- **Type**: `Parent`
  **ID**: `ST-005`
  **Role**: `ResultOf`

## 受入テスト結果 (Acceptance)

**Type**: SECTION

### [PASS] 認証付き DID 読み出しの成功

**Type**: TEST_RESULT
**UID**: TR-AT-001
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (SOVD tester)

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-001`
  **Role**: `ResultOf`

### [PASS] 未認証アクセスの拒否

**Type**: TEST_RESULT
**UID**: TR-AT-002
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-002`
  **Role**: `ResultOf`

### [PASS] スコープ不足で 403

**Type**: TEST_RESULT
**UID**: TR-AT-003
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-003`
  **Role**: `ResultOf`

### [PASS] 失効トークンの拒否

**Type**: TEST_RESULT
**UID**: TR-AT-004
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-004`
  **Role**: `ResultOf`

### [PASS] 走行中の DTC クリア拒否

**Type**: TEST_RESULT
**UID**: TR-AT-005
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (rolling road)

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-005`
  **Role**: `ResultOf`

### [PASS] 改ざんパッケージの拒否

**Type**: TEST_RESULT
**UID**: TR-AT-006
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-006`
  **Role**: `ResultOf`

### [PASS] 走行中フラッシュ書込の禁止

**Type**: TEST_RESULT
**UID**: TR-AT-007
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (rolling road)

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-007`
  **Role**: `ResultOf`

### [CONDITIONAL] アクセストークンの有効期限

**Type**: TEST_RESULT
**UID**: TR-AT-008
**RESULT**: CONDITIONAL

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**REMARK**: 既定 30 分は確認済み。 上限 60 分の境界ケースは未実施。

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-008`
  **Role**: `ResultOf`

### [SKIP] 更新進捗ストリーム (SSE)

**Type**: TEST_RESULT
**UID**: TR-AT-009
**RESULT**: SKIP

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**REMARK**: SSE テスト環境が未整備のため未実施。

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-009`
  **Role**: `ResultOf`

### [PASS] 故障コード一覧の遠隔取得

**Type**: TEST_RESULT
**UID**: TR-AT-010
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-010`
  **Role**: `ResultOf`

### [PASS] フリーズフレームの取得

**Type**: TEST_RESULT
**UID**: TR-AT-011
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-011`
  **Role**: `ResultOf`

### [SKIP] 周期データの遠隔サンプリング

**Type**: TEST_RESULT
**UID**: TR-AT-012
**RESULT**: SKIP

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**REMARK**: SSE/WS 環境が未整備のため未実施 (ST-002 と同因)。

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-012`
  **Role**: `ResultOf`

### [PASS] スナップショットの一括取得

**Type**: TEST_RESULT
**UID**: TR-AT-013
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-013`
  **Role**: `ResultOf`

### [PASS] 大容量データの中断・再開可能な転送

**Type**: TEST_RESULT
**UID**: TR-AT-014
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (link drop sim)

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-014`
  **Role**: `ResultOf`

### [PASS] 役割別アクセス制御 (RBAC)

**Type**: TEST_RESULT
**UID**: TR-AT-015
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-015`
  **Role**: `ResultOf`

### [PASS] TLS 1.3 で接続できる

**Type**: TEST_RESULT
**UID**: TR-AT-016
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (TLS probe)

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-016`
  **Role**: `ResultOf`

### [PASS] TLS ダウングレードの拒否

**Type**: TEST_RESULT
**UID**: TR-AT-017
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: workshop (TLS probe)

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-017`
  **Role**: `ResultOf`

### [PASS] 相互 TLS が成立する (OEM 内部)

**Type**: TEST_RESULT
**UID**: TR-AT-018
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: OEM lab (mTLS)

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-018`
  **Role**: `ResultOf`

### [PASS] 不正なクライアント証明書は拒否される

**Type**: TEST_RESULT
**UID**: TR-AT-019
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: OEM lab (mTLS)

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-019`
  **Role**: `ResultOf`

### [PASS] OTA による遠隔ソフトウェア更新

**Type**: TEST_RESULT
**UID**: TR-AT-020
**RESULT**: PASS

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-020`
  **Role**: `ResultOf`

### [CONDITIONAL] 前バージョンへのロールバック

**Type**: TEST_RESULT
**UID**: TR-AT-021
**RESULT**: CONDITIONAL

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype

**REMARK**: 手動ロールバックは PASS。 異常検出からの自動ロールバックは自動化未完。

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-021`
  **Role**: `ResultOf`

### [CONDITIONAL] 更新の中断耐性 (電源断からの再開)

**Type**: TEST_RESULT
**UID**: TR-AT-022
**RESULT**: CONDITIONAL

**EXECUTED_ON**: 2026-06-06

**ENVIRONMENT**: vehicle prototype (power cut rig)

**REMARK**: ダウンロード中の電源断再開は PASS。 書込中断からの復帰は限定ケースのみ確認。

**Relations**:

- **Type**: `Parent`
  **ID**: `AT-022`
  **Role**: `ResultOf`
