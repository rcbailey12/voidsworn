Chair note: filed verbatim from the Qwen3.8-Max run of Oct 29, 2026 (both model gates passed, single response), except em dashes, en dashes, and unicode minus signs in the model's text are normalized to hyphens.

WEAPONS AUDIT REPORT - VOIDSWORN

1. PROOF OF READING

Sections read:
- EVIDENCE PACK title line ("EVIDENCE PACK: weapons audit (code slices from the shipped browser build, main 264f441d…)")
- THE COMMISSIONER'S QUESTION (roguelite fleet-tactics, hull audit precedent, three charges: readable job, duplication, facing decisions)
- CHAIR CENSUS (25 weapons, stat fields, faction rename/trait system, mount counts, design rules: no rear-facing, ≤20 ships)
- WHAT TO JUDGE (five numbered questions)
- Code slice: data.js 1-60 (W table, ARC_NAME, KIND_NAME, FAC_WNAMES, WTRAITS, FAC_WTRAIT, nameWeapons())
- Code slice: battle.js 531-536 (torpedo travel rules, TORP_RING, TORP_STRAY, TORP_WARHEAD, tuning note)

Overall verdict: DUPLICATES WITH PAINT.
At least one pair is stat-identical, a second pair produces the same expected damage from the same envelope, and faction renames frequently change nothing mechanical; the arsenal has real ideas buried under redundancy.

2. FINDINGS (most severe first)

F1 [BLOCKER] - flak and gsentry are the same weapon
READ. Both entries in W are {shots:3, dmg:3, r:2, opt:2, acc:80, fall:10, vsSq:3, vsCap:.6}. Every field matches. gsentry's kind is 'flak', same as flak. The only differences are the display name ("Flak battery" vs "Null sentries") and the faction that fields it (flak appears in five faction rename lists; gsentry appears only in Deathless's). The chair census gives flak 11 mounts and gsentry 1. A player who sees both in a run will see the same numbers under two skins. This is the exact failure mode the hull audit found.

F2 [FIX] - turbo and gauss produce identical expected damage from the same envelope
READ. turbo: {shots:2, dmg:9, r:5, opt:3, acc:74, fall:8, crit:5} → 2×9×0.74 = 13.32. gauss: {shots:3, dmg:6, r:5, opt:3, acc:74, fall:8, crit:5} → 3×6×0.74 = 13.32. Same range, same optimal, same accuracy, same falloff, same crit. The sole mechanical delta is gauss's pierce:.6. That is a real keyword, but the base envelope is a copy. If pierce is not surfaced clearly in the UI, these read as one gun. INFERRED: the shot/dmg split (2×9 vs 3×6) also changes crit variance and overkill waste, but the expected-value identity makes the pair feel cloned.

F3 [FIX] - autocannon and laser are near-clone batteries at the same range band
READ. autocannon: {shots:3, dmg:5, r:4, opt:2, acc:80, fall:8, crit:5} → 12.0 expected. laser: {shots:2, dmg:7, r:4, opt:3, acc:80, fall:8, crit:5} → 11.2 expected. Same kind (battery), same range, same accuracy, same falloff, same crit. They differ by 0.8 expected damage and one point of optimal range. INFERRED: a player choosing between these two is not making a meaningful tactical decision; they are picking a number off a coin flip.

F4 [FIX] - spores is a marginal reskin of flak
READ. spores: {shots:3, dmg:4, r:2, opt:2, acc:78, fall:8, vsSq:3, vsCap:.6}. flak: {shots:3, dmg:3, r:2, opt:2, acc:80, fall:10, vsSq:3, vsCap:.6}. Deltas: +1 dmg, -2 acc, -2 falloff. Both are kind 'flak', both carry the same vsSq and vsCap multipliers. INFERRED: the +1 damage on spores is roughly offset by the -2 accuracy; the falloff change at range 2 (where both already sit at optimal) is negligible. This is a rounding-error gap, not a decision.

F5 [FIX] - the turret is the only all-arc weapon in the entire table
READ. ARC_NAME defines T:'Turret (all arcs)'. Only the weapon id turret uses it. Every other weapon is prow, port, or starboard. The facing economy therefore collapses to "turret vs. everything else." INFERRED: with a single all-arc option, the fixed-vs-turret tradeoff is not a spectrum; it is a binary, and the turret's stats (2×8, acc 74) are close enough to the fixed batteries around it that the "price" of flexibility is unclear. See §FACING ECONOMY below.

