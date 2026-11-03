1. Headline verdict
- Yes: the faction spread is still in shape after the four landed changes.
- Strongest evidence: five of six factions are exactly unchanged; the only shift is Hullbreakers 60.0→58.0, which is one run at n=50, and its 95% CI 44.2-70.6 contains the v2 value.
- Spread 12→14 is that one run (72-58 vs 72-60), not a broad movement; 14 is below the >15 trigger.

2. Shift table read
At n=50 per faction, one run = 2.0 percentage points. At 300 total runs, one run = 0.33 points.

| Faction | v2 win % | Now win % | Shift | Runs | Now 95% CI | v2 inside CI? |
|---|---|---|---|---|---|---|
| Sunward Crusade | 64.0 | 64.0 | 0 | 0 | 50.1-75.9 | yes |
| Hegemony Navy | 70.0 | 70.0 | 0 | 0 | 56.2-80.9 | yes |
| Ashfall Hullbreakers | 60.0 | 58.0 | -2.0 | -1 | 44.2-70.6 | yes |
| The Chorus | 64.0 | 64.0 | 0 | 0 | 50.1-75.9 | yes |
| The Glasswrights | 68.0 | 68.0 | 0 | 0 | 54.2-79.2 | yes |
| Eclipse | 72.0 | 72.0 | 0 | 0 | 58.3-82.5 | yes |
| Overall | 66.3 | 66.0 | -0.3 | -1/300 | 60.5-71.1 | yes |

Read: no faction movement is outside noise at n=50. Five factions have exact zero shifts on these seeds; the only nonzero shift is one run.

3. Attribution -- four landed changes
- Shield-venting cap (max 2/turn): no signature in the table. No faction moves, so nothing points to a cap effect in this run set.
- Hullbreakers anti-swarm: no signature in the table. The Hullbreakers shift is one run and inside its CI, so it does not identify an anti-swarm effect.
- Glasswright trunk perk line: no signature in the table. Glasswrights are exactly unchanged at 68.0%.
- Hull-breaker hull threshold 35%→25%: no signature in the table. The one-run Hullbreakers dip is within noise and does not isolate a threshold effect.
No change is implicated by this table.

4. Hullbreakers one-run move
- The move is 60.0%→58.0% (30/50→29/50), one run.
- At n=50, a one-run move is the smallest possible nonzero shift and is well inside noise; the 95% CI for 29/50 is 44.2-70.6.
- The v2 value 60.0% lies inside that CI, so the move is consistent with no change.
- One run cannot support a balance conclusion either way; it is noise at this sample size, not evidence of a nerf or a buff.

5. 15-point trigger
- Trigger: spread >15 points.
- Current spread: 72.0-58.0=14.0 points.
- Result: not triggered.
- Margin: 1.0 point, which is less than one run at n=50 (2.0 points). A single additional Hullbreakers loss, or a single Eclipse win, would push the spread to 16 and trigger it. The trigger is therefore within one run, even though it is not currently met.

6. Owner questions
- No new data.js numbers are proposed here, and no owner question is needed to support one.
- If the owner wants a more decisive recheck before locking v2, the single highest-value question is: "Re-run Hullbreakers and Eclipse at n=200+ with the same seed discipline before treating the 14-point spread as stable?" -- no pick is made here, because the instruction for this leg was to ask only if needed, and no question is needed for the verdict above.

7. Not checked
- Per-admiral v2 splits were not re-derived.
- Which Hullbreakers seed flipped was not identified.
- Whether effect caps actually bind in these runs was not checked.
- Glasswright XP/perk reach inside the runs was not checked.
- Profile-persistent shadow XP was not checked.
- Unlocked/gated progression state was not checked.
- Human rates were not checked.
- Policy sensitivity beyond the pack's caution was not checked.
- Timeout handling and possible bias from the 4 battle timeouts were not checked.
- Raw runner output beyond the supplied table was not checked.
- Statements about cap binding, perk reach, and gate masking are INFERRED.
