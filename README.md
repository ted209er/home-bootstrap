# home-bootstrap

## Devcontainer

Open this repository in VS Code or another devcontainer-compatible editor and rebuild the container from `.devcontainer/devcontainer.json`.

The container runs as the `ted209er` user. The post-create setup is noninteractive: it verifies the GitHub CLI is available and reports authentication status, but it does not run `gh auth login`.

By default, the devcontainer bind-mounts `${HOME}/.config/gh` from the host to `/home/ted209er/.config/gh` in the container. This lets `gh` reuse host authentication, but it also exposes the host GitHub CLI credentials to processes running inside the container. Remove the `mounts` entry in `.devcontainer/devcontainer.json` if you do not want host GitHub auth available in the container.
