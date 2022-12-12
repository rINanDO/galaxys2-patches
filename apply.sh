#!/bin/bash

PATCHESDIR="$PWD"
ANDROIDDIR="$PWD/.."

AOSPBRANCH="refs/tags/android-13.0.0_r16"
LOSBRANCH="github/lineage-20.0"

echo "======= packages/modules/Permission =========="
cd "$ANDROIDDIR/packages/modules/Permission"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/packages_modules_Permission/0001-Utils-add-FAKE_PACKAGE_SIGNATURE-to-platform-permiss.patch"
git am --signoff < "$PATCHESDIR/packages_modules_Permission/0002-Revert-Utils-add-FAKE_PACKAGE_SIGNATURE-to-platform-.patch"

echo
echo "======= packages/modules/Bluetooth =========="
cd "$ANDROIDDIR/packages/modules/Bluetooth"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/packages_modules_Bluetooth/0001-Revert-Set-Bluetooth-apex-updatable-to-true.patch"

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
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/build_make/0001-Disable-Recovery-Patch-via-BOARD_NO_RECOVERY_PATCH.patch"

echo
echo "======= frameworks/av =========="
cd "$ANDROIDDIR/frameworks/av"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/frameworks_av/0001-Revert-Camera-Reduce-latency-for-dejittering.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0002-Revert-Camera-Avoid-dequeue-too-many-buffers-from-bu.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0003-Revert-Camera-Avoid-latency-accumulation-when-syncin.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0004-Revert-Add-disable-enable-camera-service-watchdog-fe.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0005-1-2-libcameraservice-reset-to-a0a10c95a363a0df93da67.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0006-2-2-libcameraservice-massive-revert-to-Android-12-st.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0007-camera-Allow-to-use-boottime-as-timestamp-reference.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0008-libaudiohal-Bring-back-2.0-HAL.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0009-camera-Allow-devices-to-load-custom-CameraParameter-.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0010-Revert-Camera-Remove-old-recording-path-support.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0011-Camera-Restore-camera-HALv1-support-1-2.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0012-Camera-Add-extensions-to-CameraClient.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0013-nuplayer-Avoid-crash-when-codec-fails-to-load.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0014-camera-Don-t-segfault-if-we-get-a-NULL-parameter.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0015-libstagefright-Support-YVU420SemiPlanar-camera-forma.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0016-stagefright-omx-Don-t-signal-dataspace-change-on-leg.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0017-stagefright-ACodec-Resolve-empty-vendor-parameters-u.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0018-libstagefright-Free-buffers-on-observer-died.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0019-libstagefright-use-64-bit-usage-for-native_window_se.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0020-camera-include-Don-t-override-possible-overlayed-hea.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0021-Camera-check-metadata-type-before-releasing-frame.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0022-stagefright-add-changes-related-to-high-framerates-i.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0023-Camera-Add-support-for-preview-frame-fd.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0024-CameraSource.cpp-support-PIXEL_FORMAT_YUV420SP_NV21.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0025-libstagefright-Fix-memory-leak-due-to-lock-timeout.patch"
git am --signoff < "$PATCHESDIR/frameworks_av/0026-camera-media-Support-legacy-HALv1-camera-in-mediaser.patch"

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
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/frameworks_base/0001-ColorFade-fix-EGL-crash-on-exynos4-mali-blobs.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0002-DisplayPowerController-Make-colorfade-configurable-v.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0003-StorageManagerService-Storage.xml-Bring-back-XML-for.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0004-frameworks-base-Enable-Aggressive-trim-settings.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0005-CameraServiceProxy-Loosen-UID-check-conditionally.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0006-Revert-Camera-Injection.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0007-Camera-Restore-camera-HALv1-support-2-2.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0008-Camera-Add-feature-extensions.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0009-Revert-Camera-Add-support-for-readout-timestamp.patch"
git am --signoff < "$PATCHESDIR/frameworks_base/0010-Add-support-for-app-signature-spoofing.patch"

echo
echo "======= vendor/lineage =========="
cd "$ANDROIDDIR/vendor/lineage"
git checkout $LOSBRANCH
git am --signoff < "$PATCHESDIR/vendor_lineage/0001-kernel-Add-BOARD_CUSTOM_KERNEL_MK-support.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0002-kernel-Bring-back-fuse-ld-lld-from-CFLAGS.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0003-config-Add-Legacy-QCom-Camera-HAL1-support.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0004-config-Add-direct-connect-rule-support-for-Netd.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0005-config-Add-Process-SDK-version-override-support.patch"
git am --signoff < "$PATCHESDIR/vendor_lineage/0006-config-Override-memfd-backport-support.patch"

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
git checkout $LOSBRANCH
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
git checkout $AOSPBRANCH
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
git checkout $AOSPBRANCH
git am --signoff < "$PATCHESDIR/frameworks_libs_net/0001-BpfMap-Don-t-abort-when-eBPF-is-not-available.patch"

cd $PATCHESDIR
