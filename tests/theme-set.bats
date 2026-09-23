#!/usr/bin/env bats
# theme-set: the current symlink, hook dispatch and input validation. The
# real per-app hooks are swapped for a recorder so nothing on the machine
# restyles.

setup() {
  load helpers
  common_setup
  T="$HOME/.config/theme"
  mkdir -p "$T/bin" "$T/hooks" "$T/themes"
  ln -s "$REPO/home/.config/theme/bin/theme-list" "$T/bin/theme-list"
  for n in nord gruvbox; do ln -s "$REPO/home/.config/theme/themes/$n" "$T/themes/$n"; done
  record_hook alpha
  record_hook beta
}

# record_hook <name> -- a hook that logs its name, arg and palette
record_hook() {
  printf '#!/usr/bin/env bash\necho "%s $1 $THEME_NAME $BG $THEME_OUT" >>"$STUB_LOG"\n' "$1" >"$T/hooks/$1"
  chmod +x "$T/hooks/$1"
}

theme_set() { run "$REPO/home/.config/theme/bin/theme-set" "$@"; }

@test "points current at the theme and runs every hook with the palette" {
  theme_set nord
  [ "$status" -eq 0 ]
  [ "$output" = "theme: nord" ]
  [ "$(readlink "$T/current")" = "$T/themes/nord" ]
  grep -q "^alpha $T/themes/nord nord 2e3440 $T/generated$" "$STUB_LOG"
  grep -q "^beta " "$STUB_LOG"
  [ -d "$T/generated" ]
}

@test "switching themes moves the link" {
  theme_set nord
  theme_set gruvbox
  [ "$(readlink "$T/current")" = "$T/themes/gruvbox" ]
}

@test "MACARCHY_THEME_TARGETS limits which hooks run" {
  mkdir -p "$HOME/.config/macarchy"
  echo 'MACARCHY_THEME_TARGETS="beta"' >"$HOME/.config/macarchy/config"
  ln -s "$REPO/home/.config/macarchy/lib.sh" "$HOME/.config/macarchy/lib.sh"
  theme_set nord
  [ "$status" -eq 0 ]
  run ! grep -q "^alpha" "$STUB_LOG"
  grep -q "^beta" "$STUB_LOG"
}

@test "an unknown target is reported, not fatal" {
  mkdir -p "$HOME/.config/macarchy"
  echo 'MACARCHY_THEME_TARGETS="nope beta"' >"$HOME/.config/macarchy/config"
  ln -s "$REPO/home/.config/macarchy/lib.sh" "$HOME/.config/macarchy/lib.sh"
  theme_set nord
  [ "$status" -eq 0 ]
  [[ $output == *"no hook named 'nope'"* ]]
}

@test "user hooks in hooks.d run after the shipped ones" {
  mkdir -p "$HOME/.config/macarchy/hooks.d"
  printf '#!/usr/bin/env bash\necho "user $THEME_NAME" >>"$STUB_LOG"\n' >"$HOME/.config/macarchy/hooks.d/mine"
  chmod +x "$HOME/.config/macarchy/hooks.d/mine"
  theme_set nord
  [ "$(tail -1 "$STUB_LOG")" = "user nord" ]
}

@test "a failing hook is reported and the rest still run" {
  printf '#!/usr/bin/env bash\nexit 3\n' >"$T/hooks/alpha"
  theme_set nord
  [ "$status" -eq 0 ]
  [[ $output == *"hook alpha failed (exit 3)"* ]]
  grep -q "^beta" "$STUB_LOG"
}

@test "an unknown theme exits 1 and lists the real ones" {
  theme_set nosuch
  [ "$status" -eq 1 ]
  [[ $output == *"no such theme: nosuch"* ]]
  [[ $output == *"gruvbox"* ]]
  [ ! -e "$T/current" ]
}

@test "path-like names are refused before anything is sourced" {
  for bad in ../../etc "a/b" .hidden "two words"; do
    theme_set "$bad"
    [ "$status" -eq 1 ]
    [[ $output == *"invalid theme name"* ]]
  done
  [ ! -e "$T/current" ]
}

@test "no argument prints usage and exits 2" {
  theme_set
  [ "$status" -eq 2 ]
  [[ $output == *"usage: theme-set"* ]]
}
