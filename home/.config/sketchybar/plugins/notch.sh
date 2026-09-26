#!/usr/bin/env bash
# Put the clock and the mic / camera / now-playing items where they belong on
# each display. sketchybarrc adds each of them twice: at q / e (beside the
# notch) and again, with a ".c" suffix, at center. SketchyBar's q and e hug
# the notch on the built-in display but hug the exact midpoint on any other,
# so a clock at q would end at the center of an external monitor instead of
# sitting on it. This shows the q / e copy only on displays with a notch and
# the center copy everywhere else.
#
# Runs once at bar load and on space_change / display_change / system_woke,
# which covers plugging a monitor in or out (arrangement ids change with it).

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

PAIRS="clock media mic cam"
# `display=` with no ids means every display, so an empty side of the split
# gets an id no Mac has: display=16 draws the item nowhere.
NOWHERE=16

# Two lines: arrangement ids with a notch, then the rest. A display has a notch
# when AppKit reports a top safe-area inset for it; sketchybar's own query maps
# that display id to the arrangement id `display=` wants.
lists="$(
  osascript -l JavaScript - "$(sketchybar --query displays)" 2>/dev/null <<'EOF'
function run(argv) {
  ObjC.import("AppKit");
  var notched = {};
  var screens = $.NSScreen.screens;
  for (var i = 0; i < screens.count; i++) {
    var s = screens.objectAtIndex(i);
    if (s.safeAreaInsets.top > 0)
      notched[s.deviceDescription.objectForKey("NSScreenNumber").integerValue] = true;
  }
  var withNotch = [], without = [];
  JSON.parse(argv[0]).forEach(function (d) {
    (notched[d.DirectDisplayID] ? withNotch : without).push(d["arrangement-id"]);
  });
  return withNotch.join(",") + "\n" + without.join(",");
}
EOF
)"
[ -n "$lists" ] || exit 0 # could not tell; leave the q / e copy on every display

notch="${lists%%$'\n'*}"
plain="${lists#*$'\n'}"
[ -n "$notch" ] || notch=$NOWHERE
[ -n "$plain" ] || plain=$NOWHERE

args=()
for it in $PAIRS; do
  args+=(--set "$it" display="$notch" --set "$it.c" display="$plain")
done
sketchybar "${args[@]}"
