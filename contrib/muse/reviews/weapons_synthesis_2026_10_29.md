# Weapons audit - synthesis (Oct 29 program)

Four prongs: DeepSeek, Qwen, Argon, Rey (blind). All four verdicts: DUPLICATES WITH PAINT. The program's only unanimous item, now across four independent reads of the 25-weapon table at pin 264f441d.

## Verdict: DUPLICATES WITH PAINT (4 of 4)

The arsenal has a readable spine (kinds, arcs, ranges, and the torpedo system all earn their place), but the table itself contains one literal duplicate, two statistical clones, and a rename layer that sometimes carries a trait and sometimes only paint.

## Findings that stand

1. flak and gsentry are the same weapon (4 of 4 legs; chair verified field-for-field). Identical in every field including kind: {shots:3, dmg:3, r:2, opt:2, acc:80, fall:10, vsSq:3, vsCap:.6}. Mount counts diverge wildly (11 flak mounts, 1 gsentry), so the table pays a slot of design space for zero mechanical difference. The Rey leg adds the sharpest framing: Eclipse effectively lists the same point-defense gun twice, gsentry plus its own flak rename ("Null shredder").

2. turbo and gauss share an expected-damage line (Qwen, Rey; chair verified). Identical expected damage (13.32) on the same envelope; gauss weakly dominates on pierce .6 alone. Whatever separates them in play comes from the faction trait layer, not the table.

3. autocannon and laser are near-clones (Qwen); hbattery strictly dominates battery on the table itself (DeepSeek: same envelope, +1 shot, +1 dmg, +1 crit). Chair caveat carried from screening: mount availability and CP may separate the battery pair in the full data, so this is a table-level dominance, not yet a proven in-game one. An Opus check on mounts and CP settles it.

4. The torpedo design comment contradicts the live constants (Argon alone; chair verified at battle.js:531-536). The comment promises penalties of 10 and 25 for off-center hits and "Range 6"; the constants are TORP_RING [0,5,15] and range 5. The comment is the design record a future reader (or the Godot port) will trust. Fix the comment or the constants, deliberately.

5. Dead data in the table (Argon, Qwen): startorp's evMult:2 is overwritten by the Ithar trait in live play and exists only in no-trait sims; ARC_NAME defines a Rear arc no weapon uses, under the standing rule that guns never face backward. The turret is the only all-arc weapon, so the facing economy is close to binary (Qwen).

6. Renames split into two kinds (all legs agree): renames backed by a faction trait that rewrites the weapon (the Corsair rockets trait genuinely rewrites torpedoes, Qwen) are real differentiation; renames without a trait are paint. The Hegemony battery-kind gun renamed "Plasma lance" also collides with the lance kind name (Argon), a readability defect in a table where kind drives mechanics.

7. doom is an extreme spike (Qwen): 1 shot at 40 damage, expected 31.2, cooldown 2, two mounts. Noted, not graded a defect by any leg.

## What the legs protect

Torpedoes earn their complexity (4 of 4): the ring falloff, stray chance, and warhead multiplier make them the one system where the table's intricacy pays for itself. Ion's shield-stripping is settled as weapon flavor per the Oct 24 ruling and is not re-litigated here.

## Chair corrections applied

Argon's "30 effective shield damage" for ion was its own arithmetic, not a rule, and is not carried. No leg's headline claim failed verification on this item.

## For Opus (observations, not a gate)

- Decide gsentry: give it a real delta (range, a trait hook, a squadron-specific behavior) or delete it and let the rename carry the slot.
- Reconcile the torpedo comment with TORP_RING and range 5.
- One-read checks: hbattery/battery mount and CP separation; whether the Rear arc entry and startorp evMult should be deleted from the shared data file (both are carried into Godot by the shared-data rule).

## Designer questions

None requiring Ryan. The choices above are table hygiene within Opus's technical lane; if gsentry gets a new mechanic rather than deletion, that mechanic is a design choice Opus can propose and Ryan can veto.
