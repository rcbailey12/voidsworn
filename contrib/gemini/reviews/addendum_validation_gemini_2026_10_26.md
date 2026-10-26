# Addendum validation, Gemini Argon leg, 2026-10-26

Chair header: filed as the single reviews copy for the Gemini leg (house pattern). Model: Gemini 4 Argon, Thinking level High, verified in two places before submitting (the prompt bar model button read "Argon High"; reopening the picker showed "Selected 4 Argon Complex tasks" and Thinking level "Selected High Extra thorough"; Thinking level was changed from Low to High before sending). Ran 3:13-3:22 PM MDT (runtime measured). Fresh Gemini chat, already signed in as Ryan Bailey (rcbailey12@gmail.com), Pro; no new sign in was needed. Three files attached (leg_prompt_validation.md, evidence_pack_validation.md, opus-addendum-prompt.md). The response finished as one message covering sections 1-5, with no rate limit notice and no mid generation stall. Citation chips shown by the Gemini interface are interface elements, not model text, and are omitted. Model text follows verbatim.

---

1. Item Verdicts

1. Repo hygiene test suite (Item 1) - KEEP (before cutover, scoped down): Most of this script has no feel connection, but diffing hand-copied render and world constants against the JS oracle and verifying FEATURES.md claims directly stops silent visual scale drift and false completion claims on missing feel features. Build only the constant diff, RNG seed check, and feature-table verification before cutover, and push .pck and oracle hash assertions to before Steam.

2. Golden-image screenshot suite (Item 2) - KEEP (before cutover, sanity mode only): Using Godot's built-in Movie Maker mode and odiff directly protects ship quality by catching silent BoxMesh fallbacks, missing flagship geometry, and broken UI panels without wasting the owner's eye on broken builds. Keep it before cutover, but only fail on structural regressions (missing meshes, blank frames, broken UI) until after the big effects pass so strict pixel diffs do not freeze placeholder lighting and partial damage decals.

3. Generate gen/ in build, Git LFS inputs, provenance, and auto mesh LODs (Item 3) - REORDER (split: LOD distance testing and source asset tracking before cutover; build-time generator rewrite and model provenance before Steam): Testing auto mesh LOD distances and tracking .glb, .blend, .psd, and .wav source files directly protects capital-ship silhouette quality at Sins of a Solar Empire II zoom ranges. The model provenance file and build-pipeline rewrite have no feel connection and should move to before Steam so they do not delay a playable Godot battle.

4. Headless export as canonical build plus version stamping (Item 4) - REORDER (before Steam): This item has no connection to battle feel, ship quality, or fun; it is pure release packaging and executable metadata hygiene. Move it to before Steam where .pck export inspection already lives.

5. Save and settings hygiene (Item 5) - REORDER (before Steam): Splitting display settings and writing saves atomically has no battle feel connection, though it protects campaign playtest continuity once Steam Auto-Cloud is active. Move it to before Steam unless the owner is running multi-machine campaign tests during travel.

6. Scoped test-framework decision on GdUnit4 (Item 6) - DROP: Adopting GdUnit4 (exact v6.2.x compatibility claims with 4.7 are UNSURE without inspecting the release tag, though the action supports Godot 4.x) has no feel or fun connection, and maintaining a second test framework alongside the custom parity harness steals time from missing battle presentation. Stay homegrown and drive the 10 screenshot states with a simple scene script.

7. Music CREDITS.md schema and two-pass ffmpeg loudnorm (Item 7) - REORDER (keep loudnorm before cutover; move CREDITS.md to before Steam): The credits file has zero feel connection, while two-pass ffmpeg loudnorm normalization (-14 LUFS, -1 dBTP) directly protects audio feel by stopping new music tracks and weapon SFX from pumping or drowning each other out when the empty music bed is filled. Enforce the loudness script as audio assets land, and leave the licence markdown table for before Steam.

