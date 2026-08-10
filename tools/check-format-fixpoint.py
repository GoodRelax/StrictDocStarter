"""Prove a specification folder survives a Markdown formatter untouched.

`strictdoc export` passing is not evidence that a specification is safe to
ship. The notation that breaks under a formatter exports cleanly as written;
it only dies after the formatter has run once. A folder validated by export
alone can therefore be published as "checked" while carrying the exact shape
that destroys every node the first time a reader opens a file and saves it.

Measured on strictdoc 0.27.1 with prettier 3.5.3: samples/md-sovd-automotive-en
exported 294 nodes, then failed with

    Semantic error: Markdown parsing error: duplicate field names in a valid
    requirement node are not allowed.

after a single `prettier --write`. Nothing in the repository caught that.

So this script copies, formats, and exports again:

    copy-source     copy the tracked files into a scratch folder. Tracked
                    files only, because that is exactly what a clone receives.
    export-before   the folder must export as written.
    format          run the formatter over the copy.
    export-after    the folder must still export.
    graph           the nodes and relations StrictDoc read must be identical
                    before and after. An export that survives while quietly
                    losing a relation is worse than one that fails.
    fixpoint        the formatter, run over the folder exactly as shipped,
                    must find nothing to change. This one is measured on the
                    untouched copy: running `--check` after `--write` would
                    only ask whether the formatter is idempotent, which says
                    nothing about the bytes a reader receives.
    idempotent      and a second pass must settle too, so that a formatted
                    folder stays formatted.
    source          the original folder must be byte-identical afterwards.

The glob is `**/*.md`, not `*.md`. `_assets/` holds documents too -
samples/md-basic-en/_assets/note.md declares `**UID**: DOC-NOTE` and StrictDoc
reads it as a document - so a top-level-only glob leaves them unformatted and
the check passes a folder it never looked at.

The output folders sit outside the copied project. StrictDoc walks its input
recursively, so an output folder placed inside the input is read back as source
on the next run and stops the export on duplicate UIDs.

--self-test is not optional decoration. "Zero failures" means nothing until
each check has been seen to fire, so --self-test builds a small project of its
own, confirms it passes clean, then breaks it once per check and requires that
exactly the expected check fails. Run it whenever this script changes.

Usage:
    python tools/check-format-fixpoint.py
    python tools/check-format-fixpoint.py samples/md-basic-en
    python tools/check-format-fixpoint.py --self-test
    python tools/check-format-fixpoint.py samples/md-basic-ja --keep
"""

import argparse
import hashlib
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

CHECKS = (
    "export-before",
    "format",
    "export-after",
    "graph",
    "fixpoint",
    "idempotent",
    "source",
)

MD_GLOB = "**/*.md"


class CheckFailure(Exception):
    """A named check failed. The message is what the reader needs to act."""

    def __init__(self, check, detail):
        super().__init__(detail)
        self.check = check
        self.detail = detail


# ---------------------------------------------------------------- external tools


def tool(name):
    """Return the path to an external tool, or exit saying which one is absent."""
    found = shutil.which(name)
    if found is None:
        sys.exit(f"{name} not found on PATH. This check cannot run without it.")
    return found


