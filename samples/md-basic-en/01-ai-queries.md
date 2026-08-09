# jq query collection - for AI

**UID**: DOC-AI-QUERIES \
**Version**: 1.0

This document expands "Pull only the part of the specification you need" of `00-ai-guide.md`.
`00-ai-guide.md` already carries the main queries. If those are enough, skip this document.

We ran every query below against the JSON that `strictdoc export --formats=json` produced
from `samples/md-basic-en`, and we checked each output. `<json>` means `<output dir>/json/index.json`.

The `DOC-*` and `SW-*` names in this document belong to this worked example.
`00-ai-guide.md` collects the substitutions for another project in a table under
"What to substitute when you use this guide on another project".
**You do not need to rewrite the shape of a query.** Each query takes the values that
depend on this worked example from outside through `--arg`.

What this worked example holds: system requirements `SYS-001..003` / software requirements
`SW-001..004` / test cases `TC-001..004`. The review results sit in the `REVIEW_STATUS` of
the requirements themselves.
This document and `00-ai-guide.md` are documents too (`DOC-AI-QUERIES` / `DOC-AI-GUIDE`).
A document that explains the notation carries figures and code in bulk, so **always exclude
one from a query that aggregates.** The six to exclude are `DOC-AI-GUIDE`,
`DOC-AI-QUERIES`, `DOC-GUIDE`, `DOC-REVIEW`, `DOC-BROWSER` and `DOC-COWORK` (measured
with G27).
The one place that carries figures, math, code and tables together is the last chapter of
`DOC-LOWER`, alongside `_assets/fig-state.md` (`DOC-FIG-STATE`).

---

## A. Get the big picture

**Type**: SECTION

### A1. The document list

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | (.UID // "-") + "  " + .TITLE' <json>
```

```text
DOC-AI-GUIDE  Markdown StrictDoc specifications - a guide for AI
DOC-AI-QUERIES  jq query collection - for AI
DOC-GUIDE  Read this first
DOC-USECASES  Use cases
DOC-UPPER  System requirements
DOC-ARCH  System structure
DOC-LOWER  Software requirements
DOC-TESTS  Test cases
DOC-REVIEW  How we review
DOC-BROWSER  Driving StrictDoc from the browser
DOC-COWORK  Working alongside Claude
DOC-FIG-STATE  Large figure - conversion state machine
DOC-NOTE  Terminology map
```

The query prints 13 entries. `DOC-AI-GUIDE` and `DOC-AI-QUERIES` are guides for AI,
`DOC-GUIDE` is an explanatory document for humans, `DOC-ARCH` is the map of the system
structure, `DOC-REVIEW` explains how the review runs, `DOC-BROWSER` is the guide to the
browser, `DOC-COWORK` is how to write alongside an AI, `DOC-NOTE` is the terminology table
in `_assets/note.md`, and `DOC-FIG-STATE` is the large figure in `_assets/fig-state.md`.
None of these 9 holds a requirement. StrictDoc parses every `.md` file as a document
no matter where the file sits.

### A2. Counts by node type

**Type**: SECTION

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | ._NODE_TYPE] | group_by(.) | map({(.[0]): length}) | add' <json>
```

```json
{"DOCUMENT":13,"REQUIREMENT":7,"SECTION":143,"TEST_CASE":4,"TEXT":144,"USE_CASE":1}
```

### A3. The table of contents

**Type**: SECTION

`_TOC` holds a hierarchical number such as `2.1.1`.

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="SECTION") | ._TOC + "  " + .TITLE' <json>
```

### A4. Field names available per type

**Type**: SECTION

This query tells you the schema of an existing project from its JSON. When you write a
specification from scratch, no JSON exists yet, so this query does not work. Read
`basic.sgra` directly instead.

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE) | {t:._NODE_TYPE, k:keys}] | group_by(.t) | map({(.[0].t): (map(.k)|add|unique)}) | add' <json>
```

```json
{"DOCUMENT":["GRAMMAR","NODES","TITLE","UID","VERSION","_NODE_TYPE","_OPTIONS"],
 "REQUIREMENT":["RATIONALE","RELATIONS","REVIEW_ACTION","REVIEW_COMMENT","REVIEW_STATUS",
                "STATEMENT","STATUS","TITLE","UID","_NODE_TYPE","_TOC"],
 "SECTION":["NODES","TITLE","_NODE_TYPE","_TOC"],
 "TEST_CASE":["GIVEN","ISSUE_KEY","RELATIONS","TEST_REMARK","TEST_RESULT","THEN",
              "TITLE","UID","WHEN","_NODE_TYPE","_TOC"],
 "TEXT":["STATEMENT","_NODE_TYPE","_TOC"],
 "USE_CASE":["REVIEW_COMMENT","REVIEW_STATUS","STATEMENT","TITLE","UC_LEVEL","UID",
             "_NODE_TYPE","_TOC"]}
```

