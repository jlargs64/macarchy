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

To check commit messages locally before they are pushed:

```sh
git config core.hooksPath .githooks
```

## Releases

Nothing to do by hand. On every push to `main`, release-please updates a
single open PR titled `chore(main): release x.y.z` that bumps `version.txt`
and adds the next `CHANGELOG.md` entry. Merge it when you want to ship; that
tags `vx.y.z` and publishes the GitHub release with the same notes.

## CI

Every push and PR runs shellcheck (errors only), a Python syntax check of the
agent, and actionlint on the workflows.
