#!/bin/bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
DRY_RUN=false

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

usage() {
	cat <<EOF
Usage: $0 [--dry-run] [--help]

Install the weather alert utility into a local virtualenv and schedule it with
cron every 15 minutes.

Options:
  --dry-run  Print virtualenv, dependency install, and crontab changes without
             running them.
  --help     Show this help message.
EOF
}

run_cmd() {
	printf '+'
	printf ' %q' "$@"
	printf '\n'

	if [ "$DRY_RUN" = false ]; then
		"$@"
	fi
}

parse_args() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			--dry-run)
				DRY_RUN=true
				;;
			--help|-h)
				usage
				exit 0
				;;
			*)
				printf '\n' >&2
				usage >&2
				die "Unknown option: $1"
				;;
		esac
		shift
	done
}

parse_args "$@"

# Check to ensure virtual environment is installed

if [ "$DRY_RUN" = false ] && ! python3 -m venv --help >/dev/null 2>&1; then
	die "python3-venv is not installed. Run: sudo apt install python3-venv"
fi

# Setup virtual environment

if [ ! -d venv ]; then
	info "Will create virtualenv: $SCRIPT_DIR/venv"
	run_cmd python3 -m venv venv
else
	info "Virtualenv already exists: $SCRIPT_DIR/venv"
fi

info "Will install Python dependencies from: $SCRIPT_DIR/requirements.txt"
if [ "$DRY_RUN" = true ]; then
	info "+ source ./venv/bin/activate"
	info "+ pip install -r requirements.txt"
else
	# shellcheck disable=SC1091
	source ./venv/bin/activate
	pip install -r requirements.txt
fi

# Add cron job

CRON_JOB="*/15 * * * * source $SCRIPT_DIR/venv/bin/activate && python3 $SCRIPT_DIR/weather_alert.py"
EXISTING_CRON="$(crontab -l 2>/dev/null || true)"
WEATHER_CRON_COUNT="$(printf '%s\n' "$EXISTING_CRON" | grep -c 'weather_alert.py' || true)"
FILTERED_CRON="$(printf '%s\n' "$EXISTING_CRON" | grep -v 'weather_alert.py' || true)"

# Install or replace the managed cron entry without duplicating it.

info "Will install cron entry:"
info "  $CRON_JOB"

if [ "$WEATHER_CRON_COUNT" -eq 1 ] && printf '%s\n' "$EXISTING_CRON" | grep -Fxq "$CRON_JOB"; then
	info "Cron entry already installed; no crontab changes needed."
elif [ "$DRY_RUN" = true ]; then
	if [ "$WEATHER_CRON_COUNT" -gt 0 ]; then
		if [ "$WEATHER_CRON_COUNT" -eq 1 ]; then
			info "Will replace 1 existing weather alert cron entry."
		else
			info "Will replace $WEATHER_CRON_COUNT existing weather alert cron entries."
		fi
	fi
	info "+ (crontab -l 2>/dev/null | grep -v 'weather_alert.py'; echo \"$CRON_JOB\") | crontab -"
else
	{
		if [ -n "$FILTERED_CRON" ]; then
			printf '%s\n' "$FILTERED_CRON"
		fi
		printf '%s\n' "$CRON_JOB"
	} | crontab -
fi

if [ "$DRY_RUN" = true ]; then
	info "Dry run complete. No changes were made."
else
	info "Weather alert system installed and scheduled every 15 minutes."
fi
