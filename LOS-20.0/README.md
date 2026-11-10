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
2. `cleanup.sh`: removes local manifests of other devices (and an old
   `roomservice.xml`) and drops any previously applied patches (i9100's or
   another device's)
3. installs `galaxys2-20.0.xml` into `.repo/local_manifests/`
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

## What the patches address

The Galaxy S2 is a legacy device: a Linux 3.0 kernel, no Treble, and 2011
blobs. LineageOS 20.0 has dropped much of the compatibility code they depend
on, so most patches bring that code back or make Android cope without a
kernel feature. Grouped by the problem they solve:

- **No eBPF in the kernel** (`system_bpf`, `system_netd` 0001,
  `frameworks_libs_net`, `packages_modules_Connectivity`,
  `packages_modules_NetworkStack`): with `ro.kernel.ebpf.supported=false`
  the bpfloader, netd, the BPF maps, traffic stats and the network stack
  skip or only log their eBPF setup instead of aborting, and NetworkStack
  doesn't parse netlink events it can't get from this kernel.
- **Mobile data with the Samsung RIL** (`system_netd` 0002,
  `vendor_lineage` 0003): netd can force-add the kernel's directly-connected
  routes, without which IPv4 mobile data has no default route. Enable it
  with `TARGET_NEEDS_NETD_DIRECT_CONNECT_RULE := true`.
- **Old blobs in bionic** (`bionic`, `vendor_lineage` 0004):
  - per-process target SDK version override, also applied on `dlopen`, so
    old blobs get the behavior they were built for
    (`TARGET_PROCESS_SDK_VERSION_OVERRIDE`);
  - an invalid `pthread_t` passed by an old blob is logged instead of
    aborting the process.
- **memfd backport** (`art`, `external_perfetto`, `vendor_lineage` 0005):
  the kernel has a `memfd_create` backport, but ART and perfetto refuse to
  use it on a kernel older than 3.17. Set `TARGET_HAS_MEMFD_BACKPORT := true`.
- **Camera HAL v1** (`frameworks_av` 0001-0028, 0030, 0036-0042,
  `frameworks_base` 0001-0012, `system_core` 0001, `vendor_lineage` 0006,
  `hardware_lineage_interfaces` 0005): the camera blob only speaks the HAL v1
  API, which AOSP removed. libcameraservice is reverted to its Android 12
  state and HALv1 is restored in cameraserver and the framework, with the
  old recording path, the camera feature extensions, boottime timestamps,
  extra preview and recording formats, and camera-in-mediaserver support
  (`TARGET_HAS_LEGACY_CAMERA_HAL1`). The Android 13 camera changes that
  depend on HAL v3 (override to portrait, rotate and crop, readout
  timestamps, camera injection, ...) are reverted.
- **Media and codecs** (`frameworks_av` 0029, 0031-0035, 0043-0045): fixes for
  legacy OMX codecs (no crash when a codec fails to load, empty vendor
  parameters, 64-bit buffer usage, buffer leaks), plus Bluetooth SCO call
  routing and adaptive playback for legacy CAF/QCOM devices.
- **Audio HAL 2.0** (`frameworks_av` 0024, `hardware_interfaces`): the
  audio HAL 2.0 is brought back into libaudiohal, and the default audio
  service no longer loads the Bluetooth AIDL HAL or uses the binder
  threadpool.
- **Legacy HIDL HALs** (`hardware_lineage_interfaces` 0001-0004, 0006-0008):
  the legacy Wi-Fi HIDL HAL builds and works on Android 13 (with dynamic
  interfaces), and the Lineage power HAL 1.0 and the in-screen fingerprint
  HAL are restored.
- **Battery life extender** (`hardware_lineage_interfaces` 0009,
  `device_lineage_sepolicy`, `packages_apps_Settings`): a Lineage HAL, its
  sepolicy and a "Protect battery" toggle in Settings to stop charging
  early.
- **Binder and services that need newer kernels** (`frameworks_native`,
  `system_libhwbinder`, `system_core` 0002): `gpuservice` is disabled (its
  GPU memory accounting needs BPF), libbinder and libhwbinder log instead of
  aborting when a process shrinks its thread pool, installd operations have
  no timeout, and init no longer treats a failure to create a process group
  as fatal.
- **Framework tweaks for this device** (`frameworks_base` 0013-0023):
  - no warning dialogs about a vendor mismatch or an app's old target SDK;
  - the brightness slider curve for panels reporting a max brightness of
    2047 or 4095;
  - auto-rotate can use the system clock instead of the sensor timestamp,
    which is far off after deep sleep;
  - hwui reset to android-13.0.0_r13, ColorFade without the EGL crash on
    the exynos4 Mali blobs, and `ro.displaypower.colorfade=false` to turn
    ColorFade off;
  - `storage.xml` is written as text XML, which TWRP can read;
  - aggressive trimming of cached and empty apps on devices with up to 1 GB
    RAM;
  - biometric operations are cancelled when the HAL doesn't report back, and
    a `SensorPrivacyService` permission error is ignored (a hack with an
    unknown cause).
- **adb over USB** (`packages_modules_adb`): adbd falls back to the old
  blocking FunctionFS code, which this kernel needs.
- **Build and kernel** (`build_make`, `vendor_lineage` 0001-0002):
  - `BOARD_NO_RECOVERY_PATCH`: no recovery patch is created. The zip only
    writes the system and KERNEL partitions, so the recovery in the RECOVERY
    partition (TWRP) is kept;
  - `BOARD_CUSTOM_KERNEL_MK`: `galaxys2-common` builds the uncompressed
    ramdisk before the kernel, which embeds it;
  - `-fuse-ld=lld` in the kernel's host CFLAGS, because Linux 3.0 links its
    host programs with CFLAGS only.
- **Off-mode charger** (`system_core` 0003): the home button also wakes the
  screen.
- **Browser downloads** (`packages_apps_Jelly` 0001): a window opened by a
  script or a button (`window.open()`, a form with `target=_blank`, most
  download buttons) used to give an empty tab and no download. Jelly now
  follows the address that window loads, so the download prompt appears.
  Downloads that need a POST request still fail.

## Fixes in the device and kernel repos

These live in the forks listed in `galaxys2-20.0.xml`, not in patches. They
were backported from the LOS-23.2 work after checking them on a running 20.0
phone.

### Kernel (`kernel/samsung/smdk4412`)

- **Native crash reports**: `PTRACE_GETREGSET` works on ARM, and children of
  a seizing tracer start in a trap stop. Without this, `crash_dump` aborts
  with `Check failed: 0 == stop_signal` and no tombstone is written.
- **vmalloc space**: the kernel now reserves 256 MB, and the bootloader's
  later `vmalloc=144m` can no longer shrink it. With 144 MB only about 29 MB
  was still free 8 minutes after boot, and every binder process takes about
  1 MB of it.
- **Memory reservations** (27 MB more RAM): FIMD 18 MB to 6 MB, JPEG 20 MB to
  12 MB, and no FIMC3 reservation, because those regions were not fully used.
- **Accelerometer at boot**: the k3dh driver's test class device no longer
  gets a dev_t. ueventd created `/dev/accelerometer` for it as well as for
  the real misc device, and when it won the race the accelerometer, compass
  and orientation sensors (and auto-rotate) stayed dead until a reboot.

### Device (`device/samsung/galaxys2-common`, `device/samsung/i9100`)

- **Power HAL** (`power.smdk4210`): uses the pegasusq boost controls to hold
  1.2 GHz on both cores for 1 s on touch, 2 s on app launch and 2 s when the
  screen turns on. The boost is off while battery saver is active.
- **ANR timeouts** are doubled with `ro.hw_timeout_multiplier=2`.
- **Audio**: the primary output runs at 44.1 kHz, which saves resampling most
  music and video, and `audio_effects.xml` is installed in `/vendor/etc`.
- **Memory**: zram is 512 MB and uses both cores
  (`max_comp_streams=2`), and the low memory killer levels are capped at
  120 MB, so more cached apps are swapped instead of killed.
- **Reboot to recovery**: the HIDDEN partition (`mmcblk0p12`, used as
  `/misc`) is labeled `misc_block_device`. With its old
  `preload_block_device` label init could not write the bootloader message,
  so `adb reboot recovery` never reached recovery.
- **Camera app**: Open Camera (the F-Droid build) replaces Aperture.
  Aperture uses CameraX, which only allows preview + 480p recording on this
  LEGACY camera, and crashes in video mode if the camera2 shim offers
  1280x720 previews. Open Camera with the original camera API records 720p.
- **Sensors**: the sensors HAL in system_server can write the `enable` and
  `poll_delay` nodes of the gyro, light and proximity input devices
  (`sysfs_sensor` label, owned by system), so it can switch them on and set
  their rate. Before, the light sensor sent no events. The
  i9100 libsensors waits up to 3 s for the `compass_sensor` input node,
  which could appear late and leave auto-rotate dead until a reboot.

### WebView

`galaxys2-20.0.xml` pins the WebView prebuilt to 145
(`f547731aef7f92fed845d822d9fec66ddad04cd3`). Newer versions need GLES 3 and
lose GPU rendering on the Mali-400. 145 gets no more security updates.

### Dirty flashing

`ro.build.version.incremental` (the build ID) doesn't change between these
builds, and the package manager only rebuilds its parser cache when it does.
After a dirty flash that adds, removes or updates an app, delete
`/data/system/package_cache/*` in TWRP before booting, or Android keeps the
old package information (for example the previous WebView version).

The hardware composer overlays from LOS-23.2 are not backported yet.
