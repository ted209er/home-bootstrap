#!/bin/bash

# Set your location or leave blank for auto-detect (will not be accurate on vpn).
LOCATION="Austin"

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
	echo "⚠️  Weather Alert: $WEATHER"
	notify-send "⚠️ Weather Alert" "$WEATHER" 2>/dev/null
	logger "⚠️ Weather Alert: $WEATHER"
fi

