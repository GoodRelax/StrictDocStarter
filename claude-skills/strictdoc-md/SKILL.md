---
name: strictdoc-md
description: Read, write, modify and audit Markdown-flavoured StrictDoc specifications - requirements, traceability, figures, math, code, tables and attachments. Use when the user asks about a StrictDoc project or a `.sgra` grammar, wants a requirement listed, traced, added or changed, wants a figure, formula, code block, table or attachment put into a specification, asks which requirements no test covers, or asks why `strictdoc export` fails. Pull data with jq over the JSON export rather than reading the `.md` files.
user-invocable: true
---

# strictdoc-md - Markdown StrictDoc specifications

**This skill covers `.md` StrictDoc projects only.** StrictDoc also has a `.sdoc`
format; nothing here applies to it.

Everything below was measured on **strictdoc 0.27.1, jq 1.8.1, Git Bash on
Windows 11**. Section 6 tells you what to re-check on another version.

## 1. Check the preconditions first

```bash
strictdoc --version && jq --version
```

**Both must answer.** Without `strictdoc` you cannot produce the JSON, and
without `jq` you cannot query it. If either is missing, stop and tell the user:
`pip install strictdoc` installs both StrictDoc and the Python it needs; `jq`
installs from the user's package manager.

**If the version is not 0.27.1, run the canary in section 6 before you trust the
traps in section 4.**

## 2. Reading - never open the `.md` files

**Export to JSON once, then query it.** On a sample of nine documents the costs
measured like this:

| What you read | tokens |
|---|---:|
| The requirement list through jq | **91** |
| Every `.md` in the folder | 12,300 |
| `index.json` itself | 102,000 |

**Write the output next to the specification, at
`<specification folder>/output/strictdoc`.** That is where `launch-strictdoc.bat`
puts it, so an export and a served session land in the same place instead of
disagreeing.

```bash
strictdoc export <specification folder> --formats=json --output-dir <specification folder>/output/strictdoc
```

That writes `<specification folder>/output/strictdoc/json/index.json`, which the
rest of this skill calls `<json>`.

**Output inside the specification folder is safe.** StrictDoc passes its own
output directory to the file finder as an ignored directory, so it never reads
what it just wrote - measured across repeated exports and with the output folder
named `output`, `build` and `kekka` alike.

**Never read `index.json` directly.** Re-export after every edit; StrictDoc does
not refresh it.

The three queries that answer most questions:

```bash
jq -r '.DOCUMENTS[] | (.UID // "-") + "  " + .TITLE' <json>
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | [.UID, .STATUS, .TITLE] | @tsv' <json>
jq -c 'first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "SW-002")) | del(.NODES)' <json>
```

`references/queries.md` holds 34 more - traceability, coverage gaps, figures,
math, code, tables, attachments. Read it when the three above fall short.

**`--filter-nodes` does not work on JSON.** StrictDoc emits everything with no
error and no warning. Narrow with jq.

**JSON carries no file paths.** To find the file that defines a UID:

```bash
grep -rlF '**UID**: SW-004' <specification folder> --include=*.md
```

## 3. Writing

**A folder with one `.md` file exports.** No grammar file, no config file.

```
<any folder>/
  00-spec.md
```

The built-in grammar already gives you `**UID**:`, `**Statement**:`,
`**Rationale**:`, `**STATUS**:`, `**Type**: SECTION` and `**Relations**:` with
`Parent`. **You must write a `.sgra` grammar the moment you need any of these**
(all measured):

| What you want | Built-in grammar |
|---|---|
| `**Role**: ` on a relation | **Stops** - `relation type/role is not registered` |
| `**Type**: TEST_CASE` or any custom node type | **Stops** - `Invalid node type` |
| A custom field such as `PRIORITY` | **Stops** |

**★ A node with no `**Type**:` line is a `REQUIREMENT`.** That is the default,
and it is the mistake you will actually make: you declare `TEST_CASE` and
`FINDING` in the grammar, write the nodes, forget the `**Type**:` line, and
StrictDoc reads them as requirements and rejects the fields they carry.

```text
Semantic error: Invalid requirement field: SEVERITY
```

**The field name in that message tells you which node lost its type.** Write
`**Type**: FINDING` (or `TEST_CASE`, or `SECTION`) as the first line of the
field block. Only `REQUIREMENT` may leave it out.

`references/authoring.md` carries the `.md` shape, the rules that stop an
export, and a `.sgra` template you can paste.

## 4. The traps that matter

**These four break silently or stop the export with no location.** Read
`references/traps.md` before you write figures, math or tables.

