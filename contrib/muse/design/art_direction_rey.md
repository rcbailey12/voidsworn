# Voidsworn art direction: Rey's visual pack (Oct 23, 2026)

Author: Rey (Muse). Status: proposal for Ryan's verdict, then Opus's to implement. Grounded in the repo as read tonight: FACTIONS (data.js:110-125), FAC3D (ships3d.js:2-8), terrain kinds (battle.js:193), the designer lens findings (palette collisions, two colour sources, shield contradiction, gold overload). Concept plates generated with this pack live in img/ alongside this file. Space ships, never naval ships, throughout. Banned borrowed terms are not used.

## The one law for colour

**Cyan means shields. Nothing else is cyan, and shields are nothing else.**

fx3d.js currently argues with itself (one comment says cyan is always shields, another colours shields by faction), and rarity Rare sits on the same #62ccff as shields (data.js:386). One law ends all three fights:

- Shields, shield hits and shield UI pips: ice cyan, one hue family for all six factions. A player learns it once and reads every battle instantly, on a phone, at arm's length.
- Faction colour lives where identity belongs: engines, bolts, beams, windows, trim, emblems. FAC3D already routes all of those by faction; shields are the only channel that stops being factional.
- Rare rarity colour moves from #62ccff to soft violet #b78cff (epic stays gold-adjacent only if gold is freed up, see below).
- Gold is rationed: patrons and Command UI only. The selection ring goes white, the flagship marker becomes a faction-coloured chevron. Gold currently means five things; after this it means one.

## Part A: Palettes and materials, with the collisions fixed

