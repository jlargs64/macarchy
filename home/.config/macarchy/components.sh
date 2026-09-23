#!/usr/bin/env bash
# macarchy/components.sh -- the pieces of macarchy you can take or leave.
#
# Sourced by install.sh and macarchy-update. Every file under home/ belongs to
# exactly one component (see macarchy_component_of); a file is linked into
# $HOME only when its component is in MACARCHY_COMPONENTS.
#
#   core    lib.sh, config, macarchy-update. Always installed.
#   themes  theme-set and the 22 themes: terminal, editor, Neovim, wallpaper
#   wm      yabai tiling + skhd hotkeys over native Spaces
#   bar     SketchyBar status bar
#   borders JankyBorders focus border
#   keys    macarchy-keys, the which-key hotkey popup
#   agent   ws, the on-device workspace agent, and Handy for voice
#
# Written for bash 3.2 (macOS system bash): no associative arrays.

MACARCHY_ALL_COMPONENTS="themes wm bar borders keys agent"

macarchy_component_desc() {
  case "$1" in
    themes) echo "theme-set + 22 themes for your terminal, editor, Neovim and wallpaper" ;;
    wm) echo "yabai tiling + skhd hotkeys, layered over native Spaces (no SIP changes)" ;;
    bar) echo "SketchyBar status bar (needs themes)" ;;
    borders) echo "JankyBorders focus border (needs themes)" ;;
    keys) echo "macarchy-keys: alt - / which-key popup of every hotkey" ;;
    agent) echo "ws: plain-English / voice control of windows and themes, plus Handy" ;;
  esac
}

# Components a component cannot work without.
macarchy_component_needs() {
  case "$1" in
    bar | borders) echo "themes" ;;
  esac
}

# macarchy_component_of <path relative to home/> -> component name.
# Specific paths first: the first match wins.
macarchy_component_of() {
  case "$1" in
    .config/theme/bin/hotkey-check | .local/bin/hotkey-check) echo wm ;;
    .config/macarchy/bin/macarchy-keys | .local/bin/macarchy-keys) echo keys ;;
    .config/macarchy/agent/* | .config/macarchy/swift/* | .local/bin/ws) echo agent ;;
    .config/theme/* | .config/raycast/* | .local/bin/theme-*) echo themes ;;
    .config/yabai/* | .config/skhd/*) echo wm ;;
    .config/sketchybar/*) echo bar ;;
    .config/borders/*) echo borders ;;
    *) echo core ;;
  esac
}

# macarchy_has <component> -- is it in MACARCHY_COMPONENTS? core always is.
macarchy_has() {
  [ "$1" = core ] && return 0
  case " ${MACARCHY_COMPONENTS:-$MACARCHY_ALL_COMPONENTS} " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

# macarchy_resolve_components <list> -> the list plus anything it needs,
# in canonical order, unknown names dropped with a warning on stderr.
macarchy_resolve_components() {
  local want=" $* " c n out=""
  for c in $want; do
    case " $MACARCHY_ALL_COMPONENTS " in
      *" $c "*) ;;
      *) echo "macarchy: unknown component '$c' (one of: $MACARCHY_ALL_COMPONENTS)" >&2 ;;
    esac
    for n in $(macarchy_component_needs "$c"); do
      case "$want" in *" $n "*) ;; *)
        want="$want$n "
        echo "macarchy: $c needs $n, adding it" >&2
        ;;
      esac
    done
  done
  for c in $MACARCHY_ALL_COMPONENTS; do
    case "$want" in *" $c "*) out="$out $c" ;; esac
  done
  echo "${out# }"
}

# macarchy_stable_repo <dir> -> the path links into $HOME should use.
# A Homebrew install lives in .../Cellar/macarchy/<version>/libexec, which
# disappears on the next `brew upgrade`; its opt/ symlink does not, so links
# go through that instead. A git checkout is returned unchanged.
macarchy_stable_repo() {
  case "$1" in
    */Cellar/macarchy/*/libexec) echo "${1%%/Cellar/*}/opt/macarchy/libexec" ;;
    *) echo "$1" ;;
  esac
}

# macarchy_repo_files <repo> -> files under home/, one per line, relative to
# <repo>. Tracked files in a git checkout (local junk such as __pycache__
# never lands in $HOME); everything in a tarball or Homebrew install.
macarchy_repo_files() {
  if [ -e "$1/.git" ]; then
    git -C "$1" ls-files home
  else
    (cd "$1" && find home \( -type f -o -type l \) -print | LC_ALL=C sort)
  fi
}

# macarchy_is_our_link <path> <repo> -- is <path> a symlink into <repo>/home?
# Checks both the given repo path and its fully resolved form, so a link made
# through Homebrew's opt/ path and one made through Cellar/ both count.
macarchy_is_our_link() {
  local dest real
  [ -L "$1" ] || return 1
  dest="$(readlink "$1")"
  case "$dest" in "$2"/home/*) return 0 ;; esac
  # the resolved repo path is the same for every call; work it out once
  if [ "${_MACARCHY_REAL_OF:-}" != "$2" ]; then
    _MACARCHY_REAL="$(cd "$2" 2>/dev/null && pwd -P)" || return 1
    _MACARCHY_REAL_OF="$2"
  fi
  real="$_MACARCHY_REAL"
  case "$dest" in "$real"/home/*) return 0 ;; esac
  return 1
}
