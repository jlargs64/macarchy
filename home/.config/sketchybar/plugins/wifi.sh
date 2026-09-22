#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"
# shellcheck disable=SC1091
source "$HOME/.config/macarchy/lib.sh" 2>/dev/null || true

IP="$(ipconfig getifaddr "$MACARCHY_WIFI_IFACE" 2>/dev/null)"
SSID="$(ipconfig getsummary "$MACARCHY_WIFI_IFACE" 2>/dev/null | awk -F': ' '/  SSID : / {print $2}')"

if [ "$SSID" = "<redacted>" ] || [ -z "$SSID" ]; then
  SSID="$(networksetup -getairportnetwork "$MACARCHY_WIFI_IFACE" 2>/dev/null | awk -F': ' '{print $2}')"
fi

if [ -n "$IP" ]; then
  if [ -n "$SSID" ] && [ "$SSID" != "You are not associated with an AirPort network." ] && [ "$SSID" != "<redacted>" ]; then
    LABEL="$SSID"
  else
    LABEL="Wi-Fi"
  fi
  if [ ${#LABEL} -gt 12 ]; then
    LABEL="${LABEL:0:10}…"
  fi
  sketchybar --set "$NAME" \
    icon="" \
    icon.color="$WHITE" \
    label="$LABEL" \
    label.color="$WHITE"
else
  sketchybar --set "$NAME" \
    icon="" \
    icon.color="$FG_DIM" \
    label="Offline" \
    label.color="$FG_DIM"
fi
