# Blind Rey leg: station detail pass (Issue #172, R94)

Written blind, from the issue brief only, before reading the earlier station
research, the FINDINGS rows, station_kit.py, the faction look pack, or any
other leg. Anything about the current station set that I could not see is
marked INFERRED. Chair: screen this like any other leg.

## The core problem, as the brief states it

Ryan approved the station shapes (R94) with one note: from the battle camera
(about 170 units out, looking down) they read as fairly flat frames. The
detail pass has to add height and asymmetry seen from above, plus a close
zoom detail language, without breaking the triangle and frame budget next
to 20 ships.

Flat from above is a specific failure with specific causes. A top-down
camera kills any detail that lives on vertical faces, any detail smaller
than a few pixels at 170 units, and any silhouette that is radially
symmetric, because a symmetric disc or ring reads the same from every
angle and the eye files it as a flat icon. The fixes that survive a
top-down camera are:

1. Vertical relief the camera can parallax against. Stacked levels at
   different heights, so orbiting or panning the camera makes layers slide
   against each other. One tall element beats five medium ones: a single
   spire, tower or raised hub at 25 to 40 percent of the station radius in
   height gives the whole structure a readable up direction.
2. A broken outline. At least one element must cross the outer silhouette
   line off-axis: a docking arm that extends past the ring on one side, a
   radiator wing on one side only, a secondary hub offset from centre.
   Perfect radial symmetry is the enemy; roughly 70 percent symmetry with
   one strong break reads as designed, not messy.
3. Height contrast between neighbours. Adjacent modules should differ in
   height by at least a third, so the top faces form a stepped skyline
   rather than one flat roof plane. Flat roof planes are what make a
   station read as a frame or a plate.
4. Top-face detail, not side-face detail. Panel lines, hatches, markings
   and emissive strips belong on the upward faces for the battle camera;
   side detail is a close zoom luxury and should be budgeted second.
5. Cast shadows. Height only reads if the lighting throws shadows from the
   tall elements onto the lower decks. The detail pass should place tall
   elements where the battle light rakes across broad lower surfaces.

## Silhouette and height rules per station type (INFERRED station set)

The brief names review sheets for a fleet station and a refinery. I infer
the working set is a small number of large stations, likely a dock or
shipyard, a refinery or industrial station, a defensive or fortress
station, and possibly a habitat or trade hub. Rules below are written per
type so the chair can map them onto the real set.

- Dock / shipyard: the frame is the product, so make the frame three
  dimensional. Two parallel berths at different heights, one gantry tower
  taller than the berth plane, construction arms hanging below the plane
  as well as above it (the camera looks down, but a below-plane element
  shows at the silhouette edge and in shadow). A docked ship is the best
  height cue there is; one berth should read occupied in silhouette.
- Refinery / industrial: vertical tanks and stacks are natural height.
  Cluster three to five cylinders of clearly different heights off-centre,
  pipe runs that climb between levels instead of lying flat, one flare or
  vent stack tallest of all. Radiator panels angled like a fan on one side
  only.
- Fortress / defence station: a raised central keep or turret crown, gun
  decks stepped like a ziggurat, one sensor mast. Symmetry is more
  acceptable here (military order) but the keep must sit off the geometric
  centre or carry one taller quadrant.
- Habitat / trade hub: a ring reads flattest of all, so break it: one arc
  segment raised, a hub spire, docking fingers of unequal length, and
  dense window light on the top face of the ring so the ring reads as
  inhabited surface, not a torus primitive.

## Close zoom detail language

At close zoom the station has to reward the look. Detail in priority
order, cheapest and most readable first:

1. Emissive windows and light strips, clustered, not evenly sprinkled.
   Clusters say inhabited zones; even sprinkles say texture noise. A few
   windows should flicker or vary in warmth (INFERRED as a shader or
   emissive map variation, no per-window cost).
2. Blinking navigation and docking guide lights, slow, few colours.
3. Panel lines and hull markings on top faces: faction sigil or station
   number large enough to read at mid zoom, wear concentrated at docking
   edges and traffic lanes.
4. Radiators: dark red to orange emissive panels, angled, grouped near
   industrial and power modules. Radiators are the easiest way to make a
   station look like it is working.
5. Antenna arrays and sensor dishes: thin, tall, clustered on one mast
   area. Cheap in triangles, huge in silhouette value.
6. Docking arms with end lights and, at the largest stations, moving
   traffic: a shuttle or tug on a slow loop path sells scale better than
   any greeble. One or two movers per station, no more.
7. Life signs: venting vapour puffs at intervals, a lit hangar mouth,
   blinking work lights near construction or repair bays.
8. Greebles last and grouped: boxes, pipes and tanks in clusters with
   clear gaps between clusters. Even greeble coverage is what makes kit
   models look like toys.

## Per faction flavour (INFERRED from faction identities)

