"""Check that every copy of a grammar file still says the same thing.

A `.sgra` has to sit in the same folder as the documents that name it, so a
project that ships in several editions ships the grammar several times. This
repository carries `basic.sgra` four times - md-basic-en, md-basic-ja,
sd-basic-en, sd-basic-ja - and `sovd-grammar.sgra` twice.

Nothing else notices when those copies drift. A grammar does not depend on the
language of the documents: the field names are English in every edition, so the
copies are meant to be the same file. But `strictdoc export` validates each
project on its own and never compares them, `check-symmetry.py` compares the
nodes and relations two editions produce rather than the grammar behind them,
and `ascii-audit.py` only asks whether the bytes are ASCII. Add a field to one
copy and the other edition keeps exporting - it just quietly stops carrying that
field, and the two editions have become different specifications wearing the
same name.

The comparison ignores line endings. StrictDoc reads a `.sgra` through a reader
that translates newlines (helpers/file_system.py:87 opens it with utf-8-sig and
no newline="" argument), and a CRLF grammar was measured to put no carriage
return into the export, so a copy that differs only there parses identically.
It is still worth knowing about, so it is reported as a note rather than passed
over in silence.

Grouping is by file name. Two grammars that are deliberately different must have
different names - that is the rule this check enforces, and it is the same rule
that lets a reader open either copy and trust what they see.

--self-test builds a pair that has drifted and requires the check to fire.
"Zero differences" says nothing until the comparison has been seen to fail.

Exit code is 0 when every copy agrees, 1 otherwise.

Usage:
    python tools/check-grammar-copies.py
    python tools/check-grammar-copies.py samples/md-basic-en samples/md-basic-ja
    python tools/check-grammar-copies.py --self-test
"""

import argparse
import collections
import difflib
import io
import pathlib
import subprocess
import sys

SUFFIX = ".sgra"


def tracked_grammars(paths):
    """Every tracked .sgra under the given paths, as repository-relative names."""
    command = ["git", "ls-files", "--"] + list(paths)
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit("git ls-files failed:\n" + result.stderr.strip())
    return [pathlib.Path(name) for name in result.stdout.split() if name.endswith(SUFFIX)]


def read(path):
    """Return (text with newlines normalized, the line ending the file uses)."""
    raw = io.open(path, "rb").read()
    ending = "CRLF" if raw.count(b"\r\n") and raw.count(b"\r\n") == raw.count(b"\n") else (
        "LF" if b"\r" not in raw else "mixed"
    )
    return raw.replace(b"\r\n", b"\n").decode("utf-8-sig"), ending


def group(paths):
    """Collect the copies of each grammar, keyed by file name."""
    found = collections.defaultdict(list)
    for path in paths:
        found[path.name].append(path)
    return found


def compare(name, copies):
    """Return (differences, notes) for one group of same-named grammars."""
    differences = []
    notes = []
    first = copies[0]
    reference, reference_ending = read(first)
    for other in copies[1:]:
        text, ending = read(other)
        if text != reference:
            diff = difflib.unified_diff(
                reference.splitlines(),
                text.splitlines(),
                fromfile=str(first),
                tofile=str(other),
                lineterm="",
                n=1,
            )
            differences.append((other, "\n".join(diff)))
        elif ending != reference_ending:
            notes.append(
                "{0} uses {1} where {2} uses {3}. StrictDoc reads both the same "
                "way, so this changes nothing it parses.".format(
                    other, ending, first, reference_ending
                )
            )
    return differences, notes


