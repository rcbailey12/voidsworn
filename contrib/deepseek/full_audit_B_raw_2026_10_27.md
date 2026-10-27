Blind review: Voidsworn catch-up audit, Audit B (Godot port and travel sprint)
I worked only from the attached evidence pack and the six images. Where the pack does not settle something I say UNSURE. Claims about the repo cite the file path or the listing entry from the pack. Claims about outside sources cite a link where I could check one.

1. G1 rules port

Is the record backed?
Yes, the numbers in HANDOFF section 0 and the G1 parity README are backed by the documents in the pack. The PC lane B table shows 43 of 43 seeded battles, maths 316,090 inputs PASS, PRNG 3 of 3, threat overlay 3 of 3, threads PASS, and G3 campaign 30 of 30. The sweep record in the same README says 1,500 different random battles with 273,265 records and 0 differences. HANDOFF section 0 repeats the same claims. The rules test README at godot/rules/test/README.md describes the same checks and the same 1,500 battle sweep. The repo listing backs the existence of the test harness: godot/rules/test/README.md (10,591 bytes), scenarios.json (32,618 bytes), parity_main.gd (10,279 bytes), oracle/ dir, and node/ dir.

Could a parity test pass while being wrong?
The design is stronger than a weak field check. The README says each record holds “the whole battle state in canonical form (B, every unit, and the rules state kept outside B: the board cut-outs, the hexes that block sight, the id counter), including the battle log, a SHA-256 of that state, and the PRNG state.” Every non-integer number is compared as its exact 64-bit double, with no tolerance. That is not too few fields. The oracle is a pinned snapshot at godot/rules/test/oracle/, so it is not self-referential to the live JS. The sweep generator varies fight type, map, deployment, faction, admiral, boons, relics, aspect, heat, AI level, Classic mode, campaign events and the Nemesis fields. That is wide coverage, not weak scenarios.

Two residual risks. First, the README records that “s32 and the thread test were killed by a SIGTERM from outside the run on the first full pass” and that both passed when run again. A flaky first pass is a FIX, not a blocker, but it shows the test run can be disturbed by other load. Second, the PC lane B parity record is for commit 61c57fa, while the pack says HEAD at leg start is 172f019. The README says later cloud checks were done at 02f23da, 48638ef and 2b91ea4, but there is no PC lane B full parity run at the actual HEAD in this pack. The record is therefore strong for the commit it names, not for the exact HEAD the owner will test. I tag that FIX (stale parity record relative to HEAD).

JS rules area with no Godot counterpart visible?
The repo listing shows godot/rules/rules.gd (209,559 bytes), battle_api.gd (44,820), jsm.gd (30,367), and godot/rules/data/ dir. The README says the port is “a GDScript port of the game’s battle.js” and that node/export_data.js writes every data table from data.js, core.js and battle.js to godot/rules/data/tables.json. So the visible listing does not show a separate core.gd, but rules.gd is large enough to carry core logic, and the data export path covers all three JS files. The README also says the only remaining JS-only items are “non-rule tooltip helpers and G3-owned encounter rolls.” I mark that as a NOTE: the pack does not give a one-to-one file map, so a reader cannot confirm from the listing alone that every core.js function has a named counterpart, but the parity record and the data export path make a missing rule unlikely.

2. G2 whole game

Does the claimed flow hold together?
Mostly yes, with three visible gaps.

Title to final boss: HANDOFF section 0 says “Built: title to final boss” and the plan table says G2 is “BUILT Oct 27, polishing.” godot/main/FEATURES.md lists “One program: title, campaign, battles, back to title” as done. That row is backed by godot/main/main.gd (19,355 bytes), title.gd (10,950), campaign_host.gd (14,032), main.tscn in the repo listing. The flow is claimed and the files exist.

Windows build: godot/main/FEATURES.md says the build is “done on the PC” but also says “exe smoke test pending.” HANDOFF section 0 says “the Windows build” is built. The repo listing has no export/ dir or .exe, which is expected because the build lives on the PC outside git. The disagreement is between “built” and “exe smoke test pending.” That is a FIX: the owner is told the build is ready, but the one check that the exported exe actually starts is still pending.

Smart bot: HANDOFF says “100 smart runs with 0 hangs, then 36 runs across all six factions, 34 of them clean.” godot/main/FEATURES.md says headless full runs are done with --bot-runs N, a Logger for errors and a --run-timeout hang guard. The listing backs the files, but the pack does not include the bot run logs. The 34 of 36 clean figure is a self-reported result, not a file in the pack. That is a NOTE: the claim is plausible and consistent across documents, but the evidence is a sentence, not a log.

