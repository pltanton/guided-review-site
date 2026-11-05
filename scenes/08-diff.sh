source "$(dirname "$0")/lib.sh"

review_ready
viewer
listen message
record
pause 2
goto_file validate.go
pause 1.5
key '}'
pause 1.5
snap moved-fold
key j
pause 0.6
key o
pause 1
key C-d
pause 2.5
snap fees-open
key C-u
pause 0.6
key o
pause 1
key '}'
pause 1
key s
pause 4
snap split
key s
pause 1.5
stop 1
