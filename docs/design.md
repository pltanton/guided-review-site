# guided-review-site — design

A one-page site at `guided-review.pltanton.dev` that sells guided-review's features with
terminal recordings made from a real `gr` on a fake merge request. Everything — the fake
repository, the recordings, the page, the CI — lives in this repository; guided-review
itself gets one workflow file and a link in its README.

## Goals

- The landing page shows each feature in action, not a description of it.
- Recordings are reproducible: one command locally, the same command in CI, same result.
- A release of guided-review rebuilds the site without anyone touching it.
- No docs section for now.

## Layout

```
fixture/ledger/base/     Go service before the change (accounts, transfers)
fixture/ledger/mr/       files the MR adds or changes, overlaid on base
fixture/ledger/round2/   the author's follow-up push, overlaid on mr
fixture/gh/gh            fake gh: answers the calls gr makes from JSON files
fixture/gh/*.json        PR description, review threads, author replies
fixture/build.sh         builds a git repo from the overlays: main, feature, feature after round 2
scenes/NN-name.sh        one recording each: agent actor + human keystrokes
scenes/lib.sh            shared helpers: tmux on its own socket, say/wait/keys with pauses
record.sh                builds the fixture, runs every scene under asciinema, writes casts/
site/index.html          the page; site/style.css; asciinema-player from jsDelivr
site/CNAME               guided-review.pltanton.dev
.github/workflows/site.yml
```

## The fake merge request

`ledger` — a small Go service moving money between accounts. The MR adds per-account
transfer limits, a migration for the limits table and retries around the debit. It is
around 500 changed lines across ~12 files so the plan has two or three chapters, and it
carries planted problems for hotspots and comments: a check-then-debit race, float
rounding of amounts, a migration that adds a column without a default on a large table,
a moved function and a large deletion. Round 2 fixes some of them and answers the
reviewer's threads, leaving one unaddressed.

The fixture is plain files, not a git history, so it is easy to edit; `build.sh` turns it
into a repository in a temp dir with an `origin` remote pointing at a bare copy.

## Fake gh

`gr` talks to GitHub only through `gh` (`internal/github/github.go`). A script named `gh`
first on `PATH` answers the three calls gr makes — `gh api` for the PR, `gh api graphql`
for review threads, `gh api user` — from the JSON files and fails loudly on anything else, so a new gh call in gr
shows up as a broken recording instead of a silent network request. The URL used is
`https://github.com/demo/ledger/pull/42`.

## Agent actor

No LLM runs. Each scene is a bash script that plays the agent with the same `gr` commands
the skill uses — `gr init`, `gr plan set`, `gr say`, `gr note add`, `gr note detail`,
`gr comment add`, `gr thread assess` — with prepared texts, and plays the human with
`tmux send-keys` into the `gr view` pane. The agent's side waits on `gr wait` exactly as
the skill does, so the viewer behaves as in a real run. Pauses are fixed in the script;
`--idle-time-limit` caps any stall.

## Scenes

150×40, so the viewer puts the chat in its side panel; one `.cast` each. Hero and rows,
text left and recording right:

1. **Plan** — chapters and steps appear, the first step opens with the agent's message and a ⚑.
2. **Conversation** — a remark in plain words becomes a comment with a severity; one-key answers.
3. **No rubber stamp** — the reminder about unseen lines and an undiscussed hotspot, a question, a blocker.
4. **Next round** — threads with the author's replies, resolve or keep open.
5. **Finish** — the publish screen: severity, edit, hand to the agent.

"Under the hood" carousel, advancing when a recording ends:

6. **Details** — `i` on a hotspot, the code it mentions, `1` opens it; `?` explains a line.
7. **LSP** — FLOW, hover, definition, callers, peeking into a caller.
8. **Reading the diff** — moved code, a folded deletion, split view.

## Recording

`record.sh` starts a tmux server on a private socket with a fixed size and no status
line, and runs `asciinema rec --headless --window-size 150x40 -c "tmux attach"` while the
scene script drives it. Checked on macOS without a TTY: headless recording of a
send-keys-driven TUI works. Needs `gr`, `tmux`, `asciinema` 3.x, `gopls`, `git`, `go`.

## Page

Plain HTML and CSS, no build step. English, matching the README. A hero with a one-line
pitch, the install line and scene 1 autoplaying; then one block per feature, text beside
its recording, which plays when scrolled into view; an install section at the bottom.
Light and dark themes. The player loads from jsDelivr.

## CI

`.github/workflows/site.yml` runs on `repository_dispatch` (type `gr-release`),
`workflow_dispatch` and pushes to `main` here. It checks out `pltanton/guided-review` at
the dispatched ref (default: latest tag), builds `gr`, installs tmux, asciinema and
gopls, runs `record.sh`, copies `casts/` into `site/` and deploys with
`actions/deploy-pages`. A scene that fails fails the build and the old site stays up.
Casts are not committed.

In guided-review, a workflow on tag push sends the dispatch with a fine-grained token
limited to this repository (Contents: write), stored as a secret there. The README gets
the site link.

## Domain

`site/CNAME` holds `guided-review.pltanton.dev`; DNS needs `CNAME guided-review →
pltanton.github.io`. Pages is set to deploy from Actions with HTTPS enforced.

## Out of scope

Docs pages, GIFs, GitLab in the demo, a live LLM in recordings.
