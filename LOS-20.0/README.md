# LineageOS 20.0/Android 13 patches for Galaxy S2 (i9100)

These instructions assume that:

- the LineageOS 20.0 sources live (or will live) in `~/android/system`
  (see <https://github.com/LineageOS/android/tree/lineage-20.0>)
- this repository is cloned in `~/android/system/patches/galaxys2-patches`
- `git`, `git-lfs`, `repo` and `xmllint` are installed, plus the usual
  LineageOS build dependencies

All scripts accept the source root as their last argument and default to the
current directory. Run them directly (`./setup.sh`); sourcing them
(`. setup.sh`) also works.

## Quick start: set up everything

```bash
cd ~/android/system
patches/galaxys2-patches/LOS-20.0/setup.sh
```

`setup.sh` does the whole job and can be re-run at any time:

1. `repo init -b lineage-20.0 --git-lfs` if the directory isn't a checkout yet
2. installs `galaxys2-20.0.xml` into `.repo/local_manifests/`
3. `cleanup.sh`: removes local manifests of other devices and drops any
   previously applied patches (i9100's or another device's)
4. `repo sync -d --force-sync`
5. `apply.sh`

Options: `-y` (don't ask for confirmation), `--force` (see
[Cleaning up](#cleaning-up)), `-j N` (parallel sync jobs).

## Build the ROM

```bash
cd ~/android/system
. build/envsetup.sh
brunch i9100
```

Your build will be put (after many hours) in:

`~/android/system/out/target/product/i9100`

## Cleaning up

To return the tree to plain LineageOS 20.0, without any local manifest or
patches:

```bash
cd ~/android/system
patches/galaxys2-patches/LOS-20.0/cleanup.sh
```

This works on the whole tree, whichever device it was set up for. It lists
what it is going to do and asks before doing it:

- local manifests are moved to `.repo/local_manifests.backup/<date>/`
- unfinished `git am`/rebase/cherry-pick operations are aborted
- local commits (applied patches) are dropped and every project is synced to
  its manifest revision; add `--fetch` to also fetch updates from the network

It refuses to continue when a project has uncommitted changes, or when a
device repo has commits that aren't pushed to any remote. Commit/push or stash
that work first, or pass `--force` to throw it away.

## Applying or reverting only the patches

When the local manifest is already installed and synced:

```bash
cd ~/android/system
patches/galaxys2-patches/LOS-20.0/apply.sh
patches/galaxys2-patches/LOS-20.0/revert.sh
```

A repo whose patches don't apply is left in the middle of `git am` so it can
be resolved by hand; the output points at a log with the details. `revert.sh`
aborts that and resets the patched repos with `repo sync`.

## Maintaining the patch set

- The patched repositories are listed once, in `common.sh` (`PATCHED_REPOS`).
  To track a new repo, add a line there and put its `git format-patch` output
  in the matching directory, named after the repo path (`frameworks_av` for
  `frameworks/av`).
- `packages_modules_Permission` is not applied: its 0002 reverts 0001.
- Device, kernel, toolchain, hardware and vendor repos are forks listed in
  `galaxys2-20.0.xml`, all on their `lineage-20.0` branch.
