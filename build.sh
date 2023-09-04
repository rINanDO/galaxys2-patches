#!/bin/bash
CURRENTDIR="$PWD"
REPODIR="$PWD/.."
BRANCH="v1-t" 

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

rm -rf hardware/samsung
rm -rf .repo/projects/hardware/samsung.git

rm -rf vendor/samsung
rm -rf .repo/projects/vendor/samsung.git


# (Re)initialize LineageOS 20.0 manifest
cd $REPODIR
repo init -u https://gitlab.e.foundation/e/os/android.git -b $BRANCH --git-lfs

cd .repo/manifests
git checkout origin/lineage-20.0
cd $REPODIR
repo init -u https://gitlab.e.foundation/e/os/android.git -b $BRANCH --git-lfs

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
