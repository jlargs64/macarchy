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
  # bluetooth only adds itself when blueutil exists; a function satisfies command -v.
  blueutil() { :; }
  export -f blueutil
}

bar_rc() { run --separate-stderr bash "$CONFIG_DIR/sketchybarrc"; }

# right-hand items in the order the rc added them
added_right() { sed -n 's/^sketchybar --add item \([^ ]*\) right\( .*\)\{0,1\}$/\1/p' "$STUB_LOG" | tr '\n' ' '; }

@test "the default list adds the built-in items rightmost-first" {
  bar_rc
  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
  [ "$(added_right)" = "tray battery stats volume bluetooth wifi caffeine updates " ]
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

# space.sh against a yabai stand-in with two displays: Spaces 1-3 on the main
# one (1 focused), 4-7 on the laptop (4 visible, not focused).
space_ind() { # space_ind <sid> [VAR=value ...] -- run space.sh, print its --set line
  local sid="$1"
  shift
  cp "$REPO/home/.config/sketchybar/plugins/space.sh" "$CONFIG_DIR/plugins/"
  yabai() {
    case "$*" in
      "-m query --spaces --space "*)
        local s="${*##* }" vis=false
        case "$s" in 1 | 4) vis=true ;; esac
        echo "{\"index\":$s,\"is-visible\":$vis,\"has-focus\":$([ "$s" = 1 ] && echo true || echo false)}"
        ;;
      "-m query --windows --space 5") echo '[{"is-minimized":false}]' ;;
      "-m query --windows --space "*) echo '[]' ;;
    esac
  }
  export -f yabai
  : >"$STUB_LOG"
  env NAME="space.$sid" "$@" bash "$CONFIG_DIR/plugins/space.sh" "$sid"
  grep "^sketchybar --set space.$sid" "$STUB_LOG"
}

@test "space: each display's visible Space is lit, not only the focused one" {
  run space_ind 1
  [[ $output == *"icon=1 "*":Bold:"* ]]
  run space_ind 4
  [[ $output == *"icon=4 "*":Bold:"* ]]
  run space_ind 5 # occupied, not visible
  [[ $output == *"icon.color=0x99"*":Regular:"* ]]
  run space_ind 6 # empty
  [[ $output == *":Regular:"* && $output != *"icon.color=0x99"* && $output != *"icon.color=0xff"* ]]
}

@test "space: on space_change \$SELECTED wins over yabai's lagging view" {
  run space_ind 4 SENDER=space_change SELECTED=false
  [[ $output == *":Regular:"* ]]
  run space_ind 6 SENDER=space_change SELECTED=true
  [[ $output == *":Bold:"* ]]
}

@test "the bar adds an indicator for every Space up to 9 by default" {
  bar_rc
  [ "$status" -eq 0 ]
  grep -q '^sketchybar --add space space.9 left' "$STUB_LOG"
  run ! grep -q '^sketchybar --add space space.10 ' "$STUB_LOG"
  grep -q '^sketchybar --add space space.4 left --subscribe space.4 .*display_change' "$STUB_LOG"
}
