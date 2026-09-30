source "$(dirname "$0")/lib.sh"

review_ready
gr comment add --file migrations/002_daily_limits.sql --lines 1 --severity major \
  "\`NOT NULL\` without a default fails on a table that already has rows.
The first deploy stops on the ALTER.
Add \`DEFAULT 0\`: 0 already means no limit." >/dev/null
gr comment add --file internal/transfer/service.go --lines 32 --severity blocker \
  "\`limits.Check\` runs before the transaction, so two concurrent transfers both pass it.
Two transfers of 600 against a limit of 1000 send 1200.
Read the total inside \`InTx\` with \`FOR UPDATE\` on the account row." >/dev/null
gr comment add --file internal/api/handler.go --lines 40 --severity major \
  --suggestion '		Amount: int64(math.Round(body.Amount * 100)),' \
  "\`int64(body.Amount * 100)\` truncates the float instead of rounding it.
19.99 becomes 1998 cents: every such transfer is a cent short." >/dev/null
gr comment add --file internal/api/handler.go --lines 50-51 --severity major \
  "Database errors reach the client as 400 with the SQL text.
Keep 400 for validation errors, return 500 with a generic text for the rest." >/dev/null
gr comment add --file internal/transfer/service.go --lines 60 --severity minor \
  "Backoff is linear with no jitter: retries of a hot account collide again." >/dev/null
for s in s1 s2 s3 s4 s5 s6 s7; do gr step goto "$s" >/dev/null; gr step next >/dev/null 2>&1 || true; done
viewer
listen finished
record
thinking "checking the gate: 7/7 steps, 3/3 hotspots discussed" 2.5
gr prepare --verdict changes \
  --decisions "Limits must hold under concurrent transfers; amounts are rounded, never truncated." >/dev/null
say "Every step is reviewed. Verdict: changes requested, 1 blocker, 3 major, 1 minor.
Press P to see exactly what goes to the PR."
pause 3.5
key P
pause 3.5
snap preview
key j j j j
pause 1.5
key s
pause 2.5
snap severity
key P
heard >/dev/null
stop 0.2
