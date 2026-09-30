# Sourced by every scene. Plays the agent with gr commands and the human with tmux keys.
set -euo pipefail

: "${WORK:?}" "${CAST:?}"
SCENES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COLS=150 ROWS=40
SOCK="grdemo-$$"
PR=https://github.com/demo/ledger/pull/42

export HOME="$WORK/home" DEMO_GH="$WORK/gh"
export PATH="$WORK/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache"
export COLORTERM=truecolor LANG=${LANG:-en_US.UTF-8} TERM=${TERM:-xterm-256color}
mkdir -p "$HOME"
cd "$WORK/ledger"

t() { tmux -u -L "$SOCK" -f /dev/null "$@"; }
listener=""
recorder=""
(sleep 240; echo "scene timed out" >&2; kill -TERM $$) </dev/null >/dev/null 2>&1 &
watchdog=$!

cleanup() {
  kill "$watchdog" 2>/dev/null || true
  [[ -n $listener ]] && { pkill -P "$listener"; kill "$listener"; } 2>/dev/null || true
  t kill-server 2>/dev/null || true
  [[ -n $recorder ]] && wait "$recorder" 2>/dev/null || true
}
trap cleanup EXIT

pause() { sleep "$1"; }

# Off camera: what the agent did before the human looks — init and the plan.
review_ready() {
  gr init --id demo-ledger "$PR" >/dev/null
  gr plan set -f "$SCENES/plan.yaml" >/dev/null
}

viewer() {
  t new-session -d -s demo -x "$COLS" -y "$ROWS" -c "$PWD" \
    -e HOME -e PATH -e DEMO_GH -e XDG_CONFIG_HOME -e XDG_CACHE_HOME -e COLORTERM -e LANG \
    "gr view; sleep 3600"
  t set -g status off
  t set -g escape-time 0
}

record() {
  asciinema rec --headless --overwrite --output-format asciicast-v2 --window-size "${COLS}x${ROWS}" --idle-time-limit 2 \
    -c "tmux -u -L $SOCK -f /dev/null attach -t demo" "$CAST" >/dev/null &
  recorder=$!
  sleep 1
}

stop() {
  sleep "${1:-1.5}"
  t kill-server 2>/dev/null || true
  wait "$recorder" 2>/dev/null || true
  recorder=""
  grep -v 'server exited' "$CAST" >"$CAST.tmp" && mv "$CAST.tmp" "$CAST"
}

# The human.
key() {
  for k in "$@"; do t send-keys -t demo "$k"; sleep 0.35; done
}
typing() {
  local text=$1 i
  for ((i = 0; i < ${#text}; i++)); do
    t send-keys -t demo -l "${text:i:1}"
    sleep 0.035
  done
  sleep 0.4
}

# The agent: listen in the background like the skill's gr wait, until an event of KIND arrives.
listen() {
  local kind=${1:-message}
  : >"$WORK/heard"
  (until grep -q "^\[$kind\]" "$WORK/heard"; do gr wait --timeout 5m >>"$WORK/heard"; done) </dev/null >/dev/null 2>&1 &
  listener=$!
}
heard() {
  wait "$listener"
  listener=""
  cat "$WORK/heard"
}
thinking() { gr progress "$1"; sleep "${2:-1.5}"; }
say() { gr say "$@"; }

screen() { t capture-pane -p -t demo; }
snap() { [[ -n ${SNAP:-} ]] && { echo "--- $1"; screen; } >&2 || true; }
# Blocks until the language server answered: FLOW shows up once gopls has indexed the step.
lsp_ready() {
  local i
  for ((i = 0; i < 120; i++)); do
    screen | grep -q ' FLOW ' && return 0
    sleep 0.5
  done
  echo "gopls did not answer" >&2
  return 1
}

# Off camera: round 1 reviewed and published, then Kai answers and pushes round 2.
round1_published() {
  review_ready
  gr comment add --file internal/transfer/service.go --lines 32 --severity blocker \
    "\`limits.Check\` runs before the transaction, so two concurrent transfers both pass it." >/dev/null
  gr comment add --file internal/api/handler.go --lines 40 --severity major \
    "\`int64(body.Amount * 100)\` truncates the float instead of rounding it." >/dev/null
  gr comment add --file migrations/002_daily_limits.sql --lines 1 --severity major \
    "\`NOT NULL\` without a default fails on a table that already has rows." >/dev/null
  local s
  for s in s1 s2 s3 s4 s5 s6 s7; do gr step goto "$s" >/dev/null; gr step next >/dev/null 2>&1 || true; done
  gr prepare --verdict changes --decisions "Limits must hold under concurrent transfers." >/dev/null
  gr export >/dev/null
  gr mark-published >/dev/null
  echo 2 >"$DEMO_GH/round"
}
geometry() { [[ -n ${SNAP:-} ]] && t display -p -t demo 'window #{window_width}x#{window_height} pane #{pane_width}x#{pane_height} client #{client_width}x#{client_height}' >&2 || true; }
