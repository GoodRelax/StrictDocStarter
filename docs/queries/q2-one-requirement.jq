# Q2. Every field of one requirement, by UID.
#
#   jq -f docs/queries/q2-one-requirement.jq out/json/index.json
#
# `first(...)` stops the search at the first hit. `del(.NODES)` drops the
# children so the same filter also works when the UID names a section.
#
# The UID is written in because it names a node rather than a language.
# Change it to the requirement you want.
first(.DOCUMENTS[] | recurse(.NODES[]?) | select(.UID? == "SW-002"))
| del(.NODES)
