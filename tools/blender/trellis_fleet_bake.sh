#!/bin/bash
# Bake every TRELLIS.2 GLB in $1 into game hulls: $2/hulls_hi (38k tris, 2048 maps) and $2/hulls (16k tris, 1024 maps).
# Concept cut-outs (flux11_CODE_cut.png) in $3 set the paint brightness. Ref hulls (current heading) from $4 (repo hulls_hi).
# usage: trellis_fleet_bake.sh glb_dir out_dir concept_dir ref_dir [CODE ...]
G=$1; O=$2; C=$3; R=$4; shift 4; T=$(dirname "$0")/trellis_bake.py; mkdir -p $O/hulls_hi $O/hulls $O/logs
CODES=${@:-$(ls $G/*_trellis.glb | xargs -n1 basename | sed 's/_trellis.glb//')}
for code in $CODES; do
  [ -f $O/hulls/$code.json ] && continue
  flat=; case $code in O1_*|O2_*) flat=1;; esac
  ref=$R/$code.json; [ -f $ref ] || ref=-
  ( FLAT=$flat CONCEPT=$C/flux11_${code}_cut.png python3 $T $G/${code}_trellis.glb $ref $O/hulls_hi $code 38000 2048 > $O/logs/${code}_hi.log 2>&1 &
    FLAT=$flat CONCEPT=$C/flux11_${code}_cut.png python3 $T $G/${code}_trellis.glb $ref $O/hulls $code 16000 1024 > $O/logs/${code}_lo.log 2>&1 & wait )
  echo "$code $(grep -h 'done' $O/logs/${code}_hi.log | tail -1)"
done
