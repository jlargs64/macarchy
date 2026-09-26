# shellcheck shell=bash
# Bluetooth item: power state and connected-device count, device names and
# battery on hover, click opens the Bluetooth pane in System Settings.
# Sourced by sketchybarrc; defines bar_item_bluetooth and runs nothing.
#
# Needs blueutil (installed with the bar component). Without it the item is
# left out rather than drawn empty, like every optional bar item.

bar_item_bluetooth() {
  command -v blueutil >/dev/null 2>&1 || return 0

  # update_freq 30: connect / disconnect has no SketchyBar event, and the
  # plugin is cheap (two blueutil calls plus a ~0.1s system_profiler).
  sketchybar --add item bluetooth right \
    --set bluetooth \
    label.drawing=off \
    update_freq=30 \
    script="$PLUGIN_DIR/bluetooth.sh" \
    click_script="$CONFIG_DIR/helpers/open_centered com.apple.systempreferences 'x-apple.systempreferences:com.apple.BluetoothSettings'" \
    --subscribe bluetooth mouse.entered mouse.exited system_woke
}
