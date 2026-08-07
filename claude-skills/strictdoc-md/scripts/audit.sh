#!/bin/sh
# audit.sh <specification folder> <output dir> [skip-uids] [figure-prefix]
#
# Runs every check the strictdoc-md skill knows about against an exported
# project. Zero rows on every check is a healthy project.
#
# Both exports must have run first:
#   strictdoc export <spec> --formats=json --output-dir <out>
#   strictdoc export <spec> --formats=html --output-dir <out>
#
# skip-uids     comma separated UIDs of documents that only explain notation
# figure-prefix UID prefix that marks a figure document (default DOC-FIG-)

SPEC="$1"
OUT="$2"
SKIP="${3:-}"
FIGPREFIX="${4:-DOC-FIG-}"

if [ -z "$SPEC" ] || [ -z "$OUT" ]; then
    echo "usage: audit.sh <specification folder> <output dir> [skip-uids] [figure-prefix]" >&2
    exit 2
fi

JSON="$OUT/json/index.json"
if [ ! -f "$JSON" ]; then
    echo "no JSON export at $JSON - run strictdoc export --formats=json first" >&2
    exit 2
fi

HTMLDIR="$OUT/html/$(basename "$SPEC")"
FAIL=0

report() {
    # report <label> <file-of-rows>
    if [ -s "$2" ]; then n=$(wc -l < "$2" | tr -d ' '); else n=0; fi
    if [ "$n" -eq 0 ]; then
        printf '  ok    %-28s 0\n' "$1"
    else
        printf '  FAIL  %-28s %d\n' "$1" "$n"
        sed 's/^/          /' "$2"
        FAIL=$((FAIL + 1))
    fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 1. A paragraph or table cell ending in "$" stops the HTML export.
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | (.STATEMENT? // "")
| split("\n")
| reduce .[] as $line ({open: 0, out: []};
    ([$line | scan("^`{3,}")] | (.[0] // "") | length) as $w
    | if $w > 0
      then (if .open == 0 then .open = $w elif $w >= .open then .open = 0 else . end)
      else (if .open == 0 then .out += [$line] else . end)
      end)
| .out[]
| select(test("[^$][$] *$") or test("[^$][$] *[|]"))
| $doc + "  " + .' "$JSON" > "$TMP/dollar"
report "trailing dollar" "$TMP/dollar"

# 2. A table row whose cell count differs from the header loses cells on render.
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | select(.STATEMENT?) as $n
| ($n.UID // $n._TOC // "-") as $at
| $n.STATEMENT | split("\n")
| reduce .[] as $line ({open: 0, want: 0, bad: []};
    ([$line | scan("^`{3,}")] | (.[0] // "") | length) as $w
    | if $w > 0
      then (if .open == 0 then .open = $w elif $w >= .open then .open = 0 else . end)
      elif .open > 0 then .
      elif ($line | startswith("|"))
      then ([$line | scan("[^\\\\][|]")] | length) as $c
           | if .want == 0 then .want = $c elif $c != .want then .bad += [$line] else . end
      else .want = 0
      end)
| .bad[]
| $doc + "  " + $at + "  " + .' "$JSON" > "$TMP/table"
report "broken table row" "$TMP/table"

# 3. An attachment that never reached the output 404s in the browser.
if [ -d "$HTMLDIR" ]; then
    jq -r --arg skip "$SKIP" '($skip | split(",")) as $s
    | .DOCUMENTS[] | select(.UID | IN($s[]) | not)
    | recurse(.NODES[]?) | (.STATEMENT? // "")
    | split("](") | .[1:][] | split(")")[0]
    | select(startswith("http") or startswith("#") | not)' "$JSON" 2>/dev/null \
      | tr -d '\r' | sort -u \
      | while read -r p; do
            [ -n "$p" ] && [ ! -f "$HTMLDIR/$p" ] && echo "$p"
        done > "$TMP/asset"
    report "attachment not published" "$TMP/asset"
else
    printf '  skip  %-28s (no HTML export)\n' "attachment not published"
fi

# 4. A figure past 15 lines belongs in its own document.
#    A document may carry no UID at all, so default it before startswith.
jq -r --arg figprefix "$FIGPREFIX" '.DOCUMENTS[] | select((.UID // "") | startswith($figprefix) | not)
| (.UID // .TITLE) as $doc
| recurse(.NODES[]?) | select(.STATEMENT?) as $n | $n.STATEMENT
| select(contains("```mermaid")) | split("```")[] | select(startswith("mermaid"))
| ltrimstr("mermaid") | split("\n") | map(rtrimstr("\r")) | map(select(. != "")) | length as $c
| select($c > 15) | $doc + "  " + ($n.UID // $n._TOC // "-") + "  " + ($c | tostring) + " lines"' \
  "$JSON" > "$TMP/figure"
report "oversized inline figure" "$TMP/figure"

# 5. A review that says something is wrong but never says what.
#    Only projects whose grammar declares REVIEW_STATUS have anything to find
#    here; everywhere else the query simply returns nothing.
jq -r '.DOCUMENTS[] | (.UID // .TITLE) as $doc
| recurse(.NODES[]?)
| select(.REVIEW_STATUS? and (.REVIEW_STATUS | IN("Open", "Fixed", "WontFix")))
| select((.REVIEW_COMMENT // "") == "")
| $doc + "  " + (.UID // ._TOC // "-") + "  " + .REVIEW_STATUS' \
  "$JSON" > "$TMP/review"
report "review comment missing" "$TMP/review"

# StrictDoc itself refuses to export a duplicate UID or a relation that points
# at a UID nobody defines, in the same document or across documents (measured).
# Checking for either here would be dead code, so this script does not.

echo ""
if [ "$FAIL" -eq 0 ]; then
    echo "all checks clean"
else
    echo "$FAIL check(s) found something"
fi
exit "$FAIL"
