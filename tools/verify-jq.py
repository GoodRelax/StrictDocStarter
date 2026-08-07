"""Run every jq example embedded in a Markdown file and report what breaks.

The skill and the samples teach jq by showing commands. A command that no
longer runs teaches the wrong thing, and nothing else in the repository
catches that: ascii-audit.py looks at characters, `strictdoc export` looks at
the specification, and neither one executes a fenced code block.

What counts as an example:

  * a fenced block whose info string is `bash` (three or more backticks,
    indented by up to four spaces),
  * inside it, a run of lines that starts with `jq ` and ends with the
    placeholder `<json>`.

Everything else in the block is left alone. Comments, `strictdoc export`
lines, and pipelines that merely contain jq (`comm -13 <(jq ...)`) are not
commands this script can resolve, so it skips them and says so rather than
pretending they passed. The same goes for a command that still holds a
placeholder such as `<output dir>` after `<json>` is substituted.

Each command is written to a temporary .sh file and run through bash. Passing
it as `bash -c <string>` would send the jq program through Windows argument
quoting, which mangles the single quotes; a file does not.

Usage:
    python tools/verify-jq.py --json <index.json> FILE.md [FILE.md ...]
    python tools/verify-jq.py --export <specification folder> FILE.md [...]

--export runs `strictdoc export --formats=json` into a temporary folder and
uses the index.json it produces, so the report always reflects the current
specification instead of a stale export.

Exit code is 0 when every extracted command succeeds, 1 otherwise, so it can
gate a build the way ascii-audit.py does.
"""

import argparse
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

FENCE_OPEN = re.compile(r"^ {0,4}(`{3,})bash\s*$")
FENCE_CLOSE_TEMPLATE = r"^ {{0,4}}`{{{0},}}\s*$"
# A placeholder the author expects a reader to replace, such as <output dir> or
# <query file>. The Japanese samples write theirs in Japanese, so the pattern
# cannot assume ASCII. It excludes the characters that appear in a jq program or
# in shell redirection, and refuses a first character that is a space or a digit,
# so a comparison such as `$c < 5 and .n > 3` is not mistaken for one.
PLACEHOLDER = re.compile("<[^\\s\\d<>()|&;'\"$`][^<>()|&;'\"$`]{0,60}>")
COMMAND_TIMEOUT_SECONDS = 120


class Command(object):
    """One jq example: where it came from and what it is."""

    def __init__(self, line_number, text):
        self.line_number = line_number
        self.text = text


def extract(path):
    """Return (commands, skipped) for one Markdown file.

    skipped holds (line number, reason, first line) for every run of lines
    that looked like an example but could not be turned into something
    runnable.
    """
    commands = []
    skipped = []
    fence_close = None
    collecting = None
    start_line = 0

    lines = path.read_text(encoding="utf-8").splitlines()
    for number, line in enumerate(lines, start=1):
        if fence_close is None:
            match = FENCE_OPEN.match(line)
            if match:
                fence_close = re.compile(
                    FENCE_CLOSE_TEMPLATE.format(len(match.group(1)))
                )
            continue

        if fence_close.match(line):
            if collecting:
                skipped.append(
                    (start_line, "no <json> before the fence closed", collecting[0])
                )
                collecting = None
            fence_close = None
            continue

        if collecting is None:
            if not line.strip().startswith("jq "):
                continue
            collecting = [line]
            start_line = number
        else:
            if not line.strip():
                skipped.append((start_line, "blank line inside the command", collecting[0]))
                collecting = None
                continue
            collecting.append(line)

        if line.rstrip().endswith("<json>"):
            commands.append(Command(start_line, "\n".join(collecting)))
            collecting = None

    if collecting:
        skipped.append((start_line, "file ended inside the command", collecting[0]))
    return commands, skipped


def resolve(text, json_path):
    """Substitute <json>. Return (command, reason) with one of them None."""
    resolved = text.replace("<json>", '"{0}"'.format(json_path))
    left = PLACEHOLDER.search(resolved)
    if left:
        return None, "placeholder {0} has no value".format(left.group(0))
    return resolved, None


def run(command, workdir):
    """Run one command through bash. Return (returncode, stdout, stderr)."""
    script = workdir / "command.sh"
    script.write_text(command + "\n", encoding="utf-8", newline="\n")
    completed = subprocess.run(
        ["bash", str(script)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=COMMAND_TIMEOUT_SECONDS,
    )
    return completed.returncode, completed.stdout, completed.stderr


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


def first_line(text):
    stripped = text.strip()
    head = stripped.splitlines()[0] if stripped else ""
    return head if len(head) <= 88 else head[:85] + "..."


def main():
    # NFR-010: this script is ASCII, but what it quotes back is not. A Japanese
    # sample writes its placeholders in Japanese, and jq echoes document text in
    # its error messages. On the cp932 console that kills the print. Degrade the
    # characters instead of the run -- the file name and line number, which are
    # what a reader needs, stay intact either way.
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(errors="replace")

    parser = argparse.ArgumentParser(
        description="Run the jq examples embedded in Markdown files."
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--json", help="path of an existing index.json")
    source.add_argument(
        "--export", help="specification folder to export to JSON before running"
    )
    parser.add_argument("files", nargs="+", help="Markdown files to scan")
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="print the first line of every command, not only the failures",
    )
    args = parser.parse_args()

    if shutil.which("bash") is None:
        raise SystemExit("bash is not on PATH. Run this from Git Bash.")
    if shutil.which("jq") is None:
        raise SystemExit("jq is not on PATH.")

    total = 0
    failures = []
    skipped_all = []

    with tempfile.TemporaryDirectory(prefix="verify-jq-") as temp:
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

            commands, skipped = extract(path)
            skipped_all.extend((path, line, why, text) for line, why, text in skipped)
            print("\n{0}  ({1} command(s))".format(path.as_posix(), len(commands)))

            for command in commands:
                resolved, reason = resolve(command.text, json_path)
                if resolved is None:
                    skipped_all.append((path, command.line_number, reason, command.text))
                    print("  SKIP  line {0}  {1}".format(command.line_number, reason))
                    continue

                total += 1
                try:
                    code, out, err = run(resolved, workdir)
                except subprocess.TimeoutExpired:
                    code, out, err = 1, "", "timed out after {0}s".format(
                        COMMAND_TIMEOUT_SECONDS
                    )

                count = len(out.splitlines())
                if code == 0:
                    if args.verbose:
                        print(
                            "  ok    line {0}  {1:4d} line(s)  {2}".format(
                                command.line_number, count, first_line(command.text)
                            )
                        )
                else:
                    failures.append((path, command.line_number, command.text, err))
                    print(
                        "  FAIL  line {0}  exit {1}  {2}".format(
                            command.line_number, code, first_line(command.text)
                        )
                    )

    print("\n" + "-" * 72)
    if skipped_all:
        print("Skipped {0} block(s) that are not self-contained:".format(len(skipped_all)))
        for path, line, why, text in skipped_all:
            print("  {0}:{1}  {2}".format(path.as_posix(), line, why))
            print("      {0}".format(first_line(text)))
        print("")

    if failures:
        print("FAIL: {0} of {1} command(s) failed\n".format(len(failures), total))
        for path, line, text, err in failures:
            print("  {0}:{1}".format(path.as_posix(), line))
            print("      {0}".format(first_line(text)))
            for message in err.strip().splitlines()[:3]:
                print("      | {0}".format(message))
        return 1

    print("PASS: {0} command(s) ran, 0 failed".format(total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
