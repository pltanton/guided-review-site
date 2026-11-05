# guided-review-site

The page at https://guided-review.pltanton.dev and the terminal recordings on it.

    GR=/path/to/gr ./record.sh [01-plan …]   # needs tmux, asciinema 3, gopls, go
    cd site && ln -sfn ../casts casts && python3 -m http.server

`fixture/` is a small Go service with a fake pull request and a fake `gh`; `scenes/plan-*.yaml` are the parts the agent sends; `scenes/`
play the agent with real `gr` commands and the reviewer with tmux keys. CI records with
guided-review `main` (a release dispatch names its tag) and deploys to Pages; see [docs/design.md](docs/design.md).