Worst round under 15 s: The G1 parity README gives worst round totals for s4 (1.478 s), s5 (1.198 s) and s23 (1.496 s) on the PC lane B run at 61c57fa. Those are far under 15 s. godot/main/FEATURES.md also records a 20-ship sector 3 fight that measured 30.1 s mean before a fix and 13.4 s after. That is under 15 s but close to the bar, and the same row says the fix holds G4 volleys to the browser’s volley length. I mark the 15 s claim as backed, with a NOTE that the 13.4 s example leaves little headroom if more effects are added.

Movement approach from the film strip (s9_dreadnought_strip.jpg): The strip shows a dreadnought moving with its main drive plume coming from the stern along the hull axis, and the hull turning with visible side puffs at the bow and stern. The trails come from the rear nozzles, not from a generic point at the centre. That is consistent with the described approach: main drive along the hull axis, RCS turns and sidesteps, trails from the real nozzles. The approach is sound. But HANDOFF section 0 says “IN PROGRESS: thruster-true movement (R54)” and godot/main/FEATURES.md says “Ship movement with weight (R50) ... done (RCS puffs drawn by the scene in G4’s puff colour).” The film strip shows the look, but the pack says the full thruster-true behaviour is not finished. I mark the approach sound but unfinished, FIX for the sprint goal (the owner is told the movement look is in progress, not done).

Plan items with no document or listing backing:

The sprint goal includes “the new look and ships.” HANDOFF says A4 pass 3 is done for Corsairs and Voidsworn, and G4 effects are “Built,” but many A4 items are IN PROGRESS (Pyre-Barge redesign, Hegemony naval hull reshape, V17/V1b gothic peaks, I16 masts, lance-slot fan pattern). The plan’s “new look and ships” is therefore partly backed and partly open.

The sprint goal includes “campaign to battle and back with G3.” godot/main/FEATURES.md shows the campaign screens as rules done, drawn fallback for almost every screen: “Sector map, node info, node modifiers” is “fallback (no map picture)”; “Fleet screen” is “fallback”; “Shipyard” is “fallback”; “Events and results” is “fallback”; “Victory, prize ships” is “fallback”; “Progression” is “fallback”; “How to play” is “fallback”; “Run end screen” is “fallback.” The only campaign screen drawn is “Battle: real battle in the battle scene.” This is a direct gap between the sprint goal (“the whole game”) and the FEATURES table (most campaign screens still fallback). I mark that FIX.

3. G3 campaign

Map images (after_m1_map.webp, after_m3_zoom.webp): The map reads as a star system. The Hollow Sun is huge at the centre, with a bright accretion disc. Stops sit on visible orbital rings. There are moons, belts, and glowing jump lanes. The stop icons are distinct: shipyard, drydock, field repairs, battle, elite battle, flagship, unknown signal. The labels are readable at the default zoom. The zoom image keeps the orbital structure and does not collapse into a flat grid. That is a genuine improvement over a node graph and it matches the Sins 2 description.

What still reads cheap or cluttered:

The map is dense. Several stops sit close together on the same ring, and the “Decapitation / Breakthrough / Shipyard” cluster near the top left has overlapping lane labels at default zoom. The zoom shot is cleaner, but the default view is busy.

The Hollow Sun is visually dominant in a good way, but the lane lines crossing in front of the accretion disc reduce the sense of depth. The lanes are drawn as flat lines over the glow, so the sun reads as a background picture rather than an object the lanes orbit.

The stop icons are small relative to the labels, so at default zoom the text carries more weight than the icons. That is a polish issue, not a structural one.
I mark the map mostly reading as intended, with NOTE for clutter at default zoom and NOTE for lane depth over the sun.

Campaign parity evidence gap: The G1 parity README says “G3 campaign parity 30 of 30 runs PASS” at 61c57fa and again at 2b91ea4. That is rules parity. The pack does not include a separate campaign UI parity check (screens, shop, rewards, prize screen, capture, retreat, saves, meta progression). HANDOFF says “Campaign parity is green,” but the only evidence in the pack is the G1 README’s 30/30 runs. That is a NOTE: rules parity is evidenced; UI parity is not separately evidenced.

4. G4 effects and world

