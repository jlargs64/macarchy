#!/usr/bin/env bats
# The layout settings in ~/.config/macarchy/config reach yabai, borders and the
# bar: yabairc and bordersrc run against stubs and their argv is checked.

setup() {
  load helpers
  common_setup
  mkdir -p "$HOME/.config/theme/themes/nord"
  ln -s "$REPO/home/.config/theme/themes/nord" "$HOME/.config/theme/current"
  ln -s "$REPO/home/.config/macarchy/lib.sh" "$HOME/.config/macarchy/lib.sh" 2>/dev/null ||
    { mkdir -p "$HOME/.config/macarchy" && ln -s "$REPO/home/.config/macarchy/lib.sh" "$HOME/.config/macarchy/lib.sh"; }
  # yabairc ends by laying out the visible Spaces; nothing to do here
  mkdir -p "$HOME/.local/bin"
  printf '#!/bin/sh\nexit 0\n' >"$HOME/.local/bin/macarchy-center"
  chmod +x "$HOME/.local/bin/macarchy-center"
  menu_bar_autohide 1 # the documented setup: the bar covers an auto-hidden menu bar
}

# menu_bar_autohide 0|1 -- what `defaults read NSGlobalDomain _HIHideMenuBar` says
menu_bar_autohide() { stub defaults "[ \"\$2\" = NSGlobalDomain ] && echo $1; exit 0"; }

yabai_rc() { run bash "$REPO/home/.config/yabai/yabairc"; }
borders_rc() { run bash "$REPO/home/.config/borders/bordersrc"; }

@test "yabairc applies the default gaps, padding and bar strip" {
  yabai_rc
  [ "$status" -eq 0 ]
  grep -q '^yabai -m config external_bar all:32:0$' "$STUB_LOG"
  grep -q '^yabai -m config top_padding 8$' "$STUB_LOG"
  grep -q '^yabai -m config bottom_padding 20$' "$STUB_LOG"
  grep -q '^yabai -m config window_gap 8$' "$STUB_LOG"
}

@test "MACARCHY_* in the config override the layout" {
  cat >"$HOME/.config/macarchy/config" <<'CFG'
MACARCHY_GAP=12
MACARCHY_PADDING_BOTTOM=30
MACARCHY_BAR_HEIGHT=36
MACARCHY_BORDER_WIDTH=3
MACARCHY_BORDER_STYLE=square
CFG
  yabai_rc
  [ "$status" -eq 0 ]
  grep -q '^yabai -m config external_bar all:36:0$' "$STUB_LOG"
  grep -q '^yabai -m config bottom_padding 30$' "$STUB_LOG"
  grep -q '^yabai -m config left_padding 8$' "$STUB_LOG"
  grep -q '^yabai -m config window_gap 12$' "$STUB_LOG"
  borders_rc
  [ "$status" -eq 0 ]
  grep -q '^borders style=square width=3.0 hidpi=off active_color=0xff' "$STUB_LOG"
}

@test "an always-visible menu bar reserves only the bar's overhang below it" {
  # macOS already excludes the menu bar (30pt on an external display) and
  # yabai stacks external_bar on top of it, so a full 32pt would push every
  # window 30pt down. Only the 2pt the bar hangs below the menu bar is left.
  menu_bar_autohide 0
  yabai_rc
  [ "$status" -eq 0 ]
  grep -q '^yabai -m config external_bar all:2:0$' "$STUB_LOG"
  grep -q '^yabai -m config top_padding 8$' "$STUB_LOG"
}

@test "a visible menu bar taller than the bar reserves nothing extra" {
  printf 'MACARCHY_BAR_HEIGHT=24\n' >"$HOME/.config/macarchy/config"
  menu_bar_autohide 0
  yabai_rc
  [ "$status" -eq 0 ]
  grep -q '^yabai -m config external_bar all:0:0$' "$STUB_LOG"
}

@test "bordersrc defaults to a 6px round border in the theme's accent" {
  borders_rc
  [ "$status" -eq 0 ]
  grep -q '^borders style=round width=6.0 hidpi=off active_color=0xff[0-9a-f]\{6\} inactive_color=0xff[0-9a-f]\{6\}$' "$STUB_LOG"
}
