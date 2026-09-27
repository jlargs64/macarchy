#!/usr/bin/env bats
# theme-new: a user theme from one colors.sh, into a scratch themes dir.

setup() {
  load helpers
  common_setup
  OUT="$BATS_TEST_TMPDIR/themes"
  mkdir -p "$OUT"
  cp -R "$REPO/home/.config/theme/themes/hollow" "$OUT/hollow"
}

new() { run "$REPO/home/.config/theme/bin/theme-new" "$@" --out "$OUT"; }

get() { bash -c ". '$OUT/mine/colors.sh'; printf %s \"\$$1\""; }

@test "creates every contract file plus the Neovim colorscheme" {
  new mine --from hollow
  [ "$status" -eq 0 ]
  for f in colors.sh ghostty zellij.kdl neovim.lua borders nvim-mine/colors/mine.lua; do
    [ -s "$OUT/mine/$f" ] || {
      echo "missing $f"
      return 1
    }
  done
}

@test "renames the palette and keeps its colours" {
  new mine --from hollow
  [ "$(get THEME_NAME)" = mine ]
  [ "$(get NVIM_COLORSCHEME)" = mine ]
  [ "$(get BG)" = 16110f ]
  [ "$(get ACCENT)" = e8772e ]
}

@test "defaults --from to the active theme" {
  mkdir -p "$HOME/.config/theme"
  ln -s "$OUT/hollow" "$HOME/.config/theme/current"
  new mine
  [ "$status" -eq 0 ]
  [ "$(get BG)" = 16110f ]
  [[ $output == *"colors.sh"* ]]
}

@test "ghostty uses the darken-for-dim rule" {
  new mine --from hollow
  # hollow's hand-written ghostty came from the same rule, so slots match.
  for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    want="$(grep "^palette = $i=" "$OUT/hollow/ghostty")"
    got="$(grep "^palette = $i=" "$OUT/mine/ghostty")"
    [ "$want" = "$got" ] || {
      echo "slot $i: want '$want' got '$got'"
      return 1
    }
  done
}

@test "the result passes theme-render" {
  new mine --from hollow
  run "$REPO/home/.config/theme/bin/theme-render" kitty "$OUT/mine"
  [ "$status" -eq 0 ]
  [[ $output == *"background #16110f"* ]]
}

@test "--regen picks up a colors.sh edit" {
  new mine --from hollow
  sed -i '' 's/^export BG=.*/export BG=101820/' "$OUT/mine/colors.sh"
  new --regen mine
  [ "$status" -eq 0 ]
  grep -q '^background = 101820$' "$OUT/mine/ghostty"
  grep -q 'base00 = "#101820"' "$OUT/mine/nvim-mine/colors/mine.lua"
  grep -q 'bg "#101820"' "$OUT/mine/zellij.kdl"
}

@test "--regen keeps a file without the theme-new header" {
  new mine --from hollow
  echo "# mine, by hand" >"$OUT/mine/ghostty"
  new --regen mine
  [ "$status" -eq 0 ]
  [ "$(cat "$OUT/mine/ghostty")" = "# mine, by hand" ]
  [[ $output == *"kept    ghostty"* ]]
}

@test "a light background sets background=light and warns" {
  new mine --from hollow
  sed -i '' 's/^export BG=.*/export BG=f5f0e6/' "$OUT/mine/colors.sh"
  new --regen mine
  grep -q 'vim.o.background = "light"' "$OUT/mine/nvim-mine/colors/mine.lua"
  [[ $output == *light* ]]
}

@test "refuses to overwrite an existing theme" {
  new mine --from hollow
  new mine --from hollow
  [ "$status" -ne 0 ]
  [[ $output == *"already exists"* ]]
}

@test "rejects a bad name, a path --from and bad hex" {
  new "my theme" --from hollow
  [ "$status" -ne 0 ]
  new mine --from ../hollow
  [ "$status" -ne 0 ]
  new mine --from hollow
  sed -i '' 's/^export RED=.*/export RED=#b8412f/' "$OUT/mine/colors.sh"
  new --regen mine
  [ "$status" -ne 0 ]
  [[ $output == *"RED=#b8412f"* ]]
}
