#!/bin/bash

# screen-layout.sh - Cycle through screen layouts for Polybar

LAYOUT_FILE="/tmp/screen_layout"

# Get connected monitors
PRIMARY="eDP"
EXTERNAL="DisplayPort-1"

get_current_layout() {
  if [[ -f "$LAYOUT_FILE" ]]; then
    cat "$LAYOUT_FILE"
  else
    echo "extend-right"
  fi
}

set_layout() {
  local layout="$1"

  case "$layout" in
    "extend-right")
      xrandr --output $PRIMARY --auto --output $EXTERNAL --auto --right-of $PRIMARY
      ;;
    "extend-left")
      xrandr --output $PRIMARY --auto --output $EXTERNAL --auto --left-of $PRIMARY
      ;;
    "mirror")
      xrandr --output $PRIMARY --auto --output $EXTERNAL --auto --same-as $PRIMARY
      ;;
    "external-only")
      xrandr --output $PRIMARY --off --output $EXTERNAL --auto
      ;;
    "laptop-only")
      xrandr --output $EXTERNAL --off --output $PRIMARY --auto
      ;;
  esac

  echo "$layout" > "$LAYOUT_FILE"
}

cycle_layout() {
  local layouts=("extend-right" "extend-left" "mirror" "external-only" "laptop-only")
  local current=$(get_current_layout)

  local current_index=0
  for i in "${!layouts[@]}"; do
    if [[ "${layouts[$i]}" == "$current" ]]; then
      current_index=$i
      break
    fi
  done

  local next_index=$(((current_index + 1) % ${#layouts[@]}))
  set_layout "${layouts[$next_index]}"
}

display() {
  local layout=$(get_current_layout)

  case "$layout" in
    "extend-right")
      echo "󰍹󰁔󰍹"
      ;;
    "extend-left")
      echo "󰍹󰁍󰍹"
      ;;
    "mirror")
      echo "󰍹󰿟󰍹"
      ;;
    "external-only")
      echo "󰶐 󰍹"
      ;;
    "laptop-only")
      echo "󰍹 󰶐"
      ;;
    *)
      echo "󰍹󰁔󰍹"
      ;;
  esac
}

case "$1" in
  --cycle)
    cycle_layout
    ;;
  --set)
    set_layout "$2"
    ;;
  --status)
    get_current_layout
    ;;
  *)
    display
    ;;
esac

exit 0
