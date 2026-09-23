#!/usr/bin/env bash
# Renders one native macOS Space indicator: its number, at one of three
# brightnesses.
#
#   focused    full foreground, bold
#   occupied   dim   (has at least one non-minimized window, per yabai)
#   empty      faint
#
# Focus detection order:
#   1. on `space_change`: $SELECTED, which SketchyBar sets from the macOS
#      notification itself (fastest; yabai lags it on swipes)
#   2. otherwise: yabai's own view of which space has focus
#   3. yabai missing: $SELECTED again
# so the bar still highlights correctly if yabai is stopped or lacks
# Accessibility permission. Without yabai every unfocused Space renders as
# occupied, since there is no way to ask what is on it.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
# shellcheck disable=SC1091
source "$HOME/.config/macarchy/lib.sh" 2>/dev/null || true

SID="$1"

# ----- which space has focus? ----------------------------------------------
# On SketchyBar's native `space_change` event trust $SELECTED: it arrives with
# the macOS notification, while yabai's own view of the focused space can lag
# it by a few hundred ms. Asking yabai here made the bar render the OLD space
# first and only correct itself when yabai's `space_changed` signal fired,
# which showed up as a ~500ms delay on every swipe. Every other event (and the
# initial draw) still asks yabai, which is authoritative once settled.
FOCUSED=""
if [ "${SENDER:-}" = "space_change" ] && [ -n "${SELECTED:-}" ]; then
  [ "$SELECTED" = "true" ] && FOCUSED="$SID" || FOCUSED="not-$SID"
elif command -v yabai >/dev/null 2>&1; then
  FOCUSED="$(yabai -m query --spaces 2>/dev/null |
    jq -r 'map(select(."has-focus" == true)) | .[0].index // empty' 2>/dev/null)"
fi

if [ -n "$FOCUSED" ]; then
  [ "$SID" = "$FOCUSED" ] && IS_FOCUSED=1 || IS_FOCUSED=0
else
  # yabai unavailable: trust SketchyBar's own space component
  [ "${SELECTED:-false}" = "true" ] && IS_FOCUSED=1 || IS_FOCUSED=0
fi

# ----- does this space have windows? ---------------------------------------
WINDOWS=""
if command -v yabai >/dev/null 2>&1; then
  WINDOWS="$(yabai -m query --windows --space "$SID" 2>/dev/null |
    jq -r 'map(select(."is-minimized" == false)) | length' 2>/dev/null)"
fi

# ----- render ---------------------------------------------------------------
if [ "$IS_FOCUSED" -eq 1 ]; then
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
