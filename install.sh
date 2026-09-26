#!/usr/bin/env bash
# macarchy install.sh — idempotent installer for the macarchy desktop layer.
#
# Usage:
#   ./install.sh                     install/update (first run in a terminal
#                                    asks which components you want)
#   ./install.sh --only themes,wm    install just these components
#   ./install.sh --skip agent        everything you picked, minus these
#   ./install.sh --all               every component, no questions
#   ./install.sh --remove bar        unlink a component's files from $HOME
#   ./install.sh --list              show the components and exit
#   ./install.sh --dry-run           print what would happen, change nothing
#
# Components: themes wm bar borders keys agent (see
# home/.config/macarchy/components.sh). Your choice is saved as
# MACARCHY_COMPONENTS in ~/.config/macarchy/config and reused on re-runs.
#
# Safe to re-run: every step either checks first or overwrites the same
# managed path (symlinks via ln -sfn, brew install of already-installed
# formulae, etc).
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || {
  echo "macarchy: macOS only" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$SCRIPT_DIR"

DRY_RUN=0
ONLY="" SKIP="" ALL=0 REMOVE="" LIST=0
while [ $# -gt 0 ]; do
  arg="$1"
  shift
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --only)
      ONLY="${1:?--only needs a list}"
      shift
      ;;
    --only=*) ONLY="${arg#*=}" ;;
    --skip)
      SKIP="${1:?--skip needs a list}"
      shift
      ;;
    --skip=*) SKIP="${arg#*=}" ;;
    --remove)
      REMOVE="${1:?--remove needs a list}"
      shift
      ;;
    --remove=*) REMOVE="${arg#*=}" ;;
    --all) ALL=1 ;;
    --list) LIST=1 ;;
    -h | --help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "macarchy: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

# Print, and (unless --dry-run) run, a single simple command. Anything with a
# side effect that is not a plain argv command (curl | bash, command
# substitution, heredocs) is gated on $DRY_RUN by hand instead -- run() alone
# cannot stop those from firing while their arguments are being built.
run() {
  echo "+ $*"
  if [ "$DRY_RUN" != 1 ]; then
    "$@"
  fi
}

# Load config defaults (MACARCHY_DEFAULT_THEME etc). This also honors an
# already-installed ~/.config/macarchy/config, so re-running install.sh after
# editing it picks up the new values.
# shellcheck disable=SC1091
. "$REPO/home/.config/macarchy/lib.sh"
# shellcheck disable=SC1091
. "$REPO/home/.config/macarchy/components.sh"
REPO="$(macarchy_stable_repo "$REPO")"

if [ "$LIST" = 1 ]; then
  for c in $MACARCHY_ALL_COMPONENTS; do printf '  %-8s %s\n' "$c" "$(macarchy_component_desc "$c")"; done
  exit 0
fi

# -----------------------------------------------------------------------
# 0. Which components
#
# --only / --all win, then a saved MACARCHY_COMPONENTS, then (first run in a
# terminal, no config yet) a y/n question per component, then everything.
# -----------------------------------------------------------------------
pick_components() { # sets SELECTED
  local c ans
  SELECTED=""
  echo "Which parts of macarchy do you want? Each works on its own."
  echo "(Enter keeps the default. Change it later with --only, --skip or --remove.)"
  echo
  for c in $MACARCHY_ALL_COMPONENTS; do
    printf '  %-8s %s\n' "$c" "$(macarchy_component_desc "$c")"
    read -r -p "           install $c? [Y/n] " ans || ans=""
    case "$ans" in [nN]*) ;; *) SELECTED="$SELECTED $c" ;; esac
  done
  echo
}

commas() { echo "$1" | tr ',' ' '; }

if [ -n "$REMOVE" ]; then
  SELECTED="${MACARCHY_COMPONENTS:-$MACARCHY_ALL_COMPONENTS}"
elif [ -n "$ONLY" ]; then
  SELECTED="$(commas "$ONLY")"
elif [ "$ALL" = 1 ]; then
  SELECTED="$MACARCHY_ALL_COMPONENTS"
elif [ -n "${MACARCHY_COMPONENTS:-}" ]; then
  SELECTED="$MACARCHY_COMPONENTS"
