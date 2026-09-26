#!/usr/bin/env bash
# macarchy/lib.sh — shared config loader.
#
# Source this from any script that needs a MACARCHY_* value:
#
#   # shellcheck disable=SC1091
#   . "$HOME/.config/macarchy/lib.sh" 2>/dev/null || true
#
# Sets defaults first, then applies ~/.config/macarchy/config (created from
# config.example by install.sh) over them if it exists, so a config file only
# needs to list what it overrides.

MACARCHY_DEFAULT_THEME="${MACARCHY_DEFAULT_THEME:-retro-82}"
MACARCHY_FONT="${MACARCHY_FONT:-Hack Nerd Font}"
MACARCHY_SPACES="${MACARCHY_SPACES:-5}"
MACARCHY_RAYCAST_AUTHOR="${MACARCHY_RAYCAST_AUTHOR:-}"
MACARCHY_WIFI_IFACE="${MACARCHY_WIFI_IFACE:-en0}"
MACARCHY_UPDATE_AT_LOGIN="${MACARCHY_UPDATE_AT_LOGIN:-true}"
MACARCHY_THEME_TARGETS="${MACARCHY_THEME_TARGETS:-auto}"
MACARCHY_TERMINAL="${MACARCHY_TERMINAL:-ghostty}"
MACARCHY_KEYS_SOURCES="${MACARCHY_KEYS_SOURCES:-skhd ghostty zellij}"
MACARCHY_CENTER_WIDTH="${MACARCHY_CENTER_WIDTH:-16:10}"
MACARCHY_CENTER_SINGLE="${MACARCHY_CENTER_SINGLE:-true}"
# Layout (yabairc, bordersrc, sketchybarrc). Pixels.
MACARCHY_GAP="${MACARCHY_GAP:-8}"
MACARCHY_PADDING_TOP="${MACARCHY_PADDING_TOP:-8}"
MACARCHY_PADDING_BOTTOM="${MACARCHY_PADDING_BOTTOM:-20}"
MACARCHY_PADDING_LEFT="${MACARCHY_PADDING_LEFT:-8}"
MACARCHY_PADDING_RIGHT="${MACARCHY_PADDING_RIGHT:-8}"
MACARCHY_BAR_HEIGHT="${MACARCHY_BAR_HEIGHT:-32}"
MACARCHY_BORDER_WIDTH="${MACARCHY_BORDER_WIDTH:-6}"
MACARCHY_BORDER_STYLE="${MACARCHY_BORDER_STYLE:-round}"
# MACARCHY_COMPONENTS stays unset unless the config sets it: install.sh
# treats unset as "not chosen yet" and asks.

# shellcheck disable=SC1091
MACARCHY_AGENT_MODEL="${MACARCHY_AGENT_MODEL:-$HOME/.local/share/macarchy/models/workspace-agent.cact}"
MACARCHY_AGENT_EXECUTE="${MACARCHY_AGENT_EXECUTE:-false}"
MACARCHY_MIC="${MACARCHY_MIC:-:default}"
MACARCHY_HANDY="${MACARCHY_HANDY:-/Applications/Handy.app/Contents/MacOS/handy}"
[ -f "$HOME/.config/macarchy/config" ] && . "$HOME/.config/macarchy/config"

export MACARCHY_DEFAULT_THEME MACARCHY_FONT MACARCHY_SPACES MACARCHY_RAYCAST_AUTHOR MACARCHY_WIFI_IFACE
