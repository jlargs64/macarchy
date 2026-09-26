#!/usr/bin/env bash
# Update indicator, like the one on Omarchy's bar: a dot while there is
# something to update, hidden otherwise. Two sources, checked in parallel:
#
#   brew       `brew outdated --quiet` (from the last `brew update`; this
#              never updates the index itself)
#   macarchy   `macarchy-update --check`, exit 10 when a newer release is tagged
#
# Hover label: "3 brew · macarchy v0.4.0", whichever apply. Either source may
# be missing, offline or slow: both run in the background and whatever has not
# answered after UPDATES_TIMEOUT seconds (20) is killed and counts as current.
#
# Click (`--popup`) runs macarchy-update in a macarchy-popup window, lists the
# outdated brew packages, then re-checks so the dot clears.

# Appended, not prepended like the other plugins: SketchyBar starts plugins
# with launchd's bare PATH, so the order only matters under tests, whose stubs
# must win over the real brew and sketchybar.
export PATH="$PATH:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$HOME/.local/bin"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null

SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
TIMEOUT="${UPDATES_TIMEOUT:-20}"

# brew runs natively: under a Rosetta shell an arm64 Homebrew refuses to run
# without `arch -arm64`. BREW overrides the lookup (tests).
brew_run() {
  local brew="${BREW:-$(command -v brew)}"
  [ -n "$brew" ] && [ -x "$brew" ] || return 127
  if [ "$(uname -m)" = x86_64 ] && [ "${brew#/opt/homebrew/}" != "$brew" ]; then
    arch -arm64 "$brew" "$@"
  else
    "$brew" "$@"
  fi
}

case "${1:-}" in
  --popup)
    q_self="$(printf '%q' "$SELF")"
    exec "$HOME/.config/macarchy/bin/macarchy-popup" macarchy-update "env MACARCHY_UPDATES_POPUP=1 $q_self"
    ;;
esac

if [ "${MACARCHY_UPDATES_POPUP:-}" = 1 ]; then
  macarchy-update || echo "macarchy-update failed (exit $?)"
  outdated="$(brew_run outdated 2>/dev/null)"
  if [ -n "$outdated" ]; then
    printf '\n==> Outdated Homebrew packages\n%s\nRun: brew upgrade\n' "$outdated"
  fi
  # re-check so the dot clears; not in popup mode, and not waiting on this terminal
  MACARCHY_UPDATES_POPUP='' NAME=updates SENDER='' nohup "$SELF" </dev/null >/dev/null 2>&1 &
  printf '\nPress return to close. '
  read -r _
  exit 0
fi

source "$CONFIG_DIR/plugins/hover.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/macarchy-updates.XXXXXX")" || exit 0
trap 'rm -rf "$TMP"' EXIT

brew_run outdated --quiet >"$TMP/brew" 2>/dev/null &
if command -v macarchy-update >/dev/null 2>&1; then
  {
    macarchy-update --check >"$TMP/macarchy" 2>/dev/null
    echo $? >"$TMP/macarchy.rc"
  } &
fi

# Wait for both, up to TIMEOUT seconds, then drop whatever is still running.
for _ in $(seq $((TIMEOUT * 5))); do
  [ -n "$(jobs -pr)" ] || break
  sleep 0.2
done
for pid in $(jobs -pr); do
  pkill -P "$pid" 2>/dev/null
  kill "$pid" 2>/dev/null
done

parts=()
n="$(grep -c . "$TMP/brew" 2>/dev/null)"
[ "${n:-0}" -gt 0 ] && parts+=("$n brew")
if [ "$(cat "$TMP/macarchy.rc" 2>/dev/null)" = 10 ]; then
  latest="$(sed -n 's/^latest: //p' "$TMP/macarchy")"
  parts+=("macarchy ${latest:-update}")
fi

if [ ${#parts[@]} -gt 0 ]; then
  LABEL="${parts[0]}"
  [ ${#parts[@]} -gt 1 ] && LABEL="$LABEL · ${parts[1]}"
  sketchybar --set "$NAME" \
    drawing=on \
    icon="󰧞" \
    icon.color="$WHITE" \
    label="$LABEL" \
    label.color="$WHITE"
else
  sketchybar --set "$NAME" drawing=off label.drawing=off
fi
