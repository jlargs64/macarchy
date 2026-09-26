#!/usr/bin/env bats
# install.sh in --list and --dry-run modes: component selection without
# touching Homebrew, defaults or $HOME.

setup() {
  load helpers
  common_setup
}

install() { run "$REPO/install.sh" "$@"; }

@test "--list names every component" {
  install --list
  [ "$status" -eq 0 ]
  for c in themes wm bar borders keys agent; do [[ $output == *"  $c "* ]]; done
}

@test "--dry-run --only themes links only theme files and changes nothing" {
  install --dry-run --only themes
  [ "$status" -eq 0 ]
  [[ $output == *"components: themes"* ]]
  [[ $output == *"+ ln -sfn $REPO/home/.config/theme/bin/theme-set $HOME/.config/theme/bin/theme-set"* ]]
  [[ $output != *"yabai/yabairc"* ]]
  [[ $output != *"defaults write"* ]]
  [ "$(find "$HOME" -mindepth 1 -not -type d | wc -l | tr -d ' ')" = 0 ]
  run ! grep -q "^brew install" "$STUB_LOG"
}

@test "--only bar pulls in themes, which it needs" {
  install --dry-run --only bar
  [[ $output == *"components: themes bar"* ]]
}

@test "--only bar installs blueutil for the bluetooth item" {
  install --dry-run --only bar
  [[ $output == *blueutil* ]]
}

@test "--only bar creates the items.d drop-in directory, --only themes does not" {
  install --dry-run --only bar
  [[ $output == *"+ mkdir -p $HOME/.config/sketchybar/items.d"* ]]
  install --dry-run --only themes
  [[ $output != *"items.d"* ]]
}

@test "--skip drops a component from the saved choice" {
  write_config "themes wm bar"
  install --dry-run --skip wm
  [[ $output == *"components: themes bar"* ]]
}

@test "an unknown flag exits 2" {
  install --bogus
  [ "$status" -eq 2 ]
}
