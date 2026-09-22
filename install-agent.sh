#!/bin/sh
# macarchy agentic install bootstrap.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jlargs64/macarchy/main/install-agent.sh | sh -s -- [agent]
#
# Fetches AGENT-INSTALL.md (the full install prompt) and launches the named
# agent CLI interactively, seeded with it. The agent then walks you through
# the real install (cloning, ./install.sh, the manual Accessibility/Handy
# steps, verification) -- asking before it does anything, one step at a
# time. This script never passes any skip-permissions / yolo / bypass flag
# to any agent: the whole point is that you approve each step yourself.
#
# Supported agents: claude codex pi opencode gemini copilot cursor amp
# Flags: --list  --help  --print (dump the prompt to stdout and exit)
#
# POSIX sh only -- no bashisms. Must pass `sh -n install-agent.sh`.
set -eu

PROMPT_URL_DEFAULT="https://raw.githubusercontent.com/jlargs64/macarchy/main/AGENT-INSTALL.md"
PROMPT_URL="${MACARCHY_INSTALL_PROMPT_URL:-$PROMPT_URL_DEFAULT}"

SUPPORTED="claude codex pi opencode gemini copilot cursor amp"

usage() {
  cat <<'EOF'
macarchy agentic install

Usage:
  install-agent.sh [agent]
  install-agent.sh --list
  install-agent.sh --print
  install-agent.sh --help

Arguments:
  agent    one of: claude codex pi opencode gemini copilot cursor amp
           if omitted, this script auto-detects what's on PATH.

Options:
  --list   list supported agents and whether each is on PATH, then exit.
  --print  print the install prompt (AGENT-INSTALL.md) to stdout and exit.
           Useful for pasting into any chat-based agent by hand.
  --help   show this help and exit.

Env:
  MACARCHY_INSTALL_PROMPT_URL   override where the prompt is fetched from.

This script never passes a skip-permissions/yolo/bypass flag to any agent.
The agent will ask before installing anything.
EOF
}

list_agents() {
  echo "Supported agents:"
  for a in $SUPPORTED; do
    bin="$a"
    [ "$a" = "cursor" ] && bin="cursor-agent"
    if command -v "$bin" >/dev/null 2>&1; then
      echo "  $a  (found: $bin)"
    elif [ "$a" = "cursor" ] && command -v agent >/dev/null 2>&1; then
      echo "  $a  (found: agent)"
    else
      echo "  $a  (not on PATH)"
    fi
  done
}

install_hints() {
  cat <<'EOF'
None of the supported agent CLIs were found on PATH. Install one:

  claude    curl -fsSL https://claude.ai/install.sh | sh
  codex     npm install -g @openai/codex          (or: brew install codex)
  pi        curl -fsSL https://pi.dev/install.sh | sh
  opencode  curl -fsSL https://opencode.ai/install | sh
  gemini    npm install -g @google/gemini-cli
  copilot   npm install -g @github/copilot
  cursor    curl https://cursor.com/install -fsSL | sh
  amp       npm install -g @sourcegraph/amp

Then re-run:
  curl -fsSL https://raw.githubusercontent.com/jlargs64/macarchy/main/install-agent.sh | sh -s -- <agent>
EOF
}

# --- arg parsing --------------------------------------------------------
AGENT=""
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --list) list_agents; exit 0 ;;
    --print) PRINT_ONLY=1 ;;
    claude|codex|pi|opencode|gemini|copilot|cursor|amp)
      AGENT="$arg" ;;
    *)
      echo "install-agent.sh: unknown argument: $arg" >&2
      usage >&2
      exit 2 ;;
  esac
done
PRINT_ONLY="${PRINT_ONLY:-0}"

# --- locate the prompt ---------------------------------------------------
# If run from inside a checkout that has ./AGENT-INSTALL.md next to this
# script, use that file directly (no network). When piped via
# `curl | sh`, $0 is just "sh" (or similar) and this resolves to nothing
# useful, so we fall back to curl in that case.
SELF_DIR=""
if [ -f "$0" ]; then
  SELF_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P || true)"
fi

PROMPT_FILE=""
CLEANUP_PROMPT=1
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/AGENT-INSTALL.md" ]; then
  PROMPT_FILE="$SELF_DIR/AGENT-INSTALL.md"
  CLEANUP_PROMPT=0
  PROMPT_SOURCE="local checkout ($PROMPT_FILE)"
else
  TMP_PROMPT="$(mktemp -t macarchy-agent-install)"
  if ! curl -fsSL "$PROMPT_URL" -o "$TMP_PROMPT"; then
    echo "install-agent.sh: failed to fetch prompt from $PROMPT_URL" >&2
    rm -f "$TMP_PROMPT"
    exit 1
  fi
  PROMPT_FILE="$TMP_PROMPT"
  PROMPT_SOURCE="$PROMPT_URL"
  trap 'rm -f "$TMP_PROMPT"' EXIT
fi

if [ "$PRINT_ONLY" = 1 ]; then
  cat "$PROMPT_FILE"
  exit 0
fi

PROMPT="$(cat "$PROMPT_FILE")"

