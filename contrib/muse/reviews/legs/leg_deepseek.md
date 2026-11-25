# Leg: DeepSeek (DeepThink on, Search off), issue 2063

Gate record: New chat, account already signed in. DeepThink ON and Search OFF verified before sending and again after generation. The first paste became a file chip; the browser converted it back to plain text and verified a single copy with no attachment before sending. Chat: "Combined PR review", https://chat.deepseek.com/a/chat/s/e7185dd9-3648-4807-9777-2cfbbdbfbfa8

Response verbatim:

Findings, most important first (Q1)

1. godot/fx/fx.gd:813: quote `const SPARK_KIND := 8`. OBSERVED. INFERRED: PR 2049 reroutes kind 8 at line 822, while main and PR 2049 keep deathless smoke at kind 8 and PR 2007 adds another kind 8 emitter. The shared spark path can swallow Eclipse smoke. Fix: rename SPARK_KIND or move all Eclipse smoke off kind 8 before merging.

2. godot/fx/fx.gd:822: quote `if kind in [1, 7, SPARK_KIND]:`. OBSERVED. INFERRED: PR 2007 assigns kind 7 to Hegemony fire and non-organic vent sprites, so 2049 treats those as shared sparks. Fix: remove 7 from the spark reroute or reassign 2007's kind 7 uses.

3. godot/fx/fx.gd:760: quote `const SMOKY := {3: true, 7: true, 8: true, 15: true, 20: true, 23: true, 27: true, SH.BIO_CONTACT_GLOB: true}`. OBSERVED. INFERRED: 2021 marks kinds 7, 8 and 20 as smoke, but 2007 uses 7 for fire/vents, 8 for Eclipse smoke and 20 for Chorus hatch/vents. This is a three-way kind table clash. Fix: reconcile the kind table across 2007, 2021 and 2049 before merge.

4. godot/fx/fx_ship.gd:1908: quote `"deathless": return fac["damage_glow"]`. OBSERVED. INFERRED: 2021 makes Eclipse acid violet, but 2049 still carries the old green line at its branch line 1886 and the edits do not textually conflict, so a bad resolution can restore green. Fix: keep 2021's violet line and rerun its violet acid test after merging 2049.

5. godot/fx/faction_looks.json, line not given: quote `PR 2007 retunes in faction_looks.json (PR 2049 also edits that file)`. OBSERVED. INFERRED: 2007 retunes Directorate `damage_glow`, and 2049's shared spark defaults to that colour; a faction_looks conflict can drop one side and break the Directorate spark palette rule. Fix: resolve faction_looks once and rerun 2049's faction palette test.

6. godot/fx/fx_death.gd, line not given: quote `2007 x 2049 conflict in 8 files`. OBSERVED. INFERRED: death effects are touched by 2007, 2049 and 2021; the earlier death-plane failure and death variety test must be rechecked after combination. Fix: resolve death files together and rerun death-plane and death-variety checks.

7. godot/fx/fx_weapons.gd, line not given: quote `shield_hit call sites in the shared fx_weapons.gd hunks are unchanged by 2007 and 2049`. OBSERVED. INFERRED: 2049 x 2021 conflict in fx_weapons, and the pack does not say 2021 leaves shield_hit alone. Quiet shield blocks and one shield pool need a post-merge check. Fix: rebase 2021 on the merged fx_weapons and rerun quiet shield tests.

8. PR 2021 wave2b_run4.bat, line not given: quote `LB_MOMENTS=res://bench/look_moments_1693_run4.json`. OBSERVED. INFERRED: 2007's launcher checks `if not exist "%LB_MOMENTS%"`, which is a Windows file check; a res:// path will fail when the launchers combine. Fix: pass a real Windows path in 2021's launcher.

9. PR 2007 capture.bat, line not given: quote `LB_AFTER=origin/codex/issue-1991`. OBSERVED. INFERRED: AFTER is a branch ref, not a full SHA; 2049 and 2055 also default AFTER or BEFORE to branch refs. Fix: pin every AFTER and BEFORE to a full commit SHA.

Q2: faction rules that break only on combination

From this pack, no faction rule is proven to break only on combination. The concrete combination-only risks are:

Eclipse no green: only if the merge keeps 2049's old green acid line instead of 2021's violet line. That is a merge-resolution risk, not a proven break in either PR by itself.

Directorate sparks follow damage_glow: only if the faction_looks conflict drops 2007's retune while 2049 uses damage_glow for spark tint.

Chorus no metal sparks and Glasswrights no orange fire, soot or white cold gas: not enough info. The kind 7 and kind 20 reassignments are suspicious, but the pack does not show the actual sprite calls or post-merge renders.

Q3: safe merge order and rechecks

Order: 2049, 2055, 2007, 2021. Merge 2021 last only after its own Godot checks pass. Fix 2007's standing checks before its step.

After 2049: rerun all checks; shared spark palette test; quiet shield test; audit kind 7 and kind 8 uses.

After 2055: rerun all checks; render and bench checks; ship_view.gd and squadron_wing.gd; capture launcher path handling.

After 2007: fix standing checks; rerun death-plane and death-variety checks; resolve faction_looks; reconcile kind 7, kind 8 and kind 20 against 2049 and 2021; rerun Directorate palette test.

After 2021: rerun all Godot checks; violet acid test; bio glob kind 29 test; SMOKY kind table against 2007; fx_weapons shield quiet check; fx_shaders conflict resolution; launcher LB_MOMENTS Windows path.

Strongest objection to the chair's likely synthesis

The chair cannot call any merge order safe while PR 2021 fails nearly every Godot check on its own head. Putting it last does not cure that. It must be green before it is a merge candidate at all.

Not checked:

Actual post-merge rendering of Glasswrights, Chorus, Eclipse and Directorate faction rules.

Whether 2007's new kind 8 emitter uses stk() or spr().

Exact line numbers for faction_looks.json, fx_death.gd, fx_weapons.gd and the .bat launchers.

Whether 2021's fx_weapons changes touch shield_hit call sites.

Full post-merge test results, wreck cap, death-plane, one shield pool and kind 29 against 2055 thrust sprites.

Whether branch-ref AFTER values in the launchers resolve to full SHAs in practice.
