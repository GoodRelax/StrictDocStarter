# 04 StrictDocStarter 詳細ガイド

[README-ja.md](../README-ja.md) が意図して省いた内容をすべて置いてあります。
README は「ブラウザに要求ツリーが出る」ところまでを担当します。本書はそのあと、
個々の仕組みを知りたくなったときに読むものです。

英語版は [04-starter-guide.md](04-starter-guide.md) にあります。

## プロキシ環境の場合

企業などで**認証付きプロキシ**を設定している場合、`winget` / `pip` / `git` / `gh` の
外部通信が遮断されることがあります。SSL インスペクションで証明書検証に失敗する場合も
あり、どちらもダウンロードに失敗してセットアップが完了しません。

**セットアップ実行前に IT 部門へ相談してください。** この 4 つのツールがプロキシを
通過できるよう、ユーザーの**環境変数** (`HTTP_PROXY` / `HTTPS_PROXY`、および `winget` /
`pip` のプロキシ設定) を設定します。StrictDocStarter はプロキシを**検出して警告する
だけ**で、設定は代行しません。

## 同梱物

| ツール                                            | 役割                                                                                                                                                                                                                                           | 起動                         |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| `setup-strictdoc.bat`                             | 初回セットアップ (管理者): StrictDoc ツールチェイン + 開発ツールを導入し、任意でリポジトリを clone。プランを表示し一度だけ確認。`setup.config.json` で全設定可 (下記「setup が導入するもの」参照)。                                            | ダブルクリック → UAC → `yes` |
| `launch-strictdoc.bat`                            | 日常利用: **フォルダ (または `.sdoc` ファイル) をドラッグ&ドロップ**して開く — もしくはダブルクリックで入力を促す。1 文書 = 1 ウィンドウ。                                                                                                     | D&D / ダブルクリック         |
| `change-color-mode.bat`                           | 生成ページの見た目を **auto / light / dark** で切り替え。既定は `auto` (Windows の設定に追従)。                                                                                                                                                | ダブルクリック               |
| `try-json-query-en.bat` / `try-json-query-ja.bat` | 仕様書を JSON にして `jq` で引く手順を 7 段でなぞる練習用。各手順が自分で説明し、Enter を待ってから、いま表示したコマンドを実行します。プロジェクトフォルダをドロップするか、ダブルクリックで同梱の `md-basic-en` / `md-basic-ja` を使います。 | D&D / ダブルクリック         |
| `gather-logs.bat`                                 | 障害時のログ + 診断レポートを ZIP に回収                                                                                                                                                                                                       | ダブルクリック               |

## setup が導入するもの

`setup-strictdoc.bat` (既定の `auto`) は導入済みツールを検出し、プランを表示してから一度だけ
`yes` を確認します。導入済みのものはスキップされるため再実行は安全です (冪等)。既定の導入内容:

**必須 (常に導入):**

- Git / Python (3.13) / GitHub CLI — winget
- StrictDoc — `pip install strictdoc`
- VS Code + **Claude Code** 拡張 (`anthropic.claude-code`)

**追加の開発ツール (既定で ON。`setup.config.json` で切替):**

- Obsidian / Windows Terminal / PowerShell 7 / ripgrep / jq
- VS Code 拡張: Markdown All in One / Markdown Preview Mermaid / PowerShell / Python /
  日本語言語パック / GitLens

**任意 (既定で OFF。`setup.config.json` でオプトイン):**

- Claude Code **CLI** (winget または npm。npm の場合は Node.js LTS も先に導入)
- **Git リポジトリの clone** と Obsidian Vault へのリンク (ジャンクション) 作成:
  `repository.url` (および `paths.clone_target` / `vault`) を設定。URL が空の間はスキップ。
  private リポジトリでは `gh auth login` のブラウザ認証が走ります。

導入**前**に内容を確認・変更するには、**`setup-strictdoc.bat config`** (管理者不要) で
`setup.config.json` を生成・編集してから `setup-strictdoc.bat` をダブルクリックします。
その他のサブコマンド: `check` (`env-report.json` 出力) / `dryrun` (プラン表示のみ) / `help`。

## ドキュメントを開く

`launch-strictdoc.bat` は **ランチャ**です: `.sdoc` 要求が入ったフォルダを StrictDoc の
Web サイトとしてブラウザで開きます。メニューはありません — **1 文書 = 1 ウィンドウ**。

