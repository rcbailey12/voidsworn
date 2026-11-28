#!/bin/sh
# Runs the headless Godot checks named in godot/tools/ci/godot_checks.txt (issue 359 part b). GitHub runs it; so can any
# Linux checkout with Godot 4.7.2:   GODOT=/path/to/godot sh godot/tools/ci/run_checks.sh [name ...]
# First it proves the list is whole: every .gd file under godot/**/test/ is listed once, and every listed file exists.
# Then two headless checks run at a time, each with its own user dir, log and time limit. A check fails on a non-zero
# exit, on the time limit, or on any SCRIPT ERROR line in its log. Prints results in list order and exits 1 on any failure.
# Passing and plan-only shards remove their own scratch. Failed shards keep full logs and profiles alongside the excerpts.
# The list (or the shard's part of it) also has a time budget (GODOT_CHECKS_BUDGET, 1080 s; GitHub sets 600 s per
# shard. One job took 921 s for 155 checks on Nov 22 2026, up from about 200 s; the budget went from 780 s to 1080 s when
# PR 1329 tipped it over): a check gets 300 s or what is left of the budget, whichever is less, and a check the budget
# never reached is a FAIL, never a quiet skip. So this script always ends well inside the job's 25 minute limit, and a red job stays red instead of being
# cancelled (a script that does not compile makes several checks sit until their limit: commit 138ff38, 1020 s).
# SHARD=i/n (issue 1430) runs only shard i of n. Every shard makes the same plan: the headless lines, slowest first by
# godot/tools/ci/godot_check_times.txt (10 s when a check is not there), each given to the shard with the least time so
# far, so every headless check lands in exactly one shard. Shard 1 also runs the list proof. GitHub runs the shard matrix
# in parallel, each with its own budget. GODOT_CHECKS_PLAN=1 prints the plan and stops (no Godot needed).
run_godot() {
  XDG_DATA_HOME="$xdg" APPDATA="$xdg" timeout -k 10 "$@"
}

scratch() {
  # On the Windows sandbox, realpath cannot stat some ancestors of the checkout.
  node --preserve-symlinks-main "$P/tools/ci/check_scratch.js" "$@"
}

failure_excerpt() {
  awk '
    tolower($0) ~ /placeholder hull:/ { next }
    {
      fail = $0 ~ /FAIL/
      # Some checks print "FAIL detail" and end with a separate "check: FAIL (count)" summary.
      assertion = tolower($0) ~ /assertion/ || $0 ~ /^[[:space:]]*FAIL([: ]|$)/
      if (fail) { last_fail = NR; fail_text = $0 }
      if (assertion) { last_assert = NR; assert_text = $0 }
      if (n < 8 && (fail || assertion || ($0 ~ /ERROR/ && $0 !~ /leaked|still in use/))) {
        first[++n] = NR
        line[n] = $0
      }
    }
    END {
      # Keep the useful tail even when the first eight diagnostics fill up.
      late_fail = last_fail > first[n]
      late_assert = last_assert > first[n] && last_assert != last_fail
      extra = n + late_fail + late_assert - 8
      for (i = n; extra > 0 && i > 0; i--) {
        if (first[i] != last_fail && first[i] != last_assert) { delete line[i]; extra-- }
      }
      for (i = 1; i <= n; i++) if (i in line) print "    " line[i]
      if (late_assert && last_assert < last_fail) print "    " assert_text
      if (late_fail) print "    " fail_text
      if (late_assert && last_assert > last_fail) print "    " assert_text
    }' "$1"
}

