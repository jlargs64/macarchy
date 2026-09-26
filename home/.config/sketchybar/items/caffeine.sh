# shellcheck shell=bash
# caffeinate -dims toggle. The click is handled by the plugin itself (it
# receives SENDER=mouse.clicked) so start/stop and rendering share one file.
# Sourced by sketchybarrc, which calls bar_item_caffeine when
# MACARCHY_BAR_RIGHT lists "caffeine".
bar_item_caffeine() {
  sketchybar --add item caffeine right \
    --set caffeine \
    label.drawing=off \
    update_freq=30 \
    script="$PLUGIN_DIR/caffeine.sh" \
    --subscribe caffeine mouse.clicked mouse.entered mouse.exited
}
