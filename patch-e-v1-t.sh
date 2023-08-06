#!/bin/bash

PATCHESDIR="$PWD"
ANDROIDDIR="$PWD/.."

AOSPBRANCH="refs/tags/android-13.0.0_r61"
LOSBRANCH="github/lineage-20.0"
EBRANCH="e/v1-t"

echo
echo "======= system/core =========="
cd "$ANDROIDDIR/system/core"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/system_core/0001-Camera-Add-feature-extensions.patch"
git am --signoff < "$PATCHESDIR/system_core/0002-Revert-init-Treat-failure-to-create-a-process-group-.patch"
git am --signoff < "$PATCHESDIR/system_core/0003-healthd-charger-allow-home-button-to-wake.patch"

echo
echo "======= build/make =========="
cd "$ANDROIDDIR/build/make"
git checkout $EBRANCH
git am --signoff < "$PATCHESDIR/build_make/0001-Disable-Recovery-Patch-via-BOARD_NO_RECOVERY_PATCH.patch"

echo
echo "======= frameworks/av =========="
cd "$ANDROIDDIR/frameworks/av"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/frameworks_av/0001-Revert-Camera-memcpy-Blob-header-rather-than-directl.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0002-Revert-Camera-Fix-missing-physical-camera-availabili.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0003-Revert-Camera-Avoid-roundBufferDimensionsNearest-als.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0004-Revert-Camera-Skip-stream-size-check-for-whitelisted.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0005-Revert-Camera-Avoid-over-delaying-frames-in-PreviewF.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0006-Revert-Camera-Reduce-latency-for-dejittering.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0007-Revert-Camera-Avoid-dequeue-too-many-buffers-from-bu.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0008-Revert-Camera-Fix-parameter-misalignment-in-getDevic.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0009-Revert-DO-NOT-MERGE-Force-slowJpegMode-on-certain-ca.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0010-Revert-CameraService-Disable-overrideToPortrait-for-.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0011-Revert-Turn-off-overrideToPortrait-where-not-needed.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0012-Revert-Camera-Override-transform-of-all-inflight-req.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0013-Revert-DO-NOT-MERGE-Camera-Enable-session-parameter-.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0014-Revert-CameraService-Update-rotate-and-crop-dynamica.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0015-Revert-Camera-NDK-Do-not-enable-overrideToPortrait-i.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0016-Revert-DO-NOT-MERGE-libcameraservice-Provide-flag-fo.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0017-Revert-Fix-an-issue-that-the-syncTimestampToDisplayL.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0018-Revert-Camera-Add-adb-shell-cmd-to-override-stream-u.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0019-Revert-Camera-Avoid-latency-accumulation-when-syncin.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0020-Revert-Add-disable-enable-camera-service-watchdog-fe.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0021-libcameraservice-reset-to-a0a10c95a363a0df93da678b1e.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0022-2-2-libcameraservice-massive-revert-to-Android-12-st.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0023-camera-Allow-to-use-boottime-as-timestamp-reference.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0024-libaudiohal-Bring-back-2.0-HAL.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0025-camera-Allow-devices-to-load-custom-CameraParameter-.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0026-Revert-Camera-Remove-old-recording-path-support.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0027-Camera-Restore-camera-HALv1-support-1-2.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0028-Camera-Add-extensions-to-CameraClient.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0029-nuplayer-Avoid-crash-when-codec-fails-to-load.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0030-camera-Don-t-segfault-if-we-get-a-NULL-parameter.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0031-libstagefright-Support-YVU420SemiPlanar-camera-forma.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0032-stagefright-omx-Don-t-signal-dataspace-change-on-leg.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0033-stagefright-ACodec-Resolve-empty-vendor-parameters-u.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0034-libstagefright-Free-buffers-on-observer-died.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0035-libstagefright-use-64-bit-usage-for-native_window_se.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0036-camera-include-Don-t-override-possible-overlayed-hea.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0037-Camera-check-metadata-type-before-releasing-frame.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0038-stagefright-add-changes-related-to-high-framerates-i.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0039-Camera-Add-support-for-preview-frame-fd.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0040-CameraSource.cpp-support-PIXEL_FORMAT_YUV420SP_NV21.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0041-libstagefright-Fix-memory-leak-due-to-lock-timeout.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0042-camera-media-Support-legacy-HALv1-camera-in-mediaser.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0043-Fix-BT-in-call-on-CAF-devices.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0044-APM-Optionally-force-load-audio-policy-for-system-si.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0045-APM-Remove-A2DP-audio-ports-from-the-primary-HAL.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0046-audiopolicy-try-again-with-trimmed-audio-port-name-i.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0047-There-are-three-SCO-devices.-Fallback-from-one-to-th.patch"

