# Open review findings, one line each.
#
#   jq -r -f jq-samples\01-open-findings-en.jq exported-json\json\index.json
#
# This file is written entirely in English ASCII. Nothing here depends on the
# console code page, so it behaves the same in cmd.exe, PowerShell and Git Bash.
#
# REVIEW_STATUS is not a StrictDoc built-in field. It is declared in basic.sgra,
# which the md-basic and sd-basic samples share, and these samples carry it on
# the requirement itself rather than on a separate finding node. Against a
# project with a stock grammar this filter returns nothing -- that is expected.
#
# Change "Open" to "Fixed" or "WontFix" to list what someone already dealt with.
.DOCUMENTS[] | recurse(.NODES[]?)
| select(.REVIEW_STATUS == "Open")
| .UID + "  " + .REVIEW_STATUS + "  " + .TITLE
