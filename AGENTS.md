# AGENTS.md

For coding agents working on this repository. If you are helping someone
*use* their macarchy desktop instead, the skill in
`home/.claude/skills/macarchy/SKILL.md` is the right document.

## What macarchy is

An Omarchy-style desktop layer for macOS: `theme-set <name>` restyles the
terminal, editor, Zellij, SketchyBar, JankyBorders and the wallpaper at once,
and yabai tiles windows over native macOS Spaces with SIP left on.
`home/` mirrors `$HOME`; `install.sh` links it in one symlink per file.

## Component map

Every file under `home/` belongs to exactly one component
(`macarchy_component_of` in `home/.config/macarchy/components.sh`; the test
`tests/components.bats` fails if a file maps to nothing). A file is linked
into `$HOME` only when its component is in `MACARCHY_COMPONENTS`.

| Component | Owns | Notes |
|---|---|---|
| `core` | `home/.config/macarchy/{lib.sh,components.sh,config.example}`, `bin/macarchy-{update,doctor,uninstall,popup}`, `home/.claude/**`, anything not matched below | always installed |
| `themes` | `home/.config/theme/**` (bin/, hooks/, lib/, themes/), `home/.config/raycast/**`, `home/.local/bin/theme-*` | `theme-set`, `theme-pick`, `theme-bg*`, `theme-port`, `theme-wallpaper*` |
| `wm` | `home/.config/yabai/yabairc`, `home/.config/skhd/skhdrc`, `bin/macarchy-center`, `theme/bin/hotkey-check` | yabai + skhd, no scripting addition |
| `bar` | `home/.config/sketchybar/**` | needs `themes` |
| `borders` | `home/.config/borders/bordersrc` | needs `themes` |
| `keys` | `bin/macarchy-keys` | the `alt - /` which-key popup |
| `agent` | `home/.config/macarchy/agent/**`, `home/.config/macarchy/swift/**`, `home/.local/bin/ws` | `ws`, Python under `uv`; see `docs/agent.md` |

`home/.local/bin/*` are relative symlinks into `.config/*/bin`; a new script
needs one of those links too (that is how it lands on `PATH`).

Outside `home/`: `install.sh` (installer), `tests/` (bats), `docs/`
(long-form docs), `site/` (the website), `.github/` (CI, labels,
release-please).

## How `home/` reaches `$HOME`

