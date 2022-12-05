#!/bin/bash
. roomservice.sh
repo sync --force-sync
. apply.sh
cd ../
. build/envsetup.sh
breakfast i9100
make clean && brunch i9100
