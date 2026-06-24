#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${script_dir}/build-relevance.sh"

notes_file="${1:-release-notes.md}"
head_sha="${RELEASE_HEAD_SHA:-${GITHUB_SHA:-HEAD}}"
repository="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')}"
server_url="${GITHUB_SERVER_URL:-https://github.com}"
release_title="${RELEASE_TITLE:-Release}"

feat_file=$(mktemp)
fix_file=$(mktemp)
perf_file=$(mktemp)
refactor_file=$(mktemp)
docs_file=$(mktemp)
style_file=$(mktemp)
chore_file=$(mktemp)
revert_file=$(mktemp)
records_file=$(mktemp)
skip_file=$(mktemp)
contributors_file=$(mktemp)
groups_file=$(mktemp)
trap 'rm -f "$feat_file" "$fix_file" "$perf_file" "$refactor_file" "$docs_file" "$style_file" "$chore_file" "$revert_file" "$records_file" "$skip_file" "$contributors_file" "$groups_file"' EXIT

trim_text() {
    local value=$1

    printf '%s' "$value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

strip_commit_type_prefix() {
    local subject=$1
    local commit_prefix_regex='^[A-Za-z]+(\([^)]+\))?(!)?[:：][[:space:]]*(.*)$'

    if [[ "$subject" =~ $commit_prefix_regex ]]; then
        subject=${BASH_REMATCH[3]}
    fi

    trim_text "$subject"
}

raw_commit_type() {
    local subject=$1
    local raw_type
    local commit_type_regex='^([A-Za-z]+)(\([^)]+\))?(!)?[:：]'

    if [[ "$subject" =~ $commit_type_regex ]]; then
        raw_type=${BASH_REMATCH[1]}
        printf '%s' "$raw_type" | tr '[:upper:]' '[:lower:]'
        return
    fi

    printf ''
}

canonical_commit_type() {
    local subject=$1
    local raw_type

    raw_type=$(raw_commit_type "$subject")
    case "$raw_type" in
        feat|feature|add)
            printf 'feat'
            return
            ;;
        fix|bug|bugfix)
            printf 'fix'
            return
            ;;
        perf|performance)
            printf 'perf'
            return
            ;;
        refactor)
            printf 'refactor'
            return
            ;;
        docs|doc)
            printf 'docs'
            return
            ;;
        style|format)
            printf 'style'
            return
            ;;
        chore|build|ci|test|merge)
            printf 'chore'
            return
            ;;
        revert)
            printf 'revert'
            return
            ;;
    esac

    case "$subject" in
        Revert\ *|revert:*|revert：*|回滚*|撤销*)
            printf 'revert'
            ;;
        新增*|增加*|添加*|支持*|引入*|实现*)
            printf 'feat'
            ;;
        修复*|解决*|恢复*|纠正*|*修复*)
            printf 'fix'
            ;;
        性能*|提速*|加速*|*性能*优化*|*速度*优化*|*加载*优化*)
            printf 'perf'
            ;;
        重构*|简化*|清理*|整理*|调整*|优化*|完善*)
            printf 'refactor'
            ;;
        文档*|README*|readme*|注释*|更新版本号*|版本更新*)
            printf 'docs'
            ;;
        格式*|格式化*)
            printf 'style'
            ;;
        *)
            printf 'chore'
            ;;
    esac
}

version_summary_for_commit() {
    local hash=$1
    local previous_version
    local current_version

    previous_version=$(
        git show "${hash}^:control" 2>/dev/null |
            awk -F': ' '$1 == "Version" { print $2; exit }' || true
    )
    current_version=$(
        git show "${hash}:control" 2>/dev/null |
            awk -F': ' '$1 == "Version" { print $2; exit }' || true
    )

    if [[ -n "$current_version" && "$previous_version" != "$current_version" ]]; then
        if [[ -n "$previous_version" ]]; then
            printf '更新版本号：`%s` → `%s`' "$previous_version" "$current_version"
        else
            printf '设置版本号为 `%s`' "$current_version"
        fi
    fi
}

