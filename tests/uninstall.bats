#!/usr/bin/env bats
# macarchy-uninstall against a fake $HOME: removes only what is ours, puts
# back what install.sh moved aside, and asks before doing anything.

setup() {
  load helpers
  common_setup
}

uninstall() { run "$REPO/home/.config/macarchy/bin/macarchy-uninstall" "$@"; }
our_links() { find "$HOME" -type l -lname "$REPO/home/*" | wc -l | tr -d ' '; }

@test "removes every link into the repo" {
  install_links "themes wm bar"
  [ "$(our_links)" -gt 50 ]
  uninstall --yes
  [ "$status" -eq 0 ]
  [ "$(our_links)" = 0 ]
}

@test "restores files install.sh moved aside" {
  install_links themes
  rm "$HOME/.local/bin/theme-set"
  echo "my own theme-set" >"$HOME/.local/bin/theme-set.pre-macarchy"
  ln -s "$REPO/home/.config/theme/bin/theme-set" "$HOME/.local/bin/theme-set"
  uninstall --yes
  [ ! -L "$HOME/.local/bin/theme-set" ]
  [ "$(cat "$HOME/.local/bin/theme-set")" = "my own theme-set" ]
}

@test "leaves your own files and foreign links alone" {
  install_links themes
  echo keep >"$HOME/.config/theme/mine.txt"
  ln -s /etc/hosts "$HOME/.local/bin/hosts"
  mkdir -p "$HOME/.config/nvim" && echo cfg >"$HOME/.config/nvim/init.lua"
  uninstall --yes
  [ "$(cat "$HOME/.config/theme/mine.txt")" = keep ]
  [ -L "$HOME/.local/bin/hosts" ]
  [ -f "$HOME/.config/nvim/init.lua" ]
}

@test "removes the theme links it made in Zellij and Neovim configs" {
  install_links themes
  mkdir -p "$HOME/.config/zellij/themes" "$HOME/.config/nvim/lua/plugins"
  ln -s "$HOME/.config/theme/themes/nord" "$HOME/.config/theme/current"
  ln -s "$HOME/.config/theme/current/zellij.kdl" "$HOME/.config/zellij/themes/current.kdl"
  ln -s "$HOME/.config/theme/current/neovim.lua" "$HOME/.config/nvim/lua/plugins/theme.lua"
  uninstall --yes
  [ ! -L "$HOME/.config/theme/current" ]
  [ ! -L "$HOME/.config/zellij/themes/current.kdl" ]
  [ ! -L "$HOME/.config/nvim/lua/plugins/theme.lua" ]
}

@test "keeps the config file and removes directories left empty" {
  install_links "themes wm"
  uninstall --yes
  [ -f "$HOME/.config/macarchy/config" ]
  [ ! -d "$HOME/.config/yabai" ]
  [ ! -d "$HOME/.config/skhd" ]
  [ -d "$HOME/.config" ]
  [ -d "$HOME/.local/bin" ]
}

@test "removes the login agent" {
  install_links themes
  touch "$HOME/Library/LaunchAgents/macarchy.update.plist"
  uninstall --yes
  [ ! -e "$HOME/Library/LaunchAgents/macarchy.update.plist" ]
  grep -q "^launchctl bootout gui/$(id -u)/macarchy.update" "$STUB_LOG"
}

@test "--purge deletes config and generated files" {
  install_links themes
  mkdir -p "$HOME/.local/share/macarchy/venv" "$HOME/.config/theme/generated"
  uninstall --yes --purge
  [ ! -e "$HOME/.config/macarchy" ]
  [ ! -e "$HOME/.config/theme" ]
  [ ! -e "$HOME/.local/share/macarchy" ]
}

@test "--services stops services, and nothing is stopped without it" {
  install_links "themes wm"
  uninstall --yes
  run ! grep -q -- "--stop-service" "$STUB_LOG"
  uninstall --yes --services
  grep -q "^yabai --stop-service" "$STUB_LOG"
  grep -q "^skhd --stop-service" "$STUB_LOG"
}

@test "--defaults deletes exactly the keys install.sh wrote" {
  install_links "themes wm"
  uninstall --yes --defaults
  [ "$(grep -c '^defaults delete' "$STUB_LOG")" = 4 ]
  grep -q "^defaults delete com.apple.dock mru-spaces" "$STUB_LOG"
}

@test "--dry-run changes nothing" {
  install_links "themes wm"
  before="$(find "$HOME" | LC_ALL=C sort | shasum)"
  uninstall --dry-run --all
  [ "$status" -eq 0 ]
  [[ $output == *"dry run: nothing above actually ran"* ]]
  [ "$(find "$HOME" | LC_ALL=C sort | shasum)" = "$before" ]
  run ! grep -q "stop-service\|bootout\|defaults delete" "$STUB_LOG"
}

@test "refuses to run without a terminal or --yes" {
  install_links themes
  n="$(our_links)"
  uninstall </dev/null
  [ "$status" -eq 2 ]
  [[ $output == *"pass --yes"* ]]
  [ "$(our_links)" = "$n" ]
}
