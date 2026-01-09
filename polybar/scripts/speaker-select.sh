#!/bin/bash

# speaker-select.sh - Audio output (sink) selector for Polybar (PipeWire)

get_audio_sinks() {
  # Get the Sinks section from Audio - filter for lines with [vol:
  wpctl status | awk '/^Audio/,/^Video/' | awk '/Sinks:/,/Sink endpoints:/' | grep '\[vol:'
}

get_sinks() {
  # Extract sink ID - the number that appears after │ and optional * before first .
  get_audio_sinks | sed 's/^[^0-9]*//' | cut -d'.' -f1
}

get_current_sink_id() {
  get_audio_sinks | grep '\*' | sed 's/^[^0-9]*//' | cut -d'.' -f1
}

get_sink_name() {
  local sink_id=$1
  get_audio_sinks | grep -E "[[:space:]]${sink_id}\." | sed 's/^[^.]*\. //' | sed 's/ \[vol:.*//'
}

get_short_name() {
  local name="$1"
  # Shorten common names for display
  if echo "$name" | grep -qi "speaker\|headphone"; then
    echo "SPK"
  elif echo "$name" | grep -qi "hdmi\|displayport"; then
    # Extract DP number if present
    local dp_num=$(echo "$name" | grep -oE 'DisplayPort [0-9]+' | grep -oE '[0-9]+')
    if [ -n "$dp_num" ]; then
      echo "DP$dp_num"
    else
      echo "HDMI"
    fi
  elif echo "$name" | grep -qi "bluetooth\|bt"; then
    echo "BT"
  elif echo "$name" | grep -qi "usb"; then
    echo "USB"
  else
    # Take first 6 chars
    echo "${name:0:6}"
  fi
}

cycle() {
  local sinks=($(get_sinks))
  local current=$(get_current_sink_id)
  local count=${#sinks[@]}

  if [ "$count" -le 1 ]; then
    return
  fi

  # Find current index
  local current_idx=0
  for i in "${!sinks[@]}"; do
    if [ "${sinks[$i]}" = "$current" ]; then
      current_idx=$i
      break
    fi
  done

  # Try each sink until one works (some may be disconnected)
  for attempt in $(seq 1 $count); do
    local next_idx=$(( (current_idx + attempt) % count ))
    wpctl set-default "${sinks[$next_idx]}" 2>/dev/null

    # Check if it actually changed
    local new_current=$(get_current_sink_id)
    if [ "$new_current" = "${sinks[$next_idx]}" ]; then
      return
    fi
  done
}

display() {
  local current_id=$(get_current_sink_id)
  if [ -z "$current_id" ]; then
    echo "%{F#707880}󰓃 ?%{F-}"
    return
  fi
  local name=$(get_sink_name "$current_id")
  local short=$(get_short_name "$name")
  echo "%{F#E95420}󰓃%{F-} $short"
}

case "$1" in
  --cycle)
    cycle
    ;;
  --list)
    for sink_id in $(get_sinks); do
      name=$(get_sink_name "$sink_id")
      current=$(get_current_sink_id)
      if [ "$sink_id" = "$current" ]; then
        echo "* $sink_id: $name"
      else
        echo "  $sink_id: $name"
      fi
    done
    ;;
  *)
    display
    ;;
esac

exit 0
