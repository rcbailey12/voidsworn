# Admiral Portraits V2: Per-Faction Brief (Run 3, R439 + Variety Pass)

**Issue:** #1879 (Owner: Neon, branch `neon/issue-1879`).
**Status:** Updated for Run 3 after Ryan's Nov 23 2026 20:19 UTC review of the Run 2 contact sheet ("the concepts look much better but the pose and backgrounds look the exact same outside of glasswrights? no real variation"). All Run 2 faction concepts and R439 rulings stay locked; every admiral now has a distinct **Pose/Action, Camera Angle & Framing, Ship Place, and Key Light**, and Chorus `mending` explicitly excludes yellow eye-like spots.

## Summary: Why We Started Fresh and What Run 3 Fixes

Ryan's Nov 23 2026 rulings (`contrib/opus/FINDINGS.md`, R438 and R439) established both the faction concepts and the visual bar:
- **Faction concepts landed in Run 2 (keep):** dry heated black-iron Sunward Crusade (zero frost/snow/ice), clean pale-grey cybernetic Meridian Directorate (zero floating face HUD), R64 four-eyed split-jaw Ashfall Hullbreakers, R252 Loom Glasswrights in vaulted pearl-white and silver light chambers (Tamsa with 6 vanes), R439 bodyless transportable Eclipse mind-cores inside dark decks/Archive vaults (zero green), and R439 ship-internal bone-hooped Chorus Node-organ cores (zero metal wrecks, open-space planets, eyes, or space tendrils).
- **Run 3 fix (real per-admiral variation):** Run 2 reused the same straight-on camera, table/rail pose, and identical bulkhead background between faction pairs (`vex`/`ashgrove` and `kassar`/`maren`). Run 3 enforces a hard **No-Clone Rule**: no two admirals in the same faction may share a pose/action, camera angle, framing, or ship compartment, and image generation must NEVER pass another admiral's portrait as an image-to-image layout reference.
- **Run 3 Chorus `mending` fix:** remove all small oblong yellow/amber gland bumps that read as eyes or eyespots; no Chorus portrait may show anything eye-like.

Every lore claim below cites its source file in this repo.

---

## Shared Standard Across All 6 Factions

- **Rendering style (aligned with R197 ship concept tone):** grounded, realistic painterly dark sci-fi concept art with tangible physical surfaces (forged iron, machined alloy, rough hide, translucent silicate flesh, wet veined tissue), dramatic directional light, and soft background depth. No flat cel-shaded comic outlines, no glossy plastic 3D look, and no neon haze. (`docs/playbooks/factions.md` R197; `docs/playbooks/screens.md` section 2.)
- **Format and framing:** 1:1 square (`1024x1024` final), primary subject/head/core focal center placed cleanly so square cards and tight UI crops both read cleanly (`tools/portraits/portrait_specs.py` lines 4-5). Clean full-bleed perimeter with **no painted border or frame**: Godot draws frames and Eclipse's restoration marks in code (`godot/portraits/README.md`, R78 Q17).
- **Hard Per-Admiral Variety Rule (Run 3, Ryan Nov 23 20:19 UTC):** within every faction, each of the 4 admirals MUST have a different (a) pose/action or core silhouette, (b) camera angle and framing distance, (c) compartment/station aboard ship, and (d) key light direction/source. Family cohesion comes from shared faction dress/anatomy, insignia, material stack, and palette, NEVER from cloning a pose or background.
- **Zero UI noise:** no readable letters, numbers, watermarks, or floating holographic text across faces.
- **No cross-faction bleed:** every faction owns its own motifs, materials, and light colours (`contrib/opus/compute/lore_bible_r8.md` 1.3; `contrib/muse/design/faction_packages_2026_11/cross_faction_check.md`).
- **Live names and ids:** admiral ids and display names follow `godot/campaign/data/campaign_tables.json` (`tables.ADMIRALS`, the live Godot source under R405). Older doc aliases are noted in parentheses; no game files are edited.

---

## 1. Sunward Crusade (`voidsworn`)

### 1.1 Who they are (species, body plan, life aboard ship)
- **Species and body plan:** unaugmented frontier humans from the forty-odd dimming systems of the Vesper Reach (`contrib/opus/compute/lore_bible_r8.md` 2.1, 2.5). Zero implants and zero AI (`lore_bible_r8.md` 2.2): defectors and older officers carry plain healed surgical scars at the temple where Hegemony cortical links were cut out (`lore_bible_r8.md` 2.3, 2.5; `contrib/muse/design/faction_packages_2026_11/sunward_crusade.md`). Weathered skin with old healed cold-burn scars from freezing Vesper worlds, oath brands, grey stubble or lined faces, hard tired eyes, and white chalk dust on gloves (`lore_bible_r8.md` 2.5).
- **How a commander fits and works aboard ship:** Sunward warships are symmetric, pressurized, forged black-iron hulls with thick riveted decks, 16 internal frames, manual broadside gun galleries behind armored flank ports, hand-plotted fire-control rooms ("no AI: plotted by hand"), crew dawn-watch berths, a Roll hall where crew names are chalked, torpedo loading bays, carrier flight-control galleries, and a spine-block command deck looking out through narrow ember-lit vision slits (`docs/ship_pipeline/build_sheets/voidsworn_S8/README.md`, `feature_table.md`; `voidsworn_S9`/`S10`/`S11` `feature_table.md`). Tall spine spires radiate intense ember-orange reactor heat through dark iron fin slats (`docs/playbooks/factions.md` R331).
- **Interior climate (approved R439, proposal 3):** dry, cramped, warm-to-hot near gun galleries and reactors, smelling of hot iron, oil, and chalk dust. "Frost-scarred skin" means old healed cold-weather scarring on the face or hands only, never snow, frost, or ice inside a warship.

### 1.2 What ties the 4 admirals together as one family
- **Dress:** heavy matte black-iron-toned void-coat with a high collar, layered dark forged shoulder plates with rivet lines (well-kept, never rusted), practical heavy gloves lightly dusted with white chalk (`lore_bible_r8.md` 2.5; `docs/playbooks/factions.md`).
- **Insignia:** the Crusade crest, a **half sun (upper half white, lower half black) over a broken link** (`lore_bible_r8.md` 2.9), painted in crisp matte frost-white on the left chest or shoulder plate, alongside crisp frost-white rank bars.
- **Shared materials and palette:** matte black iron, dark worked steel, crisp frost-white painted markings and chalk, bright ember-orange interior instrument and gallery light, balanced by subtle cool white deck strips (`docs/playbooks/factions.md`; `godot/fx/faction_looks.json`).

### 1.3 Setting (where the portraits are taken)
- Four distinct dry, heated, riveted black-iron working stations aboard Sunward warships (`voidsworn_S8`/`S10`/`S11` `feature_table.md`): broadside plotting room, bow Cinder torpedo loading bay, Hearth carrier flight-control catwalk, and spine-block command chair.

