# Basics - system requirements

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

## Converting a file

**UID**: SYS-001 \
**STATUS**: Approved

**Statement**: The tool shall convert the input file the user specifies into the output format the user specifies.

**Rationale**: This requirement is the reason the tool exists. If we drop it, every other requirement loses its meaning.

## Rejecting unexpected input

**UID**: SYS-002 \
**STATUS**: Approved

**Statement**: The tool shall not perform the conversion when the input file does not match the format the user specifies.

## Protecting an existing file

**UID**: SYS-003 \
**STATUS**: Reviewed

**Statement**: The tool shall not overwrite a file at the destination that already carries the same name.

**Rationale**: If the tool destroys an existing file without warning, the user never notices the irreversible act. The tool keeps its default on the safe side.
