#!/bin/bash

# monitor-toggle.sh - Toggle monitors on/off for Polybar

get_status() {
  local monitor="$1"
  local mode=$(xrandr --query | grep "^$monitor " | awk '{print $3}')
  if [[ "$mode" == *"+"* ]]; then
    echo "on"
  else
    echo "off"
  fi
}

toggle_monitor() {
  local monitor="$1"
  local status=$(get_status "$monitor")

  if [[ "$status" == "on" ]]; then
    xrandr --output "$monitor" --off
  else
    xrandr --output "$monitor" --auto
  fi
}

display() {
  local monitor="$1"
  local label="$2"
  local status=$(get_status "$monitor")

  if [[ "$status" == "on" ]]; then
    echo "%{F#E95420}󰍹%{F-} $label"
  else
    echo "%{F#6d6d6d}󰶐%{F-} $label"
  fi
}

case "$1" in
  --toggle)
    toggle_monitor "$2"
    ;;
  --status)
    get_status "$2"
    ;;
  --display)
    display "$2" "$3"
    ;;
  *)
    echo "Usage: $0 --toggle|--status|--display <monitor> [label]"
    ;;
esac

exit 0