def check(paths, quiet=False):
    """Compare every group. Returns the number of groups that disagree."""
    grammars = group(tracked_grammars(paths))
    if not grammars:
        print("no .sgra found under: " + ", ".join(str(p) for p in paths))
        return 0

    failed = 0
    for name in sorted(grammars):
        copies = sorted(grammars[name])
        if len(copies) == 1:
            if not quiet:
                print("  ok    {0}  (1 copy, nothing to compare)".format(name))
            continue
        differences, notes = compare(name, copies)
        if differences:
            failed += 1
            print("  FAIL  {0}  ({1} copies, {2} disagree)".format(
                name, len(copies), len(differences)))
            for path, diff in differences:
                print("          {0}".format(path))
                for line in diff.splitlines():
                    print("            {0}".format(line))
        elif not quiet:
            print("  ok    {0}  ({1} copies agree)".format(name, len(copies)))
        for note in notes:
            print("  note  {0}".format(note))
    return failed


# ---------------------------------------------------------------- self-test


FIXTURE = """[GRAMMAR]
ELEMENTS:
- TAG: REQUIREMENT
  FIELDS:
  - TITLE: UID
    TYPE: String
    REQUIRED: True
  - TITLE: STATEMENT
    TYPE: String
    REQUIRED: True
"""

EXTRA_FIELD = """  - TITLE: RATIONALE
    TYPE: String
    REQUIRED: False
"""


def self_test():
    """Break a pair of copies once per way they can drift, and require a report."""
    import tempfile

    print("self-test: the comparison must be seen to fail before a clean run counts")
    print()
    failures = 0
    workspace = pathlib.Path(tempfile.mkdtemp(prefix="grammar-copies-"))

    def build(folder, text, newline):
        target = workspace / folder
        target.mkdir(parents=True, exist_ok=True)
        io.open(target / "basic.sgra", "w", encoding="utf-8", newline=newline).write(text)
        return target / "basic.sgra"

    identical = [build("a", FIXTURE, "\n"), build("b", FIXTURE, "\n")]
    differences, notes = compare("basic.sgra", identical)
    if differences or notes:
        print("  FAIL  identical copies were reported as different")
        failures += 1
    else:
        print("  ok    identical copies agree")

    drifted = [identical[0], build("c", FIXTURE + EXTRA_FIELD, "\n")]
    differences, _ = compare("basic.sgra", drifted)
    if not differences:
        print("  FAIL  a field added to one copy was not reported")
        failures += 1
    elif "RATIONALE" not in differences[0][1]:
        print("  FAIL  the report does not name the field that drifted")
        failures += 1
    else:
        print("  ok    a field added to one copy is reported, and named")

    endings = [identical[0], build("d", FIXTURE, "\r\n")]
    differences, notes = compare("basic.sgra", endings)
    if differences:
        print("  FAIL  a line-ending difference was treated as drift")
        failures += 1
    elif not notes:
        print("  FAIL  a line-ending difference was passed over in silence")
        failures += 1
    else:
        print("  ok    a line-ending difference is a note, not a failure")

    grouped = group([
        pathlib.Path("x/basic.sgra"),
        pathlib.Path("y/basic.sgra"),
        pathlib.Path("z/other.sgra"),
    ])
    if sorted(grouped) != ["basic.sgra", "other.sgra"] or len(grouped["basic.sgra"]) != 2:
        print("  FAIL  copies are not grouped by file name")
        failures += 1
    else:
        print("  ok    copies are grouped by file name")

    import shutil

    shutil.rmtree(workspace, ignore_errors=True)

    print()
    if failures:
        print("self-test FAILED: {0} case(s). The comparison cannot be trusted.".format(failures))
        return 1
    print("self-test passed: the comparison fires on the drift it is there to catch.")
    return 0


# ---------------------------------------------------------------- entry point


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Check that same-named grammar files hold the same grammar."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        default=["samples"],
        help="folders to search. Defaults to samples/.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="prove the comparison fires on a pair that has drifted",
    )
    parser.add_argument("--quiet", action="store_true", help="print only what disagrees")
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()

    failed = check(args.paths or ["samples"], quiet=args.quiet)
    print()
    if failed:
        print("FAIL: {0} grammar(s) differ between copies.".format(failed))
        return 1
    print("PASS: every copy of every grammar says the same thing.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
