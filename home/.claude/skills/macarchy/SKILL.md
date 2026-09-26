---
name: macarchy
description: Operate the user's macarchy desktop on macOS. Use when they ask about their Mac desktop, windows, tiling, Spaces, hotkeys, themes, wallpapers or backgrounds, the status bar, yabai, skhd, SketchyBar, JankyBorders, the ws voice agent, or say something looks wrong with their desktop.
---

# macarchy

This skill is about *operating* the desktop: what the hotkeys do, which
command changes what, and how to fix it when it misbehaves. To change
macarchy itself (the repo the config is symlinked from), read `AGENTS.md` in
the checkout (`~/Projects/macarchy` by default; `macarchy-doctor` prints the
path).

macarchy is yabai (tiling) + skhd (hotkeys) + SketchyBar (bar) + JankyBorders
(focus border) over native macOS Spaces, plus a theme system that restyles
the terminal, editor, Zellij, bar, borders and wallpaper together.

## Hotkeys

`alt` focuses and queries; `shift + alt` moves and mutates. `alt - /` shows
this list live, from `skhdrc`.

| Binding | Action |
|---|---|
| `alt - h / j / k / l` | focus window west / south / north / east |
| `shift + alt - h / j / k / l` | warp window in that direction |
| `ctrl + alt - h / l` | shrink / grow horizontally |
| `ctrl + alt - j / k` | grow / shrink vertically |
| `alt - =` | balance the tree |
| `alt - s` | toggle the space between **bsp** (tiled) and **stack** |
| `alt - [` / `alt - ]` | focus previous / next window in the stack |
| `shift + alt - s` | next new window **stacks** onto this one |
| `shift + alt - e` / `shift + alt - d` | next new window splits **right** / **below** |
| `alt - r` | rotate layout 90° |
| `alt - g` | toggle float, centered on a 4x4 grid |
| `alt - f` | zoom to fullscreen (within the tile tree) |
| `alt - c` | center the window in a column with gutters; again to put it back |
| `shift + alt - f` | native macOS fullscreen |
| `alt - v` | toggle split direction |
| `alt` + left-drag / right-drag | move / resize window |
| `shift + alt - t` | cycle the desktop theme |
| `shift + alt - b` | cycle the wallpaper within the current theme |
| `alt - b` | pop up `theme-bg-pick`, the current theme's backgrounds with pictures |
| `shift + alt - /` | pop up `theme-pick`, fzf theme picker with swatches |
| `shift + alt - r` | restart yabai and reload SketchyBar |
| `alt - /` | pop up `macarchy-keys`, a searchable list of every binding |
| `ctrl - <number>` | switch Space (**native macOS**, enable under Keyboard Shortcuts > Mission Control) |
| `alt - w` | `ws --voice`, the workspace agent |
| `alt - space` *(Handy, not skhd)* | transcribe (hold to talk, tap to toggle) |
| `shift + alt - space` *(Handy, not skhd)* | transcribe with post-process |

`alt - <letter>` not listed above is free for the user's app launchers in
`~/.config/skhd/skhdrc`.

## Commands

| Command | Does |
|---|---|
| `macarchy-doctor` | read-only health check; prints a fix for every problem. Run this first |
| `macarchy-update` | pull the repo, link new files, reload what changed (`--no-pull` to relink only) |
| `theme-set <name>` / `theme-next` / `theme-list` | switch theme; `readlink ~/.config/theme/current` shows the active one |
| `theme-pick` | fzf theme picker (`--list` for a plain table) |
| `theme-bg [<n>\|<name>\|next\|prev]` | list or pick a background within the current theme |
| `theme-bg-pick` | fzf background picker with pictures |
| `theme-bg-fetch` | download any missing backgrounds |
| `theme-wallpaper-enroll [--here]` | point every Space (or only the visible ones) at the theme wallpaper file |
| `theme-maintain` | regenerate fallback wallpapers, fetch backgrounds, resync Raycast |
| `macarchy-center apply\|toggle\|status` | centered column on wide displays; `status` says what it would do |
| `macarchy-keys --list` | every hotkey, as a table (`--markdown` for docs) |
| `hotkey-check` | hotkey collisions with macOS, Raycast and Handy |
| `ws "..."` / `ws -x "..."` / `ws --voice` | plain-English desktop control; dry-run unless `-x` or `MACARCHY_AGENT_EXECUTE=true` |
| `macarchy-restart` | restart yabai and reload the bar (what `shift + alt - r` runs, once the PR adding it lands) |
| `macarchy-rescue` | move off-screen windows back on screen (same PR) |

Popups open in `MACARCHY_TERMINAL` as a floating window; yabai floats them
by title.

## Config knobs

`~/.config/macarchy/config`, one `KEY=value` per line; defaults in
`~/.config/macarchy/lib.sh`, every knob explained in `config.example` next to
it. Nothing needs a reinstall: re-run `theme-set`, or
`yabai --restart-service; brew services restart borders; sketchybar --reload`
for layout values.

