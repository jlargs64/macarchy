# shellcheck shell=bash
# Output volume: hover shows the level. Click toggles mute. Sourced by
# sketchybarrc, which calls bar_item_volume when MACARCHY_BAR_RIGHT lists
# "volume".
bar_item_volume() {
  sketchybar --add item volume right \
    --set volume \
    label.drawing=off \
    script="$PLUGIN_DIR/volume.sh" \
    click_script="osascript -e 'set volume output muted not (output muted of (get volume settings))'; sketchybar --set volume script=\"$PLUGIN_DIR/volume.sh\"" \
    --subscribe volume volume_change mouse.entered mouse.exited
}
