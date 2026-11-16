# Leg: Grok (grok.com, default mode; signed in via Continue with Google by Ryan in-browser after the first environment lost the earlier sign-in; Nov 13, 2026, 11:09-11:22 CST)

(Worker note: the answer has no separate fleet-or-refinery-first paragraph.)

Design pack: Vesper Reach station T2 (Voidsworn issue 654)

The shape of record
T2 is the abandoned Hegemony fleet station of the Vesper Reach, the same station as the in-service T1 concept but in its write-off state: damaged and half-dark. From above the silhouette is a core stack of nine cylindrical deck drums, a habitat ring seized at an off-angle with its single open gap segment shifted from the T1 position, four docking arms at crossed angles and two heights (one reduced to a torn stub), and five towers of different heights with distinct caps. Radiator banks sit under the core. At the default battle camera (r 170) the station reads as a single massive set piece roughly twice a cruiser across (about 50 units or more), with torn holes exposing deck frames, debris frozen against arms and ring, frost and dust on the shadow side, and only scattered light clusters. The family resemblance to T1 is carried by the ring, the drum core and the arms; both share one parts kit at build time. The station must read clearly without orange blocker outlines.

Rulings that bind this build
R109 (Ryan, Nov 5, 2026): the station needs far more surface detail than plain geometric shapes; therefore T2 is a fully built set piece, not a repaint.
R206 (Ryan, Nov 11, 2026): T2 is the accepted damaged reference; the build follows the build-sheet gate of R203.
R98 and R209 (Ryan, Nov 4 and Nov 11, 2026): broken pieces must never look empty; every break must show internal structure (deck levels, bulkheads, frame stations, machinery spaces), lit or burning, never flat caps or hollow shells.
R113 (Ryan, Nov 7, 2026): no triangle caps on the station; triangles are reported. The station is priced in milliseconds on the scene gate like a ship (R116: 12.5 ms, 75 percent of the 16.7 ms frame, gate at 1080p median and 4K GPU).
R151 (Ryan, Nov 9, 2026): parts kits are per faction; the station uses a Hegemony kit only. Invisible plumbing (mount sockets, scale rules, LOD and bake pipeline, export) may be shared.
R207 and R233: the concept sets identity (mass, silhouette from above, character, palette, placement of big features); the Opus builder corrects what would not work as a real built object and lists every change on the build sheet. Design calls between concept and build belong to the Board.
R236: game data, the lore bible and the faction guide govern; the concept is a base.
R217: every part is modelled as the thing it is (a berth collar has depth, a lip, a dark bore; a tower cap is its system, not a box). Fit check applies: no part inside another, arcs and cones clear.
Hegemony faction guide: machined, modular, horizontal; flush panels, straight seams, repeated modules; colours pale grey, steel-blue trim, implant-blue light; never rust, never warm light, no ornament. Breaks occur in modules at the bulkhead rings between modules; rims torn and scorched. Inside: white corridors, blue emergency light, racks of identical equipment; breach anchors sit on the module joints. The accepted pictures show a few dull orange battery strips at torn frames; the build treats these as damage-state emergency strips only (a state, not the faction's lit language). They stay dull orange and limited to the torn frames; they do not become general lighting.

Shared build rules
The station is built through the ship recipe once its build sheet passes (issue 373, R203). Size is driven by the hexes it blocks: each blocked cell is currently 14.0 units across (blocker_visuals.gd); the finished station is at least three hexes wide and taller than any ship. SHIP_K is 1.6; a cruiser is 23.2 units long, so the station must read a little over twice that across. All parts obey the fit check (R217). Insides must be built wherever a break can occur (R98/R209). The station carries no weapons. Space language only: the stack ends in collars and platforms, never hull, prow or engine bells. Scene cost is gated like a ship.

Lore and kit
The Vesper Reach station was a Hegemony fleet station: a modular docking and support hub for fleet operations in the Reach. After the write-off it was abandoned; no one repaired it and no one remains aboard. The kit language is pure Hegemony: pale grey structural panels, steel-blue trim, implant-blue light (now reduced to the surviving clusters), flush seams, repeated modular drums and arms. Break language follows the faction rule: modules part at bulkhead rings, rims tear and scorch, interiors show white corridors under blue emergency light with identical equipment racks. The orange battery strips are confined to damage state at torn frames and do not redefine the faction palette.

Parts inventory
All counts are taken from the accepted concept and are fixed unless the Board opens them.
Core stack: 9 deck drums, stacked vertically, each a modular cylinder with bulkhead rings at the joints. Job: primary mass and structural spine; interiors visible at any break.
Habitat ring: one ring on a segmented bearing track that includes one open gap segment. In T2 the ring is seized off-angle and the gap has moved. Job: defines the silhouette from above and carries the family resemblance to T1.
Spokes: the spokes that held the ring; one is buckled. Job: structural link between core and ring; the buckled spoke is the visible failure point.
Docking arms: 4 arms at crossed angles and two heights, each ending in a lit berth collar (depth, lip, dark bore). One arm is torn down to a stub. Job: docking geometry and berth identity; the stub shows the tear line and internal frames.
Towers: 5 towers at five different heights, each with its own distinct cap that is the system it houses (not a box). In T2 the towers are dead; one leans. Job: vertical punctuation and system identity.
Radiator banks: banks under the core, cold. They are the same banks as T1; they must not read as solar arrays. Job: thermal language under the core.
Lights: approximately 90 remaining implant-blue lights in scattered stubborn clusters (down from about 650 in T1). Plus a few dull orange battery strips only at torn frames. Job: the half-dark state and the emergency strips.
Debris: pieces held where they drifted to a stop against the arms and the ring; frost and dust on the shadow side; torn holes that show deck frames inside. Job: the write-off evidence.
Moving part (design call): one large debris chunk (a torn arm segment or equivalent structural plate) held near the station in a very slow tumble. It sits just outside the ring on the shadow side, rotating slowly enough that a player at the default battle camera can read the motion without it competing with ship movement. This satisfies the issue 373 done-test requirement for one slow moving part now that the ring is seized.

How it breaks
Break lines follow Hegemony rule: at the bulkhead rings between modular drums and at the module joints of arms, spokes and towers. What comes away: entire modules or large panels shear at those rings; a buckled spoke or torn arm stub may separate further. What the insides show: white corridor structure, blue emergency light (or the remaining implant-blue clusters), racks of identical equipment, frame stations and machinery spaces; never empty or flat-capped. The damage story (design call) is one coherent write-off event: a single catastrophic failure (exact cause not specified in the record) seized the ring off-angle, buckled one spoke, tore one docking arm to a stub, killed power to most of the station and left only scattered clusters and a few battery strips at the torn frames. Frost and dust settled on the permanently shadowed side. The modules that still hold residual power are those immediately adjacent to the surviving light clusters and the battery-strip frames; everything else is dark. No one repaired it and no one is aboard, so the debris remains exactly where it drifted to a stop.

7. Must-keep and must-avoid
Must-keep: the nine-drum core, the seized off-angle ring with shifted gap, the four arms (one stub), the five towers (one leaning), the cold radiator banks under the core, the approximately 90 light clusters plus limited orange battery strips at torn frames only, the debris frozen against arms and ring, the frost/dust on the shadow side, the torn holes that expose deck frames, the family resemblance to T1 carried by ring/core/arms, and the single slow-tumbling debris piece. Must-avoid: triangle caps, hollow or empty breaks, warm light as faction language, rust, ornament, any weapons, any sea or aircraft language, any change to the listed counts without Board approval, and any reading of the radiator banks as solar arrays.

8. Stale words to ignore
None known. Older station repaint language is superseded by R109 and the acceptance of T2 as a full build.

9. Open questions for the Board
- Exact residual power map: which specific drum modules still hold the surviving clusters (the pack keeps the story at the cluster level).
- Whether the slow-tumbling debris piece needs a unique LODed mesh or can reuse an existing arm/tower fragment.
- Confirmation that the approximately 90 light count and the five-tower / four-arm counts remain locked.
