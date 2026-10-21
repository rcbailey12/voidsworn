#!/bin/bash
# usage: pcsync.sh <worktree dir>  -> stages test build files into /mnt/user-data/outputs/vs_testkit/build
SRC=$1; DST=/mnt/user-data/outputs/vs_testkit/build
mkdir -p $DST/node_modules/babylonjs
cd $SRC
for f in data.js core.js battle.js scene3d.js ships3d.js fx3d.js gfx3d.js vfx3d.js campaign_meta.js campaign_run.js ui3d.js campaign3d.js main3d.js head.html build.py tbot3.js smoke.py softlock.py step2test.py striptap.py cmdui.py yardcheck.py healtest.py bosscheck.py sfx.js sfx_data.js closeshot.py; do cp $f $DST/; done
cp node_modules/babylonjs/babylon.js $DST/node_modules/babylonjs/
ls $DST | wc -l
