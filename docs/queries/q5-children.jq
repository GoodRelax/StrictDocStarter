# Q5. Children of one requirement.
#
#   jq -r -f docs/queries/q5-children.jq out/json/index.json
#
# The JSON stores parents only. Children are found by walking every node and
# keeping the ones whose Parent relation points back at the requirement.
# Tests and components match the same way, so add a ._NODE_TYPE test to narrow.
#
# The UID is written in because it names a node rather than a language.
# Change it to the requirement you want.
.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID)
| select((.RELATIONS? // []) | any(.TYPE=="Parent" and .VALUE=="SYS-001"))
| ._NODE_TYPE + "  " + .UID + "  " + (.TITLE // "")
