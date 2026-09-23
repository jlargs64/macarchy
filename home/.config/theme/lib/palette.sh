#!/usr/bin/env bash
# theme/lib/palette.sh -- resolve a theme's full terminal palette.
#
#   . "$HOME/.config/theme/lib/palette.sh"
#   theme_palette <theme-dir>
#
# Sets bare hex (no #) in:
#   P_BG P_FG P_CURSOR P_CURSOR_TEXT P_SEL_BG P_SEL_FG P_0 .. P_15
# and P_APPEARANCE (dark|light, from the background's luminance).
#
# The theme's `ghostty` file is the source of truth, because every shipped
# theme carries a full 16-slot palette there. Anything it leaves out is
# derived from colors.sh with the same darken-for-dim rule theme-port uses,
# so a theme that only defines colors.sh still gets a complete palette.
#
# Written for bash 3.2 (macOS system bash).

_pal_darken15() {
  local h="$1" r g b
  r=$((16#${h:0:2}))
  g=$((16#${h:2:2}))
  b=$((16#${h:4:2}))
  printf '%02x%02x%02x' $(((r * 17 + 10) / 20)) $(((g * 17 + 10) / 20)) $(((b * 17 + 10) / 20))
}

# _pal_ghostty_all <file> -> shell assignments G_<key>=<hex> for every colour
# key in a Ghostty config, one awk pass (palette slots become G_palette_<n>).
_pal_ghostty_all() {
  [ -f "$1" ] || return 0
  awk '
    { line = $0; sub(/#.*$/, "", line) }
    line ~ /^[ \t]*$/ { next }
    {
      split(line, kv, "=")
      key = kv[1]; gsub(/[ \t]/, "", key)
      if (key == "palette") {
        rest = substr(line, index(line, "=") + 1)
        split(rest, pv, "=")
        n = pv[1]; gsub(/[ \t]/, "", n)
        val = pv[2]; key = "palette_" n
      } else {
        val = substr(line, index(line, "=") + 1)
      }
      gsub(/[ \t#]/, "", val)
      gsub(/-/, "_", key)
      if (val ~ /^[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]$/ && key ~ /^[a-z_0-9]+$/)
        printf "G_%s=%s\n", key, tolower(val)
    }
  ' "$1"
}

# shellcheck disable=SC2034  # P_* are read by the caller
theme_palette() {
  local dir="$1" i v derived
  # shellcheck disable=SC1091
  . "$dir/colors.sh"
  local G_background="" G_foreground="" G_cursor_color="" G_cursor_text=""
  local G_selection_background="" G_selection_foreground=""
  local G_palette_0="" G_palette_1="" G_palette_2="" G_palette_3="" G_palette_4=""
  local G_palette_5="" G_palette_6="" G_palette_7="" G_palette_8="" G_palette_9=""
  local G_palette_10="" G_palette_11="" G_palette_12="" G_palette_13="" G_palette_14=""
  local G_palette_15=""
  eval "$(_pal_ghostty_all "$dir/ghostty" | grep -E '^G_(background|foreground|cursor_color|cursor_text|selection_background|selection_foreground|palette_([0-9]|1[0-5]))=')"

  P_BG="${G_background:-$BG}"
  P_FG="${G_foreground:-$FG}"
  P_CURSOR="${G_cursor_color:-$ACCENT}"
  P_CURSOR_TEXT="${G_cursor_text:-$P_BG}"
  P_SEL_BG="${G_selection_background:-$MUTED}"
  P_SEL_FG="${G_selection_foreground:-$P_FG}"

  # Derived fallbacks, slot by slot: 0-7 dim, 8-15 bright. Only computed when
  # the ghostty file leaves a slot out.
  for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    eval "v=\$G_palette_$i"
    if [ -z "$v" ]; then
      [ -n "${derived:-}" ] || derived="$BG $(_pal_darken15 "$RED") $(_pal_darken15 "$GREEN") \
$(_pal_darken15 "$YELLOW") $(_pal_darken15 "$BLUE") $(_pal_darken15 "$MAGENTA") \
$(_pal_darken15 "$CYAN") $(_pal_darken15 "$FG") $MUTED $RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN $FG"
      # shellcheck disable=SC2086
      set -- $derived
      shift "$i"
      v="$1"
    fi
    eval "P_$i=\$v"
  done

  # Rec. 601 luma of the background; above half is a light theme.
  local r g b
  r=$((16#${P_BG:0:2}))
  g=$((16#${P_BG:2:2}))
  b=$((16#${P_BG:4:2}))
  if [ $((r * 299 + g * 587 + b * 114)) -gt 127500 ]; then P_APPEARANCE=light; else P_APPEARANCE=dark; fi
}
