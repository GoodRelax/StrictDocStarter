"""Check that the packaged skill still says what the worked example says.

`claude-skills/strictdoc-md/` is a distilled copy of the English sample's
guide. Two copies of anything drift, and this pair drifts silently: the skill
exports nothing, so `strictdoc export` never reads it, and the sample can gain
a query or lose a rule without anything noticing.

Three checks, all exact. None of them reads prose - prose is meant to differ,
because the skill is a distillation rather than a duplicate.

  1. QUERIES. Every jq command in the guide must appear in the skill's
     queries.md, compared with whitespace collapsed so a different line wrap is
     not a difference. The skill may carry more; it may not carry less.

  2. RULE TABLES. The tables that decide whether an export succeeds must hold
     the same rows on both sides, compared by their first column.

  3. THE TWO COPIES. `claude-skills/strictdoc-md` is the published copy and
     `.claude/skills/strictdoc-md` is the working one. They are kept in step by
     hand, so every handoff has ended with a manual `diff -r`. This does it.

Exit code is 0 when the skill is in step, 1 otherwise.

Usage:
    python tools/check-skill-sync.py
    python tools/check-skill-sync.py --guide samples/md-basic-en --skill claude-skills/strictdoc-md
"""

import argparse
import filecmp
import pathlib
import re
import sys

FENCE_OPEN = re.compile(r"^ {0,4}(`{3,})bash\s*$")
# Tables that decide whether an export succeeds. Each entry is the heading to
# find in the guide and the heading to find in the skill file.
RULE_TABLES = [
    ("Rules that stop the whole export", "authoring.md",
     "Rules that stop the whole export"),
]


def commands_in(path):
    """Every jq command that ends in the <json> placeholder."""
    lines = path.read_text(encoding="utf-8").splitlines()
    found = []
    index = 0
    while index < len(lines):
        match = FENCE_OPEN.match(lines[index])
        if not match:
            index += 1
            continue
        closing = re.compile(r"^ {0,4}`{" + str(len(match.group(1))) + r",}\s*$")
        scan = index + 1
        collected = None
        while scan < len(lines) and not closing.match(lines[scan]):
            line = lines[scan]
            if collected is None:
                if line.strip().startswith("jq "):
                    collected = [line]
            else:
                collected.append(line)
            if collected is not None and line.rstrip().endswith("<json>"):
                found.append(" ".join("\n".join(collected).split()))
                collected = None
            scan += 1
        index = scan + 1
    return found


def first_table(path, heading):
    """The rows of the first pipe table under a heading, keyed by column one."""
    lines = path.read_text(encoding="utf-8").splitlines()
    start = None
    for number, line in enumerate(lines):
        if line.lstrip().startswith("#") and heading in line:
            start = number
            break
    if start is None:
        return None
    rows = []
    seen = False
    for line in lines[start + 1:]:
        if line.startswith("|"):
            seen = True
            if set(line.replace("|", "").strip()) <= set("-: "):
                continue
            cell = line.split("|")[1]
            rows.append(re.sub(r"[`*]", "", cell).strip().lower())
        elif seen and not line.strip():
            break
    return rows


def main():
    parser = argparse.ArgumentParser(
        description="Check the packaged skill against the worked example.")
    parser.add_argument("--guide", default="samples/md-basic-en",
                        help="the sample the skill is distilled from")
    parser.add_argument("--skill", default="claude-skills/strictdoc-md",
                        help="the published copy of the skill")
    parser.add_argument("--working", default=".claude/skills/strictdoc-md",
                        help="the working copy that must match it")
    args = parser.parse_args()

    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(errors="replace")

    guide = pathlib.Path(args.guide)
    skill = pathlib.Path(args.skill)
    working = pathlib.Path(args.working)
    for folder in (guide, skill):
        if not folder.is_dir():
            raise SystemExit("not a folder: {0}".format(folder))

    problems = []

    # 1. queries
    sample_queries = []
    for name in ("00-ai-guide.md", "01-ai-queries.md"):
        path = guide / name
        if path.is_file():
            sample_queries.extend(commands_in(path))
    skill_queries = set(commands_in(skill / "references" / "queries.md"))
    missing = [q for q in dict.fromkeys(sample_queries) if q not in skill_queries]
    if missing:
        problems.append("queries")
        print("  FAIL  query in the guide but not in the skill   {0}".format(
            len(missing)))
        for query in missing:
            print("          {0}".format(query[:100]))
    else:
        print("  ok    query in the guide but not in the skill   0  "
              "({0} in the guide, {1} in the skill)".format(
                  len(set(sample_queries)), len(skill_queries)))

    # 2. rule tables
    drift = 0
    for heading, skill_file, skill_heading in RULE_TABLES:
        left = first_table(guide / "00-ai-guide.md", heading)
        right = first_table(skill / "references" / skill_file, skill_heading)
        if left is None or right is None:
            problems.append("rule table")
            print("  FAIL  rule table not found                     "
                  "{0}".format(heading))
            drift += 1
            continue
        only_guide = [r for r in left if r not in right]
        only_skill = [r for r in right if r not in left]
        if only_guide or only_skill:
            problems.append("rule table")
            drift += 1
            print("  FAIL  rule table differs                       {0}".format(
                heading))
            for row in only_guide:
                print("          guide only: {0}".format(row[:80]))
            for row in only_skill:
                print("          skill only: {0}".format(row[:80]))
    if not drift:
        print("  ok    rule tables agree                        "
              "{0} table(s)".format(len(RULE_TABLES)))

    # 3. the two copies
    if not working.is_dir():
        print("  skip  the two copies match                     "
              "(no {0})".format(working))
    else:
        differing = []
        published = {p.relative_to(skill).as_posix()
                     for p in skill.rglob("*") if p.is_file()}
        checked_out = {p.relative_to(working).as_posix()
                       for p in working.rglob("*") if p.is_file()}
        for name in sorted(published | checked_out):
            a, b = skill / name, working / name
            if not a.is_file() or not b.is_file():
                differing.append("{0} (only one copy has it)".format(name))
            elif not filecmp.cmp(a, b, shallow=False):
                differing.append(name)
        if differing:
            problems.append("copies")
            print("  FAIL  the two copies match                     {0}".format(
                len(differing)))
            for name in differing:
                print("          {0}".format(name))
        else:
            print("  ok    the two copies match                     "
                  "{0} file(s)".format(len(published)))

    print("\n" + "-" * 60)
    if problems:
        print("FAIL: the skill is out of step ({0})".format(
            ", ".join(sorted(set(problems)))))
        return 1
    print("PASS: the skill is in step with the worked example")
    return 0


if __name__ == "__main__":
    sys.exit(main())
