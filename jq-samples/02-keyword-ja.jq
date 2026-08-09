# 「変換」という語を含む要求を探す。
#
#   jq -r -f jq-samples\02-keyword-ja.jq exported-json\json\index.json
#
# 検索語をこのファイルの中に直接書いている。 これが肝である。
#
# 同じ語をコマンド行から --arg で渡すと、 cmd.exe の既定 (cp932) では
# エラーも出ずに 0 件になる。 chcp 65001 を先に打てば通るが、 打ち忘れた人は
# 「1 件も無い」という誤った答えを受け取る。 実測で確かめてある。
#
# ファイルの中に書けば、 jq が UTF-8 として読むので文字コードの影響を受けない。
# cp932 のままでも正しく一致する。 これも実測済みである。
#
# 探す語を変えるなら、 下の "変換" を書き換える。
.DOCUMENTS[] | recurse(.NODES[]?)
| select(._NODE_TYPE == "REQUIREMENT")
| select(((.TITLE // "") + (.STATEMENT // "")) | contains("変換"))
| .UID + "  " + .TITLE
