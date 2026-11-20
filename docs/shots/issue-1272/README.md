# Issue 1272: skies that react to the stop, and more planets (run 1, Nov 20 2026)

Stage: installed in game (opus/issue-1272), cloud render (Godot 4.7.2 Forward+ on lavapipe, quality high), ships hidden
because the cloud copy has no built hulls. Ruling: R352 (keep rival, boss and salvage moods; salvage dust stronger than the
r1 preview).

- `SKY1272_stops_r2.jpg`: one Hegemony frontier sector, four stops at camera 420, made by `godot/world/stop_sky_shots.gd`
  through the game's own path (main.gd stop_of, world.gd sector_setting, world_sky.gd stop_mood). The plain, rival and boss
  stops use a storm map, the salvage stop a wreck-field (graveyard) map, as the game decides salvage by map.
- `stop_<kind>_c420.jpg` with the provenance record of each source PNG.
- The nebula is still violet here: this branch is cut from main before PR 1304 (rose) merged.

What changed: one STOP_MOOD table and one STOP_FRAMES table in world_sky.gd; 8 remixed planet looks (PLANETS_ALT, RULEBOOK
10.3), chosen per sector. A stop against another faction than the sector's is rival, a boss fight is boss, a fight on a
wreck-field map is salvage; anything else is plain and draws today's sector sky with a per-stop planet framing.

Check: `godot/world/test/stop_sky_check.gd` (headless, 40 seeded campaigns through three sectors with the real campaign
generator): backdrop vistas per campaign today 3.0, now 18.2; planet looks seen 16 of 16; smallest sky change from a plain
stop of the same sector: rival 0.080, boss 0.132, salvage 1.448; the anchor planet never changes inside a sector.
