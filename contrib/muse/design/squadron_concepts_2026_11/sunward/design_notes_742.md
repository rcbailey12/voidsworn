# Sunward squadron concepts (issue 742): Ember Dart fighter and Pyre-Lance bomber

Refs #708. Per-faction own fighter and bomber models (R253). Two directions each, in the S8 language and the realistic Scrap Brick style (R197). Pictures: SF1.jpg, SF2.jpg (Ember Dart), SB1.jpg, SB2.jpg (Pyre-Lance), silhouette_check.jpg. All pictures 1080 x 720.

## The data each craft carries (R241: exactly these weapons, nothing decorative)

- Ember Dart (fighter wing, 4 craft): Interceptor guns (the 'guns' slot, 3 shots), hp 18, speed 6. Length 3.2 units, about 25 px long at the 1080p battle camera.
- Pyre-Lance (bomber wing, 4 craft): Bomb payload (the 'bombs' slot, 2 shots, pierce .6), hp 28, speed 5. Length 4.2 units, about 32 px at the battle camera.
- Faction language (factions.md, issue 70 spec): matte hammered black iron #4a4440, trim #c8501f, frost-white #f0f4f8 chalked oath stripes, ember-orange #ff7a2a for viewports, engines and radiator glow only. Radiators shed reactor heat; they are never steeples, crosses or statues. Engines dim like banked coals at rest. No rust (the red-brown in the renders is the painted trim and grime; Sunward plate is maintained iron, and the build sheet should keep weathering off the hull colour).

## SF1: Spire Dart (fighter direction 1)

The converged spec shape, and the chair's pick. A narrow forward-tapering iron dart, clipped delta winglets at the rear third, two small swept tail fins, one tall dorsal radiator spire behind the cockpit with ember-orange glow slats up its inner edge, and a single deep-bell nozzle.

Weapon callouts (everything pictured that is a weapon):
- Three short gun muzzles in a compact nose cluster (one upper centre, two lower flanking): the Interceptor guns, all three shots of the slot in one cluster. Nothing else on the craft is a weapon; the first render carried thin spikes on the wingtips and they were removed for exactly this reason.

## SF2: Aft-Wide Spearhead (fighter direction 2)

The wider, lower alternative. Short beak nose, hull widening early to a broad stern third, big clipped delta winglets set far aft, and two short dorsal radiator blades in a shallow vee with the ember glow in the gap (no tall spire). Frost-white oath chevrons on the nose.

Weapon callouts:
- One gun port in the chin under the nose and one in each winglet root (the dark pods under the wing roots): the Interceptor guns, three ports for three shots.
- Production note: the chin port rendered as a large round ring at the nose tip, which reads close to an intake. On the build sheet it should shrink to a flush port matching the wing-root pair.

## SB1: Cradle Lance (bomber direction 1)

The converged spec shape, and the chair's pick. A heavy iron wedge with a broad blunt prow, widest at the stern third, a split vee-tail radiator assembly (two tall angled blades, ember-orange inner faces), twin deep-bell nozzles, and frost-white oath stripes across the prow and spine.

Weapon callouts:
- Two underslung cradles under the forward hull, each holding one fat bomb with a trim band: the Bomb payload, one bomb per cradle, matching the 2-shot read. No guns anywhere on the craft.
- Production note: the cradles hang on visible struts, lower than the spec's tight underslung fit; the build sheet can pull them up against the hull.

## SB2: Hammer Anvil (bomber direction 2)

The heavier, squarer alternative. Blunt hammer prow with a frost-white chalked block marking, a deep central keel with a ventral grille, stub wings, a low dorsal radiator block behind the cockpit, broad vee-tail radiator plates, and wide-set twin bells.

Weapon callouts:
- Two open bays, one in each flank at the wing root, each holding one fat bomb with a trim band: the Bomb payload, two bombs total. No guns anywhere.
- The chair moved the bays from the blind leg's centreline sled to the flanks during generation; the keel stays clear for the level bomb run's look from the battle camera. Flagged here so the Board can send them back to the centreline if it prefers.

## Silhouette check at 32 px wide (silhouette_check.jpg)

Each picture's craft was cut out, shrunk to 32 px wide and thresholded to a pure silhouette; the sheet shows them at native size (top row, labelled) and at 10x nearest-neighbour zoom (bottom row), in the order SF1, SF2, SB1, SB2.

- SF1 reads: a long dart with one dorsal spike. Fighter, fast, unmistakable.
- SF2 reads: a broad low delta, clearly a different and heavier fighter than SF1.
- SB1 reads: a blunt heavy body, vee-tail up, and the two cradle bombs still visible as separate masses under the hull. The payload reads at battle scale, which is the point of the design.
- SB2 is the weakest of the four: it reads as a big blunt mass, distinct from SB1 by the prow block, but its flank bays merge into the hull at 32 px and the bombs do not read. If Ryan picks SB2, the build sheet should drop the bays lower or open them wider.

## Chair's picks

SF1 and SB1, the converged shapes. All three seated legs (blind Rey, DeepSeek, Flash) picked the same pair independently, and both survive the 32 px check with their weapons legible. SF2 and SB2 are real second directions if Ryan wants the wider fighter and the heavier bomber instead; they are not filler.

## Council record

Blind Rey leg first (directions: Spire Dart, Blade Wing, Cradle Lance, Forge Sled). DeepSeek (DeepThink on, Search on, the project's design-leg setting, verified before and after): converged dart and aft-wide spearhead; cradle lance and hammer-prow anvil; picks SF1 and SB1; its three-muzzle nose cluster was adopted into the SF1 render brief. Flash (Gemini "Quick answers 3.5 Flash-Lite", verified selected before and after): Spear-Dart and Chiseled Blade; Heavy Anvil and Forged Wedge; picks SF1 and SB1. Qwen: seat empty, the Qwen3.8-Max daily limit was reached earlier in the evening; no substitution. Grok: seat empty, bot wall at grok.com, the twenty-seventh consecutive empty seat. The chair composited the four render briefs from the legs: SF2 takes DeepSeek's twin-blade aft-wide spearhead (the blind leg's forked nose was dropped, it was the weakest read at 32 px), SB2 takes DeepSeek's hammer-prow anvil mass with the blind leg's open visible bays (Flash's internal flush bays were dropped, hidden bombs fail the weapon-visibility point of the exercise).
