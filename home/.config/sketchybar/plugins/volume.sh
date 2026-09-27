#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

# One call for both values. An output macOS cannot drive (HDMI or DisplayPort
# to a monitor, some USB DACs) reports "missing value" for volume and mute.
SETTINGS=$(osascript -e "get volume settings" 2>/dev/null)
VOLUME=$(printf '%s' "$SETTINGS" | sed -n 's/^output volume:\([^,]*\),.*/\1/p')
IS_MUTED=$(printf '%s' "$SETTINGS" | sed -n 's/.*output muted:\([^,]*\).*/\1/p')
if [ "$SENDER" = "volume_change" ] && [ -n "$INFO" ]; then
  VOLUME="$INFO"
fi

COLOR="$WHITE"
case "$VOLUME" in
  '' | *[!0-9]*)
    # No software volume: the device's own buttons set the level.
    ICON="󰓃"
    COLOR="$FG_DIM"
    VOLUME=""
    ;;
esac

if [ -z "$VOLUME" ]; then
  LABEL="Fixed"
elif [ "$IS_MUTED" = "true" ] || [ "$VOLUME" -eq 0 ]; then
  ICON="󰝟"
  COLOR="$FG_DIM"
  LABEL="${VOLUME}%"
else
  case "$VOLUME" in
    [6-9][0-9] | 100) ICON="" ;;
    [3-5][0-9]) ICON="" ;;
    *) ICON="" ;;
  esac
  LABEL="${VOLUME}%"
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="$LABEL" \
  label.color="$WHITE"
