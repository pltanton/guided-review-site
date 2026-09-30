source "$(dirname "$0")/lib.sh"

review_ready
gr step goto s4 >/dev/null
viewer
listen message
lsp_ready
record
pause 3.5
snap flow
geometry
key /
typing "Validate"
key Enter Escape
pause 0.6
key w w
pause 0.8
key K
pause 3
snap hover
key Escape
pause 0.6
key g d
pause 2.5
snap definition
key w
pause 0.6
key g c
pause 3
snap callers
key Enter
pause 3
snap caller-peek
key Escape
pause 1
key Escape
pause 1
key Escape
pause 1.5
stop 1
