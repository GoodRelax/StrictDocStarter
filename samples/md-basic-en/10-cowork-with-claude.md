# Working alongside Claude

**Grammar**: basic.sgra \
**UID**: DOC-COWORK \
**Version**: 1.0

This document tells you how to use the `strictdoc-md` skill bundled with this set to
make Claude Code write a specification, query it and review it.

A skill is a folder that collects the guidance you hand to an AI. Claude Code reads
only the description at startup and loads the body once the work at hand matches it.
So you never have to explain "here is how StrictDoc works" all over again.

The skill holds the rules and the worked examples of `00-ai-guide.md` and
`01-ai-queries.md`, split in two. Read those two documents yourself; hand the skill to
an AI.

## Installing the skill

**Type**: SECTION

Asking Claude Code is quickest. Say this and it handles everything from the copy to
choosing where the folder goes.

```text
Set up claude-skills/strictdoc-md so I can use it in my environment
```

If you would rather do it yourself, read the appendix. It carries the rule for where the
folder goes and the one command that puts it there.

You can tell whether it landed by typing `/strictdoc-md` and seeing whether the name
resolves. Once it does, the skill reaches for itself whenever the work matches.

The skill holds this.

| File | What it carries |
| --- | --- |
| `SKILL.md` | The rules, the preconditions, the four traps. Claude Code reads this one first |
| `references/authoring.md` | The shape of `.md`, the rules that stop the export, the `.sgra` template |
| `references/notation.md` | How to write figures, math, code, tables and attachments |
| `references/traps.md` | What breaks silently. How to keep the quirk log |
| `references/queries.md` | The jq query collection, with the output each one produced |
| `scripts/audit.sh` | The six checks StrictDoc does not report |

It needs two things on `PATH`: `strictdoc` and `jq`. Without either, the skill can do
nothing.

## Reading - never let the AI open the `.md` files

**Type**: SECTION

This is the one point that pays for itself the most.

Read the specification as `.md` and this set alone costs more than 55,000 tokens.
Export it to JSON and pull only what you need with `jq`, and the same answer costs
under 100.

```text
strictdoc export <specification folder> --formats=json --output-dir <output dir>
```

The skill knows this procedure and builds the query that fits what you asked. On your
side, just ask in plain English.

- "List the requirements in this specification"
- "Which requirements does no test cover?"
- "Follow the parents of `SW-002` up to the root"
- "Are any relations broken?"

You open a `.md` only when you are rewriting what is inside. The JSON carries no file
path, so nothing can write it mechanically back into `.md`.

## Writing

**Type**: SECTION

Starting from scratch and adding to an existing specification work the same way. The
skill carries the `.sgra` template as well, so it can start from the grammar.

Three things are worth settling before you ask. Throw the work over without them and the
AI decides for you, and you end up fixing it afterwards.

1. How UIDs are formed - the prefix such as `SYS-`, `SW-`, `TC-`, and how many digits
2. How the files divide - by system / software / test / review, or by feature
3. The grammar - whether you use `TEST_CASE` and fields of your own, or stay inside the
   defaults

This is as far as the default grammar carries you (measured).

| Available out of the box | Needs a `.sgra` |
| --- | --- |
| `UID` / `Statement` / `Rationale` / `STATUS` | `Role` (a meaning such as `Verifies`) |
| `**Type**: SECTION` | A type of your own such as `TEST_CASE` |
| The `Parent` relation | A field of your own |

**Always run the export after the AI writes.** A `.md` that does not export is not a
specification.

```text
strictdoc export <specification folder> --formats=json --output-dir <output dir>
strictdoc export <specification folder> --formats=html --output-dir <output dir>
```

**The JSON can pass while the HTML fails.** A paragraph that ends in `$` stops the HTML
alone with `string index out of range`. So run both.

When the export stops without telling you where, **add `--no-parallelization` and run it
again.** The process pool died and hid the real error; run it again and the line
appears. It is faster than `--debug`.

## Reviewing

**Type**: SECTION

### What StrictDoc stops on its own

**Type**: SECTION

You never need to look for these two, because the export fails on them.

- A duplicate UID
- A relation that names a UID which does not exist

Both stop the export whether they sit inside one document or across two.

### What StrictDoc does not report

**Type**: SECTION

This is what the skill's `audit.sh` covers. It runs six checks.

```text
sh claude-skills/strictdoc-md/scripts/audit.sh <specification> <output dir> <UIDs to skip>
```

