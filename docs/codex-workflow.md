# Codex Workflow

This document describes the recommended workflow for using Codex in this repository. The goal is to keep changes reviewable, avoid accidental runtime churn, and make generated artifacts easy to separate from source changes.

## Tmux Workflow

Use `tmux` for long-running local work so shell state is easy to recover.

```bash
tmux new -s home-bootstrap
```

Recommended panes:

- One pane for Codex or editor work.
- One pane for commands such as `git status`, syntax checks, and script runs.
- One pane for logs or generated report inspection when needed.

Useful commands:

```bash
tmux attach -t home-bootstrap
tmux new-window
tmux split-window -h
tmux split-window -v
```

Keep long-running or host-mutating commands visible in a tmux pane. Stop services or background commands before ending a task unless the user explicitly wants them left running.

## Branch Workflow

Work on a topic branch for repository hygiene or script changes.

```bash
git switch -c feature/descriptive-name
git status --short
```

Before editing, check the worktree for existing user changes. Do not revert unrelated files. If a task produces generated output, confirm whether it should be committed or ignored.

Keep commits focused by separating:

- Source or documentation changes.
- Generated reports.
- Runtime cleanup such as removing tracked virtual environments from the index.

This repository should not commit local reports, logs, virtual environments, caches, or secret-bearing config files.

## Codex Review Workflow

Start each Codex task by identifying the requested scope and the files likely to be affected. For this repository, prefer small, explicit changes over broad modernization.

Recommended review loop:

1. Run `git status --short --ignored`.
2. Read the relevant files before editing.
3. Make the smallest safe change.
4. Run targeted checks.
5. Review `git diff`.
6. Summarize changed files, verification, and any residual risks.

For shell scripts, run:

```bash
bash -n path/to/script.sh
```

For ignore-rule changes, run:

```bash
git status --ignored
git ls-files -i --exclude-standard
```

If `git ls-files -i --exclude-standard` reports tracked files, call them out. Do not remove them from the index unless the user asks.

## Report Generation Workflow

`scripts/repo_audit.sh` generates Markdown reports under `reports/repo-audits/`.

Typical flow:

```bash
bash -n scripts/repo_audit.sh
scripts/repo_audit.sh
git status --short --ignored
```

Generated reports are local review artifacts and should stay ignored by default. If a report needs to be shared, copy the relevant findings into a tracked document or commit the report only after an explicit user request.

When changing report generation, avoid adding JSON, CSV, fetch/prune behavior, automation, or new dependencies unless the user explicitly requests them.

## Recommended Safety Practices

- Treat local config files as secret-bearing unless proven otherwise.
- Keep `.env.example` and `*.example.*` files trackable.
- Avoid broad `.gitignore` rules that hide source, docs, templates, or intentional config examples.
- Prefer explicit generated-output directories such as `/reports/` over broad document ignores such as `*.md`.
- Do not run destructive Git commands such as `git reset --hard` or `git checkout --` without explicit user approval.
- Do not run network-mutating commands such as `git fetch`, package installs, or Docker installation unless the user asks and the environment permits it.
- Before finalizing, report what changed, what checks ran, and which already-tracked artifacts should be removed from the Git index.
