#!/usr/bin/env bats
# The theme contract (README "The theme contract"), checked for every
# shipped theme so a bad port or hand edit fails CI instead of theme-set.

setup() {
  load helpers
  THEMES="$REPO/home/.config/theme/themes"
}

each_theme() { find "$THEMES" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort; }

@test "at least 22 themes ship" {
  [ "$(each_theme | wc -l)" -ge 22 ]
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
