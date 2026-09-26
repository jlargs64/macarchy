# shellcheck shell=bash
# Tray: the way to the native menu bar, which the bar covers (see the top of
# sketchybarrc). Click hides the bar on every display so the menu bar reveals
# on hover as usual; shift + alt - m brings it back. Always present, and last
# in the default MACARCHY_BAR_RIGHT so it sits at the far right. Sourced by
# sketchybarrc, which calls bar_item_tray when MACARCHY_BAR_RIGHT lists "tray".
bar_item_tray() {
  sketchybar --add item tray right \
    --set tray \
    icon="⋯" \
    label="menu bar" \
    label.drawing=off \
    script="$PLUGIN_DIR/tray.sh" \
    click_script="sketchybar --bar hidden=toggle" \
    --subscribe tray mouse.entered mouse.exited
}
