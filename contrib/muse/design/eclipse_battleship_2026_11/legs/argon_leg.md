# Argon leg, Job 8 (Eclipse battleship)

Model: Gemini Argon High, both model gates passed. Filed verbatim as the record. The chair does not use this leg as a source for numbers: its Bastion and Dominion damage figures are inferences built on assumed comparator values (the leg flags them as inferences itself), and the chair synthesis recomputes all firepower from data.js. Its proposed new ability, Corona shroud, is an invention carrying an unverified code cost estimate. Screening notes are in the synthesis.

---

1. Headline

The Eclipse penumbra (d_sepulcher) is a late-run heavy fleet anchor built under Ruling R63 to give Eclipse a true battleship instead of a carrier. Its one defining strength is raw, unshielded staying power paired with twin forward Corona arcs: a 260-hull, 0.35-armor K-1 Kharon slab that phases straight through asteroid fields on its Fold drive, absorbs capital salvos without shields, and bursts Repair swarm for 52 hull points to keep itself or a newly reanimated ship alive. Its one defining cost is its crushing footprint in both economy and command cap: at 6 Command Points and 590 credits on the main branch (630 credits on rules15 once the battleship multiplier ladder is fixed), buying and fielding one locks up half a standard fleet budget in a single hull with zero evasion, zero shields, and a slow 1-hex turn rate.

2. Role in the fleet

The Eclipse zenith cruiser (d_harvester) is a durable mid-line support piece, but at 145 hull, 0.30 armor, and zero shields, it cannot stand in the open lane against enemy battleships like the Sunward Crusade Bastion (220 hull, 30 shields) or the Hegemony Dominion (230 hull, 32 shields). Because Eclipse ships have no shields to soak opening volleys and re-charge between turns, concentrated capital fire strips 145 hull before the cruiser's Repair swarm or passive regeneration can stabilize it. Worse, the faction rule Archive restore only reassembles the first non-boss Eclipse hull to fall in a battle. In a cruiser-led fleet, an aggressive Eclipse mote frigate or Eclipse flare destroyer almost always dies first and consumes that one-per-battle resurrection, leaving the zenith cruiser with no safety net if enemy dreadnoughts focus it down. Even on offense, a single zenith cruiser carries only one Corona arc lance on a 2-turn cooldown, meaning it lacks the burst damage to crack heavy armor and shields before taking return fire.

The Eclipse penumbra battleship does what the cruiser cannot: it serves as an immovable frontline sunshade that can absorb an entire enemy battleline's alpha strike on bare hull and immediately answer with two forward Corona arcs plus twin turret Null cannons. An Eclipse fleet built around one is a mid-to-late-run anvil-and-scythe formation. The battleship advances straight through central rocks and wrecks via Fold drive, forcing the enemy fleet to shoot into its 260-hull, 0.35-armor nose while lighter Eclipse hulls flank around the edges. When the first screening destroyer or cruiser falls and triggers Archive restore at the start of the next round—returning at a fraction of its hull and unable to fire—the battleship uses Repair swarm within 3 hexes to pump 20 percent hull back into that vulnerable ship so it survives its wake-up turn.

This ship should never be used as a solo flanker, a wide-arc turn fighter, or an isolated rear-guard carrier hunter. At speed 2, turn 1, and evasion 0, fast frigates and destroyers that slip past its forward arc can camp behind its wide sunshade fan where its twin Corona arcs cannot bear, chipping away at unshielded hull that costs real turns to regenerate.

Among the four shipped Eclipse admiral starting styles, it serves the two cruiser-led fleets (harvester + jackal and harvester + two motes) best. In those fleets, adding the battleship promotes the starting harvester cruiser from overworked main tank to secondary off-tank, creating overlapping Repair swarm fields that heal 52 hull on the battleship or 29 hull on the cruiser every three turns. In the two light pack-hunter fleets (two jackals + two motes and three jackals), buying this battleship mid-run provides the central bunker those fragile Fold skip raiders desperately need once enemy encounters scale up to heavy capitals.

