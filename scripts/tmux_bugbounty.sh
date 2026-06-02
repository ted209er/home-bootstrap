#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s WORKSPACE_PATH\n' "$0" >&2
  printf 'Example: %s ~/recon/test-bounty-1\n' "$0" >&2
}

require_tmux() {
  if ! command -v tmux >/dev/null 2>&1; then
    printf 'Error: tmux is not installed or is not on PATH.\n' >&2
    exit 1
  fi
}

expand_workspace_path() {
  case "$1" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    \~/*)
      printf '%s/%s\n' "$HOME" "${1#\~/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

resolve_workspace_path() {
  local requested_path expanded_path

  requested_path=$1
  expanded_path=$(expand_workspace_path "$requested_path")

  # Create the workspace before resolving it so new paths work cleanly.
  mkdir -p "$expanded_path"
  (
    cd "$expanded_path"
    pwd -P
  )
}

create_starter_files() {
  local workspace=$1

  mkdir -p \
    "$workspace/notes" \
    "$workspace/findings" \
    "$workspace/reports" \
    "$workspace/screenshots" \
    "$workspace/data"

  [ -f "$workspace/notes/notes.md" ] || : >"$workspace/notes/notes.md"
  [ -f "$workspace/scope.txt" ] || : >"$workspace/scope.txt"
}

session_name_for_workspace() {
  local workspace base safe_base

  workspace=$1
  base=$(basename "$workspace")
  [ -n "$base" ] || base="workspace"

  # Keep tmux target names boring: alphanumerics, dot, underscore, and dash.
  safe_base=$(printf '%s' "$base" | tr -c '[:alnum:]_.-' '-')
  printf 'bounty-%s\n' "$safe_base"
}

send_reconbot_hints() {
  local target=$1

  tmux send-keys -t "$target" "printf '%s\n' '# Reconbot starter commands'" C-m
  tmux send-keys -t "$target" "printf '%s\n' '# reconbot doctor --workspace .'" C-m
  tmux send-keys -t "$target" "printf '%s\n' '# reconbot --domain <domain> --workspace . --profile deep --run-name baseline'" C-m
  tmux send-keys -t "$target" "printf '%s\n' '# reconbot plan --workspace .'" C-m
}

create_tmux_workspace() {
  local session=$1
  local workspace=$2
  local window
  local top middle bottom middle_right bottom_right
  local editor

  editor=${EDITOR:-vi}

  tmux new-session -d -s "$session" -n hunt -c "$workspace"
  window="${session}:hunt"
  top=$(tmux display-message -p -t "$window" '#{pane_id}')

  # Top pane stays full-width for planning/Codex. The lower area becomes
  # two rows, each split left/right for recon, notes, shell, and testing.
  bottom=$(tmux split-window -v -p 66 -t "$top" -c "$workspace" -P -F '#{pane_id}')
  middle=$bottom
  bottom=$(tmux split-window -v -p 50 -t "$middle" -c "$workspace" -P -F '#{pane_id}')
  middle_right=$(tmux split-window -h -t "$middle" -c "$workspace" -P -F '#{pane_id}')
  bottom_right=$(tmux split-window -h -t "$bottom" -c "$workspace" -P -F '#{pane_id}')

  tmux send-keys -t "$top" "printf '%s\n' '# Codex / planning pane'" C-m
  send_reconbot_hints "$middle"
  tmux send-keys -t "$middle_right" "$editor notes/notes.md" C-m
  tmux send-keys -t "$bottom" "printf '%s\n' '# General shell'" C-m
  tmux send-keys -t "$bottom_right" "printf '%s\n' '# Testing / curl / jq / Burp helper commands'" C-m

  tmux select-pane -t "$top"
}

main() {
  local workspace session

  if [ "$#" -lt 1 ]; then
    usage
    exit 1
  fi

  require_tmux

  workspace=$(resolve_workspace_path "$1")
  create_starter_files "$workspace"
  session=$(session_name_for_workspace "$workspace")

  if tmux has-session -t "$session" 2>/dev/null; then
    printf 'Attaching to existing session: %s\n' "$session"
    exec tmux attach-session -t "$session"
  fi

  create_tmux_workspace "$session" "$workspace"
  exec tmux attach-session -t "$session"
}

main "$@"
