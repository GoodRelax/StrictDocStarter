# StrictDocStarter

**One-click Windows quickstart for [StrictDoc](https://github.com/strictdoc-project/strictdoc).**
Unzip, double-click, and go from a clean Windows 11 PC to browsing a real requirements
tree in your browser — no manual Python or command-line setup.

> ### Scope — a companion, not a replacement
>
> StrictDocStarter is a community **Windows quickstart** that **complements, not replaces**,
> the official StrictDoc. It **delegates** the server, project scaffolding, and configuration
> to the official tools — `strictdoc server`, `strictdoc new`, and `strictdoc_config.py` — and
> only adds:
>
> - a Windows **bootstrap** (installs Python + StrictDoc + VS Code via winget / pip),
> - **double-click / drag-and-drop launchers** (`.bat`) that handle UAC, Mark-of-the-Web,
>   PATH refresh, and automatic browser open, and
> - **domain sample specifications** (automotive SOVD) to learn from.
>
> For real projects, follow the official StrictDoc documentation.

## What's inside

| Tool | Role | How to run |
|---|---|---|
| `setup-strictdoc.bat` | One-time setup: installs Git, Python, StrictDoc (pip), GitHub CLI, and VS Code + the Claude Code extension | Double-click → UAC → type `yes` |
| `launch-strictdoc.bat` | Daily use: **drag a folder (or a `.sdoc` file) onto it** to open it in your browser — or double-click to be prompted. One window per document. | Drag-and-drop or double-click |
| `gather-logs.bat` | Collects logs + a diagnostics report into a ZIP for troubleshooting | Double-click |

## Quick start

1. Copy the `StrictDocStarter` folder to your PC (e.g. the Desktop).
2. Double-click **`setup-strictdoc.bat`** → approve the UAC prompt → type `yes`.
   It installs everything (~15–30 min, mostly download time).
3. **Drag your requirements folder onto `launch-strictdoc.bat`** — or just double-click it to
   open the bundled SOVD sample. It opens the StrictDoc server in its own window and your
   browser at `http://127.0.0.1:5111/`. (See [Opening your documents](#opening-your-documents).)

That's it — from ZIP to browsing requirements.

A step-by-step setup guide is in [`docs/01-environment.md`](docs/01-environment.md).

## Opening your documents

`launch-strictdoc.bat` is a **launcher**: it opens a folder of `.sdoc` requirements as a
StrictDoc website in your browser. There is no menu — **one window per document**.

- **Drag & drop** a folder onto `launch-strictdoc.bat` to open it. Drop a single `.sdoc`
  **file** and it opens that file's parent folder.
- **Double-click** (no drag) and it asks for a folder — press **Enter** for the last-used
  folder (the bundled sample on first run), or **Q** to quit.
- **Multiple documents** run side by side: each gets its own server window and its own port
  (`5111`, then `5112`, …), all on `127.0.0.1`. Drag another folder to open it too.
- **Stop** a document by **closing its server window** (or `Ctrl+C` in it). Closing the window
  stops that server. The launcher window itself closes once it has handed off.
- **Re-open the browser** for a document that's already running by dragging the same folder
  again — it just reopens the tab (no duplicate server).
- **Settings** live in `server.config.json` (host, start port, auto-open-browser). Its
  `project_path` is only the prompt default and auto-updates to your last-used folder.
- On a `.sdoc` **parse error** the server window may close instantly, so the launcher prints
  the actual error in its own window.

## Bundled samples

| Path | What |
|---|---|
| `samples/sovd-automotive-ja/` | **Default.** A full Japanese SOVD (Service-Oriented Vehicle Diagnostics; ASAM SOVD / ISO 17978) requirements spec — overview, stakeholder requirements, use cases, authentication, data access, DTC diagnostics, OTA software update, architecture, HTTP API, and test spec & results — with ASIL (ISO 26262) and A-SPICE layer custom fields, Mermaid diagrams, math, and traceability. |
| `samples/sovd-automotive-en/` | English version of the above. |
| `samples/hello-strictdoc/` | A minimal "hello world" requirements document to copy and start your own. |

To open the English sample, drag `samples\sovd-automotive-en` onto `launch-strictdoc.bat`
(or set it as `project_path` in `server.config.json` to make it the default).

## Verified StrictDoc version

Tested with **strictdoc 0.23.1** (Windows 11 / Python 3.13). The default install pulls the
**latest** StrictDoc, so a future release could change how the bundled samples render; if you
need reproducibility, pin a version, e.g. `pip install "strictdoc==0.23.1"`.

## Requirements

- Windows 11 (with `winget`)
- Administrator rights for `setup-strictdoc.bat` (acquired via UAC); `launch-strictdoc.bat`
  runs as a normal user
- Internet access (winget / pip / git)

## Documentation

- [`docs/01-environment.md`](docs/01-environment.md) — environment setup walkthrough (Phase 0 / Phase 1)
- [`docs/setup-spec.md`](docs/setup-spec.md) — `setup-strictdoc` specification (requirements, ADRs)
- [`docs/serve-spec.md`](docs/serve-spec.md) — `launch-strictdoc` specification (visible-window server model)

## License

[Apache License 2.0](LICENSE) — the same license as StrictDoc.

## Links

- Official StrictDoc: <https://github.com/strictdoc-project/strictdoc>
- StrictDoc documentation: <https://strictdoc.readthedocs.io/>

---

# 日本語 (Japanese)

**[StrictDoc](https://github.com/strictdoc-project/strictdoc) を Windows で一発で使い始めるためのクイックスタート。**
ZIP を展開してダブルクリックするだけで、クリーンな Windows 11 PC から
「ブラウザで要求ツリーを閲覧」まで到達できます (Python やコマンドラインの手動設定は不要)。

> ### スコープ — 「公式の補助」であって置き換えではない
>
> StrictDocStarter は、公式 StrictDoc を **置き換えるものではなく補助する** コミュニティ製の
> **Windows クイックスタート**です。サーバ起動・プロジェクト雛形・設定は公式の
> `strictdoc server` / `strictdoc new` / `strictdoc_config.py` に **委譲**し、本ツールが足すのは
> 次の 3 点のみ:
>
> - Windows **ブートストラップ** (winget / pip で Python + StrictDoc + VS Code を導入)
> - **ダブルクリック / ドラッグ&ドロップ ランチャ** (`.bat`。UAC / Mark-of-the-Web / PATH 更新 / ブラウザ自動起動を処理)
> - **ドメインのサンプル仕様書** (自動車 SOVD)
>
> 実プロジェクトでは公式 StrictDoc のドキュメントに従ってください。

## 同梱物

| ツール | 役割 | 起動 |
|---|---|---|
| `setup-strictdoc.bat` | 初回セットアップ: Git / Python / StrictDoc (pip) / GitHub CLI / VS Code + Claude Code 拡張 を導入 | ダブルクリック → UAC → `yes` |
| `launch-strictdoc.bat` | 日常利用: **フォルダ (または `.sdoc` ファイル) をドラッグ&ドロップ**して開く — もしくはダブルクリックで入力を促す。1 文書 = 1 ウィンドウ。 | D&D / ダブルクリック |
| `gather-logs.bat` | 障害時のログ + 診断レポートを ZIP に回収 | ダブルクリック |

## クイックスタート

1. `StrictDocStarter` フォルダを PC (例: デスクトップ) にコピー。
2. **`setup-strictdoc.bat`** をダブルクリック → UAC で許可 → `yes` と入力。
   一式が導入されます (約 15〜30 分、大半はダウンロード時間)。
3. **要求フォルダを `launch-strictdoc.bat` にドラッグ&ドロップ** — もしくはダブルクリックで
   同梱 SOVD サンプルを開きます。StrictDoc サーバが専用ウィンドウで起動し、ブラウザで
   `http://127.0.0.1:5111/` が開きます。(下記「ドキュメントを開く」参照)

これで「ZIP 展開 → 要求閲覧」まで完結します。

セットアップの手順詳細は [`docs/01-environment.md`](docs/01-environment.md) を参照。

## ドキュメントを開く

`launch-strictdoc.bat` は **ランチャ**です: `.sdoc` 要求が入ったフォルダを StrictDoc の
Web サイトとしてブラウザで開きます。メニューはありません — **1 文書 = 1 ウィンドウ**。

- **ドラッグ&ドロップ**: フォルダを `launch-strictdoc.bat` にドロップして開きます。`.sdoc`
  **ファイル**をドロップすると、その親フォルダを開きます。
- **ダブルクリック** (ドロップ無し): フォルダを尋ねられます。**Enter** で最終使用フォルダ
  (初回は同梱サンプル)、**Q** で中止。
- **複数文書**: 各文書が専用のサーバウィンドウと専用ポート (`5111`, `5112`, …、すべて
  `127.0.0.1`) で並行起動します。2 つ目のフォルダをドロップすれば同時に開けます。
- **停止**: その文書の**サーバウィンドウを閉じる** (または窓内で `Ctrl+C`)。窓を閉じる =
  そのサーバ停止。ランチャ自身の窓は起動を渡したあと閉じます。
- **ブラウザ再表示**: 既に起動中の文書は、同じフォルダをもう一度ドロップするとタブを
  開き直すだけです (サーバは二重起動しません)。
- **設定**: `server.config.json` (host / 開始ポート / ブラウザ自動起動)。`project_path` は
  プロンプトの既定値で、最終使用フォルダに自動更新されます。
- `.sdoc` の**文法エラー**時はサーバウィンドウが即閉じることがあるため、ランチャが自分の
  窓に実際のエラーを表示します。

## 同梱サンプル

| パス | 内容 |
|---|---|
| `samples/sovd-automotive-ja/` | **既定。** 日本語のフル SOVD (Service-Oriented Vehicle Diagnostics; ASAM SOVD / ISO 17978) 要求仕様書 — 全体概要・ステークホルダ要求・ユースケース・認証・データアクセス・DTC 診断・OTA ソフトウェア更新・アーキテクチャ・HTTP API・テスト仕様/結果。ASIL (ISO 26262) と A-SPICE レイヤの custom field、Mermaid 図、数式、トレーサビリティ付き。 |
| `samples/sovd-automotive-en/` | 上記の英語版。 |
| `samples/hello-strictdoc/` | 自分の要求書を書き始めるための最小テンプレート。 |

英語版を開くには、`samples\sovd-automotive-en` を `launch-strictdoc.bat` にドラッグ&ドロップ
してください (既定にするなら `server.config.json` の `project_path` を変更)。

## 動作確認済み StrictDoc バージョン

**strictdoc 0.23.1** (Windows 11 / Python 3.13) で検証済み。既定のインストールは
**最新版**の StrictDoc を取得するため、将来版で同梱サンプルの描画が変わる可能性があります。
再現性を固定したい場合はバージョンを固定してください (例: `pip install "strictdoc==0.23.1"`)。

## 動作要件

- Windows 11 (`winget` 同梱)
- `setup-strictdoc.bat` は管理者権限が必要 (UAC で取得)。`launch-strictdoc.bat` は一般ユーザ権限で動作
- インターネット接続 (winget / pip / git)

## ドキュメント

- [`docs/01-environment.md`](docs/01-environment.md) — 環境構築の手順 (Phase 0 / Phase 1)
- [`docs/setup-spec.md`](docs/setup-spec.md) — `setup-strictdoc` 仕様書 (要求・ADR)
- [`docs/serve-spec.md`](docs/serve-spec.md) — `launch-strictdoc` 仕様書 (可視ウィンドウ方式)

## ライセンス

[Apache License 2.0](LICENSE) — StrictDoc と同じライセンス。

## リンク

- 公式 StrictDoc: <https://github.com/strictdoc-project/strictdoc>
- StrictDoc ドキュメント: <https://strictdoc.readthedocs.io/>
