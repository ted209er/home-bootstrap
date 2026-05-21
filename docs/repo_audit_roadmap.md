# repo_audit.sh Roadmap

## Current State

`scripts/repo_audit.sh` is a compact Bash utility that scans repositories under `${REPOS_ROOT:-$HOME/Repos}` and writes a timestamped Markdown report under `${REPORT_DIR:-reports/repo-audits}`. It currently covers the core audit needs: repository discovery, clean/dirty state, current branch, upstream ahead/behind status, stale branch detection, and presence checks for `README.md` and `AGENTS.md`.

The script is useful as-is, but it mixes configuration, repository discovery, Git inspection, stale branch policy, and Markdown rendering in one flow. The next iteration should preserve the simple command-line experience while making the internals easier to test, extend, and reason about.

## Architectural Suggestions

- Keep Bash for the near term. The script is still small enough that Bash is reasonable, especially because the core work is shelling out to Git.
- Introduce a clear pipeline: load config, discover repos, audit each repo, render report, write report.
- Prefer `git -C "$repo_path"` over `pushd` and `popd`. This avoids ambient working-directory state and makes functions easier to test independently.
- Add argument parsing while preserving environment variable overrides. For example, support `--repos-root`, `--report-dir`, `--stale-days`, `--format`, and `--help`.
- Treat repo audit data as structured records internally. Bash can keep this simple at first, but the current single table row string makes later report formats harder.
- Add validation before scanning. `STALE_DAYS` should be a positive integer, `REPOS_ROOT` should exist, and `REPORT_DIR` should be creatable.
- Keep network-mutating behavior opt-in. Any future fetch/prune behavior should require an explicit flag such as `--fetch` or `--prune`.

## Modularization Ideas

Split the script into focused functions with narrow responsibilities:

```bash
load_config
parse_args
validate_config
discover_repos
audit_repo
render_markdown
write_report
```

Git inspection helpers should accept a repository path instead of assuming the current directory:

```bash
repo_branch "$repo_path"
repo_upstream "$repo_path"
repo_status "$repo_path"
repo_ahead_behind "$repo_path" "$upstream"
repo_default_branch "$repo_path"
repo_stale_branches "$repo_path" "$default_branch"
repo_file_presence "$repo_path" "README.md"
```

Rendering helpers should own Markdown-specific escaping and layout:

```bash
markdown_escape
render_header
render_summary
render_repo_table
render_stale_branch_details
render_findings
```

If the script grows beyond roughly 250-300 lines, consider moving to Python. Python would make structured records, tests, JSON output, date handling, and report rendering cleaner.

## Output Formatting Improvements

Add a summary section before the repository table:

```markdown
## Summary

- Repositories scanned: 12
- Dirty repositories: 3
- Repositories without upstream: 4
- Repositories behind remote: 1
- Repositories with stale local branches: 5
- Missing README.md: 2
- Missing AGENTS.md: 10
```

Keep the main table concise. The current `Stale Local Branches` cell can become very wide, so the table should show counts or short labels:

```markdown
| Repo | Status | Branch | Upstream | Sync | Stale Branches | README.md | AGENTS.md |
| --- | --- | --- | --- | --- | --- | --- | --- |
| home-bootstrap | Dirty | feature/devcontainer-setup | origin/feature/devcontainer-setup | Synced | 0 | Yes | No |
```

Move long branch details into separate sections:

```markdown
## Stale Branch Details

### tasty-algos

- `develop`: last commit 2025-07-08
- `feature/oauth-integration`: last commit 2025-12-03
- `release/0.1.0`: merged to `master`
```

Add action-oriented findings:

```markdown
## Findings

### Dirty Repositories

- `home-bootstrap`
- `tasty-algos`

### Missing Upstreams

- `mlb-pitchlab`: `develop`
- `war-room-de-tecolote`: `feature/sqlite-foundation`

### Missing Documentation

- `dotfiles_bootstrap`: missing `README.md`, `AGENTS.md`
```

Improve sync labels:

- `Synced`
- `Ahead by N`
- `Behind by N`
- `Diverged: ahead N / behind M`
- `No upstream`
- `Unknown`

Add optional output targets later:

- Markdown for human review
- JSON for automation
- CSV for spreadsheets

## Future Enhancement Roadmap

### Phase 1: Stabilize the Current Script

- Add `--help` output.
- Add config validation.
- Replace `pushd`/`popd` with `git -C`.
- Add summary metrics.
- Split stale branch details out of the main table.
- Classify dirty state into staged, unstaged, untracked, and conflicted changes.

### Phase 2: Improve Git Intelligence

- Detect detached HEAD and report the short commit SHA.
- Detect local branches without upstreams.
- Detect branches whose upstream was deleted.
- Detect branches merged into the default branch.
- Report how the default branch was selected: `origin/HEAD`, local `main`, local `master`, or fallback.
- Add optional `--fetch` and `--prune` modes for fresher remote data.

### Phase 3: Expand Repository Health Checks

- Check for common governance files: `LICENSE`, `CONTRIBUTING.md`, `.editorconfig`, `.gitignore`, and CI config.
- Detect project type from files such as `package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, and `go.mod`.
- Report dependency lockfile presence.
- Report common test commands when detectable.

### Phase 4: Add History and Automation

- Write or update `reports/repo-audits/latest.md`.
- Optionally keep historical timestamped reports.
- Add a comparison mode that shows changes since the previous report.
- Add a cron or systemd timer example.
- Add high-priority alerts for dirty repos, behind branches, or missing upstreams.

### Phase 5: Consider a Python Rewrite

Move to Python if the tool needs richer data structures, tests, multiple output formats, or report diffing. A possible layout:

```text
scripts/repo_audit.py
tests/test_repo_audit.py
docs/repo_audit_roadmap.md
reports/repo-audits/
```

## Security Considerations

- Do not run remote network operations by default. `git fetch`, `git remote update`, and pruning should be explicit because they contact remotes and mutate local remote-tracking refs.
- Treat repository names, branch names, and paths as untrusted output. Continue escaping Markdown table delimiters and consider escaping backticks if values are rendered inside code spans.
- Avoid evaluating Git-derived strings. Branch names and remote names should only be passed as quoted arguments, never interpolated into executable shell code.
- Be careful with report contents. Reports may expose local paths, branch names, project names, and work-in-progress repository state.
- Keep report output inside a predictable directory. Validate `REPORT_DIR` if user-provided, especially if later automation uploads or publishes reports.
- Avoid scanning outside the intended root by default. If symlink traversal is added later, document it and make it explicit.
- Keep authentication out of scope. The audit should not inspect credentials, GitHub tokens, or remote URLs with embedded secrets.
- If JSON or CSV output is added, preserve escaping rules for those formats rather than reusing Markdown escaping.

## Recommended Next Step

Refactor the Bash script without changing user-facing behavior: add config validation, convert Git helpers to `git -C`, and split rendering into summary, table, and detail sections. That gives the script a stronger structure while keeping it easy to run and easy to review.
