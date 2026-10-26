# Nemesis faction behaviour review, synthesis (brief muse_2026-10-26c, Job 2)

Chair synthesis of four blind inputs, all filed on main: contrib/deepseek/nemesis_review_deepseek_raw_2026_10_26.md, contrib/qwen/nemesis_review_qwen_raw_2026_10_26.md, contrib/gemini/reviews/nemesis_review_gemini_2026_10_26.md, contrib/muse/reviews/nemesis_review_rey.md. Evidence base for every leg: the R42 port notes and the data.js Nemesis block (NEM_CLOCK, NEM_WEAK, NEM_ADAPT, NEM_TRAITS, NEM_PERSONA, NEM_FAC, NEM_ADAPT_FAC, NEM_LINES). Ryan's ruling under review (R42): the Nemesis must feel different every run and behave differently by faction: Corsair raids and flees, Deathless returns once after death, Ithar duels and withdraws, Chorus feeds on your losses, Hegemony reinforces, Voidsworn challenges. Fairness reference is R7: no ship loss without warning, no stealing control.

## Verdict

The six ruling verbs are all implemented as real mechanics, not text. That part of R42 is delivered. But two structural defects undercut the ruling's intent, and the memory system is tracked far beyond what the player ever sees or hears:

1. Deathless's defining verb is not unique to Deathless (Argon, chair-confirmed below): every faction survives a flagship kill in sectors 1 and 2, and a Deathless kill before sector 3 spends his one revive on a death he would have survived anyway.
2. Voidsworn's challenge is a damage modifier with no aim (Argon, chair-confirmed below): nothing makes his flagship hunt yours, and his persona pool cannot roll the one persona that would.
3. The one hard fairness exposure is the Corsair raid's ship cut (all four legs, wording varies): a permanent ship loss delivered by a map clock, where the win that fills the clock can be the same win that cripples the ship.
4. Memory: he remembers a great deal (what beat him, how you fight, every survival, fed, riches) and says almost none of it. One template line carries the entire spoken memory. Mordor, the Chosen and the Liches all narrate state changes; this system mostly changes numbers.

None of this needs new state. The fixes are branch rules, one targeting hook, and surfacing text the data already carries.

## Per-faction results

Corsair, raids and flees: full match, four legs agree. Raid on clock fill (25% of credits at 30+, else cuts the lowest-hull non-flagship ship under 25% hull from a fleet of 3+), flee at flagship hull 35% or lower, riches converts raids and flees into extra ships next fight. The flee-and-return loop is the most mechanically distinct behaviour in the set. The fairness exposure is the ship cut; see ranked fix 3.

Deathless, returns once after death: the revive mechanic exists exactly as ruled (one revive, scar, sector 3 met drop-back), but see defect 1. The tithe strike (every ship loses 6% max hull) and the half-speed clock are additions beyond the ruling's words; no leg objects to them as design, but the tithe's "min 1" wording is unresolved (open question 1). Slowest, most committed fights (no rout), fleet-wide strike: distinct in shape even where the revive is compromised.

Ithar, duels and withdraws: withdraws is exact and lands earlier than the Corsair's (60% hull once shields are down, whole capital force leaves, player wins). Duels is the thinnest verb of the six alongside Voidsworn's: it is a fleet shape (flagship plus three biggest, all elite) and card text, not a duel mechanic. Two text problems, both chair-confirmed against the pack: the player-facing description says shields "all down" while the port notes spec tests every flagship shield at .5 or below; and the description promises he "picks off your weakest ship", which in code only happens if he rolls the cunning or cruel persona (focusWeak), not on proud or patient. Also: the duel vocabulary collides with Voidsworn's challenge text (Rey); one of the two should be renamed in player-facing words.

Chorus, feeds on your losses: the boldest and most literal match. fed rises for every player ship lost in ANY battle (cap 8), flagship hull scales +4% per point to +32%, and adaptFast adapts him after every meeting. All four legs flag the same hole: nothing in the pack surfaces fed when it changes, so the cause (a ship lost two sectors ago) and the effect (a tougher flagship) never visibly connect. Argon adds the mirror problem: in a clean run fed stays 0 and the faction's ruling verb does nothing at all. Divergence on distinctness is recorded below.

