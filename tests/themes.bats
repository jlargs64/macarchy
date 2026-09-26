#!/usr/bin/env bats
# The theme contract (README "The theme contract"), checked for every
# shipped theme so a bad port or hand edit fails CI instead of theme-set.

setup() {
  load helpers
  THEMES="$REPO/home/.config/theme/themes"
}

each_theme() { find "$THEMES" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort; }

@test "at least 23 themes ship" {
  [ "$(each_theme | wc -l)" -ge 23 ]
}

@test "every theme has the five required files" {
  bad=""
  while IFS= read -r d; do
    for f in colors.sh ghostty zellij.kdl neovim.lua borders; do
      [ -f "$d/$f" ] || bad="$bad ${d##*/}/$f"
    done
  done < <(each_theme)
  [ -z "$bad" ] || {
    echo "missing:$bad"
    return 1
  }
}

# palette <theme dir> -- KEY=VALUE for every contract key, one bash per theme
palette() {
  bash -c '. "$1/colors.sh"; for k in THEME_NAME NVIM_COLORSCHEME BG FG ACCENT ACCENT2 MUTED RED GREEN YELLOW BLUE MAGENTA CYAN; do eval "printf \"%s=%s\\n\" $k \"\${$k:-}\""; done' _ "$1"
}

@test "colors.sh exports every palette key as bare 6-digit hex" {
  bad=""
  while IFS= read -r d; do
    while IFS='=' read -r k v; do
      case "$k" in THEME_NAME | NVIM_COLORSCHEME) continue ;; esac
      [[ $v =~ ^[0-9a-fA-F]{6}$ ]] || bad="$bad ${d##*/}:$k=$v"
    done < <(palette "$d")
  done < <(each_theme)
  [ -z "$bad" ] || {
    echo "bad:$bad"
    return 1
  }
}

@test "THEME_NAME matches the directory and NVIM_COLORSCHEME is set" {
  bad=""
  while IFS= read -r d; do
    p="$(palette "$d")"
    grep -qx "THEME_NAME=${d##*/}" <<<"$p" || bad="$bad ${d##*/}:THEME_NAME"
    grep -q "^NVIM_COLORSCHEME=." <<<"$p" || bad="$bad ${d##*/}:NVIM_COLORSCHEME"
  done < <(each_theme)
  [ -z "$bad" ] || {
    echo "bad:$bad"
    return 1
  }
}

@test "colors.sh sources cleanly with set -eu and runs no commands" {
  while IFS= read -r d; do
    run bash -euc ". '$d/colors.sh'"
    [ "$status" -eq 0 ] || {
      echo "${d##*/}: $output"
      return 1
    }
    [ -z "$output" ]
  done < <(each_theme)
}

@test "vscode.json, where present, is valid JSON with name and extension" {
  while IFS= read -r f; do
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["name"] and d["extension"]' "$f" || {
      echo "bad: $f"
      return 1
    }
  done < <(find "$THEMES" -name vscode.json)
}

@test "the default theme exists" {
  # shellcheck disable=SC1091
  HOME="$BATS_TEST_TMPDIR" . "$REPO/home/.config/macarchy/lib.sh"
  [ -d "$THEMES/$MACARCHY_DEFAULT_THEME" ]
}

# theme_home -- a fake ~/.config/theme with the repo's lib and bin, a theme
# "nord" selected, and $T/$D/$FIXED pointing at it. Every command that could
# touch the machine is stubbed by common_setup; the fake HOME has no
# WallpaperAgent store, so theme_wallpaper_push does not wait.
theme_home() {
  common_setup
  T="$HOME/.config/theme"
  D="$T/themes/nord"
  FIXED="$T/wallpaper-current.jpg"
  mkdir -p "$D"
  ln -s "$REPO/home/.config/theme/lib" "$T/lib"
  ln -s "$REPO/home/.config/theme/bin" "$T/bin"
  ln -s "$D" "$T/current"
}

# with_backgrounds -- two backgrounds and the gradient for the nord theme
with_backgrounds() {
  mkdir -p "$D/backgrounds"
  echo a >"$D/backgrounds/01-a.jpg"
  echo b >"$D/backgrounds/02-b.jpg"
  echo gradient >"$D/wallpaper.jpg"
}

