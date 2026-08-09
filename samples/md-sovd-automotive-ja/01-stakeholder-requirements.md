# SOVD ステークホルダ要求 (Stakeholder Requirements)

**Grammar**: sovd-grammar.sgra \
**UID**: DOC-SOVD-STAKEHOLDER \
**Version**: 1.0

本書は SOVD 車両診断システムの **ステークホルダ要求 (L0)** を EARS で定義する要求文書である。
最上位要求 SYS-L0-001 を頂点に、 各機能ドメイン (認証 / データ / DTC / OTA) の要求が
これへ収束する。 各ドメインの要求は、 対応するユースケース (`02-usecases.md` の
UC-001 〜 UC-004) を `Parent` で指す。 背景は `00-overview.md`、
各ドメインのシステム要求 (L1) 以下は各ドメイン文書を参照のこと。

**要求とユースケースの区別 (ISO/IEC/IEEE 29148 / A-SPICE):** 本書は「システムが満たすべき条件」
(要求、 EARS) を扱う。 「アクターがどう使うか」(ユースケース、 シナリオ) は
`02-usecases.md` に分離する。 **29148 はユースケースを利害関係者要求の表現技法として扱い、
システム要求はそこから導出されるものとする。** だから本書の要求がユースケースを
`Parent` で指し、 受入テストが UC を検証する。 `Parent` は常に具体から抽象へ向く。

## 0. 最上位要求 (System Goal)

**Type**: SECTION

### 認可された関係者への遠隔診断・更新の提供

**Type**: REQUIREMENT \
**UID**: SYS-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder

**Statement**: 本システム (SOVD 遠隔診断システム) は、 整備士・OEM エンジニア・フリート運用者が、
認可された範囲で対象車両を遠隔から安全に診断・更新できる統合的な仕組みを提供すること。

**VERIFICATION**: 4 つの主要ユースケース (認証付きアクセス・データ読取・DTC 診断・OTA 更新) が認可された
関係者により遠隔で実行でき、 未認可のアクセスは拒否されること。

### 複数関係者の同時アクセス

**Type**: REQUIREMENT \
**UID**: SYS-L0-002 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `SYS-L0-001`

**Statement**: 本システムは、 認可された複数の関係者からの遠隔診断アクセスを、 車両ゲートウェイで同時に処理できること。

**Rationale**: フリート運用や複数拠点からの診断を想定し、 システム全体の同時アクセス性を最上位で要求する (具体的な同時接続上限はドメイン要求、 例 DATA-L2-008 で規定)。

## 認証・認可 (Authentication & Authorization)

**Type**: SECTION

### 認証付き診断アクセスの提供

**Type**: REQUIREMENT \
**UID**: AUTH-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-001`

**Statement**: 整備士が遠隔の SOVD クライアントから認証を経て診断アクセスを要求したとき、
本システムは認可された範囲で対象車両の診断データへのアクセスを提供すること。

**VERIFICATION**: 認証済みクライアントで診断リソースの GET が HTTP 200 を返し、 対象データが
取得できること。

### 役割に応じた診断権限の制限

**Type**: REQUIREMENT \
**UID**: AUTH-L0-002 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-001`

**Statement**: 本システムは、 利用者の役割 (整備士 / OEM エンジニア / フリート運用者) に応じて、
利用可能な診断機能 (読み出し / 書き込み) を制限すること。

**Rationale**: 過剰な権限付与は安全関連操作の誤用・悪用に直結する。

**VERIFICATION**: 役割ごとの許可操作マトリクスに従い、 権限外の操作要求が HTTP 403 で拒否されること。

### クレデンシャルの機密保持

**Type**: REQUIREMENT \
**UID**: AUTH-L0-003 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-001`

**Statement**: 通信路上および保管中、 本システムは、 診断アクセスの認証に用いるクレデンシャル
(パスワード / トークン / 証明書) を第三者へ漏洩させないこと。

**Rationale**: SOVD は HTTP ベースで、 認証・認可前のデータ漏洩リスクが従来 UDS より高い。

**VERIFICATION**: 全診断通信が TLS で暗号化され、 保管されるクレデンシャルが平文でないことを確認する。

### 未認証アクセスの拒否

**Type**: REQUIREMENT \
**UID**: AUTH-L0-004 \
**TYPE**: Restriction \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-001`

**Statement**: もし未認証のクライアントが SOVD サービスを呼び出した場合、 本システムは
診断データの読み出しを含む一切の処理を実行せず、 要求を拒否すること。

