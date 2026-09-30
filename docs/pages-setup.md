# Putting the site on GitHub Pages

Brief for the agent helping Anton publish this repository. Ask before every step that
creates or changes something on GitHub or in DNS; Anton does the steps that need his
accounts himself.

## State

- This repository (`~/dev/guided-review-site`) exists only locally, branch `main`.
- The page is `site/`, recordings are built by `record.sh` (see README.md), CI is
  `.github/workflows/site.yml`: build `gr` from `pltanton/guided-review`, record, deploy.
- `site/CNAME` is `guided-review.pltanton.dev`.
- CI records `gr` at the latest `v*` tag of guided-review, else `main`. guided-review has no
  tags, and its `main` crashes on the demo (a removed blank line panics the viewer). The fix
  is on the local branch `fix/removed-blank-line` in `~/dev/guided-review-blank-line`, not
  pushed and not merged. Until it reaches `main`, run the workflow by hand with
  `ref: fix/removed-blank-line` after that branch is pushed — or wait for the merge.
- Another session is still changing `site/` and `scenes/`; pull its commits before pushing.

## Steps

1. Create the public repo `pltanton/guided-review-site` (`gh repo create`, no README) and
   push `main`.
2. Settings → Pages → Source: GitHub Actions.
3. DNS at the pltanton.dev provider: `CNAME guided-review → pltanton.github.io`.
   Then Settings → Pages → Custom domain `guided-review.pltanton.dev`, wait for the check,
   enable Enforce HTTPS. Verifying the domain for the account (Settings → Pages → Verified
   domains, a TXT record) protects it from takeover.
4. The first push runs `site.yml`. If guided-review `main` still has the crash, run it
   manually: Actions → site → Run workflow, ref `fix/removed-blank-line` (needs that branch
   pushed to guided-review).
5. Rebuild on guided-review releases: a fine-grained token with access to
   `guided-review-site` only, Contents: read and write, saved as the secret
   `SITE_DISPATCH_TOKEN` in `pltanton/guided-review`; copy `docs/dispatch.yml` there as
   `.github/workflows/site.yml`. After that, pushing a `v*` tag rebuilds the site.
6. Add the site link to guided-review's README.

## Checking

- The Actions run is green; its log shows `recording 01-plan` … `recording 08-diff`.
- https://guided-review.pltanton.dev opens over HTTPS, every recording plays, the
  carousel advances.
- If a scene fails in CI but works locally, the usual suspects are the locale
  (`LANG=C.UTF-8` is set in the workflow), gopls indexing slower than `lsp_ready` waits
  (60 s), and the palette check in `record.sh`.
