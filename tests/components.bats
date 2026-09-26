#!/usr/bin/env bats
# components.sh: which component owns a file, dependency resolution, and the
# repo-path helpers every script shares.

setup() {
  load helpers
  common_setup
  # shellcheck disable=SC1091
  . "$REPO/home/.config/macarchy/components.sh"
}

@test "component_of maps each area to its component" {
  [ "$(macarchy_component_of .config/theme/themes/nord/colors.sh)" = themes ]
  [ "$(macarchy_component_of .local/bin/theme-set)" = themes ]
  [ "$(macarchy_component_of .config/yabai/yabairc)" = wm ]
  [ "$(macarchy_component_of .config/theme/bin/hotkey-check)" = wm ]
  [ "$(macarchy_component_of .local/bin/macarchy-center)" = wm ]
  [ "$(macarchy_component_of .config/sketchybar/sketchybarrc)" = bar ]
  [ "$(macarchy_component_of .config/borders/bordersrc)" = borders ]
  [ "$(macarchy_component_of .local/bin/macarchy-keys)" = keys ]
  [ "$(macarchy_component_of .config/macarchy/agent/ws.py)" = agent ]
  [ "$(macarchy_component_of .local/bin/macarchy-doctor)" = core ]
  [ "$(macarchy_component_of .local/bin/macarchy-uninstall)" = core ]
}

@test "every file under home/ belongs to a known component" {
  while IFS= read -r rel; do
    c="$(macarchy_component_of "${rel#home/}")"
    case " core $MACARCHY_ALL_COMPONENTS " in *" $c "*) ;; *)
      echo "$rel -> $c"
      return 1
      ;;
    esac
  done < <(macarchy_repo_files "$REPO")
}

@test "every file under home/ is inside a link dir, so prune and uninstall reach it" {
  while IFS= read -r rel; do
    rel="${rel#home/}"
    hit=0
    for d in $MACARCHY_LINK_DIRS; do
      case "$rel" in "$d"/*) hit=1 ;; esac
    done
    if [ "$hit" = 0 ]; then
      echo "$rel is outside MACARCHY_LINK_DIRS ($MACARCHY_LINK_DIRS)"
      return 1
    fi
  done < <(macarchy_repo_files "$REPO")
  [ "$(macarchy_link_dirs | head -1)" = "$HOME/.config" ]
}

@test "resolve adds dependencies and keeps canonical order" {
  run macarchy_resolve_components bar wm
  [ "$status" -eq 0 ]
  [ "${lines[${#lines[@]} - 1]}" = "themes wm bar" ]
  [[ $output == *"bar needs themes"* ]]
}

@test "resolve drops unknown components with a warning" {
  run macarchy_resolve_components themes nope
  [ "${lines[${#lines[@]} - 1]}" = "themes" ]
  [[ $output == *"unknown component 'nope'"* ]]
}

@test "has: core always, others only when listed" {
  export MACARCHY_COMPONENTS="themes"
  macarchy_has core
  macarchy_has themes
  run ! macarchy_has wm
}

@test "has: unset means everything" {
  unset MACARCHY_COMPONENTS
  macarchy_has agent
}

@test "stable_repo maps a Homebrew Cellar path to opt" {
  [ "$(macarchy_stable_repo /opt/homebrew/Cellar/macarchy/1.2.3/libexec)" = /opt/homebrew/opt/macarchy/libexec ]
  [ "$(macarchy_stable_repo /Users/me/src/macarchy)" = /Users/me/src/macarchy ]
}

@test "is_our_link accepts links through the repo path and its real path" {
  # Like Homebrew: links made through opt/ (alias) and through Cellar/ (real)
  tmp="$(cd "$BATS_TEST_TMPDIR" && pwd -P)"
  mkdir -p "$tmp/real/home" && touch "$tmp/real/home/f"
  ln -s real "$tmp/alias"
  ln -s "$tmp/real/home/f" "$HOME/via-real"
  ln -s "$tmp/alias/home/f" "$HOME/via-alias"
  ln -s /etc/hosts "$HOME/foreign"
  touch "$HOME/plain"
  macarchy_is_our_link "$HOME/via-real" "$tmp/alias"
  macarchy_is_our_link "$HOME/via-alias" "$tmp/alias"
  run ! macarchy_is_our_link "$HOME/foreign" "$tmp/alias"
  run ! macarchy_is_our_link "$HOME/plain" "$tmp/alias"
}
