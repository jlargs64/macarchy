#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

COLOR="$WHITE"
if [ -n "$CHARGING" ]; then
  ICON=""
else
  case "${PERCENTAGE}" in
    8[0-9] | 9[0-9] | 100) ICON="" ;;
    6[0-9] | 7[0-9]) ICON="" ;;
    4[0-9] | 5[0-9]) ICON="" ;;
    2[0-9] | 3[0-9]) ICON="" ;;
    *)
      ICON=""
      COLOR="$RED"
      ;;
  esac
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="${PERCENTAGE}%" \
  label.color="$WHITE"
