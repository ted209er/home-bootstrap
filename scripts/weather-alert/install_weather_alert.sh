#/bin/bash

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"


# Check to ensure virtual environment is installed

if ! python3 -m venv --help > /dev/null 2 >&1; then
	echo "❌ python3-venv is not installed. Run: sudo apt install python3-venv"
	exit 1
fi


# Setup virtual environment

if [ ! -d venv ]; then 
	python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt


# Add cron job

CRON_JOB="*/15 * * * * source $SCRIPT_DIR/venv/bin/activate && python3 $SCRIPT_DIR/weather_alert.py"


# Remove duplicate

( crontab -l | grep -v 'weather_alert.py' ; echo "$CRON_JOB" ) | crontab -

echo "Weather alert system installed and scheduled every 15 minutes."

