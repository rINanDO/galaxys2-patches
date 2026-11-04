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
  `$(call soong_config_set,netd,direct_connect_rule,true)`; in LOS-20.0
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
    `TARGET_LD_SHIM_LIBS`. The linker splits the entries on `:`, not on
    spaces, so join them with `$(subst $(space),:,...)`;
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
- **Camera HAL v1** (`frameworks_av`, `frameworks_base` 0004-0006,
  `system_core` 0005, `device_lineage_sepolicy`): the camera blob only
  speaks the HAL v1 API, which AOSP removed. These are the gts210wifi
  patches that restore HALv1 in cameraserver (or, with
  `$(call soong_config_set,camera_hal1,no_cameraserver,true)`, in
  mediaserver), the old recording path, the camera extensions and formats,
  and the HALv1 sepolicy. They replace the LOS-20.0 `frameworks_av`
  0001-0022 and camera reverts in `frameworks_base`, and
  `TARGET_HAS_LEGACY_CAMERA_HAL1` (`vendor_lineage` 0006). From LOS-20.0
  only `frameworks_av` 0030 (no crash on a NULL camera parameter) is kept;
  0025 (custom `CameraParameters` library) is unused by this device, 0035
  (64-bit buffer usage) is upstream, and 0032 and 0045 are for legacy
  Qualcomm devices only.
  `frameworks_base` 0014-0015 adapt the camera2 legacy shim for camera2
  apps: 0014 keeps the 1280x720 preview size (the M5MO has no 4:3 preview
  size above 640x480), and 0015 renders encoder surfaces as BGRA so the SEC
  encoder can convert them on FIMC (`hardware/samsung`). `galaxys2-common`
  ships Open Camera instead of Aperture: with the old camera API, recording
  is zero-copy from the HAL's FIMC2 buffers to MFC and offers 1080p.
- **Legacy HIDL HALs** (`hardware_lineage_interfaces`,
  `hardware_libhardware_legacy`, `device_lineage_sepolicy` 0002-0003,
  `frameworks_base` 0007), the same patches as gts210wifi:
  - the legacy GNSS 1.0 passthrough HAL, which
    `android.hardware.gnss@1.0-service.exynos4` needs, and the sepolicy
    labels of the legacy GNSS and Wi-Fi HALs;
  - the legacy Wi-Fi HIDL HAL (with dynamic interfaces) and the Wi-Fi headers
    it builds against, without TWT and 802.11az. These replace LOS-20.0
    `hardware_lineage_interfaces` 0001-0004. `galaxys2-common` lineage-21.0
    doesn't ship a Wi-Fi HAL at the moment;
  - `HintManagerService` no longer crashes when there is no AIDL power HAL
    (this device has the HIDL power HAL 1.0);
  - the health HAL's fast charge dump uses the right format for a 64-bit
    value on 32-bit ARM, which failed the build.

  Not ported from LOS-20.0 `hardware_lineage_interfaces`: 0005 (the legacy
  camera device it fixes no longer exists), and 0006-0008 (the Lineage power
  HAL 1.0 and the in-screen fingerprint HAL, which nothing in this device
  uses; the HIDL power HAL 1.0 is still in AOSP).
- **Framework tweaks for this device** (`frameworks_base` 0008-0012, from
  LOS-20.0 `frameworks_base` 0013-0023):
  - no warning dialogs about a vendor mismatch or an app's old target SDK;
  - `config_useSystemClockforRotationSensor`: auto-rotate uses the system
    clock instead of the sensor event timestamp, which is far off after
    deep sleep on old sensor libraries;
  - `storage.xml` is written as text XML, which TWRP can read;
  - aggressive trimming of cached and empty apps on devices with less than
    1 GB RAM (`ro.vendor.qti.sys.fw.*` properties). The number of cached
    apps is now set with the `config_customizedMaxCachedProcesses` overlay
    instead of `ro.vendor.qti.sys.fw.bg_apps_limit`.

  Replaced by settings that 23.2 already has, to be set in the device
  tree:
  - 0017 (brightness slider curve): `sys.brightness.disable_gamma_conversion=true`;
  - 0021 (`ro.displaypower.colorfade`): the `config_displayColorFadeDisabled`
    overlay. 0020 (ColorFade EGL crash) isn't needed while ColorFade is
    off.

  Not ported: 0013 (this device has no fingerprint or face sensor), 0014
  (ignore a `SensorPrivacyService` permission error, a hack with an unknown
  cause; port it again if the error shows up), 0019 (hwui reset to
  Android 13) and 0008 (CameraServiceProxy accepting calls from
  mediaserver; revisit once the camera is enabled).
