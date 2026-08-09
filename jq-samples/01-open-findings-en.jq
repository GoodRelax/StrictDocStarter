# Open review findings, one line each.
#
#   jq -r -f jq-samples\01-open-findings-en.jq exported-json\json\index.json
#
# This file is written entirely in English ASCII. Nothing here depends on the
# console code page, so it behaves the same in cmd.exe, PowerShell and Git Bash.
#
# FINDING is not a StrictDoc built-in node type. It is declared in basic.sgra,
# which the md-basic-ja and sd-basic-ja samples share. Against a project with a
# stock grammar this filter returns nothing at all -- that is expected.
#
# Drop the RESOLUTION test to list every finding, open or not.
.DOCUMENTS[] | recurse(.NODES[]?)
| select(._NODE_TYPE == "FINDING" and .RESOLUTION == "Open")
| .UID + "  " + .SEVERITY + "  " + .TITLE
