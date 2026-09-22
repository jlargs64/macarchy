# Theme system

One command restyles the whole desktop. `theme-set retro-82` changes Ghostty,
Zellij, Neovim, SketchyBar, JankyBorders and the wallpaper together, and most of
it repaints without restarting anything.

This is [Omarchy](https://omarchy.org)'s mechanism ported to macOS.

## The mechanism

Every app reads its colors from a fixed path, `~/.config/theme/current`. That
path is a **symlink**. Switching themes repoints the symlink and pokes each app
to re-read its config.

```
~/.config/theme/
├── bin/
│   ├── theme-set            switch to a named theme
│   ├── theme-list           print available themes, alphabetically
│   ├── theme-next           cycle to the next theme, wrapping
│   ├── theme-wallpaper      render a wallpaper from a theme's palette
│   └── theme-raycast-sync   regenerate the Raycast dropdown from theme-list
│
├── current -> themes/retro-82      ← THE symlink. Everything reads through it.
│
└── themes/<name>/
    ├── ghostty       Ghostty config fragment
    ├── zellij.kdl    a `themes { current { ... } }` block
    ├── neovim.lua    a LazyVim plugin spec
    ├── colors.sh     the palette, as shell exports
    ├── borders       JankyBorders settings
    └── wallpaper.jpg 5120x2880, generated (not committed)
```

The indirection is the whole trick: no app knows a theme's name. Each one points
at `current/<its file>` forever, and only the symlink moves.

## Adding a theme

Fast path, for any theme in [Omarchy's catalogue](https://github.com/omacom/omarchy/tree/quattro/themes)
(dark or light):

```
theme-port <name> [--src DIR] [--allow-light] --out home/.config/theme/themes
```

`theme-port` fetches `themes/<name>/{colors.toml,neovim.lua}` from
`omacom/omarchy` at a pinned rev and emits the five files below in this
repo's shape (`--src DIR` reads from a local Omarchy checkout instead of
curling GitHub, useful offline or against a checkout already pinned to the
rev you want). Light themes (`colors.toml` with `mode = "light"`) are
refused unless you pass `--allow-light` — the SketchyBar and border colour
derivations were written assuming a dark background, so a light port needs a
manual check afterward (see [omarchy-port.md](omarchy-port.md)). Always
point `--out` at this repo's `home/.config/theme/themes`, not the live
`~/.config/theme/themes`, so the new theme lands under version control
directly. `theme-port` cannot always resolve a plugin repo from upstream's
`neovim.lua` (an unusual spec shape, or a colorscheme with no dedicated
plugin) — it emits a `TODO/fill-in-colorscheme-plugin` placeholder in that
case; see below for the fallback.

Manual path, or to finish a `theme-port` output with a `TODO` placeholder:

1. `mkdir ~/.config/theme/themes/<name>`
2. Copy the six files from an existing theme and edit them. `colors.sh` must
   export `BG FG ACCENT ACCENT2 MUTED RED GREEN YELLOW BLUE MAGENTA CYAN`
   as bare hex (no `#`, no `0x`), plus `THEME_NAME` and `NVIM_COLORSCHEME`.
   If the theme has no upstream Neovim plugin, follow retro-82's pattern:
   drive `nvim-mini/mini.base16` directly from the palette instead of a
   `TODO` plugin entry (several of the 16 quattro-branch themes ported this
   way have no upstream `nvim` plugin at all and use this local
   `mini.base16` pattern — see [omarchy-port.md](omarchy-port.md)).
3. `theme-set <name>` — the wallpaper is generated on first use.
4. `theme-raycast-sync` to add it to the Raycast dropdown.
5. Copy the new theme directory into this repo, under `home/.config/theme/themes/<name>/`,
   and `git add` it there (see [README.md](../README.md)).

`NVIM_COLORSCHEME` must be a name Neovim can pass to `:colorscheme`, which is
not always the plugin's name — see the table below.

## What `theme-set` actually does

1. Validates the theme exists (lists the available ones on error).
2. Repoints `~/.config/theme/current`.
3. Sources the new `colors.sh`.
4. `sketchybar --reload`.
5. `borders active_color=0xff$ACCENT inactive_color=0xff$MUTED`.
6. `touch ~/.config/zellij/config.kdl` — nudges Zellij's config watcher.
7. Finds every running Neovim server socket and sends
   `<Cmd>colorscheme $NVIM_COLORSCHEME<CR>` to each.
8. Sets the wallpaper via System Events, generating it first if missing.
9. Asks Ghostty to reload by sending it `cmd+shift+,`.

Steps 4 through 9 are all best-effort: a missing or stopped app is skipped, never
fatal.

## What reloads live, and what does not

| App | Behaviour |
|---|---|
| SketchyBar | live |
| JankyBorders | live |
| Wallpaper | live, on every Space that already points at the fixed path (see below) |
| Zellij | live — a running session repaints in place |
| Neovim | live in every running instance, via `--remote-send` |
| Ghostty | needs `cmd+shift+,`; `theme-set` sends it, but see below |

Ghostty is the one that can need a keypress. `theme-set` activates it and sends
`cmd+shift+,` via AppleScript, which requires Automation permission
(System Settings > Privacy & Security > Automation). The first switch pops that
prompt and **blocks until you answer it**. If the keystroke does not land,
`theme-set` prints `cmd+shift+, in Ghostty` and you press it yourself. Terminals
are never killed.

## Wallpapers

Each theme has a `backgrounds/` directory of real images, pulled from upstream
[Omarchy](https://github.com/basecamp/omarchy) by `theme-bg-fetch`. Omarchy
ships them at 5120x2880 already.

| Theme | Backgrounds | Default |
|---|---|---|
| retro-82 | 9 | `01-quattro.jpg` |
| kanagawa-wave | 1 | `01-great-wave.jpg` |
| catppuccin-mocha | 3 | `01-waves.jpg` |

Two of those defaults come from a different upstream theme than you would
expect, on purpose:

- **retro-82 → quattro**, which is Omarchy's *tokyo-night* background. Omarchy
  has its own `retro-82` theme, but its backgrounds are teal and orange, and
  this retro-82 uses the magenta / cyan / amber palette from the spec. Quattro's
  synthwave magenta and amber match it; Omarchy's own set does not. Its 8
  images are still included, as entries 02–09.
- **kanagawa-wave → The Great Wave**, Hokusai's print off Kanagawa. The theme
  is named after it.

### Choosing one

```sh
theme-bg              # list this theme's backgrounds, * marks the active one
theme-bg 3            # pick by number
theme-bg totoro       # pick by substring
theme-bg next | prev  # cycle
theme-bg-fetch        # re-download anything missing
```

`shift + alt - b` cycles the background within the current theme;
`shift + alt - t` cycles the theme itself.

The choice is remembered per theme in `themes/<name>/.bg`, so switching away
and back keeps the image you picked.

If a theme has no `backgrounds/` directory, `theme-set` falls back to
`wallpaper.jpg` — a gradient generated from that theme's own palette by
`theme-wallpaper` (retro-82's gets faint CRT scanlines). That is the fallback
now, not the default.

Backgrounds are ~19 MB and are **not** committed. `theme-bg-fetch` runs as part
of `install.sh` (and of `theme-maintain`) and skips whatever already exists.

## Wallpapers and macOS Spaces

macOS stores the wallpaper **per Space**, and AppleScript can only reach the
Space that is active — System Events exposes one "desktop" per *display*, not
per Space. yabai cannot switch Spaces without the scripting addition either.

So every Space points at one fixed path:

```
~/.config/theme/wallpaper-current.jpg
```

Applying a background copies the chosen image over that file and restarts
`WallpaperAgent`. macOS re-reads the file's contents, so **every enrolled Space
repaints at once** — confirmed in use, not just in theory. Only the file changes;
the path each Space points at never does.

**One-time setup:** run `theme-wallpaper-enroll` once. It walks every Space
using the native `ctrl+<number>` shortcut, points each at the fixed path, and
returns you to where you started. Your screen visibly flicks through the Spaces
while it runs. That shortcut must be enabled in System Settings > Keyboard >
Keyboard Shortcuts > Mission Control.

You only need this once. After enrolment, `theme-set` and `theme-bg` repaint
all Spaces together. Run it again only if you add a Space, since a new one
starts with whatever wallpaper macOS gives it.

## The themes

### catppuccin-mocha, kanagawa-wave

Upstream everywhere — the Ghostty built-in theme, the official Zellij theme
copied from zellij's repo, the upstream Neovim plugin. Nothing hand-rolled.

### retro-82

Custom. 1982 arcade CRT: near-black phosphor background, amber primary, hot
magenta and electric cyan accents, desaturated enough to read for eight hours.

16-slot base16 palette:

```
00 0b0a0f  01 15121c  02 221c2e  03 3a3148
04 6b5a80  05 f2c66d  06 fff0c0  07 ffffff
08 ff4f6d  09 ff9f43  0A f2c66d  0B 7bff7b
0C 3ef1ff  0D 4fa8ff  0E ff59f0  0F c98cff
```

Everything is derived from those 16 values:

- **Ghostty** — ANSI 8..15 are the canonical slots verbatim; ANSI 0..7 are the
  same hues darkened 15% so bold text separates from normal text.
- **Zellij** — the simple `fg`/`bg`/named-color theme format.
- **Neovim** — `mini.base16` fed the palette directly. Because `mini.base16`
  does not register a colorscheme name, the setup call lives in a tiny local
  plugin, `themes/retro-82/nvim-retro82/colors/retro82.lua`, which sets
  `vim.g.colors_name = "retro82"` afterwards so `:colorscheme retro82` works.
- **Wallpaper** — a `0b0a0f → 221c2e` gradient with every 4th row darkened 35%,
  for faint scanlines.

## Per-app wiring

Each app was wired once. None of it needs touching again.

**Ghostty** (`~/.config/ghostty/config`) ends with a managed block:

```
config-file = ?~/.config/theme/current/ghostty
```

The leading `?` makes the include optional, so Ghostty still starts if the theme
directory is missing. Keys the theme system owns (`font-family`, `font-size`,
padding, titlebar style) are set in that block; earlier definitions of those keys
were commented out and prefixed `# [theme-system] was:`.

**Zellij** — `config.kdl` sets `theme "current"`, and
`~/.config/zellij/themes/current.kdl` is a symlink into the theme directory.

**Neovim** — `~/.config/nvim/lua/plugins/theme.lua` is a symlink to
`current/neovim.lua`. The previous `colorscheme.lua` (catppuccin-frappe) was
removed; it survives at `~/.config/nvim/lua/plugins/colorscheme.lua.bak` and in
this repo's git history.

**Neovim, part two** — `~/.config/nvim/lua/plugins/theme-plugins.lua` is a
plain tracked file (not a symlink) that declares every shipped theme's
colorscheme plugin with `lazy = true`. Without it, lazy.nvim would only ever
see the plugins of the *active* theme, which means `lazy-lock.json` churns on
every switch and the first switch to a theme has to clone its plugin. The
active theme's spec re-declares the same repo with `lazy = false` and a
priority; lazy.nvim merges the two.

The seven themes that drive `nvim-mini/mini.base16` locally (`ethereal`,
`last-horizon`, `lupine`, `miasma`, `ristretto`, `vantablack`, `white` — see
[omarchy-port.md](omarchy-port.md)) only need the one `mini.base16` entry,
not a per-theme plugin. Current full list:

```lua
{ "nvim-mini/mini.base16", version = false, lazy = true },
{ "rebelot/kanagawa.nvim", lazy = true },
{ "catppuccin/nvim", lazy = true },
{ "folke/tokyonight.nvim", lazy = true },
{ "ellisonleao/gruvbox.nvim", lazy = true },
{ "EdenEast/nightfox.nvim", lazy = true },  -- nord uses nightfox's "nordfox" variant
{ "neanias/everforest-nvim", lazy = true },
{ "kepano/flexoki-neovim", lazy = true },
{ "bjarneo/hackerman.nvim", lazy = true },
{ "bjarneo/aether.nvim", lazy = true },
{ "omacom/lumon.nvim", lazy = true },
{ "tahayvr/matteblack.nvim", lazy = true },
{ "ribru17/bamboo.nvim", lazy = true },
{ "rose-pine/neovim", name = "rose-pine", lazy = true },
{ "ficd0/ashen.nvim", lazy = true },
```

**SketchyBar** — `sketchybarrc` sources the theme palette on its first line, and
`~/.config/sketchybar/colors.sh` derives every variable the bar and its plugins
use (`BAR_BG`, `WHITE`, `FG_DIM`, `FG_FAINT`, …) from `BG`/`FG`. The bar is
monochrome like Omarchy's waybar, so only `BG`, `FG` and `RED` (near-empty
battery) are actually read; `ACCENT` and the rest go to borders and the apps.

**borders** — `bordersrc` sources the palette and sets `active_color` from
`ACCENT`, `inactive_color` from `MUTED`.

## Keybindings

| Where | Binding | Action |
|---|---|---|
| skhd | `shift + alt - t` | `theme-next` |
| skhd | `shift + alt - /` | `theme-pick --popup` |
| Raycast | "Set Theme" | dropdown of all themes |
| Ghostty | `cmd + shift + ,` | reload config |

The Raycast dropdown is generated, not hand-maintained — run
`theme-raycast-sync` after adding a theme.

## Picking a theme

`shift + alt - /` (or `theme-pick` from a terminal) opens an fzf picker in a
small floating Ghostty window (the same popup pattern `alt - /` uses for
`macarchy-keys`). Each row is a truecolor swatch strip for that theme, its
name, a light/dark tag, and a marker on whichever theme is currently active.
Enter applies the selected theme via `theme-set`; Esc cancels without
changing anything.

```sh
theme-pick             # fzf picker
theme-pick --list      # aligned "name  mode  BG  FG  ACCENT" table, no fzf
theme-pick --preview NAME  # print NAME's full palette and nvim colorscheme
theme-pick --popup     # relaunch the picker in a floating Ghostty window
theme-pick --rows      # raw fzf input rows, no fzf
theme-pick --dry-run   # picker mode, print the chosen theme instead of applying it
```

Requires `fzf`, already installed by `install.sh`.

## Gotchas worth knowing

**Ghostty theme names are exact.** `theme = catppuccin-mocha` silently fails
with a "not found" dialog; the real name is `Catppuccin Mocha`. Check with
`ghostty +list-themes`.

**`g:colors_name` does not always match `NVIM_COLORSCHEME`.** kanagawa.nvim
reports `kanagawa` even when loaded as `kanagawa-wave`. The colors are correct;
only the reported name differs.

| Theme | `NVIM_COLORSCHEME` | reported `g:colors_name` |
|---|---|---|
| catppuccin-mocha | `catppuccin-mocha` | `catppuccin-mocha` |
| kanagawa-wave | `kanagawa-wave` | `kanagawa` |
| retro-82 | `retro82` | `retro82` |

**Neovim's server socket is not in `/tmp` on macOS.** It is under `$TMPDIR`
(`/var/folders/...`). And `/tmp` is itself a symlink, so `find /tmp` needs `-L`
to descend. `theme-set` searches `$TMPDIR`, `/tmp` and `/private/tmp`.

**The scripts must run on bash 3.2.** macOS ships bash 3.2.57 and
`#!/usr/bin/env bash` finds it before any Homebrew bash. No `mapfile`, no
associative arrays.

## What is not tracked in this repo

Two things are deliberately not in git, and not written by `stow`:

- **`current`** is runtime state — `theme-set` rewrites it constantly.
  `install.sh` seeds it to `$MACARCHY_DEFAULT_THEME` on a new machine only if
  it is missing, and never touches it again.
- **`wallpaper.jpg`** is generated. ~3 MB of deterministic binaries do not
  belong in git; `theme-wallpaper` renders it from that theme's `colors.sh`.

Both are produced by `install.sh` on first setup, and by `theme-maintain`
afterward — run it after editing a theme's palette or adding/removing a
theme to regenerate wallpapers, re-fetch backgrounds, and resync Raycast.
If you are consuming macarchy via chezmoi's archive external (see
[README.md](../README.md)), add a `run_onchange_` script of your own that
execs `theme-maintain`, or just run it by hand.

## Troubleshooting

```sh
readlink ~/.config/theme/current            # which theme is active
ghostty +show-config | grep -E 'foreground|background'
ghostty +show-config 2>&1 >/dev/null        # theme-name errors show here
nvim --headless -c 'lua print(vim.g.colors_name) vim.cmd("qa!")'
sketchybar --query bar | jq .color          # expect 0xff<BG>
theme-list                                  # what is installed
```

If Ghostty shows a "Configuration Errors" dialog after a switch, the theme's
`ghostty` fragment names a theme Ghostty does not have. Compare against
`ghostty +list-themes`.