def run(argv, cwd=None):
    """Run a command and return (exit code, combined output)."""
    finished = subprocess.run(
        argv,
        cwd=str(cwd) if cwd else None,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return finished.returncode, (finished.stdout or "") + (finished.stderr or "")


def tail(text, lines=6):
    """Keep the last few meaningful lines of a tool's output for the report."""
    kept = [line.rstrip() for line in text.splitlines() if line.strip()]
    return "\n".join(kept[-lines:])


def versions():
    """Report the versions every measurement here depends on."""
    _, strictdoc = run([tool("strictdoc"), "--version"])
    _, prettier = run([tool("npx"), "prettier", "--version"])
    return strictdoc.strip().splitlines()[-1], prettier.strip().splitlines()[-1]


# ---------------------------------------------------------------- copying


def tracked_files(folder):
    """Return the repository-tracked files under a folder, relative to it.

    Tracked files are the whole of what a clone or a release archive carries.
    An untracked scratch file next to the specification is not shipped, and a
    generated output/ folder underneath would be read back as input.
    """
    code, out = run([tool("git"), "ls-files", "-z", "--", str(folder)])
    if code != 0:
        raise CheckFailure("copy-source", f"git ls-files failed:\n{tail(out)}")
    names = [name for name in out.split("\0") if name]
    if not names:
        raise CheckFailure("copy-source", f"no tracked files under {folder}")
    root = pathlib.Path(
        run([tool("git"), "rev-parse", "--show-toplevel"])[1].strip()
    )
    return root, [pathlib.Path(name) for name in names]


def copy_project(folder, destination, tracked_only=True):
    """Copy a project into a scratch folder, byte for byte.

    shutil.copy2 is deliberate. Reading as text and writing it back rewrites
    every line ending: the working tree here is CRLF while the index is LF, so
    a text-mode copy would silently hand the formatter a different file from
    the one a clone receives, and the result would say nothing about the real
    folder.
    """
    destination.mkdir(parents=True, exist_ok=True)
    if tracked_only:
        root, names = tracked_files(folder)
        prefix = pathlib.Path(folder).resolve().relative_to(root.resolve())
        pairs = [(root / name, name.relative_to(prefix)) for name in names]
    else:
        source = pathlib.Path(folder)
        pairs = [
            (path, path.relative_to(source))
            for path in sorted(source.rglob("*"))
            if path.is_file()
        ]
    for absolute, relative in pairs:
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(absolute, target)
    return [relative for _, relative in pairs]


def manifest(folder, names):
    """Hash every file, so "the original is untouched" is a measurement."""
    digests = {}
    for name in names:
        path = pathlib.Path(folder) / name
        digests[str(name).replace("\\", "/")] = hashlib.sha256(
            path.read_bytes()
        ).hexdigest()
    return digests


def compare_manifest(before, after):
    """Return the paths whose bytes moved. Empty means the original held."""
    moved = [name for name in sorted(before) if before[name] != after.get(name)]
    gone = [name for name in sorted(before) if name not in after]
    return sorted(set(moved) | set(gone))


# ---------------------------------------------------------------- the graph


def walk(node, depth=0):
    """Yield every node under a node, with the depth it was found at."""
    yield node, depth
    for child in node.get("NODES") or []:
        for found in walk(child, depth + 1):
            yield found


def fingerprint(index_path):
    """Reduce an exported project to what a formatter must not change.

    Counts alone would miss a relation that changed target while the total
    stayed the same, so this records identity: every node with its type, UID,
    title and nesting depth, and every relation as an edge.
    """
    data = json.loads(pathlib.Path(index_path).read_text(encoding="utf-8"))
    nodes = []
    edges = []
    documents = []
    for document in data.get("DOCUMENTS") or []:
        documents.append(f"{document.get('UID', '')}|{document.get('TITLE', '')}")
        for child in document.get("NODES") or []:
            for node, depth in walk(child):
                nodes.append(
                    "{}|{}|{}|{}".format(
                        depth,
                        node.get("_NODE_TYPE", ""),
                        node.get("UID", ""),
                        node.get("TITLE", ""),
                    )
                )
                for relation in node.get("RELATIONS") or []:
                    edges.append(
                        "{}|{}|{}|{}".format(
                            node.get("UID", ""),
                            relation.get("TYPE", ""),
                            relation.get("VALUE", ""),
                            relation.get("ROLE", ""),
                        )
                    )
    return {
        "documents": sorted(documents),
        "nodes": sorted(nodes),
        "edges": sorted(edges),
    }


def describe_graph_drift(before, after):
    """Say what moved, in the terms the writer edits: nodes and relations."""
    lines = []
    for key in ("documents", "nodes", "edges"):
        lost = sorted(set(before[key]) - set(after[key]))
        gained = sorted(set(after[key]) - set(before[key]))
        for item in lost[:5]:
            lines.append(f"  lost {key[:-1]}: {item}")
        for item in gained[:5]:
            lines.append(f"  gained {key[:-1]}: {item}")
    return "\n".join(lines) or "  (sets differ in ordering only)"


# ---------------------------------------------------------------- the pipeline


def export(project, output):
    """Export to JSON outside the project, without parallelization.

    Parallel export swallows the real error and reports a generic failure, so
    a check that ran in parallel cannot say what is wrong.
    """
    code, out = run(
        [
            tool("strictdoc"),
            "export",
            str(project),
            "--formats=json",
            "--output-dir",
            str(output),
            "--no-parallelization",
        ]
    )
    return code, out


def format_markdown(project, write):
    """Run the formatter over every .md in the project, `_assets/` included."""
    argv = [tool("npx"), "prettier", "--write" if write else "--check", MD_GLOB]
    return run(argv, cwd=project)


def check_folder(folder, keep=False, tracked_only=True):
    """Run every check against one folder. Returns the list of failures."""
    workspace = pathlib.Path(tempfile.mkdtemp(prefix="fixpoint-"))
    project = workspace / "project"
    failures = []
    try:
        names = copy_project(folder, project, tracked_only=tracked_only)
        before_hashes = manifest(folder, names) if tracked_only else None

        code, out = export(project, workspace / "out-before")
        if code != 0:
            raise CheckFailure("export-before", tail(out))

        # Measured on the pristine copy, before anything has been written to
        # it. `--check` after `--write` would only say whether the formatter
        # is idempotent; the question here is whether the bytes we ship are
        # already what the formatter produces, so that a reader who opens a
        # file and saves it sees no diff at all. Held back and reported after
        # the export checks, because a folder that dies under the formatter is
        # a worse finding than one that merely produces a diff.
        settled, settled_out = format_markdown(project, write=False)

        code, out = format_markdown(project, write=True)
        if code != 0:
            raise CheckFailure("format", tail(out))

        code, out = export(project, workspace / "out-after")
        if code != 0:
            raise CheckFailure("export-after", tail(out))

        before = fingerprint(workspace / "out-before" / "json" / "index.json")
        after = fingerprint(workspace / "out-after" / "json" / "index.json")
        if before != after:
            raise CheckFailure("graph", describe_graph_drift(before, after))

        if settled != 0:
            raise CheckFailure(
                "fixpoint",
                "formatting these files as shipped changes them:\n" + tail(settled_out),
            )

        code, out = format_markdown(project, write=False)
        if code != 0:
            raise CheckFailure(
                "idempotent",
                "the formatter does not settle after one pass:\n" + tail(out),
            )

        if before_hashes is not None:
            moved = compare_manifest(before_hashes, manifest(folder, names))
            if moved:
                raise CheckFailure(
                    "source",
                    "the original folder was modified:\n"
                    + "\n".join(f"  {name}" for name in moved),
                )
    except CheckFailure as failure:
        failures.append(failure)
    finally:
        if keep:
            print(f"  work kept at {workspace}")
        else:
            shutil.rmtree(workspace, ignore_errors=True)
    return failures


# ---------------------------------------------------------------- self-test


FIXTURE_GRAMMAR = """[GRAMMAR]
ELEMENTS:
- TAG: SECTION
  PROPERTIES:
    IS_COMPOSITE: True
  FIELDS:
  - TITLE: TITLE
    TYPE: String
    REQUIRED: True
- TAG: REQUIREMENT
  FIELDS:
  - TITLE: UID
    TYPE: String
    REQUIRED: True
  - TITLE: TITLE
    TYPE: String
    REQUIRED: True
  - TITLE: STATEMENT
    TYPE: String
    REQUIRED: True
  RELATIONS:
  - TYPE: Parent
- TAG: TEST_RESULT
  FIELDS:
  - TITLE: UID
    TYPE: String
    REQUIRED: True
  - TITLE: TITLE
    TYPE: String
    REQUIRED: True
  - TITLE: RESULT
    TYPE: SingleChoice(PASS, FAIL)
    REQUIRED: True
  - TITLE: EVIDENCE
    TYPE: String
    REQUIRED: True
  RELATIONS:
  - TYPE: Parent
    ROLE: ResultOf
"""

# Written in the notation this repository ships: no trailing backslash, one
# blank line after every field name that carries a list, and - for the type
# whose fields all fit on one line - a blank line before the last field, so
# that the node has a body field for `**Relations**` to sit behind. The table
# is already column-aligned, because Prettier aligns tables and a fixture that
# needed one pass to settle could not tell a fixed point from a near miss.
FIXTURE_DOCUMENT = """# Self-test specification

**Grammar**: selftest.sgra
**UID**: DOC-SELFTEST
**Version**: 1.0

This project exists so that every check in check-format-fixpoint.py can be
seen to fire. It is not a sample and it is not shipped.

| Column | Meaning                     |
| ------ | --------------------------- |
| First  | Already aligned by Prettier |

## A parent requirement

**Type**: REQUIREMENT
**UID**: REQ-001

**STATEMENT**: The tool shall do the first thing.

## A child requirement

**Type**: REQUIREMENT
**UID**: REQ-002

**STATEMENT**: The tool shall do the second thing.

**Relations**:

- **Type**: `Parent`
  **ID**: `REQ-001`

## [PASS] The child requirement is verified

**Type**: TEST_RESULT
**UID**: TR-001
**RESULT**: PASS

**EVIDENCE**: out/junit.xml#test_second

**Relations**:

- **Type**: `Parent`
  **ID**: `REQ-002`
  **Role**: `ResultOf`
"""

FIXTURE_NOTE = """# A note that lives in \\_assets

**UID**: DOC-NOTE

StrictDoc reads this as a document even though it sits in `_assets/`. A check
whose glob is `*.md` never formats this file and never learns that.
"""


def build_fixture(destination):
    """Write the self-test project. LF throughout, one trailing newline."""
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "_assets").mkdir(exist_ok=True)
    for name, text in (
        ("selftest.sgra", FIXTURE_GRAMMAR),
        ("00-spec.md", FIXTURE_DOCUMENT),
        ("_assets/note.md", FIXTURE_NOTE),
    ):
        (destination / name).write_text(text, encoding="utf-8", newline="\n")
    return destination


