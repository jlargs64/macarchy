# shellcheck shell=bash
# Wi-Fi (MACARCHY_WIFI_IFACE): hover shows the network. Click opens Wi-Fi
# settings. Sourced by sketchybarrc, which calls bar_item_wifi when
# MACARCHY_BAR_RIGHT lists "wifi".
bar_item_wifi() {
  sketchybar --add item wifi right \
    --set wifi \
    label.drawing=off \
    update_freq=30 \
    script="$PLUGIN_DIR/wifi.sh" \
    click_script="$CONFIG_DIR/helpers/open_centered com.apple.systempreferences 'x-apple.systempreferences:com.apple.wifi-settings-extension'" \
    --subscribe wifi mouse.entered mouse.exited
}
