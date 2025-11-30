#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/polybar/config.ini"
LOGFILE="${XDG_CACHE_HOME:-$HOME/.cache}/polybar.log"

if [[ ! -f "$CONFIG" ]]; then
  echo "Polybar config missing: $CONFIG" >&2
  exit 1
fi

killall -q polybar || true
while pgrep -x polybar >/dev/null; do sleep 1; done

mkdir -p "$(dirname "$LOGFILE")"
: >"$LOGFILE"

monitors=()
if command -v xrandr >/dev/null; then
  # Prefer explicit monitor targeting when available
  while IFS= read -r mon; do
    monitors+=("$mon")
  done < <(xrandr --listmonitors | awk 'NR>1 {print $4}')
fi

if [[ ${#monitors[@]} -gt 0 ]]; then
  for mon in "${monitors[@]}"; do
    MONITOR="$mon" polybar example -c "$CONFIG" >>"$LOGFILE" 2>&1 &
  done
else
  polybar example -c "$CONFIG" >>"$LOGFILE" 2>&1 &
fi

echo "Polybar launched; logs: $LOGFILE"
