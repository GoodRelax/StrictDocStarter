# StrictDocStarter

**One-click Windows quickstart for [StrictDoc](https://github.com/strictdoc-project/strictdoc).**
Unzip, double-click, and go from a clean Windows 11 PC to browsing a real requirements
tree in your browser — no manual Python or command-line setup.

> ### Scope — a companion, not a replacement
>
> StrictDocStarter is a community **Windows quickstart** that **complements, not replaces**,
> the official StrictDoc. It **delegates** the server, project scaffolding, and configuration
> to the official tools — `strictdoc server`, `strictdoc new`, and `strictdoc_config.py` — and
> adds:
>
> - a Windows **bootstrap** (`setup-strictdoc.bat`) that installs a developer toolchain via
>   winget / pip — Git, Python, StrictDoc, GitHub CLI, and VS Code with the **Claude Code**
>   extension — plus, **by default**, a few extra tools (Obsidian, Windows Terminal,
>   PowerShell 7, ripgrep, jq) and several VS Code extensions. Everything is configurable in
>   `setup.config.json` (see [What setup installs](#what-setup-installs)),
> - **double-click / drag-and-drop launchers** (`.bat`) that handle UAC, Mark-of-the-Web,
>   PATH refresh, and automatic browser open, and
> - **domain sample specifications** (automotive SOVD) to learn from.
>
> For real projects, follow the official StrictDoc documentation.

## What's inside

| Tool | Role | How to run |
|---|---|---|
| `setup-strictdoc.bat` | One-time setup (admin): installs the StrictDoc toolchain + developer tools, and can optionally clone a repo. Shows a plan, then asks once. Fully configurable via `setup.config.json` — see [What setup installs](#what-setup-installs). | Double-click → UAC → type `yes` |
| `launch-strictdoc.bat` | Daily use: **drag a folder (or a `.sdoc` file) onto it** to open it in your browser — or double-click to be prompted. One window per document. | Drag-and-drop or double-click |
| `change-color-mode.bat` | Switches the generated pages between **auto / light / dark**. Default is `auto`, which follows the Windows light/dark setting. | Double-click |
| `gather-logs.bat` | Collects logs + a diagnostics report into a ZIP for troubleshooting | Double-click |

## Quick start

0. **Behind a proxy / corporate network?** If your organization uses an **authenticated
   proxy**, outbound connections from `winget`, `pip`, `git`, and `gh` may be blocked (and
   SSL inspection can break certificate validation), so setup may fail to download anything.
   **Before running setup, ask your IT department** how to let these tools through the proxy,
   and set the proxy **environment variables** for your account (e.g. `HTTP_PROXY` /
   `HTTPS_PROXY`, plus `winget` and `pip` proxy settings) so downloads work. StrictDocStarter
   only **detects** a proxy and warns — it does **not** configure one for you.
1. Copy the `StrictDocStarter` folder to your PC (e.g. the Desktop).
2. Double-click **`setup-strictdoc.bat`** → approve the UAC prompt → review the plan → type `yes`.
   It installs the toolchain (~15–30 min, mostly download time). See
   [What setup installs](#what-setup-installs).
3. **Drag your requirements folder onto `launch-strictdoc.bat`** — or just double-click it to
   open the bundled SOVD sample. It opens the StrictDoc server in its own window and your
   browser at `http://127.0.0.1:5111/`. (See [Opening your documents](#opening-your-documents).)

That's it — from ZIP to browsing requirements.

A step-by-step setup guide is in [`docs/01-environment.md`](docs/01-environment.md).

## What setup installs

`setup-strictdoc.bat` (the default `auto` flow) probes what's already present, prints a plan,
and asks once for `yes`. Already-installed tools are skipped, so re-running is safe
(idempotent). By default it installs:

**Required (always):**

- Git, Python (3.13), GitHub CLI — via `winget`
- StrictDoc — via `pip install strictdoc`
- VS Code + the **Claude Code** extension (`anthropic.claude-code`)

**Extra developer tools (on by default — toggle in `setup.config.json`):**

- Obsidian, Windows Terminal, PowerShell 7, ripgrep, jq
- VS Code extensions: Markdown All in One, Markdown Preview Mermaid, PowerShell, Python,
  Japanese Language Pack, GitLens

**Optional (off by default — opt in via `setup.config.json`):**

- Claude Code **CLI** (via winget *or* npm; the npm path installs Node.js LTS first)
- **Clone a Git repository** and link it into an Obsidian vault (a junction): set
  `repository.url` (with `paths.clone_target` / `vault`); skipped while the URL is empty.
  Private repos trigger a `gh auth login` browser flow.

To review or change any of this **before** installing, run **`setup-strictdoc.bat config`**
(no admin needed) to generate/edit `setup.config.json`, then double-click
`setup-strictdoc.bat`. Other subcommands: `check` (write `env-report.json`), `dryrun` (print
the plan only), `help`.

## Opening your documents

`launch-strictdoc.bat` is a **launcher**: it opens a folder of `.sdoc` requirements as a
StrictDoc website in your browser. There is no menu — **one window per document**.

- **Drag & drop** a folder onto `launch-strictdoc.bat` to open it. Drop a single `.sdoc`
  **file** and it opens that file's parent folder.
- **Double-click** (no drag) and it asks for a folder — press **Enter** for the last-used
  folder (the bundled sample on first run), or **Q** to quit.
- **Multiple documents** run side by side: each gets its own server window and its own port
  (`5111`, then `5112`, …, up to ~20 ports above the start port), all on `127.0.0.1`. Drag
  another folder to open it too.
- **Stop** a document by **closing its server window** (or `Ctrl+C` in it). Closing the window
  stops that server. The launcher window itself closes once it has handed off.
- **Re-open the browser** for a document that's already running by dragging the same folder
  again — it just reopens the tab (no duplicate server).
- **Settings** live in `server.config.json`: `host`, `port` (the start port for
  auto-assignment), `open_browser`, `output_path`, and `color_mode`. `project_path` is only the
  prompt default and auto-updates to your last-used folder.
- On a `.sdoc` **parse error** the server window may close instantly, so the launcher prints
  the actual error in its own window.

### Where the generated pages go

Each project gets **its own** output folder, `<your folder>\output\strictdoc\`. Before, every
project shared one folder inside StrictDocStarter, and opening two projects at once made the
project index of the first one show the second one's documents.

That folder sits inside your project, so the launcher checks whether Git is ignoring it and, if
not, prints the one line to add. **It never edits `.gitignore` itself** — you do that. If the
folder is not in a Git working tree, or is already ignored, it says nothing.

Set `output_path` in `server.config.json` if you want it somewhere else.

### Light and dark

`change-color-mode.bat` sets `color_mode` to `auto` (default), `light`, or `dark`. A project
picks up the new value the next time you open it; servers already running keep the old one.

StrictDoc has no dark mode of its own, so this works by adding a stylesheet on top of it. The
text you read goes dark and the Mermaid diagrams follow, but a few small controls are only
partly covered and source code highlighting is unchanged. See
[Path to custom CSS](https://strictdoc.readthedocs.io/) for the mechanism.

### If the launcher offers to update a project setting

Projects opened with an older StrictDocStarter carry an older `strictdoc_config.py`, and that
file decides which screens the left toolbar shows. When the launcher finds one it wrote itself
and has not been edited since, it explains what would change, backs the file up, and asks. Say
no and it will not ask again until a newer version ships.

**A config you wrote yourself is never modified** — the launcher only prints what to add.

> Already using an older StrictDocStarter? None of this reaches you until you replace
> `launch-strictdoc.bat` and the `lib\` folder with a current copy.

## Bundled samples

Every sample comes as a pair holding **the same content in the two notations**: `md-` is
written in Markdown, `sd-` in `.sdoc` (RST). Same grammar, same UIDs, same requirement
sentences — only the body notation differs, so the two folders can be read side by side.

| Path | What |
|---|---|
| `samples/md-sovd-automotive-ja/` | **Default.** A full Japanese SOVD (Service-Oriented Vehicle Diagnostics; ASAM SOVD / ISO 17978) requirements spec — overview, stakeholder requirements, use cases, authentication, data access, DTC diagnostics, OTA software update, architecture, HTTP API, and test spec & results — with ASIL (ISO 26262) and A-SPICE layer custom fields, Mermaid diagrams, math, and traceability. Requirements are written in EARS and tests in Gherkin. Written entirely in `.md`. |
| `samples/sd-sovd-automotive-ja/` | The same specification written in `.sdoc`. This is where the notations are worth comparing at the scale of a real spec: Mermaid as `.. raw:: html`, tables as `.. list-table::`, math as `.. math::`, code as `.. code-block::`. |
| `samples/md-sovd-automotive-en/`, `samples/sd-sovd-automotive-en/` | English versions of the two above. |
| `samples/md-basic-ja/` | **The basics in `.md` — copy this folder to start your own spec.** The smallest thing that still works as a requirements spec: three upper requirements, four lower ones that point at them, four test cases that point at those, and review status carried on the requirements themselves — each group in its own file, so the traceability actually crosses file boundaries. One shared grammar file (`basic.sgra`) adds the `TEST_CASE` node type, the `REVIEW_STATUS` / `REVIEW_COMMENT` / `REVIEW_ACTION` fields and the `Verifies` relation role. Also covers prose that is deliberately *not* a requirement, linking to another `.md` file, an externalised Mermaid diagram, an SVG image, what an AI needs in order to read the set, and how to edit it from the browser and alongside Claude. Japanese. |
| `samples/sd-basic-ja/` | **The same spec written in `.sdoc`.** Adds what is specific to `.sdoc`: both RST table forms (`+---+` grid and `===` simple), `[DOCUMENT_FROM_FILE]` to pull a diagram fragment into the body (Markdown has no equivalent), and one document that declares `MARKUP: Markdown` to get pipe tables. Japanese. |
| `samples/md-basic-en/`, `samples/sd-basic-en/` | English versions of the two above. |
| `samples/sdoc-patterns/` | **Authoring patterns — start here to write your own.** `00-hello.sdoc` is the minimal document to copy: three requirements, no custom grammar. The rest add one construct each, small enough to read in full: custom grammar (`.sgra`), parent/file relations, a custom `FINDING` node type for review findings, a `REVISION` field, diagrams kept out of the requirement bodies (Mermaid, math, SVG/PNG images, and a Mermaid diagram externalised into its own `.md` under `_assets/` and linked back with a `File` relation), the same requirements written in Markdown, and what the export formats are for. `queries/` holds the seven ready-to-run jq filters from [`docs/03-sdoc-json-queries.md`](docs/03-sdoc-json-queries.md). This is the sample [`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md) refers to. |

To open the English sample, drag `samples\md-sovd-automotive-en` onto `launch-strictdoc.bat`
(or set it as `project_path` in `server.config.json` to make it the default).

## Verified StrictDoc version

The bundled samples and docs assume **strictdoc 0.27 or newer**, and are verified against
**0.27.1** (Windows 11 / Python 3.13). The default install pulls the **latest** StrictDoc, so
that requirement is met out of the box. If you need reproducibility, pin a version — see
below; if you pin an older one, section 9 of
[`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md) lists what changes.

`setup-strictdoc.bat check` prints the installed version and writes it to `env-report.json`.

## Changing the StrictDoc version

**Running setup keeps StrictDoc at the version `setup.config.json` asks for.** With the
default `latest`, that means re-running `setup-strictdoc.bat` moves you to the newest
release. The plan says so before anything happens:

```
Phase C: StrictDoc (pip package)             [REQUIRED]
  - [INSTALL] strictdoc   installed: 0.27.1 - strictdoc.version='latest',
                          will upgrade if a newer release exists
```

Answer `yes` and it upgrades; answer anything else and setup aborts without touching it.
Nothing changes without that confirmation.

To change the version without running the rest of setup:

```
setup-strictdoc.bat upgrade
```

It shows the current version, what it will run, and the command that puts it back, then asks
for `yes`. Add `-Preview` to ask pip which version it would land on first (one extra network
round trip, which took about a minute on the machine this was measured on).

Either way, the version comes from `strictdoc.version` in `setup.config.json`:

| Value | Meaning |
|---|---|
| `latest` (default) | newest release on PyPI |
| `==0.27.1` | exactly this version — use for reproducibility |
| `~=0.27.0` | `>=0.27, <0.28` |
| `0.27.1` | bare version, read as `==0.27.1` |

**Pin it if you do not want setup moving you.** With `==0.27.1` and 0.27.1 installed, Phase C
reports `[SKIP] ... (matches strictdoc.version)` and never calls pip — the check is a string
comparison, so it costs nothing.

The same setting is applied when StrictDoc is installed for the first time. An unrecognised
value stops the command rather than quietly falling back to `latest`.

**Pinning below 0.27 is not recommended.** The bundled samples no longer list `MATHJAX` /
`MERMAID` in `strictdoc_config.py`, because 0.27 enables both by default and warns if they are
listed. On an older StrictDoc those toggles are required, so diagrams show as raw text and
formulas do not render. Section 9 of [`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md)
lists the rest of the differences.

If you would rather not use the launcher, `pip install --upgrade strictdoc` does the same
thing.

## Requirements

- Windows 11 (with `winget`)
- Administrator rights for `setup-strictdoc.bat` (acquired via UAC); `launch-strictdoc.bat`
  runs as a normal user
- Internet access for downloads — `winget`, `pip`, `git`, `gh` (GitHub CLI), and the VS Code
  Marketplace (plus `npm` only if you opt into the Claude Code CLI via npm)
- If you are behind an authenticated proxy, see **Quick start step 0**

## Documentation

- [`docs/01-environment.md`](docs/01-environment.md) — environment setup walkthrough (Phase 0 / Phase 1)
- [`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md) — **how to write `.sdoc`** (and `.md`): the minimum an author — human or AI — needs so the official user guide does not have to be re-read for every requirement. Japanese; every statement verified by running strictdoc 0.27.1
- [`docs/03-sdoc-json-queries.md`](docs/03-sdoc-json-queries.md) — **JSON query cookbook**: seven copy-and-run `jq` queries over `strictdoc export --formats=json`, with their actual output. Japanese
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
> 次のとおり:
>
> - Windows **ブートストラップ** (`setup-strictdoc.bat`)。winget / pip で開発ツール一式
>   — Git / Python / StrictDoc / GitHub CLI / VS Code + **Claude Code** 拡張 — に加え、
>   **既定で**追加ツール (Obsidian / Windows Terminal / PowerShell 7 / ripgrep / jq) と
>   複数の VS Code 拡張も導入します。すべて `setup.config.json` で設定変更できます
>   (下記「setup が導入するもの」参照)。
> - **ダブルクリック / ドラッグ&ドロップ ランチャ** (`.bat`。UAC / Mark-of-the-Web / PATH 更新 / ブラウザ自動起動を処理)
> - **ドメインのサンプル仕様書** (自動車 SOVD)
>
> 実プロジェクトでは公式 StrictDoc のドキュメントに従ってください。

## 同梱物

| ツール | 役割 | 起動 |
|---|---|---|
| `setup-strictdoc.bat` | 初回セットアップ (管理者): StrictDoc ツールチェイン + 開発ツールを導入し、任意でリポジトリを clone。プランを表示し一度だけ確認。`setup.config.json` で全設定可 (下記「setup が導入するもの」参照)。 | ダブルクリック → UAC → `yes` |
| `launch-strictdoc.bat` | 日常利用: **フォルダ (または `.sdoc` ファイル) をドラッグ&ドロップ**して開く — もしくはダブルクリックで入力を促す。1 文書 = 1 ウィンドウ。 | D&D / ダブルクリック |
| `change-color-mode.bat` | 生成ページの見た目を **auto / light / dark** で切り替え。既定は `auto` (Windows の設定に追従)。 | ダブルクリック |
| `gather-logs.bat` | 障害時のログ + 診断レポートを ZIP に回収 | ダブルクリック |

## クイックスタート

0. **プロキシ / 企業ネットワーク環境の方へ。** 企業などで**認証付きプロキシ**を設定している場合、
   `winget` / `pip` / `git` / `gh` の外部通信が遮断されることがあり (SSL インスペクションで証明書
   検証に失敗することもあり)、ダウンロードに失敗してセットアップが完了しない場合があります。
   **セットアップ実行前に IT 部門に相談**し、これらのツールがプロキシを通過できるよう、PC (ユーザー) の
   **環境変数** (`HTTP_PROXY` / `HTTPS_PROXY` や `winget` / `pip` のプロキシ設定など) を設定して
   `pip` や `winget` がダウンロードできる状態にしてください。StrictDocStarter はプロキシを
   **検出して警告するだけ**で、設定の代行はしません。
1. `StrictDocStarter` フォルダを PC (例: デスクトップ) にコピー。
2. **`setup-strictdoc.bat`** をダブルクリック → UAC で許可 → プランを確認 → `yes` と入力。
   ツールチェインが導入されます (約 15〜30 分、大半はダウンロード時間)。下記「setup が導入するもの」参照。
3. **要求フォルダを `launch-strictdoc.bat` にドラッグ&ドロップ** — もしくはダブルクリックで
   同梱 SOVD サンプルを開きます。StrictDoc サーバが専用ウィンドウで起動し、ブラウザで
   `http://127.0.0.1:5111/` が開きます。(下記「ドキュメントを開く」参照)

これで「ZIP 展開 → 要求閲覧」まで完結します。

セットアップの手順詳細は [`docs/01-environment.md`](docs/01-environment.md) を参照。

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

| 英語表示 | 意味 |
|---|---|
| `What changes: 4 settings enabled -> 7 settings enabled` | 有効な設定が 4 個から 7 個に増えます |
| `2 icons in the left toolbar -> 5 icons` | 左ツールバーのアイコンが 2 個から 5 個になります |
| `Turned on: + Project statistics screen` | 統計画面が有効になります |
| `+ Traceability matrix screen` | トレーサビリティマトリクス画面が有効になります |
| `+ Tree map screen` | ツリーマップ画面が有効になります |
| `Your documents are NOT touched.` | **文書ファイルには一切触れません** |
| `A backup is written first` | 先にバックアップを取ります (`.bak-<日時>`) |
| `Want to compare first?` | 変更後のファイルを事前に見たい場合の置き場所 |
| `Update the settings file now? [Y/n]` | 更新しますか。**Enter で「はい」** |
| `Nothing was changed.` | 何も変更していません (断った場合) |

> 古い StrictDocStarter を使い続けている場合、ここまでの機能はいずれも届きません。
> `launch-strictdoc.bat` と `lib\` フォルダを新しいものに差し替えてください。

## 同梱サンプル

サンプルはすべて **同じ中身を 2 つの記法で持つ対**になっています。`md-` は Markdown、
`sd-` は `.sdoc` (RST) で書いてあります。文法も UID も要求文も同じで、違うのは本文の
記法だけなので、2 つのフォルダを並べて読み比べられます。

| パス | 内容 |
|---|---|
| `samples/md-sovd-automotive-ja/` | **既定。** 日本語のフル SOVD (Service-Oriented Vehicle Diagnostics; ASAM SOVD / ISO 17978) 要求仕様書 — 全体概要・ステークホルダ要求・ユースケース・認証・データアクセス・DTC 診断・OTA ソフトウェア更新・アーキテクチャ・HTTP API・テスト仕様/結果。ASIL (ISO 26262) と A-SPICE レイヤの custom field、Mermaid 図、数式、トレーサビリティ付き。要求は EARS、テストは Gherkin で書いてあり、本文は全部 `.md`。 |
| `samples/sd-sovd-automotive-ja/` | 同じ仕様書を `.sdoc` で書いた版。実仕様の規模で記法を比べられる: Mermaid は `.. raw:: html`、表は `.. list-table::`、数式は `.. math::`、コードは `.. code-block::`。 |
| `samples/md-sovd-automotive-en/`、`samples/sd-sovd-automotive-en/` | 上記 2 つの英語版。 |
| `samples/md-basic-ja/` | **`.md` の基本 — 自分の仕様書はこのフォルダを丸ごと写して始める。** 要求仕様書として最低限成り立つ一式: 上位要求 3 件・それを指す下位要求 4 件・それを指すテストケース 4 件・要求そのものに載せたレビュー欄を**それぞれ別ファイル**に置き、トレーサビリティがファイルをまたぐようにしてある。共有の文法定義 (`basic.sgra`) が `TEST_CASE` のノード型と `REVIEW_STATUS` / `REVIEW_COMMENT` / `REVIEW_ACTION` のフィールド、`Verifies` の関係ロールを足す。ほかに、意図して要求にしない地の文・別の `.md` へのリンク・外出しした Mermaid 図・SVG 画像・AI に読ませるために要るもの・ブラウザでの編集と Claude との共同作業。 |
| `samples/sd-basic-ja/` | **同じ仕様書を `.sdoc` で書いた版。** `.sdoc` 固有の内容を追加: RST の表 2 形式 (`+---+` grid と `===` simple)・図の断片を本文へ取り込む `[DOCUMENT_FROM_FILE]` (Markdown に相当物は無い)・パイプ表のために `MARKUP: Markdown` を宣言した文書 1 つ。 |
| `samples/md-basic-en/`、`samples/sd-basic-en/` | 上記 2 つの英語版。 |
| `samples/sdoc-patterns/` | **書き方の型 — 自分の要求書はここから始める。** `00-hello.sdoc` が写して使う最小の文書 (要求 3 件、カスタム文法なし)。以降は構文を 1 つずつ、全部読める分量で足していく: カスタム文法 (`.sgra`)・親/ファイル関係・レビュー指摘用のカスタムノード型 `FINDING`・`REVISION` フィールド・要求本体から外に出した図 (Mermaid・数式・SVG / PNG 画像・図 1 枚を `_assets/` の `.md` に外出しして `File` 関係で戻す型)・同じ要求の Markdown 版・出力形式の使い分け。`queries/` に [`docs/03-sdoc-json-queries.md`](docs/03-sdoc-json-queries.md) の jq フィルタ 7 本をそのまま同梱。[`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md) が参照するサンプル。 |

英語版を開くには、`samples\md-sovd-automotive-en` を `launch-strictdoc.bat` にドラッグ&ドロップ
してください (既定にするなら `server.config.json` の `project_path` を変更)。

## 動作確認済み StrictDoc バージョン

同梱サンプルとドキュメントは **strictdoc 0.27 以降**を前提とし、**0.27.1**
(Windows 11 / Python 3.13) で検証済みです。既定のインストールは**最新版**を取得するため、
この前提は何もしなくても満たされます。再現性を固定したい場合はバージョンを固定して
ください (下記参照)。それより古い版に固定する場合、変わる点は
[`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md) の §9 にあります。

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

| 値 | 意味 |
|---|---|
| `latest` (既定) | PyPI の最新版 |
| `==0.27.1` | このバージョンちょうど。再現性を固定したいとき |
| `~=0.27.0` | `>=0.27, <0.28` |
| `0.27.1` | 演算子なし。`==0.27.1` として読まれます |

**setup に動かされたくない場合はバージョンを固定してください。** `==0.27.1` で 0.27.1 が
入っていれば、Phase C は `[SKIP] ... (matches strictdoc.version)` と表示して pip を
呼びません (文字列の比較だけなので待ち時間もゼロです)。

同じ設定が初回インストール時にも適用されます。解釈できない値の場合、`latest` に黙って
フォールバックせずコマンドを停止します。

**0.27 未満への固定は推奨しません。** 同梱サンプルは `strictdoc_config.py` に
`MATHJAX` / `MERMAID` を列挙していません — 0.27 では既定で有効であり、列挙すると
DEPRECATION 警告が出るためです。古い版ではこの指定が必要なので、**図が生のテキストとして
表示され、数式も描画されません。** 他の差分は
[`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md) の §9 にあります。

ランチャを使わない場合は `pip install --upgrade strictdoc` でも同じことができます。

## 動作要件

- Windows 11 (`winget` 同梱)
- `setup-strictdoc.bat` は管理者権限が必要 (UAC で取得)。`launch-strictdoc.bat` は一般ユーザ権限で動作
- ダウンロードのためのインターネット接続 — `winget` / `pip` / `git` / `gh` (GitHub CLI) /
  VS Code マーケットプレイス (Claude Code CLI を npm で導入する場合は `npm` も)
- 認証付きプロキシ環境の場合は**クイックスタートの 0.** を参照

## ドキュメント

- [`docs/01-environment.md`](docs/01-environment.md) — 環境構築の手順 (Phase 0 / Phase 1)
- [`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md) — **`.sdoc` (と `.md`) の書き方。** 書き手 (人でも AI でも) が、要求 1 件ごとに公式ユーザーガイドを読み直さずに済むだけの最小限。記述はすべて strictdoc 0.27.1 で実行して確認済み
- [`docs/03-sdoc-json-queries.md`](docs/03-sdoc-json-queries.md) — **JSON クエリ集。** `strictdoc export --formats=json` の出力に対する、コピーして実行できる `jq` クエリ 7 種と実際の出力
- [`docs/setup-spec.md`](docs/setup-spec.md) — `setup-strictdoc` 仕様書 (要求・ADR)
- [`docs/serve-spec.md`](docs/serve-spec.md) — `launch-strictdoc` 仕様書 (可視ウィンドウ方式)

## ライセンス

[Apache License 2.0](LICENSE) — StrictDoc と同じライセンス。

## リンク

- 公式 StrictDoc: <https://github.com/strictdoc-project/strictdoc>
- StrictDoc ドキュメント: <https://strictdoc.readthedocs.io/>
