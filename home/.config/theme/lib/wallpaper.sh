#!/usr/bin/env bash
# theme/lib/wallpaper.sh -- which image a theme shows, and how to repaint it.
#
#   . "$HOME/.config/theme/lib/wallpaper.sh"
#   theme_wallpaper_for <theme-dir>    print the image the theme shows now
#   theme_wallpaper_push <shared-file> point the visible desktops at it, repaint
#
# Written for bash 3.2 (macOS system bash).

# The background theme-bg remembered in .bg, else the first one in
# backgrounds/, else the palette-generated gradient. Fails if there is none.
theme_wallpaper_for() {
  local bg
  bg="$(cat "$1/.bg" 2>/dev/null || true)"
  [ -f "$bg" ] || bg="$(find "$1/backgrounds" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.png' \) 2>/dev/null | LC_ALL=C sort | head -1)"
  [ -f "$bg" ] || bg="$1/wallpaper.jpg"
  [ -f "$bg" ] || return 1
  echo "$bg"
}

# Every Space already points at the shared file; only its contents changed.
# Tested: set-picture alone does not repaint when the path is unchanged, so
# WallpaperAgent must be restarted -- but only after it has written the
# request to its store, or the restart throws the request away (it was being
# killed ~8 ms after receiving it and nothing updated).
theme_wallpaper_push() {
  local store="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist" before i=0
  before="$(stat -f %Fm "$store" 2>/dev/null || true)"
  osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$1\"" >/dev/null 2>&1 || true
  while [ -n "$before" ] && [ "$i" -lt 30 ] && [ "$(stat -f %Fm "$store" 2>/dev/null || true)" = "$before" ]; do
    sleep 0.1
    i=$((i + 1))
  done
  killall WallpaperAgent >/dev/null 2>&1 || true
}