Hegemony, reinforces: full match, four legs agree. Forced reinforcement event at round 3 of his fights, flagship as formation anchor, artillery line. The round is fixed and declared on his card, so it is plannable, not a trap. One open spec question: beh sets formation:1 innately while the notes apply the +1 sync radius under the formation special; innate, special, or both is UNSURE (open question 3).

Voidsworn, challenges: the symmetric +20% flagship damage (both ways) is real and is the fairest strike in the set, but see defect 2. Fastest clock (1.5), never routs, anchor weakness excluded. Rey reads the verb as an exact match (the mutual buff IS the challenge); DeepSeek and Qwen read it as partial (no challenge event or choice); Argon reads it as half-implemented (modifier works, AI behaviour missing). The chair adopts Argon's reading as the operative one, because it is the only one that names a code-level cause Opus can act on; the divergence is recorded below, not smoothed.

## Chair-confirmed catches (checked against the pack files by the chair)

1. Deathless revive vs global survival. port_notes_r42.txt lists nemAfterBattle's flagDead outcomes in this order: with beh.revive and not yet revived (revived, scar, sector 3 met drop); in sector 3 (dead); earlier (scar). So in sectors 1 and 2 every Nemesis returns from a flagship kill with a scar, and a Deathless killed there consumes revived in a sector where survival was guaranteed. His revive only does unique work if his flagship first dies in sector 3. Whether the code's branch order matches the notes' listing order is for Opus to confirm; the design exposure stands either way. (Argon)
2. Voidsworn targeting gap. In the data block, focusFlag:1 (the +25 weight on the player's flagship) belongs only to the greedy persona. The Voidsworn persona pool is zealous, proud, cruel, methodical: no greedy. Cruel carries focusWeak:1, so a cruel Voidsworn Nemesis hunts crippled escorts while his challenge bonus waits for a flagship trade that may never be aimed at. (Argon)
3. Ithar riches is a dead variable. nemAfterBattle grants riches +1 on a flee "for factions with a flee rule"; Ithar has a flee rule, and applyNemesis only ever spends riches for Corsair. Harmless, but it is state that accumulates and does nothing. (Argon)
4. Sector pacing lock. nemNodeIs (B4 notes) converts an unmet battle or elite node when strike is set OR the column is at cols-3 or later, once per sector. So he appears once per sector in almost every run regardless of clock speed; the .5 / 1 / 1.5 multipliers change when strikes fire, not when he shows up. Deathless's slow clock reads as patience on the card but does not delay his appearances. (Argon, Rey agrees the rhythm is faction-fixed)
5. The {beat} line can promise a counter he does not have. beat is computed from the Nemesis fight alone with heavy weights (ram x3, board x3, torp x2); adaptations are picked from run-wide seen totals and (Chorus excepted) only run at sector changes. Beat him by boarding while lances dominate your other fights and he returns saying boarding will not work twice, wearing reinforced shields and no armor. Worse, a rival met again inside the same sector may not have adapted at all since the line last played. (Argon; the one-template thinness is all four legs)
6. Epithets ignore their cause. nemScar records the cause in scarList but picks a random unused epithet from the faction pool. A flagship that fled untouched can come back "the Burned"; one blown up by boarding can come back "the Unsunk". Mordor ties the epithet to the damage that caused it; the cause data is already stored here, just unused for the pick. (Argon)
7. Weaknesses are never revealed by triggering them. RUN.nem carries revealed [] and events can grant nemIntel, but neither notes file ever adds a weakness to revealed when the player triggers it in battle (a rear-arc hit on flank, ion fire on brittle emitters, the anchor break). The discovery loop the data structure implies is not wired. (Argon)
8. Contradictory trait and weakness pairs are not filtered. newNemesis removes only anchor (for Voidsworn and Deathless). swift (+1 movement) can pair with slow (-1 movement); boarders (crew x1.3) with board (crew x0.7). The pair cancels and the rival's identity blurs. (Argon; the identity-space width itself is agreed by all legs)

## Chair catches from the data block (no leg raised these)

9. One Ithar adaptation is named "Wraithbone keel" (NEM_ADAPT_FAC.ithar, armor). It contains "keel", a banned naval word under the house fiction rules, and "Wraithbone" is a Warhammer 40k Eldar material. Both problems land in Job 1 (R44 rename) territory; flagged here because it sits inside this job's evidence.
10. Chorus Nemesis titles include "Matriarch" and "Brood-queen" while an admiral is "Matriarch of Nine Throats". The name collision guard checks admiral names for name parts only; titles are unchecked, so a Chorus Nemesis can carry the admiral's defining word.
11. Hegemony name parts include pre "Petra" and post "Lindqvist"; the story outlines' sample rival is "Petra Lindqvist". The guard does not check story sample names, so the generator can produce the sample rival verbatim.
12. Deathless pre name parts (Ankh, Sekh, Seth, Neph, Thut, Osir, Ptah) lean Egyptian and Necron-adjacent, the same proximity the story review flagged around "Dynast Setekh the Patient". Job 1 territory again.

## Convergences (three or more legs)

- All six ruling verbs exist as mechanics. Nobody found a verb that is text only in the sense of having no code behind it; the argument is about depth (Ithar duel, Voidsworn challenge) and uniqueness (Deathless revive).
- The single "again" template is the whole spoken memory, and it only covers his defeats. He has no line for his wins, his raids, his flees, or your retreats. Persona meet lines are flavour, not memory.
- fed is invisible at the moment it changes (all four legs; the Chorus readability hole is the most agreed single defect after the Corsair cut).
- The Corsair ship cut is the one real R7 exposure. Argon words it as failing the constraint in edge cases; the other legs word it as an exposure or risk. The shared substance: the clock fills on the win that may have crippled the ship, and the pack does not establish that the player can act on the card announcement before the strike lands, or that anything taken is recoverable when he dies.
- Identity space is wide (names, titles, personas, trait pairs, weakness pairs, portraits, scar epithets) while speech, clock rhythm and encounter shape are fixed; runs diverge at the identity layer and converge at the behaviour layer.
- Adaptations converge on the same five counters by the same highest-count rule, so a player with a settled style meets the same answer every run, reworded per faction.
- The Godot surface is the largest shared UNSURE: the pack never establishes what the Nemesis card actually shows in the port, so every readability verdict is conditional on the beh.d texts being displayed before the fight.

## Divergences (named, not resolved)

- Voidsworn verb match: Rey "exact", DeepSeek and Qwen "partial", Argon "half-implemented". Resolved for action purposes in favour of Argon's code-level reading (fix 2), with Rey's point standing that the symmetric buff is itself a fair and elegant duel rule once it is aimed.
- Chorus distinctness: Rey "most distinct of the six" (its power is a function of the whole run), Argon "poorly distinct in battle" (invisible, and inert at fed 0), DeepSeek "distinct in data, weak in felt play", Qwen "distinct if noticed". These are compatible once the axis is named: structurally the most distinct, perceptually among the weakest until fed is surfaced.
- Corsair fairness severity: Argon's "fails in edge cases" vs the other legs' "exposure". The synthesis keeps the substance and lets Opus judge the wording against the actual card flow.
- Patent number: DeepSeek and Argon cite the Nemesis patent as US 10,926,179 / US10926179B2 (granted 2021). The Qwen leg cites US 9,289,684 B2 (2016); that figure is wrong and is flagged in its screening note. Qwen's identity-space arithmetic is also off by about 5x (3,024,000 combinations per faction on its own inputs, not 604,800). Both slips are preserved verbatim in the filed leg, per the verbatim rule, and corrected only here and in screening.

## Ranked fixes (merged)

1. Fix the Deathless revive's uniqueness. Either scope the sector 1-2 survival to an escape framing for the other five (flagship withdraws at the brink rather than being destroyed and returning) so only Deathless is ever destroyed and reassembled, or stop consuming revived before sector 3. Until one of those lands, his ruling verb is shared with everyone.
2. Aim the Voidsworn challenge. Give his flagship a targeting bonus toward the player's flagship while strike is 'challenge' (the greedy focusFlag weight is the existing pattern), so the symmetric +20% is a duel he seeks, not a coincidence. Same class of fix for Ithar: either give the duel fleet an innate weak-ship focus or take "picks off your weakest ship" out of the card text.
3. Close the Corsair fairness exposure. Make raid theft recoverable on his death (the Warframe pattern: everything taken is held and returned when the Lich dies, which the Rey and Argon legs both cite), and convert the ship cut to the same recoverable form (the ship is taken and can be won back in his fight) or drop it. At minimum, guarantee the card warning lands with time and a way to act (repair, spend, move) before the strike resolves.
4. Sync the {beat} line with the adaptation it announces. When he is beaten, his next adaptation should counter beat directly, or the line should not claim it will not work twice. The data for this already exists on both sides; they are just computed from different usage pools on different schedules.
5. Narrate state changes when they happen. fed gains, raid and tithe landings, adaptation picks with their existing why strings ("you leaned on lances and ion fire"), scar causes: one line each, on the map or at the next meeting. This is the single highest value per effort item in all four legs, and it is what turns tracked memory into felt rivalry.
6. Pick scar epithets by cause. scarList already stores causes; Mordor's rule (the damage names the scar) is a lookup away.
7. Add a second spoken memory slot: his wins. A gloat line keyed to state he already tracks (your flagship died, you fled, your losses fed the Chorus) closes the one-sidedness every leg noted.
8. Reveal weaknesses when the player triggers them in battle, per catch 7. The revealed [] structure and the nemIntel hook already exist.
9. Filter contradictory trait and weakness pairs at creation (swift/slow, boarders/board, and the shielded/ion blur), per catch 8.
10. Align the Ithar flee text and test (shields "all down" vs .5), and separate the duel vocabulary between Ithar and Voidsworn in player-facing text.
11. Small code hygiene from the legs: Ithar's unused riches increments (catch 3); the Hegemony formation question (open question 3).

## Open questions for Opus

1. Tithe "min 1": does the Deathless tithe deal a minimum of 1 damage (so it can destroy a ship sitting at 1 hull on the map, an R7 problem) or clamp ships at a minimum of 1 hull remaining? Flagged independently by Rey, Qwen and Argon.
2. Does the code's nemAfterBattle branch order match the port notes' listing order (revive before the generic earlier-sector scar)? Catch 1 depends on it.
3. Hegemony formation: is the +1 sync radius innate (beh.formation:1), from the special adaptation only, or both (+2)?
4. When the clock fills, do raid and tithe fire in addition to converting the next battle or elite node into his fight, or do they consume the strike? The B4 and R42 notes can be read both ways.
5. What do strike 'duel' (Ithar) and strike 'swarm' (Chorus) do beyond fleet archetype? The notes say other strikes "act in battle" without a strike-specific effect for either.
6. Does ensureNemesis (the B4 to R42 save upgrade) preserve beat, scars and met, or only clock, weaknesses and adaptations as the notes list? (Qwen)
7. What does the Godot Nemesis card actually show, and when? Every readability verdict in all four legs is conditional on this.

## Legs and screening

DeepSeek: clean, high pack fidelity; comparable-game citations came back as bracket numbers without a URL list, so those claims are leg-stated. Qwen: clean with two flagged slips (patent number, identity-space arithmetic), both preserved verbatim in the leg and corrected in its screening note; its unique catches are the Ithar threshold mismatch (adopted above) and the save-upgrade question (open question 6). Argon: clean, strongest leg; five of its catches are chair-confirmed against the pack files (screening note lists them). Rey: chair audit, one chair correction before filing (the Ithar shield threshold, now stated both ways). Screening notes are held with the chair's working files.
