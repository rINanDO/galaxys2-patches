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
  `system_libhwbinder`, `system_core` 0002, 0004): `gpuservice` is
  disabled (its GPU memory accounting needs BPF), libbinder and libhwbinder
  log instead of aborting when a process shrinks its thread pool, installd
  operations have no timeout, and init no longer treats a failure to create
  a process group as fatal. This kernel has no cgroup v2, so libprocessgroup
  finds a service's processes in its memcg group (`/dev/memcg/apps`).
  Before, init killed nothing when it stopped a service, so after a
  surfaceflinger crash zygote never restarted and the screen stayed black.
- **Storage after a framework restart** (`system_vold`): vold detaches the
  old FUSE mount on `/storage/emulated` when it unmounts the volume. On this
  kernel it was left behind on top of the new one, and the adb shell and
  native daemons got "Transport endpoint is not connected" for `/sdcard`.
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
- **Package manager boot warnings** (`frameworks_base` 0024-0025): every boot
  logged about 40 "was user id 0 but is now user ... I am not changing its
  files so it will probably fail!" errors and "Failed to migrate
  com.android.sdksandbox ... (code 2)", and appended them to
  `/data/system/uiderrors.txt`. Neither was a real problem: packages with a
  shared user id get their app id only when they are attached to the shared
  user, and the SDK sandbox has no app storage to migrate. Both are no
  longer reported.
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
  - the build number (`ro.build.version.incremental`) and build date in
    `build.prop` are updated on every build (`build_make` 0002). Before,
    incremental builds kept the values from the last time kati ran, and the
    package manager, which names its parser cache after the build number,
    kept stale package information after a dirty flash.
- **Off-mode charger** (`system_core` 0003): the home button also wakes the
  screen.
- **Browser downloads** (`packages_apps_Jelly` 0001): a window opened by a
  script or a button (`window.open()`, a form with `target=_blank`, most
  download buttons) used to give an empty tab and no download. Jelly now
  follows the address that window loads, so the download prompt appears.
- **Browser download names and POST downloads** (`packages_apps_Jelly`
  0002): file names come from the whole `Content-Disposition` header
  (`filename*=UTF-8''...`, `inline`, unquoted names, extra parameters) or
  from `<a download="...">`, not from the URL. Downloads that answer a
  form POST are sent again as the same POST by Jelly (cookies only for a
  same-origin form) instead of a GET that the server refuses, and blob:
  and data: downloads are saved instead of dropped. These downloads go
  straight to Downloads with a message instead of a DownloadManager
  notification. The POST is sent twice (WebView's own request turns into
  the download), so a form with a one-time token can still fail, and
  forms that upload files still use GET.
- **Messaging with a new SIM** (`packages_apps_Messaging` 0001): the SIM's
  display name is still empty while a newly inserted SIM is set up, and
  Messaging crashed with a NullPointerException on the first boot with the
  SIM. It stores an empty name until the next refresh fills it in.
- **Wi-Fi reconnect with the screen off** (`packages_modules_Wifi` 0001-0002): the
  bcmdhd driver has no scheduled scan, so Android's PNO scans fail. With the
  screen off, Wi-Fi used to stop scanning after 5 failures and stay
  disconnected until the screen came on, for example after the country-code
  disconnect a minute after boot. When PNO is unsupported, Android now runs a
  normal scan while the screen is off and Wi-Fi is disconnected.
  0002 backs these scans off: the interval starts at 2 minutes and doubles
  up to 10 minutes, and starts over when the screen turns off or Wi-Fi
  disconnects. A full scan measured 4.5 s of radio time and 0.4 s of CPU,
  about 0.11 mAh, so every 2 minutes cost about 3.4 mAh an hour (5% of the
  battery a day away from a saved network); at 10 minutes it is about
  0.7 mAh an hour. The alarm is inexact, so the real gaps are about 1.75
  times longer (measured 3.5, 7 and 14 minutes), and with the screen off a
  saved network can take up to about 17 minutes to be rejoined.

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
- **s3cfb kthread worker**: a work item is no longer touched after it has
  run, because the display driver may free it by then (upstream
  `fc039483db7f`).
