Audit B: Voidsworn Godot port and travel sprint, blind review

I received no images on this leg. Every visual judgement below is marked NOT CHECKED. All other findings rest on the documents and listings in evidence_pack_B.md. Where the pack does not settle a question I say UNSURE.

1. G1 rules port

Is the record backed by the files?

The headline numbers in HANDOFF section 0 ("43/43 golden battles; 1,500 random battles with 0 diffs; nothing NOT PORTED") trace to two documents in the pack:

FINDINGS G-12, which states "PC lane B at 61c57fa: 43/43 golden battles, maths 316,090 values 0 diffs, campaign 30/30, worst enemy think 0.406 s (bar 0.5 s); 1,500 random battles swept with 0 differences; nothing NOT PORTED."

The parity README at contrib/opus/enginetest/results/g1_parity_2026-10-27/README.md, which gives the per-check tables.

Cross-checking the README against the HANDOFF claims:

| Claim | README evidence | Match? |
|---|---|---|
| 43/43 golden battles | PC lane B at 61c57fa, "Seeded battles s1 to s43: 43 of 43 PASS" | Yes |
| Maths 316,090 values, 0 diffs | Same table, "Maths, 316,090 inputs (including big-argument sin and cos): PASS" | Yes |
| Campaign 30/30 | Same table, "G3 campaign parity: 30 of 30 runs PASS" | Yes |
| 1,500 random battles, 0 diffs | "Running sweep record: Seeds 1, 2, 3 and 4 on the PC, seed 4 again and seeds 5, 6 and 7 in the cloud: 1,500 different random battles, 273,265 records, 0 differences" | Yes |
| Nothing NOT PORTED | FINDINGS G-12: "nothing NOT PORTED (only non-rule tooltip helpers and G3-owned encounter rolls remain JS-only)" | Yes |

The cloud later reached 47/47 at commit 48638ef (s44 through s47 added for stream B step 6 and the compact field). The HANDOFF's "43/43" is the PC record at the earlier commit 61c57fa. No contradiction; the cloud simply ran later scenarios.

The repo listing backs the test infrastructure: godot/rules/test/ contains README.md (10,591 bytes), scenarios.json (32,618 bytes), parity_main.gd (10,279 bytes), api_smoke.gd, thread_test.gd, run_parity.sh, run_sweep.sh, a node/ directory and an oracle/ directory. The main port is godot/rules/rules.gd at 209,559 bytes, with jsm.gd at 30,367 bytes and battle_api.gd at 44,820 bytes. These sizes are consistent with a substantial, complete port.

Could the parity test pass while being wrong?

I looked for three failure modes:

Too few fields compared. The README states each record holds "the whole battle state in canonical form (B, every unit, and the rules state kept outside B: the board cut-outs, the hexes that block sight, the id counter), including the battle log, a SHA-256 of that state, and the PRNG state." Integers must match exactly; every other number is compared as its exact 64-bit double with "no tolerance anywhere." Records are written at 18 distinct point types (start, move, rotate, fire, death, ram, board, nova, blink, ability, order, command, wing order, tick, end turn, end activation, activation, round, end result). This is a full-state comparison, not a summary. I see no evidence of a shallow comparison.

Weak scenarios. The 47 golden scenarios cover engagements, carriers, all fight types, both AI modes, every faction's Nemesis fight, every battle signature, every weakness type, the dead-star board, rift and shoals boards, arc hulls, and the compact field. The s47 entry is notable: "A coverage pass (COVER=1 node node/golden.js ...) found that no golden took this branch: s20's note claimed it, but s20 fields three ships." This shows they run coverage analysis and add scenarios when gaps appear. The sweep generator varies "fight type, shape, map, deployment, kind, sector, column, both factions, the admiral and so the Command, the player fleet, generated enemy fleets, boons, relics, aspect, heat, veteran captains, AI level, Classic mode, campaign events, the Nemesis with his R42 and R49 fields (persona, traits, faction special, honed, riches, fed, memory lines), bot." This is broad. One residual gap: the README notes "survivorsP is dead code in the JS too," so there is at least one function neither side exercises. That is not a parity risk (both sides skip it) but it is dead weight.