keyword_content_for_subject() {
    local subject=$1
    local commit_type=$2

    case "$subject" in
        *清屏隐藏清屏按钮*)
            printf '清屏按钮隐藏选项'
            ;;
        *清屏隐藏暂停图标*|*暂停图标*)
            if [[ "$commit_type" == "feat" ]]; then
                printf '清屏暂停图标隐藏选项'
            else
                printf '清屏暂停图标显示状态'
            fi
            ;;
        *暂停按钮*)
            if [[ "$commit_type" == "feat" ]]; then
                printf '清屏暂停按钮隐藏选项'
            else
                printf '清屏暂停按钮显示状态'
            fi
            ;;
        *贴边效果*)
            printf '隐藏按钮贴边效果'
            ;;
        *倍速按钮*不显示*|*倍速按钮可能不显示*)
            printf '倍速按钮显示状态'
            ;;
        *倍数悬浮按钮*数字*|*倍速悬浮按钮*数字*)
            printf '倍速悬浮按钮数字恢复状态'
            ;;
        *系统状态栏*|*隐藏状态栏*|*隐藏系统状态栏*)
            if [[ "$commit_type" == "feat" ]]; then
                printf '清屏状态栏隐藏功能'
            else
                printf '清屏状态栏隐藏状态'
            fi
            ;;
        *右侧图标*|*收藏*)
            printf '清屏恢复后的右侧图标显示'
            ;;
        *头像下加号*)
            printf '头像加号替代入口隐藏逻辑'
            ;;
        *圆形底板*)
            printf '头像入口圆形底板隐藏'
            ;;
        *打印所有视图*|*视图的接口*)
            printf '视图调试接口'
            ;;
        *Release*|*release*)
            printf 'Release 更新日志'
            ;;
        *dylib*|*Dylib*)
            printf 'dylib 发布产物'
            ;;
        *Deb*|*deb*)
            printf 'Deb 构建产物'
            ;;
    esac
}

feature_group_for_subject() {
    local subject=$1

    case "$subject" in
        *快捷倍速*|*倍速侧边*|*倍速锁定*|*倍速长按*|*倍速设置*|*倍速悬浮*|*倍速按钮*)
            printf '快捷倍速'
            ;;
        *隐藏头像及周边*|*头像加号*|*圆形底板*)
            printf '隐藏头像及周边'
            ;;
        *推荐音乐过滤*|*推荐低赞过滤*|*搜索视频广告*|*推荐特效*|*合集*广告*)
            printf '推荐流过滤'
            ;;
    esac
}

summarize_commit_title() {
    local hash=$1
    local subject=$2
    local commit_type=$3
    local content
    local version_summary
    local revert_regex='^Revert[[:space:]]+"(.*)"$'
    local keyword_content

    if commit_touches_control "$hash"; then
        version_summary=$(version_summary_for_commit "$hash")
        if [[ -n "$version_summary" ]]; then
            printf '%s' "$version_summary"
            return
        fi
    fi

    if commit_touches_path "$hash" "Makefile" &&
       ! commit_touches_direct_build_path "$hash"; then
        printf '调整 Deb 构建配置'
        return
    fi

    content=$(strip_commit_type_prefix "$subject")
    content=$(printf '%s' "$content" | sed -E 's/[[:space:]。；;，,]+$//')

    if [[ "$commit_type" == "revert" && "$content" =~ $revert_regex ]]; then
        content=$(strip_commit_type_prefix "${BASH_REMATCH[1]}")
    fi

    keyword_content=$(keyword_content_for_subject "$subject" "$commit_type")
    if [[ -n "$keyword_content" ]]; then
        content=$keyword_content
    fi

    case "$commit_type" in
        feat)
            content=$(printf '%s' "$content" | sed -E 's/^(新增|增加|添加|支持|引入|实现|优化)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '新增%s' "${content:-插件功能}"
            ;;
        fix)
            content=$(printf '%s' "$content" | sed -E 's/^(兜底修复|修复|解决|恢复|纠正|修改|调整)[[:space:]:：]*//; s/的问题$//')
            content=$(printf '%s' "$content" | sed -E 's/不生效/生效异常/g; s/失效/异常/g; s/无法/不能/g')
            content=$(trim_text "$content")
            printf '修正%s' "${content:-已知问题}"
            ;;
        perf)
            content=$(printf '%s' "$content" | sed -E 's/^(性能优化|优化|提升|改善|提速|加速)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '优化%s' "${content:-运行性能}"
            ;;
        refactor)
            content=$(printf '%s' "$content" | sed -E 's/^(重构|简化|清理|整理|调整|优化|完善)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '整理%s' "${content:-代码结构}"
            ;;
        docs)
            content=$(printf '%s' "$content" | sed -E 's/^(文档|更新|修改|补充)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '更新%s' "${content:-文档说明}"
            ;;
        style)
            content=$(printf '%s' "$content" | sed -E 's/^(格式化|格式|规范|调整)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '规范%s' "${content:-代码格式}"
            ;;
        revert)
            content=$(printf '%s' "$content" | sed -E 's/^(回滚|撤销|取消)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '回滚%s' "${content:-上一项变更}"
            ;;
        *)
            content=$(printf '%s' "$content" | sed -E 's/^(杂项|其他|更新|调整|同步)[[:space:]:：]*//')
            content=$(trim_text "$content")
            printf '调整%s' "${content:-构建与维护项}"
            ;;
    esac
}

