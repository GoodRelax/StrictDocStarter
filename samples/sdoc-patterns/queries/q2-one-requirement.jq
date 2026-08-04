# Q2. Every field of one requirement, by UID.
#
#   jq -f queries/q2-one-requirement.jq out/json/index.json
#
# `first(...)` stops the search at the first hit. `del(.NODES)` drops the
# children so the same filter also works when the UID names a section.
first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "PAT-003"))
| del(.NODES)
