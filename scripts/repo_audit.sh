#!/usr/bin/env bash

set -u

repos_root="${REPOS_ROOT:-$HOME/Repos}"
report_dir="${REPORT_DIR:-reports/repo-audits}"
stale_days="${STALE_DAYS:-90}"
timestamp="$(date +"%Y%m%d-%H%M%S")"
report_file="${report_dir}/repo-audit-${timestamp}.md"

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

validate_config() {
    [ -n "$repos_root" ] || fail 'REPOS_ROOT must not be empty.'
    [ -d "$repos_root" ] || fail "REPOS_ROOT does not exist or is not a directory: $repos_root"

    [ -n "$report_dir" ] || fail 'REPORT_DIR must not be empty.'
    mkdir -p "$report_dir" 2>/dev/null || fail "REPORT_DIR could not be created: $report_dir"
    [ -d "$report_dir" ] || fail "REPORT_DIR is not a directory: $report_dir"
    [ -w "$report_dir" ] || fail "REPORT_DIR is not writable: $report_dir"

    case "$stale_days" in
        ''|*[!0-9]*)
            fail 'STALE_DAYS must be a positive integer.'
            ;;
    esac

    [ "$stale_days" -gt 0 ] || fail 'STALE_DAYS must be greater than zero.'
}

markdown_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//|/\\|}"
    value="${value//$'\n'/ }"
    printf '%s' "$value"
}

tracked_remote() {
    local repo_path="$1"
    git -C "$repo_path" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true
}

ahead_behind() {
    local repo_path="$1"
    local upstream="$2"

    if [ -z "$upstream" ]; then
        printf 'No upstream'
        return
    fi

    local counts
    counts="$(git -C "$repo_path" rev-list --left-right --count "${upstream}...HEAD" 2>/dev/null)" || {
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
    local repo_path="$1"

    if [ -z "$(git -C "$repo_path" status --porcelain=v1 2>/dev/null)" ]; then
        printf 'Clean'
    else
        printf 'Dirty'
    fi
}

current_branch() {
    local repo_path="$1"
    git -C "$repo_path" branch --show-current 2>/dev/null || true
}

default_branch() {
    local repo_path="$1"
    local remote_head
    remote_head="$(git -C "$repo_path" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"

    if [ -n "$remote_head" ]; then
        printf '%s' "${remote_head#origin/}"
        return
    fi

    if git -C "$repo_path" show-ref --verify --quiet refs/heads/main; then
        printf 'main'
    elif git -C "$repo_path" show-ref --verify --quiet refs/heads/master; then
        printf 'master'
    else
        git -C "$repo_path" branch --format='%(refname:short)' | head -n 1
    fi
}

stale_branches() {
    local repo_path="$1"
    local base_branch="$2"
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

        if [ -n "$upstream" ] && ! git -C "$repo_path" rev-parse --verify --quiet "$upstream" >/dev/null; then
            gone_flag=", upstream gone"
        fi

        if [ -n "$base_branch" ] && git -C "$repo_path" merge-base --is-ancestor "$branch" "$base_branch" 2>/dev/null; then
            merged_flag=", merged to ${base_branch}"
        fi

        if [ "$epoch" -lt "$stale_cutoff" ] || [ -n "$gone_flag" ] || [ -n "$merged_flag" ]; then
            branches+=("$(markdown_escape "${branch} ($(format_epoch_date "$epoch")${gone_flag}${merged_flag})")")
        fi
    done < <(git -C "$repo_path" for-each-ref refs/heads --format='%(refname:short)%09%(committerdate:unix)%09%(upstream:short)' 2>/dev/null)

    if [ "${#branches[@]}" -eq 0 ]; then
        printf 'None'
    else
        join_values ', ' "${branches[@]}"
    fi
}

behind_count() {
    local sync_status="$1"

    case "$sync_status" in
        ahead*" / behind "*)
            local behind="${sync_status##*behind }"
            [ "$behind" -gt 0 ] 2>/dev/null && printf '1' || printf '0'
            ;;
        *)
            printf '0'
            ;;
    esac
}

print_findings_group() {
    local heading="$1"
    shift

    [ "$#" -gt 0 ] || return

    printf '### %s\n\n' "$heading"
    printf '%s\n' "$@"
    printf '\n'
}

join_docs() {
    join_values ', ' "$@"
}

join_values() {
    local separator="$1"
    shift

    local result=""
    local value

    for value in "$@"; do
        if [ -z "$result" ]; then
            result="$value"
        else
            result="${result}${separator}${value}"
        fi
    done

    printf '%s' "$result"
}

validate_config

repo_rows=()
dirty_findings=()
missing_upstream_findings=()
behind_findings=()
stale_findings=()
missing_docs_findings=()

repos_scanned=0
dirty_repos=0
missing_upstreams=0
behind_repos=0
repos_with_stale_branches=0
missing_readmes=0
missing_agents=0

