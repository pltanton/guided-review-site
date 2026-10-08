source "$(dirname "$0")/lib.sh"

review_ready
gr step goto s5 >/dev/null
viewer
listen message
record
pause 2.5
key /
typing "int64(body"
key Enter Escape
pause 1.5
key Enter
pause 1
key Tab
pause 0.8
typing "this truncates, 19.99 comes out as 1998 cents."
key C-j
typing "round it instead"
pause 1.2
snap compose
key Enter
heard >/dev/null
thinking "writing the comment" 2
gr comment add --file internal/api/handler.go --lines 40 --severity major \
  --suggestion '		Amount: int64(math.Round(body.Amount * 100)),' \
  "\`int64(body.Amount * 100)\` truncates the float instead of rounding it.
19.99 becomes 1998 cents: every such transfer is a cent short." >/dev/null
listen message
say --option "yes, major" --option "no, fine as is" \
  "recorded: major, handler.go:40, with a suggestion.
Line 51 sends database errors back as 400 with their text. Comment on that too?"
pause 3
snap options
key 1
heard >/dev/null
thinking "writing the comment" 1.5
gr comment add --file internal/api/handler.go --lines 50-51 --severity major \
  "Database errors reach the client as 400 with the SQL text.
A lock timeout becomes a client error and leaks table names.
Keep 400 for validation errors, return 500 with a generic text for the rest." >/dev/null
listen message
say "recorded: major, handler.go:50–51. Two comments on this step."
pause 1.5
key C-d
pause 3.5
snap final
stop 1
