#!/usr/bin/env bash
#
# Reverts the i9100 patch set: aborts any unfinished `git am` and resets
# each patched repository to its manifest revision with `repo sync`.
#
# Usage: ./revert.sh [source-root]
#   source-root defaults to the current directory
#
# The repository list lives in common.sh.

# When sourced, re-run in a child shell so `exit` and shell options can't
# leak into (or close) the calling terminal.
if (return 0 2>/dev/null); then
    bash "${BASH_SOURCE[0]}" "$@"
    return
fi

set -uo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

init revert "${1:-}"

total=${#PATCHED_REPOS[@]}
index=0
for entry in "${PATCHED_REPOS[@]}"; do
    read -r path patch_dir <<< "$entry"
    index=$((index + 1))
    repo_dir="$SOURCE_ROOT/$path"
    log="$(log_file "$path")"

    repo_begin "$index" "$total" "$path"

    if [ ! -d "$repo_dir" ]; then
        repo_fail "directory not found" "$path"
        continue
    fi

    mapfile -t patches < <(patch_files "$patch_dir")
    if [ ${#patches[@]} -eq 0 ]; then
        repo_skip "no patches in $patch_dir/"
        continue
    fi

    note=""
    if am_in_progress "$repo_dir"; then
        git -C "$repo_dir" am --abort > "$log" 2>&1
        note=" (aborted unfinished git am)"
    fi

    if (cd "$repo_dir" && repo sync .) >> "$log" 2>&1; then
        repo_ok "synced$note"
    else
        repo_fail "repo sync failed$note" "$path"
    fi
done

finish