- Hegemony Navy: order and symmetry kept, asymmetry comes from one
  command spire and parade-straight docking arms. White and navy paint,
  gold trim, everything aligned to a grid.
- Ashfall Hullbreakers: asymmetry is free here. Welded-on modules, mixed
  heights everywhere, salvaged panels in mismatched paint, exposed pipe
  runs, one berth that is clearly a captured hull bolted in place.
- The Chorus: organic growth breaks the frame. Bulbs and membranes at
  uneven heights, no straight silhouette anywhere, bioluminescent clusters
  instead of window grids, growths colonising one side more than the
  other.
- The Glasswrights: height through stacked transparent prisms and lens
  towers; silhouette from refraction edges and bright rims, not mass.
  Keep top faces mostly clear glass with light caustic accents
  (INFERRED: cheap emissive edge strips if real refraction is costly).
- Eclipse: dark hull, low profile except one trapped-light core tower;
  detail reads as sparse cold lights and one bright core, silhouette
  mostly negative space. Asymmetry from the core sitting off-centre.
- Sunward Crusade: cathedral verticality. Tallest spires of any faction,
  gothic arches on the top faces, gold and bone white, a shrine spire as
  the single tallest element on any station in the game.

## Paint and material stack (blind proposal)

Reuse the ship paint stack rather than inventing a station stack: baked
mask procedural materials, faction trim colour, decals for markings.
Stations are static and few, so they can afford one larger texture set
each. Emissive windows and lights should be a separate emissive mask so
day and battle lighting can ride on it. Wear maps heavier than ships:
stations are old. (The chair must check this against R96 Q1, which I have
not read blind.)

## Breakable by design (blind proposal, check against R98)

Stations should be segmented at build time into named modules (hub, ring
segments, arms, towers, tank clusters) with break lines at the joints
between modules, never through a module. Each module gets capped interior
faces and a dark interior material, same rule as the ships: a broken
station piece must never show a hollow shell. Towers and arms are the
natural break-off pieces; the hub should be the last thing standing.
Segment count small (six to ten per station) so draw calls and physics
stay trivial.

## Budget (blind proposal, check against the ship ceilings)

Ships are the budget drivers: 20 ships at the stage 5 ceiling dominate
the frame. Stations are one or two per battle and mostly static, so a
fair cap is: all stations on screen together no more than about 15 to 20
percent of the ship triangle total, draw calls per station under about
40 with merged static geometry, and no per-frame cost beyond traffic
movers and blinking lights (both shader or single-script cheap). Detail
that only shows at close zoom should sit in a second LOD or a
close-range group that the battle camera distance disables. (Numbers are
my blind proposal, not sourced; the chair must reconcile with R96.)

## Reference stations (from memory, sources for the chair to verify)

- The Citadel, Mass Effect: a ring plus arms that reads from any angle
  because the arms are unequal in use and the central tower stacks.
- Deep Space Nine, Star Trek: three pylons curved up and down past the
  ring plane; the silhouette is unmistakable from above because the
  pylons break the disc.
- Babylon 5: a long cylinder with a rotating section and forward docking
  structures; length plus rotation gives parallax a disc never has.
- Homeworld shipyards and the mothership: vertical slab massing, height
  as identity.
- EVE Online stations and Sins of a Solar Empire starbases: game readable
  at strategy zoom, faction silhouette first, greebles second.
- Elite Dangerous Coriolis stations: a rotating polyhedron; proof that
  one strong geometric idea beats surface detail at distance.

## Step list for the Codex detail job (blind draft)

1. For each station, block out the height pass in greybox first: add or
   raise the tall element, offset one module, step the roof levels.
   Screenshot from the battle camera before any detail work.
2. Break the silhouette: one element crossing the outline per station.
3. Top-face pass: panel lines, markings, emissive clusters on upward
   faces.
4. Close zoom pass: radiators, antenna farm, docking arm detail,
   greeble clusters.
5. Life pass: nav light blinks, one traffic mover, vent puffs where
   cheap.
6. Segmentation pass: name modules, set break lines at joints, cap
   interiors.
7. Budget check: triangle count, draw calls and a 20-ship frame test
   with all stations present, screenshots at battle camera and close
   zoom for Ryan.

## Owner questions I would raise (blind)

1. Is the station set fixed at the R94 shapes, or can the detail pass
   move a module (not just add height)? My pick: allow moves that keep
   the approved footprint.
2. How many stations share a battle screen at once, worst case? My pick:
   budget for two large plus one small.
3. Should traffic movers be in scope for this pass or a later life pass?
   My pick: one mover per large station now, it sells scale cheaply.
4. Do stations need faction variants of each type, or one neutral build
   repainted per faction? My pick: one build, faction detail kits differ.
5. Is a destroyed station state in scope (broken modules after battle
   damage)? My pick: segmentation now, destruction states later.

End of blind leg.
