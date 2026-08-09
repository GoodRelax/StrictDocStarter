# Test cases

**Grammar**: basic.sgra \
**UID**: DOC-TESTS \
**Version**: 1.0

A test case is not a standard StrictDoc concept. We added a node type named
`TEST_CASE` ourselves in `basic.sgra`. Because we added it, we could take the
three Gherkin words `GIVEN`, `WHEN` and `THEN` straight into it as fields.
The heading doubles as the scenario name, so this grammar carries no `SCENARIO`
field.

To use a grammar type from `.md`, you write the name of the type in `Type` directly under the heading.

```text
## Scenario name

**Type**: TEST_CASE \
**UID**: TC-001 \
**TEST_RESULT**: Passed

**GIVEN**: <something> sits in <some state>.

**WHEN**: <someone> does <something>.

**THEN**: <something> happens.
```

**Four traps specific to `.md` wait for you here.**

1. The only spelling StrictDoc reserves for the type itself is `Type`. You may
   declare a grammar field named `TYPE` and write it as `**TYPE**:` in capitals
   (measured). It becomes the node-type selector only when you spell it `**Type**:`.
2. Write the key of a custom field in the uppercase the grammar declares.
   `GIVEN` passes but `Given` fails. The eight built-in words such as
   `Statement` and `Title` ignore case, on the other hand. You can only memorize
   this asymmetry.
3. Order the fields the way the grammar declares them. Once the two orders
   differ, StrictDoc stops with `Wrong field order for requirement`. Put the
   fields that fit on one line in the block directly under the heading, and put
   the fields that become paragraphs after that block. Both sides follow the
   declared order.
4. `TEST_CASE` in this grammar carries no `STATEMENT`, so you cannot write free
   text inside one. StrictDoc reads free text in `.md` as `Statement`, so free
   text inside a `TEST_CASE` stops the export with
   `Semantic error: Invalid requirement field: STATEMENT` (measured on 0.27.1).
   Write the explanation in `TEST_REMARK` instead.

**`TEST_RESULT` is required, and it takes one of `NotRun`, `Passed`, `Failed` and
`Blocked`.** `ISSUE_KEY` and `TEST_REMARK` are optional, so you write them only on
the scenarios that need them.

The relation type stays `Parent`, and `Role` changes what it means. Here we
attached `Verifies`. You must declare a `Role` in the grammar before you use it.

These four test cases cover the four software requirements of `06-lower.md` one
for one. The traceability matrix screen in the left toolbar shows you at a
glance whether the coverage holds.

The same four also verify `UC-001` in `03-usecases.md`. Each `GIVEN` / `WHEN` /
`THEN` is written at the acceptance height - "the user runs the tool" - so the
four line up one for one with the four threads of the use case.

## What Gherkin is

**Type**: SECTION

Gherkin is a language for writing down behaviour split three ways. It spread
as the format that Cucumber, a test automation tool, reads. The official
reference defines the three words like this.

| Word | What you write |
| --- | --- |
| `Given` | The precondition. The state the system sits in before anything happens |
| `When` | The event. The operation a person or another system performs |
| `Then` | The expected outcome. What ought to happen |

The reason for the split is that nobody can verify a sentence that mixes
precondition, operation and outcome. Write "handing it a broken file makes it
exit with an error" as one sentence, and a reader cannot tell what to prepare in
order to try it. Split it three ways and what to prepare, what to press and what
to look at each become decided.

**A StrictDoc field cannot repeat.** Gherkin's `And` and `But` cannot become
fields of their own, so you write the extra lines inside `GIVEN`.

```text
**GIVEN**: An input file the tool can convert exists.
No file of the same name sits at the destination.
```

This set uses the three words `Given`, `When` and `Then` and nothing else.
Gherkin also has `Feature`, `Rule`, `Scenario Outline`, `Examples` and
`Background`. We take none of them, because StrictDoc's own document structure
fills the same role: `Feature` maps to a document and a chapter, `Scenario` to a
heading.

### Sources

**Type**: SECTION

- The official Gherkin reference - <https://cucumber.io/docs/gherkin/reference/>
  It lists the keywords and defines `Given`, `When` and `Then` one by one.
  The description of the three words above follows the definitions on that page.

## The conversion succeeds

**Type**: TEST_CASE \
**UID**: TC-001 \
**TEST_RESULT**: Passed

**GIVEN**: The user prepares one input file in the format they specified, and no file of the same name sits at the destination.

**WHEN**: The user runs the tool.

**THEN**: The tool exits normally and creates an output file in the format the user specified.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-001` \
  **Role**: `Verifies`
- **Type**: `Parent` \
  **ID**: `UC-001` \
  **Role**: `Verifies`

## An unexpected format is rejected

**Type**: TEST_CASE \
**UID**: TC-002 \
**TEST_RESULT**: Failed \
**ISSUE_KEY**: PROJ-142

**GIVEN**: The user prepares one input file that does not match the format they specified.

**WHEN**: The user runs the tool.

**THEN**: The tool exits with an error and creates no output file.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-002` \
  **Role**: `Verifies`
- **Type**: `Parent` \
  **ID**: `UC-001` \
  **Role**: `Verifies`

## An existing file is not overwritten

**Type**: TEST_CASE \
**UID**: TC-003 \
**TEST_RESULT**: NotRun

**GIVEN**: The user puts a file at the destination under the same name as the output file the tool creates.

**WHEN**: The user runs the tool.

**THEN**: The tool exits with an error and the contents of the existing file stay unchanged.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-003` \
  **Role**: `Verifies`
- **Type**: `Parent` \
  **ID**: `UC-001` \
  **Role**: `Verifies`

## An interruption leaves no partial file

**Type**: TEST_CASE \
**UID**: TC-004 \
**TEST_RESULT**: Blocked \
**ISSUE_KEY**: PROJ-207

**GIVEN**: The tool is partway through writing the output file.

**WHEN**: The user kills the tool's process.

**THEN**: The tool leaves no incomplete file at the destination.

**TEST_REMARK**: The verification team has no procedure yet for stopping the process partway through the write. The team holds this scenario until that procedure exists.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-004` \
  **Role**: `Verifies`
- **Type**: `Parent` \
  **ID**: `UC-001` \
  **Role**: `Verifies`
