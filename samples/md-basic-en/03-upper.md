# System requirements

**Grammar**: basic.sgra \
**UID**: DOC-UPPER \
**Version**: 1.0

This document states **what we build** and nothing else. It leaves how we build it to `04-lower.md`.

This paragraph is free text, not a requirement, so it carries no UID. **StrictDoc
reads a paragraph that sits under a heading as the statement of a requirement.**
The text directly under the document H1 is the one exception - StrictDoc treats that
text as free text. When you write free text inside a chapter, state `**Type**: SECTION` explicitly
(every chapter of `02-guide-for-human.md` does this).

Only one rule decides whether you attach a UID - **attach one when you want to look the node up by name later.**

## How we write a requirement - EARS

**Type**: SECTION

Every requirement in this document and in `04-lower.md` follows one of the five
**EARS** patterns. EARS narrows the shape of a requirement sentence down to five
forms. That narrowing stops you dropping the condition, and it stops you packing
two requirements into one sentence.

| Pattern | Shape |
|---|---|
| Ubiquitous | The `<system>` **shall** `<response>`. |
| Event-driven | **WHEN** `<trigger>`, the `<system>` **shall** `<response>`. |
| State-driven | **WHILE** `<state>`, the `<system>` **shall** `<response>`. |
| Unwanted behaviour | **IF** `<condition>`, **THEN** the `<system>` **shall** `<response>`. |
| Optional feature | **WHERE** `<feature>`, the `<system>` **shall** `<response>`. |

**One word at the head of the sentence tells you the pattern** - `WHEN`, `WHILE`,
`IF` or `WHERE`. Only the ubiquitous pattern opens with the subject, because that
pattern carries no condition at all.

**`shall` marks a requirement.** EARS keeps three words apart: `shall` states a
requirement, `will` states a fact about the world, and `should` states a
preference. **Every requirement in this set carries a `shall`**, and that is what
the `ears-shape` check of `audit.sh` looks for.

**Write the condition ahead of the subject.** This is the point of EARS. Once you
open with the subject and write "The tool shall reject the file when the format
differs", the reader carries the subject all the way to the condition and never
notices a condition you left out. Put the condition first and **the head of the
sentence already tells the reader when the requirement applies.**

**This set deliberately keeps no EARS field on the requirement.** The pattern
shows in the `**Statement**:` sentence itself. Once you also name the pattern in a
field, a field and a sentence that disagree leave you with no way to decide which
one to believe. The `wording candidates` check of `audit.sh` reads the shape of
the sentence instead (`ears-shape` and `ears-order`).

You may leave the `negative` rows alone, though. The unwanted-behaviour pattern
says "shall not", and that is the correct way to write it.

`samples/md-basic-ja` writes the same seven requirements in Japanese and lists the
Japanese rendering of each pattern.

### The complex pattern - stacking conditions

**Type**: SECTION

**A sixth pattern stacks the five above.** The EARS source calls it the
**complex** pattern. You reach for it once a requirement carries two conditions or
more.

```text
WHERE <feature>, WHILE <state>, WHEN <trigger>, the <system> shall <response>.
```

**The stacking order is fixed.** You go outside in - **`WHERE` → `WHILE` → `WHEN`
(or `IF`)**. The source writes the complex template as
`While <precondition(s)>, When <trigger>, the <system name> shall <system response>`,
so **the state comes first and the trigger second.** To stack unwanted behaviour,
you write `If ... Then ...` in place of `When`.

| What you stack | What it means |
| --- | --- |
| `WHERE` | **It applies only to a product that carries the feature.** This is about product configuration |
| `WHILE` | **It applies for as long as the state lasts.** It has a duration |
| `WHEN` | **It applies at that instant.** It has no duration |
| `IF ... THEN` | It applies to unwanted input or an unwanted situation |

**★ Stack two conditions at most.** Nobody can enumerate the combinations behind a
sentence that stacks three. **A requirement that needs three is telling you it is
really two requirements.**

This set carries no complex example. The subject is simple enough that no
requirement needed a second condition. **Reach for the pattern only once you need
it** - stacking has no value of its own.

### Sources

**Type**: SECTION

**One source defines EARS.** Read it whenever you are unsure.

- **The official EARS page** - <https://alistairmavin.com/ears/>
  Written by Alistair Mavin, who devised the approach. It carries the template
  and an example for each of the six patterns. **The wording of this chapter
  follows the templates on that page.**
- EARS first appeared in a 2009 paper. Mavin, Wilkinson, Harwood, Novak,
  "Easy Approach to Requirements Syntax (EARS)",
  17th IEEE International Requirements Engineering Conference (RE'09), pp. 317-322.

## Converting a file

**UID**: SYS-001 \
**STATUS**: Approved \
**REVIEW_STATUS**: NoFinding

**Statement**: The tool shall convert the input file the user specifies into the output format the user specifies.

**Rationale**: This requirement is the reason the tool exists. If we drop it, every other requirement loses its meaning.

## Rejecting unexpected input

**UID**: SYS-002 \
**STATUS**: Approved \
**REVIEW_STATUS**: Fixed

**Statement**: IF the input file does not match the format the user specifies, THEN the tool shall not perform the conversion.

**REVIEW_COMMENT**: SW-002, the software requirement below this one, wrote the condition for refusing a conversion as a procedure to "check", so a reader could not tell from the head of the sentence which input the tool refuses.

**REVIEW_ACTION**: We rewrote SW-002 so that it opens with the condition. The head of the sentence now names the input the tool refuses.

## Protecting an existing file

**UID**: SYS-003 \
**STATUS**: Reviewed \
**REVIEW_STATUS**: Open

**Statement**: IF a file of the same name already sits at the destination, THEN the tool shall not overwrite that file.

**Rationale**: If the tool destroys an existing file without warning, the user never notices the irreversible act. The tool keeps its default on the safe side.

**REVIEW_COMMENT**: The requirement says "shall not overwrite" and stops there. Nobody decided what the tool does instead once it finds a file of the same name - abort, or write under another name?
