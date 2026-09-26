#!/usr/bin/env bash
# Bluetooth, the item the native menu bar loses once the bar covers it.
#
#   󰂲 dim     Bluetooth off
#   󰂯         on, nothing connected
#   󰂱 N       N devices connected
#
# Hover lists the connected devices, with a battery percentage where macOS
# knows one. Power and the device list come from blueutil (the bar component
# installs it); sketchybarrc skips the item entirely without it.
#
# Battery comes from `system_profiler SPBluetoothDataType -json`, matched to
# blueutil's devices by address. It answers in about 0.1s and covers AirPods
# (left / right / case) as well as Magic accessories (main). ioreg's
# BatteryPercent only exists for the Magic HID devices, so it would miss
# headphones. Third-party mice and keyboards report no battery either way and
# show just their name. The call is capped at 1s so a slow Bluetooth stack
# never stalls the item; without it the names still show.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

# run_capped <seconds> <cmd...> -- the command's output, or nothing if it
# takes longer. macOS ships no timeout(1), so perl forks the command into its
# own process group and kills the whole group on the alarm; killing only the
# command would leave any child holding the output pipe open.
run_capped() {
  perl -e '
    my $secs = shift;
    defined(my $pid = fork) or exit 1;
    if (!$pid) { setpgrp; exec @ARGV or exit 127 }
    $SIG{ALRM} = sub { kill "KILL", -$pid; exit 1 };
    alarm $secs;
    waitpid $pid, 0;
    exit $? >> 8;
  ' "$@" 2>/dev/null
}

POWER="$(blueutil --power 2>/dev/null)"

case "$POWER" in
  0)
    sketchybar --set "$NAME" \
      icon="󰂲" \
      icon.color="$FG_DIM" \
      label="Bluetooth off" \
      label.color="$FG_DIM"
    exit 0
    ;;
  1) ;;
  *) exit 0 ;; # blueutil failed (no Bluetooth permission yet): keep the last state
esac

CONNECTED="$(blueutil --connected --format json 2>/dev/null)"
COUNT="$(jq -r 'length' <<<"${CONNECTED:-[]}" 2>/dev/null)"

if [ "${COUNT:-0}" -eq 0 ]; then
  sketchybar --set "$NAME" \
    icon="󰂯" \
    icon.color="$WHITE" \
    label="No devices" \
    label.color="$WHITE"
  exit 0
fi

PROFILE="$(run_capped 1 system_profiler SPBluetoothDataType -json)"
jq -e . >/dev/null 2>&1 <<<"$PROFILE" || PROFILE="{}" # timed out, failed or cut short

# "Name 80%, Other" -- blueutil writes addresses as dc-da-fb-..., the
# profiler as DC:DA:FB:..., so normalise before matching. AirPods report each
# bud separately; the lower one is what runs out first.
LABEL="$(jq -rn --argjson bt "$CONNECTED" --argjson sp "$PROFILE" '
  def pct: if . then sub("%$"; "") | tonumber else null end;
  ([$sp.SPBluetoothDataType[]?.device_connected[]? | to_entries[] | .value]
    | map({key: (.device_address // "" | ascii_upcase), value: .}) | from_entries) as $info
  | [$bt[] | . as $d
      | ($info[$d.address | ascii_upcase | gsub("-"; ":")] // {}) as $i
      | ([$i.device_batteryLevelMain, $i.device_batteryLevelLeft, $i.device_batteryLevelRight]
          | map(pct) | map(select(. != null)) | min) as $b
      | $d.name + (if $b then " \($b)%" else "" end)]
  | join(", ")' 2>/dev/null)"

sketchybar --set "$NAME" \
  icon="󰂱 $COUNT" \
  icon.color="$WHITE" \
  label="${LABEL:-$COUNT connected}" \
  label.color="$WHITE"