def read_lines(path):
    """Split a file into lines, remembering which line ending it used."""
    raw = path.read_text(encoding="utf-8", newline="")
    ending = "\r\n" if "\r\n" in raw else "\n"
    return raw.replace("\r\n", "\n").split("\n"), ending


def write_lines(path, lines, ending):
    path.write_text(ending.join(lines), encoding="utf-8", newline="")


def break_dangling_parent(project):
    """Point a relation at a UID that does not exist. Export must refuse."""
    path = project / "00-spec.md"
    lines, ending = read_lines(path)
    for index, line in enumerate(lines):
        if line.strip() == "**ID**: `REQ-001`":
            lines[index] = line.replace("REQ-001", "REQ-999")
            break
    write_lines(path, lines, ending)


def section_bounds(lines, heading):
    """Return the half-open line range of one `## ` section."""
    start = lines.index(heading)
    end = start + 1
    while end < len(lines) and not lines[end].startswith("## "):
        end += 1
    return start, end


def break_relations_glued(project):
    """Glue `**Relations**` to the metadata block and move the body field down.

    This is the shape that exports as written and dies after one formatting
    pass, because the formatter separates the field name from its list. The
    rewrite stays inside one section: reaching across a heading would delete a
    node, and a mutation that removes a requirement proves nothing about
    notation.
    """
    path = project / "00-spec.md"
    lines, ending = read_lines(path)
    start, end = section_bounds(lines, "## A child requirement")
    section = lines[start:end]

    relations = section.index("**Relations**:")
    statement = next(
        index for index, line in enumerate(section) if line.startswith("**STATEMENT**:")
    )
    block = [line for line in section[relations:] if line.strip()]
    rebuilt = (
        section[: statement - 1]        # heading, metadata, no trailing blank
        + block                          # Relations glued straight on
        + ["", section[statement], ""]   # the body field pushed below it
    )
    write_lines(path, lines[:start] + rebuilt + lines[end:], ending)


