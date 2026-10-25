# Voidsworn go-forward plan

Opus, Oct 24 2026. **Status: APPROVED by Ryan, Oct 24 2026, 22:13 CDT.** Basis: main at d5d0227 plus Ryan's answers of Oct 24 (21:44 to 22:11 CDT).

Companion files, all in `contrib/opus/`:
- `FINDINGS.md`: the findings registry, the single list of what is true, wrong or open.
- `verification-report-2026-10-24.md`: the full check of the Muse and outside-model pile, behind every decision here.
- `evidence/`: the detailed per-area check reports, with file:line quotes.

HANDOFF.md at the repo root is the short version and the place a new session starts.

## Headline

Two tracks run side by side.

**Ships and look:**
- The Pyre-Barge upgrade goes first, built in Blender so it works in either engine.
- In the same window, a 6-ship engine test runs: one flagship per faction, the same scene in Babylon and in Godot.
- You and I pick the engine before ship 2.

**Game:**
- First, get the facts straight and fix what can eat a win or a node.
- Then make battles faster.
- Then let battles grow over a run.
- Then faction identity, the ship-five, and the story.

**First steps:** Phase A0 (barge v14 files into git) and Phase B0 (registry, check pack, sim baseline) run in parallel. Then A1 step 1 (barge silhouette options) and B1 (bug fixes).

## Phase status

Updated by the build session as phases move. A phase is done when its exit check in sections 4 and 5 passes.

| Phase | Status | Where it stands |
|---|---|---|
| A0 Barge files into git | DONE Oct 24 | v14 files in hulls_hi/ and hulls/ (95f01b6, a687ef5). Side-by-side: docs/ship_pipeline/c19_example/a0_repo_vs_pc.webp. |
| B0 Ground truth | DONE Oct 25 | Guard and check pack (0 FAIL). Mega sim: all legs exit 0, no exceptions; baseline in contrib/opus/compute/balance_reference.md; FINDINGS S1 to S7. |
| A1 Barge upgrade | DONE (shape and paint signed off, R16) | Final barge effects moved to A5 per R16. |
| B1 Fix what can eat a win | IN PROGRESS | Every listed fix done with a scripted check (contrib/opus/tools/b1_tests.js, 35 ok), onboarding 1 to 5 and enemy markers included. PC smoke test PASSED (Oct 25, 0 errors; board shot docs/ship_pipeline/c19_example/v15/b1_enemy_markers_board.webp). Left: Ryan's playtest run. |
| A1 step 2 | DONE Oct 25 | v15 dressed barge approved (FINDINGS R13). Builder tools/blender/a1/barge_v15.py; sheets in docs/ship_pipeline/c19_example/v15/; v15 game files in hulls_hi/ and hulls/. |
| A1 step 3 | DONE Oct 25 | Paint approved (FINDINGS R14). Sheet docs/ship_pipeline/c19_example/v15/v15_paint_pass.webp; game files in git. |
| A1 step 4 | PARTLY DONE, REST MOVED TO A5 | Interim Corsair effects stay in the game (and B-16 fixed). Ryan's bar (R16): cinematic damage, weapons and trails like BattleTech, Sins and Rogue Trader. That bar goes into the A2 test now and into A5 in the winning engine. |
| A1 step 5 | DONE Oct 25 | Source of truth: tools/blender/a1/barge_v15.py plus glTF exports in assets/ships/C19_51/ (README has the chain). Automatic checks in the build: no floating parts, no backward guns, exports reimport clean (all PASS). |
| A2 Six-ship engine test | IN PROGRESS (widened R17 to R19, trimmed R20) | Babylon main and stress run on the PC; Godot main and stress running there now. Remaining: max-detail six ships (shared), max mode, 40-ship run, simple physics, depth of field and shake, the hex-board slice, Godot .exe. One combined blind reveal for A3. |
| B2 Faster, then bigger battles | IN PROGRESS | Started Oct 25 while A2 builds: items 1 to 3 (faster, the size ramp, capture rework). Item 4 (Dead Star backdrop) waits. |
| A3 to A5, B3 to B5 | NOT STARTED | |

## 1. What is decided

Ryan decided (Oct 24 answers):

1. **Battle size grows over a run.**
   - About 10 ships on board in sector 1, about 14 in sector 2, about 20 in sector 3 and boss fights.
   - 20 is a guide, not a cap. Difficulty decides, and it should make sense.
   - Your fleet stays small and elite (4 to 7 ships) while enemies grow. Fighter wings do not count.