8. Exact-source Godot 4.7 API lookup and edit guard hooks (Item 8) - KEEP (before cutover): While it has no direct player-facing feel connection, stopping agents from hallucinating Godot 3 syntax into Godot 4.7 (as proven in Dan Malone's ai-gamedev-kit writeup) directly prevents broken tweens, shaders, and particle nodes when building the effects pass. It is cheap and speeds up all downstream visual work.

9. Plain-text verification-before-completion checklist (Item 9) - KEEP (before cutover): This has no direct feel connection, but pasting a plain-text rule into instructions costs almost nothing and stops the agent from marking feel features (like per-weapon damage marks or cut-ins) complete when they are only partial.

10. Path-scoped rules, /doctor prompt audits, worktree isolation, and Lychee (Item 10) - DROP (Lychee and /doctor) and REORDER (worktree isolation to later): None of these items connect to game feel or fun; they are agent workspace housekeeping and documentation link checks. Keep only path-scoped rules if they take five minutes, drop Lychee and /doctor, and delay worktree isolation until parallel agents actually collide.

11. gdlint gate and gdformat check mode (Item 11) - DROP: gdtoolkit has no connection to battle feel, ship quality, or fun, and policing style rules on hand-written shell scripts adds friction right when UI, camera, and effects code need fast iteration.

12. --single-threaded-scene differential run (Item 12) - REORDER (later): This is a threading diagnostic with no feel or fun connection unless battles actively desync. Run it only if a playtest or bot pass reveals non-deterministic scene behavior.

13. Scripted frame-budget benchmark at 20-ship carrier scale (Item 13) - KEEP (before cutover): Querying Godot's built-in Performance monitors on view() and ui_info() at 20-ship scale directly protects cinematic spectacle, because a turn-based tactics game loses Sins of a Solar Empire II presence if carrier fighter swarms and salvos stutter. Establish the baseline now so the upcoming big effects pass knows its GPU and CPU headroom.

14. GodotSteam, Auto-Cloud, butler, SteamPipe, and CI build-and-inspect (Item 14) - KEEP (before Steam): This item has no connection to in-game battle feel or fun, and belongs strictly before Steam as proposed (note when pulling GodotSteam that its GitHub repository archived on October 20, 2026 after moving primary hosting to Codeberg).

15. Localisation scaffolding and pseudolocalisation pass (Item 15) - REORDER (later): gettext PO/POT files and tr() wrappers have no feel or fun connection for an English-only build and add friction to writing Nemesis barks, onboarding tips, and officer descriptions. Keep only a simple long-string UI overflow test before Steam and push full localisation plumbing to post-launch unless translated SKUs are committed.

16. Audio-only cues routed as captions to the battle log (Item 16) - KEEP (before Steam, or pull into the audio pass): Routing off-screen weapon impacts, shield collapses, and system criticals into the existing battle log directly improves tactical readability and weight across a 20-ship board at very low cost.

17. Steam capsule checklist and codesigning evaluation (Item 17) - KEEP (before Steam): Store capsules and Windows installer signing have no connection to battle feel or fun and sit properly in the pre-Steam gate.

18. Editor or runtime MCP bridge (Item 18) - KEEP (later): This has no direct player feel connection, and third-party MCP servers carry heavy context overhead. Leave it for later behind its stated trigger, and if needed, prefer the tiny custom JSON TCP socket pattern from ai-gamedev-kit over bloated external plugins.

19. Aider-style generated repo map for GDScript (Item 19) - DROP (or later): This is pure agent token optimization for reading a 3,724-line rules file and has zero connection to battle feel, ship quality, or fun.

20. Godot 4.7 rendering features: AreaLight3D, DrawableTexture2D, Control offset transforms (Item 20) - REORDER (move from later to before Steam / immediately after cutover in the big effects pass): These three features directly buy ship quality and feel: DrawableTexture2D is the exact mechanism needed to upgrade the partial generic scorch decals into persistent per-weapon signature marks, AreaLight3D gives capital ships soft rectangular specular highlights instead of flat point-light dots, and Control offset transforms add snap to battle cut-ins and choice cards. Promote them out of "evaluate later" into the scheduled post-playable effects pass.

2. What Is Missing for Cinematic Feel

Rank 1: Dynamic Action-Cam Director with Sequenced Salvos and Battle Cut-Ins

What it is: A camera state machine that transitions smoothly from the tactical board to low-angle, ship-relative framing during broadsides, torpedo launches, boarding actions, and rams, paired with the missing officer/Nemesis battle cut-ins, staggered weapon firing (rippling turret shots over 1.2 to 1.8 seconds instead of firing on the same frame), and an intensity slider so players can tune camera takeover frequency. (How much camera interpolation already exists in the unattached Godot shell is UNSURE, but cut-ins are confirmed missing.)

Reference benchmark: BattleTech (2018) and Star Wars capital-ship broadsides (Rogue One Battle of Scarif, Revenge of the Sith opening over Coruscant). BattleTech sells heavy turn-based weight by cutting close to the firing chassis during salvo resolution while giving players 13 dedicated camera and pacing toggles (such as Zoom Type and Show UI During Attacks) so the spectacle never wears out its welcome (Pixel Judge review). Warhammer 40,000: Rogue Trader reinforces this by tying officer posts to distinct phase activations and visual callouts.

Effort shape: Medium.

Gate: Before cutover (battle cut-ins are already on the missing Godot checklist, and without dynamic salvo framing a 3D turn-based battle plays like a flat tabletop grid).

Rank 2: Distance-Scaled Combat Audio Bed, Layered Shield/Armor/Hull Impacts, and Critical Klaxons

What it is: Finishing the partial ambient audio bed and empty music plumbing with three concrete layers: (a) camera-distance audio scaling (deep reactor hums and metallic hull groans when zoomed in; radio static and distant booms when zoomed out), (b) distinct acoustic impact signatures for shields (high-frequency electric snap), armor (heavy kinetic thud), and hull/system crits (decompressing air and interior warning sirens), and (c) adaptive music stingers triggered by flagship turns, Nemesis arrivals, and ship kills.

Reference benchmark: EVE Online and BattleTech (2018). EVE Online creates famous high-consequence tension in slow tactical combat through its layered shield/armor/hull warning klaxons (TV Tropes Critical Annoyance) and spatial transition audio (CCP Odyssey Audio Dev Blog). BattleTech pairs Jon Everist's score with six separate volume sliders and constant pilot radio chatter to make turn-based damage feel visceral (Chalgyr's Game Room review).

