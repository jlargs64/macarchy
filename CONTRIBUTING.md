# Contributing

macarchy is one person's config, published as is. Bug reports and theme
ports are welcome. Requests to support other terminals, editors or browsers
are out of scope; see [Scope](README.md#scope).

## Issues

Pick a template. Every new issue starts as `status: needs triage`.

| Label | Meaning |
|---|---|
| `status: needs info` | Waiting on you. Reply and it goes back to triage automatically. No reply for 21 days and it closes. |
| `status: accepted` | In scope and confirmed. A PR is welcome. |
| `status: blocked` | Waiting on yabai, SketchyBar, Ghostty or macOS. |
| `resolution: *` | Why it closed without a change. |

Labels live in [.github/labels.yml](.github/labels.yml). Edit that file, not
the GitHub UI; the Labels workflow deletes anything not in it.

## Commits and PR titles

Use [Conventional Commits](https://www.conventionalcommits.org). The
changelog and version number are built from them, and a commit that does not
parse is left out of the changelog.

```
<type>(<scope>): <lowercase summary>

feat(theme): port osaka-jade from Omarchy
fix(ws): refresh the bar's space indicators after running commands
docs: explain the five-Space default
feat(install)!: require macOS 26          <- ! marks a breaking change
```

| Type | Changelog section | Version bump (before 1.0) |
|---|---|---|
| `feat` | Features | minor |
| `fix` | Fixes | patch |
| `perf` | Performance | patch |
| `docs` | Docs | patch |
| `revert` | Reverts | patch |
| `refactor`, `style`, `test`, `build`, `ci`, `chore` | hidden | none |
| any type with `!` | flagged as breaking | minor |

Scopes in use: `theme`, `windows`, `bar`, `keys`, `agent`, `ws`, `install`,
`update`, `site`.

PRs are squash-merged, so the PR title is the commit that lands on `main`. CI
rejects a title that does not parse.

The `commit-msg` hook below checks this before the commit is made.

## Hooks

[pre-commit](https://pre-commit.com) runs the same checks as CI on every
commit. One-time setup per clone:

```sh
brew install pre-commit   # or: uv tool install pre-commit
pre-commit install        # installs the pre-commit and commit-msg hooks
```

If you used the old `git config core.hooksPath .githooks`, run
`git config --unset core.hooksPath` first; `pre-commit install` refuses while
it is set.

| Area | Tools |
|---|---|
| Secrets | `detect-secrets` (against `.secrets.baseline`), `detect-private-key` |
| Shell | `shellcheck` (warnings and up), `shfmt` (2-space indent) |
| Python (`ws` agent) | `ruff check` (includes bandit's security rules), `ruff format`; config in `ruff.toml` |
| Lua (Neovim themes) | `StyLua`; config in `stylua.toml` |
| GitHub Actions | `actionlint`, `zizmor` (workflow security) |
| Files | large files, merge markers, broken symlinks, shebang/exec bit, JSON/TOML/YAML syntax, trailing whitespace, final newline |
| Commit message | Conventional Commit subject (`.githooks/commit-msg`) |

Formatters fix files in place and fail the commit; `git add` the changes and
commit again. Run everything by hand with `pre-commit run --all-files`.

**detect-secrets false positive.** Git SHAs and checksums look like secrets.
Mark a new one as reviewed with:

```sh
detect-secrets scan --baseline .secrets.baseline
detect-secrets audit .secrets.baseline   # answer "n" (not a secret) for each
```

Commit the updated `.secrets.baseline` with the change. A real secret never
goes in the baseline; take it out of the file.

**Updating hook versions:** `pre-commit autoupdate`, then commit the config.

## Releases

Nothing to do by hand. On every push to `main`, release-please updates a
single open PR titled `chore(main): release x.y.z` that bumps `version.txt`
and adds the next `CHANGELOG.md` entry. Merge it when you want to ship; that
tags `vx.y.z` and publishes the GitHub release with the same notes.

## CI

Every push and PR runs `pre-commit run --all-files`, so the table above is
exactly what CI checks. Pushes to `main` also warn about commit subjects that
are not Conventional Commits. Actions are pinned to commit SHAs; Dependabot
bumps them monthly.
