#!/usr/bin/env bats
# The volume bar item: plugins/volume.sh runs against a stubbed osascript that
# prints $VOL_SETTINGS as `get volume settings` would, and its
# `sketchybar --set` argv is checked. An HDMI output (a monitor's speakers)
# reports "missing value" for volume and mute (macOS 26, 2026-09-27).

setup() {
  load helpers
  common_setup
  mkdir -p "$HOME/.config/theme"
  ln -s "$REPO/home/.config/theme/themes/nord" "$HOME/.config/theme/current"
  export VOL_SETTINGS="output volume:42, input volume:42, alert volume:100, output muted:false"
  stub osascript 'echo "$VOL_SETTINGS"'
  # The plugin puts /opt/homebrew/bin first on PATH; exported functions win
  # over that lookup, so the stubs stay in charge.
  sketchybar() { "$STUBS/sketchybar" "$@"; }
  osascript() { "$STUBS/osascript" "$@"; }
  export -f sketchybar osascript
  export CONFIG_DIR="$REPO/home/.config/sketchybar" NAME=volume
}

plugin() { SENDER="${1:-routine}" run bash "$CONFIG_DIR/plugins/volume.sh"; }

@test "a level shows its percentage" {
  plugin
  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
  grep -q '^sketchybar --set volume icon= .* label=42% ' "$STUB_LOG"
}

@test "muted shows the mute glyph" {
  VOL_SETTINGS="output volume:42, input volume:42, alert volume:100, output muted:true" plugin
  [ "$status" -eq 0 ]
  grep -q '^sketchybar --set volume icon=󰝟 .* label=42% ' "$STUB_LOG"
}

@test "an HDMI output with no volume control says Fixed, not missing value" {
  VOL_SETTINGS="output volume:missing value, input volume:42, alert volume:42, output muted:missing value" plugin
  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
  grep -q '^sketchybar --set volume icon=󰓃 .* label=Fixed ' "$STUB_LOG"
  run ! grep -q 'missing' "$STUB_LOG"
}

@test "volume_change uses the level sketchybar passes in" {
  SENDER=volume_change INFO=75 run bash "$CONFIG_DIR/plugins/volume.sh"
  [ "$status" -eq 0 ]
  grep -q '^sketchybar --set volume icon= .* label=75% ' "$STUB_LOG"
}
