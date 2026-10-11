#!/usr/bin/env bats
# The caffeine bar item: plugins/caffeine.sh must light the cup only for the
# caffeinate it started itself. Other tools (Claude Code runs
# `caffeinate -i -t 300` while busy) spawn short-lived caffeinates that used
# to show "Awake" right up until the Mac went to sleep (2026-10-11).

setup() {
  load helpers
  common_setup
  mkdir -p "$HOME/.config/theme"
  ln -s "$REPO/home/.config/theme/themes/nord" "$HOME/.config/theme/current"
  # A stand-in caffeinate that just stays alive until killed; `ps -p PID -o
  # comm=` is stubbed to report "caffeinate" for any live PID.
  stub caffeinate 'exec sleep 300'
  stub ps 'kill -0 "$2" 2>/dev/null && echo caffeinate'
  sketchybar() { "$STUBS/sketchybar" "$@"; }
  export -f sketchybar
  export CONFIG_DIR="$REPO/home/.config/sketchybar" NAME=caffeine
  export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
  PIDFILE="$XDG_CACHE_HOME/sketchybar/caffeinate.pid"
}

teardown() {
  [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
  return 0
}

plugin() { SENDER="${1:-routine}" run bash "$CONFIG_DIR/plugins/caffeine.sh"; }

# The stub caffeinate is backgrounded with nohup, so its log line can land
# just after the plugin returns.
started_caffeinate() {
  local _
  for _ in $(seq 20); do
    grep -q '^caffeinate -dims$' "$STUB_LOG" && return 0
    sleep 0.1
  done
  return 1
}

@test "someone else's caffeinate does not light the cup" {
  stub pgrep "exit 0" # a foreign caffeinate is running
  plugin
  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
  grep -q '^sketchybar --set caffeine icon=󰾪 .* label=Sleep allowed ' "$STUB_LOG"
}

@test "a click starts caffeinate -dims, records its PID and shows Awake" {
  plugin mouse.clicked
  [ "$status" -eq 0 ]
  started_caffeinate
  kill -0 "$(cat "$PIDFILE")"
  grep -q '^sketchybar --set caffeine icon=󰅶 .* label=Awake ' "$STUB_LOG"
}

@test "a second click kills only the bar's caffeinate" {
  plugin mouse.clicked
  pid="$(cat "$PIDFILE")"
  : >"$STUB_LOG"
  plugin mouse.clicked
  [ "$status" -eq 0 ]
  run ! kill -0 "$pid"
  [ ! -f "$PIDFILE" ]
  run ! grep -q '^pkill' "$STUB_LOG"
  grep -q '^sketchybar --set caffeine icon=󰾪 .* label=Sleep allowed ' "$STUB_LOG"
}

@test "a stale PID file shows Sleep allowed and a click starts afresh" {
  mkdir -p "$(dirname "$PIDFILE")"
  echo 999999 >"$PIDFILE"
  plugin
  grep -q 'label=Sleep allowed ' "$STUB_LOG"
  plugin mouse.clicked
  [ "$status" -eq 0 ]
  started_caffeinate
  [ "$(cat "$PIDFILE")" != 999999 ]
}
