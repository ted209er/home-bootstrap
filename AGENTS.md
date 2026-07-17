# Repository Agent Guidance

## Scope and authority

Keep work bounded by the active home-bootstrap GitHub Issue and base issue
branches on `main`, the repository's integration branch. This repository owns
all of its tracked changes.

Use the existing documentation as the source of truth:

- `README.md` owns setup, bootstrap behavior, platform assumptions, and command
  usage.
- `docs/home_bootstrap_roadmap.md` owns product direction.
- `docs/repo_audit_roadmap.md` owns repo-audit design.
- `docs/shell_script_standards.md` owns shell quality, validation, privilege,
  and safety guidance.

Reference those documents instead of duplicating them. Update the relevant
authoritative document when an approved change alters its subject. The file at
`templates/AGENTS.md` is a reusable template for other repositories, not agent
guidance for this repository.

## Safety boundaries

Treat bootstrap scripts, installers, utilities, and devcontainer setup as
potentially machine-changing. Reading or statically checking source does not
authorize executing it. Do not run package managers, downloaded install
scripts, privileged commands, service or group management, login-shell or cron
changes, dotfile or symlink operations, workspace launchers, weather utilities,
repo-audit generation, or other host-mutating behavior unless the active issue
explicitly requires it and the user authorizes it.

Do not expose, copy, test, or include secrets or credentials in output. This
includes repository configuration values and host GitHub credentials made
available through the devcontainer mount described in `README.md`. Preserve
the repository's existing generated-file and runtime-artifact boundaries.

## Validation and review

Choose validation that matches the tracked change and report only checks that
were actually run. For shell source changes, follow
`docs/shell_script_standards.md`, including Bash syntax checks and ShellCheck.
For documentation or repository-configuration changes, use safe static checks
such as `git diff --check`, relevant ignore checks, manual documentation review,
and tracked-diff review. Do not execute machine-changing scripts merely to
validate documentation or workflow files.

Keep transient plans, findings, summaries, validation notes, and pull-request
drafts under ignored `.ted/`. Durable decisions and evidence belong in the
appropriate authoritative documentation, GitHub Issue, or Pull Request.
