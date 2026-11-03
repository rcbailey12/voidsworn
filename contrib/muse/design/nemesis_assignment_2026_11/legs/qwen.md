Gate: Qwen3.8-Max verified in the model selector before the prompt was submitted (Gate 1), and the chat header still showed Qwen3.8-Max after generation started and at completion (Gate 2). One response, no preference picker. An Access Verification slider appeared on the first send attempt; it was cleared and PACK.md was re-verified as still attached before sending. Run from the main chat on 2026-11-03.

Nemesis Assignment Design Draft - Qwen Leg

(1) Headline Mechanism in Five Lines
At run start, draw three distinct hunter factions without replacement from the five non-player factions, seeded deterministically from the run seed; assign them to SP1, SP2, SP3 in draw order.
Each drawn faction spawns its own named commander (identity, weaknesses, portrait generated per the existing data.js:443 tables) at run start; all three are pre-built and stored in a RUN.nem_pool array of length 3.
The active commander pointer RUN.nem is set to RUN.nem_pool[sector_index] at each sector boundary, so nemNodeIs, nemStrike, nemAdapt, and nemSignature all operate on a single RUN.nem reference exactly as today.
Adaptations persist per hunter faction in campaign state across the five-run arc; scars, epithets, and weaknesses are per-commander-instance (per run); lessons (step 7 debrief) attach per hunter faction.
Every non-player faction has marginal probability 1/5 at every story point for every player; expected hunts per faction across the full 6x3 matrix is exactly 3, verified by enumeration.

(2) The Assignment Mechanism, Stated Exactly
Pool. For player faction F, the hunter pool is the set of all six factions minus F: five candidates.
Draw rule. At run start, three hunters are drawn sequentially without replacement:
SP1: uniform draw from the 5-faction pool. P(each) = 1/5.
SP2: uniform draw from the remaining 4. P(each | SP1 outcome) = 1/4. Marginal P(each) = (4/5)(1/4) = 1/5.
SP3: uniform draw from the remaining 3. P(each | SP1,SP2 outcomes) = 1/3. Marginal P(each) = (4/5)(3/4)(1/3) = 1/5.
The joint probability of any specific ordered triple (h1, h2, h3) of distinct factions is (1/5)(1/4)(1/3) = 1/60. There are 5 x 4 x 3 = 60 equally likely ordered triples.
Seeding. The draw consumes the first three integers from the run's existing PRNG stream (the same stream that seeds RUN.seed today). No additional entropy source. The draw is fully deterministic given the run seed, so the chair can enumerate all 60 orderings per player faction by iterating seeds.
Balancing state across runs. None. Each run's assignment is independent. The five-run campaign arc (R62) generates a fresh seed per run, so variety across runs emerges from seed variation alone. Rationale: introducing cross-run memory (e.g. "reduce probability of a faction that hunted last run") would break the exact 1/5 marginal and complicate enumeration without a proportional design gain; the within-run without-replacement draw already guarantees three distinct hunters per run.
Probability table per matrix cell. For any player faction F and any story point SPk, every faction G != F has P(G hunts at SPk) = 1/5. The conditional probabilities differ (1/5, 1/4, 1/3 for SP1, SP2, SP3 respectively) but the marginals are uniform.

