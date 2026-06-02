# home-bootstrap Roadmap

## Inferred Intent

`home-bootstrap` appears to be a personal environment bootstrap and workflow
automation repository. Its core purpose is to make a Linux workstation or
devcontainer quickly usable with preferred shell tools, GitHub CLI access,
dotfiles, Docker, tmux, editor defaults, and small personal utilities.

The current contents point to four main use cases:

- Bootstrap a base machine with zsh, tmux, vim, Git, curl, neofetch, and linked
  dotfiles from `dotfiles_bootstrap`.
- Bootstrap a fuller development machine with Python tooling and Docker.
- Provide reusable personal workflow launchers, including bug bounty tmux
  workspaces and weather alert scheduling.
- Audit repositories under `$HOME/Repos` and generate Markdown reports about
  branch state, dirty worktrees, documentation presence, and stale branches.

## Current Repository Shape

- `bootstrap.sh`: baseline workstation setup for shell, tmux, vim, neofetch,
  oh-my-zsh, zsh plugins, powerlevel10k, and dotfile symlinks.
- `bootstrap_dev.sh`: expanded workstation setup that adds Python tooling and
  Docker installation/service setup.
- `.devcontainer/`: Ubuntu-based reproducible development container with zsh,
  tmux, vim, Python, Node, GitHub CLI, and host GitHub auth mounting.
- `scripts/repo_audit.sh`: local repository health reporter for repos under
  `${REPOS_ROOT:-$HOME/Repos}`.
- `scripts/tmux_bugbounty.sh`: tmux workspace launcher for bug bounty/recon
  workspaces.
- `scripts/weather_alert.sh` and `scripts/weather-alert/`: weather alert
  utilities, including a cron installer for the Python-based alert script.
- `templates/AGENTS.md`: documentation expectation template for other repos.

## Immediate Improvements

1. Normalize shell script quality.
   - Add `shellcheck` to the devcontainer image.
   - Run `shellcheck` against every `*.sh` script, including hidden paths.
   - Fix current issues such as `bootstrap.sh` spacing in the zsh shell check,
     the `#/bin/bash` typo in `scripts/weather-alert/install_weather_alert.sh`,
     and redirection spacing in that same installer.

2. Add a top-level script catalog.
   - Expand `README.md` with every supported script, expected platform,
     required tools, and whether it mutates the system.
   - Include examples for `bootstrap.sh`, `bootstrap_dev.sh`,
     `scripts/repo_audit.sh`, `scripts/tmux_bugbounty.sh`, and weather alerts.

3. Separate destructive or privileged actions from dry-runable checks.
   - Add `--help` and `--dry-run` where practical.
   - Make scripts print the package installs, symlinks, cron entries, or service
     changes they will perform before doing them.
   - Keep network and system-mutating actions explicit.

4. Improve idempotency.
   - Ensure repeated bootstrap runs do not duplicate config, cron entries, apt
     sources, or stale temporary files.
   - Check whether symlink targets already exist and report replacements.
   - Make Docker installation skip cleanly when Docker is already installed.

5. Standardize logging and error handling.
   - Use consistent `set -euo pipefail` where scripts are Bash-specific.
   - Add small helper functions such as `info`, `warn`, and `die`.
   - Prefer clear ASCII output for scripts that may run in minimal terminals.

## Recommended Next Features

### Bootstrap Profiles

Add one entrypoint, such as `scripts/bootstrap_profile.sh`, that supports named
profiles:

- `base`: shell, tmux, vim, Git, curl, dotfiles.
- `dev`: base plus Python, Node, Docker, GitHub CLI.
- `bug-bounty`: dev plus recon-oriented workspace helpers.
- `container`: devcontainer-safe setup without host-only changes like `chsh`.

This would reduce duplication between `bootstrap.sh`, `bootstrap_dev.sh`, and
`.devcontainer/scripts/setup.sh`.

### Configurable Dotfiles Source

Move hard-coded dotfile values into environment variables or a small config
file:

- `DOTFILES_REPO_URL`
- `DOTFILES_DIR`
- `BOOTSTRAP_DIR`
- `DEFAULT_SHELL`

This keeps the repo personal by default while making it easier to reuse on a
new machine or fork.

### Repo Audit v2

Continue the existing `docs/repo_audit_roadmap.md` direction:

- Add argument parsing and `--help`.
- Replace `pushd`/`popd` with `git -C`.
- Add summary metrics and separate stale branch details.
- Add optional JSON output.
- Add optional `--fetch` and `--prune` flags, disabled by default.
- Write `reports/repo-audits/latest.md` alongside timestamped reports.

### Bug Bounty Workspace Enhancements

Extend `scripts/tmux_bugbounty.sh` without running scans automatically:

- Add `--name` to override the tmux session name.
- Add `--editor` to override the notes editor.
- Add `--layout` presets for compact laptop screens versus large monitors.
- Add optional creation of `scope.txt`, `targets.txt`, and `commands.md`
  templates with safe placeholder content.
- Document expected companion tools, such as `reconbot`, `curl`, `jq`, and Burp.

### Weather Alert Cleanup

Consolidate the shell and Python weather alert paths:

- Decide whether `scripts/weather_alert.sh` or `scripts/weather-alert/` is the
  supported implementation.
- Add documentation for config, location, cron behavior, and uninstall steps.
- Add an installer `--dry-run` mode.
- Add an uninstall command that removes the cron entry cleanly.

### Devcontainer Hardening

Improve the container for repeatable repo maintenance:

- Install `shellcheck` and common formatting tools.
- Avoid installing GitHub CLI twice through both features and setup script
  unless the setup script is only a fallback.
- Document the security tradeoff of mounting host `gh` auth, already noted in
  `README.md`, and include a no-auth alternative.
- Add a validation command that confirms core tools are available.

## Suggested Milestones

### Milestone 1: Documentation and Lint Baseline

- Add complete README script documentation.
- Install ShellCheck in the devcontainer.
- Fix ShellCheck findings for all shell scripts.
- Add a simple `scripts/check.sh` that runs syntax checks and ShellCheck when
  available.

### Milestone 2: Safer Bootstrap Scripts

- Add `--help` and `--dry-run` to bootstrap scripts.
- Extract shared bootstrap helpers.
- Make dotfile and install paths configurable.
- Remove duplicated setup logic between base, dev, and devcontainer scripts.

### Milestone 3: Workflow Tooling

- Finish repo audit v2.
- Add bug bounty workspace templates and options.
- Consolidate weather alert installation and documentation.

### Milestone 4: Automation

- Add a lightweight CI workflow or local preflight script.
- Generate or update `reports/repo-audits/latest.md`.
- Add optional scheduled repo audit and weather alert setup docs.

## Guiding Principles

- Keep scripts readable Bash unless a tool grows complex enough to justify
  Python.
- Prefer idempotent setup over one-time installation assumptions.
- Make privileged, networked, or destructive operations obvious.
- Keep personal defaults, but expose enough configuration to reuse the repo on a
  fresh machine.
- Document workflow changes as part of completing them.
