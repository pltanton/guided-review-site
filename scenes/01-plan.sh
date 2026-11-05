source "$(dirname "$0")/lib.sh"

gr init --id demo-ledger "$PR" >/dev/null
viewer
record
pause 2
thinking "reading the diff: 11 files, +216 −117" 2.5
gr plan set -f "$SCENES/plan-files.yaml" >/dev/null
pause 1.5
key g g
pause 2
snap files
thinking "reading migration 002, store.go, limits.go" 2.5
thinking "reading service.go, handler.go" 2.5
gr plan set -f "$SCENES/plan-notes.yaml" >/dev/null
listen
pause 3
snap notes
key n
pause 1.5
key Enter
pause 5
snap detail
key Escape
pause 1
goto_file service.go
pause 1
key n
pause 2
key Enter
pause 3
snap risk
key Escape
stop 2