Images: 03_dead_star_board_r10.jpg shows a black hole with a bright, asymmetric accretion disc and a dark event horizon. The disc has a warm inner edge and a cooler outer edge, and the lensing distorts the star field around it. That reads as a dead-star black hole, not a painted circle. 05_frigate_marks_at_battle_camera.jpg shows per-weapon hull marks at battle camera distance: burn, plasma crater, shell crater, gauss entry, torpedo blast, flak pocks, acid spines, ion burn, boarding hatch, ram crumple. Each mark has a different shape and glow. The marks persist at the battle camera, so they are not just close-up decals. The images back the “per-weapon marks” and “glow carries to the battle camera” claims in HANDOFF section 0.

Data-driven look: godot/fx/faction_looks.json (2,397 bytes) holds per-faction weapon, shield, engine, shield_style, trail, shielded, engine_extra, damage_glow, hull_fix, nebula, accent and shield_edge. The _doc string says “Read by fx/faction_look.gd. Change a faction’s look here, not in code.” That is data-driven for the properties it lists. The repo listing backs faction_look.gd and faction_looks.json in godot/fx/. I mark the look data data-driven, with one caveat: accent and shield_edge are null for all six factions, so those two properties are not yet used. That is a NOTE.

Shields keep faction colours: The data backs it. Voidsworn shield is [1.0, 0.46, 0.16] (orange), Hegemony [0.38, 0.68, 1.0] (blue), Corsair [0.85, 0.16, 0.10] (red), Ithar [0.72, 1.0, 0.86] (pale green). Chorus and Deathless have shielded: false and shield: null, so they have no shield colour by design. The owner ruling that “shields must keep faction colours” is satisfied for every faction that has shields.

Performance risk at about 20 ships: The pack does not include a frame-time profile at 20 ships. HANDOFF says the Jolt convex-hull guard is IN PROGRESS and the G4 effects list includes “physics debris,” “engine trails,” “black-hole lensing,” “per-weapon hull marks,” “staged damage,” “wrecks” and “per-faction shield breaks.” Those are many per-event effects. The G1 parity README’s worst think times are about rules AI, not rendering. godot/main/FEATURES.md says a 20-ship sector 3 fight had enemy time 30.1 s mean before the pace fix and 13.4 s after, which is a time-per-round measure, not a GPU frame budget. I cannot confirm or rule out a frame-rate risk at 20 ships from this pack. I mark it UNSURE, with a NOTE that the Jolt convex-hull guard is still in progress and a 20-ship profile is not in the evidence.

5. A4 ships

I checked the two lineups (corsair_lineup.webp, voidsworn_lineup.webp) against the CLAUDE.md rules. I cannot inspect every region from top, side and below from a single three-quarter lineup, so this is a visible-surface check, not a full blob sweep.

Corsairs (junky is on-brand, so asymmetry and haphazard mounts are allowed):

Warlord’s Pyre-Barge: The forward ring structure is a large open circle. It reads as a sensor or ram array, not a naval anchor or a bollard. The hull has no keel line, no raked stem, no porthole row. The guns are forward and turreted. No backward guns are visible. No floating or sunk parts are visible at this angle. Clean at this angle.

Hulk-carrier: Long hull with a flat deck-like spine, but no boat keel or raked bow. The turret is on a visible mount. No porthole row. Clean at this angle.

Marauder-class cruiser: Forward torpedo tubes and side scatter guns. The hull has a blunt bow, not a raked stem. No naval tells. Clean at this angle.

Reaver-class destroyer: The side scatter guns are on visible mounts and point outward. The hull is asymmetric, which is on-brand. No backward guns. Clean at this angle.

Raider-class frigate: The autcannon turret is on a visible mount. The hull is small and junky. Clean at this angle.
The Corsair sheet does not show a clear naval tell, a backward gun, or a floating part. The one thing I would put on a closer review list is the Pyre-Barge’s forward ring, because a large open ring can read as a “ram” if the mount is not visibly structural. At this angle it looks mounted. I mark the Corsair sheet clean at visible surfaces, with a NOTE to confirm the ring mount from below.

Voidsworn:

The lineup shows gothic spires on the dorsal side. The CLAUDE.md rule says “crossbar masts and smokestack funnels count as naval tells and become antenna arrays and heat radiators.” These spires are not crossbar masts and not smokestack funnels; they read as cathedral architecture. That is a different visual language, not a naval tell. However, the tallest spire on the lead ship is very close to a mast in silhouette. A strict reading of “mast ladders” and “yardarms with rigging” does not apply because there are no ladders or rigging, but the silhouette is mast-like. I mark that NOTE: the spires are lore-appropriate gothic peaks, but the tallest one should be checked against the “mast” tell at silhouette distance.