normalize_group_text() {
    local value=$1

    value=$(strip_commit_type_prefix "$value")
    value=$(printf '%s' "$value" |
        sed -E 's/^(新增|增加|添加|支持|引入|实现|兜底修复|修复|解决|恢复|纠正|修改|调整|优化|完善|重构|简化|清理|整理|更新|规范|回滚|撤销|取消)[[:space:]:：]*//')
    value=$(printf '%s' "$value" |
        sed -E 's/(相关功能|相关问题|相关逻辑|相关配置|已知问题|的问题|问题|异常|失效|漏放|不能|闪退|逻辑|功能|选项|状态|改动|变更|同步|显示|隐藏|判定|配置|结构)$//')
    value=$(printf '%s' "$value" |
        tr -d '[:space:]' |
        sed -E 's/[[:punct:]，。；：“”"'\''（）()、]//g')

    printf '%s' "$value"
}

summary_group_key() {
    local hash=$1
    local subject=$2
    local commit_type=$3
    local summary_title=$4
    local feature_group
    local keyword_content
    local normalized

    if commit_touches_control "$hash"; then
        printf 'version:版本号'
        return
    fi

    if commit_touches_path "$hash" "Makefile" &&
       ! commit_touches_direct_build_path "$hash"; then
        printf 'build:Deb 构建配置'
        return
    fi

    feature_group=$(feature_group_for_subject "$subject")
    if [[ -n "$feature_group" ]]; then
        printf 'feature:%s' "$feature_group"
        return
    fi

    keyword_content=$(keyword_content_for_subject "$subject" "$commit_type")
    if [[ -n "$keyword_content" ]]; then
        printf 'keyword:%s' "$keyword_content"
        return
    fi

    normalized=$(normalize_group_text "$summary_title")
    if [[ -n "$normalized" ]]; then
        printf 'text:%s' "$normalized"
        return
    fi

    printf 'hash:%s' "$hash"
}

section_file_for_type() {
    case "$1" in
        feat) printf '%s' "$feat_file" ;;
        fix) printf '%s' "$fix_file" ;;
        perf) printf '%s' "$perf_file" ;;
        refactor) printf '%s' "$refactor_file" ;;
        docs) printf '%s' "$docs_file" ;;
        style) printf '%s' "$style_file" ;;
        revert) printf '%s' "$revert_file" ;;
        *) printf '%s' "$chore_file" ;;
    esac
}

reverted_commit_hash() {
    local hash=$1
    local body
    local target_hash
    local resolved_hash

    body=$(git show -s --format=%B "$hash")
    target_hash=$(printf '%s\n' "$body" |
        sed -nE 's/^This reverts commit ([0-9a-fA-F]{7,40})\.$/\1/p' |
        head -n 1)

    if [[ -z "$target_hash" ]]; then
        target_hash=$(printf '%s\n' "$body" |
            grep -Eoi '[0-9a-f]{7,40}' |
            head -n 1 || true)
    fi

    if [[ -z "$target_hash" ]]; then
        return
    fi

    resolved_hash=$(git rev-parse --verify "${target_hash}^{commit}" 2>/dev/null || true)
    printf '%s' "${resolved_hash:-$target_hash}"
}

record_hash_for() {
    local target_hash=$1

    awk -F $'\t' -v target="$target_hash" '
        $1 == target || index($1, target) == 1 || index(target, $1) == 1 {
            print $1
            exit
        }
    ' "$records_file"
}

