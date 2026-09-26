#!/usr/bin/env bats
# sketchybarrc against a sketchybar stand-in: which right-hand items
# MACARCHY_BAR_RIGHT adds, in what order, and the items.d drop-ins.

setup() {
  load helpers
  common_setup
  mkdir -p "$HOME/.config/macarchy" "$HOME/.config/theme/themes"
  ln -s "$REPO/home/.config/theme/themes/nord" "$HOME/.config/theme/current"
  ln -s "$REPO/home/.config/macarchy/lib.sh" "$HOME/.config/macarchy/lib.sh"
  # A copy of the bar config whose plugins only leave a mark, to prove the rc
  # never runs one itself (SketchyBar does, later).
  export CONFIG_DIR="$BATS_TEST_TMPDIR/sketchybar"
  cp -R "$REPO/home/.config/sketchybar" "$CONFIG_DIR"
  for p in "$CONFIG_DIR"/plugins/*.sh; do
    printf '#!/bin/sh\ntouch "%s"\n' "$BATS_TEST_TMPDIR/plugin-ran" >"$p"
  done
  # sketchybarrc puts /opt/homebrew/bin first on PATH, which would find the
  # real sketchybar ahead of the stub. A function wins over any PATH lookup.
  sketchybar() { echo "sketchybar $*" >>"$STUB_LOG"; }
  export -f sketchybar
}

bar_rc() { run --separate-stderr bash "$CONFIG_DIR/sketchybarrc"; }

# right-hand items in the order the rc added them
added_right() { sed -n 's/^sketchybar --add item \([^ ]*\) right\( .*\)\{0,1\}$/\1/p' "$STUB_LOG" | tr '\n' ' '; }

@test "the default list adds the built-in items rightmost-first" {
  bar_rc
  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
  [ "$(added_right)" = "tray battery stats volume wifi caffeine " ]
  [ ! -e "$BATS_TEST_TMPDIR/plugin-ran" ]
}

@test "MACARCHY_BAR_RIGHT=battery adds only battery on the right" {
  echo 'MACARCHY_BAR_RIGHT="battery"' >"$HOME/.config/macarchy/config"
  bar_rc
  [ "$status" -eq 0 ]
  [ "$(added_right)" = "battery " ]
  # the left and center items are untouched
  grep -q '^sketchybar --add space space.1 left' "$STUB_LOG"
  grep -q '^sketchybar --add item clock q' "$STUB_LOG"
}

@test "an unknown name is skipped with a warning" {
  echo 'MACARCHY_BAR_RIGHT="wifi nope battery"' >"$HOME/.config/macarchy/config"
  bar_rc
  [ "$status" -eq 0 ]
  [ "$(added_right)" = "battery wifi " ]
  [[ $stderr == *"no bar item 'nope'"* ]]
}

@test "a function in items.d is called, and can replace a built-in" {
  mkdir -p "$HOME/.config/sketchybar/items.d"
  cat >"$HOME/.config/sketchybar/items.d/mine.sh" <<'ITEM'
bar_item_foo() { sketchybar --add item foo right --set foo icon=F; }
bar_item_wifi() { sketchybar --add item mywifi right; }
ITEM
  echo 'MACARCHY_BAR_RIGHT="foo wifi battery"' >"$HOME/.config/macarchy/config"
  bar_rc
  [ "$status" -eq 0 ]
  [ "$(added_right)" = "battery mywifi foo " ]
}

@test "tray: click hides the bar, hover shows the menu bar label" {
  bar_rc
  grep -q "^sketchybar --add item tray right --set tray icon=⋯ label=menu bar .*click_script=sketchybar --bar hidden=toggle" "$STUB_LOG"
  : >"$STUB_LOG"
  cp "$REPO"/home/.config/sketchybar/plugins/{tray,hover}.sh "$CONFIG_DIR/plugins/"
  NAME=tray SENDER=mouse.entered run bash "$CONFIG_DIR/plugins/tray.sh"
  NAME=tray SENDER=mouse.exited run bash "$CONFIG_DIR/plugins/tray.sh"
  [ "$(cat "$STUB_LOG")" = "sketchybar --set tray label.drawing=on
sketchybar --set tray label.drawing=off" ]
}
