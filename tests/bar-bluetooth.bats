#!/usr/bin/env bats
# The bluetooth bar item: plugins/bluetooth.sh runs against stubbed blueutil
# and system_profiler fed from tests/fixtures/bluetooth, and its
# `sketchybar --set` argv is checked. items/bluetooth.sh must add nothing
# when blueutil is missing.
#
# The fixtures are trimmed from real blueutil 2.14.0 and
# `system_profiler SPBluetoothDataType -json` output (macOS 26, 2026-09-26).
# The AirPods were paired but idle at capture time; they are moved into the
# connected lists, with their real field names, to cover the battery path.

setup() {
  load helpers
  common_setup
  mkdir -p "$HOME/.config/theme"
  ln -s "$REPO/home/.config/theme/themes/nord" "$HOME/.config/theme/current"
  FIX="$REPO/tests/fixtures/bluetooth"
  export FIX BT_POWER=1 BT_CONNECTED="$FIX/connected-none.json"
  stub blueutil 'case "$1" in --power) echo "$BT_POWER" ;; --connected) cat "$BT_CONNECTED" ;; esac'
  stub system_profiler 'cat "$FIX/system-profiler.json"'
  stub ioreg
  # The plugin puts /opt/homebrew/bin first on PATH, which would find the real
  # sketchybar and blueutil ahead of the stubs. Exported functions win over
  # any PATH lookup, so route both through the stubs that way.
  sketchybar() { "$STUBS/sketchybar" "$@"; }
  blueutil() { "$STUBS/blueutil" "$@"; }
  export -f sketchybar blueutil
  export CONFIG_DIR="$REPO/home/.config/sketchybar" NAME=bluetooth
}

plugin() { SENDER="${1:-routine}" run bash "$CONFIG_DIR/plugins/bluetooth.sh"; }

@test "power off: dim off glyph, no device query" {
  BT_POWER=0 plugin
  [ "$status" -eq 0 ]
  grep -q '^sketchybar --set bluetooth icon=󰂲 icon.color=0x99[0-9a-f]\{6\} label=Bluetooth off ' "$STUB_LOG"
  run ! grep -q -- '--connected' "$STUB_LOG"
  run ! grep -q '^system_profiler' "$STUB_LOG"
}

@test "power on, nothing connected: plain glyph, no battery lookup" {
  plugin
  [ "$status" -eq 0 ]
  grep -q '^sketchybar --set bluetooth icon=󰂯 icon.color=0xff[0-9a-f]\{6\} label=No devices ' "$STUB_LOG"
  run ! grep -q '^system_profiler' "$STUB_LOG"
}

@test "two connected: count on the icon, names and battery in the label" {
  BT_CONNECTED="$FIX/connected-two.json" plugin
  [ "$status" -eq 0 ]
  # AirPods show the lower bud; the MX Master reports no battery at all
  grep -q '^sketchybar --set bluetooth icon=󰂱 2 icon.color=0xff[0-9a-f]\{6\} label=MX Master 3S M, Justins AirPods Pro v2 80% label.color=' "$STUB_LOG"
}

@test "two connected without system_profiler output: names only" {
  stub system_profiler 'exit 1'
  BT_CONNECTED="$FIX/connected-two.json" plugin
  [ "$status" -eq 0 ]
  grep -q '^sketchybar --set bluetooth icon=󰂱 2 .* label=MX Master 3S M, Justins AirPods Pro v2 label.color=' "$STUB_LOG"
}

@test "blueutil failing leaves the item untouched" {
  BT_POWER="" plugin
  [ "$status" -eq 0 ]
  run ! grep -q '^sketchybar' "$STUB_LOG"
}

@test "hover toggles the label without querying Bluetooth" {
  plugin mouse.entered
  [ "$status" -eq 0 ]
  plugin mouse.exited
  [ "$status" -eq 0 ]
  [ "$(grep '^sketchybar' "$STUB_LOG")" = "sketchybar --set bluetooth label.drawing=on
sketchybar --set bluetooth label.drawing=off" ]
  run ! grep -q '^blueutil' "$STUB_LOG"
}

@test "bar_item_bluetooth adds nothing when blueutil is absent" {
  rm "$STUBS/blueutil"
  unset -f blueutil
  PLUGIN_DIR="$CONFIG_DIR/plugins"
  # shellcheck source=../home/.config/sketchybar/items/bluetooth.sh
  source "$CONFIG_DIR/items/bluetooth.sh"
  run bar_item_bluetooth
  [ "$status" -eq 0 ]
  [ ! -s "$STUB_LOG" ]
}

@test "bar_item_bluetooth adds the item with the plugin, click and hover" {
  unset -f blueutil
  PLUGIN_DIR="$CONFIG_DIR/plugins"
  source "$CONFIG_DIR/items/bluetooth.sh"
  run bar_item_bluetooth
  [ "$status" -eq 0 ]
  grep -q "^sketchybar --add item bluetooth right --set bluetooth .*update_freq=30 script=$PLUGIN_DIR/bluetooth.sh click_script=.*x-apple.systempreferences:com.apple.BluetoothSettings.* --subscribe bluetooth mouse.entered mouse.exited" "$STUB_LOG"
}

@test "a slow system_profiler is cut off after 1s and names still show" {
  stub system_profiler 'sleep 5; cat "$FIX/system-profiler.json"'
  SECONDS=0
  BT_CONNECTED="$FIX/connected-two.json" plugin
  [ "$status" -eq 0 ]
  [ "$SECONDS" -lt 4 ]
  grep -q '^sketchybar --set bluetooth icon=󰂱 2 .* label=MX Master 3S M, Justins AirPods Pro v2 label.color=' "$STUB_LOG"
}