reverted_subject_from_title() {
    local subject=$1
    local revert_regex='^Revert[[:space:]]+"(.*)"$'

    if [[ "$subject" =~ $revert_regex ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return
    fi

    case "$subject" in
        回滚*|撤销*|取消*)
            printf '%s' "$subject" | sed -E 's/^(回滚|撤销|取消)[[:space:]:：]*//'
            ;;
    esac
}

normalize_revert_match_text() {
    local value=$1

    value=$(strip_commit_type_prefix "$value")
    value=$(printf '%s' "$value" |
        sed -E 's/^(新增|增加|添加|支持|引入|实现|修复|解决|恢复|纠正|修改|调整|优化|完善|重构|简化|清理|整理)[[:space:]:：]*//')
    value=$(printf '%s' "$value" |
        sed -E 's/(的问题|问题|逻辑|优化|功能|选项|状态|改动|变更|同步|显示|隐藏|判定|异常|失效|不能|闪退)$//')
    value=$(printf '%s' "$value" |
        tr -d '[:space:]' |
        sed -E 's/[[:punct:]，。；：“”"'\''（）()、]//g')

    printf '%s' "$value"
}

revert_key_matches_candidate() {
    local target_key=$1
    local candidate_key=$2

    [[ -n "$target_key" && -n "$candidate_key" ]] || return 1

    if [[ "$target_key" == "$candidate_key" ]]; then
        return 0
    fi

    if (( ${#target_key} >= 6 && ${#candidate_key} >= 6 )); then
        [[ "$target_key" == *"$candidate_key"* || "$candidate_key" == *"$target_key"* ]]
        return
    fi

    return 1
}

mark_skip_pair() {
    local revert_hash=$1
    local target_hash=$2

    printf '%s\n%s\n' "$revert_hash" "$target_hash" >> "$skip_file"
}

detect_same_range_reverts() {
    local hash
    local subject
    local commit_type
    local target_hash
    local matched_hash
    local target_subject
    local target_key
    local candidate_hash
    local candidate_subject
    local candidate_type
    local candidate_key

    while IFS=$'\t' read -r hash subject commit_type; do
        [[ -n "$hash" ]] || continue
        [[ "$commit_type" == "revert" ]] || continue

        target_hash=$(reverted_commit_hash "$hash")
        matched_hash=""
        if [[ -n "$target_hash" ]]; then
            matched_hash=$(record_hash_for "$target_hash")
        fi
        if [[ -n "$matched_hash" ]]; then
            mark_skip_pair "$hash" "$matched_hash"
            continue
        fi

        target_subject=$(reverted_subject_from_title "$subject")
        target_key=$(normalize_revert_match_text "$target_subject")
        if [[ -z "$target_key" || "${#target_key}" -lt 6 ]]; then
            continue
        fi

        while IFS=$'\t' read -r candidate_hash candidate_subject candidate_type; do
            [[ -n "$candidate_hash" ]] || continue
            [[ "$candidate_hash" == "$hash" ]] && continue
            git merge-base --is-ancestor "$candidate_hash" "$hash" 2>/dev/null || continue

            candidate_key=$(normalize_revert_match_text "$candidate_subject")
            if revert_key_matches_candidate "$target_key" "$candidate_key"; then
                mark_skip_pair "$hash" "$candidate_hash"
                break
            fi
        done < "$records_file"
    done < "$records_file"
}

commit_is_skipped() {
    local hash=$1

    awk -v target="$hash" '
        $1 == target || index($1, target) == 1 || index(target, $1) == 1 {
            found = 1
        }
        END {
            exit found ? 0 : 1
        }
    ' "$skip_file"
}

group_label() {
    local group_key=$1

    printf '%s' "${group_key#*:}"
}

aggregate_group_title() {
    local commit_type=$1
    local group_key=$2
    local titles_file=$3
    local title_count=$4
    local label

    if (( title_count <= 1 )); then
        head -n 1 "$titles_file"
        return
    fi

    label=$(group_label "$group_key")
    case "$label" in
        版本号)
            printf '更新版本号'
            return
            ;;
        Deb\ 构建配置)
            printf '调整 Deb 构建配置'
            return
            ;;
    esac

    case "$commit_type" in
        feat)
            printf '新增%s相关功能' "$label"
            ;;
        fix)
            printf '修正%s相关问题' "$label"
            ;;
        perf)
            printf '优化%s运行表现' "$label"
            ;;
        refactor)
            printf '整理%s相关逻辑' "$label"
            ;;
        docs)
            printf '更新%s相关说明' "$label"
            ;;
        style)
            printf '规范%s相关格式' "$label"
            ;;
        revert)
            printf '回滚%s相关变更' "$label"
            ;;
        *)
            printf '调整%s相关配置' "$label"
            ;;
    esac
}

