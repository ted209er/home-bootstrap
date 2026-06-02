# Shell Script Standards

These standards apply to Bash scripts in this repository, including scripts in
hidden directories such as `.devcontainer/`.

## Baseline

- Use a valid shebang, usually `#!/usr/bin/env bash` for portable Bash scripts
  or `#!/bin/bash` for scripts that intentionally target system Bash.
- Keep scripts readable and dependency-light. Prefer straightforward Bash over
  clever shell constructs.
- Use `set -e` for simple installer scripts. Use `set -euo pipefail` when a
  script has argument handling, functions, or non-trivial control flow.
- Quote variable expansions unless word splitting is intentional.
- Prefer `command -v` over `which`.
- Use clear function names for repeated behavior.
- Keep comments helpful and specific to behavior or intent.
- Prefer ASCII log prefixes through small helpers: `INFO:`, `WARN:`, and
  `ERROR:`. Avoid emoji or terminal-specific symbols in scripts that may run in
  minimal shells, cron, containers, or provisioning logs.
- For scripts that install packages, contact networks, update cron, change
  services, write symlinks, or change the login shell, provide `--help` and a
  `--dry-run` mode where practical.
- Dry runs should print the privileged, networked, service, cron, and
  file-mutating commands that would run without executing them.
- Mutating scripts should be idempotent where practical: skip existing package
  helpers and cloned plugin directories, avoid duplicate cron or apt source
  entries, report symlink replacements, and clean temporary installer files.

## Validation

Run syntax checks before considering shell changes complete:

```bash
bash -n bootstrap_dev.sh bootstrap.sh scripts/weather-alert/install_weather_alert.sh .devcontainer/scripts/setup.sh scripts/tmux_bugbounty.sh scripts/repo_audit.sh scripts/weather_alert.sh
```

Run ShellCheck across all shell scripts:

```bash
shellcheck bootstrap_dev.sh bootstrap.sh scripts/weather-alert/install_weather_alert.sh .devcontainer/scripts/setup.sh scripts/tmux_bugbounty.sh scripts/repo_audit.sh scripts/weather_alert.sh
```

The devcontainer installs `shellcheck` so the lint baseline is available in a
fresh container rebuild.

## Known Patterns

- If a script sources a virtualenv activation file created at runtime, add a
  narrow ShellCheck directive such as `# shellcheck disable=SC1091` immediately
  above that source line.
- Use grouped `printf` output for generated Markdown, but prefer double-quoted
  format strings with escaped backticks so ShellCheck can parse intent clearly.
- Keep network, package installation, cron, service, and shell-changing actions
  obvious in the script output.
- Prefer a small `run_cmd` helper for dry-run-aware commands so printed actions
  and executed actions stay aligned.
- For symlink management, check the current target first and report whether the
  script will create, keep, or replace the link.
