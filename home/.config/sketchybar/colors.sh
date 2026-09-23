#!/usr/bin/env bash
# Derived from the active theme: ~/.config/theme/current/colors.sh
# Edit the theme, not this file.
#
# The bar is monochrome, like Omarchy's waybar: every glyph is the theme
# foreground, and state is shown by brightness (full / dim / faint), not hue.
# RED is kept for the one genuinely alarming state, a nearly empty battery.

# shellcheck disable=SC1091
source "$HOME/.config/theme/current/colors.sh"

# Snapshot the raw palette first, so deriving never reads an already-prefixed value.
_bg=$BG
_fg=$FG
_muted=$MUTED
_red=$RED
_green=$GREEN
_yellow=$YELLOW
_blue=$BLUE
_magenta=$MAGENTA

# Base palette
export BLACK=0xff${_bg}
export WHITE=0xff${_fg}
export RED=0xff${_red}
export GREEN=0xff${_green}
export BLUE=0xff${_blue}
export YELLOW=0xff${_yellow}
export MAGENTA=0xff${_magenta}
export GREY=0xff${_muted}
export TRANSPARENT=0x00000000

# Bar background: opaque theme background, flush with the screen edge.
export BAR_BG=0xff${_bg}

# Foreground at three brightnesses. Spaces use all three; muted/offline
# indicators use FG_DIM.
export FG_FULL=0xff${_fg}
export FG_DIM=0x99${_fg}
export FG_FAINT=0x55${_fg}