append_grouped_entries_for_type() {
    local commit_type=$1
    local section_file=$2
    local group_key
    local title
    local hash
    local short_hash
    local title_count
    local hash_links
    local summary_title
    local titles_file

    while IFS= read -r group_key; do
        [[ -n "$group_key" ]] || continue

        titles_file=$(mktemp)
        hash_links=""
        while IFS=$'\t' read -r title hash; do
            [[ -n "$hash" ]] || continue
            if ! grep -Fxq "$title" "$titles_file"; then
                printf '%s\n' "$title" >> "$titles_file"
            fi

            short_hash=${hash:0:8}
            if [[ -n "$hash_links" ]]; then
                hash_links+=", "
            fi
            hash_links+="[\`${short_hash}\`](${server_url}/${repository}/commit/${hash})"
        done < <(
            awk -F $'\t' -v type="$commit_type" -v key="$group_key" '
                $1 == type && $2 == key { print $3 "\t" $4 }
            ' "$groups_file"
        )

        title_count=$(awk 'NF { count++ } END { print count + 0 }' "$titles_file")
        summary_title=$(aggregate_group_title "$commit_type" "$group_key" "$titles_file" "$title_count")
        rm -f "$titles_file"

        if [[ -n "$summary_title" && -n "$hash_links" ]]; then
            printf -- '- `%s` **%s** (%s)\n' "$commit_type" "$summary_title" "$hash_links" >> "$section_file"
        fi
    done < <(
        awk -F $'\t' -v type="$commit_type" '
            $1 == type && !seen[$2]++ { print $2 }
        ' "$groups_file"
    )
}

commit_touches_control() {
    local hash=$1

    commit_touches_path "$hash" "control"
}

latest_release_tag() {
    local latest_tag

    if ! command -v gh >/dev/null 2>&1 ||
       [[ -z "${GH_TOKEN:-}" || -z "$repository" ]]; then
        return
    fi

    latest_tag=$(gh api "repos/${repository}/releases/latest" \
        --jq '.tag_name // empty' 2>/dev/null || true)
    printf '%s' "$latest_tag"
}

tag_points_to_commit() {
    local tag=$1

    git cat-file -e "${tag}^{commit}" 2>/dev/null
}

ensure_release_tag_available() {
    local tag=$1

    if tag_points_to_commit "$tag"; then
        return 0
    fi

    git fetch --force --no-tags origin "refs/tags/${tag}:refs/tags/${tag}" \
        >/dev/null 2>&1 || return 1
    tag_points_to_commit "$tag"
}

contributor_for_commit() {
    local hash=$1
    local author_email
    local github_login
    local noreply_with_id='^[0-9]+\+([^@]+)@users\.noreply\.github\.com$'
    local noreply_plain='^([^@]+)@users\.noreply\.github\.com$'

    if command -v gh >/dev/null 2>&1 &&
       [[ -n "${GH_TOKEN:-}" && -n "$repository" ]]; then
        github_login=$(gh api "repos/${repository}/commits/${hash}" \
            --jq '.author.login // .committer.login // empty' 2>/dev/null || true)
        if [[ -n "$github_login" ]]; then
            printf '@%s' "$github_login"
            return
        fi
    fi

    author_email=$(git show -s --format=%ae "$hash")

    if [[ "$author_email" =~ $noreply_with_id ]]; then
        printf '@%s' "${BASH_REMATCH[1]}"
        return
    fi
    if [[ "$author_email" =~ $noreply_plain ]]; then
        printf '@%s' "${BASH_REMATCH[1]}"
        return
    fi
}

