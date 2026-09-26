# shellcheck shell=bash
# updates: a dot when Homebrew packages are outdated or a newer macarchy
# release is out, hidden otherwise. Hover shows what, click runs
# macarchy-update in a popup terminal. Checked hourly and on wake; see
# plugins/updates.sh. Sourced by sketchybarrc, which lists it in
# MACARCHY_BAR_RIGHT.
bar_item_updates() {
  sketchybar --add item updates right \
    --set updates \
    drawing=off \
    label.drawing=off \
    update_freq=3600 \
    script="$PLUGIN_DIR/updates.sh" \
    click_script="$PLUGIN_DIR/updates.sh --popup" \
    --subscribe updates mouse.entered mouse.exited system_woke
}
