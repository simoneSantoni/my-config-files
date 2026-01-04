#!/bin/bash

# caffeine.sh - Toggle screen sleep prevention for Polybar
# Prevents screen from sleeping/screensaver activation when enabled

CAFFEINE_FILE="/tmp/caffeine_enabled"

# Check if caffeine is currently enabled
is_enabled() {
  [[ -f "$CAFFEINE_FILE" ]]
}

# Enable caffeine (prevent sleep)
enable_caffeine() {
  touch "$CAFFEINE_FILE"
  # Disable DPMS and screensaver
  xset s off
  xset -dpms
  # Kill any existing caffeine loop and start new one
  pkill -f "caffeine_loop"
  (
    while [[ -f "$CAFFEINE_FILE" ]]; do
      xdg-screensaver reset 2>/dev/null || xset s reset
      sleep 30
    done
  ) &
  disown
}

# Disable caffeine (allow sleep)
disable_caffeine() {
  rm -f "$CAFFEINE_FILE"
  pkill -f "caffeine_loop"
  # Re-enable DPMS and screensaver
  xset s on
  xset +dpms
}

# Toggle caffeine state
toggle() {
  if is_enabled; then
    disable_caffeine
  else
    enable_caffeine
  fi
}

# Display current state with icon
display() {
  if is_enabled; then
    echo "%{F#E95420}󰅶%{F-}"  # Coffee cup icon - active (using primary color)
  else
    echo "%{F#8d8d8d}󰛊%{F-}"  # Coffee cup off - inactive (using disabled color)
  fi
}

case "$1" in
  --toggle)
    toggle
    ;;
  --enable)
    enable_caffeine
    ;;
  --disable)
    disable_caffeine
    ;;
  --status)
    is_enabled && echo "enabled" || echo "disabled"
    ;;
  *)
    display
    ;;
esac

exit 0
