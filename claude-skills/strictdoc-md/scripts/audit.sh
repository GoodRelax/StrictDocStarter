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
#    map(rtrimstr("\r")) is load-bearing: StrictDoc keeps the CRLF of the source
#    file inside STATEMENT, so every line arrives ending in CR and the anchored
#    " *$" below can never match. Without it this check reported 0 rows on a
#    document whose HTML export died on that very line (measured).
jq -r '.DOCUMENTS[] | .UID as $doc | recurse(.NODES[]?) | (.STATEMENT? // "")
| split("\n") | map(rtrimstr("\r"))
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
| $n.STATEMENT | split("\n") | map(rtrimstr("\r"))
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

# 6. Wording candidates in specification prose.
#
#    These are CANDIDATES, not violations. A shell script cannot tell an
#    intended passive from an accidental one, and it cannot tell a transitive
#    verb missing its object from an intransitive one - that needs the verb's
#    valency, which is not in the text. What it can decide is which strings are
#    present. Everything reported here still needs a reader, or the AI prompt in
#    the skill, to judge intent.
#
#    Applies to any node carrying a STATEMENT, so it covers requirements at
#    every level - needs, requirements, design - not just top-level ones.
#
#    Two passes run, one per language, and each one carries the gate the other
#    lacks: 6a reads only statements that contain a Japanese character, 6b only
#    statements that contain none. Drop either gate and one language's patterns
#    fire on the other language's requirements - a plain English project has no
#    「こと。」 and no 「は」, so the Japanese pass flagged 2 of its 2
#    requirements (measured) - and since this script exits with the number of
#    failing checks, gating a build on it would then fail forever.
#
#    6a. Japanese.
#    ears-shape     the sentence does not end in the shall-form 「こと。」
#    ears-order     a condition marker sits after the subject; EARS puts the
#                   condition first. 「時」 counts only when a particle follows
#                   it (時に / 時は / 時、) and the character before it does not
#                   turn it into a noun - 同時 / 時刻 / 時間 / 24 時間 are not
#                   conditions, and counting them flagged 9 requirements of the
#                   SOVD sample that were fine (measured)
#    passive        される / された / られる appears
#    no-subject     no は before the first comma
#    negative       ない / ません appears. The EARS unwanted-behaviour pattern
#                   uses this legitimately, so expect rows here.
jq -r --arg skip "$SKIP" '($skip | split(",")) as $s
| .DOCUMENTS[] | select((.UID // "") | IN($s[]) | not) | (.UID // .TITLE) as $doc
| recurse(.NODES[]?)
| select(._NODE_TYPE == "REQUIREMENT" and .UID? and (.STATEMENT? // "") != "")
| . as $n | ($n.STATEMENT | gsub("\r"; "")) as $t
| select($t | test("[぀-ヿ一-鿿]"))
| [ (if ($t | test("こと。\\s*$") | not) then "ears-shape" else empty end),
    (if ($t | test("は、?[^。]*(もし|場合|とき|の間|[^同日瞬常一分秒何]時(に|は|、))")) then "ears-order" else empty end),
    (if ($t | test("される|された|されて|られる|られた")) then "passive" else empty end),
    (if ($t | test("^[^。]*は")     | not) then "no-subject" else empty end),
    (if ($t | test("ない|ません")) then "negative" else empty end) ] as $why
| select(($why | length) > 0)
| $doc + "  " + $n.UID + "  " + ($why | join(","))' \
  "$JSON" > "$TMP/wording"

#    6b. English.
#    ears-shape     the sentence carries no "shall". English EARS states a
#                   requirement with that one word
#    ears-order     a sentence opens with something other than WHEN / WHILE /
#                   IF / WHERE, yet one of those words appears later in it, so
#                   the condition sits behind the subject. The test runs per
#                   sentence: a statement whose second sentence legitimately
#                   opens with "If" was otherwise flagged for the first one
#                   (measured, 3 rows of the SOVD sample). The Japanese pass
#                   already scopes itself to one sentence with [^。]*
#    passive        a form of "be" followed by a past participle
#    negative       "shall not" / "must not" / "never" appears. The EARS
#                   unwanted-behaviour pattern uses this legitimately, so expect
#                   rows here. The two-word patterns match across whitespace: a
#                   .sdoc STATEMENT wraps, and a line break landing between
#                   "shall" and "not" hid the row on one sample and not the
#                   other (measured).
#
#    English carries no no-subject rule: an English sentence states its subject,
#    so the omission the Japanese rule looks for cannot happen.
jq -r --arg skip "$SKIP" '($skip | split(",")) as $s
| .DOCUMENTS[] | select((.UID // "") | IN($s[]) | not) | (.UID // .TITLE) as $doc
| recurse(.NODES[]?)
| select(._NODE_TYPE == "REQUIREMENT" and .UID? and (.STATEMENT? // "") != "")
| . as $n | ($n.STATEMENT | gsub("\r"; "")) as $t
| select($t | test("[぀-ヿ一-鿿]") | not)
| [ (if ($t | test("\\bshall\\b"; "i") | not) then "ears-shape" else empty end),
    (if ($t | gsub("\n"; " ") | split(". ")
         | map((test("^\\s*(when|while|if|where)\\b"; "i") | not)
               and test("\\b(when|while|if|where)\\b"; "i")) | any)
        then "ears-order" else empty end),
    (if ($t | test("\\b(is|are|was|were|be|been|being)\\s+([a-z]+ed|written|given|taken|shown|known|seen|done|made|held|kept|sent|put|left|built|thrown|drawn|chosen|driven|broken)\\b"; "i")) then "passive" else empty end),
    (if ($t | test("\\b(shall\\s+not|must\\s+not|never)\\b"; "i")) then "negative" else empty end) ] as $why
| select(($why | length) > 0)
| $doc + "  " + $n.UID + "  " + ($why | join(","))' \
  "$JSON" >> "$TMP/wording"
report "wording candidates" "$TMP/wording"

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
