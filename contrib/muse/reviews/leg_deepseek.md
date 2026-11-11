# Leg: DeepSeek (writer), issue #486 cinematic audit

Landed Nov 11, 2026, 10:35 to 10:40 CST at chat.deepseek.com (chat "Cinematic audit findings"). Gates verified by the runner: DeepThink ON and Search OFF at send time and after generation (Search was initially on; the runner toggled it off and re-verified both). PACK.md (78.34 KB) attached by grant. Chair screening: citations checked against the pack during synthesis; the leg cites only pack contents (code names it uses, _best_facing, _path_dots, tables.json, come from issue 489's text inside the pack). Raw leg text follows, unedited except this header.

---

DeepSeek writer leg ,  issue #486, cinematic audit (outside eye)

How I read the evidence

I am the outside-eye writer leg. I cannot hear the game and I have not watched it move, so my sound findings are structural (from sound.md, cues.json and the 181-file clip list) and my movement findings are reference-and-design, as issue 489 asks. For pictures I lean on Rey's blind leg (B1-B11) and the capture paths it names (docs/shots/look_bench/m1-m5, f1-f3, deaths/, explosions/, rebake/), and I check each against the written rules in effects.md, deaths_and_hits.md and sound.md. I do not list the wreck break itself (issue 484). I do not propose removing FLASH_CAP; I report where it flattens and how to get drama inside it. I cite only what the pack contains; where I name a file or function it is one the pack names.

The pattern I am hunting is the one R186 names: a rule, constant or convenience chosen to be tidy, safe or easy to check, showing on screen or in the speakers as tidiness. The findings are ranked by how much each would move the game toward “feels like a film”, biggest first.

Ranked findings (18; at most twenty, no padding)

1. The shield never answers a hit and never shows its condition [PICTURE + RULE]

1. Now: In m2 and m3 the shield is a flawless honeycomb ellipsoid, identical in every row and faction. A hit puts the same beige puff at the bubble's edge and does not dent, ripple or light the cells around it. A shield at one-fifth strength is pixel-identical to a full shield; the collapse row is a flash and a loose ring with the ellipsoid still drawn; the bubble bleaches the ship inside it white.

2. A film would: Make the shield answer at the point of impact and write its condition on its surface. The Star Trek and Stargate shield hits flare locally and run interference across the surface; Sins of a Solar Empire 2 uses local flares. A failing shield fails in patches and peels or goes dark locally before the whole surface collapses. The shield is the one object the audience reads as “health bar in the world”, so it must show health.

3. Where the limit lives: effects.md §1 Target, Shields: “invisible at rest, a faint edge glow on zoom, hover or a recent hit, a downed side reads as a dark gap, and they keep faction colours (R163; Oct 24).” There is no rule for a local hit response, no strength state, and no break surface. deaths_and_hits.md gives only “Torpedo on a shield | 110 px. | The ripple: 156 px … | A shield scar for about a second.”

4. Why it is there: The shield's own look is explicitly deferred to Ryan's pick from three directions; the only defined states are invisible / edge-glow / dark-gap, which is a binary and easy to check.

5. Loosening: Give the shield three readable states (full / weakened / failing) and a hit response. On a hit: a local flare at the impact cell (about 1.5-2× the hit flash for 0.12 s), a ripple ring that travels one cell per ~0.03 s, and neighbouring cells brighten then dim. Strength reads as cell density and brightness (full = tight bright weave; low = gappy dim weave with dark patches). On break: cells fail outward from the impact in patches with a peel, not a whole-ellipsoid flash; keep a dark gap where the side went down. Reduce the ship-bleach by using an additive rim rather than a white wash.

6. Size: Medium (two or three runs: a local-response shader term, state tiers, a break animation). Frame cost: a per-cell brightness term in the existing shield shader; low.

7. Point at: docs/shots/look_bench/m2 and m3 (shield states, collapse row).

2. Every weapon lands the same two-part stamp [PICTURE + RULE]

1. Now: In m1, ten weapons land on one hull and nine produce the same small round white glow plus one soft beige puff beside it. At camera 170 a macro cannon, las, autocannon, scatter battery and plasma hit are interchangeable; only the lance (a beam) and the torpedo (a bigger puff) read differently. The hit is a pictogram, identical every time, at the same spot.

2. A film would: Separate weapons by what the hit does. A kinetic round sparks and skips; an energy hit splashes and runs; a torpedo bloom is dirty and directional. The Expanse separates PDC, railgun and torpedo this way; Battlestar Galactica separates flak from cannon. The audience should know what hit them without reading a label.

3. Where the limit lives: deaths_and_hits.md “The hits, upgraded” already writes distinct rows (Las 40 px tiny hot spark, no smoke; Macro 56 px short cone of sparks; Lance 78 px contact burn that crawls; Torpedo 154 px fire through gas and debris), but effects.md §1 says “Every explosion is built that way [route B with flash plus hot core]” and §3 step 3 says “the flash reaches its size inside two frames”. One template, resized, is applied to every weapon.

4. Why it is there: One bake route and one template are cheap and checkable: measure the flash's widest lit extent and how many frames it lasts. A single recipe proves easily.

5. Loosening: Build the hit table's rows as distinct recipes, not one template resized. Kinetic: a spark cone with ballistic sparks, a skip, no smoke. Energy: a splash that runs along the plate, a short scorch, a brief arc. Torpedo: fire seen through gas plus directional debris. Give each its own rise (kinetic 1 frame, energy 1-2, torpedo 3-4) and its own tail. Relax the two-frame rise for every body except the smallest flash.

6. Size: Medium-large (three or four runs: three body recipes plus a rebake). Frame cost: more particles per hit; cap by camera distance and event class.

7. Point at: m1 (every weapon on a hull).

3. One soft material for all destruction; nothing is thrown and nothing is left [PICTURE + RULE]

1. Now: Every explosion, hit and death is the same soft, round, beige-grey puff, scaled up or down. The torpedo's puff is the las puff enlarged. Nothing is thrown: no fragments with trajectories, no sparks that arc, no venting jet that persists, no debris that keeps moving, no scorch or residue. The world resets after every act of violence.

2. A film would: Use at least two materials moving at different speeds and in different directions: a bright fast one (sparks, molten spray) and a slow dirty one (gas, dust, debris). The Expanse torpedo blooms and BSG flak both do this; Homeworld leaves debris. Real destruction leaves a mess, and the mess is the memory of the hit.

3. Where the limit lives: effects.md §1: “Flame cap: no flame or hot core lives longer than 0.70 s, and none stays at full heat longer than 0.25 s (owner ruling). Flash and snuff out, never rolling fire.” deaths_and_hits.md rule 2 repeats it; rule 4 says “Nothing floats beside the hull.” The cap is applied to all matter, not just flame.

4. Why it is there: A real owner ruling against rolling fire, plus perf and readability; one puff is cheap.

5. Loosening: Keep the 0.70 s cap for flame, but separate the matter budget. Add non-flame materials with longer lives: ballistic sparks (0.3-0.8 s), debris chunks (1-4 s, drifting and fading), gas/dust (2-6 s, slow), scorch decals (persist), venting jets (1-2 s). Let one event carry three to five materials. Anchor spawned matter at the hull or breach (so it is not “floating” arbitrarily) but let it drift after release.

6. Size: Medium (materials plus a debris spawner). Frame cost: more sprites; cap by camera distance and event class.

7. Point at: m1, m4, deaths/cruiser_death_beats.jpg.

4. Hit response does not scale with the target's mass [PICTURE + RULE]

1. Now: In m5 the same battleship macro battery hits an Eclipse frigate, destroyer, cruiser and tomb-ark, and the impact puff and glow are the same size on all four, while the incoming tracer is a glowing comet larger than the frigate itself.

2. A film would: Let target mass change the behaviour of the hit, not just its size. A capital's main battery hit should dwarf a fighter cannon; a hit on a capital should look absorbed by mass (a local flash, a deep ring, the hull shuddering), while a hit that would gut a frigate should go through and vent. The Expanse distinguishes a PDC tick on the Roci from a railgun hit on the Donnager.

3. Where the limit lives: effects.md §1: “Each step up the ladder is about 1.4 times the one below, so a bigger event always reads bigger.” The ladder scales by weapon, not by target. deaths_and_hits.md “The hits, upgraded” has one row per weapon and no target term.

4. Why it is there: The staging table measured one weapon on one hull; a single number per weapon is easy to check.

5. Loosening: Add a target-mass term and a target behaviour table. On capitals: shrink the surface flash (~0.6×), lengthen it (~1.5×), add a hull shudder and a deep internal ring, fewer surface sparks, more absorbed glow. On frigates: full flash plus a visible exit wound, through-and-through venting, more debris. Keep the weapon ladder but multiply it by target class.

6. Size: Medium (two runs: a target-class response table plus code). Frame cost: low.

7. Point at: m5 (one weapon at every weight).

5. Beams are ruler-straight bars; one is a hairline across the whole frame [PICTURE + RULE]

1. Now: The lance and ion beam in m1 and m2 are perfect white bars: constant width, constant brightness, sharp edges, no taper, no flicker, no brighter head or fading tail. The gauss hit in m3 draws a thin line across the entire frame, edge to edge, like a scratch on the picture rather than something in the world.

2. A film would: Give the beam a straining source, a hot head, a tapering tail, edge flicker, heat shimmer along the path, and an impact that splashes. Homeworld's ion beams and Babylon 5's beams show a source under load; a beam is a physical event, not a diagram.

3. Where the limit lives: deaths_and_hits.md “Lance (cut) | The tear is the cut: a straight white line along the beam's path.” effects.md §8 order item 6 puts “Trails, beams and flares: options sheet, pick, issue 367” after the current work, so there is no beam-shape rule yet.

4. Why it is there: A straight line is the simplest and most checkable beam; the “straight white line” rule is really about the wreck's cut face.

5. Loosening: Make the live beam a bright core with a hot head, a taper to the tail, edge flicker at 10-20 Hz, a short bloom at the source, an impact splash, and a heat-shimmer distortion along the path; let the path wander by a few pixels over its length. Turn the gauss hairline into a tracer with perspective (thicker near the source, fading to a point) rather than an edge-to-edge scratch. Keep the lance's wreck cut straight; let the live beam have life.

6. Size: Medium (beam shader and mesh; two or three runs). Frame cost: a distortion pass; keep it at camera 170.

7. Point at: m1, m2 (beams), m3 (gauss hit).

6. Chain blasts are evenly spaced and equal; the core flash is a centred round ball [PICTURE + RULE]

1. Now: In the death-beat strips the capital's blasts 4 (1.58 s) and 5 (1.93 s) are the same white sparkle band at the same density; the cruiser's blasts 1-3 are the same small fire at three evenly marched positions. Then the core flash is a perfectly round orange ball with a scalloped edge, centred on the ship, owing nothing to the ship's shape or where it was hit.

2. A film would: Stagger internal explosions, uneven gaps, different sizes, some deep and muffled, one bigger than the pattern, and put the core flash at the torn face with a direction. Even spacing and equal size is the signature of a schedule, not a ship coming apart.

3. Where the limit lives: deaths_and_hits.md cruiser: “Three chain blasts walk along it at about 0.5, 0.8 and 1.1 s, each at least 75 px” (0.3 s apart, same minimum). Capital: “Five chain blasts walk the break line.” Sunward: “Magazines go off as an even row, a drumbeat a quarter second apart.” Hegemony: “Few secondaries, evenly timed.”

4. Why it is there: A schedule is easy to author and easy to check; even spacing reads clearly at camera 170.

5. Loosening: Replace fixed times with a staggered list with jitter (for example 0.48, 0.79, 1.13, 1.31, 1.52 s) and sizes varying ±40%, one blast clearly the biggest. Place the core flash at the torn face with a directional bias, an irregular silhouette (noise on the mask) and a brief occlusion by the hull. Keep a beat, not a metronome. The faction sheets can keep a rhythm but must break the equal interval.

6. Size: Small-medium (data change plus one bake). Frame cost: none.

7. Point at: deaths/capital_death_beats.jpg, deaths/cruiser_death_beats.jpg.

7. Small deaths are a puff and a ring; one faction's death is nearly invisible [PICTURE + RULE]

1. Now: In m4 the frigate and destroyer die as the standard puff plus a translucent lavender ring, a perfect circle expanding on cue, with three small orange ticks on top. The Sunward cruiser's puff is barely larger than the frigate's. The Eclipse burn-out row is three frames of a dark hulk with almost no visible event, a capital-scale death a viewer could miss.

2. A film would: Give even a small kill a signature, a hard spark, a tumble with a short ribbon, a brief bright core before dark. The smallest and largest deaths should be separated by more than puff diameter. BSG's Viper kills are small but unmistakable; The Expanse gives even a PDC kill a visible flash and debris.

3. Where the limit lives: deaths_and_hits.md frigate: “0.72: the pop. Frigate: 216 px flash for 0.18 s, 180 px body for about a second.” Small craft: “A single-frame spark and a puff, under 40 px, no wreck. Twenty of them dying must never hide a cruiser.” Eclipse: “one small hard flash and it is out. No fire.”

4. Why it is there: Small craft must not clutter the board; the Eclipse's dark death is a faction trait; the caps are checkable.

5. Loosening: Keep the concurrency cap for small craft but raise per-event readability: a 40-60 px flash with a ~0.3 s tail, a tumbling fragment, a bright core; stagger simultaneous kills so they do not merge. For Eclipse, keep “no fire” but make the death readable: a hard white-green flash, plates visibly lifting away band by band, a dark collapse with a green rim, a settling drift. It can be quiet and still be seen.

6. Size: Small-medium. Frame cost: low.

7. Point at: m4, deaths/ strips.

8. The sound is dry, short and instant, no tails, no build-up, no distance [SOUND + RULE]

1. Now: From cues.json, every cue is a short one-shot: most events have one to three clips, tail: 1, defer between 0.1 and 3.9 s, pitch jitter pj: 0.03 (3%) and spj: 0.07 (7%), fixed gain, no distance term, no size term. The engine is a single loop. Big events do not linger.

2. A film would: Keep weapons dry but give deaths, capital hits, shield breaks and engine start a long decaying tail with sub-bass and structural groans; sounds arrive late with distance and are filtered by it; a capital death runs as a bed for the length of the visual. Sins of a Solar Empire and EVE keep the mix clean but let big events breathe.

3. Where the limit lives: sound.md §1: “Short and dry. Short tails, little echo. Space is quiet; the fleet is heard as if through your own ship's hull.” Also “No arcade. No zaps, pews, rising whooshes or stock explosions”, yet cues.json uses a whoosh layer in torp, phase, death_vent, hulk_vent, arrive_jump and board_grapple, which is a contradiction to resolve. Death cues carry duration 0.35-1.5 s with defer: 2.

4. Why it is there: The “clean and tactical” brief; dry is easy to mix and avoids mud; perf.

5. Loosening: Keep weapons dry, but put a reverb send (about 1.8 s decay) on the death bus only and give deaths, capital hits and shield breaks a long tail (1.5-6 s) with sub-bass and a hull-groan layer. Add distance low-pass and level falloff. Give big events a 0.1-0.3 s pre-lap (charge, vent) and a settling tail. Run a death bed for the visual length (about 4.5 s cruiser, longer for capital) with the existing one-shots on top. Resolve the whoosh contradiction by naming the layer a vent/charge rather than a rising whoosh, or by removing it.

6. Size: Medium (mix buses and new layers). Frame cost: audio only.

7. Point at: cues.json death_*, boom_l; sound.md Target.

9. Few takes, tiny pitch jitter, and weapons share layers [SOUND + RULE]

1. Now: Many cues have only two or three clips (lance 2, lance_ion 2, torp_heavy 3, gun_sq 3); pitch jitter is 3%; and weapons share layers, boomLow appears in gun_shell, gun_rail, salvo_tail, hit_heavy and arrive_jump; laserLarge in gun_las, gun_plasma, lance and lance_dark; whoosh in torp, phase, death_vent, hulk_vent, arrive_jump and board_grapple. Weapons blur into one family.

2. A film would: Give each weapon a recognisable mid-layer and a family, with enough takes that repetition is inaudible, and vary the layers per shot.

3. Where the limit lives: sound.md §1: “Variation. At least four takes of anything heard often, never the same one twice in a row.” cues.json synth arrays: lance has 2, lance_ion 2, torp_heavy 3; pj: 0.03.

4. Why it is there: Asset budget; shared layers save files; a small jitter is safe.

5. Loosening: Raise pitch jitter for big sounds to 6-10%, add a no-repeat picker, give every weapon a unique short mid-layer (even a synthetic transient) so the shared bed does not blur it, and add two more takes to the under-four cues that fire often (lance, lance_ion, torp_heavy).

6. Size: Small-medium (assets plus picker). Frame cost: audio only.

7. Point at: cues.json lance, gun_las, torp.

10. No distance, no size, no faction in the weapon mix [SOUND + RULE]

1. Now: cues.json has fixed gains and no distance parameter. Faction variants exist only for death_crack (ithar) and board_grapple (chorus); most weapons are shared across factions.

2. A film would: Make a far-off gun a muffled thump and a near one a crack; give a capital's gun a deeper sub; let each faction's guns share a family. BSG's flak and The Expanse's PDC both change with distance and hull.

3. Where the limit lives: sound.md §1: “Faction voices. Each faction's guns and engines share a family of sound (iron and fire for the Crusade, clean electrical hum for the Hegemony, rattling junk for the Hullbreakers, glass and tone for the Glasswrights, a low held note for Eclipse, wet and breathing for the Chorus).” cues.json has one gun_shell for all.

4. Why it is there: Faction audio is deferred; one cue per weapon is simple.

5. Loosening: Add a faction layer to each weapon family (a short signature transient plus a tail colour), a distance attenuation (level plus low-pass) and a size term (sub-layer gain by weapon class and target class). The bank already contains a faction timbre under the filename choirBell_*.ogg (filename cited only as evidence that such a layer exists; the house rule bans that word in proposals), use it as a layer, not a lead.

6. Size: Medium (mixer params and a few layers). Frame cost: audio only.

7. Point at: cues.json gun_shell layers; sound.md faction voices.

11. The engine is one loop with no thrust or class [SOUND + PICTURE]

1. Now: The engine cue is a single engineLoop layer, max: 2, with no thrust parameter. In f1 every hull carries one identical white engine smudge.

2. A film would: Let the engine note rise with thrust, drop to a breath at coast, and differ by class, capital deeper and slower, fighter higher. The Expanse and Homeworld both do this.

3. Where the limit lives: cues.json engine layers; effects.md has no engine-plume rule; sound.md says only that engines share a family.

4. Why it is there: One loop is cheap and loops cleanly.

5. Loosening: Make the engine a parameterised loop (thrust 0-1 drives pitch, filter and sub), with a start whoomp and a shutdown sigh. Give class presets (frigate bright, capital deep). On the picture side, make plume length and brightness follow thrust and class.

6. Size: Medium. Frame cost: low.

7. Point at: f1; cues.json engine.

12. Death sounds are shorter than the death pictures [SOUND + RULE]

1. Now: Death cue durations are death_powerdown 0.6 s, death_vent 0.5 s, death_crack 0.4 s, death_run 0.72 s, chunk_cool 1.5 s, hulk_vent 1.15 s. The cruiser picture runs about 10 s and the capital's coals about 14 s.

2. A film would: Treat a capital death as a long sequence, groans, vents, cracks, settling, not six short one-shots.

3. Where the limit lives: cues.json duration fields; deaths_and_hits.md cruiser “to about 10” and capital “Coals cool for about 14 s.”

4. Why it is there: Cues are one-shots; no bed was built.

5. Loosening: Add a death_bed cue per size (a loop with slow evolution) that runs the visual length, with the existing one-shots layered on the beat times; let the bed duck under the core flash, then swell.

6. Size: Small-medium. Frame cost: audio only.

7. Point at: cues.json death_* durations; deaths/capital_death_beats.jpg.

13. FLASH_CAP flattens the biggest moments, report, do not remove [RULE + SAFETY]

1. Now: At most three large bright flashes per second. A capital death's core flash, chain blasts and secondaries can exceed that, so later flashes are suppressed or softened, turning a burst into a metronome and flattening the biggest event.

2. A film would: Let a big death carry a rapid series of flashes, or, if capped, let the light linger rather than vanish.

3. Where the limit lives: FINDINGS R187 caution: “godot/fx/fx.gd FLASH_CAP := 3, at most three large bright flashes in any second … WCAG 2.3.1”; effects.md §4: “The reduce-flashing variant keeps the same sizes with the softer rise and fall the table gives.”

4. Why it is there: Photosensitivity safety, on for everyone. This is a real reason, not a habit.

5. Loosening: Do not remove it. Get drama inside it: make a suppressed flash linger as light and colour (a bright area that fades over 0.3-0.5 s instead of a new flash), use smaller bright areas with a big soft bloom, ramp slower, and let sound and a short camera shake carry the hits the cap cannot show. Schedule the three biggest flashes for the moments that matter (core flash, first chain, the break) and turn secondaries into glows.

6. Size: Small (scheduling plus a glow path). Frame cost: none.

7. Point at: deaths/capital_death_beats.jpg; FINDINGS R187.

14. The scene dim does not read in its own proof [PICTURE + RULE]

1. Now: The capital beats strip prints the death twice, scene dim OFF and ON, and the two are hard to tell apart even side by side in a bench whose purpose is to show the difference.

2. A film would: A core flash that takes the light with it leaves a visible dark afterimage, so the next light reads brighter.

3. Where the limit lives: deaths_and_hits.md capital: “the whole scene dims a little for a fifth of a second.”

4. Why it is there: A cautious value and a short duration; easy to leave out.

5. Loosening: Either make it count, dim 25-35% for 0.35-0.5 s with an ease-out, or drop it. Test on the strip at camera 170; if it cannot be seen in the proof, it will not be seen in battle.

6. Size: Small. Frame cost: none.

7. Point at: deaths/capital_death_beats.jpg (dim row).

15. The camera is forbidden to move for a death [RULE]

1. Now: “The camera is never taken from the player for a death.” Big deaths play at the same camera as everything else: no push-in, no shake, no linger.

2. A film would: Give a capital death a slight push or a hold, and a shake to sell the hit. BSG and The Expanse never let a capital loss pass at the same framing as a fighter loss.

3. Where the limit lives: deaths_and_hits.md: “The camera is never taken from the player for a death.”

4. Why it is there: Player control and readability; comfort.

5. Loosening: Allow a short, optional, non-blocking camera emphasis: a ~0.3 s shake on the core flash, a 5-10% push-in that returns, and a linger on the wreck for a beat. Keep it skippable and off under reduce flashing. It is emphasis, not a cutscene.

6. Size: Small-medium. Frame cost: none.

7. Point at: deaths/capital_death_beats.jpg.

16. Salvos fire on one tick and get one shared tail [RULE + SOUND]

1. Now: cues.json groups gun cues with salvo: “gun” and gives one shared salvo_tail boom. The blind leg predicts salvos fire on one tick in the picture too.

2. A film would: Ripple a salvo, guns fire in a ragged sequence, each with its own report, and the tail is the sum of the reports rather than one boom.

3. Where the limit lives: cues.json gun_shell salvo: “gun”, salvo_tail layers; effects.md has no salvo rule.

4. Why it is there: Grouping is tidy and cheap; one tail covers many guns.

5. Loosening: Stagger salvo reports by 20-60 ms per gun with per-gun pitch, and let the tail be the sum of the reports. On the picture side, let muzzle flashes ripple across the battery rather than fire as one block.

6. Size: Small. Frame cost: low.

7. Point at: cues.json salvo_tail; m5.

17. The hit ladder is a measured spec, not an eye: a 1.4 step and a two-frame rise for everything [RULE]

1. Now: Every event's size is 1.4× the one below, and the flash reaches full size inside two frames, so a las and a torpedo have the same rise shape.

2. A film would: Let sizes jump unevenly (a torpedo is not 1.4× a macro) and give big events a visible rise, a bloom that overshoots then settles.

3. Where the limit lives: effects.md §1: “Each step up the ladder is about 1.4 times the one below”; §3 step 3: “the flash reaches its size inside two frames.”

4. Why it is there: A tidy ladder and an instant flash are easy to measure and check.

5. Loosening: Keep a ladder but break the constant (for example las 40, macro 60, lance 90, torpedo 170, death 320, with uneven ratios), and give big events a 2-4 frame rise with a bloom that overshoots then settles; keep the two-frame rule only for the smallest flash.

6. Size: Small (data). Frame cost: none.

7. Point at: m5; effects.md staging table.

18. The “never” language removes lingering drama [RULE]

1. Now: The rules say “Never rolling fire”, “Nothing floats beside the hull”, and “no flame lives longer than 0.70 s”; after the flash there is nothing to watch cool. Small craft deaths are capped at “under 40 px, no wreck”.

2. A film would: Let fire roll, gas curl, coals glow and fade, and debris drift; even a fighter kill leaves a tumbling fragment.

3. Where the limit lives: effects.md §1 flame cap; deaths_and_hits.md rule 2 “Never rolling fire”, rule 4 “Nothing floats beside the hull”, small craft “under 40 px, no wreck”.

4. Why it is there: Owner ruling, perf, and avoidance of floating effects.

5. Loosening: Distinguish flame from matter: keep the 0.70 s flame cap, but allow rolling gas/dust, drifting debris and glowing coals (already partly allowed: “coals cool for about 14 s”). Let matter detach and drift after the break, anchored at spawn. For small craft, keep the concurrency cap but allow a 40-60 px readable pop with a fragment.

6. Size: Small (wording plus material budget). Frame cost: see Finding 3.

7. Point at: deaths/cruiser_death_beats.jpg; m4.

What I could not judge

I cannot hear the game, so I judge the sound from sound.md, cues.json and the clip list, structure, not timbre. I have not seen it move, so the movement section is reference and design, as issue 489 asks. Timing and rhythm inside a turn (whether salvos fire on one tick) need the capture leg's measurements.

MOVEMENT (issue 489 sections 1-5)
How the best space battles show weight and vacuum

The Expanse (TV). The reference for weight. Ships burn along the nose and coast dark; turning is done by RCS puffs and is separate from travel; to stop or reverse they flip and burn. Plumes are long, bright and class-scaled; a corvette flips fast, a battleship turns slowly. PDC tracers arc and flak leaves a wall. The audience always knows which way a ship is going and which way it is pointing.

Battlestar Galactica (2004). Vipers and Raptors drift and rotate; the battlestar's turns are slow RCS manoeuvres with visible puffs; flak and tracer arcs show the volume of fire. The show is less rigorous than The Expanse about Newtonian motion, but it sells mass and vacuum through the contrast between small craft and the battlestar.

Babylon 5. The Starfury is the best “drift while turned” reference: thrusters at all corners let it rotate to fire while its travel continues. That single device, nose and velocity decoupled, is the one this game most needs.

2001: A Space Odyssey. Slow rotation, no sound, weightless drift. The lesson is patience: mass reads as time taken.

Firefly / Serenity. Flip-and-burn and visible RCS puffs; the engine note changes with thrust.

Homeworld 2/3. Fleet-scale reference: capitals slow with RCS puffs, strikecraft drift, ion beams with a source under load, debris that persists.

Nexus: The Jupiter Incident. The closest game reference for Newtonian-ish capital movement: ships drift and rotate, thrusters fire on the hull, turns are committed and slow.

Sins of a Solar Empire. Good for fleet readability and clean tactical sound, but its capital movement leans naval; use it for scale and mix, not for motion.

Elite Dangerous / Star Citizen (flight assist off). 6DOF drift, but too free for a hex board.

What suits a turn-based hex game seen from above, and what does not

Suits: flip-and-burn as a LOOK (rotate during the move, engine flare at the ends); drift while turned (translate along the hex route while the nose rotates independently to the final facing); RCS puffs at authored hull points during rotation and at start/stop; main engine burn only during acceleration and braking, dark coast between; class differentiation (capital spool-up, slower rotation, bigger plume, a settle/overshoot); a smooth spline route through hex centres; a short camera lead/lag and engine-start shake; a small settle at the end of a move; slow drift and rotation on wrecks and stopped ships.

Does not suit: banking or rolling into a turn (aircraft tell); nose always along the path (car tell); a wake or bobbing (water tell); a turn that needs forward speed; broadside naval turning; full multi-turn Newtonian drift that changes which hex the ship ends on (it would confuse the board, keep translation on the route and rotate independently).

How good hex and fleet tactics games handle facing and routes

BattleTech (tabletop and the HBS game) makes facing a choice with a cost; players complain when a unit ends facing away from every enemy, when the route forces a facing, and when the “hex spine” makes a path look crooked. Battlefleet Gothic: Armada makes turns slow and committed; players complain about being unable to come about in time. Star Hammer: The Vanguard Prophecy makes facing matter in a hex-like space and is praised when the final facing is legible before commit. Into the Breach and XCOM avoid the problem by not having a facing on movement, so they offer no lesson here.

The recurring complaints are: a snap to final facing; a spin the long way round; a route that zigzags or stair-steps along hex centres; a preview path that does not match the flown path; a ship that ends facing away from every enemy; and a final facing the player did not choose. The good handling is: show a ghost of the final facing before commit, animate the pivot as a manoeuvre, draw the route as a spline with rounded corners, and fly exactly the previewed spline.

Movement proposals (eight; each marked LOOK or RULE)

M1. Decouple the nose from the travel, drift while turning [LOOK]

1. Now: From the stills and the issue 489 framing, the ship slides along the route with its nose pinned to the path and snaps to a heading at the end. It reads as a counter on rails.

2. A ship in space, on film: Babylon 5's Starfury and The Expanse's ships drift one way while pointing another, with thrusters firing to rotate.

3. Where it lives: issue 489 §1 names the tell: “following a curved road-like arc with the nose always along the path, like a car”. The final facing is decided by _best_facing in godot/scenes/battle/battle.gd (named in the issue 489 brief).

4. Why it is there: Nose-on-path is the simplest interpolation and the easiest to check.

5. Change: Keep translation along the hex route, but drive the nose with a separate rotation curve toward the final facing, starting at move start and finishing with a settle. For part of the route the ship visibly drifts sideways or backwards relative to its nose. Playback only.

6. Size: Medium (one or two runs). Frame cost: none.

7. Capture: A cruiser making a two-hex lateral move ending 90° off its travel.

M2. Main engine burns only when accelerating or braking; plume scales with thrust and class [LOOK]

1. Now: f1 shows one identical white engine smudge on every hull; the engine reads as on/off.

2. A ship in space, on film: The Expanse and Homeworld: a long bright plume under burn, dark while coasting, a flare to brake.

3. Where it lives: effects.md has no engine-plume rule; cues.json engine is a single loop.

4. Why it is there: Not specced.

5. Change: Drive plume length, brightness and colour from a thrust curve per class; an ignition whoomp at start, a shutdown sigh at coast, a retro flare at the end; a capital plume 2-3× a frigate's with a slower ramp. Playback only.

6. Size: Medium. Frame cost: low.

7. Capture: A frigate and a capital each making a one-hex move.

M3. Manoeuvring thruster puffs on the hull at rotation and at start/stop [LOOK]

1. Now: No visible RCS; the ship rotates with no visible cause.

2. A ship in space, on film: The Expanse RCS puffs, Babylon 5 Starfury corner thrusters, Homeworld.

3. Where it lives: issue 489 §2: “Are there manoeuvring thrusters at all? … placed on the hull where a thruster would be”.

4. Why it is there: Not built; perf.

5. Change: Spawn short puffs at authored thruster hardpoints: bow-right and stern-left fire for a left yaw, the reverse for a right yaw; forward puffs on braking; scale with class. Playback only.

6. Size: Small-medium. Frame cost: low.

7. Capture: A ship pivoting 180°.

M4. End-of-move facing as a visible weighty pivot, not a snap [LOOK]

1. Now: The ship snaps to its heading at the last hex.

2. A ship in space, on film: The Expanse flip-and-burn: the rotation is the manoeuvre; capitals take seconds.

3. Where it lives: issue 489 §5: “Does the ship turn to its final facing at the end as one visible, weighty manoeuvre, or does it snap?”

4. Why it is there: A snap is clean and fast.

5. Change: Animate the pivot over 0.3-0.8 s (class-scaled) with thruster puffs and a slight overshoot/settle; if the rules make it spin the long way, show that (and see M7 for the rule question). Playback only.

6. Size: Medium. Frame cost: none.

7. Capture: A cruiser ending 120° off its travel.

M5. Capital versus fighter motion signatures [LOOK]

1. Now: issue 489 §3 predicts “speed that is the same for every ship and every move” in playback.

2. A ship in space, on film: The Expanse's Donnager versus the Roci; Homeworld capitals.

3. Where it lives: issue 489 §1 weight; data.js sp and tn exist, and godot/rules/data/tables.json holds the same, but playback may not express them.

4. Why it is there: Uniform playback is simple.

5. Change: Let playback duration and rotation ease by class: capitals get a longer spool, slower rotation and a visible settle/overshoot; fighters turn quickly but still drift; plumes and puffs scale. Playback only.

6. Size: Medium. Frame cost: none.

7. Capture: The same move with a frigate and a capital.

M6. Smooth spline route through hex centres; preview matches flown [LOOK]

1. Now: The route stair-steps along hex centres, and the preview may not match the flown path.

2. A ship in space, on film: No hexes, but a ship under thrust follows a smooth curve; the point is the look of the route.

3. Where it lives: issue 489 §4: “Does a route zigzag across hexes where a straight run exists? … does the path shown to the player before he commits match what the ship then flies?” The brief names _path_dots and _move_segments.

4. Why it is there: Hex-grid readability.

5. Change: Draw the route as a Catmull-Rom spline through hex centres with rounded corners and a lead-in/out; fly exactly that spline; show the same spline in preview. Playback only.

6. Size: Small-medium. Frame cost: none.

7. Capture: A multi-hex diagonal move.

M7. Let the player choose the final facing (or default to best arc) as a captain's decision [RULE]

1. Now: _best_facing picks the final facing; a ship can end facing away from every enemy.

2. A ship in space, on film: A captain chooses to present guns; Babylon 5's Starfury rotates to fire.

3. Where it lives: issue 489 §5 names _best_facing; forward (F) weapons matter most, so a wrong facing costs shots.

4. Why it is there: Fewer clicks; helps the AI.

5. Change: After the route, offer a facing picker within the turn budget, with a ghost preview of arcs, defaulting to the best arc. This changes play, so it is a RULE: it needs Ryan's ruling and must be kept in step in both rule twins (battle.js/core.js and godot/rules/rules.gd, named in issue 489). Playback plus rules.

6. Size: Medium-large (rules, UI, both engines). Frame cost: none.

7. Capture: A ship with only forward guns ending a move.

M8. Secondary motion and camera: engine-start shake, hull recoil, settle, debris drift, slight camera lead [LOOK]

1. Now: Ships slide as counters; the camera is fixed; f1 suggests no drift, recoil or exhaust change.

2. A ship in space, on film: The Expanse and BSG: hulls shudder, the camera shakes on burns, debris drifts.

3. Where it lives: issue 489 §3 (“ships sliding through each other … a ship that teleports its last step”) and the f1 observation in the blind leg.

4. Why it is there: Not specced.

5. Change: On engine start, a small camera shake and a hull recoil; on stop, a settle; wrecks and stopped ships keep a slow drift and rotation; the camera leads the moving ship by a few percent and returns. Playback only.

6. Size: Small-medium. Frame cost: low.

7. Capture: Any move; a wreck drifting.

The single loosening that would do the most

If I could pick one, it is Finding 3's separation of flame from matter: keep the 0.70 s flame cap, but stop applying it to everything. Let sparks, debris, gas, dust, venting jets and scorch have their own longer lives, and let a hit or death carry three to five materials at different speeds. That single change breaks the “one soft ball” look that runs through every picture in the bench, gives the sound's new tails something to match, and makes the shield, the beams and the target-scale fixes land on a battlefield that already looks like matter rather than a diagram. It is also the cheapest of the big wins: it is a materials budget and a spawner, not a new renderer.
