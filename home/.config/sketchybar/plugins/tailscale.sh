#!/usr/bin/env bash
# Tailscale state from `tailscale status --json`:
#   Running, no exit node   connected glyph, full brightness
#   Running via exit node   globe glyph, full brightness
#   Stopped / not running   disconnected glyph, dim
#   NeedsLogin              disconnected glyph, dim; click opens the app
# Hover label: this machine's tailnet name, plus the exit node when one is in
# use. The click is handled here (SENDER=mouse.clicked): `down` when running,
# `up` otherwise, then the item redraws from the new state.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

# The CLI: `tailscale` on PATH, else the app bundle's binary, which doubles as
# the CLI. items/tailscale.sh makes the same check before adding the item.
tailscale_cli() {
  local app_cli="${TAILSCALE_APP_CLI:-/Applications/Tailscale.app/Contents/MacOS/Tailscale}"
  if command -v tailscale >/dev/null 2>&1; then
    command -v tailscale
  elif [ -x "$app_cli" ]; then
    echo "$app_cli"
  else
    return 1
  fi
}

TS="$(tailscale_cli)" || exit 0

# One line, "|"-separated so an empty field stays in place:
#   BackendState|this machine's short DNS name|exit node's short DNS name
read_state() {
  "$TS" status --json 2>/dev/null | jq -r '
    [ .BackendState // "",
      (.Self.DNSName // "" | split(".")[0]),
      (if .ExitNodeStatus then
         ([.Peer[]? | select(.ExitNode)][0].DNSName // "exit node" | split(".")[0])
       else "" end)
    ] | join("|")' 2>/dev/null
}

STATUS="$(read_state)"
IFS='|' read -r STATE HOST EXIT <<<"$STATUS"

if [ "$SENDER" = "mouse.clicked" ]; then
  case "$STATE" in
    Running) "$TS" down >/dev/null 2>&1 ;;
    NeedsLogin | "") open -a Tailscale 2>/dev/null ;;
    *) "$TS" up >/dev/null 2>&1 || open -a Tailscale 2>/dev/null ;;
  esac
  STATUS="$(read_state)"
  IFS='|' read -r STATE HOST EXIT <<<"$STATUS"
fi

case "$STATE" in
  Running)
    COLOR="$WHITE"
    if [ -n "$EXIT" ]; then
      ICON="󰇧"
      LABEL="${HOST:-Tailscale} via $EXIT"
    else
      ICON="󰌘"
      LABEL="${HOST:-Tailscale}"
    fi
    ;;
  NeedsLogin)
    ICON="󰌙"
    COLOR="$FG_DIM"
    LABEL="Log in to Tailscale"
    ;;
  "")
    ICON="󰌙"
    COLOR="$FG_DIM"
    LABEL="Tailscale not running"
    ;;
  *)
    ICON="󰌙"
    COLOR="$FG_DIM"
    LABEL="Tailscale off"
    ;;
esac

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="$LABEL" \
  label.color="$WHITE"