- **frameworks/native** (`frameworks_native`), the same patches as
  gts210wifi:
  - `gpuservice` is disabled, because its GPU memory accounting needs BPF
    (replaces LOS-20.0 0001);
  - `libbinder` no longer aborts when it shrinks its thread pool (replaces
    LOS-20.0 0002);
  - `BLASTBufferQueue` falls back to `epoll_pwait` without
    `epoll_pwait2`.

  LOS-20.0 0003 (no installd timeouts) is obsolete: installd now waits
  without a timeout when `pidfd_open` fails, which it always does on
  Linux 3.0.
- **adb over USB** (`packages_modules_adb`): adbd only does asynchronous
  USB I/O, which this kernel's FunctionFS doesn't support. adbd now falls
  back to the old blocking FunctionFS code when the first asynchronous read
  fails, or uses it straight away with `ro.adb.nonblocking_ffs=false`.
  The device side of the old USB transport is built into adbd only,
  because the adb host has its own USB transport now. (gts210wifi
  backports FunctionFS AIO to its kernel instead.)
- **Build and kernel** (`build_make`, `build_soong`, `system_linkerconfig`,
  `vendor_lineage`):
  - `BOARD_NO_RECOVERY_PATCH` (`build_make` 0001): recovery is part of the
    kernel image, so there is no recovery image to patch from the boot
    image, and the OTA no longer requires one;
  - `BOARD_CUSTOM_KERNEL_MK` (`vendor_lineage` 0001): `galaxys2-common`'s
    `shkernel.mk` builds the uncompressed ramdisk before the kernel, which
    embeds it;
  - `-fuse-ld=lld` in the kernel's `HOSTCFLAGS` (`vendor_lineage` 0002),
    because Linux 3.0 links its host programs with `HOSTCFLAGS` only;
  - from gts210wifi: no Treble (`build_make` 0004 and
    `system_linkerconfig`), uncompressed APEXes, `link_type_error` as a
    warning, `TARGET_SPECIFIC_HEADER_PATH` (`build_make` 0005 and
    `build_soong`), which `galaxys2-common` and `i9100` use, and the
    automatic kernel header library.

  The kernel is LZMA-compressed; `lzma` comes from
  `prebuilts/tools-lineage`, so the gts210wifi xz patches aren't needed.
  The LOS-20.0 `vendor_lineage` 0003-0006 are replaced by Soong config
  variables (see above).
- **Smaller fixes** (`system_libhwbinder`, `system_core` 0006):
  - libhwbinder logs an error instead of aborting when a process shrinks its
    thread pool, as `libbinder` does (`frameworks_native` 0001);
  - in the off-mode charger, the home button also wakes the screen.
- **Legacy kernel fixes from gts210wifi** (`system_memory_lmkd`,
  `frameworks_base` 0013, `system_core` 0007):
  - lmkd no longer exits at every boot: with the kernel's low memory
    killer it tried to start PSI monitoring when ActivityManager asked, and
    this kernel has no PSI;
  - `FileIntegrity` skips fs-verity, which this kernel lacks, instead of
    logging a stack trace on every settings and permissions write;
  - fast reboot on legacy devices too.

## LOS-20.0 patches that are no longer needed

- **Audio** (`frameworks_av` 0024, `hardware_interfaces` 0001-0002): the
  device now uses the audio HAL 7.0, which 23.2 still supports, through
  `hardware/samsung`'s own legacy audio service. The 2.0 HAL and the
  changes to the default audio service aren't needed.
- **Battery life extender** (`hardware_lineage_interfaces` 0009,
  `packages_apps_Settings`, `device_lineage_sepolicy`): `galaxys2-common`
  lineage-21.0 doesn't ship that HAL. LineageOS's own Charging control
  (health HAL with `charge_start_level`/`charge_stop_level` in the kernel),
  as on herolte, would replace it.
- **`packages_modules_Permission`** 0001-0002: the second patch reverts the
  first.

## Status

The LineageOS 20.0 patch set is ported: the tree syncs and all patches
apply. Nothing has been built yet. The device trees are still on
lineage-21.0, and before the first build they need:

- the Soong config variables above instead of `TARGET_PROCESS_SDK_VERSION_OVERRIDE`,
  `TARGET_LD_SHIM_LIBS`, `TARGET_HAS_MEMFD_BACKPORT`,
  `TARGET_NEEDS_NETD_DIRECT_CONNECT_RULE` and
  `TARGET_HAS_LEGACY_CAMERA_HAL1`;
- `sys.brightness.disable_gamma_conversion=true` and the
  `config_displayColorFadeDisabled` overlay instead of
  `ro.displaypower.colorfade=false`;
- optionally the `config_customizedMaxCachedProcesses` overlay.
