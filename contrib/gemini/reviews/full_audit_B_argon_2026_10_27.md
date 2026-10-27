# Blind audit leg: full catch-up audit, Audit B (Godot port and travel sprint), Argon leg

Filed by the chair from the model's verbatim answer. Model: Gemini 4 Argon, thinking level High, verified in two places by the running agent (prompt bar picker and menu both read Argon High). Fresh chat, signed in as rcbailey12@gmail.com. Run Oct 27, 2026; message sent about 09:48 PDT, answer complete by 09:59 PDT. Pinned main HEAD at leg start: 172f019e7f8b9eba60e8c3947ffbac5e82885c43.

Attachments (all 9 granted files attached, none dropped): leg_prompt_B.md, evidence_pack_B.md, corsair_lineup.webp, C13s_23_sweep_painted.webp, after_m1_map.webp, after_m3_zoom.webp, 03_dead_star_board_r10.jpg, 05_frigate_marks_at_battle_camera.jpg, s9_dreadnought_strip.jpg. Note: voidsworn_lineup.webp and the V-series sweeps were not part of this leg's attachments; the model marks them NOT CHECKED itself.

Method notes and screening live outside this file. The text below is the model's answer, verbatim.

---

1. G1 rules port

Verification of the claimed parity record

Backed by documents and listings: HANDOFF.md section 0, FINDINGS G-12, contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md, and godot/rules/test/README.md (10,591 bytes) back the core port files in godot/rules/rules.gd (209,559 bytes), godot/rules/battle_api.gd (44,820 bytes), godot/rules/jsm.gd (30,367 bytes), godot/rules/API.md (21,699 bytes), godot/rules/test/scenarios.json (32,618 bytes), and godot/rules/test/parity_main.gd (10,279 bytes). The documents record 43 of 43 golden battles passing on PC lane B at commit 61c57fa (g1_lb_parity_61c57fa), 47 of 47 golden battles passing in the cloud at commit 48638ef, 316,090 maths values with 0 differences (including 26,030 sin and cos inputs above 2^19 pi), and 30 of 30 campaign parity runs passing.

Problem 1.1 [FIX] The 1,500 random-battle count spans different commits and double-counts seed 4 in its narrative: In contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md (section Running sweep record), the summary states: "Seeds 1, 2, 3 and 4 on the PC, seed 4 again and seeds 5, 6 and 7 in the cloud: 1,500 different random battles, 273,265 records, 0 differences". The same README states under g1_lb_sweep_61c57fa that PC seed 4 (200 battles, 33,500 records) is "the same battles and the same record count as the cloud run of seed 4". Summing the reported records across the named runs (33,500 for cloud seed 4 at 61c57fa, 33,500 for PC seed 4 at 61c57fa, 36,163 for cloud seed 5 at 02f23da, 37,913 for cloud seed 6 at 48638ef, 54,785 for cloud seed 7 at 48638ef, and 36,606 for PC seed 3 at 2b91ea4) already gives 1,300 battle runs and 232,467 records across four different commits, leaving only 200 battles (40,798 records) for seeds 1 and 2 combined. Only 500 random battles (seeds 6 and 7) were run at the latest cloud commit 48638ef, and only 200 (seed 4) on the PC at 61c57fa.

Problem 1.2 [FIX] PC lane B parity lags behind the cloud golden suite (43/43 vs 47/47): HANDOFF.md section 0 and FINDINGS G-12 report 43/43 golden battles from PC lane B at commit 61c57fa, whereas contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md (Later cloud checks) and godot/rules/test/README.md (10,591 bytes) show that scenarios s44 to s46 (Stream B step 6 arc hulls at 02f23da) and s47 (compact field B0small at 48638ef) were only verified in the cloud, not on the PC.

Problem 1.3 [FIX] PC enemy think-time bar (0.5 s) was exceeded in g1_lb_parity_1027e and cloud runs hit SIGTERM: While FINDINGS G-12 cites the 0.406 s worst think time from 61c57fa, contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md (g1_lb_parity_1027e at 2b91ea4) shows battle s4 hitting 0.585 s in round 2 (missing the 0.5 s bar). The same README notes that in the cloud run at 61c57fa, s32 and thread_test.gd were killed by an external SIGTERM because multiple streams run Godot inside the same 2-CPU container.

Ways the parity test could pass while being wrong

Problem 1.4 [FIX] Pinned oracle drift (godot/rules/test/oracle/ vs live Stream B JS files): Per Go-forward plan section 4 and godot/rules/test/README.md (10,591 bytes), node/golden.js runs against a pinned copy of data.js, core.js, and battle.js inside godot/rules/test/oracle/ (at 61c57fa, battle.js and core.js were pinned at d8b47c6 and data.js at 6b1571e, while HEAD is 172f019e7f8b9eba60e8c3947ffbac5e82885c43). If Stream B edits the live root JS files and G1 has not yet re-pinned godot/rules/test/oracle/, the parity suite passes with 0 differences against the stale snapshot while diverging from the current JS rules.

