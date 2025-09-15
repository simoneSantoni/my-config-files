#!/bin/bash

# keyboard-layout.sh - Script to display and switch keyboard layouts for Polybar
# Save this script to ~/.config/polybar/scripts/keyboard-layout.sh
# Make it executable with: chmod +x ~/.config/polybar/scripts/keyboard-layout.sh

# Dependencies: xkb-switch (or setxkbmap for fallback functionality)

# Function to get the current keyboard layout
get_layout() {
  if command -v xkb-switch &>/dev/null; then
    # Use xkb-switch if available (more reliable)
    xkb-switch -p
  else
    # Fallback to setxkbmap
    setxkbmap -query | grep layout | awk '{print $2}'
  fi
}

# Function to cycle to the next layout
cycle_layout() {
  local current_layout=$(get_layout)
  local layouts=("us" "de" "es" "fr" "ru") # Add or remove layouts as needed

  # Find current layout index
  local current_index=0
  for i in "${!layouts[@]}"; do
    if [[ "${layouts[$i]}" == "$current_layout" ]]; then
      current_index=$i
      break
    fi
  done

  # Calculate next layout index
  local next_index=$(((current_index + 1) % ${#layouts[@]}))

  # Set the next layout
  if command -v xkb-switch &>/dev/null; then
    xkb-switch -s "${layouts[$next_index]}"
  else
    setxkbmap "${layouts[$next_index]}"
  fi

  # Update i3 with new layout
  i3-msg -q "exec --no-startup-id pkill -RTMIN+1 i3blocks" &>/dev/null
}

# Function to display the layout with a nice icon
display_layout() {
  local layout=$(get_layout)

  # Use FontAwesome icons if available
  case "$layout" in
  "us")
    echo " US"
    ;;
  "de")
    echo " DE"
    ;;
  "es")
    echo " ES"
    ;;
  "fr")
    echo " FR"
    ;;
  "ru")
    echo " RU"
    ;;
  *)
    echo " $layout"
    ;;
  esac
}

# Main execution
case "$1" in
--cycle)
  cycle_layout
  ;;
--get)
  display_layout
  ;;
*)
  display_layout
  ;;
esac

exit 0
