# shellcheck shell=bash
# Battery: charge glyph, red below 20%; hover shows the percentage. Click
# opens Battery settings. Sourced by sketchybarrc, which calls bar_item_battery
# when MACARCHY_BAR_RIGHT lists "battery".
bar_item_battery() {
  sketchybar --add item battery right \
    --set battery \
    label.drawing=off \
    update_freq=60 \
    script="$PLUGIN_DIR/battery.sh" \
    click_script="$CONFIG_DIR/helpers/open_centered com.apple.systempreferences 'x-apple.systempreferences:com.apple.Battery-Settings.extension'" \
    --subscribe battery mouse.entered mouse.exited
}
