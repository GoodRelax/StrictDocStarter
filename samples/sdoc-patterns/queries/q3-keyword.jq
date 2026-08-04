# Q3. Requirements whose title or statement contains a keyword.
#
#   jq -r -f queries/q3-keyword.jq out/json/index.json
#
# To search every field instead of just these two, replace the concatenation
# with `[.. | strings] | join(" ")`.
.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(((.TITLE//"") + (.STATEMENT//"")) | contains("上書き"))
| .UID + "  " + .TITLE
