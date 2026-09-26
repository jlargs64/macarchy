#!/usr/bin/env bash
# Mic and camera activity, like the orange and green dots in the native menu bar.
# One plugin drives four items ($NAME is `mic` or `cam`, or their `.c` twins
# that sketchybarrc centers on displays without a notch). The state comes from
# macarchy-avstate (CoreAudio / CoreMediaIO "is running somewhere"), so any app
# counts, not only ws. While `ws --voice` owns the mic the glyph is red and a
# click is the same as pressing alt - w again. Hidden means idle.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$HOME/.local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

AV="$HOME/.local/share/macarchy/bin/macarchy-avstate"
PIDF="${XDG_CACHE_HOME:-$HOME/.cache}/macarchy/ws-rec.pid"

ws_listening() { [ -f "$PIDF" ] && kill -0 "$(cut -d' ' -f1 "$PIDF")" 2>/dev/null; }

if [ "$SENDER" = "mouse.clicked" ]; then
  [ "${NAME%.c}" = mic ] && ws_listening && nohup ws --voice >/dev/null 2>&1 &
  exit 0
fi

[ -x "$AV" ] || {
  sketchybar --set "$NAME" drawing=off
  exit 0
} # not built: see ~/.config/macarchy/swift/build
STATE="$("$AV" 2>/dev/null)"

case "${NAME%.c}" in
  mic)
    ON="${STATE#*mic=}"
    ON="${ON:0:1}"
    ICON="󰍬"
    COLOR="$YELLOW"
    LABEL="Microphone in use"
    if ws_listening; then
      ON=1
      COLOR="$RED"
      LABEL="ws listening… alt-w again to run"
    fi
    ;;
  cam)
    ON="${STATE#*cam=}"
    ON="${ON:0:1}"
    ICON="󰄀"
    COLOR="$GREEN"
    LABEL="Camera in use"
    ;;
esac

if [ "$ON" = 1 ]; then
  sketchybar --set "$NAME" drawing=on icon="$ICON" icon.color="$COLOR" label="$LABEL" label.color="$WHITE"
else
  sketchybar --set "$NAME" drawing=off label.drawing=off
fi
