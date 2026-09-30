source "$(dirname "$0")/lib.sh"

gr init --id demo-ledger "$PR" >/dev/null
viewer
record
thinking "reading the diff: 11 files, +216 −117" 2.5
thinking "planning: 3 chapters, 7 steps" 2.5
gr plan set -f "$SCENES/plan.yaml" >/dev/null
listen
snap planned
pause 4
key n
pause 1.5
key i
pause 5
snap detail
key Escape
pause 1
key n
pause 2
key i
pause 3
snap note
key Escape
stop 2
