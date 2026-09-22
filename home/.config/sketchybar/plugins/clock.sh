#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null

# Omarchy's clock format: "Friday 14:42"
sketchybar --set "$NAME" \
  label="$(date '+%A %H:%M')" \
  label.color="$WHITE"
