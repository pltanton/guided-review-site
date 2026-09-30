#!/usr/bin/env bash
# record.sh [SCENE…] — builds the fixture and records each scene to casts/NAME.cast.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
out="$here/casts"
mkdir -p "$out"
gr=${GR:-$(command -v gr)}
command -v asciinema tmux gopls >/dev/null

scenes=("$@")
if [[ ${#scenes[@]} -eq 0 ]]; then
  for f in "$here"/scenes/[0-9]*.sh; do scenes+=("$(basename "$f" .sh)"); done
fi

for name in "${scenes[@]}"; do
  work=$(mktemp -d "${TMPDIR:-/tmp}/grdemo.XXXXXX")
  "$here/fixture/build.sh" "$work" >/dev/null
  ln -s "$gr" "$work/bin/gr"
  echo "recording $name"
  WORK="$work" CAST="$out/$name.cast" bash "$here/scenes/$name.sh"
  # The page frames casts in the viewer's dark palette; #A78BFA is its dark accent.
  if ! grep -q '167;139;250' "$out/$name.cast"; then
    echo "$name: not recorded in the dark palette" >&2
    echo "truecolor $(grep -o '38;2;' "$out/$name.cast" | wc -l), 256 $(grep -o '38;5;' "$out/$name.cast" | wc -l)" >&2
    cat "$work/diag" >&2 || true
    head -c 1500 "$out/$name.cast" >&2
    exit 1
  fi
  rm -rf "$work" /tmp/guided-review/demo-ledger
done
