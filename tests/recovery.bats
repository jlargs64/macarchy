#!/usr/bin/env bats
# Recovery tooling against stubs: macarchy-restart's order and subsets,
# macarchy-rescue moving only the windows that sit off every display, and
# the doctor checks for the ways the desktop fails silently.

setup() {
  load helpers
  common_setup
  ln -s "$(PATH="$PATH:/opt/homebrew/bin:/usr/local/bin" command -v jq)" "$STUBS/jq"
  export FAKE="$BATS_TEST_TMPDIR/fake"
  mkdir -p "$FAKE"
  # a 3440x1440 ultrawide (display 1, focused) and a MacBook screen to its left
  cat >"$FAKE/displays.json" <<'JSON'
[{"index":1,"frame":{"x":0,"y":0,"w":3440,"h":1440},"spaces":[1],"has-focus":true},
 {"index":2,"frame":{"x":-1512,"y":76,"w":1512,"h":982},"spaces":[2],"has-focus":false}]
JSON
  cat >"$FAKE/spaces.json" <<'JSON'
[{"index":1,"type":"bsp","display":1,"is-visible":true},
 {"index":2,"type":"bsp","display":2,"is-visible":true}]
JSON
  echo '[]' >"$FAKE/windows.json"
  echo '[]' >"$FAKE/signals.json"
}

# fake_yabai -- a yabai that answers queries from the fixtures and logs the rest
fake_yabai() {
  stub yabai '
    case "$*" in
      "-m query --displays") cat "$FAKE/displays.json" ;;
      "-m query --spaces") cat "$FAKE/spaces.json" ;;
      "-m query --windows") cat "$FAKE/windows.json" ;;
      "-m signal --list") cat "$FAKE/signals.json" ;;
      "-m config left_padding") echo 8 ;;
      "-m config --space "*" left_padding") echo 8 ;;
      *) ;;
    esac'
}

# win <id> <x> <y> <w> <h> [key=json ...]
win() {
  local id=$1 x=$2 y=$3 w=$4 h=$5 extra=""
  shift 5
  for kv in "$@"; do extra="$extra,\"${kv%%=*}\":${kv#*=}"; done
  echo "{\"id\":$id,\"app\":\"App$id\",\"title\":\"win $id\",\"space\":1,\"frame\":{\"x\":$x,\"y\":$y,\"w\":$w,\"h\":$h},\"is-minimized\":false,\"is-hidden\":false,\"is-floating\":false,\"has-fullscreen-zoom\":false,\"has-focus\":false$extra}"
}
windows() { printf '[%s]' "$(
  IFS=,
  echo "$*"
)" >"$FAKE/windows.json"; }

restart() { run "$REPO/home/.config/macarchy/bin/macarchy-restart" "$@"; }
rescue() { run "$REPO/home/.config/macarchy/bin/macarchy-rescue" "$@"; }
doctor() { run "$REPO/home/.config/macarchy/bin/macarchy-doctor" "$@"; }

# stub_order <line> <line> ... -- the lines appear in $STUB_LOG in this order
stub_order() {
  local pos=0 next
  for want in "$@"; do
    next="$(grep -n -F -- "$want" "$STUB_LOG" | awk -F: -v p="$pos" '$1 > p {print $1; exit}')"
    if [ -z "$next" ]; then
      echo "not found after line $pos: $want"
      cat "$STUB_LOG"
      return 1
    fi
    pos="$next"
  done
}

fake_plist() { # fake_plist <label> [with-throttle]
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    echo '<plist version="1.0"><dict>'
    echo "<key>Label</key><string>$1</string>"
    echo '<key>KeepAlive</key><true/>'
    [ -z "${2:-}" ] || echo '<key>ThrottleInterval</key><integer>10</integer>'
    echo '</dict></plist>'
  } >"$HOME/Library/LaunchAgents/$1.plist"
}

# ----- macarchy-restart ----------------------------------------------------

@test "restart: yabai, wait, center, borders, bar, skhd in that order" {
  fake_yabai
  stub brew '[ "$1 $2" = "services list" ] && echo "borders started me ~/Library/LaunchAgents/sh.brew.borders.plist"; exit 0'
  restart
  echo "$output"
  [ "$status" -eq 0 ]
  stub_order "yabai --restart-service" "yabai -m query --displays" "yabai -m query --spaces" \
    "brew services list" "brew services restart borders" "sketchybar --reload" "skhd --reload"
  [[ $output == *"yabai    restarted, answering after 0s"* ]]
  [[ $output == *"center   spaces re-centered"* ]]
  [[ $output == *"borders  restarted (brew services)"* ]]
  [[ $output == *"bar      SketchyBar reloaded"* ]]
  [[ $output == *"skhd     reloaded"* ]]
}

@test "restart: --bar --skhd leaves yabai and borders alone" {
  restart --bar --skhd
  [ "$status" -eq 0 ]
  run ! grep -q "yabai" "$STUB_LOG"
  run ! grep -q "brew" "$STUB_LOG"
  grep -q "sketchybar --reload" "$STUB_LOG"
  grep -q "skhd --reload" "$STUB_LOG"
}

