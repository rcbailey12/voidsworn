# Weapons audit - Rey leg (Oct 29 program)

Blind leg: written from the evidence pack and direct code reads at pin 264f441d only. Expected-damage figures below are the chair's own arithmetic from the pack's table (shots x dmg x acc/100, before falloff, crit and pierce), marked INFERRED where used.

## 1. Proof of reading

Read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE; the code slices (data.js 1-60: the W table, ARC_NAME, KIND_NAME, FAC_WNAMES, WTRAITS, FAC_WTRAIT, nameWeapons; battle.js 531-536: torpedo travel rules comment and constants). Spot-verified against battle.js in the repo: ion application (ionVs/ionOf, battle.js:602,660), the vsSq/vsCap damage multiplier (battle.js:679), the torpedo impact resolution (battle.js:837-838), and trait application sites for ignite/shred/acid/armorPierce (battle.js:704,712-714).

Overall verdict: DUPLICATES WITH PAINT - the arsenal has a readable spine (light battery, heavy battery, lance, torpedo, point defense), but at least one pair is field-for-field identical, two more pairs share an expected-damage line to the decimal, and several faction renames carry no trait at all.

## 2. Findings

1. [BLOCKER] flak and gsentry are the same weapon. READ: both are {k:'flak', shots:3, dmg:3, r:2, opt:2, acc:80, fall:10, vsSq:3, vsCap:.6}, identical in every field including kind. The only differences in the game are the name, the faction (gsentry is the Deathless sentry gun, 1 mount against flak's 11), and the Deathless rename of flak itself to "Null shredder," which means the Deathless faction carries the same point-defense gun under two of its own names. No trait touches either (FAC_WTRAIT has no flak entry for any faction). This is the duplication the audit was commissioned to find, at full strength.

2. [BLOCKER] turbo and gauss land on the identical expected-damage line, and gauss weakly dominates. INFERRED from READ numbers: turbo is 2x9 at acc 74 (expected 13.32); gauss is 3x6 at acc 74 (expected 13.32). Same range 5, same opt 3, same fall 8, same crit 5. The sole mechanical delta is gauss's pierce:.6, which is strictly additive value; nothing on turbo's row compensates. Faction separation (turbo is Hegemony, gauss is Deathless) and their traits (plasma vs the gauss armorPierce trait) rescue the pair in play, but in the table itself the difference is one field, closer to a rounding decision than a design decision.

3. [FIX] The torpedo design comment contradicts the live constants it documents. READ: the comment at battle.js:531-535 says the impact penalty is "10 harder 1 hex off, 25 harder 2 hexes off" and "Range 6 and the cooldown stay," but line 536 sets TORP_RING=[0,5,15] and TORP_STRAY=10, and startorp's range in the table is 5, not 6. Anyone porting or tuning from the comment implements the wrong weapon. The constants are the truth (they are what impact resolution at battle.js:837 reads); the comment is stale drift and should be rewritten to match.

4. [FIX] autocannon and laser are the same light-battery job at rounding distance. INFERRED from READ numbers: autocannon 3x5 at acc 80 (expected 12.0, r4, opt2); laser 2x7 at acc 80 (expected 11.2, r4, opt3). Same kind, same accuracy, same falloff and crit; laser trades a little expected damage for a one-hex better optimal band. Laser also has exactly 1 mount in the whole roster (census). If laser vanished, no fleet decision would change; its row exists to give the Hegemony a base gun for the plasma trait, which is a trait-delivery reason, not a weapon reason.

5. [FIX] spores is a marginal reskin of flak with slightly better numbers. READ: spores {k:'flak', 3 shots, dmg:4, r:2, acc:78, fall:8, vsSq:3, vsCap:.6} against flak {dmg:3, acc:80, fall:10}. Expected damage against squadrons and capitals is a touch higher for spores on both axes. It is not a clone as exact as gsentry, but it is the same job with the dial turned one notch, and the Chorus has no flak trait to differentiate it further (its trait list covers bioplasma, tendril, sporeb only).

6. [NOTE] The ion system is one weapon deep. READ: ion:2.5 exists on exactly one row (ion, 1x12, expected 9.6 hull damage, 24 effective against shields before other modifiers), and the code read adds one doctrine rider (a Hegemony ion hit locks the struck shield facing's regen for a turn, battle.js:700). The job (dedicated shield-stripper) is real and no other weapon does it, since lances bypass shields with pierce rather than stripping them. But a "system" with a single carrier and a faction-locked rider is fragile: one hull losing its ion mount removes the mechanic from a fleet entirely.

7. [NOTE] The turret row is the weakest battery-class gun despite being the facing system's namesake. INFERRED: turret is 2x8 at acc 74 (expected 11.84), below autocannon (12.0) and far below battery (17.28). Because arcs live on mounts rather than on the weapon row, the turret's low output is the price of the all-arc mount, which is correct design direction, but the gap means the turret gun is a coverage purchase, never a damage purchase. Worth one tuning look, not a redesign.

8. [NOTE] Several faction renames are pure paint because no trait follows them. READ: FAC_WTRAIT assigns traits to a subset of each faction's renamed guns only. Hegemony renames flak to "Picket lasers" and Deathless renames it to "Null shredder," with no flak trait in either faction; Ithar renames pulsar to "Prism lance" while its needle trait covers shard and turret, not pulsar. Where a trait exists the renames earn their keep (see check 4); where none exists the rename is flavor text over an unchanged decision.

9. [NOTE] Hegemony's rename of turbo to "Plasma lance" collides with the lance kind. READ: turbo is k:'battery', but FAC_WNAMES.hegemony renames it 'Plasma lance', while lance and pulsar are actual k:'lance' weapons and pulsar's Ithar name is also 'Prism lance' against Hegemony laser 'Plasma cannon'. A player reading names cannot tell kind from label in the Hegemony list. Cosmetic, but it taxes exactly the role readability this audit is judging.

10. [NOTE] shard is the quiet success of the table. READ: shard {k:'battery', 3x6, r:4, acc:80, crit:6, vsSq:1.6} is the only battery-kind gun with an anti-squadron multiplier, giving it a dual-role job (line gun that can swat wings) no other row states. Its Ithar needle trait (acc+6, crit+8) sharpens the same identity. One line because it needs no fix; it is the standard the borderline rows should be held to.

## 3. Explicit checks

### 1. ROLE CLARITY (one line per non-squadron weapon, from numbers alone)

- autocannon: cheap light battery, short optimal band, filler firepower. (expected 12.0)
- flak: point defense; murders squadrons (vsSq 3), tickles capitals (vsCap .6).
- battery: the standard mid battery, the roster's baseline gun. (17.28)
- hbattery: battery but more; the heavy line gun. (25.2) Same job as battery, bigger - flagged as a tier, not a distinct role, which is legitimate for a heavy variant.
- lance: long-range (r7) single heavy shot that pierces shields (.6). (16.4)
- torp: delayed 42-damage strike on a marked hex, cooldown 2, dodgeable. The positional weapon.
- turret: all-arc coverage gun; output is the tax for the mount. (11.84)
- laser: light battery. SAME one-liner as autocannon - flagged.
- turbo: mid battery, two heavy shots. (13.32)
- hturbo: turbo stretched to r6 with a third shot; the long mid battery. (19.44)
- ion: shield-stripper; low hull damage, 2.5x against shields.
- scatter: point-blank (r3) five-shot shredder. (19.5 at knife range)
- htorp: torp doubled; two 34-damage delayed strikes, cooldown 2.
- tendril: melee-range (r1) bio gun, heavy per-hit with pierce .5; the boarding-range weapon.
- bioplasma: the bio line gun; mid battery output with light pierce .2. Its one-liner nearly matches turbo's ("mid gun with a pierce rider"); the bio kind and Chorus traits carry the difference.
- spores: point defense. SAME one-liner as flak - flagged.
- pulsar: lance split in two; two piercing shots at r6. (19.2) Distinct from lance by shot count and range band.
- startorp: torp, slightly lighter (38), shorter (r5), better pierce (.4) and accuracy. A variant of the torp job, not a new one - acceptable as the Ithar expression of the same system, and its star trait changes its tracking (code read: its impact ring is [0,0,10] against TORP_RING's [0,5,15]).
- gauss: mid gun whose shots pierce shields (.6). Expected-damage line identical to turbo's - flagged in finding 2.
- gsentry: point defense. SAME one-liner as flak, and same numbers - flagged as finding 1.
- doom: the siege gun; one 40-damage piercing shot, cooldown 2 (about 15.6 expected per turn). Distinct.
- shard: dual-role battery; line gun with real anti-squadron teeth (vsSq 1.6). Distinct.

Weapons whose job cannot be stated distinctly: laser (autocannon's line), gsentry (flak's line, verbatim), spores (flak's line with a nudge).

### 2. DUPLICATION (three closest pairs)

1. flak / gsentry: identical in every field and kind. Difference: none. Not a rounding error; a copy. Verdict: paint.
2. turbo / gauss: identical expected damage (13.32), identical range/opt/fall/crit; gauss adds pierce:.6 and fires 3x6 instead of 2x9. Difference: one field. In the table it is a rounding-level distinction; the faction traits (plasma's pierce .25 and +1 dmg vs the gauss trait's armor halving) are what turn it into a decision, which means the table is borrowing its differentiation from the trait layer.
3. autocannon / laser: expected 12.0 vs 11.2, same kind/acc/fall/crit, laser's opt one hex longer. Difference: a rounding error with a range-band fig leaf.

(Honorable mention: spores / flak, one damage point and two accuracy points apart, same job.)

### 3. FACING ECONOMY

INFERRED from the table and the mount census. Fixed guns pay clearly for their constraint: battery (17.28) out-damages turret (11.84) by about 46%, and hbattery (25.2) more than doubles it, so bringing arcs to bear is rewarded in raw output. The tradeoff is real. Weapons I would only ever mount on a turret: the point-defense family (flak, gsentry, spores), because range 2 anti-squadron coverage is worthless if the wing crosses on the wrong facing; their damage against capitals is negligible either way, so the all-arc mount is their whole value. Weapons I would never put on a turret: lance and doom, whose long range and single heavy shots want a prow line and lose nothing by being fixed, and torpedoes, whose aim hex is chosen at launch regardless of arc. No weapon's facing is its whole identity except the PD family, and that is a mount identity, not a row identity.

### 4. FACTION TRAITS (two weapons across factions)

autocannon, in two factions. Voidsworn (las trait): falloff halved (8 to 4) and acc +4, so the same light gun holds its damage at range and becomes a skirmish-line weapon. Corsair (scrap trait): shots 3 to 4, acc 80 to 68, crit 5 to 8, so it becomes a wild volume crit gun you fire at close range and accept the misses. Same row, two different decisions about where the ship wants to stand. The trait changes the decision, not the name.

turret, in three factions. Voidsworn las makes it a steadier long-band coverage gun; Corsair scrap makes it a four-shot lottery (3 shots +1, acc down, crit up); Ithar needle (acc +6, crit +8) makes it a precision coverage gun. Three behaviors from one row. Again: decision, not paint.

Counterweight (READ): the system only differentiates where FAC_WTRAIT has an entry. Torp shows the strongest version: Voidsworn hellfire adds burning, while Corsair rockets rewrites the weapon wholesale (shots x3, damage /2.9, evMult 1.5, and rockets can be shot down by point defense), which is a different weapon wearing the torp's name. But flak in Hegemony and Deathless hands, and pulsar in Ithar hands, are renames with no trait, so the answer is split by row, not by faction: traits are real where they exist, and roughly half the renamed rows have none.

### 5. SPECIAL SYSTEMS

Torpedoes: earn their complexity. They are the only delayed, positional weapon: launch now, strike next turn on a marked hex, with a dodge gradient (the target can move off the aim hex at rising penalties), a stray-hit rule, point-defense interplay through the Corsair rockets variant, a cooldown, and a 1.2x warhead compensating for the dodge (code comment, READ). Delete them and the game loses its only weapon that makes enemy movement a defensive action, plus two hulls' heavy variants (htorp) and the Ithar star variant. The system is justified; its documentation is not (finding 3).

Ion: earns its complexity, narrowly. One weapon carries it, but the job (strip shields at 2.5x so hull guns can work, plus the Hegemony regen-lock rider in code) is a real sequencing decision: ion first, then everything else. Delete it and shield play collapses to pierce-only, and Hegemony loses a doctrine piece. The risk is depth, not existence: a second ion carrier or a smaller ion rider on another row would make the system robust.

Point defense (flak and gsentry): the system earns its complexity; the second gun does not. The vsSq 3 / vsCap .6 split creates a clean anti-squadron job that interacts with wings, torpedo rockets, and shard's dual role. Delete flak and squadrons lose their hard counter. Delete gsentry and nothing mechanical changes at all, because it is flak (finding 1). Keep the system, merge or differentiate the duplicate.

Doom (from WHAT TO JUDGE 5): earns its mount. One 40-damage piercing shot on a cooldown is a distinct siege rhythm against the lance's every-turn 20, and the Deathless gauss trait (armor halving) compounds its identity. Deleting it leaves Deathless with gauss alone and no heavy answer.

## 4. Not checked

- Hull mount layouts: which arcs each weapon actually sits on per hull (the pack gives mount counts per weapon, not per-arc placement), so the facing judgment is from the table and census, not from fitted ships.
- Cost: weapons carry no price or CP in the pack, so value-for-cost cannot be judged; a duplicate that is cheaper would read differently.
- Falloff in play: expected-damage figures ignore the falloff curve beyond optimal range and all crit math.
- Squadron weapons (guns, bombs, sporeb) beyond noting bombs and sporeb are near-identical rows (2 shots, pierce .6, dmg 9 vs 10, vsSq .2 vs .3, crit 10 vs 8); the prompt scopes role clarity to the 22 non-squadron weapons.
- The Godot port's weapon data (the pack states it mirrors this design; not independently read).

## 5. Questions for the designer

1. Should gsentry be differentiated (a real stat or behavior delta, for example a wider vsSq band or an interception rider) or merged back into flak with the Deathless flavor carried by the rename alone? Stakes: as shipped, one of the table's 25 rows is a copy, and the Deathless list shows the same gun twice under two names.
2. Is the turbo/gauss expected-damage identity intentional, with faction traits trusted to separate them, or should one row move (range, shot count, or a crit gap) so the table differentiates before traits apply? Stakes: any context that strips traits (sim exports, the port's data checks) sees two factions' signature guns as the same weapon.
3. Should the ion mechanic gain a second carrier so the shield-stripping system survives losing one mount? Stakes: today the entire sequencing layer of shield play hangs on a single weapon row mounted on a handful of hulls.
