source "$(dirname "$0")/lib.sh"

review_ready
gr step goto s4 >/dev/null
viewer
listen message
record
pause 2.5
key n
pause 1.5
key i
pause 5
snap detail
key 1
pause 3.5
snap code
key j j j j
pause 2
key Escape
pause 1.5
key Escape
pause 1
key n
pause 1
key a
pause 0.8
key Enter
listen message
pause 0.5
thinking "reading Service.Transfer and retry" 2
say "retry re-runs the whole InTx closure, so a failed attempt rolls back Debit, Credit and AddSpent together.
Only 40001 and 40P01 are retried; ErrInsufficientFunds and ErrExceeded return at once."
pause 5
snap explain
stop 1