### 1.4 Must-exclude list
- **No ice, snow, icicles, frozen bulkheads, or frost crystals anywhere** (R438, R439).
- **No rust** (Hullbreakers; `docs/playbooks/factions.md`, `lore_bible_r8.md` 2.5).
- **No cybernetic implants, glowing temple ports, or holographic blue screens** (Meridian Directorate; `lore_bible_r8.md` 2.2).
- **No religious or Warhammer 40k ornament:** no wax seals, parchment purity strips, crosses, statues, stained glass, censer smoke, or cathedral arches (`docs/RULEBOOK.md` 11.2; `lore_bible_r8.md` 1.2, 2.4).
- **No sea-ship props:** no ship wheels, rope, wooden decks, or spyglasses (`docs/playbooks/factions.md`).
- **No shared pose or background between any two Sunward admirals** (Run 3 variety rule).

### 1.5 The 4 Sunward Crusade admirals (distinct pose, camera, compartment, light)
1. **`vex` - Admiral Roderic Vex** (*Line of battle* / *Fire for effect*; `sunward_crusade.md`, `STORY_BEAT3`): Veteran line commander from the manual gun decks who chalks the Roll beside the dorsal airlock before every jump.
   - **Pose/Action:** standing square and solid, chalk-dusted gloved hands planted firmly on a heavy iron plotting rail, leaning slightly forward.
   - **Camera/Framing:** level chest-up front view, centered.
   - **Ship Place:** riveted black-iron broadside plotting room (`voidsworn_S8`), dark bulkhead behind him bearing faint vertical chalk tally marks (the Roll) and narrow ember-lit vision slits.
   - **Light:** warm ember-orange key light rising from the manual plotting table below, cool white overhead deck strip rim.
