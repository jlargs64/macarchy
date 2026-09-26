# Spec: harmonize the native menu bar with SketchyBar, then fill the bar

Prompt for an implementing session. Everything under **Findings** was
verified on the reference machine on 2026-09-26 unless marked *unverified*.
Do the phases in order. Each phase is one PR.

## Goal

The auto-hidden macOS menu bar reveals on pointer hover at the top edge,
exactly where macarchy's 32pt SketchyBar strip lives. Hovering or clicking
bar items reveals the native bar over ours. Fix that, then add the bar items
a user loses once the native bar is covered, behind a small config surface.

## Ground rules

- SIP stays on. No yabai scripting addition. No code injection.
- The `bar` component must work without the `wm` component. Nothing in the
  bar may depend on yabai being installed or running.
- macarchy writes no menu bar `defaults` keys. Auto-hide stays whatever the
  user set. `install.sh` step_defaults (`install.sh:212-220`) and
  `macarchy-uninstall:138-146` stay at their four keys; `tests/uninstall.bats:93`
  asserts that count.
- Conventional commits (release-please reads them). Work in a git worktree;
  other sessions edit the main checkout.
- Shell is x86_64 under Rosetta: `arch -arm64 bats tests/` and
  `arch -arm64 brew ...`.
- Every optional bar item exits silently when its app or daemon is missing,
  the same rule the theme hooks follow.
- Match the Omarchy look: one flat opaque strip, monochrome glyphs, no pills.

## Findings

### The reveal cannot be tuned away

- macOS has no supported setting for the menu bar reveal delay, dwell or
  hot-zone height. Scanned: NSGlobalDomain, com.apple.controlcenter,
  com.apple.dock, com.apple.WindowManager, and the dyld shared cache strings.
  The Dock's `autohide-delay` has no menu bar equivalent.
- The knobs exist only as private, process-local overrides in HIToolbox and
  AppKit (`_HIMenuBarSetAutoShowDelay`, `_setAutoHideHeight:`). Using them
  needs injection into the frontmost app. Ruled out.
- The reveal is driven by pointer position, not by what is drawn. So a thin
  `y_offset` gap does nothing, and removing the hover-to-show labels
  (`plugins/hover.sh`) does nothing either, because clicks trigger it too.
- Third-party managers (Ice, Bartender, Hidden Bar, Dozer) manage status
  items, not the reveal. None is installed.
