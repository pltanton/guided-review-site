source "$(dirname "$0")/lib.sh"

round1_published
gr init --id demo-ledger "$PR" >/dev/null
viewer
listen message
record
thinking "round 2: 1 new commit, 3 answered threads" 2
thinking "checking Kai's replies against the new code" 2.5
gr thread assess PRRT_race --propose resolve \
  "Fixed: Check runs inside InTx and SpentToday takes FOR UPDATE OF a, so a second transfer waits for the first." >/dev/null
gr thread assess PRRT_round --propose resolve \
  "Fixed: handler.go:41 rounds with math.Round; 19.99 becomes 1999." >/dev/null
gr thread assess PRRT_migration --propose open \
  --reply "Size is not the issue: ADD COLUMN … NOT NULL without a default fails on any non-empty table. Add DEFAULT 0." \
  "Not fixed: the migration is unchanged. The table size does not matter; Postgres rejects NOT NULL without a default as soon as there is one row." >/dev/null
gr plan set -f "$SCENES/plan-round2.yaml" >/dev/null
say "Threads: race and rounding fixed, I suggest resolving. Migration not fixed, I suggest keeping it open with a reply.
Press R to decide."
pause 4
snap round2
key R
pause 4
key a
pause 1.2
key j
pause 0.8
key a
pause 1.2
key j
pause 1.5
key a
pause 2.5
snap decided
key Escape
pause 2.5
snap back
stop 1
