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
  `galaxys2-23.2.xml`. The device trees and the kernel use `lineage-23.2`.
  `hardware/samsung` uses `lineage-23.2-exynos4`, because its `lineage-23.2`
  branch no longer has the exynos4 HALs. The GCC 4.9 toolchain and
  `vendor/samsung` stay on `lineage-20.0` (the only branch with the i9100
  blobs).


## What the patches address

The Galaxy S2 is a legacy device: a Linux 3.0 kernel, no Treble, and 2011
blobs. LineageOS 23.2 has dropped much of the compatibility code they depend
on.

- **No BPF in the kernel** (`system_bpf`, `system_netd`,
  `packages_modules_Connectivity`, `packages_modules_DnsResolver`,
  `packages_modules_NetworkStack`): networking, traffic stats, DNS and the
  network stack work without eBPF. The bpfloader no longer panics, and
  NetworkStack gets link and TCP information without the netlink features
  this kernel lacks. These replace the LOS-20.0 `system_bpf`, `system_netd`
  0001, `packages_modules_Connectivity`, `packages_modules_NetworkStack` and
  `frameworks_libs_net` patches (that library is part of Connectivity now).
  `packages_modules_Connectivity` 0009 makes the loaders stop at once when
  the kernel has no bpf() syscall, which starts zygote ~1.4 s earlier.
- **Video freezing after a surface change** (`frameworks_av` 0017): the SEC AVC
  decoder aligns its port height after its buffers were allocated. ACodec then
  set a new surface to that size, and the surface dropped every buffer, so a
  1280x674 video froze on rotation while audio kept playing.
- **Wi-Fi with the screen off** (`packages_modules_Wifi`): the BCM4330 driver
  has no scheduled scan, so hardware PNO is not available and Wi-Fi does not
  connect while the screen is off. The patch defaults the Software PNO flag to
  on, so `config_wifiSwPnoEnabled` in the device's Wi-Fi overlay decides.
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
  speaks the HAL v1 API, which AOSP removed. These restore HALv1 in
  cameraserver (or, with
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
  `frameworks_base` 0007):
  - the legacy GNSS 1.0 passthrough HAL, which
    `android.hardware.gnss@1.0-service.exynos4` needs, and the sepolicy
    labels of the legacy GNSS and Wi-Fi HALs;
  - the legacy Wi-Fi HIDL HAL (with dynamic interfaces) and the Wi-Fi headers
    it builds against, without TWT and 802.11az. These replace LOS-20.0
    `hardware_lineage_interfaces` 0001-0004;
  - `HintManagerService` no longer crashes when there is no AIDL power HAL
    (this device has the HIDL power HAL 1.0);
  - the health HAL's fast charge dump uses the right format for a 64-bit
    value on 32-bit ARM, which failed the build.

  Not ported from LOS-20.0 `hardware_lineage_interfaces`: 0005 (the legacy
  camera device it fixes no longer exists), and 0006-0008 (the Lineage power
  HAL 1.0 and the in-screen fingerprint HAL, which nothing in this device
  uses; the HIDL power HAL 1.0 is still in AOSP).
- **Keyboard haptics** (`hardware_lineage_interfaces` 0011): the legacy
  AIDL vibrator advertised an on-completion callback that it never called,
  so every effect waited out the framework's 1 s callback timeout and the
  next key presses were dropped. It now reports no capabilities, and every
  key tap vibrates.
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
  mediaserver; not needed, the camera works without it).
