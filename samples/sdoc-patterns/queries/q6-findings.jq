# Q6. Review findings.
#
#   jq -r -f queries/q6-findings.jq out/json/index.json
#
# StrictDoc has no built-in "finding" concept. This filter assumes the custom
# FINDING node type declared in patterns.sgra; against a stock grammar it
# always returns nothing. Add `select(.RESOLUTION=="Open")` for open ones only.
.DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE=="FINDING")
| .UID + " [" + .SEVERITY + "/" + .RESOLUTION + "] -> "
+ ((.RELATIONS // []) | map(select(.ROLE=="Reviews") | .VALUE) | join(","))
+ "  " + .TITLE