2. **`malek` - Oath-Captain Torben Hark** (*Hunter-killer* / *Hunter's salvo*; live name in `campaign_tables.json` and `lore_bible_r8.md` 2.10; older draft Malek Draven in `sunward_crusade.md`; `voices.json`, `STORY_BEAT3`): Former Hegemony defector who cut out his own cortical link with a mess knife; torpedo stalker.
   - **Pose/Action:** angled half-crouch beside a loaded Cinder torpedo cradle, one gloved hand running along the forged warhead casing, head turned sharply toward camera so his plain healed temple excision scar (zero metal, zero glow) is clearly visible.
   - **Camera/Framing:** tight three-quarter profile bust, slightly low angle looking down the narrow receding bay.
   - **Ship Place:** cramped bow Cinder torpedo loading bay (`voidsworn_S11`), heavy forged launch tubes and overhead hoist rails in depth.
   - **Light:** hard side-lit deep ember-red arming lamps along the tube bay, deep iron shadow across the far side of his face.
3. **`ashgrove` - Commodore Sera Ashgrove** (*Carrier doctrine* / *Scramble all wings*; `sunward_crusade.md`, `voices.json`, `STORY_BEAT3`): Youngest commodore, deckborn raised in a Hearth carrier hangar, directs wings over wired headset mic.
   - **Pose/Action:** standing turned three-quarter right beside an angled armored gallery stanchion (NO plotting table), one hand raised to her wired headset mic, glancing alertly over her shoulder toward the camera.
   - **Camera/Framing:** slightly high three-quarter waist-up framing, off-center left so the deep hangar opens on the right.
   - **Ship Place:** elevated side catwalk of a Hearth carrier flight-control gallery (`voidsworn_S10`), tall angled armored glass looking down onto warm amber-lit black-iron fighter launch rails below.
   - **Light:** strong warm amber-gold backlight and side-spill from the launch bay floods through the glass, crisp cool-white glint on her headset and forged shoulder plate.
4. **`thale` - High Admiral Oryn Thale** (*Iron doctrine* / *Iron wall*; `sunward_crusade.md` uses she/her; `voices.json`, `STORY_BEAT3`): Oldest living crusader, veteran of three expeditions, pours lukewarm tea from a battered thermos during alerts and chalks her own name on the Roll.
   - **Pose/Action:** seated steadily in a heavy riveted iron command chair, silver hair framed by the iron headrest, one weathered hand holding a battered metal thermos cup resting on the chair arm, calm unhurried gaze straight ahead.
   - **Camera/Framing:** slightly low medium close-up, seated off-center right.
   - **Ship Place:** spine-block command deck of a Daybreak dreadnought (`voidsworn_S8`), insulated reactor heat-plenum pipes and thick armored forward vision slits behind her.
   - **Light:** soft warm ember glow from side status gauges and distant spine slits, steady cool-white overhead lamp catching her silver hair and healed cold-burn scars.

---

## 2. Meridian Directorate (`hegemony`)

### 2.1 Who they are (species, body plan, life aboard ship)
- **Species and body plan:** composed, well-kept, proudly cybernetic core-world humans linked directly to the Registry at Meridian (`lore_bible_r8.md` 3.1, 3.3). Tasteful, flush cybernetics: a neat cortical-link port at the temple with a faint implant-blue indicator, ocular implants with crisp minimal data rings across the iris, and thin metallic subdermal traces along the jaw and hands (`lore_bible_r8.md` 3.3; `contrib/muse/design/faction_packages_2026_11/hegemony_navy.md`).
- **How a commander fits and works aboard ship:** Meridian warships are clean, modular, symmetric pale-grey wedges with white corridors, numbered crew posts, blue light strips, racks of identical equipment, forward ion/deflector capacitor banks, drone hangars between stern rails, and a low, flat, recessed **command deck ("the Registry link room")** tucked directly beneath the low sensor fin (`docs/playbooks/factions.md`; `docs/ship_pipeline/build_sheets/hegemony_H10/README.md`, `feature_table.md`; `hegemony_IM5/feature_table.md`).

### 2.2 What ties the 4 admirals together as one family
- **Dress:** immaculate tailored pale-grey high-collared Directorate uniform tunic with crisp steel-blue shoulder piping, flat machined pale-grey shoulder panels, and fitted dark steel-blue or pale-grey gloves where worn (`lore_bible_r8.md` 3.3; `hegemony_navy.md`).
- **Insignia:** the Directorate crest, a clean **wedge inside a ring of five linked nodes** (`lore_bible_r8.md` 3.8), worn as a flush brushed-steel clasp at the high collar.
- **Cybernetics:** identical Registry hardware family across all four (flush temple cortical-link port with faint blue light, thin subdermal jaw/hand traces, subtle iris readout ring).
- **Shared materials and palette:** pale grey, crisp off-white machined panels, brushed steel blue, cool implant-blue indicator light (`docs/playbooks/factions.md`; `godot/fx/faction_looks.json`).

### 2.3 Setting (where the portraits are taken)
- Four distinct clean, machined modular spaces aboard Meridian warships (`hegemony_H10`/`IM5`/`H7` `feature_table.md`): central Registry link room, dimmed inner sensor-interdiction bay, elevated drone-and-fighter hangar overlook, and forward bow-deflector capacitor corridor.

### 2.4 Must-exclude list
- **No floating neon hologram grids or scribbles pasted over the face** (ocular data lives cleanly inside the iris; fixes old `kassar.webp`).
- **No giant ringed planet or round porthole directly behind the head** (fixes old `kassar.webp`).
- **No warm orange/ember light, rust, dirt, torn cloth, or chalk** (`docs/playbooks/factions.md`, `lore_bible_r8.md` 1.3).
- **No crude bulky cybernetics, exposed wires, or half-robot skull faces** (`lore_bible_r8.md` 3.3).
- **No naval conning towers, yacht decks, brass rails, or Imperial/Star Wars peaked caps** (`docs/playbooks/factions.md`; `lore_bible_r8.md` 3.8).
- **No shared pose or background between any two Meridian admirals** (Run 3 variety rule).

### 2.5 The 4 Meridian Directorate admirals (distinct pose, camera, compartment, light)
1. **`kassar` - First Admiral Ilsa Kassar** (*Fire discipline* / *Synchronized volley*; `hegemony_navy.md`, `voices.json`, `STORY_BEAT3`): Registry's highest-rated formation purist who runs extra timing drills before battle while quietly knowing the model priced Vesper.
   - **Pose/Action:** standing erect with hands clasped neatly behind her back, chin level, calm composed gaze turned slightly toward camera.
   - **Camera/Framing:** clean straight-on formal chest-up view, slightly off-center left.
   - **Ship Place:** central Registry link room (`hegemony_H10`), wide symmetrical pale-grey modular deck with a long horizontal implant-blue fleet-sync strip and blurred linked officers at low consoles.
   - **Light:** even cool clinical off-white overhead architectural light with clean horizontal implant-blue rim bounce from behind.
2. **`vorn` - Commodore Dace Vorn** (*Precision fire* / *Interdiction strike*; `hegemony_navy.md`, `voices.json`, `STORY_BEAT3`): Border listening-post hunter (Post M-14) who clears conservative plots down to one razor intercept.
   - **Pose/Action:** leaning forward on one forearm over a dark glass tactical table, other gloved hand hovering over a single crisp blue intercept line, eyes narrowed behind a flush precision ocular lens on one eye.
   - **Camera/Framing:** slightly high diagonal three-quarter close-up looking across the dark tactical glass.
   - **Ship Place:** dimmed inner sensor-interdiction bay aboard a Cordon destroyer (`hegemony_H7`), narrow vertical pale-grey server racks and dark matte telemetry walls.
   - **Light:** crisp directional implant-blue up-lighting from the recessed tactical glass table against cool shadowed pale-grey panels.
3. **`reyes` - Fleet Marshal Corin Reyes** (*Strike group* / *Launch the strike group*; `hegemony_navy.md`, `voices.json`, `STORY_BEAT3`): Polished broadcast-ready carrier marshal who privately switches off his temple link for the unlogged minute.
   - **Pose/Action:** standing in crisp three-quarter profile looking back calmly over his left shoulder toward the camera, right gloved hand resting subtly near his collar and unlit (switched-off) temple link port.
   - **Camera/Framing:** slightly low medium waist-up three-quarter shot along a receding diagonal glass overlook.
   - **Ship Place:** elevated flight-operations gallery overlooking a Vanguard/Dominion fighter and drone hangar (`hegemony_H10` drone hangar between stern rails), pale-grey geometric ceiling trusses and sleek grey strike craft parked in neat rows below.
   - **Light:** bright cool white hangar bay floodlight streaming from the right glass wall, crisp steel-blue fill shadows, dark unlit temple port.
4. **`maren` - Line Admiral Oskar Maren** (*Armored column* / *Shield wall order*; `hegemony_navy.md`, `voices.json`, `STORY_BEAT3`): Former shield engineer who inspects bow deflector readings himself before strapping in.
   - **Pose/Action:** paused mid-inspection in a reinforced pale-grey armored bridge vest over his uniform, turning his head from a vertical bulkhead deflector gauge while one bare hand (fine subdermal wrist traces visible) grips a machined corridor rail.
   - **Camera/Framing:** tight diagonal three-quarter bust, camera angled down a crisp receding white-and-steel-blue corridor (NO symmetrical bridge room behind him!).
   - **Ship Place:** forward bow-deflector capacitor corridor of a Dominion dreadnought (`hegemony_H10`/`IM5` forward crew deck and capacitor banks), tall vertical pale-grey shield-coil housings and vertical implant-blue conduit strips receding into perspective.
   - **Light:** strong cool steel-blue side light from the vertical deflector capacitor columns on the left, clean neutral white corridor fill from the right.

---

## 3. Ashfall Hullbreakers (`corsair`)

### 3.1 Who they are (species, body plan, life aboard ship)
- **Species and body plan (locked by R64 and Nov 1 rulings):** huge, heavy-gravity alien void hunters from the Ashfall belt (`lore_bible_r8.md` 4.1, 4.3; `contrib/opus/FINDINGS.md` R64; `contrib/muse/design/faction_packages_2026_11/ashfall_hullbreakers.md`). Bear-heavy hunting beast mass: massive shoulder hump, thick forearms, heavy clawed hands. Coarse fur **only as a mane** over the hump, neck, and shoulders (grey, black, or rust-brown); everywhere else, tough dark hide with ridged protective plates running down the back and shoulders (`lore_bible_r8.md` 4.3). **Face:** bare, short, and blunt, armoured in overlapping dull horn plates grown organically from the hide with dark leathery skin in the creases; **no fur on the face, no snout, no nose**. **Jaw:** splits vertically down the middle of the chin into two tooth-lined halves that open sideways. **Eyes:** a horizontal row of **four small eyes** across the brow glinting in the dark, with **heat-sensing pits** beside them (`lore_bible_r8.md` 4.3).
- **How a commander fits and works aboard ship:** Hullbreaker ships are lopsided, heavy-framed scrap vessels welded from scavenged iron and stolen enemy hull plates, built to run cold and dark (`docs/playbooks/factions.md`; `lore_bible_r8.md` 4.3). Ship interiors (`docs/ship_pipeline/build_sheets/corsair_A16/feature_table.md`, `corsair_A17/feature_table.md`) include the aft **Warlord hall** and **bridge** on the Pyre-Barge, the cramped forward **listening room and bridge** behind the wake-sniffer dishes on cruisers/raiders, **boarding kennels**, **loot holds**, and a belly **hangar**.
- **Posture rule (locked Nov 1 ruling, `ashfall_hullbreakers.md` line 3):** species base is low and wide (Knuckle Stalker), and portrait posture is by character with the Warlord always upright: **Grax upright in challenge, Old Mott low and wide, Sable low and skulking, Vesh upright over trophies**.

### 3.2 What ties the 4 admirals together as one family
- **Anatomy:** exact same R64 species blueprint on all four (four small eyes in a brow row, heat pits, blunt bare dull-horn plated face with leather creases, vertically split sideways lower jaw, coarse mane on neck/hump/shoulders only, tough dark hide, ridged back plates, heavy claws).
- **Dress and trophy rule (`FINDINGS.md` R78 Q5; `ashfall_hullbreakers.md` line 3):** heavy dark bolted leather-and-iron void-harness strapped across chest and shoulders bearing **exactly one hero trophy** (a single recognizable salvaged hull plate or hardware piece from another faction, bolted flat).
- **Insignia:** the Hullbreaker crest, a ring of welded scrap teeth around three claw slashes (`lore_bible_r8.md` 4.8; `corsair_A16/README.md`), gouged or welded onto a harness plate or background bulkhead.
- **Shared materials and palette:** matte soot black, dark brick rust, dried-blood red, dark-grey salvaged metal (R274, never chalky white), one faction-coloured trophy accent, dim deep-red running lights and secondary orange work glow (`docs/playbooks/factions.md`, `godot/fx/faction_looks.json`).

### 3.3 Setting (where the portraits are taken)
- Four distinct running-dark working compartments aboard Hullbreaker scrap warships (`corsair_A16`/`A17` `feature_table.md`): aft Warlord hall, pitch-dark forward nose listening bridge, belly scrap-hangar command overlook, and lower-deck loot-hold salvage bench.

### 3.4 Must-exclude list
- **No reptile/dinosaur snout, no two-eyed face, and no single hinged lizard jaw** (fixes old `grax.webp`).
- **No bears, wolves, or human bodybuilder torsos** (`lore_bible_r8.md` 4.3).
- **No film Predator tells:** no dreadlocks/quills/cables on the head, no mandible tusks framing the mouth, no mesh netting, no domed helmet (`lore_bible_r8.md` 4.3).
- **No metal masks, helmets, or riveted metal plates on the face** (living dull horn only; `lore_bible_r8.md` 4.3).
- **No skulls, bones, hanging chains/cages, chalky white patches, weird crystals, or green ork skin** (`lore_bible_r8.md` 4.2, 4.3; `docs/playbooks/factions.md` R185 (3), R197, R274).
- **No shared pose or background between any two Hullbreaker admirals** (Run 3 variety rule).

### 3.5 The 4 Ashfall Hullbreakers admirals (distinct pose, camera, compartment, light)
1. **`grax` - Warlord Grax Ironmaw** (*Fast assault* / *Full burn*; live name in `campaign_tables.json` and `lore_bible_r8.md` 4.9; older draft Grax Steelgrin; `ashfall_hullbreakers.md`, `STORY_BEAT3`): Rattlehold Warlord who held the Pyre-Barge through eleven challenges.
   - **Pose/Action:** upright, hunched-forward dominant challenge stance, slamming one massive clawed hand onto a heavy throttle lever, split jaw parted in a fierce snarl, one scorched steel-blue Hegemony cruiser plate bolted flat on his left shoulder harness.
   - **Camera/Framing:** low-angle monumental chest-up view looking slightly upward at his bristling rust-and-black shoulder hump.
   - **Ship Place:** aft Warlord hall of the Pyre-Barge (`corsair_A16`), heavy riveted soot-black, dark-grey, and dried-blood-red welded bulkheads behind.
   - **Light:** dim deep-red overhead running lamp plus warm red-orange throttle console bounce from below.
2. **`sable` - Sable the Smiling Knife** (*Knife work* / *Knife in the dark*; `ashfall_hullbreakers.md`, `voices.json`, `STORY_BEAT3`): Lone Howler ambush hunter running completely dark, split jaw hanging slightly open when she locks onto an ion trail.
   - **Pose/Action:** low, coiled skulking crouch angled diagonally near the deck, sleek black mane hunched low, head craned forward and tilted slightly to listen, four eyes glinting and split jaw parted in her quiet hunting smile; one matte dark stripped sensor-array housing bolted flat to her harness strap, claws resting silently beside a dimmed console.
   - **Camera/Framing:** slightly high-angle tight three-quarter view looking down across the shadowed listening console, emphasizing her low predatory crouch.
   - **Ship Place:** cramped, pitch-dark forward nose listening bridge of a Pack Hunter cruiser (`corsair_A17` "listening room and bridge in the head"), curved soot-black bulkhead ribs, passive acoustic dish cables, and tiny crimson wake-tracker scope dials.
   - **Light:** ultra-low-key single deep crimson scope glow from the lower left catching her four eyes and split chin out of near-black deck shadow.
3. **`mott` - Old Mott** (*Junkyard carriers* / *Release the swarm*; `ashfall_hullbreakers.md`, `voices.json`, `STORY_BEAT3`): Oldest Hullbreaker alive (outlived forty captains), commands the hulk-carrier and the pack's young from his welded harness chair.
   - **Pose/Action:** low, wide, heavy settled sprawl seated back inside a crude welded-iron command harness chair, deeply chipped horn plates with one clouded eye, heavy forearms resting wide on welded armrests, one battered rival captain's iron chest-plate bolted to his harness.
   - **Camera/Framing:** wide level medium shot anchoring his broad immovable bulk against the deep cavernous hangar behind.
   - **Ship Place:** command overlook above the belly scrap-hangar bay of a hulk-carrier (`corsair_A16` hangar), heavy welded girders and patched scrap fighter hulls below.
   - **Light:** harsh side-lit orange-white welding sparks flaring in the distant hangar to the left, dull deep-red deck lamps on the right.
4. **`vesh` - Vesh the Collector** (*Scrap armor* / *Patch and weld*; `ashfall_hullbreakers.md` uses him; `STORY_BEAT3` uses her; anatomically non-human): Quartermaster-eyed Ripper missing three digits on one hand from stripping a live Chorus wreck.
   - **Pose/Action:** upright three-quarter side stance leaning over a heavy salvage workbench, scarred clawed hand (visibly missing three digits) tilting a pristine violet-black Eclipse alloy panel toward an overhead lamp while the single hero trophy plate gleams on the shoulder harness.
   - **Camera/Framing:** medium side-three-quarter view looking across the salvage bench toward the tall dark-grey-maned hunter.
   - **Ship Place:** lower-deck loot hold and weld bay (`corsair_A16` "loot hold"), stacked salvaged plates from other factions chained flat to soot-black stanchions.
   - **Light:** harsh cool-white overhead inspection work lamp focused onto the salvage bench and hands, contrasting against dim deep-red hold shadows behind.

---

## 4. The Glasswrights (`ithar`)

### 4.1 Who they are (species, body plan, life aboard ship)
- **Species and substance (locked by R252 Loom body law; `contrib/opus/FINDINGS.md` R252; `contrib/muse/design/glasswright_species_2026_11/design.md`; visual canon `docs/shots/portraits/glasswright_species/round_4_loom/loom_sheet.jpg`):**
  - The Starwrights who stayed flesh, living 300 to 400 years (`lore_bible_r8.md` 6.1; `design.md` section 6).
  - Made of **one continuous living silicate tissue (lumen-flesh)** ranging seamlessly from pale, soft, hydrated organic flesh to clear optical glass and opaque died-back silver-white fibre at vane edges (`design.md` section 1). Soft pale green-white **stored light** glows from deep inside the upper chest core; involuntary wavelength shifts act as an emotional blush (amber for grief, cold blue for focus), while they speak normally (`design.md` section 1, Nov 1 ruling).
  - **The Loom body plan (R252):** tall, narrow, vertical thorax held high (~1.5 m off the floor) on **four long, straight, jointed support limbs** with broad ridged foot-pads (`design.md` section 2; `loom_sheet.jpg`). **Four arms** in two pairs: upper longer working arms and lower finer precision arms with wrist spinnerets (`design.md` section 4). **Face (`design.md` section 3; `loom_sheet.jpg` panel 2):** broad slightly flattened skull, **two flush deep-green grown lens-eyes** with slow sliding lids, **heavy segmented translucent brow** (5 to 7 cushions, more in elders), **no nose**, and a **small flush woven-glass reed grille** at the mouth.
  - **Sails/vanes (`design.md` section 5):** layered fan of translucent, silver-edged crystal vanes grown organically from the upper back behind the shoulders, splitting faint rainbow fringes at thin margins.
- **How a commander fits and works aboard ship (approved R439, proposal 4):** Glasswright ships are opaque braided pearl-white ribbons with silver edges and marbled stained-glass mosaic panels of sapphire blue, emerald green, violet, and golden amber (`docs/playbooks/factions.md` R337; `docs/ship_pipeline/build_sheets/ithar_CD5/README.md`). Inside (`ithar_CD5`, `ithar_GA1` `feature_table.md`), tall vaulted pearl-white and silver optical chambers house two shaped glass decks, open annealed frames, three braided light cores, and optical reservoirs built for the tall four-legged Loom carriage (`design.md` section 7). Zero metal console buttons.

### 4.2 What ties the 4 admirals together as one family
- **Anatomy:** strict R252 Loom body plan (`loom_sheet.jpg`) across all four. Individual variation lives in age/fusion depth, glow warmth, and individual vane count/geometry (`design.md` section 6).
- **Dress and insignia:** minimal open-weave glass-thread lattice apron hanging from the waist carrying the woven pale green-white **cracked-lens crest** (`lore_bible_r8.md` 6.8; `design.md` section 7).
- **Shared materials and palette:** opaque pearl white, silver filigree, translucent pale green-white lumen-flesh, deep green lens-eyes, stained-mosaic accents in golden amber, sapphire blue, emerald green, and violet (`docs/playbooks/factions.md` R337; `design.md`).

### 4.3 Setting (where the portraits are taken)
- Four distinct vaulted pearl-white and silver optical chambers aboard Glasswright ships (`ithar_CD5`/`GA1`/`GP1`): Aperture carrier hangar, forward Prism-lance waveguide gallery, faceted mirror-alignment hall, and central braided light-reservoir vault.

### 4.4 Must-exclude list
- **No dark metal spaceship bridges, rubber keyboards, or blinking plastic console buttons** (R439; fixes old `aelith.webp` and `loom_sheet.jpg` panel 4).
- **No bipedal human bodies, human noses/lips, elf ears, grey-alien black eyes, faceless gem heads, or squat spider posture** (`design.md` sections 2-3; R252).
- **No heavy cloth robes covering sails or chest, no metal armor, no crystal shards bolted onto skin, and no insect chitin** (`design.md` sections 5, 7; `docs/playbooks/factions.md`).
- **No shared pose or background between any two Glasswright admirals** (Run 3 variety rule).

### 4.5 The 4 Glasswrights admirals (distinct pose, camera, compartment, light)
1. **`aelith` - Tamsa of the Clear Aperture** (*Wing-mistress* / *Starling flight*; `the_glasswrights.md`, `design.md` section 6, `STORY_BEAT3`): Youngest admiral (90), raised in Ringing Field salvage crews, carrier commander.
   - **Pose/Action:** standing tall turned slightly right with **exactly 6 clean tight-jointed clear vanes** (locked R439, proposal 5) fanned wide, upper right working arm raised gracefully to trace a launch vector while her other three slender arms poise naturally over her woven apron.
   - **Camera/Framing:** slightly low medium-wide three-quarter shot (head to upper hips/apron), off-center left so a launching starling cradle opens across the right.
   - **Ship Place:** tall vaulted opaque pearl-white and silver Aperture carrier hangar (`ithar_GA1`), slender translucent starling craft suspended in graceful silver cradles along both flanks, sapphire and emerald stained-mosaic ribs.
   - **Light:** bright cool white-blue hangar aperture light pouring from high behind-right, catching sharp rainbow edges along her 6 vanes.
2. **`vaelen` - Saro of Long Focus** (*Focused lances* / *Burning glass*; `the_glasswrights.md`, `design.md` section 6, `STORY_BEAT3`): Oldest admiral, 60 years on the Astra watch, patient lance master.
   - **Pose/Action:** dead-still forward concentration with **exactly 4 vanes** (2 very long narrow razor-ground primaries + 2 short lower secondaries, frosted at tips with age), heavy 7-8 segment brow drawn inward over deepest forest-green eyes, all four arms drawn inward as his lower precision fingers hold and calibrate a small suspended focusing lens splitting a crisp thin white-and-rainbow beam.
   - **Camera/Framing:** tight symmetrical level medium close-up focused on frosted brow, deep-green eyes, chest core, and lens-aligning hands.
   - **Ship Place:** narrow vaulted forward Prism-lance waveguide gallery (`ithar_CD5`), braided glowing light-core conduits curving overhead and deep violet/golden-amber stained-mosaic side panels.
   - **Light:** sharp bright white-and-rainbow focal beam lighting his hands and chin from the front, soft violet-amber mosaic glow from the flanking ribs.
3. **`thorne` - Vell of the Third Mirror** (*Refraction tactics* / *Scatter the light*; `the_glasswrights.md`, `design.md` section 6, `STORY_BEAT3`): Duellist and hand-polishing mirror-smith, leads with her left.
   - **Pose/Action:** turned sharply three-quarter left looking back over her shoulder, **5 asymmetric vanes** (larger port primary carrying a broad opaque died-back silver mirror face), one upper hand angling a tall vertical silvered mirror rib beside her, chipped-and-regrown brow segment and warmer amber emotional glow beneath her skin.
   - **Camera/Framing:** dynamic diagonal three-quarter shot off-center right, showing a crisp partial reflection of her asymmetric vanes in an angled mirror plane on the left.
   - **Ship Place:** faceted mirror-alignment gallery aboard a Prism cruiser (`ithar_GP1`), tall angled pearl-framed reflection panels and warm golden-amber/emerald mosaic light slits.
   - **Light:** hard raking directional white light bouncing off the mirror face across her left side, warm amber internal lumen-flesh glow.
4. **`mirelle` - Brin of the Fourth Lens** (*Prism hulls* / *Prism ward*; `the_glasswrights.md`, `design.md` section 6, `voices.json`, `STORY_BEAT3`; pronoun open in `design.md`): Defensive shield warden protecting every surviving crew.
   - **Pose/Action:** broad, steady, sheltering upright stance turned slightly left, **6 wide concave cupped vanes** (heaviest silver lattice and richest rainbow fringe) spread calmly outward, upper working hands resting gently on a curved pearl-and-silver rail around a glowing light reservoir.
   - **Camera/Framing:** slightly high serene medium-wide shot highlighting the broad protective arc of the 6 silver-cupped vanes.
   - **Ship Place:** deep central braided light-reservoir chamber (`ithar_CD5`), thick vertical glowing columns of stored pale-green light braided inside smooth pearl glass hoops beneath sapphire/emerald mosaic vaults.
   - **Light:** soft enveloping pale green-white stored-light wash rising gently from the central reservoir columns.

---

## 5. Eclipse (`deathless`)

### 5.1 Who they are (species, form, life aboard ship)
- **Species and nature:** Starwrights who uploaded their minds into machines a thousand years ago, killing Ardent (`lore_bible_r8.md` 7.1). Billions of **separate individual minds** backed up in one shared Archive ("Each mind stays its own; the Archive holds copies, not a merged self"; `lore_bible_r8.md` 7.4). They count the casings/frames they have worn ("This is my ninth frame"; `lore_bible_r8.md` 7.2, `voices.json`).
- **Locked rulings:**
  - **No real bodies and no faces (R439, Nov 23 2026; Nov 1 ruling in `eclipse.md`):** Eclipse admirals have NO humanoid, bipedal, or Starwright-shaped bodies, limbs, heads, or faces. Each Eclipse admiral is a **unique, transportable mind-core housed inside its ship**, each a **different size and shape**, engineered with docking clamps, collars, or rails so it can be detached and moved between ships or Archive vaults if needed.
  - **All violet-black and white-gold, ZERO green:** Nov 20 2026 ruling (`docs/playbooks/factions.md`, issue 1419; `godot/fx/faction_looks.json` issue 1503) removed all green from Eclipse.
- **How an admiral core physically fits and works aboard ship (`deathless_E11` to `E14`):** Eclipse warships have **three internal decks**, **octagonal crew/drone access hatches**, **archive vaults**, weapons capacitor banks, fold-drive spar dark decks, and **trapped-light core ports** (`deathless_E11` to `E14` `feature_table.md`, `inventory.md`). Every admiral portrait shows that admiral's unique core physically clamped inside its specific shipboard housing cradle.

### 5.2 What ties the 4 admirals together as one family
- **Material grammar:** identical precision dark violet-black layered sunshade plates, dead-even recessed panel seams, pale-violet worn bevel edges, zero rust, zero soot (`docs/playbooks/factions.md` R243; `deathless_E11/README.md`).
- **Core architecture:** every admiral is an un-bodied, faceless **transportable shipboard mind-core** seated in an Eclipse housing cradle, combining layered violet-black sunshade shielding, a clean violet-white or white-gold optical/corona light feature, and physical docking clamps or transfer rails.
- **Insignia:** the Eclipse crest, an **eclipsed sun** (black disc inside a thin white-gold ring; `lore_bible_r8.md` 7.8), etched faintly in pale violet-gold or projected dimly in the vault.
- **Light and framing:** clean dark outer margins so Godot's R78 Q17 restoration frame overlay (`godot/portraits/README.md`) never collides with key details. Illumination comes strictly from the core's own white-gold slit/corona seams and faint violet-white deck light.

### 5.3 Setting (where the portraits are taken)
- Four distinct unlit dark-deck core housings aboard Eclipse ships (`deathless_E11` to `E14` `feature_table.md`): spacious Archive vault transfer cradle, towering corona-arc capacitor bay, cramped narrow fold-spar dark corridor, and wide armored bow-sunshade transfer sled bay.

### 5.4 Must-exclude list
- **No bodies, heads, limbs, shoulders, torsos, or humanoid armor** (R439: "no real bodies").
- **No abstract room-filling vortex tunnels or giant space portals** that cannot sit inside a ship or be transported (R438, old `nekhet.webp`).
- **No green glow anywhere** (Nov 20 2026 issue 1419 / 1503).
- **No faces, eyes, mouths, skulls, ribs, bones, Necron/Egyptian ornaments, flame, rust, or smoke** (`lore_bible_r8.md` 7.2; `docs/playbooks/factions.md`).
- **No two Eclipse cores sharing the same size, shape, housing, or camera angle** (R439 + Run 3 variety rule).

### 5.5 The 4 Eclipse admirals (distinct size, shape, camera, housing, light)
1. **`nekhet` - Nadir Aurex, Ninth Frame** (*Endless restoration* / *Release the repair swarms*; `eclipse.md`, `voices.json`, `STORY_BEAT3`): Oldest continuously restored admiral (ninth casing), quietly deleting memories from his backup.
   - **Core Size & Shape:** **large, monumental annular broken-ring mind-core** built from concentric segmented curved violet-black sunshade ring-plates around a recessed violet-white/white-gold inner core; one upper-right ring segment stands slightly parted as two tiny cold-white repair drones reseat its bevel, base gripped by heavy three-arm magnetic transport clamps.
   - **Camera/Framing:** low-angle heroic three-quarter view looking slightly up at the tall ring-core in its cradle.
   - **Ship Housing / Place:** spacious unlit Archive vault (`deathless_E11`), tall dark vertical mind-storage monoliths with tiny white-gold status ticks, dark octagonal hatch, faint white-gold eclipsed-sun memory projection in the gloom behind.
   - **Light:** bright central violet-white-to-white-gold core glow and crisp thin violet corona lines along the ring bevels.
2. **`sekhmar` - Umbra Vessane, Third-Housed** (*Corona strikes* / *Noon volley*; `eclipse.md`, `voices.json`, `STORY_BEAT3`): Original Ardent array engineer housed in a tall heavy-ordnance core, secretly tracking Vesper's dimming light.
   - **Core Size & Shape:** **tall, heavy vertical hexagonal-column siege core** flanked by twin swept curved dorsal capacitor fins echoing Null cannon mounts (`deathless_E11`), locked between heavy top-and-bottom lifting collars with a vertical slit-shuttered violet-white energy core down its center.
   - **Camera/Framing:** steep upward diagonal shot along the towering vertical column, off-center left so its swept capacitor fins arch across the upper right.
   - **Ship Housing / Place:** high-voltage corona-arc capacitor bay (`deathless_E11` capacitor bank behind projector), stacked circular capacitor discs and thick dark conduits framing the vertical mount.
   - **Light:** intense cold violet-white slit light spilling across stepped matte alloy collars, thin horizontal white-gold siphon telemetry trace in the rear shadow.
3. **`anuket` - Ostrel of the Long Copy** (*Silent hunters* / *Out of the shadow*; `eclipse.md`, `voices.json`, `STORY_BEAT3`): Deep-recon scout mind copied so often from copies that even other Eclipse find Ostrel unnervingly silent; trims every stray emission.
   - **Core Size & Shape:** **small, compact, narrow horizontal/canted stealth prism-spindle core** (dramatically smaller and more portable than Aurex's monumental ring, chest-sized so a single drone pair can unlatch and carry it fast), wrapped in overlapping matte angled light-baffle sunshade plates with integrated machined transport handles and quick-release lock pins.
   - **Camera/Framing:** tight high-angle diagonal close-up looking slightly down along the small faceted prism-core clamped inside a slim deck-rail cradle, emphasizing its compact portable scale against surrounding conduits.
   - **Ship Housing / Place:** tight, cramped, completely unlit fold-drive spar corridor aboard an Eclipse scout (`deathless_E13`/`E14` "dark decks along the spar"), close curved dark violet-black bulkhead ribs, dark octagonal maintenance hatch receding behind, hexagonal floor grate below.
   - **Light:** extreme stealth chiaroscuro: near-total matte darkness broken only by one whisper-thin white-gold optical slit along an upper bevel and faintest cold violet light bleeding up from the distant floor grate.
4. **`khepra` - Seveth, Twice-Restored** (*Layered plates* / *Sunshade wall*; `eclipse.md`, `voices.json`, `STORY_BEAT3`): Restored twice after "educational" deaths, personally keeps every ship's restore list, defensive sunshade warden.
   - **Core Size & Shape:** **broad, squat, heavily armoured layered-sunshade bastion core** (wide and low, opposite of Vessane's tall column and Ostrel's compact spindle), wrapped in thick overlapping tiered crescent violet-black shield slabs carrying two crisp pale-violet precision repair-weld seams, bolted down onto a heavy railed deck transfer sled.
   - **Camera/Framing:** level side-three-quarter wide shot capturing its low, wide, bunker-like defensive mass seated on its transfer sled.
   - **Ship Housing / Place:** armored forward command-core bay behind sunshade bulkheads (`deathless_E11`/`E12`), thick layered blast ribs and a tall calm pale white-gold restore-list column beside the sled.
   - **Light:** calm steady white-gold column light grazing across the broad curved dark violet-black shield slabs and illuminating the two precision repair-weld seams.

---

## 6. The Chorus (`chorus`)

### 6.1 Who they are (species, form, life aboard ship)
- **Species and nature:** NOT a people and NOT bipedal officers (`lore_bible_r8.md` 5.1, 5.3; `contrib/muse/design/faction_packages_2026_11/the_chorus.md`). A living bio-weapon grown by the Fleshwrights around H-3 Crucible to destroy Eclipse; it consumed its makers and became one hungry swarm speaking as "we" with two internal throats: **Hunger** and **Memory** (`lore_bible_r8.md` 5.1, 5.2).
- **Anatomy (`lore_bible_r8.md` 5.3; `docs/playbooks/factions.md` R349; `the_chorus.md`):** grown organisms with **no face, no eyes, and no limbs**: glistening wet lumpy olive-brown hide with deep folds, pores, and dark red veins, overlapping ochre-bone/horn armadillo chitin ridges, satin membranes (roughness ~0.6, never plastic gloss), dark fleshy-lipped recessed throat bores, and dim bile yellow-green internal light rising ONLY from deep inside bores or chamber floors.
- **Unique hero rule (locked Nov 1 ruling, `the_chorus.md` line 3; `FINDINGS.md` R78 Q14; R439 proposal 6):** parallel to Eclipse, each Chorus admiral is a **unique ship-internal living Node-organ core** of a different size, shape, and chamber, rooted directly inside its living flagship's bone-hooped interior cavity (`chorus_C10` to `C14` `feature_table.md`: `ganglion | the Node: the knot of nerve that steers the body (no bridge)`).

### 6.2 What ties the 4 admirals together as one family
- **Biological material grammar:** all four share the exact Chorus surface stack (`docs/playbooks/factions.md` R349): muddy dark olive-brown wrinkled/folded hide with dark red surface veins and pores, pale ochre-horn chitin ridges and structural bone hoops, real deep dark recessed throat/pore openings with puckered fleshy lips, and dim bile yellow-green internal glow emerging only from deep inside cavities or under thin stretched nursery membranes.
- **Architectural framing:** all four are framed in situ inside living bone-hooped organic ship cavities (no bridges, no metal, no open space).
- **Crest echo:** the Chorus crest (a ring of nine open mouths; `lore_bible_r8.md` 5.8) is echoed organically in Matriarch's nine puckered throats, never painted as a symbol.

### 6.3 Setting (where the portraits are taken)
- Four distinct internal organ cavities aboard living Chorus ships (`chorus_C10` to `C14` `feature_table.md`): cavernous brood-sac Node chamber, tight forward prow ram-muscle cavity, wide ruptured regrowth fissure chamber, and tall suspended upper acoustic resonator vault.

### 6.4 Must-exclude list
- **No eyes, no eyespots, and no round/oblong yellow or amber glowing gland bumps that look like eyes** (Run 3 fix on `mending`; `lore_bible_r8.md` 5.3; `docs/playbooks/factions.md` R349).
- **No faces, no human teeth, no limbs or hands, and no loose waving space-tentacles/boarding-tendril limbs** (R437).
- **No metal anywhere:** no human shipwreck bulkheads, bolts, girders, pipes, or sunlit holes (`docs/playbooks/factions.md`).
- **No open-space planets or comic smoke clouds.**
- **No cartoon thread stitches, grub segments, red/magenta flesh, or Tyranid/Zerg armored bugs** (`lore_bible_r8.md` 5.2; `docs/playbooks/factions.md`).
- **No two Chorus cores sharing the same silhouette, cavity layout, or camera angle** (R439 + Run 3 variety rule).

### 6.5 The 4 Chorus admirals (distinct size, shape, cavity, camera, light)
1. **`matriarch` - The Matriarch of Nine Throats** (*Brood swarm* / *Spawning surge*; `the_chorus.md`, `voices.json`, `STORY_BEAT3`): Oldest commanding growth, nine throats fused around a shard of the original Fleshwright vats.
   - **Organ Size & Shape:** **tall, towering vertical central column-organ** rooted into the floor and ribs, crowned by nine uneven thick-lipped deep dark recessed brood throats venting faint misty spore haze above swollen dimly bile-lit lower nursery folds.
   - **Camera/Framing:** low-angle monumental shot looking upward at the towering nine-throated crown.
   - **Ship Cavity / Place:** vast cavernous brood-sac Node chamber (`chorus_C14`), wide arching pale-ochre structural bone hoops and dark-veined olive membrane walls.
   - **Light:** dim misty bile yellow-green luminescence rising from deep inside the lower translucent nursery folds, deep cool shadows across the nine dark throat rims.
2. **`razormaw` - Red Undertow** (*Hunter pack* / *Blood frenzy*; live name in `campaign_tables.json` and `lore_bible_r8.md` 5.3; older draft Razormaw in `the_chorus.md`; `voices.json`, `STORY_BEAT3`): Forward bladeback assault growth driving the first bite, scarred with calcified enemy hull splinters.
   - **Organ Size & Shape:** **sleek, low, forward-wedged armoured assault ganglion** fused into heavy knotted ram-muscle, sheathed in overlapping jagged ochre-horn chitin plates scarred with dark calcified ridges around a single split dark forward sphincter-maw.
   - **Camera/Framing:** aggressive tight low-diagonal front-three-quarter shot looking down a narrow muscular cavity, emphasizing forward charging momentum.
   - **Ship Cavity / Place:** tight forward prow ram-muscle cavity of a Bladeback cruiser (`chorus_C11` "ram muscle under the bone crests"), thick ridged dark-red venous muscle bundles and jagged forward bone crests.
   - **Light:** deep hot internal amber-bile glow pulsing far back inside the split dark sphincter-maw, sharp grazing highlights along the wet scarred ochre chitin plates.
3. **`mending` - Mending Throng** (*Regrowth* / *Regrowth tide*; `the_chorus.md`, `voices.json`, `STORY_BEAT3`): Vast, slow growth of interwoven repair flesh knitting torn chitin and sealing ruptured chambers.
   - **Organ Size & Shape:** **wide, sprawling horizontal bridge-like webbing organ** built purely of broad overlapping braided bands of pale-olive muscular repair flesh and freshly calcifying jagged ochre bone-splints actively spanning a ruptured dark-veined fissure (**strictly ZERO round or oblong yellow/amber bumps or eye-like spots**).
   - **Camera/Framing:** slightly high diagonal three-quarter shot looking across the wide living seam bridging a deep organic chasm (NO symmetrical circular tunnel border).
   - **Ship Cavity / Place:** asymmetrical split regrowth chamber (`chorus_C10`/`C13` "regrowth tissue"), torn dark-olive membrane walls being pulled shut above a deep glowing pool of pale yellow-green regeneration fluid below.
   - **Light:** soft pale yellow-green bioluminescent bounce rising strictly from the regeneration pool deep beneath the fissure, leaving the upper braided olive muscle and ochre bone splints completely free of glowing dots or eye-like spots.
4. **`voice` - Voice of the Deep** (*Acid tide* / *Spitting volley*; `the_chorus.md`, `voices.json`, `STORY_BEAT3`): Far-travelling acoustic throat grown in the dark between stars where dead Fleshwright signals echo beneath pressurized acid chambers.
   - **Organ Size & Shape:** **suspended, hollow, bell-like ribbed acoustic chamber-organ** hanging vertically from upper ochre bone arches by taut dark-veined ligaments, formed of concentric thin pleated olive-brown resonance membranes encircling one deep cavernous dark central throat bore (ZERO yellow spots).
   - **Camera/Framing:** dramatic off-center upward/side three-quarter shot looking into the suspended hanging acoustic cavity from below-left.
   - **Ship Cavity / Place:** deep hollow upper resonator vault beside dark-veined bile stores (`chorus_C12`/`C13`), long vertical bone ribs and taut drum-like olive septa receding into wet shadow.
   - **Light:** faint eerie pale-bile glow rising from far down inside the single central dark throat bore, grazing the translucent pleated resonance membranes.

---

## 7. Test Set Plan (Run 3: All 12 Varied Portraits)

Every pair tests **shared faction family identity** alongside **maximum per-admiral variation in pose/shape, camera angle, compartment, and lighting**:

| Faction | Pick 1 | Pick 2 | Variation contrast tested |
|---|---|---|---|
| Sunward Crusade (`voidsworn`) | `vex` | `ashgrove` | Square-on level plotting room (ember uplight) vs high three-quarter carrier flight-control catwalk over fighter bays (amber backlight, headset mic, NO plotting table). |
| Meridian Directorate (`hegemony`) | `kassar` | `maren` | Straight-on formal central Registry link room (even white light) vs tight diagonal bow-deflector capacitor corridor mid-inspection (vest, bare hand on rail, vertical blue side light). |
| Ashfall Hullbreakers (`corsair`) | `grax` | `sable` | Low-angle upright Warlord hall challenge at throttle vs high-angle crouched stealth skulk in a pitch-dark nose listening bridge under crimson scope light. |
| The Glasswrights (`ithar`) | `aelith` (Tamsa) | `vaelen` (Saro) | Slightly low three-quarter Aperture hangar with 6 clean vanes and launch gesture vs tight symmetrical waveguide gallery with 4 frosted vanes and lens-aligning beam. |
| Eclipse (`deathless`) | `nekhet` (Aurex) | `anuket` (Ostrel) | Low-angle large monumental broken-ring core in Archive vault cradle vs tight high-angle small portable stealth prism-spindle core in narrow dark-deck fold spar corridor. |
| The Chorus (`chorus`) | `matriarch` | `mending` | Low-angle towering vertical nine-throated brood column vs slightly high diagonal sprawling horizontal braided repair-flesh chasm bridge (zero yellow eye-like spots). |

---

## 8. Decided Rulings (R439 + Run 3 Variety Ruling, Nov 23 2026)

All 6 proposals from Run 1 were decided by Ryan on Nov 23 2026 19:59 UTC (R439), plus the Run 3 variation ruling at 20:19 UTC:

1. **Eclipse admiral form and scale (DECIDED, R439):** no real bodies; each Eclipse admiral is a unique transportable mind-core housed inside its ship, each a different size and shape. Aurex's broken ring is reworked to fit a core in a transfer cradle, not a body.
2. **Eclipse Starwright body proportions (REJECTED, R439):** dropped. No real bodies, limbs, heads, or humanoid chassis.
3. **Sunward interior climate (APPROVED, R439):** dry heated black iron; zero ice, snow, or frost anywhere inside ships or on coats.
4. **Glasswright ship interiors (APPROVED, R439):** tall vaulted pearl-white and silver light chambers with suspended mirrors, braided light-core conduits, and marbled mosaic light (`ithar_CD5`, `factions.md` R337).
5. **Tamsa's vane count (DECIDED, R439):** **6 vanes**.
6. **Chorus admirals as ship-internal Node-organ cores (APPROVED, R439 + Run 3):** parallel to Eclipse; each Chorus admiral is a unique Node-organ core rooted inside its flagship's bone-hooped organic cavity (`chorus_C10` to `C14`), with zero metal wrecks, zero open-space planets, zero eyes/eyespots/yellow eye-like gland spots, and zero space-tendrils (R437).
7. **Per-admiral variety rule (DECIDED, Run 3 Nov 23 20:19 UTC):** no two admirals of a faction may share a pose, camera angle, framing, or ship background.

**Minor lore-doc vs live-data notes (no game files touched):**
- `malek` is **Oath-Captain Torben Hark** in live `godot/campaign/data/campaign_tables.json` and `lore_bible_r8.md` 2.10 (`sunward_crusade.md` still says Malek Draven).
- `grax` is **Warlord Grax Ironmaw** in live `campaign_tables.json` and `lore_bible_r8.md` 4.9 (`rename_map_final.md` had Grax Steelgrin).
- `razormaw` is **Red Undertow** in live `campaign_tables.json` and `lore_bible_r8.md` 5.3 (`the_chorus.md` still says Razormaw).
- `thale` (Oryn Thale) uses she/her in `sunward_crusade.md` (`voices.json` is neutral); `vesh` uses him in `ashfall_hullbreakers.md` and her in `STORY_BEAT3`; `mirelle` (Brin) has no ruled pronoun in `design.md`.
