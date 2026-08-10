# queries/

jq filters for the JSON that `strictdoc export --formats=json` produces. Each
one is explained, with its real output, in
[`docs/03-sdoc-json-queries.md`](../03-sdoc-json-queries.md).

```bash
strictdoc export --formats=json --output-dir out samples/sd-basic-ja
jq -r -f docs/queries/q5-children.jq out/json/index.json
```

**They are files rather than inline strings on purpose.** PowerShell strips the
`"` inside a quoted argument, so `jq '...' file` breaks there; `jq -f file.jq`
works the same in PowerShell, cmd and Git Bash.

| File                         | Answers                                                     |
| ---------------------------- | ----------------------------------------------------------- |
| `q1-section-requirements.jq` | which requirements are in a section (`--arg sec <title>`)   |
| `q2-one-requirement.jq`      | every field of one requirement                              |
| `q3-keyword.jq`              | which requirements mention a keyword (`--arg kw <keyword>`) |
| `q4-parents.jq`              | what this requirement derives from (transitively)           |
| `q5-children.jq`             | what derives from this requirement                          |

All five work against any StrictDoc project.

**The filters are ASCII.** Anything language-specific is passed in, so
`q1-section-requirements.jq` and `q3-keyword.jq` take their argument on the
command line - against the Japanese sample those are
`--arg sec "要求も同じように書ける"` and `--arg kw "変換"`. Run either without
its `--arg` and it prints its usage line instead of failing.

**`q2`, `q4` and `q5` name a UID inside the file.** A UID names a node rather
than a language, so passing it in would buy nothing; edit the file to point at
the requirement you want. As shipped they name `SW-002`, `SW-002` and
`SYS-001`, which exist in `samples/sd-basic-ja` and `samples/md-basic-ja`.
