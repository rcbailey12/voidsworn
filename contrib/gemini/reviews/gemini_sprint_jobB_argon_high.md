# Job B B3/B4 review (Gemini leg, Argon High, Oct 26, 2026)

Filed verbatim from a fresh Gemini chat. Ran Oct 26, 2026, 07:08-07:13 CDT (runtime-measured, 5m).

Model verification (required by the assignment): signed in as Ryan Bailey (rcbailey12@gmail.com), Pro badge shown. Model 4 Argon (Complex tasks) was already selected. Thinking level was set to Low; it was changed to High. After the change, BOTH the mode picker button ("Open mode picker, currently Argon High") AND the prompt bar dropdown read "Argon High". Picker state verified before submitting. No fallback model was used.

Chair note on process (not part of Gemini's review): paste-entry mode hung the page (page_unresponsive, outcome unknown); the prompt box was checked and confirmed empty, so the default fill path was used instead (pack pasted in 3 parts: replace, then append twice) plus a one-line framing instruction restating the pack's own return-format instruction. No duplicate message was sent. The page shows a trailing status line "Verifying simulation state consistency" under the response; it is not part of the review text and is excluded below. The model's sidebar showed other Voidsworn-related chats from this account, but the review text does not quote or build on them. This is a commissioned blind review leg for the travel sprint (not a leads-only shelf); it is screened like the other legs. See the screening note for the chair's flags.

## Gemini review (verbatim)

1. Ranked findings

Post-B-19 admiral win rates are unverified and existing baselines are stale [INFERRED / UNSURE]

What: Commit beae728b315ad69a2ca6721c5818d012edfef60c (B-19) changes every battle loop in sim3d.js via the roundStart helper so round starts await turn-start deaths. Resolving turn-start deaths (such as damage-over-time ticks, hazard damage, or delayed effects) before ships act changes turn order, firing opportunities, and death-explosion chains across all simulated battles. The commit message reports no updated win rates. Prior to B-19, sector 1 admirals sat at 57% to 89% at 96 runs per admiral (FINDINGS S6). Because 89% is only 1 percentage point below the 90% ceiling, any upward shift from B-19 pushes at least one admiral outside the approved 50-90% band.

Where: sim3d.js (roundStart helper and battle loops, exact line numbers UNSURE because repository files are not attached to this session) and contrib/opus/compute/ (FINDINGS S6, UNSURE whether a post-commit output file exists).

Plan item or ruling: Section 1 and Section 5 admiral balance ruling (all admirals must remain within the 50-90% win-rate band).

Check to close: Check contrib/opus/compute/ for a sim run timestamped after Oct 26, 2026, 06:58 CDT. If none exists, re-run the 96-run sector 1 admiral benchmark on current main and check whether any admiral falls below 50% or exceeds 90%.

Conflicting Voidsworn carrier rulings threaten Commodore Ashgrove [OBSERVED in pack / UNSURE on live main]

What: An asymmetry ruling list records "Voidsworn no carriers" as a faction loss, which directly contradicts approved plan B3.1 ("Voidsworn keep carriers, at a price premium"). Banning carriers from Voidsworn breaks Commodore Ashgrove, a Voidsworn admiral whose entire kit is built around carriers. Leaving both texts on main or coding the roster gate from the asymmetry loss list instead of Plan B3.1 breaks an existing admiral and violates the approved record.

Where: data.js:204 (Commodore Ashgrove definition, OBSERVED in pack Section 3), contrib/opus/briefs/muse_2026-10-26_travel_sprint.md (pack Section 3 B3.1 and Section 4), and Voidsworn roster/shop tables in data.js (exact lines UNSURE without live repo files attached).

Plan item or ruling: Breaks Plan B3.1 and the Section 4 conflict ruling if the carrier ban is implemented or left uncleaned in repo docs.

Check to close: Inspect data.js:204 and the faction roster/price ladder tables in data.js to confirm Voidsworn carriers remain purchasable with a price multiplier rather than a ban, and edit the asymmetry ruling list on main to match Plan B3.1.

B-18 "no change in the sim" claim after restoring killUnit stalled-battle check is unverified and risks breaking Deathless reanimation [INFERRED / UNSURE]

What: B-18 fixes a bug in battle.js where killUnit's stalled-battle check after a death explosion was swallowed by a comment. The commit message claims "no change in the sim, where nothing stalls". That claim is inferred rather than proven. When a death explosion kills the last remaining ship(s) or triggers chain deaths, running a stalled-battle check inside killUnit can terminate a battle immediately. If that check fires before Deathless reanimation (battle.js:702) or before B-19's roundStart finishes processing turn-start death queues, a Deathless fleet that should reanimate or a mutual-explosion edge case will resolve differently in the sim.

Where: battle.js (killUnit, exact line UNSURE without live file attachment) and battle.js:702 (Deathless reanimate rule, OBSERVED in pack Section 3 B3.5).

Plan item or ruling: Affects B-18 verification (Section 2 and Section 5) and Plan B3.5 (Deathless elite attrition built on the reanimate rule at battle.js:702).

Check to close: Read killUnit and battle.js:702 to verify that the stalled-battle check executes only after reanimation and all queued death explosions complete, then run a fixed-seed sim3d.js comparison before and after B-18 to verify zero battle diffs.

FID telemetry in fmatrix is sim-only, misses specific B3 ruling checks, and lacks player-visible UI counterparts [INFERRED / UNSURE]

What: The new fmatrix FID line prints five numbers per faction: average firing range, incoming damage split (shields, armor and other cuts, hull), hull regrown per ship, loss rate, and damage dealt per ship. While these cover the high-level B3 exit metrics, they leave major blind spots for both rule verification and player readability:

Hegemony (Plan B3.2, Section 4): Aggregate range and damage dealt per ship do not verify that synchronized fire only applies within the flagship anchor radius, that losing the flagship collapses sync, or that the Anchored Volley boon is blocked from stacking with sync.

Ithar (Plan B3.1, B3.3, Section 4): Total shield soak in the incoming damage split mixes baseline shield regen (which all shielded hulls get) with Ithar's faction shield charge. It does not verify how much charge occurred above baseline regen, nor does it verify that Ithar ships never used Brace.

Chorus (Plan B3.4, Section 4): "Hull regrown per ship" tracks healing, but does not verify that the Chorus feed cap was enforced or that Chorus received zero repair outside feed.

Deathless (Plan B3.5, Section 4): FID does not separate reanimate triggers (battle.js:702) and elite attrition from general hull/loss stats, and must confirm zero shield soak under the "no shields" loss rule.

Player readability (Section 1, Section 5): The commit adds telemetry only to fmatrix. A player in a live battle cannot read fmatrix console lines. Without on-screen HUD or board indicators for flagship sync range and sync collapse, Ithar shield charge above baseline, Chorus feed procs and cap limit, Deathless attrition ticks, and B3.6 torpedo lanes with next-turn impact warnings, the player cannot read the faction identity mechanics.

Where: fmatrix sim file and battle UI files (exact file:line UNSURE without live repo files attached; INFERRED from commit message in Section 2).

Plan item or ruling: Plan B3.1 through B3.6, Section 4 faction identity rulings, and Section 1 and Section 5 readability rules.

Check to close: Add dedicated rule counters in fmatrix (sync-active shots vs unsynced shots, Ithar bonus shield charge vs baseline regen, capped feed heals, reanimate counts, Brace count) and verify in the game UI code that every faction mechanic and torpedo lane renders a visible state on the tactical board.

Any B3 or B4 item marked "exited" during the 4-day travel sprint breaks the plan exit criteria [OBSERVED in pack]

What: Plan B3 requires Ryan to play each faction once and confirm it feels like itself before exiting. Plan B4 requires Ryan to play each of the five items (B4.1 through B4.5) to exit, and enforces a strict build order where B4.2 events write flags, B4.3 faction verbs read those flags, and B4.4 the Nemesis builds on those flags. Because Ryan is traveling for 4 days and not playing (Section 5), no B3 or B4 work completed during the travel sprint can pass its exit gate.

Where: contrib/opus/briefs/muse_2026-10-26_travel_sprint.md (OBSERVED in pack Section 1, Section 3 B3/B4, and Section 5).

Plan item or ruling: Plan B3 and B4 exit rules and Section 5 travel sprint gate.

Check to close: Verify in the sprint tracker and commit history that all B3 and B4 deliverables remain marked "in review / awaiting Ryan playtest" until Ryan returns and plays them, and verify B4.3 and B4.4 do not bypass B4.2 event flag definitions.

2. Short verdict per trigger item

B-18 (killUnit stalled-battle check in battle.js): Flagged (INFERRED / UNSURE). Restoring a commented-out stalled-battle check after death explosions is a valid bug fix in principle, but the commit message's assertion of "no change in the sim, where nothing stalls" is unverified by a sim diff and risks interacting with Deathless reanimation (battle.js:702) or mutual-kill explosions. In addition, because live repo files were not attached to this session, the exact implementation in battle.js could not be directly read (UNSURE).

B-19 (roundStart helper awaiting turn-start deaths in sim3d.js): Flagged (INFERRED / UNSURE). Bringing sim3d.js round-start death resolution in line with the game's turn-start death awaiting is consistent with keeping the JS sim accurate, but changing death ordering across all battle loops invalidates prior balance runs. Because no post-B-19 admiral win rates were included in the commit message or verified in contrib/opus/compute/, the sector 1 admiral band (FINDINGS S6, previously 57% to 89%) is now stale and must be re-run. Live code presence in sim3d.js is UNSURE without attached repo files.

FID telemetry (faction identity lines in fmatrix): Flagged (INFERRED / UNSURE). The five metrics (average firing range, incoming damage split across shields/armor/hull, hull regrown per ship, loss rate, damage dealt per ship) align with the high-level B3 exit metrics, but they do not isolate Hegemony flagship-anchor sync, Ithar shield charge above baseline regen, Chorus feed cap hits, or Deathless reanimation (battle.js:702). Furthermore, fmatrix lines are sim-only and provide no player-visible readability in the game UI. Live code presence in fmatrix is UNSURE without attached repo files.

3. Not checked

Live repository source files (battle.js, sim3d.js, data.js, fmatrix, and UI files): Not checked (UNSURE). No repository files or code attachments were provided in this prompt session, and no filesystem connector is available to read the repository directly. Therefore, I could not directly verify whether killUnit in battle.js, the roundStart helper in sim3d.js, or the FID lines in fmatrix exist in the current code on main, nor could I inspect the exact line numbers beyond those explicitly cited in the evidence pack (data.js:204 and battle.js:702).

Simulation output files in contrib/opus/compute/ (FINDINGS S6 and any post-B-19 runs): Not checked (UNSURE). Because contrib/opus/compute/ is not attached in the pack, I could not verify whether a post-B-19 sim run exists or check individual admiral win rates against the 50-90% band. All admiral-band verdicts are therefore marked UNSURE.

Asymmetry ruling document vs data.js roster tables on main: Not checked (UNSURE). Without access to the live repository tree, I could not verify whether the "Voidsworn no carriers" text is still present in a repo document on main or whether data.js currently implements the Plan B3.1 carrier price premium for Voidsworn.

Godot / GDScript export parity: Not checked (UNSURE). Plan B3/B4 context notes that data.js tables reach Godot through the JSON exporter and rules changes land in JS first, then in GDScript with a new golden scenario. No exporter or GDScript files were in the pack to verify.

4. Repo claims and evidence index

contrib/opus/briefs/muse_2026-10-26_travel_sprint.md: OBSERVED (in pack Section 1, 3, 4). Source of the job scope, B3 and B4 plan items, faction identity rulings, and exit criteria.

data.js:204: OBSERVED (cited in pack Section 3 B3.1). Defines Commodore Ashgrove, a Voidsworn admiral whose kit requires carriers; used to uphold Plan B3.1 over the conflicting asymmetry loss list. Live file contents at line 204 are UNSURE (file not attached).

battle.js:702: OBSERVED (cited in pack Section 3 B3.5). Location of the Deathless reanimate rule on which B3.5 elite attrition is built. Live file contents at line 702 are UNSURE (file not attached).

battle.js (killUnit stalled-battle check, B-18): INFERRED (from commit beae728b315ad69a2ca6721c5818d012edfef60c in pack Section 2) / UNSURE (in live code). Exact line numbers and implementation in battle.js could not be read because the file was not attached.

sim3d.js (roundStart helper across battle loops, B-19): INFERRED (from commit beae728b315ad69a2ca6721c5818d012edfef60c in pack Section 2) / UNSURE (in live code). Exact line numbers and loop call sites in sim3d.js could not be read because the file was not attached.

fmatrix (FID telemetry output lines): INFERRED (from commit beae728b315ad69a2ca6721c5818d012edfef60c in pack Section 2) / UNSURE (in live code). Exact file path, line numbers, and metric formulas could not be read because the file was not attached.

contrib/opus/compute/ (FINDINGS S6 admiral win-rate band 57-89% at 96 runs per admiral): OBSERVED (cited in pack Section 5) / UNSURE (post-B-19 status). No post-commit sim files were attached to verify current admiral win rates.
