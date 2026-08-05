"""Report non-ASCII characters in code and configuration files (NFR-010).

Everything that is not a user-authored document has to be English ASCII,
comments and console messages included. The launcher runs on a cp932 console,
where a non-ASCII byte in a message turns into mojibake and, in the worst case,
kills the process that printed it. Keeping the sources ASCII removes the whole
class of problem.

Documents are exempt on purpose: .sdoc and .md are what the user writes and
translates, and the specs under docs/ are documents too.

Usage:
    python tools/ascii-audit.py [path]

Exit code is 0 when everything is clean, 1 otherwise, so it can gate a build.
"""

import pathlib
import sys
import unicodedata
from collections import Counter

PATTERNS = ("*.bat", "*.ps1", "*.psm1", "*.js", "*.json", "*.py", "*.sgra", "*.svg", "*.css")
SKIP_DIRS = {
    ".git",
    ".venv",
    "__pycache__",
    "node_modules",
    "output",
    "temp",
    "venv",
}


def audit(root: pathlib.Path) -> list:
    findings = []
    for pattern in PATTERNS:
        for path in sorted(root.rglob(pattern)):
            if SKIP_DIRS & set(path.relative_to(root).parts):
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                findings.append((path.relative_to(root).as_posix(), -1, "not valid UTF-8"))
                continue
            offenders = Counter(char for char in text if ord(char) > 127)
            if not offenders:
                continue
            sample = ", ".join(
                "{0!r} ({1})".format(char, unicodedata.name(char, "U+%04X" % ord(char)))
                for char, _ in offenders.most_common(4)
            )
            findings.append(
                (path.relative_to(root).as_posix(), sum(offenders.values()), sample)
            )
    return findings


def main() -> int:
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    findings = audit(root)
    if not findings:
        print("PASS: every scanned code and configuration file is pure ASCII")
        return 0

    print("FAIL: {0} file(s) contain non-ASCII characters\n".format(len(findings)))
    for name, count, sample in findings:
        suffix = "" if count < 0 else " ({0} characters)".format(count)
        print("  {0}{1}".format(name, suffix))
        print("      {0}".format(sample[:160]))
    print("\nSee NFR-010 in docs/serve-spec.md.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
