#!/bin/bash
CURRENTDIR="$PWD"
REPODIR="$PWD/.."
BRANCH="lineage-21.0" 

# Reset all existing repo's
cd $REPODIR
repo forall -c git am --abort
repo forall -c git reset --hard

# Drop roomservice.xml
cd $REPODIR
rm -rf .repo/local_manifests

# Fix the future failure during checkout-process in repo
cd $REPODIR
rm -rf prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/*
rm -rf .repo/projects/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9.git

rm -rf system/core
rm -rf .repo/projects/system/core
rm -rf .repo/project-objects/LineageOS/android_system_core.git

rm -rf vendor/lineage
rm -rf .repo/projects/vendor/lineage.git

rm -rf frameworks/native
rm -rf .repo/projects/frameworks/native.git

rm -rf frameworks/base
rm -rf .repo/projects/frameworks/base.git
rm -rf .repo/project-objects/LineageOS/android_frameworks_base.git

rm -rf frameworks/av
rm -rf .repo/projects/frameworks/av.git

rm -rf hardware/samsung
rm -rf .repo/projects/hardware/samsung.git

rm -rf vendor/samsung
rm -rf .repo/projects/vendor/samsung.git

rm -rf art
rm -rf .repo/projects/art.git

rm -rf external/jemalloc_new
rm -rf .repo/projects/external/jemalloc_new.git

rm -rf external/perfetto
rm -rf .repo/projects/external/perfetto.git

rm -rf hardware/qcom/audio
rm -rf .repo/projects/hardware/qcom/audio.git

rm -rf frameworks/libs/net
rm -rf .repo/projects/frameworks/libs/net.git

rm -rf hardware/qcom/display
rm -rf .repo/projects/hardware/qcom/display.git

rm -rf hardware/qcom/media
rm -rf .repo/projects/hardware/qcom/media.git

rm -rf packages/modules/NetworkStack
rm -rf .repo/projects/packages/modules/NetworkStack.git

# (Re)initialize LineageOS manifest
cd $REPODIR
repo init -u https://github.com/LineageOS/android.git -b $BRANCH --git-lfs
cd .repo/manifests
git checkout origin/$BRANCH
cd $REPODIR
repo init -u https://github.com/LineageOS/android.git -b $BRANCH --git-lfs

cd $CURRENTDIR

# Sync with roomservice (Which could fail)
. roomservice.sh
cd $REPODIR
repo sync --force-sync

cd $CURRENTDIR
. apply.sh

cd $REPODIR
. build/envsetup.sh
breakfast i9100
make clean && brunch i9100
