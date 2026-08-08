# Q4. Ancestors of one requirement, followed transitively.
#
#   jq -r -f docs/queries/q4-parents.jq out/json/index.json
#
# For direct parents only, this is enough:
#   select(.UID=="SW-002") | .RELATIONS[] | select(.TYPE=="Parent") | .VALUE
#
# The UID is written in because it names a node rather than a language.
# Change it to the requirement you want.
[ .DOCUMENTS[] | recurse(.NODES[]?) | select(._NODE_TYPE and .UID) ] as $all
| def parents($u):
    ($all[] | select(.UID == $u) | .RELATIONS? // [] | .[]
     | select(.TYPE=="Parent") | .VALUE) as $p
    | [$p], parents($p);
  [ parents("SW-002") ] | flatten | unique | .[]
