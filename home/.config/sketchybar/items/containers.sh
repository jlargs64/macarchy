# shellcheck shell=bash
# Running containers, Docker and Podman combined (plugins/containers.sh).
# Self-hiding: drawn only while at least one container runs. Skipped entirely
# when neither CLI is installed. Click opens Docker Desktop, or Podman Desktop
# when only that is installed.

bar_item_containers() {
  # sketchybarrc's PATH lacks /opt/podman/bin, where the Podman installer puts
  # its CLI. The tests point CONTAINERS_PATH at their stubs.
  local path="$PATH:${CONTAINERS_PATH-/usr/local/bin:/opt/podman/bin}" click=""
  PATH="$path" command -v docker >/dev/null 2>&1 ||
    PATH="$path" command -v podman >/dev/null 2>&1 ||
    return 0

  if [ -d /Applications/Docker.app ]; then
    click="open -a Docker"
  elif [ -d "/Applications/Podman Desktop.app" ]; then
    click="open -a 'Podman Desktop'"
  fi

  sketchybar --add item containers right \
    --set containers \
    drawing=off \
    label.drawing=off \
    update_freq=10 \
    script="$PLUGIN_DIR/containers.sh" \
    click_script="$click" \
    --subscribe containers mouse.entered mouse.exited
}