run_check() {
  name=$1 script=$2 setup=$3 args=$4
  left=$(( deadline - $(date +%s) ))
  if [ "$left" -le 0 ]; then
    echo "  $name: FAIL (not run: the shard's $BUDGET s budget was used up)"
    return 1
  fi

  xdg="$T/xdg/$name"
  if ! mkdir "$xdg"; then echo "  $name: FAIL (could not create its user dir)"; return 1; fi
  fx="$T/fixtures/$name.json"
  set --
  case "$setup" in
    fixture:*)
      if ! timeout -k 10 "$left" node "$ROOT/contrib/opus/tools/${setup#fixture:}" "$fx" > "$T/logs/$name.fixture.log" 2>&1 < /dev/null; then
        echo "  $name: FAIL (fixtures: node contrib/opus/tools/${setup#fixture:})"
        tail -5 "$T/logs/$name.fixture.log" | sed 's/^/    /'
        return 1
      fi ;;
    userdir)
      # Onboarding accepts an explicit profile only at <Godot temp>/voidsworn-onboarding-*/profile.
      # Ask the engine instead of assuming /tmp. The profile still points to this check's own data.
      probe="$T/logs/$name.temp.log"
      [ "$left" -le 20 ] || left=20
      if ! run_godot "$left" "$G" --headless --path "$P" --script res://tools/ci/print_temp_dir.gd > "$probe" 2>&1 < /dev/null ||
        grep -q 'SCRIPT ERROR' "$probe"; then
        echo "  $name: FAIL (could not read Godot's temp dir)"
        failure_excerpt "$probe"
        return 1
      fi
      godot_temp=$(tr -d '\r' < "$probe" | sed -n 's/^GODOT_TEMP_DIR=//p')
      if ! profile=$(GODOT_TEMP_DIR="$godot_temp" CHECK_USER_DIR="$xdg" scratch onboarding); then
        echo "  $name: FAIL (could not create its onboarding profile alias)"
        return 1
      fi
      # Only remove the alias. The underlying profile stays with this shard when it fails.
      trap 'CHECK_PROFILE_ALIAS="$profile" scratch unlink-onboarding || exit 1' EXIT
      xdg="$profile"
      set -- "$profile" ;;
    -) ;;
    *) echo "  $name: FAIL (unknown setup $setup)"; return 1 ;;
  esac
  if [ "$args" != "-" ]; then
    # Split the list's space-separated words before substitution, keeping paths with spaces whole.
    set -f
    # shellcheck disable=SC2086
    for arg in $args; do
      case "$arg" in
        '{fixture}'*) arg="$fx${arg#'{fixture}'}" ;;
        '{repo}'*) arg="$ROOT${arg#'{repo}'}" ;;
      esac
      set -- "$@" "$arg"
    done
    set +f
  fi

  t0=$(date +%s)
  left=$(( deadline - t0 ))
  if [ "$left" -le 0 ]; then
    echo "  $name: FAIL (not run: the shard's $BUDGET s budget was used up during setup)"
    return 1
  fi
  lim=300; [ "$left" -lt "$lim" ] && lim=$left
  [ "$#" -eq 0 ] || set -- -- "$@"
  log="$T/logs/$name.log"
  run_godot "$lim" "$G" --headless --path "$P" --script "res://$script" "$@" > "$log" 2>&1 < /dev/null
  code=$?
  se=$(grep -c 'SCRIPT ERROR' "$log")
  s=$(( $(date +%s) - t0 ))
  if [ "$code" -eq 0 ] && [ "$se" -eq 0 ]; then
    echo "  $name: PASS (${s} s)"
  else
    why="exit code $code"; [ "$code" -eq 124 ] && why="time limit ($lim s)"; [ "$code" -eq 137 ] && why="time limit ($lim s), had to be killed"; [ "$se" -gt 0 ] && why="$why, $se SCRIPT ERROR line(s)"
    echo "  $name: FAIL ($why)"
    failure_excerpt "$log"
    return 1
  fi
}

# Private entry point for xargs workers. Each writes a separate report so excerpts do not interleave.
if [ "${1:-}" = --worker ]; then
  shift
  name=$1
  # Finish worker cleanup before recording its result. xargs fails only if dispatch or recording fails.
  (run_check "$@") > "$T/logs/$name.report" 2>&1
  echo "$?" > "$T/logs/$name.status"
  exit $?
fi

