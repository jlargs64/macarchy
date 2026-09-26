#!/usr/bin/env bats
# macarchy-update: relinking, pruning, exit status, and running from a
# Homebrew-style Cellar/opt layout.

setup() {
  load helpers
  common_setup
}

update() { run "$REPO/home/.config/macarchy/bin/macarchy-update" "$@"; }

# fake_brew <version> -- copy the working tree into a Homebrew-shaped prefix
# (Cellar/macarchy/<v>/libexec, opt/macarchy -> that version), no .git.
fake_brew() {
  PREFIX="$(cd "$BATS_TEST_TMPDIR" && pwd -P)/brew"
  local lib="$PREFIX/Cellar/macarchy/$1/libexec"
  mkdir -p "$lib" "$PREFIX/opt"
  (cd "$REPO" && git ls-files -co --exclude-standard -z | xargs -0 tar cf -) | (cd "$lib" && tar xf -)
  echo "$1" >"$lib/version.txt"
  ln -sfn "../Cellar/macarchy/$1" "$PREFIX/opt/macarchy"
}

@test "--no-pull links the chosen components and exits 0" {
  write_config themes
  update --no-pull
  [ "$status" -eq 0 ]
  [ "$(readlink "$HOME/.local/bin/theme-set")" = "$REPO/home/.local/bin/theme-set" ]
  [ ! -e "$HOME/.config/yabai/yabairc" ]
}

@test "prunes links to files deleted from the repo" {
  write_config themes
  ln -s "$REPO/home/.config/theme/bin/gone" "$HOME/.local/bin/gone"
  update --no-pull
  [ ! -L "$HOME/.local/bin/gone" ]
  [[ $output == *"1 pruned"* ]]
}

@test "skips a real file instead of overwriting it" {
  write_config themes
  echo mine >"$HOME/.local/bin/theme-set"
  update --no-pull
  [ "$(cat "$HOME/.local/bin/theme-set")" = mine ]
  [[ $output == *"skip: $HOME/.local/bin/theme-set is a real file"* ]]
}

@test "Homebrew: links go through opt/, not the versioned Cellar path" {
  fake_brew 1.0.0
  write_config themes
  run "$PREFIX/opt/macarchy/libexec/home/.config/macarchy/bin/macarchy-update"
  [ "$status" -eq 0 ]
  [[ $output == *"installed with Homebrew; relinking only"* ]]
  [ "$(readlink "$HOME/.local/bin/theme-set")" = "$PREFIX/opt/macarchy/libexec/home/.local/bin/theme-set" ]
}

@test "Homebrew: links survive an upgrade to a new version" {
  fake_brew 1.0.0
  write_config themes
  run "$PREFIX/opt/macarchy/libexec/home/.config/macarchy/bin/macarchy-update"
  fake_brew 2.0.0
  rm -rf "$PREFIX/Cellar/macarchy/1.0.0"
  [ -e "$HOME/.local/bin/theme-set" ]
  run "$PREFIX/opt/macarchy/libexec/home/.config/macarchy/bin/macarchy-update"
  [ "$status" -eq 0 ]
  [[ $output == *"0 pruned"* ]]
}

@test "Homebrew: doctor and uninstall recognise the install" {
  fake_brew 1.0.0
  write_config themes
  bin="$PREFIX/opt/macarchy/libexec/home/.config/macarchy/bin"
  run "$bin/macarchy-update"
  run "$bin/macarchy-doctor"
  [[ $output == *"v1.0.0 (Homebrew)"* ]]
  [[ $output == *"files linked into"* ]]
  [[ $output != *"not linked"* ]]
  run "$bin/macarchy-uninstall" --yes
  [ "$(find "$HOME" -type l -lname "$PREFIX/*" | wc -l | tr -d ' ')" = 0 ]
}

@test "a copy that is neither git nor Homebrew is refused" {
  mkdir -p "$BATS_TEST_TMPDIR/copy"
  (cd "$REPO" && git ls-files -z | xargs -0 tar cf -) | (cd "$BATS_TEST_TMPDIR/copy" && tar xf -)
  run "$BATS_TEST_TMPDIR/copy/home/.config/macarchy/bin/macarchy-update"
  [ "$status" -eq 1 ]
  [[ $output == *"is not a git checkout"* ]]
}

# stub_tags <tag...> -- git answers ls-remote with these tags (none: it fails,
# as when offline) and passes everything else to the real git.
stub_tags() {
  export TAGS="$BATS_TEST_TMPDIR/tags"
  : >"$TAGS"
  for t in "$@"; do printf '0000000\trefs/tags/%s\n' "$t" >>"$TAGS"; done
  # shellcheck disable=SC2016
  stub git 'for a; do [ "$a" = ls-remote ] && { [ -s "$TAGS" ] && exec cat "$TAGS"; exit 128; }; done
exec /usr/bin/git "$@"'
}

@test "--check exits 0 when the installed release is the latest tag" {
  v="$(cat "$REPO/version.txt")"
  stub_tags v0.0.1 "v$v"
  update --check
  [ "$status" -eq 0 ]
  [[ $output == *"installed: v$v"* ]]
  [[ $output == *"latest: v$v"* ]]
  grep -q "ls-remote --tags --refs origin" "$STUB_LOG"
}

@test "--check exits 10 and names the newer release, comparing numerically" {
  stub_tags v9.0.0 v10.0.0 v10.0.0-rc1
  update --check
  [ "$status" -eq 10 ]
  [[ $output == *"latest: v10.0.0"* ]]
}

@test "--check changes nothing and pulls nothing" {
  write_config themes
  stub_tags v99.0.0
  update --check
  [ "$status" -eq 10 ]
  [ ! -e "$HOME/.local/bin/theme-set" ]
  [ "$(grep -c pull "$STUB_LOG")" = 0 ]
}

@test "--check exits 1 when the releases cannot be listed" {
  stub_tags
  update --check
  [ "$status" -eq 1 ]
  [[ $output == *"could not list releases"* ]]
}

@test "Homebrew: --check asks GitHub, since the install has no remote" {
  fake_brew 1.0.0
  stub_tags v1.0.0 v1.1.0
  run "$PREFIX/opt/macarchy/libexec/home/.config/macarchy/bin/macarchy-update" --check
  [ "$status" -eq 10 ]
  [[ $output == *"installed: v1.0.0"* ]]
  [[ $output == *"latest: v1.1.0"* ]]
  grep -q "ls-remote --tags --refs https://github.com/jlargs64/macarchy.git" "$STUB_LOG"
}