# --- pick an agent ---------------------------------------------------------
if [ -z "$AGENT" ]; then
  FOUND=""
  for a in $SUPPORTED; do
    bin="$a"
    [ "$a" = "cursor" ] && bin="cursor-agent"
    if command -v "$bin" >/dev/null 2>&1 || { [ "$a" = "cursor" ] && command -v agent >/dev/null 2>&1; }; then
      FOUND="$FOUND $a"
    fi
  done
  # trim leading space
  FOUND="${FOUND# }"

  set -- $FOUND
  case $# in
    0)
      install_hints
      exit 1 ;;
    1)
      AGENT="$1" ;;
    *)
      echo "Several agent CLIs found on PATH. Pick one:"
      i=1
      for a in $FOUND; do
        echo "  $i) $a"
        i=$((i + 1))
      done
      # Read the choice from the real terminal, not stdin (which may be the
      # piped script itself).
      if [ ! -r /dev/tty ]; then
        echo "install-agent.sh: no /dev/tty to prompt for a choice; pass an agent name explicitly, e.g.:" >&2
        echo "  sh -s -- claude" >&2
        exit 1
      fi
      printf "> " > /dev/tty
      read -r choice < /dev/tty
      i=1
      for a in $FOUND; do
        if [ "$i" = "$choice" ]; then
          AGENT="$a"
        fi
        i=$((i + 1))
      done
      if [ -z "$AGENT" ]; then
        echo "install-agent.sh: invalid choice: $choice" >&2
        exit 1
      fi
      ;;
  esac
fi

# --- re-attach the terminal ------------------------------------------------
# When piped via `curl | sh`, stdin is the script itself. The agent needs a
# real, interactive terminal to talk to the user.
if [ ! -r /dev/tty ]; then
  echo "install-agent.sh: /dev/tty is not readable; can't launch $AGENT interactively." >&2
  echo "Run this in a real terminal (not inside another non-interactive pipe)." >&2
  exit 1
fi
exec < /dev/tty

echo "macarchy agentic install"
echo "  agent:  $AGENT"
echo "  prompt: $PROMPT_SOURCE"
echo "  the agent will ask before installing anything -- no auto-approve flags are passed."
echo

case "$AGENT" in
  claude)
    exec claude "$PROMPT"
    ;;
  codex)
    exec codex "$PROMPT"
    ;;
  pi)
    # pi takes the prompt as an @file attachment, so the file must outlive
    # this script's own cleanup. Copy it to a stable path and skip the trap
    # cleanup for it (harmless few-KB leftover in $TMPDIR).
    STABLE="${TMPDIR:-/tmp}/macarchy-agent-install.md"
    cp "$PROMPT_FILE" "$STABLE"
    if [ "$CLEANUP_PROMPT" = 1 ]; then
      trap - EXIT
      rm -f "$PROMPT_FILE" 2>/dev/null || true
    fi
    exec pi @"$STABLE"
    ;;
  opencode)
    exec opencode run "$PROMPT" -i
    ;;
  gemini)
    if gemini --help 2>&1 | grep -q -- '--prompt-interactive'; then
      exec gemini -i "$PROMPT"
    else
      echo "warning: this gemini build has no --prompt-interactive; falling back to" >&2
      echo "         'gemini -p', which runs headless (one-shot, no back-and-forth)." >&2
      exec gemini -p "$PROMPT"
    fi
    ;;
  copilot)
    # `copilot -i` (interactive, seeded with a message) is unverified against
    # the installed copilot CLI's actual flags. `-p` (programmatic/one-shot)
    # is the documented, verifiable mode, so we use that rather than guess at
    # an interactive seed flag that might not exist.
    echo "note: launching copilot in programmatic mode (-p), which is single-shot," >&2
    echo "      not a back-and-forth session. If you'd rather drive this by hand," >&2
    echo "      the prompt is also at: $PROMPT_FILE" >&2
    exec copilot -p "$PROMPT"
    ;;
  cursor)
    if command -v cursor-agent >/dev/null 2>&1; then
      exec cursor-agent "$PROMPT"
    else
      exec agent "$PROMPT"
    fi
    ;;
  amp)
    # amp's documented pattern pipes the prompt over stdin (`printf '%s\n'
    # "$PROMPT" | amp`), which would consume the TTY we just re-attached and
    # leave no interactive stdin for amp itself. An `amp "$PROMPT"` positional
    # form is undocumented and unverified. Safest honest option: start amp
    # interactively and tell the user what to paste.
    STABLE="${TMPDIR:-/tmp}/macarchy-agent-install.md"
    cp "$PROMPT_FILE" "$STABLE"
    if [ "$CLEANUP_PROMPT" = 1 ]; then
      trap - EXIT
      rm -f "$PROMPT_FILE" 2>/dev/null || true
    fi
    echo "note: amp's flags for seeding an interactive session were not verified." >&2
    echo "      Starting amp now -- paste this once it's ready:" >&2
    echo "        @$STABLE" >&2
    exec amp
    ;;
  *)
    echo "install-agent.sh: internal error: unhandled agent '$AGENT'" >&2
    exit 2
    ;;
esac
