#!/usr/bin/env bats
# macarchy-doctor against a fake $HOME: what it flags, what it fixes, and
# that it only checks the components you installed.

setup() {
  load helpers
  common_setup
  stub magick
  stub fzf
}

doctor() { run "$REPO/home/.config/macarchy/bin/macarchy-doctor" "$@"; }

# a themes-only install that should come back clean
healthy_themes() {
  install_links themes
  ln -s "$HOME/.config/theme/themes/nord" "$HOME/.config/theme/current"
  mkdir -p "$HOME/.config/theme/themes/nord/backgrounds"
  touch "$HOME/.config/theme/themes/nord/backgrounds/1.jpg"
}

@test "a healthy themes-only install has no failures" {
  healthy_themes
  doctor
  echo "$output"
  [ "$status" -eq 0 ]
  [[ $output == *"active theme: nord"* ]]
  [[ $output == *"files linked into"* ]]
  [[ $output != *FAIL* ]]
}

@test "skips sections for components you did not install" {
  healthy_themes
  doctor
  [[ $output == *Themes* ]]
  [[ $output != *"Window management"* ]]
  [[ $output != *"Status bar"* ]]
  [[ $output != *"Workspace agent"* ]]
}

@test "a missing link fails with the relink command" {
  healthy_themes
  rm "$HOME/.local/bin/theme-set"
  doctor
  [ "$status" -eq 1 ]
  [[ $output == *"1 file(s) not linked: ~/.local/bin/theme-set"* ]]
  [[ $output == *"fix: macarchy-update --no-pull"* ]]
}

@test "a real file where a link belongs is a warning, not a failure" {
  healthy_themes
  rm "$HOME/.local/bin/theme-list"
  echo mine >"$HOME/.local/bin/theme-list"
  doctor
  [ "$status" -eq 0 ]
  [[ $output == *"1 real file(s) sit where a link should be"* ]]
}

@test "a dangling link into the repo is reported" {
  healthy_themes
  ln -s "$REPO/home/.config/theme/bin/deleted-upstream" "$HOME/.local/bin/deleted-upstream"
  doctor
  [[ $output == *"1 dangling link(s)"* ]]
}

@test "no active theme fails with theme-set" {
  install_links themes
  doctor
  [ "$status" -eq 1 ]
  [[ $output == *"no active theme"* ]]
  [[ $output == *"fix: theme-set retro-82"* ]]
}

@test "a current link to a deleted theme fails" {
  install_links themes
  ln -s "$HOME/.config/theme/themes/gone" "$HOME/.config/theme/current"
  doctor
  [ "$status" -eq 1 ]
  [[ $output == *"points at a theme that does not exist"* ]]
}

@test "wm: stopped services fail with the start command" {
  install_links "themes wm"
  doctor
  [ "$status" -eq 1 ]
  [[ $output == *"yabai not running"* ]]
  [[ $output == *"fix: yabai --start-service"* ]]
  [[ $output == *"skhd not running"* ]]
}

@test "wm: yabai running but not answering points at Accessibility" {
  install_links "themes wm"
  stub pgrep 'exit 0'
  stub yabai '[ "$1" = -m ] && exit 1; exit 0'
  doctor
  [[ $output == *"not answering queries, usually missing Accessibility"* ]]
}

@test "~/.local/bin missing from PATH fails" {
  healthy_themes
  PATH="$STUBS:/usr/bin:/bin:/usr/sbin:/sbin" doctor
  [ "$status" -eq 1 ]
  [[ $output == *"~/.local/bin is not on PATH"* ]]
}

@test "login agent enabled in config but not loaded is a warning" {
  healthy_themes
  echo 'MACARCHY_UPDATE_AT_LOGIN=true' >>"$HOME/.config/macarchy/config"
  doctor
  [[ $output == *"login agent is not loaded"* ]]
  [[ $output == *"fix: macarchy-update --login on"* ]]
}

@test "--quiet prints only problems and the summary" {
  healthy_themes
  doctor --quiet
  [ "$status" -eq 0 ]
  [[ $output != *"  ok "* ]]
  [[ $output != *"Themes"* ]]
}

@test 'never writes to $HOME' {
  healthy_themes
  before="$(find "$HOME" | LC_ALL=C sort | shasum)"
  doctor
  [ "$(find "$HOME" | LC_ALL=C sort | shasum)" = "$before" ]
}
