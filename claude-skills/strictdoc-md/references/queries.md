# Pulling data out with jq

Loaded by the `strictdoc-md` skill. Read this when the three queries in the
skill itself do not answer the question.

`<json>` means `<output dir>/json/index.json`. Every query here ran against the
worked example in `samples/md-basic-en` and produced the output shown.

---

## 3. Pull only the part of the specification you need

**When you need only a part of the specification, do not read the `.md` files.**
Reading the whole specification of this worked example (`03` through `07` and
`_assets/`) costs a little under a fifth of reading every `.md` in the set, and
about a third of it once you include `02-guide-for-human.md`. Convert it to JSON
and pull the list of requirements with `jq`, and the same answer costs under 0.2 %.

**★ This ban covers only "reading in order to learn". You may open a file to rewrite it.**
When your job is to fix an existing specification, the correct procedure is to
open the target `.md` and edit it (3.1 collects the steps).
**You cannot mechanically write back from JSON to `.md`** -
the JSON holds no file paths.

| What you do | Do you open the `.md`? |
|---|---|
| Learn, count or search the content | **No.** Export JSON and query it with `jq` |
| Rewrite the content | **Yes.** Locate the place with example 16 first, then open it |

### Step 1 - Convert to JSON

```bash
strictdoc export <specification folder> --formats=json --output-dir <output dir>
```

StrictDoc creates `<output dir>/json/index.json`. Below we write `<json>` for this file.

**Put `<output dir>` outside the specification folder.** Use a scratch location such as somewhere under `%TEMP%`.

To be precise, **only `--formats=sdoc` is dangerous** (measured). StrictDoc skips
its own json / html output, so that output breaks nothing even when it sits
inside the folder. But `sdoc` writes out `.sdoc` files that StrictDoc can parse,
so the next run picks them up as input and the whole export stops.

```text
error: TraceabilityIndex: the document "A" imports a grammar from a file that does not exist: "basic.sgra".
```

**Always writing outside is safer than remembering which format is safe.**

**You may write json and html to the same `<output dir>`** (measured). StrictDoc splits them into
`<output dir>/json/` and `<output dir>/html/`, so they do not overwrite each other.

**After you edit a `.md`, run this `strictdoc export` again.**
StrictDoc does not update the JSON on its own.

**Do not read this `index.json` directly** - it is bigger than the whole `.md` set,
about one and a half times it.
The file exists only for `jq` to read.

**StrictDoc has a query language of its own, but it does not affect the JSON output.**
`--filter-nodes` narrows only the `.sdoc` and the HTML output. Add it to `--formats=json` and
**StrictDoc emits every node with neither an error nor a warning**. Do the narrowing with `jq`.

### Step 2 - Pull the data out with jq

The structure of the JSON:

```json
{"DOCUMENTS": [
  {"_NODE_TYPE": "DOCUMENT", "UID": "...", "TITLE": "...", "GRAMMAR": {},
   "NODES": [
     {"_NODE_TYPE": "SECTION", "TITLE": "...", "NODES": [
       {"_NODE_TYPE": "TEXT", "_TOC": "2.1.1", "STATEMENT": "Free text. It has no UID"}]},
     {"_NODE_TYPE": "REQUIREMENT", "UID": "...", "TITLE": "...", "STATEMENT": "...",
      "RELATIONS": [{"TYPE": "Parent", "VALUE": "...", "ROLE": "..."}]}]}]}
```

**★ Figures, math and code land almost entirely in free-text nodes with `_NODE_TYPE == "TEXT"`.**
You can write them in the `STATEMENT` of a requirement, but they normally sit in free text.
**A `TEXT` node has no `UID`.** To point at a place, use `_TOC` (a hierarchical number
such as `2.1.1`). When you tell a person where something is, give all three:
**the `UID` of the document, the `_TOC`, and the title of the parent chapter**.

Nodes nest inside each other. **Use the following boilerplate to flatten them.**

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | .UID + "  " + .TITLE' <json>
```

- The key that tells you the node type is `_NODE_TYPE`. **It starts with an underscore.** So do `_TOC` and `_OPTIONS`
- **The JSON holds no `.md` file paths.** To pull "only the requirements of one file",
  narrow by the `UID` of the document (`DOC-UPPER`, for instance). Example 1 finds the document UIDs
- `_TOC` is a hierarchical number such as `2.1.1`. Use it to narrow by chapter
- **The JSON records no "children".** To pull the children of a requirement, walk every
  node and collect the ones whose parent is that requirement
- `RELATIONS` puts both `Parent` and `File` in the same array. When you need only the parents,
  narrow with `select(.TYPE=="Parent")`
- **Do not add `--included-documents`.** It duplicates the included documents,
  and the same UID shows up in two places
- The JSON contains neither `DATE` nor `METADATA:`. The document-level metadata is only
  `UID` / `VERSION` / `CLASSIFICATION` / `PREFIX` / `ROOT`
- With `-r`, `jq` prints lines a human reads; without it, `jq` prints JSON as it is.
  **Leave it off when a program processes the output**
- StrictDoc converts non-ASCII characters to `\uXXXX` inside `index.json`, but `jq`
  prints the original characters back. You do not have to convert anything yourself

### Examples

We ran every one of these and checked its output.

```bash
# 1. What is there to begin with - the list of documents
jq -r '.DOCUMENTS[] | (.UID // "-") + "  " + .TITLE' <json>