`-c` makes jq print one line; the block above wraps it for reading. All six node types
show up. `basic.sgra` defines three of them - `REQUIREMENT`, `USE_CASE` and `TEST_CASE`; StrictDoc builds
`DOCUMENT`, `SECTION` and `TEXT` from the structure of the Markdown.

---

## B. Pin down a location

**Type**: SECTION

### B5. One node by UID

**Type**: SECTION

```bash
jq -c 'first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "SW-002")) | del(.NODES)' <json>
```

`first(...)` stops the search at the first hit. `del(.NODES)` lets you run the same
expression on a section node as well.

### B6. UIDs by regular expression

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? and (.UID | test("^SW-"))) | .UID' <json>
```

```text
SW-001
SW-002
SW-003
SW-004
```

### B7. Search by word

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | select(((.TITLE//"") + (.STATEMENT//"")) | contains("convert")) | .UID' <json>
```

To cover every field, flatten the node with `[.. | strings] | join(" ")` first and then
apply `contains`.

### B8. Search by regular expression

**Type**: SECTION

`test()` takes flags as its second argument. `"i"` ignores case. It handles Japanese too.

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.TITLE? and (.TITLE | test("convert|check"; "i"))) | (.UID // "-") + "  " + .TITLE' <json>
```

```text
-  Step 1 - Convert to JSON
UC-001  Convert an input file into the requested format
SYS-001  Converting a file
SW-002  Checking the input format
SW-003  Checking the destination
```

### B9. Narrow to one document

**Type**: SECTION

**You cannot filter by file name. The JSON holds no file path.** Use the document `UID`.

```bash
jq -r '.DOCUMENTS[] | select(.UID=="DOC-UPPER") | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | .UID + "  " + .TITLE' <json>
```

When you do not know a document's UID, look it up with A1.

### B10. Narrow to one chapter

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._TOC? and (._TOC | startswith("2."))) | ._TOC + "  " + (.TITLE // "")' <json>
```

`startswith("2.")` matches `2.1` and `2.2`, but it does not match the chapter itself (`2`).
To include the chapter itself, write `(._TOC=="2" or (._TOC|startswith("2.")))`.

---

## C. Follow relations

**Type**: SECTION

### C11. Direct parents

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?=="TC-001") | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE' <json>
```

### C12. Parents up to the root (transitive)

**Type**: SECTION

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID)] as $all
| def anc($u): ($all[] | select(.UID==$u) | .RELATIONS? // [] | .[] | select(.TYPE=="Parent") | .VALUE) as $p | [$p], anc($p);
  [anc("TC-001")] | flatten | unique | .[]' <json>
```

```text
SW-001
SYS-001
UC-001
```

### C13. Direct children (reverse lookup)

**Type**: SECTION

**The JSON records no children.** Scan every node and collect the ones that name the node
you want as their parent.

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE=="SYS-001")) | .UID' <json>
```

### C14. Children down to the leaves (transitive)

**Type**: SECTION

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID)] as $all
| def desc($u): ($all[] | select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE==$u)) | .UID) as $c | [$c], desc($c);
  [desc("SYS-001")] | flatten | unique | .[]' <json>
```

```text
SW-001
TC-001
```

### C15. Narrow by ROLE

**Type**: SECTION

