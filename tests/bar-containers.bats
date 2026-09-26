#!/usr/bin/env bats
# containers bar item: running count across docker and podman, hidden when
# idle, a hung daemon cannot stall the bar, and no item without either CLI.

setup() {
  load helpers
  common_setup
  export CONFIG_DIR="$REPO/home/.config/sketchybar" PLUGIN_DIR="$REPO/home/.config/sketchybar/plugins"
  export CONTAINERS_PATH="$STUBS" NAME=containers SENDER=routine
  rm -f "$STUBS/docker" "$STUBS/podman"
}

# ps_stub <cli> <n> -- `<cli> ps -q` lists n container ids
ps_stub() {
  stub "$1" "i=0; while [ \$i -lt $2 ]; do i=\$((i + 1)); echo id\$i; done"
}

plugin() {
  run "$PLUGIN_DIR/containers.sh"
  [ "$status" -eq 0 ]
}

@test "zero running containers: drawing=off" {
  ps_stub docker 0
  ps_stub podman 0
  plugin
  grep -q "sketchybar --set containers drawing=off" "$STUB_LOG"
  run ! grep -q "drawing=on" "$STUB_LOG"
}

@test "no daemon answering: drawing=off" {
  stub docker "echo 'Cannot connect to the Docker daemon' >&2; exit 1"
  stub podman "echo 'Cannot connect to Podman' >&2; exit 125"
  plugin
  grep -q "drawing=off" "$STUB_LOG"
  run ! grep -q "drawing=on" "$STUB_LOG"
}

@test "docker only: count and docker hover label" {
  ps_stub docker 3
  plugin
  grep -q "drawing=on icon=󰡨 3 .* label=3 docker label.color" "$STUB_LOG"
}

@test "podman only: count and podman hover label" {
  ps_stub podman 2
  plugin
  grep -q "drawing=on icon=󰡨 2 .* label=2 podman label.color" "$STUB_LOG"
}

@test "both: total and split hover label" {
  ps_stub docker 2
  ps_stub podman 1
  plugin
  grep -q "drawing=on icon=󰡨 3 .* label=2 docker · 1 podman label.color" "$STUB_LOG"
}

@test "a hung daemon is cut off after about a second" {
  stub docker "sleep 3; echo late"
  ps_stub podman 1
  SECONDS=0
  plugin
  [ "$SECONDS" -lt 3 ]
  grep -q "drawing=on icon=󰡨 1 .* label=1 podman label.color" "$STUB_LOG"
}

@test "hover events only toggle the label" {
  ps_stub docker 1
  SENDER=mouse.entered plugin
  [ "$(grep -c . "$STUB_LOG")" -eq 1 ]
  grep -q "sketchybar --set containers label.drawing=on" "$STUB_LOG"
}

@test "bar_item_containers adds nothing without docker or podman" {
  # shellcheck disable=SC1091
  . "$CONFIG_DIR/items/containers.sh"
  bar_item_containers
  run ! grep -q sketchybar "$STUB_LOG"
}

@test "bar_item_containers adds a hidden item when a CLI exists" {
  ps_stub podman 0
  # shellcheck disable=SC1091
  . "$CONFIG_DIR/items/containers.sh"
  bar_item_containers
  grep -q "sketchybar --add item containers right --set containers drawing=off" "$STUB_LOG"
  grep -q "script=$PLUGIN_DIR/containers.sh" "$STUB_LOG"
  grep -q "update_freq=10" "$STUB_LOG"
  grep -q -- "--subscribe containers mouse.entered mouse.exited" "$STUB_LOG"
}

@test "sourcing the item file runs nothing" {
  ps_stub docker 1
  run bash -c ". '$CONFIG_DIR/items/containers.sh'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -s "$STUB_LOG" ]
}
