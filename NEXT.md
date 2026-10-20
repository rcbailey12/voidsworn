# NEXT: the build queue

Build in this order. Anything not listed here goes to the parking lot at the bottom, not into the current version. Full reasoning: the master review doc (claude.ai artifact aef64607-980c-49ce-977b-ff7b8a32868a).

## v53: solid and readable (publish each workstream as it lands: v53.1, v53.2, ...)

Gate before every publish: `node sim3d.js rulecheck`, `node sim3d.js fuzz 20`, `python3 smoke.py` all pass; one battle on the Pixel for anything visual.

- [ ] A. Board readability: drift near zero (coastCap), motion on the model only; side-coloured ring on every occupied hex; contact shadow; move hexes outline-only; nebula dimmed under the board; expected-damage line + ghost ship on first tap.
- [ ] B. Correctness and safety: animPath stops writing u.q/u.r/facing (ramUnit gets its own commit); live() checks in rotateUnit and blink; B.seed overwrite in prepBattle removed; floating killUnit calls awaited in order; swarmPhase under stallGuard; weapon spent only after the live check; seeded lifepod roll; cloud-save run vs settings timestamps; save defaults in one place; seed replay check; smoke extended through a sector boss.
- [ ] C. Loading and phone performance: parallel awaited hull fetch before the title with progress and a log line naming the live hull path; skip fragmentHull at Medium; pool fxText; full frame rate while animating; shared shield ring geometry; a ?prof=1 profiler capture that exports CSV.
- [ ] D. AI that reads: per-weapon target re-pick; shield strippers first; sticky focus; threat ignores fired guns + death cliff; objective terms with round clock; abilities after moving; squadron focus; escort spacing; enemy focus marker on the board (tap, not hover).
- [ ] E. World: asteroid rebuild (tall faceted blockers on a marked hex, sparse dressing off playable hexes, recipe variety, sharper shapes, v51 filler pulled back); Ithar material fix; one Ithar sail card test.

## v54: factions and rewards (parallel with v55)

Doctrines (Ithar and Chorus first, then Corsair, Deathless, Hegemony, Voidsworn); boon decline + reroll; rule-changing boons; legendary per patron (Hades style, unlocked at boss/elite after 2-3 of that patron's boons); rarity changes effect; shared refit tracks per class; kill marks and sector chronicle; section consequences; fire damage-control choice; earned Admiral's Command; objectives that change priorities; faction AI behaviours; differentiated admirals.

Decided rules: Ithar fire then move (post-fire move capped at half, no climb/dive); Chorus heals on dealing damage at range 1-2, capped per round, with a will-heal indicator; Voidsworn brace also shields one adjacent same-facing ally; Corsair capture pays a bonus refit/salvage on top of normal rewards, one prize per battle, never a flagship; Deathless one return per battle for the fleet, telegraphed a round ahead, not the flagship, returns low and cannot fire that activation; Hegemony ion stops shield regen on the struck facing for a round. Mid-battle reload replays the same node and enemy fleet.

## v55: spectacle

Ithar remesh (sails erased with Qwen-Image-Edit, hull core via Hunyuan, sails in engine); Corsair variants; Deathless frigate; per-hull Blender pass (weighted normals, curvature, gradient); per-ship tint and hull numbers; finer windows; CC0 explosion flipbooks; death timing by class; ripple broadsides; thicker beams; section smoke; shield quadrant ripple; sinking wreckage; arcing torpedoes; Sonniss + synth sound pass with distinct cues; 4:1 lighting with rim; backdrop pass; parallax dust; bodies above and below the board.

## Still cut (design reasons)

Altitude combat rules and class heights; stances and momentum; undo after a move; ground-first picking; rules/graphics event-queue refactor; gltfpack; tactical view toggle; one-shield small ships (maybe later as an experiment).

## Parking lot

(new ideas land here first)
