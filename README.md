# macarchy

Omarchy's desktop, on the MacBook you already own.

An [Omarchy](https://omarchy.org)-style layer for macOS: one command restyles
the terminal, multiplexer, editor, status bar, window borders and wallpaper,
and windows tile over native Spaces. System Integrity Protection stays on.

It is one person's config, published as is. It is built around the tools I use
and it themes only those. If your terminal is not Ghostty or your editor is not
Neovim, macarchy does not restyle it today; see [Scope](#scope) and
[Plans](#plans). The reasoning is in [Why macarchy exists](#why-macarchy-exists).

| Area | What |
|---|---|
| Theming | `theme-set <name>` restyles Ghostty, Zellij, Neovim, SketchyBar, JankyBorders and the wallpaper together. [docs/theme-system.md](docs/theme-system.md) |
| Window management | yabai (tiling) + skhd (hotkeys) + SketchyBar (status bar) + JankyBorders (focus border), layered over native macOS Spaces, no SIP changes. [docs/window-management.md](docs/window-management.md) |
| Hotkey discovery | `alt - /` pops up a searchable which-key style list of every skhd binding; Enter runs it. Also lists Ghostty and Zellij keybinds when those configs exist |
| Theme picker | `shift + alt - /` pops up `theme-pick`, an fzf picker with truecolor swatches for all 22 themes, in a floating Ghostty window; Enter applies it |
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

What it themes: Ghostty, Zellij, Neovim (through a LazyVim plugin spec),
SketchyBar, JankyBorders and the wallpaper. A theme directory holds one file
per app, and `theme-set` only knows about those files.

What it does not do:

- Theme any other terminal (Alacritty, Kitty, WezTerm, iTerm2, Terminal.app),
  editor (VS Code, Zed, JetBrains) or browser. No theme file exists for them,
  so a switch leaves them alone.
- Manage your Ghostty, Zellij or Neovim configs. It adds one include line to
  each and the configs stay yours; see
  [Hooking in your own configs](#hooking-in-your-own-configs).
- Replace macOS Spaces or touch System Integrity Protection. yabai runs
  without its scripting addition, so a few yabai features are unavailable; see
  [docs/window-management.md](docs/window-management.md).
- Derive bar and border colours for light themes. The five light themes ship
  because each was checked by hand after porting.

The hotkeys, the bar layout, the five-Space default and the choice of tools are
my preferences. Most of them are a config edit or a file away from being yours.
Some are hard-coded.

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

- Theme files for more apps, so a theme directory can also carry outputs for
  other terminals (Alacritty, Kitty, WezTerm, iTerm2), editors (VS Code, Zed)
  and browsers, and `theme-set` reloads whichever of them are installed.
- A pick-your-apps install: choose your terminal, multiplexer and editor and
  have `install.sh` link only those hooks.
- Light themes handled in the SketchyBar and JankyBorders colour derivations,
  so `theme-port --allow-light` stops needing hand edits afterwards.
- Generating the per-app files from `colors.sh` alone, so a theme that only
  defines a palette still covers every app.

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

### stow

```sh
git clone <url> ~/Projects/macarchy && cd ~/Projects/macarchy && ./install.sh
```

`install.sh` bootstraps Homebrew, installs the packages, sets a handful of
macOS `defaults`, links `home/` into `$HOME` (via `stow` if it is on `PATH`,
otherwise plain symlinks), seeds the default theme, generates wallpapers, and
writes `~/.config/macarchy/config` from the example. It is idempotent, so
re-running is safe. `./install.sh --dry-run` prints every action without changing
anything.

To stay current, run `macarchy-update`. It pulls (fast-forward only), links any
files added upstream, removes links to files deleted upstream, and reloads only
the services whose config changed. It tells you when `install.sh` itself changed
and needs a re-run for new packages. `install.sh` also sets it to run at every
login and posts a notification when it pulls something; turn that off with
`macarchy-update --login off` or `MACARCHY_UPDATE_AT_LOGIN=false`.

To skip the packages/defaults and only link files:

```sh
stow -t "$HOME" home
```

One manual step remains: yabai and skhd cannot start until you grant
Accessibility permission.

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
macarchy release.

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
```

The example file also carries `MACARCHY_KEYS_SOURCES` and the `ws` agent
settings (`MACARCHY_AGENT_MODEL`, `MACARCHY_AGENT_EXECUTE`, `MACARCHY_MIC`,
`MACARCHY_HANDY`), each with a comment. Edit the file and re-run `theme-set`
or `theme-raycast-sync`, or restart SketchyBar, as relevant. Nothing needs a
full reinstall.

## Hooking in your own configs

macarchy does not manage Ghostty, Zellij or Neovim themselves. Add one line
to each:

| App | File | Line |
|---|---|---|
| Ghostty | `~/.config/ghostty/config` | `config-file = ?~/.config/theme/current/ghostty` |
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
| `wallpaper.jpg` | 5120x2880, generated, not tracked |
| `backgrounds/` | real images, fetched, not tracked |

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
  .config/macarchy/         config.example + lib.sh (the shared config loader) + bin/ (macarchy-keys, macarchy-update)
  .local/bin/                theme-*, macarchy-keys and macarchy-update on PATH, symlinked into .config/theme/bin and .config/macarchy/bin
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
`home/.config/yabai/yabairc`, so editing one edits both. No re-linking is needed
unless you added or removed a file.

Two kinds of files are deliberately untracked: runtime state
(`~/.config/theme/current`) and generated artifacts (wallpapers, backgrounds).
`install.sh` and `theme-maintain` (re)create both; see
[docs/theme-system.md](docs/theme-system.md#what-is-not-tracked-in-this-repo).
