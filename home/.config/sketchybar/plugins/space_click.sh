#!/usr/bin/env bash
# Switch to a native macOS Space on click.
#
# `yabai -m space --focus` needs the scripting addition (SIP), which this setup
# does not enable, so fall back to the native ctrl+<number> shortcut. That
# shortcut must be enabled in:
#   System Settings > Keyboard > Keyboard Shortcuts > Mission Control
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"
SID="$1"

yabai -m space --focus "$SID" 2>/dev/null && exit 0

# macOS key codes for the digits 1..9 (same table theme-wallpaper-enroll uses)
case "$SID" in
  1) code=18 ;; 2) code=19 ;; 3) code=20 ;; 4) code=21 ;; 5) code=23 ;;
  6) code=22 ;; 7) code=26 ;; 8) code=28 ;; 9) code=25 ;;
  *) exit 0 ;;
esac
osascript -e "tell application \"System Events\" to key code $code using control down" 2>/dev/null || true
