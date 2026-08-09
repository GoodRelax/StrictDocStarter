"""Run every jq query in a document against a fixture and report the dead ones.

verify-jq.py answers "does this command still run". check-jq-output.py answers
"is the pasted output still what it prints". Neither one notices a query that
runs, prints nothing, and is simply wrong - a misspelt field name, a node type
that was renamed, a filter that can no longer match. Against the real sample
that failure is invisible, because plenty of queries correctly return nothing
there.

So this runs them against a fixture built to make every query hit: the
specification body of the sample supplies the UIDs the queries name by hand,
and a document of planted defects supplies a row for each detection query. A
query that returns nothing against THAT is dead.

Three conditions cannot be in one fixture, and saying so is part of the job:

  * a dangling relation and a duplicate UID stop the export before any JSON
    exists, so no fixture can carry them. StrictDoc enforces both itself.
  * the trailing-dollar trap stops the HTML export, and the query that reads
    the HTML needs that export to have succeeded. Those need separate runs.

Queries carrying a placeholder other than <json> are skipped, the same way
verify-jq.py skips them: the author expects a reader to substitute something.

Exit code is 0 when every runnable query returned at least one row, 1 otherwise.

Usage:
    python tools/run-query-fixture.py --fixture <dir> FILE.md [FILE.md ...]
    python tools/run-query-fixture.py --fixture <dir> --keep FILE.md
"""

import argparse
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

FENCE_OPEN = re.compile(r"^ {0,4}(`{3,})bash\s*$")
PLACEHOLDER = re.compile("<[^\\s\\d<>()|&;'\"$`][^<>()|&;'\"$`]{0,60}>")
COMMAND_TIMEOUT_SECONDS = 120

DEFAULT_SOURCE = pathlib.Path("samples/md-basic-ja")
KEEP = ["03-usecases.md", "04-upper.md", "05-architecture.md", "06-lower.md",
        "07-tests.md", "basic.sgra", "strictdoc_config.py",
        "strictdoc-theme.css"]
ASSETS = ["fig-state.md", "note.md", "flow.svg", "formats.csv"]
# The planted defects live beside this script, not under docs/in-private-work,
# because that folder is git-ignored: a tracked tool cannot depend on an
# untracked file, or it breaks for everyone who clones the repository.
DEFECTS = pathlib.Path(__file__).with_name("query-fixture-defects.md")

# A query that returns nothing even against this fixture, matched by a piece of
# its own body rather than by a line number, which moves. Each entry needs a
# reason: an unexplained exemption is how a dead query survives.
EXPECTED_EMPTY = [
    ("select(.VALUE | IN($ids[]) | not)",
     "a relation pointing at a UID nobody defines. StrictDoc refuses to export "
     "one, so no fixture can hold it - the query's own comment says zero is "
     "normal"),
]


def commands_in(path):
    """Yield (line number, command) for every jq command ending in <json>."""
    lines = path.read_text(encoding="utf-8").splitlines()
    index = 0
    while index < len(lines):
        match = FENCE_OPEN.match(lines[index])
        if not match:
            index += 1
            continue
        closing = re.compile(r"^ {0,4}`{" + str(len(match.group(1))) + r",}\s*$")
        scan = index + 1
        collected = None
        start = None
        while scan < len(lines) and not closing.match(lines[scan]):
            line = lines[scan]
            if collected is None:
                if line.strip().startswith("jq "):
                    collected = [line]
                    start = scan + 1
            else:
                collected.append(line)
            if collected is not None and line.rstrip().endswith("<json>"):
                yield start, "\n".join(collected)
                collected = None
            scan += 1
        index = scan + 1


def build_fixture(target, source):
    """Copy the specification body and add the planted defects."""
    if target.exists():
        shutil.rmtree(target)
    (target / "_assets").mkdir(parents=True)
    for name in KEEP:
        origin = source / name
        if origin.exists():
            shutil.copy(origin, target / name)
    for name in ASSETS:
        origin = source / "_assets" / name
        if origin.exists():
            shutil.copy(origin, target / "_assets" / name)
    if not DEFECTS.is_file():
        raise SystemExit("no defect document at {0}".format(DEFECTS))
    shutil.copy(DEFECTS, target / "90-defects.md")
    return target