(3) Commander Identity and Persistence Under Rotation
Generation. At run start, after the three hunters are drawn, a commander is generated for each using the existing identity machinery (data.js:443 onward): name from faction pre/post pools, title, persona, two strength traits, portrait id nem_<faction>_1..6, two weaknesses from NEM_WEAK (data.js:428). All three commanders are built at run start and stored in RUN.nem_pool[0..2].
Active pointer. RUN.nem is reassigned at each sector boundary: RUN.nem <- RUN.nem_pool[sector - 1]. All existing functions that read RUN.nem (nemNodeIs at campaign_run.js:296, nemStrike at campaign_run.js:284, nemAdapt at campaign_run.js:300, nemSignature at campaign_run.js:273) continue to operate on a single object reference. The code shape is recognisable: the only structural change is that RUN.nem is a pointer into a three-element array rather than a singleton.
Sector 3 deciding fight. The SP3 commander is the final hunter. The existing rule (campaign_run.js:244-249 header comment) stands: in sector 3, the commander's flagship death ends him and the run. Because the without-replacement draw guarantees the SP3 commander has not appeared in SP1 or SP2, the deciding fight is always against a fresh commander the player has not met this run. This preserves the escalation fiction: the final hunter is a new threat, not a repeat.
Weaknesses. Two per commander, rolled at run start (existing). They attach to the commander instance. Intel events and nemReveal (campaign_run.js:271) reveal them per commander. If the player faces the same hunter faction in a later run of the campaign, a new commander is generated with new weaknesses. Weaknesses do NOT persist across runs.
Adaptations. Adaptations persist per hunter faction in campaign state (a new CAMPAIGN.faction_adapt[fac] object). At run start, the commander for faction G loads CAMPAIGN.faction_adapt[G] as its starting adaptation set. After the meeting, if the commander survives (escapes in sectors 1 or 2), nemAdapt (campaign_run.js:300) writes the new adaptation back to CAMPAIGN.faction_adapt[G]. In sector 3, whether the commander lives or dies, the adaptation is still written (the faction learned from the engagement). The clash check (blocked set in nemAdapt; tests at contrib/opus/tools/nemesis_clash_tests.js) operates on the current commander's loaded adaptation set versus that commander's revealed weaknesses - logically unchanged from today, just reading from campaign state rather than RUN.nem.seen alone.
Scars and epithets. Per commander instance (per run). A commander that escapes in sector 1 or 2 gains a scar and possibly an epithet. These are not carried into future runs; the next time that faction hunts, a new commander is generated. INFERRED: optionally, the faction's cumulative scar count across the campaign could be displayed as a "legend" stat in the commander's title (e.g. "Thrice-Scarred"), but this is cosmetic and not required.
Lessons (step 7 debrief teaching). Attach per hunter faction, not per commander instance. If the player loses to a Chorus Nemesis meeting, the debrief lesson is about Chorus Nemesis behaviour (feed mechanic, adaptation pattern). This persists across runs so the player accumulates knowledge of a faction's package even though the individual commander changes. This aligns with the #71 debrief design's "hunter-specific" language: the hunter is the faction package, not the individual name.
Strike and the clock. The clock (NEM_CLOCK = 4, data.js:427; nemClockAdd at campaign_run.js:280) fills as today. When it fills, nemStrike (campaign_run.js:284) triggers the meeting for the current sector's assigned hunter. The strike brings the meeting forward within its sector; it does not change which hunter is assigned and does not create an additional meeting. The clock remains an accelerant only.

(4) The Full Matrix: Player Faction x Story Point
Notation: Gl = Glasswrights, Hu = Hullbreakers, Cr = Sunward Crusade, He = Hegemony, Ch = Chorus, Ec = Eclipse.
Each cell lists the set of possible hunters and the marginal probability of each. Because the draw is without replacement from the five non-player factions, every non-player faction can appear at every story point.
Glasswrights - SP1: {Hu, Cr, He, Ch, Ec} each 1/5; SP2: {Hu, Cr, He, Ch, Ec} each 1/5; SP3: {Hu, Cr, He, Ch, Ec} each 1/5
Hullbreakers - SP1: {Gl, Cr, He, Ch, Ec} each 1/5; SP2: {Gl, Cr, He, Ch, Ec} each 1/5; SP3: {Gl, Cr, He, Ch, Ec} each 1/5
Sunward Crusade - SP1: {Gl, Hu, He, Ch, Ec} each 1/5; SP2: {Gl, Hu, He, Ch, Ec} each 1/5; SP3: {Gl, Hu, He, Ch, Ec} each 1/5
Hegemony - SP1: {Gl, Hu, Cr, Ch, Ec} each 1/5; SP2: {Gl, Hu, Cr, Ch, Ec} each 1/5; SP3: {Gl, Hu, Cr, Ch, Ec} each 1/5
Chorus - SP1: {Gl, Hu, Cr, He, Ec} each 1/5; SP2: {Gl, Hu, Cr, He, Ec} each 1/5; SP3: {Gl, Hu, Cr, He, Ec} each 1/5
Eclipse - SP1: {Gl, Hu, Cr, He, Ch} each 1/5; SP2: {Gl, Hu, Cr, He, Ch} each 1/5; SP3: {Gl, Hu, Cr, He, Ch} each 1/5
Within a single run, the three hunters are distinct (without replacement). The marginal probability at each cell is 1/5 for each non-player faction; the conditional probabilities are 1/5, 1/4, 1/3 for SP1, SP2, SP3 respectively.
All six drafted hunters (Chorus, Glasswrights, Hullbreakers, Crusade, Hegemony, Eclipse) appear in the matrix. The defect of the Job 9 draft (Hegemony never hunted, Eclipse hunted twice, one-directional pairings) is eliminated: every faction hunts and is hunted, and no pairing is fixed or excluded.