echo
echo "======= hardware/interfaces =========="
cd "$ANDROIDDIR/hardware/interfaces"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/hardware_interfaces/0001-Revert-Audio-Load-Bluetooth-AIDL-HAL.patch"
git am --signoff < "$PATCHESDIR/hardware_interfaces/0002-Revert-audio-use-binder-threadpool.patch"

echo
echo "======= hardware/lineage/interfaces =========="
cd "$ANDROIDDIR/hardware/lineage/interfaces"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/hardware_lineage_interfaces/0001-wifi-1.0-legacy-Add-provision-to-create-remove-dynam.patch"
git am --signoff < "$PATCHESDIR/hardware_lineage_interfaces/0002-wifi-fix-legacy-HIDL-for-T.patch"
git am --signoff < "$PATCHESDIR/hardware_lineage_interfaces/0003-wifi-hidl_struct_util.cpp-convertLegacyWifiChannelWi.patch"
git am --signoff < "$PATCHESDIR/hardware_lineage_interfaces/0004-wifi-wifi.h-fix-build-undef-NAN.patch"
git am --signoff < "$PATCHESDIR/hardware_lineage_interfaces/0005-camera-Fix-build-for-S.patch"
git am --signoff < "$PATCHESDIR/hardware_lineage_interfaces/0006-Revert-power-Remove-1.0-HIDL.patch"
git am --signoff < "$PATCHESDIR/hardware_lineage_interfaces/0007-Revert-biometrics-Deprecate-inscreen-HAL.patch"
git am --signoff < "$PATCHESDIR/hardware_lineage_interfaces/0008-Revert-power-Deprecate-lineage-power-HAL.patch"

echo
echo "======= frameworks/base =========="
cd "$ANDROIDDIR/frameworks/base"
git checkout $EBRANCH
git am --signoff < "$PATCHESDIR/frameworks_base/0001-Revert-CameraManager-Swap-propertyName-packageName-i.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0002-Revert-DO-NOT-MERGE-Force-slowJpegMode-on-certain-ca.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0003-Revert-Per-app-compat-treatment-for-overrideToPortra.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0004-Revert-DO-NOT-MERGE-CameraManager-Enable-override-to.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0005-Revert-DO-NOT-MERGE-CameraManager-Provide-flag-for-o.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0006-Revert-camera-Skip-HFR-checks-for-privileged-apps.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0007-Revert-Camera-Skip-stream-size-check-for-whitelisted.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0008-CameraServiceProxy-Loosen-UID-check-conditionally.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0009-Revert-Camera-Injection.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0010-Camera-Restore-camera-HALv1-support-2-2.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0011-Camera-Add-feature-extensions.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0012-Revert-Camera-Add-support-for-readout-timestamp.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0013-BiometricScheduler-Cancel-operation-if-not-idle.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0014-Hack-Ignore-SensorPrivacyService-Security-Exception.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0015-Disable-vendor-mismatch-warning.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0016-core-Remove-old-app-target-SDK-dialog.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0017-Fix-brightness-slider-curve-for-some-devices.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0018-sensors-Create-bool-to-select-what-timestamp-to-use.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0019-hwui-reset-to-android-13.0.0_r13.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0020-ColorFade-fix-EGL-crash-on-exynos4-mali-blobs.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0021-DisplayPowerController-Make-colorfade-configurable-v.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0022-StorageManagerService-Storage.xml-Bring-back-XML-for.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0023-frameworks-base-Enable-Aggressive-trim-settings.patch"

echo
echo "======= vendor/lineage =========="
cd "$ANDROIDDIR/vendor/lineage"
git checkout $EBRANCH
git am --signoff < "$PATCHESDIR/vendor_lineage/0001-kernel-Add-BOARD_CUSTOM_KERNEL_MK-support.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0002-kernel-Bring-back-fuse-ld-lld-from-CFLAGS.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0003-config-Add-direct-connect-rule-support-for-Netd.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0004-config-Add-Process-SDK-version-override-support.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0005-config-Override-memfd-backport-support.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0006-config-Add-Legacy-QCom-Camera-HAL1-support.patch"

