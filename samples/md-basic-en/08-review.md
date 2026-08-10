# How we review

**Grammar**: basic.sgra
**UID**: DOC-REVIEW
**Version**: 1.0

This document tells you where a review result goes and how you write it.

This set writes a finding on the requirement itself. You can also raise a
finding as a node of its own and tie it to the requirement with a relation, but we
do not. "Why we do not use a separate node" gives the reason.

We added these three fields to the requirement. **`basic.sgra` declares them on
`REQUIREMENT` alone, so a test case carries none of them.**

| Field | What it holds | Who writes it |
| --- | --- | --- |
| `REVIEW_STATUS` | The state of the review. Required | The reviewer and the author |
| `REVIEW_COMMENT` | The finding itself. What is wrong | The reviewer |
| `REVIEW_ACTION` | What the author did about it, or why they will not | The author |

## The five states

**Type**: SECTION

```text
- TITLE: REVIEW_STATUS
  TYPE: SingleChoice(NotReviewed, NoFinding, Open, Fixed, WontFix)
  REQUIRED: True
```

| Value | Meaning | `REVIEW_COMMENT` | `REVIEW_ACTION` |
| --- | --- | --- | --- |
| `NotReviewed` | Nobody has looked at it yet | empty | empty |
| `NoFinding` | Somebody looked. No finding | empty | empty |
| `Open` | A finding, still open | needed | empty |
| `Fixed` | The author acted on the finding | needed | needed |
| `WontFix` | The author considered it and decided against acting | needed | needed (give the reason) |

We set `REQUIRED: True`. Forget the field and `strictdoc export` stops, so no
requirement ever reaches the reader without a review field. That is why
`NotReviewed` is an explicit value - once a missing field carries meaning, you
can no longer tell it apart from a field somebody forgot.

`WontFix` closes a finding just as legitimately as `Fixed` does. Take the
finding, think it through, decide against changing anything, and then **leave the
reason in `REVIEW_ACTION`.** With the reason on record, the same finding six
months later costs you no second argument.

**We avoid the word `Rejected`** because it reads as though we threw the finding
itself out. We picked a word that shows a decision taken after receiving it.

## How you write it

**Type**: SECTION

`REVIEW_STATUS` goes below `STATUS`, inside the block of metadata. The two
prose fields take the same shape as `Statement` and `Rationale` - paragraphs at
the end of the node.

```text
## Rejecting unexpected input

**UID**: SYS-002
**STATUS**: Approved
**REVIEW_STATUS**: Fixed

**Statement**: IF the input file does not match the format the user specifies, THEN the tool shall not perform the conversion.

**REVIEW_COMMENT**: Nobody had decided what happens when the tool is handed a corrupt file.

**REVIEW_ACTION**: We added a failed read to the checks SW-002 performs.
```

**Never change the order of the fields you write as paragraphs.** Once the order
`basic.sgra` declares and the order you wrote in `.md` disagree, the export stops
like this. A single-line field inside the metadata block does survive being
reordered - StrictDoc quietly sorts it back into the declared order (measured).

```text
Semantic error: Wrong field order for requirement: [UID, STATUS, TITLE, REVIEW_STATUS, ...]
```

**Spell the key the way the grammar does.** `**Review_comment**:` fails with
`Invalid requirement field`. Only these eight words ignore case:
`Statement`, `Title`, `Status`, `Rationale`, `Comment`, `Level`, `Tags`, `Prefix`.

## Why we do not use a separate node

**Type**: SECTION

You can raise a finding as a type of your own, such as `FINDING`, and tie it to
the requirement with `Role: Reviews`. This set used to do exactly that. One
reason made us stop.

**The state does not show in a list of requirements.** Tie the finding on as a
relation and all the requirement shows is that a finding exists. Whether
somebody has acted on it stays hidden until you open the finding. That is
precisely what a review wants to know.

Put it in a field of the requirement and it shows in all three views - Document,
Table and Traceability (measured). The Table view in particular lets you pick
and reorder the columns, so "list the `Open` ones" finishes on the spot.

We gave something up as well.

| | Field of the requirement (this set) | Separate node + relation |
| --- | --- | --- |
| The state shows in a list of requirements | yes | no |
| Several findings on one requirement | no, one only | yes |
| A UID and a history per finding | no | yes |
| Appears in the project-wide matrix | no | yes |
| Effort to write | three added lines | raise a node in another document |

Once you have to stack findings and track them one by one, the separate node
suits you better. Add the type to `basic.sgra` then. `02-guide-for-human.md`
shows you how.

## Counting what has piled up

**Type**: SECTION

Querying the JSON beats counting on screen. List every open finding.

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS == "Open")
| .UID + "  " + .TITLE + "  " + (.REVIEW_COMMENT // "-")' <json>
```

This gives you the count per state.

```bash
jq -r '[.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS?) | .REVIEW_STATUS]
| group_by(.) | map({(.[0]): length}) | add' <json>
```

To list the requirements nobody has looked at yet, pick `NotReviewed`.

```bash
jq -r '.DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS == "NotReviewed")
| .UID + "  " + .TITLE' <json>
```

**A requirement that claims a finding but never says what it is** is what
`audit.sh` finds. The check is called `review comment missing`. It fires on
`REVIEW_COMMENT` left empty while the state is one of `Open`, `Fixed` and
`WontFix`.

## Where this set stands

**Type**: SECTION

The seven requirements of `04-upper.md` and `06-lower.md` show all five states
between them.

| UID | `REVIEW_STATUS` | What it illustrates |
| --- | --- | --- |
| `SYS-001` | `NoFinding` | Somebody looked and found nothing |
| `SYS-002` | `Fixed` | A finding, acted on |
| `SYS-003` | `Open` | A finding, still open |
| `SW-001` | `NoFinding` | |
| `SW-002` | `NoFinding` | |
| `SW-003` | `NotReviewed` | Nobody has looked yet |
| `SW-004` | `WontFix` | Considered, and decided against acting |

A test case carries no `REVIEW_STATUS`. `basic.sgra` declares the three fields
on `REQUIREMENT` alone. A test case carries `TEST_RESULT`, `ISSUE_KEY` and
`TEST_REMARK` instead - `07-tests.md` shows you how to write them. Once you want
to review the wording of the tests as well, add the same three fields to
`TEST_CASE`. **What you edit is the grammar file, not the individual document.**
