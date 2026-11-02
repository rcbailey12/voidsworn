# Task: playtest fixes, batch 1 (Ryan's Nov 2 morning playtest)

Ryan played 9 battles on the exe built from main b50c932. His phone photos of the screen are in docs/shots/playtest/2026-11-02/ (ryan_01 to ryan_20; photos of a monitor, so ignore moire stripes). Read contrib/opus/briefs/feel_pass_2026-11-01.md (house rules) and godot/fx/API.md first. Touch only what each item needs.

**Start here:** an earlier run of this job did most of the work and then hit the usage limit before its checks. Apply it first: `git apply contrib/codex/fb1_partial.patch`, then delete that patch file. Review what it did against each item below, finish what is missing (API.md notes, the blocker check across generated battles, the destruction checks), fix anything that fails, and remove godot/world/debug_blocker_tmp.gd if it exists. Keep test scratch folders out of the commit.

Items, in order:

1. Torpedo aim lane points the wrong way (ryan_02: the chevrons run from the target back toward the firing ship). Make the lane read from shooter to target, for every weapon kind that draws a lane, and check the enemy-intent lanes too.

2. Line of sight and blocked hexes are invisible (ryan_16, ryan_20: "Line of sight is blocked" with nothing visible in the way; Ryan also could not move to hexes for no visible reason). Audit every terrain kind that blocks sight or movement in rules.gd (and battle.js) against what godot/world draws, including planet footprints, stations, hulks and small rocks, at the default cinematic camera. Then:
   a. Every blocking hex must show something solid at that hex (if a model is too small or sits off its hex, fix the placement or scale so the footprint and the visual agree).
   b. When a shot is blocked, outline the hex(es) that block it and name the blocker in the tooltip ("Blocked by the asteroid at ...").
   c. When the player hovers a hex they cannot enter, the tooltip says why.
   No rules change: the rules decide what blocks; you only show it.

3. Hull holes and wrecks (ryan_03, ryan_06, ryan_07, ryan_09):
   a. The breach size must follow the damage that section actually took. A ship at 90% midships hull must not look like its midships is gone. Small hits are scorches and small punctures; only heavy section damage opens big holes.
   b. The flat square particles that drift out of holes look like floating squares. Replace them with small irregular hull shards (meshes, not quads), with a few sparks and embers, and cap the count.
   c. Holes must never show as a flat black disc (ryan_03): the cavity needs depth, inner structure and a lit rim.

4. The Chorus is organic (ryan_03 is a Chorus hull). Give Chorus ships their own damage and death look: wet torn flesh and membrane edges instead of metal plates, ichor and spore puffs instead of sparks and metal shards, a pulsing or bleeding glow in wounds, and a death that collapses and deflates or ruptures rather than a metal break-up. Keep it non-gory (no blood-red gore); use the faction's colours. Glasswright damage should also read as crystal (chips, refracted light) if cheap.

5. Battle start is slow: every battle bakes planet and sky textures for 2 to 6 seconds each (godot.log "[world] baked planet ... in 5593 ms", 6 to 9 seconds per battle). Cache the bakes to user:// keyed by their seed and settings, so a repeat is a load, and bake on a thread or at a lower size first so the battle opens quickly.

6. Debris (ryan_04, ryan_13) is plain grey boxes and trusses next to detailed asteroids. Build debris from real hull pieces instead: chunks cut from the existing ship meshes of the factions in this battle (godot/assets/ships), with the same paint, scorches and torn edges as the breach work. Keep the same footprint and tooltip. The ship .glb files are not in this folder (they live only in the full build): write the code to cut chunks from the ship scenes already loaded in the battle at runtime, fall back to the current debris when none are loaded, and test the cutting with a simple stand-in mesh.

Do not change movement, the blue move tiles, planets, the station model or rules numbers in this batch (those come next, after Ryan answers some questions).

Tests: parse-check every changed .gd; rules parity must still PASS (no rules change); the destruction checks in godot/fx/test; add a headless check that every blocking hex in a sample of generated battles has a visual at that hex. Report file names of any captures. Final message: per item what changed (file:line), checks, and anything left. Plain ASCII, never the em dash; no commit (the board runner commits and pushes).