F6 [NOTE] - the design rule "weapons never face backward" coexists with an R:'Rear' arc label
READ. The CHAIR CENSUS states "weapons never face backward." ARC_NAME includes R:'Rear'. No weapon in W is assigned to arc R. INFERRED: the Rear arc is dead data. It should be removed or the rule should be re-stated, because a future designer will see R in the enum and assume it is loadable.

F7 [NOTE] - ion has 1 chair and its key mechanic (ion:2.5) is unexplained in the pack
READ. ion is {shots:1, dmg:12, r:6, opt:5, acc:80, fall:6, ion:2.5, crit:4}. The field ion:2.5 appears nowhere else in the code slices. The CHAIR CENSUS gives it 4 mounts across all hulls, but no rule text explains what ion does to shields. INFERRED: without the shield-interaction rule, I cannot judge whether ion earns its slot or is just a weaker lance (12 dmg vs lance's 20, no pierce).

F8 [NOTE] - the 'rockets' faction trait rewrites torpedo mechanics wholesale
READ. WTRAITS.rockets: "shots*=3; dmg=Math.round(w.dmg/2.9); acc+=2; evMult=1.5; rockets=1". Applied to Corsair torp (1×42, acc 64, evMult 2), this yields 3 shots × 14 dmg, acc 66, evMult 1.5, and a rockets flag that the description says "point defense can shoot…down." This is not a rename; it converts a single heavy torpedo into a three-round rocket salvo with a new counterplay axis. INFERRED: this is the strongest example of a faction trait creating a genuinely different weapon, and it works. The same trait on htorp (2×34) yields 6×12, which is a very different profile.

F9 [NOTE] - most faction renames are cosmetic until a trait is applied
READ. FAC_WNAMES maps e.g. voidsworn autocannon → "Sear repeater," hegemony laser → "Plasma cannon," corsair scatter → "Scrap scatter gun." The code comment says "the numbers underneath are unchanged until the v47 mechanics pass." FAC_WTRAIT then applies traits to some but not all renamed weapons. For instance, Voidsworn renames seven weapons but only five receive traits (autocannon, battery, hbattery, turret get 'las'; torp gets 'hellfire'). The remaining two (lance as "Oath lance," flak as "Spark flak") are pure renames. INFERRED: a player who sees "Oath lance" will expect it to differ from a generic lance. It does not. This is paint.

F10 [NOTE] - doom's damage spike is extreme relative to every other lance
READ. doom: {shots:1, dmg:40, r:5, opt:4, acc:78, fall:6, pierce:.6, crit:12, cd:2}. Expected: 31.2. The next highest lance is pulsar at 19.2. Doom is 63% above pulsar and has a cooldown. INFERRED: with only 2 chairs in the entire roster, doom is a rare capstone, so the spike may be intentional. But the pack gives no rule for how cooldown interacts with the ≤20-ship battle cap, so I cannot judge whether cd:2 is a meaningful tax or trivially absorbed.

3. EXPLICIT CHECKS

3A. ROLE CLARITY
One-line job for each of the 22 non-squadron weapons, derived from numbers alone:
1. autocannon - Cheap short-range volume battery (3×5, r4, opt 2).
2. flak - Anti-squadron screen; nearly useless vs. capitals (vsSq 3, vsCap .6, r2).
3. battery - Reliable mid-range broadside DPS (4×6, r5).
4. hbattery - Upgraded battery: more shots, more damage, same envelope (5×7, r5).
5. lance - Long-range single-shot sniper with heavy pierce (1×20, r7, pierce .6).
6. torp - Massive delayed strike on a marked hex; dodgeable, cd 2 (1×42, r6).
7. turret - All-arc flexible battery; the only weapon covering every facing (2×8, r5).
8. laser - Accurate short-mid battery; slightly weaker than turbo, tighter opt (2×7, r4).
9. turbo - Harder-hitting mid-range battery; slight upgrade over laser (2×9, r5).
10. hturbo - Sustained heavy mid-long battery; upgrade path from turbo (3×9, r6).
11. ion - Anti-shield utility lance; the ion:2.5 field implies shield stripping (1×12, r6).
12. scatter - Close-range spray; high shot count, steep falloff, short reach (5×5, r3, fall 10).
13. htorp - Double-tap delayed torpedo; higher volume, lower per-shot dmg than torp (2×34, r6).
14. tendril - Point-blank boarding bio-weapon; range 1, high pierce (2×13, r1, pierce .5).
15. bioplasma - Mid-range bio damage with light pierce (2×12, r4, pierce .2).
16. spores - Anti-squadron screen; marginally stronger than flak (3×4 vs 3×3, r2).
17. pulsar - Multi-shot piercing lance; sustained lance DPS (2×12, r6, pierce .6).
18. startorp - Delayed strike, shorter range but more pierce than torp (1×38, r5, pierce .4).
19. gauss - Armor-ignoring mid-range battery (3×6, r5, pierce .6).
20. gsentry - Anti-squadron screen (identical to flak in every stat).
21. doom - Super-heavy slow-firing lance; capstone damage (1×40, r5, cd 2, pierce .6).
22. shard - Battery with an anti-squadron bonus; hybrid role (3×6, r4, vsSq 1.6).

Flags:
- gsentry's job is literally the same sentence as flak's. I cannot distinguish them from numbers. They are the same gun.
- laser and autocannon both resolve to "accurate short-range battery." The one-liners are nearly interchangeable; only the shot/dmg split and 1 point of optimal range differ.
- turbo and gauss both resolve to "mid-range DPS battery with identical expected output." The pierce keyword is the only separator, and it is a keyword, not a shape change.
- spores and flak both resolve to "anti-squadron screen at range 2." The +1 dmg / -2 acc delta is noise.
Four pairs produce functionally identical one-liners. That is four too many for a 22-weapon table.

3B. DUPLICATION
Three closest pairs:
Pair 1 - flak vs gsentry (kind: flak / flak)
Every stat is identical: 3 shots, 3 dmg, r2, opt2, acc80, fall10, vsSq3, vsCap.6. The difference is zero. This is not a decision; it is a copy-paste with a different display string. gsentry exists only so the Deathless faction can call flak "Null sentries." The 11-to-1 chair split means gsentry is effectively a faction skin on flak, not a weapon.
Pair 2 - turbo vs gauss (kind: battery / gauss)
Both produce 13.32 expected damage. Both sit at r5, opt3, acc74, fall8, crit5. The differences are the shot/dmg split (2×9 vs 3×6) and gauss's pierce:.6. Pierce is a real mechanical keyword - it changes how armor interacts with the hit - but the base envelope is cloned. The difference is a decision (pierce matters against armored targets), but the fact that the expected DPS is identical to the decimal means the numbers were likely derived from the same starting point, and the player sees two guns that do "the same damage" with one having a bonus tag.
Pair 3 - autocannon vs laser (kind: battery / battery)
autocannon: 3×5, r4, opt2, acc80, fall8, crit5 → 12.0. laser: 2×7, r4, opt3, acc80, fall8, crit5 → 11.2. Same kind, same range, same accuracy, same falloff, same crit. Expected damage differs by 0.8. The difference is a rounding error. Optimal range shifts by one hex (2 vs 3), which changes the sweet spot, but the overall shape - accurate, short-range, low-damage battery - is the same. A player cannot articulate why they would pick one over the other without looking at a spreadsheet.

3C. FACING ECONOMY
The table has exactly one all-arc weapon: turret (arc T). Every other weapon is fixed to Prow, Port, or Starboard. The design rule adds that no weapon faces Rear.
Does the fixed constraint pay?
Turret stats: 2×8, r5, acc74 → 11.84 expected. Compare to the fixed batteries around it:
- turbo (fixed): 2×9, r5, acc74 → 13.32. Turret sacrifices ~11% damage for all-arc coverage.
- battery (fixed): 4×6, r5, acc72 → 17.28. Turret sacrifices ~31% damage.
- hbattery (fixed): 5×7, r5, acc72 → 25.2. Turret sacrifices ~53% damage.
The tax scales with the fixed gun it replaces. Against a single battery mount, the turret gives up modest damage. Against a heavy battery, it gives up half the output. INFERRED: in a ≤20-ship hex battle where flanking and facing matter, the turret's value should spike when a ship is surrounded or outmaneuvered. But the pack provides no movement or hex-facing rules, so I cannot verify whether the tactical situations that reward all-arc fire actually arise often enough.
Is there a weapon you would only ever take on a turret, or never on one?
The turret is the only all-arc option, so the question inverts: is there any weapon that should also be available as a turret? The pack does not offer turret variants of lance, torp, or gauss. INFERRED: a turret-mounted gauss or lance would create a genuine "flexibility vs. power" decision at the heavy end. As it stands, the facing economy is a single data point (turret) versus everything else, which is not an economy - it is a toggle.
The design rule "weapons never face backward" further compresses the decision space: no ship can cover its rear, so the turret's "all arcs" claim is the only rear coverage in the game. INFERRED: if the Rear arc label in ARC_NAME is truly dead, the turret is even more valuable than the numbers suggest, because it is the only way to shoot behind you. That should probably cost more than 11% damage.

3D. FACTION TRAITS
I will examine two weapons that appear across multiple factions.
Weapon 1: autocannon (base: 3×5, r4, opt2, acc80, fall8, crit5)
- Voidsworn renames it "Sear repeater" and applies trait las: fall = ceil(8/2) = 4; acc += 4 → 84. The weapon becomes more accurate and holds damage better at range. This changes the engagement profile: the Voidsworn autocannon is a mid-range gun, not a short-range brawler. This is a real decision change.
- Corsair renames it "Autocannon" (no rename) and applies trait scrap: shots += 1 → 4; acc -= 12 → 68; crit += 3 → 8. The weapon becomes a high-volume, low-accuracy crit-fisher. This is a real decision change.
- No other faction fields autocannon.
Verdict for autocannon: the two faction variants play genuinely differently. The las trait extends range; the scrap trait trades accuracy for volume and crits. These are different weapons in practice. The renames support the mechanical shift.
Weapon 2: turret (base: 2×8, r5, opt3, acc74, fall8, crit5)
- Voidsworn renames it "Sear turret" and applies trait las: fall → 4; acc → 78. Slightly better at range.
- Corsair renames it "Junk turret" and applies trait scrap: shots → 3; acc → 62; crit → 8. Wild but crit-heavy.
- Ithar renames it "Needle beam" and applies trait needle: acc += 6 → 80; crit += 8 → 13. Precise and deadly.
- Hegemony does not field turret. Chorus does not field turret. Deathless does not field turret.
Verdict for turret: three factions apply three different traits, and each meaningfully changes the weapon. The Ithar "Needle beam" turret at 80 acc / 13 crit is a precision instrument; the Corsair "Junk turret" at 62 acc / 8 crit is a scattergun. These are real decisions.
However: the pack also contains renames with no trait. Voidsworn's lance ("Oath lance") and flak ("Spark flak") are renamed but carry no trait. Hegemony's ion is renamed "Ion cannon" (the same name) with no trait. These are paint. The comment in the code confirms: "the numbers underneath are unchanged until the v47 mechanics pass." For these entries, the rename creates a false expectation of difference.
Overall: the trait system works where it is applied. The problem is coverage: some renamed weapons get traits and some do not, and the player cannot tell which is which without inspecting the code.

3E. SPECIAL SYSTEMS
Torpedoes (torp, htorp, startorp)
The delayed-strike mechanic is the most complex system in the pack. Torpedoes launch, travel along a lane, and resolve at the start of the firing side's next turn against a marked hex. The target can dodge (2-hex radius, scaling penalty), a stray enemy can absorb the hit, or the salvo can miss entirely. Damage multipliers are locked at launch; accuracy, shields, armor, and PD resolve at impact. Cooldown 2 prevents spam. The evMult field (2 for torp/htorp, modified to 1.5 by Corsair rockets) governs how hard the torpedo is to dodge.
Does it earn its complexity? Yes. The delayed resolution creates a unique decision: you fire at where the enemy is, hoping they will still be there next turn. This is a prediction game layered on top of the damage game, and no other weapon kind replicates it. The three torpedo variants (single heavy, double heavy, shorter-range high-pierce) offer meaningful spread.
What breaks if deleted? The evasion/positioning counterplay disappears. Every other weapon resolves instantly. The "dodge the torpedo" minigame, which the tuning note ("torpedo admirals fell out of the 50 to 90 band") suggests was actively balanced, vanishes. The Corsair rockets trait, which adds a PD-interaction layer to torpedoes, also loses its host.
Ion cannon (ion)
The ion:2.5 field is the entire mechanic. The pack does not include the rule for what ion does to shields. INFERRED: it likely strips or bypasses 2.5 points of shield per hit, making it the dedicated anti-shield tool. With only 4 chairs and 1 weapon carrying the field, ion is a narrow utility pick.
Does it earn its complexity? Marginal. The ion field is a single number, so the complexity cost is low. But with no rule text in the pack, I cannot confirm it interacts meaningfully with the shield system. If ion just adds flat damage against shields, it is a weaker lance (12 vs 20 dmg, no pierce) and does not justify a separate weapon slot.
What breaks if deleted? If ion is the only shield-counter, deleting it removes the player's ability to answer shield-heavy compositions without brute-forcing through with pierce weapons. That may or may not matter depending on how prevalent shields are, which the pack does not state.
Point defense: flak and gsentry
Both are {shots:3, dmg:3, r2, opt:2, acc:80, fall:10, vsSq:3, vsCap:.6}. They exist to counter squadrons (vsSq:3 triples damage vs. squadron targets) and are nearly useless vs. capitals (vsCap:.6). Spores occupies the same niche with slightly different numbers.
Does the system earn its complexity? The role earns its place: without point defense, squadrons have no counter. But two identical weapons (flak and gsentry) do not earn their combined complexity. One weapon with the faction rename would suffice. The 11-to-1 chair split confirms gsentry is a Deathless-flavored reskin, not a design.
What breaks if deleted? Squadrons (guns, bombs, sporeb) become uncounterable. The vsSq multiplier is the only mechanical lever against them. Deleting flak/gsentry/spores removes the counterplay axis entirely.
Doom (Corona arc)
{shots:1, dmg:40, r:5, opt:4, acc:78, fall:6, pierce:.6, crit:12, cd:2}. One shot, 40 damage, half-armor pierce, 12% crit, cooldown 2. Expected damage 31.2. The next-highest lance (pulsar) does 19.2. Doom is a 63% spike.
Does it earn its complexity? The cd:2 and single-shot delivery make it a "fire once, wait two turns" weapon. In a ≤20-ship battle, that is a significant tempo cost. INFERRED: if battles last 6-8 turns, doom fires 2-3 times. At 31.2 expected per shot, that is 62-94 total damage over a battle, which is competitive but not broken. The Deathless faction's gauss trait (armorPierce .5) stacking with doom's pierce .6 could be very strong, but the pack does not specify whether pierce and armorPierce stack or take the maximum.
What breaks if deleted? The Deathless lose their capstone. The lance kind loses its top end (lance → pulsar → doom is a clear escalation). The 2-chair scarcity means doom is already a rare draft; deleting it removes the "one big hit" fantasy without replacing it.

4. NOT CHECKED
The following questions cannot be answered from this pack:
1. Shield mechanics. The ion field and shield interaction rules are not in the code slices. I cannot judge whether ion, pierce, or any shield-stripping mechanic is balanced.
2. Armor model. Pierce and armorPierce are referenced but the armor calculation is not shown. I cannot judge whether gauss's pierce .6 or the Deathless gauss trait's armorPierce .5 are strong, weak, or redundant.
3. Movement and hex-facing rules. The facing economy judgment depends on how often ships are flanked or outmaneuvered. No movement rules are in the pack.
4. Squadron combat resolution. vsSq and vsCap multipliers are stated, but the squadron combat loop (how squadrons attack, how PD intercepts, how vsSq is applied) is not shown.
5. Cooldown interaction with battle length. cd:2 on torp and doom is a tax, but without knowing average battle length, I cannot size the tax.
6. Faction hull budgets. The CHAIR CENSUS says "same hulls and budgets" for the trait pass, but the hull table is not in this pack. I cannot judge whether weapon loadouts are constrained fairly.
7. The Godot port. The pack states the Godot port "mirrors this design," but no Godot code is included. I cannot verify parity.
8. evMult resolution. The evasion multiplier appears on torpedoes and the star trait, but the evasion formula is not in the pack.

5. QUESTIONS FOR THE DESIGNER
Q1. flak and gsentry share every stat. Was gsentry intended to diverge (e.g., a Deathless-specific PD behavior via the gauss/null kind), or is it a rename that was never mechanically differentiated? Stakes: if it is a rename, one weapon entry should be deleted and the Deathless should use flak with a faction rename, removing a false choice from the draft.
Q2. turbo and gauss both produce 13.32 expected damage at identical range and accuracy. Was gauss's envelope derived from turbo's, or did they converge by accident? Stakes: if convergence was accidental, one weapon's numbers need to shift to make the pierce-vs-volume tradeoff legible without a spreadsheet; if intentional, the UI must surface pierce's impact on actual damage output, or players will see two identical guns.
Q3. The turret is the only all-arc weapon, and the Rear arc exists in ARC_NAME but is unused. Is the facing economy meant to be a single binary (turret vs. fixed), or is there a plan to offer turret variants of other weapon kinds (turret-lance, turret-gauss) and to resolve the dead Rear arc? Stakes: a single all-arc weapon makes facing a toggle, not a decision; a dead arc enum invites future bugs and misreading of the design intent.
