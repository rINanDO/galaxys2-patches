#!/usr/bin/env bash
#
# Returns a LineageOS 20.0 tree to plain LineageOS: removes all local
# manifests (any device, not just i9100) and resets every project to its
# manifest revision, dropping applied patches and other local commits.
#
# Usage: ./cleanup.sh [options] [source-root]
#   source-root defaults to the current directory
#
# Options:
#   -y, --yes      don't ask for confirmation
#   -f, --force    discard uncommitted changes and unpushed commits instead of
#                  stopping (they can't be recovered afterwards)
#   --fetch        fetch from the network while syncing (default: local only)
#   --keep FILE    leave .repo/local_manifests/FILE in place
#   --no-sync      do everything except the final `repo sync` (used by setup.sh)
#   -h, --help     show this help
#
# Removed local manifests are moved to .repo/local_manifests.backup/<date>/.

# When sourced, re-run in a child shell so `exit` and shell options can't
# leak into (or close) the calling terminal.
if (return 0 2>/dev/null); then
    bash "${BASH_SOURCE[0]}" "$@"
    return
fi

set -uo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

usage() {
    sed -n '3,/^$/s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
    exit "${1:-0}"
}

ASSUME_YES=0
force=0
fetch=0
sync=1
keep=""
root=""
while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)   ASSUME_YES=1 ;;
        -f|--force) force=1 ;;
        --fetch)    fetch=1 ;;
        --keep)     keep="${2:?--keep needs a file name}"; shift ;;
        --no-sync)  sync=0 ;;
        -h|--help)  usage ;;
        -*)         echo "unknown option: $1" >&2; usage 1 ;;
        *)          root="$1" ;;
    esac
    shift
done

require_tools git repo xmllint
resolve_source_root "$root"
cd "$SOURCE_ROOT" || die "cannot enter $SOURCE_ROOT"

header "Clean up to plain LineageOS"
echo "    source root: $SOURCE_ROOT"
echo