| Check | What it finds |
| --- | --- |
| `trailing dollar` | A paragraph or a cell ends in `$`. The HTML export stops |
| `broken table row` | A row of a table is broken |
| `attachment not published` | A referenced file never reached the output. An attachment left outside `_assets/` |
| `oversized inline figure` | A figure embedded in the body is too large. It inflates what you hand an AI |
| `review comment missing` | A finding with nothing in it. `REVIEW_STATUS` is `Open` / `Fixed` / `WontFix` but there is no `REVIEW_COMMENT` |
| `wording candidates` | EARS shape, word order, passive voice, missing subject, negative form. These are candidates rather than violations, and a human and an AI decide |

The third argument reaches only the checks that aggregate. `attachment not published`
ignores it and reads every document - it drops fenced blocks and inline code first, so a
document that carries `![alt](path)` to explain the syntax produces no false hit anyway
(every one of the 29 references in this set checked, 0 rows. Measured). For this set you
pass this.

```text
DOC-AI-GUIDE,DOC-AI-QUERIES,DOC-GUIDE,DOC-REVIEW,DOC-BROWSER,DOC-COWORK
```

### Reviewing the content

**Type**: SECTION

For what no check finds, just ask.

- "List the requirements no test covers"
- "Do the software requirements below `SYS-002` cover it?"
- "Is this requirement written so that it can be verified?"

**Zero rows from the audit does not mean it passed.** Make a copy, break it on purpose,
and confirm that the check really fires. That procedure found one real bug in the audit
script (it raised on a document with no UID and swallowed the exception).

## Worked examples - five ways to ask

**Type**: SECTION

What follows is five requests we actually made. Each one records three things: what the
AI does behind the scenes, what the human decides, and what to confirm afterwards. A
list of prompts on its own leaves you unable to judge whether the answer that came back
is right.

You call them all the same way. Put the name of the skill first and carry on in plain
English.

| Example | What the AI uses behind the scenes | What the human decides |
| --- | --- | --- |
| 1. Import from another format | Another skill plus `.sgra` plus the export checks | How much counts as one requirement |
| 2. List the unsuitable requirements | `wording candidates` in `audit.sh` | Which candidates are real mistakes |
| 3. List the parents and children | JSON plus a `jq` walk over the relations | How many levels to follow |
| 4. Write a test specification | JSON plus `TEST_CASE` from the `.sgra` | How many "as many as needed" is |
| 5. List what the review has not finished | JSON plus `REVIEW_STATUS` in `jq` | Which states count as finished |

In the queries below, `<json>` means `<output dir>/json/index.json`.

### Import from another format

**Type**: SECTION

```text
/strictdoc-md Import the requirements in XXX.pptx into a StrictDoc specification in .md form
```

This one does not finish inside a single skill. Reading a `.pptx` is not the job of
`strictdoc-md`, which handles only the `.md` side. Opening the slides and pulling the
text out belongs to Claude Code's own reading, or to another skill that handles `pptx`.
Ask for it knowing that it combines two skills.

`strictdoc-md` takes on three parts.

1. The shape to land in - the order of `**UID**:`, `**STATUS**:` and `**Statement**:`,
   and how the chapters are built
2. The `.sgra` - the grammar you need once fields of your own such as `TEST_CASE` or
   `REVIEW_STATUS` come in
3. The check after the import - run the export in both formats

**What the human decides.** On top of the three from the previous chapter (how UIDs are
formed, how the files divide, the grammar), the human decides which box on a slide
counts as one requirement. An AI cannot decide whether the words inside a diagram are a
requirement or a note. Sometimes one slide is one requirement; sometimes one bullet is.

**What to confirm afterwards.** That the export passes in both formats, and that the
number imported matches the number you started with. Count them like this.

```text
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")] | length' <json>
```

### List the unsuitable requirements

**Type**: SECTION

```text
/strictdoc-md Pull out the requirements that do not follow EARS, that use the passive voice unintentionally, or that take an object but carry none, and propose a fix for each
```

**What the AI does behind the scenes.** It exports to JSON and runs `wording candidates`
from `audit.sh`. That check raises candidates under five verdicts.

| Verdict | What it finds |
| --- | --- |
| `ears-shape` | The sentence carries no `shall` |
| `ears-order` | The sentence opens with something other than `WHEN` / `WHILE` / `IF` / `WHERE`, yet one of them appears later |
| `passive` | A form of "be" plus a past participle |
| `no-subject` | Nothing - an English sentence states its subject |
| `negative` | `shall not` / `must not` / `never` |

All a machine can decide is whether the string is present.

- A machine cannot tell an intended passive from an accidental one.
- A machine cannot find a requirement that takes an object and carries none. Nothing in
  the text records whether a given verb takes one.

So the machine narrows the candidates and the AI judges the intent. That division is the
point of this example. The AI reads the candidates the machine raised one at a time and
turns only the ones worth fixing into a proposal.