**Rationale**: 認証・認可前のデータ漏洩を防ぐ。 SOVD は外部からの直接接続リスクが UDS より高い。

**VERIFICATION**: トークンを伴わない全エンドポイント呼び出しが HTTP 401 を返すこと。

### ASAM SOVD 認証要件への準拠

**Type**: REQUIREMENT \
**UID**: AUTH-L0-005 \
**TYPE**: Constraint \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-001`

**Statement**: 本システムの認証・認可機能は、 ASAM SOVD v1.0 (Part 1: Common) の認証要件に
準拠すること。

### 認証・認可の監査証跡

**Type**: REQUIREMENT \
**UID**: AUTH-L0-006 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-001`

**Statement**: 本システムは、 認証・認可に関わるアクセス試行 (成功・失敗) を、 追跡可能な監査証跡として記録すること。

**Rationale**: なりすまし・不正アクセスの事後追跡 (フォレンジック) のため。 §1.2 の脅威対策の土台。

## 車両データアクセス (Vehicle Data Access)

**Type**: SECTION

### 車両状態データの遠隔読み取りの提供

**Type**: REQUIREMENT \
**UID**: DATA-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-002`

**Statement**: 整備士や OEM エンジニアが遠隔の SOVD クライアントから車両の現在状態 (走行距離・
バッテリ電圧・各 ECU 温度等) の取得を要求したとき、 本システムは認可された範囲で
そのデータを返すこと。

**VERIFICATION**: 認可されたクライアントで代表的な DID 群が取得でき、 未認可の項目は返らないこと。

### 周期的なデータサンプリング

**Type**: REQUIREMENT \
**UID**: DATA-L0-002 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-002`

**Statement**: 本システムは、 利用者が指定した DID リストを 100 ms 〜 60 s の周期で連続取得できる
ようにすること。

### スナップショットの一括取得

**Type**: REQUIREMENT \
**UID**: DATA-L0-003 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-002`

**Statement**: 本システムは、 特定時刻における車両の全 DID 値スナップショットを 1 トランザクションで
取得できるようにすること。

### 大量データの中断・再開可能な転送

**Type**: REQUIREMENT \
**UID**: DATA-L0-004 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-002`

**Statement**: 本システムは、 ロギングデータや録画フレーム等の数百 MB 規模のデータを、 中断・再開
可能な方式で転送できること。

### 読み出し権限と書き込み権限の分離

**Type**: REQUIREMENT \
**UID**: DATA-L0-005 \
**TYPE**: Restriction \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-002`

**Statement**: もし読み出し専用トークンで DID 値の書き込み (writeDataByIdentifier 相当) が要求された
場合、 本システムはこれを拒否すること。

**Rationale**: 読み出しと書き込みを別スコープで管理し、 誤書込・悪用を防ぐ。 本サンプルでは DID 書込 API は在域外のため、 本要求は将来の書込操作に対するガード方針として保持し、 レビューで担保する。

## 故障診断 (DTC)

**Type**: SECTION

### 故障コードの遠隔取得

**Type**: REQUIREMENT \
**UID**: DTC-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-003`

**Statement**: 整備士が遠隔の SOVD クライアントから故障コード一覧を要求したとき、 本システムは
車両に記録された全 DTC をステータスマスクとともに返すこと。

**VERIFICATION**: 代表的な DTC が、 status (active/pending/confirmed/permanent) 付きで取得できること。

### フリーズフレームデータの取得

**Type**: REQUIREMENT \
**UID**: DTC-L0-002 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-003`

**Statement**: 本システムは、 DTC 発生時刻のスナップショット (フリーズフレーム) を取得できるように
すること。

### DTC のクリア

**Type**: REQUIREMENT \
**UID**: DTC-L0-003 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-003`

**Statement**: 整備士が修理完了後に対象 DTC のクリアを要求したとき、 本システムは write:dtc スコープを確認したうえでクリアすること。

**Rationale**: 不正・誤った DTC クリアによる故障情報の隠蔽を防ぐ。

### 走行中の DTC クリア禁止

**Type**: REQUIREMENT \
**UID**: DTC-L0-004 \
**TYPE**: Restriction \
**ASIL**: C \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-003`

**Statement**: もし車速が 0 km/h でない場合、 本システムは DTC クリア要求を拒否すること。

**Rationale**: 走行中に安全関連 DTC を消すと、 走行中の機能安全評価に影響するため。

### ISO 14229 セマンティクス準拠

**Type**: REQUIREMENT \
**UID**: DTC-L0-005 \
**TYPE**: Constraint \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-003`

