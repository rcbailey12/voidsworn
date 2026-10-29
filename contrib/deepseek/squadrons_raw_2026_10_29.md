Chair note: filed verbatim from the DeepSeek run of Oct 29, 2026 (DeepThink and Search on, toggles verified), except em dashes and en dashes in the model's text are normalized to hyphens.

1. Proof of reading

Sections read:

- EVIDENCE PACK title line
- THE COMMISSIONER'S QUESTION
- CHAIR CENSUS
- WHAT TO JUDGE
- Code slices:
  - data.js squadron hulls and every launch/hangar hull line
  - data.js 132-152: ABILITIES
  - data.js 506-520: WING_STANCES, WING_PERKS, WING_XP
  - battle.js 612-616: wing constants and stance changes
  - battle.js 149-165: enemy generator carrier handling
  - faction roster lines embedded in the data.js hull slice

Overall verdict: MOSTLY DISTINCT - fighter and bomber are visibly different, but spore is a bomber-class reskin, and hangar pricing/counterplay are not proven by the pack.

2. Findings

1. [BLOCKER] Spore is a bomber reskin, not a third wing job.
Claims: READ - spore has sq:'bomber', speed sp:5, evasion ev:25, HP 26; bomber has sq:'bomber', sp:5, ev:25, HP 28. The only visible difference is sporeb vs bombs and faction. INFERRED - spore inherits bomber targeting ("ships first for bombers") and the same perk/stance behavior class, so it does not create a third decision space.

2. [FIX] The hangar economy is not demonstrably fair, and some hangar values look badly priced.
Claims: READ - launch hulls keep guns and put launch in the ability slot; e.g. h_vanguard has 1 hangar, 3 weapons, cp4; h_dominion has 1 hangar, 4 weapons, cp6; b_brood has 3 hangars, cp5, regen:8. INFERRED - hangars are bundled into hulls rather than visibly traded against a gun, and without squadron weapon stats or sibling hull data the trade cannot be priced. Best apparent carrier value: b_brood (3 hangars at cp5 plus regen). Worst apparent non-boss carrier value: h_dominion (1 hangar at cp6), though its gun battery explains part of that cp.

3. [FIX] The carrier archetype is one carrier substitution, not a distinct carrier fight.
Claims: READ - generator does arch==='carrier'&&kind!=='boss', pushes the highest-cp carrier, then does roster=roster.filter(x=>!x.car) and fills the same budget with non-carriers. INFERRED - there is no escort shaping, screen assignment, or carrier-specific formation logic. The fight differs mainly because one hull is a carrier and budget is subtracted; otherwise it is a gun line with wings attached.

4. [FIX] Point defense is not proven as a real answer to wings.
Claims: READ - census says 11 flak mounts and 1 gsentry mount across the roster; launch hulls total 16 hangar slots and can hold spare wings. INFERRED - 12 point-defense mounts across the whole roster is thin relative to 16 initial wing slots and up to 32 launches if every spare is used, and the pack gives no flak/gsentry damage, rate, radius, or uptime. Mount count alone does not establish counterplay.

5. [FIX] Veterancy is not shown to be planable; several perks are conditional or low-impact.
Claims: READ - thresholds are WING_XP=[3,8,15]; reserve gives "one more spare wing"; pickets only helps screening wings shoot torpedoes more often. INFERRED - the pack does not say whether wing XP/perks persist across replacement wings, so the ladder may reward disposable wings or may be lost on death. pickets is dead in non-torpedo matchups or when not screening; reserve only matters after a wing loss.

6. [NOTE] The torpedo-screen interaction does make carriers defensive assets, but .45 needs cadence/stacking context.
Claims: READ - WING_SCREEN_R=2, WING_SCREEN_TORP=.45; screen stance shoots down torpedoes aimed at ships beside the wing. INFERRED - this is the right kind of number: probabilistic interception, not immunity, with a real positioning cost because screen keeps wings within 2 hexes. But .45 per what, with what stacking and cadence, is not in the pack, so strength is unjudgeable.

7. [NOTE] The preview anti-wing advice bug is a real audit smell.
Claims: READ - census says the preview layer "sometimes advises anti-wing play against factions with no wings." INFERRED - this does not decide squadron balance, but it means the UI/advice layer is not a reliable guide to counterplay and should be fixed before using player-facing advice as evidence.

8. [NOTE] The no-carrier faction is intentional, not an omission.
Claims: READ - Deathless/Eclipse has sq:null and the designer ruled on Oct 29, 2026 that it stays without a carrier. INFERRED - do not score faction asymmetry itself as a failure; judge whether the carrier factions' layer earns its complexity.

3. Explicit checks

1. WING JOBS