def break_missing_blank_line(project):
    """Drop the blank line after `**Relations**`. Exports fine, never settles."""
    path = project / "00-spec.md"
    lines, ending = read_lines(path)
    rebuilt = []
    skip = False
    for line in lines:
        if skip and not line.strip():
            skip = False
            continue
        rebuilt.append(line)
        skip = line == "**Relations**:"
    write_lines(path, rebuilt, ending)


def break_assets_only(project):
    """Leave a blank line at the end of a file in `_assets/`.

    Exports fine either way. The formatter drops it, so the folder is not a
    fixed point - and only a `**/*.md` glob ever reaches the file.

    One blank line, not two. StrictDoc stops on `two or more consecutive empty
    lines are not allowed`, and a mutation that fails the export would be
    testing the wrong check.
    """
    path = project / "_assets" / "note.md"
    raw = path.read_text(encoding="utf-8", newline="")
    path.write_text(raw + "\n", encoding="utf-8", newline="")


SABOTAGE = (
    ("dangling-parent", break_dangling_parent, "export-before"),
    ("relations-glued", break_relations_glued, "export-after"),
    ("missing-blank-line", break_missing_blank_line, "fixpoint"),
    ("blank-line-in-assets", break_assets_only, "fixpoint"),
)


def self_test(keep=False):
    """Confirm the clean fixture passes, then that each break is caught."""
    print("self-test: every check must be seen to fire before a clean run counts")
    print()
    failed = 0

    workspace = pathlib.Path(tempfile.mkdtemp(prefix="fixpoint-selftest-"))
    clean = build_fixture(workspace / "clean")
    problems = check_folder(clean, keep=keep, tracked_only=False)
    if problems:
        print(f"  FAIL  clean fixture: {problems[0].check}: {problems[0].detail}")
        failed += 1
    else:
        print("  ok    clean fixture passes every check")

    for name, sabotage, expected in SABOTAGE:
        broken = build_fixture(workspace / name)
        sabotage(broken)
        problems = check_folder(broken, keep=keep, tracked_only=False)
        if not problems:
            print(f"  FAIL  {name}: nothing failed. '{expected}' did not fire")
            failed += 1
        elif problems[0].check != expected:
            print(
                f"  FAIL  {name}: expected '{expected}' to fire, "
                f"got '{problems[0].check}'"
            )
            failed += 1
        else:
            print(f"  ok    {name} -> {expected} fired")

    # The remaining two checks cannot be reached by breaking a document. A
    # formatter that changed the graph without failing the export would be a
    # StrictDoc bug rather than a notation defect, and nothing this script
    # writes can modify the original folder. Both comparators are exercised
    # directly instead, so neither can rot into a function that always agrees.
    left = {"documents": ["D"], "nodes": ["0|REQUIREMENT|A|Title"], "edges": []}
    right = {"documents": ["D"], "nodes": ["0|REQUIREMENT|A|Title"], "edges": ["A|Parent|B|"]}
    if left == right or not describe_graph_drift(left, right).strip():
        print("  FAIL  graph: the comparator does not report a lost relation")
        failed += 1
    else:
        print("  ok    graph comparator reports a lost relation")

    if compare_manifest({"a.md": "1"}, {"a.md": "2"}) != ["a.md"]:
        print("  FAIL  source: the manifest comparator does not report a rewrite")
        failed += 1
    else:
        print("  ok    source comparator reports a rewritten file")

    if not keep:
        shutil.rmtree(workspace, ignore_errors=True)
    else:
        print(f"\n  fixtures kept at {workspace}")

    print()
    if failed:
        print(f"self-test FAILED: {failed} case(s). The checks cannot be trusted.")
        return 1
    print("self-test passed: every check fires on the defect it is there to catch.")
    return 0


