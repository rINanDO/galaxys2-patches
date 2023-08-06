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

echo
echo "======= build/make =========="
cd "$ANDROIDDIR/build/make"
git checkout $EBRANCH

echo
echo "======= frameworks/av =========="
cd "$ANDROIDDIR/frameworks/av"
git checkout $LOSBRANCH

echo
echo "======= hardware/interfaces =========="
cd "$ANDROIDDIR/hardware/interfaces"
git checkout $LOSBRANCH

echo
echo "======= hardware/lineage/interfaces =========="
cd "$ANDROIDDIR/hardware/lineage/interfaces"
git checkout $LOSBRANCH

echo
echo "======= frameworks/base =========="
cd "$ANDROIDDIR/frameworks/base"
git checkout $EBRANCH

echo
echo "======= vendor/lineage =========="
cd "$ANDROIDDIR/vendor/lineage"
git checkout $EBRANCH

echo
echo "======= packages/modules/adb =========="
cd "$ANDROIDDIR/packages/modules/adb"
git checkout $LOSBRANCH

echo
echo "======= system/bpf =========="
cd "$ANDROIDDIR/system/bpf"
git checkout $AOSPBRANCH

echo
echo "======= art =========="
cd "$ANDROIDDIR/art"
git checkout $AOSPBRANCH

echo
echo "======= external/perfetto =========="
cd "$ANDROIDDIR/external/perfetto"
git checkout $AOSPBRANCH

echo
echo "======= packages/modules/NetworkStack =========="
cd "$ANDROIDDIR/packages/modules/NetworkStack"
git checkout $AOSPBRANCH

echo
echo "======= packages/modules/Connectivity =========="
cd "$ANDROIDDIR/packages/modules/Connectivity"
git checkout $EBRANCH

echo
echo "======= system/libhwbinder =========="
cd "$ANDROIDDIR/system/libhwbinder"
git checkout $AOSPBRANCH

echo
echo "======= system/netd =========="
cd "$ANDROIDDIR/system/netd"
git checkout $LOSBRANCH

echo
echo "======= frameworks/native =========="
cd "$ANDROIDDIR/frameworks/native"
git checkout $LOSBRANCH

echo
echo "======= bionic =========="
cd "$ANDROIDDIR/bionic"
git checkout $LOSBRANCH

echo
echo "======= frameworks/libs/net =========="
cd "$ANDROIDDIR/frameworks/libs/net"
git checkout $EBRANCH


cd $PATCHESDIR