Problem 1.5 [FIX] One-way table scanner in node/export_data.js: godot/rules/test/README.md (10,591 bytes) states that node/export_data.js scans godot/rules/*.gd for TB.NAME, TB["NAME"], and TB.get("NAME") to verify that requested tables exist in godot/rules/data/tables.json. If Stream B adds a new table or rule table key in data.js, core.js, or battle.js that godot/rules/*.gd has not yet referenced, the scanner will not fail because godot/rules/*.gd never queries TB for it.

Problem 1.6 [NOTE] Self-referential thread check for UI/helper calls and narrow scenario subset: In godot/rules/test/README.md (10,591 bytes), thread_test.gd runs only on s4 and s23 while the main thread calls view, ui_info, threat_map, compute_reach, and preview_fire, checking that multi-threaded GDScript ends identical to single-threaded GDScript. Except for threat_map (which is checked against JS on s4, s19, and s23), view, ui_info, compute_reach, and preview_fire are only compared against GDScript itself, not against the JS oracle. Additionally, in contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md, 11 of 200 battles in seed 4 and 18 of 200 battles in seed 3 ended with "no result", meaning those runs hit a step/round cap without testing end-of-battle resolution.

JS rules areas with no Godot counterpart in the listings

Problem 1.7 [FIX] Unlisted godot/campaign/ files and JS-only helpers: FINDINGS G-12 states that "non-rule tooltip helpers and G3-owned encounter rolls remain JS-only" with respect to godot/rules/. Within godot/rules/, there are no separate core.gd or data.gd scripts because node/export_data.js flattens tables from data.js, core.js, and battle.js into godot/rules/data/tables.json (size unlisted under data/ dir), math lives in godot/rules/jsm.gd (30,367 bytes), and battle logic lives in godot/rules/rules.gd (209,559 bytes) and godot/rules/battle_api.gd (44,820 bytes). However, the G3 counterpart for campaign_run.js, campaign_meta.js, and encounter rolls (godot/campaign/, assigned to G3 in Go-forward plan section 4) is completely absent from the repo listings in evidence_pack_B.md (UNSURE of file names and byte sizes on disk).

2. G2 whole game

Coherence of the claimed flow across FEATURES.md, HANDOFF.md, and the plan table

Problem 2.1 [BLOCKER] godot/main/FEATURES.md (10,493 bytes) marks all 13 non-battle campaign screens as fallback (no map picture) despite G3 claiming the campaign map is DONE: In godot/main/FEATURES.md (10,493 bytes, updated Oct 26 evening), the Campaign screens table lists Rules (G3) as done, but the Drawn column marks Sector map, node info, node modifiers as fallback (no map picture) and marks all 12 other campaign screens (Admiral/faction pick, Aspect pick, Intro briefing, Fleet screen, Shipyard, Drydock, Events, Victory/prize screen, Sector change, Progression, How to play, Run end) as fallback. The repo listing for godot/main/ still includes campaign_fallback_ui.gd alongside campaign_host.gd (14,032 bytes) and main.gd (19,355 bytes). Either godot/main/ is still wired to the fallback UI instead of G3's star-system map, or godot/main/FEATURES.md (10,493 bytes) is out of sync with the actual integration.

Problem 2.2 [BLOCKER] The Windows .exe export has not been smoke-tested: HANDOFF.md section 0 and the Go-forward plan status table row G2 state that the Windows build is built/done, but godot/main/FEATURES.md (10,493 bytes, row Windows build (.exe)) explicitly states: exe smoke test pending. If build\export\Voidsworn.exe (launched by tools/pc/play_godot.bat) fails on launch due to missing packed resources or paths, the owner cannot test the Windows build on return.

Problem 2.3 [FIX] Bot run failure rate (2 of 36 unclean runs) is omitted from the plan table: HANDOFF.md section 0 reports: Bot runs: 100 smart runs with 0 hangs, then 36 runs across all six factions, 34 of them clean. That means 2 of the 36 faction runs failed or logged errors, whereas the Go-forward plan status table row G2 cites only smart bot 100 runs 0 hangs and Go-forward plan section 4 (Sprint goal (R35)) requires a bot that has played many full runs with 0 errors.

Problem 2.4 [FIX] Disagreement between worst round under 15 s (HANDOFF.md) and 13.4 s mean (FEATURES.md): HANDOFF.md section 0 claims every battle's worst round is under 15 s and the plan status table claims pace under 15 s per round. However, godot/main/FEATURES.md (10,493 bytes, row Enemy turns at B2 pace) states that a 20-ship sector 3 fight measured 30.1 s mean, now 13.4 s. Because 13.4 s is the mean round duration across the battle, the worst round in a 20-ship battle is either above 15 s or unstated in FEATURES.md.

Problem 2.5 [FIX] Disagreement on ship movement status (done in FEATURES.md vs IN PROGRESS in HANDOFF.md and the plan table): godot/main/FEATURES.md (10,493 bytes) marks Ship movement with weight (R50) as done, while HANDOFF.md section 0 and the plan status table row G2 mark R54 thruster-true movement (R54: main drive on the hull axis, RCS turns and sidesteps, trails from real nozzles) as IN PROGRESS.

Judgement of the movement approach from s9_dreadnought_strip.jpg

Visual check of s9_dreadnought_strip.jpg: The image compares Before (Brisk) (top row) and After (Cinematic) (bottom row) at 0.30s, 0.80s, 1.30s, and 2.00s as a Voidsworn dreadnought moves from the upper-left hex into the lower-right hex and rotates from facing South-East to facing East.

Problem 2.6 [FIX] Main rear engines stay at full burn while stationary and rotating in the destination hex (s9_dreadnought_strip.jpg): In s9_dreadnought_strip.jpg, by 0.80s, 1.30s, and 2.00s the dreadnought is already inside its target hex and is only rotating/settling in place (with a bluish-white RCS puff firing from the stern quarter at 1.30s and 2.00s), yet the two bright orange main rear engine plumes remain fully flared at 0.80s, 1.30s, and 2.00s in both Brisk and Cinematic strips. The R54 design approach (main drive on the hull axis, RCS turns and sidesteps, trails from real nozzles in HANDOFF.md section 0) is physically sound only if the main axial drive cuts off once forward translation ends, leaving in-place turns, braking, and sidesteps strictly to RCS thrusters.

Items the plan says should exist that no document or listing backs up

Problem 2.7 [FIX] G2 folders and files absent from the repo listings: Go-forward plan section 4 assigns godot/scenes/battle/, godot/render/, godot/ui/battle/, godot/audio/, and project.godot to G2, HANDOFF.md section 0 names brand.gd, and godot/main/FEATURES.md (10,493 bytes) names godot/audio/build/render_ambient_bed.py, tools/pc/play_godot.bat, tools/pc/play_godot_safe.bat, and build/export/Voidsworn.exe. None of those folders or files appear in the Repo listings at leg start section of evidence_pack_B.md (only godot/main/ and docs/shots/g2/ are listed; UNSURE of their sizes/presence on disk).

Problem 2.8 [NOTE] Browser features intentionally dropped in godot/main/FEATURES.md (10,493 bytes): FEATURES.md notes two browser features not carried over to Godot: the Concept-art hulls toggle (marked not carried over (vetoable)) and the enemy reach line on the ship stat sheet (Left out: the enemy reach line (it needs a threat pass per hover; R shows the threat map)).

3. G3 campaign

Visual judgement of the rebuilt campaign map (after_m1_map.jpg and after_m3_zoom.jpg)

What reads as a Sins 2 style star system: In both after_m1_map.jpg and after_m3_zoom.jpg, the Hollow Sun (black hole with a bright orange-white accretion disc, lensing arch, and particle ring) dominates the centre of the sector, surrounded by concentric blue orbital rings, glowing cyan and red jump lanes, and 3D stop meshes (ringed planets, asteroid belt clusters, skeletal shipyard frame, and glowing blue flagship icon).

Problem 3.1 [FIX] Node labels and icons clip into HUD panels and overlap each other (after_m1_map.jpg, after_m3_zoom.jpg):

In after_m3_zoom.jpg (top right of the map viewport, directly against the FLEET COMMAND sidebar), the Decapitation / NEMESIS / DEADLY / colossus... stop and its text are clipped off by the right sidebar border.

In after_m3_zoom.jpg (top centre), the Decapitation / EVEN / split lanes / Relic stop label sits directly behind the translucent PATRONS WATCHING top bar box.

In after_m3_zoom.jpg (upper right of the Hollow Sun, on the red planet Engagement / NEMESIS / DEADLY), the red diamond and text Unknown signal sit right on top of the red planet surface and collide with the PLANET ORBIT curve label above it, while five stacked lines of sub-labels (Engagement, NEMESIS, DEADLY, archipelago - bounty, Credits) clutter the planet.

In after_m1_map.jpg, the Unknown signal diamond sits directly on the jump lane just above Engagement / NEMESIS / DEADLY, making it look attached to the Engagement stop rather than a distinct node.

Problem 3.2 [NOTE] Repetitive ASTEROID BELT headers and flat 2D diamond badges (after_m3_zoom.jpg): In after_m3_zoom.jpg, four separate stops on the left all repeat the same grey all-caps ASTEROID BELT label above large neon-green 2D diamond outlines (Decapitation, Hunt, Relay, Engagement), which reads as HUD clutter over the 3D asteroid clusters.

Problem 3.3 [FIX] Duplicate strings and wall-of-text clutter in the right NEMESIS sidebar (after_m1_map.jpg, after_m3_zoom.jpg): In the right sidebar of both after_m1_map.jpg and after_m3_zoom.jpg:

The admiral line reads Admiral: Admiral Castellan Vex, line of battle (duplicating Admiral: Admiral).

The bottom line of the NEMESIS block reads Weaknesses: unknown (win against him to learn it) unknown (win against him to learn it) (printing unknown (win against him to learn it) twice in a row with no separator).

The NEMESIS section contains six dense paragraphs of tiny prose, and the bottom-left legend lines (Battle a fight... and Danger against your fleet now...) run across the bright orbital rings with low contrast.

Evidence gaps on G3 campaign parity

Problem 3.4 [FIX] No test specification, README, or repo file listing backs the 30 of 30 campaign parity claim: HANDOFF.md section 0 claims Campaign parity is green and contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md includes a single table line: G3 campaign parity | 30 of 30 runs PASS. Unlike G1 battle parity, godot/rules/test/README.md (10,591 bytes) does not mention campaign parity at all under What it checks, and evidence_pack_B.md contains no README or file listing for godot/campaign/, godot/ui/campaign/, or godot/scenes/campaign/ (only docs/shots/g3_campaign/8a12941/ is listed). Which campaign actions, shop/reward rolls, save states, or meta-progression fields are compared in those 30 runs is completely undocumented in the pack (UNSURE).

4. G4 effects and world

Visual judgement from 03_dead_star_board_r10.jpg and 05_frigate_marks_at_battle_camera.jpg

Problem 4.1 [FIX] Black-hole lensing seam/step artifact and blown-out white ships in 03_dead_star_board_r10.jpg:

In 03_dead_star_board_r10.jpg (upper left), the gravitational lensing arch over the top of the black hole has a sharp vertical step/discontinuity right at top-dead-centre where the left half of the glowing orange arch is taller than the right half, surrounded by a faintly visible circular bounding ring against the starfield.

In 03_dead_star_board_r10.jpg (middle column), both the top-middle fan-shaped Ithar ship and the bottom-middle Hegemony ship are rendered in blown-out, chalky flat white with almost no material tonal separation, and green thruster/shield glow smears horizontally across the top row of ships.

Problem 4.2 [FIX] Half of the per-weapon hull marks are unreadable at battle camera distance, especially by 9 seconds (05_frigate_marks_at_battle_camera.jpg):

In 05_frigate_marks_at_battle_camera.jpg (10 weapon rows showing clean | 1 s after the hit | 9 s after on a Voidsworn frigate at battle camera with pixels x2), lance burn, gauss entry, and boarding hatch read clearly at 1 s via bright orange glow, and plasma crater shows a small blue spot at 1 s.

However, flak pocks, acid spines, ion burn, and ram crumple are nearly invisible at both 1 s and 9 s against the dark hull (the 1 s and 9 s frames look almost identical to the clean frame).

By 9 s after (right column), once the initial glow cools, plasma crater, shell crater, flak pocks, acid spines, ion burn, and ram crumple leave no readable lasting scar at battle camera distance. (HANDOFF.md section 0 marks flak readability, lasting scars, and the Jolt convex-hull guard as IN PROGRESS.)

Furthermore, godot/main/FEATURES.md (10,493 bytes, row Reduce flashing (WCAG)) notes that Compatibility mode (play_godot_safe.bat) draws no hull damage marks yet (G4: decals are off there).

Data-driven vs hard-coded look (godot/fx/faction_looks.json vs godot/fx/*.gd)

Problem 4.3 [FIX] Effect parameters are heavily hard-coded in ~305 KB of GDScript rather than godot/fx/faction_looks.json (2,397 bytes):

In the godot/fx/ repo listing, faction_looks.json is only 2,397 bytes, whereas fx_shaders.gd is 68,563 bytes, fx_breach.gd is 61,751 bytes, fx_weapons.gd is 50,757 bytes, fx_ship.gd is 50,044 bytes, fx_death.gd is 34,657 bytes, fx.gd is 29,804 bytes, and fx_hull.gd is 9,899 bytes.

Inside godot/fx/faction_looks.json (2,397 bytes), "accent": null and "shield_edge": null are null for all six factions, and five of the six factions (voidsworn, hegemony, corsair, ithar, deathless) share the exact same orange "damage_glow": [1.0, 0.45, 0.12] despite having blue, mint-cyan, or green faction palettes.

Integer enums ("shield_style": 0..3, "trail": 0..3) and string tags ("engine_extra": "none" | "soot" | "spores" | "embers") in godot/fx/faction_looks.json (2,397 bytes) rely on hard-coded branches in godot/fx/*.gd for all shader uniforms, geometry, and per-weapon mark behaviour.

Performance risk at about 20 ships on screen

Problem 4.4 [FIX] Overlapping active G4 effects and unguarded convex-hull wreck physics in 20-ship fights:

godot/main/FEATURES.md (10,493 bytes, row Enemy turns at B2 pace) documents that G4 volleys initially pushed a 20-ship sector 3 fight to 30.1 s mean per round, and that G2 fixed the turn wait by advancing to the next ship's turn "while the effect plays on". Because effects continue playing while subsequent ships move and fire, a 20-ship battle now overlaps multiple concurrent weapon volleys (fx_weapons.gd, 50,757 bytes), breach decals (fx_breach.gd, 61,751 bytes), real-hull wreck splits (fx_death.gd, 34,657 bytes), and custom shaders (fx_shaders.gd, 68,563 bytes).

In addition, HANDOFF.md section 0 lists the Jolt convex-hull guard as still IN PROGRESS, leaving real-hull wreck generation vulnerable to physics stalls when multiple ships die in a 20-ship fight.

Owner ruling: shields must keep faction colours

Problem 4.5 [FIX] chorus and deathless have "shield": null in godot/fx/faction_looks.json (2,397 bytes):

voidsworn ([1.0, 0.46, 0.16]), hegemony ([0.38, 0.68, 1.0]), corsair ([0.85, 0.16, 0.10]), and ithar ([0.72, 1.0, 0.86]) have distinct faction shield colours in godot/fx/faction_looks.json (2,397 bytes).

However, chorus and deathless both have "shield": null (and "shielded": false), and all six factions have "shield_edge": null in godot/fx/faction_looks.json (2,397 bytes). If a chorus or deathless ship acquires shields through a campaign module, boon, relic, or event in play, faction_looks.json provides no faction shield colour for them.

5. A4 ships

Missing image note: evidence_pack_B.md lists voidsworn_lineup.webp under Attached images and lists V14, V15, V16, V17, V18, V1b sweeps under docs/shots/a4/46a89fe/, but voidsworn_lineup.webp and the individual sweeps for C14s, C15s, C16s, V14, V15, V16, V17, V18, V1b were NOT attached to this review leg. Per the leg prompt rule, the Voidsworn lineup (voidsworn_lineup.webp, V14 to V1b close-ups and sweeps) and the individual painted sweeps for C14s, C15s, C16s are marked NOT CHECKED. Every ship visible in the attached images (corsair_lineup.webp, C13s_23_sweep_painted.webp, and 03_dead_star_board_r10.jpg) is checked below against the CLAUDE.md ship rules:

Ship 5 Warlord's Pyre-Barge (C19_51) in corsair_lineup.webp and bottom-right of 03_dead_star_board_r10.jpg [FIX]:

Naval tells (CLAUDE.md rules): Violates the hull shape and mast rules (no boat keels or raked stems... Crossbar masts and smokestack funnels count as naval tells... This covers the whole hull shape). It has a naval raked boat bow, a flat boat deck line, a central naval conning tower with glowing bridge window slits, and a tall vertical mast with a horizontal crossbar yardarm on top of the bridge. (HANDOFF.md section 0 notes IN PROGRESS: the Pyre-Barge redesign to match C13s to C16s (R54).)

Ship 4 Hulk-carrier (C16s_23) in corsair_lineup.webp [FIX]:

Naval tells (CLAUDE.md rules): Has upright cylindrical smokestack funnels on the midship superstructure beside the elevated gun turret.

Blobs and bolt-ons (CLAUDE.md rules): The bow and upper forward shoulders are covered in lumpy, melted AI blobs rather than crisp mechanical plating, and a spindly grey grabber claw hangs under the chin on a thin L-bracket.

Ship 3 Marauder-class cruiser (C15s_23) in corsair_lineup.webp [FIX]:

Naval tells (CLAUDE.md rules): Features two vertical cylindrical orange-rimmed smokestack funnels right behind the midship bridge block, plus a horizontal waterline-style row of lit portholes/windows along the mid-hull side above the blue stripe.

Blobs and bolt-ons (CLAUDE.md rules): Retaining rounded AI blobs along the aft-midship spine and the exact same copy-pasted ventral chin claw as C16s_23.

Ship 2 Reaver-class destroyer (C14s_23) in corsair_lineup.webp [FIX]:

Blobs and sunk parts (CLAUDE.md rules): Heavy, melted brown AI blobs across the bow and midship flanks; the forward-aimed torpedo/gun tubes on the upper bow are sunk into blobby brown mesh lumps rather than sitting on clean mechanical mounts, and the same copy-pasted ventral claw hangs below the bow.

Ship 1 Raider-class frigate (C13s_23) in corsair_lineup.webp and C13s_23_sweep_painted.webp [FIX]:

Naval tells (CLAUDE.md rules): Upright cylindrical smokestack pipes/funnels rise immediately behind the red dorsal twin-gun turret (visible in corsair_lineup.webp and mid side / mid top of C13s_23_sweep_painted.webp).

Blobs and floating/jagged stern fins (CLAUDE.md rules): In C13s_23_sweep_painted.webp (bow top, mid top, mid side), flat rectangular armor patches are pasted over underlying AI mesh that is still visibly blobby on the nose cone and midship sides. In stern side of C13s_23_sweep_painted.webp, the upper and lower angled tail fins behind the main engine nozzle sit detached from the nozzle cone on thin struts with chewed-up, blobby mesh edges. (Its dorsal twin autocannon turret is aimed forward cleanly with no backward guns.)

Other ships visible in 03_dead_star_board_r10.jpg [FIX]:

Bottom-middle white Hegemony capital ship (03_dead_star_board_r10.jpg): Severe naval tells (CLAUDE.md rules), including a boat-like battleship hull, flat deck, tiered WWII naval bridge tower amidships, and thin vertical masts. (HANDOFF.md section 0 notes the Hegemony naval hull reshape is IN PROGRESS.)

Bottom-left dark Voidsworn capital ship (03_dead_star_board_r10.jpg): Boat-shaped hull profile with a thin vertical mast rising from the aft-midship superstructure (HANDOFF.md section 0 notes the V17/V1b gothic peaks are IN PROGRESS).

Top-left pink Chorus ship (03_dead_star_board_r10.jpg): Reads as an unrefined pink lumpy blob with spires on top.

6. Stream B rules

What is evidenced in the pack vs what is unbacked

Evidenced in the pack (B0 and B2):

B0 baseline: Go-forward plan status table row B0 Ground truth cites Guard and check pack (0 FAIL). Mega sim: all legs exit 0, no exceptions; baseline in contrib/opus/compute/balance_reference.md; FINDINGS S1 to S7.

B2 browser pace and Sector 1 boss after-spread: Go-forward plan status table row B2 Faster, then bigger battles cites before-and-after browser round wait times (sector 3 21.8 to 8.0 s per round in the real browser), stability checks (fuzz 2000 0 exceptions (S9), check pack 0 FAIL, b1_tests 39 ok), and the post-fix Sector 1 boss win-rate spread (Sector 1 boss spread now 57 to 89% (S6 fixed: Mending, Voice, Vesh start fleets trimmed, Kassar guns 5% lighter)). Note that the pre-fix (before) Sector 1 boss spread from S6 is not given in the table, only the after spread (57 to 89%).

G1 functional parity on Stream B steps 1 to 6: godot/rules/test/README.md (10,591 bytes) proves that GDScript matches JS deterministically on single seeded battles for Stream B steps 1 to 3 (s24 to s31), step 4 Nemesis (s35 to s40), step 5 admiral band (s42, s43, s15, s28), step 5b (s6, s7, s9, s12, s16, s21, s23, s24, s30, s31), and step 6 arc hulls (s44 to s46).

Problem 6.1 [FIX] Stream B steps 5, 5b, and 6 (admiral band, faction tune, new start fleets, and R41 arc hull sidegrades) have NO before-and-after balance sim results in the pack:

HANDOFF.md section 0 explicitly states: Stream B rules: admiral band and faction tune; the PC confirmation set is running.

Consequently, none of the latest balance adjustments described in godot/rules/test/README.md (10,591 bytes) have before-and-after win-rate spreads in evidence_pack_B.md: Reyes (squadrons +10% with strike group and Command), the Matriarch (brood and two drones), Mending Choir and Nekhet regrowth (6% to 4%), the new campaign start fleets, Malek (rear hits +35%), Ashgrove (squadrons +40%), or the six R41 arc hull variants (Gilded marauder, Jackal court guard, Sun-eater razorfiend, Archive wraithcarrier, lance penitent, interdictor variant).

In addition, godot/rules/test/README.md (10,591 bytes, under s42, s43) states: The new start fleets are campaign data (G3); no battle rule reads them. That means G1 battle goldens do not test the new start fleets at all, and their balance impact depends entirely on the unfinished PC confirmation sims.

7. Music and portraits

Music check (godot/music/CREDITS.md, 18,739 bytes)

Licence and credit completeness:

All 24 .ogg tracks in the summary table of godot/music/CREDITS.md (18,739 bytes) have a complete entry under ## Per track with Used for, Title, Author, Source page, Licence, Licence URL, Attribution text (exact), and Changes.

Sixteen tracks use CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/), four tracks use CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/: calm_tactical.ogg, calm_darktimes.ogg, hot_heat.ogg, fac_voidsworn.ogg), and four tracks use CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/: map_drone.ogg, sting_victory.ogg, sting_champion.ogg, sting_lose.ogg). Both CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/) and CC BY 3.0 / CC BY 4.0 (https://creativecommons.org/licenses/by/3.0/, https://creativecommons.org/licenses/by/4.0/) permit commercial Steam distribution and looping/level edits without NonCommercial (NC), NoDerivatives (ND), or ShareAlike (SA) restrictions.

Spot-check of three source links:

Because live external web search is disabled in this review environment, live remote page state is tagged UNSURE per the leg prompt rule; we audited the three source links below against their documented fields and Creative Commons licence URLs in godot/music/CREDITS.md (18,739 bytes):

https://opengameart.org/content/intense-percussions (used for calm_tactical.ogg, calm_darktimes.ogg, and hot_heat.ogg by NorthFantasyMusic, licensed under CC BY 3.0 at https://creativecommons.org/licenses/by/3.0/ with edit notice edited for looping and level; live external page state UNSURE).

https://opengameart.org/content/chapel-of-hate (used for fac_voidsworn.ogg by FoxSynergy, licensed under CC BY 3.0 at https://creativecommons.org/licenses/by/3.0/, matching the author credit notice "Please credit me as FoxSynergy."; live external page state UNSURE).

https://opengameart.org/content/fanfares (used for sting_victory.ogg, sting_champion.ogg, and sting_lose.ogg by Spring Spring / Spring/Spring Enterprises, offered on the page under CC-BY 4.0, CC-BY 3.0, CC-BY-SA 4.0 and CC-BY-SA 3.0 and selected under CC BY 4.0 at https://creativecommons.org/licenses/by/4.0/; live external page state UNSURE).

Problem 7.1 [FIX] fac_deathless.ogg is a third-party mashup of four tracks from two other authors without upstream source URLs in godot/music/CREDITS.md (18,739 bytes):

In godot/music/CREDITS.md (18,739 bytes), fac_deathless.ogg cites https://opengameart.org/content/claimed-by-the-void-new-factory-ai-fight-and-simulation-unknown-vitalezzz-vs-tricksntraps, which is a third-party remix by glitchart combining "Claimed by the Void" by vitalezzz and "new factory", "AI fight", and "Simulation unknown" by tricksntraps. CREDITS.md does not record the upstream OpenGameArt URLs for the original vitalezzz and tricksntraps uploads to prove each underlying stem is CC0 (upstream links missing/UNSURE).

Problem 7.2 [NOTE] Inconsistent attribution formatting on map_drone.ogg and raw node URL on boss_final.ogg in godot/music/CREDITS.md (18,739 bytes):

Under ### map_drone.ogg, the exact attribution text reads Dark Ambient Drone by Tsorthan Grove - CC BY 4.0 - https://opengameart.org/content/dark-ambient-drone (https://creativecommons.org/licenses/by/4.0/; edited for looping and level). which omits (loop) from the title field (Dark Ambient Drone (loop)), lacks quotes around the title, and formats the licence URL differently from all other CC BY tracks.

Under ### boss_final.ogg (The Final Battle by skrjablin), the source link is a raw Drupal node URL (https://opengameart.org/node/73591) rather than a canonical /content/ URL.

In the repo listings for godot/music/, tracks/ is shown only as tracks/ dir without listing the 24 .ogg files and byte sizes inside it (UNSURE from listing).

Portraits check

Problem 7.3 [FIX] Mismatch between HANDOFF.md, Go-forward plan section 4, and the godot/portraits/ repo listing:

HANDOFF.md section 0 claims: Portraits: 24 Nemesis portraits in game, and new-look prompts drafted. Painting is held for lore approval.

However, the repo listing for godot/portraits/ (README.md (10,950), index.json (21,749), portraits.gd, alts/, crests/, nemesis/, painted/, sheets/, test/ dirs) shows that a painted/ directory already exists on disk despite HANDOFF.md stating painting is held for lore approval.

Furthermore, because alts/, crests/, nemesis/, painted/, and sheets/ are listed only as directory names without file counts or byte sizes, and tools/portraits/ (assigned in Go-forward plan section 4) is omitted from the repo listings, the presence of all 24 portrait textures inside godot/portraits/nemesis/ cannot be confirmed from the directory listing alone (UNSURE, though godot/portraits/index.json at 21,749 bytes and the Scrap-baron Skarn Rot portrait visible in after_m1_map.jpg and after_m3_zoom.jpg confirm the index and at least one in-game Nemesis portrait).

8. Cross-stream

Folder ownership collisions and duplicated work

Problem 8.1 [FIX] godot/render/ ownership collision between G2 and G4: Go-forward plan section 4 assigns godot/render/ to G2 (G2 battle and the whole game (godot/scenes/battle/, godot/render/, godot/ui/battle/, godot/audio/, godot/main/, project.godot)), while simultaneously assigning godot/render/look.gd and the takeover of ported Babylon effects to G4 (G4 look (godot/fx/, godot/world/, godot/render/look.gd)).

Problem 8.2 [FIX] Ship trails and RCS puffs split between G2 and G4: HANDOFF.md section 0 assigns R54 thruster-true movement (R54: main drive on the hull axis, RCS turns and sidesteps, trails from real nozzles) to G2, whereas Go-forward plan section 4 assigns engine trails to G4 (godot/fx/fx_ship.gd, 50,044 bytes), and godot/main/FEATURES.md (10,493 bytes) states RCS puffs drawn by the scene in G4's puff colour. Both streams are modifying engine trail and thruster visuals concurrently.

Problem 8.3 [FIX] Campaign UI duplication between G2 (godot/main/campaign_fallback_ui.gd) and G3 (godot/ui/campaign/): G2 maintains godot/main/campaign_host.gd (14,032 bytes) and godot/main/campaign_fallback_ui.gd, while G3 owns godot/campaign/, godot/ui/campaign/, and godot/scenes/campaign/ (Go-forward plan section 4).

Problem 8.4 [FIX] Shared container process collisions killing parity runs: contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md reports that multiple helper streams run Godot inside the same 2-CPU cloud container, causing SIGTERM kills on s32 and thread_test.gd.

Disagreements between documents in the pack (with both sources named)

Campaign UI and map integration [BLOCKER]: HANDOFF.md section 0 and Go-forward plan status table row G3 campaign state G3 campaign: DONE. The R51 map is rebuilt as a Sins 2 style star system over 4 rounds, whereas godot/main/FEATURES.md (10,493 bytes, Campaign screens table) marks Sector map, node info, node modifiers as fallback (no map picture) and marks all 12 other non-battle campaign screens as fallback.

Windows .exe readiness [BLOCKER]: HANDOFF.md section 0 (Built: title to final boss, the Windows build) and Go-forward plan status table row G2 (Title to final boss, Windows build) claim the Windows build is done, whereas godot/main/FEATURES.md (10,493 bytes, row Windows build (.exe)) states exe smoke test pending.

Bot run cleanliness [FIX]: HANDOFF.md section 0 states 36 runs across all six factions, 34 of them clean (2 runs not clean), whereas Go-forward plan status table row G2 cites only smart bot 100 runs 0 hangs and Go-forward plan section 4 (Sprint goal (R35)) requires 0 errors.

Battle round pace [FIX]: HANDOFF.md section 0 claims every battle's worst round is under 15 s and Go-forward plan status table row G2 claims pace under 15 s per round, whereas godot/main/FEATURES.md (10,493 bytes, row Enemy turns at B2 pace) reports 13.4 s as the mean round time of a 20-ship sector 3 fight (measured 30.1 s mean, now 13.4 s), not the worst round.

Ship movement status [FIX]: HANDOFF.md section 0 and Go-forward plan status table row G2 mark R54 thruster-true movement as IN PROGRESS, whereas godot/main/FEATURES.md (10,493 bytes, row Ship movement with weight (R50)) marks ship movement as done.

Golden battle count (43/43 vs 47/47) [FIX]: HANDOFF.md section 0 and FINDINGS G-12 claim 43/43 golden battles, whereas contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md (Later cloud checks) and godot/rules/test/README.md (10,591 bytes) document 47 of 47 golden battles (s1 to s47) at commit 48638ef.

Enemy think-time bar [FIX]: FINDINGS G-12 and godot/rules/test/README.md (10,591 bytes) claim every enemy think time is inside the 0.5 s bar (worst 0.406 s, s23), whereas contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md (g1_lb_parity_1027e) records 0.585 s on s4 and states s4 missed the bar on this run.

Pyre-Barge (C19_51) completion [FIX]: Go-forward plan status table rows A1 step 2, A1 step 3, and A1 step 5 mark v15 dressed barge approved and Paint approved as DONE Oct 25 (and corsair_lineup.webp includes C19_51 in the pass 3 Corsair lineup), whereas HANDOFF.md section 0 marks the Pyre-Barge redesign to match C13s to C16s (R54) as IN PROGRESS.

Portrait painting status [NOTE]: HANDOFF.md section 0 states Painting is held for lore approval, whereas the repo listing for godot/portraits/ already contains a painted/ directory (painted/ dir).

Claims marked done that the repo listings in evidence_pack_B.md do not back up

Problem 8.5 [FIX] Major stream folders omitted from the pack's repo listings: The Repo listings at leg start section in evidence_pack_B.md only lists godot/rules/, godot/rules/test/, godot/main/, godot/fx/, godot/music/, godot/portraits/, tools/blender/, and docs/shots/. It contains no listing for:

G2: godot/scenes/battle/, godot/render/, godot/ui/battle/, godot/audio/, project.godot, brand.gd, tools/pc/play_godot.bat, tools/pc/play_godot_safe.bat, or build/export/Voidsworn.exe.

G3: godot/campaign/, godot/ui/campaign/, or godot/scenes/campaign/.

G4: godot/world/ or godot/render/look.gd.

A4: assets/ships/<code>/, godot/assets/ships/, hulls_hi/, or hulls/ (and voidsworn_lineup.webp is missing from the attached files).

Stream B and Lore: battle.js, core.js, data.js, campaign_run.js, campaign_meta.js, contrib/opus/tools/b1_tests.js, contrib/opus/compute/balance_reference.md, or contrib/opus/compute/lore_bible_r6.md.

Top Three Most Serious Problems

[BLOCKER] Campaign UI integration gap between G2 (godot/main/) and G3 (godot/ui/campaign/): godot/main/FEATURES.md (10,493 bytes) still marks all 13 non-battle campaign screens (including Sector map, node info, node modifiers) as fallback (no map picture) in the Drawn column while godot/main/campaign_fallback_ui.gd sits in godot/main/, contradicting HANDOFF.md section 0 (G3 campaign: DONE) and risking that the main executable still launches the text fallback instead of the rebuilt 3D star-system campaign map.

[BLOCKER] Unverified Windows .exe export (exe smoke test pending): While HANDOFF.md section 0 and the Go-forward plan status table report the Windows build as done, godot/main/FEATURES.md (10,493 bytes) admits exe smoke test pending for build\export\Voidsworn.exe, and HANDOFF.md section 0 notes that 2 of the 36 six-faction bot runs were not clean (34 of them clean), leaving a blocking risk that tools/pc/play_godot.bat fails or errors during a full run on the owner's PC.

[FIX] Widespread CLAUDE.md ship-rule violations (naval tells and AI blobs) and unreadable G4 weapon scars at battle camera: In corsair_lineup.webp, C13s_23_sweep_painted.webp, and 03_dead_star_board_r10.jpg, ships still exhibit vertical smokestack funnels (C13s_23, C15s_23, C16s_23), a crossbar mast and boat hull (C19_51 and the white Hegemony battleship), row portholes (C15s_23), and uncleaned AI blobs (C13s_23, C14s_23, C15s_23, C16s_23, pink Chorus hull), while 05_frigate_marks_at_battle_camera.jpg shows that flak pocks, acid spines, ion burn, and ram crumple marks are nearly invisible at battle camera distance.

One-line verdict: The sprint is close on rules parity and core battle plumbing, but it is not yet ready for a clean owner test until the Windows .exe smoke test passes, godot/main/ is confirmed wired to G3's 3D campaign UI rather than campaign_fallback_ui.gd, and the remaining 2 unclean faction bot runs and ship/effect visual defects are resolved.
