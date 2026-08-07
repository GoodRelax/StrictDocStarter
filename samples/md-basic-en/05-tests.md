# Basics - test cases

**Grammar**: basic.sgra \
**UID**: DOC-TESTS \
**Version**: 1.0

A test case is **not a standard StrictDoc concept.** We added a node type named
`TEST_CASE` ourselves in `basic.sgra`. Because we added it, it can also carry a
field of our own named `EXPECTED`.

To use a grammar type from `.md`, you write the name of the type in `Type` directly under the heading.

```text
## The conversion succeeds

**Type**: TEST_CASE \
**UID**: TC-001
```

**Two traps specific to `.md` wait for you here.**

1. **StrictDoc uses the name `Type` for the type itself, so never declare a field
   named `TYPE` in the grammar.** If you declare one, you can no longer write it
   from `.md`.
2. **Write the key of a custom field in the uppercase the grammar declares.**
   `EXPECTED` passes but `Expected` fails. The eight built-in words such as
   `Statement` and `Title` ignore case, on the other hand. **You can only memorize
   this asymmetry.**

**The relation type stays `Parent`, and `Role` changes what it means.** Here we
attached `Verifies`. You must declare a `Role` in the grammar before you use it.

These four test cases cover the four software requirements of `04-lower.md` one
for one. The **traceability matrix** screen in the left toolbar shows you at a
glance whether the coverage holds.

## The conversion succeeds

**Type**: TEST_CASE \
**UID**: TC-001

**Statement**: Give the tool an input file in the expected format and run it with no file of the same name at the destination.

**EXPECTED**: The tool exits normally and has created an output file in the format the user specified.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-001` \
  **Role**: `Verifies`

## An unexpected format is rejected

**Type**: TEST_CASE \
**UID**: TC-002

**Statement**: Give the tool an input file that does not match the specified format and run it.

**EXPECTED**: The tool exits with an error and has created no output file.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-002` \
  **Role**: `Verifies`

## An existing file is not overwritten

**Type**: TEST_CASE \
**UID**: TC-003

**Statement**: Put a file of the same name at the destination, run the tool, and compare the contents of that file before and after the run.

**EXPECTED**: The tool exits with an error and the contents of the existing file stay unchanged.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-003` \
  **Role**: `Verifies`

## An interruption leaves no partial file

**Type**: TEST_CASE \
**UID**: TC-004

**Statement**: Kill the process partway through the write and inspect the state of the destination.

**EXPECTED**: No incomplete file remains at the destination.

**Relations**:
- **Type**: `Parent` \
  **ID**: `SW-004` \
  **Role**: `Verifies`