| Trap | What happens |
|---|---|
| A paragraph or table cell **ends with `$`** | HTML export stops with `error: string index out of range`. **JSON export succeeds**, so a JSON-only workflow never sees it |
| **Two `$` on one line** | MathJax eats the text between them. `The cost is $100 to $200` renders "100 to " as math. The export succeeds |
| A pipe **not escaped** inside a table cell | The row splits. A backtick code span does **not** protect a pipe, though it does protect a `$` |
| An attachment **outside `_assets/`**, or a path that does not exist | The export succeeds and the browser gets a 404 |

**When the export dies with no file name:**

```bash
strictdoc export <specification folder> --formats=json --output-dir <output dir> --no-parallelization
```

That prints the real error with a file and a line. `--debug` does not.

## 5. Auditing - run this after you write

**Export both formats, then run the checks.** Zero rows everywhere is healthy.

```bash
strictdoc export <specification folder> --formats=json --output-dir <output dir>
strictdoc export <specification folder> --formats=html --output-dir <output dir>
```

```bash
scripts/audit.sh <specification folder> <output dir> [skip-uids] [figure-prefix]
```

It checks the six things StrictDoc does not: the `$` trap, broken table rows,
attachments that never reached the output, figures that outgrew the body, a
review that says something is wrong without saying what, and requirement wording.

The last two stay quiet where they do not apply. `review comment missing` needs
a grammar that declares `REVIEW_STATUS`. `wording candidates` reads Japanese
patterns only, so it skips any statement with no Japanese character in it -
without that gate it flagged every requirement in an English project (measured),
and since this script exits with the number of failing checks, gating a build on
it would then fail forever.

**`wording candidates` reports candidates, not violations.** A shell script can
decide which strings are present. It cannot decide intent, so an intended
passive and an accidental one look identical to it, and it cannot find a
transitive verb missing its object because valency is not in the text. Expect
`negative` rows on any requirement written in the EARS unwanted-behaviour
pattern - those are correct. Only `ears-order`, a condition placed after the
subject, is a defect on its own.

Hand the rest to a reader, or judge them yourself. The machine narrows the list;
you decide which of its candidates is really a mistake, and you catch the one
thing it cannot see at all:

> Take each row `audit.sh` reported. For every one, quote the statement, say
> whether the passive, the negative or the missing subject is deliberate, and
> why. Then, separately, read every requirement for a transitive verb with no
> object - `audit.sh` cannot find those. Propose a rewrite for each real
> problem and leave the deliberate ones alone.

It exits with the number of checks that found something, so you can gate on it.

**It deliberately does not check duplicate UIDs or dangling relations.**
StrictDoc refuses to export either one - within a document and across documents
(measured) - so a query for them can never return a row. If the export
succeeded, both are already clean.

**`--formats=json` alone proves nothing.** It passes over the `$` trap. Always
run `--formats=html` too when you touched a figure, a formula or a table.

## 6. When the version differs

Write a file whose only content is a paragraph ending in math, then export it to
HTML:

```bash
printf '# Canary\n\nThe time is $T$\n' > <tmp>/00.md
strictdoc export <tmp> --formats=html --output-dir <tmp-out>
```

- **It fails with `string index out of range`** - the traps in section 4 still
  apply. Continue.
- **It passes** - StrictDoc fixed the `$` trap. Tell the user that this skill's
  section 4 is out of date for their version, and keep working.

## 7. Log what surprises you, then move on

**When StrictDoc behaves in a way this skill does not describe, do not
investigate.** Work around it, append one line to
`<specification folder>/strictdoc-quirks.tsv`, and carry on.

```bash
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date +%F)" "$(strictdoc --version)" "export-html" "the error's first line" "what you did instead" "the file" >> <specification folder>/strictdoc-quirks.tsv
```

Create it with a header row if it does not exist: `date`, `sd_version`, `step`,
`symptom`, `workaround`, `where`. **Append only.** Someone reads the file in
bulk later, when a version changes or the lines pile up, and folds what it says
back into this skill. StrictDoc does not parse `.tsv`, so the file never becomes
a document.

## Conventions this skill assumes, and how to change them

**Two settings are project agreements, not StrictDoc behaviour.** Pass them to
the queries as arguments; never edit a query body.

| Agreement | Default here | How to override |
|---|---|---|
| UID prefix that marks a figure document | `DOC-FIG-` | `--arg figprefix` |
| Which documents only explain notation | none | `--arg skip 'UID,UID'` |

A document that explains notation carries figures, math and tables in bulk, so
it drowns any count you take. List the requirement-free documents with the first
query in section 2 and pass them to `--arg skip`.

## Reference files

| File | Read it when |
|---|---|
| `references/authoring.md` | You write or change a `.md` document, or need a `.sgra` |
| `references/notation.md` | You add a figure, formula, code block, table or attachment |
| `references/traps.md` | The export fails, or before you ship anything with math or tables |
| `references/queries.md` | The three queries in section 2 do not answer the question |
| `scripts/audit.sh` | Always, after writing |
