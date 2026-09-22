#!/usr/bin/env bash
# macarchy install.sh — idempotent installer for the macarchy desktop layer.
#
# Usage:
#   ./install.sh              install/update everything
#   ./install.sh --dry-run    print what would happen, change nothing
#
# Safe to re-run: every step either checks first or overwrites the same
# managed path (symlinks via ln -sfn, brew install of already-installed
# formulae, etc).
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || { echo "macarchy: macOS only" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$SCRIPT_DIR"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,10p' "$0"
      exit 0 ;;
    *) echo "macarchy: unknown argument: $arg" >&2; exit 2 ;;
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

echo "macarchy install${DRY_RUN:+ (dry run)}"
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
BREW_FORMULAE=(
  jq
  fzf
  imagemagick
  koekeishiya/formulae/yabai
  koekeishiya/formulae/skhd
  FelixKratz/formulae/sketchybar
  FelixKratz/formulae/borders
)
BREW_CASKS=(font-hack-nerd-font handy)

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
  run brew install "${BREW_FORMULAE[@]}"
  # --adopt: take over an app that is already in /Applications (e.g. Handy installed by hand) instead of failing
  run brew install --cask --adopt "${BREW_CASKS[@]}"

  echo "==> sketchybar-app-font"
  local dest="$HOME/Library/Fonts/sketchybar-app-font.ttf"
  if [ -f "$dest" ]; then
    echo "  already installed: $dest"
  elif [ "$DRY_RUN" = 1 ]; then
    echo "+ download $SKETCHYBAR_APP_FONT_URL -> $dest (sha256 verified)"
  else
    local tmp
    tmp="$(mktemp -t sketchybar-app-font)"
    if curl -fsSL -o "$tmp" "$SKETCHYBAR_APP_FONT_URL" \
       && echo "$SKETCHYBAR_APP_FONT_SHA256  $tmp" | shasum -a 256 -c --status; then
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
  echo "==> Linking files into \$HOME"
  if command -v stow >/dev/null 2>&1; then
    run stow -t "$HOME" -d "$REPO" home
    return
  fi

  echo "  stow not found on PATH; falling back to manual symlinks"
  # Mirror what stow would do, one real file/symlink at a time, so an
  # existing unrelated ~/.config is never replaced wholesale.
  while IFS= read -r -d '' src; do
    rel="${src#"$REPO"/home/}"
    target="$HOME/$rel"
    if [ "$DRY_RUN" = 1 ]; then
      echo "+ mkdir -p $(dirname "$target") && ln -sfn $src $target"
    else
      mkdir -p "$(dirname "$target")"
      ln -sfn "$src" "$target"
    fi
  done < <(find "$REPO/home" \( -type f -o -type l \) -print0)
}

# -----------------------------------------------------------------------
# 4. Seed the active theme
# -----------------------------------------------------------------------
step_seed_current() {
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
    echo "  $dst already exists, leaving it alone"
  else
    run cp "$REPO/home/.config/macarchy/config.example" "$dst"
  fi
}

# -----------------------------------------------------------------------
# 9. Optional integrations -- only touched if the target app is present
# -----------------------------------------------------------------------
step_agent() {
  # Workspace agent (`ws`): a venv with the Needle runtime and the fine-tuned model.
  local venv="$HOME/.local/share/macarchy/venv" models="$HOME/.local/share/macarchy/models"
  local model="${MACARCHY_AGENT_MODEL:-$models/workspace-agent.cact}"
  echo "==> Workspace agent (ws): venv + model"
  run mkdir -p "$models"
  if [ ! -x "$venv/bin/python" ]; then
    run python3 -m venv "$venv"
  fi
  run "$venv/bin/pip" install -q cactus-needle
  if [ ! -f "$model" ]; then
    if [ -n "${MACARCHY_AGENT_MODEL_URL:-}" ]; then
      run curl -fsSL "$MACARCHY_AGENT_MODEL_URL" -o "$model"
    else
      echo "  agent: no model at $model; ws falls back to base Needle 3 (weaker)." >&2
      echo "  agent: train one with home/.config/macarchy/agent/finetune/README.md, or set MACARCHY_AGENT_MODEL_URL." >&2
    fi
  fi
}

step_optional_integrations() {
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

step_brew
step_defaults
step_link
step_seed_current
step_theme_assets
step_config
step_agent
step_optional_integrations

cat <<NOTICE

macarchy installed${DRY_RUN:+ (dry run -- nothing above actually ran)}.

MANUAL STEP REQUIRED -- yabai and skhd cannot start without it:

  1. System Settings > Privacy & Security > Accessibility
     Add and enable BOTH:
       /opt/homebrew/bin/yabai
       /opt/homebrew/bin/skhd

  2. Then start the services:
       yabai --start-service
       skhd --start-service
       brew services start borders
       brew services start sketchybar

  3. Open Handy.app once (it's installed but needs manual setup):
       - Grant Microphone and Accessibility when it prompts
         (System Settings > Privacy & Security)
       - Pick a model on first run -- Parakeet EN is recommended (~700 MB)
       - Optional: enable "launch at login" in Handy's own settings
     This is what \`ws --voice\` transcribes through (MACARCHY_HANDY).

One-line hooks to add to your OWN configs (not managed by this repo):

  Ghostty  (~/.config/ghostty/config):
    config-file = ?~/.config/theme/current/ghostty

  Zellij   (~/.config/zellij/config.kdl):
    theme "current"

  Neovim   (a plugins file, e.g. lua/plugins/theme-plugins.lua):
    declare the colorscheme plugins the shipped themes use with lazy = true,
    so lazy.nvim sees them even when their theme is not the active one:
    nvim-mini/mini.base16, rebelot/kanagawa.nvim, catppuccin/nvim,
    folke/tokyonight.nvim, ellisonleao/gruvbox.nvim, EdenEast/nightfox.nvim.
    See docs/theme-system.md.

Re-run this script any time; every step is idempotent. After editing a
theme's colors.sh or adding/removing a theme, run \`theme-maintain\` instead
of the whole installer.
NOTICE
