#!/bin/bash

PATCHESDIR="$PWD"
ANDROIDDIR="$PWD/.."

AOSPBRANCH="refs/tags/android-13.0.0_r75"
LOSBRANCH="rinando HEAD:lineage-20.0"

echo "======= packages/modules/Permission =========="
cd "$ANDROIDDIR/packages/modules/Permission"
git push $LOSBRANCH --force

echo
echo "======= packages/modules/Bluetooth =========="
cd "$ANDROIDDIR/packages/modules/Bluetooth"
git push $LOSBRANCH --force

echo
echo "======= system/core =========="
cd "$ANDROIDDIR/system/core"
git push $LOSBRANCH --force

echo
echo "======= build/make =========="
cd "$ANDROIDDIR/build/make"
git push $LOSBRANCH --force

echo
echo "======= frameworks/av =========="
cd "$ANDROIDDIR/frameworks/av"
git push $LOSBRANCH --force

echo
echo "======= hardware/interfaces =========="
cd "$ANDROIDDIR/hardware/interfaces"
git push $LOSBRANCH --force

echo
echo "======= hardware/lineage/interfaces =========="
cd "$ANDROIDDIR/hardware/lineage/interfaces"
git push $LOSBRANCH --force

echo
echo "======= frameworks/base =========="
cd "$ANDROIDDIR/frameworks/base"
git push $LOSBRANCH --force


echo
echo "======= vendor/lineage =========="
cd "$ANDROIDDIR/vendor/lineage"
git push $LOSBRANCH --force

echo
echo "======= packages/modules/adb =========="
cd "$ANDROIDDIR/packages/modules/adb"
git push $LOSBRANCH --force

echo
echo "======= system/bpf =========="
cd "$ANDROIDDIR/system/bpf"
git push $LOSBRANCH --force

echo
echo "======= art =========="
cd "$ANDROIDDIR/art"
git push $LOSBRANCH --force

echo
echo "======= external/perfetto =========="
cd "$ANDROIDDIR/external/perfetto"
git checkout $AOSPBRANCH
git push $LOSBRANCH --force

echo
echo "======= packages/modules/NetworkStack =========="
cd "$ANDROIDDIR/packages/modules/NetworkStack"
git checkout $AOSPBRANCH
git push $LOSBRANCH --force

echo
echo "======= packages/modules/Connectivity =========="
cd "$ANDROIDDIR/packages/modules/Connectivity"
git push $LOSBRANCH --force

echo
echo "======= system/libhwbinder =========="
cd "$ANDROIDDIR/system/libhwbinder"
git push $LOSBRANCH --force

echo
echo "======= system/netd =========="
cd "$ANDROIDDIR/system/netd"
git push $LOSBRANCH --force

echo
echo "======= frameworks/native =========="
cd "$ANDROIDDIR/frameworks/native"
git push $LOSBRANCH --force

echo
echo "======= bionic =========="
cd "$ANDROIDDIR/bionic"
git push $LOSBRANCH --force

echo
echo "======= frameworks/libs/net =========="
cd "$ANDROIDDIR/frameworks/libs/net"
git push $LOSBRANCH --force

cd $PATCHESDIR