**Statement**: 本システムの DTC 機能は、 ISO 14229-1 (UDS) Service 0x19 (ReadDTCInformation) および
0x14 (ClearDiagnosticInformation) のセマンティクスを保つこと。

### 安全関連 DTC クリアの追加権限

**Type**: REQUIREMENT \
**UID**: DTC-L0-006 \
**TYPE**: Restriction \
**ASIL**: QM \
**CAL**: CAL2 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `DTC-L0-003`

**Statement**: もし安全関連 DTC のクリアが要求された場合、 本システムは通常の write:dtc に加えて
追加の権限 (write:dtc:safety スコープ) を要求すること。

**Rationale**: 安全関連 DTC (ASIL B〜D が割り当てられた DTC) の不正・誤クリアは機能安全評価に
影響するため、 上位権限を要する。 クリア機能 (DTC-L0-003) から独立した制約として切り出す。

## ソフトウェア更新 (OTA)

**Type**: SECTION

### OTA による遠隔ソフトウェア更新の提供

**Type**: REQUIREMENT \
**UID**: SWU-L0-001 \
**TYPE**: Functional \
**ASIL**: QM \
**CAL**: CAL3 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-004`

**Statement**: OEM が不具合修正ソフトを配信したいとき、 本システムは車両 ECU のソフトウェアを OTA (無線) で更新できるようにすること。

**VERIFICATION**: 署名付きパッケージの配信 → 適用が一連で行え、 適用後に新バージョンで起動すること。

### 改ざん検知 (署名検証)

**Type**: REQUIREMENT \
**UID**: SWU-L0-002 \
**TYPE**: Functional \
**ASIL**: D \
**CAL**: CAL4 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-004`

**Statement**: 本システムは、 更新パッケージのデジタル署名を検証し、 改ざん・偽造を検知すること。

**Rationale**: 不正なファームウェアの注入は安全関連 ECU の機能喪失に直結し (安全)、 かつ車両は
攻撃対象となる (セキュリティ)。 そのため安全・セキュリティの双方で最高保証レベルとする。

### ロールバック対応

**Type**: REQUIREMENT \
**UID**: SWU-L0-003 \
**TYPE**: Functional \
**ASIL**: C \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-004`

**Statement**: もし更新後に異常が検出された場合、 本システムは直前のバージョンへ自動または手動で
ロールバックできること。

### 走行中の更新禁止

**Type**: REQUIREMENT \
**UID**: SWU-L0-004 \
**TYPE**: Restriction \
**ASIL**: D \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-004`

**Statement**: もし車両が IG-ON かつ車速 > 0 の場合、 本システムは ECU フラッシュ書込を開始しないこと。

**Rationale**: 走行中の書込中断や挙動変化は、 安全機能の喪失に直結するため。

### 更新所要時間

**Type**: REQUIREMENT \
**UID**: SWU-L0-005 \
**TYPE**: Non-Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-004`

**Statement**: 本システムの 1 ECU 当たりの平均更新時間 (検証 + 書込 + 再起動) は、 5 分以内で
あること。

### 改ざんパッケージの不適用

**Type**: REQUIREMENT \
**UID**: SWU-L0-006 \
**TYPE**: Restriction \
**ASIL**: D \
**CAL**: CAL4 \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-004`

**Statement**: もし更新パッケージの署名検証に失敗した場合、 本システムは当該パッケージを
インストールせず破棄すること。

**Rationale**: SWU-L0-002 (改ざん検知) の検知結果を受けた安全反応。 検知と「適用しない」反応を
分離し、 各々を独立に検証する。

### 走行中のダウンロード許容

**Type**: REQUIREMENT \
**UID**: SWU-L0-007 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-004`

**Statement**: 走行中も、 本システムは、 更新パッケージのダウンロードを実行できること。

**Rationale**: 書込 (フラッシュ) は走行中禁止 (SWU-L0-004) だが、 ダウンロードは安全に影響しない
ため許容し、 停車後すぐ書込へ移れるようにする。

### 更新進捗の可視化

**Type**: REQUIREMENT \
**UID**: SWU-L0-008 \
**TYPE**: Functional \
**ASIL**: QM \
**LAYER**: L0_Stakeholder
**Relations**:
- **Type**: `Parent` \
  **ID**: `UC-004`

**Statement**: 本システムは、 OTA 更新の進捗を、 ドライバーが SOVD クライアントで確認できるように
すること。
