# Writing a Markdown StrictDoc specification

Loaded by the `strictdoc-md` skill. Read this when you create or change a
`.md` document, or when you need a `.sgra` grammar file.

Everything here was measured on strictdoc 0.27.1.

---

## 1. Writing a specification

Below is a template that we confirmed strictdoc 0.27.1 parses. **This template creates
five kinds of node: `DOCUMENT` / `TEXT` / `SECTION` / `REQUIREMENT` / a custom node type.**

```markdown
# Document title

**Grammar**: basic.sgra
**UID**: DOC-UPPER
**Version**: 1.0

Text directly under the H1 becomes free text. It has no UID, so it is not a requirement.

## Chapter name

**Type**: SECTION

Free text inside the chapter. Without `Type`, StrictDoc reads this paragraph as the body of a requirement.

## Requirement name

**UID**: SW-001
**STATUS**: Approved
**REVIEW_STATUS**: NoFinding

**Statement**: The system shall ...

**Rationale**: The reason we decided that.

**Relations**:

- **Type**: `Parent`
  **ID**: `SYS-001`

## Test case name

**Type**: TEST_CASE
**UID**: TC-001
**TEST_RESULT**: NotRun

**GIVEN**: ... is in the ... state.

**WHEN**: ... runs ...

**THEN**: ... has become ...

**Relations**:

- **Type**: `Parent`
  **ID**: `SW-001`
  **Role**: `Verifies`
```

**Never end a field line with `\`.** StrictDoc does not need it. It buys you nothing
and it carries the only failure mode this notation has: left behind on the last line
of a block, it stops the export, and every field you delete risks leaving one behind.
(This is about the fields of a node. A `\` at the end of a line inside a `bash` fence
is a shell line continuation and has nothing to do with StrictDoc - the commands in
`queries.md` use it, and removing one breaks the command.)

**Two trailing spaces are not a substitute.** StrictDoc keeps trailing whitespace
inside the value of a field (measured on 0.27.1). `**Grammar**: basic.sgra  ` dies
with `imports a grammar from a file that does not exist`, and a choice field dies
with `invalid SingleChoice value`. A field the grammar does not validate simply
swallows the spaces, and nothing tells you.

**Put `**Relations**` behind the body fields and leave one blank line after it.**
A Markdown formatter inserts that blank line by itself, so a file written without
it changes the first time anyone opens it and saves. Written with `**Relations**`
glued to the metadata block, that same save separates the field name from its list
and the export stops with `duplicate field names in a valid requirement node are
not allowed` - pointing at the head of the node, never mentioning the blank line.

**Check with a copy, never with the original.** `strictdoc export` passing says
nothing about this: the shape that breaks exports cleanly as written and only dies
after a formatter has run once. Copy the folder, format the copy, export it again,
and compare the nodes and relations on both sides. `tools/check-format-fixpoint.py`
in StrictDocStarter does exactly that.

### Rules that stop the whole export when you break them

| Rule                                                                    | Error message you get                                                                                                                                 |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Start the file with an H1. Put exactly one of them in a file            | `the document must start with an H1 heading`                                                                                                          |
| **Do not skip a heading level.** Never put `###` right after `#`        | `heading level forward jumps are not allowed: L1 -> L3`                                                                                               |
| Do not put two or more empty lines right after a heading                | `two or more consecutive empty lines are not allowed`                                                                                                 |
| Spell a field name exactly as the grammar declares it                   | `Invalid requirement field`                                                                                                                           |
| Write a field named `TYPE` as `**TYPE**:`, in capitals                  | `**Type**:` is taken as the node-type selector before anything else                                                                                   |
| Do not write a `Role` that the grammar does not declare                 | `Semantic error: Requirement relation type/role is not registered: Parent / Verifies`                                                                 |
| **Declare `SECTION` when you write your own grammar**                   | `Semantic error: Invalid node type: SECTION.`                                                                                                         |
| **Give `SECTION` a `PROPERTIES: IS_COMPOSITE: True`**                   | `The SECTION grammar element must be declared as composite.` (the Hint shows you the fix)                                                             |
| **Put `**Relations**` behind the body fields, one blank line after it** | `duplicate field names in a valid requirement node are not allowed` - but only once a formatter has run, so an export that passes proves nothing here |
| **Save every file as UTF-8. A byte order mark is allowed**              | `'utf-8' codec can't decode byte 0x82 in position 2: invalid start byte` - and it names no file                                                       |
| **Never write a horizontal rule (`---`) anywhere in a document**        | `duplicate field names in a valid requirement node are not allowed`                                                                                   |
| **Name a parent that exists somewhere in the project**                  | `Requirement SW-001 references parent requirement which doesn't exist: SYS-999.`                                                                      |

