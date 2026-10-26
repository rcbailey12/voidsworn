# Brief for Muse: sprint audits, round 2 (Oct 26, 2026, afternoon)

From Opus. House rules as in `contrib/opus/briefs/muse_2026-10-25_engine_and_b2.md`: blind legs (Argon, DeepSeek, Qwen), primary sources with links, file:line for repo claims, UNSURE tags, plain words, no em dashes, raw returns in `contrib/<model>/`, syntheses in `contrib/muse/reviews/`, no edits under `contrib/opus/`, `godot/`, game code or HANDOFF.md, commit to main. The earlier sprint queue (Jobs A campaign part, C part 3, E, F) is scrapped by Ryan; this replaces it. Usage is short, so run jobs in the order given and file whatever finishes.

Opus will independently verify every claim you file against the repo (`contrib/opus/evidence/`), so precise file:line references matter more than volume.

## Job 1: new-names review (trigger: `contrib/opus/compute/rename_map.md` on main)
Ryan ruled (FINDINGS R44) that every Warhammer 40k-adjacent name is renamed. For each proposed new name: (a) does it collide with another game, franchise or trademark (search; cite), (b) does it still read as that faction (voices in data.js and `godot/story/outlines.md`), (c) is any remaining name in data.js still 40k-adjacent that the map missed. Deliverable: `contrib/muse/reviews/rename_review.md`.

## Job 2: Nemesis faction behaviour review (trigger: stream B Nemesis commits; see `contrib/opus/compute/port_notes.md`)
Ryan (R42): the Nemesis must feel different every run and behave differently by faction (Corsair raids and flees, Deathless returns once after death, Ithar duels and withdraws, Chorus feeds on your losses, Hegemony reinforces, Voidsworn challenges). Compare the implementation against Shadow of Mordor's Nemesis system and other rival systems (sources), and check: is each faction's behaviour readable to the player before the fight, fair (no ship loss without warning, no stealing control, R7), and distinct; does he remember the player in ways the player notices. Deliverable: `contrib/muse/reviews/nemesis_review.md`.

## Job 3: per-weapon damage marks reference (start now)
Ryan (R43) wants every weapon to leave its own mark on the hull itself (lance burn-through, plasma splash craters, gauss punctures, torpedo blast craters, flak pockmarks, bio acid pitting, ion burns, ram crumple, boarding breaches). Research how readable, distinct hull damage is done in Homeworld 3, Sins of a Solar Empire 2, Battlefleet Gothic: Armada 2, Starsector, BattleTech, Children of a Dead Earth and others (screenshots described in words, developer talks, sources), and give per weapon: what the mark should look like at a distance of a tactical camera, how it should evolve over a battle (fresh, cooling, scarred), and what keeps 20 ships readable when they are all damaged. Deliverable: `contrib/muse/reviews/damage_marks_reference.md`.

## Job 4: campaign map UX review (trigger: PC screenshots of the 3D map under `docs/` or reported in commits by the G3 helper)
Ryan (R36, R38): the map should be more detailed, more interesting and more useful, like Sins 2, BattleTech and Rogue Trader. Judge the new map against those references for: route planning, information at a glance, danger readability, visual interest, clutter. Deliverable: `contrib/muse/reviews/campaign_map_review.md`.

## Job 5: music licences (trigger: `godot/music/CREDITS.md` on main)
Check every track's licence at its source page: CC0 or CC BY only (no NC, ND or SA), the author and licence URL correct, attribution text complete for a commercial Steam release. Deliverable: `contrib/muse/reviews/music_licence_check.md`.

## Job 6: story unlock balance (trigger: stream B adds the story hull variants, see `godot/story/unlocks.md` and port_notes.md)
Each faction gets one hull variant for finishing its arc, meant as a sidegrade. Check each against its base hull and the faction roster (data.js) and the sim numbers stream B posts: is any a straight upgrade or a trap pick. Deliverable: `contrib/muse/reviews/story_unlocks_review.md`.

## Job 7: accessibility pass (start any time)
Check the Godot game's settings and UI code (`godot/main/`, `godot/ui/`, `godot/fx/`) for colour-blind readability of factions and danger bands, flashing limits (at most 3 per second; a reduce-flashing option exists), text size and contrast, input remapping, and hold-vs-toggle controls, against Xbox and Game Accessibility Guidelines (sources). Deliverable: `contrib/muse/reviews/accessibility_review.md`.

Order if usage runs short: 3, 1, 2, 5, 6, 4, 7.
