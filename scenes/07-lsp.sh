source "$(dirname "$0")/lib.sh"

review_ready
viewer
listen message
record
pause 2
goto_file service.go
pause 0.5
key /
typing "Validate"
key Enter Escape
lsp_ready
pause 2.5
snap here
geometry
key w w
pause 0.8
key K
pause 3
snap hover
key Escape
pause 0.6
key g d
pause 3
snap definition
key g c
pause 6
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
