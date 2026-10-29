# Roster synthesis: hull roster identity (Oct 28, 2026)

Chair synthesis of the Oct 28 battle-layer program, roster item. Legs: DeepSeek, Argon, Qwen, all DUPLICATES WITH PAINT. Evidence pinned to main 264f441d. Chair verifications were run against data.js in voidsworn-fresh and are marked as such. Filed legs: contrib/deepseek/reviews/roster_2026_10_28.md, contrib/gemini/reviews/roster_argon_high_2026_10_28.md, contrib/qwen/reviews/roster_2026_10_28.md.

## Verdict

**DUPLICATES WITH PAINT, 3 of 3, and the chair concurs.** The roster's faction flavor lives in defensive profiles and drives; its ship-to-ship decisions too often do not. The item produced the program's most concrete defects: variants that silently delete weapons, a flagship that cannot trigger its own faction drive, and a boss that repeats its cruiser's guns at three times the command points. Underneath sits a chair-owned census error that all three legs caught and the synthesis corrects first, because every count downstream depends on it.

## The census, corrected (chair-owned)

The pack claimed five base hulls per faction plus a boss. The code says otherwise, verified by direct count of data.js at 264f441d: HULLS holds 33 entries before the variant merge (30 ship hulls plus 3 squadrons). Base ladders are Voidsworn 5, Hegemony 4, Corsair 4, Chorus 4, Ithar 4, Deathless 3, plus one boss-slot hull per faction. HULL_VARIANTS adds 12 renown and 6 arc variants, and the merge at data.js:578 brings the total to 48 ship hulls. The standing "45 hulls" figure from the Oct 23 census does not reconcile with this build and should be retired; Qwen's leg arithmetic (33 plus 18 equals 51 entries) is correct. Whether the uneven ladders are deliberate asymmetry is a designer question below; the error was the pack's claim, not necessarily the ladders.

## Findings (ranked)

1. **The ascendant cannot trigger Broadside doctrine (Argon, chair-verified, BLOCKER).** data.js:68: the player's flagship dreadnought (cp 8) carries hbattery P and S, speed 1, ability nova. data.js:106: Broadside doctrine pays +40 percent to port and starboard guns after moving 2 or more hexes. A speed 1 ship cannot move 2 hexes under its own power, so the flagship built around broadsides can never earn the broadside bonus. One situational exception exists (the gravity well's +1 movement assist within 6 hexes), which is board luck, not a design answer. Only penitent and cathedral among Voidsworn hulls can use the faction's defining mechanic at all.

2. **Two renown variants silently delete a primary weapon (Argon, chair-verified).** d_harvester_t (cost 30, the most expensive variant in the table) describes only moving the doom cannon to a turret; its mount list drops one of the base hull's two gauss turrets. i_song_w (cost 25) drops one of i_song's two pulsars the same way. Neither description discloses the loss, so the buyer cannot see the trade. Qwen noticed the d_harvester_t gauss loss but graded it a legible trade; the synthesis sides with Argon: a trade the description hides is not legible, whatever the math. These read as data-entry defects, not design.

3. **The gunship variants end with no active ability (Argon, chair-verified).** h_vanguard_g and c_hulk_g set mod ab:null with hangar:0, and the hydration loop deletes the ability when null. Both descriptions disclose losing the hangar; neither discloses that the ship ends up ability-less, the only ships in the roster in that state. c_hulk_g is the severe case (DeepSeek and Argon agree): it gives up hangar 2 and launch for +20 HP and short-range scatter broadsides on a speed 2, turn 1 hull.

4. **d_boss repeats its cruiser's guns at 3x CP and loses the faction trait (Argon and DeepSeek, chair-verified).** d_harvester (cp 4): gauss T twice, doom F, gsentry T, reanimate. d_boss (cp 12): gauss T twice, doom F, flak T, no reanimate, half the speed. Three d_harvesters for the same 12 CP triple the firepower, the regen, and the reanimations. The Deathless boss is also the only Deathless hull without reanimate (fights synthesis, finding 9), so the faction's apex ship is the one ship that does not do the faction's thing.