2. **Dead Star stays as a real board.** The existing gravity well (slingshot, drag, rim damage) stays. The Dead Star painting becomes its backdrop and a finale backdrop.
3. **Shields keep their faction colours.**
   - The "cyan means shields, nothing else is cyan" rule is retired for 3D shields.
   - The shield bars and numbers in the interface stay cyan for every faction.
4. **Captured ships.**
   - In battle, a boarded enemy switches sides as now.
   - After a win, each prize gets one choice: add it (if you have command points), strip it (parts or modules), or ransom it (credits).
   - With a full fleet it auto-scraps for credits. Sector flagships cannot be captured.
5. **Engine.** The barge is built engine-neutral, and the 6-ship test runs in both engines. You and I pick before ship 2. A downloadable PC app is fine if Godot wins.
6. **Acceptance checks.** Your eye plus automatic checks (brightness scan, colourblind simulation, silhouette test). No 7-person viewer panels.
7. **One enemy commander per run** serves as both the Nemesis and the story-arc rival.
8. **Barge colours.** The Corsair "rust and bone" palette from the art direction, judged by you on screenshots.
9. **Space ships, never naval, applies to the whole hull shape,** not just the parts bolted on. Wherever the barge's hull reads as a boat, the v13d shell is open again.
10. **Chorus portraits** (Matriarch v3 verdict, new Mending direction) go on the backlog as their own item. Nothing waits on them.
11. **The repo stays public** on purpose.
12. **Sound stays as is,** Sonniss clips included.

All earlier rulings in OPUS_HANDOFF.md section 1 stand, except where 1 to 4 above refine them.

Technical calls I made are listed in the verification report, section A10 (mega sim, wait budget, tonemapper test, torpedoes, budgets and others). Any of them can be vetoed.

## 2. How work runs

- **Two tracks.**
  - Track A (ships and look) is mostly Blender and art pipeline work, run on your PC.
  - Track B (game) is rules, campaign and interface code, worked in the cloud and tested in the headless sim, then on your PC.
- **Until the engine call,** no new Babylon-only rendering work beyond what the test and today's game need. Rules and campaign fixes are worth doing either way: in Babylon they ship as is, and in Godot the same logic gets retyped, not redesigned.
- **What you see:** screenshots and short clips at every visual step, and a double-click .bat for anything you run.
- **Gates stay light.** A step is done when the automatic checks pass and, for anything visual, you say yes on the screenshots.
- **Automatic checks:**
  - the check pack (0 FAIL);
  - headless sims (no crashes, win rates in a sensible band);
  - a smoke test on your PC;
  - frame time on your PC for visual work.

## 3. What the plan uses from Muse's research and design work

Muse's work is the toolbox for both tracks. This is the map: what gets used where, what is already in the game, and what is left out and why. Everything listed is free, per your free-only rule.

### Building ships (A1 barge, A4 kit rollout)

| What | From | How it is used |
|---|---|---|
| Ship template as data: one file per ship listing parts, hardpoints, damage looks and detail levels, checked by a schema tool (AJV) in the .bat build | kit spec synthesis; batch 8 (D7, D12); tool guides part 3 | The core of the kit. Hardpoints carry a forward arc, so a backward gun cannot be built. Kept simpler than the full spec: no TypeScript codegen. |
| Smooth hull lofting from cross-sections (loft v2) | ship_kit_upgrade.md; kit spec synthesis | Rebuilding the barge's hull wherever it reads as a boat, then other hulls. |
| Faction silhouette grammars and the Corsair look | art_direction_rey.md | The brief for the barge's shape options and for every later ship. |
| Approved-part protection: a read-only Blender parts library, linked into ship files, one change at a time, same-angle before/after renders | batch 6; batch 8 (D3, D4, D10) | Stops approved parts drifting between versions. The before/after renders double as your screenshots. |
| Geometry Nodes generators (Blender Studio Spaceship Generator, Discombobulator) | batch 8 (D5); visual expansion 4.3, 4.4 | For repeat detail only (plating rows, greebles) inside each faction's rules. Never random whole ships. |
| One master trim sheet with per-faction tint and wear | batch 8 (B6, B7) | The main material for plating. Unique textures only for hero parts. |
| Packed material maps (AO, roughness, metal in one image) | batch 8 (B1) | Already wired in the game (ships3d.js:65-67). Kept as the export rule. |
| Poly Haven and ambientCG (free CC0 metals, paint, rust, grime) | batch 8 (B5); visual expansion 2.1, 2.2 | Base materials, run through our own paint and wear pass first. |
| Material Maker (free) | visual expansion top pick 1 | Authoring panel and trim textures. |
| Local texture chain on your GPU (CHORD, Hunyuan paint, UltraTex via ComfyUI) | tool guides part 4 | Trialled on the barge for paint and wear. Kept only if it beats hand paint. |
| Free-licence image models for concept refs (Qwen-Image, FLUX schnell) | tool guides part 4 | Any new concept art. FLUX dev avoided (licence). |
| AI meshes (TRELLIS, Hunyuan, Tripo) | tool guides part 4; batch 8 (C7, C8) | Blockouts and reference only, never final parts. You already rejected TRELLIS.2 as too stubby. |
| Kenney Space Station Kit, KayKit Space Base Bits (CC0) | batch 8 (C2, C3) | Stations, the transport and the relay beacon, last in A4. |
| Detail levels made from the hero mesh, never re-modelled | batch 8 (D9); tool guides part 1.4 | For the distant view and the 20-ship battles. |
| Export checks: reimport into an empty file, per-map texture audit, applied transforms, hole check after reduction | batch 6 | Built into the export script, so they cost you nothing. |
| The 9-cell blob sweep (bow, middle, stern, each from top, side and below) | CLAUDE.md | Every ship, before you see it. |
| Blender automation (community blender-mcp on your 4.5.14) | batch 6; claude_skills.md | Trialled in A1, so I can drive Blender and see renders directly. The official Blender server needs 5.1, so later. |

