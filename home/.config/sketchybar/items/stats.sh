# shellcheck shell=bash
# CPU and memory: hover shows the numbers. Click opens Activity Monitor.
# Sourced by sketchybarrc, which calls bar_item_stats when MACARCHY_BAR_RIGHT
# lists "stats".
bar_item_stats() {
  sketchybar --add item stats right \
    --set stats \
    label.drawing=off \
    update_freq=5 \
    script="$PLUGIN_DIR/stats.sh" \
    click_script="$CONFIG_DIR/helpers/open_centered com.apple.ActivityMonitor ''" \
    --subscribe stats mouse.entered mouse.exited
}