3. Stat block

Shipped-format hull line:

d_sepulcher "Eclipse penumbra", Battleship, size 1.0, cp 6, hp 260, sh 0, rg 0, armor .35, speed 2, turn 1, evasion 0, weapons: Null cannon (turret) x2, Corona arc (prow) x2, Null shredder (turret). Ability: Repair swarm. Refit slots 3. Regen 5 (4 on rules15). Reanimate. Cost: computed, 590 on main (630 on rules15 with multiplier 1.70).

Number-by-number justification against the comparators:

Size (1.0): Sits cleanly above the Eclipse zenith cruiser (0.82) and just above the Bastion (0.95) and Dominion (0.98) to reflect its wide forward sunshade fan, while staying far smaller than The Unsetting boss (1.3).

Command Points (cp 6): Follows Ruling R63 ("stronger but dearer, faction appropriate across stats, price and command points"). Eclipse steps up by +2 CP from destroyer (cp 2) to cruiser (cp 4); stepping up another +2 CP to cp 6 matches the Hegemony Dominion (cp 6), sits 1 CP above the Crusade Bastion (cp 5), and sits at exactly half of The Unsetting (cp 12).

Hull (hp 260): The Bastion has 220 hull plus 30 shields (250 combined initial hit pool) and the Dominion has 230 hull plus 32 shields (262 combined initial hit pool), with both regenerating 12 shields every turn. Because Eclipse ships never carry shields (sh 0, rg 0), hp 260 gives the penumbra the same opening survival pool as the Dominion (260 vs 262), steps up by +115 HP over the zenith cruiser (hp 145), and stays near half of The Unsetting (hp 480).

Shields and Shield Regen (sh 0, rg 0): Strictly enforces the shipped Eclipse faction rule across all hulls.

Armor (0.35): Eclipse hulls climb by exactly +0.05 armor per class: frigate 0.20, destroyer 0.25, cruiser 0.30. Stepping the battleship to 0.35 completes that progression, matches The Unsetting (0.35), beats the Bastion (0.30) and Dominion (0.25) to offset the lack of shields, and honors the lore fact that Eclipse holds K-1 Kharon, the armor core.

Speed, Turn, Evasion (speed 2, turn 1, evasion 0): Matches the zenith cruiser, the Bastion, and the Dominion (speed 2, turn 1, evasion 0) so the battleship can advance in formation with cruisers rather than crawling at The Unsetting's boss speed of 1.

Refit slots (3): Automatic by the engine rule that any hull at cp 5 or higher receives 3 refit slots, matching the Bastion.

Regen (5 on main, 4 on rules15): On main, Eclipse regen scales from frigate 3 and destroyer 3 to cruiser 4 and boss 8. Setting the battleship to 5 on main and trimming it by 1 to 4 on rules15 follows the exact Job 3 balance package v2 formula (-1 regen across every non-boss Eclipse class).

Reanimate (true): Required on every non-boss Eclipse hull to feed Archive restore.

Full price arithmetic and FS-2 resolution:
Under data.js:539 to 547, a hull without a hardcoded price computes its base cost as (60×CP)+10, rounded to the nearest 5, and then multiplies by the faction class multiplier, rounded to the nearest 5 again.

Hull & CP Option | Base Cost Formula | main Multiplier & Price | rules15 Current Multiplier (1.60) & Price | rules15 Fixed Multiplier (1.70) & Price
Eclipse zenith (Cruiser, CP 4) | (60×4)+10=250 | 250×1.55=387.5→390 | 250×1.65=412.5→415 | 250×1.65=412.5→415
Eclipse penumbra (Battleship, CP 6 pick) | (60×6)+10=370 | 370×1.60=592.0→590 | 370×1.60=592.0→590 | 370×1.70=629.0→630
Eclipse penumbra (If set to CP 5) | (60×5)+10=310 | 310×1.60=496.0→495 | 310×1.60=496.0→495 | 310×1.70=527.0→525