@test "restart: a yabai that never answers is reported and the rest still runs" {
  stub yabai '[ "$1" = -m ] && exit 1; exit 0'
  export MACARCHY_RESTART_WAIT=1
  restart --yabai --bar
  [ "$status" -eq 1 ]
  [[ $output == *"yabai    FAILED: restarted but not answering after 1s"* ]]
  [[ $output == *"bar      SketchyBar reloaded"* ]]
}

@test "restart: skhd --reload failing falls back to --restart-service" {
  stub skhd '[ "$1" = --reload ] && exit 1; exit 0'
  restart --skhd
  [ "$status" -eq 0 ]
  stub_order "skhd --reload" "skhd --restart-service"
  [[ $output == *"skhd     restarted"* ]]
}

@test "restart: borders not under brew services is killed and relaunched from bordersrc" {
  stub brew '[ "$1 $2" = "services list" ] && echo "borders none"; exit 0'
  mkdir -p "$HOME/.config/borders"
  printf '#!/usr/bin/env bash\necho "bordersrc $*" >>"$STUB_LOG"\n' >"$HOME/.config/borders/bordersrc"
  chmod +x "$HOME/.config/borders/bordersrc"
  restart --borders
  [ "$status" -eq 0 ]
  [[ $output == *"borders  relaunched from ~/.config/borders/bordersrc"* ]]
  grep -q "pkill -x borders" "$STUB_LOG"
  run ! grep -q "brew services restart" "$STUB_LOG"
  sleep 0.3
  grep -q "^bordersrc" "$STUB_LOG"
}

@test "restart: --throttle adds ThrottleInterval once, whichever label the plist has" {
  fake_plist com.asmvik.yabai
  restart --throttle
  [ "$status" -eq 0 ]
  [[ $output == *"ThrottleInterval 10 added to ~/Library/LaunchAgents/com.asmvik.yabai.plist"* ]]
  [ "$(/usr/libexec/PlistBuddy -c 'Print :ThrottleInterval' "$HOME/Library/LaunchAgents/com.asmvik.yabai.plist")" = 10 ]
  run ! grep -q "yabai --restart-service" "$STUB_LOG"
  restart --throttle
  [ "$status" -eq 0 ]
  [[ $output == *"already set"* ]]
  [ "$(grep -c ThrottleInterval "$HOME/Library/LaunchAgents/com.asmvik.yabai.plist")" = 1 ]
}

@test "restart: --throttle without a plist fails and names yabai --start-service" {
  restart --throttle
  [ "$status" -eq 1 ]
  [[ $output == *"no yabai LaunchAgent"* ]]
}

# ----- macarchy-rescue -----------------------------------------------------

@test "rescue moves only the windows off every display, to the focused one" {
  fake_yabai
  windows "$(win 1 100 100 800 600)" "$(win 2 5000 0 800 600)" \
    "$(win 3 3400 0 800 600)" "$(win 4 6000 0 800 600 is-minimized=true)" \
    "$(win 5 -1000 200 600 400)"
  rescue
  echo "$output"
  [ "$status" -eq 0 ]
  [[ $output == *'moved 2 App2 "win 2" from 5000,0 800x600 to display 1'* ]]
  grep -q "yabai -m window 2 --display 1" "$STUB_LOG"
  grep -q "yabai -m window 3 --display 1" "$STUB_LOG" # only 5% of it is on screen
  run ! grep -q "yabai -m window 1 " "$STUB_LOG"
  run ! grep -q "yabai -m window 4 " "$STUB_LOG"
  run ! grep -q "yabai -m window 5 " "$STUB_LOG" # on the MacBook screen
}

@test "rescue --dry-run prints and moves nothing" {
  fake_yabai
  windows "$(win 1 100 100 800 600)" "$(win 2 5000 0 800 600)"
  rescue --dry-run
  [ "$status" -eq 0 ]
  [[ $output == *'would move 2 App2 "win 2" at 5000,0 800x600 to display 1'* ]]
  run ! grep -q "yabai -m window" "$STUB_LOG"
}

@test "rescue exits 0 when nothing is lost and when yabai does not answer" {
  fake_yabai
  windows "$(win 1 100 100 800 600)"
  rescue --dry-run
  [ "$status" -eq 0 ]
  [[ $output == *"every window is on a display"* ]]
  stub yabai 'exit 1'
  rescue
  [ "$status" -eq 0 ]
  [[ $output == *"yabai did not answer"* ]]
}

# ----- macarchy-doctor -----------------------------------------------------

