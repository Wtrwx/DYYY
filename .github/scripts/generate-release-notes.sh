#!/usr/bin/env bash

set -euo pipefail

notes_file="${1:-release-notes.md}"
head_sha="${GITHUB_SHA:-HEAD}"
repository="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')}"
server_url="${GITHUB_SERVER_URL:-https://github.com}"
zero_sha="0000000000000000000000000000000000000000"

features_file=$(mktemp)
improvements_file=$(mktemp)
fixes_file=$(mktemp)
trap 'rm -f "$features_file" "$improvements_file" "$fixes_file"' EXIT

is_plugin_file() {
    local path=$1

    case "$path" in
        DYYY.plist|Resources/*|layout/*)
            return 0
            ;;
    esac

    if [[ "$path" != */* ]]; then
        case "$path" in
            *.h|*.m|*.mm|*.x|*.xm|*.c|*.cc|*.cpp|*.s|*.S)
                return 0
                ;;
        esac
    fi

    return 1
}

commit_touches_plugin() {
    local hash=$1
    local path

    while IFS= read -r path; do
        if is_plugin_file "$path"; then
            return 0
        fi
    done < <(git diff-tree --root --no-commit-id --name-only -r "$hash")

    return 1
}

if [[ -n "${PUSH_BEFORE:-}" && "$PUSH_BEFORE" != "$zero_sha" ]] &&
   git cat-file -e "${PUSH_BEFORE}^{commit}" 2>/dev/null; then
    commit_range="${PUSH_BEFORE}..${head_sha}"
else
    previous_tag=$(git tag --list 'DYYY_*-build.*' --sort=-version:refname | head -n 1)
    if [[ -n "$previous_tag" ]]; then
        commit_range="${previous_tag}..${head_sha}"
    elif git rev-parse "${head_sha}^" >/dev/null 2>&1; then
        commit_range="${head_sha}^..${head_sha}"
    else
        commit_range="$head_sha"
    fi
fi

relevant_count=0

while IFS=$'\t' read -r hash subject; do
    [[ -n "$hash" ]] || continue

    parent_count=$(git rev-list --parents -n 1 "$hash" | awk '{ print NF - 1 }')
    if (( parent_count > 1 )) || ! commit_touches_plugin "$hash"; then
        continue
    fi

    relevant_count=$((relevant_count + 1))
    short_hash=${hash:0:8}
    entry="- **${subject}** ([\`${short_hash}\`](${server_url}/${repository}/commit/${hash}))"

    case "$subject" in
        新增*|增加*|添加*|支持*|引入*|实现*|feat:*|feat\(*|Feature*|Add*)
            printf '%s\n' "$entry" >> "$features_file"
            ;;
        修复*|解决*|恢复*|纠正*|fix:*|fix\(*|Fix*|Bugfix*)
            printf '%s\n' "$entry" >> "$fixes_file"
            ;;
        *)
            printf '%s\n' "$entry" >> "$improvements_file"
            ;;
    esac
done < <(git log --reverse --format=$'%H\t%s' "$commit_range")

cat > "$notes_file" <<EOF
# 更新日志

本次构建包含 ${relevant_count} 项插件功能变更，以下为详细更新内容：
EOF

append_section() {
    local title=$1
    local section_file=$2

    if [[ -s "$section_file" ]]; then
        printf '\n## %s\n\n' "$title" >> "$notes_file"
        cat "$section_file" >> "$notes_file"
    fi
}

append_section "新增功能" "$features_file"
append_section "体验优化与调整" "$improvements_file"
append_section "问题修复" "$fixes_file"

if (( relevant_count == 0 )); then
    printf '\n本次手动构建未检测到新的插件功能变更。\n' >> "$notes_file"
fi

cat >> "$notes_file" <<'EOF'

---

本 Release 包含 Rootful、Rootless 和 Roothide 三个 Deb 安装包。
EOF

cat "$notes_file"