Self-referential oracle. The oracle is the pinned JS source (battle.js and core.js at d8b47c6, data.js at 6b1571e) in godot/rules/test/oracle/. The Godot port is compared against the JS game, not against an independent reference. This means if the JS game has a rules bug, the Godot port will reproduce it and the test passes. That is inherent to a parity test: it verifies "Godot does what JS does," not "both are correct." The correctness of the JS rules is stream B's job (balance sims, owner playtests). For the stated purpose (a faithful port), the oracle is appropriate. The data export (node/export_data.js) writes tables from data.js, core.js and battle.js to godot/rules/data/tables.json, with a SHA-256 check on load and a scan that fails if a table the port reads is missing. Non-integer numbers are written as exact IEEE hex. These are strong guards against data drift.

One structural note: the NOT PORTED hard stop ("anything a battle reaches that the port does not carry stops the run with NOT PORTED: <rule>") only fires for rules actually reached by the scenarios or the sweep. A rule path that no scenario or random battle hits would not be caught. The coverage pass mitigates this, but it is not a proof of completeness.

Any JS rules area with no Godot counterpart?

The pack names three JS rules files: battle.js, core.js, data.js. The Godot side has rules.gd (the port of battle.js and core.js rules), jsm.gd (JS number semantics, fdlibm math, PRNG), and battle_api.gd (the API the scene calls). Data flows through the export pipeline to tables.json. FINDINGS G-12 explicitly states "only non-rule tooltip helpers and G3-owned encounter rolls remain JS-only." The pack does not include a full listing of the JS source tree, so I cannot independently confirm there is no fourth JS file with rules logic. UNSURE on that narrow point, but the three named files all have Godot counterparts and the parity test's table-export scan would catch a missing table.

G1 verdict: the record is internally consistent and backed by the documents in the pack. The test design is strong. No defects found.

2. G2 whole game

Do the documents agree on the claimed flow?

