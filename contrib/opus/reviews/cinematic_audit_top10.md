# The cinematic audit: one list for Ryan

Issue 487 (and 485, 486, 489). Written by the Board (Fable 5.2), Nov 11 2026. FINDINGS R186 to R189 are the brief.

Ryan asked: "find other similar issues like the death breaking up really cleanly... effects, the weapons, the sounds, anything like that, that we sort of have these weird arbitrary, like, guidance on that is making it... more restricted and less realistic and cinematic than it should be", and then: "Can we also audit ship movement? Make sure it's clean, feels weighty and like you're in space, not water or land?"

Nothing here is built. Ryan picks; then jobs are filed.

## Where this comes from, and how it was checked

Four reports, all on main or in open pull requests:
- contrib/opus/reviews/cinematic_audit_code.md (an Opus worker read the code and rule books: 15 findings)
- contrib/opus/reviews/movement_audit_code.md (an Opus worker read the movement rules and playback: 14 findings)
- contrib/muse/reviews/cinematic_audit_2026_11.md (Muse, five models, from the captures and the rule books; a blind leg first)
- contrib/codex/reviews/cinematic_audit_capture.md (Codex played a six-ship and a twenty-ship battle on the PC, filmed motion strips for three ship sizes, and measured them)

What the Board did with them, as Ryan asked ("validate themselves, look for root causes that might be evidenced by the audits but they don't call out explicitly"):
- Opened every cited file and line for the items below. All hold. Lines are given so anyone can re-check.
- Read the W3C page behind the flash limit itself (item 2).
- Looked at every capture used below.
- Kept three corrections that one leg made to another. Codex showed the hull-hit sound is not one file (it has six takes); the fault is that the weapon does not choose the sound. Codex also notes a weak-looking hit is not proof the flash counter refused it. The movement worker reversed the first audit on the roll into turns (remove it, do not raise it).
- Re-read each old ruling for its purpose before calling anything a conflict with it (R189).

## The root causes

Five habits explain almost every finding. Fixing the habit matters more than fixing the list.

**A. One strict counter, and everything tuned to hide under it.** The game counts a bright flash from 65 pixels across. The guideline it cites counts from about thirteen times that area. Every hit, muzzle flash and hull light was then sized to sit just under the game's number, on purpose (godot/fx/fx_weapons.gd lines 64 to 69: "All stay under the 65 px... so they never wait on the flash budget... Claude's calls, vetoable"). So no gun in the game is allowed to look big.

**B. One recipe, resized.** Every hit, explosion and death is the same flash plus the same soft puff, at different sizes. The playbook describes different hits for different weapons (a spark cone for shells, a crawling burn for the lance, fire through gas for a torpedo). Those rows were written and never built; one bake route was cheaper and easier to measure.

**C. The rule books describe a better game than the one that runs, and nothing checks the difference.** Written and not running: hits light the ships around them; wounds glow, cool and stay as craters; the lance's contact burn crawls and leaves a tail; a slow-motion beat on big deaths (R73: the function exists and only a test calls it); braking and side jets (in the movement spec; they only fire in an old debug mode). The checks measure what is easy to measure: a size within fifteen percent, a rise within two frames.

**D. Rulings written down as short bans, then obeyed to the letter.** "Thruster puffs only on turns, no side-to-side shuffle" (R76) cost the game its braking burns; Ryan's actual complaint was that movement was sudden (R189). The same thing happened to "fire is wrong for space": the 0.70 second cap on flame was applied to sparks, debris, gas and embers too, so nothing is thrown and nothing lingers. And to "short and dry" sound, which was built as no tails at all. The Board wrote most of these lines.

**E. An even clock, judged one ship at a time on a bench.** Shots leave at exact fixed intervals; chain blasts are evenly timed, one size, spread as far apart as possible; secondaries are born together. The look bench shows one ship against a plain sky, so nothing was ever judged in a moving twenty-ship fight until Codex filmed one for this audit.

A sixth, smaller one: **nothing scales with who is shooting or who is hit.** A hit is sized by the target's class only; ship weight stops growing at battleship size.

## The ten, ranked by what the player gains