echo
echo "======= packages/modules/adb =========="
cd "$ANDROIDDIR/packages/modules/adb"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/packages_modules_adb/0001-adb-Bring-back-support-for-legacy-FunctionFS.patch"

echo
echo "======= system/bpf =========="
cd "$ANDROIDDIR/system/bpf"
git checkout $AOSPBRANCH
git am --signoff < "$PATCHESDIR/system_bpf/0001-Support-legacy-kernel-using-ro.kernel.ebpf.supported.patch"
git am --signoff < "$PATCHESDIR/system_bpf/0002-Disable-bpf-map-array-kernel-bug-detection-when-bpf-.patch"

echo
echo "======= art =========="
cd "$ANDROIDDIR/art"
git checkout $AOSPBRANCH
git am --signoff < "$PATCHESDIR/art/0001-art-Conditionally-remove-version-check-for-memfd_cre.patch"

echo
echo "======= external/perfetto =========="
cd "$ANDROIDDIR/external/perfetto"
git checkout $AOSPBRANCH
git am --signoff < "$PATCHESDIR/external_perfetto/0001-perfetto-Conditionally-remove-version-check-for-memf.patch"

echo
echo "======= packages/modules/NetworkStack =========="
cd "$ANDROIDDIR/packages/modules/NetworkStack"
git checkout $AOSPBRANCH
git am --signoff < "$PATCHESDIR/packages_modules_NetworkStack/0001-IpClientLinkObserver-Disable-Netlink-event-parsing-w.patch"

echo
echo "======= packages/modules/Connectivity =========="
cd "$ANDROIDDIR/packages/modules/Connectivity"
git checkout $EBRANCH
git am --signoff < "$PATCHESDIR/packages_modules_Connectivity/0001-NetdUpdatable-Disable-bpf-initialization-when-eBPF-i.patch"
git am --signoff < "$PATCHESDIR/packages_modules_Connectivity/0002-BpfNetMaps-Only-log-errors-when-eBPF-is-not-availabl.patch"
git am --signoff < "$PATCHESDIR/packages_modules_Connectivity/0003-NetworkStatsService-Prevent-crashes-when-eBPF-is-not.patch"

echo
echo "======= system/libhwbinder =========="
cd "$ANDROIDDIR/system/libhwbinder"
git checkout $AOSPBRANCH
git am --signoff < "$PATCHESDIR/system_libhwbinder/0001-Don-t-crash-Binder-threadpool-cannot-be-shrunk-after.patch"

echo
echo "======= system/netd =========="
cd "$ANDROIDDIR/system/netd"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/system_netd/0001-Ignore-netd-errors-for-4.9-kernels.patch"
git am --signoff < "$PATCHESDIR/system_netd/0002-netd-Allow-devices-to-force-add-directly-connected-r.patch"

echo
echo "======= frameworks/native =========="
cd "$ANDROIDDIR/frameworks/native"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/frameworks_native/0001-Disable-gpu-service.patch"
git am --signoff < "$PATCHESDIR/frameworks_native/0002-ProcessState-Only-log-thread-pool-shrunk-message.patch"
git am --signoff < "$PATCHESDIR/frameworks_native/0003-Revert-Add-a-timeout-for-all-installd-operations.patch"

echo
echo "======= bionic =========="
cd "$ANDROIDDIR/bionic"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/bionic/0001-Implement-per-process-target-SDK-version-override.patch"
git am --signoff < "$PATCHESDIR/bionic/0002-linker-Apply-TARGET_PROCESS_SDK_VERSION_OVERRIDE-on-.patch"
git am --signoff < "$PATCHESDIR/bionic/0003-Hack-Ignore-invalid-pthread_t-to-s.patch"

echo
echo "======= frameworks/libs/net =========="
cd "$ANDROIDDIR/frameworks/libs/net"
git checkout $EBRANCH
git am --signoff < "$PATCHESDIR/frameworks_libs_net/0001-BpfMap-Don-t-abort-when-eBPF-is-not-available.patch"


cd $PATCHESDIR