- **Hardware Menu key** (`frameworks_base` 0016): Lineage's key rebinding
  makes `KeyGestureController` skip `KEYCODE_MENU` and `KEYCODE_ASSIST`.
  In 23.2 that also skips `PhoneWindowManager`, so the Menu key's press and
  long press actions never ran (holding Menu didn't open recent apps). The
  keys now go on to `PhoneWindowManager` like the other keys. The kernel
  side (touch key reported as released when its LED is switched) is fixed
  in `kernel/samsung/smdk4412`.
- **A settled phone after boot** (`frameworks_base` 0017): the boot is
  CPU-bound, and the phone used to reach the home screen while dexopt and
  app starts still kept both cores busy, so the first minute of use was
  slow and prone to ANRs. WindowManager now keeps the boot animation up
  (with the screen on) until the CPU has been under 50% busy for three
  2-second samples, or for 180 s at most.
- **Screen staying on during the boot settle** (`frameworks_base` 0018):
  SystemUI remembers whether the phone was asleep so that a SystemUI
  restart doesn't leave the screen on, but the setting survived reboots.
  After a reboot started with the screen off, SystemUI put the phone back
  to sleep during the boot animation. The state is now only restored
  within the same boot.
- **frameworks/native** (`frameworks_native`):
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
  because the adb host has its own USB transport now.
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
  - no Treble (`build_make` 0004 and `system_linkerconfig`), uncompressed
    APEXes, `link_type_error` as a warning, `TARGET_SPECIFIC_HEADER_PATH`
    (`build_make` 0005 and `build_soong`), which `galaxys2-common` and
    `i9100` use, and the automatic kernel header library.

  The kernel is LZMA-compressed; `lzma` comes from
  `prebuilts/tools-lineage`. The LOS-20.0 `vendor_lineage` 0003-0006 are
  replaced by Soong config variables (see above).
- **Smaller fixes** (`system_libhwbinder`, `system_core` 0006):
  - libhwbinder logs an error instead of aborting when a process shrinks its
    thread pool, as `libbinder` does (`frameworks_native` 0001);
  - in the off-mode charger, the home button also wakes the screen.
- **Legacy kernel fixes** (`system_memory_lmkd`, `frameworks_base` 0013,
  `system_core` 0007):
  - lmkd no longer exits at every boot: with the kernel's low memory
    killer it tried to start PSI monitoring when ActivityManager asked, and
    this kernel has no PSI;
  - `FileIntegrity` skips fs-verity, which this kernel lacks, instead of
    logging a stack trace on every settings and permissions write;
  - fast reboot on legacy devices too.
- **WebView** (`galaxys2-23.2.xml`): WebView 146 and later need OpenGL ES 3,
  which the Mali-400 doesn't have, so they fall back to software raster at
  half the frame rate and lose WebGL. The manifest pins the arm WebView to
  145.0.7632.109, the last release with GPU raster and WebGL 1 on this GPU.
  It gets no further security fixes; recheck GLES 2 support before moving
  it.

## Fixes in the device, kernel and hardware repos

Most i9100 issues are fixed in the forks listed in `galaxys2-23.2.xml`, not
in patches. The main ones:

### Kernel (`kernel/samsung/smdk4412`)

- **Booting Android 16 on Linux 3.0**: `/proc/config.gz` (system_server
  aborts on its VMAP_STACK check without it), `/dev/loop-control` for
  apexd, `CONFIG_XFRM_USER`, namespace dentries that aren't reused, and
  SELinux policies with netlink xperm rules.
- **vmalloc exhaustion after ~20 minutes**: every binder process takes
  about 1 MB of vmalloc on this kernel, and the bootloader's `vmalloc=144m`
  ran out ("Binder driver could not be opened"). The kernel now reserves
  256 MB, and a later `vmalloc=` can no longer shrink it.
- **Hang on reboot or shutdown**: removing a per-app memory cgroup could
  loop forever in `mem_cgroup_force_empty` when a charge was stuck, which
  hung init. The loop now gives up after 1 s.
- **Kernel panic when apps change cgroup**: a thread that exited while
  system_server moved its process to another cgroup hit
  `BUG_ON(!newcg)`. Such threads are skipped now.
- **Kernel panic or frozen display when the screen turns off**: the
  display's kthread_worker still touched a work item after running it,
  and the flush item lives on surfaceflinger's stack, so the worker wrote
  to and woke stale stack memory. The worker no longer touches the item,
  as in Linux 3.8.
- **Native crash backtraces**: `PTRACE_GETREGSET` works on ARM, and
  children of a seizing tracer start in a trap stop, so `crash_dump` gets
  registers and tombstones have backtraces.
- **Wi-Fi drops and unreachable networks**: the gateway of a route is
  looked up in the route's own table, and the socket's UID is passed into
  routing flows, so the per-network routing rules match.
- **Dead auto-rotate**: the K3DH accelerometer's test class device had a
  bogus device number, and ueventd could create `/dev/accelerometer` for it
  instead of the real sensor.
- **Menu key long press**: switching the touch key LEDs while a key was
  held made the controller report a release; LED commands now wait until
  the key is released.
- **Camera**: the M5MO frame rate register runs ~10% fast and is
  calibrated, so 24 and 25 fps video is close to 24 and 25 fps. The FIMC
  capture path selects the camera input when it starts, so recording works
  after a video was played through FIMC.
- **Memory layout**: FIMC0 has enough memory for 720p preview, the ION
  contiguous heap is 52 MB for the hardware encoder and the composer, and
  the FIMD, JPEG and FIMC3 reservations are trimmed to what is used
  (27 MB more RAM). The media regions stay clear of the bootloader logo,
  which no longer turns to noise during boot.
- **ext4 symlink warning**: creating a symlink with a target longer than
  60 characters no longer logs an `inc_nlink` warning (`fs/inode.c:347`).
  The link count is set back to 1 with `set_nlink()`, as in mainline;
  nothing on disk was ever wrong. Fixed on the LOS-20.0 branch first.
- **USB function switch with adb open**: when the USB mode changes while
  adbd keeps its FunctionFS endpoints open, the function is no longer bound
  a second time (`functionfs_bind failed (-77)` and a warning on every
  switch); its strings only get new ids, so they no longer clash with the
  next function's. A failed bind no longer blocks the next one. Fixed on
  the LOS-20.0 branch first.

### Hardware (`hardware/samsung`)

- **HAL updates**: AIDL touch, LiveDisplay and vibrator HALs, libril built
  through `hardware/ril`, and fixes for the current Clang, libutils and
  libcutils.
- **Hardware composer overlays**: the full-screen app layer, the status bar
  and decoded video (scaled on FIMC) are scanned out on FIMD windows
  instead of being composed on the GPU, which roughly halves the jank in
  Settings and app lists.
- **Composer fixes**:
  - a file descriptor leak of one sync fence per frame, which made
    surfaceflinger run out of descriptors after a few hours and every app
    crash in a loop (screen flicker);
  - surfaceflinger crashing while a video resized when the ION heap was
    full: the frame is composed on the GPU until overlay buffers can be
    allocated again;
  - a 480x35 display after surfaceflinger restarted, because the kernel
    sets the mode of fb0 to the size of the last layer in window 0;
  - sheared video shown at a width that isn't a multiple of 16 (e.g. a 4:3
    video in NewPipe), because FIMC wrote the picture with a narrower row
    pitch than the display scanned it out with.
