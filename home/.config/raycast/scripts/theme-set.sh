#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Set Theme
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎨
# @raycast.packageName Theme
# @raycast.argument1 { "type": "dropdown", "placeholder": "theme", "optional": false, "data": [{"title": "catppuccin-mocha", "value": "catppuccin-mocha"}, {"title": "kanagawa-wave", "value": "kanagawa-wave"}, {"title": "retro-82", "value": "retro-82"}] }

# Documentation:
# @raycast.description Switch Ghostty, Zellij, Neovim, SketchyBar, borders and wallpaper together.
# (no @raycast.author line by default; set MACARCHY_RAYCAST_AUTHOR and run
#  theme-raycast-sync to regenerate this file with one)

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
exec "$HOME/.config/theme/bin/theme-set" "$1"
