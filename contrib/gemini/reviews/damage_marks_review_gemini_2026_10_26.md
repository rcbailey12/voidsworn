# Damage marks review, Gemini (Argon) leg (brief muse_2026-10-26c, Job 3)

Model: Gemini 4 Argon, Thinking level High ("Argon High" verified in the picker button and the prompt bar dropdown before submitting), fresh chat "Space Fleet Damage Rendering Review", Oct 26, 2026. Both pack files attached via Upload files (leg prompt and evidence pack). Filed verbatim below with a chair header only; the model's source links are mostly community and store pages, so treat its game claims as lead-grade and its per-mark entries as the design judgement it labels them.

---

1. Research Findings: Hull Damage in Reference Games

Voidsworn requires readable per-weapon hull damage across up to 20 ships on screen at tactical camera distance in Godot for PC. Ships use hull sections that can be temporarily disabled by critical hits, and the damage state must be readable on the hull itself rather than only in UI bars. The reference games below show how existing space and mech tactics games handle the trade-off between physical detail and fleet-scale readability.

Homeworld 3

Technique and sources: Blackbird Interactive implemented persistent battle scars that remain on ship hulls from mission to mission ([https://store.steampowered.com/app/1840080/Homeworld_3/](https://store.steampowered.com/app/1840080/Homeworld_3/), [https://cogconnected.com/review/homeworld-3-review/](https://cogconnected.com/review/homeworld-3-review/)). Weapon impacts and unit damage were detailed in Blackbird Interactive's February 2023 Fig and Reddit developer update on weapons and unit damage ([https://www.reddit.com/r/homeworld/comments/1133kgd/fig_update_weapons_and_unit_damage_in_homeworld_3/](https://www.reddit.com/r/homeworld/comments/1133kgd/fig_update_weapons_and_unit_damage_in_homeworld_3/)). The exact shader graph breakdown for how Homeworld 3 blends decal projections with underlying hull material layers is not publicly documented in a developer talk (UNSURE).

Visual and screenshot description: At medium-close camera distance on a Hiigaran Battlecruiser or Destroyer ([https://store.steampowered.com/app/1840080/Homeworld_3/](https://store.steampowered.com/app/1840080/Homeworld_3/)), ion cannon beams carve long, straight trenches across the grey-blue hull plating. The fresh trench has a bright white-orange molten core bordered by ragged black char covering roughly 10 to 15 percent of the struck hull face ([https://store.steampowered.com/app/1840080/Homeworld_3/](https://store.steampowered.com/app/1840080/Homeworld_3/)) (judgement on exact percentage coverage). Ballistic cannon bursts leave tight clusters of dark grey divots with orange-red hot centers that cool to matte soot. At full tactical zoom-out, individual bullet divots disappear into dark smudges, while only the long ion trenches and large blackened hull patches remain distinct (judgement).

Sins of a Solar Empire 2

Technique and sources: Ironclad Games and Stardock built Sins of a Solar Empire 2 to showcase cinematic capital-ship spectacle at fleet scale, documenting individual turret meshes, simulated projectile geometry, and combat geometry in their official developer journals ([https://forums.stardock.net/515013/sins-ii-dev-journal-2-exploring-the-kol-class-battleship](https://forums.stardock.net/515013/sins-ii-dev-journal-2-exploring-the-kol-class-battleship), [https://wiki.sinsofasolarempire2.com/space/SSEFW/2592473108/Sins+II+Dev+Journal:+Combat+Geometry+Part+Two+-+Missiles+and+Point+Defense](https://wiki.sinsofasolarempire2.com/space/SSEFW/2592473108/Sins+II+Dev+Journal:+Combat+Geometry+Part+Two+-+Missiles+and+Point+Defense)). While a developer noted plans on the Steam forums to write a dedicated dev blog on the damage system ([https://steamcommunity.com/app/1575940?l=turkish](https://steamcommunity.com/app/1575940?l=turkish)), a public technical post detailing the exact hull damage shader pipeline could not be verified (UNSURE).

Visual and screenshot description: At fleet camera distance showing 15 to 30 ships around a gravity well ([https://forums.stardock.net/515013/sins-ii-dev-journal-2-exploring-the-kol-class-battleship](https://forums.stardock.net/515013/sins-ii-dev-journal-2-exploring-the-kol-class-battleship)), a TEC Kol-class Battleship takes beam and missile hits across its broad dorsal armor plates. Hull damage reads primarily through high-contrast orange-red emissive cracks, localized fire plumes, and darkened scorch zones covering 20 to 40 percent of a damaged section (judgement). At fleet scale, surface decals alone are secondary to bright shield-hit ripples and glowing orange hull fissures that contrast against the cool grey-blue TEC hull paint (judgement).

Battlefleet Gothic: Armada 2

Technique and sources: Tindalos Interactive built the game in Unreal Engine 4, combining subsystem critical hits, fires, prow ramming, and Tyranid bio-ship spore/boarding mechanics ([https://steamcommunity.com/app/573100/discussions/0/5312592307015019287/?ctp=7](https://steamcommunity.com/app/573100/discussions/0/5312592307015019287/?ctp=7), [https://www.reddit.com/r/BFGArmada/comments/apdfw2/biomass_and_you_how_to_play_and_fight_tyranids/](https://www.reddit.com/r/BFGArmada/comments/apdfw2/biomass_and_you_how_to_play_and_fight_tyranids/)). No public GDC talk or technical blog by Tindalos Interactive on their hull decal or shader mask setup could be located (UNSURE).

Visual and screenshot description: At tactical table distance, Imperial Navy cruisers have ornate gold and gothic ribbed broadsides where flat surface decals break up over heavy 3D greebles (judgement). Tindalos solves this by tying readability to large-scale volumetric and emissive states: when a cruiser takes 500 to 800 hull damage from torpedoes and a prow ram ([https://steamcommunity.com/app/573100/discussions/0/5312592307015019287/?ctp=7](https://steamcommunity.com/app/573100/discussions/0/5312592307015019287/?ctp=7)), large chunks of the dorsal cathedral structure blacken, orange fires burn along deck trenches covering 15 to 25 percent of the hull length, and shattered debris trails behind the ship (judgement).

Starsector

Technique and sources: Fractal Softworks tracks localized armor on a 2D cell grid overlaying each ship sprite, where a hit affects the impact cell plus surrounding cells in a weighted 5x5 grid ([https://fractalsoftworks.com/forum/index.php?topic=12268.0](https://fractalsoftworks.com/forum/index.php?topic=12268.0)). As armor cells deplete and hull HP drops, the engine stamps overlapping burn, crack, and hole damage decals onto the 2D ship sprite ([https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90](https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90)).

Visual and screenshot description: Viewed from Starsector's top-down tactical camera ([https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90](https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90)), an Onslaught or Eagle cruiser hit by Heavy Velocity Drivers (kinetic punctures) and Maulers (high-explosive shells) develops dark ragged cavities exposing a dark-grey interior lattice beneath painted armor plates. However, community documentation on the official forum notes a classic readability failure mode: when a ship takes heavy sustained fire, overlapping burn, crack, and hole decals turn the entire sprite into "shredded metal cheese," obscuring the underlying hull art and weapon mounts ([https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90](https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90)).

BattleTech (Harebrained Schemes) and MechWarrior Online / MechWarrior 5

Technique and sources: Harebrained Schemes' BattleTech divides each unit into discrete armor and structure sections (head, center torso, left/right torso, arms, legs) ([https://steamcommunity.com/sharedfiles/filedetails/?id=1938439954](https://steamcommunity.com/sharedfiles/filedetails/?id=1938439954)). It shares mechanical and visual lineage with Piranha Games' MechWarrior Online and MechWarrior 5, which use per-component damage masks and an emissive thermal "mech glow" shader on struck armor ([https://www.reddit.com/r/OutreachHPG/comments/483p7c/mwo_used_to_look_so_much_better/](https://www.reddit.com/r/OutreachHPG/comments/483p7c/mwo_used_to_look_so_much_better/), [https://steamcommunity.com/app/342200/discussions/0/135508489637774052/](https://steamcommunity.com/app/342200/discussions/0/135508489637774052/)).

Visual and screenshot description: At tactical turn-based camera distance in BattleTech ([https://steamcommunity.com/sharedfiles/filedetails/?id=1938439954](https://steamcommunity.com/sharedfiles/filedetails/?id=1938439954)), a mediumlaser burst rakes a continuous bright orange-yellow melt line across a mech's torso, while an AC/20 impact punches a single concentrated dark crater ([https://steamcommunity.com/sharedfiles/filedetails/?id=1938439954](https://steamcommunity.com/sharedfiles/filedetails/?id=1938439954)). When a section's armor is stripped to internal structure, the entire limb or torso swaps or blends its surface appearance to dark, unpainted skeletal metal with trailing black smoke plumes, and destroyed limbs detach completely ([https://steamcommunity.com/sharedfiles/filedetails/?id=1938439954](https://steamcommunity.com/sharedfiles/filedetails/?id=1938439954)). In MechWarrior Online, early builds had laser damage glow that stayed super-bright for several seconds, which players noted was visually striking but could become blinding if over-tuned ([https://www.reddit.com/r/OutreachHPG/comments/483p7c/mwo_used_to_look_so_much_better/](https://www.reddit.com/r/OutreachHPG/comments/483p7c/mwo_used_to_look_so_much_better/)).

Children of a Dead Earth

Technique and sources: Developer Qswitched documented the physical armor simulation in detail on the official development blog ([https://childrenofadeadearth.wordpress.com/tag/damage/](https://childrenofadeadearth.wordpress.com/tag/damage/), [https://childrenofadeadearth.wordpress.com/2016/07/02/the-photon-lance/](https://childrenofadeadearth.wordpress.com/2016/07/02/the-photon-lance/)). The engine models hypervelocity projectile spalling, Whipple shield plasma shocking, and laser melt/sublimation ablation across multi-layered armor cylinders ([https://childrenofadeadearth.wordpress.com/tag/damage/](https://childrenofadeadearth.wordpress.com/tag/damage/), [https://coade.fandom.com/wiki/Armor](https://coade.fandom.com/wiki/Armor)).

Visual and screenshot description: On a close-up inspection view of a cylindrical spacecraft hull ([https://medium.com/our-space/the-true-physics-of-space-battles-571926ecf1e2](https://medium.com/our-space/the-true-physics-of-space-battles-571926ecf1e2)), railgun and coilgun barrages punch sharp, pinpoint black holes through outer Whipple shields and leave ragged spall craters on bulk armor ([https://childrenofadeadearth.wordpress.com/tag/warfare/](https://childrenofadeadearth.wordpress.com/tag/warfare/)). Continuous laser beams paint narrow, wandering black-and-white ablation tracks across rotating hull cylinders as the beam waist wanders ([https://childrenofadeadearth.wordpress.com/2016/07/02/the-photon-lance/](https://childrenofadeadearth.wordpress.com/2016/07/02/the-photon-lance/)). At tactical orbital camera distance, however, ships are tiny icons and hull marks are completely invisible ([https://medium.com/our-space/the-true-physics-of-space-battles-571926ecf1e2](https://medium.com/our-space/the-true-physics-of-space-battles-571926ecf1e2)), proving that physically accurate millimeter-scale punctures cannot be used at fleet scale without exaggeration (judgement).

Additional Reference: Nebulous: Fleet Command

Technique and sources: Eridanus Industries' tactical space game Nebulous: Fleet Command is the closest technical benchmark for section-based 3D fleet damage ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082), [https://steamcommunity.com/app/887570/allnews/](https://steamcommunity.com/app/887570/allnews/)). Modding documentation and patch notes confirm that ships use an "Armor Damage Base" texture (a burned hull overlay), a runtime "Armor Mask" texture populated by hits, parallax occlusion mapping for crater depth, and a model-space (triplanar/3D) damage mapping system that eliminates ugly UV seam cutoffs when large damage marks cross hull plates ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082), [https://steamcommunity.com/app/887570/allnews/](https://steamcommunity.com/app/887570/allnews/)).

Visual and screenshot description: At tactical fleet camera distance ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082)), smooth, uninterrupted hull slabs on a cruiser display high-contrast black-and-orange circular blast masks from heavy cannon shells (covering 5 to 10 percent of a hull segment per volley) and deep parallax holes from railgun sabots. Bridge lights also change colour or shut off to indicate power loss ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082)).

2. Per-Mark Reference Entries

In Voidsworn, marks must read clearly on a hull section when 20 ships are visible on the board. In a turn-based game, "fresh" means during the attack resolution and the remainder of that turn, "cooling" means 1 to 2 turns after impact, and "scarred" means 3+ turns later or once the section is heavily damaged (judgement).

1. Lance: Burn-Through

Weapons: Lance array (dmg 20, pierce .6), pulsar lance, doom arc (dmg 40).

Tactical camera look: A long, straight, continuous gash slicing across 20 to 35 percent of a hull section's length, with a bright white-yellow core and a narrow, high-contrast black char border (judgement). For high-pierce hits, a small exit bloom appears on the opposite hull face (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: Incandescent white-cyan or white-orange line (2x to 3x HDR bloom) with liquid metal droplets ejecting from the end of the cut (judgement).

Cooling: Glow drops to dull cherry-red segments broken up by cooling black slag bridges along the trench (judgement).

Scarred: A deep, dark-grey linear cleft with a glossy obsidian rim that catches specular light when the ship turns (judgement).

Accumulation behaviour: Multiple lance hits on the same section should cross-hatch like tally marks rather than merging into a round blob (judgement). Cap visible distinct slashes at 3 per hull section; further lance hits widen the existing slashes (judgement).

Strongest source: Homeworld 3 ion cannon trenches across capital hulls ([https://store.steampowered.com/app/1840080/Homeworld_3/](https://store.steampowered.com/app/1840080/Homeworld_3/)) and Children of a Dead Earth laser ablation tracks ([https://childrenofadeadearth.wordpress.com/2016/07/02/the-photon-lance/](https://childrenofadeadearth.wordpress.com/2016/07/02/the-photon-lance/)).

2. Plasma: Splash Craters

Weapons: Hegemony laser and turbolaser battery weapons with the plasma trait.

Tactical camera look: An irregular, liquid-splatter footprint (like a thrown bucket of paint) covering 8 to 12 percent of a hull section, with a Dish-shaped melted center and 3 to 5 asymmetrical splash droplets trailing in the direction of fire (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: Vivid green-white or magenta-orange (matching Hegemony plasma colour) molten pool that bubbles and sheds slow, glowing plasma globules into space (judgement).

Cooling: The outer splash droplets solidify into dark metallic crusts first, while the shallow basin center pulses with a dim orange-amber thermal glow (judgement).

Scarred: A smooth, warped, vitrified saucer depression with rainbow heat-tint rings (blue/purple/bronze) around the melted rim (judgement).

Accumulation behaviour: Overlapping plasma splashes should merge their outer metaball thresholds into a larger slagged puddle rather than stacking sharp circular edges (judgement).

Strongest source: MechWarrior Online and MechWarrior 5 thermal damage glow shaders ([https://www.reddit.com/r/OutreachHPG/comments/483p7c/mwo_used_to_look_so_much_better/](https://www.reddit.com/r/OutreachHPG/comments/483p7c/mwo_used_to_look_so_much_better/)).

3. Gauss: Punctures

Weapons: Gauss flayer (pierce .6), gauss sentries (flak kind).

Tactical camera look: Because a realistic railgun hole is invisible at fleet scale, exaggerate the mark into a sharp, high-contrast black keyhole surrounded by a bright silver-white petaled rim of peeled metal, plus a wider exit crater on the far side of the section (judgement). Covers 4 to 6 percent of a section per volley, arranged in a tight 2-to-3 shot stitched line (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: A pinpoint white-hot ring around a pitch-black interior hole, accompanied by a straight cone of fast-moving silver spall fragments bursting outward from both entry and exit points (judgement).

Cooling: The white-hot ring fades within seconds to bright, bare, unpainted silver steel that contrasts sharply with painted hull armor (judgement).

Scarred: A permanent pitch-black parallax hole with a bright, jagged silver collar and a faint trail of frozen white atmosphere venting from deep inside the hull (judgement).

Accumulation behaviour: Repeated gauss hits on one section should cluster into a perforated sieve pattern without merging the black holes together, keeping the distinct "punched sheet metal" texture (judgement).

Strongest source: Children of a Dead Earth hypervelocity projectile entry/exit spalling ([https://childrenofadeadearth.wordpress.com/tag/damage/](https://childrenofadeadearth.wordpress.com/tag/damage/)) and Nebulous: Fleet Command parallax occlusion railgun holes ([https://steamcommunity.com/app/887570/allnews/](https://steamcommunity.com/app/887570/allnews/)).

4. Torpedo: Blast Craters

Weapons: Torpedo salvo (dmg 42), heavy torpedoes, star torpedo, Voidsworn hellfire torpedoes.

Tactical camera look: The largest single-hit mark in the game: a deep, jagged concavity covering 20 to 30 percent of a hull section, breaking the outer silhouette edge if it hits near a hull ridge, and exposing an internal grid of bent girders (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: Roaring orange-yellow internal fire (or white-blue fusion fire for star torpedoes) illuminating exposed structural ribs, with thick black smoke or venting fuel plumes and spinning hull plates (judgement).

Cooling: Open flames die down to smoldering red-orange embers deep inside the exposed ribcage, framed by a wide, jagged collar of matte-black soot (judgement).

Scarred: A gaping dark structural cavity with bent dark-grey I-beams and occasional intermittent electrical sparks (judgement).

Accumulation behaviour: A hull section should hold at most 1 to 2 major torpedo craters; a second torpedo hit in the same section expands the exposed internal structure mesh rather than stamping a second overlapping decal (judgement).

Strongest source: Nebulous: Fleet Command model-space heavy blast masks ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082)) and Battlefleet Gothic: Armada 2 torpedo broadside cavities ([https://steamcommunity.com/app/573100/discussions/0/5312592307015019287/?ctp=7](https://steamcommunity.com/app/573100/discussions/0/5312592307015019287/?ctp=7)).

5. Flak: Pockmarks

Weapons: Flak battery, spore mines, gauss sentries.

Tactical camera look: A broad, peppered stipple pattern covering 25 to 40 percent of a hull section's surface, reading as a rough, sandblasted change in surface roughness and value rather than a single crater (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: A cloud of tiny yellow-white micro-flashes just above the hull skin that immediately leaves a patch of bright, scratched bare-metal speckles (judgement).

Cooling: The micro-flashes vanish instantly; the stippled zone dulls to a rough, matte light-grey scuff patch that strips off faction paint and decals (judgement).

Scarred: A permanent, high-roughness "scoured paint" texture patch with zero emissive glow, clearly distinct from deep structural damage (judgement).

Accumulation behaviour: Implemented as a single roughness/albedo blend mask per section rather than individual decals; more flak hits simply increase the opacity and area of the scoured paint layer so it never causes decal clutter (judgement).

Strongest source: Children of a Dead Earth Whipple shield fragmentation scouring ([https://childrenofadeadearth.wordpress.com/tag/warfare/](https://childrenofadeadearth.wordpress.com/tag/warfare/)).

6. Bio Weapons: Acid Pitting

Weapons: Boarding tendrils (bio, range 1, pierce .5), bio-plasma, spore mines, spore burst.

Tactical camera look: Organic, spongy, honeycomb corrosion patches covering 15 to 25 percent of a hull section, defined by toxic chartreuse-green or bile-yellow colour that no mechanical weapon uses (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: Bright bioluminescent green-yellow foam eating outward in fractal rings, venting thin wisps of greenish-yellow corrosive vapor (judgement).

Cooling: The bright foam subsides into weeping, viscous green-amber veins trapped inside irregular, dissolved pits in the armor plate (judgement).

Scarred: Rusty, hollowed-out,swiss-cheese necrotic metal with a dull olive-brown crust and faint bioluminescent spores clinging to plate seams (judgement).

Accumulation behaviour: Adjacent acid patches merge via an organic cellular (Voronoi) noise mask, expanding outward across armor seams as if digesting the hull section (judgement).

Strongest source: Battlefleet Gothic: Armada 2 Tyranid bio-fleet spore and biomass corruption visuals ([https://www.reddit.com/r/BFGArmada/comments/apdfw2/biomass_and_you_how_to_play_and_fight_tyranids/](https://www.reddit.com/r/BFGArmada/comments/apdfw2/biomass_and_you_how_to_play_and_fight_tyranids/)).

7. Ion: Burns

Weapons: Ion cannon (kind lance, dmg 12, ion 2.5 shield-strip property).

Tactical camera look: A branching, fractal Lichtenberg lightning figure covering 15 to 30 percent of a hull section, with zero physical crater depth so it reads as electrical overload rather than armor hull loss (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: Brilliant electric cyan-violet arcs snapping between turrets, antennas, and panel seams, while nearby ship windows and running lights flicker and go dark (judgement).

Cooling: The continuous lightning breaks into sporadic blue-white micro-arcs jumping across blackened, feathery fractal scorch lines (judgement).

Scarred: A flat, feathery purple-black carbonized dendritic trace along panel lines, paired with darkened interior window lights on that hull section until repaired (judgement).

Accumulation behaviour: Subsequent ion hits reuse and brighten the same conductive panel-line pathways rather than stamping new overlapping lightning decals (judgement).

Strongest source: Starsector EMP arc disabling effects on weapon mounts and engines ([https://starsector.fandom.com/wiki/Starsector_0.96a](https://starsector.fandom.com/wiki/Starsector_0.96a)) and Nebulous: Fleet Command bridge light power-loss indicators ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082)).

8. Ram: Crumple

Action: Ship-to-ship ramming movement action affecting both hulls.

Tactical camera look: A wide, directional structural deformation covering 25 to 40 percent of the struck section, featuring buckled plates, accordion-folded ribs, and scrape streaks painted in the enemy ship's hull colour (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: Orange friction-heat streaks along long parallel gouges, accompanied by large detached armor plates tumbling away and white atmosphere venting from popped seams (judgement).

Cooling: Friction heat fades quickly, leaving bright bare-metal scrape grooves and buckled, uplifted armor edges that catch directional light (judgement).

Scarred: Permanent vertex-displaced (or strong normal-mapped) dented geometry with torn hull plating and a matte dark-grey structural crease (judgement).

Accumulation behaviour: Applied once per section via vertex displacement along the impact normal plus a directional scrape mask; multiple rams deepen the vertex crease up to a clamped maximum so the mesh never turns inside out (judgement).

Strongest source: Battlefleet Gothic: Armada 2 prow ramming exchanges ([https://steamcommunity.com/app/573100/discussions/0/5312592307015019287/?ctp=7](https://steamcommunity.com/app/573100/discussions/0/5312592307015019287/?ctp=7)).

9. Boarding: Breaches

Action / Weapons: Close-range boarding capture action and boarding tendrils.

Tactical camera look: A deliberate, geometric entry wound (4 to 8 percent of a section) shaped like a ring of cutting-charge torches or a clamped bio-tendril sphincter, distinct from chaotic explosive craters (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: A bright orange ring of thermite cutting sparks (or pulsing fleshy tendrils) around a blown hatch, followed by rapid staccato white-and-red muzzle-flash strobes flickering from inside the dark breach to show crew fighting (judgement).

Cooling: While boarding combat continues or resolves, internal strobe flashes slow down and a steady plume of grey-white atmosphere vents from the open airlock breach (judgement).

Scarred: Once the boarding action ends, a neat polygonal or circular dark opening remains, surrounded by severed clamping hooks or shriveled tendril stubs and a golden-yellow emergency bulkhead forcefield or blast shutter sealing the hole (judgement).

Accumulation behaviour: Clamped to 1 to 2 breach points per hull section located at predefined hardpoint/hatch sockets so breaches always align sensibly with ship architecture (judgement).

Strongest source: Battlefleet Gothic: Armada 2 boarding pod and Tyranid tendril assaults ([https://www.reddit.com/r/BFGArmada/comments/apdfw2/biomass_and_you_how_to_play_and_fight_tyranids/](https://www.reddit.com/r/BFGArmada/comments/apdfw2/biomass_and_you_how_to_play_and_fight_tyranids/)).

10. Battery Fire: Lighter Generic Mark

Weapons: Autocannon, macro battery, heavy macro battery, turret, laser cannon, turbolaser, heavy turbolaser, scatter cannons, shuriken cannon.

Tactical camera look: Because batteries are the most common weapons in Voidsworn, they must leave low-noise "attrition clusters" (small groups of 3 to 5 shallow dark-grey divots for kinetic batteries, or short 2-meter soot-rimmed scorch dashes for las batteries) covering 5 to 8 percent of a section (judgement).

Evolution (Fresh -> Cooling -> Scarred):

Fresh: Brief yellow-orange impact sparks or short red las-flashes that fade within 1.5 seconds so they do not compete with signature weapon glows (judgement).

Cooling: Warm amber embers in small shallow craters that dim to grey soot by the end of the turn (judgement).

Scarred: Low-contrast charcoal scorch smudges and shallow normal-map dents that darken the section's base albedo by 15 to 20 percent without breaking the hull's silhouette or glowing (judgement).

Accumulation behaviour: Battery hits should accumulate into a single per-section "wear and soot" shader mask rather than spawning dozens of persistent decals, leaving visual headroom for the 9 signature marks to stand out on top (judgement).

Strongest source: Starsector community feedback on avoiding decal spam from routine gunfire ([https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90](https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90)).

3. Fleet-Scale Readability Rules (20 Ships on Screen)

Mark Budgets and Layering Architecture

Two-tier damage rendering (Shader Mask + Hero Decals): Do not use individual projected Decal nodes for every hit ([https://docs.godotengine.org/en/4.5/classes/class_decal.html](https://docs.godotengine.org/en/4.5/classes/class_decal.html)) (judgement). Instead, use a per-section multi-channel splatmap/mask in the hull shader for high-frequency attrition (Battery fire, Flak pockmarks, Bio acid spread, Ion panel-line burns), and reserve projected or mesh decals strictly for "hero" structural hits (Lance slashes, Torpedo craters, Gauss punctures, Ram crumples, Boarding breaches) (judgement).

Hard cap on hero marks: Limit each hull section to a maximum of 3 active hero marks, and each ship to 8 to 10 hero marks total (judgement). When a 4th hero hit lands on a section, either upgrade an existing mark of the same weapon kind or replace the oldest cooled mark (judgement).

Model-space projection to prevent UV seams: Follow Nebulous: Fleet Command by projecting damage masks in 3D model space (or triplanar coordinates) rather than 2D UV space so large lance slashes and torpedo craters never clip at texture seams ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082), [https://steamcommunity.com/app/887570/allnews/](https://steamcommunity.com/app/887570/allnews/)).

Contrast, Shape, and Colour Coding Rules

Separate marks by silhouette geometry first, colour second: At tactical camera distance, small colour differences vanish (judgement). Ensure the 10 marks fall into distinct geometric primitives:

Lines: Lance (straight trench), Ion (branching lightning), Battery las (short dashes) (judgement).

Circles/Points: Torpedo (giant ragged hole), Gauss (small black keyhole with bright silver collar), Boarding (neat geometric ring with internal strobe) (judgement).

Patches/Textures: Plasma (splatter with tail droplets), Bio (green honeycomb), Flak (matte grey stipple), Ram (directional buckle crease) (judgement).

Strict emissive discipline: Only Fresh hits (current turn) and Disabled/Critical sections may emit bright HDR bloom (judgement). Once a mark enters the Cooling and Scarred phases, clamp its emission to near zero and rely on albedo value contrast (dark interior vs medium hull paint vs bright silver rim) (judgement).

Section-disabled visual state: Because critical hits disable hull sections temporarily in Voidsworn, a disabled section should shut off all its normal running/window lights ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082)) and vent a slow, continuous plume of dark smoke or arcing sparks until the disable expires (judgement).

Fleet Distance vs. Close Zoom (LOD Rules)

| Camera Distance | What Renders on the Hull | What Is Culled or Simplified |
|---|---|---|
| Tactical Fleet View (20 ships visible) | High-contrast hero mark silhouettes (Lance, Torpedo, Gauss collar, Bio patch, Ion arc), Fresh turn-hit emissive glow, section-disabled light shutoff, and macro soot/flak darkening (judgement). | Fine normal-map noise, small individual battery bullet holes, secondary spark emitters, and subtle heat-tint rainbows (judgement). |
| Close Inspection Zoom (1 to 3 ships) | Parallax occlusion interior girders ([https://steamcommunity.com/app/887570/allnews/](https://steamcommunity.com/app/887570/allnews/)), individual battery divots, weeping bio-fluid droplets, internal boarding muzzle strobes, and specular heat-tint rings (judgement). | Exaggerated fleet-scale rim thickening on Gauss punctures scales down by 40 percent so holes look sharp and physical up close (judgement). |

Failure Modes to Avoid

The "Shredded Metal Cheese" Effect: Identified in Starsector ([https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90](https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90)), where uncapped overlapping decals obliterate ship art and faction colours. Prevent this by keeping at least 35 percent of every hull section's silhouette and base faction trim recognizable even at 1 percent HP (judgement).

The "Christmas Tree" Emissive Overload: Identified in early MechWarrior Online builds ([https://www.reddit.com/r/OutreachHPG/comments/483p7c/mwo_used_to_look_so_much_better/](https://www.reddit.com/r/OutreachHPG/comments/483p7c/mwo_used_to_look_so_much_better/)), where long-lasting bright damage glows turn a damaged target into a blinding neon blob. Prevent this by decaying fresh hit emission by 80 percent after the turn of impact (judgement).

Greeble Projection Tearing: Projecting flat decals onto busy 3D turrets and ribs causes smeared textures ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082)). Design Voidsworn hulls with clean, readable armor slabs and fade decal opacity based on surface normal angle relative to the hit vector (judgement).

4. Ranked Recommendations and UNSURE List

Ranked Recommendations (Most Important First)

Split marks into a Per-Section Shader Splatmap (Attrition) and a Capped Pool of 3 Hero Decals per Section (Signature Hits) (judgement). This is the single most important technical rule to keep 20 ships performant and readable in Godot without turning hulls into decal soup ([https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90](https://fractalsoftworks.com/forum/index.php?action=profile;u=3240;area=showposts;start=90)) (judgement).

Enforce a strict Turn-Based Emissive Decay (Fresh = Bright HDR, Cooling = Dim Ember, Scarred = Unlit Contrast) (judgement). In a turn-based tactics game, glowing scars tell the player "what just got hit this turn," while dark/silver unlit scars tell the player "how beat up this section is overall" (judgement).

Exaggerate small marks at fleet distance using contrasting rims (Silver Collar for Gauss, Green Foam for Bio, Strobe Ring for Boarding) (judgement). Physically scaled holes disappear at fleet distance ([https://medium.com/our-space/the-true-physics-of-space-battles-571926ecf1e2](https://medium.com/our-space/the-true-physics-of-space-battles-571926ecf1e2)); high-contrast collars make small punctures readable across the board (judgement).

Use Model-Space / Triplanar Damage Mapping on smooth hull slabs ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082), [https://steamcommunity.com/app/887570/allnews/](https://steamcommunity.com/app/887570/allnews/)). This prevents lance burn-throughs and torpedo craters from cutting off unnaturally at UV seams.

Tie Section Disable state to ship lighting shutoff ([https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082](https://steamcommunity.com/sharedfiles/filedetails/?id=2815953082)) (judgement). Turning off a hull section's emissive windows and running lights when critically disabled makes section status instantly readable at fleet scale without UI bars (judgement).

UNSURE List

Homeworld 3 internal shader pipeline (UNSURE): While persistent battle scars and weapon damage were publicly demonstrated ([https://store.steampowered.com/app/1840080/Homeworld_3/](https://store.steampowered.com/app/1840080/Homeworld_3/), [https://www.reddit.com/r/homeworld/comments/1133kgd/fig_update_weapons_and_unit_damage_in_homeworld_3/](https://www.reddit.com/r/homeworld/comments/1133kgd/fig_update_weapons_and_unit_damage_in_homeworld_3/)), Blackbird Interactive has not published a technical GDC or blog breakdown of the exact shader node graph used in Unreal Engine 4.

Sins of a Solar Empire 2 hull damage dev blog (UNSURE): A developer stated on Steam forums that a dev blog on the damage system was planned ([https://steamcommunity.com/app/1575940?l=turkish](https://steamcommunity.com/app/1575940?l=turkish)), but a published technical article detailing its hull decal/shader implementation could not be verified.

Battlefleet Gothic: Armada 2 shader documentation (UNSURE): No primary developer post or GDC talk by Tindalos Interactive detailing their Unreal Engine 4 damage shader and decal budgets could be located.

Voidsworn exact ship polycount and UV layout (UNSURE): The evidence pack specifies Godot for PC and hull sections, but does not specify whether Voidsworn uses forward+, mobile, or compatibility rendering in Godot, or whether ship meshes have sufficient vertex density for vertex-shader Ram crumple displacement without tessellation (UNSURE).
