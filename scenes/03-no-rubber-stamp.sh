source "$(dirname "$0")/lib.sh"

review_ready
gr step goto s4 >/dev/null
viewer
listen ask
lsp_ready
record
pause 3
key '>'
pause 3
snap hotspot-reminder
key n
pause 1
key A
typing "can two transfers get past this check at the same time?"
key Enter
heard >/dev/null
thinking "reading Service.Transfer and store.SpentToday" 2.5
listen message
say "Yes. Check reads the total before InTx opens, and nothing locks the account row.
Two transfers of 600 against a limit of 1000 both read 0, both pass: 1200 leaves the account."
pause 4
snap answered
key c
typing "blocker: race, read the total inside the tx with FOR UPDATE"
key Enter
heard >/dev/null
thinking "writing the comment" 1.5
gr comment add --file internal/transfer/service.go --lines 32 --severity blocker \
  "\`limits.Check\` runs before the transaction, so two concurrent transfers both pass it.
Two transfers of 600 against a limit of 1000 send 1200.
Read the total inside \`InTx\` with \`FOR UPDATE\` on the account row." >/dev/null
listen message
say "recorded: blocker, service.go:32."
pause 1.5
key C-d
pause 3
snap commented
key '>'
pause 3
snap s5
stop 1
