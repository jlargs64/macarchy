#!/usr/bin/env bash
# Toggle `caffeinate -dims` from the bar. While on, the display, system and
# disks are kept awake and idle sleep is blocked; click again to let the Mac
# sleep normally.
#
# The icon reflects ANY caffeinate this user is running, including one typed
# into a terminal, since that is what actually decides whether the Mac sleeps.
# Clicking "off" kills the one the bar started (PID kept in a file, so it
# survives `sketchybar --reload`), or failing that every caffeinate of ours.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

PIDFILE="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar/caffeinate.pid"
mkdir -p "$(dirname "$PIDFILE")"

# True when any caffeinate owned by this user is running.
is_on() {
  pgrep -u "$(id -u)" -x caffeinate >/dev/null 2>&1
}

if [ "$SENDER" = "mouse.clicked" ]; then
  if is_on; then
    PID="$(cat "$PIDFILE" 2>/dev/null)"
    if [ -n "$PID" ] && ps -p "$PID" -o comm= 2>/dev/null | grep -q caffeinate; then
      kill "$PID" 2>/dev/null
    else
      pkill -u "$(id -u)" -x caffeinate 2>/dev/null
    fi
    rm -f "$PIDFILE"
  else
    nohup caffeinate -dims >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
  fi
fi

if is_on; then
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