# 2. Field names usable per node type (read the schema of an existing project from
#    the JSON. When you start a new one there is no JSON yet, so read basic.sgra directly)
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE) | {t:._NODE_TYPE, k:keys}] | group_by(.t) | map({(.[0].t): (map(.k)|add|unique)}) | add' <json>

# 3. The list of requirements as a table (cheapest of all)
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | [.UID, .STATUS, .TITLE] | @tsv' <json>

# 4. Every field of one requirement
jq -c 'first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "SW-002")) | del(.NODES)' <json>

# 5. Narrow to one document (you cannot narrow by file name)
jq -r '.DOCUMENTS[] | select(.UID=="DOC-UPPER") | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | .UID + "  " + .TITLE' <json>

# 5b. Reverse lookup - which document each node belongs to
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | select(.UID? and ._NODE_TYPE!="DOCUMENT") | $doc + "  " + .UID + "  " + .TITLE' <json>

# 6. Search with a regular expression (the 2nd argument holds flags. "i" ignores
#    case. Non-ASCII characters work too)
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.TITLE? and (.TITLE | test("convert|check"; "i"))) | (.UID // "-") + "  " + .TITLE' <json>

# 7. and / or / not - put not at the end
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS=="Open" and .STATUS=="Reviewed") | .UID' <json>
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE" or .REVIEW_STATUS=="WontFix") | .UID' <json>
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? and (._NODE_TYPE=="REQUIREMENT" | not)) | ._NODE_TYPE + " " + .UID' <json>

# 8. Direct children (reverse lookup)
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE=="SYS-001")) | .UID' <json>

# 9. Walk the parents up to the root (transitive). unique sorts the result, so the output
#    order is not the hierarchy order. To tell which one is the root, open each returned
#    UID with example 4 and check that it carries no RELATIONS
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID)] as $all
| def anc($u): ($all[] | select(.UID==$u) | .RELATIONS? // [] | .[] | select(.TYPE=="Parent") | .VALUE) as $p | [$p], anc($p);
  [anc("TC-001")] | flatten | unique | .[]' <json>

# 10. Requirements that no test case points at "directly".
#     This is not transitive coverage. This sample returns SYS-001..003, but tests
#     reach all three through software requirements. That is not a defect. For a
#     transitive view, apply the reverse of example 9 (walk the children) to each UID
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE") | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE] as $tested
| .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.UID | IN($tested[]) | not) | .UID + "  " + .TITLE' <json>

