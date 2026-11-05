#!/usr/bin/env bash
#
# Sets up a complete LineageOS 20.0 source tree for i9100:
#   1. `repo init` (only if source-root isn't a repo checkout yet)
#   2. install galaxys2-20.0.xml as local manifest (first, so an outdated
#      or broken copy can't stop the cleanup)
#   3. cleanup.sh: remove other local manifests, abort unfinished git
#      operations, drop previously applied patches
#   4. `repo sync`
#   5. apply.sh: apply the patch set
#
# Safe to re-run: an existing i9100 tree is reset and re-patched.
#
# Usage: ./setup.sh [options] [source-root]
#   source-root defaults to the current directory; it is created if missing
#
# Options:
#   -y, --yes      don't ask for confirmation
#   -f, --force    discard uncommitted changes and unpushed commits instead of
#                  stopping (they can't be recovered afterwards)
#   -j N           number of parallel jobs for repo sync
#   -h, --help     show this help

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

cleanup_args=()
sync_args=(-d --force-sync)
root=""
while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)   cleanup_args+=(--yes) ;;
        -f|--force) cleanup_args+=(--force); sync_args+=(--force-remove-dirty) ;;
        -j)         sync_args+=(-j "${2:?-j needs a number}"); shift ;;
        -j*)        sync_args+=("$1") ;;
        -h|--help)  usage ;;
        -*)         echo "unknown option: $1" >&2; usage 1 ;;
        *)          root="$1" ;;
    esac
    shift
done
root="${root:-$PWD}"

require_tools git git-lfs repo xmllint

step=0
steps=5
step() {
    step=$((step + 1))
    echo
    header "[$step/$steps] $*"
}

# ---------------------------------------------------------------------------
step "Source tree"
# ---------------------------------------------------------------------------
if [ -d "$root/.repo" ]; then
    resolve_source_root "$root"
    branch=$(git -C "$SOURCE_ROOT/.repo/manifests" config branch.default.merge)
    [ "$branch" = "refs/heads/$LINEAGE_BRANCH" ] \
        || die "$SOURCE_ROOT is initialized for ${branch#refs/heads/}, not $LINEAGE_BRANCH (switch with: repo init -b $LINEAGE_BRANCH)"
    echo "    using existing $LINEAGE_BRANCH checkout in $SOURCE_ROOT"
else
    mkdir -p "$root" || die "cannot create $root"
    SOURCE_ROOT="$(cd -- "$root" && pwd)"
    echo "    initializing $LINEAGE_BRANCH in $SOURCE_ROOT"
    (cd "$SOURCE_ROOT" && repo init -u "$LINEAGE_MANIFEST_URL" -b "$LINEAGE_BRANCH" --git-lfs --no-clone-bundle) \
        || die "repo init failed"
fi
cd "$SOURCE_ROOT" || die "cannot enter $SOURCE_ROOT"

# ---------------------------------------------------------------------------
step "Local manifest"
# ---------------------------------------------------------------------------
mkdir -p .repo/local_manifests
target=".repo/local_manifests/$LOCAL_MANIFEST"
if cmp -s "$PATCHES_DIR/$LOCAL_MANIFEST" "$target"; then
    echo "    $target is up to date"
else
    if [ -f "$target" ]; then
        backup=".repo/local_manifests.backup/$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup" && mv "$target" "$backup/" \
            && echo "    moved the outdated $LOCAL_MANIFEST to $backup/"
    fi
    cp "$PATCHES_DIR/$LOCAL_MANIFEST" "$target" || die "could not install $target"
    echo "    installed $target"
fi

# ---------------------------------------------------------------------------
step "Clean up"
# ---------------------------------------------------------------------------
if [ -s .repo/project.list ]; then
    "$PATCHES_DIR/cleanup.sh" "${cleanup_args[@]}" --keep "$LOCAL_MANIFEST" --no-sync "$SOURCE_ROOT" \
        || exit 1
else
    echo "    not synced yet, nothing to clean up"
fi

# ---------------------------------------------------------------------------
step "repo sync ${sync_args[*]}"
# ---------------------------------------------------------------------------
repo sync "${sync_args[@]}" || die "repo sync failed, see the output above"

# ---------------------------------------------------------------------------
step "Apply patches"
# ---------------------------------------------------------------------------
"$PATCHES_DIR/apply.sh" "$SOURCE_ROOT" || die "some patches did not apply, see above"

echo
header "${C_GREEN}$DEVICE is ready to build${C_RESET}"
echo
echo "    cd $SOURCE_ROOT"
echo "    source build/envsetup.sh"
echo "    brunch $DEVICE"
