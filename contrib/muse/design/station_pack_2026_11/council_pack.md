# Design pack: the Vesper Reach station, T2 (Voidsworn issue 654)

You are one leg of a design council. Your leg drafts the complete design pack for ONE accepted concept: station T2, so an Opus build-sheet designer can start from it without asking anyone anything. Write the whole pack, in the section structure given at the end. Ground every claim in the facts and rulings below; where the record is silent, make the smallest design call that fits and mark it as your call; where a question belongs to the Board, put it in the open questions section instead of deciding it. Plain ASCII in spirit: no em dashes.

## The station (accepted concept, R206)

T2 is a Hegemony fleet station of the Vesper Reach, abandoned after a write-off: the same station as the accepted in-service concept T1, in its damaged, half-dark state. Ryan picked T2 (R206, Nov 11, 2026: "T2 damaged", the Vesper Reach station, damaged and half dark). Issue 373 builds it through the ship recipe once its build sheet passes (R203).

T1, the station in service (the parts inventory T2 inherits): a core stack of 9 deck drums; a habitat ring turning on a segmented bearing track with one open gap segment; four docking arms at crossed angles and two heights with lit berth collars (one berth empty, guide lights on, cargo pods queued); five towers at five heights with five different caps; radiator banks under the core; about 650 implant-blue lights in clusters; fresh replacement panels among older ones.

T2, the same station after the write-off (the accepted pictures show exactly this): the ring seized off-angle with its gap segment moved; one spoke buckled; one docking arm torn down to a stub; debris held where it drifted to a stop against the arms and the ring; towers dead, one leaning; radiators cold; about 90 lights left, in scattered stubborn clusters, plus a few dull orange battery strips at torn frames; frost and dust on the shadow side; torn holes showing deck frames inside. Marks from the concept round: the flat radiator banks below read slightly like solar arrays (they are the same banks as T1's, cold); the family resemblance to T1 is carried by the ring, the drum core and the arms, and both directions share one parts kit at build time.

## Size (from the game's own data)

- godot/world/blocker_visuals.gd: each blocked station cell currently gets a piece 14.0 units across. The built station is sized from the hexes it blocks: at least three hexes wide, and taller than any ship (issue 373's done test).
- godot/render/hull_table.gd: SHIP_K 1.6; the cruiser entry is 14.5, so a cruiser is 23.2 units long. In T2's accepted scale view the station is a little over twice the cruiser across (about 50 units or more).
- The station must read at the default battle camera (r 170) without the orange blocker outlines explaining it.

## Rulings that bind (with sources)

- R109 (Ryan, Nov 5, 2026, on the old station repaint): "we need WAY more surface detail, it looks super plain and just like regular shapes right now." This is why the station is one built set piece now, not a repaint.
- R206 (Ryan, Nov 11, 2026): T2 accepted as a build reference; the build follows the build-sheet gate (R203).
- R98 and R209 (Ryan, Nov 4 and Nov 11, 2026): broken pieces must never be visibly empty; build the insides (deck levels, bulkheads, frame stations, machinery spaces) so hits, breaks and deaths show structure, lit or burning spaces, never flat caps or a hollow shell.
- R113 (Ryan, Nov 7, 2026): no triangle caps on the station; triangles are reported, and the station is priced in milliseconds on the scene gate like a ship (R116: 12.5 ms, 75 percent of the 16.7 ms frame, gate scene at 1080p median and 4K GPU).
- R151 (Ryan, Nov 9, 2026): parts kits are per faction, never one shared kit; only invisible plumbing (mount sockets, scale rules, LOD and bake pipeline, export) is shared. The station kit is a Hegemony kit.
- R207 and R233: the concept guides; the builder designs. The picture sets identity (mass, silhouette from above, character, palette, where the big features sit); the Opus builder corrects what would not work as a real built object and lists each change on the build sheet. The Board makes the design calls between concept and build.
- R236 (per the issue): game data, the lore bible and the faction guide govern; the concept is a base.
- R217 (build sheets): every part is modelled as the thing it is (a berth collar has depth, a lip, a dark bore; a tower cap is its system, not a box), and the fit check applies: no part inside another, arcs and cones clear.
- Hegemony faction guide (docs/playbooks/factions.md): machined, modular, horizontal; flush panels, straight seams, repeated modules; colours pale grey, steel-blue trim, implant-blue light; never rust, never warm light, no ornament. How Hegemony breaks: in modules, at the bulkhead rings between modules, rims torn and scorched; inside: white corridors, blue emergency light, racks of identical equipment; breach anchors sit on the module joints. Note the live tension: T2's accepted pictures carry a few dull orange battery strips at torn frames, against the faction's never-warm-light line; the pack must state how the build handles that (the chair's expectation: damage-state emergency strips are a state, not the faction's lit language; say it plainly either way).

## Design calls your leg must make (mark them as calls)

1. The slow moving part. Issue 373's done test requires lights and one slow moving part. T1's moving part is the turning ring; T2's ring is seized. What moves slowly on the dead station? (Candidates in the record's spirit: a torn arm segment or debris chunk in a slow tumble, held near the station; a debris piece drifting along the ring track; one surviving mechanism still cycling.) Pick one, say where it sits and how a player reads it at the battle camera.
2. The damage story. Which half is dark, and why? The record gives: ring seized off-angle, one spoke buckled, one arm torn to a stub, about 90 lights left in clusters, battery strips at torn frames, frost and dust on the shadow side. Write the one-paragraph story that makes those facts one event, name which modules still hold power, and keep it consistent with a write-off (nobody repaired it; nobody is aboard).
3. How it breaks in battle. It is a blocker set piece ships fight around. Give its break lines (Hegemony rule: at bulkhead rings and module joints), what comes away, and what the insides show at each break (per R98/R209 and the faction's insides).
4. Fleet or refinery first. Issue 373 asks which station kind comes first. T2 is the fleet station; the refinery is T3, a different plan and kit. State the answer and the reasoning in one short paragraph.

## Pack structure (follow the faction pack format)

Title line, then:
1. The shape of record (what T2 is, from above and at the battle camera; the silhouette that must survive the build)
2. Rulings that bind this build (each ruling, its source, what it forces)
3. Shared build rules (recipe, insides, fit check, gate, as they apply to a station)
4. Lore and kit (who built it, what the Vesper Reach station was for, the Hegemony kit language)
5. Parts inventory (every part the sheet designer must draw: core drums, ring and bearing track, spokes, docking arms and berth collars, towers and caps, radiator banks, lights, debris, the moving part; with counts and the job each part does)
6. How it breaks (break lines, insides, the damage story cross-reference)
7. Must-keep and must-avoid
8. Stale words to ignore (anything in older documents the designer should not follow, if you know of any; otherwise say none known)
9. Open questions for the Board (only genuine Board calls; keep it short)

## Ground rules

- The station carries no weapons. Do not invent any.
- Space, not sea: no hull, no prow, no engine bells; the stack ends in collars and platforms.
- Counts from the accepted concept are the record (9 deck drums, 4 arms, 5 towers, about 650 lights in service, about 90 in T2). Do not quietly change them; flag any you think must change as an open question.
- Everything the designer needs must be in the pack; anything not in the record is either your marked call or an open question.
