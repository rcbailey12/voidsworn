#!/bin/sh
# Issue 1517: the detail check inside Blender (pip bpy 4.5.4 wheel), on real PC bakes. For each ship it rebuilds the build
# sheet at the PC run's own commit (a 256 px, 1 sample bake: only the UVs and the atlas names are needed), puts the PC run's
# own 4096 atlases beside the blend, and runs tools/recipe/detail_check.py from THIS checkout the way stage 5 does
# (blender -b CELL.blend -P detail_check.py -- JOB CELL SHIP_JSON). Expected: O2 at pin-1413c exits 1 (FAIL), C12 round G
# and S10 exit 0 (PASS).
#   sh contrib/opus/tools/issue1517/blender_proof.sh <venv python> <work dir>
set -e
PY=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); W=$2; REPO=$(git rev-parse --show-toplevel)
mkdir -p "$W"
cat > "$W/run.py" <<'PYEOF'
import bpy, sys, runpy
a = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
sys.argv = ['detail_check.py', '--'] + a[2:]
try:
    runpy.run_path(a[1], run_name='__main__')
except SystemExit as e:
    sys.stdout.flush(); import os; os._exit(int(e.code or 0))
PYEOF
proof() {  # cell relay-branch gltf-source-dir ship-json commit expected-exit
  cell=$1; D="$W/$cell"; mkdir -p "$D/job"
  git -C "$REPO" fetch -q --depth=1 origin "$2:refs/remotes/proof1517/$cell"
  for a in hull parts; do for k in normal albedo orm; do
    git -C "$REPO" show "refs/remotes/proof1517/$cell:$3/${cell}_${a}_${k}.png" > "$D/job/${cell}_${a}_${k}.png"; done; done
  git -C "$REPO" fetch -q --depth=1 origin "$5"
  [ -d "$D/wt" ] || git -C "$REPO" worktree add -q --detach "$D/wt" "$5"
  (cd "$D/wt" && R209_SHIP="$D/wt/tools/recipe/ships/$4.json" "$PY" tools/blender/r209/bake_sheet.py -- "$D/lo" x x "$cell" 256 1 > "$D/bake.log" 2>&1)
  cp "$D/lo/$cell.blend" "$D/job/$cell.blend"
  set +e
  "$PY" "$W/run.py" -- "$D/job/$cell.blend" "$REPO/tools/recipe/detail_check.py" "$D/job" "$cell" "$REPO/tools/recipe/ships/$4.json" > "$D/log_detail.txt" 2>&1
  code=$?; set -e
  line=$(grep -E '^(PASS detail check|detail check FAIL|OPT-OUT detail check)' "$D/log_detail.txt")
  if [ "$code" = "$6" ]; then echo "PASS $cell exit $code: $line"; else echo "FAILED $cell exit $code, expected $6: $line"; exit 1; fi
}
proof O2 board/pc-out-1413-O2c opus1413o2c_out/recipe/export/O2_37/_gltf_source hegemony_O2 e031f492561e76b3f6ee807323b7a15e8b0d2641 1
proof C12 board/pc-out-1291c12d opus1291c12d_out/recipe/export/B19_11/_gltf_source chorus_C12 392b9468b495d66cad4ffac29a6fe95d6f27a1fc 0
proof S10 board/pc-out-1119zzzs10 1157_shipjob9_out/recipe/export/V16_37/_gltf_source voidsworn_S10 eef9fd8149d43ffadebebe62fa9b725d49415416 0
echo "PASS blender_proof: O2 fails, C12 and S10 pass, inside Blender"
