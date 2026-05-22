# Agent Instructions

## Scope

This repository bootstraps a personal development environment and contains small utility scripts. Treat it as an operations repository: changes can affect shell setup, package installation, local credentials, and host runtime state.

## Working Rules

- Read the relevant script or document before editing it.
- Keep changes narrowly scoped to the user request.
- Do not rewrite bootstrap scripts unless the user explicitly asks for script changes.
- Do not add dependencies, CI/CD, cron jobs, systemd units, or network-mutating behavior without explicit approval.
- Do not commit changes unless the user explicitly asks.
- Preserve intentional project files such as `README.md`, `AGENTS.md`, `docs/`, `scripts/`, `.devcontainer/`, and templates.
- Keep generated files, reports, logs, virtual environments, caches, and local secrets out of commits.

## Safety Checks

- Run `git status --short --ignored` before summarizing work.
- For shell scripts, run `bash -n path/to/script.sh` after edits.
- For generated reports, verify they are ignored unless the user asks to keep a report.
- Call out already-tracked generated or secret-bearing files that should be removed from the Git index with `git rm --cached`.

## Repository Notes

- `scripts/repo_audit.sh` writes generated Markdown reports under `reports/`, which should remain untracked.
- `scripts/weather-alert/` uses Python and may create a local virtual environment, logs, and local config files.
- Example config files are allowed to be tracked; local config files with real credentials are not.
