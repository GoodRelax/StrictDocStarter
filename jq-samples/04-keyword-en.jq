# The requirements that carry the word "convert".
#
#   jq -r -f jq-samples\04-keyword-en.jq exported-json\json\index.json
#
# The search word sits inside this file. That is the point of the exercise.
#
# For an ASCII word it makes no practical difference whether you write it here
# or pass it with --arg on the command line: both routes agree. The difference
# arrives the moment the word is not ASCII. cmd.exe hands a non-ASCII argument
# to jq in the console code page, and on a Japanese Windows (cp932) the match
# then returns zero rows with no error and no warning. jq always reads a FILE
# as UTF-8, so a word written here matches whatever the console is set to.
# jq-samples\02-keyword-ja.jq is the same query with a Japanese word.
#
# To search for something else, rewrite "convert" below. contains() is case
# sensitive, so "Convert" and "convert" are different words to this filter.
.DOCUMENTS[] | recurse(.NODES[]?)
| select(._NODE_TYPE == "REQUIREMENT")
| select(((.TITLE // "") + (.STATEMENT // "")) | contains("convert"))
| .UID + "  " + .TITLE