Each has a named picture in docs/shots/cinematic_audit/top10/. LOOK means only the picture or the sound changes and battle results stay identical. Sizes are in agent runs (small: one; medium: two or three; large: more), each plus one review round with Ryan.

### 1. Every gun leaves the same small spark
- **Now:** a battleship's main battery and a frigate's gun leave the same puff. On a capital ship it is a dot. Ten weapons on one hull give nine identical marks.
- **Where:** godot/fx/fx_weapons.gd:1071-1072 sizes a hit by the TARGET's class only (56 px, times 0.8, 1.0 or 1.2); lines 64 to 69 hold the sizes under the flash counter. docs/playbooks/deaths_and_hits.md already describes a different hit per weapon.
- **Fix:** build the playbook's hit rows as real, different recipes (shell: a spark cone that skips; energy: a splash that runs along the plate; torpedo: fire through gas with thrown debris), and size each by the gun that fired it as well as the ship it hits. Root causes A and B.
- **LOOK. Large** (three or four runs, with a rebake). Picture: t01_hits_one_small_stamp.jpg.

### 2. The flash counter is about thirteen times stricter than the guideline it cites
- **Now:** a capital death uses the whole allowance for over a second, so a torpedo or a second death in that window is turned into a dim puff and lights nothing.
- **Where:** godot/fx/fx.gd:23-25 (three flashes a second; a flash counts from 6 percent of screen height). W3C, Understanding SC 2.3.1: the limit applies when the combined flashing area passes a quarter of a 10 degree field, which W3C estimates as a 341 by 256 pixel box on a 1024 by 768 screen. That is about a 234 pixel disc on a 1080 screen, against the game's 65.
- **Fix:** keep three a second and keep reduce flashing exactly as it is. Count by combined area, as the guideline does. Let a refused flash keep its size, colour and light and lose only its sharp peak.
- **Cautions:** several small flashes at once add up, and a large monitor close up has less margin. Prove the new counter with the salvo test before it ships. **This is a comfort limit, so it is Ryan's decision (below).**
- **LOOK. Medium.** Picture: t02_flash_counter.jpg.

