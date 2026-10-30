#!/usr/bin/env bash
#
# Applies the i9100 patch set on top of a synced LineageOS 23.2 tree.
#
# Usage: ./apply.sh [source-root]
#   source-root defaults to the current directory
#
# The repository list lives in common.sh. A repo whose patches don't apply is
# left in the middle of `git am` so it can be resolved by hand; revert.sh
# cleans that up.

# When sourced, re-run in a child shell so `exit` and shell options can't
# leak into (or close) the calling terminal.
if (return 0 2>/dev/null); then
    bash "${BASH_SOURCE[0]}" "$@"
    return
fi

set -uo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

init apply "${1:-}"

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

    if am_in_progress "$repo_dir"; then
        repo_fail "a previous git am is still in progress (run revert.sh first)" "$path"
        continue
    fi

    if git -C "$repo_dir" am --3way "${patches[@]}" > "$log" 2>&1; then
        repo_ok "$(plural ${#patches[@]} patch patches) applied"
    else
        reason=$(grep -m1 '^Patch failed at' "$log")
        repo_fail "${reason:-git am failed}" "$path"
    fi
done

finish