- Fighter: fast, evasive gun wing (sp:6, ev:35, guns) that hits the best target; only becomes an explicit craft-hunter through screen stance.
- Bomber: slower, tougher bomb wing (sp:5, ev:25, HP 28, bombs) that targets ships first.
- Spore: slower, tougher bomber-class wing (sp:5, ev:25, HP 26, sq:'bomber', sporeb); functionally a Chorus bomber skin.
- Flag: bomber and spore one-liners come out the same - same squadron class, same speed/evasion, nearly same HP, and no separate targeting rule in the pack.

2. HANGAR ECONOMY

Launch hull | Hangars / cp | Visible weapons | What hangar appears to cost | Judgment
reliquary | 2 / cp4, cost260 | turret, flak | ability slot only; no visible gun removed | Cannot price without sibling data
h_vanguard | 1 / cp4 | turbo×2, ion | ability slot; retains 3 guns | One hangar looks cheap at cp4, but no sibling baseline
h_dominion | 1 / cp6 | hturbo P/S, ion, flak | ability slot; retains 4 guns | One hangar at high cp looks like weak carrier value
c_hulk | 2 / cp4 | turret×2 | ability slot; no visible gun removed | Apparent solid carrier value, but no sibling data
c_boss | 2 / cp10 boss | scatter×2, htorp, flak | ability slot | Boss; not comparable to line carriers
b_brood | 3 / cp5, regen8 | bioplasma, spores | ability slot; retains 2 guns | Best apparent carrier value
b_boss | 3 / cp12 boss, regen20 | bioplasma×2, tendril, spores | ability slot | Boss; not comparable
i_carrier | 2 / cp5 | pulsar, turret | ability slot; retains 2 guns | Cannot price without sibling data

Claims: READ - the table's cp, hangar, weapon, and regen lines. INFERRED - "cost" is mostly the ability slot, because no launch hull visibly loses a gun to buy hangars. Fairness cannot be established from the pack. Best apparent: b_brood; worst apparent non-boss: h_dominion.

3. STANCES AND VETERANCY

Stances create real decisions: strike is baseline, screen trades reach for carrier proximity, craft priority, and torpedo interception, and hunt trades exposure (10 easier to hit) for +4 range and +20% damage against crippled ships. Those are planable tradeoffs.

Veterancy is less proven. Thresholds at 3/8/15 kills are concrete, but the pack does not say whether perks persist across replacement wings. pickets is the most nearly dead perk: it only matters when screening and when enemy torpedoes exist. reserve is second: it only matters after a wing loss. No stance is dead weight; strike is the necessary baseline.

4. COUNTERPLAY

Point defense is not proven as a real answer. The roster has 11 flak mounts and 1 gsentry mount, but the pack gives no flak/gsentry damage, rate, radius, or coverage. Against 16 hangar slots - and up to 32 launches if every spare is used - the mount count looks thin, but that is INFERRED because per-battle mount counts and weapon stats are missing.

The torpedo-screen interaction does make carriers defensive assets: screen wings stay within 2 hexes and intercept at WING_SCREEN_TORP=.45, and pickets improves that. .45 is the right kind of number - probabilistic, not a hard counter - but without cadence, stacking, and torpedo volume it cannot be judged as balanced.

5. THE CARRIER FIGHT

From the generator slice, a carrier-archetype fleet is a gun line with one carrier substituted in, not a distinct carrier fight. The generator picks one carrier, removes all carriers from the fill roster, and spends the remaining budget on the same weighted non-carrier options. There is no escort composition, screen assignment, or formation logic. The fight may feel different because the carrier consumes budget and adds wings, but the code does not build a carrier-specific battle.

4. Not checked

The pack does not let me judge:

- actual weapon stats for guns, bombs, sporeb, flak, gsentry, torpedoes, or other weapons;
- squadron cost, sortie cost, replacement timing beyond "adjacent hex" and cooldown 1;
- whether wing XP/perks persist across replacement wings;
- exact spare-wing cap/stacking with reserve;
- AI target selection beyond the stance descriptions;
- per-battle point-defense coverage and torpedo volume;
- faction sibling hulls for most carriers;
- terrain/map effects on wing movement and screening;
- actual player experience or whether the carrier layer "feels" complex.

5. Questions for the designer

1. What are the full weapon profiles for guns, bombs, sporeb, flak, and gsentry? Stakes: without damage/rate/radius, neither hangar-vs-gun value nor point-defense counterplay can be priced.
2. Does wing XP and veterancy persist across replacement wings, and does reserve stack with the launch ability's spare per hangar slot? Stakes: this decides whether the perk ladder is a planable investment or disposable decoration.
3. Is the carrier archetype intended to produce a distinct fight with escorts/screens, or is "one carrier plus normal fill" the design? Stakes: if the latter, the generator does not need carrier-specific logic; if the former, the current slice does not implement it.
