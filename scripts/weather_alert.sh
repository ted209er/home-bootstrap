#!/bin/bash

set -euo pipefail

info() {
	printf 'INFO: %s\n' "$*"
}

warn() {
	printf 'WARN: %s\n' "$*" >&2
}

die() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

# Set your location or leave blank for auto-detect (will not be accurate on vpn).
LOCATION="Austin"

if ! command -v curl >/dev/null 2>&1; then
	die "curl is not installed or is not on PATH."
fi

# Fetch current weather in a simple format
WEATHER=$(curl -s "wttr.in/${LOCATION}?format=1")

# Define severe weather keywords to look for
KEYWORDS=("thunder" "storm" "lightning" "hail" "tornado" "severe" "flood")

# Convert weather string to lowercase for easier matching
WEATHER_LOWER=$(echo "$WEATHER" | tr '[:upper:]' '[:lower:]')

# Check if any keywords are in the weather string
ALERT=false
for word in "${KEYWORDS[@]}"; do
	if echo "$WEATHER_LOWER" | grep -q "$word"; then
		ALERT=true
		break
	fi
done

# Send alert if needed
if [ "$ALERT" = true ]; then
	warn "Weather alert: $WEATHER"
	notify-send "Weather Alert" "$WEATHER" 2>/dev/null || true
	logger "Weather Alert: $WEATHER"
else
	info "No weather alert: $WEATHER"
fi
