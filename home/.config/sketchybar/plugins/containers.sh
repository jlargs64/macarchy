#!/usr/bin/env bash
# Running containers across Docker and Podman. The icon carries the total;
# hover shows the split ("2 docker · 1 podman"). Hidden when nothing runs,
# including when neither daemon is up, like av.sh hides an idle mic.
#
# Each CLI gets one second to answer. A stopped Docker Desktop or Podman
# machine usually fails fast, but a wedged socket can hang `ps` for much
# longer, and this runs every 10s. There is no `timeout` on stock macOS, and
# `perl -e alarm` does not work here: Go binaries ignore SIGALRM. So the query
# runs in the background with a watchdog that SIGKILLs it after 1s.

# Docker Desktop links its CLI into /usr/local/bin, the Podman installer puts
# it in /opt/podman/bin. The tests point CONTAINERS_PATH at their stubs.
export PATH="${CONTAINERS_PATH-/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/opt/podman/bin}:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

TMP="$(mktemp "${TMPDIR:-/tmp}/sketchybar-containers.XXXXXX")" || exit 0
trap 'rm -f "$TMP"' EXIT

# running <cli>: how many containers `<cli> ps -q` lists, 0 when the CLI is
# missing, fails or does not answer within a second. Output goes to a file,
# not a pipe, so a killed query's leftover children cannot hold us open.
running() {
  command -v "$1" >/dev/null 2>&1 || {
    echo 0
    return
  }
  "$1" ps -q >"$TMP" 2>/dev/null </dev/null &
  local pid=$!
  (sleep 1 && kill -9 "$pid") >/dev/null 2>&1 &
  local watchdog=$!
  if wait "$pid"; then
    echo $(($(grep -c . "$TMP")))
  else
    echo 0
  fi
  kill "$watchdog" 2>/dev/null
}

DOCKER="$(running docker)"
PODMAN="$(running podman)"
TOTAL=$((DOCKER + PODMAN))

if [ "$TOTAL" -gt 0 ]; then
  LABEL=""
  [ "$DOCKER" -gt 0 ] && LABEL="$DOCKER docker"
  [ "$PODMAN" -gt 0 ] && LABEL="${LABEL:+$LABEL · }$PODMAN podman"
  sketchybar --set "$NAME" drawing=on icon="󰡨 $TOTAL" icon.color="$WHITE" label="$LABEL" label.color="$WHITE"
else
  sketchybar --set "$NAME" drawing=off label.drawing=off
fi