- **ドラッグ&ドロップ**: フォルダを `launch-strictdoc.bat` にドロップして開きます。`.sdoc`
  **ファイル**をドロップすると、その親フォルダを開きます。
- **ダブルクリック** (ドロップ無し): フォルダを尋ねられます。**Enter** で最終使用フォルダ
  (初回は同梱サンプル)、**Q** で中止。
- **複数文書**: 各文書が専用のサーバウィンドウと専用ポート (`5111`, `5112`, …、開始ポート +20
  まで、すべて `127.0.0.1`) で並行起動します。2 つ目のフォルダをドロップすれば同時に開けます。
- **停止**: その文書の**サーバウィンドウを閉じる** (または窓内で `Ctrl+C`)。窓を閉じる =
  そのサーバ停止。ランチャ自身の窓は起動を渡したあと閉じます。
- **ブラウザ再表示**: 既に起動中の文書は、同じフォルダをもう一度ドロップするとタブを
  開き直すだけです (サーバは二重起動しません)。
- **設定**: `server.config.json` の `host` / `port` (自動割当の開始ポート) / `open_browser` /
  `output_path` / `color_mode`。`project_path` はプロンプトの既定値で、最終使用フォルダに
  自動更新されます。
- `.sdoc` の**文法エラー**時はサーバウィンドウが即閉じることがあるため、ランチャが自分の
  窓に実際のエラーを表示します。

### 生成物の出力先

