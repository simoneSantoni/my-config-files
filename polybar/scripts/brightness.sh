#!/bin/bash

# brightness.sh - Control screen brightness for Polybar

get_brightness() {
  if command -v brightnessctl &>/dev/null; then
    brightnessctl -m | awk -F, '{print $4}' | tr -d '%'
  elif command -v xbacklight &>/dev/null; then
    xbacklight -get | cut -d. -f1
  else
    echo "N/A"
  fi
}

set_brightness() {
  local value="$1"
  if command -v brightnessctl &>/dev/null; then
    brightnessctl set "$value" -q
  elif command -v xbacklight &>/dev/null; then
    xbacklight -set "$value"
  fi
}

increase() {
  if command -v brightnessctl &>/dev/null; then
    brightnessctl set +5% -q
  elif command -v xbacklight &>/dev/null; then
    xbacklight -inc 5
  fi
}

decrease() {
  if command -v brightnessctl &>/dev/null; then
    brightnessctl set 5%- -q
  elif command -v xbacklight &>/dev/null; then
    xbacklight -dec 5
  fi
}

display() {
  local brightness=$(get_brightness)
  if [[ "$brightness" == "N/A" ]]; then
    echo "󰃠 N/A"
  else
    echo "󰃠 ${brightness}%"
  fi
}

case "$1" in
  --up)
    increase
    ;;
  --down)
    decrease
    ;;
  --set)
    set_brightness "$2"
    ;;
  *)
    display
    ;;
esac

exit 0
