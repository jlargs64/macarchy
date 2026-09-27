#!/usr/bin/env bash
# Renders one native macOS Space indicator: its number, at one of three
# brightnesses.
#
#   current    full foreground, bold (the Space its display is showing)
#   occupied   dim   (has at least one non-minimized window, per yabai)
#   empty      faint
#
# "Current" is per display: with two displays, each bar highlights the Space
# that display shows, so both stay lit whichever display has focus. Asking
# for the one focused Space instead left the other display's bar with nothing
# highlighted, and flipping between lit and unlit depending on which event
# drew it last (SketchyBar's $SELECTED is per display, yabai's has-focus is
# not).
#
# Detection order:
#   1. on `space_change`: $SELECTED, which SketchyBar sets from the macOS
#      notification itself (fastest; yabai lags it on swipes)
#   2. otherwise: yabai's is-visible for this Space
#   3. yabai missing: $SELECTED again
# so the bar still highlights correctly if yabai is stopped or lacks
# Accessibility permission. Without yabai every other Space renders as
# occupied, since there is no way to ask what is on it.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
# shellcheck disable=SC1091
source "$HOME/.config/macarchy/lib.sh" 2>/dev/null || true

SID="$1"

# ----- is this space the one its display shows? ----------------------------
# On SketchyBar's native `space_change` event trust $SELECTED: it arrives with
# the macOS notification, while yabai's own view can lag it by a few hundred
# ms. Asking yabai here made the bar render the OLD space first and only
# correct itself when yabai's `space_changed` signal fired, which showed up as
# a ~500ms delay on every swipe. Every other event (and the initial draw)
# still asks yabai, which is authoritative once settled.
VISIBLE=""
if [ "${SENDER:-}" = "space_change" ] && [ -n "${SELECTED:-}" ]; then
  VISIBLE="$SELECTED"
elif command -v yabai >/dev/null 2>&1; then
  VISIBLE="$(yabai -m query --spaces --space "$SID" 2>/dev/null |
    jq -r '."is-visible" // empty' 2>/dev/null)"
fi
# yabai unavailable: trust SketchyBar's own space component
[ -n "$VISIBLE" ] || VISIBLE="${SELECTED:-false}"
[ "$VISIBLE" = "true" ] && IS_CURRENT=1 || IS_CURRENT=0

# ----- does this space have windows? ---------------------------------------
WINDOWS=""
if command -v yabai >/dev/null 2>&1; then
  WINDOWS="$(yabai -m query --windows --space "$SID" 2>/dev/null |
    jq -r 'map(select(."is-minimized" == false)) | length' 2>/dev/null)"
fi

# ----- render ---------------------------------------------------------------
if [ "$IS_CURRENT" -eq 1 ]; then
  COLOR="$FG_FULL"
  FONT="$MACARCHY_FONT:Bold:13.0"
elif [ "${WINDOWS:-1}" -gt 0 ]; then
  COLOR="$FG_DIM"
  FONT="$MACARCHY_FONT:Regular:13.0"
else
  COLOR="$FG_FAINT"
  FONT="$MACARCHY_FONT:Regular:13.0"
fi

sketchybar --set "$NAME" \
  icon="$SID" \
  icon.color="$COLOR" \
  icon.font="$FONT"
