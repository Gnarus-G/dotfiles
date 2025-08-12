#!/bin/bash

# Script to dynamically generate eww bar configurations based on detected monitors

EWW_CONFIG_DIR="$(dirname "$0")"
BASE_CONFIG="$EWW_CONFIG_DIR/eww.yuck.template"
OUTPUT_CONFIG="$EWW_CONFIG_DIR/eww.yuck"

# Function to detect connected monitors
detect_monitors() {
  # Use xrandr to get connected monitors, excluding disconnected ones
  xrandr --query | grep " connected" | wc -l
}

# Function to generate bar definition for a specific monitor
generate_bar_def() {
  local monitor_index=$1
  local bar_name="bar$monitor_index"
  local y_pos="5px"
  local distance="30px"

  if [ $monitor_index -eq 0 ]; then
    bar_name="bar"
    y_pos="10px"
    distance="35px"
  fi

  cat <<EOF

(defwindow $bar_name
  :monitor $monitor_index
  :windowtype "dock"
  :geometry (geometry :x "0%"
                      :y "$y_pos"
                      :width "99%"
                      :height "10px"
                      :anchor "top center")
  :reserve (struts :side "top" :distance "$distance")
  (bar :index $monitor_index))
EOF
}

# Function to generate open-many command for eww
generate_open_command() {
  local monitor_count=$1
  local bars=""

  for i in $(seq 0 $((monitor_count - 1))); do
    if [ $i -eq 0 ]; then
      bars="bar"
    else
      bars="$bars bar$i"
    fi
  done

  echo "eww -c \$SCRIPTPATH/.config/eww open-many $bars"
}

# Main execution
main() {
  echo "🖥️  Detecting monitors..."
  MONITOR_COUNT=$(detect_monitors)
  echo "📊 Found $MONITOR_COUNT monitors"

  # Copy base template to working config
  if [ -f "$BASE_CONFIG" ]; then
    cp "$BASE_CONFIG" "$OUTPUT_CONFIG"
  else
    echo "❌ Base template not found at $BASE_CONFIG"
    echo "ℹ️  Creating template from current config..."
    # Create template by removing existing bar definitions
    sed '/^(defwindow bar/,/^  (bar :index [0-9]))/d' "$OUTPUT_CONFIG" >"$BASE_CONFIG"
  fi

  echo "🔧 Generating dynamic bar configurations..."

  # Generate bar definitions for each monitor
  for i in $(seq 0 $((MONITOR_COUNT - 1))); do
    echo "  📺 Adding bar for monitor $i"
    generate_bar_def $i >>"$OUTPUT_CONFIG"
  done

  echo "✅ Generated eww.yuck with $MONITOR_COUNT bars"

  # Output the eww command for the up script
  echo "💡 Use this command in your up script:"
  echo "   $(generate_open_command $MONITOR_COUNT)"

  return 0
}

# Run main function
main "$@"
