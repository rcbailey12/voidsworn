1. Headline mechanism in five lines

1. At run start, assign a hunter faction to each of the three story points (SP1, SP2, SP3) by drawing uniformly from the five non-player factions, with the constraint that SP2 differs from SP1 and SP3 differs from SP2 (no consecutive repeats; SP1 may equal SP3).
2. Each matrix cell (player faction, story point) therefore has each non-player hunter with probability exactly 1/5; expected hunts per faction across the 6x3 set is exactly 3.
3. One commander per hunter faction per run is created lazily; that commander persists and accumulates weaknesses, adaptations, scars and lessons whenever its faction is drawn.
4. The once-per-sector meeting stands: the sector's assigned hunter is the mandatory meeting; the clock is a single run-level accelerant paced by the current hunter's faction and only brings that meeting forward.
5. The sector 3 deciding fight is the SP3 commander's flagship death; SP1/SP2 commanders who were beaten escape and return only if drawn again (SP1 can return at SP3 with probability 1/4 given SP1).

2. Assignment mechanism stated exactly

Let the six factions be F = {Glasswrights, Hullbreakers, Sunward Crusade, Hegemony, Chorus, Eclipse}. For a run with player faction P, let S = F \ {P}, so |S| = 5.

SP1: draw H1 uniformly from S. For every X in S, Pr(H1 = X) = 1/5.

SP2: draw H2 uniformly from S \ {H1}. For every X in S, Pr(H2 = X) = 1/5 (marginal; see section 5), and Pr(H2 = H1) = 0.

SP3: draw H3 uniformly from S \ {H2}. For every X in S, Pr(H3 = X) = 1/5 (marginal), and Pr(H3 = H2) = 0. Note Pr(H3 = H1 | H1) = 1/4, so the SP1 hunter returns at SP3 with probability 1/4.

The assignment is computed once at run start and stored as RUN.nemAssign = [H1, H2, H3]. There is no cross-run balancing state; each run is independent. Seeding uses the run's existing RNG seed at run start (INFERRED: the pack does not name the RNG function, only that RUN.nem is created once at run start, campaign_run.js:250; Godot mirror campaign.gd:1114, newNemesis at campaign.gd:1802).

Probability per matrix cell: for every player P and every story point k in {1, 2, 3}, each faction X != P has probability 1/5; X = P has probability 0. This is exact by the symmetry of S and the uniform draws.

Code shape implied (no code written): RUN.nemAssign is a three-element array of faction ids. RUN.nem becomes RUN.nems, a map from faction id to commander object, populated lazily via the existing newNemesis(fac) identity logic (campaign_run.js:250; data.js:443 onward). The active hunter for sector k is RUN.nems[RUN.nemAssign[k-1]]. nemNodeIs (campaign_run.js:296), nemStrike (campaign_run.js:284), nemAdapt (campaign_run.js:300) and nemSignature (campaign_run.js:273) take the active commander instead of the single RUN.nem. The clock remains a single RUN.nemClock (NEM_CLOCK=4, data.js:427); nemClockAdd (campaign_run.js:280) is unchanged, but the pace is read from the active commander's faction beh.clock (data.js:443-470), and nemStrike uses the active commander.

3. Commander identity and persistence under rotation

Identity: one commander per hunter faction per run, created lazily when that faction is first assigned. Each commander gets the full shipped R42 identity: name from the faction's pre/post pools (never matching an ADMIRALS name), title, persona, two strength traits, portrait id nem_<faction>_1..6, two weaknesses rolled from NEM_WEAK (data.js:428), scars and epithets on survival (data.js:443 onward; newNemesis at campaign_run.js:250). This is per run, not per campaign; each run resets the commander registry, matching today's run-start creation.

Persistence: each commander object holds its own state: weaknesses, revealed set, adaptations, seen data, scars, epithets, lessons, and signature list. This is the shipped RUN.nem state, now keyed by faction in RUN.nems. If a faction is drawn at SP1 and SP3, the same commander persists across both meetings and can flee at SP1 and return richer/honed/revived at SP3, preserving the return mechanics in the behaviour packages. If drawn only once, the commander is met once and either escapes (SP1/SP2) or dies (SP3).

Sector 3 deciding fight: the SP3 commander is the one whose flagship death ends him (campaign_run.js:244-249 header comment). If the SP3 commander is the same as SP1, his SP1 escape is followed by the SP3 return and death. SP1/SP2 commanders not drawn at SP3 are not present; if beaten earlier they escaped and do not return. The run's Nemesis arc concludes with the SP3 meeting.

Attachment of weaknesses, adaptations, scars, lessons: per commander. nemReveal (campaign_run.js:271) reveals weaknesses on the active commander. nemAdapt (campaign_run.js:300) runs per commander on sector advance using that commander's seen. Debrief teaching (Job 7 step 7) uses the active commander's identity and attaches the lesson to that commander. This keeps the issue #71 debrief design's hunter-specific lessons, now per commander rather than per run; the pack's revisit trigger is this redesign, and the answer is "lessons attach per commander."

