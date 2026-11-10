#!/bin/sh
# Runs the headless Godot checks named in godot/tools/ci/godot_checks.txt (issue 359 part b). GitHub runs it; so can any
# Linux checkout with Godot 4.7.2:   GODOT=/path/to/godot sh godot/tools/ci/run_checks.sh [name ...]
# First it proves the list is whole: every .gd file under godot/**/test/ is listed once, and every listed file exists.
# Then each headless line (except the ones another named step runs) runs with a time limit. A check fails on a non-zero
# exit, on the time limit, or on any SCRIPT ERROR line in its log. Prints one line per check and exits 1 on any failure.
# The whole list also has a time budget (GODOT_CHECKS_BUDGET, 780 s; a healthy run takes about 200 s): a check gets
# 300 s or what is left of the budget, whichever is less, and a check the budget never reached is a FAIL, never a quiet
# skip. So this script always ends well inside GitHub's 30 minute job limit, and a red job stays red instead of being
# cancelled (a script that does not compile makes several checks sit until their limit: commit 138ff38, 1020 s).
cd "$(dirname "$0")/../.." || exit 1
P=$(pwd)            # godot/
ROOT=$(cd .. && pwd)
G="${GODOT:-godot}"
LIST="$P/tools/ci/godot_checks.txt"
T="${RUNNER_TEMP:-/tmp}/godot_checks"
rm -rf "$T"; mkdir -p "$T/logs" "$T/fixtures" "$T/xdg"
F=0
BUDGET="${GODOT_CHECKS_BUDGET:-780}"

# 1. the list is whole
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

# 2. the headless checks
ran=0; t_all=$(date +%s)
grep '^headless|' "$LIST" > "$T/headless.txt"
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
echo "Ran $ran headless Godot checks in $(( $(date +%s) - t_all )) s (logs: $T/logs)."
if [ $F -eq 0 ]; then echo "PASS: every listed headless Godot check passed."; else echo "FAIL: $F Godot check(s) failed."; exit 1; fi