| Setting | Default | Meaning |
|---|---|---|
| `MACARCHY_DEFAULT_THEME` | `retro-82` | theme seeded on install, `theme-set` with no argument |
| `MACARCHY_THEME_TARGETS` | `auto` | hooks `theme-set` runs, or a list such as `ghostty zed neovim` |
| `MACARCHY_TERMINAL` | `ghostty` | terminal the popups open in: ghostty kitty alacritty iterm2 wezterm |
| `MACARCHY_COMPONENTS` | all | `themes wm bar borders keys agent`, written by `install.sh` |
| `MACARCHY_FONT` | `Hack Nerd Font` | bar font |
| `MACARCHY_SPACES` | `5` | Space indicators the bar draws (1-9) |
| `MACARCHY_WIFI_IFACE` | `en0` | interface the wifi item reads |
| `MACARCHY_KEYS_SOURCES` | `skhd ghostty zellij` | what `macarchy-keys` lists |
| `MACARCHY_UPDATE_AT_LOGIN` | `true` | `macarchy-update` LaunchAgent at login |
| `MACARCHY_GAP`, `MACARCHY_PADDING_TOP/BOTTOM/LEFT/RIGHT` | `8`, `8/20/8/8` | pixels between windows and screen edges |
| `MACARCHY_BAR_HEIGHT` | `32` | bar strip; yabai reserves it on every display |
| `MACARCHY_BORDER_WIDTH`, `MACARCHY_BORDER_STYLE` | `6`, `round` | JankyBorders focus border |
| `MACARCHY_CENTER_WIDTH`, `MACARCHY_CENTER_SINGLE` | `16:10`, `true` | centered-column width; auto-center a lone window |
| `MACARCHY_AGENT_EXECUTE`, `MACARCHY_MIC`, `MACARCHY_HANDY`, `MACARCHY_AGENT_MODEL` | see file | the `ws` agent |

Themes live in `~/.config/theme/themes/<name>/`; 22 ship (17 dark, 5 light).
The user's own theme hooks go in `~/.config/macarchy/hooks.d/`.

## When it breaks

Start with `macarchy-doctor`. It is read-only and names the fix for each
failure (missing package, service not running, Accessibility not granted,
`mru-spaces` on, font missing, popup terminal absent, no active theme).

| Symptom | Do |
|---|---|
| Windows stopped tiling, bar stale, something generally off | `shift + alt - r` (or `yabai --restart-service && sketchybar --reload`; `macarchy-restart` once it lands) |
| Wallpaper wrong on one Space | switch to that Space once (yabai enrolls it on arrival), or run `theme-wallpaper-enroll` to walk every Space (the screen flicks through them; needs `ctrl + <number>` enabled) |
| Wallpaper wrong everywhere | `theme-bg apply`, then `theme-set $(basename "$(readlink ~/.config/theme/current)")` |
| A window is off screen or lost | `macarchy-rescue` (once it lands); until then `alt - g` to float it, `alt - =` to rebalance, or drag it from Mission Control |
| Hotkeys dead | `macarchy-doctor`: is skhd running and granted Accessibility? If it is clean, check Secure Keyboard Entry: a terminal (Terminal.app, iTerm2) or a password manager holding it stops skhd from seeing keys; turn it off in that app. `tail /tmp/skhd_$USER.err.log` for the rest |
| `could not access accessibility features! abort..` in `/tmp/yabai_$USER.err.log` or the skhd log, often after `brew upgrade yabai` or `skhd` | the grant was invalidated: System Settings > Privacy & Security > Accessibility, remove and re-add `/opt/homebrew/bin/yabai` and `/opt/homebrew/bin/skhd`, then `yabai --restart-service; skhd --restart-service` |
| Space numbers drift or the bar shows the wrong Space | `defaults write com.apple.dock mru-spaces -bool false && killall Dock` (doctor checks this) |
| Theme changed but one app did not | that app's hook: `theme-set <name>` again and read its warning; Ghostty errors show in `ghostty +show-config 2>&1 >/dev/null` |
| Popup (`alt - /`, `shift + alt - /`, `alt - b`) does not open | `MACARCHY_TERMINAL` names a terminal that is installed? `fzf` installed? (doctor checks both) |
| Pictures missing in the pickers | `brew install chafa`; `theme-bg-fetch` if a theme has no backgrounds |
| `macarchy-update` failed at login | `~/Library/Logs/macarchy-update.log`; usually local edits blocking the fast-forward, or no network |
| `ws` prints instead of acting | that is the default; `ws -x` or `MACARCHY_AGENT_EXECUTE=true` |

Logs: `/tmp/yabai_$USER.err.log`, `/tmp/skhd_$USER.err.log`,
`~/Library/Logs/macarchy-update.log`.

## Constraints

- yabai runs **without the scripting addition** (SIP stays on). yabai cannot
  create or destroy Spaces, switch Spaces (`yabai -m space --focus` returns 0
  and does nothing) or move a window to another Space (`--space N` fails).
  Switch with native `ctrl + <number>` / `ctrl + arrow`; move a window by
  dragging it (hold, then `ctrl + arrow`, or to the screen edge, or into
  Mission Control), or pin the app to a Desktop from its Dock icon.
- `~/.config/{theme,yabai,skhd,sketchybar,borders,macarchy}` and
  `~/.local/bin/theme-*`, `macarchy-*`, `ws` are symlinks into the repo
  checkout. Editing them edits the repo; changing them permanently is a repo
  change, so follow `AGENTS.md` (branch, Conventional Commit, tests).
- Restarting services and switching Spaces are visible, disruptive actions on
  the user's screen; ask before doing them unless the user asked for the fix.
- Accessibility grants cannot be scripted; tell the user what to click.