```text
sh claude-skills/strictdoc-md/scripts/audit.sh <specification> <output dir> <UIDs to skip>
```

Run it on this set and one of the six checks fires, with three candidates (measured).

```text
  ok    trailing dollar              0
  ok    broken table row             0
  ok    attachment not published     0
  ok    oversized inline figure      0
  ok    review comment missing       0
  FAIL  wording candidates           3
          DOC-UPPER  SYS-002  negative
          DOC-UPPER  SYS-003  negative
          DOC-LOWER  SW-004  negative

1 check(s) found something
```

None of the three is a mistake. The EARS unwanted-behaviour pattern is written with
"shall not", so `negative` firing is exactly what you expect. The machine raises it
because it does not know the pattern. The human and the AI are the ones who do. Reading
the candidates and deciding "leave all three" is one full turn of this request.

**What the human decides.** Which candidates to fix. An `ears-order` candidate appears
on a sentence that puts the subject before the condition, such as "The tool shall ...
when ...". EARS puts the condition first, so bringing it into line means rewriting it as
"WHEN ..., the tool shall ...". The requirements in this set already use the second
order, so `ears-order` currently raises nothing. Which of the two you take is undecidable
until you have decided who reads it.

**What to confirm afterwards.** Run `audit.sh` again after the fix and see that the drop
in the count matches the number you fixed. Then run the export in both formats.

### List the parents and children

**Type**: SECTION

```text
/strictdoc-md List the parent requirements and the child requirements tied to SW-004
```

**What the AI does behind the scenes.** It exports to JSON and walks the relations with
`jq`. A relation is written in one direction only, from child to parent. So the parents
fall out of the node's own `RELATIONS`, while the children need a walk over every
requirement collecting the ones that name it. The directions differ, so one query prints
both.

```text
jq -r --arg uid SW-004 '
[ .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT" and .UID?) ] as $r
| ( [ $r[] | select(.UID==$uid) | .RELATIONS[]? | select(.TYPE=="Parent" and (.ROLE|not)) | .VALUE ] ) as $up
| ( [ $r[] | select( [.RELATIONS[]? | select(.TYPE=="Parent" and (.ROLE|not)) | .VALUE] | index($uid) ) | .UID ] ) as $down
| ( [ $r[] | select(.UID | IN($up[])) | .UID + "  " + .TITLE ] ) as $upl
| ( [ $r[] | select(.UID | IN($down[])) | .UID + "  " + .TITLE ] ) as $downl
| "upper (" + ($upl|length|tostring) + ")", ($upl[] | "  " + .),
  "lower (" + ($downl|length|tostring) + ")", ($downl[] | "  " + .)' <json>
```

The output looks like this (measured).

```text
upper (1)
  SYS-003  Protecting an existing file
lower (0)
```

Run the same query on `SYS-003` and the directions swap (measured).

```text
upper (0)
lower (2)
  SW-003  Checking the destination
  SW-004  Atomic writing
```

A test case carries the `Verifies` role, so this query does not count it as a child. The
single `select(.ROLE|not)` drops it. Take that condition out to include the tests.

**What the human decides.** How many levels to follow. The query above prints only the
one level that connects directly. The query that follows the chain to the root lives in
the skill's `references/queries.md`. The human also decides how to read a zero. Whether
`SW-004` has no children because the decomposition finished or because someone forgot to
write them is not something a machine can settle.

**What to confirm afterwards.** The counts. The export stops on a relation that names a
UID which does not exist, so once the export passes, every destination that came back is
real. The remaining danger sits on the side that forgot to draw a relation at all.

### Write a test specification

**Type**: SECTION

```text
/strictdoc-md Write a test specification for SW-003, split into as many items as it needs
```

**What the AI does behind the scenes.** It pulls the `STATEMENT` of the target
requirement out of the JSON, counts the conditions, and adds them to the `.md` in the
`TEST_CASE` shape the `.sgra` declares. The test cases in this set carry eight fields,
three of them from Gherkin.

| Field | What you write |
| --- | --- |
| `UID` | The identifier of the test case. Required |
| `TITLE` | The name of the scenario |
| `GIVEN` | The precondition |
| `WHEN` | The operation |
| `THEN` | The expected outcome |
| `TEST_RESULT` | The result of running it |
| `ISSUE_KEY` | The number of the issue ticket |
| `TEST_REMARK` | A note |

You tie it to the requirement with a `Parent` relation carrying the `Verifies` role. The
real thing sits in `07-tests.md`.

**Forget the type line and StrictDoc reads the chapter as a requirement.** Write
`**Type**: TEST_CASE` at the top of the chapter. Forget it and the export stops with
`Invalid requirement field: TEST_RESULT`. The field name in the message tells you which
chapter lost its type.

