# StrictDocStarter

See [README-ja.md](README-ja.md) for Japanese.

**One-click Windows quickstart for [StrictDoc](https://github.com/strictdoc-project/strictdoc).**
Go from a clean Windows 11 PC to browsing a real requirements tree in your browser.
No Python, no command line, no manual setup.

> **A community quickstart, not a replacement.** StrictDocStarter installs the official
> StrictDoc and launches it for you — the server, the project scaffolding and the
> configuration are all StrictDoc's own. For real projects, follow the official
> StrictDoc documentation.

## Quick start

You need **Windows 11**. Nothing else: setup installs Git, Python and StrictDoc itself.

1. **[Download the ZIP](https://github.com/GoodRelax/StrictDocStarter/archive/refs/heads/main.zip)** — about 4 MB.
2. Right-click it and choose **Extract All**. You get a folder named
   **`StrictDocStarter-main`**. Put it where you like, for example on the Desktop.
3. Double-click **`setup-strictdoc.bat`**, approve the Windows permission prompt, read
   the plan it prints, and type `yes`. It installs the toolchain: **15–30 minutes**,
   almost all of it downloading.
4. Double-click **`launch-strictdoc.bat`** and press **Enter**.

Your browser opens at `http://127.0.0.1:5111/` showing a real requirements tree.
**To stop it, close the server window that opened alongside your browser.**

> Behind a corporate proxy, step 3 may fail to download anything. Read
> [Behind a proxy](docs/04-starter-guide.md#behind-a-proxy) before you start.

## What you are looking at

That page is `samples/md-basic-en`, the smallest set of files that still works as a
requirements specification: three upper requirements, four lower ones that point at
them, four test cases that verify those, and review status carried on the requirements
themselves — each group in its own file, so the traceability crosses file boundaries.

**Copy that folder to start your own specification.** To open any other folder, drag it
onto `launch-strictdoc.bat`. One document per window, as many as you like at once.

StrictDoc also has a launcher of its own now, and `open-strictdoc-launcher.bat` starts it.
It opens one document at a time, and in exchange it exports, edits the project config,
repairs UIDs and runs `git` for you —
[the two side by side](docs/04-starter-guide.md#the-two-launchers).

You can also [read the bundled samples in your browser](https://goodrelax.github.io/StrictDocStarter/) without installing
anything — including a full 122-requirement automotive specification.

## Next steps

| Where                                                          | What is in it                                                                                                                                                                                                   |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`docs/04-starter-guide.md`](docs/04-starter-guide.md)         | **Everything else about StrictDocStarter**: what setup installs, running several documents at once, where the generated pages go, light and dark, the bundled samples, and pinning a StrictDoc version. English |
| [`docs/01-environment.md`](docs/01-environment.md)             | A step-by-step walkthrough of setup, with a troubleshooting table. Japanese                                                                                                                                     |
| [`docs/02-sdoc-authoring.md`](docs/02-sdoc-authoring.md)       | **How to write** `.sdoc` and `.md` for StrictDoc — the minimum an author needs. Japanese                                                                                                                        |
| [`docs/03-sdoc-json-queries.md`](docs/03-sdoc-json-queries.md) | Five copy-and-run `jq` queries over the JSON export. Japanese                                                                                                                                                   |
| [`claude-skills/strictdoc-md/`](claude-skills/strictdoc-md)    | A **Claude Code skill** that reads, writes and audits these specifications for you                                                                                                                              |
| `try-json-query-en.bat`                                        | A guided 7-step trial: export a specification to JSON, then pull answers out of it with `jq`. Double-click it. `-ja` is the same in Japanese                                                                    |

If something goes wrong, run `gather-logs.bat`. It gathers the logs and a diagnostics
report into a ZIP. Extract it, then ask Claude Code to read the contents and work out
what failed. The report names your machine and your folders, so read it before you
share it with anyone.

## License

[Apache License 2.0](LICENSE) — the same license as StrictDoc.

## Links

- Official StrictDoc: <https://github.com/strictdoc-project/strictdoc>
- StrictDoc documentation: <https://strictdoc.readthedocs.io/>
