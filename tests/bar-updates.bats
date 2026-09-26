#!/usr/bin/env bats
# The bar's updates item: plugins/updates.sh turns `brew outdated --quiet` and
# `macarchy-update --check` into a dot with a hover label, or hides it.

setup() {
  load helpers
  common_setup
  export CONFIG_DIR="$REPO/home/.config/sketchybar" NAME=updates SENDER=routine
  unset BREW UPDATES_TIMEOUT
  stub macarchy-update 'echo "installed: v0.3.0"; echo "latest: v0.3.0"; exit 0'
}

plugin() { run "$CONFIG_DIR/plugins/updates.sh" "$@"; }

brew_outdated() { # brew_outdated <formula...> -- brew lists these as outdated
  stub brew "[ \"\$1\" = outdated ] && printf '%s\n' $*; exit 0"
}

macarchy_behind() {
  stub macarchy-update '[ "$1" = --check ] || exit 0; echo "installed: v0.3.0"; echo "latest: v0.4.0"; exit 10'
}

@test "hidden when brew and macarchy are both current" {
  plugin
  [ "$status" -eq 0 ]
  grep -q "^sketchybar --set updates drawing=off" "$STUB_LOG"
  grep -q "^macarchy-update --check" "$STUB_LOG"
  grep -q "^brew outdated --quiet" "$STUB_LOG"
}

@test "brew only: dot with the outdated count" {
  brew_outdated git jq node
  plugin
  [ "$status" -eq 0 ]
  grep -q "^sketchybar --set updates drawing=on .* label=3 brew label.color" "$STUB_LOG"
}

@test "macarchy only: dot with the new release" {
  macarchy_behind
  plugin
  grep -q "^sketchybar --set updates drawing=on .* label=macarchy v0.4.0 label.color" "$STUB_LOG"
}

@test "both: brew count and macarchy release in one label" {
  brew_outdated git
  macarchy_behind
  plugin
  grep -q "^sketchybar --set updates drawing=on .* label=1 brew · macarchy v0.4.0 label.color" "$STUB_LOG"
}

@test "a missing brew is not an error" {
  export BREW="$BATS_TEST_TMPDIR/nope/brew"
  macarchy_behind
  plugin
  [ "$status" -eq 0 ]
  grep -q "label=macarchy v0.4.0 " "$STUB_LOG"
}

@test "missing brew and macarchy-update: hidden, no error" {
  export BREW="$BATS_TEST_TMPDIR/nope/brew"
  rm "$STUBS/macarchy-update"
  plugin
  [ "$status" -eq 0 ]
  grep -q "^sketchybar --set updates drawing=off" "$STUB_LOG"
}

@test "an offline macarchy check counts as current" {
  stub macarchy-update 'echo "macarchy-update: could not list releases" >&2; exit 1'
  plugin
  grep -q "^sketchybar --set updates drawing=off" "$STUB_LOG"
}

@test "a hung brew is cut off at UPDATES_TIMEOUT" {
  stub brew 'sleep 30'
  macarchy_behind
  export UPDATES_TIMEOUT=1
  start=$SECONDS
  plugin
  [ "$status" -eq 0 ]
  [ $((SECONDS - start)) -lt 5 ]
  grep -q "label=macarchy v0.4.0 " "$STUB_LOG"
}

@test "hover only toggles the label" {
  brew_outdated git
  SENDER=mouse.entered plugin
  [ "$(cat "$STUB_LOG")" = "sketchybar --set updates label.drawing=on" ]
}

@test "click opens macarchy-update in a macarchy-popup" {
  mkdir -p "$HOME/.config/macarchy/bin"
  stub macarchy-popup
  ln -s "$STUBS/macarchy-popup" "$HOME/.config/macarchy/bin/macarchy-popup"
  plugin --popup
  [ "$status" -eq 0 ]
  grep -q "^macarchy-popup macarchy-update env MACARCHY_UPDATES_POPUP=1 .*/plugins/updates.sh$" "$STUB_LOG"
  [ "$(grep -c "^macarchy-update" "$STUB_LOG")" = 0 ]
}

@test "inside the popup: runs macarchy-update, then lists outdated brew packages" {
  brew_outdated git
  MACARCHY_UPDATES_POPUP=1 plugin </dev/null
  [ "$status" -eq 0 ]
  grep -q "^macarchy-update $" "$STUB_LOG"
  [[ $output == *"Outdated Homebrew packages"*"git"*"brew upgrade"* ]]
}

@test "the item file only defines bar_item_updates" {
  PLUGIN_DIR="$CONFIG_DIR/plugins"
  source "$CONFIG_DIR/items/updates.sh"
  [ ! -s "$STUB_LOG" ]
  bar_item_updates
  grep -q "^sketchybar --add item updates right --set updates drawing=off .* update_freq=3600 script=$PLUGIN_DIR/updates.sh click_script=$PLUGIN_DIR/updates.sh --popup --subscribe updates mouse.entered mouse.exited system_woke$" "$STUB_LOG"
}
