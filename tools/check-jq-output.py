"""Compare the jq output pasted into a Markdown file with what the query prints.

verify-jq.py answers "does this command still run". This answers "is the output
shown underneath it still what the command prints". Nothing else in the
repository catches the second question: a query that runs but displays a stale
result teaches the wrong number, and it does so with full confidence. Run
against the samples and the skill, this found 25 blocks whose output no longer
matched.

What counts as a pair:

  * a fenced `bash` block (three or more backticks) holding exactly one jq
    command, where the command ends with the placeholder `<json>`,
  * followed, after blank lines only, by a fenced `text` or `json` block.

The second block is the claimed output. Everything else is left alone.

An author does not always paste the whole output, so a plain string comparison
would flag every deliberate excerpt and the script could never gate a build.
Four verdicts separate the cases:

  ok        the claimed output matches line for line
  elided    the claim ends in a parenthesised count, such as "(16 more lines)".
            The lines before it must be a prefix of the real output, AND the
            number must equal how many lines the claim dropped. The count is
            checked, not trusted
  excerpt   every claimed line appears in the real output, in order, and the
            claim covers no more than half of it. Representative rows lifted
            out of a long listing
  reflowed  the claim is the real output with whitespace inserted. `jq -c`
            prints one long line that an author wraps by hand to read it
  STALE     anything else

The half in `excerpt` is what stops a listing that grew from passing as a
selection: an outdated full paste is a subsequence of the new output, so the
subsequence test alone cannot tell "I chose these rows" from "I never came
back". It let a listing of 11 documents stand after the sample grew to 13. An
author who wants to show more than half must paste the whole output or end the
claim with an elision line, whose count this script checks.

Only STALE fails. Exit code is 0 when nothing is stale, 1 otherwise, so this can
gate a build the way ascii-audit.py and verify-jq.py do.

Usage:
    python tools/check-jq-output.py --json <index.json> FILE.md [FILE.md ...]
    python tools/check-jq-output.py --export <specification folder> FILE.md [...]
"""

import argparse
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

FENCE = re.compile(r"^ {0,4}(`{3,})([a-zA-Z]*)\s*$")
OUTPUT_INFO = ("text", "json")
# A placeholder the author expects a reader to replace, such as <output dir> or
# <query file>. Copied from verify-jq.py so the two scripts skip the same blocks.
PLACEHOLDER = re.compile("<[^\\s\\d<>()|&;'\"$`][^<>()|&;'\"$`]{0,60}>")
# "(16 more lines)" in English, its Japanese equivalent, and anything else an
# author writes to stand for the rest: a parenthesised line carrying a number.
# Matching the shape rather than the words keeps this file ASCII and keeps it
# working whatever language the sample is written in.
ELISION = re.compile(r"^\s*\(.*[0-9]+.*\)\s*$")
# How much of the real output an "excerpt" may cover. Every deliberate excerpt
# in this repository sits between 0.10 and 0.30; the stale listing that got
# through covered 0.85. Half is the round number between the two, and it states
# a rule an author can hold in their head: an excerpt shows a minority.
EXCERPT_MAX_SHARE = 0.5
COMMAND_TIMEOUT_SECONDS = 120


class Block(object):
    """One fenced block: its info string, where it sits, and what is inside."""

    def __init__(self, info, first_line, body, end_line):
        self.info = info
        self.first_line = first_line
        self.body = body
        self.end_line = end_line


def blocks(lines):
    """Return every fenced block in a file, in order.

    A fence closes only on a marker at least as long as the one that opened it,
    so a four-backtick block may hold three-backtick blocks inside it. The
    samples rely on that: a query body contains ``` of its own.
    """
    found = []
    index = 0
    while index < len(lines):
        match = FENCE.match(lines[index])
        if not match:
            index += 1
            continue
        closing = re.compile(r"^ {0,4}`{" + str(len(match.group(1))) + r",}\s*$")
        body = []
        scan = index + 1
        while scan < len(lines) and not closing.match(lines[scan]):
            body.append(lines[scan])
            scan += 1
        found.append(Block(match.group(2), index + 1, body, scan + 1))
        index = scan + 1
    return found