cd "$(dirname "$0")/../.." || exit 1
P=$(pwd)            # godot/
ROOT=$(cd .. && pwd)
G="${GODOT:-godot}"
LIST="$P/tools/ci/godot_checks.txt"
BUDGET="${GODOT_CHECKS_BUDGET:-1080}"
case "$BUDGET" in ""|0*|*[!0-9]*) echo "FAIL: GODOT_CHECKS_BUDGET must be a positive whole number of seconds."; exit 2 ;; esac
F=0
TIMES="${GODOT_CHECKS_TIMES:-$P/tools/ci/godot_check_times.txt}"
SHARD="${SHARD:-1/1}"
si=${SHARD%/*}; sn=${SHARD#*/}
case "$SHARD" in */*) ;; *) si=x ;; esac
case "$si" in ""|*[!0-9]*) si=x ;; esac
case "$sn" in ""|*[!0-9]*) si=x ;; esac
if [ "$si" = x ]; then echo "FAIL: SHARD must be i/n with whole numbers, got '$SHARD'."; exit 2; fi
if [ "$si" -lt 1 ] || [ "$si" -gt "$sn" ]; then echo "FAIL: SHARD $SHARD is outside 1/$sn to $sn/$sn."; exit 2; fi
if command -v cygpath > /dev/null 2>&1; then
  case "${RUNNER_TEMP:-}" in
    //*) ;;
    /*) RUNNER_TEMP=$(cygpath -m "$RUNNER_TEMP") || RUNNER_TEMP=
        export RUNNER_TEMP ;;
  esac
fi
if ! T=$(scratch shard); then
  echo "FAIL: could not prepare Godot check scratch space."; exit 1
fi
SCRATCH=${T%/godot_checks}
echo "  scratch: $SCRATCH"
trap 'code=$?; if [ "$code" -ne 0 ]; then
  echo "  scratch kept: $SCRATCH"
elif ! CHECK_SHARD_SCRATCH="$T" scratch remove-shard; then
  echo "WARN: could not clean all passing Godot check scratch space at $SCRATCH."
fi; exit "$code"' EXIT

# 0. the shard plan: same on every shard. Lines: shard|class|script|setup|args|reason, in list order.
# Use ENVIRON so awk does not interpret backslashes in a native Windows path as escapes.
grep '^headless|' "$LIST" | TIMES="$TIMES" awk -F'|' '
  BEGIN { tf = ENVIRON["TIMES"]; while ((getline l < tf) > 0) { if (l ~ /^#/ || l == "") continue; split(l, a, " "); t[a[1]] = a[2] + 0 } }
  { nm = $2; sub(/.*\//, "", nm); sub(/\.gd$/, "", nm); w = ($3 ~ /^step:/) ? 0 : ((nm in t) ? t[nm] : 10)
    printf "%d|%07d|%s|%s\n", w, NR, nm, $0 }' | sort -t'|' -k1,1nr -k3,3 -k2,2n | awk -F'|' -v n="$sn" '
  { best = 1; for (k = 2; k <= n; k++) if (load[k] < load[best]) best = k
    if ($6 ~ /^step:/) best = 1
    load[best] += $1; line = $0; sub(/^[^|]*\|[^|]*\|[^|]*\|/, "", line); printf "%s|%d|%s\n", $2, best, line }
  END { for (k = 1; k <= n; k++) printf "load|%d|%d\n", k, load[k] > "/dev/stderr" }' 2> "$T/loads.txt" | sort -t'|' -k1,1n | cut -d'|' -f2- > "$T/plan.txt"
# The plan must hold every headless line of the list exactly once, each with a shard from 1 to n; otherwise stop (Artoo
# on PR 1615: a planner error could leave a short or empty plan and an empty shard would still say PASS).
# GODOT_CHECKS_PLAN_EDIT (tests only) is a sed script applied to the plan first, so godot_shard_tests.js can break it.
if [ -n "${GODOT_CHECKS_PLAN_EDIT:-}" ]; then sed -e "$GODOT_CHECKS_PLAN_EDIT" "$T/plan.txt" > "$T/plan_edit.txt"; mv "$T/plan_edit.txt" "$T/plan.txt"; fi
grep '^headless|' "$LIST" | sort > "$T/plan_want.txt"
cut -d'|' -f2- "$T/plan.txt" | sort > "$T/plan_got.txt"
badshard=$(awk -F'|' -v n="$sn" '$1 !~ /^[0-9]+$/ || $1 < 1 || $1 > n' "$T/plan.txt" | head -3)
if ! cmp -s "$T/plan_want.txt" "$T/plan_got.txt" || [ -n "$badshard" ] || [ ! -s "$T/plan_want.txt" ]; then
  echo "  shard: FAIL, the shard plan does not hold every headless line exactly once:"
  diff "$T/plan_want.txt" "$T/plan_got.txt" | head -8 | sed 's/^/    /'
  [ -n "$badshard" ] && echo "$badshard" | sed 's/^/    bad shard: /'
  echo "FAIL: the shard plan is broken, so this shard is a failed check (not a skip); no Godot check ran here."; exit 1
fi
mine=$(awk -F'|' -v i="$si" '$1 == i' "$T/plan.txt" | grep -vc '|step:')
est=$(awk -F'|' -v i="$si" '$2 == i {print $3}' "$T/loads.txt")
echo "  shard: $si of $sn, $mine checks, about $est s by the recorded times"
# A branch can still use an older shard count after CI merges in main's longer check list.
# Allow 15 percent above the plan, capped at the normal single-job budget.
need=$(( (${est:-0} * 115 + 99) / 100 ))
[ "$need" -le 1080 ] || need=1080
if [ "$need" -gt "$BUDGET" ]; then
  echo "  shard: WARN, $est s planned for a $BUDGET s budget; budget raised to $need s. Update the branch's shard count."
  BUDGET=$need
elif [ $(( ${est:-0} * 100 )) -gt $(( BUDGET * 80 )) ]; then
  echo "  shard: WARN, $est s planned is over 80 percent of the $BUDGET s budget."
fi
if [ "${GODOT_CHECKS_PLAN:-0}" = 1 ]; then cat "$T/plan.txt"; exit $?; fi

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

# 2. the headless checks. Both workers use the same deadline, including time spent in setup.
ran=0; t_all=$(date +%s); deadline=$(( t_all + BUDGET ))
awk -F'|' -v i="$si" '$1 == i' "$T/plan.txt" | cut -d'|' -f2- > "$T/headless.txt" || exit 1
while IFS='|' read -r cls script setup args reason; do
  name=${script##*/}; name=${name%.gd}
  if [ $# -gt 0 ]; then case " $* " in *" $name "*) ;; *) continue ;; esac; fi
  printf '%s|%s|%s|%s\n' "$name" "$script" "$setup" "$args" || exit 1
done < "$T/headless.txt" > "$T/selected.txt" || exit 1
export P ROOT G T BUDGET deadline
while IFS='|' read -r name script setup args; do
  case "$setup" in step:*) continue ;; esac
  printf '%s\000' "$name" "$script" "$setup" "$args"
done < "$T/selected.txt" | xargs -0 -r -n 4 -P 2 sh "$P/tools/ci/run_checks.sh" --worker
if [ "$?" -ne 0 ]; then echo "  workers: FAIL (could not dispatch or record every check)"; F=$((F+1)); fi

while IFS='|' read -r name script setup args; do
  case "$setup" in step:*) echo "  $name: in its own step (${setup#step:})"; continue ;; esac
  [ ! -f "$T/logs/$name.log" ] || ran=$((ran+1))
  if [ -s "$T/logs/$name.status" ] && cat "$T/logs/$name.report"; then
    [ "$(cat "$T/logs/$name.status")" = 0 ] || F=$((F+1))
  else
    echo "  $name: FAIL (worker did not record a complete result)"
    F=$((F+1))
  fi
done < "$T/selected.txt" || exit 1
echo "Ran $ran headless Godot checks (shard $si of $sn) in $(( $(date +%s) - t_all )) s."
if [ $F -eq 0 ]; then echo "PASS: every listed headless Godot check passed."; else echo "FAIL: $F Godot check(s) failed."; exit 1; fi
