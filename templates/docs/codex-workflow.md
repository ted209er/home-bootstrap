# Codex Workflow

This document describes a reusable workflow for using Codex in TC's repositories. The goal is to keep changes reviewable, protect local state, and separate source changes from generated artifacts.

## Tmux Workflow

Use `tmux` for long-running work so shell state can survive disconnects and interruptions.

```bash
tmux new -s project-name
```

Recommended panes:

- One pane for Codex or editor work.
- One pane for commands such as `git status`, tests, syntax checks, and script runs.
- One pane for logs, generated reports, or server output when needed.

Useful commands:

```bash
tmux attach -t project-name
tmux new-window
tmux split-window -h
tmux split-window -v
```

Keep long-running servers, logs, and host-mutating commands visible in a tmux pane. Stop background commands before ending a task unless the user explicitly wants them left running.

## Branch Workflow

Work on a topic branch for each focused change.

```bash
git switch -c feature/descriptive-name
git status --short
```

Before editing, inspect the worktree for existing user changes. Do not revert unrelated changes. If a task produces generated output, confirm whether it should be committed or ignored.

Keep commits focused by separating:

- Source or documentation changes.
- Generated reports or build output.
- Runtime cleanup such as removing tracked caches, logs, local config, or virtual environments from the Git index.

Do not commit local reports, logs, virtual environments, caches, dependency folders, or secret-bearing config files.

## Codex Review Workflow

Start each task by identifying the requested scope and the files likely to be affected. Prefer small, explicit changes over broad modernization.

Recommended loop:

1. Run `git status --short --ignored`.
2. Read relevant files before editing.
3. Make the smallest safe change.
4. Run targeted checks.
5. Review `git diff`.
6. Summarize changed files, verification, and residual risks.

For Bash scripts, run:

```bash
bash -n path/to/script.sh
```

For Python changes, use the existing project command when present:

```bash
pytest
ruff check .
python -m compileall path/to/package
```

For ignore-rule changes, run:

```bash
git status --ignored
git ls-files -i --exclude-standard
```

If `git ls-files -i --exclude-standard` reports tracked files, call them out. Do not remove them from the index unless the user asks.

## Report Generation Workflow

Generated reports should be treated as local review artifacts unless the project explicitly tracks them.

Typical flow:

```bash
bash -n scripts/repo_audit.sh
scripts/repo_audit.sh
git status --short --ignored
```

Store generated reports under a predictable ignored directory such as `reports/`. If a report needs to be shared, copy the relevant findings into a tracked document or commit the report only after an explicit request.

When changing report generation, avoid adding new formats, network behavior, automation, or dependencies unless explicitly requested.

## Recommended Safety Practices

- Treat local config files as secret-bearing unless proven otherwise.
- Keep `.env.example`, `*.example.*`, and template files trackable.
- Avoid broad `.gitignore` rules that hide source, docs, scripts, or intentional config examples.
- Prefer explicit generated-output directories over broad document or config ignores.
- Do not run destructive Git commands such as `git reset --hard` or `git checkout --` without explicit approval.
- Do not run network-mutating commands such as `git fetch`, package installs, migrations, deploys, or Docker installation unless the user asks and the environment permits it.
- Before finalizing, report what changed, what checks ran, and which already-tracked artifacts should be removed from the Git index.

