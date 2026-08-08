# SOVD 故障診断 (DTC) 要求仕様 (Diagnostic Trouble Codes)

**Grammar**: sovd-grammar.sgra \
**UID**: DOC-SOVD-DTC \
**Version**: 1.0

本書は SOVD の **故障診断 (DTC・フリーズフレーム)** の読出・クリア要求を L1→L3 で
定義する。 内部では ISO 14229 (UDS) の 0x19 系 (ReadDTCInformation) / 0x14
(ClearDiagnosticInformation) を SOVD でラップする。 ステークホルダ要求 (L0)・ユースケースは
`01-stakeholder-requirements.md`、 共有の前付けは `00-overview.md`、 認証・認可は
`03-auth.md` を前提とする。

DTC の **読み出し** は安全機能ではないため原則 **ASIL=QM**。 ただし **「走行中に
安全関連 DTC を消す」 と機能安全評価に影響しうる** ため、 クリアの **走行状態ガードは
ASIL C** とする。 「誰がクリアできるか」 の権限はセキュリティ事項なので **CAL** を付与する。

## L1 — システム要求 (System Requirements)

**Type**: SECTION

**L1 代表シーケンス: DTC の読み出しと、 走行状態ガード付きクリア**

読み出しは UDS 0x19 へ、 クリアは UDS 0x14 へブリッジする。 クリアは車速ゼロを
確認できた場合のみ実行し、 走行中は 409 で拒否する。

**この図は 16 行を超えるので別文書にしてある** → [LINK: DOC-FIG-DTC-GUARD]

### DTC リスト取得 API

**Type**: REQUIREMENT \
**UID**: DTC-L1-001 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L1_System
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-001`

**Statement**: 車両は GET /components/{ecu}/faults を提供し、 ステータスマスク
(active/pending/confirmed/permanent) でフィルタ可能とすること。

### フリーズフレーム取得 API

**Type**: REQUIREMENT \
**UID**: DTC-L1-002 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L1_System
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-002`

**Statement**: 車両は GET /components/{ecu}/faults/{code}/freeze-frame で、 指定 DTC のフリーズフレーム
(発生時の DID 値スナップショット) を JSON で返すこと。

### DTC クリア API

**Type**: REQUIREMENT \
**UID**: DTC-L1-003 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L1_System
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-003`

**Statement**: 車両は DELETE /components/{ecu}/faults/{code} で DTC をクリアできるようにし、
スコープ write:dtc を要求すること。

### クリア前の車速ゼロチェック

**Type**: REQUIREMENT \
**UID**: DTC-L1-004 \
**TYPE**: Functional \
**ASIL**: C \
**LAYER**: L1_System
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-004`

**Statement**: DTC クリア要求を受信したとき、 車両は、 現在の車速 (DID 0xF40D) を読み出すこと。 もし車速が 0 km/h でないならば、 車両は、 HTTP 409 Conflict を返すこと。 もし車速を取得できないならば、 車両は、 安全側に倒してクリアを実行せず拒否すること。

**VERIFICATION**: 車速 > 0 でのクリア要求が 409 で拒否され、 車速 0 でのみ成功すること。

### 全 DTC 一括クリア API

**Type**: REQUIREMENT \
**UID**: DTC-L1-005 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L1_System
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-003`
- **Type**: `Parent` \
  **ID**: `DTC-L0-004`

**Statement**: 車両は、 DELETE /components/{ecu}/faults で全 DTC を一括クリアできるように
すること。 このときの車速ゼロの条件は、 DTC-L1-004 と同じであること。

### DTC レスポンス時間

**Type**: REQUIREMENT \
**UID**: DTC-L1-006 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**LAYER**: L1_System
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L1-001`

**Statement**: 車両の DTC リスト取得は、 95 パーセンタイルで 1 秒以内に応答すること。

**VERIFICATION**: 代表負荷下で、 DTC リスト取得の p95 が 1 秒以内であること。

### DTC 発生履歴

**Type**: REQUIREMENT \
**UID**: DTC-L1-007 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L1_System
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-001`

**Statement**: 車両は、 直近 1024 件 (概ね 24 時間相当) の DTC 発生履歴を保持し、 GET
/components/{ecu}/faults/history で取得できるようにすること。

### 安全関連 DTC クリアの権限検証

**Type**: REQUIREMENT \
**UID**: DTC-L1-008 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L1_System
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-006`

**Statement**: もし安全関連 DTC のクリアが要求されたならば、 車両は、 write:dtc:safety スコープを
検証すること。 もしそのスコープを欠くならば、 車両は、 HTTP 403 を返すこと。

**VERIFICATION**: 安全関連 DTC のクリアが、 write:dtc のみのトークンで 403、 write:dtc:safety を
伴う場合に許可されること。

## L2 — ECU ソフトウェア要求 (ECU Software Requirements)

**Type**: SECTION

### UDS 0x19 ReadDTCInformation ブリッジ