# ---------------------------------------------------------------- entry point


def default_folders():
    """Every sample folder that holds a tracked Markdown document."""
    code, out = run([tool("git"), "ls-files", "--", "samples"])
    if code != 0:
        return []
    folders = sorted(
        {
            "/".join(name.split("/")[:2])
            for name in out.split()
            if name.endswith(".md")
        }
    )
    return folders


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Check that a specification folder is a formatting fixed point."
    )
    parser.add_argument(
        "folders",
        nargs="*",
        help="specification folders. Defaults to every Markdown sample.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="prove each check fires on the defect it is there to catch",
    )
    parser.add_argument(
        "--keep",
        action="store_true",
        help="keep the scratch folders for inspection",
    )
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test(keep=args.keep)

    strictdoc_version, prettier_version = versions()
    print(f"strictdoc {strictdoc_version} / prettier {prettier_version}")
    print()

    folders = args.folders or default_folders()
    if not folders:
        sys.exit("no folders to check")

    failed = 0
    for folder in folders:
        path = pathlib.Path(folder)
        if not path.is_dir():
            print(f"FAIL  {folder}: not a folder")
            failed += 1
            continue
        problems = check_folder(path, keep=args.keep)
        if problems:
            failed += 1
            for problem in problems:
                print(f"FAIL  {folder}  [{problem.check}]")
                for line in problem.detail.splitlines():
                    print(f"        {line}")
        else:
            print(f"ok    {folder}  ({', '.join(CHECKS)})")

    print()
    if failed:
        print(f"{failed} of {len(folders)} folder(s) failed.")
        return 1
    print(f"All {len(folders)} folder(s) are formatting fixed points.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
