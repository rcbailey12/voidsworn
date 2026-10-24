# Screening: Packs G, H, I (Qwen returns, round 2)

Screener: Rey (Muse), Oct 23, 2026. Attribution confirmed by Ryan: the second set of returns (G, plus second H and I) is Qwen's. Method as in packFGHI_screening.md: decisive claims spot-checked with grep against the local clone; the ui3d.js guard block was read in full. Filing the model's file does not verify it. Code truth remains Opus's to confirm.

## Pack G (guard-pattern hunt): the headline corrects the record, in the game's favour

Qwen's central classification is right, and it walks back Qwen's own council-era claim. Read in full, the ui3d.js:410 direct-fire block is:

if(u&&u.side==='enemy'){ if(s&&s.side==='player'&&canUse(s)){ const set=firingSet(s,u); if(set.length){ guard(s); await act(...)

The guard(s) return value is indeed discarded (DISCARDED is the correct classification), but the outer condition has just checked canUse(s), and guard(u) itself (ui3d.js:382) returns true exactly when canUse(u) holds, with a side effect (it sets B.activeUnit in alternating mode when unset). So the bare call is currently redundant, not exploitable: the path is gated by canUse(s) one level up. The neighbouring call sites are checked properly (board/blink/nova/launch at ui3d.js:403-406 use &&guard(s); attack-move and movement in the same block do too), matching Qwen's table.

Consequence: the "Alternating-mode guard bypass" carried in the council reconciliation as a spot-verified live bug should be downgraded to a latent hazard. It becomes a live bypass only if the outer canUse(s) check is removed or refactored away. Worth a one-line fix (make it if(guard(s)) for defence in depth), not a sequence slot. The rest of Qwen's classification table spot-checks clean (canFire enforced in fireWeapon, canAbility at useAbility entry, canCommand at useCommand entry; one harmless offset: the table cites canCommand at battle.js:848, the definition sits at 846).

Pack-building note: G's pack included the caller context around the known instance, which is exactly why this return could correct the earlier claim. The transitive-closure pack rule worked as designed.

## Pack H (repairs, Qwen): verdict not accepted as stated; one verified branch adopted

Two load-bearing claims fail verification:

1. "Guaranteed pre-boss Drydock" (verdict header) is wrong. core.js:215 makes c5 a pick of shipyard/drydock/field, and core.js:225 guarantees only that a drydock or a shipyard exists in the column. The annex mapcheck (603 of 900 pre-boss nodes free) is the correct picture: common, not guaranteed. DeepSeek's H had this right.
2. Finding 6 misreads core.js:228. The conversion is not "drydocks in columns 1-3 overwritten 50% of the time": every drydock in columns 1-4 is converted, with certainty; rnd()<.5 only chooses whether it becomes a battle or an event. Direction (no early drydocks) is right; mechanism and column range are wrong.

Qwen's H also never engages the timing problem DeepSeek's H is built on: the drydock sits after the elite it is meant to answer. Its Finding 10 arithmetic for S1 (38% hull, drydock restores 37.2 points, ~75% for the boss) is correct arithmetic for the sector where the elite is weakest.

What survives, and is genuinely new: Findings 8 and 9. repairMult (core.js:183) is (heatOn('h_repair') ? .5 : 1) * (sectorCond().repair || 1); Scarcity carries repair:.75 (data.js:373) and Short supplies halves every repair (data.js:380). Under either, the free-repair loop degrades exactly as Qwen describes, and paid repairs stop being optional. The annex ran no Heat above 0, so no prior audit priced this.

Combined H verdict across both returns: MIXED for the base game on DeepSeek's conditions (contrib/deepseek/reviews/packH_repairs.md), trending SQUEEZED under Short supplies or Scarcity per Qwen's branch. Qwen's base-game CODDLED label is rejected: it rests on a guarantee the generator does not make.

## Pack I (enemy AI, Qwen): sound, narrower than DeepSeek's, three unique adds

Spot-checks verified: FACTION_AI values (battle.js:987), the death-cliff penalty (battle.js:1115; cited as 1116, one-line drift), the overkill-avoidance condition (battle.js:1054; cited as 1048, the block start), escort spacing (battle.js:1118), the standard-AI hold pull (battle.js:1121), boss scaling (battle.js:313), the squadron focus multiplier (battle.js:876), the 35% CP rout (battle.js:786), TERRAIN_META selection (battle.js:193). Minor blemish: Finding 1 pairs its doctrine argument with the Voidsworn blurb (data.js:111) while discussing faction flavour generally; the argument is unaffected.

Unique adds over DeepSeek's I: the death-cliff freeze (a flat -25 on any hex where expected threat >= hp, battle.js:1115), overkill-avoidance spoofing (heavy guns withheld when a lighter gun can finish, battle.js:1054), and the escort ring's predictability. Its rout finding reframes the same line as an anti-farming annoyance; DeepSeek's framing (the rout bypasses Hold/Break/Relay objectives entirely) is the design-critical one, and both readings are consistent with the code.

What Qwen's I misses that DeepSeek's caught: the Intercept escape-win inversion, flak never firing offensively, the telegraphed and cancellable boss Command, the hunt flagship's 9-hex saturation, and the terrain fallback to open. As a pair, the two I audits are complementary: DeepSeek's is the completeness pass, Qwen's is the exploit-hunting pass.

## Net for the chair

1. The Alternating guard item drops from live bug to latent hazard (G). Adjust the reconciliation sequence accordingly.
2. Repairs: adopt DeepSeek's MIXED plus Qwen's heat/condition corollary. The contest is closed.
3. Across both rounds of H and I, Qwen's pattern holds: sharpest single-mechanism catches (death cliff, repairMult branch, guard context), weaker on enumeration and on any claim that depends on reading a generator's guarantee precisely (drydock "guarantee", conversion "50%").
