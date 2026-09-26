# shellcheck shell=bash
# Tailscale: connected / disconnected / exit node in use, from
# `tailscale status --json`. Click toggles `up` / `down` (plugins/tailscale.sh
# handles its own click); hover shows this machine's tailnet name and the exit
# node, if any. Nothing is added when the Tailscale CLI is absent.
#
# The CLI lookup matches tailscale_cli() in plugins/tailscale.sh: `tailscale`
# on PATH (Homebrew or the standalone install), else the binary inside the
# Mac App Store / standalone app bundle, which doubles as the CLI.

bar_item_tailscale() {
  local app_cli="${TAILSCALE_APP_CLI:-/Applications/Tailscale.app/Contents/MacOS/Tailscale}"
  command -v tailscale >/dev/null 2>&1 || [ -x "$app_cli" ] || return 0

  sketchybar --add item tailscale right \
    --set tailscale \
    label.drawing=off \
    update_freq=15 \
    script="$PLUGIN_DIR/tailscale.sh" \
    --subscribe tailscale mouse.clicked mouse.entered mouse.exited
}
