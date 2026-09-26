# Shared setup for the bats suite. Every test gets:
#   HOME      a fresh, empty fake home under $BATS_TEST_TMPDIR
#   STUBS     a directory first on PATH holding no-op stand-ins for every
#             command that could touch the real machine (launchctl, yabai,
#             brew, defaults, ...). Each stub appends its argv to $STUB_LOG.
#   REPO      this checkout
# Nothing a test runs can reach the real $HOME, services or LaunchAgents.

bats_require_minimum_version 1.5.0

REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
export REPO

stub() { # stub <name> [body] -- body defaults to "exit 0"
  printf '#!/usr/bin/env bash\necho "%s $*" >>"$STUB_LOG"\n%s\n' "$1" "${2:-exit 0}" >"$STUBS/$1"
  chmod +x "$STUBS/$1"
}

common_setup() {
  export REAL_HOME="$HOME"
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/Library/LaunchAgents"
  export STUBS="$BATS_TEST_TMPDIR/stubs" STUB_LOG="$BATS_TEST_TMPDIR/stub.log"
  mkdir -p "$STUBS"
  : >"$STUB_LOG"
  for c in launchctl yabai skhd sketchybar borders brew defaults killall osascript open uv ioreg pkill; do stub "$c"; done
  stub pgrep "exit 1"                                             # nothing is running unless a test says so
  stub launchctl '[ "$1" = print ] && exit 113; exit 0'           # no agent loaded
  export MACARCHY_YABAI_ERR_LOG="$BATS_TEST_TMPDIR/yabai.err.log" # not the real /tmp/yabai_$USER.err.log
  export PATH="$STUBS:$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  export NO_COLOR=1
  unset MACARCHY_COMPONENTS MACARCHY_THEME_TARGETS MACARCHY_UPDATE_AT_LOGIN
}

# write_config <components> -- a minimal ~/.config/macarchy/config
write_config() {
  mkdir -p "$HOME/.config/macarchy"
  printf 'MACARCHY_COMPONENTS="%s"\nMACARCHY_UPDATE_AT_LOGIN=false\n' "$1" >"$HOME/.config/macarchy/config"
}

# install_links <components> -- link the repo into $HOME the way install.sh
# does, through macarchy-update --no-pull (stubbed reloads, no theme set yet).
# Linking ~200 files is the slow part of the suite, so each component set is
# installed once per test file into a template and copied from there; the
# links are absolute paths into the repo, so a copy is identical.
install_links() {
  local tpl="$BATS_FILE_TMPDIR/tpl-${1// /-}"
  if [ ! -d "$tpl" ]; then
    mkdir -p "$tpl.tmp/.config" "$tpl.tmp/.local/bin" "$tpl.tmp/Library/LaunchAgents"
    (
      export HOME="$tpl.tmp"
      write_config "$1"
      "$REPO/home/.config/macarchy/bin/macarchy-update" --no-pull >/dev/null
    )
    mv "$tpl.tmp" "$tpl"
  fi
  cp -a "$tpl/." "$HOME/"
  : >"$STUB_LOG"
}
