# Installing macarchy — agent instructions

You are helping a user install **macarchy** on their Mac: a macOS desktop
layer tying together yabai (tiling window manager), skhd (hotkeys),
SketchyBar (status bar), JankyBorders (focus border), a theme system that
restyles all of the above plus terminal/editor/wallpaper together, Raycast
hooks, Handy (offline speech-to-text), and `ws`, an on-device workspace
agent for plain-English or voice window/theme control. Walk the user
through the real install flow end to end, running commands where safe and
stopping for anything only a human can do (sudo, granting macOS
permissions, picking install locations).

## Ground rules

- **Ask before sudo or anything destructive.** Nothing here should need
  sudo; if a command would, stop and ask first, and explain why.
- **Don't touch dotfiles outside what `install.sh` manages** without
  asking. `install.sh` only writes under `~/.config/{theme,sketchybar,skhd,
  yabai,borders,raycast,macarchy}` and `~/.local/bin` — never shell rc
  files, git config, SSH keys, etc.
- **Check for pre-existing configs first.** `install.sh` links one file at
  a time; a real file already where a link goes (e.g. the user's own
  `~/.config/skhd/skhdrc`) is moved to `<file>.pre-macarchy`. If any of
  `~/.config/{skhd,yabai,sketchybar,borders}` already hold the user's own
  files, stop, describe what would be moved aside, and ask before
  proceeding.
- **Dry-run first, always.** Run `./install.sh --dry-run`, show the user
  the plan, get explicit confirmation before running it for real.
- **Don't guess at permission grants.** macOS Accessibility/Microphone
  grants (TCC) can't be scripted. Tell the user exactly what to click, then
  wait for them to confirm before moving on.

## Steps

### 1. Prerequisites

```sh
sw_vers -productVersion        # need macOS 13+
xcode-select -p || xcode-select --install
command -v brew
```

If Homebrew is missing, ask before installing, then use the official
one-liner:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

(`install.sh` will also offer this in step 2 if brew is still missing —
don't do it twice.)

### 2. Clone

Ask where (default: `~/Projects/macarchy`). If the path already exists,
stop and ask (reuse, `git pull`, or a different location).

```sh
git clone https://github.com/jlargs64/macarchy.git ~/Projects/macarchy
cd ~/Projects/macarchy
```

### 3. Pick components, dry run, then install

macarchy is split into parts that each install on their own. Show the user
`./install.sh --list` and ask which they want: `themes` (terminal, editor,
Neovim, wallpaper theming), `wm` (yabai + skhd), `bar` (SketchyBar),
`borders`, `keys` (hotkey popup), `agent` (`ws` + Handy). Someone who only
wants themes gets `--only themes`; someone who only wants tiling gets
`--only wm`. Pass the choice as `--only a,b,c` on both commands below (you are
not in an interactive terminal, so `install.sh` will not ask on its own). The
choice is saved to `~/.config/macarchy/config`, so later re-runs need no
flag. Skip steps below that belong to components the user did not pick.

```sh
./install.sh --only <components> --dry-run
```

Summarize the plan for the user (brew formulae/casks, macOS `defaults` it
sets, files it links, theme seeded, config written, `ws` venv). Get
confirmation, then:

```sh
./install.sh --only <components>
```

Idempotent — safe to re-run. Installs only the chosen components' brew
packages (the README's Components table lists them); with `wm`, sets four
per-user `defaults` keys (no sudo, all reversible via `defaults delete`);
links those components' files from `home/` into `$HOME`; with `themes`,
seeds the default theme and generates wallpapers; writes
`~/.config/macarchy/config`; with `agent`, sets up the `ws` venv.

### 4. Manual — Accessibility (`wm` only; can't be scripted)

1. System Settings > Privacy & Security > Accessibility
2. Add and enable **both** `/opt/homebrew/bin/yabai` and
   `/opt/homebrew/bin/skhd`

Wait for confirmation, then start services:

```sh
yabai --start-service
skhd --start-service
brew services start borders
brew services start sketchybar
```

If a service won't start: `tail /tmp/yabai_$USER.err.log` /
`/tmp/skhd_$USER.err.log`. `could not access accessibility features!
abort..` means step 4 was missed, or a binary upgrade invalidated the old
grant — remove and re-add the entry.

### 5. Manual — Handy (`agent` only, for `ws --voice`)

1. Open Handy.app once.
2. Grant **Microphone** and **Accessibility** when prompted.
3. Pick a model — Parakeet EN recommended (~700 MB).
4. Optional: enable "launch at login" in Handy's own settings.

Wait for confirmation. Handy owns `alt - space` (hold to talk, tap to
toggle) and `shift + alt - space` (transcribe + post-process) itself —
these are Handy settings, not skhd bindings.

### 6. App hooks (`themes` only)

`install.sh` prints one include line per app. Ask which terminal, editor and
multiplexer the user runs, and offer to add the line for those only, showing
the exact edit before making it: Ghostty `config-file =
?~/.config/theme/current/ghostty`; kitty `include
~/.config/theme/generated/kitty.conf`; Alacritty `import =
["~/.config/theme/generated/alacritty.toml"]` under `[general]`; Zed
`"theme": "Macarchy"`; Zellij `theme "current"`. iTerm2 is a click (make the
"macarchy" profile the default); VS Code needs nothing. If the user's
terminal is not Ghostty, set `MACARCHY_TERMINAL` (step 7) so popups open in
it.

### 7. Config file

`install.sh` already copied `config.example` to
`~/.config/macarchy/config` if it didn't exist. Walk through the knobs
with the user: `MACARCHY_DEFAULT_THEME`, `MACARCHY_FONT`,
`MACARCHY_SPACES`, `MACARCHY_RAYCAST_AUTHOR`, `MACARCHY_WIFI_IFACE`,
`MACARCHY_KEYS_SOURCES`, `MACARCHY_THEME_TARGETS`, `MACARCHY_TERMINAL`, and the `ws` settings (`MACARCHY_AGENT_EXECUTE`,
`MACARCHY_MIC`, `MACARCHY_HANDY`). Changes here never need a reinstall —
`theme-set` / `theme-raycast-sync` / a SketchyBar restart pick them up.

### 8. Verify

```sh
yabai -m query --spaces | head
pgrep -x skhd
hotkey-check          # or: macarchy-keys --list
```

Ask the user to confirm interactively: `alt - /` pops up the hotkey list,
`shift + alt - t` cycles the theme, `alt - space` (Handy) transcribes.

### 9. Wrap-up

Summarize what got installed. For the key hotkeys, **read the current
tables from `docs/window-management.md` in the cloned repo** (Focus /
Move-resize / Layout / Other) rather than repeating a fixed list here —
report what's actually in the repo just installed, not a stale copy.

## Troubleshooting

- Window management, Accessibility grants, moving windows between Spaces,
  hotkey tables: [docs/window-management.md](docs/window-management.md)
- General install options, config reference, theme contract:
  [README.md](README.md)
- The `ws` workspace agent: [docs/agent.md](docs/agent.md)