@test "doctor: secure keyboard entry names the app holding it" {
  install_links "themes wm"
  stub ioreg 'echo "\"IOConsoleUsers\" = ({\"kCGSSessionOnConsoleKey\"=Yes,\"kCGSSessionSecureInputPID\"=4242,\"kCGSSessionUserIDKey\"=501})"'
  stub ps 'echo /System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal'
  doctor
  [[ $output == *"secure keyboard entry is on in Terminal (pid 4242), so skhd aborts"* ]]
  grep -q "ps -o comm= -p 4242" "$STUB_LOG"
}

@test "doctor: the accessibility line in yabai's log fails with the re-grant" {
  install_links "themes wm"
  stub pgrep 'exit 0'
  stub yabai '[ "$1" = -m ] && exit 1; exit 0'
  {
    yes "some other line" | head -60
    echo "could not access accessibility features! abort.."
  } >"$MACARCHY_YABAI_ERR_LOG"
  doctor
  [ "$status" -eq 1 ]
  [[ $output == *"yabai cannot use Accessibility"* ]]
  [[ $output == *"remove yabai, add"*"again, then yabai --restart-service"* ]]
  [[ $output != *"usually missing Accessibility"* ]]
}

@test "doctor: an old accessibility line further up the log is ignored" {
  install_links "themes wm"
  stub pgrep 'exit 0'
  stub yabai '[ "$1" = -m ] && exit 1; exit 0'
  {
    echo "could not access accessibility features! abort.."
    yes "some other line" | head -60
  } >"$MACARCHY_YABAI_ERR_LOG"
  doctor
  [[ $output == *"usually missing Accessibility"* ]]
}

@test "doctor: a yabai plist without ThrottleInterval warns with --throttle" {
  install_links "themes wm"
  fake_plist com.koekeishiya.yabai
  doctor
  [[ $output == *"yabai LaunchAgent has no ThrottleInterval"* ]]
  [[ $output == *"fix: macarchy-restart --throttle"* ]]
  [[ $output == *"PlistBuddy -c 'Add :ThrottleInterval integer 10' ~/Library/LaunchAgents/com.koekeishiya.yabai.plist"* ]]
  fake_plist com.koekeishiya.yabai with
  doctor
  [[ $output == *"yabai LaunchAgent has ThrottleInterval"* ]]
}

@test "doctor: a running yabai without the yabairc signals fails" {
  install_links "themes wm"
  stub pgrep 'exit 0'
  fake_yabai
  doctor
  [ "$status" -eq 1 ]
  [[ $output == *"yabai is running without the signals yabairc adds"* ]]
  [[ $output == *"fix: yabai --restart-service"* ]]
  echo '[{"index":0,"label":"center-window_created","event":"window_created","action":"x"}]' >"$FAKE/signals.json"
  doctor
  [[ $output == *"yabai signals from yabairc loaded"* ]]
}

@test "doctor: counts off-screen windows and points at macarchy-rescue" {
  install_links "themes wm"
  stub pgrep 'exit 0'
  fake_yabai
  windows "$(win 1 100 100 800 600)" "$(win 2 5000 0 800 600)" "$(win 3 7000 0 800 600)"
  doctor
  [[ $output == *"2 window(s) sit off every display"* ]]
  [[ $output == *"fix: macarchy-rescue"* ]]
  run ! grep -q "yabai -m window" "$STUB_LOG"
  windows "$(win 1 100 100 800 600)"
  doctor
  [[ $output == *"every window is on a display"* ]]
}

@test "doctor: two borders processes warn with --borders" {
  install_links "themes borders"
  stub pgrep 'printf "%s\n" 111 222; exit 0'
  doctor
  [[ $output == *"JankyBorders running"* ]]
  [[ $output == *"2 borders processes running"* ]]
  [[ $output == *"fix: macarchy-restart --borders"* ]]
}

@test "doctor: crash reports from the last week are listed, older ones are not" {
  install_links "themes wm"
  mkdir -p "$HOME/Library/Logs/DiagnosticReports"
  touch "$HOME/Library/Logs/DiagnosticReports/yabai-2026-09-25-101010.ips"
  touch "$HOME/Library/Logs/DiagnosticReports/skhd-2026-09-24-090909.ips"
  touch -t 202601010000 "$HOME/Library/Logs/DiagnosticReports/yabai-2026-01-01-000000.ips"
  doctor
  [[ $output == *"1 yabai crash report(s) in the last 7 days: yabai-2026-09-25-101010.ips"* ]]
  [[ $output == *"1 skhd crash report(s)"* ]]
  [[ $output != *"yabai-2026-01-01"* ]]
}

@test "doctor: none of the new checks write to \$HOME" {
  install_links "themes wm borders"
  fake_plist com.asmvik.yabai
  stub pgrep 'exit 0'
  fake_yabai
  windows "$(win 2 5000 0 800 600)"
  before="$(find "$HOME" | LC_ALL=C sort | shasum)"
  doctor
  [ "$(find "$HOME" | LC_ALL=C sort | shasum)" = "$before" ]
  [ "$(grep -c ThrottleInterval "$HOME/Library/LaunchAgents/com.asmvik.yabai.plist")" = 0 ]
}