### 3. Shields never answer a hit and never show their condition
- **Now:** a full shield, a shield at one fifth and a collapsing shield look almost the same. A hit puts a beige puff beside the bubble. The bubble bleaches the ship inside it white. (The bench's own caption says the low-shield look does not exist yet.)
- **Where:** docs/playbooks/effects.md section 1 defines only "invisible at rest, a faint edge glow... a downed side reads as a dark gap". No rule for a hit response or a strength state.
- **Fix:** a flare where the hit lands and a ripple outward; brightness and density that fall with strength; a break that fails in patches from the hit. A faint faction tint in place of the white bleach. This fits whichever shield look Ryan picks from the options sheet still owed to him.
- **LOOK. Medium.** Picture: t03_shields_never_react.jpg.

### 4. Nothing is thrown and nothing lingers
- **Now:** one soft beige puff for every act of violence. No sparks that arc, no fragments with a direction, no venting, no scorch. Space resets clean after each hit. (The new wrecks, issue 484, are the first exception.)
- **Where:** the flame cap (0.70 s, Ryan's ruling: fire is wrong for space) is applied to all matter; docs/playbooks/deaths_and_hits.md rule 4, "Nothing floats beside the hull"; and, per the code leg, wounds capped at 12 a ship with old scars deleted (not re-checked by the Board).
- **Fix:** keep the flame cap for flame exactly as ruled. Give matter its own lives: sparks under a second, debris one to four seconds, gas and dust a few seconds, embers that cool orange to dark with no flicker. Scorch that stays. Root cause D.
- **LOOK. Medium.** Picture: t04_one_material.jpg. **Ryan's confirmation asked below** (it is his fire ruling being read more narrowly).

### 5. The engine is a speedometer, and nothing fires to stop
- **Now (measured by Codex):** the plume is brightest at full speed and fades as the ship slows. A dreadnought stops from full speed in 1.2 seconds with nothing firing forward.
- **Where:** godot/render/ship_view.gd:1146-1148 (thrust is speed divided by cruise speed); retro and side jets exist (ship_view.gd:735, 1175) and are only called in the old segments mode.
- **Fix:** drive the main engine from acceleration (burn to speed up, dim glow while coasting), fire retro jets to brake and side jets to slide, from the forces the move already has. Same smooth path, same results. R189 says this is what Ryan wanted all along.
- **LOOK. Medium.** Picture: t05_engine_is_a_speedometer.jpg.

### 6. Turns are folded into the move, so the nose swings instead of being flown
- **Now:** the heading is blended onto the route in the first 18 percent of a move and onto the final facing in the last 24 percent. A dreadnought's final facing arrives as one late swing at 90 degrees a second; a one-hex sidestep swings the nose out and back. (The movement worker also reads the code as spinning the ship right round on a one-hex back-off; that one is not filmed yet and is unconfirmed.)
- **Where:** godot/render/ship_view.gd:1066-1067.
- **Fix:** give the heading its own motion with thrusters that start and stop the turn, slower for heavier ships; fly sidesteps and back-offs as slides with the heading held (R189). Remove the 4 degree roll into turns (ship_view.gd:1132), which is how aircraft and boats turn. Build with item 5.
- **LOOK. Medium.** Picture: t06_turn_folded_into_the_move.jpg.

### 7. The kill camera leaves before the kill, and the slow-motion beat never plays
- **Now:** the cut-in for a kill releases after 1.6 seconds. A cruiser's core flash is at 1.66 s; a capital breaks at 2.0 s and flashes at 2.3 s. The slow-motion beat Ryan asked for (R73) is in the code and is only ever called by a test.
- **Where:** godot/scenes/battle/battle.gd:1968; godot/fx/fx.gd:586. R123 (a Board ruling of Nov 8, not Ryan's): "the camera is never taken for a capital death; punch and slow motion are the only accents".
- **Fix:** hold the cut-in until just after the core flash; call the slow-motion beat at the core flash for cruisers, capitals and flagships; both skippable and off under reduce motion.
- **LOOK. Small.** Picture: t07_kill_camera_leaves_early.jpg. **Ryan's call below** (it changes how a kill feels and how long it holds the screen).

### 8. The gun does not choose the sound of its hit
- **Now:** one gun sound plays per volley, about 0.2 s before the first muzzle flash. Every hull hit uses the same family of clips whatever fired it (40 plain hits and 5 heavy in Codex's six-ship fight, from three different weapon types). Hit sounds for glass, ion, plasma, rail and wet impacts exist in the game files and are never played.
- **Where:** godot/scenes/battle/battle.gd:1786; godot/audio/sfx.gd:393-394; godot/audio/cues.json.
- **Fix:** one gun sound per shot at its own fire time; the hit sound chosen by weapon and by what was struck, using the clips already there.
- **LOOK (sound). Small.** Picture: t08_one_hit_sound_family.jpg.

### 9. Big moments have no build-up, no tail and no weight in the sound
- **Now:** every weapon is at full volume on its first frame. Death sounds run 0.35 to 1.5 seconds against death pictures of ten seconds and more. The sub-bass clip is not part of any death. Death cues have no pitch variation and one take each. Nothing ducks the mix under a death.
- **Where:** godot/audio/cues.json (death cues, duck 0 everywhere but the boom family); godot/audio/death_audio.gd; docs/playbooks/sound.md section 1, "Short and dry. Short tails, little echo", built as no tails.
- **Fix:** weapons stay dry. Deaths, capital hits and shield breaks get tails, the sub-bass, a bed for the length of the picture, the mix ducking under the core flash, and a beat of near-silence after a capital dies. A short charge on the lance and the torpedo. More takes come with the sound redo.
- **LOOK (sound). Medium.** No picture: it is sound. A listening page goes with the build.

### 10. Everything keeps perfect time
- **Now:** shots leave at exact fixed intervals with identical strokes. Chain blasts and secondaries are evenly spaced in time and place, one size, one colour. The core flash is a round ball centred on the ship. Ryan saw the same thing in the new wrecks: "the secondary explosion smoke looks a little too even and weird".
- **Where:** godot/fx/fx_weapons.gd:51-52, 212, 233, 240; godot/fx/fx_death.gd around 1357, 1463, 1480, 1510.
- **Fix:** seeded unevenness everywhere: timing, size, colour, placement in clumps and gaps; one blast plainly bigger than the pattern; the core flash at the torn face. Seeded, so a replay matches. The death half is already in the wreck job (issue 484).
- **LOOK. Small to medium.** Picture: t10_shots_on_a_metronome.jpg.

## The next ten, shorter

These are taken from the four reports. The Board has checked the file and line where one is given below, but has not looked at a capture of each.

11. **Light reaches the same 1.7 hexes for everything, and never touches a neighbour.** fx.gd:209 (range 30 for every light); the playbook asks for two to three hexes. Small; frame cost to measure.
12. **Beams are ruler-straight bars; the gauss is a hairline across the whole screen.** The playbook already asks for a crawling burn and a tail. Medium.
13. **Small ships die as a puff and a ring; the Eclipse burn-out is nearly invisible.** Goes into issue 463 (small-ship deaths).
14. **Camera shake is invisible** (a capital's break moves the view about 0.16 px; fx.gd:641-643). Small.
15. **Misses vanish in empty space** (fx_weapons.gd:1132 handles beams only). Small.
16. **Weight barely shows.** A battleship cruises 1.28 times slower than a frigate, and anything bigger moves exactly like a battleship (battle.gd:1501). Small; build with items 5 and 6.
17. **The dead star's pull plays as a powered move** (the ship turns and burns toward the star; battle.gd:1324). Small.
18. **One fixed climb over rocks and through friendly ships** (9 units up for every hull size; battle.gd:1618). Small to medium.
19. **Every faction moves the same way**, and the pace numbers make the Eclipse quicker per hex than the Glasswrights, who are meant to be the fastest. Medium.
20. **Parked ships bob like boats; the music is never told about gunfire or kills; the plume blips at about 40 percent speed.** Small each.

## What needs Ryan's own word

1. **The flash counter (item 2).** Board's pick: change how it counts (by area, as the guideline does), keep three a second, keep reduce flashing untouched, test before it ships.
2. **The kill moment (item 7).** Board's pick: hold the camera through the core flash and play the slow-motion beat on cruiser, capital and flagship kills, skippable.
3. **The flame cap read narrowly (item 4; Muse's question 1).** Board's pick: yes. Flame still flashes and snuffs out in 0.70 s; sparks, debris, gas and embers get their own longer lives.
4. **Flip-and-burn (R64, "flip-and-burn stays off", no reason recorded).** Board's pick: keep it off for now. Retro jets do the braking in items 5 and 6; look again once those are on screen.
5. **Bigger death flashes than the ruled table (Muse's question 2: cruiser 380 px, capital 560 px against the 302 and 423 Ryan ruled).** Board's pick: not now. Fix the counter and the hits first, then judge deaths again.
6. **Two changes that touch play, not only looks (RULE):** the facing the game suggests can point away from every enemy when no gun is in reach (battle.gd:2141; fix: prefer the prow guns and the nearest enemy), and the enemy ignores which way it ends up facing when it cannot shoot. Board's pick: yes to the first (it only changes a suggestion); the second waits for a balance run.

## The Board's pick of what to build first

The order follows the root causes, so each job unlocks the next.

1. **The flash counter (item 2).** Small in code, and it is the lid on items 1, 4 and 10. One Opus worker, with the salvo test.
2. **Hits (items 1 and 4 together, with the light from 11).** The biggest visible change in every fight. An Opus worker for the recipes, Codex for the rebake.
3. **Movement (items 5 and 6, with 16).** One Opus worker; Codex re-films the same motion strips for before and after.
4. **Sound (items 8 and 9).** The workhorse can do the routing in one run; tails and the death bed go with the sound redo and a listening page.
5. **The kill moment (item 7).** One small run, once Ryan rules.

Shields (item 3) follow as soon as Ryan has picked a shield look. Item 10's death half is already being built.

## How this stops happening again

These go into the rulebook (issue 492), not just this list:
- Every rule records the problem it answers, in Ryan's words where they exist.
- A number in a playbook is a starting point judged by eye in a moving fight, not a gate. Checks protect crashes, saves, comfort and frame rate; they do not lock looks.
- A rule that says the game does something gets a check or a capture that proves it does, or it is marked "not built yet".
- Effects are judged in a real twenty-ship battle capture, as Codex did here, as well as on the bench.
