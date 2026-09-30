# guided-review-site — implementation plan

Spec: [design.md](design.md). Each task ends with a commit; a task is done when its check passes.

- [ ] **1. Fixture.** `fixture/ledger/{base,mr,round2}` — compiling Go (stdlib only, so gopls
      needs no downloads). `fixture/build.sh OUT` builds `OUT/ledger` (main, `feature/limits`
      = round 1, then round 2 on top) and `OUT/gh/*.json` with the real SHAs.
      Check: `go vet ./...` in each round; `git -C OUT/ledger log --all --oneline` shows 3 commits.
- [ ] **2. Fake gh.** `fixture/gh/gh` answers `api … repos/demo/ledger/pulls/42`,
      `api … graphql`, `api … user` from `$DEMO_GH/*.json` (round picked by `$DEMO_GH/round`),
      anything else exits 1 with the args on stderr.
      Check: `gr init https://github.com/demo/ledger/pull/42` in the built repo prints the review id.
- [ ] **3. Scene harness.** `scenes/lib.sh`: private tmux socket, fixed size, `gr view` window,
      `keys`, `type_slow`, `say`, `pause`, `await` (runs `gr wait` until the expected event).
      `record.sh [scene…]`: build fixture, per scene fresh HOME/cache, asciinema headless → `casts/`.
      Check: a smoke scene records a cast showing the viewer.
- [ ] **4. Plan file.** `scenes/plan.yaml` — the route the actor posts: chapters, steps,
      messages, hotspots, annotations with details, written against the fixture's line numbers.
      Check: `gr plan set` accepts it.
- [ ] **5. Scenes 1–6** per the spec, one script each; review every cast by playing it.
      Check: `asciinema play` of each looks right; total run under 10 min.
- [ ] **6. Page.** `site/index.html`, `site/style.css`, `site/CNAME`; player from jsDelivr,
      lazy start on scroll, light/dark. Check: served locally, looks right at desktop and phone width.
- [ ] **7. CI.** `.github/workflows/site.yml` (dispatch, manual, push) and the dispatch workflow
      for guided-review kept in `docs/dispatch.yml` until it is copied there.
      Check: `actionlint` clean; first real run after the repo exists.
