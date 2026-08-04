# queries/

jq filters for the JSON that `strictdoc export --formats=json` produces. Each
one is explained, with its real output, in
[`docs/03-sdoc-json-queries.md`](../../../docs/03-sdoc-json-queries.md).

```bash
strictdoc export --formats=json --output-dir out samples/sdoc-patterns
jq -r -f samples/sdoc-patterns/queries/q6-findings.jq out/json/index.json
```

**They are files rather than inline strings on purpose.** PowerShell strips the
`"` inside a quoted argument, so `jq '...' file` breaks there; `jq -f file.jq`
works the same in PowerShell, cmd and Git Bash.

| File | Answers |
|---|---|
| `q1-section-requirements.jq` | which requirements are in section N |
| `q2-one-requirement.jq` | every field of one requirement |
| `q3-keyword.jq` | which requirements mention a keyword |
| `q4-parents.jq` | what this requirement derives from (transitively) |
| `q5-children.jq` | what derives from this requirement |
| `q6-findings.jq` | review findings and what they point at |
| `q7-revised.jq` | which requirements were revised |

`q1`–`q5` work against any StrictDoc project. `q6` and `q7` rely on the custom
`FINDING` node type and `REVISION` field declared in `../patterns.sgra`.
