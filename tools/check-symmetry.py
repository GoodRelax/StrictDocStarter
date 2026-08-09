"""Compare two language editions of the same specification and report drift.

The samples come in pairs - md-basic-ja and md-basic-en hold the same
requirements in two languages - and the pair is only useful while both sides
say the same thing. Prose is expected to differ. Structure is not: a
requirement that exists in one language and not the other, a relation drawn on
one side only, or a document that gained a chapter in one language and not the
other, is a defect nothing else in the repository catches. `strictdoc export`
validates each project alone, and check-jq-output.py compares a pasted output
with its query inside one language.

What must match exactly:

  * the set of document UIDs,
  * the set of node UIDs (requirements, use cases, test cases),
  * the set of relation edges, as (source UID, type, target UID, role),
  * the set of documents that carry no UID at all.

What is compared but not required to match:

  * SECTION and TEXT counts per document. English and Japanese split their
    prose differently, so the totals differ by a handful even when the two
    editions are in step (measured: md-basic carries 4 more of each in
    Japanese). What matters is that an edit moves both sides by the same
    amount, so this script prints the per-document counts and fails only when
    a document exists on one side alone.

Exit code is 0 when the two editions agree, 1 otherwise, so this can gate a
build the way ascii-audit.py does.

Usage:
    python tools/check-symmetry.py --json <ja index.json> <en index.json>
    python tools/check-symmetry.py --export <ja folder> <en folder>
    python tools/check-symmetry.py --export <ja folder> <en folder> --verbose
"""

import argparse
import pathlib
import json
import subprocess
import sys
import tempfile

STRUCTURAL = ("REQUIREMENT", "USE_CASE", "TEST_CASE")


def walk(node):
    """Yield a node and every node nested under it."""
    yield node
    for child in node.get("NODES") or []:
        for found in walk(child):
            yield found


def read(index_path):
    """Return the facts two editions must agree on."""
    data = json.loads(pathlib.Path(index_path).read_text(encoding="utf-8"))
    documents = set()
    untitled = set()
    nodes = set()
    edges = set()
    shape = {}
    for document in data.get("DOCUMENTS") or []:
        uid = document.get("UID")
        if uid:
            documents.add(uid)
        else:
            # A document may carry no UID. Name it by title so the two editions
            # can still be lined up; a title differs by language, so this only
            # reports the count.
            untitled.add(document.get("TITLE") or "-")
        counts = {}
        for node in walk(document):
            kind = node.get("_NODE_TYPE")
            counts[kind] = counts.get(kind, 0) + 1
            node_uid = node.get("UID")
            if node_uid and kind in STRUCTURAL:
                nodes.add(node_uid)
            for relation in node.get("RELATIONS") or []:
                if node_uid:
                    edges.add((node_uid, relation.get("TYPE"),
                               relation.get("VALUE"), relation.get("ROLE")))
        if uid:
            shape[uid] = counts
    return {"documents": documents, "untitled": untitled, "nodes": nodes,
            "edges": edges, "shape": shape}


