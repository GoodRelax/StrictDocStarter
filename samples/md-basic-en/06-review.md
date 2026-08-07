# Basics - review findings

**Grammar**: basic.sgra \
**UID**: DOC-REVIEW \
**Version**: 1.0

**This document is the whole reason we ship `basic.sgra`.**

A review finding is not a standard StrictDoc concept either. If you force it into
the built-in requirement, you have nowhere to put a severity or a resolution. So we
added a node type named `FINDING` to `basic.sgra` and declared `SEVERITY` and
`RESOLUTION` as fields of its own.

**Fix the choices in the grammar.** Once you write
`SingleChoice(Major, Minor, Question)`, a misspelling raises a parse error on the
spot, and the editing screen in the browser turns the field into a dropdown of the
choices. Never leave the field open to free text.

We tie a finding to the requirement it reviews with the `Reviews` role. That lines
the finding up on the requirement's own screen as well, and a single query pulls it
out of the JSON.

## SW-002 does not say how to check the format

**Type**: FINDING \
**UID**: RV-001

**SEVERITY**: Major

**RESOLUTION**: Open

**Statement**: SW-002 does not write down how the tool decides that the format passes. Reading the extension and reading the contents lead to different implementations and to different steps in TC-002. We must pick one of the two.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-002` \
  **Role**: `Reviews`

## SYS-003 offers no way to allow overwriting

**Type**: FINDING \
**UID**: RV-002

**SEVERITY**: Question

**RESOLUTION**: Open

**Statement**: Keeping the default on the safe side is reasonable, but a user who wants to overwrite on purpose has no way out. We have not decided whether to add an explicit option.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SYS-003` \
  **Role**: `Reviews`
