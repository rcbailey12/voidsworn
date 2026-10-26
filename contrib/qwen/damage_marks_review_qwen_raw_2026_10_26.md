# Damage marks review, Qwen leg (brief muse_2026-10-26c, Job 3)

Model: Qwen3.8-Max web chat, fresh chat "Hull Damage Marks Reference", Oct 26, 2026. Both model gates passed: the selector was changed from the default Qwen3.7-Plus to Qwen3.8-Max before submitting, and the chat header still showed Qwen3.8-Max after generation started. The pack was pasted inline in two parts (Qwen cannot take the pack as a file here). The model states at the top of its return that it had no live web access in the session, so its claims about other games are from-knowledge, not independently sourced; weight them accordingly. Filed verbatim below.

---

Job 3 Review: Per-Weapon Damage Marks Reference (Blind Leg)

Web access note: I do not have live web access in this session. All claims about other games, developer talks, and techniques below are marked "from knowledge" (drawn from training data through early 2026) or "judgement" (my own design reasoning). I have not fabricated URLs. Where I recall a specific talk or document existing, I name it and flag it as from-knowledge so the commissioner can verify.

1. Research Findings: How Reference Games Handle Readable Hull Damage

Homeworld 3 (Blackbird Interactive, 2024)

From knowledge: Homeworld 3 ships use a layered damage material system. The surface shader blends between pristine hull material and progressively damaged states driven by a damage mask texture. At the default tactical camera (whole fleet visible, ships roughly 40 to 120 pixels tall on a 1080p screen), individual damage decals are not distinguishable. What reads at that distance is overall hull darkening, the presence or absence of glow points (fires, exposed reactor light), and trailing particle effects (smoke, debris streams). At closer zoom (one or two ships filling the screen), you see scorch decals, gouged plating, and exposed substructure. The damage is generalized, not per-weapon-type. A ship hit by lasers and a ship hit by kinetic rounds look similar at the scar stage; the distinction lives mainly in the hit VFX moment, not the persistent mark.

I recall a Blackbird developer discussing their damage approach in a post-launch dev update or interview (from knowledge, UNSURE of exact source title). The key technique was a damage mask texture per hull section that accumulates hits and drives a material blend, rather than spawning individual decal meshes. This keeps draw calls bounded regardless of how many hits a ship has taken.

Describing the typical screenshot: at fleet distance, a damaged Homeworld 3 frigate reads as a dark silhouette with two or three orange glow points along its spine and a faint grey particle trail. The glow points are the primary damage signal. The hull texture change (darkening, charring) is visible but secondary. At close zoom, the same ship shows irregular dark patches covering roughly 20 to 40 percent of the hull surface, with brighter orange emission at the centres of the worst patches.

Takeaway for Voidsworn: Homeworld 3 confirms that at fleet distance, glow points and silhouette changes do the readability work, not decal detail. Per-weapon distinction has to survive at the glow-colour and mark-shape level, not at texture-detail level.

Sins of a Solar Empire 2 (Ironclad Games, 2025)

From knowledge: The original Sins of a Solar Empire (2008) and its expansion had minimal per-ship damage visuals. Ships had a health bar, glowed when hit, and exploded in a multi-stage death sequence. The hull model itself did not accumulate visible damage. Sins of a Solar Empire 2, released in early access and reaching 1.0 in 2025, improved visual fidelity substantially but the design philosophy at strategic zoom remains similar: ships are small on screen (capital ships perhaps 80 to 150 pixels long at default zoom, frigates much smaller), and the primary damage readout is the UI health bar plus hit-flash and explosion effects.

At the closest zoom in Sins 2, capital ships do show some surface degradation: darkened hull areas, glow spots where weapons have hit. But the game does not attempt per-weapon-type damage marks. The damage visual is generic scorching and structural glow. The readability at fleet scale comes from ship count, formation shape, and the UI layer, not from hull marks.

Takeaway for Voidsworn: Sins 2 is the named presentation benchmark for Voidsworn, but it is not a strong model for per-weapon damage marks specifically. Its lesson is negative: at fleet scale, the game relies on UI and VFX, not hull texture detail. If Voidsworn wants hull-borne damage to be the primary read (per FINDINGS R43), it needs to go beyond what Sins 2 does and borrow from games that do location-specific damage visuals.

Battlefleet Gothic: Armada 2 (Tindalos Interactive, 2019)

From knowledge: This is the closest existing model to what Voidsworn needs. Ships in BFG:A2 are large relative to the screen (a battleship can fill half the screen at tactical zoom), and they show progressive damage in a location-aware way. Hull sections that take critical damage show visible breaches: dark holes with orange interior glow, trailing smoke and spark particles. Weapon-specific damage is partially present: lance strikes leave long scorch lines, macro battery hits leave clusters of smaller impact marks, torpedo hits leave larger blast craters. However, at the default fleet-view distance (multiple ships visible), the per-weapon distinction softens into "dark hole with glow" and "trailing smoke."

I recall Tindalos discussing their damage system in developer diaries around the game's release (from knowledge, UNSURE of exact blog URL). The technique involved per-section damage states on the ship model, with each section having an intact, damaged, and destroyed mesh/material variant. Transitions between states were triggered by damage thresholds. Particle emitters (smoke, sparks, venting gas) were attached to damaged sections to add motion and draw the eye.

