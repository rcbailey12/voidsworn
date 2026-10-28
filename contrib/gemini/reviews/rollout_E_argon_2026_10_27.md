# Blind audit leg: rollout audit, Audit E, Argon leg

Filed by the chair from the model's verbatim answer. Model: Gemini 4 Argon, thinking level High, verified in two places (prompt bar button read Argon High; the picker showed Selected 4 Argon). Signed in as rcbailey12@gmail.com. Run Oct 27, 2026. The first chat (https://gemini.google.com/app/d128d990dc37128c) stalled after Part 2 with a Gemini error and produced no answer in about 12 minutes; one fresh retry chat was started, as the assignment permits for a stalled generation. Retry chat: https://gemini.google.com/app/5607c5dfb72d0685; Part 1 sent about 4:39 PM PDT, Part 2 about 4:42 PM PDT, complete response observed about 4:47 PM PDT. Pinned main HEAD: 806233f766bfdfd98c61fbe5bebb834cc11bbe6c.

Attachments (all 9 text files and all 9 image files attached in each attempt): leg_prompt_E.md, brief.md, context_E.md, g4_gallery_readme.md, sb_evidence.md, findings_extract.md, CLAUDE.md, bible_looks.md, faction_looks.json, hegemony_lineup.webp, voidsworn_lineup.webp, corsair_lineup.webp, V1b_r_23_sweep_painted.webp, H4_11_sweep_painted.webp, bow_before_after_H8_H7_V1b.jpg, bow_before_after_H4_H10_H9.jpg, crests_all.webp, dreadnought_turn_then_burn_after_frames.jpg, frigate_sidestep_after_frames.jpg.

Method notes and screening live outside this file. Gemini citation chips are interface elements, not model text, and were omitted; table rows were preserved in text form. The text below is the model's answer, verbatim.

---

