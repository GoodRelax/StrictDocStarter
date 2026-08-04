# Q7. Requirements that were revised.
#
#   jq -r -f queries/q7-revised.jq out/json/index.json
#
# Also not a built-in concept: this assumes the REVISION field and the Revised
# status declared in patterns.sgra. To see the actual diff between two
# revisions, use StrictDoc's DIFF feature rather than a query -- add "DIFF" to
# project_features and pass --generate-diff-dirs or --generate-diff-git.
.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| select(.REVISION != null or .STATUS == "Revised")
| .UID + " (" + (.STATUS // "-") + ")  " + .TITLE
