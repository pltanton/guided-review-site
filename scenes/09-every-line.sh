source "$(dirname "$0")/lib.sh"

review_ready
gr step goto s7 >/dev/null
viewer
listen message
record
pause 2.5
key /
typing "database at"
key Enter Escape
pause 3
snap wrapped
key W
pause 2
snap cut
key l l l l l l l l
pause 2.5
snap scrolled
key W
pause 1.5
key c
typing "the log line prints the database url, password included"
key Enter
heard >/dev/null
thinking "reading config.Load" 1.5
gr comment add --file cmd/ledger/main.go --lines 25 --severity major \
  "The startup log prints \`cfg.DatabaseURL\`, which carries the database password.
Log the host only, or drop the URL from the line." >/dev/null
listen message
say "recorded: major, main.go:25.
The URL comes from DATABASE_URL, so the password lands in every startup log."
pause 3
key t
pause 1
key k
pause 1
key y
pause 2.5
snap copied
key Escape
stop 1.5