Effort shape: Medium.

Gate: Before cutover for the ambient bed, impact layering, and initial music tracks (since both are on the missing Godot checklist); full adaptive stinger polish before Steam.

Rank 3: Per-Weapon Persistent Hull Scars, Class-Scaled Hull Fires, and Multi-Stage Ship Deaths

What it is: Completing the partial damage-marks reference using Godot 4.7's DrawableTexture2D so battery fire bakes into a persistent scorch layer, each weapon family leaves its own scar, and rams/torpedoes carve silhouette-breaking hull chunks, combined with progressive hull fires and a 2-second multi-stage destruction sequence (internal secondary pops obeying the 3-flashes-per-rolling-second cap, reactor vent, listing drift, and persistent floating hulk).

Reference benchmark: EVE Online. In August 2025, CCP introduced EVE's "Smoke, Fire & Smart Lights" overhaul specifically so fleet commanders can read ship scale and hull damage without looking at UI bars - scaling from 1 large fire on a frigate to 2-3 on cruisers/battleships and up to 7 localized fires plus flickering Smart-Light-Sets on capitals (EVE Online Smoke, Fire & Smart Lights Dev Blog).

Effort shape: Medium to Large.

Gate: Before Steam (as the centerpiece of the scheduled post-playable big effects pass).