Resolving the R1 FS-2 multiplier anomaly on rules15:
On main, the Eclipse class multipliers step up by +0.05 per hull size: Frigate 1.45, Destroyer 1.50, Cruiser 1.55, Battleship 1.60. In Job 3 balance package v2 (rules15), the first three classes were raised by +0.10 (to 1.55, 1.60, 1.65), while Battleship was left untouched at 1.60 because no Eclipse battleship existed yet. Even though a CP 6 battleship at 1.60 still costs 590 (clearing the cruiser's 415), leaving the multiplier at 1.60 violates the R1 FS-2 rule (data.js:540) in multiplier progression. The cleanest fix is to raise the Eclipse battleship multiplier on rules15 from 1.60 to 1.70 (preserving the exact +0.05 class step across all four tiers and yielding a computed price of 630), rather than hardcoding an explicit cost that bypasses future balance passes.

4. Weapons and ability

Weapon loadout and rationale:

Null cannon (turret) x2 (gauss): 3 shots, 6 damage, range 5, accuracy 74, pierce 0.6, crit 5.

Corona arc (prow) x2 (doom): lance kind, 1 shot, 40 damage, range 5, accuracy 78, pierce 0.6, crit 12, cooldown 2.

Null shredder (turret) (flak): flak kind, 3 shots, 3 damage, range 2, accuracy 80, strong against squadrons, weak against capital ships.

Every weapon is chosen strictly from the shipped Eclipse weapon list. The zenith cruiser mounts two turret Null cannons, one prow Corona arc, and one turret Null spire. Stepping up to the penumbra battleship adds a second prow Corona arc and upgrades the point-defense mount from the Null spire (2 shots, 4 damage, range 3) to the heavier Null shredder (3 shots, 3 damage, range 2, previously carried only by The Unsetting). Doubling the prow Corona arc gives the battleship a terrifying 80-raw-damage forward lance salvo on burst turns to punish enemy dreadnoughts, while the Null shredder chews up enemy bomber squadrons that dive into close range—vital under Ruling R63 because Eclipse has no carrier or fighter squadrons of its own to intercept enemy strikes.

Rough expected damage per firing turn comparison (labelled rough):
Per section 6 of the pack, the table below computes rough expected damage per turn with accuracy applied and cooldowns averaged.

Cooldown averaging note: In turn-based tables, cooldown 2 on Corona arc means either firing once every 2 turns (a 2-turn cycle: fire, recharge) or having 2 recharge turns between shots (a 3-turn cycle). Both averages are shown below.

Inference flag on Bastion and Dominion: pack.md gives exact weapon stats for Eclipse weapons, and gives the weapon names and arcs for the Bastion (Heavy sear broadside port/starboard, Oath lance prow, Spark flak turret) and Dominion (Heavy plasma lance port/starboard, Ion cannon prow, Picket lasers turret), but does not include the non-Eclipse weapon damage tables from data.js. To provide a transparent comparator benchmark without inventing hidden code facts, Bastion and Dominion numbers below are marked as [Inference] assuming their prow heavy weapon matches the Corona arc tier (~15.6 avg expected dmg/turn) and each heavy broadside equals roughly 1.5× a Null cannon (~20.0 expected dmg/turn per side). Crucially, because Bastion and Dominion split their main guns between port and starboard arcs, they can only fire one broadside plus their prow weapon at a single target in front or to one side, whereas the penumbra brings both turret Null cannons and both prow Corona arcs to bear on the same forward target.

Hull | Anti-Capital Weapons Bearing on 1 Target | Expected Damage on Burst Turn (Accuracy Applied) | Rough Average Anti-Capital Damage / Turn (2-Turn Lance Cycle / 3-Turn Cycle) | Point-Defense / Flak Mount (Raw Expected vs Squadrons) | Armor-Piercing Edge
Eclipse zenith (Cruiser, CP 4) | 2× Null cannon (turret) + 1× Corona arc (prow) | 26.64+31.20=57.84 | 42.24 / 37.04 | 1× Null spire: 8×0.80=6.40 | 0.60 pierce + Null halves armor
Eclipse penumbra (Battleship, CP 6) | 2× Null cannon (turret) + 2× Corona arc (prow) | 26.64+62.40=89.04 | 57.84 / 47.44 | 1× Null shredder: 9×0.80=7.20 | 0.60 pierce + Null halves armor
Bastion-class (Crusade BB, CP 5) | 1× Heavy sear broadside + 1× Oath lance (1 side) (or 2× broadsides if straddling 2 targets) | ~51.2 single target (~71.2 both sides) [Inference] | ~35.6 single target (~55.6 both sides) [Inference] | 1× Spark flak (turret) | Standard faction pierce [Inference]
Dominion (Hegemony BB, CP 6) | 1× Heavy plasma lance + 1× Ion cannon (1 side) (or 2× broadsides if straddling 2 targets) | ~51.2 single target (~71.2 both sides) [Inference] | ~35.6 single target (~55.6 both sides) [Inference] | 1× Picket lasers (turret) + 1 Squadron | Standard faction pierce + Squadron

Rough calculation details: One Null cannon deals 3×6×0.74=13.32 expected damage every turn (26.64 for two), before its 5% crit chance and before the Eclipse faction weapon trait (Null weapons ignore half of target armor in addition to 0.60 pierce). One Corona arc deals 1×40×0.78=31.20 expected damage on its firing turn (62.40 for two), averaging 15.60 per turn on a 2-turn cycle (31.20 for two) or 10.40 per turn on a 3-turn cycle (20.80 for two), before its 12% crit chance.

Ability choice — why Repair swarm (reclaim) is the right inheritance (with Spinal cannon and a flagged new ability compared):
Inheriting Repair swarm (reclaim, cooldown 3, restores 20 percent hull to your most damaged ship within 3 hexes, this ship included) from the cruiser is the strongest fit for the battleship's role as a shieldless fleet anchor. Because Repair swarm scales by percentage of maximum hull, jumping from the 145-HP cruiser to the 260-HP battleship increases the self-heal burst from 29 HP to 52 HP every 3 turns (an average of 17.33 HP per turn on top of 4 to 5 passive regeneration). That scaling is what lets a shieldless 260-HP hull survive focused capital fire without ever breaking the faction's no-shield rule.

If the owner prefers an offensive ability that fits only a battleship and no smaller hull, the shipped alternative is Spinal cannon (nova: 40 damage to a hex 3 to 9 away and 20 to everything adjacent, hits friends too, cooldown 3), currently carried only by The Unsetting boss and the Crusade dreadnought. Spinal cannon is unusable on Eclipse frigates and destroyers because they want to Fold skip into point-blank range where a friendly-fire blast would wreck their own pack, whereas a slow range-5 battleship can shell enemy clusters 3 to 9 hexes ahead before the smaller ships close in.

Flagged new ability alternative (invention — cost stated): Corona shroud (d_shroud_pulse, cooldown 3): emits a blinding flare from the hull's sunshade ring that grants all friendly Eclipse ships within 2 hexes +15 evasion until next turn and restores 10 percent hull to this ship. Cost to add: requires 1 new ability object in data.js, roughly 25 lines of turn-buff logic in the combat script, and 1 white-gold ring particle trigger.

5. Name

Display name: Eclipse penumbra

Data id: d_sepulcher

Class label: Battleship

Justification against naming and motif rules:
The shipped Eclipse line hulls follow the strict pattern of the word Eclipse (no "the") plus one lowercase noun drawn from light and its absence: Eclipse mote (a tiny speck in a sunbeam), Eclipse flare (a sudden burst of solar light), and Eclipse zenith (the sun at its highest point). In astronomy, the penumbra is the wide outer shadow cast across a world by an eclipsing body—matching both the faction's lost-sun motif and the physical look of a giant sunshade hull behind which the rest of the fleet shelters. It avoids any Glasswright words (no glass, crystal, prism, or reflection) and avoids retired song words.

For the internal data id, none of the shipped Eclipse ids (d_scythe, d_jackal, d_harvester, d_boss) match their display names; instead, they use grim tomb and reaper nouns under the deathless (d_) prefix. d_sepulcher fits d_scythe, d_jackal, and d_harvester cleanly and will never collide with another hull. The class label Battleship matches the Hegemony Dominion (class label Battleship) and Ruling R63.

Runner-up display name and why it lost:
The runner-up is Eclipse nadir (with Eclipse umbra a close third). Astronomically, nadir is the exact opposite of zenith—the lowest point of the sun beneath the dark horizon—which makes a poetic pair with the Eclipse zenith cruiser. However, section 4 of the pack lists the five Eclipse officer ranks as Shade, Gloam, Umbra, Midnight, Nadir. Naming a ship hull Eclipse nadir or Eclipse umbra duplicates an admiral rank word in the UI, whereas Eclipse penumbra is uniquely a hull name.

6. The look

The Eclipse penumbra is a wide, heavy deep-space sunshield vessel built around the faction's core silhouette: a massive, multi-tiered forward sunshade fan sheltering an armored spinal vault behind it, crowned at the stern by a glowing white-gold eclipse corona ring. In strict compliance with the October 21–24 ship rules, it has zero naval warship features: no boat keel, no raked nautical stem, no masts, no smoke funnels, no open decks, no bollards or anchors, and no rows of portholes. Its underside is a flat, heavily armored belly slab studded with recessed docking hatches, thruster pods, and downward sensor blisters.

The forward sunshade fan: The front third of the ship is a broad, crescent-shaped shield composed of five overlapping, stepped armor petals made of dark violet-black K-1 Kharon plates. The fan spreads wider than the main hull body (size 1.0) so smaller hulls look like they can shelter in its shadow. Two symmetric vertical notches are cut into the left and right inner petals of the fan so the forward lance emitters can fire straight ahead without clipping the shield.

The Archive core and spinal vault: Sheltered directly behind the center of the sunshade fan sits an armored octagonal sarcophagus housing the ship's local Archive backup core. Narrow seams between its heavy violet-black armor plates leak a soft, cold violet-white inner glow, surrounded by low stepped command sensor housings rather than a tall naval bridge tower.

Weapon mounts and firing arcs: All weapons sit in matched symmetric pairs on visible mechanical mounts and aim strictly forward or outward, never backward and never into the hull:

The two prow Corona arcs sit on heavy forward saddle mounts recessed into the left and right shoulders directly behind the sunshade firing notches, aiming dead ahead.

The two turret Null cannons sit on raised armored plate-and-ball mounts on the port and starboard dorsal flanks midships, raised clear of the spinal vault so they can track forward and outward across wide side arcs.

The turret Null shredder sits on a central dorsal column mount just aft of the Archive core, giving its triple barrels a clean upper hemisphere to shred incoming bomber squadrons (mirrored by a matching ventral sensor/point-defense dome on the flat belly).

Heat radiators and antenna arrays: Instead of masts or funnels, four flat, blade-like heat radiator fins extend diagonally from the mid-hull flanks, glowing faint white-gold along their inner cooling vanes to vent the heat of the twin Corona arcs. Forward sensor prongs project horizontally from the lower lip of the sunshade.

Engines and eclipse corona ring: At the rear, the ship has no flaming rocket bells. Instead, a wide, hollow ring of dark violet-black metal—the eclipse ring—encircles a cluster of four dark, silent Fold-drive reaction nozzles. The inner rim of this ring shines with a crisp, blazing white-gold eclipse corona light, looking like a total solar eclipse viewed from behind.

Contradiction flagged for the builder (do not copy):
The shipped 3D palette line in data.js:126 still sets Eclipse to hull dark grey-green, trim green, glow green. That code line is stale and contradicts both the lore bible and the Job 2 faction package. The builder must not use any green on this ship: use dark violet-black armor plates, white-gold eclipse corona trim and ring light, violet-white inner seam and Null weapon glow, and cold white repair swarm effects.

7. Concept image prompts

Prompt 1 — Top view (orthographic plan view):

Top-down orthographic concept art of a heavy sci-fi deep-space battleship for the Eclipse faction, centered on a neutral dark studio background. The silhouette is dominated at the forward hull by a wide, crescent-shaped sunshade heat shield built from five layered, overlapping fan petals of matte dark violet-black armor plate. Two symmetrical forward-facing lance barrels sit in saddle mounts recessed into notches on the left and right shoulders behind the sunshade fan, aiming straight ahead. Behind the fan, a thick octagonal armored spine houses a recessed Archive core glowing softly with violet-white inner light along its plate seams. Midships features a matched symmetric pair of dual-barrel turret cannons on raised circular plate mounts on the left and right flanks aiming forward-outward, flanked by four angled flat heat-radiator fins with faint white-gold cooling seams. At the rear sits a wide circular eclipse ring surrounding silent dark drive nozzles; the inner edge of the ring shines with brilliant white-gold solar corona light, with no engine flames. Strictly a deep-space machine with flat armored geometry, sensor arrays, and equipment pods. No naval boat features, no keel, no raked nautical stem, no masts, no funnels, no open decks, no portholes, no green glow anywhere, no text or labels.

Prompt 2 — Side view (orthographic profile view):

Side profile orthographic concept art of a heavy sci-fi deep-space battleship facing left, on a neutral dark studio background. The forward hull is a tall, curved, multi-layered sunshade shield made of dark violet-black armor plates angled to block incoming fire and solar radiation, with horizontal sensor antenna prongs extending from its lower lip. The underside of the entire spacecraft is a completely flat, heavy armored belly slab fitted with recessed docking hatches and maneuvering thruster pods. Sheltered behind the upper sunshade sits a low, stepped armored command housing and an octagonal Archive vault leaking cold violet-white light between thick armor slabs, followed by a raised dorsal column mount carrying a triple-barrel point-defense turret. A heavy forward lance emitter protrudes through a notch in the forward sunshade, and a midships turret sits on a visible side saddle mount aiming forward. Four sloped radiator vanes project aft toward a vertical circular eclipse ring encircling dark, flameless Fold-drive nozzles; the ring casts a bright white-gold corona halo against the dark violet-black hull. Strictly space-industrial architecture: no boat hull, no keel, no masts, no smoke funnels, no porthole rows, no flaming engine bells, no green light anywhere, no text.

Prompt 3 — Three-quarter view (isometric perspective view):

Three-quarter front-left perspective concept render of an ancient-futuristic sci-fi battleship in deep space, built for the Eclipse faction. The spacecraft leads with a massive, layered crescent sunshade fan at the forward hull, crafted from overlapping dark violet-black K-1 Kharon armor plates etched with subtle white-gold trim along the outer rim. Through two symmetric cut-outs in the sunshade fan, a pair of heavy Corona arc lance emitters aim forward from recessed saddle mounts, glowing with violet-white energy. Behind the protective fan, the bulky armored body has a flat underside belly, symmetric port and starboard sponson blocks carrying paired Null cannon turrets on visible ball-and-plate mounts aiming forward and outward, and a dorsal point-defense turret behind a glowing violet-white Archive core housing. Angular heat radiator blades and forward sensor arrays replace any nautical structures. Around the rear drive section floats a large circular eclipse ring shining with an intense white-gold solar corona edge glow, with no fire or exhaust plumes from the engine nozzles. Crisp studio key lighting highlighting dark violet-black metal, white-gold corona light, and violet-white accents. Strictly no naval ship parts, no keel, no masts, no funnels, no portholes, no green glow, no text.

8. Hand built parts list

Because AI 3D hull generators reliably mangle fine mechanical geometry, the builder should strip and hand-build the following parts under the project's nine blob-sweep categories, snapping every part onto the hull on visible mounts in matched symmetric pairs:

1. Guns of any size:

Prow Corona arc lances (1 symmetric pair): Long, slotted twin-rail lance barrels mounted on heavy saddle mounts inside the port and starboard notches of the forward sunshade fan, aiming straight ahead.

Midships Null cannon turrets (1 symmetric pair): Twin-barrel medium turrets on raised circular plate-and-ball mounts on the port and starboard dorsal shoulders, angled 15 degrees outward from forward.

Dorsal & ventral Null shredder / sensor turrets (1 vertical symmetric pair): A triple-barrel short-range flak turret on a central column mount behind the Archive spine, paired with a matching ventral sensor/defense cupola on a plate mount on the flat belly.

2. Bridge and superstructure tiers:

Archive core vault and low command blister (centerline assembly): A crisp octagonal stepped armor housing on a flat plate mount immediately behind the sunshade crest, with recessed violet-white light seams in place of windows or bridge towers.

3. Masts and funnels (rebuilt as antenna arrays and heat radiators):

Forward Fold-sensor prongs (1 symmetric pair): Twin horizontal multi-rod antenna arrays on saddle mounts under the left and right lower edges of the forward sunshade, pointing dead ahead.

Mid-hull heat radiator vanes (2 symmetric pairs, port and starboard): Four flat, louvered cooling blades on hinged saddle mounts angled outward from the rear hull flanks, lit with white-gold emissive strips.

4. Tanks, drums and cylinders:

Siphon capacitor drums (2 symmetric pairs): Four armored cylindrical starlight-siphon cells snapped into recessed saddle cradles along the port and starboard waist between the turrets and the engine ring.

5. Bow shape (forward hull sunshade):

Layered sunshade fan petals (center plate + 2 symmetric pairs of outer petals): Five crisp, hard-edged overlapping armor fan plates mounted on heavy rear column struts to form the forward sunshield with clean weapon notches.

6. Engine nozzles:

Stern Eclipse corona ring and dark drive nozzles (centerline ring + 2 symmetric pairs of nozzles): One clean circular outer ring on four radial column struts with an inner white-gold emissive band, surrounding four recessed dark reaction cones with zero flame geometry.

7. Armour stacks:

Dorsal K-1 Kharon carapace slabs (3 symmetric pairs): Six stepped, beveled violet-black armor plates snapped onto plate mounts along the spine behind the sunshade.

8. Sponson blocks:

Port and starboard weapon sponsons (1 symmetric pair): Heavy angular side hull blocks snapped seamlessly onto the mid-hull walls to provide flat horizontal decks for the Null cannon turret plate mounts.

9. Thin spiky debris (cleanup sweep):

Full AI artifact deletion pass: Strip all thin AI-generated spikes, ragged corona tendrils, crooked antennas, and floating mesh crumbs before snapping on the hand-built parts above.

9. Owner questions

Question 1: Command Points and Shipyard Price
How heavy should the Eclipse penumbra feel in fleet cap and shipyard price?

Option A (Recommended — CP 6, 590 credits on main / 630 on rules15): Matches the Hegemony Dominion at 6 CP, steps up cleanly by +2 CP over the zenith cruiser (CP 4), and justifies top-tier 260 hull and twin Corona arcs under Ruling R63.

Option B (CP 5, 495 credits on main / 525 on rules15): Matches the Crusade Bastion at 5 CP and makes the battleship easier to slot into a 10–12 CP fleet alongside a cruiser, but requires trimming its hull from 260 down to ~225 so it does not underprice the Dominion.

Why Option A is picked: Ruling R63 states Eclipse hulls are stronger and dearer across stats, price, and CP, so matching the highest non-boss CP in the game (CP 6) lets it be an uncompromising dreadnought-peer.

Question 2: Active Ability on the Battleship
Which active ability should the player press on a 3-turn cooldown when flying this ship?

Option A (Recommended — Repair swarm, inherited from the zenith cruiser): Restores 20% hull (52 HP on self, or 20% to a nearby ally within 3 hexes), letting the battleship heal itself through focused fire or save the ship that just revived from Archive restore.

Option B (Spinal cannon, shared with The Unsetting boss and Crusade dreadnought): Fires a 40-damage artillery shell 3 to 9 hexes away with 20 splash damage to all adjacent hexes (including friendlies), turning the battleship into a long-range siege gun.

Option C (New ability — Corona shroud, costs ~25 lines of code): Gives friendly ships within 2 hexes +15 evasion for 1 turn and repairs 10% hull on this ship, acting as a literal protective sunshade for the fleet.

Why Option A is picked: It requires zero new code, scales naturally with the battleship's huge 260-HP pool (healing 52 HP per cast), and keeps Spinal cannon special for The Unsetting boss.

Question 3: Main Gun Loadout
How should the battleship step up its firepower over the Eclipse zenith cruiser?

Option A (Recommended — Twin Prow Corona Arcs: 2x Corona arc (prow), 2x Null cannon (turret), 1x Null shredder (turret)): Doubles the cruiser's forward lance burst to 80 raw damage every second turn while keeping two turret Null cannons and upgrading flak to a Null shredder.

Option B (Sustained Null Battery: 1x Corona arc (prow), 3x Null cannon (turret), 1x Null shredder (turret)): Keeps a single prow Corona arc like the cruiser and boss, and adds a third turret Null cannon for steadier every-turn fire in all directions.

Why Option A is picked: Twin forward Corona arcs give the battleship a dramatic visual and tactical identity—lining up its sunshade nose to vaporize an enemy capital ship—that feels distinctly heavier than a cruiser.

Question 4: Fixing the rules15 Battleship Price Multiplier
On branch rules15, the Eclipse cruiser multiplier was raised to 1.65, leaving the battleship multiplier behind at 1.60. How should the builder resolve this?

Option A (Recommended — Raise the rules15 battleship multiplier from 1.60 to 1.70): Restores the clean +0.05 step per hull class (1.55, 1.60, 1.65, 1.70) and prices the CP 6 battleship automatically at 630 credits.

Option B (Set an explicit hardcoded price on the hull line): Leaves the multiplier table alone and types a fixed cost (such as 600 or 630) directly onto the ship entry.

Why Option A is picked: Fixing the multiplier cell in data.js keeps all four Eclipse classes on one consistent formula so future global price tweaks work automatically.

10. Not checked

The following items were outside pack.md and could not be independently verified from source code during this review:

Non-Eclipse weapon stats in data.js: pack.md lists the exact stats for the four Eclipse weapons (gauss, doom, gsentry, flak), and lists the weapon names and arcs for the Bastion (Heavy sear broadside, Oath lance, Spark flak) and Dominion (Heavy plasma lance, Ion cannon, Picket lasers), but does not include the numeric damage, accuracy, or cooldown lines for Crusade and Hegemony weapons. Their expected damage figures in Section 4 are therefore flagged as inferences.

Exact cooldown 2 tick implementation: Whether cooldown 2 on Corona arc fires every 2nd turn (1 recharge turn between shots) or every 3rd turn (2 recharge turns between shots) in the combat loop was not stated in pack.md; both averages are shown in Section 4.

Exact hull fraction restored by Archive restore: pack.md notes that the first fallen Eclipse ship reassembles "at a fraction of its hull" at the start of the next round, without stating the exact percentage in code.

Stale 3D palette line location: Taken on trust from pack.md that data.js:126 still holds the legacy green palette values and has not yet been patched on rules15.