while IFS= read -r git_dir; do
    repo_path="$(dirname "$git_dir")"
    repo_name="$(basename "$repo_path")"

    if ! git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        continue
    fi

    repos_scanned=$((repos_scanned + 1))

    branch="$(current_branch "$repo_path")"
    [ -n "$branch" ] || branch="Detached HEAD"
    upstream="$(tracked_remote "$repo_path")"
    clean="$(git_cleanliness "$repo_path")"
    sync_status="$(ahead_behind "$repo_path" "$upstream")"
    base_branch="$(default_branch "$repo_path")"
    stale="$(stale_branches "$repo_path" "$base_branch")"

    readme="No"
    agents="No"
    missing_docs=()
    [ -f "$repo_path/README.md" ] && readme="Yes" || missing_docs+=("README.md")
    [ -f "$repo_path/AGENTS.md" ] && agents="Yes" || missing_docs+=("AGENTS.md")

    if [ "$clean" = "Dirty" ]; then
        dirty_repos=$((dirty_repos + 1))
        dirty_findings+=("- \`$(markdown_escape "$repo_name")\`")
    fi

    if [ -z "$upstream" ]; then
        missing_upstreams=$((missing_upstreams + 1))
        missing_upstream_findings+=("- \`$(markdown_escape "$repo_name")\`: \`$(markdown_escape "$branch")\`")
    fi

    if [ "$(behind_count "$sync_status")" -eq 1 ]; then
        behind_repos=$((behind_repos + 1))
        behind_findings+=("- \`$(markdown_escape "$repo_name")\`: $(markdown_escape "$sync_status")")
    fi

    if [ "$stale" != "None" ] && [ "$stale" != "Unable to calculate cutoff" ]; then
        repos_with_stale_branches=$((repos_with_stale_branches + 1))
        stale_findings+=("- \`$(markdown_escape "$repo_name")\`: $(markdown_escape "$stale")")
    fi

    if [ "$readme" = "No" ]; then
        missing_readmes=$((missing_readmes + 1))
    fi

    if [ "$agents" = "No" ]; then
        missing_agents=$((missing_agents + 1))
    fi

    if [ "${#missing_docs[@]}" -gt 0 ]; then
        missing_docs_list="$(join_docs "${missing_docs[@]}")"
        missing_docs_findings+=("- \`$(markdown_escape "$repo_name")\`: missing $(markdown_escape "$missing_docs_list")")
    fi

    repo_rows+=("| $(markdown_escape "$repo_name") | $(markdown_escape "$repo_path") | $(markdown_escape "$clean") | $(markdown_escape "$branch") | $(markdown_escape "$upstream") | $(markdown_escape "$sync_status") | $(markdown_escape "$stale") | $readme | $agents |")
done < <(find "$repos_root" -mindepth 2 -maxdepth 2 -type d -name .git | sort)

{
    printf '# Repo Audit\n\n'
    printf -- '- Generated: `%s`\n' "$(date -Iseconds)"
    printf -- '- Repos root: `%s`\n' "$repos_root"
    printf -- '- Stale branch threshold: `%s days`\n\n' "$stale_days"

    printf '## Summary\n\n'
    printf -- '- Repositories scanned: %s\n' "$repos_scanned"
    printf -- '- Dirty repositories: %s\n' "$dirty_repos"
    printf -- '- Repositories without upstream: %s\n' "$missing_upstreams"
    printf -- '- Repositories behind remote: %s\n' "$behind_repos"
    printf -- '- Repositories with stale local branches: %s\n' "$repos_with_stale_branches"
    printf -- '- Missing README.md: %s\n' "$missing_readmes"
    printf -- '- Missing AGENTS.md: %s\n\n' "$missing_agents"

    printf '## Repositories\n\n'
    printf '| Repo | Path | Status | Branch | Upstream | Ahead/Behind | Stale Local Branches | README.md | AGENTS.md |\n'
    printf '| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n'

    if [ "${#repo_rows[@]}" -eq 0 ]; then
        printf '| No repositories found | `%s` | - | - | - | - | - | - | - |\n\n' "$(markdown_escape "$repos_root")"
    else
        printf '%s\n' "${repo_rows[@]}"
        printf '\n'
    fi

    printf '## Findings\n\n'
    if [ "${#dirty_findings[@]}" -eq 0 ] &&
        [ "${#missing_upstream_findings[@]}" -eq 0 ] &&
        [ "${#behind_findings[@]}" -eq 0 ] &&
        [ "${#stale_findings[@]}" -eq 0 ] &&
        [ "${#missing_docs_findings[@]}" -eq 0 ]; then
        printf 'No findings.\n'
    else
        print_findings_group 'Dirty Repositories' "${dirty_findings[@]}"
        print_findings_group 'Missing Upstreams' "${missing_upstream_findings[@]}"
        print_findings_group 'Behind Remote' "${behind_findings[@]}"
        print_findings_group 'Stale Local Branches' "${stale_findings[@]}"
        print_findings_group 'Missing Documentation' "${missing_docs_findings[@]}"
    fi
} > "$report_file"

printf 'Wrote %s\n' "$report_file"
