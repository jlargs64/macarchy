#!/usr/bin/env bash
# Toggle `caffeinate -dims` from the bar. While on, the display, system and
# disks are kept awake and idle sleep is blocked; click again to let the Mac
# sleep normally.
#
# The icon reflects only the caffeinate the bar started (PID kept in a file,
# so it survives `sketchybar --reload`). Other caffeinates are ignored: tools
# such as Claude Code run their own short `caffeinate -i -t 300` while busy,
# and lighting the cup for those showed "Awake" minutes before the Mac went
# to sleep. Clicking "off" kills the bar's process and nothing else.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

PIDFILE="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar/caffeinate.pid"
mkdir -p "$(dirname "$PIDFILE")"

# Prints the PID of the caffeinate the bar started, if that process is still
# alive and still a caffeinate (guards against PID reuse). Fails otherwise.
own_pid() {
  local pid
  pid="$(cat "$PIDFILE" 2>/dev/null)"
  [ -n "$pid" ] || return 1
  ps -p "$pid" -o comm= 2>/dev/null | grep -q caffeinate || return 1
  echo "$pid"
}

if [ "$SENDER" = "mouse.clicked" ]; then
  if PID="$(own_pid)"; then
    kill "$PID" 2>/dev/null
    rm -f "$PIDFILE"
  else
    nohup caffeinate -dims >/dev/null 2>&1 &
    echo $! >"$PIDFILE"
  fi
fi

if own_pid >/dev/null; then
  ICON="󰅶"
  COLOR="$WHITE"
  LABEL="Awake"
else
  ICON="󰾪"
  COLOR="$FG_DIM"
  LABEL="Sleep allowed"
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="$LABEL" \
  label.color="$WHITE"