elif [ -t 0 ] && [ -t 1 ] && [ ! -f "$HOME/.config/macarchy/config" ]; then
  # first install: ask. An existing install without the setting keeps all.
  pick_components
else
  SELECTED="$MACARCHY_ALL_COMPONENTS"
fi
for c in $(commas "$SKIP") $(commas "$REMOVE"); do
  SELECTED="$(echo " $SELECTED " | sed "s/ $c / /g")"
done
MACARCHY_COMPONENTS="$(macarchy_resolve_components $SELECTED)"
export MACARCHY_COMPONENTS
[ -n "$MACARCHY_COMPONENTS" ] || {
  echo "macarchy: no components selected; nothing to do" >&2
  exit 1
}

DRY_NOTE=""
[ "$DRY_RUN" = 1 ] && DRY_NOTE=" (dry run -- nothing above actually ran)"
echo "macarchy install${DRY_NOTE:+ (dry run)}"
[ "$DRY_RUN" = 1 ] && echo "(dry run: no changes will be made)"
echo

# -----------------------------------------------------------------------
# 1. Homebrew bootstrap + packages
#
# This is the *workflow subset* only: the desktop stack (yabai, skhd,
# sketchybar, borders) and what they need (jq for the space plugin,
# imagemagick for wallpaper generation, fzf for macarchy-keys, Hack Nerd
# Font for bar glyphs), plus Handy -- the offline speech-to-text engine
# `ws --voice` shells out to (see MACARCHY_HANDY in
# home/.config/macarchy/config.example). It deliberately does not install
# shell/editor tooling (zellij, neovim, starship, etc) -- that is a
# different concern from this repo.
# -----------------------------------------------------------------------
BREW_FORMULAE=()
BREW_CASKS=()
macarchy_has themes && BREW_FORMULAE+=(imagemagick fzf chafa)
macarchy_has wm && BREW_FORMULAE+=(jq koekeishiya/formulae/yabai koekeishiya/formulae/skhd)
macarchy_has bar && BREW_FORMULAE+=(jq FelixKratz/formulae/sketchybar) && BREW_CASKS+=(font-hack-nerd-font)
macarchy_has borders && BREW_FORMULAE+=(FelixKratz/formulae/borders)
macarchy_has keys && BREW_FORMULAE+=(fzf)
macarchy_has agent && BREW_FORMULAE+=(uv) && BREW_CASKS+=(handy)

# Pinned release + sha256 for the per-app glyph font used by the SketchyBar
# Space indicators. A moved tag or tampered asset is refused, not installed.
# To bump: update both SKETCHYBAR_APP_FONT_URL and SKETCHYBAR_APP_FONT_SHA256.
SKETCHYBAR_APP_FONT_URL="https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf"
SKETCHYBAR_APP_FONT_SHA256="e49ee3281aca67634c2e7c0261d898226149664e9842b7fe61af8c4726d1f1de"