Describing a typical screenshot: at medium distance (three or four cruisers visible), a damaged BFG:A2 battleship shows two or three dark breach holes along its port side, each roughly 10 to 15 percent of the hull length. Each breach has an orange-red glow at its centre and a stream of grey smoke drifting aft. The surrounding hull is darkened in a radius around each breach. At closer zoom, you can see that the breach holes have jagged, torn-metal edges and expose a brighter interior structure.

Takeaway for Voidsworn: BFG:A2 validates the per-section damage approach and shows that breach glow plus smoke is the strongest distance-readability signal. Its weakness is that weapon-type distinction is subtle and mostly lost at fleet distance. Voidsworn can improve on this by making the glow colour and mark silhouette more weapon-specific.

Starsector (Fractal Softworks, ongoing since 2011)

From knowledge: Starsector is 2D, top-down, which changes the damage readability problem fundamentally. Ships are sprites, and damage is shown by swapping or blending sprite layers. A ship at full health shows its clean sprite. As hull sections take damage, the sprite shows darkened areas, missing chunks, and small fire/glow effects at damage points. At the default zoom (whole battle visible, up to 30 or 40 ships), individual damage marks are not visible. What reads is the overall ship colour darkening and the presence of small orange glow dots.

The Starsector developer (Alex Mosolov, "Alex") has discussed damage visuals in forum posts on the Fractal Softworks forums over the years (from knowledge). The approach is pragmatic: damage states are pre-drawn sprite variants, not procedural decals. This keeps performance predictable and ensures every damage state is art-directed for readability.

Takeaway for Voidsworn: Starsector's lesson is that pre-authored damage states (rather than fully procedural accumulation) give the artist control over readability at every zoom level. For Voidsworn's nine weapon types, this suggests having authored damage decal variants per weapon per hull section, rather than trying to procedurally composite unlimited unique damage patterns.

BattleTech (Harebrained Schemes, 2018)

From knowledge: BattleTech is the named tactical-feel benchmark for Voidsworn, and its damage model is the most relevant for location-based damage readability. Each mech has eight locations (head, centre torso, left/right torso, left/right arm, left/right leg), each with armour points and internal structure. As armour strips, the mech model visually degrades: armour plates darken, crack, and fall away to expose the grey internal structure beneath. When a location is destroyed, the limb or section is visually removed (an arm falls off, a torso section is blown open).

At the default tactical camera (one or two mechs visible, roughly 200 to 400 pixels tall), the damage is clearly readable. You can see which arm is missing, which torso section is scorched and glowing. The game uses a combination of material swaps (armour to structure), mesh swaps (intact limb to damaged limb to stub), and particle effects (sparks, smoke from damaged locations).

I recall a Harebrained Schemes developer talk or GDC presentation discussing the mech damage pipeline (from knowledge, UNSURE of exact talk title and year). The key technique was a damage-state machine per location with discrete visual steps rather than continuous degradation. Each step was a hand-authored asset state. This kept the visual read clean and predictable.

Describing a screenshot: a medium-range shot of a battered Atlas mech shows its left arm missing entirely (ragged shoulder stump with sparking wires), its right torso panel darkened and cracked with an orange glow at the seam, and its centre torso showing exposed grey structure where armour has been stripped. The damage is readable at a glance because each location is a distinct visual zone.

Takeaway for Voidsworn: BattleTech validates discrete damage states per hull section over continuous accumulation. For Voidsworn, this means each hull section should have a small number of authored damage states (intact, lightly marked, heavily marked, breached) rather than a continuous damage texture. The per-weapon mark type determines which authored state set is used.

Children of a Dead Earth (Patrick Leamy, 2016)

From knowledge: This is a hard-science space combat simulator. Ships are built from modules (reactors, weapons, radiators, crew sections, armour plates), and combat destroys individual modules. The visual damage is extreme and granular: armour plates are blown off, weapon barrels are bent or missing, radiator panels are shredded, and the ship's silhouette changes dramatically over a battle. At the default camera distance, a damaged ship looks like a broken skeleton of its original form.

The game is not a good model for Voidsworn's scale (20 ships at fleet distance) because Children of a Dead Earth typically has one or two ships per engagement and the camera is close. However, its principle is valuable: damage should change the ship's silhouette, not just its surface texture. A ship that has lost a weapon turret, a radiator bank, and a chunk of armour should look structurally different, not just dirtier.

From knowledge, the developer discussed the damage model in Steam community posts and a few interviews (UNSURE of exact sources). The technique was per-module destruction with physics-based debris. Each module had an intact and destroyed state, and the destroyed state exposed internal structure.

Takeaway for Voidsworn: Silhouette change is a powerful damage signal that works at any distance. For Voidsworn's ram damage and torpedo damage in particular, the mark should include a structural deformation or missing chunk, not just a surface decal.

Freespace 2 (Volition, 1999)

From knowledge: A classic reference for 3D space combat damage. Ships accumulate damage through a combination of texture darkening (the hull texture blends toward a damaged variant), spark and fire particle effects at hit points, and progressive subsystem destruction (turrets stop tracking, engines go dark). At the typical combat camera distance, the primary damage signals are the darkened hull texture and the particle effects. The game did not have per-weapon-type damage marks; all damage looked like generic scorching.