### The message you got, and what causes it

The table above is the list to follow while writing. This one is for afterwards, when the
export has already stopped: **it is keyed by the message rather than by the rule**, because the
message is what you are holding at that moment.

`duplicate field names in a valid requirement node are not allowed` has **three unrelated
causes**, and the line number it prints points at the head of the node rather than at any of
them.

| The message                                                                   | What actually caused it                                                                                                                                                                                                                                                                                                                                                      |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `duplicate field names in a valid requirement node are not allowed`           | (a) `**Relations**` glued to the metadata block, with a formatter since separating the field name from its list. (b) A horizontal rule (`---`) anywhere in the document - measured in both places it can go, inside a node and straight after a chapter heading, and both give this message. (c) A body field that lost the blank line separating it from the metadata block |
| `'utf-8' codec can't decode byte 0x.. in position ..: invalid start byte`     | A file is not UTF-8, and **the message names no file**. Find it by decoding each source as UTF-8 yourself                                                                                                                                                                                                                                                                    |
| `Requirement <UID> references parent requirement which doesn't exist: <UID>.` | A relation names a `**UID**` no node declares. A parent may live in another file, but it has to exist somewhere                                                                                                                                                                                                                                                              |
| `Relations list must not be empty.`                                           | `**Relations**:` with nothing under it, usually because a formatter pushed a blank line between the field name and its list                                                                                                                                                                                                                                                  |
| `Relations must directly follow requirement metadata without an empty line.`  | `**Relations**` after the metadata block in a node with no body field behind which to sit. Give the node one: put a blank line before its last one-line field                                                                                                                                                                                                                |
| `Node is missing a field that is required by grammar: <NAME>.`                | The grammar declares a field the node lacks. The `Hint` lists every declared field, so one edit converges                                                                                                                                                                                                                                                                    |
| `Wrong field order for requirement`                                           | The fields are not in the grammar's declared order. One-line fields go under the heading, paragraph fields after, both in declared order                                                                                                                                                                                                                                     |
| `A process in the process pool was terminated abruptly...`                    | Not the real error. Re-run with `--no-parallelization`                                                                                                                                                                                                                                                                                                                       |

### How the file itself has to be saved

**UTF-8, and nothing else.** StrictDoc opens every source with `utf-8-sig`, so a byte order
mark is read and discarded, but there is no fallback. One file in another encoding stops the
export for the whole project, and the message names no file.

**Save `.md` with LF.** This does not stop an export, which is exactly why it is easy to miss.
StrictDoc reads `.md` without translating newlines, so a CRLF file carries a carriage return
into every field value read out of it, and on into the JSON export where every query has to
strip it again. Measured on 0.27.1: the same 13 files put 4265 carriage returns into 152
`STATEMENT` fields as CRLF and none as LF. That is why the queries in `queries.md` are full of
`rtrimstr("\r")`.

**`.sdoc` and `.sgra` do not have this problem** (measured). They go through a reader that
translates newlines and carried no carriage return through even when every one was CRLF.

**You do not have to declare `TEXT`. It is built in** (measured). We exported with a grammar
that declares only `SECTION` and `REQUIREMENT`, and the free text still became a `TEXT` node.
**Only `SECTION` needs a declaration.**