各プロジェクトが**それぞれ専用の**出力先 `<指定フォルダ>\output\strictdoc\` を持ちます。
以前は全プロジェクトが StrictDocStarter 内の 1 か所を共有しており、**2 つ同時に開くと
先に開いた方のプロジェクトインデックスに後から開いた方の文書一覧が表示されていました。**

出力先がプロジェクト内になるため、ランチャは Git がそこを無視しているかを確認し、
していなければ**追記すべき 1 行を表示します。`.gitignore` は書き換えません** — 追記は
ご自身で行ってください。Git 管理外の場合、および既に無視されている場合は何も表示しません。

別の場所にしたい場合は `server.config.json` の `output_path` を設定してください。

### ライトとダーク

`change-color-mode.bat` で `color_mode` を `auto` (既定) / `light` / `dark` に設定します。
**次にそのプロジェクトを開いたときから反映**され、起動中のサーバは元のままです。

StrictDoc 自身はダークモードを持たないため、これは**スタイルシートを上から重ねる**方式です。
本文と Mermaid 図は暗くなりますが、小さな操作部品は一部が対象外で、ソースコードの
シンタックスハイライトは変わりません。仕組みは
[Path to custom CSS](https://strictdoc.readthedocs.io/) を参照してください。

### 設定ファイルの更新を尋ねられたら

古い StrictDocStarter で開いたプロジェクトには古い `strictdoc_config.py` が残っており、
このファイルが**左ツールバーに出る画面**を決めています。ランチャは「自分が書いた、かつ
未編集の」設定ファイルを見つけた場合に限り、**何がどう変わるかを示し、バックアップを
取ってから**確認します。断れば、次の新版が出るまで再度尋ねません。

**ご自身で書いた設定ファイルは絶対に変更しません** — 追記すべき行を表示するだけです。

画面は英語表示です。訳は次のとおりです。

| 英語表示                                                 | 意味                                             |
| -------------------------------------------------------- | ------------------------------------------------ |
| `What changes: 4 settings enabled -> 7 settings enabled` | 有効な設定が 4 個から 7 個に増えます             |
| `2 icons in the left toolbar -> 5 icons`                 | 左ツールバーのアイコンが 2 個から 5 個になります |
| `Turned on: + Project statistics screen`                 | 統計画面が有効になります                         |
| `+ Traceability matrix screen`                           | トレーサビリティマトリクス画面が有効になります   |
| `+ Tree map screen`                                      | ツリーマップ画面が有効になります                 |
| `Your documents are NOT touched.`                        | **文書ファイルには一切触れません**               |
| `A backup is written first`                              | 先にバックアップを取ります (`.bak-<日時>`)       |
| `Want to compare first?`                                 | 変更後のファイルを事前に見たい場合の置き場所     |
| `Update the settings file now? [Y/n]`                    | 更新しますか。**Enter で「はい」**               |
| `Nothing was changed.`                                   | 何も変更していません (断った場合)                |

> 古い StrictDocStarter を使い続けている場合、ここまでの機能はいずれも届きません。
> `launch-strictdoc.bat` と `lib\` フォルダを新しいものに差し替えてください。

## 同梱サンプル

**同梱サンプル 6 件は、何も入れずにブラウザで読めます:
<https://goodrelax.github.io/StrictDocStarter/>。** GitHub Actions が 1 件ずつ
別プロジェクトとして書き出して公開します。生成物はコミットしません。

サンプルはすべて対になっています。`md-` は Markdown、`sd-` は `.sdoc` (RST) で
書いてあります。2 つは**要求の核**を共有しており、文法も `SYS-` / `SW-` / `TC-` の
識別子も要求文も同じなので、フォルダを並べて記法を読み比べられます。
**`sd-` のほうは意図して小さくしてあります** (文書 6 件に対して 11 件)。記法を
見せるためのものであり、`md-` が持つ手引きをもう一部持つためのものではありません。

| パス                                           | 内容                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `samples/md-basic-en/`                         | **既定。** **`.md` の基本 — 自分の仕様書はこのフォルダを丸ごと写して始める。** 要求仕様書として最低限成り立つ一式: 上位要求 3 件・それを指す下位要求 4 件・それを指すテストケース 4 件・要求そのものに載せたレビュー欄を**それぞれ別ファイル**に置き、トレーサビリティがファイルをまたぐようにしてある。共有の文法定義 (`basic.sgra`) が `TEST_CASE` のノード型と `REVIEW_STATUS` / `REVIEW_COMMENT` / `REVIEW_ACTION` のフィールド、`Verifies` の関係ロールを足す。ほかに、意図して要求にしない地の文・別の `.md` へのリンク・外出しした Mermaid 図・SVG 画像・AI に読ませるために要るもの・ブラウザでの編集と Claude との共同作業。英語。 |
| `samples/md-basic-ja/`                         | 同じ仕様書の日本語版。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `samples/sd-basic-en/`、`samples/sd-basic-ja/` | **同じ仕様書を `.sdoc` で書いた版。** `.sdoc` 固有の内容を追加: RST の表 2 形式 (`+---+` grid と `===` simple)・図の断片を本文へ取り込む `[DOCUMENT_FROM_FILE]` (Markdown に相当物は無い)・パイプ表のために `MARKUP: Markdown` を宣言した文書 1 つ。                                                                                                                                                                                                                                                                                                                                                                                        |
| `samples/md-sovd-automotive-ja/`               | 日本語のフル SOVD (Service-Oriented Vehicle Diagnostics; ASAM SOVD / ISO 17978) 要求仕様書 — 全体概要・ステークホルダ要求・ユースケース・認証・データアクセス・DTC 診断・OTA ソフトウェア更新・アーキテクチャ・HTTP API・テスト仕様/結果。ASIL (ISO 26262) と A-SPICE レイヤの custom field、Mermaid 図、数式、トレーサビリティ付き。要求は EARS、テストは Gherkin で書いてあり、本文は全部 `.md`。                                                                                                                                                                                                                                         |
| `samples/md-sovd-automotive-en/`               | 上記の英語版。                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |

`md-basic-en` は、`launch-strictdoc.bat` を何もドロップせずにダブルクリックしたときに開く
サンプルです。意図して小さくしてあります — 全部読み切ってから丸ごと写せることが狙いです。

**本格的な例を見るには、`samples\md-sovd-automotive-en` を `launch-strictdoc.bat` に
ドラッグ&ドロップしてください。** 21 文書・要求 122 件で、EARS の要求文、Gherkin のテスト、
ASIL と A-SPICE の custom field、Mermaid 図、数式、そして要求 → 設計 → API → テスト仕様 →
結果を辿るトレーサビリティが入っています。起動時の既定を別のフォルダにしたい場合は、
`server.config.json` の `project_path` を変更してください。

## Claude Code で仕様書を書く

[`claude-skills/strictdoc-md/`](../claude-skills/strictdoc-md) は、Markdown 版 StrictDoc
仕様書の読み書き・修正・監査を Claude に教える Claude Code の**スキル**です。`.md` の形、
export を止める規則、図・数式・コード・表・添付、クエリ集が教える `jq` クエリ全部と実測の
出力、そして StrictDoc 自身が報告しない失敗を見つける監査スクリプトが入っています。
自分の `.claude/skills/` にフォルダを写すと使えます。

```bash
cp -r claude-skills/strictdoc-md ~/.claude/skills/
```

スキルの中のクエリはすべて `samples/md-basic-en` に対して実測してあります。中身の一覧と、
公開用の複製を Claude Code が実際に読む複製と揃えておく方法は
[`claude-skills/README.md`](../claude-skills/README.md) にあります。

## サンプルとドキュメントを検査する

`tools/` には、このリポジトリが自分自身に対して走らせるスクリプトが入っています。これらは
保守用の道具であり、Windows クイックスタートの一部ではありません。サンプルかドキュメントを
変更するときにだけ使ってください。どれも `strictdoc export --formats=json` が書く JSON を
入力に取ります。

| 道具                                                                  | 何を見るか                                                                                          |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [`tools/ascii-audit.py`](../tools/ascii-audit.py)                     | コードと設定ファイルが非 ASCII 文字を含まないこと (NFR-010)                                         |
| [`tools/verify-jq.py`](../tools/verify-jq.py)                         | 文書に埋め込んだ `jq` の例が今も走ること                                                            |
| [`tools/check-jq-output.py`](../tools/check-jq-output.py)             | クエリの下に貼った出力が、そのクエリが今出す内容と一致すること                                      |
| [`tools/run-query-fixture.py`](../tools/run-query-fixture.py)         | 全クエリにヒットするよう組んだ投入用データに対して、どのクエリも 1 行以上返すこと                   |
| [`tools/check-references.py`](../tools/check-references.py)           | 引用した見出し・`[LINK:]` の宛先・地の文に書いたファイル名がすべて解決すること                      |
| [`tools/check-symmetry.py`](../tools/check-symmetry.py)               | `ja` と `en` の版が同じ文書・ノード・関係を持つこと                                                 |
| [`tools/check-numbers.py`](../tools/check-numbers.py)                 | 地の文が主張する件数が、隣に貼ってある出力と合っていること                                          |
| [`tools/check-skill-sync.py`](../tools/check-skill-sync.py)           | 同梱スキルが実例と同じことを言い続けていること                                                      |
| [`tools/check-grammar-copies.py`](../tools/check-grammar-copies.py)   | 同じ名前の文法ファイルの各コピーが、今も同じ文法を持っていること                                    |
| [`tools/check-format-fixpoint.py`](../tools/check-format-fixpoint.py) | Markdown 整形器を通した**後でも** export が通ること、および整形器が手を出さない形で配られていること |

**`.md` のサンプルを編集したら走らせるのはこれです。** そしてこれだけが、export を読むだけでは
済まない検査です。**`strictdoc export` が通ったことは、その仕様書を人に渡してよい証拠になりません。**
整形器で壊れる記法は、書かれたままなら export が通り、整形が 1 度走って初めて落ちるからです。
strictdoc 0.27.1 / prettier 3.5.3 で実測したところ、`samples/md-sovd-automotive-en` は 294 ノードを
export した後、`prettier --write` を 1 回かけただけで
`duplicate field names in a valid requirement node are not allowed` で停止しました。
**利用者が開いて保存した瞬間に文書が壊れる状態で配られていた**ということです。

そこでこの検査は、フォルダを複製し、複製に整形をかけ、もう一度 export して、
両側のノードと関係を突き合わせます。スクリプト自体を変更したときは先に `--self-test` を
走らせてください。**検査ごとに 1 つずつ壊した見本を作り、狙った検査が実際に鳴ることを要求します** ——
「0 件」は、各検査が鳴るのを見るまでは何の意味も持たないからです。

```bash
python tools/check-format-fixpoint.py
```

**対処として整形器を止めてはいけません。** `.prettierignore` や `editor.formatOnSave: false` は、
仕様書を守るために同じフォルダの普通の Markdown 編集をすべて犠牲にします。その設定は配布先には
付いていきませんし、誰かが外した瞬間に壊れます。**同梱サンプルは代わりに「整形器が手を出さない形」で
配ってあります** —— 利用者の環境には何も要求しません。

各サンプルフォルダには `endOfLine: auto` と書いた小さな `.prettierrc.yaml` が 1 つ入っており、
**フォルダを複製すると一緒に付いていきます。** これは整形を止める設定の**逆**で、規則はすべて
そのまま効きます。効果は「各ファイルが既に持っている改行をそのまま尊重せよ」と Prettier に
伝えることだけです。おかげで、**あなたが** Windows で作った Markdown（CRLF）も、同梱ファイル（LF）も
等しく受け入れられ、どちらも保存時に書き換えられません。Prettier の既定は LF なので、この 1 行が
無いと、あなたが足したファイルは**改行が違うというだけの理由で**未整形と報告されます。

[`tools/capture-manual-ja.py`](../tools/capture-manual-ja.py) と
[`tools/capture-manual-en.py`](../tools/capture-manual-en.py) は、起動中のサーバに対して
`09-browser-guide.md` の写真を撮り直します。画面と写真がずれないようにするためです。

## 動作確認済み StrictDoc バージョン

同梱サンプルとドキュメントは **strictdoc 0.27 以降**を前提とし、**0.27.1**
(Windows 11 / Python 3.13) で検証済みです。既定のインストールは**最新版**を取得するため、
この前提は何もしなくても満たされます。再現性を固定したい場合はバージョンを固定して
ください (下記参照)。それより古い版に固定する場合、変わる点は
[`docs/02-sdoc-authoring.md`](02-sdoc-authoring.md) の §9 にあります。

`setup-strictdoc.bat check` が導入済みバージョンを表示し、`env-report.json` にも記録します。

## StrictDoc のバージョンを変える

**setup は、`setup.config.json` が指定したバージョンに合わせます。** 既定の `latest` なら、
`setup-strictdoc.bat` を実行するだけで最新版になります。**何が起きるかはプランに出ます。**

```
Phase C: StrictDoc (pip package)             [REQUIRED]
  - [INSTALL] strictdoc   installed: 0.27.1 - strictdoc.version='latest',
                          will upgrade if a newer release exists