step_brew() {
  echo "==> Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    if [ "$DRY_RUN" = 1 ]; then
      echo "+ install Homebrew (curl -fsSL .../install.sh | bash)"
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  fi

  run brew update
  [ ${#BREW_FORMULAE[@]} -eq 0 ] || run brew install "${BREW_FORMULAE[@]}"
  # --adopt: take over an app that is already in /Applications (e.g. Handy installed by hand) instead of failing
  [ ${#BREW_CASKS[@]} -eq 0 ] || run brew install --cask --adopt "${BREW_CASKS[@]}"

  macarchy_has bar || return 0
  echo "==> sketchybar-app-font"
  local dest="$HOME/Library/Fonts/sketchybar-app-font.ttf"
  if [ -f "$dest" ]; then
    echo "  already installed: $dest"
  elif [ "$DRY_RUN" = 1 ]; then
    echo "+ download $SKETCHYBAR_APP_FONT_URL -> $dest (sha256 verified)"
  else
    local tmp
    tmp="$(mktemp -t sketchybar-app-font)"
    if curl -fsSL -o "$tmp" "$SKETCHYBAR_APP_FONT_URL" &&
      echo "$SKETCHYBAR_APP_FONT_SHA256  $tmp" | shasum -a 256 -c --status; then
      mv "$tmp" "$dest"
      echo "  installed: $dest"
    else
      rm -f "$tmp"
      echo "  (download failed or checksum mismatch; bar will render app icons as blanks)" >&2
    fi
  fi
}

# -----------------------------------------------------------------------
# 2. macOS defaults
#
# Per-user `defaults` keys that make Space switching feel responsive. No
# sudo, nothing system-wide, each one reversible with `defaults delete`.
# -----------------------------------------------------------------------
step_defaults() {
  macarchy_has wm || return 0
  echo "==> macOS defaults"
  run defaults write com.apple.dock expose-animation-duration -float 0.1
  run defaults write com.apple.dock workspaces-edge-delay -float 0.05
  run defaults write com.apple.dock mru-spaces -bool false
  run defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
  run killall Dock
}

# -----------------------------------------------------------------------
# 3. Link home/ into $HOME
# -----------------------------------------------------------------------
step_link() {
  echo "==> Linking files into \$HOME ($MACARCHY_COMPONENTS)"
  # One symlink per file, never a whole directory, so an unrelated
  # ~/.config/<app> is never replaced. A real file already at a target is
  # moved aside to <file>.pre-macarchy first, never overwritten.
  local repo_real rel src target dir_real n=0
  repo_real="$(cd "$REPO" && pwd -P)"
  while IFS= read -r rel; do
    rel="${rel#home/}"
    macarchy_has "$(macarchy_component_of "$rel")" || continue
    src="$REPO/home/$rel"
    target="$HOME/$rel"
    [ "$(readlink "$target" 2>/dev/null)" = "$src" ] && continue
    # A directory stow folded into one link already resolves into the repo;
    # linking through it would overwrite the repo file with a link to itself.
    dir_real="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)" || dir_real=""
    case "$dir_real/" in "$repo_real"/*) continue ;; esac
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      run mv "$target" "$target.pre-macarchy"
    fi
    if [ "$DRY_RUN" = 1 ]; then
      echo "+ ln -sfn $src $target"
    else
      mkdir -p "$(dirname "$target")"
      ln -sfn "$src" "$target"
    fi
    n=$((n + 1))
  done < <(repo_files)
  echo "  $n new links"
}

repo_files() { macarchy_repo_files "$REPO"; }

# --remove: delete the links a component put in $HOME. Only links that point
# into this repo are touched; brew packages and your own files stay.
step_unlink() {
  local c rel target
  for c in $(commas "$REMOVE"); do
    echo "==> Removing $c"
    while IFS= read -r rel; do
      rel="${rel#home/}"
      [ "$(macarchy_component_of "$rel")" = "$c" ] || continue
      target="$HOME/$rel"
      case "$(readlink "$target" 2>/dev/null)" in
        "$REPO"/home/*)
          run rm "$target"
          if [ -e "$target.pre-macarchy" ]; then run mv "$target.pre-macarchy" "$target"; fi
          ;;
      esac
    done < <(repo_files)
  done
}

# -----------------------------------------------------------------------
# 4. Seed the active theme
# -----------------------------------------------------------------------
step_seed_current() {
  macarchy_has themes || return 0
  echo "==> Seeding active theme (\$MACARCHY_DEFAULT_THEME=$MACARCHY_DEFAULT_THEME)"
  local current="$HOME/.config/theme/current"
  local target="$HOME/.config/theme/themes/$MACARCHY_DEFAULT_THEME"
  if [ -e "$current" ]; then
    echo "  $current already set, leaving it alone"
    return
  fi
  if [ "$DRY_RUN" = 1 ]; then
    echo "+ ln -sfn $target $current"
    return
  fi
  if [ -d "$target" ]; then
    ln -sfn "$target" "$current"
    echo "  theme: seeded current -> $MACARCHY_DEFAULT_THEME"
  else
    echo "  warning: default theme '$MACARCHY_DEFAULT_THEME' not found under ~/.config/theme/themes" >&2
  fi
}

# -----------------------------------------------------------------------
# 5-7. Theme assets: fallback wallpapers, real backgrounds, Raycast sync
# (what chezmoi's run_onchange used to do automatically; also available any
# time afterward as `theme-maintain`)
# -----------------------------------------------------------------------
step_theme_assets() {
  macarchy_has themes || return 0
  echo "==> Generating fallback wallpapers"
  for d in "$HOME"/.config/theme/themes/*/; do
    [ -f "$d/colors.sh" ] || continue
    if [ "$DRY_RUN" = 1 ]; then
      echo "+ theme-wallpaper $d"
    else
      "$HOME/.config/theme/bin/theme-wallpaper" "$d" || echo "  wallpaper generation failed for $d" >&2
    fi
  done

  echo "==> Fetching real backgrounds"
  run "$HOME/.config/theme/bin/theme-bg-fetch"

  echo "==> Syncing Raycast dropdown"
  run "$HOME/.config/theme/bin/theme-raycast-sync"
}

# -----------------------------------------------------------------------
# 8. Config file
# -----------------------------------------------------------------------
step_config() {
  echo "==> Config file"
  local dst="$HOME/.config/macarchy/config"
  if [ -f "$dst" ]; then
    echo "  $dst already exists, leaving the rest of it alone"
  else
    run cp "$REPO/home/.config/macarchy/config.example" "$dst"
  fi
  save_components "$dst"
}

# Record the component choice so re-runs, --remove and macarchy-update agree.
# Rewrites only the MACARCHY_COMPONENTS line; the file is written through so a
# config symlinked from dotfiles stays a symlink.
save_components() {
  local f="$1" line="MACARCHY_COMPONENTS=\"$MACARCHY_COMPONENTS\""
  if [ "$DRY_RUN" = 1 ]; then
    echo "+ set $line in $f"
    return
  fi
  if grep -q '^MACARCHY_COMPONENTS=' "$f" 2>/dev/null; then
    local out
    out="$(LINE="$line" awk '/^MACARCHY_COMPONENTS=/ { print ENVIRON["LINE"]; next } { print }' "$f")"
    printf '%s\n' "$out" >"$f"
  else
    printf '\n# Set by install.sh; edit, or re-run with --only / --skip / --remove.\n%s\n' "$line" >>"$f"
  fi
  echo "  $line"
}

# -----------------------------------------------------------------------
# 9. Optional integrations -- only touched if the target app is present
# -----------------------------------------------------------------------
step_agent() {
  macarchy_has agent || return 0
  # Workspace agent (`ws`): a uv-managed venv (agent/uv.lock) with the Needle
  # runtime, plus the fine-tuned model.
  local models="$HOME/.local/share/macarchy/models"
  local model="${MACARCHY_AGENT_MODEL:-$models/workspace-agent.cact}"
  echo "==> Workspace agent (ws): venv + model"
  run mkdir -p "$models"
  run "$REPO/home/.config/macarchy/agent/sync-venv"
  if [ ! -f "$model" ]; then
    if [ -n "${MACARCHY_AGENT_MODEL_URL:-}" ]; then
      run curl -fsSL "$MACARCHY_AGENT_MODEL_URL" -o "$model"
    else
      echo "  agent: no model at $model; ws falls back to base Needle 3 (weaker)." >&2
      echo "  agent: train one with home/.config/macarchy/agent/finetune/README.md, or set MACARCHY_AGENT_MODEL_URL." >&2
    fi
  fi
}

step_build() {
  { macarchy_has agent || macarchy_has bar; } || return 0
  # Two small Swift helpers: the Handy-style pill `ws --voice` draws, and the
  # mic/camera probe the bar's `mic` and `cam` items poll. Needs swiftc (Xcode CLT).
  echo "==> Swift helpers (macarchy-overlay, macarchy-avstate)"
  if xcrun -f swiftc >/dev/null 2>&1; then
    run "$REPO/home/.config/macarchy/swift/build"
  else
    echo "  swiftc not found; skipping. ws --voice falls back to notifications and the mic/cam items stay hidden." >&2
    echo "  Install with: xcode-select --install, then run home/.config/macarchy/swift/build" >&2
  fi
}

step_login_update() {
  echo "==> Update at login (MACARCHY_UPDATE_AT_LOGIN=$MACARCHY_UPDATE_AT_LOGIN)"
  if [ "$MACARCHY_UPDATE_AT_LOGIN" = true ]; then
    run "$REPO/home/.config/macarchy/bin/macarchy-update" --login on
  else
    run "$REPO/home/.config/macarchy/bin/macarchy-update" --login off
  fi
}

step_optional_integrations() {
  macarchy_has themes || return 0
  echo "==> Optional integrations"
  if [ -d "$HOME/.config/zellij" ]; then
    run mkdir -p "$HOME/.config/zellij/themes"
    run ln -sfn "$HOME/.config/theme/current/zellij.kdl" "$HOME/.config/zellij/themes/current.kdl"
  else
    echo "  ~/.config/zellij not found, skipping zellij theme link"
  fi
  if [ -d "$HOME/.config/nvim" ]; then
    run mkdir -p "$HOME/.config/nvim/lua/plugins"
    run ln -sfn "$HOME/.config/theme/current/neovim.lua" "$HOME/.config/nvim/lua/plugins/theme.lua"
  else
    echo "  ~/.config/nvim not found, skipping neovim theme link"
  fi
}

if [ -n "$REMOVE" ]; then
  step_unlink
  save_components "$HOME/.config/macarchy/config"
  cat <<NOTICE

Removed: $(commas "$REMOVE"). Still installed: $MACARCHY_COMPONENTS.
Brew packages were left in place. To stop and remove them too:
  wm       yabai --stop-service; skhd --stop-service; brew uninstall yabai skhd
  bar      brew services stop sketchybar; brew uninstall sketchybar
  borders  brew services stop borders; brew uninstall borders
  agent    brew uninstall --cask handy; rm -rf ~/.local/share/macarchy/venv
NOTICE
  exit 0
fi

echo "components: $MACARCHY_COMPONENTS"
echo
step_brew
step_defaults
step_link
step_seed_current
step_theme_assets
step_config
step_agent
step_build
step_login_update
step_optional_integrations

echo
echo "macarchy installed$DRY_NOTE: $MACARCHY_COMPONENTS"
step=0
next_step() {
  step=$((step + 1))
  echo
  echo "  $step. $*"
}

if macarchy_has wm; then
  next_step "Accessibility, or yabai and skhd cannot start:"
  echo "     System Settings > Privacy & Security > Accessibility, add and enable"
  echo "       /opt/homebrew/bin/yabai"
  echo "       /opt/homebrew/bin/skhd"
fi
if macarchy_has wm || macarchy_has bar || macarchy_has borders; then
  next_step "Start the services:"
  macarchy_has wm && echo "       yabai --start-service" && echo "       skhd --start-service"
  macarchy_has borders && echo "       brew services start borders"
  macarchy_has bar && echo "       brew services start sketchybar"
fi
if macarchy_has agent; then
  next_step 'Open Handy.app once (what `ws --voice` transcribes through):'
  echo "       - grant Microphone and Accessibility when it prompts"
  echo "       - pick a model on first run; Parakeet EN is recommended (~700 MB)"
fi
if macarchy_has themes; then
  next_step "Point your apps at the theme. One line each, in YOUR configs; only the apps you use:"
  cat <<HOOKS
       Ghostty    ~/.config/ghostty/config
                    config-file = ?~/.config/theme/current/ghostty
       kitty      ~/.config/kitty/kitty.conf
                    include ~/.config/theme/generated/kitty.conf
       Alacritty  ~/.config/alacritty/alacritty.toml
                    [general]
                    import = ["~/.config/theme/generated/alacritty.toml"]
       iTerm2     Settings > Profiles > "macarchy" > Other Actions > Set as Default
       Zellij     ~/.config/zellij/config.kdl
                    theme "current"
       Neovim     declare the shipped colorscheme plugins with lazy = true
                    (list in docs/theme-system.md)
       VS Code    nothing to add: theme-set sets workbench.colorTheme
       Zed        ~/.config/zed/settings.json
                    "theme": "Macarchy"
     Apps you don't have are skipped. Limit theme-set to some of them with
     MACARCHY_THEME_TARGETS in ~/.config/macarchy/config.
HOOKS
fi

cat <<NOTICE

Staying current: \`macarchy-update\` pulls, relinks and reloads. It also
runs at every login (MACARCHY_UPDATE_AT_LOGIN; \`macarchy-update --login off\`
to stop), logging to ~/Library/Logs/macarchy-update.log.

Re-run this script any time; every step is idempotent. Add or drop parts
with --only / --skip / --remove (./install.sh --list shows them).
NOTICE