**StrictDoc prints an error on two lines. The first line carries the file name.**

```text
error: could not parse file: C:\...\06-lower.md.
Semantic error: Invalid node type: SECTION.
```

**Exactly one exception exists: an error that names neither the cause nor the file.**

```text
error: A process in the process pool was terminated abruptly while the future was running or pending.
```

**★ When you see this error, run the export again with `--no-parallelization`. StrictDoc then
prints the real error** (measured).

```bash
strictdoc export <specification folder> --formats=json --output-dir <output dir> --no-parallelization
```

```text
error: could not parse file: C:\...\00-ai-guide.md.
Semantic error: Markdown parsing error: heading level forward jumps are not allowed: L1 -> L3.
Location: C:\...\00-ai-guide.md:54:1
```

**It prints the file name and the line number.** Only when it runs in parallel does StrictDoc
fail to carry the real error out of the child process and swallow it (a defect in strictdoc
0.27.1: it fails to construct the exception class). **`--debug` only prints a stack trace and
never prints the location. `--no-parallelization` gets you there faster.**

**Only two errors hide their location from you: this one and the `string index out of range` in `traps.md`.**
For every other error, the first line tells you where it is.

### Rules that a worked example does not show you

- **StrictDoc treats a sentence placed directly under a heading as an implicit `Statement`.** The
  heading then becomes a requirement node. Write `**Type**: SECTION` on every chapter that is not
  a requirement. Without it StrictDoc stops and blames the missing `UID`. **Only the text directly
  under the H1 is an exception**; it always becomes free text
- **Case of a field name**: only these eight words ignore case: `Statement` `Title` `Status`
  `Rationale` `Comment` `Level` `Tags` `Prefix`. Spell every other field as the grammar declares it
  (`GIVEN` passes, `Given` stops). **When you cannot decide, write the name in all capitals**
- **Write the link on the lower side.** Put `**Relations**:` on the lower node and point it at the
  parent's UID. Write nothing on the upper side. The parent may live in another file (StrictDoc
  resolves a UID across the whole project)
- **You may write a `Role` only when the grammar declares a `ROLE` on that node type's relation.**
  `basic.sgra` declares the following. **Never put a `Role` on a software requirement** -
  copying the test case pattern verbatim stops the export
  | Node type | Relations you may write |
  |---|---|
  | `REQUIREMENT` | `Parent` / `Child`. **You cannot add a `Role`** |
  | `TEST_CASE` | `Parent` + `Role: Verifies` |
- **Only inside a relation does the key become `**ID**:`.** A node's identifier is `**UID**:`, but
  the key that points at the other node inside a `**Relations**:` block is `**ID**:`. `**UID**:`
  does not pass there
- **`Type` is the reserved word that picks a node type in `.md`.** What is reserved is
  **the spelling `Type` alone** - the reader compares `field_.name == "Type"` exactly
  (`backend/markdown/reader.py`, 0.27.1). **So you may declare a grammar field named `TYPE`**:
  write it as `**TYPE**:` in capitals and it passes through as an ordinary field, even on a node
  that also carries `**Type**: COMPONENT` (measured). It is a single-line custom field, so
  **declare it after `TITLE`**
- **Declare `FIELDS` in `.sgra` in this order** (it is not the order you write them in `.md`).
  `MID / UID / LEVEL / STATUS / TAGS (the built-in meta fields) → TITLE →
your own single-line fields → STATEMENT →
multi-line fields such as RATIONALE`. **Break the order and json, html and sdoc all stop on the
  spot** (measured): `Semantic error: Wrong field order for requirement: [...]`, and the `Hint:`
  line names the offending field and prints the order the grammar declares
- **Only five fields written directly under the document's H1 survive into the JSON:
  `**Grammar**:` `**UID**:` `**Version**:` `**Classification**:` `**Prefix**:`**
  (measured). `**Date**:` and `**Root**:` **do not stop the export, but they disappear from the
  JSON.** No machine can query them afterward, so never put information you want to query later
  at the document level
