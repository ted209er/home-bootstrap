# home-bootstrap

## Devcontainer

Open this repository in VS Code or another devcontainer-compatible editor and rebuild the container from `.devcontainer/devcontainer.json`.

The container runs as the `ted209er` user. The post-create setup is noninteractive: it verifies the GitHub CLI is available and reports authentication status, but it does not run `gh auth login`.

By default, the devcontainer bind-mounts `${HOME}/.config/gh` from the host to `/home/ted209er/.config/gh` in the container. This lets `gh` reuse host authentication, but it also exposes the host GitHub CLI credentials to processes running inside the container. Remove the `mounts` entry in `.devcontainer/devcontainer.json` if you do not want host GitHub auth available in the container.

## Scripts

### Bug Bounty tmux Workspace

Launch or attach to a prepared bug bounty workspace:

```bash
scripts/tmux_bugbounty.sh ~/recon/test-bounty-1
```

The launcher creates the workspace when needed, adds standard folders for notes,
findings, reports, screenshots, and data, then opens a five-pane tmux session.
The session name is based on the workspace directory name, such as
`bounty-test-bounty-1`.

### Shell Script Quality

Shell scripts should pass Bash syntax checks and ShellCheck. See
`docs/shell_script_standards.md` for the repo's shell scripting conventions and
validation commands.
