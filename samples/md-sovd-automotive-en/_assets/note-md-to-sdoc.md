# Note - what we measured moving this specification from `.sdoc` to `.md`

**UID**: DOC-SOVD-NOTE-MD2SDOC

This is not part of the specification. It records **the constraints we actually
measured while moving this set from its `.sdoc` original to `.md`.** The same
constraints bite anyone trying the other direction.

**This file is itself the worked example of an external Markdown document.**
StrictDoc parses every `.md` under `_assets/` as a document of its own, so a
`**UID**:` right below the heading is all it takes to make it the target of a
`[LINK:]`. **`.md` has no way to pull a fragment in** - there is no counterpart
to `.sdoc`'s `[DOCUMENT_FROM_FILE]` - so material that leaves the body is joined
back by a link.

Measured on strictdoc 0.27.1, Python 3.13, Windows 11.

## 1. StrictDoc does the conversion itself

**Type**: SECTION

`--formats=markdown` converts `.sdoc` to `.md`; `--formats=sdoc` goes the other
way. The node structure - documents, chapters, requirements, relations, custom
fields - travels intact.

```bash
strictdoc export <specification folder> --formats=markdown --output-dir <output dir>
```

**Only the body notation stays behind.** The body of an `.sdoc` parses as RST by
default, so every RST directive arrives verbatim. This set rewrote five of them.

| RST                                       | Markdown                                   |
| ----------------------------------------- | ------------------------------------------ |
| `.. raw:: html` + `<pre class="mermaid">` | a ` ```mermaid ` fence                     |
| `.. math::` / `` :math:`x` ``             | `$$ ... $$` / `$x$`                        |
| `.. image:: path`                         | the Markdown image notation                |
| `.. list-table::`                         | a pipe table                               |
| `.. code-block:: <language>`              | a ` ``` ` fence carrying the language name |

## 2. The grammar has to declare `TITLE` early

**Type**: SECTION

**In `.md` the title comes from the heading, so StrictDoc inserts `TITLE` itself.**
The position is fixed: **after the built-in meta fields (`MID` / `UID` / `LEVEL` /
`STATUS` / `TAGS`) and before every custom field.** So **the grammar has to declare
its `FIELDS` in that same order.** This set carries no meta field other than `UID`,
so `TITLE` ends up right after it. The original `sovd-grammar.sgra` declared it
after `LAYER`, and the converted `.md` stopped like this.

```text
Semantic error: Wrong field order for requirement: [UID, TITLE, TYPE, ASIL, LAYER, STATEMENT, VERIFICATION].
Hint: Problematic field: TITLE. Compare with the document grammar: [UID, TYPE, ASIL, CAL, LAYER, TITLE, STATEMENT, RATIONALE, VERIFICATION] for type: REQUIREMENT.
```

There are two ways out: move `TITLE` up in the grammar, or give up on `.md`. This
set took the first and moved `TITLE` right after `UID` on `REQUIREMENT` and
`API`. The `.sdoc` original needs the same reordering, or it stops instead.

**Break the order and json, html and sdoc all stop on the spot** (measured).
"json passes but sdoc fails" does not happen.

## 3. `TYPE` is a usable field name. `LEVEL` is not

**Type**: SECTION

**`TYPE` works.** The `.md` reader reserves the spelling `Type` alone; it
compares `field_.name == "Type"` **exactly, case-sensitively**
(`backend/markdown/reader.py`). Write `**TYPE**:` in capitals and it passes
through as an ordinary field, on a node that may also carry
`**Type**: COMPONENT`.

**`LEVEL` does not.** It collides with StrictDoc's built-in `Level`, the
table-of-contents level. **The damage is silent: the export succeeds and the
`_TOC` number is overwritten with the field's value.**

```text
{"_TOC":"Unit", "_NODE_TYPE":"REQUIREMENT", "UID":"R-001", "LEVEL":"Unit", "TITLE":"..."}
                        ^ this should be a hierarchical number such as "1"
```

This set renames the test level to **`TEST_LEVEL`** and avoids the collision.
`COMMENT` and `PRIORITY` did not collide even though they are also built-in
words (measured). **Of the eight case-insensitive built-ins** - `Statement`,
`Title`, `Status`, `Rationale`, `Comment`, `Level`, `Tags`, `Prefix` - **only
`Level` did damage.**

## 4. The `.md` to `.sdoc` round trip does not come back on its own

**Type**: SECTION

`--formats=sdoc` writes every document out, but **reading that output back stops
for two reasons, and neither has anything to do with the declaration order**
(measured).

1. **The `.sgra` does not travel with it.** The generated `.sdoc` names the
   grammar file, and nothing copies it into the output folder. Copy it yourself
2. **A document that quotes `[LINK: UID]` as an example turns the quotation into
   a live link.** In `.md` the text stays inert; in the generated `.sdoc`
   StrictDoc tries to resolve it and stops

```text
error: DocumentIndex: the inline link references an object with an UID that does not exist: UID.
```

**A real link such as `[LINK: DOC-FIG-ARCH-CONTEXT]` survives the conversion.**
Removing that one quotation and copying the grammar in got the read-back to
pass.

**This set carries no guide to the notation**, which keeps the same knowledge
from existing in four places - and **as a side effect it avoids this trap too**,
because no `[LINK: UID]` is quoted anywhere in it.

## 5. Keep the `.md` as the master when you need the round trip

**Type**: SECTION

Both problems above are fixable by hand, so **a one-way conversion is
practical.** If you need the round trip, though, **keep the `.md` as the master
and treat the `.sdoc` as something you write out**. The other way round makes you
patch those two points every single time.