Rank 4: Live Turret Tracking, Point-Defense Tracer Streams, and Physicalized Board Torpedoes

What it is: Eliminating the "frozen chess piece" look between activations by having ship turrets physically pitch and yaw toward targets inside their firing arcs during movement previews, firing continuous point-defense tracer streams and light-blue plasma bursts at incoming ordnance, and rendering multi-turn torpedoes as physical board entities with exhaust trails, proximity pips, and interception explosions.

Reference benchmark: Sins of a Solar Empire II and Warhammer 40,000: Rogue Trader. Sins II sells fleet scale by simulating individual turret pitch and tracking speeds alongside physical missiles that ships can body-block or shoot down with point defense (Sins II Steam page). Rogue Trader turns torpedo salvos into independent turn-based board threats that force evasive turns or point-defense interception on following rounds (Rogue Trader Space Combat Wiki).

Effort shape: Medium.

Gate: Before Steam (with visible torpedo board tokens and firing-arc previews before cutover).

Rank 5: Hyperspace Fleet Arrival, Nemesis Scar Showcase Intro, and Post-Battle Holographic Debrief

What it is: Framing every battle with a 3-second hyperspace jump-in where fleets decelerate into formation, a dedicated camera close-up and voice/text callout when the Nemesis arrives (highlighting the physical hull scars and counter-weapons earned from prior clashes), and a post-battle holographic debrief summarizing hull losses, criticals inflicted, and salvage.

Reference benchmark: Star Wars films (Rebel fleet arrival over Scarif in Rogue One) and Star Wars Zero Company (2026). Bit Reactor's Star Wars Zero Company elevates turn-based tactics by wrapping grid combat in high-budget Star Wars briefing tables, character bonds, and persistent campaign consequences that carry visibly from mission to mission (Star Wars Zero Company on Steam).

Effort shape: Small for warp-in tween and Nemesis intro bark hook; Medium for showcase battles and debrief screen.

Gate: Basic warp-in tween and Nemesis intro camera pan before cutover; title/map showcase battles and post-battle debrief before Steam.

3. What Is Missing for Fun and Balance

Rank 1: Turn-Pacing, Mop-Up Drag, and Decision-Density Telemetry

What gets measured and what decision it changes: Extend the 19,500-battle simulation runner and human playtest logs to record three fun metrics beyond win rates: (a) Mop-Up Drag (the number of rounds between when one side loses 50% of its fleet power and when the last ship dies), (b) No-Brainer Activation Rate (the share of ship turns where only one valid move/target existed inside firing arcs or no officer post was usable), and (c) Verb Share (how often boarding, ramming, torpedoes, and temporary criticals decide a kill versus basic battery attrition). If Mop-Up Drag exceeds 3 rounds in 20-ship late-sector fights, add an enemy rout/warp-out mechanic; if No-Brainer Activations climb above 40% as ship count scales, cap fleet size and buff officer abilities to honor the project's decision-weight rule; if boarding or ramming sits under 5% share, retune its range or cooldown.

Reference benchmark: Warhammer 40,000: Rogue Trader, which keeps turn-based space combat brisk by giving every officer post cooldown-driven active verbs and having damaged pirate vessels attempt to flee rather than forcing tedious cleanup turns (Rogue Trader Space Combat Wiki).

Effort shape: Small (counters added to the existing simulation harness and playtest log).

Gate: Before cutover.

Rank 2: Pre-Battle Admiral Doctrine & Threat Telegraph Card (Surfacing the Hidden Difficulty Variable)

What gets measured and what decision it changes: Enemy admirals currently act as a hidden difficulty variable that swung sector 1 win rates from 57% to 89% and boss win rates from 38% to 98%. Add a pre-battle Admiral Intel card on the map node and ship sheet showing the enemy admiral's doctrine (e.g., torpedo saturation, ramming, shield disruption) and a computed matchup threat rating against the player's current fleet, while logging Human Hull Attrition vs. Bot Expected Attrition per Admiral in playtests. This changes the player's pre-battle deployment and facing decisions on turn 1, and tells the designer whether an 89%-win-rate admiral is fair once telegraphed or still requires a stat nerf.