INFERRED: the exact lesson storage shape is not in the pack; I infer lessons are stored on the commander object like weaknesses. The pack states lessons are "hunter-specific" and that this redesign is the revisit trigger.

4. Full matrix: player faction x story point

Abbreviations: GW = Glasswrights, HB = Hullbreakers, SC = Sunward Crusade, HG = Hegemony, CH = Chorus, EC = Eclipse. Each listed hunter has probability 1/5 in that cell; the player's own faction has probability 0. The same five-hunter set appears in every non-self cell; the no-consecutive-repeat constraint is a joint restriction (section 2), not a marginal change.

Player | SP1 hunters (1/5 each) | SP2 hunters (1/5 each) | SP3 hunters (1/5 each)
GW | HB, SC, HG, CH, EC | HB, SC, HG, CH, EC | HB, SC, HG, CH, EC
HB | GW, SC, HG, CH, EC | GW, SC, HG, CH, EC | GW, SC, HG, CH, EC
SC | GW, HB, HG, CH, EC | GW, HB, HG, CH, EC | GW, HB, HG, CH, EC
HG | GW, HB, SC, CH, EC | GW, HB, SC, CH, EC | GW, HB, SC, CH, EC
CH | GW, HB, SC, HG, EC | GW, HB, SC, HG, EC | GW, HB, SC, HG, EC
EC | GW, HB, SC, HG, CH | GW, HB, SC, HG, CH | GW, HB, SC, HG, CH

Joint restriction: for each row, Pr(H2 = H1) = 0 and Pr(H3 = H2) = 0. Pr(H3 = H1 | H1) = 1/4.

5. Symmetry check arithmetic

For any faction X, it can hunt player P only if P != X. There are 5 such players. At each story point k, Pr(Hk = X) = 1/5. Therefore

E[hunts by X] = sum over P != X sum over k=1 to 3 Pr(Hk = X) = 5 * 3 * 1/5 = 3.

This holds for all six X. Total expected hunts = 6 * 3 = 18 = 6 players * 3 story points. Each player is hunted exactly 3 times (once per SP), never by itself. Every hunter X is reachable for every player P at every SP: Pr(Hk = X) = 1/5 > 0. No pairing is the only option (each cell has 5 options), and no pairing is impossible (every X != P appears in every cell).

Marginal proofs:

Pr(H2 = X) = sum over Y != X Pr(H1 = Y) Pr(H2 = X | H1 = Y) + Pr(H1 = X) * 0 = 4 * 1/5 * 1/4 = 1/5.

Pr(H3 = X) = sum over Y != X Pr(H2 = Y) Pr(H3 = X | H2 = Y) + Pr(H2 = X) * 0 = 4 * 1/5 * 1/4 = 1/5.

The no-consecutive-repeat constraint changes only the joint distribution, not the marginals. The expected hunts per faction are exactly equal, shown not asserted.

6. Reconciliation with Job 7 steps 6, 7 and 11

Step 6 - clash check (nemAdapt, campaign_run.js:300; sector advance campaign_run.js:576; tests contrib/opus/tools/nemesis_clash_tests.js). The clash check is already in the code: adaptations never directly counter a revealed weakness (blocked set in nemAdapt). Under rotation, nemAdapt must run per commander that was active in the sector, using that commander's own RUN.nems[F].seen and adaptation state. The blocked-set logic and the tests are unchanged; they simply execute per commander. No duplication: the clash check remains adaptation logic, not telemetry.

Step 7 - mandatory meeting language and debrief teaching (nemNodeIs, campaign_run.js:296). nemNodeIs marks a battle or elite node as the active commander's when a strike is pending, or at the last fight before the rest stop if that commander has not been met this sector. Under rotation, "active commander" is RUN.nems[RUN.nemAssign[sector-1]], and the "met this sector" flag is per commander. The once-per-sector meeting stands: exactly one meeting per sector, with the assigned hunter. A strike brings that meeting forward inside the sector; it does not create an extra meeting and does not change the hunter. Debrief teaching on a lost meeting attaches to the commander met; meeting language uses that commander's name and faction and owns the mandatory status. The issue #71 lessons remain hunter-specific, now per commander. Anchor: campaign_run.js:296.

Step 11 - telemetry counters (nemSignature, campaign_run.js:273). nemSignature logs a nem_signature event each time a behaviour fires (raid, tithe, flee, revive, feed, reinforce, duel, challenge), capped list on the commander. Under rotation, each commander has its own signature list; the event includes the commander's faction. Step 11's escape counter is per run (counts commanders who escaped, i.e., beaten at SP1/SP2 and not killed). The compounding counter is per commander where the behaviour is commander-specific (e.g., Chorus growth from ships the player loses anywhere is on the Chorus commander). This avoids duplicating the clash check. Anchor: campaign_run.js:273.

