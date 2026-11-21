#!/bin/sh
# Issue 1517: the detail check inside Blender (pip bpy 4.5.4 wheel), the way stage 5 runs it on the PC:
#   blender -b CELL.blend -P detail_check.py -- JOB CELL SHIP_JSON
# For each ship it bakes the build sheet at a commit (stage 5's bake_sheet.py, 1024 px, 8 samples), DELETES every atlas file
# the bake wrote to the job folder (Artoo on PR 1521: the PC's Glasswright and KF1 runs had none there), and runs
# tools/recipe/detail_check.py from THIS checkout on the blend alone. It must read the fresh bake inside the blend.
#   sh contrib/opus/tools/issue1517/blender_proof.sh <venv python> <work dir>
set -e
PY=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); W=$2; REPO=$(git rev-parse --show-toplevel)
mkdir -p "$W"
cat > "$W/run.py" <<'PYEOF'
import bpy, sys, runpy, os
a = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
sys.argv = ['detail_check.py', '--'] + a[2:]
try:
    runpy.run_path(a[1], run_name='__main__')
except SystemExit as e:
    sys.stdout.flush(); os._exit(int(e.code or 0))
PYEOF
proof() {  # cell ship-json commit expected-exit
  cell=$1; D="$W/$cell"; mkdir -p "$D"
  git -C "$REPO" fetch -q --depth=1 origin "$3"
  [ -d "$D/wt" ] || git -C "$REPO" worktree add -q --detach "$D/wt" "$3"
  (cd "$D/wt" && R209_SHIP="$D/wt/tools/recipe/ships/$2.json" "$PY" tools/blender/r209/bake_sheet.py -- "$D/job" x x "$cell" 1024 8 > "$D/bake.log" 2>&1)
  rm -f "$D/job"/*.png
  set +e
  "$PY" "$W/run.py" -- "$D/job/$cell.blend" "$REPO/tools/recipe/detail_check.py" "$D/job" "$cell" "$REPO/tools/recipe/ships/$2.json" > "$D/log_detail.txt" 2>&1
  code=$?; set -e
  line=$(grep -E '^(PASS detail check|detail check FAIL|OPT-OUT detail check)' "$D/log_detail.txt")
  if [ "$code" = "$4" ]; then echo "PASS $cell exit $code, no atlas files in the job folder: $line"; else echo "FAILED $cell exit $code, expected $4: $line"; exit 1; fi
}
MAIN=$(git -C "$REPO" rev-parse origin/main)
proof O2 hegemony_O2 e031f492561e76b3f6ee807323b7a15e8b0d2641 1     # Navy Convoy at board/pin-1413c: Ryan saw clay
proof C12 chorus_C12 392b9468b495d66cad4ffac29a6fe95d6f27a1fc 0      # Chorus round G, accepted (PC run opus1291c12d)
proof S10 voidsworn_S10 "$MAIN" 0                                       # Sunward Vigil, accepted
proof GV2 ithar_GV2 "$MAIN" 0                                           # Glasswright fighter, accepted
proof KF1 corsair_KF1 237fd5b260efe1be2df04aba5492ed7d41e505c6 0      # Hullbreaker fighter KF1 L, Ryan OK Nov 21
echo "PASS blender_proof: O2 fails, C12, S10, GV2 and KF1 L pass, read from the blend with no atlas files on disk"
