# macarchy

An [Omarchy](https://omarchy.org)-style desktop layer for macOS: a theme
system that restyles the terminal, editor, status bar and window borders
together, plus a tiling window manager over native macOS Spaces.

| Area | What |
|---|---|
| Theming | `theme-set <name>` restyles Ghostty, Zellij, Neovim, SketchyBar, JankyBorders and the wallpaper together. [docs/theme-system.md](docs/theme-system.md) |
| Window management | yabai (tiling) + skhd (hotkeys) + SketchyBar (status bar) + JankyBorders (focus border), layered over native macOS Spaces, no SIP changes. [docs/window-management.md](docs/window-management.md) |
| Hotkey discovery | `alt - /` pops up a searchable which-key style list of every skhd binding; Enter runs it. Also lists Ghostty and Zellij keybinds when those configs exist |
| Raycast | a generated "Set Theme" script command |
| Workspace agent | `ws`: plain-English (or voice, `alt - space`) control of windows, Spaces, theme and terminal tabs via an on-device 14 MB model. [docs/agent.md](docs/agent.md) |

Six themes ship: `retro-82` (custom, 1982 arcade CRT), `kanagawa-wave`,
`catppuccin-mocha`, and three ported from Omarchy with `theme-port`:
`tokyo-night`, `gruvbox`, `nord`. Port any other dark Omarchy theme with
`theme-port <name>`; see [docs/omarchy-port.md](docs/omarchy-port.md).

This repo owns the desktop layer only — terminal emulator, multiplexer and
editor themselves are yours; macarchy just hooks into them (see
[Hooking in your own configs](#hooking-in-your-own-configs) below).

## Install

Pick one.

### stow

```sh
git clone <url> ~/Projects/macarchy && cd ~/Projects/macarchy && ./install.sh
```

`install.sh` bootstraps Homebrew, installs the packages, sets a handful of
macOS `defaults`, links `home/` into `$HOME` (via `stow` if it is on `PATH`,
otherwise plain symlinks), seeds the default theme, generates wallpapers, and
writes `~/.config/macarchy/config` from the example. It is idempotent — safe
to re-run. `./install.sh --dry-run` prints every action without changing
anything.

To skip the packages/defaults and only link files:

```sh
stow -t "$HOME" home
```

**One manual step remains** — yabai and skhd cannot start until you grant
Accessibility permission:

1. System Settings > Privacy & Security > Accessibility
2. Add and enable `/opt/homebrew/bin/yabai` and `/opt/homebrew/bin/skhd`
3. `yabai --start-service && skhd --start-service && brew services start borders && brew services start sketchybar`

### chezmoi archive external

If your own dotfiles are managed with [chezmoi](https://chezmoi.io), pull
macarchy in as a tagged archive instead of a git submodule. Add to your
`.chezmoiexternal.toml`:

```toml
[".config/theme"]
    type = "archive"
    url = "https://github.com/jlargs64/macarchy/archive/refs/tags/v0.1.0.tar.gz"
    exact = true
    stripComponents = 2
    include = [".config/theme/**"]

[".config/sketchybar"]
    type = "archive"
    url = "https://github.com/jlargs64/macarchy/archive/refs/tags/v0.1.0.tar.gz"
    exact = true
    stripComponents = 2
    include = [".config/sketchybar/**"]

[".config/skhd"]
    type = "archive"
    url = "https://github.com/jlargs64/macarchy/archive/refs/tags/v0.1.0.tar.gz"
    exact = true
    stripComponents = 2
    include = [".config/skhd/**"]

[".config/yabai"]
    type = "archive"
    url = "https://github.com/jlargs64/macarchy/archive/refs/tags/v0.1.0.tar.gz"
    exact = true
    stripComponents = 2
    include = [".config/yabai/**"]

[".config/borders"]
    type = "archive"
    url = "https://github.com/jlargs64/macarchy/archive/refs/tags/v0.1.0.tar.gz"
    exact = true
    stripComponents = 2
    include = [".config/borders/**"]

[".config/raycast/scripts"]
    type = "archive"
    url = "https://github.com/jlargs64/macarchy/archive/refs/tags/v0.1.0.tar.gz"
    exact = true
    stripComponents = 2
    include = [".config/raycast/scripts/**"]

[".config/macarchy"]
    type = "archive"
    url = "https://github.com/jlargs64/macarchy/archive/refs/tags/v0.1.0.tar.gz"
    exact = true
    stripComponents = 2
    include = [".config/macarchy/**"]

[".local/bin"]
    type = "archive"
    url = "https://github.com/jlargs64/macarchy/archive/refs/tags/v0.1.0.tar.gz"
    exact = true
    stripComponents = 2
    include = [".local/bin/theme-*"]
```

`stripComponents = 2` strips `macarchy-0.1.0/home/` off every archive path, so
`home/.config/theme/...` in the tag lands at `.config/theme/...` in your
target. Bump the tag in all seven `url`s together when you pull a new
macarchy release.

chezmoi will not run `install.sh` for you — it only writes files. After the
first `chezmoi apply`, run `~/.config/theme/bin/theme-maintain` once by hand
(it seeds wallpapers, fetches backgrounds and syncs the Raycast dropdown), or
add your own `run_onchange_` script that execs it. Homebrew packages and
macOS `defaults` are on you too, or copy the relevant blocks out of
`install.sh`.

### Config file

`~/.config/macarchy/config` (copied from
[`home/.config/macarchy/config.example`](home/.config/macarchy/config.example)
by `install.sh` if it does not already exist):

```sh
MACARCHY_DEFAULT_THEME=retro-82   # theme.set with no argument, and the seed on first install
MACARCHY_FONT="Hack Nerd Font"    # SketchyBar icon/label font
MACARCHY_SPACES=5                 # how many Space indicators the bar renders (1-9)
MACARCHY_RAYCAST_AUTHOR=""        # @raycast.author line; blank omits it
MACARCHY_WIFI_IFACE=en0           # interface the wifi bar plugin reads
```

Edit it and re-run `theme-set` / `theme-raycast-sync` / restart SketchyBar as
relevant — nothing needs a full reinstall.

## Hooking in your own configs

macarchy does not manage Ghostty, Zellij or Neovim themselves — add one line
to each:

| App | File | Line |
|---|---|---|
| Ghostty | `~/.config/ghostty/config` | `config-file = ?~/.config/theme/current/ghostty` |
| Zellij | `~/.config/zellij/config.kdl` | `theme "current"` |
| Neovim | a plugins file (e.g. `lua/plugins/theme-plugins.lua`) | declare the colorscheme plugins the shipped themes use with `lazy = true`, so lazy.nvim sees them even when their theme isn't active: `nvim-mini/mini.base16`, `rebelot/kanagawa.nvim`, `catppuccin/nvim`, `folke/tokyonight.nvim`, `ellisonleao/gruvbox.nvim`, `EdenEast/nightfox.nvim` (nord uses its `nordfox` variant) |

`install.sh` also symlinks `~/.config/zellij/themes/current.kdl` and
`~/.config/nvim/lua/plugins/theme.lua` for you, but only if `~/.config/zellij`
or `~/.config/nvim` already exists.

## The theme contract

Every theme is a directory under `home/.config/theme/themes/<name>/`:

| File | Purpose |
|---|---|
| `colors.sh` | the palette, as shell exports |
| `ghostty` | Ghostty config fragment |
| `zellij.kdl` | a `themes { current { ... } }` block |
| `neovim.lua` | a LazyVim plugin spec |
| `borders` | JankyBorders settings |
| `wallpaper.jpg` | 5120x2880, generated — not tracked |
| `backgrounds/` | real images, fetched — not tracked |

`colors.sh` must export bare hex (no `#`, no `0x`):

```sh
export THEME_NAME=<name>
export NVIM_COLORSCHEME=<name neovim's :colorscheme accepts>
export BG=......      export FG=......      export ACCENT=......
export ACCENT2=......  export MUTED=......
export RED=......     export GREEN=......   export YELLOW=......
export BLUE=......    export MAGENTA=......  export CYAN=......
```

Full mechanism, adding a theme, and per-app wiring in
[docs/theme-system.md](docs/theme-system.md).

## Layout of this repo

```
home/                       mirrors $HOME; `stow -t "$HOME" home`
  .config/theme/            the theme switcher and theme definitions
  .config/sketchybar/       status bar
  .config/skhd/             hotkeys
  .config/yabai/            tiling WM
  .config/borders/          focused-window border
  .config/raycast/scripts/  Raycast script commands
  .config/macarchy/         config.example + lib.sh (the shared config loader) + bin/ (macarchy-keys)
  .local/bin/                theme-* and macarchy-keys on PATH, symlinked into .config/theme/bin and .config/macarchy/bin
install.sh                  installer (see above)
docs/                        long-form documentation
```

## Working on it

```sh
git clone <url> ~/Projects/macarchy && cd ~/Projects/macarchy
$EDITOR home/.config/yabai/yabairc      # edit the source
stow -R -t "$HOME" home                 # re-link (no-op unless files were added/removed)
yabai --restart-service
```

If you installed with `stow`, `~/.config/yabai/yabairc` already **is**
`home/.config/yabai/yabairc` — editing one edits both, no re-linking needed
unless you added or removed a file.

Two kinds of files are deliberately untracked: runtime state
(`~/.config/theme/current`) and generated artifacts (wallpapers, backgrounds).
`install.sh` and `theme-maintain` (re)create both; see
[docs/theme-system.md](docs/theme-system.md#what-is-not-tracked-in-this-repo).
