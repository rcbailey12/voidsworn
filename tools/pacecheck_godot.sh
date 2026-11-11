#!/bin/sh
# F2 pace check for the Godot battle (feel pass, Nov 1; replaces the retired 12 s target and 15 s round limit, R64).
# Plays three bot battles headless at 60 fixed frames a second (real game speed, outcomes as the rules decide) and checks
# every move against Ryan's movement ruling, then reports the enemy's time per round (report only: no round limit now).
#   - each hull's cruise pace is 500 to 1250 ms a hex (560 for an escort, 860 for a battleship, and on past it for
#     dreadnoughts and bosses up to about 1100 since issue 505, a small faction flavour on top);
#   - no move runs longer than 7 s at normal speed;
#   - ships move one at a time (never two burns at once);
#   - enemy moves play at the ship's own pace (no squeeze on the enemy's turn): speed 1.00 unless hurried.
# Usage: GODOT=/path/to/godot sh tools/pacecheck_godot.sh [scenario ...]   (default: s26 s23 s24, 10, 20 and 28 ships)
#        MOV=segments plays the pre-F2 motion and pace for a before number (its move checks then fail by design).
cd "$(dirname "$0")/.." || exit 1
G="${GODOT:-godot}"; OUT="${OUT:-/tmp/pacecheck_godot}"; mkdir -p "$OUT"
SC="${*:-s26 s23 s24}"
EXTRA=""; [ -n "$MOV" ] && EXTRA="--movement $MOV"
F=0
for s in $SC; do
  "$G" --headless --fixed-fps 60 --path godot -- --scenario "$s" --bot --pace-report --fast 1 --move-trace $EXTRA > "$OUT/$s.txt" 2>&1
  python3 - "$OUT/$s.txt" "$s" <<'EOF' || F=$((F+1))
import sys, re, json
txt = open(sys.argv[1], encoding='utf-8', errors='replace').read(); sc = sys.argv[2]
m = re.search(r'\[battle\] report: (\{.*\})', txt)
if not m:
    print('  %s: FAIL (no battle report; see %s)' % (sc, sys.argv[1])); sys.exit(1)
rep = json.loads(m.group(1)); pace = rep.get('pace', {})
mv = re.findall(r'^\[move\] (\S+) (\S+) (\S+) size ([\d.]+) hexes (\d+) turns (\d+) dur ([\d.]+) s, (\d+) ms a hex, speed ([\d.]+)', txt, re.M)
bad = []
hull = [x for x in mv if x[2] != 'Squadron']
for x in hull:
    per, dur, spd = int(x[7]), float(x[6]), float(x[8])
    if spd >= 0.99 and not (500 <= per <= 1250): bad.append('%s %s pace %d ms a hex' % (x[0], x[2], per))
    if spd >= 0.99 and dur > 7.05: bad.append('%s %s move %.2f s' % (x[0], x[2], dur))
    if x[1] == 'enemy' and spd < 0.99: bad.append('%s enemy move squeezed (speed %.2f)' % (x[0], spd))
ov = len(re.findall(r'^\[move\] overlap', txt, re.M))
if ov: bad.append('%d moves started while another burned' % ov)
durs = sorted(float(x[6]) for x in hull)
med = durs[len(durs) // 2] if durs else 0
print('  %s: %s  enemy time a round: mean %.1f s, worst %.1f s over %d rounds (%s); moves %d, median %.1f s, longest %.1f s; enemy move share %.1f s a round' % (
    sc, 'PASS' if not bad else 'FAIL', pace.get('enemy_s_mean', 0), pace.get('enemy_s_max', 0), pace.get('rounds', 0), rep.get('result', '?'),
    len(hull), med, durs[-1] if durs else 0, pace.get('per_round_by_kind', {}).get('move', 0)))
print('     by round:', pace.get('by_round'))
for b in bad[:8]: print('     ' + b)
sys.exit(1 if bad else 0)
EOF
done
if [ $F -eq 0 ]; then echo "PASS: every move meets the movement ruling (R64)."; else echo "FAIL: $F battle(s) with moves outside the ruling."; exit 1; fi
