#!/bin/sh
# Runs the headless Godot checks named in godot/tools/ci/godot_checks.txt (issue 359 part b). GitHub runs it; so can any
# Linux checkout with Godot 4.7.2:   GODOT=/path/to/godot sh godot/tools/ci/run_checks.sh [name ...]
# First it proves the list is whole: every .gd file under godot/**/test/ is listed once, and every listed file exists.
# Then each headless line (except the ones another named step runs) runs with a time limit. A check fails on a non-zero
# exit, on the time limit, or on any SCRIPT ERROR line in its log. Prints one line per check and exits 1 on any failure.
# The list (or the shard's part of it) also has a time budget (GODOT_CHECKS_BUDGET, 1080 s; GitHub sets 600 s per
# shard. One job took 921 s for 155 checks on Nov 22 2026, up from about 200 s; the budget went from 780 s to 1080 s when
# PR 1329 tipped it over): a check gets 300 s or what is left of the budget, whichever is less, and a check the budget
# never reached is a FAIL, never a quiet skip. So this script always ends well inside the job's 25 minute limit, and a red job stays red instead of being
# cancelled (a script that does not compile makes several checks sit until their limit: commit 138ff38, 1020 s).
# SHARD=i/n (issue 1430) runs only shard i of n. Every shard makes the same plan: the headless lines, slowest first by
# godot/tools/ci/godot_check_times.txt (10 s when a check is not there), each given to the shard with the least time so
# far, so every headless check lands in exactly one shard. Shard 1 also runs the list proof. GitHub runs 3 shards in
# parallel, each with its own budget. GODOT_CHECKS_PLAN=1 prints the plan and stops (no Godot needed).
cd "$(dirname "$0")/../.." || exit 1
P=$(pwd)            # godot/
ROOT=$(cd .. && pwd)
G="${GODOT:-godot}"
LIST="$P/tools/ci/godot_checks.txt"
T="${RUNNER_TEMP:-/tmp}/godot_checks"
rm -rf "$T"; mkdir -p "$T/logs" "$T/fixtures" "$T/xdg"
F=0
BUDGET="${GODOT_CHECKS_BUDGET:-1080}"
TIMES="${GODOT_CHECKS_TIMES:-$P/tools/ci/godot_check_times.txt}"
SHARD="${SHARD:-1/1}"
si=${SHARD%/*}; sn=${SHARD#*/}
case "$SHARD" in */*) ;; *) si=x ;; esac
case "$si" in ""|*[!0-9]*) si=x ;; esac
case "$sn" in ""|*[!0-9]*) si=x ;; esac
if [ "$si" = x ]; then echo "FAIL: SHARD must be i/n with whole numbers, got '$SHARD'."; exit 2; fi
if [ "$si" -lt 1 ] || [ "$si" -gt "$sn" ]; then echo "FAIL: SHARD $SHARD is outside 1/$sn to $sn/$sn."; exit 2; fi

# 0. the shard plan: same on every shard. Lines: shard|class|script|setup|args|reason, in list order.
grep '^headless|' "$LIST" | awk -F'|' -v tf="$TIMES" '
  BEGIN { while ((getline l < tf) > 0) { if (l ~ /^#/ || l == "") continue; split(l, a, " "); t[a[1]] = a[2] + 0 } }
  { nm = $2; sub(/.*\//, "", nm); sub(/\.gd$/, "", nm); w = ($3 ~ /^step:/) ? 0 : ((nm in t) ? t[nm] : 10)
    printf "%d|%07d|%s|%s\n", w, NR, nm, $0 }' | sort -t'|' -k1,1nr -k3,3 -k2,2n | awk -F'|' -v n="$sn" '
  { best = 1; for (k = 2; k <= n; k++) if (load[k] < load[best]) best = k
    if ($6 ~ /^step:/) best = 1
    load[best] += $1; line = $0; sub(/^[^|]*\|[^|]*\|[^|]*\|/, "", line); printf "%s|%d|%s\n", $2, best, line }
  END { for (k = 1; k <= n; k++) printf "load|%d|%d\n", k, load[k] > "/dev/stderr" }' 2> "$T/loads.txt" | sort -t'|' -k1,1n | cut -d'|' -f2- > "$T/plan.txt"
mine=$(awk -F'|' -v i="$si" '$1 == i' "$T/plan.txt" | grep -vc '|step:')
est=$(awk -F'|' -v i="$si" '$2 == i {print $3}' "$T/loads.txt")
echo "  shard: $si of $sn, $mine checks, about $est s by the recorded times"
if [ "${GODOT_CHECKS_PLAN:-0}" = 1 ]; then cat "$T/plan.txt"; exit 0; fi

# 1. the list is whole (shard 1 only: the list and the plan are the same on every shard)
if [ "$si" -eq 1 ]; then
grep -v '^#' "$LIST" | grep -v '^$' | cut -d'|' -f2 | sort > "$T/listed.txt"
find . \( -path ./.godot -o -path ./gen \) -prune -o -path '*/test/*' -name '*.gd' -print | sed 's|^\./||' | sort > "$T/found.txt"
dup=$(uniq -d "$T/listed.txt")
miss=$(comm -13 "$T/listed.txt" "$T/found.txt")
gone=$(comm -23 "$T/listed.txt" "$T/found.txt")
bad=$(grep -v '^#' "$LIST" | grep -v '^$' | awk -F'|' 'NF != 5 || ($1 != "headless" && $1 != "gpu" && $1 != "retired") {print}')
if [ -n "$dup$miss$gone$bad" ]; then
  [ -n "$miss" ] && echo "  list: FAIL, test scripts not in godot_checks.txt:" && echo "$miss" | sed 's/^/    /'
  [ -n "$gone" ] && echo "  list: FAIL, listed but missing:" && echo "$gone" | sed 's/^/    /'
  [ -n "$dup" ] && echo "  list: FAIL, listed twice:" && echo "$dup" | sed 's/^/    /'
  [ -n "$bad" ] && echo "  list: FAIL, lines that are not class|script|setup|args|reason:" && echo "$bad" | sed 's/^/    /'
  F=$((F+1))
else
  echo "  list: PASS ($(wc -l < "$T/found.txt") test scripts: $(grep -c '^headless|' "$LIST") headless, $(grep -c '^gpu|' "$LIST") gpu, $(grep -c '^retired|' "$LIST") retired)"
fi
fi

# 2. the headless checks
ran=0; t_all=$(date +%s)
awk -F'|' -v i="$si" '$1 == i' "$T/plan.txt" | cut -d'|' -f2- > "$T/headless.txt"
while IFS='|' read -r cls script setup args reason; do
  name=$(basename "$script" .gd)
  if [ $# -gt 0 ]; then case " $* " in *" $name "*) ;; *) continue ;; esac; fi
  case "$setup" in step:*) echo "  $name: in its own step (${setup#step:})"; continue ;; esac
  left=$(( BUDGET - ( $(date +%s) - t_all ) ))
  if [ $left -le 0 ]; then echo "  $name: FAIL (not run: the list's $BUDGET s budget was used up by the checks above)"; F=$((F+1)); continue; fi
  lim=300; [ $left -lt $lim ] && lim=$left
  xdg="$T/xdg"
  a=""
  case "$setup" in
    fixture:*)
      fx="$T/fixtures/$name.json"
      if ! node "$ROOT/contrib/opus/tools/${setup#fixture:}" "$fx" > "$T/logs/$name.fixture.log" 2>&1 < /dev/null; then
        echo "  $name: FAIL (fixtures: node contrib/opus/tools/${setup#fixture:})"; tail -5 "$T/logs/$name.fixture.log" | sed 's/^/    /'; F=$((F+1)); continue
      fi ;;
    userdir) xdg="$ROOT/.onboarding_checks/xdg"; mkdir -p "$xdg" ;;
    -) ;;
    *) echo "  $name: FAIL (unknown setup $setup)"; F=$((F+1)); continue ;;
  esac
  [ "$args" != "-" ] && a=$(printf '%s' "$args" | sed "s|{fixture}|$T/fixtures/$name.json|g; s|{repo}|$ROOT|g")
  t0=$(date +%s)
  # shellcheck disable=SC2086
  XDG_DATA_HOME="$xdg" timeout -k 10 $lim "$G" --headless --path "$P" --script "res://$script" ${a:+--} $a > "$T/logs/$name.log" 2>&1 < /dev/null
  code=$?
  se=$(grep -c 'SCRIPT ERROR' "$T/logs/$name.log")
  s=$(( $(date +%s) - t0 )); ran=$((ran+1))
  if [ $code -eq 0 ] && [ "$se" -eq 0 ]; then
    echo "  $name: PASS (${s} s)"
  else
    why="exit code $code"; [ $code -eq 124 ] && why="time limit ($lim s)"; [ $code -eq 137 ] && why="time limit ($lim s), had to be killed"; [ "$se" -gt 0 ] && why="$why, $se SCRIPT ERROR line(s)"
    echo "  $name: FAIL ($why)"
    grep -E 'SCRIPT ERROR|FAIL|ERROR' "$T/logs/$name.log" | grep -v 'leaked\|still in use' | head -8 | sed 's/^/    /'
    F=$((F+1))
  fi
done < "$T/headless.txt"
echo "Ran $ran headless Godot checks (shard $si of $sn) in $(( $(date +%s) - t_all )) s (logs: $T/logs)."
if [ $F -eq 0 ]; then echo "PASS: every listed headless Godot check passed."; else echo "FAIL: $F Godot check(s) failed."; exit 1; fi
