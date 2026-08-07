# Terminology map

**UID**: DOC-NOTE

This file is a `.md`. It sits here as **the target that `.sdoc` documents link
to**. The "attachments" section of `01-guide-for-human.sdoc` reaches this page
with `[LINK: DOC-NOTE]`.

A file needs only one thing to become the target of a link: it declares
`**UID**:` right below its heading. You do not write the output path.
StrictDoc resolves it from the UID.

| What this sample calls it | What StrictDoc calls it | What it actually is |
| --- | --- | --- |
| system requirement | REQUIREMENT | `SYS-*` in `02-upper.sdoc` |
| software requirement | REQUIREMENT | `SW-*` in `03-lower.sdoc` |
| test case | TEST_CASE | `TC-*` in `04-tests.sdoc` |
| review finding | FINDING | `RV-*` in `05-review.sdoc` |
| free text | TEXT | a paragraph that carries no UID |
| chapter | SECTION | the nested `[[SECTION]]` blocks in `01-guide-for-human.sdoc` |

**StrictDoc parses every `.md` in the project as a document, wherever it sits.**
`_assets/` is no exception. That is why this file must start with a `#` heading.
One `.md` without a heading stops the whole export.
