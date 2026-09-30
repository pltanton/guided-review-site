source "$(dirname "$0")/lib.sh"

review_ready
gr step goto s7 >/dev/null
viewer
listen message
lsp_ready
record
pause 3
key '}'
pause 1.5
snap moved-fold
key '}'
pause 0.6
key j
pause 0.6
key o
pause 1
key C-d
pause 2.5
snap fees-open
key C-u
pause 0.6
key o
pause 1
key '}'
pause 1
key s
pause 4
snap split
key s
pause 1.5
stop 1
