#!/usr/bin/env bash
# Shared by the icon-only right-hand items: show the label while the pointer is
# over the item, hide it again on exit. Omarchy does this with tooltips;
# SketchyBar has none, so the label stands in for one.
#
# Source this after $NAME and $SENDER are set. It exits the plugin on hover
# events so the caller never recomputes its value just for a mouse move.
case "$SENDER" in
  mouse.entered)
    sketchybar --set "$NAME" label.drawing=on
    exit 0
    ;;
  mouse.exited)
    sketchybar --set "$NAME" label.drawing=off
    exit 0
    ;;
esac
