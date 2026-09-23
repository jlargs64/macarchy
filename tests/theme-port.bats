#!/usr/bin/env bats
# theme-port against a local Omarchy-shaped fixture (--src), so no network.

setup() {
  load helpers
  common_setup
  OUT="$BATS_TEST_TMPDIR/out"
  mkdir -p "$OUT"
}

port() { run "$REPO/home/.config/theme/bin/theme-port" "$@" --src "$BATS_TEST_DIRNAME/fixtures/omarchy" --out "$OUT"; }

get() { bash -c ". '$OUT/test-dark/colors.sh'; printf %s \"\$$1\""; }

@test "ports a dark theme into the five contract files" {
  port test-dark
  [ "$status" -eq 0 ]
  for f in colors.sh ghostty zellij.kdl neovim.lua borders; do
    [ -s "$OUT/test-dark/$f" ] || {
      echo "missing $f"
      return 1
    }
  done
}

@test "maps Omarchy keys onto the colors.sh contract" {
  port test-dark
  [ "$(get THEME_NAME)" = test-dark ]
  [ "$(get BG)" = 1a1b26 ]
  [ "$(get FG)" = a9b1d6 ]
  [ "$(get ACCENT)" = 7aa2f7 ]
  [ "$(get MUTED)" = 414868 ]
  [ "$(get RED)" = f7768e ]
  [ "$(get CYAN)" = 449dab ]
}

@test "ACCENT2 is the bright variant farthest from ACCENT" {
  port test-dark
  # accent 7aa2f7 == blue. Squared RGB distance to cyan 449dab is 8717,
  # to magenta ad8ee6 3290, so cyan is farthest and bright_cyan wins.
  [ "$(get ACCENT2)" = 0db9d7 ]
}

@test "reads the colorscheme name out of neovim.lua" {
  port test-dark
  [ "$(get NVIM_COLORSCHEME)" = tokyonight-night ]
}

@test "refuses a light theme without --allow-light" {
  port test-light
  [ "$status" -ne 0 ]
  [[ $output == *light* ]]
  [ ! -e "$OUT/test-light/colors.sh" ]
}

@test "ports a light theme with --allow-light" {
  port test-light --allow-light
  [ "$status" -eq 0 ]
  [ -s "$OUT/test-light/colors.sh" ]
}

@test "an unknown theme fails cleanly" {
  port does-not-exist
  [ "$status" -ne 0 ]
  [ ! -d "$OUT/does-not-exist" ]
}
