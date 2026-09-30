#!/usr/bin/env bash
# build.sh OUT — OUT/ledger (git repo with origin), OUT/gh (fake gh answers), OUT/bin/gh.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
out=$(mkdir -p "$1" && cd "$1" && pwd)
rm -rf "${out:?}/ledger" "$out/origin.git" "$out/gh" "$out/bin"
mkdir -p "$out/ledger" "$out/gh" "$out/bin"
cp "$here/gh/gh" "$out/bin/gh"

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=Kai GIT_AUTHOR_EMAIL=kai@example.com
export GIT_COMMITTER_NAME=Kai GIT_COMMITTER_EMAIL=kai@example.com
git_() { git -C "$out/ledger" -c init.defaultBranch=main "$@"; }
commit() {
  export GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1"
  git_ add -A && git_ commit -q -m "$2"
}
overlay() {
  cp -R "$here/ledger/$1/." "$out/ledger/"
  if [[ -f "$out/ledger/.deleted" ]]; then
    while read -r p; do git_ rm -q -r "$p"; done < "$out/ledger/.deleted"
    rm "$out/ledger/.deleted"
  fi
}

git_ init -q
cp -R "$here/ledger/base/." "$out/ledger/"
commit "2026-09-01T10:00:00Z" "ledger: accounts and transfers"
git_ checkout -q -b feature/limits
overlay mr
commit "2026-09-22T14:30:00Z" "limits: per-account daily transfer limits"
git_ tag round1
overlay round2
commit "2026-09-24T11:05:00Z" "limits: check inside the transaction, round amounts"
git_ tag round2
git_ checkout -q main
git clone -q --bare "$out/ledger" "$out/origin.git"
git_ remote add origin "$out/origin.git"
git_ fetch -q origin

base=$(git_ rev-parse main)
for round in 1 2; do
  head=$(git_ rev-parse "round$round")
  cat > "$out/gh/pr-$round.json" <<JSON
{"title":"Daily transfer limits per account","html_url":"https://github.com/demo/ledger/pull/42",
 "head":{"ref":"feature/limits","sha":"$head"},"base":{"sha":"$base"}}
JSON
  sed "s/@HEAD@/$head/g" "$here/gh/threads-$round.json" > "$out/gh/threads-$round.json"
done
echo 1 > "$out/gh/round"