The technique was texture blending driven by a damage value, plus particle emitters placed at predefined damage points on the hull. This is a simple, performance-friendly approach that reads well at medium distance.

Takeaway for Voidsworn: Freespace 2 shows that even without per-weapon marks, a combination of hull darkening and particle effects communicates damage effectively. The per-weapon system in Voidsworn is an ambition beyond what most of these games do, which means the mark design needs to be especially disciplined to avoid noise.

MechWarrior 5: Mercenaries (Piranha Games, 2019)

From knowledge: Similar to the Harebrained BattleTech game but in first/third person. Mech damage is shown through armour stripping (surface material transitions), component destruction (arms, legs, weapon barrels lost), and heat/shock effects. At the third-person camera distance, the damage is very readable because the mech fills the screen. The armour-stripping effect uses a material blend where the outer armour paint and plating transitions to scorched, cracked metal, then to exposed internal frame. This is driven by per-location damage values.

Takeaway for Voidsworn: The material-blend approach for armour stripping (clean to scorched to exposed) is a proven technique for showing progressive damage on a 3D model without swapping meshes. It could be used for Voidsworn's hull sections as a base layer, with the per-weapon marks layered on top as decals.

Nexus: The Jupiter Incident (Mithis Entertainment, 2004)

From knowledge: A real-time tactics space game with large, detailed capital ships. Damage was shown through hull texture changes, fires, explosions, and section break-offs. Ships could lose entire superstructure sections. At the typical camera distance (one or two capital ships visible), the damage was readable through silhouette changes and fire/smoke particles. From memory, the game did not do per-weapon-type marks. UNSURE of detailed developer material on the damage system.

Takeaway for Voidsworn: Nexus confirms that silhouette-breaking damage (sections blown off) is highly readable at medium distance and is especially appropriate for high-damage weapons like torpedoes and ramming.

2. Per-Mark Reference Entries

For each mark, I cover: appearance at tactical camera distance, evolution over a battle (fresh, cooling, scarred), accumulation behaviour, and the strongest source or example.

Mark 1: Lance Burn-Through

Appearance at tactical distance: A narrow, elongated bright point on the hull, roughly 3 to 5 percent of the hull length. The shape is a thin line or slot, not a round hole. Colour: white-hot at the centre fading to deep orange at the edges when fresh. When scarred, it reads as a dark line with a faint residual glow. At fleet distance (20 ships visible), the mark reads as a bright dash on the hull silhouette. The line orientation should follow the angle of the incoming lance for verisimilitude, but at fleet distance the orientation is not readable, only the presence and colour.

Evolution:

Fresh (0 to 5 seconds after hit): bright white core, intense orange halo, slight bloom. The mark is at maximum brightness. A brief spark shower along the line. This is the moment of peak readability.

Cooling (mid-battle, 30 seconds to several minutes): the white fades to orange, then to deep red. The halo contracts. The line becomes darker, more defined. Faint smoke wisp from the wound.

Scarred (late battle): a dark, vitrified line. Slight glossy sheen (melted and resolidified hull material). No glow unless the section is critically damaged, in which case a faint interior orange glow bleeds through the line. The mark is roughly 2 percent of hull length and reads as a dark scratch.

Accumulation: Multiple lance hits on the same hull section should merge into a wider burn channel rather than spawning many parallel lines. Cap at three visible lance lines per hull section. Beyond that, the section transitions to a "lanced open" state where the hull plating is visibly peeled back along the burn lines, exposing interior glow.

Strongest source: Battlefleet Gothic: Armada 2's lance strike visuals (from knowledge). In BFG:A2, lance hits leave a bright line that fades to a dark scar. The shape is right for Voidsworn. The addition of the vitrified, glossy scar texture is a judgement call on my part to distinguish lance from other energy weapons.

Mark 2: Plasma Splash Craters

Appearance at tactical distance: A cluster of two to four round-ish dark spots with raised, irregular rims, covering roughly 5 to 8 percent of the hull surface in the affected section. Colour: the fresh crater interior is bright orange-yellow (superheated splash residue), the rim is darkened and slightly raised. At fleet distance, this reads as a rough, warm-coloured blotch on the hull, distinctly wider and messier than a lance line.

Evolution:

Fresh: bright orange-yellow interior with a brief splash-spatter particle effect (small droplets of glowing plasma arcing off the impact point). The crater rim glows.

Cooling: the interior darkens to a deep red-brown. The spatter marks around the crater remain as small dark dots. Smoke wisps.

Scarred: the crater is a dark, rough-textured depression. The raised rim catches light differently from the surrounding hull, giving it a subtle 3D read even at distance. The spatter dots remain as small dark freckles around the main crater.

Accumulation: Plasma craters should accumulate as a growing splash zone. First hit: one crater. Second and third hits: craters overlap and merge into a wider splash area. Cap at a splash zone covering roughly 15 percent of the hull section. Beyond that, the section reads as "scoured," with the entire surface roughened and darkened.

