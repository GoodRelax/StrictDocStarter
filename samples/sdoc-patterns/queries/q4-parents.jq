# Q4. Ancestors of one requirement, followed transitively.
#
#   jq -r -f queries/q4-parents.jq out/json/index.json
#
# For direct parents only, this is enough:
#   select(.UID=="PAT-003") | .RELATIONS[] | select(.TYPE=="Parent") | .VALUE
[ .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID) ] as $all
| def parents($u):
    ($all[] | select(.UID == $u) | .RELATIONS? // [] | .[]
     | select(.TYPE=="Parent") | .VALUE) as $p
    | [$p], parents($p);
  [ parents("PAT-003") ] | flatten | unique | .[]
