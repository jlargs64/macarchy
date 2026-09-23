#!/usr/bin/env bash
#
# CPU and memory for the status bar.
#
# Both numbers used to come from `top -l 1`, and both were wrong:
#
#   CPU     `top -l 1` reports usage averaged SINCE BOOT, not right now, and
#           the old code read only the user% field, ignoring sys%. Two samples
#           are required for a real delta; usage is 100 - idle.
#
#   Memory  `top`'s "PhysMem: NNg used" counts the file cache as used. macOS
#           caches aggressively, so on a 24 GB machine that reads ~22 GB
#           permanently. Activity Monitor's "Memory Used" is a different figure:
#               App Memory + Wired + Compressed
#           which is what this computes from vm_stat.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh" 2>/dev/null
source "$CONFIG_DIR/plugins/hover.sh"

# ----- CPU: two samples, one second apart, usage = 100 - idle ---------------
CPU=$(top -l 2 -n 0 -s 1 2>/dev/null |
  awk '/CPU usage/ { idle = $(NF-1); sub(/%/, "", idle) } END { printf "%d", 100 - idle }')
[ -z "$CPU" ] && CPU=0

# ----- Memory: Activity Monitor's "Memory Used" -----------------------------
MEM=$(vm_stat 2>/dev/null | awk '
  /page size of/                 { ps = $8 }
  /Pages wired down/             { gsub(/\./, ""); wired = $4 }
  /Pages purgeable/              { gsub(/\./, ""); purge = $3 }
  /Anonymous pages/              { gsub(/\./, ""); anon  = $3 }
  /Pages occupied by compressor/ { gsub(/\./, ""); comp  = $5 }
  END {
    app  = anon - purge
    used = (app + wired + comp) * ps / 1073741824
    printf "%.1fG", used
  }')
[ -z "$MEM" ] && MEM="?"

CPU_ICON=""
MEM_ICON=""

sketchybar --set "$NAME" \
  icon="$CPU_ICON" \
  icon.color="$WHITE" \
  label="${CPU}% $MEM_ICON ${MEM}" \
  label.color="$WHITE"
