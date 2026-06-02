# home-bootstrap

## Devcontainer

Open this repository in VS Code or another devcontainer-compatible editor and rebuild the container from `.devcontainer/devcontainer.json`.

The container runs as the `ted209er` user. The post-create setup is noninteractive: it verifies the GitHub CLI is available and reports authentication status, but it does not run `gh auth login`.

By default, the devcontainer bind-mounts `${HOME}/.config/gh` from the host to `/home/ted209er/.config/gh` in the container. This lets `gh` reuse host authentication, but it also exposes the host GitHub CLI credentials to processes running inside the container. Remove the `mounts` entry in `.devcontainer/devcontainer.json` if you do not want host GitHub auth available in the container.

## Scripts

This repo contains personal workstation, devcontainer, repo maintenance, and
workflow helper scripts. Most scripts target Ubuntu or another Debian-like Linux
environment.

| Script | Purpose | Platform | Required tools | Mutates system or workspace |
| --- | --- | --- | --- | --- |
| `bootstrap.sh` | Baseline workstation setup with zsh, tmux, vim, neofetch, oh-my-zsh, zsh plugins, powerlevel10k, and dotfile symlinks. | Ubuntu/Debian-like Linux host | `bash`, `sudo`, `apt`, `git`, `curl` | Yes. Installs packages, clones dotfiles, creates symlinks, installs shell plugins, and may change the login shell. |
| `bootstrap_dev.sh` | Development workstation setup that extends the baseline with Python tooling and Docker. | Ubuntu/Debian-like Linux host with systemd for Docker service management | `bash`, `sudo`, `apt`, `git`, `curl`, `systemctl` | Yes. Installs packages, clones or updates dotfiles, creates symlinks, installs Docker, updates user groups, starts/enables Docker, and may change the login shell. |
| `.devcontainer/scripts/setup.sh` | Post-create setup for the devcontainer, mainly GitHub CLI availability/auth status and optional neofetch output. | Devcontainer built from `.devcontainer/Dockerfile` | `bash`, `sudo`, `apt-get`, `curl`, `gh` | Yes, inside the container only. May install GitHub CLI support packages and apt source configuration. |
| `scripts/repo_audit.sh` | Scans local repos and writes a Markdown repo health report. | Linux or macOS shell with Git | `bash`, `git`, `find`, `sort`, `date` | Yes, but only by creating report files under `${REPORT_DIR:-reports/repo-audits}`. It does not fetch, prune, or mutate scanned repositories. |
| `scripts/tmux_bugbounty.sh` | Creates or attaches to a five-pane bug bounty tmux workspace. | Linux or macOS shell with tmux | `bash`, `tmux`, `${EDITOR:-vi}` | Yes. Creates the requested workspace directory, starter subdirectories, starter files, and a tmux session. It does not run scans automatically. |
| `scripts/weather_alert.sh` | Simple weather alert check using `wttr.in`, `notify-send`, and `logger`. | Linux desktop/session environment | `bash`, `curl`, `tr`, `grep`, optional `notify-send`, `logger` | No persistent changes. It contacts `wttr.in` and may emit desktop/system log notifications. |
| `scripts/weather-alert/install_weather_alert.sh` | Installs the Python weather alert utility into a local virtualenv and schedules it in cron. | Linux host with cron | `bash`, `python3`, `python3-venv`, `pip`, `crontab` | Yes. Creates `scripts/weather-alert/venv`, installs Python requirements, and updates the user crontab. |

### Bootstrap Examples

Run the base workstation bootstrap:

```bash
./bootstrap.sh
```

Preview the base workstation bootstrap without making changes:

```bash
./bootstrap.sh --dry-run
```

Run the fuller development bootstrap:

```bash
./bootstrap_dev.sh
```

Preview the fuller development bootstrap without making changes:

```bash
./bootstrap_dev.sh --dry-run
```

Both bootstrap scripts perform package installation and other host-level setup.
Use `--help` to review supported options, and review the script body before
running on a new machine. They are intended to be repeatable: existing dotfile
symlinks are checked before replacement, existing oh-my-zsh plugins are skipped,
and Docker installation is skipped when Docker is already present.

### Repo Audit

Generate a Markdown report for repositories under `$HOME/Repos`:

```bash
scripts/repo_audit.sh
```

Override the scan root, report directory, or stale-branch threshold:

```bash
REPOS_ROOT="$HOME/Repos" REPORT_DIR="reports/repo-audits" STALE_DAYS=120 scripts/repo_audit.sh
```

### Bug Bounty tmux Workspace

Launch or attach to a prepared bug bounty workspace:

```bash
scripts/tmux_bugbounty.sh ~/recon/test-bounty-1
```

The launcher creates the workspace when needed, adds standard folders for notes,
findings, reports, screenshots, and data, then opens a five-pane tmux session.
The session name is based on the workspace directory name, such as
`bounty-test-bounty-1`.

### Weather Alerts

Run the lightweight shell weather alert check once:

```bash
scripts/weather_alert.sh
```

Install the Python weather alert utility and schedule it every 15 minutes with
cron:

```bash
scripts/weather-alert/install_weather_alert.sh
```

Preview the virtualenv, dependency, and crontab changes first:

```bash
scripts/weather-alert/install_weather_alert.sh --dry-run
```

The cron installer mutates the user crontab and installs Python dependencies
into `scripts/weather-alert/venv`. Repeated runs replace the managed weather
alert cron entry instead of duplicating it. Use `--help` to review supported
options.

### Shell Script Quality

Shell scripts should pass Bash syntax checks and ShellCheck. See
`docs/shell_script_standards.md` for the repo's shell scripting conventions and
validation commands.