- **ION contiguous heap** (cherry-picked from the LOS-23.2 branch): grown
  from 34 MB to 52 MB (18 MB less RAM), so 1080p video frames fit in it and
  the composer can show 1080p video as an overlay. The media regions below
  the heap move down with it; the bootloader's logo (at `0x5ec00000`) is now
  reserved so they don't overwrite it during boot. In the 30-minute soak the
  1080p frames that missed the heap went from 78 to 0.
- **Memory cgroup removal**: removing a memcg group no longer loops forever
  when its charges can't be moved to the parent; after 20 passes without
  progress `rmdir` fails with EBUSY. Init removes a service's group after
  killing it, and with zygote's group the shutdown hung until the reboot
  watchdog fired, so `adb reboot recovery` came back up in Android.
- **Cgroup thread-group move**: moving a whole process to another cgroup
  (writing `cgroup.procs`) skips threads that are already exiting. Before,
  a thread that exited during the move made `cgroup_task_migrate` hit
  `BUG_ON` and panic the kernel; system_server's OomAdjuster does this move
  all the time.
- **USB gadget DMA**: the USB controller driver now stops an endpoint's DMA
  before it gives a cancelled request back. Before, when adbd exited or the
  USB function was switched, the host's next adb packet could be written
  into a buffer that had already been freed, which corrupted memory and
  panicked the kernel (adb's `OKAY` showed up in the crash).
- **USB function switch with adb open**: when the USB mode changes while
  adbd keeps its FunctionFS endpoints open, the function is no longer bound
  a second time (`functionfs_bind failed (-77)` and a warning on every
  switch); its strings only get new ids, so they no longer clash with the
  next function's. A failed bind no longer blocks the next one.
  The "adb offline after a USB switch" seen before came from setting
  `sys.usb.config` by hand: that turns on the MTP function without
  starting the MTP server, and the host's gvfs/libmtp kept resetting the
  unanswered device. Switching through Settings or `svc usb setFunctions`
  works, and adb comes back by itself within a few seconds.
- **ext4 symlink warning**: creating a symlink with a target longer than
  60 characters no longer logs an `inc_nlink` warning (`fs/inode.c:347`),
  dozens of times per boot. The link count is set back to 1 with
  `set_nlink()`, as in mainline; nothing on disk was ever wrong.

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
  Proximity is checked in a call: the dialer holds the proximity screen-off
  wake lock only while the call is off-hook, and the screen goes dark while
  the sensor reports near.
- **ION for all apps**: every `untrusted_app` domain can open
  `/dev/ion`, not only `untrusted_app_27`. Gralloc runs in the app process,
  and without ION the buffers of newer apps (and their video) came from UMP
  with no physical address, so the composer could not scan them out.
- **Mobile data** (`libsecril-shim`): data calls always ask for an IPv4
  context. Samsung's RIL cannot configure the dual-stack context the network
  grants for an `IPV4V6` APN (such as KPN `internet`): it fails with
  `pdp type is not supported`, leaves the PDP context defined so the modem
  rejects every retry until a reboot, and the framework retried several
  times a second. Checked with a simyo SIM on KPN: connected and validated
  over EDGE with one data call request per boot.
- **Voice network type** (`libsecril-shim`): the RIL leaves the voice radio
  technology empty and the shim always reported UMTS, also on a 2G cell
  (all of KPN since its 3G shutdown in 2022). It now follows the data
  registration: GSM while data is on GPRS/EDGE, UMTS on 3G. The same code
  read past the end of the RIL response and parsed the hex LAC/CID as
  decimal. Checked in Phone information: voice GSM, data EDGE; calls and
  SMS work.

### Hardware (`hardware/samsung`)

- **Gralloc** (`gralloc.exynos4`): cloned buffer handles are shorter than
  the full handle struct, and gralloc read fields past their end. When a handle
  ended at a page boundary, surfaceflinger crashed during boot and the
  framework restarted. Those fields (backing store, producer and consumer
  usage) are removed; the getters use the handle's usage and UMP id instead.
  Cherry-picked from the LOS-23.2 branch.
- **Gralloc ION use**: only buffers the composer, FIMC or MFC can read by
  physical address (window buffers, framebuffer, video, camera) come from
  the contiguous ION carveout (52 MB, see the kernel section). Buffers the CPU reads often
  (surfaceflinger screenshots, which include every Recents thumbnail) and
  GPU-only buffers come from the non-contiguous ION heap, and so do
  scanout buffers when the carveout is full; the composer draws those
  with the GPU. Before, the launcher's Recents thumbnails alone held about
  19 MB of the carveout. In a 30-minute soak (video, rotation, Settings,
  Recents) UMP fallbacks went from 478 to 0, and the composer no longer ran
  out of overlay memory. The non-contiguous heap is still shared by fd:
  UMP-only screenshots could be freed before system_server received them.
- **Hardware composer overlays** (`hwcomposer.exynos4`): cherry-picked from
  LOS-23.2. A full-screen app goes straight to FIMD window 0, the status bar
  to its own window, and video is scaled and converted by FIMC, so less is
  composed on the Mali-400. Measured with 10 scroll pairs in Settings:
  janky frames went from about 5% (GPU only) to about 1%, and the 90th
  percentile frame time from 24 ms to 18 ms. During video playback
  surfaceflinger uses about 30% CPU instead of 39%. The properties
  `debug.hwc.app_overlay`, `debug.hwc.rgb_overlay` and
  `debug.hwc.video_overlay` (all `true` by default) turn each kind off.
  On top of the cherry-pick:
  - FIMC writes rows with a pitch of the width rounded up to 16 pixels, so
    the overlay buffers and the FIMD stride use that width too. This stops
    shearing of videos whose scaled width isn't a multiple of 16 (checked
    with a 352x640 video).
  - When ION has no memory for the overlay buffers, the composer uses the
    GPU for 60 frames instead of showing a broken window.
  - Acquire fences are closed on every path, including the client target's
    fence on frames that don't need it. Before, surfaceflinger leaked
    about 350 fences per scroll test.
  - The panel size comes from `/sys/class/graphics/fb0/modes`. The kernel
    sets fb0's size to window 0's, so after a surfaceflinger restart during
    video the display could come back as a 480x35 strip.
