#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Set Theme
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎨
# @raycast.packageName Theme
# @raycast.argument1 { "type": "dropdown", "placeholder": "theme", "optional": false, "data": [{"title": "catppuccin-latte", "value": "catppuccin-latte"}, {"title": "catppuccin-mocha", "value": "catppuccin-mocha"}, {"title": "ethereal", "value": "ethereal"}, {"title": "everforest", "value": "everforest"}, {"title": "flexoki-light", "value": "flexoki-light"}, {"title": "gruvbox", "value": "gruvbox"}, {"title": "hackerman", "value": "hackerman"}, {"title": "kanagawa-wave", "value": "kanagawa-wave"}, {"title": "last-horizon", "value": "last-horizon"}, {"title": "lumon", "value": "lumon"}, {"title": "lupine", "value": "lupine"}, {"title": "matte-black", "value": "matte-black"}, {"title": "miasma", "value": "miasma"}, {"title": "nord", "value": "nord"}, {"title": "osaka-jade", "value": "osaka-jade"}, {"title": "retro-82", "value": "retro-82"}, {"title": "ristretto", "value": "ristretto"}, {"title": "rose-pine", "value": "rose-pine"}, {"title": "solitude", "value": "solitude"}, {"title": "tokyo-night", "value": "tokyo-night"}, {"title": "vantablack", "value": "vantablack"}, {"title": "white", "value": "white"}] }

# Documentation:
# @raycast.description Switch Ghostty, Zellij, Neovim, SketchyBar, borders and wallpaper together.

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
exec "$HOME/.config/theme/bin/theme-set" "$1"
