#!/usr/bin/env bash
# Tray item (items/tray.sh): nothing to compute, the glyph is fixed. Only the
# hover label, "menu bar", is shown and hidden here.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/hover.sh"