- **gralloc**: reading past the end of cloned buffer handles, which crashed
  apps that rotate while a video plays.
- **Video encoder**: BGRA surface input is converted to NV12 on FIMC
  instead of NEON, and camera HAL frames are encoded in place, which makes
  zero-copy 720p and 1080p recording possible.

### Device (`device/samsung/galaxys2-common`, `device/samsung/i9100`)

- **Bring-up on 23.2**: Soong config variables instead of the old
  `TARGET_*` flags, a VINTF manifest that passes `check_vintf`, the USB 1.3
  and AIDL touch, LiveDisplay and vibrator HALs, a tmpfs `/metadata` for
  aconfigd, the libgps shim calling the real `get_gps_interface`, and many
  SELinux fixes (vendor libraries labelled as same-process HALs, ION,
  GNSS, dhd, sysfs nodes).
- **Watchdog kills of system_server**: a VINTF interface without a service
  (`ISunlightEnhancement`) is no longer declared.
- **Slow shutdown**: the zram swapoff at shutdown, which took minutes on
  this kernel, is skipped.
- **Memory**: zram is 512 MB on both cores, the Dalvik heap overrides and
  userspace lmkd tunables are gone, the low memory killer levels are
  lower, the launcher and WebView are no longer pinned in RAM (69 MB), the
  Go launcher is used, and unused apps are removed (AudioFX,
  DeviceAsWebcam, ImsServiceEntitlement, Seedvault, the Updater,
  SecureElement, printing, live wallpapers and others).
- **Audio**: `audio_effects.xml` is installed where 23.2 looks for it, the
  Codec2 software codecs are used again, and the primary output runs at
  44.1 kHz, which saves resampling most music and video.
- **Camera**: the HAL v1 camera and the legacy provider build and run;
  fixed frame rates (15, 24 and 30 fps) are advertised; recording frames
  are passed as native handles for zero-copy recording up to 1080p; a
  1080p recording deadlock is fixed; preview stalls are recovered from
  instead of leaving the camera "in use" until a reboot. Open Camera
  replaces Aperture.
- **Sensors**: the sensors HAL can control the input sensors, and waits
  for the compass input node, which could appear late and leave
  auto-rotate dead until a reboot.
- **Responsiveness**: a power HAL boosts the CPU to 1.2 GHz on both cores
  for 1 s on touch, 2 s on app launch and 2 s when the screen turns on
  (waking took 1.2-1.3 s instead of 0.75-0.9 s on one core, because the
  second core only came up after the screen was on); ANR timeouts are doubled
  (`ro.hw_timeout_multiplier=2`); the boot animation runs at 30 fps at
  480x160; the stock 60 fps animation cost 13-21 s of boot time.
- **App compilation**: system apps are compiled with `speed`. Installed
  apps are installed with `verify` and compiled with `speed` by background
  dexopt when the phone is idle, because compiling them at install time
  made installing a large app take a minute or more.
- **Wi-Fi**: Software PNO is enabled, so Wi-Fi reconnects with the screen
  off.

## LOS-20.0 patches that are no longer needed

- **Audio** (`frameworks_av` 0024, `hardware_interfaces` 0001-0002): the
  device now uses the audio HAL 7.0, which 23.2 still supports, through
  `hardware/samsung`'s own legacy audio service. The 2.0 HAL and the
  changes to the default audio service aren't needed.
- **Battery life extender** (`hardware_lineage_interfaces` 0009,
  `packages_apps_Settings`, `device_lineage_sepolicy`): `galaxys2-common`
  doesn't ship that HAL anymore.
- **`packages_modules_Permission`** 0001-0002: the second patch reverts the
  first.

## Status

The ROM builds and is in daily use. Working: display with hardware
overlays, GPU, touch and hardware keys, Wi-Fi (also with the screen off),
GPS, sensors and auto-rotate, audio, both cameras with
photos and video recording up to 1080p, hardware video decoding and
encoding, adb, TWRP flashing, charging.

Known limitations:

- Phone calls and SMS are untested (no 2G/3G network available for the
  tests); Bluetooth is unconfirmed.
- 720p60 video decodes at about 10 fps, because the SEC decoder converts
  its tiled output with NEON; 480p plays at 27-30 fps.
- Rotated video (landscape) is composed on the GPU, not on FIMC.
- The hardware decoder (MFC) runs only a few decoders at once (at most
  four, fewer for larger videos); another video fails to start until a
  player releases its decoder.
- WebView stays on 145 (see above).