- **Color saturation**: the overlays can only be used when surfaceflinger
  has no color matrix. An old `persist.sys.sf.color_saturation` of 1.1
  ("Boosted" from earlier builds) forced every layer to the GPU, and this
  device has no color modes in Settings to reset it. `init.smdk4210.rc`
  now sets it back to 1.0 before surfaceflinger starts.

### WebView

`galaxys2-20.0.xml` pins the WebView prebuilt to 145
(`f547731aef7f92fed845d822d9fec66ddad04cd3`). Newer versions need GLES 3 and
lose GPU rendering on the Mali-400. 145 gets no more security updates.

WebView 156 was measured on the phone against 145 (Jelly, local test pages,
3 runs each):

| Test | 145 | 156 |
|---|---|---|
| Scrolling a long page | 57-58 fps | 8-11 fps |
| CSS animation (40 shadowed boxes) | 40-42 fps | 7 fps |
| Canvas 2D (300 circles per frame) | 21-23 fps | 15-22 fps |
| WebGL | yes (Mali-400) | no |

156 logs `GLES3 is unsupported and ES version fallback is disabled`:
Chromium hard-codes `allow_es_version_fallback = false` with no switch or
feature flag, so it can't create a GL context, blocklists the GPU and
rasterizes everything in software. A newer WebView can't be made usable
with flags, so the pin stays at 145.