No backward guns are visible. The guns are forward or turreted.

No floating or sunk parts are visible at this angle.

The hulls are ornate, not blobby. The AI blob sweep is claimed in HANDOFF as “Pass 3 is done for Corsairs and Voidsworn,” but the pack does not include a region-by-region blob sweep report. I mark the Voidsworn sheet clean at visible surfaces except for the mast-silhouette note, and the blob sweep UNSURE because the report is not in the pack.

6. Stream B rules

The pack does not include before-and-after sims for the admiral band and faction tune. What it includes is:

The plan table’s B0 row: “Mega sim: all legs exit 0, no exceptions; baseline in contrib/opus/compute/balance_reference.md; FINDINGS S1 to S7.” That is a baseline, not a before-and-after for the admiral band.

The plan table’s B2 row: “Sector 1 boss spread now 57 to 89% (S6 fixed: Mending, Voice, Vesh start fleets trimmed, Kassar guns 5% lighter).” That is a result with a spread, but the pack does not include the sim log or the before-and-after distributions.

The G1 parity README says s42 and s43 cover “the admiral band” (Reyes with his strike group and Command, the Matriarch with her brood and two drones). That is parity coverage, not balance evidence. The same README says “The new start fleets are campaign data (G3); no battle rule reads them.” So the start-fleet trims are campaign data changes, and the pack does not include the campaign-side sim.

HANDOFF says “Stream B rules: admiral band and faction tune; the PC confirmation set is running.” That is a status, not a result.

I mark the Stream B balance claims partly unbacked. The plan table cites a baseline and a spread, but the pack does not contain the before-and-after sims for the admiral band or the faction tune. The parity record proves the rules match JS; it does not prove the balance is better. That is a FIX: a balance claim without a before-and-after sim is not reproducible from the pack.

7. Music and portraits

Licences: godot/music/CREDITS.md (18,739 bytes) lists 24 tracks. Every listed licence is CC0 1.0 or CC BY 3.0/4.0. There is no NC, ND or SA entry. That meets the commercial Steam release rule in the document. The licence check section says “All 17 source pages were read on Oct 26 2026 and read again on Oct 27 2026 ... each matched the entries above.” I spot-checked four source pages:

War Theme (ver 2), Spring Spring: The OpenGameArt page at https://opengameart.org/content/war-theme says “License(s): CC0” in the page text. The credit is complete (author, title, source link, licence). Matches.

Dark Ambient Drone, Tsorthan Grove: The OpenGameArt page at https://opengameart.org/content/dark-ambient-drone says “Copyright/Attribution Notice: Dark Ambient Drone by Tsorthan Grove - CC BY 4.0 - https://opengameart.org/content/dark-ambient-drone”. The credit is complete. Matches.

QaziJamJam, Emma_MA: The OpenGameArt page at https://opengameart.org/content/qazijamjam-orchestral-battle-theme says “This track has been released into the public domain as of January 2017.” The CREDITS.md lists it as CC0 1.0. Public domain is compatible with CC0 for a commercial release. The credit is complete. Matches.

Fanfares (VICTORY, WIN AGAINST CHAMPION, LOSE), Spring Spring: The OpenGameArt page at https://opengameart.org/content/fanfares shows “Copyright/Attribution Notice: Spring/Spring Enterprises” and lists the three files, but the snippet I retrieved does not show the licence selector. The CREDITS.md says the page offers CC BY 4.0, CC BY 3.0, CC BY-SA 4.0 and CC BY-SA 3.0 and that the three stings are used under CC BY 4.0 only. I could not confirm the licence from the page text I retrieved. I mark the Fanfares licence UNSURE from my spot check, not a confirmed mismatch. The CREDITS.md’s own licence check says it matched, so the weight of evidence is on the credit being correct, but the page snippet I saw does not settle it.
No entry looks wrong. The only unverifiable item from my spot check is the Fanfares licence. That is a NOTE to keep the page evidence on file.

Portraits: HANDOFF says “24 Nemesis portraits in game.” The repo listing shows godot/portraits/ with index.json (21,749 bytes), nemesis/ dir, painted/ dir, alts/, crests/, sheets/, test/ and portraits.gd. That backs the existence of a portrait pipeline and a Nemesis folder. The pack does not give the count of files in nemesis/, so the “24” is a claim from HANDOFF, not a listing count. I mark it backed in structure, count UNSURE. The “painting of final looks is held for lore approval” is consistent with HANDOFF and with the plan’s “lore round 6 waits on Ryan.” No mismatch is visible between the claim and the listing.

