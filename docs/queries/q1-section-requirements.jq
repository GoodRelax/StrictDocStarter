# Q1. Requirements belonging to a given section.
#
#   jq -r --arg sec <section title> -f docs/queries/q1-section-requirements.jq out/json/index.json
#
# The section is passed in rather than written here, so this file stays ASCII
# and works against a project in any language. Run it without --arg and it
# prints the usage line instead of failing.
#
# The match is a prefix, so a numbered heading can be selected with its number
# alone: --arg sec "2. ".
($ARGS.named.sec // "") as $sec
| if $sec == "" then
    "usage: jq -r --arg sec <section title> -f docs/queries/q1-section-requirements.jq out/json/index.json"
  else
    .DOCUMENTS[] | recurse(.NODES[]?)
    | select(._NODE_TYPE=="SECTION" and (.TITLE|startswith($sec)))
    | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
    | .UID + "  " + .TITLE
  end
