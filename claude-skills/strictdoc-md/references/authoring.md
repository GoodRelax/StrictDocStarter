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

**Grammar**: basic.sgra \
**UID**: DOC-UPPER \
**Version**: 1.0

Text directly under the H1 becomes free text. It has no UID, so it is not a requirement.

## Chapter name

Free text inside the chapter. Without `Type`, StrictDoc reads this paragraph as the body of a requirement.

## Requirement name

**UID**: SW-001 \
**STATUS**: Approved

**Statement**: The system shall ...

**Rationale**: The reason we decided that.

## Test case name

**Type**: TEST_CASE \
**UID**: TC-001

**Statement**: We run it under the ... condition.

**EXPECTED**: The result is ...

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-001` \
  **Role**: `Verifies`
```

StrictDoc does not need the `\` at the end of a line. Other Markdown viewers join
consecutive lines into a single line, and this character stops them.

### Rules that stop the whole export when you break them

| Rule | Error message you get |
|---|---|
| Start the file with an H1. Put exactly one of them in a file | `the document must start with an H1 heading` |
| **Do not skip a heading level.** Never put `###` right after `#` | `heading level forward jumps are not allowed: L1 -> L3` |
| Do not put two or more empty lines right after a heading | `two or more consecutive empty lines are not allowed` |
| Spell a field name exactly as the grammar declares it | `Invalid requirement field` |
| Do not create a field named `TYPE` in the grammar | StrictDoc uses that name to pick a node type, so you can no longer write the field from `.md` |
| Do not write a `Role` that the grammar does not declare | `Semantic error: Requirement relation type/role is not registered: Parent / Verifies` |
| **Declare `SECTION` when you write your own grammar** | `Semantic error: Invalid node type: SECTION.` |
| **Give `SECTION` a `PROPERTIES: IS_COMPOSITE: True`** | `The SECTION grammar element must be declared as composite.` (the Hint shows you the fix) |

**You do not have to declare `TEXT`. It is built in** (measured). We exported with a grammar
that declares only `SECTION` and `REQUIREMENT`, and the free text still became a `TEXT` node.
**Only `SECTION` needs a declaration.**

**StrictDoc prints an error on two lines. The first line carries the file name.**

```text
error: could not parse file: C:\...\04-lower.md.
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
  (`EXPECTED` passes, `Expected` stops). **When you cannot decide, write the name in all capitals**
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
  | `FINDING` | `Parent` + `Role: Reviews` |
- **Only inside a relation does the key become `**ID**:`.** A node's identifier is `**UID**:`, but
  the key that points at the other node inside a `**Relations**:` block is `**ID**:`. `**UID**:`
  does not pass there
- **`Type` is a reserved word that picks a node type in `.md`, not a field of the grammar.**
  That is why you can write `**Type**: TEST_CASE` and yet cannot create a field named `TYPE` in
  the grammar
- **Declare `FIELDS` in `.sgra` in this order** (it is not the order you write them in `.md`).
  `UID → STATUS → TITLE → your own single-line fields → STATEMENT →
  multi-line fields such as RATIONALE`. A json / html export still passes when you break the
  order, but converting to `.sdoc` with `--formats=sdoc` and reading it back stops with
  `Wrong field order`. **You cannot catch this later, so write them in this order from the start**
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
Below is the smallest template that you can use as it stands. We confirmed that the export passes with it.

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
  - TITLE: STATEMENT
    TYPE: String
    REQUIRED: True
  - TITLE: RATIONALE
    TYPE: String
    REQUIRED: False
  RELATIONS:
  - TYPE: Parent
  - TYPE: Child
- TAG: TEST_CASE
  FIELDS:
  - TITLE: UID
    TYPE: String
    REQUIRED: True
  - TITLE: TITLE
    TYPE: String
    REQUIRED: True
  - TITLE: STATEMENT
    TYPE: String
    REQUIRED: True
  - TITLE: EXPECTED
    TYPE: String
    REQUIRED: True
  RELATIONS:
  - TYPE: Parent
    ROLE: Verifies
```

How to read it:

| What you write | What it means |
|---|---|
| `- TAG: <name>` | Declares one node type. `**Type**: <name>` on the `.md` side points at it |
| `PROPERTIES: IS_COMPOSITE: True` | The node can hold other nodes inside it. **`SECTION` requires this** |
| `- TITLE: <name>` | Declares one field. `**<name>**:` on the `.md` side points at it |
| `TYPE: String` | Any string |
| `TYPE: SingleChoice(A, B, C)` | An enumeration. A value that this list omits stops the export |
| `REQUIRED: True` | Omitting the field stops the export |
| `RELATIONS: - TYPE: Parent` | You can now draw a `Parent` link in `**Relations**:` |
| `ROLE: <name>` | You can now write `**Role**:` on that relation. **Without it you cannot use `Role`** |

**Rules:**

- **`SECTION` needs a declaration. `TEXT` does not** (it is built in)
- **Match the names you give `TAG` and `TITLE` to the spelling on the `.md` side exactly.** Once you
  declare `EXPECTED`, write `**EXPECTED**:` in the `.md` too. `**Expected**:` stops the export
- **Never declare a field named `TYPE`.** It is the reserved word that picks a node type
- **The order in which you declare the fields constrains the `.md` side.** Declare them in the order
  `UID → STATUS → TITLE → your own single-line fields → STATEMENT →
  multi-line fields such as RATIONALE`. In any other order, reading the document back with
  `--formats=sdoc` stops with `Wrong field order`
- **Run `--formats=sdoc` to learn whether the order is right. If it finishes without a word, it is right**

```bash
strictdoc export <specification folder> --formats=sdoc --output-dir <output dir>
```

**The export passes without a `strictdoc_config.py`.** Put one directly in this folder only when
you need `exclude_doc_paths` or a screen setting (do not put it in the parent folder; StrictDoc does not read it there).

**★ Restart the server after you edit `strictdoc_config.py`** (measured).
**StrictDoc reads this file exactly once, at startup.** When you edit a document's `.md`, the
server picks the change up in under a second, but **it never picks up the project settings again.**

| What you edited | Restart the server |
|---|---|
| A `.md` document | Not needed. The server applies it automatically |
| A `.sgra` grammar | Not needed |
| **`strictdoc_config.py`** | **Needed** |

**This symptom hides itself well.** You fixed the setting, the screen still shows the old state,
so you conclude that you got the setting wrong. **The server also keeps writing HTML from the old
settings, so the output folder stays stale too.** When in doubt, stop the server and run
`strictdoc export` once by hand to check.

---