Audit E Report (pinned to [github.com/rcbailey12/voidsworn](https://github.com/rcbailey12/voidsworn) main commit 806233f766bfdfd98c61fbe5bebb834cc11bbe6c, Oct 27, 2026)

## Verdict

No BLOCKER findings for Ryan's return; the G4 20-ship stall fix and Stream B RAMP easing are well-reasoned in commit code and preliminary sims but still await their queued PC confirmation runs (r19 bench and sb_ramp_*), while A4 pass 5 ships and the admiral crest sheet carry visual FIX items against CLAUDE.md and bible_looks.md.

## Job E1: the G4 20-ship bench (commits cc8aeed and 2aac0ca)

### Questions Answered

Is the stated cause convincing?

Yes. In r18 (cc8aeed, g4_gallery_readme.md), average frame times on Ryan's RTX 5080 are fast across all three configurations: Forward+ 1080p averages 3.96 ms (253 fps), Forward+ 4K averages 6.99 ms (143 fps), and Compatibility 1080p averages 3.56 ms (281 fps).

The severe stalls appear only in the 1% lows (66.8 ms / 15 fps at 1080p Forward+, 109.8 ms / 9 fps at 4K Forward+, 54.6 ms / 18 fps at 1080p Compatibility) and the multi-second worst frames (4302 ms, 4029 ms, and 1584 ms).

The stated cause in 2aac0ca and g4_gallery_readme.md is that every hull damage rebuild re-launched the ship's background death cut (consuming seconds of worker time on high-poly hulls and uploading piece meshes on the main thread), and when a ship died, the main thread waited synchronously if a death cut was still running. In a 20-ship volley fight where ships take rapid sequential hits before dying, repeated worker restarts and synchronous main-thread waits on unfinished cuts directly explain a 1.58 s to 4.30 s freeze alongside low average frame times.

Is the fix sound against that cause?

The fix in 2aac0ca (re-cutting a ship at most once every 6 s, caching the last finished cut so a death breaks up along it immediately, and holding the cook-off up to 2.5 s if the very first cut is still running instead of freezing the main thread) directly removes both the per-hit cut restart churn and the synchronous main-thread wait on death.

Two edge cases remain UNSURE until measured: (a) if a high-poly flagship is killed before its first cut finishes and worker thread contention pushes that first cut past the 2.5 s cook-off hold (given r18 stalled for up to 4.30 s), a smaller stall could still occur; and (b) uploading piece meshes on the main thread once every 6 s per damaged ship could still create multi-millisecond frame spikes that affect 1% lows.

Is there a re-bench anywhere in the pack that proves the fix?

No (UNSURE). context_E.md (HANDOFF section 0, G4 row) explicitly states: "the fix landed in 2aac0ca, but a re-bench is needed to confirm". g4_gallery_readme.md notes that "the r19 run re-measures, and the bench now lists every frame over 33 ms", but the r19 numbers are not yet in the pack.

Is anything else in the record likely to hitch at 20 ships (4K 1% low of 9 fps, Compatibility renderer numbers)?

Yes. Comparing the three r18 rows in g4_gallery_readme.md shows two separate hitch sources:

CPU / main-thread geometry and mesh uploads (shown by Compatibility 1080p): The Compatibility renderer strips out heavy Forward+ shaders and lens distortion (g4_gallery_readme.md), yet still suffers a 54.6 ms (18 fps) 1% low and a 1584 ms worst frame. Alongside the death-cut stalls addressed by 2aac0ca, each weapon mark splits coarse hull triangles and builds an overlay mesh with both worker and main-thread cost (MARKS_COST in g4_gallery_readme.md). Under 20-ship volley fire, main-thread mark mesh swaps and damage stage rebuilds can still pressure 1% lows (UNSURE how much remains after 2aac0ca).

Resolution-dependent GPU / shader spikes at 4K Forward+ (109.8 ms / 9 fps 1% low): Moving from 1080p Forward+ to 4K Forward+ on the exact same seeded battle raises average frame time by only 3.03 ms (3.96 ms to 6.99 ms), but worsens the 1% low by 43.0 ms (66.8 ms to 109.8 ms). Because CPU mesh cuts and PCIe uploads do not scale with screen resolution, that extra 43.0 ms gap at 4K points to pixel-fillrate and shader spikes when multiple fireballs, raymarched fires/vents, screen-space distortion, soft particles, parallax holes, and 64 lights overlap at 4K (max-only extras cost 1.92 ms average at 6 ships in r2, and the 6-flagship 4K bench already had a 21.2 ms 1% low in g4_gallery_readme.md).

### Job E1 Findings

NOTE (Tracked in HANDOFF Still to do) | context_E.md (commit 2aac0ca, HANDOFF section 0), g4_gallery_readme.md: The 2aac0ca death-cut fix is not yet proven by post-fix frame-time numbers (r19 re-bench pending) (UNSURE).

FIX | g4_gallery_readme.md (20-ship performance record r18): Forward+ 4K 1% low is 109.8 ms (9 fps) versus 66.8 ms (15 fps) at 1080p Forward+ and 54.6 ms (18 fps) on 1080p Compatibility. Even after 2aac0ca removes the CPU death-cut freeze, the 43.0 ms resolution penalty on the 1% low between 1080p and 4K indicates overlapping 4K shader/fillrate spikes during 20-ship volleys that 2aac0ca alone does not touch (UNSURE whether r19 stays under the 33 ms bar at 4K without trimming overlapping max particle/raymarch overdraw).

## Job E2: Stream B balance (commit d551697, port_notes steps 8 and 9, streamb files)

### Questions Answered

Does the full-run win rate now sit near about 20% in simulation, and on what evidence (seeds, run counts, PC or cloud)?

Yes, on preliminary in-sample runs. In sb_evidence.md (Step 9 Sim table), the full-run win rate after d551697 sits at 20% on seed 7101 (was 17% on cb55ec9) and 19% on seed 7102 (was 10% on cb55ec9), averaging 19.5% across 200 seeded runs (runsim 100 per seed).

Caveat on evidence (UNSURE): Those two seeds (7101 and 7102) are the exact same two seeds used for the attribution sweep and candidate tuning (sb_evidence.md, streamb/fullrun_attr.txt). sb_evidence.md states that runsim is deterministic across environments ("the same seed gives the same runs on the PC and in the cloud") and notes that out-of-sample PC confirmation on fresh seeds (7103, 7104) and the sector 2 and 3 campaign sim (jobs sb_ramp_*) are "results to follow in this section".

Does the attribution table in step 9 support the chosen change (the RAMP easing) over the candidates tried?

Yes. The Step 9 attribution table (sb_evidence.md and streamb/fullrun_attr.txt, 200 runs per variant across seeds 7101 and 7102, standard error about 2.4 points) isolates the 8.5-point drop from Pass 1 (5294612, 20.0% wins: V5_1 18%, V5_2 22%) to Pass 3 control (bcc7e47, 11.5% wins: V0_1 11%, V0_2 12%) and cb55ec9 (13.5% wins: V4_1 17%, V4_2 10%):

Removing the Pass 2 faction tuning made wins 1 point worse (10.5%: V1_1 16%, V1_2 5%), proving faction balance changes did not cause the drop.

Removing the B-21 escort anti-wing fix restored 3.5 points (15.0%: V2_1 17%, V2_2 13%), and removing move-then-fire also restored 3.5 points (15.0%: V3_1 18%, V3_2 12%).

Because B-21 and move-then-fire are intentional gameplay fixes that must stay (sb_evidence.md), and pass3_report.md shows the drop happens in the sector 2 boss and sector 3 (reaching sector 3 fell from 38% in Pass 1 to 26% in cb55ec9), easing the sector 2 and 3 enemy fleet RAMP in battle.js is the right lever.

Across the three RAMP candidates tested on seeds 7101 and 7102 (sb_evidence.md), easing boss escorts only (.45/.55) with sector 3 grow 1.28 under-shot at 17.5%, while adding lighter sector 2 grow 1.2 and thin .66/.60 over-shot to 31%. The chosen middle setting (grow [0,1.2,1.24,1.26], thin [0,.73,.675,.62], boss [0,.3,.44,.53], leaving sector 1 untouched) landed at 20% and 19%.

Are all admirals still inside 53 to 85% and the faction spread 9 points or less (pass 3 figures), and did anything in steps 8 or 9 put those at risk?

Did steps 8 or 9 put them at risk? No. Step 8 (9b30668) only changed skirmish fleet lists (FLEET_LISTS[fac].sk in ui3d.js and sim3d.js), which fmatrix and bossmatrix do not use (sb_evidence.md). Step 9 (d551697) only changed battle.js RAMP indices 2 and 3 (sectors 2 and 3 campaign enemy fleets), leaving sector 1 values untouched; sb_evidence.md confirms that bossmatrix (which uses sector 1) and fmatrix (which uses set fleets) produce identical output before and after on the same seed.

What the attached pass3_report.md actually shows vs G-13 (UNSURE): findings_extract.md (G-13) records that across 75a75d0 to cb55ec9, admirals sit at 53 to 85% vs a sector 1 flagship and faction strength spread moved from 17 to 9 points. However, the streamb/pass3_report.md file included in sb_evidence.md only prints the pre-t2 table at commit bcc7e47, where faction strength sits at chorus 60.5 down to voidsworn 43.5 and ithar 43.5 (a 17.0-point spread) and ends with the line "Read: Chorus still runs ahead and Voidsworn and Ithar trail (B3 exit 'no faction runs away' not met). Tuning t2 below." without including the t2 (cb55ec9) fmatrix or bossmatrix tables in the excerpt. Thus, the cb55ec9 53 to 85% admiral band and 9-point faction spread are supported by G-13 and Step 9's invariance check, but the raw cb55ec9 bossmatrix and t2 fmatrix tables themselves are not in sb_evidence.md (UNSURE).

### Job E2 Findings

NOTE | sb_evidence.md (Step 9 Sim, pass3_report.md Addendum): Promised PC confirmation runs on two fresh seeds (7103, 7104) and the post-RAMP sector 2 and 3 campaign sim (jobs sb_ramp_*, including updated sector 3 round-wait numbers) are marked "results to follow in this section" and are not yet evidenced in the pack (UNSURE).

NOTE | sb_evidence.md (streamb/pass3_report.md) vs findings_extract.md (G-13): The attached pass3_report.md stops at bcc7e47 (showing the 17-point faction spread before t2 and omitting the cb55ec9 t2 fmatrix and bossmatrix tables cited in G-13), though Step 9 proves d551697 does not alter cb55ec9's sector 1 bossmatrix or fmatrix outputs (UNSURE on raw cb55ec9 table cells).

NOTE | sb_evidence.md (Step 8 skirmish matrix): Equalizing skirmish lists to 20 command points fixed the Deathless worst matchup from 6% to 56%, but player-side bot advantage in skirmish remains very wide (mirror matchups win 63% to 100% for the player side, and AI-controlled Corsair loses 81% to 100% against every player faction).

## Job E3: A4 pass 5 ships (images in docs/shots/a4/a7c4e0d/)

### Pass 5 Claims Verification

Blunt level prows on Hegemony ships (H4_11, H10_23, H9_23, H8_23, H7_23) and V1b_r_23: CONFIRMED. Both before-and-after sheets (bow_before_after_H4_H10_H9.jpg and bow_before_after_H8_H7_V1b.jpg) and V1b_r_23_sweep_painted.webp show that the downward-sloping, pointed/rounded noses on all five Hegemony hulls and the pointed boat-like stem on V1b_r_23 have been replaced with squared-off, level prows.

Pyre-Barge (C19_51) at 256k triangles (was 475k): The triangle count itself is NOT CHECKED from images per house rules (note that context_E.md mentions 256k in HANDOFF section 0 and 326k PC export / 233k cloud budget in commit a7c4e0d). Visually in corsair_lineup.webp (#5 Warlord's Pyre-Barge), the decimated mesh holds crisp silhouette and surface detail with no visible mesh tearing or low-poly faceting.

Missing H4 sweep sheet: leg_prompt_E.md lists "the H4 sweep" among the evidence images, but no 9-cell sweep image for H4_11 was attached in the pack (NOT CHECKED for the 9-cell H4 sweep; H4_11 is audited below using hegemony_lineup.webp and bow_before_after_H4_H10_H9.jpg).

### Ship-by-Ship Audit Against CLAUDE.md Rules

Ship (ID / Class) | Evidence Images | Verdict | Rule Check Details (Space not naval; No backward guns; No blobs; Matched pairs)
Hegemony #1: H7_23 Picket-class frigate | hegemony_lineup.webp, bow_before_after_H8_H7_V1b.jpg | PASS | Blunt level prow; forward 3-prong laser and symmetric pair of forward-angled dorsal flak turrets; no backward guns. Minor note: in bow_before_after_H8_H7_V1b.jpg (H7_23 after side view), the front edge of the dorsal 3-prong gun box overhangs slightly over the sloped foredeck crease.
Hegemony #2: H8_23 Interdictor-class destroyer | hegemony_lineup.webp, bow_before_after_H8_H7_V1b.jpg | PASS | Blunt level prow; forward 3-prong ion cannon and forward-aimed dorsal twin turret; blocky space superstructure; no backward guns.
Hegemony #3: H9_23 Vanguard-class cruiser | hegemony_lineup.webp, bow_before_after_H4_H10_H9.jpg | PASS | Blunt level prow; forward 3-prong ion cannon, centerline forward turret, and symmetric flanking forward turrets; clean panelling; no backward guns.
Hegemony #4: H10_23 Dominion-class battleship | hegemony_lineup.webp, bow_before_after_H4_H10_H9.jpg | PASS | Blunt level prow; forward 3-prong ion cannon, forward dorsal turrets, and two symmetric pairs of broadside twin turrets aimed 90 degrees out to port/starboard; no backward guns; clean hull plates.
Hegemony #5: H4_11 Dominion super-dreadnought | hegemony_lineup.webp, bow_before_after_H4_H10_H9.jpg | FAIL (FIX) | Blunt level prow and forward/side turrets obey gun-direction and symmetry rules, but in both hegemony_lineup.webp (#5) and bow_before_after_H4_H10_H9.jpg (H4_11 after), the AI hull surface along the upper bow cheeks and midship shoulders remains visibly lumpy and blobby around the crisp hand-built turrets and bridge block.
Voidsworn #1: V14_23 Warden-class frigate | voidsworn_lineup.webp | PASS (with tracked work) | Forward twin autocannon and two forward-aimed aft dorsal flak turrets; symmetric hull; no backward guns. The oversized smooth block under the forward gun is already listed in context_E.md HANDOFF section 0 under Still to do ("the Warden mount if not done").
Voidsworn #2: V15_37 Harrow-class destroyer | voidsworn_lineup.webp | FAIL (FIX) | Forward launcher box and midship dorsal turret face forward (no backward guns), but in voidsworn_lineup.webp (#2), the aft third of the dorsal hull behind the vertical fin has uncleaned, melted AI blobs, and the flat-shaded rectangular box on the foredeck clashes starkly in surface detail with the hull (CLAUDE.md blob sweep rule).
Voidsworn #3: V16_37 Penitent-class cruiser | voidsworn_lineup.webp | FAIL (FIX) | Forward dorsal lance housing, midship turret, and side broadside batteries face forward/sideways (no backward guns), but in voidsworn_lineup.webp (#3), the aft spine behind the dorsal fin is a lumpy AI blob mass and the smooth blocky forward lance housing contrasts sharply with the melted AI hull texture beneath it.
Voidsworn #4: V18_51 Reliquary-class carrier | voidsworn_lineup.webp | PASS | Symmetric delta space hull; two matched pairs of forward-facing dorsal twin turrets; clean central spire and stern fins; no backward guns or naval tells.
Voidsworn #5: V17_37 Cathedral-class battleship | voidsworn_lineup.webp | FAIL (FIX) | Forward dorsal twin turrets and side broadside batteries obey gun rules, but in voidsworn_lineup.webp (#5), the dark grey bridge gantry supporting the upper forward turret looks like an untextured flat kit block against the pitted hull, and the aft spine behind the radiator bank retains blobby AI bumps (V17's radiator bank is tracked in HANDOFF Still to do).
Voidsworn #6: V1b_r_23 Ascendant-class dreadnought | voidsworn_lineup.webp, V1b_r_23_sweep_painted.webp, bow_before_after_H8_H7_V1b.jpg | FAIL (FIX) | Blunt level prow; broadside batteries aim sideways and all dorsal turrets (including the stern dorsal turret in V1b_r_23_sweep_painted.webp stern top) aim forward. The chimney-like vents and side porthole rows are already tracked in context_E.md HANDOFF section 0 Still to do ("V1b's vents and porthole rows"), but in V1b_r_23_sweep_painted.webp (bow top) and bow_before_after_H8_H7_V1b.jpg (V1b_r_23 after bow top), there is a deep black circular hole/pit artifact in the foredeck right behind the prow that needs cleanup.
Corsair #1: C13s_23 Raider-class frigate | corsair_lineup.webp | PASS | Forward dorsal twin turret, forward rocket pods, and lower bow boarding claw; no backward guns; space silhouette with trophy plating (CLAUDE.md notes Corsair is the junky/asymmetric exception).
Corsair #2: C14s_23 Reaver-class destroyer | corsair_lineup.webp | PASS | Forward dorsal twin tubes, side casemate gun, and lower bow claw; no backward guns; cohesive junky space hull.
Corsair #3: C15s_23 Marauder-class cruiser | corsair_lineup.webp | FAIL (FIX) | Forward/side guns and bow claw obey weapon rules, but in corsair_lineup.webp (#3), the midship deck features two vertical cylindrical smokestack funnels with soot rims, violating CLAUDE.md ("crossbar masts and smokestack funnels count as naval tells and become antenna arrays and heat radiators").
Corsair #4: C16s_23 Hulk-carrier | corsair_lineup.webp | FAIL (FIX) | Forward dorsal turret and bow claw obey weapon rules, but in corsair_lineup.webp (#4), the mid-deck and bridge top carry cylindrical smokestack funnels (naval tells per CLAUDE.md), and the upper bow nose has bubbly, rounded AI lumps.
Corsair #5: C19_51 Warlord's Pyre-Barge | corsair_lineup.webp | PASS | Rebuilt welded-hull space barge with twin lower boarding claws, forward torpedo bays, and top forward-aimed twin flak turret; no backward guns, no naval hull tells, and clean kit integration.

### Job E3 Summary of Findings

FIX | hegemony_lineup.webp (#5), bow_before_after_H4_H10_H9.jpg (H4_11 after): Uncleaned AI hull blobs on the upper bow cheeks and midship shoulders of H4_11.

FIX | voidsworn_lineup.webp (#2 V15_37, #3 V16_37, #5 V17_37): Melted AI blobs on the aft dorsal spines behind the midship fins/radiators, and stark surface-detail contrast where smooth, untextured kit boxes/gantries sit on rough AI hulls.

FIX | V1b_r_23_sweep_painted.webp (bow top), bow_before_after_H8_H7_V1b.jpg (V1b_r_23 after): Deep black circular pit/hole artifact on the foredeck of V1b_r_23. (Note: V1b_r_23's chimney vents and porthole rows, V17_37's radiator bank, V14_23's mount, and the round 8 faction repaints are already tracked in context_E.md HANDOFF section 0 "Still to do".)

FIX | corsair_lineup.webp (#3 C15s_23, #4 C16s_23): Vertical cylindrical smokestack funnels on C15s_23 and C16s_23 violate the CLAUDE.md ban on smokestack funnels, plus bubbly AI lumps on the upper nose of C16s_23.

## Job E4: G2 movement (R54 and R55)

### Evaluation of Target Feel Against Stills and Commit Text

Turn in place on jets, then burn:

Confirmed in stills. In dreadnought_turn_then_burn_after_frames.jpg (docs/shots/g2/680324c/), frames 0.10s and 0.27s show the dreadnought (Pale Crusader) rotating in its starting hex with its main rear engines dark (only a dim pilot glow) while white-blue lateral RCS jets fire at the bow and stern. At 0.43s, once aligned, the three main rear engine plumes ignite, and at 0.60s and 0.87s the ship burns straight across the hex boundary.

Sidesteps and back-offs with the main drive dark:

Sidestep confirmed; back-off UNSURE. In frigate_sidestep_after_frames.jpg (docs/shots/g2/680324c/), frames 0.07s, 0.17s, 0.27s, 0.37s, and 0.50s show the frigate (Lament of Iron) translating laterally into an adjacent hex with its main rear drives dark (dim pilot glow only) and side RCS jets firing. (In frame 0.73s, the frigate enters a second forward hex move where a rear trail appears.) No back-off (reverse) frame strip is in the pack, so back-off main-drive behaviour is UNSURE.

Eased stops (braking as long as the thrust-up, jets firing through the burn, slight settle):

Described in 3be2896 commit text, visually UNSURE. Both attached frame strips come from docs/shots/g2/680324c/, which is the build before Ryan noted in R55 (findings_extract.md) that the stop felt too sudden. While dreadnought_turn_then_burn_after_frames.jpg (1.20s) and frigate_sidestep_after_frames.jpg (0.50s) show brief braking RCS puffs at the end of the move, the 3be2896 smooth-stop rework ("every move segment brakes for as long as it thrust up, eased, the jets firing through the whole braking burn, with a slight settle at the end; turns ease into their counter-spin") cannot be verified visually because docs/shots/g2/3be2896/ has not landed yet (context_E.md HANDOFF section 0 Still to do) and .mp4 videos cannot be attached (UNSURE).

Flip-and-burn only on long runs, and only if it reads well:

Gated behind --flip-burn in 3be2896, visually UNSURE. Commit 3be2896 (context_E.md) implements flip-and-burn test behind --flip-burn (cruisers and bigger, 3+ hex straight runs), matching R55's rule that only big hulls on long runs attempt it. Because the A/B clips in docs/shots/g2/3be2896/ have not landed (context_E.md HANDOFF section 0 Still to do), whether flip-and-burn reads well in motion is UNSURE.

### Job E4 Findings

NOTE (Tracked in HANDOFF Still to do) | context_E.md (3be2896, HANDOFF section 0): The docs/shots/g2/3be2896/ A/B comparison clips (current vs smooth stop vs flip-and-burn) have not landed yet, leaving the visual feel of 3be2896 eased stops, turn counter-spin easing, back-offs, and --flip-burn UNSURE from stills.

NOTE | dreadnought_turn_then_burn_after_frames.jpg, frigate_sidestep_after_frames.jpg: In the 680324c battle capture frames, the top-center Admiral's Command tutorial modal overlaps the top-left HUD bar and the right-side help text clips against the right edge of the viewport.

## Job E5: Portraits and crests

### 1. Six Faction Crests vs bible_looks.md Specs

crests_all.webp is titled "Voidsworn admiral crests (one per admiral; glyph = Command)" and displays 24 admiral badges arranged in 6 faction groups of 4, where each badge combines a faction border frame with one of 6 repeated interior Command ability glyphs (three spears, crosshair sword, two chevrons with five arrowheads, three chevrons with three dashes, half-dome over two bars, or ring with three ticks). The standalone godot/portraits/crests/faction_<id>.svg files mentioned in context_E.md (e243729) are not attached as separate files (NOT CHECKED outside crests_all.webp). Judged on crests_all.webp, five of the six faction crests fail to show the bible_looks.md crest iconography, and the sixth is obscured by the interior Command glyph:

Faction | bible_looks.md Crest Spec | What crests_all.webp Shows | Verdict
Crusade (voidsworn) | 2.9: "a half sun, its lower half black, over a broken link" | An orange/white shield outline with a tiny orange half-circle nub perched on top of the upper border; no black lower half and no broken link. (The half-dome over two straight bars on Oryn Thale is a generic Command glyph also used on Oskar Maren, Mirelle Starwarden, and Khepra the Patient.) | FAIL (FIX)
Hegemony (hegemony) | 3.8: "a wedge in a ring of five linked nodes" | A plain blue 6-sided shield outline containing the generic Command glyphs; no wedge and no ring of five linked nodes. | FAIL (FIX)
Hullbreakers (corsair) | 4.8: "a ring of welded scrap teeth around three claw slashes" | An 8-sided red polygonal shield with 8 tiny corner dots containing the generic Command glyphs; no ring of welded scrap teeth and no three claw slashes. | FAIL (FIX)
Chorus (chorus) | 5.8: "a ring of nine open mouths" | A wobbly yellow-green amoeba outline with outer spore dots containing the generic Command glyphs; no ring of nine open mouths. | FAIL (FIX)
Glasswrights (ithar) | 6.8: "a cracked lens with one beam of light passing through" | An uncracked silver pointed oval (vesica) with 12 thin exterior radial lines containing the generic Command glyphs; no crack in the lens and no single beam passing through. | FAIL (FIX)
Eclipse (deathless) | 7.8: "an eclipsed sun, a black disc with a thin white-gold ring" | A dark purple-black disc inside a thin white-gold ring surrounded by two segmented gold outer arcs, with a large Command glyph filling the center of the disc. Closest to spec, though the outer segmented mechanical rings and interior Command glyph obscure the simple eclipsed sun disc. | NOTE

### 2. Palette Rows in faction_looks.json vs bible_looks.md

Faction ID | bible_looks.md Colour Line | faction_looks.json Values | Verdict
voidsworn (Crusade) | 2.5: "black iron, frost white, bright ember" (no rust) | weapon [1.0, 0.55, 0.2], shield [1.0, 0.5, 0.18], engine [1.0, 0.55, 0.18], damage_glow [1.0, 0.5, 0.14] (bright ember); accent [0.8, 0.9, 1.0], shield_edge [0.82, 0.92, 1.0] (frost white); nebula dark slate/frost/ember. | PASS
hegemony (Hegemony) | 3.3: "pale grey, steel blue, implant blue" | weapon [0.55, 0.82, 1.0], shield [0.38, 0.68, 1.0], engine [0.45, 0.72, 1.0] (implant/steel blue); nebula [[0.08, 0.2, 0.42], [0.22, 0.42, 0.72], [0.85, 0.93, 1.0]] (deep blue, steel blue, pale grey). Note: damage_glow is [1.0, 0.72, 0.38] (warm white-gold, documented in _fields for internal hull fire/conduits). | PASS (with NOTE)
corsair (Hullbreakers) | 4.3: "soot, rust, dried blood, trophy colours, red running lights" | weapon [0.95, 0.22, 0.1], shield [0.85, 0.16, 0.1] (dried blood red), engine [1.0, 0.38, 0.16], engine_extra "soot", damage_glow [1.0, 0.3, 0.07], accent [1.0, 0.1, 0.05] (red running lights), nebula soot/rust/red-orange. | PASS
chorus (Chorus) | 5.3: "dark olive, ochre bone, bile yellow-green light" | weapon [0.72, 0.88, 0.18], engine [0.7, 0.86, 0.2], damage_glow [0.66, 0.92, 0.16] (bile yellow-green); nebula [[0.14, 0.16, 0.06], [0.55, 0.38, 0.12], [0.8, 0.9, 0.35]] (dark olive, ochre, bile yellow-green). | PASS
ithar (Glasswrights) | 6.3: "clear crystal, silver, rainbow edge, stored light" | weapon [0.92, 0.96, 1.0], shield [0.82, 0.9, 1.0], engine [0.82, 0.94, 1.0], damage_glow [0.85, 0.92, 1.0] (stored white-crystal light); accent [0.88, 0.9, 0.96] (silver); shield_edge "rainbow". | PASS
deathless (Eclipse) | 7.3: "dark violet-black plates, a white-gold eclipse corona, violet-white inner glow" | weapon [0.72, 0.55, 1.0], engine [0.7, 0.52, 1.0], damage_glow [0.72, 0.5, 1.0] (violet-white glow); accent [1.0, 0.84, 0.5] (white-gold corona); nebula [[0.1, 0.04, 0.16], [0.34, 0.14, 0.52], [1.0, 0.84, 0.55]] (violet-black to white-gold, no green). Note: engine_extra is "embers". | PASS (with NOTE)

### 3. Admiral Portrait Repaints and Existing Assets vs bible_looks.md

The portrait prompt updates in 494c000 (context_E.md: furred Hullbreakers, light-storing Glasswright skin, violet-black Eclipse) match bible_looks.md sections 4.3, 6.3, and 7.3, and the PC Lane A repaint jobs (r8a, r8b, r8e) are marked "Still to do" in context_E.md HANDOFF section 0.

On crests_all.webp, the caption labels still display retired pre-rollout strings that contradict bible_looks.md and brief.md (Voidsworn admiral crests, The Mending Choir instead of the Mending Throng in bible_looks.md 5.3, Seraph Vaelen using retired church word Seraph, and Egyptian/Necron Deathless names Nekhet the Undying, Sekhmar the Reaper, Cryptlord Anuket, Khepra the Patient). Updating the portrait contact sheets and display names to the rename map is already tracked in context_E.md HANDOFF section 0 ("Portraits: Still to do: Admiral and Nemesis repaints on PC lane A (jobs r8a, r8b, r8e) and contact sheets. Display names follow the map").

### Job E5 Findings

FIX | crests_all.webp vs bible_looks.md (2.9, 3.8, 4.8, 5.8, 6.8, 7.8): crests_all.webp renders 24 admiral Command badges whose faction frames omit the required faction crest motifs (no half sun with black lower half over a broken link for Crusade; no wedge in five linked nodes for Hegemony; no welded scrap teeth ring with three claw slashes for Hullbreakers; no ring of nine open mouths for Chorus; no cracked lens with a single beam passing through for Glasswrights). Whether the standalone godot/portraits/crests/faction_<id>.svg files (e243729) have the full bible motifs or the simplified frames from crests_all.webp is UNSURE because those .svg files are not in the pack.

NOTE | faction_looks.json vs bible_looks.md (3.3, 7.3): All six palettes in faction_looks.json match the round 8 colour lines. Two minor details for Opus/Ryan to be aware of: hegemony.damage_glow is warm white-gold [1.0, 0.72, 0.38] (documented in _fields as internal hull fire/conduits, whereas Hegemony's external palette in bible_looks.md 3.3 is strictly pale grey, steel blue, and implant blue), and deathless.engine_extra is "embers" (colored white-gold by accent), whereas bible_looks.md 7.3 states Eclipse ships have "eclipse rings around the engines, no flaming engine bells".

NOTE (Tracked in HANDOFF Still to do) | crests_all.webp, context_E.md (HANDOFF section 0): crests_all.webp still carries pre-rollout admiral display names (Cryptlord Anuket, Nekhet the Undying, Sekhmar the Reaper, Khepra the Patient, Seraph Vaelen, The Mending Choir); regenerating contact sheets with mapped display names is already listed in HANDOFF section 0 "Still to do".

## Not Checked

G4 post-fix re-bench (r19): Not in pack (context_E.md HANDOFF section 0 marks the re-bench after 2aac0ca as "Still to do").

Stream B fresh-seed PC confirmation (7103, 7104, jobs sb_ramp_*) and post-RAMP sector 2 and 3 campaign sim: Promised in sb_evidence.md ("results to follow in this section"), not in pack.

Stream B cb55ec9 (t2) raw fmatrix and bossmatrix tables: Summarized in findings_extract.md (G-13), but streamb/pass3_report.md in sb_evidence.md only includes the pre-t2 (bcc7e47) table.

Pyre-Barge (C19_51) 256k triangle count: NOT CHECKED from images per leg_prompt_E.md instructions.

A4 H4_11 9-cell blob sweep sheet ("the H4 sweep"): Referenced in leg_prompt_E.md, but not included among the attached images (H4_11 was checked via hegemony_lineup.webp and bow_before_after_H4_H10_H9.jpg only).

G2 docs/shots/g2/3be2896/ A/B movement clips and .mp4 videos (680324c and 3be2896): Folder 3be2896/ had not landed at pinned HEAD 806233f766bfdfd98c61fbe5bebb834cc11bbe6c (context_E.md), and .mp4 files cannot be attached.

Standalone godot/portraits/crests/faction_<id>.svg files and admiral/Nemesis portrait image files (r8a, r8b, r8e): Only crests_all.webp (the 24 admiral Command crests sheet) was attached in the pack; the 6 standalone faction_<id>.svg files and the portrait .webp/.png sheets are not in the pack.