Single source of truth ruling: **FAC3D (ships3d.js) wins for anything rendered in 3D; data.js FACTIONS should be regenerated from it.** The two disagree today on Voidsworn trim (#c8501f vs #9c3a1c), Corsair trim (#b8402a vs #a3542c), Ithar hull (#eef3f1 vs #e4ebe7) and Deathless hull (#1d2220 vs #2c3431). One table, generated from the other, ends the drift.

**Voidsworn Crusade** (the reference dark fleet). Hull #4a4440 warm charcoal, dark #1c1918, trim #9c3a1c burnt sienna, glow ember orange (win/engine/bolt all in the 1.0, .42-.52, .12-.18 family). Material: blackened steel plate, heat-blued edges, soot. Light behaviour: absorbs light, reads by its lit windows and engine glare. Silhouette carries it (Part B), colour only confirms.

**Hegemony Navy.** Hull #c4ccd5 pale grey, dark #5a6573, trim #3a78d0 royal blue, glow clean blue. Material: painted naval ceramic, panel lines crisp, minimal weathering, parade finish kept even in battle. The only bright hull in the game: it should look lit in scenes where everyone else is shadow.

**Ashfall Corsairs** (collision fix 1: away from Voidsworn). Today both are dark hulls with hot orange-red glow, and they are the sector 1 pairing, the worst place to be twins. Fix: Corsairs go rust and bone. Hull base shifts from #6a2c22 to a desaturated rust brown #59331f with large patches of stolen Hegemony grey and bare metal (the patchwork is the identity, not the base colour), trim #a3542c ochre, glow stays hot red #e0402c but engines burn dirty: flicker, soot trails, uneven plume (MOVE_FEEL already gives them jit .38). Rule: if a hull panel matches another faction's base colour, it is visibly bolted on, scarred and misaligned. Voidsworn is a uniform; Corsairs are a crime scene.

**The Chorus.** Hull #57364c plum chitin, dark #211419, trim #a4913a (a dull gold that reads as chitin ridge, not metal), glow bile #d6d24a. Material: wet-look chitin, subsurface glow between plates, surfaces that pulse at the MOVE_FEEL cyc 1.5 rhythm. No right angles anywhere, including the UI-facing emblem.

**The Ithar.** Hull #e4ebe7 pearl (FAC3D value wins; it was deliberately taken off-white in v53 so seams read), dark #6c8179 sage, trim #d7c88a pale gold, glow soft jade (win .6, 1, .82). Material: ceramic pearl with gold filigree inlay, solar sail membranes (translucent, jade-lit from behind) mounted vertically, as tall fins on the dorsal and ventral line, never as horizontal wings (horizontal reads as insect; owner's call, Oct 23). Bright like Hegemony but warm and organic-curved where Hegemony is cool and angular: the two bright fleets separate on temperature and geometry.

**The Deathless Dynasty** (collision fix 2: away from Voidsworn). Both hulls are near-black; only the green glow separates them today, and glow is the first thing lost at phone size. Fix: Deathless hull goes colder and harder, #232a28 with a mineral, slate-and-bone quality: pale bone-white structural ribs and face-like prow plates as the faction's second colour (new trim direction: bone #cfd4c8 used structurally, not as paint), trim stays terminal green #1fbf4a, glow #3dff6a. Voidsworn is warm black with fire inside; Deathless is cold black with bone on the outside and green light in the cracks. At silhouette distance Deathless reads by its ribcage geometry (Part B).

## Part B: Silhouette rules and hero hulls

Geometry grammar per faction (readable in flat black, no colour, no light):

- Voidsworn: vertical emphasis. Spires, arched buttresses, a raised cathedral block aft, prow like a rood screen. Nothing horizontal except the lance decks.
- Hegemony: the wedge. One clean triangular plan from above, stepped deck levels, sensor dome on the centreline. No protrusions off the wedge line.
- Corsairs: asymmetry as a rule. No Corsair hull is symmetrical; bolted donor sections, one oversized engine, torpedo racks slung outside the hull line.
- Chorus: radial, knotted, no straight edge longer than a plate. Every hull has visible growth rings and at least one tendril cluster.
- Ithar: the dart and the sail, vertical. Needle prow, hull narrowing to the stern, sail and radiator planes mounted as tall vertical fins above and below the hull line, so the profile is tall, not wide. Horizontal sail wings are banned: they read as insect wings. The thinnest and tallest profiles in the game.
- Deathless: the ribcage. Exposed longitudinal ribs over a dark core, prow plate like a blank face, sections that read as segments of a spine.

Twelve hero concepts (new hulls; none duplicates a roster or SHIP_QUEUE name):

1. **Basilica** (Voidsworn, carrier). A cathedral that launches fighters: twin spire towers flank an open launch nave, stained-glass hangar mouths glowing amber. Grammar: vertical emphasis, arched launch bays.
2. **Confessor** (Voidsworn, lance frigate). All prow and lance: a long rood-screen bow, one spinal lance, minimal stern. Grammar: vertical prow plate, single vertical fin.
3. **Edict** (Hegemony, battlecruiser). The perfect wedge, three stepped decks, ion batteries in recessed centreline trenches so the wedge line is never broken. Grammar: pure wedge, dome.
4. **Meridian** (Hegemony, carrier). Wedge split by a centreline hangar slot lit cool white; fighter screens launch along the wedge axis. Grammar: wedge with a single clean incision.
5. **Jackdaw** (Corsair, torpedo skiff). Half a stolen picket welded to an oversized engine block, external torpedo rack bigger than the crew hull. Grammar: asymmetry, external racks.
6. **Midden** (Corsair, salvage carrier). A hollowed hulk worn as armour, donor turrets on mismatched mounts, crane rigs, bomber bays in the ribs of the dead ship. Grammar: asymmetry at carrier scale, visible salvage.
7. **Lullaby** (Chorus, spore carrier). A gravid brood sac with translucent spore pods clustered under chitin plates (see the Chorus plate in img/). Grammar: radial knot, pods.
8. **Threnody** (Chorus, leviathan). Growth rings like a shell, razor tendril crown forward, bile glow pulsing along ring seams. Grammar: rings, tendrils.
9. **Palinode** (Ithar, sail cruiser). Needle hull, twin vertical sail fins (one dorsal, one ventral) lit jade from behind, gold filigree spars. Grammar: dart plus vertical fins.
10. **Vesper** (Ithar, interceptor). The smallest hero hull: a single blade with a pearl finish, no visible engines, light bending at its edges. Grammar: pure dart.
11. **Cenotaph** (Deathless, tomb carrier). A ribcage the size of a station, bone prow plate blank and staring, green light deep in the ribs where the fighters sleep. Grammar: ribcage at maximum scale.
12. **Ossuary** (Deathless, cruiser). Spine segments with visible articulation, ribs half-open like a cage, reassembly seams glowing green. Grammar: segmented spine.

Generated plates with this pack: all twelve hero studies in img/ (Basilica and Confessor for the Voidsworn, Edict and Meridian for the Hegemony, Jackdaw and Midden for the Corsairs, Lullaby and Threnody for the Chorus, Palinode and Vesper for the Ithar, Cenotaph and Ossuary for the Deathless). The Confessor's first plate composed its spinal lance pointing aft; it was regenerated the same night with the lance forward, muzzle foremost (the v2 plate in img/), per the standing rule that guns never face backward. The first plate is superseded.

## Part C: Backgrounds, the plate system

Backgrounds are where the game can get beautiful cheaply: they are seen in every battle and cost no per-ship work. Today's fights pick a terrain kind (belt, station, planet, storm, graveyard; battle.js:193) but the backdrop does not carry that identity. Proposal: a plate per terrain kind, built as four layers, with a hard readability cap.

The cap, stated once: **no background pixel inside the board area may exceed 40% of the luminance of an unlit hull facet.** Backgrounds are the theatre, ships are the actors; any plate that fights the ships fails review regardless of beauty.

Layers: (1) far gradient nebula (two colours max, region-tinted), (2) one mid feature (the plate's subject), (3) near particulate (dust, ice, embers, drifting debris, matched to the feature), (4) a starfield whose density and colour temperature are set per plate.

The six plates:

1. **Belt** (asteroid belt). Amber-brown nebula wash, a dense tumbling rock field as the mid feature lit warm from one side, dust motes near. Mood: prospector gold over black.
2. **Storm** (ion storm; generated, img/bg_ion_storm). Violet and teal plasma, lightning crawling between filaments, charged haze. Mood: the sky is a weapon. In-battle tie-in: storm terrain already costs accuracy; the plate sells why.
3. **Graveyard** (wreck field). Cold blue-black, the silhouettes of broken hulls as the mid feature (dead, dark, no lights except one blinking distress beacon in factionless white), ice crystals near. Mood: a battlefield that never got cleaned up.
4. **Planet** (orbital). A gas giant limb fills the lower third, ring plane catching light, aurora shimmer at the pole, hard star glare from the system primary. Mood: the only plate with a horizon; fights feel low and fast over the clouds.
5. **Station** (dockyard). Near-black teal, a vast station silhouette at mid distance with running lights in port white and amber, construction sparks, traffic lanes of tiny moving lights. Mood: civilisation, the calm before.
6. **Dead Star** (generated, img/bg_dead_star). A black sphere with a thin ember accretion ring, starlight streaking around it from lensing, sparse cold field, debris catching ring-light. Mood: the gravity well made visible; this plate is the argument for the well mechanic on sight alone.

Region seasoning: FAC_MAP already ties factions to home ground. A plate's far gradient takes a whisper of the home faction's glow colour (never more than a tint) so a Hegemony fight and a Deathless fight on "belt" are cousins, not clones. Twelve effective backdrops from six plates.

## Part C2: The expanded plate catalogue (18 plates)

Owner direction (Oct 23): backgrounds carry a huge share of the game's beauty and variety, so six plates become eighteen. Structure: the six terrain anchors from Part C, a variant for each anchor (a fight should not see the same sky twice in a sector), and six specials not tied to terrain (boss fights, anomalies, finales). Same rules throughout: four layers, 40% luminance cap inside the board area.

Anchors (done): Belt, Storm, Graveyard, Planet, Station, Dead Star.

Variants (queued): Belt Core (one mountain-sized asteroid dominating the mid field, the belt at its densest), Crimson Storm (the storm plate in red and magenta, for Chorus and Corsair home ground), Fresh Battlefield (graveyard variant: wrecks still burning, ember fields, a battle that ended an hour ago), Ring World (planet variant: the full disc of a ringed gas giant held at distance, colder and more serene), Dockyard Dawn (station variant: the primary rising behind the yard, running lights against first light), Dead Star Companion (a living star being siphoned by the dead one, a streamer of fire bending into the dark).

Specials (four done in wave 2, two queued): Stellar Nursery (towering pillars of teal and gold gas, newborn stars embedded, the most beautiful plate in the set; sector finales), Ice Field (crystalline ice asteroids and a bright comet crossing; Ithar home ground seasoning), Shattered Moon (a cracked moon with light in its fractures and a debris ring spreading from it), Pulsar (a small brilliant neutron star sweeping two blue beams through black; timed fights and ambushes), Solar Corona (queued: fighting in the glare above a star's surface, plasma arcs, the brightest legal plate, kept legal by putting the glare at the frame edge), Void Rift (queued: a black tear in space with violet-lit edges and stars smeared around it; Voidsworn home ground and the Nemesis, if he ships).

Generation proceeded in waves of four (the image tool's per-message cap). All eighteen catalogue plates are generated and sit in img/: anchors (Belt, Storm, Graveyard, Planet, Station, Dead Star), variants (Belt Core, Crimson Storm, Fresh Battlefield, Ring World, Dockyard Dawn, Dead Star Companion) and specials (Stellar Nursery, Ice Field, Shattered Moon, Pulsar, Solar Corona, Void Rift).

## Part D: Effects language

Weapon fire is already faction-coloured in FAC3D (bolt, beam). Extend the same discipline:

- Muzzle character: Voidsworn lances charge with a rising ember flare (slow, liturgical); Hegemony ion fire is instant and clinical, no charge; Corsair torpedoes burn dirty and wobble; Chorus spits globs that pulse as they travel; Ithar beams are hair-thin and blinding at the core; Deathless gauss fire is silent-looking, a green line that arrives before its glow.
- Shield hits (all factions, per the law): the cyan ripple, with the faction expressed in the ripple's shape only: Hegemony perfect hexagons, Voidsworn arch-segmented, Chorus blistered, Ithar smooth gradient, Deathless cracked-glass, Corsair patchy and flickering where the shield generator is second-hand.
- Damage states: Voidsworn cracks glow ember from inside; Hegemony vents blue coolant in clean jets; Corsairs shed rust and a donor panel; Chorus bleeds bile and the wound knits visibly; Ithar sails tear and go dark panel by panel; Deathless loses a rib segment, which drifts, then (on reassembly) burns green and flies home.
- Destruction: no two factions die alike. Voidsworn breaks like a burning building, spires toppling inward. Hegemony dies in one white flash and clean halves. Corsairs come apart at the welds, donor sections spinning away intact. Chorus deflates and darkens, pods bursting late. Ithar shatters like glass, sails first. Deathless goes dark in segments, stern to prow, and the green lights are the last thing out.

## Part E: Admirals

Approach: generate portraits with a local image model on Ryan's PC (the Qwen image model already downloaded), not a hosted service. 24 portraits, one locked template, per-faction modifiers, so the set reads as one game's cast.

Pilot status (Oct 23): nine final portraits in img/. The three human pilots (Vex, Kassar, Grax) stand as generated. The Chorus is complete at four of four: the Matriarch (a faceless column of membrane organ pipes), the Voice of the Deep (an abyssal comb-jelly bell), the Mending Choir (a mass of pulsing throat sacs and membrane chambers stitching a broken hull with fleshy sutures) and Razormaw (a blade formation holding a ring that reads as a maw, with a lure light in the empty centre). Nekhet's final form (v3) drops the humanoid frame entirely: a monumental broken ring of bone-white ceramic computation around a green core, attended by service drones. Aelith's final form (v4) stretches the Ithar past human without going aquatic: elongated skull and neck, huge wide-set black eyes, gold light channels under translucent skin, seven-fingered hands, and behind her a radiant array of near-geometric light sails, structured like her fleet's rigs rather than anything grown. Two earlier drifts were corrected on owner feedback and are worth remembering as failure modes: the Mending Choir's first version came out as built architecture (bells in a cathedral), which violates the Chorus guideline that everything is grown flesh; Aelith's v3 read as a fish, which violates the Ithar guideline against aquatic features. Earlier versions are superseded. The remaining 15 portraits can be produced against the same template whenever the game is ready to display them.

Locked style template (every portrait, no exceptions): three-quarter bust, subject lit from the left in their faction glow colour, the faction's background plate (Part C) soft and dark behind them, painterly finish matched to the concept plates in img/, a thin faction-trim frame line at the portrait edge. No text, no insignia lettering.

Per-faction modifiers: Voidsworn, reliquary framing and candle-warm practical light, oath scars and votive seals on the uniform. Hegemony, parade dress, cool clinical light, rank geometry worn as flat enamel bars. Corsair, scars, salvaged insignia from three different navies, nothing matching. Chorus, organic first and always: living flesh, membrane, chitin, bile and growth, gross and disgusting in the way deep biology is. No human features, and no recognizable Earth-animal anatomy (no faces, eyes or limbs borrowed from familiar creatures), but equally no buildings, instruments or architecture: a Chorus admiral is a grown organism, never a constructed thing. A Chorus admiral's name describes what it does or the formation it holds, never a body part of an animal. Ithar, beautiful and genuinely other: elongated, luminous, translucent, proportions stretched well past human, statuesque like beings of light; their sail membranes read as radiant, near-geometric structures of light, never as fish fins, gills or anything aquatic. Explicitly not human-looking, and if a portrait could pass for a costumed human it has failed. Deathless, machine intelligences with no requirement of a humanoid frame at all: constructs, rings, lattices, swarm cores and architectures of computation, sensor light instead of faces, with the green light as a core/system light rather than a soul light. (Owner rulings, Oct 23: the first three factions stay human; Deathless went robotic, Chorus went fully alien, Ithar went non-human, and the Nekhet, Matriarch and Aelith pilots were regenerated to match.)

Speech rules per faction (voice lines below follow them):

- Voidsworn: liturgical military. Short declarative sentences; the vocabulary of oaths, debts and rolls of honour. Never slang, never doubt.
- Hegemony: staff-college precision. Procedural and unhurried; targets are queued, damage is acknowledged, nothing is ever a surprise.
- Corsair: transactional and funny under fire. Everything has a price, every wreck has an owner, retreat is just good business.
- Chorus: plural voice, always "we". Hunger and music metaphors; lines feel sung at low volume.
- Ithar: elegiac courtesy. Measured, archaic politeness; the enemy is pitied, endings are spoken of plainly.
- Deathless: archival flatness. No emotion words; ships are registry entries, damage is an annotation, death is a filing state.

Worked examples (real admirals, real doctrines and Commands, from data.js ADMIRALS):

**Admiral Castellan Vex** (Voidsworn, Line of battle; Command: Fire for effect)
- Battle start: "Form the line. Let them come to the guns."
- Victory: "The debt is paid in full. Record their names."
- Defeat: "Break off. A vow unkept is not a vow broken."
- A kill: "Struck from the roll. Next target."
- Taking heavy damage: "We have bled before. Hold formation."
- Command: "All batteries: fire for effect. Now."

**Grand Admiral Ilsa Kassar** (Hegemony, Fire discipline; Command: Synchronized broadside)
- Battle start: "Battle stations. Fire plan is live; hold your sectors."
- Victory: "Objective secured. Log the expenditure and stand down."
- Defeat: "Disengage on my mark. Preserve the hulls; the plan was wrong, not you."
- A kill: "Target neutralized. Shift fire, next in queue."
- Taking heavy damage: "Damage report acknowledged. Rotate the column and continue."
- Command: "Synchronized broadside, on my count. Fire."

**Warlord Grax Ironjaw** (Corsair, Ram and board; Command: Full burn)
- Battle start: "Pointy end toward the enemy. Try not to scratch the loot."
- Victory: "Ha! Dibs on the big wreck. I saw it first."
- Defeat: "Fall back, fall back! Nobody dies for cargo."
- A kill: "That is one less insurance policy. Keep going."
- Taking heavy damage: "She has held together through worse. Ram speed anyway."
- Command: "Full burn! Everybody hold on to something expensive."

**Overlord Nekhet the Undying** (Deathless, Eternal legion; Command: Reanimation protocol)
- Battle start: "Registry open. All hulls present. Proceed."
- Victory: "Outcome archived. The legion does not diminish."
- Defeat: "Withdrawal is a clerical matter. We will be refiled."
- A kill: "Target struck from the living registry. Noted."
- Taking heavy damage: "Damage is a temporary annotation. Continue."
- Command: "Reanimation protocol. Rise, and resume your posts."

## Status

Complete as a pack: all twelve plates generated (six hero ship studies, six background plates, in img/), Parts A to E written. Ryan reviewed the plates Oct 23, 2026 and approved them, with one design revision: Ithar sail planes are vertical fins, not horizontal wings (the first Palinode plate read as insect-like). The grammar in Parts A and B is updated and the Palinode plate regenerated to match.

Next, on Ryan's sign-off: push this pack to contrib/muse/design/ and hand Opus the palette unification (FAC3D as source, data.js regenerated) as the first implementation slice.
