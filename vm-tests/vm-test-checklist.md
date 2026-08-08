# StrictDocStarter VM テストチェックリスト

クリーン Windows 11 VM で StrictDocStarter の挙動を回帰検証する。 **T0 (推奨) で一気通貫**、 または個別ステップを手動実行。

仕様参照: [setup-spec.md §5 Test Strategy](../docs/setup-spec.md) (11 シナリオ仕様)。

---

## T0: クリーン VM での通しテスト (推奨、一発)

**所要 80〜110 分、手動操作は ZIP 展開 + ダブルクリック 3 回 + 手動 SC-015 / SC-016 / SC-017 / SC-018 (35 分)。**

> **今回の重点は SC-016 (upgrade)。** シナリオ 8 と SC-016 が新規で、 それ以外は回帰確認。
> **時間が無いなら T0 のステップ 3 → 4 → 5 → 7 → 12 だけでも成立する。**
> ステップ 3 と 5 (`check` の 2 回) は省かない — **どの版で試験したのかが残らないと、 結果を後から読めない。**

### 手順

1. **VM スナップショットを復元** (完全クリーン状態)
2. ホスト `StrictDocStarter\temp\StrictDocStarter.zip` を VM デスクトップに Ctrl+V → 「すべて展開」 → `Desktop\StrictDocStarter\` 1 階層作成 (ZIP の作り方は「前提」節)
3. **`setup-strictdoc.bat check`** を実行 (**setup の前**。 admin 不要) → `env-report.json` が出る
   → **スナップショットが本当にクリーンか**を先に確定させる。 `strictdoc: NOT FOUND` と
   `existing_tools` が全て空であることを確認。 **ここで何か入っていたらスナップショットが汚れており、
   以降の結果は全て無効**なので、先に復元をやり直す
4. **`Desktop\StrictDocStarter\setup-strictdoc.bat`** ダブルクリック → UAC → `yes` → 完走待ち → Enter (= T1 ベースライン、 Phase A〜E 全 OK)
5. **`setup-strictdoc.bat check`** を再実行 → **導入された strictdoc の版を記録する**
   → クリーン VM は `latest` を取るため、 **その日の PyPI 最新が入る**。 以降の全ての判断がこの版を基準にする。
   `env-report.json` をホストへ退避しておくと後で照合できる
6. (任意) `setup-strictdoc.bat dryrun` → plan の Phase C 行が `already installed: <版>` に変わることを確認
7. **`Desktop\StrictDocStarter\vm-tests\run-tests.bat`** ダブルクリック → UAC → 11 シナリオ自動実行 → サマリ → Enter
   → 冒頭の `Baseline strictdoc: <版>` と末尾の `strictdoc: <版> (unchanged from baseline)` を必ず見る
8. **手動 SC-015 (FR-209 abort)** の確認: 別途 `setup-strictdoc.bat` ダブルクリック → UAC → plan 表示 → **`no`** 入力 → `[WARN] Aborted -` 3 行 + `Config:` 行が表示されることを目視確認 → Enter
9. **手動 SC-016 (upgrade)** を実施 — 自動テストが見られない対話部分
10. **手動 SC-017 (サンプル目視)** を実施 — ランチャ経由で 3 サンプルを開く
11. **手動 SC-018 (サーバ実行中の pip 保護)** を実施 — FR-343a。 ホスト機で実際に壊れた経路
12. **`vm-tests\gather-test-logs.bat`** ダブルクリック → エクスプローラ選択状態の ZIP を Ctrl+C → ホストの `TestResult/` に Ctrl+V

### 期待結果

- ステップ 3: `strictdoc: NOT FOUND` + `existing_tools` が空 (= スナップショットがクリーン)
- ステップ 4: Phase A〜E 全 OK、 Phase D は SKIP (URL 空既定)
- ステップ 5: `strictdoc: <版> (README records 0.27.1)` — **この版を記録する。以降の基準**
- ステップ 6: dryrun 完走、 plan に `[REQUIRED]` / `[OPTIONAL]` / `[SKIP]` / `[INSTALL]` タグ表示
- ステップ 7: **PASS / FAIL / SKIP の 3 状態で集計される**。 `NegativeAbort` は常に SKIP (手動 SC-015 に委ねるため)。
  **user scope で入っているツール (jq / ripgrep / Obsidian) の uninstall シナリオも SKIP になる** —
  `run-tests.bat` は昇格して動くが、 winget は昇格中に user scope のパッケージを削除しないため。
  **これは製品の不具合ではない。** exit code は SKIP を失敗に数えない。
  冒頭の `Baseline strictdoc:` がステップ 5 の版と一致し、 末尾が `(unchanged from baseline)` であること。
  **`(CHANGED - a scenario did not restore it)` が出たら FAIL 扱い** — シナリオ 8 の復元が効いていない
- ステップ 8: abort guidance 3 行が表示される
- ステップ 9: SC-016 の A〜I が全て期待どおり (**特に G と H — `no` で変わらず、 `yes` で最新版になること**)
- ステップ 10: SC-017 で **3 サンプルとも DEPRECATION 警告が出ず**、 図と数式が描画される
- ステップ 11: SC-018 で **サーバ窓が開いている間は Phase C が `[BLOCKED]`** になり、 pip が一切呼ばれない
- ステップ 12: `StrictDocStarter-test-result-*.zip` に per-scenario log (11 件) + final setup.log + diagnostics.txt

---

## 前提

- クリーン Win11 VM (Hyper-V 等)、 スナップショット取得済
- VM に winget が利用可能 (`winget --version` で確認)
- VM のネットワーク疎通 OK
- ホストの `StrictDocStarter\temp\StrictDocStarter.zip` を VM に運ぶ準備 (拡張セッションのクリップボード)

**ZIP の作り方 (専用スクリプトは無い)。** リポジトリのルートで PowerShell:

```powershell
$stage = Join-Path $env:TEMP "StrictDocStarter"
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
git ls-files | ForEach-Object {
    $dst = Join-Path $stage $_
    New-Item (Split-Path $dst) -ItemType Directory -Force | Out-Null
    Copy-Item $_ $dst
}
New-Item temp -ItemType Directory -Force | Out-Null
Compress-Archive -Path $stage -DestinationPath temp\StrictDocStarter.zip -Force
```

`git ls-files` を基準にするのは、`docs/in-private-work/` ・ `output/` ・ `setup.config.json` ・
`*.log` を**除外し忘れないため**。 追跡対象のファイルだけが入り、作業ツリーの未コミット変更は
そのまま反映される (= 検証したいものが入る)。

---

## 11 シナリオ一覧 (run-tests.bat で自動)

| # | シナリオ | 内容 | uninstall 対象 | 所要 (目安) |
|---|---|---|---|---|
| 1 | Idempotency | 何も変えず再実行、 全 SKIP | (なし) | ~30 秒 |
| 2 | PartialOptional | 3 件 uninstall → 再 install。 **jq / ripgrep は user scope のため昇格下では消せず SKIP になる** | jq, ripgrep, gitlens 拡張 | ~3〜5 分 |
| 3 | RequiredOnly | gh uninstall → 再 install | GitHub CLI | ~2 分 |
| 4 | ExtensionsOnly | 拡張 2 件 uninstall → 再 install | bierner.markdown-mermaid, ms-python.python | ~30 秒 |
| 5 | Mixed | optional + 拡張 1 件 uninstall (他シナリオと完全独立)。 **Obsidian は user scope のため SKIP になる** | Obsidian, MS-CEINTL.vscode-language-pack-ja | ~3〜5 分 |
| 6 | ClaudeExtension | Phase A coverage、 Claude 拡張 uninstall → 再 install | anthropic.claude-code | ~30 秒 |
| 7 | StrictDocPip | Phase C coverage、 pip uninstall → 再 install → **元の版へ復元** | strictdoc (pip) | ~3〜5 分 |
| 8 | **StrictDocUpgrade** | FR-334〜338: `strictdoc.version` を別版にピン → **`auto` がそのピンを適用すること**を確認 → 満たされたピンでの再実行が **no-op** であることを確認 → `upgrade` でも版が動くことを確認 → config と版を復元 | (なし、 strictdoc の版を一時変更) | ~3〜5 分 |
| 9 | NegativeAbort | **常に SKIP** (手動 SC-015 に委ね)。 従来は PASS と表示されていた | (なし) | ~1 秒 |
| 10 | NegativeClaudeBoth | FR-305 排他: config 改変 → 期待動作確認 → 復元 | (なし、 config 一時改変) | ~1〜2 分 |
| 11 | DryrunAssert | dryrun 出力の [REQUIRED]/[OPTIONAL]/[SKIP] タグ + Phase E sort assert | (なし、 dryrun のみ) | ~10 秒 |

シナリオ独立性は **setup-spec.md §5.3 uninstall マトリクス** で保証。 各ツールは 1 シナリオでのみ touch される。

実行モード:
- `run-tests.bat` または `run-tests.bat real` — 本番モード (uninstall + reinstall)
- `run-tests.bat dryrun` — dryrun モード (uninstall せず planner だけ走らせる、 host でも実行可)
- `run-tests.bat foo` (typo) → ValidateSet で **fatal stop** (FR-1003)

タイムアウト: 1 シナリオ 5 分 (`Start-Job -Timeout`)、 タイムアウト時は exit 124 で FAIL 記録 (子孫プロセスは killed されないので Task Manager で winget/msiexec を手動 kill する場合あり)

---

## T1: クリーン VM での初回フル実行 (手動)

**目的:** クリーン状態から `setup-strictdoc.bat` 1 回で開発環境を構築できること。

### 手順

1. VM スナップショット復元
2. `StrictDocStarter.zip` を VM デスクトップに転送 → 展開
3. `Desktop\StrictDocStarter\setup-strictdoc.bat` ダブルクリック
4. UAC → 「はい」 → プラン → `yes` → Phase A〜E 完走 → Enter

### 期待結果

```text
=== Summary ===
  Phase A  : OK    (VS Code + Claude Code 拡張)
  Phase B  : OK    (Git + Python + gh)
  Phase C  : OK    (strictdoc)
  Phase D  : SKIP  (repository.url 空既定)
  Phase E  : OK    (Obsidian/Terminal/PS7/ripgrep/jq + VS Code 拡張群)