### The engine test (A2) and the look (A5)

| What | From | How it is used |
|---|---|---|
| The beauty corner test scene: heroes, backdrops, effects added one at a time, measurement steps | beauty_corner_spec.md | Becomes the 6-ship engine test, minus its cyan and triangle-cap rules. |
| Godot starting points: the godotshaders shield shelf, the Reebo Labs force-field set, the Sci-Fi Combat FX hit-ripple spec, Forward+ against Compatibility | batches 1 and 2 | The Godot side of the test. |
| Effects recipes: shield shell plus ripple from the hit point, a multi-hit buffer, low-shield gaps, break dissolve from the killing hit, staged damage (scorched, dented, exposed, breach, wreck), beam core plus fringe, staged muzzle flashes, vacuum explosions without a filled wash | batch 7 | The effects pass, as starting recipes tuned on screen with you. |
| Feel values: hitstop, shake, wind-up, bloom, rim light | batches 5 and 7 | Starting guesses only. The two legs disagree on most of them, so we tune by eye. |
| Per-faction effects language (shield break styles, weapon signatures) | Gemini Argon High visual pack | The brief for each faction's effects. Its colour swatches are not used. |
| Backdrops for the five terrains and the dead star, plus fixes for ship-on-background clashes (light floors and rim light for black Deathless hulls; dimmer backgrounds behind pale Ithar) | Gemini Argon High background pack | The lighting and backdrop pass. Its new hex grid look goes to you for a verdict. |
| Background brightness scan (no board pixel brighter than 40% of a mid-grey reference) | luminance facet synthesis | One of the automatic checks. |
| Screenshot capture list, per-shot checklist, scoring against the concept art | visual_qa_pack.md | The fixed set of shots you get at each visual step. Its cyan tests and viewer panels are dropped. |
| Accessibility numbers (at most 3 flashes per second, a reduce-flashing toggle) and readability rules | graphics_craft.md; batch 7 | The effects pass. The doc's phone framing is ignored. |
| Smaller game-ready textures on the graphics card (KTX2 with Basis) | tool guides part 2; visual expansion top pick 2 | Cuts graphics memory about 4x if Babylon stays. The doc's setting name is wrong for 8.20; the right one is URLConfig. |
| Kenney Particle Pack (CC0) | visual expansion top pick 6 | Spark, smoke and flash sprites in the effects pass. |
| Profiling with Spector.js and the Babylon inspector | tool guides part 2.5 | The frame-time numbers in the engine test. |
| Reference games (Rogue Trader, Sins 2, BattleTech, Homeworld) | GRAPHICS_REFERENCES.md | The comparison shots in reference scoring. |

Already in the game, so nothing new to add: thin instances for debris (fx3d.js:518), per-map colour grading (scene3d.js:682), hull decals (fx3d.js:337), parallax on hulls, the glow layer, TAA.

### Game design (Track B)