# 11. Relations that point at a UID that does not exist (a broken link). Zero is normal
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?) | .UID] as $ids
| .DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?) as $n
| ($n.RELATIONS // [])[] | select(.VALUE | IN($ids[]) | not) | $n.UID + " -> " + .VALUE' <json>

# 12. Just the count
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")] | length' <json>
```

### Examples for figures, math, and code

**These two use a fence of four backticks.** The query body itself contains
` ``` ` (2.5).

**13. Where the figures, math, code, tables, and images are.** The second column
holds the `UID`, or `_TOC` when the node has none.

**Pass the UIDs of the explanatory documents to `--arg skip` as a comma-separated
list.** Without it the output mixes in a large amount of their content (below).

````bash
jq -r --arg skip 'DOC-AI-GUIDE,DOC-AI-QUERIES,DOC-GUIDE,DOC-REVIEW' '($skip | split(",")) as $s
| .DOCUMENTS[] | select(.UID | IN($s[]) | not) | .UID as $doc
| recurse(.NODES[]?) | select(.STATEMENT?) as $n | $n.STATEMENT as $t
| [$t | split("```") | to_entries[] | select(.key % 2 == 1) | .value | split("\n")[0] | rtrimstr("\r")] as $lang
| [ (if ($lang | index("mermaid")) then "figure" else empty end),
    (if ($t | contains("$$")) then "math" else empty end),
    (if ($lang | map(select(. != "mermaid" and . != "")) | length) > 0 then "code" else empty end),
    (if ($t | test("(?m)^[|]")) then "table" else empty end),
    (if ($t | contains("![")) then "image" else empty end) ] as $k
| select(($k | length) > 0) | $doc + "  " + ($n.UID // $n._TOC // "-") + "  " + ($k | join(","))' <json>
````

```text
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

**What you pass to `--arg skip` differs from one worked example to the next.** This
worked example has six explanatory documents (`DOC-AI-GUIDE` = this document,
`DOC-AI-QUERIES`, `DOC-GUIDE`, `DOC-REVIEW`, `DOC-BROWSER` and `DOC-COWORK`). **In the other project, list the documents with
example 1 first, find the ones that double as an explanation of the notation, and
pass those** (`queries.md`, "Exclude explanatory documents when you count", tells you
how to find them).

**Without it the query returns 91 rows, and 84 of them come from the explanatory
documents** (measured). A guide carries the notation in bulk in order to explain it,
so nothing is broken. **With it you get 7 rows.**

**Read the language name one fence at a time.** When you cut the text on ` ``` `,
every odd-numbered piece is fence content, so its first line is the language name.
**Never decide by asking whether the whole node contains `mermaid`** - when a figure
and code share one node, that test drops the code.

**14. Count what sits side by side in a figure.** This form lines up every figure
for you to look at.

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

**The second column is the first line of the fence**, so a real figure names its
kind there - `flowchart LR`, `sequenceDiagram`, `stateDiagram-v2`. A row whose
second column holds a piece of jq is not a figure at all: an explanatory document
writes a fence marker and the language name inside the body of a query, and this
query picks each of those up. **Read the kind column and the fragments sort
themselves out.**

**This query cannot count a sequence diagram that declares neither `participant`
nor `actor`.** Mermaid raises a lifeline from the arrows alone; this query reads
strings out of the JSON and draws no such inference.

**14b. Print only the figures past the guideline. 0 rows is the normal result.** It
skips the figures you already moved out (documents whose UID starts with
`DOC-FIG-`), so **one returned row is an invitation to look, not a defect** - the
guideline is the writer's to overrule.

**Pass the UID prefix of the figure documents to `--arg figprefix`.** In this worked
example it is `DOC-FIG-`. **In the other project, pass their prefix. Do not rewrite
the body of the query.**

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

**15. Extract a whole figure definition.** You name the document by its UID.

````bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-FIG-STATE") | recurse(.NODES[]?) | (.STATEMENT? // "")
| select(contains("```mermaid")) | split("```")[] | select(startswith("mermaid")) | ltrimstr("mermaid")' <json>
````

`split("```")` cuts the text at every fence boundary, keeps only the pieces that
start with `mermaid`, and drops the leading 7 characters. **Change the language name
and the same shape pulls out code as well** (`startswith("python")`).

**Two traps wait for you when you write this output back. We measured both.**

**Trap 1 - a blank line appears at the top and at the bottom.**
`ltrimstr("mermaid")` drops only the 7 characters of `mermaid`, and the newline right
after them stays. The output of a 19-line figure comes to 21 lines. **Paste it back
as it is and one blank line piles up per round trip.** Example 14 drops blank lines
before it counts, so **the line count never tells you.** Drop the blank lines at both
ends before you paste. The version that drops them:

````bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-FIG-STATE") | recurse(.NODES[]?) | (.STATEMENT? // "")
| select(contains("```mermaid")) | split("```")[] | select(startswith("mermaid")) | ltrimstr("mermaid")
| split("\n") | map(rtrimstr("\r")) | map(select(. != "")) | join("\n")' <json>
````

**Trap 2 - `jq` on Windows prints CRLF line endings** (measured. The JSON itself
holds LF. StrictDoc normalizes to LF as it reads). **Pour that into a `.md` through a
redirect and you mix line endings.** Paste with an editing tool, and never write with
a shell redirect.

**16b. Extract a figure that sits in the body text.** Example 15 assumes a document
dedicated to a figure. When you take one out of a body document, point at the
position with `_TOC` (the second column of example 13 holds that number).
**When a document holds two or more figures, nothing else tells them apart.**

````bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-LOWER") | recurse(.NODES[]?) | select(._TOC? == "6.1")
| (.STATEMENT? // "") | split("```")[] | select(startswith("mermaid")) | ltrimstr("mermaid")
| split("\n") | map(rtrimstr("\r")) | map(select(. != "")) | join("\n")' <json>
````

**16. Track down which file defines a given UID.**
**The JSON carries no file path, so here alone you use `grep`.**

```bash
grep -rlF '**UID**: DOC-FIG-STATE' <specification folder> --include=*.md
```

**Include the `**UID**:` part in what you search for.** Search for the UID alone and
you also get the files that only reference it through `[LINK:]` (we measured 5 of
them). You need `-F` so that `grep` does not read `**` as a regular expression.

**Even so, you may get more than one file.** Run it in this folder and you get 4
files - only `_assets/fig-state.md` holds the real definition, and the remaining 2
come from this document and `queries.md`, **because they show this notation as
an example.** **An explanatory document contains the very strings it explains.** Tell
whether a returned file is a specification or a guide from the table at the top of
this document.

**17. Lines that hold the `$` trap (`traps.md`). 0 rows is the normal result.** Run this
every time you add a figure or a formula.

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

**The `reduce` part throws away the content of every code fence.** A `$` does no harm
inside a fence, so without that the query fills up with false positives. **It
remembers the length of the marker that opened the fence, and it closes only on a
marker of the same length or longer.** In a document like this one, where a ` ```` `
holds a ` ``` ` inside it, the simple approach of "cut on ``` and take the
even-numbered pieces" falls apart (we measured 4 false positives).

**★ 0 rows from this query does not prove you are safe.** It detects only **the trap
that fails the export** (a paragraph or a cell that ends with `$`). **The other trap
in `traps.md` - the one where `The cost runs from $100 to $200` turns into math - does not
fail the export, so this query never shows it.** Whenever you write an amount of
money or an environment variable, look at the HTML with your own eyes.

**18. Check that the attachments arrived (2.8). 0 rows is the normal result.**
**This one query catches both a missing target and a file you put outside `_assets/`.**

It judges every reference that `jq` lists by whether the file exists **on the
exported HTML side**. Run `--formats=html` first.

```bash
jq -r '.DOCUMENTS[] | select(.UID | IN("DOC-AI-GUIDE", "DOC-AI-QUERIES", "DOC-GUIDE", "DOC-REVIEW") | not)
| recurse(.NODES[]?) | (.STATEMENT? // "")
| split("](") | .[1:][] | split(")")[0]
| select(startswith("http") or startswith("#") | not)' <json> \
  | tr -d '\r' | sort -u \
  | while read -r p; do [ -f "<output dir>/html/<specification folder name>/$p" ] || echo "NOT PUBLISHED  $p"; done
```

```text
NOT PUBLISHED  _assets/missing.svg      ← the file does not exist
NOT PUBLISHED  attachments/other.svg    ← it exists, but outside _assets/
```

**Never leave out any of the three.**

- **`tr -d '\r'`** - `jq` on Windows prints CRLF line endings. Leave it out and a
  `\r` hangs off the end of every path, so **the check calls even a file that exists
  "missing"** (we hit this one; measured)
- **the `select` that excludes the explanatory documents** - an explanatory document
  carries **a description of the syntax**, such as `![alt](path)`, in its body text.
  Leave it out and `path` and `_assets/x.svg` come out as "missing" (measured)
- **looking at `<output dir>/html/...`** - looking at the **output** instead of the
  specification folder catches the other case at the same time: "we put it in the
  wrong place, so nothing copied it"

**To find the attachments nobody uses**, turn the direction around. It tells you what
you may delete. **This one does not exclude the explanatory documents** (a reference
from anywhere counts as "used"). **It does exclude `_assets/*.md`** - those are
documents, and `[LINK:]` points at them by UID, so they never show up as a path.

```bash
comm -13 <(jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | (.STATEMENT? // "") | split("](") | .[1:][] | split(")")[0]' <json> | tr -d '\r' | sort -u) \
         <(cd <specification folder> && find _assets -type f -not -name "*.md" | sort)
```

**19. Extract a whole table.** Point at the position with the UID for a requirement
and with `_TOC` for free text (the second column of example 13).

```bash
jq -r --arg doc DOC-LOWER --arg at 6.1 '.DOCUMENTS[] | select(.UID == $doc) | recurse(.NODES[]?)
| select((.UID? // ._TOC? // "") == $at) | (.STATEMENT? // "")
| split("\n")[] | select(startswith("|"))' <json>
```

```text
| Symbol | Unit | Meaning |
|---|---|---|
| $S_{need}$ bytes | bytes | Free space the conversion needs |
| $S_{out}$ bytes | bytes | Size of the output file |
| $S_{tmp}$ bytes | bytes | Size of the temporary file. It equals $S_{out}$ bytes |
| Path | - | The three stages `input \| convert \| output` |
```

**This table is a worked example that obeys every rule in 2.7.** The word "bytes"
follows the math, a `|` inside a cell is escaped as `\|`, and a pipe stands at both
ends of the row.

**Pass the position with `--arg`.** You never rewrite the body of the query, so you
reuse the same one everywhere. **This does not pick up a table that lacks a pipe at
both ends** (2.7).

**20. Find the tables that break (2.7.1). 0 rows is the normal result.** Run this
every time you add a table.

````bash
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | select(.STATEMENT?) as $n
| ($n.UID // $n._TOC // "-") as $at
| $n.STATEMENT | split("\n")
| reduce .[] as $line ({open: 0, want: 0, bad: []};
    ([$line | scan("^`{3,}")] | (.[0] // "") | length) as $w
    | if $w > 0
      then (if .open == 0 then .open = $w elif $w >= .open then .open = 0 else . end)
      elif .open > 0 then .
      elif ($line | startswith("|"))
      then ([$line | scan("[^\\\\][|]")] | length) as $c
           | if .want == 0 then .want = $c elif $c != .want then .bad += [$line] else . end
      else .want = 0
      end)
| .bad[] | $doc + "  " + $at + "  " + .' <json>
````

Point it at a deliberately broken document and it prints this:

```text
DOC-TBL  4.1  | code span | `a | b` |             ← a code span does not protect a |
DOC-TBL  4.1  | not escaped | a | b |             ← nobody escaped it
DOC-TBL  5.1  | too few | cells |                 ← a cell is missing
DOC-TBL  5.1  | too many | cells | here | oops |  ← "oops" disappears in the HTML
```

**It remembers how many separators the header row has, and it reports every row that
differs.** `scan("[^\\\\][|]")` does not count the ones escaped as `\|`, so a row you
escaped correctly never shows up. **This query alone uses a double backslash** - no
other way excludes an escaped `|`. **When it fails, write it into a `.jq` file and
pass it with `-f`** (constraint 2 below).

### Two constraints when you write a query

**1. Do not use a backslash in a regular expression.** `bash -c` halves a **double**
backslash such as `\\[`, and jq then fails with `Invalid escape` (measured). Write a
character class such as `[$]` or `[|]`, or use `split()` / `contains()`.
**A single backslash such as `split("\n")` survives** (measured). Only the double form halves.

**2. Put the query in a file when it has to get complicated.** Place it in a `.jq` file and
pass it with `-f`. The query never goes through the shell, so no backslash problem appears.

```bash
jq -r -f <query file>.jq <json>
```

### Exclude the explanatory documents when you aggregate

**A project sometimes mixes in a document that doubles as an explanation of the notation.**
Such a document carries figures, formulas, code and tables to explain them, so it always skews
an aggregate such as "how many figures does this set hold". **This worked example has six
explanatory documents** (`DOC-AI-GUIDE` = this guide, `DOC-AI-QUERIES`, `DOC-GUIDE`,
`DOC-REVIEW`, `DOC-BROWSER`, `DOC-COWORK`). **These six take up 113 of the 125 lines that
example 13 prints** (measured).

**A query finds those documents mechanically, as "a document that holds no node with a UID".**
That means a document that holds nothing but free text and chapters.

```bash
jq -r '.DOCUMENTS[] | select([recurse(.NODES[]?) | select(._NODE_TYPE != "DOCUMENT" and .UID?)] | length == 0) | (.UID // "-") + "  " + .TITLE' <json>
```

```text
DOC-AI-GUIDE  Markdown StrictDoc specifications - a guide for AI
DOC-AI-QUERIES  jq query collection - for AI
DOC-GUIDE  Read this first
DOC-ARCH  System structure
DOC-REVIEW  How we review
DOC-BROWSER  Driving StrictDoc from the browser
DOC-COWORK  Working alongside Claude
DOC-FIG-STATE  Large figure - conversion state machine
DOC-NOTE  Terminology map
```

**Do not filter on "a document that holds no requirement".** That also catches a document that
holds nothing but test cases or review findings (`DOC-TESTS` / `DOC-REVIEW`), because node types
other than the requirement carry a UID too.

Drop the UIDs you do not need from the result, then aggregate. **What you drop depends on your
goal** - keep the figure document when you want to count figures.

```bash
jq -r '.DOCUMENTS[] | select(.UID | IN("DOC-AI-GUIDE", "DOC-AI-QUERIES", "DOC-GUIDE", "DOC-REVIEW") | not) | .UID' <json>
```

**Add this `select` to examples 13 through 15 as well when you aggregate with them.**
You do not need it when you only use them to locate something.

---

## 3.1 Rewriting an existing specification

**No tool turns the JSON back into `.md` mechanically.** The JSON holds no file path, so you
open the `.md` and rewrite it there. The procedure is fixed.

**1. Locate the place you have to fix** - example 13 prints where it sits, and examples 15 / 16b
pull out its content.

**2. Locate the file** - the `grep` of example 16. **You open no `.md` up to this point.**

**3. Open that `.md` and rewrite it.** Watch out for the two traps of example 15 when you paste
the text back (the blank lines around it, and the CRLF that jq on Windows emits).

**4. Measure the line count again when you touch a figure** - example 14. **When it reaches 16
lines or more, follow 2.1, move it out into `_assets/fig-*.md`, and leave a `[LINK:]` in its
old place.**

**5. Fix the free text around a figure once you move that figure out of the body.** A sentence
such as "as the figure below shows" or "we put a small figure in the body" then points at
nothing. **No query detects this. Read it with your own eyes.**

**6. You do not have to touch `strictdoc_config.py` when you add a new `_assets/fig-*.md`**
(measured). `exclude_doc_paths` names each file explicitly, so a new file passes straight
through and becomes an ordinary document.

**7. Export again and check.** StrictDoc does not update the JSON on its own. **Run both json and
html, and confirm that example 14b (a rule violation), example 17 (the `$` trap) and example 11
(a broken link) all return zero rows.**

```bash
strictdoc export <specification folder> --formats=json --output-dir <output dir>
strictdoc export <specification folder> --formats=html --output-dir <output dir>
```

**In a project that has a `strictdoc_config.py`, the export creates a `__pycache__/` inside the
input folder** (measured). It is a side effect of loading the configuration. You may delete it.

---

Read `queries.md` only when the above does not cover your need. It sorts 32 queries by
purpose and shows the output of each one (about 6,800 tokens). It holds the table of contents,
a filter by chapter, transitive children, a filter by ROLE, the detection of an orphan
requirement, the detection of a duplicate UID, and more.

---

# The full query collection

## A. Get the big picture

### A1. The document list

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

**The query prints 9 entries.** `DOC-AI-GUIDE` and `DOC-AI-QUERIES` are guides for AI,
`DOC-GUIDE` is an explanatory document for humans, `DOC-NOTE` is the terminology table in
`_assets/note.md`, and `DOC-FIG-STATE` is the large figure in `_assets/fig-state.md`.
**None of these 5 holds a requirement.**
StrictDoc parses every `.md` file as a document no matter where the file sits.

### A2. Counts by node type

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | ._NODE_TYPE] | group_by(.) | map({(.[0]): length}) | add' <json>
```

```json
{"DOCUMENT":13,"REQUIREMENT":7,"SECTION":143,"TEST_CASE":4,"TEXT":144,"USE_CASE":1}
```

### A3. The table of contents

`_TOC` holds a hierarchical number such as `2.1.1`.

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="SECTION") | ._TOC + "  " + .TITLE' <json>
```

### A4. Field names available per type

**This query tells you the schema of an existing project from its JSON.** When you write a
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

`-c` makes jq print one line; the block above wraps it for reading. All five node types
show up. This worked example's grammar defines two of them, `REQUIREMENT` and
`TEST_CASE`; StrictDoc builds `DOCUMENT`, `SECTION` and `TEXT` from the structure of the
Markdown.

---

## B. Pin down a location

### B5. One node by UID

```bash
jq -c 'first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "SW-002")) | del(.NODES)' <json>
```

`first(...)` stops the search at the first hit. `del(.NODES)` lets you run the same
expression on a section node as well.

### B6. UIDs by regular expression

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

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | select(((.TITLE//"") + (.STATEMENT//"")) | contains("convert")) | .UID' <json>
```

To cover every field, flatten the node with `[.. | strings] | join(" ")` first and then
apply `contains`.

### B8. Search by regular expression

**`test()` takes flags as its second argument. `"i"` ignores case. It handles Japanese too.**

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

**You cannot filter by file name. The JSON holds no file path.** Use the document `UID`.

```bash
jq -r '.DOCUMENTS[] | select(.UID=="DOC-UPPER") | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | .UID + "  " + .TITLE' <json>
```

When you do not know a document's UID, look it up with A1.

### B10. Narrow to one chapter

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._TOC? and (._TOC | startswith("2."))) | ._TOC + "  " + (.TITLE // "")' <json>
```

`startswith("2.")` matches `2.1` and `2.2`, but it does not match the chapter itself (`2`).
To include the chapter itself, write `(._TOC=="2" or (._TOC|startswith("2.")))`.

---

## C. Follow relations

### C11. Direct parents

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID?=="TC-001") | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE' <json>
```

### C12. Parents up to the root (transitive)

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

**The JSON records no children.** Scan every node and collect the ones that name the node
you want as their parent.

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE=="SYS-001")) | .UID' <json>
```

### C14. Children down to the leaves (transitive)

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

In this worked example only the test cases use `Verifies`.

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

### D16. Requirements that no test case points to "directly"

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
**This is design, not a defect** - the software requirements underneath cover them.

### D17. Requirements with no parent

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | select(((.RELATIONS // []) | map(select(.TYPE=="Parent")) | length) == 0) | .UID' <json>
```

### D18. Requirements that nothing points to

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

### E21. Filter by STATUS

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT" and .STATUS=="Draft") | .UID' <json>
```

### E22. and / or / not

You can use the ordinary logical operators inside `select()`.

```bash
# and - requirements that reached review and carry a finding nobody has acted on
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS=="Open" and .STATUS=="Reviewed") | .UID' <json>

# or - test cases, or requirements we decided against changing
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE" or .REVIEW_STATUS=="WontFix") | .UID' <json>

# not - nodes that hold a UID and are not requirements
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? and (._NODE_TYPE=="REQUIREMENT" | not)) | ._NODE_TYPE + " " + .UID' <json>
```

**Put `not` at the end.** You cannot write `select(not(...))`.

### E23. Find nodes that lack a field

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT") | select(has("RATIONALE") | not) | .UID' <json>
```

**`has()` returns true even when the value is empty.** To exclude an empty string as well,
write `select((.RATIONALE // "") == "")`.

---

## F. Shape the output

### F24. Table form (the cheapest listing)

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

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")] | length' <json>
```

### F26. Only the fields you need, as JSON

```bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS? and .REVIEW_STATUS != "NoFinding")] | map({UID, REVIEW_STATUS})' <json>
```

**Do not add `-r`.** It flattens the output into strings.

---

## G. Handle figures, math, and code

**`STATEMENT` holds every figure, formula, and code block verbatim.** So `jq` can pull them
out, and you can count what sits inside them. The queries in this chapter build on that.

**The queries in this chapter follow two rules.**

- **They use no double backslash in a regular expression.** They use the character classes
  `[$]` and `[[]` in place of `\\$` and `\\[`, and they use `contains()` / `split()` even
  where a regular expression would do. G0 explains why
- **They wrap their code fences in four backticks.** The query body itself contains ` ``` `,
  so three backticks would close the fence halfway. StrictDoc reads a four-backtick fence
  correctly too (measured)

### G0. Why we avoid double backslashes

**When you hand a query to Git Bash as `bash -c "..."`, Git Bash cuts every double
backslash in half.** We measured this on strictdoc 0.27.1 / jq 1.8.1 / Windows 11.

| How you pass it | Result of `scan("!\\[...")` |
|---|---|
| `jq -f query.jq` | passes |
| You put it in a shell script and run `bash script.sh` | passes |
| **`bash -c 'jq -r ...'`** | **fails with `Invalid escape`** |

An AI usually runs its commands in the `bash -c` form. **So do not write a query that
contains a double backslash.** String operations give you the same result.

**A single backslash survives.** `split("\n")` passes in every form above (measured).
Git Bash halves only a doubled backslash, so you can use `\n` and `\t` normally.

**When a query has to get complicated, put it in a file.** It never passes through the
shell, so nothing breaks it.

```bash
jq -r -f <query file>.jq <json>
```

### G27. What lives where

**Run this one first.** It lists which node of which document holds a figure, a formula,
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

(15 representative rows out of 126. **Six explanatory documents take up 113 of them** -
this document, `00-ai-guide.md`, `02-guide-for-human.md`, `08-review.md`,
`09-browser-guide.md` and `10-cowork-with-claude.md`. A document that explains the
notation carries that notation in bulk, so pass `--arg skip` as example 13 does when you
count. The specification itself produces only 13 rows - `DOC-USECASES`, `DOC-UPPER`,
`DOC-ARCH`, `DOC-LOWER`, `DOC-TESTS`, `DOC-FIG-STATE` and `DOC-NOTE` - and the other
2 rows above are samples lifted out of an explanatory document)

The second column shows the `UID` when the node has one and the `_TOC` hierarchical number
when it does not. **Free text carries no UID**, so use `_TOC` to point at a position.

**★ Read the language name one fence at a time.** When you cut the text on ` ``` `, every
odd-numbered piece is fence content, so its first line is the language name. **Never decide
by asking whether the whole node contains `mermaid`.** When a figure and code share one
node, that test drops the code. `DOC-LOWER 6.1` has exactly that shape (a figure, math, and
code together), so **always try your own query of this kind on that line.**

### G28. Extract a figure definition

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
`mermaid`, and drops the leading `mermaid` (7 characters). **The JSON holds the fence
content verbatim**, so this hands you the whole Mermaid definition.

Change the language name and the same shape pulls out code as well (G31).

### G29. Count what sits side by side in a figure

**This project's guideline says: at 5 lifelines or more in a sequence diagram, or 5
classes or more in a class diagram, move the figure into `_assets/fig-*.md` as its own
document.** A flowchart carries no guideline. **The query passes no judgement** - it
reports the counts, and the writer decides where the figure goes. `audit.sh` used to
fail an oversized inline figure and no longer does; see 2.1 of `notation.md` for why.

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

**The kind of figure is the first line of the fence, printed as it stands.** A row whose
kind column holds a fragment of jq is not a figure: a document that explains the notation
writes the fence marker and the language name `mermaid` inside the body of a query, and
this query picks that up as a fragment of a figure.

**This query cannot count a sequence diagram that declares neither `participant` nor
`actor`.** Mermaid raises a lifeline from the arrows alone, but this query reads strings
out of the JSON and draws no such inference. Write `participant` in a figure you want
counted.

The next form prints only the figures past the guideline. **It skips a document whose UID
starts with `DOC-FIG-`, because you already moved that one out. 0 rows is the normal
result.**

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
`_assets/`. Run the same query against `md-sovd-automotive-en`, which does carry large
figures, and it returns three rows - 8 lifelines, 6 classes and 5 classes - all of them
already in `_assets/`.

### G30. Extract the math

```bash
jq -r '.DOCUMENTS[] | select(.UID == "DOC-LOWER") | recurse(.NODES[]?) | (.STATEMENT? // "")
| [scan("[$][$]([^$]+)[$][$]")] | .[][] | gsub("^\n|\n$"; "")' <json>
```

```text
S_{need} = S_{out} + S_{tmp} = 2 \times S_{out}
```

`[$][$]` is a character class that stands for `$$` (G0). `scan()` returns one array per
capture, so `.[][]` flattens them.

**Narrow to one document.** Run it across everything and it also picks up the `$$`
description in the notation guide inside `02-guide-for-human.md`, and then you cannot tell
which formula is real.

**Give up on extracting an inline `$...$` mechanically.** You cannot tell it apart from a
`$` that sits in free text (an amount of money or an environment variable), so the query
misfires. When you need an inline formula, find its place with G27 and then read that
node's whole `STATEMENT`.

### G31. Code by language

How many blocks each language holds:

````bash
jq -c '[.DOCUMENTS[] | recurse(.NODES[]?) | (.STATEMENT? // "") | scan("(?m)^```([a-z]+)")]
| flatten | group_by(.) | map({(.[0]): length}) | add' <json>
````

```json
{"bash":56,"json":5,"markdown":3,"mermaid":6,"python":4,"text":76}
```

**`mermaid` shows up here too.** A figure is a code fence as well.

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

**This shape misses a fence whose author wrote no language name.** So always write the
language name yourself.

### G32. Image targets

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

`path` comes straight from the `![alt](path)` syntax that the explanatory document
describes. **No such image exists.** A set that includes a document explaining the notation
mixes in apparent hits like this one.

The query stacks `split()` three times so that it can carve out `![...](...)` without a
backslash.

### G33. Find lines that hold the `$` trap

**When `$` stands as the last character of a paragraph or of a table cell, the HTML export
stops and prints `error: string index out of range` and nothing else.** It gives you no
file name and no line number.

**The JSON export, however, succeeds** (measured). So **export the JSON first and run this
query, and you find the place before you build the HTML.**

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

This sample returns 0 entries. **0 entries is the normal result.** Run it on a document we
broke on purpose and it prints this:

```text
DOC-LINT  CRASH  paragraph ending in math $T$
DOC-LINT  CRASH  bare trailing dollar 100 $
DOC-LINT  SAFE   escaped trailing dollar 100 \$
DOC-LINT  | CRASH cell ending in math | $T$ |
```

The `reduce` part **throws the fence content away.** A `$` does no harm inside a fence, so
keeping it would flood you with false detections.

**The query remembers how long the opening fence marker is and closes only on a marker of
the same length or longer.** A simpler way cuts on three `` ` `` and takes the
even-numbered pieces, but **that breaks on a document that puts ` ``` ` inside ` ```` `.**
This document and the skill have exactly that shape, so the simple version reports
4 false positives (measured).

**One kind of false detection remains** - the query also prints a line that escapes the
character as `\$` (the third line above). An escaped one is safe, so look at it and skip it.

### G34. Rewrite a figure and write it back to `.md`

**You cannot write back from JSON to `.md` mechanically.** The JSON holds no file path
(see the note at the top of this document). Follow these steps.

**1. Extract the figure** - G28.

**2. Find which file holds it.** Search for the UID declaration as a fixed string.
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

**3. Edit that `.md` directly.** Replace the fence content.

**4. Count what sits side by side again.** Once the figure passes the guideline, move it
out of the body into `_assets/fig-*.md` and leave a `[LINK:]` in its old place (G29).

**5. Export again.** StrictDoc does not update the JSON on its own.

```bash
strictdoc export <specification folder> --formats=json --output-dir <output dir>
```

**6. Confirm that the HTML passes too.** `--formats=json` lets the `$` trap through.
Whenever you touch a figure or a formula, run `--formats=html` as well.

```bash
strictdoc export <specification folder> --formats=html --output-dir <output dir>
```