- FelixKratz declined to handle this inside SketchyBar for performance
  reasons (SketchyBar discussion #281). Issue #228 says the answer is
  `topmost` with an opaque bar, no margin, no offset. macarchy's bar is
  already that shape (`BAR_BG` opaque, `margin=0`, `y_offset=0`).

### Window levels (SketchyBar v2.24.0 source, `bar_manager.c:291-303`)

| Setting | Level | Relative to menu bar (level 24) |
|---|---|---|
| `topmost=off` (current) | -20 kCGBackstopMenuLevel | below, so the reveal slides over the bar |
| `topmost=window` | 3 kCGFloatingWindowLevel | still below |
| `topmost=on` | 25 kCGStatusWindowLevel | above |

Only `topmost=on` covers the menu bar. Drop-down menus open at level 101, so
they still render above the bar. Menu bar status items also sit at level 25;
their stacking order against the bar on reveal is *unverified*. This is the
one fact that can sink Phase 1, so Phase 0 tests it first.

SketchyBar shifts itself down by the menu bar height only when auto-hide is
off and `topmost` is off (`bar.c:478`). With auto-hide on, nothing moves.

### Geometry (NSScreen + SLSGetDisplayMenubarHeight, this machine)

| | LG 3440x1440 (main) | MacBook 1512x982 (notch) |
|---|---|---|
| Revealed menu bar height | 30pt | 33pt |
| `safeAreaInsets.top` | 0 | 32 |
| Reserved while hidden | nothing | 32pt (notch) |
| Covered by the 32pt bar | fully | 1pt sliver may show below |

`spans-displays=0`: each display has its own menu bar and its own reveal.
`notch_display_height` (built-in display only) can lift the bar to 33 if the
sliver shows.

### yabai (v7.1.25)

- `external_bar all:32:0` (`yabairc:31`) merges with the notch height while
  auto-hide is on. With auto-hide off yabai *stacks* menu bar height plus
  external_bar (`display.c display_bounds_constrained`), so turning auto-hide
  off would open a 30pt gap on the LG. Reason not to touch auto-hide.
- `menubar_opacity` works without the scripting addition
  (`SLSSetMenuBarInsetAndAlpha` from yabai's own connection). At 0.0 the
  menu bar ignores the mouse. Open regression on Tahoe and later: it stops
  after Mission Control (yabai #2687). It also breaks SketchyBar `alias`
  items (#558) and ties the bar to yabai. Opt-in only, not the default.
- `macarchy-center` only touches left/right padding and sizes from the full
  display height (`macarchy-center:80,104,109,134,140-141`). No change in
  any option.
- `plugins/notch.sh` detects the notch from `safeAreaInsets.top > 0`
  (`notch.sh:31`), hardware geometry, independent of menu bar state. No change.

### Keyboard access to a covered menu bar

- "Move focus to menu bar" is at its default: enabled, ctrl+F2. With
  `fnState=0` that is ctrl+fn+F2 on the laptop keyboard. Its drop-downs render
  above the bar; the menu titles stay covered. *Unverified* whether it is
  comfortable to use that way.
- Raycast "Search Menu Items" searches the front app's menus.
- SketchyBar booleans accept `toggle`, so `sketchybar --bar hidden=toggle`
  hides the bar on every display. With the bar hidden, yabai still reserves
  the strip and the native bar reveals normally on hover. This is the escape
  hatch and the port of Omarchy's Super+Shift+Space "toggle top bar".

### What the native bar shows on the reference machine

Control Center, Bluetooth, Battery, Clock, Shortcuts, Raycast, Tailscale,
Handy, 1Password, Docker. Installed and relevant: Docker Desktop, Podman
Desktop, Tailscale, Ollama, Handy, 1Password, Raycast, Spotify, Zoom.
macarchy already covers Battery, Clock, Wi-Fi, volume, mic/camera, media.
Gap after covering: Bluetooth, Tailscale, containers, and everything else
via the escape hatch.

### Rejected designs, for the record

| Design | Why not |
|---|---|
| `y_offset` or taller bar with a strip above | Pointer still crosses the trigger band; breaks the notch-flush look |
| Menu bar visible, bar drawn over it | yabai stacks heights (30pt gap on the LG); macarchy would own a menu bar default it must save and restore; native items unreachable anyway |
| Bar at the bottom | Same bug moved to the auto-hidden Dock; MacBook loses 64pt; not Omarchy |
| Pointer clamp helper (CGEventTap) | Works, but needs an Accessibility grant that breaks on every swiftc rebuild. Fallback only |
| `MACARCHY_MENUBAR=hidden\|visible\|below` knob | 8 to 12h carrying every risk above |
| Hand-off daemon (hide SketchyBar when the pointer nears the top) | Bar vanishes exactly when the user aims at it |

## Phase 0: verify (manual, 10 minutes, no code)

1. `sketchybar --bar topmost=on`
2. Hover and click along the top edge of both displays for a minute,
   including the top-right of the LG where status items live.
3. Press ctrl+F2 (ctrl+fn+F2 on the laptop). Open a menu.
4. `sketchybar --bar hidden=toggle`, hover the top edge, toggle back.
5. Revert: `sketchybar --reload`.

Record: does anything native bleed through; does the MacBook show a 1pt
sliver; is ctrl+F2 usable. If status items bleed through, stop and open the
pointer-clamp fallback as its own spec instead of Phase 1.

## Phase 1: cover the menu bar (about 1.5h)

Files: `home/.config/sketchybar/sketchybarrc`, `home/.config/skhd/skhdrc`,
`docs/window-management.md`, `home/.config/macarchy/bin/macarchy-doctor`.

1. `sketchybarrc` `--bar` block (`:35-45`): add `topmost=on`. Comment: level
   25 vs the menu bar's 24, so the auto-hidden menu bar reveals underneath
   an opaque bar. Add `notch_display_height=33` only if Phase 0 showed the
   sliver. Rewrite the header comment (`:1-20`) to say the bar covers the
   native menu bar and how to reach it.
2. `skhdrc`, near the theme bindings (`:80-86`): add
   `shift + alt - m : sketchybar --bar hidden=toggle   # toggle the bar (reveals the native menu bar)`.
   Run `hotkey-check` for conflicts. `macarchy-keys` picks the trailing
   comment up automatically. Regenerate the docs table with
   `macarchy-keys --markdown`.
3. `docs/window-management.md`: new subsection "The native menu bar" under
   the bar section. Cover: why it is covered, the toggle, ctrl+F2, Raycast
   menu search, and that the existing wifi/battery/volume clicks open the
   right Settings panes.
4. `macarchy-doctor` "Status bar" section (`:216-224`): `ok` when
   `sketchybar --query bar` reports `"topmost": "on"`, `warn` otherwise with
   `sketchybar --reload` as the fix. Add one `doctor.bats` case each way; the
   `sketchybar` stub in `tests/helpers.bash` needs to echo that JSON.

Acceptance: hovering and clicking every bar item on both displays never
shows the native menu bar. `shift + alt - m` twice returns the bar with all
items and the Space indicators intact. `arch -arm64 bats tests/` green.

## Phase 2: bar item framework (about 3h)

Files: `home/.config/macarchy/lib.sh`, `home/.config/macarchy/config.example`,
`home/.config/sketchybar/sketchybarrc`, `docs/window-management.md`, tests.

1. `lib.sh` (`:13-23`): `MACARCHY_BAR_RIGHT="${MACARCHY_BAR_RIGHT:-caffeine wifi volume stats battery tray}"`,
   exported at `:34`. Order is left to right as displayed. `config.example`
   gets a commented block next to `MACARCHY_KEYS_SOURCES` (`:50-56`).
2. `sketchybarrc`: replace the fixed right-hand block (`:135-176`) with a loop
   over `MACARCHY_BAR_RIGHT` reversed (right items stack right-to-left in add
   order). Each name maps to a function `bar_item_<name>` that adds and
   configures it. Unknown names log to stderr and are skipped.
3. Drop-in directory `~/.config/sketchybar/items.d/*.sh`, sourced after the
   built-in functions and before the loop, so a user file can define a new
   `bar_item_foo` and list `foo` in the config. Mirror the wording of the
   theme `hooks.d` docs. `install.sh` creates the directory; it is not stowed.
4. Optional-app rule: each `bar_item_*` for a third-party tool returns 0
   without adding anything when its binary or app bundle is absent. Hover
   labels keep using `hover.sh`.
5. Tests: a `bar.bats` that runs `sketchybarrc` against the `sketchybar`
   stub and asserts the add order for a custom `MACARCHY_BAR_RIGHT`, that an
   unknown name is skipped, and that an `items.d` file is sourced.

Acceptance: default config renders exactly today's right side plus the tray
item. `MACARCHY_BAR_RIGHT="battery"` renders only battery.

## Phase 3: items (one PR each)

Each item: a `bar_item_<name>` function, a plugin under `plugins/`, click
behaviour, hover label via `hover.sh`, a row in the bar table in
`docs/window-management.md`, and a bats case that the plugin's output
parsing handles a fixture. Glyphs from the Nerd Font already required.

| Order | Item | Behaviour | Hours |
|---|---|---|---|
| 1 | `tray` | Glyph `⋯` at the far right. Click runs `sketchybar --bar hidden=toggle`. Hover label "menu bar". Always present; this is what makes Phase 1 safe | 1 |
| 2 | `bluetooth` | Icon: on/off, connected count. Hover: device names and battery from `blueutil --connected --format json` plus `ioreg` battery. Click: Bluetooth settings pane via `open_centered`. Requires `blueutil` (add to the bar component's brew list and doctor). Omarchy's bar has this | 2 |
| 3 | `tailscale` | `/Applications/Tailscale.app/Contents/MacOS/Tailscale status --json`: up, down, exit node. Click toggles `up`/`down`. Hidden when the app is absent | 1.5 |
| 4 | `containers` | Running count across `docker ps -q` and `podman ps -q`, each only if its daemon answers within 1s. Hidden when both are absent or stopped. Click opens Docker Desktop (or Podman Desktop if only that exists) | 1.5 |
| 5 | `updates` | Dot when `brew outdated --quiet` is non-empty or `macarchy-update --check` reports a newer tag (add `--check` if missing). `update_freq=3600`. Click runs `macarchy-update` in `macarchy-popup`. Omarchy's bar has an update indicator | 2 |

Not adding: a Handy item (the mic item already turns red while recording),
1Password and Raycast (keyboard tools), a front-app name (not Omarchy).
Later if asked: Focus mode toggle, keyboard layout, Zoom meeting indicator.

## Phase 4: close out (about 2h)

1. `README.md` component table row for the bar: mention the covered menu
   bar, the toggle, and `MACARCHY_BAR_RIGHT`.
2. `docs/window-management.md` bar table lists every built-in item with its
   click and hover behaviour and which app it needs.
3. `macarchy-uninstall`: nothing new to reverse (no defaults were written).
   Confirm `tests/uninstall.bats` still asserts four keys.
4. `install.sh --only bar --dry-run` shows the `items.d` mkdir and the
   `blueutil` install. Add an `install.bats` case.

## Open questions to settle during Phase 0

1. Do level-25 status items draw above the `topmost=on` bar on reveal?
2. Does the MacBook show a 1pt sliver under the bar?
3. Is ctrl+F2 usable with the titles covered, or does the tray toggle need to
   be the documented primary route?