Strongest source: Judgement. No reference game I know of distinguishes plasma from other thermal weapons at the mark level. The splash-crater shape is drawn from the weapon's fiction (a blob of superheated matter that splatters on impact) rather than from a specific game. The closest visual analogue in games is the mortar/impact crater marks in Company of Heroes or Dawn of War (from knowledge), where explosions leave wide, irregular dark craters with raised rims. Translating that to a space hull is a design extrapolation.

Mark 3: Gauss Punctures

Appearance at tactical distance: Small, clean, round dark dots, 1 to 2 percent of hull length each. At fleet distance, individual punctures are below the readable threshold. What reads is a subtle darkening or "dirtying" of the hull section where multiple punctures cluster. If the section has taken many gauss hits, it reads as a darkened patch, almost like a bruise. Up close (one or two ships on screen), individual punctures are visible as small, perfectly round holes with clean edges and a slight inward bevel. No raised rim (the slug goes in, it does not splash).

Evolution:

Fresh: a brief bright flash at the puncture point (kinetic impact energy), then immediately a clean dark hole. Tiny debris particles.

Cooling: not much change. Gauss punctures do not glow or cool significantly. The hole is dark from the start. Slight metallic sheen at the hole edge.

Scarred: the punctures remain as clean dark dots. If the hull section has taken many, the dots cluster and the area between them may show slight cracking (structural stress). No colour shift. The mark is the most "permanent-looking" of all nine: it does not heal, fade, or change. It is a hole.

Accumulation: Punctures accumulate as a growing cluster of dots. Cap at roughly 8 to 12 visible punctures per hull section. Beyond that, the section shows a "perforated" state: the clustered holes merge into a ragged dark patch with visible interior structure.

Strongest source: BattleTech's armour-pip loss visual (from knowledge). In the Harebrained BattleTech game, as armour strips from a location, the surface shows small dark impact points that accumulate. The gauss rifle in that game leaves clean, small holes. The visual language of "many small clean holes" is well established. Also, the Gauss rifle in Children of a Dead Earth (from knowledge) punches clean holes through armour modules.

Mark 4: Torpedo Blast Craters

Appearance at tactical distance: A large, irregular dark crater, roughly 8 to 12 percent of hull length. The crater has a deep, concave shape with jagged, torn edges and a wide char ring around it. Colour: the fresh crater interior glows bright orange, the char ring is black, and the surrounding hull shows heat-discolouration (darkening in a radial pattern). At fleet distance, this reads as the largest and darkest single mark type. A torpedo-hit ship is immediately identifiable by the big dark wound.

Evolution:

Fresh: a bright flash, then a deep orange-red crater with active fire particles and a shockwave ring that fades over two seconds. Smoke pours from the crater. The char ring is at its widest.

Cooling: the fire dies down to smouldering embers inside the crater. Smoke continues. The char ring remains. The crater interior shifts from orange to dark red.

Scarred: a deep, dark, jagged hole. No glow unless the section is critical. The char ring has faded to a dark stain. The crater edges show bent, torn metal. If the torpedo hit caused a critical, the crater may expose a glowing interior (reactor, magazine) as a persistent small glow point.

Accumulation: Torpedo craters should not merge. Each torpedo hit is one crater, and they should be placed at distinct positions on the hull section. Cap at three craters per hull section. If a section takes a fourth torpedo hit, it should be destroyed (breached, missing, or structurally collapsed) rather than showing four craters.

Strongest source: Battlefleet Gothic: Armada 2's torpedo damage (from knowledge) combined with Children of a Dead Earth's module-destruction approach (from knowledge). BFG:A2 shows large blast craters with fire and smoke. Children of a Dead Earth shows structural sections being blown away. The Voidsworn torpedo mark should combine the surface crater of BFG:A2 with the structural consequence of CotDE: a torpedo hit dents and chars the hull, and a critical torpedo hit removes a chunk of it.

Mark 5: Flak Pockmarks

Appearance at tactical distance: A wide, shallow scattering of tiny dark dots and short scratches across a hull section, covering roughly 10 to 15 percent of the section surface. At fleet distance, this reads as a general "roughening" or slight darkening of the hull section, like sandblast damage. Individual pockmarks are not visible. The overall effect is a matte, dulled patch on an otherwise reflective hull.

Evolution:

Fresh: a brief spray of tiny spark particles across the affected area. No single bright flash; instead, a rapid-fire sprinkle of small impacts.

Cooling: the sparks fade. The pockmarks remain as tiny dark dots. No glow, no smoke. Flak damage is the least visually dramatic per hit.

Scarred: a wide, slightly roughened, matte patch. The surface looks sandblasted. No structural deformation. The pockmarks are purely surface-level.

Accumulation: Flak pockmarks should accumulate as a growing matte zone. They are the most "paint-like" damage: each hit adds a small dot, and the dots blend into a zone. Cap at one matte zone per hull section (covering up to 20 percent of the section). Beyond that, the section's surface is fully dulled and further flak hits have no additional visual effect (the surface is already rough).

Strongest source: Judgement. No reference game I know of renders flak/point-defence damage as a distinct hull mark. In most games, point-defence weapons shoot down incoming ordnance and do not leave marks on the target. In Voidsworn, flak is also used offensively (flak battery is a weapon kind), so it needs a mark. The sandblast/pockmark visual is my extrapolation from the fiction of many small kinetic impacts. The closest game analogue is the surface scarring on vehicles in Battlefield or War Thunder after sustained machine-gun fire (from knowledge): many small dark dots that blend into a roughened zone.