`macarchy-update` (and `install.sh`'s link step) walks `macarchy_repo_files`,
which is `git ls-files home` in a checkout, and does
`ln -sfn $REPO/home/<rel> $HOME/<rel>` for every file whose component is
installed. Consequences:

- `~/.config/yabai/yabairc` *is* `home/.config/yabai/yabairc`. Editing a
  tracked file in the repo edits the live config on the maintainer's machine
  immediately. Untracked files are never linked.
- Adding a file needs `macarchy-update --no-pull` (or `./install.sh`) to link
  it; editing an existing one needs nothing. A new directory under `home/`
  needs no registration as long as `macarchy_component_of` maps it (unmatched
  paths fall to `core`), but a new *top-level* one (like `.claude`) must be
  added to `MACARCHY_LINK_DIRS` in `components.sh`, the list of `$HOME`
  directories that `macarchy-update` prunes and `macarchy-uninstall` cleans;
  `tests/components.bats` checks.
- `.stow-local-ignore` lists repo-root files stow must skip; it does not
  affect `macarchy-update`.
- Runtime state is not tracked: `~/.config/theme/current` (a symlink),
  `~/.config/theme/generated/`, `wallpaper-current.jpg`, per-theme
  `wallpaper.jpg` and `backgrounds/`, `themes/<name>/.bg`.

## Settings

`MACARCHY_*` values are read from `~/.config/macarchy/config`. Defaults live
in `home/.config/macarchy/lib.sh` (source it with
`. "$HOME/.config/macarchy/lib.sh"`), and every knob is documented with a
comment in `home/.config/macarchy/config.example`. Add a new setting in both
places, then in the README's config block or `docs/window-management.md`.

Current knobs: `MACARCHY_DEFAULT_THEME`, `MACARCHY_THEME_TARGETS`,
`MACARCHY_TERMINAL`, `MACARCHY_COMPONENTS`, `MACARCHY_FONT`,
`MACARCHY_SPACES`, `MACARCHY_RAYCAST_AUTHOR`, `MACARCHY_WIFI_IFACE`,
`MACARCHY_UPDATE_AT_LOGIN`, `MACARCHY_KEYS_SOURCES`, `MACARCHY_GAP`,
`MACARCHY_PADDING_{TOP,BOTTOM,LEFT,RIGHT}`, `MACARCHY_BAR_HEIGHT`,
`MACARCHY_BORDER_WIDTH`, `MACARCHY_BORDER_STYLE`, `MACARCHY_CENTER_WIDTH`,
`MACARCHY_CENTER_SINGLE`, `MACARCHY_AGENT_MODEL`, `MACARCHY_AGENT_EXECUTE`,
`MACARCHY_MIC`, `MACARCHY_HANDY`. `MACARCHY_PREVIEW_FORMAT` is an
environment override for `theme-img`, not a config line.

## Commands

| Command | Does |
|---|---|
| `macarchy-doctor [--quiet]` | read-only health check of the installed components, with a fix per problem; exit 1 on failures |
| `macarchy-update [--no-pull] [--login on\|off]` | `git pull --ff-only`, link new files, prune dead links, reload what changed |
| `macarchy-center apply\|toggle\|status` | centered column on wide displays; `apply` is run by yabai signals, `toggle` is `alt - c` |
| `theme-set <name>` / `theme-next` / `theme-list` | repoint `~/.config/theme/current` and run every hook |
| `theme-pick [--list\|--preview NAME\|--popup\|--rows\|--dry-run]` | fzf theme picker; `shift + alt - /` |
| `theme-bg [<n>\|<name>\|next\|prev\|apply]` | pick a background within the current theme |
| `theme-bg-pick [--popup\|--rows\|--dry-run]` | fzf background picker with pictures; `alt - b` |
| `theme-bg-fetch` / `theme-wallpaper <dir>` / `theme-maintain` | fetch backgrounds, render fallback gradients, do all housekeeping |
| `theme-wallpaper-enroll [--here]` | point every Space (or only the visible ones, quietly) at the shared wallpaper file |
| `theme-port <name> [--src DIR] [--allow-light] --out DIR` | port an Omarchy theme into `home/.config/theme/themes/` |
| `theme-render <app> [dir]` / `theme-raycast-sync` | generate an app's config from the palette; regenerate the Raycast command |
| `macarchy-keys [--list\|--markdown\|--popup\|--source X]` | which-key hotkey list from `skhdrc` (plus Ghostty and Zellij); `alt - /` |
| `hotkey-check` | collisions between skhd, macOS, Raycast and Handy hotkeys |
| `ws [-x] "..."` / `ws --voice` | the on-device workspace agent; dry-run unless `MACARCHY_AGENT_EXECUTE=true` |
| `macarchy-uninstall [--dry-run ...]` | remove the links, restore `.pre-macarchy` files |

Landing in a parallel PR (do not document as present until it merges):
`macarchy-restart` (what `shift + alt - r` will run: restart yabai, reload
the bar) and `macarchy-rescue` (moves off-screen windows back on screen).

## Theme system in one paragraph

`~/.config/theme/current` is a symlink to `themes/<name>/`. Every app reads
through it (`current/ghostty`, `current/neovim.lua`) or through
`generated/<app>` files that `theme-render` builds from the theme's palette.
`theme-set` validates the name, repoints the symlink, sources `colors.sh` and
the config, then runs every script in `home/.config/theme/hooks/` (or only
those in `MACARCHY_THEME_TARGETS`) with `THEME_NAME`, `THEME_DIR`,
`THEME_ROOT`, `THEME_OUT` and the palette in the environment, followed by the
user's own `~/.config/macarchy/hooks.d/*`. A hook exits 0 when its app is
missing, writes through symlinks, and never blocks. The theme contract
(`colors.sh` exports, required files) is in the README; the mechanism, the
hook table and wallpapers-per-Space are in `docs/theme-system.md`.

## The scripting-addition constraint

yabai runs without its scripting addition, on purpose; nothing here touches
SIP or `csrutil`. That rules out, from yabai: creating or destroying Spaces,
`yabai -m space --focus N` (returns 0 and does nothing), and
`yabai -m window --space N` (fails). Space switching is native `ctrl + N`
(or synthesized key codes, as `space_click.sh` and `ws` do); moving windows
between Spaces is a drag or Mission Control. Any feature you design must work
inside this; `docs/window-management.md` lists what still works.

## Working rules

- **Commits.** Conventional Commits; release-please builds the changelog and
  version from them, and CI rejects a PR title that does not parse. Scopes in
  use: `theme`, `windows`, `bar`, `keys`, `agent`, `ws`, `install`, `update`,
  `site`. PRs are squash-merged, so the PR title is the commit on `main`.
- **Hooks and tests.** `pre-commit install` once per clone;
  `pre-commit run --all-files` is exactly what CI runs (shellcheck at
  warning level, `shfmt -i 2 -ci -s`, ruff, StyLua, actionlint, zizmor,
  detect-secrets). Tests are bats: `arch -arm64 bats tests/`. The
  maintainer's shell runs under Rosetta (x86_64), so `arch -arm64` is needed
  for `bats` and `brew`. Tests run against a fake `$HOME` with stubbed
  `yabai`, `skhd`, `sketchybar`, `brew`, `launchctl` and friends
  (`tests/helpers.bash`); keep it that way.
- **bash 3.2.** Every script runs on macOS's `/bin/bash`: no `mapfile`, no
  associative arrays, no `${var,,}`. `#!/usr/bin/env bash` finds 3.2 first.
- **Shared working tree.** Other sessions edit the main clone at the same
  time. Work in a `git worktree` on a branch; never `git stash`, `checkout`
  or `switch` in the main clone.
- **The maintainer's machine is live.** Because `home/` is symlinked into
  `$HOME`, edits take effect in the running desktop. Do not open windows,
  restart yabai/skhd/SketchyBar/borders, run `theme-set`,
  `theme-wallpaper-enroll` or `macarchy-update` on the maintainer's machine
  while testing unless asked. Prefer the bats suite and `--dry-run`,
  `--list`, `--rows`, `status` modes.
- **Docs to update when behaviour changes.** `docs/*.md` (window
  management, theme system, agent), `README.md`, `site/index.html`,
  `home/.config/macarchy/config.example` (and `lib.sh` for a new default),
  `AGENT-INSTALL.md` when install steps change, and the hotkey tables in
  `docs/window-management.md`, which `macarchy-keys --markdown` regenerates
  from the `# comment`s in `skhdrc`. A new hotkey is a `skhdrc` line with a
  comment; `macarchy-keys` and `hotkey-check` pick it up from there.
- **New scripts.** Add the file under `home/.config/<area>/bin/`, a relative
  symlink in `home/.local/bin/`, a `macarchy_component_of` case if it should
  not be `core`, a header comment with usage, and a bats test.
- **Themes.** New themes go through `theme-port` into
  `home/.config/theme/themes/`, never into the live `~/.config/theme/themes`.
  Backgrounds and `wallpaper.jpg` are not committed.