```

`yes` で更新、それ以外なら**何も触らずに中止**します。確認なしに変わることはありません。

setup 全体を走らせずにバージョンだけ変えたい場合は、こちらを使います。

```
setup-strictdoc.bat upgrade
```

現在のバージョン・実行するコマンド・元に戻すコマンドを表示してから `yes` を尋ねます。
`-Preview` を付けると、pip にどのバージョンになるかを先に問い合わせます (ネットワーク往復が
1 回増えます。計測した環境では約 1 分かかりました)。

どちらも、どのバージョンにするかは `setup.config.json` の `strictdoc.version` で決まります。

| 値              | 意味                                           |
| --------------- | ---------------------------------------------- |
| `latest` (既定) | PyPI の最新版                                  |
| `==0.27.1`      | このバージョンちょうど。再現性を固定したいとき |
| `~=0.27.0`      | `>=0.27, <0.28`                                |
| `0.27.1`        | 演算子なし。`==0.27.1` として読まれます        |

**setup に動かされたくない場合はバージョンを固定してください。** `==0.27.1` で 0.27.1 が
入っていれば、Phase C は `[SKIP] ... (matches strictdoc.version)` と表示して pip を
呼びません (文字列の比較だけなので待ち時間もゼロです)。

同じ設定が初回インストール時にも適用されます。解釈できない値の場合、`latest` に黙って
フォールバックせずコマンドを停止します。

**0.27 未満への固定は推奨しません。** 同梱サンプルは `strictdoc_config.py` に
`MATHJAX` / `MERMAID` を列挙していません — 0.27 では既定で有効であり、列挙すると
DEPRECATION 警告が出るためです。古い版ではこの指定が必要なので、**図が生のテキストとして
表示され、数式も描画されません。** 他の差分は
[`docs/02-sdoc-authoring.md`](02-sdoc-authoring.md) の §9 にあります。

ランチャを使わない場合は `pip install --upgrade strictdoc` でも同じことができます。

## 動作要件

- Windows 11 (`winget` 同梱)
- `setup-strictdoc.bat` は管理者権限が必要 (UAC で取得)。`launch-strictdoc.bat` は一般ユーザ権限で動作
- ダウンロードのためのインターネット接続 — `winget` / `pip` / `git` / `gh` (GitHub CLI) /
  VS Code マーケットプレイス (Claude Code CLI を npm で導入する場合は `npm` も)
- 認証付きプロキシ環境の場合は[プロキシ環境の場合](#プロキシ環境の場合)を参照
