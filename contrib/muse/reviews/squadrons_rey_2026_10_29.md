# Squadrons and carriers audit - Rey leg (Oct 29 program)

## 1. Proof of reading

Sections read: the EVIDENCE PACK title line ("squadrons and carriers audit (code slices from the shipped browser build, main 264f441d)"); THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE (items 1 to 5); and the code slices: data.js squadron hulls and every launch/hangar hull line, data.js 132-152 (ABILITIES and ORDERS), data.js 506-520 (WING_STANCES, WING_PERKS, WING_XP), battle.js 612-616 (wing constants and stance changes), and battle.js 149-165 (the enemy generator's carrier handling). I also verified and extended pack claims with direct reads in the repo clone at the same pin: the W weapon table entries for guns, bombs, sporeb, flak and gsentry; screenTorps and aiStance in battle.js; wingKind, makeWing and launch gating in battle.js; wingVetAfter and wingPerkGrant in campaign_run.js; and the sibling hull lines in data.js used for the hangar economy check.

Overall verdict: DUPLICATES WITH PAINT - the fighter/bomber core is a real split, but the third wing type is a reskin of the second and the carrier-archetype fleet is a gun line with one carrier substituted in, so two of the system's three headline layers duplicate instead of deciding.

## 2. Findings

1. [BLOCKER] The spore swarm is a bomber reskin, not a third wing job. READ: the spore hull line reads "sq:'bomber'" with sp 5, tn 9, ev 25, identical to the bomber hull, and hp 26 against the bomber's 28. READ (weapon table, code): sporeb is {shots:2, dmg:10, acc:78, pierce:.6, vsSq:.3, crit:8} against bombs at {shots:2, dmg:9, acc:78, pierce:.6, vsSq:.2, crit:10}; same kind, same range, same falloff, no different delivery mechanic. INFERRED: a Chorus player makes exactly the bomber's decisions with a different name; the faction whose whole identity is biological has the least distinct air arm.

2. [BLOCKER] The carrier archetype buys one carrier and then fills the fleet with the same generic weighted draw as every other archetype. READ: the generator slice picks "a carrier with its escort" in the census's words, but the code only forces the single most expensive affordable launch hull into the list, removes other carriers from the roster, and then runs the identical budget fill loop with no escort, screen, or formation shaping; the carrier branch is also skipped entirely for boss fights ("arch==='carrier'&&kind!=='boss'"). INFERRED: a carrier fight differs from a gun line only by the wings the one hull launches, which is a hull property, not a fleet shape.

3. [FIX] The torpedo screen's real math is narrower and stranger than its description. READ (code, battle.js screenTorps): each screening wing in radius gets exactly one roll against the first live torpedo in a salvo and then stops (the inner loop breaks after the first live shot), at WING_SCREEN_TORP .45, or .65 with the pickets perk. INFERRED: stacking compounds geometrically per torpedo (two wings give about a 70% kill chance on the first torpedo), but each wing can kill at most one torpedo per salvo no matter how large the salvo, and that cap is nowhere in the stance text, which says only that wings "shoot down torpedoes aimed at ships beside them."

4. [FIX] Wing veterancy perks are random grants, so the ladder rewards play but cannot be planned around. READ (code, campaign_run.js): wingVetAfter pools a carrier's wing kills across battles against WING_XP thresholds 3, 8, 15, and wingPerkGrant grants "pick(pool)" from the perks the carrier does not already hold; the player is never offered a choice. READ (code): the perks themselves are real when they land (aces and jinkers and armored apply at makeWing, killers adds damage against ships, pickets raises the screen roll, reserve adds a spare wing). INFERRED: a player can plan to keep a veteran carrier alive, but the build they are protecting is a lottery draw; enemy wings, which hold no campaign ship record, effectively never earn perks, so the ladder is also one-sided.

5. [FIX] Launch occupies the carrier's only ability slot while doing nothing on most turns. READ: the launch ability text says carriers "start each battle with their wings in flight" and the ability itself only "launches a replacement for a lost wing," with one spare per hangar slot (confirmed in code: spare count equals hangar, plus one with the reserve perk). INFERRED: every sibling hull at these CP values presses a real activated ability (focus, surge, overburn, ionpulse); a carrier whose wings are alive has a dead ability button, so part of the hangar's price is paid every single turn in a currency the census did not count.

6. [FIX] There is no consistent price for a hangar across the eight launch hulls. READ: b_brood carries hangar 3 at cp 5, while h_dominion carries hangar 1 at cp 6; h_vanguard keeps a full three-gun fit (two turbo, one ion) alongside its hangar 1 at cp 4, while the reliquary at the same cp 4 is reduced to a turret and a flak gun for its hangar 2, and c_hulk at cp 4 keeps only two turrets for hangar 2. INFERRED: hangar value is set hull by hull with no visible exchange rate against guns, CP, or the ability slot, so carrier shopping is guesswork.

7. [NOTE] Point defense is a real answer, and the game adapts it upward when the player leans on carriers. READ (code): ships with a flak-kind weapon receive 2 intercepts per round, non-point-defense weapons take a -15 accuracy penalty against squadrons, and flak itself carries vsSq 3. READ (code, battle.js setup): when the player fields two or more carriers, the enemy bolts extra point defense onto its ships and can launch fighter wings of its own to hunt player craft. READ: the mount base is thin, though: flak has 11 mounts across the roster and gsentry 1, and gsentry's weapon line is field-for-field identical to flak ({shots:3, dmg:3, r:2, acc:80, vsSq:3, vsCap:.6}), so the second named point-defense weapon is paint.

8. [NOTE] The fighter job exists only when the enemy brings craft. READ (code, wingKind): a player carrier from a fighter faction alternates fighter and bomber wings, but if the enemy side has no squadrons and no launch hull, every wing is generated as a bomber ("no enemy craft to fight: every wing is a strike wing"). INFERRED: this is sensible AI-side economy, but it means the fighter's anti-craft job, and any module or boon bought to support it, silently switches off in exactly the fights where the enemy has no air, with no player decision involved.

9. [NOTE] A carrier-archetype roll against a launch-less faction does not produce a carrier fight at all. READ (code, effArch in battle.js): if the rolled faction's roster has no launch hull, the carrier archetype is remapped to heavy before generation, so a Deathless carrier roll fields a heavy fleet. READ: the census notes the preview layer sometimes advises anti-wing play against factions with no wings. INFERRED: between the remap and the preview advice, the word "carrier" can appear in the player's information while no carrier exists on either side of the fight.

10. [NOTE] The screen stance's tether is shorter than the carriers it protects want to fly. READ: WING_SCREEN_R is 2 and the screening wing's leash is that radius plus 1 around the guarded ship, while most carriers are speed 2 backline hulls whose wings must stay within 2 hexes of the torpedo's target, not of themselves, to intercept (screenTorps measures distance from the wing to the target ship). INFERRED: screening a fleet, rather than the carrier itself, requires parking wings beside the ships most likely to be torpedoed, which the stance name and text do not teach.

## 3. Explicit checks

### 1. WING JOBS

- Fighter: a fast, fragile anti-craft interceptor (sp 6, ev 35, hp 18) whose guns multiply damage against squadrons (vsSq 2.2) and halve it against ships (vsCap .5). READ.
- Bomber: a slower, tougher anti-ship striker (sp 5, ev 25, hp 28) whose bombs pierce .6 against ships and are nearly useless against craft (vsSq .2). READ.
- Spore: a slower, tougher anti-ship striker (sp 5, ev 25, hp 26) whose burst pierces .6 against ships and is nearly useless against craft (vsSq .3). READ.
- FLAG: the bomber and spore one-liners come out the same, because they are the same job; the spore hull is literally typed sq:'bomber' and its weapon differs from bombs by 1 damage, .1 vsSq, and 2 crit. Only the fighter's line is distinct.

### 2. HANGAR ECONOMY

Per launch hull, what the hangar costs and whether the trade is fair (siblings from the same faction roster, READ from data.js):

- reliquary (cp 4, hangar 2, voidsworn): pays almost its entire gun fit (turret plus flak only, where the cp 3 penitent carries battery, battery, lance plus focus) and its ability slot. The trade is the steepest in the game, softened only by monopoly: it is the faction's only carrier. Unfair as priced, tolerable as the sole option.
- h_vanguard (cp 4, hangar 1, hegemony): keeps two turbos and an ion gun, hp 140, sh 24; pays mainly the ability slot against its roster siblings. The hangar is close to free on a working cruiser. Fair, even generous.
- h_dominion (cp 6, hangar 1, hegemony): keeps a full four-gun dreadnought fit including flak; pays almost nothing, and gets almost nothing: one hangar on the most expensive non-boss hull in its roster. As a gunship with a bonus wing it is fine; as a carrier it is the worst hangar value in the game at 1 hangar per 6 CP.
- c_hulk (cp 4, hangar 2, corsair): pays its guns down to two turrets and its ability (the cp 3 c_marauder carries four weapons plus overburn), compensated with the roster's carrier-class hull at hp 170. A real sacrifice for a real return. Roughly fair.
- c_boss (cp 10, hangar 2, corsair boss): a boss hull; the hangars ride on a 600 hp barge with four guns. Not a purchasable trade; excluded from the value ranking.
- b_brood (cp 5, hangar 3, chorus): keeps a bioplasma gun and a spores point-defense mount, hp 200 and regen 8; its hangars are its identity rather than a tax on a gun line (the cp 3 b_razor carries two guns, frenzy, regen 7). Best carrier value in the game: 3 hangars at cp 5, the highest hangar-per-CP of any non-boss hull, with self-repair on top.
- b_boss (cp 12, hangar 3, chorus boss): a boss hull; excluded from the value ranking for the same reason as c_boss.
- i_carrier (cp 5, hangar 2, ithar): pays one gun and the ability slot against the cp 4 i_song (three guns plus surge), but keeps the faction's speed identity (sp 4, ev 12, the fastest carrier). A clean, legible trade. Fair.
- Best carrier value: b_brood. Worst carrier value: h_dominion (the reliquary pays more, but it delivers a dedicated two-hangar carrier; the dominion delivers one hangar as decoration on a dreadnought).

### 3. STANCES AND VETERANCY

Stances create real decisions. READ: one free stance change per carrier per round (canStance tracks stanceRound), and the three stances change targeting and leashes in code, not just text: strike is the default best-target behavior, screen tethers wings to a guarded ship and doubles their value against enemy craft while enabling torpedo interception, hunt extends the leash by WING_HUNT_LEASH 4, multiplies damage against ships below half hull (confirmed in code at +20% for a hunting wing, with the killers perk stacking), and makes the wing easier to hit. A player facing torpedo hulls screens, a player closing out a crippled flagship hunts, and the once-per-round change makes the call a commitment. The enemy runs the same logic reactively (aiStance: screen against torpedoes or superior craft, hunt a crippled ship, else strike).

Veterancy is weaker as a decision system. The thresholds (3, 8, 15 pooled wing kills per carrier) are reachable in a long run and the perks are individually meaningful, but the grant is random, so the ladder is something a player feeds, not something they steer; what they plan around is keeping the carrier alive, not which perk arrives.

Dead weight: the pickets perk. It pays out only while the carrier is in screen stance, only against torpedo salvos, and only if the random grant happened to deal it; every other perk works in the default stance or passively. No stance is dead weight, though screen is the most conditional of the three.

### 4. COUNTERPLAY

Point defense is a real answer at the pack's mount counts, with one caveat. READ: 12 point-defense mounts exist (11 flak, 1 gsentry), flak carries vsSq 3 with 3 shots, flak-armed ships gain 2 intercepts per round, and ordinary guns are accuracy-penalized against squadrons, which makes dedicated point defense meaningfully better than improvised fire rather than a label. The caveat is distribution: those mounts live on specific hulls, and a fleet built without them has no retrofit answer inside this pack's evidence; and the adaptation code raises enemy point defense specifically when the player brings two or more carriers, so the counter scales against the strategy it counters.

The torpedo screen does make carriers defensive assets: a screening wing parked within 2 hexes of a threatened ship rolls against incoming torpedoes at impact, after point defense. On the number itself: 0.45 is the right kind of number, a flat per-wing probability that a player can hold in their head and that stacks geometrically across wings (about 70% for two wings on one torpedo, about 83% for three, INFERRED arithmetic from the code's independent rolls). What is wrong is not .45 but the hidden structure around it: one attempt per wing per salvo, a 2-hex tether measured to the target rather than the carrier, and a pickets upgrade to .65 that the player cannot choose to earn. A legible .45 with invisible caps teaches worse than a slightly lower number with visible rules.

### 5. THE CARRIER FIGHT

From the generator slice, a carrier-archetype fleet is a gun line with wings attached. READ: the archetype forces exactly one launch hull (the most expensive the budget affords), bans further carriers, and fills the rest of the budget through the same weighted random draw, with the same weights, as the swarm and heavy archetypes after their own first-pick shaping. Nothing in the slice buys an escort for the carrier, holds a screen back, or reserves budget for a second wave; the fight's difference is entirely downstream of the launch ability on one hull, its starting wings, and its spare count. The archetype is also disabled for boss fights, so the game's biggest set pieces never use it. INFERRED: if the designer wants carrier fights to feel different, the difference has to be bought at generation time (an escort shape, a second smaller carrier for swarm factions, a point-defense tax on the opposing fill), because the hull alone does not create it.

## 4. Not checked

- Live play feel: wing pathing, animation time, and whether wing turns slow a 20-ship battle down; the pack is code and data only.
- The Godot port's squadron implementation and parity against these constants.
- Wing behavior under player-issued wing orders (strike and guard orders exist in code) beyond what the stance system shows.
- Boon and module interactions in full: the hive effect lets some non-launch hulls hold stance, and brood and feast effects grant extra wings; I read their trigger lines but did not audit the whole boon pool's wing economy.
- Whether the preview layer's anti-wing advice against wingless factions (noted in the census) also fires for the effArch carrier-to-heavy remap specifically.
- Simulation or win-rate evidence for carrier versus gun-line fleets; no sim output was in the pack.
- Squadron rendering and readability at full board density.

## 5. Questions for the designer

1. Should the spore swarm get a genuinely different delivery (for example a lingering damage cloud or an area burst) or is Chorus difference meant to live in the brood-sac's hangar count and regen instead? Stakes: an entire faction's air arm currently duplicates the bomber's decisions, and every future Chorus wing decision inherits that duplication.
2. Should the carrier archetype buy a fleet shape (a forced escort, a screen, or a second small carrier for swarm factions) instead of one hull plus generic fill? Stakes: as generated today, the archetype the player is warned about and plans against does not exist as a shape, so scouting and counter-building aim at a label.
3. Should wing perk grants at the 3, 8, and 15 kill thresholds be a choice between two perks instead of a random draw? Stakes: that single change decides whether the veterancy ladder is a build a player plans a run around or a lottery that happens to them.