In this set only the test cases use `Verifies`.

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?) as $n | ($n.RELATIONS // [])[] | select(.ROLE=="Verifies") | $n.UID + " -> " + .VALUE' <json>
```

```text
TC-001 -> SW-001
TC-002 -> SW-002
TC-003 -> SW-003
TC-004 -> SW-004
```

---

## D. Find the gaps

**Type**: SECTION

### D16. Requirements that no test case points to "directly"

**Type**: SECTION

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE") | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE] as $tested
| .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.UID | IN($tested[]) | not) | .UID + "  " + .TITLE' <json>
```

```text
SYS-001  Converting a file
SYS-002  Rejecting unexpected input
SYS-003  Protecting an existing file
```

In this set the tests cover the software requirements `SW-*`, and nothing covers the system
requirements `SYS-*` directly.
This is design, not a defect - the software requirements underneath cover them.

### D17. Requirements with no parent

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | select(((.RELATIONS // []) | map(select(.TYPE=="Parent")) | length) == 0) | .UID' <json>
```

### D18. Requirements that nothing points to

**Type**: SECTION

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE] as $parents
| .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.UID | IN($parents[]) | not) | .UID' <json>
```

This sample returns 0 entries (something points to every requirement).

**Broken links and duplicate UIDs need no query.** StrictDoc stops the export
while it resolves relations and writes no JSON at all (measured). By the time a
JSON exists, neither defect is in it. These were D19 and D20; they were removed
because they can never fire, and the numbers are left as gaps.

```text
error: [DocumentIndex.create] Requirement SW-001 references parent requirement which doesn't exist: SYS-999.
error: DocumentIndex: two nodes with the same UID exist in the same document: SW-002 in "Lower-level requirements".
error: DocumentIndex: two nodes with the same UID exist in two different documents: SW-002 in "Lower-level requirements" and "Test cases".
```

A duplicate UID stops the export inside one document and across two, with a
different message for each.

---

## E. Filter by field

**Type**: SECTION

### E21. Filter by STATUS

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT" and .STATUS=="Draft") | .UID' <json>
```

### E22. and / or / not

**Type**: SECTION

You can use the ordinary logical operators inside `select()`.

```bash
# and - requirements that reached review and carry a finding nobody has acted on
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS=="Open" and .STATUS=="Reviewed") | .UID' <json>

# or - test cases, or requirements we decided against changing
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE" or .REVIEW_STATUS=="WontFix") | .UID' <json>

# not - nodes that hold a UID and are not requirements
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? and (._NODE_TYPE=="REQUIREMENT" | not)) | ._NODE_TYPE + " " + .UID' <json>
```

Put `not` at the end. You cannot write `select(not(...))`.

### E23. Find nodes that lack a field

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | select(has("RATIONALE") | not) | .UID' <json>
```

**`has()` returns true even when the value is empty.** To exclude an empty string as well,
write `select((.RATIONALE // "") == "")`.

---

## F. Shape the output

**Type**: SECTION

### F24. Table form (the cheapest listing)

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | [.UID, .STATUS, .TITLE] | @tsv' <json>
```

```text
SYS-001	Approved	Converting a file
SYS-002	Approved	Rejecting unexpected input
SYS-003	Reviewed	Protecting an existing file
SW-001	Approved	Running the conversion
SW-002	Approved	Checking the input format
SW-003	Approved	Checking the destination
SW-004	Draft	Atomic writing
```

### F25. The count only

**Type**: SECTION

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")] | length' <json>
```

### F26. Only the fields you need, as JSON

**Type**: SECTION

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS? and .REVIEW_STATUS != "NoFinding")] | map({UID, REVIEW_STATUS})' <json>
```

**Do not add `-r`.** It flattens the output into strings.

---

## G. Handle figures, math, and code

**Type**: SECTION

`STATEMENT` holds every figure, formula, and code block verbatim. So `jq` can pull them
out, and you can count what sits inside them. The queries in this chapter build on that.

The queries in this chapter follow two rules.

- They use no double backslash in a regular expression. They use the character classes
  `[$]` and `[[]` in place of `\\$` and `\\[`, and they use `contains()` / `split()` even
  where a regular expression would do. G0 explains why
- They wrap their code fences in four backticks. The query body itself contains ` ``` `,
  so three backticks would close the fence halfway. StrictDoc reads a four-backtick fence
  correctly too (measured)

### G0. Why we avoid double backslashes

**Type**: SECTION

When you hand a query to Git Bash as `bash -c "..."`, Git Bash cuts every double
backslash in half. We measured this on strictdoc 0.27.1 / jq 1.8.1 / Windows 11.

| How you pass it | Result of `scan("!\\[...")` |
|---|---|
| `jq -f query.jq` | passes |
| You put it in a shell script and run `bash script.sh` | passes |
| `bash -c 'jq -r ...'` | fails with `Invalid escape` |

An AI usually runs its commands in the `bash -c` form. **So do not write a query that
contains a double backslash.** String operations give you the same result.

A single backslash survives. `split("\n")` passes in every form above (measured).
Git Bash halves only a doubled backslash, so you can use `\n` and `\t` normally.

When a query has to get complicated, put it in a file. It never passes through the
shell, so nothing breaks it.

```bash
jq -r -f <query file>.jq <json>
```

### G27. What lives where

**Type**: SECTION

Run this one first. It lists which node of which document holds a figure, a formula,
code, a table, or an image.

````bash
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | select(.STATEMENT?) as $n | $n.STATEMENT as $s
| [$s | split("```") | to_entries[] | select(.key % 2 == 1) | .value | split("\n")[0] | rtrimstr("\r")] as $lang
| [ (if ($lang | index("mermaid")) then "figure" else empty end),
    (if ($s | contains("$$")) then "math" else empty end),
    (if ($lang | map(select(. != "mermaid" and . != "")) | length) > 0 then "code" else empty end),
    (if ($s | test("(?m)^[|]")) then "table" else empty end),
    (if ($s | contains("![")) then "image" else empty end) ] as $k
| select(($k | length) > 0) | $doc + "  " + ($n.UID // $n._TOC // "-") + "  " + ($k | join(","))' <json>
````

```text
DOC-AI-GUIDE  5.2.1  code,table
DOC-GUIDE  3.2.1  figure,image
DOC-USECASES  1  table
DOC-USECASES  2.1  code,table
DOC-USECASES  3.1  code,table
DOC-UPPER  2.1  table
DOC-UPPER  2.2.1  code,table
DOC-ARCH  2.1  figure
DOC-ARCH  3.1  figure
DOC-ARCH  4.1  table
DOC-LOWER  6.1  figure,math,code,table
DOC-TESTS  1  code
DOC-TESTS  2.1  code,table
DOC-FIG-STATE  1  figure
DOC-NOTE  1  table
```

(15 representative rows out of 126. Six explanatory documents take up 113 of them -
this document, `00-ai-guide.md`, `02-guide-for-human.md`, `08-review.md`,
`09-browser-guide.md` and `10-cowork-with-claude.md`. A document that explains the
notation carries that notation in bulk, so pass `--arg skip` as example 13 does when you
count. The specification itself produces only 13 rows - the `DOC-USECASES`, `DOC-UPPER`,
`DOC-ARCH`, `DOC-LOWER`, `DOC-TESTS`, `DOC-FIG-STATE` and `DOC-NOTE` rows above - and the
other 2 rows above are samples lifted out of an explanatory document)

The second column shows the `UID` when the node has one and the `_TOC` hierarchical number
when it does not. Free text carries no UID, so use `_TOC` to point at a position.

Read the language name one fence at a time. When you cut the text on ` ``` `, every
odd-numbered piece is fence content, so its first line is the language name. **Never decide
by asking whether the whole node contains `mermaid`.** When a figure and code share one
node, that test drops the code. `DOC-LOWER 6.1` has exactly that shape (a figure, math, and
code together), so always try your own query of this kind on that line.

### G28. Extract a figure definition

**Type**: SECTION

````bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-FIG-STATE") | recurse(.NODES[]?) | (.STATEMENT? // "")
| select(contains("```mermaid")) | split("```")[] | select(startswith("mermaid")) | ltrimstr("mermaid")' <json>
````

```text
stateDiagram-v2
    [*] --> Idle
    Idle --> ParseArgs : the user runs the conversion
    (16 more lines)
```

`split("```")` cuts the text at every fence boundary, keeps only the pieces that start with
`mermaid`, and drops the leading `mermaid` (7 characters). The JSON holds the fence
content verbatim, so this hands you the whole Mermaid definition.

Change the language name and the same shape pulls out code as well (G31).

### G29. Count what sits side by side in a figure

**Type**: SECTION

This project's guideline says: at 5 lifelines or more in a sequence diagram, or 5
classes or more in a class diagram, move the figure into `_assets/fig-*.md` as its own
document. A flowchart carries no guideline. The query below passes no judgement; it
reports the counts, and the writer decides where the figure goes.

First, measure every figure:

````bash
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | (.STATEMENT? // "")
| select(contains("```mermaid")) | split("```")[] | select(startswith("mermaid"))
| ltrimstr("mermaid") | split("\n") | map(rtrimstr("\r")) | map(select(. != "")) as $lines
| ($lines[0] // "-") as $kind
| ([$lines[] | select(test("^ *(participant|actor) "))] | length) as $l
| ([$lines[] | select(test("^ *class "))] | length) as $c
| $doc + "  " + $kind + "  lifelines " + ($l|tostring) + "  classes " + ($c|tostring)' <json>
````

```text
DOC-AI-GUIDE   ` fence | passes | `<pre class="mermaid">` |  lifelines 0  classes 0
DOC-AI-GUIDE  stateDiagram-v2  lifelines 0  classes 0
DOC-AI-GUIDE  ")) | split("  lifelines 0  classes 0
DOC-AI-GUIDE  ")) | split("  lifelines 0  classes 0
DOC-AI-GUIDE  ")) | split("  lifelines 0  classes 0
DOC-AI-GUIDE  ")) | split("  lifelines 0  classes 0
DOC-AI-QUERIES  ")) | split("  lifelines 0  classes 0
DOC-AI-QUERIES  ")) | split("  lifelines 0  classes 0
DOC-AI-QUERIES  ")) | split("  lifelines 0  classes 0
DOC-GUIDE  flowchart LR  lifelines 0  classes 0
DOC-ARCH  flowchart LR  lifelines 0  classes 0
DOC-ARCH  sequenceDiagram  lifelines 3  classes 0
DOC-LOWER  flowchart LR  lifelines 0  classes 0
DOC-BROWSER     lifelines 0  classes 0
DOC-FIG-STATE  stateDiagram-v2  lifelines 0  classes 0
```

The kind of figure is the first line of the fence, printed as it stands. A row whose
kind column holds a fragment of jq is not a figure. An explanatory document writes the
fence marker and the language name `mermaid` inside the body of a query, and this query
picks that up as a fragment of a figure. Measure a document that explains the notation
and self-reference of this kind always mixes in.

This query cannot count a sequence diagram that declares neither `participant` nor
`actor`. Mermaid raises a lifeline from the arrows alone, but this query reads strings
out of the JSON and draws no such inference. Write `participant` in a figure you want
counted.

The next form prints only the figures past the guideline. It skips a document whose UID
starts with `DOC-FIG-`, because you already moved that one out. 0 rows is the normal
result.

````bash
jq -r --arg figprefix 'DOC-FIG-' '.DOCUMENTS[] | select(.UID | startswith($figprefix) | not) | .UID as $doc
| recurse(.NODES[]?) | select(.STATEMENT?) as $n | ($n.STATEMENT // "")
| select(contains("```mermaid")) | split("```")[] | select(startswith("mermaid"))
| ltrimstr("mermaid") | split("\n") | map(rtrimstr("\r")) | map(select(. != "")) as $lines
| ([$lines[] | select(test("^ *(participant|actor) "))] | length) as $l
| ([$lines[] | select(test("^ *class "))] | length) as $c
| select($l >= 5 or $c >= 5)
| $doc + "  " + ($n.UID // $n._TOC // "-") + "  lifelines " + ($l|tostring) + "  classes " + ($c|tostring)' <json>
````

This sample returns 0 entries, because every figure past the guideline already sits in
`_assets/`.

### G30. Extract the math

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-LOWER") | recurse(.NODES[]?) | (.STATEMENT? // "")
| [scan("[$][$]([^$]+)[$][$]")] | .[][] | gsub("^\n|\n$"; "")' <json>
```

```text
S_{need} = S_{out} + S_{tmp} = 2 \times S_{out}
```

`[$][$]` is a character class that stands for `$$` (G0). `scan()` returns one array per
capture, so `.[][]` flattens them.

Narrow to one document. Run it across everything and it also picks up the `$$`
description in the notation guide inside `02-guide-for-human.md`, and then you cannot tell
which formula is real.

Give up on extracting an inline `$...$` mechanically. You cannot tell it apart from a
`$` that sits in free text (an amount of money or an environment variable), so the query
misfires. When you need an inline formula, find its place with G27 and then read that
node's whole `STATEMENT`.

### G31. Code by language

**Type**: SECTION

How many blocks each language holds:

````bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | (.STATEMENT? // "") | scan("(?m)^```([a-z]+)")]
| flatten | group_by(.) | map({(.[0]): length}) | add' <json>
````

```json
{"bash":56,"json":5,"markdown":3,"mermaid":6,"python":4,"text":76}
```

`mermaid` shows up here too. A figure is a code fence as well.

Pull out the content (the same shape as G28):

````bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-LOWER") | recurse(.NODES[]?) | (.STATEMENT? // "")
| split("```")[] | select(startswith("python")) | ltrimstr("python")' <json>
````

```text
def convert(src: str, dst: str) -> None:
    tmp = dst + ".part"          # create it in the same directory as dst
    (6 more lines)
```

This shape misses a fence whose author wrote no language name. **So always write the
language name yourself.**

### G32. Image targets

**Type**: SECTION

```bash
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | (.STATEMENT? // "")
| split("![") | .[1:][] | select(contains("](")) | split("](")[1] | split(")")[0]
| $doc + "  " + .' <json>
```

```text
DOC-AI-GUIDE  _assets/x.svg
DOC-AI-GUIDE  _assets/x.svg
DOC-AI-GUIDE  "
DOC-AI-GUIDE  path
DOC-AI-QUERIES  "
DOC-AI-QUERIES  path
DOC-AI-QUERIES  ...
DOC-GUIDE  path
DOC-GUIDE  _assets/flow.svg
```

All 9 rows are above, and only the last one names an image that exists.
`path` and `_assets/x.svg` come straight from the `![alt](path)` syntax that the
explanatory documents describe, and `"` and `...` are fragments of a query body this
document quotes. A set that includes a document explaining the notation mixes in apparent
hits like these.

The query stacks `split()` three times so that it can carve out `![...](...)` without a
backslash.

### G33. Find lines that hold the `$` trap

**Type**: SECTION

**When `$` stands as the last character of a paragraph or of a table cell, the HTML export
stops and prints `error: string index out of range` and nothing else.** It gives you no
file name and no line number.

The JSON export, however, succeeds (measured). So export the JSON first and run this
query, and you find the place before you build the HTML.

````bash
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | (.STATEMENT? // "")
| split("\n") | map(rtrimstr("\r"))
| reduce .[] as $line ({open: 0, out: []};
    ([$line | scan("^`{3,}")] | (.[0] // "") | length) as $w
    | if $w > 0
      then (if .open == 0 then .open = $w elif $w >= .open then .open = 0 else . end)
      else (if .open == 0 then .out += [$line] else . end)
      end)
| .out[]
| select(test("[^$][$] *$") or test("[^$][$] *[|]"))
| $doc + "  " + .' <json>
````

This sample returns 0 entries. 0 entries is the normal result. Run it on a document we
broke on purpose and it prints this:

```text
DOC-LINT  CRASH  paragraph ending in math $T$
DOC-LINT  CRASH  bare trailing dollar 100 $
DOC-LINT  SAFE   escaped trailing dollar 100 \$
DOC-LINT  | CRASH cell ending in math | $T$ |
```

The `reduce` part throws the fence content away. A `$` does no harm inside a fence, so
keeping it would flood you with false detections.

The query remembers how long the opening fence marker is and closes only on a marker of
the same length or longer. A simpler way cuts on three `` ` `` and takes the
even-numbered pieces, but that breaks on a document that puts ` ``` ` inside ` ```` `.
This document and `00-ai-guide.md` have exactly that shape, so the simple version reports
4 false positives (measured).

One kind of false detection remains - the query also prints a line that escapes the
character as `\$` (the third line above). An escaped one is safe, so look at it and skip it.

### G34. Rewrite a figure and write it back to `.md`

**Type**: SECTION

**You cannot write back from JSON to `.md` mechanically.** The JSON holds no file path
(see the note at the top of this document). Follow these steps.

1. Extract the figure - G28.

2. Find which file holds it. Search for the UID declaration as a fixed string.
You add `-F` so that grep does not read `**` as a regular expression.

```bash
grep -rlF '**UID**: DOC-FIG-STATE' <specification folder> --include=*.md
```

```text
samples/md-basic-ja/_assets/fig-state.md
```

**A file that only mentions the UID does not show up.** The query above matches the
`**UID**:` declaration, so `06-lower.md`, which only references it with
`[LINK: DOC-FIG-STATE]`, drops out.

3. Edit that `.md` directly. Replace the fence content.

4. Count what sits side by side again. Once the figure passes the guideline, move it out
of the body into `_assets/fig-*.md` and leave a `[LINK:]` in its old place (G29).

5. Export again. StrictDoc does not update the JSON on its own.

```bash
strictdoc export <specification folder> --formats=json --output-dir <output dir>
```

6. Confirm that the HTML passes too. `--formats=json` lets the `$` trap through.
Whenever you touch a figure or a formula, run `--formats=html` as well.

```bash
strictdoc export <specification folder> --formats=html --output-dir <output dir>
```