8. Cross-stream

Folder ownership collisions: The plan’s stream list gives G2 ownership of godot/render/ and G4 ownership of godot/render/look.gd. That is a collision: look.gd sits inside a folder G2 owns. The same list gives G4 godot/fx/ and godot/world/, which are separate. The godot/render/ collision is the only direct overlap in the text. It is a FIX, because two streams editing the same folder can produce conflicting changes. The listing shows godot/fx/ files and godot/main/ files, but the pack does not show the full godot/render/ listing, so I cannot say whether look.gd is the only file at risk.

Duplicated work: The A4 stream owns godot/assets/ships/ and assets/ships/<code>/, while G4 owns godot/render/look.gd and effects. Those are adjacent but not duplicated. The G2 movement work (R54) and the G4 engine-trail work overlap conceptually: G2 owns the movement and the pace, G4 owns the trails and puffs. The plan does not name a single owner for “engine trails,” so that is a NOTE for coordination, not a proven duplicate.

Documents that say different things:

Windows build: HANDOFF section 0 says “Built: ... the Windows build.” godot/main/FEATURES.md says “Windows build (.exe) ... done on the PC ... exe smoke test pending.” The two do not contradict on existence, but they differ on readiness. The FEATURES row is more cautious. FIX (owner-facing wording).

Campaign drawing: HANDOFF section 0 says “G3 campaign: DONE. The R51 map is rebuilt ... Campaign parity is green.” godot/main/FEATURES.md says the campaign rules are done but the drawing is “fallback” for almost every screen (sector map, fleet, shipyard, drydock, events, victory/prize, sector change, progression, how to play, run end). That is a real disagreement about what “campaign done” means. FIX.

G4 compatibility mode: HANDOFF section 0 says “G4 effects: Built: per-weapon hull marks...” godot/main/FEATURES.md says “Compatibility mode (play_godot_safe.bat) draws no hull damage marks yet (G4: decals are off there).” That is a caveat, not a contradiction, but the owner could read “built” as covering all renderers. NOTE.

B2 status: The plan table says B2 is “BUILT, waiting on Ryan’s playtest.” HANDOFF section 0 does not list B2 in the G-stream status. That is a coverage gap in HANDOFF, not a contradiction. NOTE.

Claims not backed by repo listings:

G1 parity is backed by the test README and the scenario file.

G2 Windows build is not in the repo listing (expected, PC artifact), and the exe smoke test is pending.

G4 effects are backed by godot/fx/ files and docs/shots/g4/f3603c9/ 7 jpgs, but the “20 ships at frame rate” claim has no profile in the listing.

A4 pass 3 is backed by docs/shots/a4/46a89fe/ 12 webp, but the actual godot/assets/ships/ contents are not listed, so the claim that the kit ships are “in godot/assets/ships” is not backed by a listing in the pack.

Music credits are backed by godot/music/CREDITS.md and music.json.

Portraits are backed by the godot/portraits/ listing, but the count of 24 Nemesis portraits is not backed by a file count in the pack.

Three most serious problems

Windows build exe smoke test is pending (FIX). HANDOFF tells the owner the Windows build is built, but godot/main/FEATURES.md says the exe smoke test is pending. The sprint goal is that the owner returns to a game he can test. An unverified exe is the one artifact that can stop him at the first step.

Campaign screens are still fallback, not the new look (FIX). godot/main/FEATURES.md marks the sector map, fleet, shipyard, drydock, events, victory/prize, progression, how to play and run end as “fallback.” HANDOFF says “G3 campaign: DONE.” The rules are done, but the owner will see fallback UI for most of the campaign. That is a direct gap against the sprint goal of “the whole game.”

G1 parity record is for an older commit than HEAD (FIX). The PC lane B record is at 61c57fa, while the pack says HEAD is 172f019. Later cloud checks exist, but the full PC lane B 43/43 and 1,500-battle sweep are not re-run at HEAD in the pack. A parity claim that is one commit behind is still strong, but it is not a guarantee for the exact build the owner will test.

Verdict: The sprint is close but not on track for a clean test-on-return: the rules parity evidence is strong and the map and effects are real, but the unverified exe, the fallback campaign screens, and the older-commit parity record are three concrete gaps the owner would hit or question on day one.
