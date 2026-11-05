source "$(dirname "$0")/lib.sh"

review_ready
viewer
listen ask
record
pause 2
goto_file service.go
pause 1.5
key P
pause 4
snap finish-card
key Escape
pause 1
key n
pause 1.5
key a
typing "can two transfers get past this check at the same time?"
key Enter
heard >/dev/null
thinking "reading Service.Transfer and store.SpentToday" 2.5
listen message
say "Yes. Check reads the total before InTx opens, and nothing locks the account row.
Two transfers of 600 against a limit of 1000 both read 0, both pass: 1200 leaves the account."
pause 4
snap answered
key k
pause 0.6
key Enter
pause 0.8
key Tab
pause 0.8
typing "blocker: race, read the total inside the tx with FOR UPDATE"
key Enter
heard >/dev/null
thinking "writing the comment" 1.5
gr comment add --file internal/transfer/service.go --lines 32 --severity blocker \
  "\`limits.Check\` runs before the transaction, so two concurrent transfers both pass it.
Two transfers of 600 against a limit of 1000 send 1200.
Read the total inside \`InTx\` with \`FOR UPDATE\` on the account row." >/dev/null
listen message
say "recorded: blocker, service.go:32. That checks the risk off."
pause 2
key C-d
pause 3
snap commented
key P
pause 4
snap finish-card-again
key Escape
stop 1
