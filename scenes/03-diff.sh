source "$(dirname "$0")/lib.sh"

review_ready
gr step goto s7 >/dev/null
viewer
listen message
lsp_ready
record
pause 3
key /
typing "func Validate"
key Enter Escape
pause 1
key w
pause 0.5
key g c
pause 3
snap callers
key Escape
pause 1
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
key /
typing "NewChecker"
key Enter Escape
pause 0.8
key w w w w w
pause 0.5
key g d
pause 3.5
snap definition
key Escape
stop 1
