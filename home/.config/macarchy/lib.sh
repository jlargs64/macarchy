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

# shellcheck disable=SC1091
MACARCHY_AGENT_MODEL="${MACARCHY_AGENT_MODEL:-$HOME/.local/share/macarchy/models/workspace-agent.cact}"
MACARCHY_AGENT_EXECUTE="${MACARCHY_AGENT_EXECUTE:-false}"
MACARCHY_MIC="${MACARCHY_MIC:-:0}"
MACARCHY_HANDY="${MACARCHY_HANDY:-/Applications/Handy.app/Contents/MacOS/handy}"
[ -f "$HOME/.config/macarchy/config" ] && . "$HOME/.config/macarchy/config"

export MACARCHY_DEFAULT_THEME MACARCHY_FONT MACARCHY_SPACES MACARCHY_RAYCAST_AUTHOR MACARCHY_WIFI_IFACE
