#!/bin/bash

# Script to clean up dynamically generated eww configurations

EWW_CONFIG_DIR="$(dirname "$0")"
TEMPLATE_CONFIG="$EWW_CONFIG_DIR/eww.yuck.template"
OUTPUT_CONFIG="$EWW_CONFIG_DIR/eww.yuck"

if [ -f "$TEMPLATE_CONFIG" ]; then
  echo "🧹 Restoring original configuration from template"
  cp "$TEMPLATE_CONFIG" "$OUTPUT_CONFIG"
  echo "✅ Configuration restored"
else
  echo "❌ Template file not found at $TEMPLATE_CONFIG"
  echo "ℹ️  Cannot restore original configuration"
  exit 1
fi