# stub yabai for the full enrol walk: one Space, focused
stub_one_space() { stub yabai 'case "$*" in *--spaces*) echo "[{\"index\":1,\"has-focus\":true}]";; esac'; }

@test "theme-wallpaper-enroll --here sets only the visible desktops, without switching" {
  theme_home
  touch "$FIXED"
  run "$T/bin/theme-wallpaper-enroll" --here
  [ "$status" -eq 0 ]
  grep -q '^osascript' "$STUB_LOG"
  run ! grep -q 'key code' "$STUB_LOG"
  run ! grep -q '^killall' "$STUB_LOG"
}

@test "theme-wallpaper-enroll --here is a no-op before the first enrolment" {
  theme_home
  run "$T/bin/theme-wallpaper-enroll" --here
  [ "$status" -eq 0 ]
  run ! grep -q '^osascript' "$STUB_LOG"
}

@test "theme-wallpaper-enroll seeds the shared file from the background theme-bg chose" {
  theme_home
  with_backgrounds
  echo "$D/backgrounds/02-b.jpg" >"$D/.bg"
  stub_one_space
  run "$T/bin/theme-wallpaper-enroll"
  [ "$status" -eq 0 ]
  [ "$(cat "$FIXED")" = b ]
  grep -q 'key code' "$STUB_LOG"
}

@test "theme-wallpaper-enroll falls back to the first background, then the gradient" {
  theme_home
  with_backgrounds
  stub_one_space
  run "$T/bin/theme-wallpaper-enroll"
  [ "$status" -eq 0 ]
  [ "$(cat "$FIXED")" = a ]
  rm -r "$D/backgrounds"
  run "$T/bin/theme-wallpaper-enroll"
  [ "$status" -eq 0 ]
  [ "$(cat "$FIXED")" = gradient ]
}

@test "theme-wallpaper-enroll refuses a theme with no wallpaper at all" {
  theme_home
  stub_one_space
  run "$T/bin/theme-wallpaper-enroll"
  [ "$status" -eq 1 ]
  [[ $output == *"no wallpaper"* ]]
}

# The repaint order: WallpaperAgent must get the set-picture request and
# write it down before it is restarted, so osascript always precedes killall.
@test "theme-bg apply remembers the choice and sets the picture before restarting WallpaperAgent" {
  theme_home
  with_backgrounds
  run "$T/bin/theme-bg" 2
  [ "$status" -eq 0 ]
  [ "$output" = "background: 02-b.jpg" ]
  [ "$(cat "$D/.bg")" = "$(cd "$D" && pwd -P)/backgrounds/02-b.jpg" ] # theme-bg resolves the theme dir
  [ "$(cat "$FIXED")" = b ]
  [ "$(grep -c '' "$STUB_LOG")" -eq 2 ]
  [[ $(sed -n 1p "$STUB_LOG") == "osascript -e "*"set picture to \"$FIXED\""* ]]
  [ "$(sed -n 2p "$STUB_LOG")" = "killall WallpaperAgent" ]
  : >"$STUB_LOG"
  run "$T/bin/theme-bg" apply
  [ "$output" = "background: 02-b.jpg" ]
  [ "$(cat "$FIXED")" = b ]
}

@test "the wallpaper hook applies the remembered background in the same order" {
  theme_home
  with_backgrounds
  echo "$D/backgrounds/02-b.jpg" >"$D/.bg"
  THEME_ROOT="$T" THEME_DIR="$D" run "$REPO/home/.config/theme/hooks/wallpaper"
  [ "$status" -eq 0 ]
  [ "$(cat "$FIXED")" = b ]
  [[ $(sed -n 1p "$STUB_LOG") == "osascript -e "*"set picture to \"$FIXED\""* ]]
  [ "$(sed -n 2p "$STUB_LOG")" = "killall WallpaperAgent" ]
}

@test "the wallpaper hook uses the gradient when the theme has no backgrounds" {
  theme_home
  echo gradient >"$D/wallpaper.jpg"
  THEME_ROOT="$T" THEME_DIR="$D" run "$REPO/home/.config/theme/hooks/wallpaper"
  [ "$status" -eq 0 ]
  [ "$(cat "$FIXED")" = gradient ]
  grep -q '^osascript' "$STUB_LOG"
  grep -q '^killall WallpaperAgent' "$STUB_LOG"
}
