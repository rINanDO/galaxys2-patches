# LineageOS 24.0/Android 17 patches for Galaxy S2 (i9100)

These instructions assume that:

- the LineageOS 24.0 sources live (or will live) in `~/android/system`
  (see <https://github.com/LineageOS/android/tree/lineage-24.0>)
- this repository is cloned in `~/android/system/patches/galaxys2-patches`
- `git`, `git-lfs`, `repo` and `xmllint` are installed, plus the usual
  LineageOS build dependencies

All scripts accept the source root as their last argument and default to the
current directory. Run them directly (`./setup.sh`); sourcing them
(`. setup.sh`) also works.

## Quick start: set up everything

```bash
cd ~/android/system
patches/galaxys2-patches/LOS-24.0/setup.sh
```

`setup.sh` does the whole job and can be re-run at any time:

1. `repo init -b lineage-24.0 --git-lfs` if the directory isn't a checkout yet
2. `cleanup.sh`: removes local manifests of other devices and drops any
   previously applied patches (i9100's or another device's)
3. installs `galaxys2-24.0.xml` into `.repo/local_manifests/`
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

To return the tree to plain LineageOS 24.0, without any local manifest or
patches:

```bash
cd ~/android/system
patches/galaxys2-patches/LOS-24.0/cleanup.sh
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
patches/galaxys2-patches/LOS-24.0/apply.sh
patches/galaxys2-patches/LOS-24.0/revert.sh
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
  `galaxys2-24.0.xml`. `galaxys2-common`, `i9100` and the kernel use
  `lineage-24.0`, branched from `lineage-23.2`. `hardware/samsung` uses
  `lineage-24.0-exynos4`, branched from `lineage-23.2-exynos4`, the only
  branch with the exynos4 HALs. The GCC 4.9 toolchain and `vendor/samsung`
  stay on `lineage-20.0` (the only branch with the i9100 blobs).

## What the patches address

The Galaxy S2 is a legacy device: a Linux 3.0 kernel, no Treble, and 2011
blobs. LineageOS 24.0 has dropped much of the compatibility code they depend
on.

- **No BPF in the kernel** (`system_bpf`, `system_netd`,
  `packages_modules_Connectivity`, `packages_modules_DnsResolver`,
  `packages_modules_NetworkStack`): networking, traffic stats, DNS and the
  network stack work without eBPF. The bpfloader no longer panics, and
  NetworkStack gets link and TCP information without the netlink features
  this kernel lacks. These replace the LOS-20.0 `system_bpf`, `system_netd`
  0001, `packages_modules_Connectivity`, `packages_modules_NetworkStack` and
  `frameworks_libs_net` patches (that library is part of Connectivity now).
  `packages_modules_Connectivity` 0014 makes the loaders stop at once when
  the kernel has no bpf() syscall, which starts zygote ~1.4 s earlier.
  New for Android 17, shared with the other legacy device ports:
  `packages_modules_Connectivity` 0009-0013 neutralize netbpfload's kernel
  version checks and stop the local network, loopback and UID permission
  code from aborting without BPF maps, and `packages_modules_NetworkStack`
  0016-0017 adapt `IpClientLinkObserver` to the reverted netlink code.
- **Video freezing after a surface change** (`frameworks_av` 0017): the SEC AVC
  decoder aligns its port height after its buffers were allocated. ACodec then
  set a new surface to that size, and the surface dropped every buffer, so a
  1280x674 video froze on rotation while audio kept playing.
- **Wi-Fi with the screen off** (`packages_modules_Wifi`): the BCM4330 driver
  has no scheduled scan, so hardware PNO is not available and Wi-Fi does not
  connect while the screen is off. The patch defaults the Software PNO flag to
  on, so `config_wifiSwPnoEnabled` in the device's Wi-Fi overlay decides.
  0002 adds `config_wifiDisableIpv6`: the BCM4330 firmware has no Neighbor
  Discovery offload, so a router that checks the phone's IPv6 addresses
  every few seconds woke it about every 4 s and drained the battery at
  25-39 %/h with the screen off (measured on 23.2).
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
- **Keyboard haptics**: the legacy AIDL vibrator advertised an
  on-completion callback that it never called, so every effect waited out
  the framework's 1 s callback timeout and the next key presses were
  dropped. LineageOS has fixed this upstream (the vibrator no longer
  advertises the callback), so it needs no patch here any more.
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
  - 0021 (`ro.displaypower.colorfade`): `config_forceColorFade`, which
    turns ColorFade on despite `ro.config.low_ram`. 0020 (ColorFade EGL
    crash) is replaced by this repo's 0027, which fixes the cause.

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
  2-second samples, or for 180 s at most. Since 0025 it only does that on
  the first boot after a wipe, so the setup wizard starts on a settled
  phone; later boots reach the home screen as soon as it is ready.
- **Screen staying on during the boot settle** (`frameworks_base` 0018):
  SystemUI remembers whether the phone was asleep so that a SystemUI
  restart doesn't leave the screen on, but the setting survived reboots.
  After a reboot started with the screen off, SystemUI put the phone back
  to sleep during the boot animation. The state is now only restored
  within the same boot.
- **Phone process ANR loop on the first boot** (`frameworks_base` 0029): a
  persistent process that dies is restarted with the same process record,
  but the startup timeout of the dead process stayed queued and fired
  against the new one about 20 s into its start. The first boot is slow
  enough that `com.android.phone` then went through five ANRs in a row.
  The timeout is now cancelled when the process is restarted.
- **Timeouts not extended for a waiting process** (`frameworks_base`
  0030): a broadcast, service or job timeout is extended by the time the
  process waited for a CPU, but the native `AnrTimer` read that time from
  `schedstat` as a 32-bit value, which wraps after 4.3 s. The extension
  came out as almost nothing, so on the first boot `com.android.phone`
  missed a broadcast timeout while it was still starting. The times are
  now read as 64-bit values.
- **Broadcast timeouts during app startup** (`frameworks_base` 0031): a
  broadcast sent after a process attached is delivered while
  `Application.onCreate()` is still running, and its timeout runs although
  the receiver can't run yet. On the first boot `com.android.phone` spends
  about 45 s in `onCreate()`, and a SafetyCenter broadcast sent during it
  was declared not responding. The timeout now starts again while the
  process is still starting; the process start timeout covers a process
  that never finishes.
- **Process start timeout on the first boot** (`frameworks_base` 0032):
  when a process hasn't finished starting after the start timeout, the
  timeout is extended by the time the process waited for a CPU, but only
  once. On the first boot `com.android.phone` was still starved when the
  extension ran out and was declared not responding about 5 s before it
  would have finished starting. The timeout is now extended again by the
  time the process waited since the last extension, up to twice the
  timeout in total; a process that is stuck gets no extension.
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
- **Allocator churn during video playback** (`frameworks_native` 0006,
  `frameworks_av` 0019): native processes free memory with a decay time
  of 0, so SurfaceFlinger mapped and zeroed a fresh page about 90 times a
  second, and the AAC decoder in `media.swcodec` did the same with two
  buffers per frame. Both now keep freed memory for a second, as apps do.
  At 800 MHz during 480p playback, SurfaceFlinger's main thread drops from
  about 22% to 18% of one core.
- **Recorded videos with a short audio track** (`frameworks_av` 0020-0021):
  in 1080p recordings the audio could end several seconds before the
  video (5-7 s of 40-50 s after NewPipe had played), and the sound ran
  ahead of the picture. The HAL captured all audio, but camera recording
  keeps both cores busy and the recorder's loopers ran at the default
  priority. AudioSource's AudioRecord callback waited behind them for its
  lock, AudioFlinger dropped the audio it couldn't deliver, and nothing
  filled the gap, because `getInputFramesLost()` only counts what the HAL
  lost. 0020 runs the recorder looper and the audio encoder's looper at
  audio priority; 0021 fills the gap after an overrun with silence, so the
  audio stays in sync. With two busy loops during a 45 s recording, the
  audio track lost 17 s before and nothing after.
- **Widevine playback in ExoPlayer apps** (`frameworks_av` 0022): the
  legacy Widevine plugin is a drm@1.0 plugin, which has no session
  security level, and `MediaDrm.getSecurityLevel()` failed with
  `ERROR_DRM_CANNOT_HANDLE`. ExoPlayer asks for it to choose a decoder,
  so NPO Start stopped after the ad with error 35000 ("configuratiefout").
  For drm@1.0 plugins the framework now reports the device level from the
  plugin's `securityLevel` property (L3 here). NPO Start plays its
  episodes on the hardware H.264 decoder.
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
  - `-fuse-ld=lld` in the kernel's `HOSTCFLAGS` (`vendor_lineage` 0003),
    because Linux 3.0 links its host programs with `HOSTCFLAGS` only;
  - no Treble (`build_soong` 0002 and `system_linkerconfig`): Android 17
    removed `PRODUCT_FULL_TREBLE`, so `ro.treble.enabled` is now set to
    false in `gen_build_prop.py`. Uncompressed APEXes, `link_type_error` as
    a warning, `TARGET_SPECIFIC_HEADER_PATH` (`build_make` 0004 and
    `build_soong` 0001), which `galaxys2-common` and `i9100` use, and the
    automatic kernel header library;
  - GCC kernel builds (`vendor_lineage` 0002): reverts "kernel: Rip out GCC
    support", because Linux 3.0 can't be built with Clang.

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
- **Samsung libril** (`hardware_ril`): with
  `$(call soong_config_set,ril,samsung_libril,true)` libril is built from
  `hardware/samsung`'s sources, which add Samsung's vendor requests and
  modem quirks, and linked against IRadio 1.2 to 1.4.
- **Signal icon with one SIM** (`frameworks_opt_telephony`): without
  IRadioConfig, PhoneSwitcher sends no data switch command on a single SIM
  device and so never published the active data subscription. SystemUI then
  showed an exclamation mark on the signal icon, although mobile data
  worked. The switch is now finished without a command.
- **Messaging with a new SIM** (`packages_apps_Messaging`): the SIM's
  display name is still empty while a newly inserted SIM is set up, and
  Messaging crashed with a NullPointerException on the first boot with the
  SIM. It stores an empty name until the next refresh fills it in. Same
  change as on 20.0, where it is tested; the new-SIM case is not tested on
  24.0.
- **Storage after a framework restart** (`system_vold`): vold detaches the
  old FUSE mount on `/storage/emulated` when it unmounts the volume. On this
  kernel it was left behind on top of the new one, and the adb shell and
  native daemons got "Transport endpoint is not connected" for `/sdcard`.
  24.0 unmounts through `UnmountUserFuseEnhanced()`, so the detach runs
  there too; the 20.0 change only hooked `UnmountUserFuse()`, which 24.0
  no longer calls. Tested after a framework restart.
- **WebView** (`galaxys2-24.0.xml`): WebView 146 and later need OpenGL ES 3,
  which the Mali-400 doesn't have, so they fall back to software raster at
  half the frame rate and lose WebGL. The manifest pins the arm WebView to
  145.0.7632.109, the last release with GPU raster and WebGL 1 on this GPU.
  It gets no further security fixes; recheck GLES 2 support before moving
  it.

## Fixes in the device, kernel and hardware repos

Most i9100 issues are fixed in the forks listed in `galaxys2-24.0.xml`, not
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
- **Slow mmap in apps with many mappings**: Linux 3.0 found a free address
  range by walking the vma list, and media apps have thousands of vmas
  (NewPipe about 3700) while Codec2 maps an ION buffer per audio frame.
  The `vm_unmapped_area()` search from Linux 3.8 is backported, with its
  rbtree gap tracking built on 3.0's `rb_augment_*` helpers. During 720p60
  playback in NewPipe, `find_vma` dropped from about 4% of all CPU time to
  below 0.3%.
- **Hang on reboot or shutdown**: removing a per-app memory cgroup could
  loop forever in `mem_cgroup_force_empty` when a charge was stuck, which
  hung init. The loop now gives up after 1 s.
- **swapoff on zram never returns**: `sys_swapoff()` waits for swap
  allocators with `while (flags >= SWP_SCANNING)`, which only works while
  `SWP_SCANNING` is the highest swap flag. `SWP_FAST` had been added above
  it, and zram sets it, so swapoff spun forever however little was in
  swap. `SWP_FAST` now uses a lower bit. Swapping back in is still slow on
  this kernel (about 1 MB/s), so shutdown keeps skipping it.
- **Second 1080p decoder**: MFC exposes its free memory per port
  (`IOCTL_MFC_GET_FREE_MEM`) for the decoder's check below, and logs the
  frame buffers each decoder gets.
- **Battery values in sysfs**: `voltage_now` and `capacity` read stack
  garbage (often negative), because the fuel gauge driver reads the
  property value as an input selector and sysfs passed it uninitialised.
  The value is zeroed first.
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
  after a video was played through FIMC. When the camera app is killed
  while recording, FIMC2 is still stopped, so later recordings don't fail.
  When another user of the same FIMC (the decoder's colour conversion)
  closes it, the capture keeps running; only the file that set the capture
  up, or the last user, stops it and unloads the sensor.
- **720p60 video after a quality switch or seek**: on Exynos4210 the bus
  level also sets the FIMC clock, and 720p decoding only locked the bus at
  L1 (FIMC at 133 MHz), where converting a frame takes 9-11 ms instead of
  7.3 ms. A bus lock could also lower the bus below the level the monitor
  had set, and the monitor, which only runs on cpufreq changes, never raised
  it again while the CPU stayed at 1.2 GHz. The player showed about 9 fps
  for 20-30 s while it caught up. Locks now only raise the bus, and MFC
  locks L0 from 720p up; the catch-up takes 3-5 s.
- **Memory layout**: FIMC0 has enough memory for 720p preview, the ION
  contiguous heap is 52 MB for the hardware encoder and the composer, and
  the FIMD, JPEG and FIMC3 reservations are trimmed to what is used
  (27 MB more RAM). The media regions stay clear of the bootloader logo,
  which no longer turns to noise during boot.
- **Black screen after waking up**: when the composer put an overlay on
  fb0's own window, the framebuffer driver left fb0 pointing at that
  buffer. After the screen was off, the framebuffer target was mapped from
  the wrong memory, so everything composed on the GPU (lock screen,
  launcher) stayed black while the panel was on. fb0 now keeps its own
  memory.
- **Initramfs device nodes**: the static nodes match
  `CONFIG_MMC_BLOCK_MINORS=12`: HIDDEN (`mmcblk0p12`) is 259:0 and the SD
  card is 179:12/179:13. Stage 1 still reads HIDDEN's number from sysfs,
  because the kernel hands out 259:x numbers at boot.
- **ext4 symlink warning**: creating a symlink with a target longer than
  60 characters no longer logs an `inc_nlink` warning (`fs/inode.c:347`).
  The link count is set back to 1 with `set_nlink()`, as in mainline;
  nothing on disk was ever wrong.
- **USB function switch with adb open**: when the USB mode changes while
  adbd keeps its FunctionFS endpoints open, the function is no longer bound
  a second time (`functionfs_bind failed (-77)` and a warning on every
  switch); its strings only get new ids, so they no longer clash with the
  next function's. A failed bind no longer blocks the next one.
- **USB gadget DMA**: the USB controller driver stops an endpoint's DMA
  before it gives a cancelled request back. Before, when adbd exited or the
  USB function was switched, the host's next adb packet could be written
  into a buffer that had already been freed, which corrupted memory and
  panicked the kernel.
- **Modem and Wi-Fi wakeups**: the wakelock to wakeup source conversion
  rounded every hold shorter than a second down to 0 (HZ=200), so the AP
  could suspend before rild read an incoming call or SMS, and the Wi-Fi
  rx/ctrl holds did nothing. When the modem woke the AP during a suspend,
  the HSIC link code kept the AP awake until the link suspended again,
  which could take most of the time on battery; it now aborts the suspend
  with a 500 ms wakeup event instead.
- **Stalls from swapping instead of killing cached apps**: the
  lowmemorykiller counted mapped file pages, the code of running apps, as
  free cache, so the cache never fell below the minfree levels while a
  dozen cached apps sat in zram. The phone froze for seconds at a time
  and several processes hit input ANRs at once. For cached apps (adj 900
  and up) mapped pages no longer count; the other levels are unchanged, so
  the keyboard and the previous app are kept as before.
- **Stalls during video playback**: when the contiguous ION heap was full,
  gralloc's fallback heap asked for 1 MB and 64 KB chunks with reclaim
  allowed. Highmem, fragmented by zram, never has such blocks, so kswapd
  kept evicting the whole zone and swapped out every app while hundreds of
  MB were free (load up to 29, UI freezes up to 40 s). Those chunks are now
  only taken when they are free already.
- **SD cards not mounting**: vold mounts FAT cards with `time_offset=`,
  which Linux 3.0 didn't know, so every card was "unmountable". The option
  is backported from Linux 4.19, so cards mount and file times use the
  device's time zone.
- **Phone freezing completely (ashmem deadlock)**: ashmem copied a
  buffer's name from or to the app while holding its global lock. When that
  copy had to fault memory in while another thread of the same app was in
  `mmap()`, both threads waited on each other forever, and system_server,
  SystemUI and the watchdog then blocked on the lock too. The copies and
  `read()` now happen outside the lock, as in later Linux versions.

### Hardware (`hardware/samsung`)

- **HAL updates**: AIDL touch, LiveDisplay and vibrator HALs, libril built
  through `hardware/ril`, and fixes for the current Clang, libutils and
  libcutils.
- **IRadio 1.4** (libril): Android 16 and later no longer support IRadio
  below 1.4, so the 1.1 service left the phone without SIM, network, calls
  and data. The 1.2 to 1.4 requests map onto the legacy RIL requests, and
  responses and indications use the 1.2 and 1.4 variants. The ICCID, which
  the legacy card status lacks and without which no subscription is
  created, is taken from the framework's own read of EF_ICCID. A failed
  data call no longer makes the framework retry in a tight loop.
- **Call audio** (`libsecril-client`): built from source and installed to
  `/vendor/lib`. It takes its wake lock through `/sys/power/wake_lock`
  instead of the SystemSuspend service, which the audio HAL can't reach on
  `/dev/vndbinder`; the proprietary library blocked the audio HAL at the
  end of every call.
- **Hardware composer overlays**: the full-screen app layer, the status bar
  and decoded video (scaled on FIMC) are scanned out on FIMD windows
  instead of being composed on the GPU, which roughly halves the jank in
  Settings and app lists. FIMC also rotates hardware-decoded video, so
  full-screen landscape video no longer keeps the GPU 65-85% busy
  (`debug.hwc.video_rotation=0` switches that off). The camera preview is
  not rotated on FIMC: the camera keeps FIMC2 for recording while it is
  open, and recordings stayed empty.
- **Composer fixes**:
  - sync fence leaks: the HWC1 adapter hands the composer a new dup() of
    every layer's acquire fence on each frame, also for layers composed on
    the GPU, and the composer only closed those of layers on a FIMD window
    (not the framebuffer target when every layer was on an overlay, nor
    those of layers whose FIMC operation failed). Surfaceflinger ran out of
    its 32768 descriptors after a few hours: every app crashed in a loop
    (screen flicker), or after a screen-off SystemUI crashed in a loop
    (`Failed to initialize display event receiver. status=-24`) and the
    screen stayed black. Every acquire fence still open is closed once the
    frame is posted now;
  - surfaceflinger crashing while a video resized when the ION heap was
    full: the frame is composed on the GPU until overlay buffers can be
    allocated again;
  - a 480x35 display after surfaceflinger restarted, because the kernel
    sets the mode of fb0 to the size of the last layer in window 0;
  - sheared video shown at a width that isn't a multiple of 16 (e.g. a 4:3
    video in NewPipe), because FIMC wrote the picture with a narrower row
    pitch than the display scanned it out with;
  - video shaking and flickering while the contiguous ION heap was full
    (for example NewPipe switching from 480p to 720p while a paused app
    held decoder buffers): gralloc then gives some of the decoder's
    buffers memory without a physical address, and the composer showed
    those frames on the GPU and the others on FIMC, which scale
    differently. The video stays on the GPU while such buffers show up,
    and for about 2 s after the last one. Tested with the heap filled by
    a test tool, both full and with part of the decoder's buffers still
    contiguous: the video stays on the GPU in every frame and plays
    correctly;
  - a black screen while a video played as a small thumbnail (30 px wide):
    the kernel rejects windows narrower than 128 bytes and every frame
    failed. Such layers are composed on the GPU now (tested with a video
    shown 23 px wide in Glimpse);
  - a kernel panic (the phone rebooted) when the camera opened while FIMC2
    rotated a layer: once the camera had set FIMC2 up for capture, the
    kernel sent the composer's interrupt to the capture handler.
- **gralloc**:
  - reading past the end of cloned buffer handles, which crashed apps that
    rotate while a video plays;
  - a cloned handle registered after the original was freed: the UMP
    secure ID is gone by then, and `media.swcodec` aborted in libUMP. The
    buffer is imported from the clone's ION fd again;
  - no video thumbnails (MediaMetadataRetriever frame extraction failed
    with FrameDecoder error -110) while another app played a 1080p video:
    with MFC busy, the frame comes from the software decoder, whose
    buffers gralloc fell back to UMP-only memory for once the contiguous
    ION heap was full, and `media.swcodec` can't import a buffer without
    an ION fd. gralloc now takes non-contiguous ION memory first; it has
    no physical address, so FIMC and the composer leave it to the GPU.
    Video from the software decoder plays correctly from such buffers
    (tested with the contiguous heap filled).
- **Video encoder**: BGRA surface input is converted to NV12 on FIMC
  instead of NEON, and camera HAL frames are encoded in place, which makes
  zero-copy 720p and 1080p recording possible.
- **Video decoder**: the NV12T output of the decoders is converted on FIMC1
  straight into the display buffer (`BOARD_USE_CSC_FIMC`) instead of NEON,
  which cut media.codec from 30-43% to about 14% of the CPU during 720p
  playback, and portrait video drops fewer frames. FIMC1 is the one FIMC
  nothing else uses: the rear camera captures on FIMC0, and the front
  camera and the composer use FIMC2. The OSAL now looks up
  the plane addresses of gralloc buffers, and libfimc passes the
  destination with `V4L2_CID_DST_INFO` and knows the tiled formats.
- **Two apps playing 1080p video**: a 1080p H.264 decoder takes 7 frame
  buffers, about 17.7 MB of MFC's 34 MB port B, so a second one doesn't
  fit. The MFC only allocated them at the first frame, after `start()`,
  and the app showed a playback error (for example Glimpse while a paused
  NewPipe player held the decoder). The H.264 decoder now checks the free
  MFC memory when the app configures it and reports `NO_MEMORY`; Android
  then reclaims the decoder from a background app and retries, or the app
  falls back to the software decoder. A web page whose decoder is
  reclaimed stops its video until it is reloaded.
- **GNSS wakelocks**: the GNSS service used `/dev/vndbinder` as its default
  binder, so libpower couldn't find `ISystemSuspend` and the HAL got no
  wakelocks during a fix (`Failed to get SystemSuspend service`). It stays
  on `/dev/binder` now; the legacy GPS library doesn't use binder.

### Device (`device/samsung/galaxys2-common`, `device/samsung/i9100`)

- **Bring-up on 23.2**: Soong config variables instead of the old
  `TARGET_*` flags, a VINTF manifest that passes `check_vintf`, the USB 1.3
  and AIDL touch, LiveDisplay and vibrator HALs, a tmpfs `/metadata` for
  aconfigd, the libgps shim calling the real `get_gps_interface`, and many
  SELinux fixes (vendor libraries labelled as same-process HALs, ION,
  GNSS, dhd, sysfs nodes).
- **Watchdog kills of system_server**: a VINTF interface without a service
  (`ISunlightEnhancement`) is no longer declared.
- **Slow shutdown**: the zram swapoff at shutdown, which takes minutes on
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
  replaces Aperture. Preview frames are copied to the window before the
  buffer goes back to FIMC0, so the preview no longer tears. Recording
  frames are dequeued in their own thread with their own timestamp, so a
  slow preview frame no longer makes the frame spacing uneven, and only
  metadata slots cameraserver has given back are used (cameraserver crashed
  in `writeNativeHandle()`).
- **Sensors**: the sensors HAL can control the input sensors, and waits
  for the compass input node, which could appear late and leave
  auto-rotate dead until a reboot.
- **Telephony**: IRadio 1.4 is declared in the VINTF manifest.
  `libsecril-shim`:
  - data calls always ask for an IPv4 context, because Samsung's RIL can't
    configure the dual-stack context the network grants for an `IPV4V6`
    APN and then leaves the modem rejecting every retry until a reboot;
  - voice reports GSM instead of a fixed UMTS while data is on GPRS/EDGE,
    and an out-of-bounds read and the hex LAC/CID parsing in the same code
    are fixed;
  - the CDMA and EVDO signal values, which the RIL fills with the GSM
    signal level, are unavailable, so telephony uses the GSM signal.

  The audio HAL may take kernel wake locks (for `libsecril-client`), and the
  call volume has 5 steps, as the modem gets quieter above level 5.
- **Responsiveness**: a power HAL boosts the CPU to 1.2 GHz on both cores
  for 1 s on touch, 2 s on app launch and 2 s when the screen turns on
  (waking took 1.2-1.3 s instead of 0.75-0.9 s on one core, because the
  second core only came up after the screen was on); ANR timeouts are doubled
  (`ro.hw_timeout_multiplier=2`); the boot animation runs at 30 fps
  (every 2nd frame) with full-size 480x160 frames; the stock 60 fps
  animation cost 13-21 s of boot time.
- **App compilation**: the kernel has no userfaultfd, so ART runs the CC
  collector, and code compiled for the default CMC collector is rejected
  (`Read barrier state mismatch`): the boot image was compiled again on the
  phone and the system apps ran verified only. AOSP's
  `default_art_config.mk` overrides `PRODUCT_ENABLE_UFFD_GC`, so
  `galaxys2-common` sets `OVERRIDE_ENABLE_UFFD_GC := false`. SystemUI, the
  launcher and the setup wizard are compiled with `speed`; the other system
  apps are verified (with `speed` they took 500 MB, more than /system
  holds). Installed apps are installed with `verify`, because compiling
  them at install time made installing a large app take a minute or more.
  Background dexopt compiles apps with `speed-profile` when the phone is
  idle and charging, using the profile ART records while the app runs;
  after an update, `adb shell cmd package bg-dexopt-job` does it at once
  (about 5 minutes). `speed` made the code of large apps much bigger (89
  MB of dex: 15 MB odex with `speed-profile`) and their cold starts slower.
- **Wi-Fi**: Software PNO is enabled, so Wi-Fi reconnects with the screen
  off. Wi-Fi uses IPv4 only, so router neighbor checks no longer keep the
  phone awake. The Wi-Fi driver reads and writes `/data/.psm.info`,
  `.wifiver.info` and `.mac.info` from netd; those files are labelled
  `wifi_data_file` (init runs `restorecon` after creating them) and netd
  may use them. Its copy of the MAC to `/efs/wifi/.mac.info` stays blocked
  (and isn't logged), so `/efs` keeps the factory data.
- **SELinux**: `mediacodeclist_generator` may read the `media.stagefright.*`
  properties (`media_config_prop`). The GNSS HAL may take wakelocks
  (`wakelock_use`), and its probes for Samsung factory test files in
  `/data/data` aren't logged. With Magisk's Zygisk, zygote's attempt to
  open the property areas read-write (Magisk's property code tries that
  before read-only) isn't logged either; zygote stays read-only.
  `/sys/kernel/wakeup_reasons` is labelled in `file_contexts` (genfscon
  doesn't label sysfs on this kernel; ueventd's restorecon does), so
  system_suspend may read the wakeup reason after a resume. The lookups
  for an AIDL graphics allocator (mediacodec, camera HAL) and WebView's
  lookup of the content capture service aren't logged; both fall back.
- **GPS shim**: no positions, cell IDs or movement details in logcat. The
  jitter filter, which repeats the last position while the phone doesn't
  move, compares the horizontal distance in metres with its thresholds; it
  added up raw degree and altitude differences, so only altitude changes
  counted as movement.

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

## Changelog

The changes and fixes in each build, newest first. Each build is named
after its zip, `lineage-24.0-<date>-UNOFFICIAL-i9100.zip`.

### 20261128 (28 November 2026)

- Kernel: no more complete freezes from an ashmem deadlock, seen while
  starting playback in DS audio under memory pressure.

### 20261127 (27 November 2026)

- Kernel: SD cards mount again. The FAT driver now accepts vold's
  `time_offset=` option, and file times use the device's time zone.

### 20261126 (26 November 2026)

- Kernel: the lowmemorykiller kills cached apps instead of letting them
  thrash in zram, which caused multi-second freezes and input ANRs.
- Kernel: no more freezes and swapping during video playback when the
  contiguous ION heap is full (gralloc's fallback no longer wakes kswapd
  for 1 MB and 64 KB chunks).
- `frameworks_av` 0022: Widevine content plays in ExoPlayer apps; NPO
  Start no longer stops after the ad with error 35000.

## Status

Work in progress. The ROM builds and boots to the home screen on 24.0
(SELinux enforcing). Tested working: display, Wi-Fi, camera preview, video
recording with sound, hardware video playback (720p60 in NewPipe at about
50-58 fps, limited by the CPU), GPS (first fix in about 150 s cold, 30 s
warm, without assisted GPS), phone calls with call volume, SMS, mobile data
(GSM/EDGE), Bluetooth audio (A2DP), `adb install`, `adb reboot recovery`,
Magisk root.

Android 17 changes that needed fixes on top of the 23.2 port:

- **Build**: `build_soong` 0003 (no generated filesystem modules without a
  vendor partition), `vendor_lineage` 0004 (no ramdisk -> kernel dependency
  with `BOARD_CUSTOM_KERNEL_MK`), `frameworks_av` 0018 and `frameworks_base`
  0019 (HALv1 camera code against the current camera interfaces),
  `hardware/samsung` (libperfmgr namespace, HIDL consumerir removed) and
  `galaxys2-common` (target-level 7, legacy HALs in the framework matrix).
- **SurfaceFlinger abort at boot**: `system_sepolicy` 0001 (label `/dev/ion`
  again) and `legacy_gralloc` in `galaxys2-common`.
- **system_server watchdog loop**: `bionic` 0010. 24.0 made the text
  relocation check read only the process SDK, so the per-library
  `SDK_VERSION_OVERRIDES` stopped working and the GPS, RIL and sensor blobs
  were refused.
- **App starts stalling**: `system_zygote` 0001-0003. The native-app zygote
  aborts on legacy cgroups and on capability bounds of old kernels.
- **No IP address on Wi-Fi**: kernel `rtnetlink` ignores attributes it
  doesn't know (`IFA_FLAGS`) instead of failing `RTM_NEWADDR`.
- **Camera hangs on the first preview frame**: `frameworks_native` 0005.
  Without a vendor partition, vendor executables load the system libbinder,
  whose binder stats observer deadlocked `vndservicemanager`.
- **Shutdown takes 5 minutes, `adb reboot recovery` boots Android**:
  `system_core` 0008 skips the zram swapoff. It hung because of the swap
  flag order in the kernel (fixed there); swapping back in is still too
  slow for shutdown.
- **Video recording fails** (Codec2 software codecs can't allocate):
  `libion,legacy_impl` in `galaxys2-common` and kernel ION ioctl layouts of
  3.4+ for alloc and import.
- **Wi-Fi doesn't reconnect on its own**: Android requests all 14 channels
  because it can't read the band list from this kernel, and the firmware
  (`ccode=GB`) has no channel 14, so the kernel rejected every automatic
  scan. Kernel `nl80211` now skips channels the driver doesn't register.
- **Apps always told memory is low**: the kernel has no `MemAvailable`
  (added in 3.14), so `ActivityManager.MemoryInfo` reported `availMem = 0`
  and `lowMemory = true`. Backported to `/proc/meminfo`.
- **Old apps can't be installed**: Android 17 refuses apps that target an
  SDK below 24. `frameworks_base` 0020 adds a property that turns the block
  off for every installer, and `galaxys2-common` sets it to 1 by default,
  so old apps install from a file manager or app store. To block them
  again (userdebug builds; the shell can set it, apps can't):

  ```
  adb shell setprop persist.debug.pm.allow_low_target_sdk 0
  ```

  A value set like this is kept in `/data` and overrides the default, also
  after a ROM update. Installed apps keep working when it's 0.
- **`adb install` fails with `splice failed: EINVAL`**: the installer
  splices the APK from adbd's unix socket into the file, and kernels before
  4.2 can't splice from a unix socket. `frameworks_base` 0021 falls back to
  a plain copy when the first splice fails.
- **zram compressed on one core**: fs_mgr opens `max_comp_streams`
  read-only, so the fstab option never applied. `galaxys2-common` writes it
  from init before `swapon_all`; it can't change after that.
- **Cached apps keep their GPU memory**: Android 17 no longer sends
  `TRIM_MEMORY_BACKGROUND` to cached apps, so without a cached app freezer
  they kept their HWUI rendering context. Mali memory can't be swapped
  (2.5-11.5 MB per app). `frameworks_base` 0022 sends it once when a
  process that showed UI becomes cached, on low-RAM devices.
  `galaxys2-common` also sets HWUI's `extremelowram` memory policy, which
  destroys an app's GPU context 5 s after all its windows stop. That covers
  the app last left and apps at foreground service priority (a music app
  playing in the background), which Android 17 doesn't send background
  trims to. Reopening an app takes about 100-200 ms longer.
- **SystemUI work on a rotation** (`frameworks_base` 0023-0024): SystemUI
  rebuilt the lockscreen layout on every configuration change, also while
  the phone was unlocked, and extracted the media player colors again each
  time an app republished the same artwork. 0023 defers the lockscreen
  refresh until a transition to the lockscreen starts, and 0024 reuses the
  colors while the artwork's pixels are unchanged. SystemUI's CPU time for
  a rotation during video playback went from about 40-50 % to 20-28 % of a
  core over 6 s.
- **Slow volume panel** (`frameworks_base` 0026): SystemUI built the volume
  dialog again on every key press and read the Lineage panel-side setting
  from system_server each time it showed, which took up to 840 ms during
  video playback. 0026 keeps the dialog while the configuration is
  unchanged and reads the setting once. With a video playing, the panel
  still takes about 0.5-1 s to appear; the rest is CPU contention.
- **Screen fade** (`frameworks_base` 0027-0028): ColorFade used to be off,
  since it crashed when the screen turned off. It destroyed its EGL surface
  while the surface was still current, so libEGL disconnected the window
  while the Mali driver still held a dequeued buffer. 0027 destroys the
  surface after the context is detached. The screen now fades out with a
  black layer (`config_animateScreenLights`) and, with 0028, fades in
  again: the fade steps wait until each step is on the display, since the
  display pipeline stalls for 100-300 ms after the panel turns on and a
  timed animation lost most of its frames.
- **Video playing too fast without sound**: once a pcm write failed, every
  later write failed too and returned at once, so players that follow the
  audio clock raced through the video. `galaxys2-common`'s audio HAL now
  closes and reopens the pcm device after a failed write, and waits for as
  long as the buffer would have played.
- **Root**: Magisk installs from TWRP; see below.

Known issues:

- A worn battery makes the modem reset itself (`PA EVENT : reset =1, pa=0`
  in the kernel log) when it starts transmitting, during network
  registration or right after dialing: the cell voltage sags below about
  3.3 V under the transmit load. Such a battery read 3.33 V at 80 % charge
  as a call started; with a healthy battery calls work.
- A board leak drains the battery while the phone sleeps. Two of three
  test phones lost about 4-4.5 % per hour with the screen off, in airplane
  mode, while a third lost about 1 % per hour on the same build. Suspend
  itself was normal on all of them: awake under a minute per hour, no wake
  locks, and the same sleep register and regulator states as on LOS 14.1.
  Swapping batteries didn't move the drain, because the leak is in the
  phone: across the battery connector the two draining phones measured
  89.6 Ω and 109.4 Ω, the good one 64.6 kΩ. At about 3.9 V, 90-110 Ω
  draws 35-45 mA, about 2-3 % per hour of a 1650 mAh battery, whatever
  the software does.

  To check a phone that drains too fast:

  1. Switch the phone off, unplug USB and take the battery out.
  2. Set a multimeter to resistance.
  3. Put the red probe on pin 2 (+) and the black probe on pin 4 (-) of
     the phone's battery connector.
  4. Read the value once it has settled; capacitors on the board make it
     climb for a moment.

  A healthy board reads tens of kΩ. A reading of a few hundred Ω or less
  is a leak in the phone; a new battery or another ROM won't fix it.

## Root with Magisk

The S2 has no boot image: Android's ramdisk is built into the zImage, so
Magisk can't patch it in place. Instead, the kernel's stage 1 init boots a
ramdisk from a slot on the HIDDEN partition when the slot holds a valid
copy of its own ramdisk, and a TWRP zip writes the Magisk-patched copy
there. The KERNEL partition isn't touched.

1. Build the zips once; they hold only the install script and work with
   any Magisk release:

   ```
   device/samsung/galaxys2-common/magisk/make-magisk-zips.sh <output-dir>
   ```

   This makes `i9100-magisk-installer.zip` and
   `i9100-magisk-uninstaller.zip`. Copy them to a folder on the phone
   together with a Magisk release APK, for example `/sdcard1/ROMS/Magisk/`.
2. Boot TWRP with a kernel that has the slot (it leaves the stock ramdisk at
   `/.stock-boot.cpio`) and flash the installer zip. It installs the newest
   `Magisk*.apk` in its own folder (by the APK's version code; a sideloaded
   zip searches `/sdcard1/ROMS/Magisk`, `/sdcard/ROMS` and
   `/sdcard/Download`), builds the boot image Magisk patches on the phone,
   and runs Magisk's own flash script on the stock ramdisk, without the
   addon.d step. It passes the pre-init partition (`mmcblk0p10`), which
   Magisk only detects by itself in Android, and names FACTORYFS `system`
   for Magisk, which TWRP 3.6 lists as `/system_root`.
3. Boot Android and install `/sdcard/ROMS/Magisk.apk`, or use
   `adb install`.

Notes:

- Don't use Install or Reinstall for Magisk in the app: it would patch the
  KERNEL partition. To update Magisk, download the new APK next to the
  installer zip on the phone and flash the zip again; no PC is needed.
- A ROM build with a different ramdisk turns the slot off by itself (it was
  made from another ramdisk) and boots without Magisk; flash the installer
  zip again. Builds with the same ramdisk keep Magisk.
- The uninstaller zip clears the slot and removes Magisk from `/data/adb`.
- Magisk 31.1 and later don't ask for root with a popup anymore: `su` from
  an app that isn't in the Superuser tab is refused straight away (`su:
  request rejected (<uid>)` in `/cache/magisk.log`). Add every app that
  needs root, and the ADB shell, in the Superuser tab first. Old root apps
  may also crash or hang when refused instead of reporting it.

The 24.0 port started from the 23.2 one, where the ROM was in daily use;
several sections above still describe that bring-up. See
`../LOS-23.2/README.md` for 23.2's working features and known limitations.
