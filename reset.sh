#!/bin/bash

PATCHESDIR="$PWD"
ANDROIDDIR="$PWD/.."

AOSPBRANCH="refs/tags/android-14.0.0_r1"
LOSBRANCH="github/lineage-21.0"

echo "======= packages/modules/Permission =========="
cd "$ANDROIDDIR/packages/modules/Permission"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= packages/modules/Bluetooth =========="
cd "$ANDROIDDIR/packages/modules/Bluetooth"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= system/core =========="
cd "$ANDROIDDIR/system/core"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= build/make =========="
cd "$ANDROIDDIR/build/make"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= frameworks/av =========="
cd "$ANDROIDDIR/frameworks/av"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= hardware/lineage/interfaces =========="
cd "$ANDROIDDIR/hardware/lineage/interfaces"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= hardware/interfaces =========="
cd "$ANDROIDDIR/hardware/interfaces"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= frameworks/base =========="
cd "$ANDROIDDIR/frameworks/base"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= vendor/lineage =========="
cd "$ANDROIDDIR/vendor/lineage"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= packages/modules/adb =========="
cd "$ANDROIDDIR/packages/modules/adb"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= system/bpf =========="
cd "$ANDROIDDIR/system/bpf"
git am --abort
git add -A
git reset --hard
git checkout $AOSPBRANCH

echo "======= art =========="
cd "$ANDROIDDIR/art"
git am --abort
git add -A
git reset --hard
git checkout $AOSPBRANCH

echo "======= external/perfetto =========="
cd "$ANDROIDDIR/external/perfetto"
git am --abort
git add -A
git reset --hard
git checkout $AOSPBRANCH

echo "======= packages/modules/NetworkStack =========="
cd "$ANDROIDDIR/packages/modules/NetworkStack"
git am --abort
git add -A
git reset --hard
git checkout $AOSPBRANCH

echo "======= packages/modules/Connectivity =========="
cd "$ANDROIDDIR/packages/modules/Connectivity"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= system/libhwbinder =========="
cd "$ANDROIDDIR/system/libhwbinder"
git am --abort
git add -A
git reset --hard
git checkout $AOSPBRANCH

echo "======= system/netd =========="
cd "$ANDROIDDIR/system/netd"
git am --abort
git add -A
git reset --hard
git checkout $AOSPBRANCH

echo "======= frameworks/native =========="
cd "$ANDROIDDIR/frameworks/native"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= bionic =========="
cd "$ANDROIDDIR/bionic"
git am --abort
git add -A
git reset --hard
git checkout $LOSBRANCH

echo "======= frameworks/libs/net =========="
cd "$ANDROIDDIR/frameworks/libs/net"
git am --abort
git add -A
git reset --hard
git checkout $AOSPBRANCH

cd $PATCHESDIR
