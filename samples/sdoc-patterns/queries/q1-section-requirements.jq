# Q1. Requirements belonging to a given section.
#
#   jq -r -f queries/q1-section-requirements.jq out/json/index.json
#
# The section prefix can be passed in instead of hard-coding it:
#
#   jq -r --arg sec "2. " -f queries/q1-section-requirements.jq out/json/index.json
#
# and then use `startswith($sec)` below.
.DOCUMENTS[] | recurse(.NODES[]?)
| select(._NODE_TYPE=="SECTION" and (.TITLE|startswith("2. ")))
| recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
| .UID + "  " + .TITLE