**What the human decides.** How many "as many as it needs" is. It is not one test per
requirement. For `SW-003` the minimum is the two cases "a file of that name exists" and
"it does not", and whether you add write permission or case sensitivity on top depends on
what you are trying to protect. An AI can count the conditions in the requirement
sentence and offer candidates, but it cannot decide where to stop.

**What to confirm afterwards.** Run the export in both formats. Then count again the
requirements that no test covers.

```text
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="TEST_CASE") | (.RELATIONS // [])[] | select(.TYPE=="Parent") | .VALUE] as $tested
| .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.UID | IN($tested[]) | not) | .UID + "  " + .TITLE' <json>
```

### List what the review has not finished

**Type**: SECTION

```text
/strictdoc-md List the specifications the review has not finished (NotReviewed, Open)
```

**What the AI does behind the scenes.** It exports to JSON and narrows on
`REVIEW_STATUS` with `jq`. The `.sgra` of this set declares five values.

| Value | Meaning |
| --- | --- |
| `NotReviewed` | Nobody has looked at it yet |
| `NoFinding` | Someone looked and found nothing |
| `Open` | There is a finding and nobody has fixed it |
| `Fixed` | There was a finding and someone fixed it |
| `WontFix` | There was a finding and someone decided not to fix it |

```text
jq -r '.DOCUMENTS[] | (.UID // .TITLE) as $doc
| recurse(.NODES[]?)
| select(.REVIEW_STATUS? and (.REVIEW_STATUS | IN("NotReviewed","Open")))
| [$doc, .UID, .REVIEW_STATUS, .TITLE] | @tsv' <json>
```

The output holds three rows (measured).

```text
DOC-USECASES	UC-001	Open	Convert an input file into the requested format
DOC-UPPER	SYS-003	Open	Protecting an existing file
DOC-LOWER	SW-003	NotReviewed	Checking the destination
```

A use case carries `REVIEW_STATUS` too, so this query picks it up alongside the
requirements. Add `select(._NODE_TYPE == "REQUIREMENT")` to see requirements alone.

**What the human decides.** What "not finished" covers. `WontFix` is the finish of
deciding not to fix, and `Fixed` is the finish of having fixed. Whether you count those
two as finished changes the number that comes back. The query above counts both as
finished.

**What to confirm afterwards.** Look at `review comment missing` in `audit.sh`. That
check raises a node whose `REVIEW_STATUS` is `Open` / `Fixed` / `WontFix` while its
`REVIEW_COMMENT` is empty. A list that comes back with nothing inside it is not a review.

## The division - how much to hand over

**Type**: SECTION

| Work | Whose | Why |
| --- | --- | --- |
| Listing, aggregating, searching | AI | JSON and `jq` make it fast and cheap |
| Finding gaps (no test, a broken relation) | AI | It follows mechanically |
| Fixing the notation (tables, figures, attachments) | AI | The rules are written down |
| Crossing versions, rewriting in bulk | AI | A human misses cases |
| Deciding what to build | Human | You cannot hand over the content of a specification |
| Deciding how fine a requirement is | Human | The right answer only follows from context |
| Confirming that it passed | Human | Never take an AI's "done" on trust |

When you split a large job across several AIs, split it by file and **never let two of
them touch the same file.** Freeze the conventions that cross files first and hand them
to everyone. We measured this while translating this set - not one of the names we froze
first came out inconsistent, and only the wording we forgot to freeze split four ways.

## When the version changes

**Type**: SECTION

The skill was measured on strictdoc 0.27.1, jq 1.8.1 and Git Bash on Windows 11.
`SKILL.md` carries a canary in chapter 6 - it tells you what to measure again when the
version differs.

**When you hit an error this document does not carry, never chase the cause on the
spot.** Add one line to `strictdoc-quirks.tsv` and move on. Read the file back when a
version goes up or when the lines pile up, and use it as material for fixing the guide.
It holds 17 lines today.

Driving StrictDoc from the browser is in `09-browser-guide.md`.

## Appendix - installing it by hand

**Type**: SECTION

The skill sits in `claude-skills/strictdoc-md/`. Copy the whole folder wherever you want
to use it.

```text
cp -r claude-skills/strictdoc-md ~/.claude/skills/
```

There are two places it can go.

| Where | What it reaches |
| --- | --- |
| `~/.claude/skills/` | Every project of that user |
| `<project>/.claude/skills/` | That project alone |

Claude Code picks it up the next time you start a session. Drop it in while one is open
and that session will not see it.

`claude-skills/` is the copy for publication; what Claude Code reads is
`.claude/skills/`. We keep the two in sync by hand, so **fix one alone and they will
drift apart.**
