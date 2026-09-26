# macarchy

Omarchy's desktop, on the MacBook you already own.

An [Omarchy](https://omarchy.org)-style layer for macOS: one command restyles
the terminal, multiplexer, editor, status bar, window borders and wallpaper,
and windows tile over native Spaces. System Integrity Protection stays on.

macarchy is an independent project, not affiliated with or endorsed by
Omarchy or the Omacom Foundation. Ported themes are used under Omarchy's MIT
licence; see [NOTICE](NOTICE).

It started as one person's config and is built around the tools I use, but
you do not have to take all of it. The installer asks which parts you want:
just the themes, just the window manager, or any mix (see
[Components](#components)). Themes cover Ghostty, kitty, Alacritty, iTerm2,
VS Code (and Cursor, VSCodium, Windsurf), Zed, Zellij and Neovim; see
[Scope](#scope). The reasoning is in [Why macarchy exists](#why-macarchy-exists).

| Area | What |
|---|---|
| Theming | `theme-set <name>` restyles your terminal (Ghostty, kitty, Alacritty, iTerm2), editor (VS Code and forks, Zed, Neovim), Zellij, SketchyBar, JankyBorders and the wallpaper together, skipping apps you don't have. [docs/theme-system.md](docs/theme-system.md) |
| Window management | yabai (tiling) + skhd (hotkeys) + SketchyBar (status bar) + JankyBorders (focus border), layered over native macOS Spaces, no SIP changes. The bar draws above the auto-hidden menu bar; `shift + alt - m` hides it to reach the native one. [docs/window-management.md](docs/window-management.md) |
| Hotkey discovery | `alt - /` pops up a searchable which-key style list of every skhd binding; Enter runs it. Also lists Ghostty and Zellij keybinds when those configs exist |
| Theme picker | `shift + alt - /` pops up `theme-pick`, an fzf picker with truecolor swatches for all 22 themes, in a floating window of your terminal (`MACARCHY_TERMINAL`); Enter applies it |
| Raycast | a generated "Set Theme" script command |
| Workspace agent | `ws`: plain-English (or voice, `alt - w`) control of windows, Spaces, theme and terminal tabs via an on-device 14 MB model. [docs/agent.md](docs/agent.md) |
| Speech-to-text | [Handy](https://handy.computer) (offline, open-source; brew cask `handy`, installed by `install.sh`) transcribes for `ws --voice`. Its own hotkey, `alt - space` (hold to talk, tap to toggle), is configured inside Handy, not skhd. |

Themes live under `home/.config/theme/themes/`. 22 themes ship. `retro-82` is
custom (a 1982 arcade CRT look); `kanagawa-wave` and `catppuccin-mocha` follow
their upstream palettes; the rest are Omarchy themes brought over with
`theme-port <name>`, which works for any theme in Omarchy's catalogue. See
[docs/omarchy-port.md](docs/omarchy-port.md). Light themes need
`--allow-light` and a manual check afterwards, because the SketchyBar and
border colour derivations assume a dark background. 5 of the 22 are light:

- **Dark (17):** catppuccin-mocha, ethereal, everforest, gruvbox, hackerman,
  kanagawa-wave, last-horizon, lumon, matte-black, miasma, nord, osaka-jade,
  retro-82, ristretto, solitude, tokyo-night, vantablack
- **Light (5):** catppuccin-latte, flexoki-light, lupine, rose-pine, white

## Scope

macarchy is opinionated on purpose. It is not a framework for every Mac setup,
and it does not try to be.

What it themes:

- Terminals: Ghostty, kitty, Alacritty and iTerm2 (all 16 ANSI colours,
  cursor and selection). Popups open in whichever one `MACARCHY_TERMINAL`
  names, WezTerm included.
- Editors: VS Code, Cursor, VSCodium, Windsurf and VS Code Insiders (through
  the marketplace theme the Omarchy theme maps to), Zed (a generated
  "Macarchy" theme) and Neovim (a LazyVim plugin spec).
- Zellij, SketchyBar, JankyBorders and the wallpaper.

Each app is one hook script in `home/.config/theme/hooks/`. `theme-set` runs
them all, and a hook for an app you don't have exits without doing anything.
Your own hooks go in `~/.config/macarchy/hooks.d/`.

What it does not do:

- Theme WezTerm's colours, Terminal.app, JetBrains IDEs or browsers. A hook
  for any of them is one short script; see
  [docs/theme-system.md](docs/theme-system.md#adding-an-app).
- Theme VS Code for the 7 themes that have no matching marketplace theme
  (retro-82, ethereal, lupine, miasma, ristretto, vantablack, white). A
  switch to one of those leaves VS Code on its previous theme.
- Manage your terminal, editor or multiplexer configs. It adds one include
  line to each and the configs stay yours; see
  [Hooking in your own configs](#hooking-in-your-own-configs).
- Replace macOS Spaces or touch System Integrity Protection. yabai runs
  without its scripting addition, so a few yabai features are unavailable; see
  [docs/window-management.md](docs/window-management.md).
- Derive bar and border colours for light themes. The five light themes ship
  because each was checked by hand after porting.

The hotkeys, the bar layout and the five-Space default are my preferences.
Most of them are a config edit or a file away from being yours. Some are
hard-coded.

## Components

Each part installs on its own. `./install.sh` asks on the first run and
saves your answer as `MACARCHY_COMPONENTS` in `~/.config/macarchy/config`.

| Component | What you get | Brew packages |
|---|---|---|
| `themes` | `theme-set`, `theme-pick` and the 22 themes for every app above | imagemagick, fzf |
| `wm` | yabai tiling + skhd hotkeys over native Spaces, no SIP changes | yabai, skhd, jq |
| `bar` | SketchyBar status bar (pulls in `themes`) | sketchybar, jq, Hack Nerd Font |
| `borders` | JankyBorders focus border (pulls in `themes`) | borders |
| `keys` | `macarchy-keys`, the `alt - /` which-key popup | fzf |
| `agent` | `ws`, plain-English and voice control of windows and themes | Handy (cask) |

```sh
./install.sh --list              # the table above
./install.sh --only themes       # just the themes
./install.sh --only wm,bar       # a tiling desktop, no theme hooks in your apps
./install.sh --skip agent        # what you picked before, minus the agent
./install.sh --remove bar        # unlink a component (restores any file it moved aside)
```

`macarchy-update` only links files of the components you chose.

## Why macarchy exists

I love Linux. Hyprland, Niri and Omarchy are the desktops I want, and I would
run one full time. I also already paid for a MacBook. It is a very good laptop,
and a few thousand dollars for a second one that fits my needs worse is not a
trade I want to make. Some of my work needs Xcode and the Mac apps anyway. So
this does what Omarchy does, on macOS, and leaves the machine alone.

**Why not just install Linux?** If you can, do. Omarchy is the better version
of this idea. macarchy is for the MacBook you already own, or the one your
apps keep you on.

**Isn't this yabai with dotfiles?** yabai is the tiler. The rest is one theme
directory driving six apps at once, 22 palettes ported from Omarchy with a
porter for the rest of its catalogue, and a voice agent that runs on device.

**What do I give up?** macOS keeps owning Spaces, so yabai cannot create them
or move windows between them; see
[docs/window-management.md](docs/window-management.md). Only the apps in my
stack are themed today; see [Scope](#scope).

## Plans

The plan is to keep the symlink mechanism and widen what it drives. None of
this exists yet, and the list is an order of intent, not a schedule.

- Light themes handled in the SketchyBar and JankyBorders colour derivations,
  so `theme-port --allow-light` stops needing hand edits afterwards.
- A generated VS Code theme for the themes with no marketplace match.
- Hooks for WezTerm colours, JetBrains IDEs and browsers.

If one of these matters to you, open an issue naming the app and the config
format it reads. That is the part that takes the time.

## Install

Pick one.

### Agentic install

One line, on a fresh Mac, walks you through the rest interactively:

```sh
curl -fsSL https://raw.githubusercontent.com/jlargs64/macarchy/main/install-agent.sh | sh -s -- claude
```

Swap `claude` for any of `codex`, `pi`, `opencode`, `gemini`, `copilot`,
`cursor`, `amp`, or leave the argument off to auto-detect (or get a picker,
or install hints if none are found). This launches that agent CLI
interactively, seeded with [`AGENT-INSTALL.md`](AGENT-INSTALL.md), which
walks it (and you) through the same steps below: prerequisites, cloning,
`./install.sh --dry-run` then `./install.sh`, the manual Accessibility and
Handy steps, and verification. The agent asks before it runs anything. This never passes a
skip-permissions or yolo flag to any agent.

Don't use one of the supported CLIs, or want to paste the prompt into a
chat-based agent instead? `install-agent.sh --print` dumps the same prompt
to stdout for that.

### Script

```sh
git clone <url> ~/Projects/macarchy && cd ~/Projects/macarchy && ./install.sh
```

`install.sh` asks which [components](#components) you want, then bootstraps
Homebrew and installs only their packages, sets a handful of macOS `defaults`
(with `wm` only), links their files from `home/` into `$HOME` one symlink per
file, seeds the default theme, generates wallpapers, and writes
`~/.config/macarchy/config` from the example. A real file already where a
link goes is moved to `<file>.pre-macarchy`, never overwritten. It is
idempotent, so re-running is safe. `./install.sh --dry-run` prints every
action without changing anything.

After that, `macarchy-update` keeps the checkout and `$HOME` in sync, and
`install.sh` sets it to run at every login. See
[Staying up to date](#staying-up-to-date).

With `wm`, one manual step remains: yabai and skhd cannot start until you
grant Accessibility permission. The installer prints only the steps for the
components you picked.

1. System Settings > Privacy & Security > Accessibility
2. Add and enable `/opt/homebrew/bin/yabai` and `/opt/homebrew/bin/skhd`
3. `yabai --start-service && skhd --start-service && brew services start borders && brew services start sketchybar`
4. Open Handy.app once and grant Microphone + Accessibility when it asks,
   then pick a model (Parakeet EN recommended, ~700 MB). `ws --voice` needs
   it.

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
target. Bump the tag in all eight `url`s together when you pull a new
macarchy release. (`macarchy-update` needs a git checkout, so it does not
apply here; bumping the tag is the chezmoi equivalent.)

chezmoi will not run `install.sh` for you. It only writes files. After the
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
MACARCHY_UPDATE_AT_LOGIN=true     # install.sh sets up macarchy-update to run at login
MACARCHY_THEME_TARGETS=auto       # apps theme-set restyles; or a list, e.g. "kitty zed neovim"
MACARCHY_TERMINAL=ghostty         # terminal popups open in: ghostty kitty alacritty iterm2 wezterm
MACARCHY_COMPONENTS="themes wm"   # written by install.sh; what it and macarchy-update manage
```

The example file also carries `MACARCHY_KEYS_SOURCES` and the `ws` agent
settings (`MACARCHY_AGENT_MODEL`, `MACARCHY_AGENT_EXECUTE`, `MACARCHY_MIC`,
`MACARCHY_HANDY`), each with a comment. Edit the file and re-run `theme-set`
or `theme-raycast-sync`, or restart SketchyBar, as relevant. Nothing needs a
full reinstall.

## Staying up to date

Every file under `home/` is a symlink into the checkout, so an edit that
`git pull` brings in is live right away. A bare pull misses three things:
files added upstream (nothing links them), links to files deleted upstream
(they dangle), and running services (they keep the old config until
reloaded). `macarchy-update` handles all three:

```sh
macarchy-update              # pull, relink, prune, reload what changed
macarchy-update --no-pull    # relink and reload everything without pulling (restarts yabai)
macarchy-update --login on   # run at every login (install.sh does this by default)
macarchy-update --login off  # stop running at login
```

1. `git pull --ff-only` in the checkout it lives in. It never merges; if
   local edits conflict with upstream, it stops and you commit or stash
   them first.
2. Links every git-tracked file under `home/` that belongs to one of your
   components into `$HOME`. A real file
   where a link should be is left alone and reported, never overwritten.
3. Removes symlinks in `~/.config` and `~/.local/bin` that point at repo
   files that no longer exist.
4. Reloads only what the pull touched: SketchyBar, skhd, yabai, borders,
   and re-applies the current theme if anything under `.config/theme/`
   changed.
5. If `install.sh` changed, it prints a reminder to re-run it. It never
   installs Homebrew packages itself.

**At login.** `--login on` writes a LaunchAgent to
`~/Library/LaunchAgents/macarchy.update.plist`. At login it waits up to a
minute for the network, runs the steps above, and posts a macOS
notification when it pulls something or fails. Runs where nothing changed
stay quiet. Every run is logged to `~/Library/Logs/macarchy-update.log`,
the first place to look when a notification says it failed (usually local
edits blocking the fast-forward, or no network). `install.sh` turns it on or
off to match `MACARCHY_UPDATE_AT_LOGIN`.

## Hooking in your own configs

macarchy does not manage your app configs. Add one line to each app you use;
skip the rest:

| App | File | Line |
|---|---|---|
| Ghostty | `~/.config/ghostty/config` | `config-file = ?~/.config/theme/current/ghostty` |
| kitty | `~/.config/kitty/kitty.conf` | `include ~/.config/theme/generated/kitty.conf` |
| Alacritty | `~/.config/alacritty/alacritty.toml` | `import = ["~/.config/theme/generated/alacritty.toml"]` under `[general]` |
| iTerm2 | Settings > Profiles | select the "macarchy" profile, Other Actions > Set as Default (a Dynamic Profile `theme-set` rewrites) |
| VS Code | nothing | `theme-set` sets `workbench.colorTheme` and installs the theme's extension if missing |
| Zed | `~/.config/zed/settings.json` | `"theme": "Macarchy"` |
| Zellij | `~/.config/zellij/config.kdl` | `theme "current"` |
| Neovim | a plugins file (e.g. `lua/plugins/theme-plugins.lua`) | declare the colorscheme plugins the shipped themes use with `lazy = true`, so lazy.nvim sees them even when their theme isn't active -- 15 entries covering all 22 themes (`nvim-mini/mini.base16` alone covers the 7 themes that drive it locally); see [docs/theme-system.md](docs/theme-system.md) for the full current list |

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
| `vscode.json` | optional: `{"name", "extension"}` of the matching VS Code theme |
| `kitty.conf`, `alacritty.toml`, `iterm2.json`, `zed.json` | optional: used as is instead of the generated file |
| `wallpaper.jpg` | 5120x2880, generated, not tracked |
| `backgrounds/` | real images, fetched, not tracked |

kitty, Alacritty, iTerm2 and Zed files are generated from the `ghostty`
palette (and `colors.sh` for anything it leaves out) by `theme-render`, so a
theme needs no per-app file for them.

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
home/                       mirrors $HOME; install.sh links it file by file
  .config/theme/            the theme switcher, themes, hooks/ (one per app), lib/palette.sh
  .config/sketchybar/       status bar
  .config/skhd/             hotkeys
  .config/yabai/            tiling WM
  .config/borders/          focused-window border
  .config/raycast/scripts/  Raycast script commands
  .config/macarchy/         config.example, lib.sh (config loader), components.sh (what install.sh can install), bin/ (macarchy-keys, macarchy-popup, macarchy-update)
  .local/bin/                theme-*, macarchy-keys and macarchy-update on PATH, symlinked into .config/theme/bin and .config/macarchy/bin
install.sh                  installer (see above)
docs/                        long-form documentation
```

## Working on it

```sh
git clone <url> ~/Projects/macarchy && cd ~/Projects/macarchy
$EDITOR home/.config/yabai/yabairc      # edit the source
macarchy-update --no-pull               # re-link (no-op unless files were added/removed)
yabai --restart-service
```

`~/.config/yabai/yabairc` is a symlink to
`home/.config/yabai/yabairc`, so editing one edits both. No re-linking is needed
unless you added or removed a file.

Two kinds of files are deliberately untracked: runtime state
(`~/.config/theme/current`) and generated artifacts (wallpapers, backgrounds).
`install.sh` and `theme-maintain` (re)create both; see
[docs/theme-system.md](docs/theme-system.md#what-is-not-tracked-in-this-repo).

## Licence

macarchy is MIT licensed; see [LICENSE](LICENSE). Themes ported from Omarchy
and the upstream colour schemes they derive from are credited in
[NOTICE](NOTICE).
