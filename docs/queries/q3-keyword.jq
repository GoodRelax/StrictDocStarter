# Q3. Requirements whose title or statement contain a keyword.
#
#   jq -r --arg kw <keyword> -f queries/q3-keyword.jq out/json/index.json
#
# The keyword is passed in rather than written here, so this file stays ASCII
# and works against a project in any language. Run it without --arg and it
# prints the usage line instead of failing.
#
# To search every field instead of just these two, replace the concatenation
# with `[.. | strings] | join(" ")`.
($ARGS.named.kw // "") as $kw
| if $kw == "" then
    "usage: jq -r --arg kw <keyword> -f queries/q3-keyword.jq out/json/index.json"
  else
    .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="REQUIREMENT")
    | select(((.TITLE//"") + (.STATEMENT//"")) | contains($kw))
    | .UID + "  " + .TITLE
  end
