# Repository Standards

These standards are intended for TC's Python, Bash, and application repositories. They keep projects easier to review, safer for agent-assisted work, and less likely to accumulate generated artifacts in Git.

## Required Project Files

Every repository should include:

- `README.md` with the project purpose, setup, common commands, and operational notes.
- `AGENTS.md` with repository-specific instructions for Codex and other AI agents.
- `.gitignore` tuned to the project stack and generated artifacts.
- `docs/codex-workflow.md` describing the local agent workflow.
- Example config files such as `.env.example` or `config.example.json` when local config is needed.

## Source Layout

Keep source and generated output clearly separated.

Recommended locations:

- `scripts/` for Bash and helper scripts.
- `src/` or the project package directory for application code.
- `tests/` for tests.
- `docs/` for committed documentation.
- `templates/` for reusable project templates.
- `reports/` for generated local reports, ignored by default.

Avoid placing generated files next to source unless the tool requires it. If generated files must live near source, document that behavior in `README.md` or `AGENTS.md`.

## Configuration

Track example configuration, not local secrets.

Track:

- `.env.example`
- `config.example.json`
- `settings.example.toml`
- Template files with placeholder values.

Do not track:

- `.env`
- `.env.local`
- Local config files with real tokens, API keys, hostnames, credentials, or personal paths.
- Generated logs or runtime state.

If a secret-bearing file has already been tracked, remove it from the Git index with `git rm --cached` and rotate the secret.

## Ignore Rules

`.gitignore` should be targeted and readable. Each section should explain what it ignores.

Prefer ignoring:

- Python bytecode and caches.
- Virtual environments.
- Dependency folders such as `node_modules/`.
- Logs and runtime state.
- Generated reports.
- Build and distribution output.
- Editor and OS metadata.

Avoid ignoring:

- `*.md`
- `*.json`
- `docs/`
- `scripts/`
- `templates/`
- `README.md`
- `AGENTS.md`
- `.devcontainer/`
- Example config files.

## Bash Standards

For Bash scripts:

- Use `#!/usr/bin/env bash` when portability matters.
- Use `set -euo pipefail` when the script is written to support it.
- Quote variable expansions unless word splitting is intentional.
- Prefer `git -C "$repo"` over changing directories for Git inspection.
- Keep host-mutating behavior explicit and documented.
- Run `bash -n script.sh` after edits.

## Python Standards

For Python projects:

- Keep virtual environments out of Git.
- Track dependency manifests such as `requirements.txt`, `pyproject.toml`, or lockfiles when the project uses them intentionally.
- Keep generated caches and coverage output ignored.
- Prefer project-local commands documented in `README.md`.
- Run existing tests or syntax checks after edits.

## App Repository Standards

For app repositories:

- Keep source, tests, docs, and build output separate.
- Ignore dependency folders and build output.
- Track lockfiles when they are part of the app's reproducible install workflow.
- Document required environment variables in `.env.example`.
- Do not commit generated screenshots, reports, coverage, or local database files unless explicitly required.

## Review Checklist

Before handing off work:

- Run `git status --short --ignored`.
- Run relevant syntax checks or tests.
- Review `git diff`.
- Confirm generated artifacts are ignored.
- List changed files.
- Call out tracked files that should be removed from the Git index.
- Suggest a commit message if the user asked for one.

