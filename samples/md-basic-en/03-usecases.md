# Use cases

**Grammar**: basic.sgra \
**UID**: DOC-USECASES \
**Version**: 1.0

This document writes down how a user uses the tool. Where the system requirements in
`04-upper.md` write the conditions the tool must satisfy, this document writes the
thread of using it. The two are different things.

| | Use case (this document) | Requirement (`04-upper.md` / `06-lower.md`) |
|---|---|---|
| Subject | The user | The tool |
| What it writes | How you use it. What happens | What it must satisfy |
| Shape | Main success scenario plus extensions | One EARS sentence (a requirement-sentence pattern. `04-upper.md`) |
| How you count | One per user goal | One per condition to satisfy |

`USE_CASE` is not a standard StrictDoc node type. We added it in `basic.sgra`, and the
same goes for the `UC_LEVEL` field. You may add as many node types and fields as you
like - how to add them, and what to watch out for, is in the grammar chapter of
`02-guide-for-human.md`.

## A use case sits above the requirements

**Type**: SECTION

**The use case in this document is the parent of the system requirements in
`04-upper.md`.** The requirement side carries the `**Relations**:` that points at the
use case, not the other way round. The root is the single `UC-001` in this document,
and one thread runs from there down to verification.

```text
UC-001 (UserGoal)  <-  SYS-001/002/003  <-  SW-*  <-  TC-*
      ^                                              |
      `----------------------------------------------'
                    TC-* verifies UC-001 as well
```

Look at the content and you can see why the arrow runs this way. The system
requirements come straight out of the thread of `UC-001`. We keep the extensions out of
the node and put them in this table instead, beside the requirement each one produced.

| Where in `UC-001` | The requirement it produced |
|---|---|
| Main success scenario, step 4 (write out the converted result) | `SYS-001` |
| Extension 2a (the format differs - do not convert) | `SYS-002` |
| Extension 3a (a file of that name exists - do not overwrite) | `SYS-003` |
| Extension 4a (the write stopped - leave no partial file) | No new system requirement. `SW-004` takes it directly, and its parent is `SYS-003` |

**It is the extensions that produce the requirements.** Write only the main success
scenario and you lose the unwanted-behaviour requirements (`SYS-002` / `SYS-003`)
wholesale. That is half the reason for writing a use case at all.

The mapping is not one to one, though. Extension 4a produced no system requirement.
Guarding against an interruption is not a promise the user can see; it is what the
implementation side needs in order to keep `SYS-003` (do not break an existing file).
**Never make one system requirement per extension.**

The standards run the same way. ISO/IEC/IEEE 29148 lists the use case as a technique
for eliciting and expressing stakeholder requirements, and treats the system
requirements as derived from it. Cockburn likewise holds that a sea-level use case is
itself a behavioural requirement, and that you read the individual conditions off the
extensions.

When the direction is unclear, decide it by asking which of the two is the more
abstract. `Parent` always runs from the concrete to the abstract. In a set that puts a
layer of stakeholder requirements above the use cases, the use case becomes a child of
that layer. This set has no such layer; its top is the system requirement.

The system requirements carrying `**Relations**:` breaks no rule. The child side always
writes the relation, and here the system requirement is the child (`06-lower.md`).

## How to write one - the Cockburn form

**Type**: SECTION

The use case follows Cockburn's form - the way of writing that Alistair Cockburn set out
in *Writing Effective Use Cases* (2000). Its point is that you write the main success
scenario as numbered steps and then list the threads that leave it as "extensions",
numbered off the step they leave.

Cockburn lists the following items for a "fully dressed" use case. Copied into `.md` it
looks like this.

```text
## <Title, written as a verb phrase naming the goal>

**Type**: USE_CASE \
**UID**: UC-00X \
**UC_LEVEL**: UserGoal

**Statement**: <the goal in one sentence>

**Scope** - <how much you treat as the thing being designed>

**Primary actor** - <the person who holds the goal>

**Stakeholders and interests** - <who cares about what>

**Preconditions** - <what must hold before you start>

**Minimal guarantees** - <what holds even when it fails>

**Success guarantees** - <what holds when it succeeds>

**Trigger** - <what signals the start>

**Main success scenario**

1. <who does what>
2. <who does what>

**Extensions**

- 2a. <the thread that leaves step 2> -> <what happens>
```

**Those labels use a dash rather than a colon on purpose.** An ASCII-only bold label
followed by a colon - `**Scope**:` - is read by StrictDoc as a field declaration, and
the export stops with `Invalid requirement field: Scope` (measured). A dash, a period or
a parenthetical all pass; a colon does not.

Only the level goes into a field, `UC_LEVEL`. Its values are closed to three, so
declaring it `SingleChoice` lets StrictDoc reject a misspelling - which prose cannot do.
We leave the rest out of the fields: what you will not later look up by name is
something to read, not a search key.

The `UC-001` of this set writes only the goal, the level and the main success scenario
out of all of that. **The body of a node appears as it is on the traceability screen, so
a long one makes the tree of requirements unreadable.** We did not drop the rest, we put
it elsewhere: the extensions are in the table of the previous chapter, and the scope is
just below. Since nothing but the steps is left, we also leave out the
`**Main success scenario**` label. Add an item to the node once you know you need it.

The scope of `UC-001` is one run of the tool. Choosing which file to convert, handing
the finished file on, and treating several of them together all sit outside. Start
writing without settling the scope and what you build spreads without end, so even a set
that keeps it out of the node draws the line somewhere.

`UC_LEVEL` is the height of the goal, in Cockburn's terms.

| Value | What Cockburn calls it | Meaning | In this set |
|---|---|---|---|
| `Summary` | Kite | A business-level thread that bundles several goals | Not used |
| `UserGoal` | Sea level | What a user wants to achieve in one go. The main battleground | `UC-001` only |
| `Subfunction` | Fish | A part of the goal above. Alone it is not a user goal | Not used |

This set carries sea level and nothing else. We did once write a kite-level "receive the
file at hand in another format", but its steps were "decide on the file", "convert it
with the tool" and "use the finished file", and the tool takes on only the middle one.
The remaining two are the user's own work and become no requirement. In other words the
kite only restated the one sea-level case, so it was not worth the extra level and we
folded it away.

A set of nothing but kites never settles what to build; a set of nothing but fish leaves
you unable to say what a function is for. **Add a level only when there is something
that only that level can say.**

We keep `UC_LEVEL` as a field even with a single use case. Without stating the height we
wrote at, no one would notice if someone later mixed in a kite or a fish. Because it is
a `SingleChoice`, whoever adds one has to pick one of the three.

## Convert an input file into the requested format

**Type**: USE_CASE \
**UID**: UC-001 \
**UC_LEVEL**: UserGoal \
**REVIEW_STATUS**: Open

**Statement**: A user converts an input file into the requested output format and gets it at the output location.

1. The user names an input file and an output format.
2. The tool confirms that the input file really is the format that was named.
3. The tool confirms that no file of that name sits at the output location.
4. The tool writes the converted result to the output location.
5. The tool tells the user that the conversion succeeded.

**REVIEW_COMMENT**: When a file of that name exists and the tool refuses to write, what the user gets told is not settled. Step 5 covers only how success is announced. This is the same gap as the open finding on `SYS-003`.