- **StrictDoc parses every `.md` in the folder as a document, wherever it sits.** `_assets/` is no
  exception, so an `.md` you put there needs an H1 as well
- **List an `.md` you do not want StrictDoc to parse by file name under `exclude_doc_paths` in
  `strictdoc_config.py`.** Never list a whole folder such as `_assets/**`. If you do, StrictDoc
  stops copying the images too, and the export reports success while every image in the HTML
  returns 404
- **Chapter 2 collects how to write figures, math, code, tables and images.** They hold many
  traps, so read it before you write any of them
- **Add a node type, a field or a `Role` to the `.sgra`.**
  Never add one to an individual document

**The minimum layout for a new project** (measured):

```text
<project folder>/
  <name>.sgra       ← put it in the same folder as the documents. **Grammar**: <name>.sgra points here
  00-upper.md
  01-lower.md
```

**You may name the grammar file anything you like** (measured; it does not have to be
`basic.sgra`). Only the extension has to be `.sgra`.
**StrictDoc reads the `.sgra` too and logs `Reading SDOC:` for it, but it never becomes a document.**

### 1.1 Writing a grammar file (`.sgra`)

**When you start a new project, you always end up writing your own `.sgra`.**
Below is the smallest template that you can use as it stands. **It pairs with the `.md` template
above.** We pasted both as they stand and ran `--formats=json` and `--formats=html`; both passed
(measured).

**★ Always use the two templates as a pair.** Leave one field the `.md` template writes out of the
`.sgra` and StrictDoc stops the export - `Semantic error: Invalid requirement field: <name>`, with
a `Hint:` line listing the fields the grammar does declare.

**`REVIEW_STATUS` / `REVIEW_COMMENT` / `REVIEW_ACTION` are a convention, not StrictDoc.** They put
the review result on the requirement itself, which is what `audit.sh`'s `review comment missing`
check reads. Drop all three from both templates if the project tracks findings some other way.

```text
[GRAMMAR]
ELEMENTS:
- TAG: SECTION
  PROPERTIES:
    IS_COMPOSITE: True
  FIELDS:
  - TITLE: TITLE
    TYPE: String
    REQUIRED: True
- TAG: REQUIREMENT
  FIELDS:
  - TITLE: UID
    TYPE: String
    REQUIRED: True
  - TITLE: STATUS
    TYPE: SingleChoice(Draft, Reviewed, Approved)
    REQUIRED: False
  - TITLE: TITLE
    TYPE: String
    REQUIRED: True
  - TITLE: REVIEW_STATUS
    TYPE: SingleChoice(NotReviewed, NoFinding, Open, Fixed, WontFix)
    REQUIRED: True
  - TITLE: STATEMENT
    TYPE: String
    REQUIRED: True
  - TITLE: RATIONALE
    TYPE: String
    REQUIRED: False
  - TITLE: REVIEW_COMMENT
    TYPE: String
    REQUIRED: False
  - TITLE: REVIEW_ACTION
    TYPE: String
    REQUIRED: False
  RELATIONS:
  - TYPE: Parent
  - TYPE: Child
- TAG: USE_CASE
  FIELDS:
  - TITLE: UID
    TYPE: String
    REQUIRED: True
  - TITLE: TITLE
    TYPE: String
    REQUIRED: True
  - TITLE: UC_LEVEL
    TYPE: SingleChoice(Summary, UserGoal, Subfunction)
    REQUIRED: True
  - TITLE: REVIEW_STATUS
    TYPE: SingleChoice(NotReviewed, NoFinding, Open, Fixed, WontFix)
    REQUIRED: True
  - TITLE: STATEMENT
    TYPE: String
    REQUIRED: True
  - TITLE: REVIEW_COMMENT
    TYPE: String
    REQUIRED: False
  - TITLE: REVIEW_ACTION
    TYPE: String
    REQUIRED: False
  RELATIONS:
  - TYPE: Parent
- TAG: TEST_CASE
  FIELDS:
  - TITLE: UID
    TYPE: String
    REQUIRED: True
  - TITLE: TITLE
    TYPE: String
    REQUIRED: True
  - TITLE: TEST_RESULT
    TYPE: SingleChoice(NotRun, Passed, Failed, Blocked)
    REQUIRED: True
  - TITLE: ISSUE_KEY
    TYPE: String
    REQUIRED: False
  - TITLE: GIVEN
    TYPE: String
    REQUIRED: True
  - TITLE: WHEN
    TYPE: String
    REQUIRED: True
  - TITLE: THEN
    TYPE: String
    REQUIRED: True
  - TITLE: TEST_REMARK
    TYPE: String
    REQUIRED: False
  RELATIONS:
  - TYPE: Parent
    ROLE: Verifies
```

