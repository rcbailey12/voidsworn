#!/bin/sh
# Cloud run of the PC ship job's checks before a pin is frozen (issue 1414: the Harrow's first PC run failed stage 4 on six
# floating louvres the sheet fit check does not see). Runs, in order: the sheet fit check, recipe stage 4's parts build, its
# audit (floating parts, machines across seams), the build sheet contract, an unbaked stage 7 export, check_export, and the
# Godot death seam check. Needs the bpy venv (pip bpy 4.5.4) and Godot headless at /opt/godot.
#   sh contrib/opus/tools/issue1414/cloud_ship_check.sh <venv python> <ship json> <sheet code> <cell> <game code> <out dir>
# Example: sh contrib/opus/tools/issue1414/cloud_ship_check.sh V/bin/python tools/recipe/ships/voidsworn_S11.json voidsworn_S11 S11 V15_37 /tmp/s4
set -e
PY=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); SHIP=$(realpath "$2"); CODE=$3; CELL=$4; GAME=$5; OUT=$6
HERE=$(dirname "$(realpath "$0")")
mkdir -p "$OUT"
BL="$OUT/blender"
printf '#!/bin/sh\nexec %s %s/blender_shim.py "$@"\n' "$PY" "$HERE" > "$BL"; chmod +x "$BL"
export R209_SHIP="$SHIP"
"$PY" tools/blender/build_sheets/build.py "$CODE" "$OUT/fit" fit > "$OUT/log_fit.txt" 2>&1
grep -E '^FIT|weapon match' "$OUT/log_fit.txt"
grep -q "'CLASH': 0, 'MOUNT': 0, 'ARC': 0, 'SENSOR': 0, 'SWEEP': 0, 'EXHAUST': 0, 'EXIT': 0, 'LANE': 0" "$OUT/log_fit.txt" || { echo 'FAILED: sheet fit check'; exit 1; }
"$BL" -b -P tools/blender/r209/sheet_hull.py -- "$OUT/build" "$CELL" > "$OUT/log_build.txt" 2>&1 || { echo 'FAILED: stage 4 parts build'; exit 1; }
"$BL" -b "$OUT/build/$CELL.blend" -P tools/recipe/audit.py -- "$OUT/audit.json" > "$OUT/log_audit.txt" 2>&1 || { grep '\[audit\] {' "$OUT/log_audit.txt"; echo 'FAILED: stage 4 audit'; exit 1; }
echo 'PASS stage 4 audit'
"$BL" -b -P tools/recipe/sheet_contract_selftest.py -- "$SHIP" "$OUT/build" > "$OUT/log_contract.txt" 2>&1 || { tail -3 "$OUT/log_contract.txt"; echo 'FAILED: sheet contract'; exit 1; }
echo 'PASS sheet contract'
"$BL" -b "$OUT/build/$CELL.blend" --python-exit-code 1 -P tools/recipe/export7.py -- "$SHIP" "$OUT/export" maps=1024 unbaked=1 > "$OUT/log_export.txt" 2>&1 || { cat "$OUT/export/export_status.txt"; echo 'FAILED: stage 7 export'; exit 1; }
"$PY" tools/recipe/check_export.py "$SHIP" "$OUT/export" unbaked=1 > "$OUT/log_check.txt" 2>&1 || { tail -5 "$OUT/log_check.txt"; echo 'FAILED: check_export'; exit 1; }
tail -1 "$OUT/log_check.txt"
/opt/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path godot --script res://fx/test/death_seam_check.gd -- "$OUT/export/$GAME.glb" > "$OUT/log_seam.txt" 2>&1 || true
grep -q 'DEATH_SEAM failures=0' "$OUT/log_seam.txt" || { grep DEATH_SEAM "$OUT/log_seam.txt"; echo 'FAILED: death seam'; exit 1; }
echo 'PASS death seam'
echo "PASS cloud ship check $CODE"
