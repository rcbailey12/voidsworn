#!/bin/sh
# Cloud run of the PC ship job's checks before a pin is frozen (issue 1414: the Harrow's first PC run failed stage 4 on six
# floating louvres the sheet fit check does not see). Runs, in order: the sheet fit check, recipe stage 4's parts build, its
# audit (floating parts, machines across seams), the build sheet contract, an unbaked stage 7 export, check_export and its self-test, and the
# Godot death seam check, plus the concept, camera fit and outline steps of stages 1, 3 and 4. A first PC run of a sheet ship
# needs all seven stages in its bat (stage 3 writes concept_camera.json). Needs the bpy venv (pip bpy 4.5.4) and Godot headless at /opt/godot.
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
# The outline steps of stages 1, 3 and 4 that a first PC run makes and scores (issue 1414: pin 1414c ran stages 4 to 7 only and
# stage 4 found no concept_camera.json). Stage 2's TRELLIS shape reference needs the PC's GPU, so here the build's own outline
# stands in for b0.npz: this proves the concept picture loads, the camera fit and the outline scoring run, not the PC's numbers.
NAME=$(basename "$SHIP" .json)
"$PY" tools/recipe/ship.py "$NAME" concept "$OUT/concept.png" > "$OUT/log_concept.txt" 2>&1 || { tail -3 "$OUT/log_concept.txt"; echo 'FAILED: stage 1/3 concept picture'; exit 1; }
"$BL" -b -P tools/blender/r209/sil_dump.py -- "$OUT/$CELL.npz" build sheet_hull "$CELL" > "$OUT/log_sildump.txt" 2>&1
grep -q '\[sil\] dumped' "$OUT/log_sildump.txt" || { tail -5 "$OUT/log_sildump.txt"; echo 'FAILED: stage 3/4 outline dump'; exit 1; }
"$PY" tools/blender/r209/silhouette4.py fit "$OUT/concept.png" "$OUT/$CELL.npz" "$OUT/concept_camera.json" > "$OUT/log_camfit.txt" 2>&1 || { tail -5 "$OUT/log_camfit.txt"; echo 'FAILED: stage 3 concept camera fit'; exit 1; }
mkdir -p "$OUT/sil"
"$PY" tools/blender/r209/silhouette4.py score "$OUT/concept.png" "$OUT/concept_camera.json" "$OUT/sil" "$CELL=$OUT/$CELL.npz" > "$OUT/log_sil.txt" 2>&1 || { tail -5 "$OUT/log_sil.txt"; echo 'FAILED: stage 4 outline score'; exit 1; }
"$PY" tools/blender/r209/outline_thirds.py "$OUT/concept.png" "$OUT/concept_camera.json" "$OUT/sil" "$CELL=$OUT/$CELL.npz" > "$OUT/log_thirds.txt" 2>&1 || { tail -5 "$OUT/log_thirds.txt"; echo 'FAILED: stage 4 outline thirds'; exit 1; }
"$PY" tools/recipe/ship.py "$NAME" gate "$OUT/sil/silhouette_scores.json" || { echo 'FAILED: outline score unreadable'; exit 1; }
echo 'PASS stage 1/3/4 outline steps (stage 2 TRELLIS stand-in: the build outline)'
"$BL" -b -P tools/recipe/sheet_contract_selftest.py -- "$SHIP" "$OUT/build" > "$OUT/log_contract.txt" 2>&1 || { tail -3 "$OUT/log_contract.txt"; echo 'FAILED: sheet contract'; exit 1; }
echo 'PASS sheet contract'
"$BL" -b "$OUT/build/$CELL.blend" --python-exit-code 1 -P tools/recipe/export7.py -- "$SHIP" "$OUT/export" maps=1024 unbaked=1 > "$OUT/log_export.txt" 2>&1 || { cat "$OUT/export/export_status.txt"; echo 'FAILED: stage 7 export'; exit 1; }
"$PY" tools/recipe/check_export.py "$SHIP" "$OUT/export" unbaked=1 > "$OUT/log_check.txt" 2>&1 || { tail -5 "$OUT/log_check.txt"; echo 'FAILED: check_export'; exit 1; }
"$PY" tools/recipe/check_export_selftest.py "$SHIP" "$OUT/export" unbaked=1 > "$OUT/log_export_selftest.txt" 2>&1 || { tail -8 "$OUT/log_export_selftest.txt"; echo 'FAILED: check_export_selftest'; exit 1; }
echo 'PASS check_export and its self-test'
tail -1 "$OUT/log_check.txt"
/opt/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path godot --script res://fx/test/death_seam_check.gd -- "$OUT/export/$GAME.glb" > "$OUT/log_seam.txt" 2>&1 || true
grep -q 'DEATH_SEAM failures=0' "$OUT/log_seam.txt" || { grep DEATH_SEAM "$OUT/log_seam.txt"; echo 'FAILED: death seam'; exit 1; }
echo 'PASS death seam'
echo "PASS cloud ship check $CODE"
