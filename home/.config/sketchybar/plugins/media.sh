#!/usr/bin/env bash

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null

STATE="$(osascript -e '
if application "Spotify" is running then
  tell application "Spotify"
    if player state is playing then
      return "Spotify|" & name of current track & " - " & artist of current track
    end if
  end tell
end if
if application "Music" is running then
  tell application "Music"
    if player state is playing then
      return "Music|" & name of current track & " - " & artist of current track
    end if
  end tell
end if
return ""
' 2>/dev/null)"

if [ -n "$STATE" ]; then
  APP="${STATE%%|*}"
  TITLE="${STATE#*|}"
  if [ ${#TITLE} -gt 30 ]; then
    TITLE="${TITLE:0:28}…"
  fi
  if [ "$APP" = "Spotify" ]; then
    ICON=""
  else
    ICON=""
  fi
  sketchybar --set "$NAME" \
    drawing=on \
    icon="$ICON" \
    icon.color="$WHITE" \
    label="$TITLE" \
    label.color="$WHITE"
else
  sketchybar --set "$NAME" drawing=off
fi
