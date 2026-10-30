# LineageOS 23.2/Android 16 patches for Galaxy S2 (i9100)

These instructions assume that:

- the LineageOS 23.2 sources live (or will live) in `~/android/system`
  (see <https://github.com/LineageOS/android/tree/lineage-23.2>)
- this repository is cloned in `~/android/system/patches/galaxys2-patches`
- `git`, `git-lfs`, `repo` and `xmllint` are installed, plus the usual
  LineageOS build dependencies

All scripts accept the source root as their last argument and default to the
current directory. Run them directly (`./setup.sh`); sourcing them
(`. setup.sh`) also works.

## Quick start: set up everything

```bash
cd ~/android/system
patches/galaxys2-patches/LOS-23.2/setup.sh
```

`setup.sh` does the whole job and can be re-run at any time:

1. `repo init -b lineage-23.2 --git-lfs` if the directory isn't a checkout yet
2. `cleanup.sh`: removes local manifests of other devices and drops any
   previously applied patches (i9100's or another device's)
3. installs `galaxys2-23.2.xml` into `.repo/local_manifests/`
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

To return the tree to plain LineageOS 23.2, without any local manifest or
patches:

```bash
cd ~/android/system
patches/galaxys2-patches/LOS-23.2/cleanup.sh
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
patches/galaxys2-patches/LOS-23.2/apply.sh
patches/galaxys2-patches/LOS-23.2/revert.sh
```

A repo whose patches don't apply is left in the middle of `git am` so it can
be resolved by hand; the output points at a log with the details. `revert.sh`
aborts that and resets the patched repos with `repo sync`.

## Maintaining the patch set

- The patched repositories are listed once, in `common.sh` (`PATCHED_REPOS`).
  To track a new repo, add a line there and put its `git format-patch` output
  in the matching directory, named after the repo path (`frameworks_av` for
  `frameworks/av`).
- Device, kernel, hardware and vendor repos are forks listed in
  `galaxys2-23.2.xml`. None of them has a `lineage-23.2` branch yet, so the
  manifest uses the newest branch each fork has: `lineage-21.0` for the device
  trees and `hardware/samsung` (its `lineage-23.2` branch no longer has the
  exynos4 HALs), and `lineage-20.0` for the kernel, the GCC 4.9 toolchain and
  `vendor/samsung` (the only branch with the i9100 blobs).

## What the patches address

The Galaxy S2 is a legacy device: a Linux 3.0 kernel, no Treble, and 2011
blobs. LineageOS 23.2 has dropped much of the compatibility code they depend
on. Most problems are shared with other legacy devices, so where possible the
patches are the same as in gts210wifi-patches LOS-23.2.

- **No BPF in the kernel** (`system_bpf`, `system_netd`,
  `packages_modules_Connectivity`, `packages_modules_DnsResolver`,
  `packages_modules_NetworkStack`): networking, traffic stats, DNS and the
  network stack work without eBPF. The bpfloader no longer panics, and
  NetworkStack gets link and TCP information without the netlink features
  this kernel lacks. These replace the LOS-20.0 `system_bpf`, `system_netd`
  0001, `packages_modules_Connectivity`, `packages_modules_NetworkStack` and
  `frameworks_libs_net` patches (that library is part of Connectivity now).
- **Mobile data with the Samsung RIL** (`system_netd` 0004): netd can add a
  rule for the kernel's directly-connected routes, without which IPv4 mobile
  data has no default route. Enable it in the device tree with
  `$(call soong_config_set_bool,netd,direct_connect_rule,true)`; in LOS-20.0
  this was `TARGET_NEEDS_NETD_DIRECT_CONNECT_RULE` plus a `vendor_lineage`
  patch.
- **Old blobs and an old kernel in bionic** (`bionic`):
  - per-process target SDK version override, so old blobs get the behavior
    they were built for. In the device tree:
    `$(call soong_config_set,bionic,sdk_version_overrides,...)`, which
    replaces `TARGET_PROCESS_SDK_VERSION_OVERRIDE` (LOS-20.0 `bionic`
    0001-0002 and `vendor_lineage` 0004);
  - shim libraries loaded into specific blobs:
    `$(call soong_config_set,bionic,ld_shim_libs,...)`, which replaces
    `TARGET_LD_SHIM_LIBS`;
  - pre-Android 9 mutex behavior, and the linker ignores library namespaces
    for blobs that expect a flat one;
  - no `MADV_WIPEONFORK` and no `renameat2`, which this kernel lacks;
  - an invalid `pthread_t` passed by an old blob is logged instead of
    aborting the process (LOS-20.0 `bionic` 0003).
- **memfd backport** (`art`, `external_perfetto`, `frameworks_base`): the
  kernel has a `memfd_create` backport, but ART and perfetto refuse to use
  it on a kernel older than 3.17. Set
  `$(call soong_config_set,art,has_memfd_backport,true)` in the device
  tree; this replaces `TARGET_HAS_MEMFD_BACKPORT` (LOS-20.0 `art`,
  `external_perfetto` and `vendor_lineage` 0005). Bitmaps sent to other
  processes keep using ashmem, because the legacy memfd broke apps such as
  YouTube ("Could not copy bitmap to parcel blob").
- **cgroup v1-only kernel** (`system_core`, `frameworks_base`, `system_netd`
  0003): the kernel has no cgroup v2. These revert the v2-only freezer and
  memcg setup, and make a failure to create a process's cgroup a logged
  error instead of a reason not to start it (LOS-20.0 `system_core` 0002 is
  part of `system_core` 0002).

## Status

Work in progress: the LineageOS 20.0 patch set is being ported. The tree
syncs and the patches apply; the ROM doesn't build yet.
