# Window management

Tiling windows on top of **native macOS Spaces**, without touching SIP.

| Component | Role |
|---|---|
| [yabai](https://github.com/koekeishiya/yabai) | tiles windows inside each Space |
| [skhd](https://github.com/koekeishiya/skhd) | hotkeys that drive yabai |
| [SketchyBar](https://github.com/FelixKratz/SketchyBar) | status bar, incl. Space indicators |
| [JankyBorders](https://github.com/FelixKratz/JankyBorders) | border on the focused window |

Colors for the bar and the borders come from the [theme
system](theme-system.md); neither has hardcoded colors.

## The SIP decision

yabai has an optional **scripting addition** that injects into Dock.app. It
requires partially disabling System Integrity Protection. **This setup does not
use it**, and nothing here asks you to run `csrutil`.

What still works without it — the things you actually use:

- tiling, splitting, resizing, rebalancing, rotating layouts
- focusing windows by direction
- floating and zoom-fullscreen toggles
- window rules
- signals that keep SketchyBar in sync

What you give up:

- creating and destroying Spaces from yabai (use Mission Control)
- moving a window to another Space from yabai (drag it, or use the native
  keyboard shortcut)
- `yabai -m space --focus` (use `ctrl + <number>`)

That trade is the point of the setup: macOS keeps owning Spaces, yabai only
arranges windows inside one.

## Setup on a new machine

`./install.sh` (or `stow -t "$HOME" home`, plus `brew install` the packages
yourself) writes the configs and installs the binaries, but **macOS will not
let either daemon run until you grant Accessibility permission by hand.**

1. System Settings > Privacy & Security > Accessibility
2. Add and enable both:
   - `/opt/homebrew/bin/yabai`
   - `/opt/homebrew/bin/skhd`
3. Start everything:

   ```sh
   yabai --start-service
   skhd --start-service
   brew services start borders
   brew services start sketchybar
   ```

4. Open Handy.app once and grant it Microphone + Accessibility when
   prompted, then pick a model (Parakeet EN recommended, ~700 MB). This is
   separate from yabai/skhd's Accessibility grant above, and is what
   `ws --voice` (see [docs/agent.md](agent.md)) transcribes through.

If a service refuses to start, the reason is in its log:

```sh
tail /tmp/yabai_$USER.err.log
tail /tmp/skhd_$USER.err.log
```

`could not access accessibility features! abort..` means step 2 was skipped, or
the binary was upgraded and macOS invalidated the old grant — remove the entry
and re-add it.

## Keybindings

`alt` focuses and queries. `shift + alt` moves and mutates.

### Focus

| Binding | Action |
|---|---|
| `alt - h / j / k / l` | focus window west / south / north / east |

### Move and resize

| Binding | Action |
|---|---|
| `shift + alt - h / j / k / l` | warp window in that direction |
| `ctrl + alt - h / l` | shrink / grow horizontally |
| `ctrl + alt - j / k` | grow / shrink vertically |

### Layout

| Binding | Action |
|---|---|
| `alt - =` | balance the tree |
| `alt - s` | toggle the space between **bsp** (tiled) and **stack** |
| `alt - [` / `alt - ]` | focus previous / next window in the stack |
| `shift + alt - s` | next new window **stacks** onto this one |
| `shift + alt - e` / `shift + alt - d` | next new window splits **right** / **below** |
| `alt - r` | rotate layout 90° |
| `alt - g` | toggle float, centered on a 4×4 grid |
| `alt - f` | zoom to fullscreen (within the tile tree) |
| `alt - c` | center the window in a column with gutters on both sides; again to put it back (see [Wide displays](#wide-and-external-displays)) |
| `shift + alt - f` | native macOS fullscreen |
| `alt - v` | toggle split direction |
| `alt - <letter>` | free for your app launchers (except `w`, `space` -- see below), see skhdrc |

### Mouse

| Gesture | Action |
|---|---|
| `alt` + left-drag | move window |
| `alt` + right-drag | resize window |

### Other

| Binding | Action |
|---|---|
| `shift + alt - t` | cycle the desktop theme |
| `shift + alt - b` | cycle the wallpaper within the current theme |
| `shift + alt - /` | pop up `theme-pick` — fzf theme picker with swatch previews |
| `shift + alt - r` | restart yabai and reload SketchyBar |
| `alt - /` | pop up `macarchy-keys` — a searchable list of every skhd binding |
| `ctrl - <number>` | switch Space (**native macOS**, see below) |
| `alt - w` | `ws --voice` — the workspace agent, see [docs/agent.md](agent.md) |
| `alt - space` *(Handy, not skhd)* | Handy: transcribe (hold to talk, tap to toggle) |
| `shift + alt - space` *(Handy, not skhd)* | Handy: transcribe with post-process |

The last two rows aren't skhd bindings — Handy runs its own global-hotkey
listener (it needs hold-to-talk key-down/key-up semantics skhd doesn't give
it) and owns `alt - space` / `shift + alt - space` by default, configurable
in Handy > Settings > Shortcuts. `ws --voice` was moved to `alt - w` to stay
out of the way; `hotkey-check` knows about Handy's defaults too.

`ctrl + <number>` is not a skhd binding — it is macOS's own shortcut, and it is
off by default for Spaces past the first few. Enable it in
System Settings > Keyboard > Keyboard Shortcuts > Mission Control.

## Discovering hotkeys

`alt - /` pops up `macarchy-keys`, a which-key style fuzzy-searchable list of
every binding in `skhdrc`, in a small floating Ghostty window (kept off the
tiling layer by the yabai rule in `yabairc`). Type to filter, Enter runs the
selected binding's command, Esc closes it.

From a terminal:

```sh
macarchy-keys --list       # aligned table, no fzf
macarchy-keys --markdown   # GitHub markdown table, grouped by source and
                            # section -- this is how the tables above get
                            # regenerated
macarchy-keys --popup      # what alt - / runs
```

Descriptions come straight out of `skhdrc`: a trailing `# comment` on the
binding line, or the comment line(s) directly above it if there is no
trailing one. Add or edit a hotkey with a `# comment` and `macarchy-keys`
picks it up automatically — no separate list to keep in sync.

`macarchy-keys` also lists Ghostty's `keybind` lines and Zellij's
`keybinds { ... }` block, when those config files exist, so the same picker
covers every keyboard shortcut on the machine, not just window management.
Which sources it shows is controlled by `MACARCHY_KEYS_SOURCES` (default
`skhd ghostty zellij`, settable in `~/.config/macarchy/config`), or narrow it
for one run with `macarchy-keys --source <name>` (repeatable, or
comma-separated, e.g. `--source zellij` or `--source ghostty,zellij`). A
Ghostty or Zellij binding can't be run from outside those programs, so Enter
on one of those rows copies its key to the clipboard and prints it instead of
executing anything.

## Wide and external displays

Three things change on a monitor that is not the MacBook screen. All of them
happen without the scripting addition.

**The bar strip.** yabai excludes the 32px notch strip on the built-in display
by itself, but an external display has no notch and, with the menu bar
auto-hidden, nothing excluded at all, so windows would cover the bar.
`yabairc` sets `external_bar all:32:0`, which reserves the strip on every
display; on the notch display yabai merges the two heights instead of stacking
them, so nothing moves there.

**The clock sits on the midpoint.** SketchyBar's `q` and `e` positions hug the
notch, and on a display without one they hug the exact center, which leaves a
`q` clock ending at the midpoint. The clock and the mic / camera / now-playing
items therefore exist twice, the second copy at `center`, and
`plugins/notch.sh` shows each set only on its own displays. It re-runs on Space
and display changes, so plugging a monitor in or out is picked up.

**A lone window is centered in a column.** Two windows side by side on an
ultrawide is a lot of neck travel, and one window across all 3440px is worse.
`macarchy-center` pads the sides of a Space so the tile tree lays out in a
centered column with wallpaper gutters:

- automatically, whenever a Space shows a single tile (one window, or a stack)
- on demand, with `alt - c`, for the focused window on a busier Space. It
  zooms to the column; `alt - c` again drops it back into its tile. The window
  never leaves the tree (it is `zoom-fullscreen` with side padding), so it
  returns exactly where it was.

Both are driven by yabai signals in `yabairc`, plus a re-check after `alt - f`
and `alt - g`. Two settings in `~/.config/macarchy/config`:

| Setting | Default | Meaning |
|---|---|---|
| `MACARCHY_CENTER_WIDTH` | `16:10` | Column width, as an aspect ratio relative to the display height (2304px on a 3440x1440 ultrawide) or a pixel count (`2200`). A display narrower than the column gets no gutters, so the default leaves a 16:9 monitor and the MacBook screen alone. |
| `MACARCHY_CENTER_SINGLE` | `true` | `false` turns off the automatic centering; `alt - c` still works. |

`macarchy-center status` prints what it would do for each visible Space.

**Moving a window to another display.** Drag it there, with or without `alt`
held; yabai re-tiles it on the display it lands on. Between Spaces it is the
native mechanisms below, since that is the part yabai cannot do without the
scripting addition.

## Moving windows between Spaces

yabai cannot do this without the scripting addition. Both commands *look* like
they work and do not:

```sh
yabai -m space --focus 1          # returns 0, focus does not change
yabai -m window <id> --space 1    # "could not locate the window to act on!"
```

That is tested behaviour on this machine, not a guess. So use the native macOS
mechanisms — all of these work today:

| How | What to do |
|---|---|
| **Drag + `ctrl`+arrow** | Start dragging the window's title bar, then press `ctrl+←` / `ctrl+→` while still holding. The window travels with you. Fastest method. |
| **Drag to screen edge** | Drag the window to the left or right edge and hold. `workspaces-edge-delay` is set to `0.05`, so it flips almost instantly. |
| **Mission Control** | Drag the window to the top of the screen, then drop it on a desktop thumbnail. |
| **Pin an app** | Right-click its Dock icon > Options > Assign To > Desktop N. Per-app, not per-window. |

Switching Spaces without moving anything is `ctrl+1`..`ctrl+4`, or
`ctrl+←`/`ctrl+→`. All of those shortcuts are already enabled here; if they ever
stop working, re-check System Settings > Keyboard > Keyboard Shortcuts >
Mission Control.

## Layout configuration

`~/.config/yabai/yabairc`, in full:

- **bsp** layout, new windows open as `second_child`, no auto-balance
- 8px gaps and padding on every side except the bottom, which is 20px so the
  6px JankyBorders border does not sit on the screen edge. `external_bar
  all:32:0` reserves the 32px SketchyBar strip on every display (yabai only
  excludes it by itself on the notch display), so no extra top padding is
  needed to clear the bar
- focus does not follow the mouse, in either direction
- `window_border off` — JankyBorders draws the border instead
- never tiled: System Settings, System Information, Activity Monitor,
  Calculator, Archive Utility, Finder copy dialogs, 1Password, Raycast

To stop yabai managing another app, add a rule and restart:

```sh
yabai -m rule --add app="^App Name$" manage=off   # try it live
# then add the same line to home/.config/yabai/yabairc in this repo to persist
# it -- with stow, ~/.config/yabai/yabairc IS that file, so editing either one
# edits both
```

## Space indicators in the bar

The bar shows Spaces 1–5 as plain numbers, Omarchy-style. Brightness carries
the state: the focused Space is full foreground and bold, Spaces with windows
are dim, empty Spaces are faint.

Two event sources keep it current:

- `yabai_window_change` — a custom SketchyBar event, triggered by the signals in
  `yabairc` on window create / destroy / focus and on space change.
- `space_change` — SketchyBar's own built-in event for native Space switches.

`plugins/space.sh` asks yabai which Space has focus, and falls back to
SketchyBar's `$SELECTED` when yabai is not running. So the bar stays correct even
with yabai stopped or lacking permission — it just cannot tell occupied Spaces
from empty ones, so every unfocused Space renders as occupied.

Clicking a Space runs `plugins/space_click.sh`, which tries
`yabai -m space --focus` (fails without the scripting addition) and falls back to
synthesizing the native `ctrl + <number>` keystroke.

## Caffeine toggle in the bar

The coffee-cup icon on the right toggles `caffeinate -dims`: display, system
and disk stay awake and idle sleep is blocked until it is clicked again. Bright
cup = awake, dim crossed-out cup = normal sleep. The icon reflects any
`caffeinate` you are running, including one typed into a terminal. Clicking
"off" kills the one the bar started (PID in `~/.cache/sketchybar/caffeinate.pid`,
so it survives `sketchybar --reload`), or failing that all of yours.

## Desktop feel

`install.sh`'s macOS-defaults step sets four per-user `defaults` keys.
None need sudo, and each is reversible with `defaults delete`.

| Key | Value | Why |
|---|---|---|
| `com.apple.dock expose-animation-duration` | `0.1` | Space-switch slide, halved from the 0.2s default. The main fix for swipes feeling floaty. |
| `com.apple.dock workspaces-edge-delay` | `0.05` | Hover time before a drag at the screen edge flips Space, down from ~0.75s. |
| `com.apple.dock mru-spaces` | `false` | Stops macOS reordering Spaces by recent use. **Required** — yabai and the bar's Space indicators both assume Space N stays Space N. |
| `NSGlobalDomain NSWindowResizeTime` | `0.001` | Instant AppKit window resize. |

If switching Spaces still feels floaty at 0.1s, the stronger option is
System Settings > Accessibility > Display > **Reduce Motion**, which replaces
the slide with a near-instant crossfade. It is left off by default because it
flattens animations system-wide, not just for Spaces.

To go back to stock:

```sh
defaults delete com.apple.dock expose-animation-duration
defaults delete com.apple.dock workspaces-edge-delay
killall Dock
```