(5) Symmetry Check Arithmetic
Claim: Each of the six factions hunts exactly 3 times in expectation across the full 6x3 matrix.
Proof by direct computation.
Fix a hunter faction G. G can appear as hunter for any of the 5 player factions F != G. For each such F, and for each story point SPk in {SP1, SP2, SP3}:
P(G is the hunter for F at SPk) = 1/5 (shown in section 2 marginal derivation).
Expected number of times G hunts across the full matrix:
E[hunts by G] = sum over F != G, k=1 to 3 of P(G hunts F at SPk) = 5 x 3 x 1/5 = 3.
This holds for every faction G by the symmetry of the construction (the pool always excludes only the player's own faction, and the draw is uniform). Therefore:
Glasswrights - Expected hunts 3, Expected times hunted 3
Hullbreakers - Expected hunts 3, Expected times hunted 3
Sunward Crusade - Expected hunts 3, Expected times hunted 3
Hegemony - Expected hunts 3, Expected times hunted 3
Chorus - Expected hunts 3, Expected times hunted 3
Eclipse - Expected hunts 3, Expected times hunted 3
Total assignments: 6 players x 3 SPs = 18. Sum of expected hunts: 6 x 3 = 18. Check.
No-faction-equals-player check: the pool excludes the player's own faction by construction. Check.
Every pairing reachable: for any ordered pair (F, G) with F != G, P(G appears for F at some SP) = 1 - P(G not drawn in any of 3 draws) = 1 - (4/5)(3/4)(2/3) = 1 - 2/5 = 3/5 > 0. Check.
No pairing is the only option: at every story point, the pool has at least 3 candidates (SP3 has 3). No single pairing is forced. Check.
Spread per run. For a fixed player faction, there are 60 equally likely ordered triples. Each run presents exactly 3 distinct hunters. Across seeds, all 60 orderings are equiprobable (each at 1/60). The per-run spread is therefore always 3 distinct factions; the variance is in which 3 and in what order. The chair can verify by iterating seeds and tabulating the 60 buckets.

(6) Reconciliation with Job 7 Steps 6, 7, and 11
Step 6 - Clash Check (R63)
Current code: nemAdapt at campaign_run.js:300; the blocked set prevents an adaptation from directly countering a REVEALED weakness; tests at contrib/opus/tools/nemesis_clash_tests.js.
What changes: nemAdapt currently reads and writes RUN.nem.seen. Under rotation, it reads the active commander's adaptation set (loaded from CAMPAIGN.faction_adapt[G] at run start) and writes back to CAMPAIGN.faction_adapt[G] after the meeting. The blocked-set logic itself is unchanged: it still checks the current commander's revealed weaknesses against proposed adaptations. The file:line anchor campaign_run.js:300 remains the call site; the function signature gains a faction key for the campaign-state lookup.
What does not change: the clash-check rule, the blocked-set data, the test harness at contrib/opus/tools/nemesis_clash_tests.js. The check is still per-commander, still fires once per sector on sector advance (campaign_run.js:576), still operates on adaptations versus revealed weaknesses.
Step 7 - Mandatory Meeting and Debrief Teaching
Current code: nemNodeIs at campaign_run.js:296 marks a battle or elite node as the Nemesis meeting; the once-per-sector meeting is enforced there. Debrief teaching per #71 is hunter-specific.
What changes: nemNodeIs must resolve which commander is active for the current sector (RUN.nem <- RUN.nem_pool[sector - 1]). The meeting language ("mandatory") is unchanged. The debrief lesson on a lost meeting now attaches to the hunter faction (not the individual commander name), so the lesson persists if the same faction hunts again in a later run. The #71 revisit trigger (noted in the pack) is satisfied: hunter shape changes from one-per-run to one-per-story-point, but the lesson is keyed to the faction behaviour package, which is unchanged.
What does not change: the once-per-sector meeting rule, the clock-as-accelerant-only rule, the nemNodeIs fallback (last fight before rest stop if no strike), the escape rule (sectors 1-2) and flagship-death rule (sector 3, campaign_run.js:244-249).
Step 11 - Telemetry Counters
Current code: nemSignature at campaign_run.js:273 logs a 'nem_signature' telemetry event each time a behaviour fires (raid, tithe, flee, revive, feed, reinforce, duel, challenge); capped list on the commander.
What changes: Each of the three commanders per run has its own nemSignature log (capped list per commander, as today). Step 11's escape counter increments each time a commander escapes (sectors 1-2); with up to 3 commanders per run, the run-level escape counter can reach 2 (SP1 and SP2 commanders can escape; SP3 ends by death or run end). Step 11's compounding counter tracks how many times a faction's adaptation set has been added to across the campaign; this is read from CAMPAIGN.faction_adapt[G].length or a dedicated counter.
What does not change: the telemetry event schema ('nem_signature'), the behaviour tag list, the per-commander capped list structure. The file:line anchor campaign_run.js:273 remains the call site; it now reads from the active RUN.nem pointer, which is the same indirection as today.

(7) Build Issues Opus Can File (Sequenced)
B1 - Introduce RUN.nem_pool array and sector-index pointer - Replace singleton RUN.nem with a 3-element pool; set RUN.nem = RUN.nem_pool[sector-1] at sector boundary. All downstream readers continue to use RUN.nem. - campaign_run.js (RUN init ~line 250, sector-advance ~line 576), campaign.gd:1114 / campaign.gd:1802 (Godot mirror)
B2 - Implement seeded without-replacement hunter draw at run start - Draw 3 distinct factions from the 5-faction pool using the run PRNG; build three commanders via existing identity tables. - campaign_run.js (newNemesis, ~line 250), data.js:443+ (identity generation, called 3x)
B3 - Route nemNodeIs and nemStrike to the active sector commander - nemNodeIs (campaign_run.js:296) and nemStrike (campaign_run.js:284) read RUN.nem (now the active pointer). Verify no direct RUN.nem_pool access leaks into battle resolution. - campaign_run.js:284, campaign_run.js:296
B4 - Migrate nemAdapt to campaign faction state - nemAdapt (campaign_run.js:300) reads/writes CAMPAIGN.faction_adapt[fac] instead of RUN.nem.seen alone. Clash-check blocked set unchanged. Update tests. - campaign_run.js:300, campaign_run.js:576, contrib/opus/tools/nemesis_clash_tests.js
B5 - Update nemSignature telemetry for multi-commander runs - nemSignature (campaign_run.js:273) tags events with commander index and faction. Add run-level escape counter (0-2) and campaign compounding counter per faction. - campaign_run.js:273, telemetry schema
B6 - Rekey debrief lessons to hunter faction - Step 7 teaching and #71 debrief design: lesson key changes from commander id to hunter faction id. Update meeting language to reference faction package. - Debrief/lesson module (INFERRED: contrib/muse/design/ or equivalent), campaign_run.js meeting resolution
B7 - Godot mirror sync - Replicate B1-B6 in the Godot port: campaign.gd:1114 (RUN.nem creation), campaign.gd:1802 (newNemesis), shared data tables. - campaign.gd:1114, campaign.gd:1802
Sequence: B1 to B2 to B3 to B4 to B5 to B6 to B7. B1-B3 are the structural refactor; B4-B6 are the state and telemetry migration; B7 is the port sync.

(8) Owner Questions (At Most Five) with Picks
Q1. Run 5 finale assignment.
The campaign arc is five runs (R62). Does the run 5 finale meeting need a special assignment rule (e.g. a fixed "arch-nemesis" drawn from the faction that hunted most across runs 1-4), or does it use the same SP3 draw?
Pick: Use the same SP3 draw. A special rule adds a code path, breaks the symmetry arithmetic, and the five-run arc already provides narrative closure through accumulated faction adaptations. Cost of alternative: one extra assignment function, a campaign-state query, and a symmetry exception to document.
Q2. Adaptation persistence scope.
Adaptations are proposed at faction level across the campaign. Should they instead reset each run (fresh commander, fresh adaptations)?
Pick: Faction-level persistence. This preserves the accumulation feel the ruling values and gives the player a reason to remember a faction across runs. Cost of alternative: simpler code, but loses the "returning hunter" fiction and makes the Chorus adaptFast package (which compounds) feel weightless.
Q3. Scars across runs.
Scars and epithets are per-commander-instance. Should a faction's cumulative scar count display as a cosmetic "legend" prefix on future commanders of that faction?
Pick: Yes, cosmetic only, no mechanical effect. Low build cost (one string lookup), high fiction value. Cost: one additional data field on CAMPAIGN.faction_adapt[fac], one display string.
Q4. Commander escape and re-encounter fiction.
In sectors 1-2 the commander escapes. With rotation, that commander does not reappear this run. If the same faction hunts in a later run, is it the same commander (returned) or a new one?
Pick: New commander, same faction. The escaped commander's scars are lost; the faction's adaptations persist. This avoids a persistent-commander tracking system across runs. Cost of alternative: persistent commander registry, cross-run scar/weakness carry, more state to test.
Q5. Strike interaction with sector transition.
If the clock fills on the very last node of a sector (after the mandatory meeting has already occurred), does the strike carry over to the next sector's hunter, or is it discarded?
Pick: Discard. The meeting already occurred; the clock resets at sector boundary. The clock is an accelerant, not a queue. Cost of alternative: a pending-strike flag that crosses the sector boundary, complicating nemNodeIs.

(9) Not Checked
- The pack states the Godot port "mirrors" the browser build and shares data tables. I have not verified that campaign.gd:1114 and campaign.gd:1802 have identical structure to the JS equivalents; the build issue B7 assumes they do.
- The exact PRNG stream consumption order (which three integers are drawn, whether they are consumed before or after other run-start rolls) is not specified in the pack. I assume sequential consumption from the existing stream; the chair or Opus should confirm the stream layout.
- The #71 debrief design document is referenced but not reproduced in the pack. The lesson-rekeying proposal (B6) is INFERRED from the pack's summary of #71 ("hunter-specific, with a noted revisit trigger").
- The R62 five-run campaign arc structure is referenced but not detailed in the pack. The claim that "each run generates a fresh seed" is INFERRED from standard roguelike practice and the pack's mention of seeding.
- The Chorus adaptFast behaviour (adapts after every meeting, not just sector advance) is noted in the pack (data.js:443-470). Under rotation, the Chorus commander appears in only one sector, so adaptFast fires after that single meeting. This is mechanically identical to today's single-meeting-per-sector behaviour, but I have not verified whether adaptFast was intended to fire multiple times per run in a future multi-meeting design.
- The pack states "at most five owner questions with chair picks." I have provided picks; the chair (Rey) should confirm or override.
