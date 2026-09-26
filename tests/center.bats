#!/usr/bin/env bats
# macarchy-center against a fake yabai: when a Space gets side gutters, how
# wide they are, and that toggle remembers the window it zoomed.

setup() {
  load helpers
  common_setup
  export XDG_CACHE_HOME="$HOME/.cache"
  # the real jq: both the script and the yabai stub below need it
  ln -s "$(PATH="$PATH:/opt/homebrew/bin:/usr/local/bin" command -v jq)" "$STUBS/jq"
  # A 3440x1440 ultrawide (display 1, Space 1 visible) and a 1512x982 MacBook
  # screen (display 2, Space 2 visible). Tests overwrite windows.json.
  export FAKE="$BATS_TEST_TMPDIR/fake"
  mkdir -p "$FAKE"
  cat >"$FAKE/displays.json" <<'EOF'
[{"index":1,"frame":{"x":0,"y":0,"w":3440,"h":1440},"spaces":[1]},
 {"index":2,"frame":{"x":-1512,"y":76,"w":1512,"h":982},"spaces":[2]}]
EOF
  cat >"$FAKE/spaces.json" <<'EOF'
[{"index":1,"type":"bsp","display":1,"is-visible":true},
 {"index":2,"type":"bsp","display":2,"is-visible":true}]
EOF
  echo '[]' >"$FAKE/windows.json"
  # yabai stub: answers queries from the fixtures, remembers per-Space padding
  # and the zoom state of window ids, and logs everything else.
  stub yabai '
    case "$*" in
      "-m query --displays") cat "$FAKE/displays.json" ;;
      "-m query --spaces") cat "$FAKE/spaces.json" ;;
      "-m query --windows") cat "$FAKE/windows.json" ;;
      "-m query --windows --window") jq ".[] | select(.[\"has-focus\"])" "$FAKE/windows.json" ;;
      "-m query --windows --window "*) jq ".[] | select(.id == $5)" "$FAKE/windows.json" ;;
      "-m config left_padding") echo 8 ;;
      "-m config --space "*" left_padding" | "-m config --space "*" right_padding")
        cat "$FAKE/pad.$4" 2>/dev/null || echo 8 ;;
      "-m config --space "*" left_padding "*) echo "$6" >"$FAKE/pad.$4" ;;
      "-m config --space "*" right_padding "*) ;;
      "-m window --toggle zoom-fullscreen")
        jq "map(if .[\"has-focus\"] then .[\"has-fullscreen-zoom\"] |= not else . end)" "$FAKE/windows.json" >"$FAKE/w.tmp"
        mv "$FAKE/w.tmp" "$FAKE/windows.json" ;;
      *) exit 1 ;;
    esac'
}

center() { run "$REPO/home/.config/macarchy/bin/macarchy-center" "$@"; }

# win <id> <space> [key=value ...] -> one window object
win() {
  local id=$1 space=$2 extra=""
  shift 2
  for kv in "$@"; do extra="$extra,\"${kv%%=*}\":${kv#*=}"; done # key=json-value
  echo "{\"id\":$id,\"space\":$space,\"is-floating\":false,\"is-minimized\":false,\"is-hidden\":false,\"has-fullscreen-zoom\":false,\"has-focus\":false$extra}"
}
windows() { printf '[%s]' "$(
  IFS=,
  echo "$*"
)" >"$FAKE/windows.json"; }
padding() { cat "$FAKE/pad.$1" 2>/dev/null || echo 8; }

@test "a lone window on the ultrawide gets 16:10 gutters, the MacBook does not" {
  windows "$(win 1 1)" "$(win 2 2)"
  center apply
  [ "$status" -eq 0 ]
  [ "$(padding 1)" = 568 ] # (3440 - 1440 * 16/10) / 2
  [ "$(padding 2)" = 8 ]   # 982 * 16/10 is wider than 1512
}

@test "two windows side by side get the normal padding back" {
  echo 568 >"$FAKE/pad.1"
  windows "$(win 1 1)" "$(win 2 1)"
  center apply
  [ "$(padding 1)" = 8 ]
}

@test "floating, minimized and hidden windows are not tiles" {
  windows "$(win 1 1)" "$(win 2 1 is-floating=true)" "$(win 3 1 is-minimized=true)" "$(win 4 1 is-hidden=true)"
  center apply
  [ "$(padding 1)" = 568 ]
}

@test "a stack counts as one tile" {
  sed -i '' 's/"type":"bsp","display":1/"type":"stack","display":1/' "$FAKE/spaces.json"
  windows "$(win 1 1)" "$(win 2 1)" "$(win 3 1)"
  center apply
  [ "$(padding 1)" = 568 ]
}

@test "MACARCHY_CENTER_WIDTH takes a pixel width" {
  export MACARCHY_CENTER_WIDTH=2000
  windows "$(win 1 1)"
  center apply
  [ "$(padding 1)" = 720 ]
}

@test "MACARCHY_CENTER_SINGLE=false leaves a lone window alone" {
  export MACARCHY_CENTER_SINGLE=false
  windows "$(win 1 1)"
  center apply
  [ "$(padding 1)" = 8 ]
}

@test "toggle zooms the focused window into the column and back" {
  windows "$(win 1 1 has-focus=true)" "$(win 2 1)"
  center toggle
  [ "$status" -eq 0 ]
  [ "$(padding 1)" = 568 ]
  [ "$(cat "$HOME/.cache/macarchy/centered")" = 1 ]
  grep -q 'yabai -m window --toggle zoom-fullscreen' "$STUB_LOG"

  center toggle
  [ "$(padding 1)" = 8 ]
  [ ! -s "$HOME/.cache/macarchy/centered" ]
}

@test "a zoom that was not made by toggle keeps the normal padding" {
  windows "$(win 1 1 has-fullscreen-zoom=true)" "$(win 2 1)"
  center apply
  [ "$(padding 1)" = 8 ]
}

@test "a centered window that was un-zoomed elsewhere is forgotten" {
  mkdir -p "$HOME/.cache/macarchy"
  echo 1 >"$HOME/.cache/macarchy/centered"
  echo 568 >"$FAKE/pad.1"
  windows "$(win 1 1)" "$(win 2 1)"
  center apply
  [ "$(padding 1)" = 8 ]
  [ ! -s "$HOME/.cache/macarchy/centered" ]
}

@test "toggle refuses a floating window" {
  windows "$(win 1 1 has-focus=true is-floating=true)"
  center toggle
  [ "$status" -eq 1 ]
  [[ $output == *floating* ]]
}

@test "status prints the plan without touching yabai" {
  windows "$(win 1 1)" "$(win 2 2)"
  center status
  [ "$status" -eq 0 ]
  [[ $output == *"space 1: padding 8 -> 568 (single)"* ]]
  [[ $output == *"space 2: padding 8 -> 8 (too-narrow)"* ]]
  [ ! -e "$FAKE/pad.1" ]
}