record_contributor_for_commit() {
    local hash=$1
    local contributor

    contributor=$(contributor_for_commit "$hash")
    if [[ -n "$contributor" ]] &&
       ! grep -Fxq -- "$contributor" "$contributors_file"; then
        printf '%s\n' "$contributor" >> "$contributors_file"
    fi
}

previous_tag=$(latest_release_tag)
if [[ -n "$previous_tag" ]] &&
   ! ensure_release_tag_available "$previous_tag"; then
    previous_tag=""
fi

if [[ -z "$previous_tag" ]]; then
    previous_tag=$(git tag --list 'DYYY_*' --sort=-version:refname | head -n 1)
fi

if [[ -n "$previous_tag" ]] &&
   ! tag_points_to_commit "$previous_tag"; then
    previous_tag=""
fi

if [[ -n "$previous_tag" ]]; then
    commit_range="${previous_tag}..${head_sha}"
elif [[ -n "${PUSH_BEFORE:-}" && "$PUSH_BEFORE" != "$zero_sha" ]] &&
     git cat-file -e "${PUSH_BEFORE}^{commit}" 2>/dev/null; then
    commit_range="${PUSH_BEFORE}..${head_sha}"
else
    if git rev-parse "${head_sha}^" >/dev/null 2>&1; then
        commit_range="${head_sha}^..${head_sha}"
    else
        commit_range="$head_sha"
    fi
fi

while IFS=$'\t' read -r hash subject; do
    [[ -n "$hash" ]] || continue

    parent_count=$(git rev-list --parents -n 1 "$hash" | awk '{ print NF - 1 }')
    if (( parent_count > 1 )) || ! commit_affects_build "$hash"; then
        continue
    fi

    commit_type=$(canonical_commit_type "$subject")
    printf '%s\t%s\t%s\n' "$hash" "$subject" "$commit_type" >> "$records_file"
done < <(git log --reverse --format=$'%H\t%s' "$commit_range")

detect_same_range_reverts

relevant_count=0

while IFS=$'\t' read -r hash subject commit_type; do
    [[ -n "$hash" ]] || continue
    if commit_is_skipped "$hash"; then
        continue
    fi

    relevant_count=$((relevant_count + 1))
    summary_title=$(summarize_commit_title "$hash" "$subject" "$commit_type")
    group_key=$(summary_group_key "$hash" "$subject" "$commit_type" "$summary_title")
    summary_title=$(printf '%s' "$summary_title" | tr '\t' ' ')
    printf '%s\t%s\t%s\t%s\n' "$commit_type" "$group_key" "$summary_title" "$hash" >> "$groups_file"
    record_contributor_for_commit "$hash"
done < "$records_file"

append_grouped_entries_for_type "feat" "$feat_file"
append_grouped_entries_for_type "fix" "$fix_file"
append_grouped_entries_for_type "perf" "$perf_file"
append_grouped_entries_for_type "refactor" "$refactor_file"
append_grouped_entries_for_type "docs" "$docs_file"
append_grouped_entries_for_type "style" "$style_file"
append_grouped_entries_for_type "chore" "$chore_file"
append_grouped_entries_for_type "revert" "$revert_file"

cat > "$notes_file" <<EOF
## ${release_title} 更新日志
EOF

append_section() {
    local title=$1
    local section_file=$2

    if [[ -s "$section_file" ]]; then
        printf '\n### %s\n\n' "$title" >> "$notes_file"
        cat "$section_file" >> "$notes_file"
    fi
}

append_section "新增功能" "$feat_file"
append_section "修复问题" "$fix_file"
append_section "性能优化" "$perf_file"
append_section "代码重构" "$refactor_file"
append_section "文档更新" "$docs_file"
append_section "代码格式" "$style_file"
append_section "杂项/其他" "$chore_file"
append_section "回滚" "$revert_file"

contributor_count=$(awk 'NF { count++ } END { print count + 0 }' "$contributors_file")
if (( contributor_count >= 2 )); then
    printf '\n## Contributors\n\n' >> "$notes_file"
    first_contributor=true
    while IFS= read -r contributor; do
        [[ -n "$contributor" ]] || continue
        if [[ "$first_contributor" == "true" ]]; then
            first_contributor=false
        else
            printf ', ' >> "$notes_file"
        fi
        printf '%s' "$contributor" >> "$notes_file"
    done < "$contributors_file"
    printf '\n' >> "$notes_file"
fi

cat "$notes_file"