How to read it:

| What you write                   | What it means                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------------ |
| `- TAG: <name>`                  | Declares one node type. `**Type**: <name>` on the `.md` side points at it            |
| `PROPERTIES: IS_COMPOSITE: True` | The node can hold other nodes inside it. **`SECTION` requires this**                 |
| `- TITLE: <name>`                | Declares one field. `**<name>**:` on the `.md` side points at it                     |
| `TYPE: String`                   | Any string                                                                           |
| `TYPE: SingleChoice(A, B, C)`    | An enumeration. A value that this list omits stops the export                        |
| `REQUIRED: True`                 | Omitting the field stops the export                                                  |
| `RELATIONS: - TYPE: Parent`      | You can now draw a `Parent` link in `**Relations**:`                                 |
| `ROLE: <name>`                   | You can now write `**Role**:` on that relation. **Without it you cannot use `Role`** |

**Rules:**

- **`SECTION` needs a declaration. `TEXT` does not** (it is built in)
- **Match the names you give `TAG` and `TITLE` to the spelling on the `.md` side exactly.** Once you
  declare `GIVEN`, write `**GIVEN**:` in the `.md` too. `**Given**:` stops the export
- **You may declare a field named `TYPE`.** Only the spelling `Type` is reserved.
  Write it as `**TYPE**:` in the `.md`, and declare it after `TITLE`
- **The order in which you declare the fields constrains the `.md` side.** Declare them in the order
  `MID / UID / LEVEL / STATUS / TAGS (the built-in meta fields) → TITLE →
your own single-line fields → STATEMENT →
multi-line fields such as RATIONALE`. **In any other order json, html and sdoc all stop on the
  spot** (measured): `Semantic error: Wrong field order for requirement: [...]`, and the `Hint:`
  line names the offending field and prints the order the grammar declares
- **`--formats=json` already tells you whether the order is right.** "json passes but sdoc fails"
  does not happen

```bash
strictdoc export <specification folder> --formats=json --output-dir <output dir>
```

**`--formats=sdoc` is no use as a round-trip check** (measured). The generated `.sdoc` names the
`.sgra` but nothing copies that file into the output, and a document that quotes `[LINK: UID]` as
an example turns the quotation into a live link, so reading the result back stops with
`the inline link references an object with an UID that does not exist: UID`.

**The export passes without a `strictdoc_config.py`.** Put one directly in this folder only when
you need `exclude_doc_paths` or a screen setting (do not put it in the parent folder; StrictDoc does not read it there).

**★ Restart the server after you edit `strictdoc_config.py`** (measured).
**StrictDoc reads this file exactly once, at startup.** When you edit a document's `.md`, the
server picks the change up in under a second, but **it never picks up the project settings again.**

| What you edited           | Restart the server                              |
| ------------------------- | ----------------------------------------------- |
| A `.md` document          | Not needed. The server applies it automatically |
| A `.sgra` grammar         | Not needed                                      |
| **`strictdoc_config.py`** | **Needed**                                      |

**This symptom hides itself well.** You fixed the setting, the screen still shows the old state,
so you conclude that you got the setting wrong. **The server also keeps writing HTML from the old
settings, so the output folder stays stale too.** When in doubt, stop the server and run
`strictdoc export` once by hand to check.

---