The sprint goal (R35, in the plan's travel sprint section) requires: "the Godot version does everything today's game does, from title to final boss, with parity PASS, a bot that has played many full runs with 0 errors, the new look and ships, and a Windows build he starts from a .bat."

Checking each element across the three documents:

| Element | HANDOFF section 0 | Plan table (G2 row) | FEATURES.md |
|---|---|---|---|
| Title to final boss | "Built: title to final boss" | "Title to final boss" | "One program: title, campaign, battles, back to title (godot/main): done" |
| Windows build | "the Windows build" | "Windows build" | "Windows build (.exe): done on the PC... exe smoke test pending" |
| Smart bot | "100 smart runs with 0 hangs, then 36 runs across all six factions, 34 of them clean" | "smart bot 100 runs 0 hangs" | "Headless full runs with both sides on AI: done: --bot-runs N" |
| Worst round under 15 s | "every battle's worst round is under 15 s" | "pace under 15 s per round" | "a 20-ship sector 3 fight measured 30.1 s mean, now 13.4 s; a 10-ship fight 6.4 to 7.2 s" |

The three documents agree on all four elements. The HANDOFF adds the detail "36 runs across all six factions, 34 of them clean," meaning 2 runs had issues. The plan table does not mention those 2 unclean runs. This is not a contradiction (the plan table cites the 100-run figure), but the 2 failures in the 36-run set are worth tracking. Severity: NOTE.

The exe smoke test gap. FEATURES.md (godot/main/FEATURES.md, "Last update: Oct 26 2026 evening") says of the Windows build: "done on the PC (the preset writes ../export from build\godot, so build\export\Voidsworn.exe); test folders kept out of the package; --check-export on the exe checks that; exe smoke test pending." The build pipeline works and the export check passes, but nobody has confirmed the exe actually launches and runs. The sprint goal says Ryan "starts from a .bat." FEATURES.md confirms "Double-click start for Ryan: done: tools/pc/play_godot.bat (runs the exported .exe when present)." If the exe is broken, the .bat is broken too, and Ryan cannot test on return. Severity: FIX. The build exists and the pipeline is verified, but the final artifact has not been launched. This should be resolved before Ryan returns.

Bot run details. The HANDOFF reports "100 smart runs with 0 hangs, then 36 runs across all six factions, 34 of them clean." The 2 unclean runs out of 36 are not described. The pack does not say what "unclean" means (crash, wrong result, timeout). UNSURE what the 2 failures were. If they are known and benign, this is a NOTE. If they are uninvestigated, it is a FIX.

Movement approach (R54). HANDOFF marks "thruster-true movement (R54: main drive on the hull axis, RCS turns and sidesteps, trails from real nozzles)" as IN PROGRESS. The plan table confirms: "thruster-true movement in progress (R54)." Because this is marked IN PROGRESS, its incompleteness is not a defect per the audit rules. The approach itself (main drive along the hull axis, side thrusters for lateral movement, trails from nozzle positions) is physically grounded and standard for Newtonian-style ship movement in games. I cannot judge the visual execution. Film strip image: NOT CHECKED.

The current movement system (R50) is listed as done in FEATURES.md: "mass-scaled burn and braking, hulls swing and bank into turns, big hulls arc, overshoot and settle, engine flare on the burn, RCS puffs on turns and stops, wings trail a beat behind." The R54 work refines this. No conflict.

Anything the plan says should exist that no document or listing backs up?

The plan's G2 folder ownership lists godot/scenes/battle/, godot/render/, godot/ui/battle/, godot/audio/, godot/main/, and project.godot. The repo listings in the pack show godot/main/ (with main.gd at 19,355 bytes, title.gd at 10,950 bytes, campaign_host.gd at 14,032 bytes, campaign_fallback_ui.gd, main.tscn) but do not list godot/scenes/battle/, godot/render/, godot/ui/battle/, or godot/audio/. The pack's listings are not stated to be exhaustive, and FEATURES.md references all of these as done. I cannot confirm their existence from the pack alone. UNSURE. This is an evidence gap in the pack, not necessarily a project gap.

3. G3 campaign

Map rebuild claim. HANDOFF section 0 states: "G3 campaign: DONE. The R51 map is rebuilt as a Sins 2 style star system over 4 rounds (docs/shots/g3_campaign/8a12941/)." The plan table agrees: "G3 campaign: DONE Oct 27. Campaign parity green; R51 map rebuilt as a star system (4 rounds)."

The repo listing confirms the evidence folder exists: "docs/shots/g3_campaign/8a12941/: 32 webp shots, before and after pairs: map, hover, zoom, low, sector2, and stop types (belt, drydock, event, field, flagship, nebula, planet, shipyard, station, sun, wreck)." The 32 shots covering 11 stop types plus map views, hover states, zoom levels and a second sector suggest a thorough visual record.

The R51 spec calls for: planets on orbits, moons, belts, glowing jump lanes, the Hollow Sun huge at the centre, high-quality stops and icons, decluttered. I cannot verify any of these visual qualities. Map images: NOT CHECKED.

Campaign parity. The G1 parity README records "G3 campaign parity: 30 of 30 runs PASS" at both the 61c57fa PC run and the 2b91ea4 PC run. FINDINGS G-12 confirms "campaign 30/30." The G3 campaign rules are ported and tested through the same parity harness as G1.

Evidence gap. The repo listings do not show godot/campaign/, godot/ui/campaign/, or godot/scenes/campaign/, which the plan assigns to G3. FEATURES.md lists all campaign screens with "Rules (G3): done" and "Drawn: fallback" for most screens. The "fallback" status means G2's campaign_fallback_ui.gd (listed in godot/main/) is drawing the campaign screens until G3's own UI is ready. This is consistent with the plan (G3 owns the rules and the campaign UI, G2 provides the fallback). But the absence of the G3 directories from the listing means I cannot confirm the campaign code exists in the repo. UNSURE. The documents claim it is done; the listing does not show the folders.

One NOTE: FEATURES.md shows every campaign screen's "Drawn" column as "fallback" except "Battle: real battle in the battle scene, retreat: done" and "Map: G3's 3D star-system map takes its place." If Ryan returns expecting the new Sins 2 map to be the playable campaign map (not just a screenshot), the "fallback" status on all other screens means the campaign UI is still the temporary version. The map itself may be rebuilt, but the screens around it (fleet, shipyard, events, rewards) are still fallback. This is not a defect (the rules are done, the drawing is G3's UI work), but it is worth flagging so Ryan's expectations match reality. Severity: NOTE.

4. G4 effects and world

What is claimed. HANDOFF section 0 lists as built: "per-weapon hull marks with glow that carries to the battle camera, mass-scaled hit reactions, per-faction shield breaks, wrecks from the real hulls, cratered asteroids, and the dead-star black hole with Doppler beaming (docs/shots/g4/f3603c9/)." IN PROGRESS: "flak readability, lasting scars, and the Jolt convex-hull guard."

The repo listing confirms docs/shots/g4/f3603c9/ with 7 jpgs: "asteroids and lighting, asteroid close before/after, dead star board, wrecks and rocks, frigate marks at battle camera, ram crumple, weak marks comparison." The G4 code is in godot/fx/ with substantial files: fx.gd (29,804 bytes), fx_breach.gd (61,751 bytes), fx_death.gd (34,657 bytes), fx_hull.gd (9,899 bytes), fx_shaders.gd (68,563 bytes), fx_ship.gd (50,044 bytes), fx_weapons.gd (50,757 bytes), faction_look.gd, faction_looks.json (2,397 bytes), plus fx_pool.gd, a gallery/ directory and a test/ directory.

Visual judgement on the dead star board, weapon marks, and other effects: NOT CHECKED (no images on this leg).

Is the look data-driven?

The faction_looks.json file (godot/fx/faction_looks.json, 2,397 bytes) has a _doc field that reads: "Per-faction colours and styles for effects, hulls and backdrops (G4). Linear RGB. Read by fx/faction_look.gd. Change a faction's look here, not in code. See fx/API.md section 15."

Each of the six factions (voidsworn, hegemony, corsair, chorus, ithar, deathless) has: weapon colour, shield colour, engine colour, shield_style (integer), trail (integer), shielded (boolean), engine_extra (string), damage_glow colour, hull_fix colour, nebula colour array, accent (null for all), shield_edge (null for all).

This is properly data-driven. Colours and style indices live in JSON, not in code. The faction_look.gd script reads the JSON. Changing a faction's palette requires editing one JSON entry, not touching GDScript. The design is sound.

Do shields keep faction colours?

The owner ruling requires shields to keep faction colours. In faction_looks.json, each faction has a distinct "shield" colour:

voidsworn: [1.0, 0.46, 0.16] (orange)
hegemony: [0.38, 0.68, 1.0] (blue)
corsair: [0.85, 0.16, 0.10] (red)
chorus: null, with "shielded": false
ithar: [0.72, 1.0, 0.86] (teal-green)
deathless: null, with "shielded": false

Chorus and Deathless have no shields (shielded: false, shield: null), which is a faction design choice, not a missing colour. The four shielded factions each have a unique shield colour that matches their faction palette. The data backs the ruling. Severity: no issue.

Performance at about 20 ships.

The pack shows fx_pool.gd in godot/fx/, which indicates object pooling for effects. Pooling is the standard approach to avoid allocation churn with many simultaneous effects. The G2 section of FEATURES.md mentions a pace fix where "G4 volleys now follow the pace (they played at full length, so big fights ran 20 to 30 s of enemy time a round; a 20-ship sector 3 fight measured 30.1 s mean, now 13.4 s)." This confirms 20-ship battles exist and were measured. The fix brought the round time under the 15 s bar.

However, the pack does not include frame-rate data, GPU timings, or a performance budget. The shader file (fx_shaders.gd) is 68,563 bytes, suggesting substantial shader work. Whether 20 ships with per-weapon marks, shield effects, trails, and the black-hole lensing hold a playable frame rate is UNSURE from the pack. The reduce-flashing option and the graphics quality settings (MSAA, shadows, SSAO, SSIL, haze per FEATURES.md) provide scaling levers. The compatibility renderer (play_godot_safe.bat) exists as a fallback but "draws no hull damage marks yet (G4: decals are off there)."

Severity: NOTE. No evidence of a performance problem, but no evidence of a performance budget or frame-rate target being met at 20 ships either.

5. A4 ships

I received no images on this leg. All visual judgements in this section are NOT CHECKED.

The repo listing confirms the evidence exists: docs/shots/a4/46a89fe/ contains 12 webp files: "painted sweeps for C13s, C14s, C15s, C16s (Corsair), V14, V15, V16, V17, V18, V1b (Voidsworn), plus corsair_lineup and voidsworn_lineup."

HANDOFF section 0 states: "Pass 3 is done for Corsairs and Voidsworn (docs/shots/a4/46a89fe/). IN PROGRESS: the Pyre-Barge redesign to match C13s to C16s (R54), the Hegemony naval hull reshape, the V17/V1b gothic peaks, the I16 masts, and the lance-slot fan pattern."

The CLAUDE.md rules in the pack define what to check: no naval tells (keels, masts, funnels, porthole rows), no backward guns, no floating or sunk parts, matched symmetric pairs (Corsairs excepted), no blobs. I cannot perform these checks without seeing the images.

The IN PROGRESS items are not defects per the audit rules. The Pyre-Barge redesign, Hegemony reshape, gothic peaks, masts, and lance-slot fan are all explicitly in progress.

A4 verdict: NOT CHECKED for all visual items. The file listing confirms the work products exist. The IN PROGRESS items are acknowledged.

6. Stream B rules

What is claimed. HANDOFF section 0: "Stream B rules: admiral band and faction tune; the PC confirmation set is running." The plan table has two B rows:

B1 "Fix what can eat a win": IN PROGRESS. "Every listed fix done with a scripted check (contrib/opus/tools/b1_tests.js, 35 ok), onboarding 1 to 5 and enemy markers included. PC smoke test PASSED (Oct 25, 0 errors). Left: Ryan's playtest run."

B2 "Faster, then bigger battles": BUILT, waiting on Ryan's playtest. "Faster (enemy waits about halved: sector 3 21.8 to 8.0 s per round in the real browser), the size ramp (about 9 / 13 / 18 ships), one batched prize screen with add, strip or ransom (R23). Checks: fuzz 2000 0 exceptions (S9), check pack 0 FAIL, b1_tests 39 ok. Sector 1 boss spread now 57 to 89% (S6 fixed: Mending, Voice, Vesh start fleets trimmed, Kassar guns 5% lighter)."

Do the balance changes have before-and-after sims?

The plan table for B0 (ground truth, DONE Oct 25) states: "Mega sim: all legs exit 0, no exceptions; baseline in contrib/opus/compute/balance_reference.md; FINDINGS S1 to S7." This establishes a baseline.

B2 cites specific before-and-after numbers:

Enemy wait time: sector 3 went from 21.8 s to 8.0 s per round.
Sector 1 boss spread: now 57 to 89%, attributed to S6 fix (Mending, Voice, Vesh start fleets trimmed, Kassar guns 5% lighter).
Fuzz test: 2000 runs, 0 exceptions (S9).
b1_tests grew from 35 ok (B1) to 39 ok (B2).

These are concrete before-and-after figures. The baseline is in contrib/opus/compute/balance_reference.md (not included in the pack, so I cannot inspect it). FINDINGS S1 through S7 and S9 are referenced but not included in the pack. UNSURE whether the FINDINGS contain the detailed sim logs.

The admiral band (step 5) and step 5b changes are covered by golden scenarios in the G1 parity record: s42, s43 for the admiral band (Reyes, Matriarch), existing goldens for Malek and Ashgrove. Step 6 (arc hulls) has s44 through s46. The Mending Choir and Nekhet regrowth change (6% to 4%) is covered by s15 and s28. These are parity checks (does Godot match JS after the change), not balance sims (is the change good for gameplay). The balance justification would be in stream B's own sim work.

The HANDOFF says "the PC confirmation set is running," which means the final sim confirmation is not yet complete. The plan table says B1 is IN PROGRESS with "Left: Ryan's playtest run." B2 is "BUILT, waiting on Ryan's playtest."

Assessment. The balance changes have before-and-after numbers for pace (21.8 to 8.0 s) and boss spread (57 to 89%). The baseline document exists (contrib/opus/compute/balance_reference.md). Fuzz testing shows 0 exceptions over 2000 runs. However, the pack does not include the balance_reference.md or the FINDINGS S1-S9 documents, so I cannot verify the sim methodology or the full before-and-after data. The PC confirmation set is still running. Severity: NOTE. The structure is there (baseline, scripted checks, fuzz, golden scenarios), but the final confirmation is incomplete, and the pack does not include the underlying sim documents.

7. Music and portraits

Music

Licence check. CREDITS.md (godot/music/CREDITS.md, 18,739 bytes) lists 24 tracks. Every licence is one of: CC0 1.0, CC BY 3.0, or CC BY 4.0.

CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/) dedicates the work to the public domain. Commercial use is unrestricted. No NC, ND, or SA conditions apply.

CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/) requires attribution. Commercial use is allowed. No NC, ND, or SA.

CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/) requires attribution. Commercial use is allowed. No NC, ND, or SA.

All 24 tracks use licences compatible with a commercial Steam release. No track uses NC, ND, or SA. The file's own licence check section states: "Rules (R40): CC0 first; CC BY accepted with attribution; no NC, ND or SA licences; no source without a clear licence on its page."

One entry needs attention: the Fanfares page (source for sting_victory.ogg, sting_champion.ogg, sting_lose.ogg) "offers CC-BY 4.0, CC-BY 3.0, CC-BY-SA 4.0 and CC-BY-SA 3.0." The CREDITS.md notes: "used under CC-BY 4.0 only." This is correct: CC BY 4.0 is selected from the available options, and CC BY-SA is not used. The attribution text for each sting cites CC BY 4.0 specifically. No issue.

Credit completeness. Each of the 24 entries has: file name, title, author, source page URL, licence, licence URL, exact attribution text, and a description of changes made. The 17 unique source pages are listed. I count 17 unique sources across 24 tracks (SRG774's Dark Sci-Fi Audio Pack provides 4 tracks, NorthFantasyMusic's Intense Percussions provides 3, Spring Spring's Fanfares provides 3, Emma_MA provides 2).

The fac_deathless.ogg entry is the most complex: "Claimed by the void, new factory, AI fight and simulation unknown (vitalezzz vs Tricksntraps)" by "vitalezzz, tricksntraps (mix by glitchart)," CC0 1.0. The attribution text names all three contributors and the source page. The note confirms: "Mix by glitchart of 'Claimed by the Void' by vitalezzz and 'new factory', 'AI fight', 'Simulation unknown' by tricksntraps, all CC0." A mix of CC0 works is CC0. The attribution is thorough. No issue.

Spot-check of source links. I cannot browse the web from this leg. I can assess internal consistency: all 17 source pages are on opengameart.org, a well-known free game asset repository. The URLs follow OpenGameArt's standard path format (/content/slug or /node/id). The boss_final.ogg entry uses a node URL (https://opengameart.org/node/73591) rather than a content slug, which is valid for older OpenGameArt submissions. The CREDITS.md states "All 17 source pages were read on Oct 26 2026 and read again on Oct 27 2026 (licence, author, attached file names, attribution notes); each matched the entries above." I cannot independently verify this. UNSURE on live page verification. I would flag three URLs for spot-checking if I had web access:

https://opengameart.org/content/fanfares (Spring Spring, CC BY 4.0, source of three stings)
https://opengameart.org/content/dark-sci-fi-audio-pack (SRG774, CC0, source of four tracks)
https://opengameart.org/content/intense-percussions (NorthFantasyMusic, CC BY 3.0, source of three tracks)

These three pages account for 10 of the 24 tracks, so verifying them would cover a large fraction.

Any entries that look wrong or unverifiable? No entry has a missing author, missing source, or a licence outside the allowed set. The sting_fanfare.ogg entry credits "Spring Spring (Julie Damsgaard)" and the attribution reads "Produced by Julie Damsgaard/Spring Spring/Spring Enterprises @ https://spring-enterprises.neocities.org." The neocities.org URL is a personal site, not the OpenGameArt source page. The actual source page is https://opengameart.org/content/just-a-random-fanfare. The neocities link is supplementary. No issue, but the dual naming (Spring Spring / Julie Damsgaard / Spring Enterprises) is unusual. The CREDITS.md handles it by including all names in the attribution. NOTE at most.

Portraits

HANDOFF section 0: "Portraits: 24 Nemesis portraits in game, and new-look prompts drafted. Painting is held for lore approval."

The repo listing shows godot/portraits/ with: README.md (10,950 bytes), index.json (21,749 bytes), portraits.gd, and directories alts/, crests/, nemesis/, painted/, sheets/, test/. The nemesis/ directory exists, consistent with the claim. index.json at 21,749 bytes could hold 24 entries with metadata (roughly 900 bytes per entry). But the pack does not include the contents of index.json or a file listing of nemesis/, so I cannot confirm the count of 24. UNSURE on the exact count.

The "painted/" directory exists. The HANDOFF says "Painting is held for lore approval." If painting has not started, the painted/ directory may be empty or contain only drafts. The pack does not list its contents. UNSURE.

No mismatch is visible between the claim and the listing structure, but the count of 24 cannot be verified from the pack.

8. Cross-stream

Folder ownership collisions

The plan's travel sprint section assigns folder ownership. One overlap is explicit:

G2 owns godot/render/.
G4 owns godot/render/look.gd.

G4 owns a specific file inside a G2-owned directory. The plan lists this explicitly, so it is intentional, but it creates a touch point where two streams edit the same directory. If G2 restructures godot/render/ or if G4's look.gd depends on G2's renderer internals, a merge conflict or integration break is possible. Severity: NOTE. The plan acknowledges the split, but the owner should be aware of the coupling.

No other folder collisions are visible. The assignments are:

G1: godot/rules/, parity tooling
G2: godot/scenes/battle/, godot/render/, godot/ui/battle/, godot/audio/, godot/main/, project.godot
G3: godot/campaign/, godot/ui/campaign/, godot/scenes/campaign/
G4: godot/fx/, godot/world/, godot/render/look.gd
A4: tools/blender/a4/, assets/ships/<code>/, godot/assets/ships/
B: JS game files, sims, oracle
Story: godot/story/, godot/ui/career/
Music/portraits: godot/music/, godot/portraits/, tools/portraits/

These are disjoint except for the godot/render/ overlap above.

Document disagreements

I checked HANDOFF, the plan table, FEATURES.md, and FINDINGS G-12 for conflicts:

G1 battle count. HANDOFF says "PC: 43/43 golden battles." The parity README's latest cloud check at 48638ef says "47 of 47 battles." These are different commits (PC at 61c57fa, cloud at 48638ef). Not a disagreement; the cloud ran later scenarios. No issue.

G2 status. HANDOFF says "Built." Plan table says "BUILT Oct 27, polishing." FEATURES.md says features are "done" with specific gaps (exe smoke test pending, concept-art hulls not carried over). The word "polishing" in the plan and "exe smoke test pending" in FEATURES.md are consistent: the build is functionally complete but not fully verified. No disagreement.

Bot run results. HANDOFF: "100 smart runs with 0 hangs, then 36 runs across all six factions, 34 of them clean." Plan table: "smart bot 100 runs 0 hangs." The plan table omits the 36-run set and its 2 unclean runs. This is a minor omission, not a contradiction. NOTE.

Campaign screen drawing. FEATURES.md lists all campaign screens as "Drawn: fallback." HANDOFF says "G3 campaign: DONE." The "DONE" refers to the rules and the map, not the UI drawing. FEATURES.md clarifies: "Campaign screens (rules: G3, done with parity; drawing: G3's ui/campaign, until then the G2 fallback)." No disagreement, but a reader of HANDOFF alone might think the campaign UI is finished when it is still on fallback. NOTE.

Stream B status. HANDOFF: "admiral band and faction tune; the PC confirmation set is running." Plan table: B1 is IN PROGRESS, B2 is BUILT waiting on playtest. The HANDOFF does not use the B1/B2 labels and does not mention that Ryan's playtest is still needed. Not a contradiction, but less specific. NOTE.

Claims not backed by repo listings

The repo listings in the pack show: godot/rules/, godot/main/, godot/fx/, godot/music/, godot/portraits/, tools/blender/, docs/shots/. The following directories are referenced by the plan and FEATURES.md but do not appear in the pack's listings:

godot/scenes/battle/ (G2)
godot/render/ (G2) and godot/render/look.gd (G4)
godot/ui/battle/ (G2)
godot/audio/ (G2)
godot/campaign/ (G3)
godot/ui/campaign/ (G3)
godot/scenes/campaign/ (G3)
godot/world/ (G4)
godot/assets/ships/ (A4)
godot/story/ (Story)
godot/ui/career/ (Story)
project.godot (G2)
tools/pc/ (parity.bat, play_godot.bat)
contrib/opus/ (various)

The pack's listings appear to be a selection, not a full tree. Multiple documents reference these directories as existing and functional. I treat the absence from the listing as an evidence gap in the pack, not as evidence the directories are missing. UNSURE. However, this means I cannot independently confirm from the pack that the G2 battle scene, the G3 campaign code, the G4 world code, or the project.godot file exist in the repo. The documents say they do; the listing does not show them.

One specific item: FEATURES.md references "tools/pc/play_godot.bat" and the plan references "tools\pc\parity.bat." The repo listing shows tools/blender/ but not tools/pc/. UNSURE whether tools/pc/ exists. The parity README says "On the PC: double-click tools\pc\parity.bat." If this file is missing, the PC parity workflow is broken. But the listing may simply omit it. UNSURE.

Top three problems

1. FIX. The Windows exe has not been smoke tested. FEATURES.md (godot/main/FEATURES.md, last update Oct 26) states "exe smoke test pending" for the Windows build. The sprint goal (R35, plan travel sprint section) requires "a Windows build he starts from a .bat." The build pipeline works and --check-export passes, but the actual exe has not been launched. If it fails to start, Ryan cannot test anything on return. The play_godot.bat wrapper (listed as done in FEATURES.md) runs the exe, so an untested exe means an untested .bat too. This should be resolved before Oct 30.

2. FIX. Two of 36 bot runs were not clean, and the failures are not described. HANDOFF section 0 reports "36 runs across all six factions, 34 of them clean." The 2 unclean runs are not explained in any document in the pack. The plan table omits them entirely (citing only "smart bot 100 runs 0 hangs"). If the 2 failures are known, benign, and tracked, this drops to NOTE. If they are uninvestigated, they represent a gap in the "bot that has played many full runs with 0 errors" goal. The owner needs to know whether those 2 runs hit a real bug.

3. NOTE. The campaign UI is on fallback for every screen except the battle itself. FEATURES.md lists all campaign screens (admiral pick, aspect pick, briefing, sector map, fleet, shipyard, drydock, events, victory, sector change, progression, how to play, run end) as "Drawn: fallback." HANDOFF says "G3 campaign: DONE," which is true for the rules and the map, but a reader could expect the full campaign UI to be finished. Ryan returning to test the campaign will see the fallback UI for most screens, with the 3D star-system map only on the map screen. This is not a defect (the plan assigns the UI drawing to G3 and it is not marked done), but the HANDOFF's "DONE" without qualification may set the wrong expectation.

Verdict

The sprint is on track for the owner to test on return, with one prerequisite: the Windows exe must be smoke tested before Ryan sits down, and the 2 unclean bot runs need a written disposition. The rules port is thoroughly verified, the game flow is documented consistently across three documents, the music licensing is clean, and the data-driven effects architecture is sound. The main risks are the untested exe and the gap between "DONE" in HANDOFF and "fallback UI" in FEATURES.md for the campaign screens.