Mark 6: Bio Acid Pitting

Appearance at tactical distance: Irregular, organic-looking dark patches with a faint greenish or yellowish tint, covering 5 to 10 percent of a hull section. The edges of the patches are uneven, almost fractal, like corrosion or chemical burns. At fleet distance, this reads as a discoloured stain on the hull, distinctly different in colour from the black-and-orange palette of thermal and kinetic damage. The green-yellow tint is the key identifier.

Evolution:

Fresh: a wet, glistening patch with a bright yellow-green centre. Small drip particles running along the hull surface (acid eating downward/outward). A faint bubbling particle effect.

Cooling: the bright centre dulls to a darker olive-green. The glistening fades. The patch edges become more defined as the acid neutralises. Faint wisps of acrid smoke (greenish-grey).

Scarred: a dark, pitted, corroded zone. The surface texture is rough and eaten, like rusted metal but with a greenish cast. No glow, no particles. The mark looks "old" and chemically damaged rather than thermally or mechanically damaged.

Accumulation: Acid patches should spread slightly over time after the initial hit (the acid keeps working for a few seconds), then stabilise. Multiple hits merge into a larger corrosion zone. Cap at roughly 20 percent of the hull section covered. Beyond that, the section shows structural weakening: the corroded area thins and a small breach hole appears at the centre.

Strongest source: The Zerg creep and acid effects in StarCraft II (from knowledge) provide a visual language for organic, corrosive damage. The acid-spit attack of the Zerg Hydralisk leaves a brief acid splash that corrodes the target's surface. For a more grounded reference, the xenomorph acid blood damage in Alien: Isolation (from knowledge) shows metal surfaces being eaten through with a bubbling, smoking, greenish corrosion. Neither is a space-fleet game, but both establish the visual language of "acid on metal" clearly.

Mark 7: Ion Burns

Appearance at tactical distance: Branching, lightning-like scorch patterns (Lichtenberg figures) in blue-white or pale violet, covering 4 to 8 percent of a hull section. At fleet distance, this reads as a pale, cold-coloured bright mark, distinctly different from the orange-red of thermal weapons. The branching shape is the key identifier when visible; at extreme distance, the colour alone (cool blue-white vs warm orange) distinguishes it.

Evolution:

Fresh: a bright blue-white flash in the branching pattern. The pattern appears instantly, like a photograph of lightning. Brief electrical crackle particles (small blue sparks along the branches).

Cooling: the bright blue fades to a paler, more violet hue. The branching pattern remains visible. Small residual sparks at the branch tips. A faint ozone-haze effect (very subtle blue glow around the mark).

Scarred: the branches become dark, thin scorch lines with a slight blue-black tint. The electrical character is gone; it looks like a burnt circuit trace on the hull surface. No glow.

Accumulation: Ion burns should layer. Each new ion hit adds a new branching pattern radiating from the impact point. Cap at three overlapping patterns per hull section. Beyond that, the section shows a generalised blue-black scorching (the patterns merge into a zone). If the ion weapon has a shield-strip property (as the ion cannon does in the weapon table), the visual should also show a brief shield-disruption effect (a hexagonal or geometric shield flicker) at the moment of the hit, separate from the hull mark.

Strongest source: The ion weapon effects in Star Wars: Squadrons (from knowledge) show blue electrical damage on ship surfaces. The TIE fighter and X-wing ion cannon hits produce a blue-white electrical effect that briefly disables systems. The persistent mark is less well developed in that game, but the colour and branching language is clear. Also, the EMP and ion weapon effects in the Homeworld series (from knowledge) use blue-white electrical visuals. The Lichtenberg-figure branching pattern is a judgement call to make the mark distinctive and physically plausible (electrical discharge on a conductive surface).

Mark 8: Ram Crumple

Appearance at tactical distance: This is the only mark that changes the ship's silhouette rather than its surface texture. A rammed hull section shows visible deformation: plating buckled inward, the hull edge bent or crumpled, and a section of the ship's outline visibly dented or misshapen. At fleet distance, this reads as a ship with a "wrong" outline: a dent in the bow, a crumpled flank, a bent prow. No glow, no colour change initially. The shape change is the signal.

Evolution:

Fresh: the moment of impact shows a structural shockwave (a brief ripple across the hull surface), spark showers at the contact point, and the hull section visibly deforms (the mesh bends inward). Both ships show deformation at the contact point.

Cooling: the deformed area shows stress marks: hairline cracks radiating from the crumple point, slight discolouration (metal stressed beyond its yield point shows heat tinting, a straw-to-blue gradient). Small debris floats away from the impact.

Scarred: the crumple remains as a permanent deformation. The cracked plating may have a few dark fracture lines. If the crumple was severe, a section of plating has buckled away, exposing understructure. The ship's silhouette is permanently altered for the rest of the battle.

Accumulation: Ram damage does not accumulate in the same way as weapon hits. A ship can be rammed once or twice in a battle. Each ram event deforms a different hull section. There is no "cap"; the deformation is the mark. However, if a section is rammed twice, the second impact should breach the already-weakened section rather than deforming it further.