| What | From | How it is used |
|---|---|---|
| Stable ids forever, renames handled by an alias table, the check pack run in every build | mod_scene_field_guide.md front section; the check pack | The save-brick fix in B1. The build stops on a hard FAIL. |
| Three project skills: ship kit, screenshot verdict, playtest and balance | claude_skills.md | Written in B0, so every future session works the same way. |
| Onboarding fixes 1 to 5 | onboarding synthesis | B1. Fix 10 is already in the game. |
| Sim calibration method (step-by-step tuning with sim logging) | difficulty dial synthesis | Tuning the battle-size ramp in B2. The 5-notch dial itself waits. |
| Pacing fixes: no dead air, faster enemy turns, coast and thrust ghost previews, fading hulks | batch 5 | B2. |
| Faction identities, price ladder (with corrections), prohibitions | asymmetry synthesis and decision page; price ladder synthesis | B3. |
| Torpedo telegraph: predicted path and impact marker, two-stage warning, a ramp to white about 800 ms before impact | batch 7; torpedo and boarding synthesis | The travelling torpedoes in B3. |
| Nemesis and events: small named hierarchy, known successor, visible intel clock, fixed weaknesses plus one capped adaptation per sector, blue options, no-repeat event decks, every event writes a flag | batch 3; independent audit | B4. |
| Wing stances: positioning and targeting, visible intercept zone, at most three veteran perks, orders override stances, overlays never in shield or Command colours | batch 4 | B4. |
| Faction arcs | career_story.md | B5. |
| The five terrain anchors from the plate mapping | plate mapping synthesis | The backdrop wiring. Its variant and special triggers wait, because their game hooks do not exist yet. |

### Not used, and why

- **Paid packs and tools** (Synty, Grey Fleet, MSGDI, BigMediumSmall greebles, paid smart materials, Houdini, ArmorPaint and Laigter binaries): your free-only rule.
- **Quaternius:** licence is QAL, not CC0.
- **The glTF and gltfpack recipes** in the tool guides: the game loads its own hull format. They come back only for the Godot test exports, or if we later move the game to glTF.
- **The official Blender server:** needs Blender 5.1.
- **The full kit spec machinery** (generated TypeScript types, gain calibration by least squares): more process than a one-person game needs. The schema check covers it.
- **7-person viewer panels:** replaced by your eye plus the automatic checks.
- **Plot-all-then-execute turns and repeat-last-move inertia** (batch 5): these would change the turn structure away from the Rogue Trader alternating feel.
- **Three height bands for 3D space** (space_3d.md): a big rules change. Ryan, Oct 24: near backlog, not this pass.

## 4. Track A: ships and look

### A0. Barge files into git

