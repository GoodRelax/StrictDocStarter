# Terminology map

**UID**: DOC-NOTE

This file sits inside `_assets/`, but **StrictDoc treats it as one document.**
The "links" section of `02-guide-for-human.md` reaches this page with `[LINK: DOC-NOTE]`.

A file needs only one thing to become the target of a link: it declares
`**UID**:` right below its heading. You do not write the output path.
StrictDoc resolves it from the UID.

| What this sample calls it | What StrictDoc calls it | What it actually is |
| --- | --- | --- |
| system requirement | REQUIREMENT | `SYS-*` in `04-upper.md` |
| software requirement | REQUIREMENT | `SW-*` in `06-lower.md` |
| test case | TEST_CASE | `TC-*` in `07-tests.md` |
| review result | a field of REQUIREMENT | `REVIEW_STATUS` / `REVIEW_COMMENT` / `REVIEW_ACTION` |
| free text | TEXT | a paragraph that carries no UID |
| chapter | SECTION | a heading that declares `**Type**: SECTION` |

**StrictDoc parses every `.md` in the project as a document, wherever it sits.**
That is why this file must also start with a `#` heading. One `.md` without a
heading stops the whole export.
