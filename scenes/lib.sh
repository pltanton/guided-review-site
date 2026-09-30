# Sourced by every scene. Plays the agent with gr commands and the human with tmux keys.
set -euo pipefail

: "${WORK:?}" "${CAST:?}"
SCENES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COLS=140 ROWS=40
SOCK="grdemo-$$"
PR=https://github.com/demo/ledger/pull/42

export HOME="$WORK/home" DEMO_GH="$WORK/gh"
export PATH="$WORK/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache"
export COLORTERM=truecolor LANG=en_US.UTF-8
mkdir -p "$HOME"
cd "$WORK/ledger"

t() { tmux -L "$SOCK" -f /dev/null "$@"; }
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
  asciinema rec --headless --overwrite --window-size "${COLS}x${ROWS}" --idle-time-limit 2 \
    -c "tmux -L $SOCK -f /dev/null attach -t demo" "$CAST" >/dev/null &
  recorder=$!
  sleep 1
}

stop() {
  sleep "${1:-1.5}"
  t kill-server 2>/dev/null || true
  wait "$recorder" 2>/dev/null || true
  recorder=""
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