**Type**: REQUIREMENT \
**UID**: DTC-L2-001 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L2_ECU_SW
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L1-001`

**Statement**: SOVD GET /faults 要求を受けたとき、 ゲートウェイ ECU は担当 ECU 群へ UDS Service
0x19 SubFunction 0x02 (reportDTCByStatusMask) を発行し、 結果を集約して JSON で
返すこと。

### フリーズフレーム取得

**Type**: REQUIREMENT \
**UID**: DTC-L2-002 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L2_ECU_SW
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L1-002`

**Statement**: ゲートウェイ ECU は、 UDS 0x19 SubFunction 0x04
(reportDTCSnapshotRecordByDTCNumber) を用いてフリーズフレームを取得すること。

### UDS 0x14 ClearDiagnosticInformation

**Type**: REQUIREMENT \
**UID**: DTC-L2-003 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L2_ECU_SW
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L1-003`

**Statement**: DTC クリア要求に対し、 ゲートウェイ ECU は車速チェック (DTC-L2-004) の成功後に
UDS Service 0x14 を対象 ECU へ発行すること。

### VehicleSpeedGuard

**Type**: REQUIREMENT \
**UID**: DTC-L2-004 \
**TYPE**: Functional \
**ASIL**: C \
**LAYER**: L2_ECU_SW
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L1-004`

**Statement**: 全ての DTC クリア要求 (個別・一括を問わず) の前に、 ゲートウェイ ECU は VehicleSpeedGuard により車速 == 0 を
100 ms 以内に検証すること。

**VERIFICATION**: 車速 > 0 のときクリアが実行されないこと (ガードで阻止) を確認する。

### DTC マスタテーブル

**Type**: REQUIREMENT \
**UID**: DTC-L2-005 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L2_ECU_SW
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L1-001`

**Statement**: ゲートウェイ ECU は、 OEM 提供の DTC マスタテーブル (コード → 説明 / 推奨対処) を
NVRAM に保持し、 API レスポンスに同梱すること。

### DTC 履歴循環バッファ

**Type**: REQUIREMENT \
**UID**: DTC-L2-006 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L2_ECU_SW
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L1-007`

**Statement**: ゲートウェイ ECU は、 タイムスタンプ・DTC・status mask を 1 エントリとする
DTC 履歴を、 最大 1024 件まで循環バッファで保持すること。

### UDS タイムアウト

**Type**: REQUIREMENT \
**UID**: DTC-L2-007 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**LAYER**: L2_ECU_SW
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L1-006`

**Statement**: ゲートウェイ ECU の UDS 要求の P2 タイムアウトは 50 ms、 P2* タイムアウトは
500 ms とすること。

### NRC ハンドリング

**Type**: REQUIREMENT \
**UID**: DTC-L2-008 \
**TYPE**: Constraint \
**ASIL**: QM \
**LAYER**: L2_ECU_SW
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L2-001`

**Statement**: もし UDS Negative Response Code (NRC) を受けた場合、 ゲートウェイ ECU は SOVD
クライアントへ HTTP 502 と、 JSON ボディに NRC コードを含めて返すこと。

## L3 — ユニット要求 (Unit / Software Component Requirements)

**Type**: SECTION

### DtcParser ユニット

**Type**: REQUIREMENT \
**UID**: DTC-L3-001 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L2-001`

**Statement**: DtcParser ユニットは、 UDS 0x19 のバイナリ応答を解析し、 (dtc_code, status_byte) の
リストを返すこと。

### FreezeFrameDecoder ユニット

**Type**: REQUIREMENT \
**UID**: DTC-L3-002 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L2-002`

**Statement**: FreezeFrameDecoder ユニットは、 UDS 0x19/0x04 のフリーズフレームペイロードを
(did, value) のリストに変換すること。

### SpeedReader ユニット

**Type**: REQUIREMENT \
**UID**: DTC-L3-003 \
**TYPE**: Functional \
**ASIL**: C \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L2-004`

**Statement**: SpeedReader ユニットは、 ASIL C 認定のリアルタイムタスクとして DID 0xF40D を 10 ms
周期で更新し、 最新値を const アクセスで提供すること。

### DtcHistoryStore ユニット

**Type**: REQUIREMENT \
**UID**: DTC-L3-004 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L2-006`

**Statement**: DtcHistoryStore ユニットは、 ロックフリーのリングバッファ (Single Producer Multiple
Consumer) として実装し、 サイズ 1024 を NVRAM 上に確保すること。

### NVRAM 摩耗保護

**Type**: REQUIREMENT \
**UID**: DTC-L3-005 \
**TYPE**: Constraint \
**ASIL**: QM \
**LAYER**: L3_Unit
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L3-004`

**Statement**: DTC 履歴の NVRAM 書込は wear-leveling アルゴリズム (例: log-structured) を採用し、
同一セクタへの連続書込を避けること。
