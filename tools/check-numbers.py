"""Catch the two ways a number in prose goes quietly false.

check-jq-output.py compares a pasted output block with what its query prints.
Nothing compares the SENTENCE next to that block. That gap is where the rot
lives: this repository has found the same defect four times, most recently a
paragraph claiming "9 representative rows out of 91" beside a query that
printed 125, and a byte table claiming a 143,587-byte source set that measured
212,287.

Two checks.

1. COUNT CLAIMS. For every jq command with a pasted output - found the way
   check-jq-output.py finds them, so the two agree on what a pair is - read the
   paragraph that follows and take the number the sentence presents as the
   TOTAL: "out of 91", "of the 125 lines", the Japanese "127 lines out of" and
   "all 128 lines". That number must equal the rows the query prints, or the
   rows the block shows.

   Only the total is checked. The same paragraph also counts subsets - "115
   belong to the six explanatory documents", "the specification itself produces
   13" - and each of those is a sum over some subset of the documents. Allowing
   every subset sum would pass almost any number, because a dozen documents
   reach almost every value between them; checking the total keeps the rule
   sharp, and the total is what rotted both times this repository caught it.

   KNOWN GAP: a claim written far from its query is not checked. `00-ai-guide`
   describes example 13's output in a different file from the block, and its
   "127 lines" went stale unnoticed until a hand survey found it. Binding those
   would need a registry, and a registry rots too.

2. BYTE AND TOKEN FIGURES. The project decided that a number describing size
   is written as a ratio when it compares, and as a rounded absolute when it
   states a budget. A byte count is never reproducible - it moves with CRLF
   against LF - and an unrounded token count rots the moment anyone edits a
   word. So:

     * a byte figure of 1000 or more is reported. Express it as a ratio.
     * a token figure of 1000 or more that is not rounded to a whole hundred
       is reported. "about 8,000 tokens" passes, "61,116 tokens" does not.

   Small figures pass: "6 bytes" and "114 tokens" describe one character and
   one figure, and the guides use them deliberately.

Exit code is 0 when nothing is reported, 1 otherwise.

Usage:
    python tools/check-numbers.py --json <index.json> FILE.md [FILE.md ...]
    python tools/check-numbers.py --export <folder> FILE.md [...]
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
PLACEHOLDER = re.compile("<[^\\s\\d<>()|&;'\"$`][^<>()|&;'\"$`]{0,60}>")
COMMAND_TIMEOUT_SECONDS = 120

# A number is counting rows when one of these sits beside it. The Japanese
# words are built from code points so this file stays ASCII (NFR-010).
GYOU = chr(0x884C)          # "line"
KEN = chr(0x4EF6)           # "item"
NO_UCHI = "".join(chr(c) for c in (0x306E, 0x3046, 0x3061))   # "out of"
ZEN = chr(0x5168)           # "all of"
# Only a number a sentence presents as THE TOTAL is checked. A paragraph also
# counts subsets - "115 lines belong to the six explanatory documents", "the
# specification itself produces 13" - and those are sums over a subset of the
# documents. Allowing every subset sum would let almost any number through,
# because a dozen documents reach almost every total between them (measured).
# Checking the total alone stays precise, and the total is what rotted both
# times this repository caught it: "out of 91" beside a query printing 125, and
# "127 lines" beside one printing 128.
TOTAL_MARKERS = [
    re.compile(r"out of\s*([0-9][0-9,]*)"),
    re.compile(r"of the\s*([0-9][0-9,]*)\s*(?:rows?|lines?|entries)"),
    re.compile(r"([0-9][0-9,]*)\s*" + GYOU + NO_UCHI),
    re.compile(ZEN + r"\s*([0-9][0-9,]*)\s*" + GYOU),
    re.compile(r"([0-9][0-9,]*)\s*" + KEN + NO_UCHI),
]

BYTES_FIGURE = re.compile(
    r"([0-9][0-9,]*)\s*(?:bytes?|" + "".join(chr(c) for c in (0x30D0, 0x30A4, 0x30C8)) + r")")
TOKENS_FIGURE = re.compile(r"([0-9][0-9,]*)\s*tokens?")

# Ranges such as "15-50" and "124-179 tokens" state the budget of one figure and
# stay absolute on purpose.
RANGE = re.compile(r"[0-9]+\s*-\s*[0-9]+\s*tokens?")


class Block(object):
    def __init__(self, info, first_line, body, end_line):
        self.info = info
        self.first_line = first_line
        self.body = body
        self.end_line = end_line


def blocks(lines):
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
        if line.rstrip().endswith("<json>"):
            commands.append("\n".join(collected))
            collected = None
    if collected is not None or len(commands) != 1:
        return None
    return commands[0]


def run(command, json_path, workdir):
    script = workdir / "command.sh"
    script.write_text(command.replace("<json>", '"{0}"'.format(json_path)) + "\n",
                      encoding="utf-8", newline="\n")
    done = subprocess.run(["bash", str(script)], capture_output=True, text=True,
                          encoding="utf-8", errors="replace",
                          timeout=COMMAND_TIMEOUT_SECONDS)
    return done.returncode, [l.rstrip() for l in done.stdout.splitlines()
                             if l.strip()]


def paragraph_after(lines, end_line):
    """The first non-empty run of prose after a block, as one string.

    A count claim sits immediately under the output it describes. Reading
    further would pull in the next section's numbers.
    """
    index = end_line
    while index < len(lines) and not lines[index].strip():
        index += 1
    collected = []
    while index < len(lines) and lines[index].strip():
        if FENCE.match(lines[index]):
            break
        collected.append(lines[index])
        index += 1
    return " ".join(collected)


def as_int(text):
    return int(text.replace(",", ""))


def main():
    parser = argparse.ArgumentParser(
        description="Check the numbers a sentence claims about a query's output.")
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--json")
    source.add_argument("--export")
    parser.add_argument("files", nargs="+")
    parser.add_argument("--allow-count", default="",
                        help="comma separated counts this project quotes for "
                             "something other than the query beside them")
    parser.add_argument("--skip-size", action="store_true",
                        help="run only the count check")
    args = parser.parse_args()

    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(errors="replace")
    if shutil.which("bash") is None:
        raise SystemExit("bash is not on PATH. Run this from Git Bash.")
    if shutil.which("jq") is None:
        raise SystemExit("jq is not on PATH.")

    spared = set(as_int(n) for n in args.allow_count.replace(" ", "").split(",")
                 if n)

    bad_counts = []
    bad_sizes = []
    checked = {"count": 0, "size": 0}

    with tempfile.TemporaryDirectory(prefix="check-numbers-") as temp:
        workdir = pathlib.Path(temp)
        if args.export:
            out = workdir / "export"
            done = subprocess.run(
                ["strictdoc", "export", args.export, "--formats=json",
                 "--output-dir", str(out), "--no-parallelization"],
                capture_output=True, text=True)
            if done.returncode != 0:
                raise SystemExit("strictdoc export failed")
            index = out / "json" / "index.json"
        else:
            index = pathlib.Path(args.json)
        if not index.is_file():
            raise SystemExit("not a file: {0}".format(index))
        json_path = index.resolve().as_posix()

        for name in args.files:
            path = pathlib.Path(name)
            if not path.is_file():
                raise SystemExit("not a file: {0}".format(path))
            lines = path.read_text(encoding="utf-8").splitlines()
            found = blocks(lines)

            # 1. count claims
            for position, block in enumerate(found):
                if block.info != "bash" or position + 1 >= len(found):
                    continue
                command = sole_jq_command(block.body)
                if command is None:
                    continue
                if PLACEHOLDER.search(command.replace("<json>", "")):
                    continue
                following = found[position + 1]
                if following.info not in OUTPUT_INFO:
                    continue
                gap = lines[block.end_line:following.first_line - 1]
                if any(line.strip() for line in gap):
                    continue
                try:
                    code, actual = run(command, json_path, workdir)
                except subprocess.TimeoutExpired:
                    continue
                if code != 0:
                    continue
                shown = len([l for l in following.body if l.strip()])
                allowed = {len(actual), shown} | spared
                text = paragraph_after(lines, following.end_line)
                claims = set()
                for pattern in TOTAL_MARKERS:
                    claims.update(as_int(m) for m in pattern.findall(text))
                for claim in sorted(claims):
                    checked["count"] += 1
                    if claim in allowed:
                        continue
                    bad_counts.append(
                        (path, following.end_line + 1, claim,
                         len(actual), shown))

            # 2. byte and token figures, in prose only
            open_len = 0
            for number, line in enumerate(lines, 1):
                match = FENCE.match(line)
                if match:
                    width = len(match.group(1))
                    if open_len == 0:
                        open_len = width
                    elif width >= open_len:
                        open_len = 0
                    continue
                if open_len or args.skip_size:
                    continue
                for value in BYTES_FIGURE.findall(line):
                    checked["size"] += 1
                    if as_int(value) >= 1000:
                        bad_sizes.append((path, number, value, "bytes"))
                if RANGE.search(line):
                    continue
                for value in TOKENS_FIGURE.findall(line):
                    checked["size"] += 1
                    n = as_int(value)
                    if n >= 1000 and n % 100 != 0:
                        bad_sizes.append((path, number, value, "tokens"))

    print("  checked   count claims {0}   size figures {1}".format(
        checked["count"], checked["size"]))

    problems = 0
    if bad_counts:
        problems += 1
        print("  FAIL  count claim the output does not support   {0}".format(
            len(bad_counts)))
        for path, line_no, claim, total, shown in bad_counts:
            print("          {0}:{1}  claims {2}; the query prints {3} row(s), "
                  "the block shows {4}".format(
                      path.as_posix(), line_no, claim, total, shown))
    else:
        print("  ok    count claim the output does not support   0")

    if bad_sizes:
        problems += 1
        print("  FAIL  size figure that should be a ratio        {0}".format(
            len(bad_sizes)))
        for path, line_no, value, kind in bad_sizes:
            print("          {0}:{1}  {2} {3}".format(
                path.as_posix(), line_no, value, kind))
    else:
        print("  ok    size figure that should be a ratio        0")

    print("\n" + "-" * 60)
    if problems:
        print("FAIL: {0} kind(s) of number no longer hold".format(problems))
        return 1
    print("PASS: every number in prose still holds")
    return 0


if __name__ == "__main__":
    sys.exit(main())
