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

# Launch polybar on all connected monitors
for monitor in $(xrandr --query | grep " connected" | cut -d' ' -f1); do
  MONITOR="$monitor" polybar example -c "$CONFIG" >>"$LOGFILE" 2>&1 &
  echo "Polybar launched on $monitor"
done

echo "Logs: $LOGFILE"