7. Build issues Opus can file, sequenced

Assignment data and run init. Add RUN.nemAssign = [H1, H2, H3] computed at run start with the no-consecutive-repeat draw. Files: campaign_run.js (run start / newNemesis area), Godot mirror campaign.gd:1114, campaign.gd:1802. Scope: exact assignment, seeding, storage.

Commander registry. Replace single RUN.nem with RUN.nems keyed by faction; lazy creation using the existing newNemesis(fac) identity logic. Files: campaign_run.js:250, campaign.gd:1802. Scope: per-faction identity and persistence.

Meeting targeting. Update nemNodeIs (campaign_run.js:296) to use RUN.nemAssign[currentSector-1] and a per-commander "met this sector" flag. Scope: once-per-sector meeting, strike targeting.

Clock and strike. Keep RUN.nemClock; pace from the active commander's beh.clock; nemStrike (campaign_run.js:284) uses the active commander. Files: campaign_run.js:280, campaign_run.js:284.

Adaptation per commander. Call nemAdapt (campaign_run.js:300) for each commander active in the sector on sector advance (campaign_run.js:576); preserve the clash check and extend contrib/opus/tools/nemesis_clash_tests.js to per-commander cases.

Telemetry. Per-commander signature list (campaign_run.js:273); add run-level escape counter and per-commander compounding counter where applicable.

Identity and lessons. Ensure weaknesses (nemReveal, campaign_run.js:271), scars, epithets and lessons attach to the commander object; debrief teaching uses the active commander. Files: campaign_run.js:271; identity pools data.js:443 onward.

UI. Display the current sector's assigned hunter and prior commander state (scars, lessons) in the Nemesis panel. Files: UI code (INFERRED: not in pack).

Tests. Enumeration/symmetry test over seeds; per-commander clash check; telemetry; once-per-sector meeting. Files: new test files, extend contrib/opus/tools/nemesis_clash_tests.js.

Sequence: 1 to 2 to 3 to 4 to 5 to 6 to 7 to 8 to 9. Issues 1-2 are data-shape foundations; 3-5 are the meeting/adaptation behaviour; 6-7 are state and telemetry; 8-9 are presentation and verification.

8. Owner questions with chair picks (at most five)

Assignment rule: no-consecutive-repeat (chair pick) vs independent uniform draws. Pick cost: SP2 hunter cannot return at SP3; SP1 hunter can return at SP3 with probability 1/4. Independent draws allow consecutive repeats and all-same runs, simplify enumeration, but weaken "hunter varies by story point."

Return mechanics: allow the SP1 hunter to return at SP3 (chair pick) vs force three distinct hunters. Pick cost: one commander can appear twice, so accumulated state must be handled (already in the per-commander model). Forcing distinct hunters kills all "returns richer/honed/revived" behaviour within a run.

Clock scope: single run-level clock paced by the current hunter (chair pick) vs per-commander clocks. Pick cost: less granular; a commander's clock does not persist across sectors when not active. Per-commander clocks multiply state and complicate nemClockAdd.

Sector 3 resolution: only the SP3 commander's flagship death ends him (chair pick) vs resolving all commanders at sector 3. Pick cost: SP1/SP2 commanders who escaped have no death scene; their arcs end unresolved. Resolving all would add extra meetings, violating the once-per-sector rule.

Telemetry counters: escape counter per run, compounding counter per commander (chair pick) vs all per commander or all per run. Pick cost: two levels of counters; but this matches step 11's "per run" for escapes and Chorus's per-commander growth.

9. Not checked

Exact Godot mirror line numbers beyond campaign.gd:1114 and campaign.gd:1802; I did not verify nemNodeIs, nemAdapt or nemSignature in campaign.gd.

The Job 9 faction review file contents (not attached); I rely on the pack's summary and the drafted pairings table.

The issue #71 debrief design details; I infer lessons attach per commander from the pack's "hunter-specific" statement.

The exact RNG seeding function and whether run start has a stable seed; I infer the run's existing RNG is used.

The UI's ability to display multiple commanders and prior commander state.

The exact behaviour of adaptFast for Chorus under rotation; I assume it fires on the Chorus commander after each meeting.

Whether the run 5 finale meeting needs its own assignment rule (the pack flags this as an open design question for the legs).

The exact contents of contrib/opus/tools/nemesis_clash_tests.js; I only know its path and purpose from the pack.

The chair's enumeration over seeds and measured spread; I provide analytic probabilities, not empirical spread.

Gate: DeepSeek leg, run 2026-11-03 from the main chat. DeepThink ON and Search ON verified before sending; PACK.md attached to the outgoing message itself.
