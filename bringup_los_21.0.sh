###/generator.go:226:46: undefined: android.PathForSourceRelaxed
croot && cd build/soong && git fetch https://github.com/LineageOS/android_build_soong refs/changes/19/369119/1 && git checkout FETCH_HEAD && git rebase github/lineage-21.0

###error: hardware/lineage/compat/Android.bp:318:1: "libgui_shim_vendor" depends on undefined module "libgui_vendor".
croot && cd frameworks/native && git fetch https://github.com/LineageOS/android_frameworks_native refs/changes/44/371144/3 && git checkout FETCH_HEAD && git rebase github/lineage-21.0


###error: bootable/recovery/volume_manager/Android.bp:17:1: dependency "libdiskconfig" of "libvolume_manager" missing variant:
croot && cd system/core && git fetch https://github.com/LineageOS/android_system_core refs/changes/41/371241/2 && git checkout FETCH_HEAD && git rebase github/lineage-21.0

###error: frameworks/base/Android.bp:62:1: "framework-non-updatable-sources" depends on undefined module "adbrootservice_aidl".
croot && cd packages/apps/Settings && git fetch https://github.com/LineageOS/android_packages_apps_Settings refs/changes/85/369885/13 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd packages/modules/adb &&  git fetch https://github.com/LineageOS/android_packages_modules_adb refs/changes/72/368672/4 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd packages/modules/common && git fetch https://github.com/LineageOS/android_packages_modules_common refs/changes/82/368682/1 && git checkout FETCH_HEAD && git rebase github/lineage-21.0

#error: vendor/lineage/build/soong/Android.bp:24:8: module "generated_kernel_includes": cmd: unknown variable '$(PATH_OVERRIDE_SOONG)'
croot && cd bootable/recovery && git fetch https://github.com/LineageOS/android_bootable_recovery refs/changes/50/369250/4 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd hardware/interfaces && git fetch https://github.com/LineageOS/android_hardware_interfaces refs/changes/42/369042/2 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd system/sepolicy && git fetch https://github.com/LineageOS/android_system_sepolicy refs/changes/51/368751/2 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd system/vold && git fetch https://github.com/LineageOS/android_system_vold refs/changes/73/368773/2 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd system/extras && git fetch https://github.com/LineageOS/android_system_extras refs/changes/34/368734/1 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd frameworks/base && git fetch https://github.com/LineageOS/android_frameworks_base refs/changes/72/372672/7 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd frameworks/av && git fetch https://github.com/LineageOS/android_frameworks_av refs/changes/11/368311/3 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd system/core && git fetch https://github.com/LineageOS/android_system_core refs/changes/41/371241/2 && git checkout FETCH_HEAD && git rebase github/lineage-21.0
croot && cd build/make && git fetch https://github.com/LineageOS/android_build refs/changes/91/371191/2 && git checkout FETCH_HEAD && git rebase github/lineage-21.0

### error: hardware/samsung/hidl/thermal/Android.bp:43:13: module "android.hardware.thermal@2.0-service.samsung" variant "android_vendor.34_arm_armv7-a-neon_cortex-a9": tidy_flags: should not contain '-warnings-as-errors=android-*,clang-analyzer-security*,cert-*'; use tidy_checks_as_errors instead.
croot && cd hardware/samsung && git fetch https://github.com/LineageOS/android_hardware_samsung refs/changes/82/370382/3 && git cherry-pick FETCH_HEAD  && git rebase github/lineage-21.0

#vendor/lineage/overlay/no-rro/packages/apps/Settings/res/values-vi/config.xml:9: error: resource string/backup_transport_setting_label (aka com.android.settings:string/backup_transport_setting_label) not found.
croot && cd packages/apps/Settings && git fetch https://github.com/LineageOS/android_packages_apps_Settings refs/changes/85/369885/13 && git checkout FETCH_HEAD  && git rebase github/lineage-21.0

# Manually remove TrebuchetQuickStep from /vendor/lineage/config/common_mobile.mk

croot && cd bionic && git fetch https://github.com/LineageOS/android_bionic refs/changes/74/368174/2 && git checkout FETCH_HEAD && git rebase github/lineage-21.0

. build/envsetup.sh
breakfast i9100 && make clean && make ramdisk && brunch i9100