def sole_jq_command(body):
    """Return the one jq command in a bash block, or None.

    None covers a block with no command, with several, or with a command this
    script cannot resolve. Reporting nothing beats reporting a guess.
    """
    collected = None
    commands = []
    for line in body:
        if collected is None:
            if not line.strip().startswith("jq "):
                continue
            collected = [line]
        else:
            if not line.strip():
                return None
            collected.append(line)
        # A one-line command opens and closes on the same line, so this test
        # belongs outside the branch that appends a continuation line.
        if line.rstrip().endswith("<json>"):
            commands.append("\n".join(collected))
            collected = None
    if collected is not None or len(commands) != 1:
        return None
    return commands[0]


def run(command, json_path, workdir):
    """Run one command through bash and return its stdout as a list of lines.

    Passing the program as `bash -c <string>` would send it through Windows
    argument quoting, which mangles the single quotes. A file does not.

    Blank lines are dropped. StrictDoc keeps the source file's CRLF inside
    STATEMENT and jq on Windows adds a CRLF of its own, so a printed line
    arrives as "...\\r\\r\\n" and universal newlines turn that into two line
    breaks. A pasted output never carries a meaningful blank line, so dropping
    them costs nothing and removes the whole question.
    """
    script = workdir / "command.sh"
    script.write_text(
        command.replace("<json>", '"{0}"'.format(json_path)) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    completed = subprocess.run(
        ["bash", str(script)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=COMMAND_TIMEOUT_SECONDS,
    )
    lines = [line.rstrip() for line in completed.stdout.splitlines() if line.strip()]
    return completed.returncode, lines, completed.stderr


def strip_annotation(line):
    """Drop a trailing arrow note the author added by hand, such as "<- the same".

    The samples write that arrow as U+2190. Naming it by escape rather than by
    the character keeps this file ASCII (NFR-010).
    """
    for arrow in ("\u2190", "<-"):
        if arrow in line:
            return line.split(arrow)[0].rstrip()
    return line.rstrip()


def is_subsequence(claimed, actual):
    """True when every claimed line appears in actual, in the same order."""
    position = 0
    for line in claimed:
        while position < len(actual) and actual[position] != line:
            position += 1
        if position == len(actual):
            return False
        position += 1
    return True


def squeeze(lines):
    return "".join("".join(lines).split())


def classify(claimed, actual):
    """Return (verdict, detail). Only "STALE" counts as a failure."""
    if claimed == actual:
        return "ok", ""

    if claimed and ELISION.match(claimed[-1]):
        shown = claimed[:-1]
        dropped = len(actual) - len(shown)
        if actual[: len(shown)] != shown:
            return "STALE", "the lines before the elision are not the real first lines"
        numbers = [int(n) for n in re.findall(r"[0-9]+", claimed[-1])]
        if dropped < 0 or dropped not in numbers:
            return "STALE", "the elision claims {0}, the query dropped {1}".format(
                "/".join(str(n) for n in numbers) or "nothing", dropped
            )
        return "elided", "{0} shown, {1} dropped".format(len(shown), dropped)

    if len(claimed) < len(actual) and is_subsequence(claimed, actual):
        if len(claimed) > EXCERPT_MAX_SHARE * len(actual):
            dropped = len(actual) - len(claimed)
            return "STALE", (
                "shows {0} of {1} line(s): too much of the output to read as an "
                "excerpt. Paste all {1}, or end the block with an elision line "
                'such as "({2} more line{3})"'.format(
                    len(claimed), len(actual), dropped, "" if dropped == 1 else "s"
                )
            )
        return "excerpt", "{0} of {1} line(s)".format(len(claimed), len(actual))

    if squeeze(claimed) == squeeze(actual):
        return "reflowed", "{0} line(s) wrapped from {1}".format(
            len(claimed), len(actual)
        )

    return "STALE", "shown {0} line(s), actual {1}".format(len(claimed), len(actual))


def export_json(project, workdir):
    """Export the project to JSON and return the path of index.json."""
    output_dir = workdir / "export"
    completed = subprocess.run(
        [
            "strictdoc",
            "export",
            str(project),
            "--formats=json",
            "--output-dir",
            str(output_dir),
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if completed.returncode != 0:
        sys.stderr.write(completed.stdout)
        sys.stderr.write(completed.stderr)
        raise SystemExit("strictdoc export failed for {0}".format(project))
    index = output_dir / "json" / "index.json"
    if not index.is_file():
        raise SystemExit("strictdoc export produced no {0}".format(index))
    return index


def pairs(lines):
    """Yield (command, first line of the bash block, claimed output lines)."""
    found = blocks(lines)
    for index, block in enumerate(found):
        if block.info != "bash" or index + 1 >= len(found):
            continue
        command = sole_jq_command(block.body)
        if command is None:
            continue
        if PLACEHOLDER.search(command.replace("<json>", "")):
            continue
        following = found[index + 1]
        if following.info not in OUTPUT_INFO:
            continue
        gap = lines[block.end_line : following.first_line - 1]
        if any(line.strip() for line in gap):
            continue
        claimed = [
            strip_annotation(line) for line in following.body if line.strip()
        ]
        yield command, block.first_line, claimed


def main():
    # verify-jq.py's note applies here too: this script is ASCII, but what it
    # quotes back is not. A Japanese sample echoes its own text. On a cp932
    # console that kills the print, so degrade the characters instead of the run.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(errors="replace")

    parser = argparse.ArgumentParser(
        description="Compare pasted jq output with what the query prints."
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--json", help="path of an existing index.json")
    source.add_argument(
        "--export", help="specification folder to export to JSON before running"
    )
    parser.add_argument("files", nargs="+", help="Markdown files to scan")
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="print only the stale blocks, not every verdict",
    )
    args = parser.parse_args()

    if shutil.which("bash") is None:
        raise SystemExit("bash is not on PATH. Run this from Git Bash.")
    if shutil.which("jq") is None:
        raise SystemExit("jq is not on PATH.")

    tally = {"ok": 0, "elided": 0, "excerpt": 0, "reflowed": 0, "STALE": 0}
    stale = []

    with tempfile.TemporaryDirectory(prefix="check-jq-output-") as temp:
        workdir = pathlib.Path(temp)

        if args.export:
            project = pathlib.Path(args.export).resolve()
            if not project.is_dir():
                raise SystemExit("not a folder: {0}".format(project))
            index = export_json(project, workdir)
        else:
            index = pathlib.Path(args.json).resolve()
            if not index.is_file():
                raise SystemExit("not a file: {0}".format(index))
        json_path = index.as_posix()
        print("JSON: {0}".format(json_path))

        for name in args.files:
            path = pathlib.Path(name)
            if not path.is_file():
                raise SystemExit("not a file: {0}".format(path))
            lines = path.read_text(encoding="utf-8").splitlines()

            header_printed = False
            for command, line_number, claimed in pairs(lines):
                try:
                    code, actual, error = run(command, json_path, workdir)
                except subprocess.TimeoutExpired:
                    code, actual, error = 1, [], "timed out"
                if code != 0:
                    verdict, detail = "STALE", "the query failed: {0}".format(
                        error.strip().splitlines()[0] if error.strip() else code
                    )
                else:
                    verdict, detail = classify(claimed, actual)

                tally[verdict] += 1
                if verdict == "STALE":
                    stale.append((path, line_number, detail, claimed, actual))
                if args.quiet and verdict != "STALE":
                    continue
                if not header_printed:
                    print("\n{0}".format(path.as_posix()))
                    header_printed = True
                print(
                    "  {0:<8} line {1:<5} {2}".format(verdict, line_number, detail)
                )

    print("\n" + "-" * 72)
    for verdict in ("ok", "elided", "excerpt", "reflowed", "STALE"):
        print("  {0:<9} {1}".format(verdict, tally[verdict]))

    if stale:
        print("")
        for path, line_number, detail, claimed, actual in stale:
            print("{0}:{1}  {2}".format(path.as_posix(), line_number, detail))
            for line in claimed:
                print("  - {0}".format(line))
            for line in actual:
                print("  + {0}".format(line))
            print("")
        print("FAIL: {0} block(s) show output the query no longer prints".format(
            len(stale)
        ))
        return 1

    print("\nPASS: every pasted output still matches its query")
    return 0


if __name__ == "__main__":
    sys.exit(main())
