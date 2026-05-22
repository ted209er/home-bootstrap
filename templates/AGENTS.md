# Agent Instructions

## Scope

This repository may contain Python, Bash, application code, documentation, templates, and local tooling. Treat it as a source repository first: keep intentional project files visible and keep generated or local runtime files out of commits.

## Working Rules

- Read the relevant files before editing.
- Keep changes narrowly scoped to the user request.
- Prefer existing project patterns over new abstractions.
- Do not add dependencies, services, CI/CD, cron jobs, or systemd automation unless explicitly requested.
- Do not commit changes unless explicitly requested.
- Do not rewrite scripts or application structure unless that is the task.
- Preserve intentional project files such as `README.md`, `AGENTS.md`, `docs/`, `scripts/`, `.devcontainer/`, templates, source files, and example config files.
- Keep generated files, reports, logs, virtual environments, caches, build output, and local secrets out of commits.

## Safety Checks

- Run `git status --short --ignored` before summarizing work.
- For Bash scripts, run `bash -n path/to/script.sh` after edits.
- For Python changes, run the repository's existing test or lint command if one exists.
- For generated reports, verify they are ignored unless the user asks to keep them.
- For `.gitignore` changes, run `git status --ignored` and `git ls-files -i --exclude-standard`.
- Call out already-tracked generated or secret-bearing files that should be removed from the Git index with `git rm --cached`.

## Repository Hygiene

- Keep `.env.example`, `*.example.*`, and template files trackable.
- Treat `.env`, local config files, API keys, tokens, logs, and runtime state as private.
- Avoid broad ignore rules that hide source code, documentation, scripts, templates, or examples.
- Prefer generated-output directories such as `/reports/`, `/tmp/`, `/dist/`, or `/build/` over broad file-type ignores such as `*.md` or `*.json`.