Reference benchmark: Star Wars Zero Company (2026) and BattleTech (2018), both of which surface enemy capabilities and mission threat ratings before deployment so high difficulty spikes feel like tactical stakes rather than blind ambushes (Star Wars Zero Company on Steam).

Effort shape: Small (UI panel reading existing admiral data, paired with finishing the partial ship sheet).

Gate: Before cutover.

Rank 3: Live In-Game "Feel & Pacing" Tuning Overlay (F10 Inspector Drawer)

What gets measured and what decision it changes: A hot-reloadable debug overlay for the owner's playtests exposing live sliders for non-rules feel parameters: camera cut hold duration, delay between turret shots in a salvo, ship movement speed, screen-shake/hit-stop strength, decal opacity, and audio ducking, with a one-click export to feel_config.json plus telemetry logging which speed settings the owner actually plays on. If the owner consistently turns salvo delay or movement duration down after 3 battles, those faster timings become the new default without waiting on a code-edit cycle.

Reference benchmark: BattleTech (2018), which exposes granular camera and combat speed controls because turn-based pacing with 10 to 20 units requires constant balance between cinematic weight and player impatience (Pixel Judge review).

Effort shape: Small.

Gate: Before cutover (so the owner has live tuning controls during his playable Godot battle sign-off).

Rank 4: Outlier Battle Seed Bookmarks and Visual Turn Scrubber

What gets measured and what decision it changes: Have the 19,500-battle simulation automatically flag and save the seeds and command logs of the top 5 statistical outlier battles per run (fastest player wipe, longest round count, largest underdog upset, highest single-turn crit chain), and add a replay scrubber in Godot to step backward and forward through any saved battle turn-by-turn. Instead of guessing from win-rate tables why a boss admiral hits 98% or why a battle stalls, the owner can load the exact outlier seed in 10 seconds and see whether to fix spawn geometry, firing-arc dead zones, or temporary crit stacking.

Reference benchmark: Deterministic seeded lockstep replay as demonstrated in ai-gamedev-kit and tactical combat inspection in Sins of a Solar Empire II.

Effort shape: Medium.

Gate: Before Steam.

Rank 5: Nemesis Memory-to-Bark Coverage Auditor

What gets measured and what decision it changes: Because the Nemesis system tracks rich adaptation and scar memory in data but currently speaks through very few lines, add a script that cross-references every possible Nemesis memory/scar state against authored dialogue lines and logs Nemesis Bark Repeat Rate and Player Weapon-Switch Rate across simulated and human runs. This tells you exactly which tracked memories are mute (prioritizing where to write new barks) and whether the Nemesis counter-adaptation successfully encourages the player to diversify weapons or just punishes their favorite build.

Reference benchmark: Star Wars Zero Company (2026), where reactive character dialogue and campaign memory turn tactical skirmishes into a personal rivalry (Star Wars Zero Company on Steam).

Effort shape: Small.

Gate: Before Steam.

4. Risks

Risk 1: The Golden-Image Suite Freezing Placeholder Art and Lighting Too Early (Item 2)

The threat: The big effects pass has not happened yet, and weapon damage marks are only partial generic scorch decals. If Opus wires 10 strict pixel-diff goldens into odiff hooks now with manual blessing required for every visual change, every experiment with AreaLight3D, DrawableTexture2D damage scars, particle trails, or camera angles will break the test suite and create commit ceremony. That friction penalizes visual iteration right when the game needs its biggest visual leap.

Guardrail: Run Item 2 in Sanity & Contact-Sheet Mode until the big effects pass is complete: fail automated runs only on missing meshes (BoxMesh fallbacks), blank viewports, or UI text clipping, while auto-generating a 10-shot visual contact sheet for the owner's eye. Turn on strict odiff pixel-diff gating only after the owner blesses the post-effects look.

