#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
else
  VOLUME=$(osascript -e "output volume of (get volume settings)" 2>/dev/null)
fi

IS_MUTED=$(osascript -e "output muted of (get volume settings)" 2>/dev/null)

COLOR="$WHITE"
if [ "$IS_MUTED" = "true" ] || [ "${VOLUME:-0}" -eq 0 ]; then
  ICON="󰝟"
  COLOR="$FG_DIM"
else
  case "$VOLUME" in
    [6-9][0-9]|100) ICON="" ;;
    [3-5][0-9]) ICON="" ;;
    *) ICON="" ;;
  esac
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="${VOLUME}%" \
  label.color="$WHITE"