```

### 確認コマンド (新しい PowerShell で)

```powershell
code --list-extensions | findstr anthropic
git --version
python --version
strictdoc --version
gh --version
rg --version
jq --version
```

すべてバージョン情報が出れば OK。

---

## SC-015: 手動 negative test (FR-209 abort guidance)

run-tests.bat の T_negative_abort は **自動化不能** (PowerShell の Read-Host が piped stdin を読まないため)。 v1.0 では手動で確認:

### 手順

1. T1 完了後の VM で `Desktop\StrictDocStarter\setup-strictdoc.bat` ダブルクリック
2. UAC → 「はい」 → plan 表示 → `Proceed with the above? Type 'yes' to install, anything else to abort: ` プロンプト
3. **`no` と入力 → Enter**

### 期待結果

以下 5 行が表示される:

```text
[WARN]  Aborted - 'yes' not entered.
[INFO]  To customize installation:
[INFO]    1. Edit setup.config.json (path shown below)
[INFO]    2. Re-run setup-strictdoc.bat (idempotent - already-installed tools are skipped)
[INFO]  Config: C:\Users\<your-username>\Desktop\StrictDocStarter\setup.config.json
```

`<your-username>` 部分が `$env:USERNAME` 実値で展開済であることを確認 (`<user>` リテラルが残っていれば FR-208 違反)。

---

## SC-016: 手動 upgrade テスト (FR-334〜338)

`T_strictdoc_upgrade` は `-NonInteractive` で走るため **`yes` プロンプトそのものを検証できない**。
版が変わる操作の確認は人が見る。 **T1 完了後の VM で実施する。**

`setup.config.json` は `Desktop\StrictDocStarter\setup.config.json`。 編集はメモ帳でよい。

> **前提: 導入済み版が最新でないこと** (例 0.23.1)。 最新版が入っている状態では B と H が
> 「変化なし」 になり、 何も確かめられない。 最新なら先に `pip install "strictdoc==0.23.1"`
> で下げてから始める。

| # | 操作 | 期待 |
|:-:|---|---|
| **A** | `setup-strictdoc.bat check` | 画面末尾に `strictdoc: <版>`。 `env-report.json` に `strictdoc` ブロック (`installed` / `verified_version` / `matches_verified`) と `existing_tools.strictdoc` |
| **B** | `setup-strictdoc.bat dryrun` | Phase C 行が **`[INSTALL] strictdoc  installed: 0.23.1 - strictdoc.version='latest', will upgrade if a newer release exists`**。 **`[SKIP]` ではない** (FR-335 の reconcile) |
| **C** | `setup-strictdoc.bat upgrade` → プロンプトに **`no`** | `Installed now` / `Configured spec` / `Will run` / `To go back afterwards` の 4 行が**先に**出る。 `no` で `[WARN] Aborted - strictdoc left at <版>.`。 **`strictdoc --version` が変わらないこと** |
| **D** | `strictdoc.version` を `"newest please"` にして `dryrun` | Phase C 行が `INVALID strictdoc.version 'newest please' ... - Phase C will stop` |
| **E** | 続けて `setup-strictdoc.bat upgrade` | `[ERROR] Invalid strictdoc.version ...` + 受理される形式の案内。 **`latest` にフォールバックしない**。 版は変わらない |
| **F** | `strictdoc.version` を **`"==0.23.1"`** にして `dryrun` | Phase C 行が **`[SKIP] strictdoc  already installed: 0.23.1 (matches strictdoc.version='==0.23.1')`**。 **ピンが一致していれば pip を呼ばない** — 画面が即座に出ること (待ちが入ったら実装が間違い) |
| **G** | **`H` の主役。** `strictdoc.version` を `"latest"` に戻して **`setup-strictdoc.bat`** → プランで Phase C が `[INSTALL]` であることを確認 → **`no`** | **中止され、 版が変わらないこと。** 確認なしに変わらないことの担保 |
| **H** | 同じく `setup-strictdoc.bat` → 今度は **`yes`** | **`[OK] strictdoc: 0.23.1 -> <最新版>`** が出て、 続けて `docs/02-sdoc-authoring.md` への誘導と `pip install "strictdoc==0.23.1"` (戻し方) が表示される。 **`strictdoc --version` が最新版になること (FR-335)** |
| **I** | もう一度 `setup-strictdoc.bat` → `yes` | **`[OK] strictdoc <最新版> (already up to date)`**。 2 回目は変化しないこと |

> **D / E で編集した `setup.config.json` は F 以降の前に必ず戻す。** 戻し忘れると以降が全て停止する。

> **旧版からの変更点。** 以前の H は 「`setup-strictdoc.bat` を実行しても版が変わらないこと」
> を期待していた。 **FR-335 の反転により逆になった** — 設定が `latest` なら setup で最新版に
> なるのが正しい。 変わらないでほしい場合は `strictdoc.version` を固定する (F)。

## SC-017: 同梱サンプルの目視 (0.27.1 での描画)

クリーン VM の `pip install strictdoc` は**最新版**を取る。 同梱サンプルは
**0.27 以降を前提**にしてあり、 前提が満たされる版で描画されることを見る。
古い版で何が変わるかは `docs/02-sdoc-authoring.md` §9。 ランチャ経由で実際に開く。

| # | 操作 | 期待 |
|:-:|---|---|
| **A** | `samples\sdoc-patterns` を `launch-strictdoc.bat` にドラッグ | ブラウザに **7 文書** (`_assets/flow-convert.md` を含む)。 **DEPRECATION 警告が出ないこと**。 `00-hello` が先頭に並ぶ。 `01-requirements` の冒頭に **図への本文リンク**があり、 クリックで `flow-convert` の文書へ飛べること。 `03-figures` で Mermaid・数式・**SVG と PNG の画像 2 枚が実際に表示される** (枠だけ・壊れ画像アイコンなら NG)。 **`_assets/flow-convert.md` が 1 個の文書として並び、 その中の Mermaid が図として描画される。** PAT-001 の File 関係からその文書へクリックで飛べること。 `04-markdown-form` が `.md` のまま並び **末尾の MD-003 に Mermaid 図と PNG が描画**。 `05-outputs` が並ぶ。 **`queries/README.md` が文書として現れないこと** (`exclude_doc_paths`) |
| **B** | `samples\md-sovd-automotive-ja` をドラッグ (**既定のサンプル**) | **DEPRECATION 警告が出ないこと**。 **21 文書** (本体 12 + `_assets/` の図 8 + 覚書 1) が描画され、 Mermaid 図と数式も出ること。 図の文書へは本文の `[LINK:]` からクリックで飛べること |
| **C** | `samples\sd-sovd-automotive-ja` をドラッグ | 同上。 **B と同じ 21 文書・同じ要求文が、 `.sdoc` (RST) の記法で描画されること** |
| **D** | `samples\md-sovd-automotive-en` / `samples\sd-sovd-automotive-en` をドラッグ | 同上 (英語版) |

> **どのサンプルでも警告が出ないのが正しい状態になった。** `MATHJAX` / `MERMAID` の列挙を
> 全サンプルの `strictdoc_config.py` から外したためである (0.27 では既定で有効)。
> **警告が出た場合も、 図や数式が描画されない場合も報告対象。**

> **`samples\hello-strictdoc` は無くなった。** `sdoc-patterns` の `00-hello.sdoc` が
> その役目 (写して始める最小の文書) を引き継いでいる。 **フォルダが残っていたら
> ZIP の作り直し漏れである。**

> **`samples\sovd-automotive-ja` と `samples\sovd-automotive-en` も無くなった。**
> `md-sovd-automotive-*` と `sd-sovd-automotive-*` の 4 つが同じ中身を 2 つの記法で
> 持っている。 **旧フォルダが残っていたら ZIP の作り直し漏れである。**

## SC-018: 手動 - サーバ実行中の pip 保護 (FR-343a / FR-344a)

**自動化していない。** サーバ窓を開いた状態を作る必要があるため。 **T1 完了後に実施する。**

> **背景:** ホスト機で実際に壊れた。 `launch-strictdoc.bat` で開いたサーバ窓が
> `strictdoc.exe` を掴んだまま `setup-strictdoc.bat` を実行し、 pip が
> `[WinError 32]` で失敗。 **旧パッケージを消し終えた後に失敗したため、
> `strictdoc.exe` だけが残り `ModuleNotFoundError` になった。**

| # | 操作 | 期待 |
|:-:|---|---|
| **A** | `samples\sdoc-patterns` を `launch-strictdoc.bat` にドラッグしてサーバを立てる。 **窓は開いたまま**にする | ブラウザが開く |
| **B** | その状態で `setup-strictdoc.bat dryrun` | Phase C 行が **`[BLOCKED] strictdoc  <n> strictdoc process(es) running (PID ...) - close the StrictDoc server window(s) first; ...`**。 **PID が実際の値であること** |
| **C** | 続けて `setup-strictdoc.bat` | **`yes` プロンプトの前に** `[WARN] 1 step(s) above are [BLOCKED] and will NOT run: strictdoc` が出ること (FR-345a) |
| **C2** | そのまま **`yes`** | Phase C が **pip を呼ばずに** 中止。 `[ERROR] <n> strictdoc process(es) are running.` + PID 一覧 + `Nothing has been changed.`。 **サマリが `Phase C  : BLOCKED (nothing was changed)`** であり **`FAILED` ではないこと**。 結びが `Stopped early: Phase C blocked.`。 **`strictdoc --version` が変わらないこと** |
| **D** | `setup-strictdoc.bat upgrade` | 同様に **`yes` プロンプトへ進む前に**中止すること |
| **E** | サーバ窓を閉じて `setup-strictdoc.bat dryrun` | Phase C が通常の `[INSTALL]` / `[SKIP]` に戻ること |

> **C で pip が走ってしまったら FR-343a 違反。** ログに `pip install` の行が出ていないことを確認する。

> **半壊状態 (FR-344a) の確認は任意。** 作るには pip を故意に中断させる必要があるため、
> 通常は C までで足りる。 作った場合の期待は Phase C 行が
> `on PATH but not runnable (interrupted upgrade?) - will reinstall`。

---

## ログ回収

`vm-tests\gather-test-logs.bat` ダブルクリック → `%TEMP%\StrictDocStarter-test-result-*.zip` 生成 → エクスプローラで select 状態 → Ctrl+C → ホストへ Ctrl+V

含まれるファイル (期待):
- `T_*.log` × 11 (各シナリオの setup-strictdoc.ps1 transcript)
- `T_*.runner-capture.log` × 11 (runner 側の生 stdout/stderr capture、 FR-1004)
- 最新 `setup.log` (T1 ベースラインの transcript)
- `diagnostics.txt` (Windows / PS / winget version、 既存 tool、 PATH 等)

---

## 報告いただきたい内容

各テスト (T1 / 11 シナリオ / SC-015 / SC-016 / SC-017 / SC-018) について:
- [ ] 期待通り動作したか (OK / NG)
- [ ] NG なら: 実際の出力と推定原因
- [ ] 所要時間 (NFR-008 で REAL モード合計 60 分以内が目標)
- [ ] サマリの 11 シナリオ結果 (PASS / FAIL / SKIPPED)
- [ ] 違和感を覚えた挙動・出力 (細かい UX 含む)

特に NegativeClaudeBoth は v1.0 で FR-305 が auto.ps1 に未実装の場合 `[WARN] FR-305 enforcement not yet observable in log` という soft warn が出る — それが想定挙動。

## トラブル発生時

`gather-test-logs.bat` で取得した ZIP を共有してください。 各 `T_*.runner-capture.log` には sub-process が transcript 開始前に死んだ場合の生エラーが含まれます (FR-1004)。