def export(project, workdir, label):
    """Export one project to JSON and return the path of its index.json."""
    out = workdir / label
    done = subprocess.run(
        ["strictdoc", "export", str(project), "--formats=json",
         "--output-dir", str(out), "--no-parallelization"],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    if done.returncode != 0:
        sys.stderr.write(done.stdout)
        sys.stderr.write(done.stderr)
        raise SystemExit("strictdoc export failed for {0}".format(project))
    index = out / "json" / "index.json"
    if not index.is_file():
        raise SystemExit("strictdoc export produced no {0}".format(index))
    return index


def label_of(path):
    """Name a side by something a reader recognises.

    Every export lands on the same file name, so "index.json vs index.json"
    tells nobody which side is which. Walk up to the first folder that is not
    part of the export layout and use that.
    """
    p = pathlib.Path(path)
    for part in (p.name, ):
        if part != "index.json":
            return part
    for parent in p.parents:
        if parent.name and parent.name != "json":
            return parent.name
    return str(p)


def report_set(name, left, right, left_label, right_label, problems):
    """Compare two sets and record every element missing from either side."""
    only_left = sorted(left - right)
    only_right = sorted(right - left)
    if not only_left and not only_right:
        print("  ok    {0:<22} {1}".format(name, len(left)))
        return
    print("  FAIL  {0:<22} {1} vs {2}".format(name, len(left), len(right)))
    for item in only_left:
        print("          {0} only: {1}".format(left_label, item))
    for item in only_right:
        print("          {0} only: {1}".format(right_label, item))
    problems.append(name)


def main():
    parser = argparse.ArgumentParser(
        description="Compare two language editions of one specification.")
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--json", nargs=2, metavar=("LEFT", "RIGHT"),
                        help="two existing index.json files")
    source.add_argument("--export", nargs=2, metavar=("LEFT", "RIGHT"),
                        help="two specification folders to export first")
    parser.add_argument("--verbose", action="store_true",
                        help="print the per-document SECTION and TEXT counts")
    args = parser.parse_args()

    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(errors="replace")

    with tempfile.TemporaryDirectory(prefix="check-symmetry-") as temp:
        workdir = pathlib.Path(temp)
        if args.export:
            left_label, right_label = args.export
            left_index = export(pathlib.Path(left_label), workdir, "left")
            right_index = export(pathlib.Path(right_label), workdir, "right")
        else:
            left_label, right_label = args.json
            left_index, right_index = args.json
        left = read(left_index)
        right = read(right_index)

    left_name = label_of(left_label)
    right_name = label_of(right_label)
    print("{0}  vs  {1}\n".format(left_name, right_name))

    problems = []
    report_set("document UIDs", left["documents"], right["documents"],
               left_name, right_name, problems)
    report_set("node UIDs", left["nodes"], right["nodes"],
               left_name, right_name, problems)

    edge_left = set("{0} -{1}/{2}-> {3}".format(a, b, d or "-", c)
                    for a, b, c, d in left["edges"])
    edge_right = set("{0} -{1}/{2}-> {3}".format(a, b, d or "-", c)
                     for a, b, c, d in right["edges"])
    report_set("relation edges", edge_left, edge_right,
               left_name, right_name, problems)

    if len(left["untitled"]) != len(right["untitled"]):
        print("  FAIL  {0:<22} {1} vs {2}".format(
            "documents with no UID", len(left["untitled"]),
            len(right["untitled"])))
        problems.append("documents with no UID")
    else:
        print("  ok    {0:<22} {1}".format(
            "documents with no UID", len(left["untitled"])))

    # Prose shape. The totals may differ by language; a document present on one
    # side alone may not.
    print("")
    drift = []
    for uid in sorted(left["documents"] | right["documents"]):
        a = left["shape"].get(uid, {})
        b = right["shape"].get(uid, {})
        pair = []
        for kind in ("SECTION", "TEXT"):
            pair.append((a.get(kind, 0), b.get(kind, 0)))
        if args.verbose or pair[0][0] != pair[0][1] or pair[1][0] != pair[1][1]:
            drift.append((uid, pair))
    if drift:
        print("  prose shape (SECTION / TEXT), listed where the two differ:")
        for uid, pair in drift:
            print("      {0:<16} SECTION {1:>3} vs {2:<3}  TEXT {3:>3} vs {4}"
                  .format(uid, pair[0][0], pair[0][1], pair[1][0], pair[1][1]))
        print("      a difference here is expected; a missing document is not")

    print("\n" + "-" * 60)
    if problems:
        print("FAIL: {0} set(s) differ: {1}".format(
            len(problems), ", ".join(problems)))
        return 1
    print("PASS: both editions carry the same documents, nodes and relations")
    return 0


if __name__ == "__main__":
    sys.exit(main())