def export(project, out):
    done = subprocess.run(
        ["strictdoc", "export", str(project), "--formats=json",
         "--output-dir", str(out), "--no-parallelization"],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    if done.returncode != 0:
        sys.stderr.write(done.stdout)
        sys.stderr.write(done.stderr)
        raise SystemExit("the fixture does not export; fix it before running")
    return out / "json" / "index.json"


def run(command, json_path, workdir):
    script = workdir / "command.sh"
    script.write_text(command.replace("<json>", '"{0}"'.format(json_path)) + "\n",
                      encoding="utf-8", newline="\n")
    done = subprocess.run(["bash", str(script)], capture_output=True, text=True,
                          encoding="utf-8", errors="replace",
                          timeout=COMMAND_TIMEOUT_SECONDS)
    rows = [l for l in done.stdout.splitlines() if l.strip()]
    return done.returncode, rows, done.stderr


def main():
    parser = argparse.ArgumentParser(
        description="Run every jq query against a fixture built to make them hit.")
    parser.add_argument("files", nargs="+")
    parser.add_argument("--sample", default=str(DEFAULT_SOURCE),
                        help="the sample whose specification body the "
                             "fixture is built from")
    parser.add_argument("--fixture", help="where to build the fixture "
                                          "(a temporary folder by default)")
    parser.add_argument("--keep", action="store_true",
                        help="leave the fixture and its export behind")
    args = parser.parse_args()

    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(errors="replace")
    if shutil.which("bash") is None:
        raise SystemExit("bash is not on PATH. Run this from Git Bash.")
    if shutil.which("jq") is None:
        raise SystemExit("jq is not on PATH.")
    if not pathlib.Path(args.sample).is_dir():
        raise SystemExit("no such sample: {0}".format(args.sample))

    temp = None
    if args.fixture:
        base = pathlib.Path(args.fixture)
        base.mkdir(parents=True, exist_ok=True)
    else:
        temp = tempfile.TemporaryDirectory(prefix="query-fixture-")
        base = pathlib.Path(temp.name)

    try:
        fixture = build_fixture(base / "fixture", pathlib.Path(args.sample))
        index = export(fixture, base / "out")
        json_path = index.resolve().as_posix()
        workdir = base / "work"
        workdir.mkdir(exist_ok=True)

        print("fixture: {0}".format(fixture.as_posix()))
        empty = []
        exempt = []
        failed = []
        total = 0
        skipped = 0

        for name in args.files:
            path = pathlib.Path(name)
            if not path.is_file():
                raise SystemExit("not a file: {0}".format(path))
            for line_no, command in commands_in(path):
                if PLACEHOLDER.search(command.replace("<json>", "")):
                    skipped += 1
                    continue
                total += 1
                try:
                    code, rows, error = run(command, json_path, workdir)
                except subprocess.TimeoutExpired:
                    failed.append((path, line_no, "timed out"))
                    continue
                if code != 0:
                    first = (error.strip().splitlines() or ["exit {0}".format(code)])[0]
                    failed.append((path, line_no, first))
                elif not rows:
                    reason = None
                    for signature, why in EXPECTED_EMPTY:
                        if signature in command:
                            reason = why
                            break
                    if reason is None:
                        empty.append((path, line_no, command.splitlines()[0]))
                    else:
                        exempt.append((path, line_no, reason))

        print("\n  ran {0} quer(ies), skipped {1} holding a placeholder".format(
            total, skipped))
        for path, line_no, reason in exempt:
            print("  note  {0}:{1} returns nothing on purpose"
                  "\n          {2}".format(path.as_posix(), line_no, reason))
        problems = 0
        if failed:
            problems += 1
            print("  FAIL  query did not run            {0}".format(len(failed)))
            for path, line_no, detail in failed:
                print("          {0}:{1}  {2}".format(
                    path.as_posix(), line_no, detail))
        else:
            print("  ok    query did not run            0")
        if empty:
            problems += 1
            print("  FAIL  query returned nothing       {0}".format(len(empty)))
            for path, line_no, head in empty:
                print("          {0}:{1}  {2}".format(
                    path.as_posix(), line_no, head[:90]))
        else:
            print("  ok    query returned nothing       0")

        print("\n" + "-" * 60)
        if problems:
            print("FAIL: {0} kind(s) of query problem".format(problems))
            return 1
        print("PASS: every query ran and returned at least one row")
        return 0
    finally:
        if temp is not None and not args.keep:
            temp.cleanup()


if __name__ == "__main__":
    sys.exit(main())
