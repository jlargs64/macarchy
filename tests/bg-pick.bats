#!/usr/bin/env bats
# theme-bg-pick and theme-img: the picker rows follow theme-bg's numbering
# and the previews degrade to text without chafa or viu.

setup() {
  load helpers
  common_setup
  T="$HOME/.config/theme"
  mkdir -p "$T/bin" "$T/themes/nord/backgrounds"
  ln -s "$REPO/home/.config/theme/lib" "$T/lib" # theme-bg sources lib/wallpaper.sh
  for b in theme-bg theme-bg-pick theme-img theme-pick theme-list; do
    ln -s "$REPO/home/.config/theme/bin/$b" "$T/bin/$b"
  done
  cp "$REPO/home/.config/theme/themes/nord/colors.sh" "$T/themes/nord/"
  printf 'x' >"$T/themes/nord/backgrounds/01-fjord.jpg"
  printf 'x' >"$T/themes/nord/backgrounds/02-aurora.jpg"
  ln -s "$T/themes/nord" "$T/current"
  # theme-bg resolves symlinks (pwd -P) and the bats tmp lives under /var ->
  # /private/var, so use the resolved path like theme-bg itself writes it
  D="$(cd "$T/themes/nord" && pwd -P)"
  echo "$D/backgrounds/02-aurora.jpg" >"$T/themes/nord/.bg"
  unset ZELLIJ TMUX # theme-img falls back to blocks inside a multiplexer
}

@test "rows list the theme's backgrounds, numbered like theme-bg, current marked" {
  run "$T/bin/theme-bg-pick" --rows
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [[ ${lines[0]} == "   1  01-fjord"$'\t'"$D/backgrounds/01-fjord.jpg"$'\t'"1" ]]
  [[ ${lines[1]} == "*  2  02-aurora (current)"$'\t'"$D/backgrounds/02-aurora.jpg"$'\t'"2" ]]
}

@test "theme-img falls back to text when neither chafa nor viu is installed" {
  run "$T/bin/theme-img" "$T/themes/nord/backgrounds/01-fjord.jpg" 20 10
  [ "$status" -eq 0 ]
  [[ $output == *"01-fjord.jpg"* ]]
  [[ $output == *"brew install chafa"* ]]
}

@test "theme-img draws with chafa when present, in the terminal's format" {
  stub chafa
  run env MACARCHY_TERMINAL=ghostty "$T/bin/theme-img" "$T/themes/nord/backgrounds/01-fjord.jpg" 20 10
  [ "$status" -eq 0 ]
  grep -q '^chafa -f kitty --size 20x10 --animate off ' "$STUB_LOG"
  run env MACARCHY_TERMINAL=alacritty "$T/bin/theme-img" "$T/themes/nord/backgrounds/01-fjord.jpg"
  grep -q '^chafa -f symbols ' "$STUB_LOG"
}

@test "theme-pick --preview shows the theme's remembered background first" {
  stub chafa
  THEMES_DIR="$T/themes" run "$T/bin/theme-pick" --preview nord
  [ "$status" -eq 0 ]
  grep -q '02-aurora.jpg$' "$STUB_LOG"
  [[ $output == *"nord  [dark]"* ]]
}

@test "picker refuses to run without a theme" {
  rm "$T/current"
  run "$T/bin/theme-bg-pick" --rows
  [ "$status" -eq 1 ]
  [[ $output == *"no theme selected"* ]]
}
