# 04 StrictDocStarter guide

Everything about StrictDocStarter that the [README](../README.md) deliberately leaves out.
The README gets you to a requirements tree in your browser; this page is what you
read afterwards, when you want to know how a piece of it works.

See [04-starter-guide-ja.md](04-starter-guide-ja.md) for Japanese.

## Behind a proxy

If your organization uses an **authenticated proxy**, outbound connections from
`winget`, `pip`, `git` and `gh` may be blocked, and SSL inspection can break
certificate validation — so setup may fail to download anything.

**Ask your IT department first** how to let those four tools through, then set the
proxy **environment variables** for your account (`HTTP_PROXY` / `HTTPS_PROXY`, plus
the `winget` and `pip` proxy settings). StrictDocStarter only **detects** a proxy and
warns about it — it does **not** configure one for you.

## What's inside

| Tool                                             | Role                                                                                                                                                                                                                                                  | How to run                      |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| `setup-strictdoc.bat`                            | One-time setup (admin): installs the StrictDoc toolchain + developer tools, and can optionally clone a repo. Shows a plan, then asks once. Fully configurable via `setup.config.json` — see [What setup installs](#what-setup-installs).              | Double-click → UAC → type `yes` |
| `launch-strictdoc.bat`                           | Daily use: **drag a folder (or a `.sdoc` file) onto it** to open it in your browser — or double-click to be prompted. One window per document.                                                                                                        | Drag-and-drop or double-click   |
| `open-strictdoc-launcher.bat`                    | Starts **StrictDoc's own** desktop launcher (`strictdoc launcher`, added in 0.22.0, still experimental) — see [The two launchers](#the-two-launchers). Takes no dropped folder; you pick one in the window.                                           | Double-click                    |
| `change-color-mode.bat`                          | Switches the generated pages between **auto / light / dark**. Default is `auto`, which follows the Windows light/dark setting.                                                                                                                        | Double-click                    |
| `try-json-query-en.bat`, `try-json-query-ja.bat` | A guided 7-step trial of querying a specification as JSON with `jq`: each step explains itself, waits for Enter, then runs the command it just showed. Drop a project folder on it, or double-click to use the bundled `md-basic-en` / `md-basic-ja`. | Drag-and-drop or double-click   |
| `gather-logs.bat`                                | Collects logs + a diagnostics report into a ZIP for troubleshooting                                                                                                                                                                                   | Double-click                    |

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

- Claude Code **CLI** (via winget _or_ npm; the npm path installs Node.js LTS first)
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

### The two launchers

StrictDoc ships a launcher of its own — `strictdoc launcher`, added in **0.22.0** and still
marked experimental. `open-strictdoc-launcher.bat` starts it, so you can try it without
remembering the command. It is a separate piece of work by a StrictDoc contributor, not a
version of the one here.

Use whichever fits the moment:

|                       | `launch-strictdoc.bat`                                                                   | `open-strictdoc-launcher.bat`                                         |
| --------------------- | ---------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| How you open a folder | **Drag it on**                                                                           | Pick it in the window                                                 |
| Documents at once     | **As many as you like** — one window and one port each                                   | **One.** A second attempt says the server is already running          |
| Before starting       | Checks your sources are UTF-8 and warns about CRLF Markdown                              | —                                                                     |
| Also does             | Colour mode, output kept in `output\strictdoc\`, `.gitignore` advice, config scaffolding | **Export, config editor, UID repair, `git pull` / `commit` / `push`** |
| Needs                 | Nothing beyond this repository                                                           | A Python with `tkinter`                                               |

**The bundled samples assume you can open several at once** — the whole point of shipping
`md-basic-en` beside `md-basic-ja`, and `md-` beside `sd-`, is to put two windows side by side
and compare. That is why `launch-strictdoc.bat` is still here.

Everything else, StrictDoc does better itself, and the intent is to hand more over as its
launcher grows. Note that the two write their generated pages to different places:
`output\strictdoc\` here, `output\server\` there.

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

**You can read all six samples in your browser without installing anything:
<https://goodrelax.github.io/StrictDocStarter/>.** A GitHub Actions workflow exports each
one as its own project and publishes them; nothing generated is committed.

Every sample comes as a pair: `md-` is written in Markdown, `sd-` in `.sdoc` (RST). The two
share **the requirement core** — same grammar, same `SYS-` / `SW-` / `TC-` identifiers, same
requirement sentences — so you can put the folders side by side and compare the notations.
**The `sd-` set is deliberately the smaller of the two** (6 documents against 11): it is
there to show the notation, not to carry a second copy of every guide.

| Path                                           | What                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `samples/md-basic-en/`                         | **Default.** **The basics in `.md` — copy this folder to start your own spec.** The smallest thing that still works as a requirements spec: three upper requirements, four lower ones that point at them, four test cases that point at those, and review status carried on the requirements themselves — each group in its own file, so the traceability actually crosses file boundaries. One shared grammar file (`basic.sgra`) adds the `TEST_CASE` node type, the `REVIEW_STATUS` / `REVIEW_COMMENT` / `REVIEW_ACTION` fields and the `Verifies` relation role. Also covers prose that is deliberately _not_ a requirement, linking to another `.md` file, an externalised Mermaid diagram, an SVG image, what an AI needs in order to read the set, and how to edit it from the browser and alongside Claude. English. |
| `samples/md-basic-ja/`                         | The same spec in Japanese.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `samples/sd-basic-en/`, `samples/sd-basic-ja/` | **The same spec written in `.sdoc`.** Adds what is specific to `.sdoc`: both RST table forms (`+---+` grid and `===` simple), `[DOCUMENT_FROM_FILE]` to pull a diagram fragment into the body (Markdown has no equivalent), and one document that declares `MARKUP: Markdown` to get pipe tables.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `samples/md-sovd-automotive-ja/`               | A full Japanese SOVD (Service-Oriented Vehicle Diagnostics; ASAM SOVD / ISO 17978) requirements spec — overview, stakeholder requirements, use cases, authentication, data access, DTC diagnostics, OTA software update, architecture, HTTP API, and test spec & results — with ASIL (ISO 26262) and A-SPICE layer custom fields, Mermaid diagrams, math, and traceability. Requirements are written in EARS and tests in Gherkin. Written entirely in `.md`.                                                                                                                                                                                                                                                                                                                                                                |
| `samples/md-sovd-automotive-en/`               | The English version of the above.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |

`md-basic-en` is what `launch-strictdoc.bat` opens when you double-click it with nothing
dropped. It is deliberately small — the point is that you can read all of it and then copy it.

**For a full-size example, drag `samples\md-sovd-automotive-en` onto `launch-strictdoc.bat`**:
122 requirements across 21 documents, with EARS requirement text, Gherkin tests, ASIL and
A-SPICE custom fields, Mermaid diagrams, math, and traceability that runs requirement →
design → API → test spec → result. To make a different folder the startup default, set
`project_path` in `server.config.json`.

## Writing specifications with Claude Code

[`claude-skills/strictdoc-md/`](../claude-skills/strictdoc-md) is a Claude Code **skill** that
teaches Claude how to read, write, modify and audit Markdown StrictDoc specifications: the
`.md` shape, the rules that stop an export, figures, math, code, tables and attachments,
every `jq` query the cookbook teaches with its measured output, and an audit script for the
failures StrictDoc does not report itself. Install it by copying the folder into your own
`.claude/skills/`:

```bash
cp -r claude-skills/strictdoc-md ~/.claude/skills/
```

`samples/md-basic-en` is the worked example every query in the skill was measured against.
[`claude-skills/README.md`](../claude-skills/README.md) covers what is inside and how the
published copy is kept in step with the one Claude Code actually reads.

## Checking the samples and the docs

`tools/` holds the scripts this repository runs on itself. They are maintenance tools, not
part of the Windows quickstart — reach for them only if you are changing a sample or the
documentation. Each one takes the JSON that `strictdoc export --formats=json` writes.

| Tool                                                                  | What it checks                                                                                                              |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| [`tools/ascii-audit.py`](../tools/ascii-audit.py)                     | code and configuration files hold no non-ASCII characters (NFR-010)                                                         |
| [`tools/verify-jq.py`](../tools/verify-jq.py)                         | every `jq` example embedded in a document still runs                                                                        |
| [`tools/check-jq-output.py`](../tools/check-jq-output.py)             | the output pasted under a query still matches what the query prints                                                         |
| [`tools/run-query-fixture.py`](../tools/run-query-fixture.py)         | every query returns at least one row against a fixture built to hit them all                                                |
| [`tools/check-references.py`](../tools/check-references.py)           | quoted headings, `[LINK:]` targets and file names named in prose all resolve                                                |
| [`tools/check-symmetry.py`](../tools/check-symmetry.py)               | the `ja` and `en` editions carry the same documents, nodes and relations                                                    |
| [`tools/check-numbers.py`](../tools/check-numbers.py)                 | a count claimed in prose matches the output it sits beside                                                                  |
| [`tools/check-skill-sync.py`](../tools/check-skill-sync.py)           | the packaged skill still says what the worked example says                                                                  |
| [`tools/check-grammar-copies.py`](../tools/check-grammar-copies.py)   | every copy of a grammar file still holds the same grammar                                                                   |
| [`tools/check-format-fixpoint.py`](../tools/check-format-fixpoint.py) | a sample still exports **after** a Markdown formatter has run over it, and is shipped in a shape the formatter leaves alone |

**`check-format-fixpoint.py` is the one to run after editing a `.md` sample**, and it is the
only check here that does not simply read an export. A passing `strictdoc export` says nothing
about whether a specification is safe to hand to someone else: the notation that breaks under
a formatter exports cleanly as written and only dies after the formatter has run once. Measured
on strictdoc 0.27.1 with prettier 3.5.3, `samples/md-sovd-automotive-en` exported 294 nodes and
then failed with `duplicate field names in a valid requirement node are not allowed` after a
single `prettier --write`, so anyone who opened a file and saved it destroyed the document.

So the check copies the folder, formats the copy, exports it again, and compares the nodes and
relations on both sides. Run `--self-test` first if you have changed the script: it breaks a
project of its own once per check and requires that exactly the expected check fires, because
"zero failures" means nothing until each check has been seen to fire.

```bash
python tools/check-format-fixpoint.py
```

The answer is **not** to switch the formatter off for the specification folder. A `.prettierignore`
or an `editor.formatOnSave: false` protects the specification by sacrificing every ordinary
Markdown edit in the same folder, it depends on a setting that travels with nobody, and it breaks
the moment someone removes it. The samples here are shipped in a shape a formatter has nothing
to say about instead, which asks nothing of your environment.

Each sample folder carries one small `.prettierrc.yaml` saying `endOfLine: auto`, and it travels
with the folder when you copy it. That is the opposite of switching formatting off — every rule
still applies. It only tells Prettier to keep whatever line endings each file already has, so a
Markdown file **you** create on Windows (CRLF) is as acceptable as the ones shipped here (LF), and
neither is rewritten on save. Prettier writes LF by default, so without it a file you added
yourself would be reported as unformatted for no reason other than its line endings.

[`tools/capture-manual-ja.py`](../tools/capture-manual-ja.py) and
[`tools/capture-manual-en.py`](../tools/capture-manual-en.py) re-take every screenshot in
`09-browser-guide.md` against a running server, so the pictures cannot drift from the UI.

## Verified StrictDoc version

The bundled samples and docs assume **strictdoc 0.27 or newer**, and are verified against
**0.27.1** (Windows 11 / Python 3.13). The default install pulls the **latest** StrictDoc, so
that requirement is met out of the box. If you need reproducibility, pin a version — see
below; if you pin an older one, section 9 of
[`docs/02-sdoc-authoring.md`](02-sdoc-authoring.md) lists what changes.

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

| Value              | Meaning                                        |
| ------------------ | ---------------------------------------------- |
| `latest` (default) | newest release on PyPI                         |
| `==0.27.1`         | exactly this version — use for reproducibility |
| `~=0.27.0`         | `>=0.27, <0.28`                                |
| `0.27.1`           | bare version, read as `==0.27.1`               |

**Pin it if you do not want setup moving you.** With `==0.27.1` and 0.27.1 installed, Phase C
reports `[SKIP] ... (matches strictdoc.version)` and never calls pip — the check is a string
comparison, so it costs nothing.

The same setting is applied when StrictDoc is installed for the first time. An unrecognised
value stops the command rather than quietly falling back to `latest`.

**Pinning below 0.27 is not recommended.** The bundled samples no longer list `MATHJAX` /
`MERMAID` in `strictdoc_config.py`, because 0.27 enables both by default and warns if they are
listed. On an older StrictDoc those toggles are required, so diagrams show as raw text and
formulas do not render. Section 9 of [`docs/02-sdoc-authoring.md`](02-sdoc-authoring.md)
lists the rest of the differences.

If you would rather not use the launcher, `pip install --upgrade strictdoc` does the same
thing.

## Requirements

- Windows 11 (with `winget`)
- Administrator rights for `setup-strictdoc.bat` (acquired via UAC); `launch-strictdoc.bat`
  runs as a normal user
- Internet access for downloads — `winget`, `pip`, `git`, `gh` (GitHub CLI), and the VS Code
  Marketplace (plus `npm` only if you opt into the Claude Code CLI via npm)
- If you are behind an authenticated proxy, see [Behind a proxy](#behind-a-proxy)
