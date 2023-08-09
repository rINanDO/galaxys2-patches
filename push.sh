#!/bin/bash

PATCHESDIR="$PWD"
ANDROIDDIR="$PWD/.."

EBRANCH="e-v1-t"
REPO="rinando"

echo
echo "======= system/core =========="
cd "$ANDROIDDIR/system/core"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= build/make =========="
cd "$ANDROIDDIR/build/make"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= frameworks/av =========="
cd "$ANDROIDDIR/frameworks/av"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= hardware/interfaces =========="
cd "$ANDROIDDIR/hardware/interfaces"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= hardware/lineage/interfaces =========="
cd "$ANDROIDDIR/hardware/lineage/interfaces"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= frameworks/base =========="
cd "$ANDROIDDIR/frameworks/base"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force


echo
echo "======= vendor/lineage =========="
cd "$ANDROIDDIR/vendor/lineage"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= packages/modules/adb =========="
cd "$ANDROIDDIR/packages/modules/adb"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= system/bpf =========="
cd "$ANDROIDDIR/system/bpf"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= art =========="
cd "$ANDROIDDIR/art"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= external/perfetto =========="
cd "$ANDROIDDIR/external/perfetto"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= packages/modules/NetworkStack =========="
cd "$ANDROIDDIR/packages/modules/NetworkStack"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= packages/modules/Connectivity =========="
cd "$ANDROIDDIR/packages/modules/Connectivity"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= system/libhwbinder =========="
cd "$ANDROIDDIR/system/libhwbinder"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= system/netd =========="
cd "$ANDROIDDIR/system/netd"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= frameworks/native =========="
cd "$ANDROIDDIR/frameworks/native"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= bionic =========="
cd "$ANDROIDDIR/bionic"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

echo
echo "======= frameworks/libs/net =========="
cd "$ANDROIDDIR/frameworks/libs/net"
git checkout -b $EBRANCH
git push $REPO HEAD:$EBRANCH --force

cd $PATCHESDIR