- **Goal:** the first commission never depends on one copy on one disk.
- **What I found:** the v14 files exist only on your PC, in `Downloads\voidsworn_test\build\hulls_hi\`:
  - `C19_51.vsm` (2.6 MB, Oct 22);
  - `C19_51_kit.json` (17.8 MB);
  - kit and finish maps.

  The repo build falls back to the old hull without them.
- **Entry:** plan approved, write access granted.
- **Exit:** v14 files committed. The repo build shows the same barge as your PC build, confirmed by one side-by-side screenshot.

### A1. Pyre-Barge upgrade (engine-neutral)

- **Goal:** the barge reads, in one screenshot, as a Corsair salvage capital: junk, theft, repairs, rust and bone. No naval read anywhere, in shape or parts.
- **Where it stands:**
  - Your v14 verdict (NEXT.md:56): "it's pretty close". Still to do: clean up the big blocky and undetailed areas, and add real material texture.
  - The kit script still builds naval parts: a mast "with two yards spanning sideways" (c19_kit.py:173), funnels (:160), a hull "falling to the keel" (:38), a keel plate (:403). Those go.
- **Steps:**
  1. **Shape review against the space-not-naval list:**
     - bow profile, keel line, deck line, superstructure tiers;
     - the v14 crossbar mast and smokestack funnels.

     I send 2 or 3 clay silhouette options. You pick one.
  2. **Dressing on the picked shape:**
     - stolen-panel plating with visible bolts and brackets;
     - salvage asymmetry;
     - belly slabs that read as bolted-on scrap;
     - antenna arrays and heat radiators in place of the mast and funnels;
     - guns forward or to the side only.
  3. **Paint and materials:**
     - the rust-and-bone palette as the colour source;
     - baked maps for wear and grime only;
     - a material audit (no surface that looks new, no clean naval paint).
  4. **Barge effects:** dirty flickering engines, ragged muzzle flashes, staged damage looks (light, heavy, wreck).
  5. **Source of truth:** a Blender scene plus a versioned build script, exported to standard files. Today's game format and a Godot import are both produced from it.
- **Entry:** A0 done.
- **Exit:** you sign off the barge from studio renders and in-game screenshots at battle zoom and close-up.
- **Automatic checks:**
  - every added part sits on the hull on a visible mount;
  - no backward guns;
  - export reimports clean.

### A2. Six-ship engine test

- **Goal:** a fair, like-for-like look at Babylon and Godot on your PC, with numbers and side-by-side shots.
- **The six ships** (each faction's flagship, the ships you see biggest and closest):

| Faction | Ship | Mesh |
|---|---|---|
| Voidsworn | Ascendant dreadnought | V1b_r_23 |
| Hegemony | Super-dreadnought | H4_11 |
| Corsair | Pyre-Barge | C19_51 (the upgraded barge once A1 lands; v14 until then) |
| Chorus | Bio-titan | B16_23 |
| Ithar | Ark | I8_37 |
| Deathless | Tomb-ark | D22_23 |

- **The scene:**
  - one battle-zoom camera path plus one close-up;
  - the same key and fill lights and background plate;
  - one fixed effect set per ship: main weapon fire, shield hit in faction colour (Chorus and Deathless take hull hits), one explosion.
  - The effects in both engines are built fresh to the same short spec, in an equal time box. Babylon's existing effects do not get a head start.
- **Measured on your PC:**
  - frame time (average and worst 1%) at 4K and at 1440p;
  - GPU memory;
  - load time;
  - how long it took to get one ship from Blender into each engine (authoring throughput);
  - in Godot, the full renderer (Forward+) against the reduced one (Compatibility), so we know what a web build would lose.
- **Optional last step,** only if both pass: copy the six up to about 20 ships to see where each engine starts to strain.
- **Also an input to the call, already measured:** today the battle rules (data.js, core.js, battle.js, about 216 KB) run with no renderer at all; the headless sim does exactly that. Everything else (rendering, effects, interface, about 780 KB not counting sound data) is engine-specific. A Godot move means rewriting all of it in Godot's language, rules included.
- **Entry:** plan approved, and your OK to install Godot (free, a portable zip, nothing system-wide).
- **Exit:** a one-page result with numbers and labelled side-by-side shots, plus my recommendation.

### A3. The engine call

**Who decides:** I recommend, you decide. A migration is a joint call, never mine alone.

**What moves it toward Godot:**
- you prefer the Godot shots in a blind side-by-side (labels hidden until you pick);
- Godot holds 60 fps or better at 4K with the full effect set;
- it is not slower to author for;
- and you are fine with the rewrite cost and a downloadable app.

**What keeps Babylon:**
- no clear look win;
- or the look gap closes with the planned effects and lighting work;
- or the rewrite cost outweighs the gain.

If Babylon stays, the question closes for this project phase.

**Entry:** A2 result.
**Exit:** a written decision in this file.

### A4. Kit rollout (ship 2 onward)

- **Entry:** A1 signed off and A3 decided.
- **Order:**
  1. Corsairs first, reusing the barge's grammar right away: C13s, C14s, C15s, C16s.
  2. Then one faction at a time, flagship first (it proves that faction's look), then its line from frigate up:
     - Voidsworn (the default player faction);
     - Hegemony (the sector 1 escort and ambush enemy);
     - Chorus, Ithar, Deathless.
  3. Squadron craft and objective structures (station, transport, relay beacon) last.
- **Per ship:** the region-by-region blob sweep from CLAUDE.md, the space-not-naval check on shape, your screenshot sign-off.
- **Exit per faction:** you approve a faction lineup shot.

### A5. Effects pass

- **Entry:** A3 decided.
- **Covers:**
  - every weapon distinct (plasma nothing like lasers);
  - faction-coloured shield hits with a distinct ripple and break per faction;
  - staged damage looks;
  - the torpedo lane visuals (B3);
  - lighting and tonemapper tuning (ACES against Khronos PBR Neutral, scored on colour faithfulness);
  - the readability rules (every resolution skippable, a reduce-flashing toggle).
- **Starting values:** the research numbers (hitstop, shake, bloom) are guesses. They get tuned on screen with you.
- **Weapon looks:** the per-family list in NEXT.md under "Effects, doubled down" (laser, plasma, autocannon, rail, lance and ion, needle, spine, torpedoes) is the brief. It sits alongside the batch 7 recipes and the Argon pack's per-faction effect language.
- **Exit:** you approve a short clip per faction.

## 5. Track B: game

### B0. Ground truth (nothing in the game changes)

- **Findings registry:** `contrib/opus/FINDINGS.md`, already seeded Oct 24. B0 adds the mega sim numbers, and every later fix updates its row.
- **Check pack:** decoded from base64 and adopted into `contrib/opus/tools/`.
- **CampaignSim crash:** the one-line guard added to sim3d.js.
- **Mega sim:** finished in the cloud.
  - The legs that passed stand (game code has not changed since Oct 22).
  - The missing legs run: boss matrix, faction matrix, matrix, archetype matrix.
  - The result is `contrib/opus/compute/balance_reference.md` plus CSVs.

  This is the "before" baseline every later change gets compared against.
- **Exit:** the registry exists, the check pack runs 0 FAIL, and the baseline is filed.

### B1. Fix what can eat a win

| Issue | Where | Status at d5d0227 |
|---|---|---|
| Retreat dialog: keyboard still plays the battle behind it, and "Jump out" can turn a finished win into a retreat | ui3d.js:484 has no open-dialog check; campaign3d.js:95 does not check that the battle is still live | confirmed present |
| Reload bug 1: a mid-battle reload eats the node | nothing saves during battle, and continuing replays the seeded node (campaign_meta.js:42) | looks fixed; I confirm it in a browser test |
| Reload bug 2: a reload during the reward screens loses the boon, refit and relic | the salvage pick saves (campaign_run.js:274) before the node completes (:309); event fights also skip node seeding (campaign3d.js:50) | present |
| Save-brick class: a renamed hull, an unknown relic, a captain with no name, or a stale admiral crashes the save | core.js:180 and :164; campaign_run.js:46; core.js:126; campaign_meta.js:196 | present |
| Captured flagship joins your fleet past the cap; selling it turns credits into NaN | campaign3d.js:81; campaign_run.js:181 | present; fixed by the capture rework in B2 |
| Smaller ones: free blink after a stalled animation; Nova cooldown spent by an abandoned cast; towing past the command cap; a zero-fleet win recorded as a loss; a reserve captain overwriting a hired veteran; a crit reviving a destroyed system | battle.js:944, :953, :771; campaign_run.js:272; campaign3d.js:99; battle.js:562-563 | present |

Onboarding fixes 1 to 5 also land here:
1. Standard AI for fresh profiles (today it defaults to Veteran, campaign3d.js:3).
2. The motion rule in the move tip: sitting still makes you easier to hit.
3. Alternating turns explained at battle start.
4. One-line reward definitions.
5. A clearer enemy-activation signal (today only the top bar says "Enemy activation", ui3d.js:86) plus a Threat prompt.

Two small items from your shield answer:
- The tutorial line "Cyan is shields" changes to point at the shield bars.
- Enemy markers get a shape plus a colour that no faction shield uses, so red Corsair shields stop clashing with red enemy markers.

- **Exit:** each fix has a sim or scripted check proving it. Smoke test passes on your PC. You play one run.

### B2. Faster battles, then bigger battles

1. **Faster first.**
   - Today's waits are already 11 to 15 seconds of animation per round at 7 to 13 ships.
   - The target is 12 s per round, with 15 s as the limit, at every battle size.
   - Means:
     - shorter moves and turns;
     - independent enemy actions resolved in parallel;
     - quicker enemy turns;
     - every resolution skippable or sped up.
2. **Then bigger** (your answer 1A).
   - Enemy fleet budgets grow by sector and difficulty.
   - The 8-ship enemy limit and the "never outgrow the player" rule (battle.js:136 and 147) are replaced by the ramp, aiming at about 10, 14 and 20 ships on board.
   - Your command points stay tight, so your side stays small and elite.
3. **Capture rework** (your answer 4A): the post-win add, strip or ransom choice, auto-scrap when full, and no flagship capture.
4. **Dead Star:** the painting wired in as the dead-star board's backdrop and as a finale backdrop. The 40 concept images are not in the repo, so this needs them from Rey's pack or your PC.

- **Exit:**
  - Sims show the target sizes reached, waits inside the limit, no crashes, and sector win rates in a sensible band. Starting band: no admiral below 50% or above 90% against a sector 1 flagship. It is a flag for me, not a gate for you.
  - You play a run and say whether the growth feels right.

### B3. Faction identity (all approved Oct 24)

1. **Data-only pass:** per-faction price ladder, roster gates, and prohibitions.
   - Price multipliers per faction and class.
   - Ithar cannot Brace.
   - The Corsair prohibition becomes "no lance-kind (long-range) weapons", already true of their roster. The proposed "missile or bombard" kinds do not exist in the game.
   - Voidsworn keep carriers, at a price premium. The proposed carrier ban would break Commodore Ashgrove, a Voidsworn admiral whose whole kit is carriers (data.js:204).
2. **Hegemony synchronized fire,** with the flagship anchor: sync only near the flagship, and losing it collapses sync. The Anchored Volley boon (the one thing that rewards standing still) will not stack with sync.
3. **Ithar shield charge,** above the regen every shielded hull already gets.
4. **Chorus feed** (kills heal), with a cap.
5. **Deathless elite attrition,** built on the reanimate rule that already exists (battle.js:702).
6. **Torpedoes that travel:**
   - a visible lane during your turn;
   - impact on the next turn, so ships can dodge;
   - range stays 6, with the cooldown kept.
   - This is the Rogue Trader feel item from your benchmark.

- **Exit:**
  - The sim shows each faction playing differently (engagement range, damage soaked by shields versus armour, losses).
  - No faction runs away with win rates.
  - You play each faction once and say whether it feels like itself.

### B4. The ship-five

Built in this order, because each step uses the one before:
1. **The two reload bugs and the retreat dialog.** Already done in B1.
2. **Event blue options plus 20 new events.** Options unlocked by your fleet, faction or relics; costs in different currencies; no repeats within a run. Every event writes a flag later systems can read.
3. **Faction campaign verbs,** one per faction, using those event flags. Six small hooks between battles.
4. **The Nemesis,** one named enemy commander per run.
   - Built on the flags above: a visible intel clock, fixed weaknesses, and one capped adaptation per sector.
   - The rule: no stealing control of your ships, and no ship loss without warning.
   - This same commander is the story rival in B5.
5. **Wing doctrines:**
   - Screen, Strike and Hunt stances, one free switch per round;
   - up to three visible veteran perks per wing.
   - Orders override stances, with a visible marker.
   - Can start alongside step 2, since it touches battle code, not campaign code.

- **Exit per item:** sim checks for crashes and balance, and you play it.

### B5. Story

1. **Option A first:** voices and records. Admiral lines, medals, a service record. Small.
2. **Then Option B:** faction arcs, three beats per faction across a run, with the Nemesis as the rival you meet in beat 2 and settle in beat 3.

- **Exit:** you read and approve the arc text for each faction before it ships.

## 6. Second legs, the mega sim and the registry

- **Qwen second legs** (price ladder, plate mapping): Rey's retry runs Oct 25 around 09:45 CDT. Nothing waits on it.
  - When the legs land, I re-check both against the code before B3 (price ladder) and B2 (plate mapping) use them.
  - If the Qwen limit holds, I derive the missing leg myself from data.js and battle.js and say so in the registry.
- **Mega sim:** finished in B0 as a cloud job. It is re-run after each phase that touches balance (B2, B3, B4) and compared against the baseline.
- **Findings registry** (`contrib/opus/FINDINGS.md`):
  - one table: claim, source, verdict, evidence, status;
  - every new claim from Rey, DeepSeek, Qwen or Gemini enters as unverified and gets checked before anything is built on it;
  - a fix updates its row in the same commit.

## 7. Out of scope for this plan

- Anything phone.
- A full 5-notch difficulty dial. The battle-size ramp is the difficulty lever for now; revisit after B2.
- New terrain kinds beyond the existing five plus the dead-star board.
- Permanent crits. Crits stay soft and temporary.
- Option C (the long career).
- Paid assets of any kind.
- Admiral portraits (backlog), including the Chorus regenerations and the 15 unmade portraits.
- Adaptive music.
- The per-faction economy engine spike. The data-only pass in B3 comes first.
- An installable app wrapper, unless Godot wins.
- Three height bands for 3D space (near backlog).

## 8. Risks

1. **An engine switch means rewriting the whole game,** rules included. Kept small by deciding before ship 2 and by keeping Blender as the single source for ships.
2. **Reopening the barge shape adds rounds.** Kept small by one silhouette pick before any dressing.
3. **Bigger battles mean longer waits.** That is why faster comes first in B2, and why waits get checked at every size.
4. **The bridge to your PC was flaky tonight** (the remote shell did not start; file access works). Fallback: the .bat watcher jobs already used for Blender bakes.
5. **Research numbers are guesses,** often from weak sources. They are starting points only, tuned on screen.
6. **Older documents still carry superseded rules,** and they will mislead anyone who follows them as written:
   - cyan-only shields (in 7 places);
   - phone tiers (71 mentions in one research memo);
   - Quaternius as "CC0";
   - the old gold fixes;
   - recipes built around .glb files and gltfpack, which the game never loads (it uses its own JSON and WebP hull files).

   The registry marks them, and I check before building from any of them.
7. **Usage limits** if many helpers run at once. I keep helpers to independent jobs only.

## 9. Where you weigh in

1. Approve this plan.
2. Grant write access to the repo, so I can commit.
3. OK to install Godot on your PC for A2.
4. Pick the barge silhouette (A1, step 1).
5. Sign off the barge (A1 exit).
6. The engine call, with me (A3).
7. Approve each faction lineup during kit rollout (A4).
8. Approve an effects clip per faction (A5).
9. Play a run after B1, after B2 (does growth feel right?), and once per faction after B3.
10. Approve the arc text per faction (B5).

Anything else I decide, then report.

## 10. Working notes for the build session

**Effort.**
- High by default.
- Extra effort for four pieces:
  - the save-brick fix (B1);
  - tuning the battle-size ramp (B2);
  - travelling torpedoes (B3);
  - the engine call write-up (A3).

**Helpers.**
- Run independent checks as background helpers and keep working; do not sit in a blocking wait. Interrupting a waiting step tonight stopped every running helper, twice.
- The old "two helpers at most" rule is retired (Ryan, Oct 24).

**Where things are on Ryan's PC** (Windows 10, PowerShell 5.1, no real Python):
- **Test runner:** `C:\Users\rcbai\Downloads\voidsworn_test` (watcher.bat). The rules are in HANDOFF.md, Gotchas.
- **Barge v14 game files:** `...\voidsworn_test\build\hulls_hi\`:
  - `C19_51.vsm` (2.6 MB);
  - `C19_51_kit.json` (17.8 MB);
  - `C19_51_kit_a.webp`, `_kit_f`, `_kit_n`;
  - `C19_51_a.webp`, `_f`, `_fn`;
  - `C19_51.hdr.json`.

  None of these are in git yet (A0).
- **Barge sources:** `...\voidsworn_test\comfy_io\C19_51\` (concept, mesh, lod, kit, views, proj).
- **Blender:** `...\voidsworn_test\blender\blender-4.5.14-windows-x64\blender.exe`.
- **ComfyUI:** `C:\Users\rcbai\Downloads\ComfyUI_windows_portable`.
- **PC bridge, Oct 24 evening:** folder listing worked once Ryan granted `voidsworn_test`, but the remote shell failed ("Workspace unavailable"). Use file staging and commits plus the watcher .bat jobs.

**Barge build scripts in the repo:**
- `tools/blender/hs/c19_kit.py`. It still builds naval parts that must go: a mast with yards (line 173), funnels (160), a keel line (38), a keel plate (403).
- `detail_lib.py`, `hs_lib.py`, `project_paint.py`, `pixal_to_game.py`, `vsm_pack.mjs`.
- Jobs `tools/pc/jobs/c19_*.bat`.

**How the Oct 24 numbers were measured** (repeat these for the B0 baseline):
- **Ships on board:** load sim3d.js's eval block (data.js, core.js, battle.js) and call `startBattle` with campaignSim's reference fleets, 60 battles per sector and kind. Count non-squadron units per side.
- **Waits:** `node sim3d.js campaign 15` with the guard below. The "new" timing model gives 46 to 132 s per battle.
- **Harness crash fix** (sim3d.js:112): replace `OBJS_SEEN[B.obj.type].w++;` with `(OBJS_SEEN[B.obj.type]=OBJS_SEEN[B.obj.type]||{n:0,w:0}).w++;`.
- **Boss matrix:** `node sim3d.js bossmatrix 1` runs sector 1 in about 35 s in the cloud, so the whole mega sim fits in the cloud.

**Files committed as base64 text** (decode before use):
- `contrib/muse/tools/checkpack/checks.js` and `RUN_CHECKS.bat`;
- every CSV in `contrib/muse/compute/`.

**Older documents that will mislead if followed as written** (details in FINDINGS.md):
- cyan-only shield tests (beauty_corner_spec.md, visual_qa_pack.md);
- phone framing (visual_expansion_research.md, graphics_craft.md);
- glTF and gltfpack recipes (tool_guides.md);
- the 1.32 GB figure (ship_kit_upgrade.md);
- "around 20 ships today" (CONVERSATION_CONTEXT.md);
- the kit script's naval parts.

**Rey (Muse)** works external point of view only and files into `contrib/muse/`.
- The Qwen second legs (price ladder, plate mapping) retry Oct 25 around 09:45 CDT.
- Anything Rey or the outside models file is unverified until checked here and logged in FINDINGS.md.

**Commits:**
- Straight to main, the repo's convention. Identity `-c user.name="Ryan Bailey" -c user.email="rcbailey12@gmail.com"`, ending with the Co-Authored-By and Claude-Session lines.
- No em dashes anywhere (`grep -c` must be 0).

**Ryan's way of working:**
- Plain words, screenshots of everything visual, double-click .bat files.
- Lead with the answer, and give a pick rather than a neutral list.
- The plan is approved, so no new scope questions unless something changes it.

## 11. Starter line for a fresh session

```
Read HANDOFF.md, then contrib/opus/go-forward-plan.md and contrib/opus/FINDINGS.md in github.com/rcbailey12/voidsworn (main), and continue from the first phase not marked done.
```