# ---------------------------------------------------------------------------
# 1. Find local manifests and the projects they bring in.
# ---------------------------------------------------------------------------
remove_manifests=()
local_paths=()
for manifest in .repo/local_manifests/*.xml .repo/local_manifest.xml; do
    [ -f "$manifest" ] || continue
    mapfile -t -O "${#local_paths[@]}" local_paths < <(manifest_paths "$manifest")
    [ -n "$keep" ] && [ "$manifest" = ".repo/local_manifests/$keep" ] && continue
    remove_manifests+=("$manifest")
done

# ---------------------------------------------------------------------------
# 2. Scan every project for unfinished git operations, uncommitted changes and
#    commits on top of the manifest revision.
# ---------------------------------------------------------------------------
echo "Scanning projects (this takes a minute)..."

# Runs inside each project via `repo forall` (POSIX sh). Prints one line per
# finding: "busy <path> <operation>", "dirty <path>" or "ahead <path> <count>".
scan='
g=$(git rev-parse --git-dir)
op=
if [ -d "$g/rebase-apply" ]; then
    if [ -f "$g/rebase-apply/applying" ]; then op=am; else op=rebase; fi
elif [ -d "$g/rebase-merge" ]; then op=rebase
elif [ -f "$g/CHERRY_PICK_HEAD" ]; then op=cherry-pick
elif [ -f "$g/REVERT_HEAD" ]; then op=revert
elif [ -f "$g/MERGE_HEAD" ]; then op=merge
fi
if [ -n "$op" ]; then
    echo "busy $REPO_PATH $op"
elif [ -n "$(git status --porcelain --untracked-files=no 2>/dev/null)" ]; then
    echo "dirty $REPO_PATH"
fi
n=$(git rev-list --count "$REPO_LREV..HEAD" 2>/dev/null)
[ "${n:-0}" -gt 0 ] && echo "ahead $REPO_PATH $n"
exit 0
'
scan_err=$(mktemp)
scan_out=$(repo forall -j "$(nproc)" -c "$scan" 2> "$scan_err" | sort) \
    || { cat "$scan_err" >&2; rm -f "$scan_err"; die "scanning projects with repo forall failed (a project that isn't checked out, e.g. after an interrupted sync, also does this: run repo sync first)"; }
rm -f "$scan_err"

busy=() busy_ops=() dirty=() ahead=()
declare -A busy_op=()
while read -r kind path extra; do
    case "$kind" in
        busy)  busy+=("$path"); busy_op[$path]=$extra; busy_ops+=("$path ($extra)") ;;
        dirty) dirty+=("$path") ;;
        ahead) ahead+=("$path ($(plural "$extra" commit))") ;;
    esac
done <<< "$scan_out"

# Projects from local manifests are removed or replaced by the sync, so any
# commit that isn't on a remote would be lost.
unpushed=()
for path in "${local_paths[@]}"; do
    [ -d "$path/.git" ] || continue
    if [ -n "$(git -C "$path" rev-list -1 HEAD --branches --not --remotes 2>/dev/null)" ]; then
        unpushed+=("$path")
    fi
done

# ---------------------------------------------------------------------------
# 3. Show the plan and stop on anything that would lose work.
# ---------------------------------------------------------------------------
if [ ${#remove_manifests[@]} -eq 0 ] && [ ${#busy[@]} -eq 0 ] \
        && [ ${#dirty[@]} -eq 0 ] && [ ${#ahead[@]} -eq 0 ] && [ "$fetch" -eq 0 ]; then
    echo
    header "${C_GREEN}Already plain LineageOS, nothing to do"
    exit 0
fi

echo
echo "This will:"
[ ${#remove_manifests[@]} -gt 0 ] && list "remove local manifests (backed up):" "${remove_manifests[@]#.repo/local_manifests/}"
[ -n "$keep" ] && [ -f ".repo/local_manifests/$keep" ] && list "keep local manifest:" "$keep"
[ ${#busy[@]} -gt 0 ] && list "abort unfinished git operations in:" "${busy_ops[@]}"
[ ${#ahead[@]} -gt 0 ] && list "drop local commits (patches) in:" "${ahead[@]}"
[ "$sync" -eq 1 ] && echo "    sync all projects to their manifest revision$([ "$fetch" -eq 0 ] && echo ' (no network)')"
echo

blocked=0
if [ ${#dirty[@]} -gt 0 ]; then
    if [ "$force" -eq 1 ]; then
        list "${C_RED}discard uncommitted changes${C_RESET} in:" "${dirty[@]}"
    else
        list "${C_RED}uncommitted changes${C_RESET} in:" "${dirty[@]}"
        blocked=1
    fi
fi
if [ ${#unpushed[@]} -gt 0 ]; then
    if [ "$force" -eq 1 ]; then
        list "${C_RED}lose commits not pushed to any remote${C_RESET} in:" "${unpushed[@]}"
    else
        list "${C_RED}commits not pushed to any remote${C_RESET} in:" "${unpushed[@]}"
        blocked=1
    fi
fi
if [ "$blocked" -eq 1 ]; then
    echo
    die "commit/push or stash the work above first, or re-run with --force to throw it away"
fi
[ ${#dirty[@]} -gt 0 ] || [ ${#unpushed[@]} -gt 0 ] && echo

confirm "Continue?" || die "aborted, nothing was changed"
echo

# ---------------------------------------------------------------------------
# 4. Do it.
# ---------------------------------------------------------------------------
for path in "${busy[@]}"; do
    git -C "$path" "${busy_op[$path]}" --abort > /dev/null 2>&1 \
        || warn "could not abort ${busy_op[$path]} in $path"
done
[ ${#busy[@]} -gt 0 ] && echo "${C_GREEN}OK${C_RESET}    aborted $(plural ${#busy[@]} operation)"

if [ "$force" -eq 1 ]; then
    for path in "${dirty[@]}"; do
        git -C "$path" reset -q --hard || warn "could not reset $path"
    done
    [ ${#dirty[@]} -gt 0 ] && echo "${C_GREEN}OK${C_RESET}    discarded uncommitted changes"
fi

if [ ${#remove_manifests[@]} -gt 0 ]; then
    backup=".repo/local_manifests.backup/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup"
    mv "${remove_manifests[@]}" "$backup"/ || die "could not move local manifests to $backup"
    echo "${C_GREEN}OK${C_RESET}    moved local manifests to $backup/"
fi

if [ "$sync" -eq 1 ]; then
    sync_args=(-d --force-sync)
    [ "$fetch" -eq 0 ] && sync_args+=(-l)
    [ "$force" -eq 1 ] && sync_args+=(--force-remove-dirty)
    echo
    header "repo sync ${sync_args[*]}"
    repo sync "${sync_args[@]}" || die "repo sync failed, see the output above"
fi

echo
if [ "$sync" -eq 1 ]; then
    header "${C_GREEN}Done: the tree is plain LineageOS ($LINEAGE_BRANCH)$([ -n "$keep" ] && echo " + $keep")"
else
    header "${C_GREEN}Cleanup done${C_RESET}${C_BOLD} (projects are reset by the next repo sync)"
fi
