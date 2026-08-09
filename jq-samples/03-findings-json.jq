# Review findings as JSON, for a program rather than for a person to read.
#
#   jq -f jq-samples\03-findings-json.jq exported-json\json\index.json
#
# Note there is no -r on that command line. -r flattens the result into plain
# text, which is what you want for a person and never what you want for a
# program.
#
# The outer [ ... ] collects the results, which arrive one at a time, into a
# single array. Without it the values are printed one after another and the
# output is not a JSON array.
#
# map({...}) keeps only those four fields. Delete that line to get every field
# of every reviewed node.
[ .DOCUMENTS[] | recurse(.NODES[]?) | select(.REVIEW_STATUS) ]
| map({UID, REVIEW_STATUS, REVIEW_COMMENT, TITLE})