5. **Strict-upgrade variants are renown taxes (all three legs; three chair-verified).** d_scythe_s adds a gsentry turret with no trade (all three legs' worst offender). h_picket_i upgrades the laser to a turret and raises evasion 18 to 24 with no downside (chair-verified at data.js:553). c_reaver_t rotates scatter S to T with no downside. Under the redesign, variants are also a 250-renown sink; a variant that strictly obsoletes its base hull is not a sink, it is a toll. The genuine sidegrades exist and are the majority (Qwen counts the arc six as clean; Argon counts 9 of 18 genuine), which makes the strict ones look like oversights rather than policy.

6. **Warden and h_picket are the same ship (all three legs, chair-verified verbatim).** Both cp 1, shields 10, range 5, armor .1, speed 5, turn 3, ability evasive, flak turret. The entire difference is autocannon F versus laser F, 5 HP, and 2 evasion. Neither frigate touches its faction's mechanic (no broadsides for the warden, no ion for the picket).

7. **Launch is concentrated and Hegemony's pair is the worst case (all three legs).** Launch sits on 8 hulls; both Hegemony line ships carry a token hangar 1 (h_vanguard cp 4, h_dominion cp 6), so Hegemony has no dedicated carrier and its battleship spends its ability slot launching one 18 HP wing. Qwen names h_dominion the worst value in the game on exactly this basis; Argon names it the most wasted ability; DeepSeek makes the same point as duplication. Three framings, one ship.

8. **Boss hulls recycle roster kits (all three legs, cross-checked in the fights synthesis).** b_boss is b_brood's carrier package scaled; c_boss is c_hulk's; i_boss is i_song scaled (Qwen: same surge ability, distinction numerical). No boss introduces a boss-exclusive weapon or ability except c_boss's htorp mount. Boss CP is also uneven in a way CP does not explain (ascendant cp 8 against h_boss cp 12, with c_boss at cp 10 carrying more HP than h_boss).

9. **Four abilities are orphans (all three legs, exact agreement).** focus, ionpulse, frenzy, and reclaim each appear on exactly one hull. Whether orphan abilities are signature moves or unfinished families is a designer question; the readability cost is real either way, since a player meets each ability exactly where it is hardest to learn it.

10. **CP does not price durability consistently (DeepSeek; chair-verified with a caveat).** i_song (cp 4, hp 90, shields 26, armor .05) against c_hulk (cp 4, hp 170, shields 16, armor .2, hangar 2): the raw durability gap at equal CP is large. Caveat the synthesis keeps: i_song carries range 10, two pulsars, and surge, so the honest claim is narrower than a mispricing charge. CP prices packages, and the packages are not commensurable on any single axis; d_scythe as best value (all three legs: cruiser-tier armor, highest 1 CP HP, regen, phase, reanimate at cp 1) and the dominated d_jackal (Argon: two d_scythes beat one d_jackal on every axis at once) are the cleaner exhibits.

11. **Carrier blurb inversion (Argon).** reliquary (Voidsworn carrier, armor .15, hp 130) against c_hulk (Corsair carrier, armor .2, hp 170): the "fast, thin shields" faction's carrier out-armors the "heavy armor" faction's carrier at the same CP. Small, but it is the kind of inversion that makes faction identity read as paint.

## Questions for the designer

1. Uneven ladders: are 5/4/4/4/4/3 base ladders deliberate asymmetry (Deathless as a swarm faction with no carrier or battleship class), or missing content? Deathless at 3 is the case that needs an explicit answer either way.
2. Variant policy: must every variant carry a real trade? If yes, d_scythe_s, h_picket_i, and c_reaver_t need downsides, and findings 2 and 3 need data fixes regardless (disclose or restore the deleted weapons; give the gunship variants a replacement ability or disclose the loss).
3. Hegemony carriers: one dedicated carrier with a real hangar instead of two token launch ships, or is the distributed hangar 1 the faction's intended shape?
4. The ascendant: does the flagship get speed 2, a movement ability, or a doctrine exception? As built, the player's most expensive ship cannot use the player's faction rule.
5. Orphan abilities: signature (one hull, by design) or families (spread each to a second hull)?

## Not checked

Silhouette and visual identity at battle distance (no art in the pack; Ryan's eye at the playtest); weapon table values behind the autocannon-versus-laser question (outside the pack, so the warden/picket difference could be larger in practice than the hull rows show); Godot port parity for variant hydration.

## Designer rulings (Oct 29, 2026)

Q7 RULED (split, chair's option c, sharpened): the uneven ladders stand for the four-hull factions, and Eclipse/Deathless expands a bit, gaining a battleship-class hull so its ladder scales (frigate, destroyer, cruiser, battleship, boss). The designer's principle: factions should feel unique and different, but they should scale appropriately. Q2 cross-reference: Deathless/Eclipse gets NO carrier, ruled the same day. Q8 RULED: option (a); every variant carries a real trade, and the silent weapon deletions (finding 2) and ability deletions (finding 3) are fixed or disclosed regardless of policy. Q9 RULED: option (a); the ascendant goes to speed 2 (the designer called the movement-ability option overcomplicated). Q10 RULED: option (c); the combat verbs (focus, ionpulse, frenzy) spread to second hulls, reclaim stays the harvester's signature.