Strongest source: Children of a Dead Earth's collision damage (from knowledge). Ships in CotDE can collide, and the impact deforms and destroys modules at the contact point. The visual is structural, not surface-level. Also, the ramming mechanics in Battlefleet Gothic: Armada 2 (from knowledge) show ships colliding and taking structural damage with visible hull deformation and debris.

Mark 9: Boarding Breaches

Appearance at tactical distance: A jagged, torn opening in the hull, roughly 5 to 10 percent of hull length, with bright interior light spilling out (warm white or orange, representing the ship's interior lighting or fires from the boarding fight). The edges of the breach are irregular, torn, and bent outward (forced open from outside by tendrils or cutting tools). At fleet distance, this reads as a bright wound in the hull: a glowing hole with dark, ragged edges.

Evolution:

Fresh: the breach appears with a cutting/breaking animation (the hull surface splits or is torn open over one to two seconds). Bright interior light floods out. Brief particle burst of sparks and debris. If boarding tendrils (bio weapon) are used, the breach edges show a slight greenish residue (bio-organic material).

Cooling: the interior light dims slightly. Smoke drifts from the breach. The edges remain jagged. Small flickering lights inside the breach (crew fighting, or fires).

Scarred: a dark, open hole with faint interior glow. The edges are blackened. If the boarding action was repelled, the breach remains as a wound but the interior is dark (the section is sealed off or destroyed). If the boarding action succeeded, the breach may show a different interior colour (the boarding faction's lighting, or fire).

Accumulation: Boarding breaches do not accumulate. A hull section is either intact or breached. One boarding action produces one breach. If the same section is boarded again, the existing breach is reused (fighters go in through the same hole). Multiple sections can be breached independently.

Strongest source: The boarding mechanics in Battlefleet Gothic: Armada 2 (from knowledge) show boarding actions as a close-range event that leaves visible damage. The breach visual in BFG:A2 is a dark hole with interior glow. The addition of torn, outward-bent edges and the bio-residue for tendrils is a judgement call for Voidsworn. Also, the breach-and-clear visuals in Alien: Isolation (from knowledge) show torn-open hull panels with jagged edges and interior light, which is a strong visual reference for what a boarding breach should look like up close.

Mark 10: Battery Fire (Generic Light Mark)

Appearance at tactical distance: Small, dark scorch spots, 1 to 2 percent of hull length each, with a very faint orange tinge. At fleet distance, individual battery marks are invisible. What reads is a very slight overall darkening of the hull section that has taken battery fire, as if the paint is slightly scorched. This is intentionally the least visible mark. Batteries are the most common weapon in the game, and if every battery hit left a prominent mark, every ship would be covered in noise within a few turns.

Evolution:

Fresh: a tiny orange flash at the impact point, gone in under a second. A small dark spot appears.

Cooling: the spot is a dark dot, slightly warm-toned. No particles, no smoke.

Scarred: a dark dot, indistinguishable from a gauss puncture at very close range but smaller and shallower. No glow, no depth.

Accumulation: Battery marks should accumulate as a gradual hull darkening. Individual spots are placed, but the primary visual effect is a section-level darkening that increases with the number of battery hits. Cap: after roughly 6 to 8 battery hits on a section, the section is noticeably darkened. After 12 to 15, it is heavily scorched. Beyond that, additional battery hits do not add visual change. The darkening is a uniform overlay, not a collection of visible individual marks.

Strongest source: The hull-darkening damage model in Freespace 2 (from knowledge) and the original Homeworld (from knowledge). Both games show progressive hull darkening as a generic damage indicator. This is the simplest and most readable approach for a high-frequency, low-damage weapon. The Hegemony plasma-trait batteries (which are re-skinned as plasma weapons in faction naming) should use the plasma splash crater mark (Mark 2) instead of this generic battery mark, per the faction weapon trait system described in the evidence pack.

3. Readability Rules: Keeping 20 Damaged Ships Readable at Fleet Distance

Rule 1: Mark Budget Per Hull

Each hull section gets a maximum number of visible marks. I recommend:

3 marks per section for large, distinct marks (torpedo craters, lance lines, boarding breaches, ram crumples).

1 zone per section for area marks (plasma splash, flak pockmarks, acid pitting, ion burns). The zone is one merged area, not multiple separate patches.

1 darkening overlay per section for generic battery damage.

Total visible marks per section: no more than 3 distinct marks plus 1 zone plus 1 overlay. This keeps any single hull section from becoming noise.

(Judgement. No reference game publishes a specific mark budget number. The cap of 3 distinct marks is drawn from BFG:A2's visual approach where more than 3 breaches on a section becomes hard to parse, and from BattleTech's approach of limiting visual states per location.)

Rule 2: Contrast and Colour Separation

The nine marks must be distinguishable by colour and shape even at fleet distance. The palette splits into three families:

Hot marks (thermal weapons): lance, plasma, torpedo. Colour range: white, yellow, orange, red. Shape differentiators: lance is a line, plasma is a wide crater, torpedo is a large jagged crater.

Cold marks (kinetic, electrical, chemical): gauss, flak, ion, acid. Colour range: dark dots (gauss), matte grey (flak), blue-white (ion), green-yellow (acid). Shape differentiators: gauss is small round dots, flak is a matte zone, ion is branching lines, acid is irregular patches.

Structural marks (physical deformation): ram, boarding. No colour glow; the signal is silhouette change (ram) or interior light through a hole (boarding).

Battery darkening is achromatic (just a darkening of the existing hull colour) and does not compete with any of the above.

At fleet distance, the primary readable signals are: (a) does the ship have hot glow points (orange/red), cold glow points (blue/green), or structural deformation (silhouette change)? (b) How many glow points are there? (c) Is the ship trailing smoke or particles? These three questions should be answerable for all 20 ships at fleet distance.

(Judgement. The colour-family split is my design recommendation. The specific colour assignments follow from the weapon fiction and are consistent across most sci-fi visual language.)

Rule 3: Accumulation Behaviour (What Changes, What Caps)

Marks accumulate up to the per-section cap, then the section transitions to a "destroyed" or "breached" state. The destroyed state is a single, clear visual (missing chunk, open breach, collapsed structure) that replaces all accumulated marks.

Mixed damage on one hull: a section can have one hot mark, one cold mark, and one structural mark simultaneously. The marks do not interact visually. A torpedo crater next to an acid patch next to a boarding breach should be three distinct, readable marks.

When a section is destroyed, all marks on it are replaced by the destroyed-state visual. This prevents late-battle hulls from becoming a soup of 15 overlapping marks.

Global hull state: if more than 50 percent of a ship's sections are damaged or destroyed, the ship's overall material darkens slightly and it gains a persistent smoke trail. This is a ship-level signal that works at fleet distance even if individual marks do not.

Rule 4: LOD (Level of Detail) Behaviour

At different camera distances, different information is shown:

Fleet distance (all 20 ships visible): Show glow points (coloured dots at mark locations), smoke/particle trails, and silhouette changes. Do not show mark shape detail. Do not show texture-level damage (pockmarks, small punctures). The hull material shows a simplified damage state (intact, damaged, heavily damaged, critical) as a colour/darkness shift.

Squadron distance (5 to 8 ships visible): Show mark shapes as simplified decals (a dark crater shape, a line, a branching pattern). Glow points become small glow areas. Smoke and particles remain.

Close zoom (1 to 2 ships visible): Show full mark detail: texture, depth, edge detail, interior structure, particle effects (sparks, drips, embers). This is where the full art direction of each mark is visible.

The transition between LOD levels should be a smooth crossfade, not a pop. In Godot, this can be driven by the camera distance uniform in the hull shader, blending between the simplified and detailed damage textures.

(Judgement. The three-tier LOD approach is standard practice in strategy games. Sins of a Solar Empire and Homeworld both use camera-distance-driven LOD for ship detail. The specific thresholds are my recommendation.)

Rule 5: Particle Budget

Particles (smoke, sparks, embers, drips) are the most expensive part of damage visuals at scale. With 20 ships, each potentially showing particles from 3 to 6 damaged sections, the particle count can explode.

Recommendation: at fleet distance, limit each ship to a maximum of 3 active particle emitters (the 3 worst-damaged sections). At close zoom, all damaged sections can emit. Use GPU particles (Godot's GPUParticles3D) rather than CPU particles for performance. Smoke trails should be the last particles to be culled, because they are the most visible at distance.

(Judgement. The cap of 3 emitters per ship at fleet distance is a performance-driven recommendation. I have not profiled Godot's particle system at this scale, so the specific number is UNSURE and should be validated by performance testing.)

Failure Modes to Avoid

The noise wall: Too many marks on one hull, all at the same visual weight. The hull becomes a uniform dark smear and no individual mark reads. Prevented by the mark budget and the section-destroy transition.

The colour soup: Too many different glow colours on one ship, making it look like a Christmas tree. Prevented by limiting each section to marks from at most two colour families, and by the cap of 3 distinct marks per section.

The invisible mark: A mark that is too small, too low-contrast, or too similar in colour to the base hull material to be seen at any distance. Every mark must have a minimum size (at least 1 percent of hull length at close zoom) and a minimum contrast ratio against the hull material. Gauss punctures and flak pockmarks are the most at risk here. They must be visible at close zoom even if they are invisible at fleet distance.

The permanent flash: A fresh-hit glow effect that is too bright or lasts too long, making the ship look like it is constantly being hit. The fresh-hit flash should last no more than 2 to 3 seconds, then transition to the cooling state.

The identical-damage problem: All marks looking the same at fleet distance because the LOD simplification strips away the distinguishing shape and colour. Prevented by ensuring that the fleet-distance LOD preserves the colour family (hot/cold/structural) even if it drops the shape detail.

The empty-hull problem: A ship that has taken many hits but shows no visible damage because all hits were absorbed by shields or armour without marking the hull. In Voidsworn, if the design intent is that hull marks show actual hull damage, then shield hits and armour-only hits should not produce hull marks. Only damage that reaches the hull should mark it. (This is a design question for the team, flagged here as a readability concern.)

4. Ranked Recommendations

Ranked from most important to least important for the success of the damage-mark system:

Establish the three-family colour split (hot, cold, structural) and enforce it across all nine marks. This is the single most important readability lever at fleet distance. If the player can glance at a ship and sort its damage into "burned," "corroded/shocked," or "broken," the system works. Everything else is refinement.

Implement the per-section mark budget (3 distinct marks, 1 zone, 1 overlay) and the section-destroy transition. Without this, late-battle hulls become unreadable noise. The transition from "accumulated marks" to "destroyed section" is the key mechanic that keeps the visual clean.

Use the three-tier LOD system (fleet, squadron, close) and make sure the fleet-distance tier preserves glow colour and silhouette change. The marks must be designed for fleet distance first and close zoom second. If a mark only works at close zoom, it has failed the brief.

Make ram and boarding marks structural (silhouette change, breach with interior glow) rather than surface decals. These are the two highest-drama events in a battle, and they should be readable from across the fleet. A crumpled bow or a glowing breach hole is unmistakable at any distance.

Give battery fire the generic darkening treatment and keep it visually subordinate to the nine signature marks. Batteries are the most common weapon. If they leave prominent marks, they will drown out the distinctive marks. The darkening overlay is the right call.

Use discrete damage states per section (intact, marked, heavily marked, destroyed) rather than continuous damage accumulation. This follows the BattleTech model and keeps the art directed and readable. Each state is authored, not generated.

Cap particle emitters per ship at fleet distance and use GPU particles. This is a performance requirement that directly affects whether 20 damaged ships can be rendered at playable frame rates.

Design the fresh-hit flash as a 2-to-3-second event that transitions to the cooling state. The flash is the moment of feedback ("you hit me"), but it must not persist. The persistent mark is the scar, not the flash.

Ensure the Hegemony plasma-trait batteries use the plasma splash mark, not the generic battery mark. The faction weapon trait system in the evidence pack explicitly re-names these weapons. The visual should match the trait.

Prototype the full system on one ship at fleet distance with all nine mark types active simultaneously before art-directing individual marks. The interaction between marks, the colour balance, and the noise level can only be judged in context. A single-ship test with all nine marks will reveal whether the palette works or whether two marks are too similar.

5. UNSURE List

Items I could not source, verify, or judge with confidence:

UNSURE: The exact developer talk or blog post from Blackbird Interactive about Homeworld 3's damage mask system. I recall the technique being discussed publicly, but I cannot provide a title, URL, or date without web access. The commissioner should search for Blackbird post-launch developer updates or GDC 2024/2025 talks.

UNSURE: The exact Tindalos Interactive developer diary on BFG:A2's per-section damage system. I recall developer diaries existing around the 2019 release, but I cannot cite them precisely.

UNSURE: Whether a Harebrained Schemes GDC talk on BattleTech's mech damage pipeline exists, or whether the information I recall came from developer interviews and forum posts instead. The technique description (discrete damage states per location, hand-authored asset states) is from knowledge but the specific source is uncertain.

UNSURE: The exact particle performance budget for Godot at 20 ships with 3 to 6 damaged sections each. The cap of 3 emitters per ship at fleet distance is a judgement estimate. It needs to be validated by profiling in the actual Godot project on target hardware.

UNSURE: Whether Sins of a Solar Empire 2's 1.0 release added any per-ship hull damage visuals beyond what was in early access. My knowledge of the game's final state may be incomplete. The commissioner should check the latest patch notes or Ironclad developer streams.

UNSURE: The exact visual behaviour of the ion cannon's shield-strip property in Voidsworn. The weapon table says "ion 2.5 shield-strip property," but I do not know how this is intended to look in practice. My recommendation of a hexagonal shield-flicker effect is a judgement call and may not match the designer's intent.

UNSURE: Whether the boarding tendrils (bio weapon, range 1, pierce 0.5) are intended to leave acid-residue marks at the breach point or whether the boarding breach mark is purely mechanical (torn metal). I recommended a faint green residue for tendril-based boarding, but this is a judgement call. If the designer wants boarding breaches to look the same regardless of the boarding method, the bio-residue detail should be dropped.

UNSURE: The exact hull-section layout and count per ship in Voidsworn. The evidence pack mentions "hull sections" but does not specify how many sections a ship has or how they are arranged. The mark budget and accumulation rules assume roughly 4 to 8 sections per ship. If ships have more or fewer sections, the budget numbers may need adjustment.

UNSURE: Whether Children of a Dead Earth's developer (Patrick Leamy) published any formal technical documentation on the module-destruction system. I recall Steam community posts and informal discussions, but I cannot cite a specific document.

UNSURE: The performance cost of per-section damage-state mesh swaps in Godot at 20 ships. If each ship has 6 sections and each section has 4 damage states, that is 24 possible mesh/material variants per ship. At 20 ships, the variant count is manageable, but the draw-call cost depends on whether the variants are pre-instanced or loaded on demand. This needs engine-side testing.

UNSURE: Whether the game's turn-based nature changes the damage-mark pacing compared to the real-time reference games. In a turn-based game, all damage from a turn resolves at once, which could mean 5 to 10 marks appearing simultaneously. The fresh-hit flash sequence may need to be staggered or queued rather than simultaneous, to keep each hit readable. This is a judgement concern flagged for playtesting.

End of review. Filed as blind leg, Job 3.
