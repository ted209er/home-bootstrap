#!/usr/bin/env bash

set -u

repos_root="${REPOS_ROOT:-$HOME/Repos}"
report_dir="${REPORT_DIR:-reports/repo-audits}"
timestamp="$(date +"%Y%m%d-%H%M%S")"
report_file="${report_dir}/repo-audit-${timestamp}.md"
stale_days="${STALE_DAYS:-90}"

mkdir -p "$report_dir"

markdown_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//|/\\|}"
    value="${value//$'\n'/ }"
    printf '%s' "$value"
}

tracked_remote() {
    git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true
}

ahead_behind() {
    local upstream="$1"

    if [ -z "$upstream" ]; then
        printf 'No upstream'
        return
    fi

    local counts
    counts="$(git rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null)" || {
        printf 'Unknown'
        return
    }

    local behind ahead
    behind="${counts%%[[:space:]]*}"
    ahead="${counts##*[[:space:]]}"
    printf 'ahead %s / behind %s' "$ahead" "$behind"
}

format_epoch_date() {
    local epoch="$1"
    date -d "@${epoch}" +"%Y-%m-%d" 2>/dev/null || date -r "$epoch" +"%Y-%m-%d" 2>/dev/null || printf '%s' "$epoch"
}

git_cleanliness() {
    if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
        printf 'Clean'
    else
        printf 'Dirty'
    fi
}

current_branch() {
    git branch --show-current 2>/dev/null || true
}

default_branch() {
    local remote_head
    remote_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"

    if [ -n "$remote_head" ]; then
        printf '%s' "${remote_head#origin/}"
        return
    fi

    if git show-ref --verify --quiet refs/heads/main; then
        printf 'main'
    elif git show-ref --verify --quiet refs/heads/master; then
        printf 'master'
    else
        git branch --format='%(refname:short)' | head -n 1
    fi
}

stale_branches() {
    local base_branch="$1"
    local stale_cutoff
    stale_cutoff="$(date -d "${stale_days} days ago" +%s 2>/dev/null || date -v-"${stale_days}"d +%s 2>/dev/null || true)"

    if [ -z "$stale_cutoff" ]; then
        printf 'Unable to calculate cutoff'
        return
    fi

    local branches=()
    local branch epoch upstream gone_flag merged_flag

    while IFS=$'\t' read -r branch epoch upstream; do
        [ -n "$branch" ] || continue
        [ "$branch" = "$base_branch" ] && continue

        gone_flag=""
        merged_flag=""

        if [ -n "$upstream" ] && ! git rev-parse --verify --quiet "$upstream" >/dev/null; then
            gone_flag=", upstream gone"
        fi

        if [ -n "$base_branch" ] && git merge-base --is-ancestor "$branch" "$base_branch" 2>/dev/null; then
            merged_flag=", merged to ${base_branch}"
        fi

        if [ "$epoch" -lt "$stale_cutoff" ] || [ -n "$gone_flag" ] || [ -n "$merged_flag" ]; then
            branches+=("$(markdown_escape "${branch} ($(format_epoch_date "$epoch")${gone_flag}${merged_flag})")")
        fi
    done < <(git for-each-ref refs/heads --format='%(refname:short)%09%(committerdate:unix)%09%(upstream:short)' 2>/dev/null)

    if [ "${#branches[@]}" -eq 0 ]; then
        printf 'None'
    else
        local IFS=', '
        printf '%s' "${branches[*]}"
    fi
}

repo_rows=()

if [ -d "$repos_root" ]; then
    while IFS= read -r git_dir; do
        repo_path="$(dirname "$git_dir")"
        repo_name="$(basename "$repo_path")"

        if ! git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            continue
        fi

        pushd "$repo_path" >/dev/null || continue

        branch="$(current_branch)"
        [ -n "$branch" ] || branch="Detached HEAD"
        upstream="$(tracked_remote)"
        clean="$(git_cleanliness)"
        sync_status="$(ahead_behind "$upstream")"
        base_branch="$(default_branch)"
        stale="$(stale_branches "$base_branch")"

        readme="No"
        agents="No"
        [ -f README.md ] && readme="Yes"
        [ -f AGENTS.md ] && agents="Yes"

        repo_rows+=("| $(markdown_escape "$repo_name") | $(markdown_escape "$repo_path") | $(markdown_escape "$clean") | $(markdown_escape "$branch") | $(markdown_escape "$upstream") | $(markdown_escape "$sync_status") | $(markdown_escape "$stale") | $readme | $agents |")

        popd >/dev/null || exit 1
    done < <(find "$repos_root" -mindepth 2 -maxdepth 2 -type d -name .git | sort)
fi

{
    printf '# Repo Audit\n\n'
    printf -- "- Generated: \`%s\`\n" "$(date -Iseconds)"
    printf -- "- Repos root: \`%s\`\n" "$repos_root"
    printf -- "- Stale branch threshold: \`%s days\`\n\n" "$stale_days"

    printf '| Repo | Path | Status | Branch | Upstream | Ahead/Behind | Stale Local Branches | README.md | AGENTS.md |\n'
    printf '| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n'

    if [ "${#repo_rows[@]}" -eq 0 ]; then
        printf "| No repositories found | \`%s\` | - | - | - | - | - | - | - |\n" "$repos_root"
    else
        printf '%s\n' "${repo_rows[@]}"
    fi
} > "$report_file"

printf 'Wrote %s\n' "$report_file"