Risk 2: Harness and Hygiene Work Crowding Out the Missing Feel Checklist Before Cutover (Items 1, 3, 4, 6, 10, 11)

The threat: The Godot build is still missing battle cut-ins, title and map showcase battles, a finished ship sheet, the ambient audio bed, all music tracks, onboarding tip 10, and command strip help. Adopting all 13 pre-cutover and workflow items at once will burn pre-cutover engineering time on build scripts, test frameworks (GdUnit4), linters (gdlint), and repo plumbing while the playable battle arrives silent and flat.

Guardrail: Enforce a strict Pre-Cutover Tooling Cap: allow only Item 1 (scoped to constant diffs, seed check, and feature table verification), Item 2 (sanity capture), Item 7's loudnorm rule, Item 8 (API lookup), Item 9 (plain-text checklist), and Item 13 (performance baseline) before cutover. Require that every tooling task before cutover be paired with finishing at least one item from the missing feel checklist.

Risk 3: Committed Frame Monitors and Auto-LODs Capping Spectacle and Erasing Silhouette Damage (Items 3 and 13)

The threat: Item 3 adds auto mesh LODs and visibility ranges to ship meshes, and Item 13 commits Performance monitor numbers on every change at 20-ship scale. Aggressive auto-LODs can pop capital ships into low-poly shapes at tactical zoom and erase the silhouette-breaking geometry reserved for rams and torpedoes. Worse, if Opus is judged on committed frame-time diffs per commit, the agent will optimize for flat numbers by starving the game of dynamic lights, point-defense tracers, and multi-stage explosions during the effects pass.

Guardrail: Define Item 13 as a hard ceiling (e.g., 16.6 ms / 60 FPS minimum on target hardware during a 20-ship salvo) rather than a monotonic diff that penalizes adding VFX within budget, and require Item 3's LOD distances to be visually verified in Item 2 screenshots at close, medium, and far zoom on torpedo-scarred hulls before enabling them.

5. The One Thing

If the team adds one feel-or-fun item not in the addendum before cutover, build a 15-Second Scripted "Action-Cam Salvo & Cut-In" Movie Maker Slice backed by feel_config.json timing sliders. Specifically, wire the missing battle cut-in, a low-angle Action Camera cut, staggered turret firing, and layered shield/hull impact audio for one flagship salvo exchange, and use Godot's Movie Maker mode (--write-movie outputting PNGs + WAV audio muxed via ffmpeg) to render a 15-second video clip alongside the Item 2 still screenshots. Still PNGs can prove a ship mesh loaded, but they cannot prove that a battle feels like Star Wars, BattleTech, or Rogue Trader; a 15-second video with sound lets the owner judge camera weight, salvo rhythm, cut-ins, and audio during travel, while leaving behind the exact live timing sliders he needs when he sits down to play the cutover build himself.

Viewed strictly through the feel-and-fun lens, the addendum as written over-indexes on defensive engineering hygiene and under-serves the cinematic space battle game the owner actually wants to play, because it schedules 13 harness, build, and linter tasks before cutover while leaving essential feel drivers like Godot 4.7's DrawableTexture2D damage marks and AreaLight3D ship lighting in the "evaluate later" bucket. The core core of the addendum - Item 1's constant/feature drift guard, Item 2's screenshot capture, Item 8's Godot 4.7 API lookup, and Item 13's 20-ship performance baseline - genuinely protects visual quality and agent speed, and should be kept. The single change I would insist on is inverting the pre-cutover priority: strip Items 4, 5, 6, 10, 11, 12, and the build-rewrite half of Item 3 out of the pre-cutover gate, promote Item 20 (DrawableTexture2D, AreaLight3D, Control offset transforms) into the immediate post-cutover effects pass, and gate cutover on a 15-second Movie Maker combat video with cut-ins and audio rather than on build-pipeline perfection.
