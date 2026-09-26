#!/usr/bin/env bats
# The tailscale bar item: plugins/tailscale.sh renders each BackendState from
# a `tailscale status --json` fixture and toggles up/down on click;
# items/tailscale.sh adds nothing when the CLI is absent.

setup() {
  load helpers
  common_setup
  SB="$REPO/home/.config/sketchybar"
  FIX="$REPO/tests/fixtures/tailscale"
  export CONFIG_DIR="$SB" PLUGIN_DIR="$SB/plugins" NAME=tailscale SENDER=routine
  export TAILSCALE_APP_CLI="$BATS_TEST_TMPDIR/no-such-app/Tailscale"
  mkdir -p "$HOME/.config/theme/current"
  printf 'BG=111111\nFG=eeeeee\nMUTED=888888\nRED=ff0000\n' >"$HOME/.config/theme/current/colors.sh"

  # The plugin puts /opt/homebrew/bin first on PATH, ahead of $STUBS, so the
  # commands it must not really run are stubbed as exported functions, which
  # win over any PATH lookup. `tailscale status` prints $TS_FIXTURE.
  sketchybar() { echo "sketchybar $*" >>"$STUB_LOG"; }
  open() { echo "open $*" >>"$STUB_LOG"; }
  tailscale() {
    echo "tailscale $*" >>"$STUB_LOG"
    [ "$1" = status ] && cat "$TS_FIXTURE"
    return 0
  }
  export -f sketchybar open tailscale
}

render() { # render <fixture> -- run the plugin, leave its --set line in $out
  export TS_FIXTURE="$FIX/$1.json"
  run "$SB/plugins/tailscale.sh"
  [ "$status" -eq 0 ]
  out="$(grep '^sketchybar --set tailscale ' "$STUB_LOG")"
}

@test "Running: connected glyph at full brightness, label is the machine name" {
  render running
  [[ $out == *"icon=󰌘 "* ]]
  [[ $out == *"icon.color=0xffeeeeee "* ]]
  [[ $out == *"label=laptop "* ]]
}

@test "Running with an exit node: globe glyph, label names the exit node" {
  render running-exit-node
  [[ $out == *"icon=󰇧 "* ]]
  [[ $out == *"icon.color=0xffeeeeee "* ]]
  [[ $out == *"label=laptop via homeserver "* ]]
}

@test "Stopped: disconnected glyph, dim" {
  render stopped
  [[ $out == *"icon=󰌙 "* ]]
  [[ $out == *"icon.color=0x99eeeeee "* ]]
  [[ $out == *"label=Tailscale off "* ]]
}

@test "NeedsLogin: disconnected glyph, dim, asks to log in" {
  render needs-login
  [[ $out == *"icon=󰌙 "* ]]
  [[ $out == *"icon.color=0x99eeeeee "* ]]
  [[ $out == *"label=Log in to Tailscale "* ]]
}

@test "daemon not answering: dim, says not running" {
  render missing-fixture
  [[ $out == *"icon.color=0x99eeeeee "* ]]
  [[ $out == *"label=Tailscale not running "* ]]
}

@test "hover only toggles the label, without querying tailscale" {
  export TS_FIXTURE="$FIX/running.json"
  SENDER=mouse.entered run "$SB/plugins/tailscale.sh"
  [ "$(cat "$STUB_LOG")" = "sketchybar --set tailscale label.drawing=on" ]
}

@test "click while Running runs down, then redraws" {
  export SENDER=mouse.clicked
  render running
  grep -qx 'tailscale down' "$STUB_LOG"
  run ! grep -q 'tailscale up' "$STUB_LOG"
  [ "$(grep -cx "tailscale status --json" "$STUB_LOG")" -eq 2 ]
}

@test "click while Stopped runs up" {
  export SENDER=mouse.clicked
  render stopped
  grep -qx 'tailscale up' "$STUB_LOG"
  run ! grep -q 'tailscale down' "$STUB_LOG"
}

@test "click on NeedsLogin opens the app instead of up/down" {
  export SENDER=mouse.clicked
  render needs-login
  grep -qx 'open -a Tailscale' "$STUB_LOG"
  run ! grep -Eq 'tailscale (up|down)' "$STUB_LOG"
}

@test "the app bundle binary is used when tailscale is not on PATH" {
  unset -f tailscale
  export TAILSCALE_APP_CLI="$BATS_TEST_TMPDIR/app/Tailscale"
  mkdir -p "${TAILSCALE_APP_CLI%/*}"
  printf '#!/usr/bin/env bash\necho "app $*" >>"$STUB_LOG"\ncat "%s"\n' "$FIX/stopped.json" >"$TAILSCALE_APP_CLI"
  chmod +x "$TAILSCALE_APP_CLI"
  PATH="$STUBS:/usr/bin:/bin" render stopped
  grep -qx 'app status --json' "$STUB_LOG"
  [[ $out == *"label=Tailscale off "* ]]
}

@test "bar_item_tailscale adds the item when the CLI exists" {
  # shellcheck disable=SC1091
  . "$SB/items/tailscale.sh"
  bar_item_tailscale
  run cat "$STUB_LOG"
  [[ $output == "sketchybar --add item tailscale right --set tailscale "* ]]
  [[ $output == *"update_freq=15"* ]]
  [[ $output == *"script=$SB/plugins/tailscale.sh"* ]]
  [[ $output == *"--subscribe tailscale mouse.clicked mouse.entered mouse.exited" ]]
}

@test "bar_item_tailscale adds nothing when the CLI is absent" {
  unset -f tailscale
  # shellcheck disable=SC1091
  . "$SB/items/tailscale.sh"
  PATH="$STUBS:/usr/bin:/bin" bar_item_tailscale
  [ ! -s "$STUB_LOG" ]
}
