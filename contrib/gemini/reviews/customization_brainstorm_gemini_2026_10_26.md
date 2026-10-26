# Ship customization brainstorm, Gemini Argon leg, 2026-10-26

Chair header: filed as the single reviews copy for the Gemini leg (house pattern). Model: Gemini 4 Argon, Thinking level High, verified in two places before submitting (the prompt bar mode picker button read "Argon High"; the opened picker showed "Selected 4 Argon Complex tasks" and Thinking level "Selected High Extra thorough"; the model had initially been set to Low and was changed to High before sending). Ran 2:33-2:40 PM PDT (runtime measured). Fresh Gemini chat, signed in as Ryan Bailey (rcbailey12@gmail.com), Pro. Two files attached via Upload files (leg_prompt_customization.md, evidence_pack_customization.md). No rate limit message appeared before sending and no fallback model was used. Citation chips shown by the Gemini interface are interface elements, not model text, and are omitted. Model text follows verbatim.

---

1. CANDIDATE VERDICTS

A. Authored Hull Variants: PRIMARY
Authored variants work like Type A, B, and C ship layouts in FTL: Faster Than Light (Subset Games): they give a familiar hull a distinct tactical role without opening a part-by-part garage screen for every escort in the fleet. On feel, variants alone only lightly scratch the BattleTech (Harebrained Schemes, 2018) mech bay itch because the player chooses a finished blueprint rather than wrenching on parts, which is why variants need a flagship partner. On fun, variants put decision weight into fleet drafting, capture choices, and faction arc unlocks with zero pre-battle spreadsheet time. On balance cost, each variant is a static row that plugs directly into the 19,500-battle simulation harness, keeping the 57 to 98 percent admiral win-rate bounds measurable. On build cost, variant rows with cost and faction arc unlock fields are already in the project plans for the story audit trigger, need no dynamic turret sockets across 45 hulls, require no enemy AI rewrite, and feed cleanly into Nemesis weapon-kind adaptation.

B. Dock Refits with a Clock Cost: SECONDARY
Charging credits and Nemesis clock time at shipyard nodes works best as the economic wrapper around flagship customization rather than a fleet-wide refit loop. It borrows the best tension from Yang's MechBay work-order timer in BattleTech (Harebrained Schemes, 2018) and the shipworks repair clock in HighFleet (Konstantin Koshutin), where time spent re-engineering a hull lets enemy strike groups close in. On feel, paying credits and advancing the 4-win Nemesis clock makes a major weapon swap feel like heavy drydock work instead of a free menu toggle. On fun, weighing a pod swap against an earlier Nemesis strike (and another +10 percent flagship scar multiplier) adds real route-planning weight at shipyard nodes, provided it is restricted to the flagship so players do not micromanage pods across ten ships. On balance cost, the clock penalty prevents free counter-picking right before bosses. On build cost, shipyard nodes, modules, and the Nemesis clock already exist, so this only needs a shipyard UI trigger and a Nemesis counter increment.

C. Flagship-Only Layered Customization: PRIMARY
Concentrating a swappable weapon pod, module slot, and section tuning on the single ship present in every battle mirrors the personal voidship in Warhammer 40,000: Rogue Trader (Owlcat Games) and the Kapisi carrier in Homeworld: Deserts of Kharak (Blackbird Interactive). On feel, it directly scratches the BattleTech mech bay itch because the flagship already carries the admiral, Command abilities, persistent scars, Hegemony formation sync, and the Nemesis duel multiplier, making it the player's command mech on the board. On fun, it honors the standing rule to favor per-activation decision weight over fleet size: customizing one centerpiece transforms how your fleet anchors a fight without multiplying pre-battle menu chores across ten hulls. On balance cost, limiting deep customization to one ship out of roughly twenty on the board bounds the math so the simulation harness only has to test a few flagship configurations per admiral. On build cost, visual hardpoint sockets and deep dock UI only need to exist for flagship hulls, enemy AI only evaluates one modified target, and Nemesis adaptation tracks weapon kinds normally.

D. Section Tuning for Every Ship: REJECT (as a fleet-wide system; fold into C for the flagship only)
Shifting fixed points between prow, mid, and engine on every ship in the fleet tries to copy per-location armor allocation from BattleTech (Harebrained Schemes, 2018) and flux vent/capacitor sliders from Starsector (Fractal Softworks), but fails the scale test of a 20-ship board. On feel, sliding abstract stat bars on ten escort hulls without changing weapons or silhouettes feels like adjusting an audio equalizer, not running a mech bay. On fun, reversible dock sliders across an entire fleet create pure pre-battle spreadsheet maintenance, where optimal play nags the player to shift points into prow armor before a brawl and into engines before a chase at every shipyard. On balance cost, letting every hull shift durability and speed blurs faction hull grammar across 45 ships and undermines baseline simulation data by letting players tune out intended hull weaknesses. On build cost, while it skips 3D mount art, it requires per-instance stat serialization and tuning UI across every fleet slot for very low dramatic payoff.

E. Full Open Hardpoint Lab: REJECT
A literal BattleTech (Harebrained Schemes, 2018) MechLab or Starsector (Fractal Softworks) open refit screen works when you command four mechs or play an open-ended sandbox, but it clashes with a brisk turn-based fleet roguelite where roughly twenty ships share the board. On feel, stripping hull-locked weapons destroys the personality of the 45 hulls and erases the six factions' visual and mechanical weapon grammar. On fun, open hardpoints across a growing fleet create severe refit fatigue between battles and reduce ships to generic tonnage frames holding whichever of the 25 weapons has the best math efficiency. On balance cost, it breaks the 19,500-battle simulation process: free-form combinations across 45 hulls and 25 weapons cannot be exhaustively simmed, and min-maxed boats (like classic all-laser or all-LRM spam in BattleTech) would blow past the 57 to 98 percent admiral win-rate guardrails. On build cost, it is the heaviest option in every category, requiring universal weapon sockets across 45 meshes, complex drag-and-drop UI, dynamic AI threat scoring, and a rewrite of capture and Nemesis adaptation rules.

2. THE CENTRAL QUESTION

Answer: Yes, with one condition. Flagship-only layered customization (Candidate C) does enough of the mech bay job on its own, on the condition that line ships still offer selection-level variety through Authored Hull Variants (Candidate A) and their existing single module/refit slot. The player needs to feel like they are engineering their flagship while curating their fleet.

Where one customized centerpiece carried the fantasy:
In Warhammer 40,000: Rogue Trader (Owlcat Games), space battles are strictly turn-based with a small fleet, and all deep customization lives on the player's single flagship. The player swaps prow, dorsal, port, and starboard weapon batteries, upgrades void shields, plasma drives, and armor plating, and assigns officers to Bridge Posts for active ship abilities, while the escort frigate unlocked through colony projects has fixed weapons and zero hardpoint tinkering. The player feels intense personal attachment and spatial mastery: because every upgrade, scar, and officer ability rides on that one hull, you know its exact turn arc, shield strength, and broadside timing by heart, and every hit it takes feels personal. A second verified example is Homeworld: Deserts of Kharak (Blackbird Interactive), where the expedition carrier Kapisi is the only unit with persistent power-grid tuning (shifting points between armor, weapon range, speed, and repair systems) and artifact slots, while all escort cruisers and strike craft have fixed roles. The player feels like a fleet commander operating a mobile flagship fortress whose custom loadout sets the doctrine for the whole battle group.

Where fleet-wide tinkering was the point (and what happens when it scales up):
In BattleTech (Harebrained Schemes, 2018), concentrating customization on the commander's personal mech alone would fail because the player only deploys a lance of four mechs total, and salvaging partial mech chassis and replacement weapons after permanent limb destruction is the core campaign loop. With only four units on the field, the player feels like a chief mechanic building an interlocking four-piece puzzle, where converting a Hunchback from an autocannon brawler into a laser boat changes what the other three mechs need to carry. However, when that same fleet-wide hardpoint tinkering scales up to a 10 to 20 ship fleet in Starsector (Fractal Softworks), the player experience shifts from intimate garage craft to administrative chore: players love hand-tuning their personal flagship, but assigning vents, capacitors, hullmods, and small mounts on their eighth escort destroyer feels like tax preparation (which is why Starsector had to build an autofit preset system). Similarly, in Battlestar Galactica Deadlock (Black Lab Games), where players command seven ships in turn-based battles, hulls keep fixed gun batteries and only swap a munition and squadron slot; keeping escort choices down to a single slot prevents hangar burnout between turns.

Why the condition matters for Voidsworn:
Because Voidsworn has soft, temporary critical hits rather than permanent limb loss, and fields roughly twenty ships on the board, it does not need a four-mech salvage repair bay. Giving the flagship deep layered tinkering (Candidate C) satisfies the hands-on BattleTech and Rogue Trader attachment fantasy, while giving line ships 1 to 2 Authored Hull Variants (Candidate A) ensures that drafting or capturing a second frigate in Sector 2 still feels fresh without forcing the player into a ten-ship spreadsheet.

3. INTERACTION RISKS

For the top-ranked hybrid (Flagship Layered Customization [C] + Authored Hull Variants [A] + Shipyard Clock Cost [B]), these are the three worst interactions with existing systems:

Flagship Pod Swapping vs. Nemesis Weapon-Kind Adaptation and Flagship Duels

The Interaction: The Nemesis adapts to the player's most used weapon kind every 4 wins (base interval), gains scars (+10 percent flagship damage each), and can trigger a Nemesis challenge mode that is a flagship duel with a damage multiplier. A player could fire lances all run so the Nemesis adapts to lances, then duck into a shipyard node right before the Nemesis duel and swap the flagship's weapon pod to torps or gauss, nullifying the Nemesis's adaptation in the 1v1 duel.

Verdict: Paper problem in standard 20-ship battles; real problem in the Nemesis flagship duel. In a full fleet battle, swapping one pod on one ship out of ten player hulls will not overturn fleet-wide weapon usage stats. In a 1v1 flagship duel, it completely bypasses the Nemesis's core counter-mechanic.

Cheapest Guardrail: Make any flagship weapon pod swap at a shipyard tick the Nemesis clock by +1 win-equivalent (Candidate B) and refresh the Nemesis's adaptation check so that in flagship challenge duels, the Nemesis adapts to the flagship's currently mounted weapon kinds if they out-damage the fleet average.

Flagship Pod & Section Tuning vs. Faction Identity and Named Loss Conditions

The Interaction: The six factions rely on strict visual and mechanical rules, weapon traits (like Hegemony's light-blue plasma), and named loss conditions (Hegemony loses formation sync without its flagship; Chorus cannot repair; Ithar cannot Brace; Deathless has no shields), while 24 admirals ride the flagship. If section tuning or pod swaps let a Hegemony flagship stack enough prow/mid armor to become unkillable (erasing the formation-sync loss risk), or let Deathless gain shield stats, or let non-Hegemony ships mount blue plasma pods, faction and admiral identity collapse into one generic meta build.

Verdict: Real problem. In BattleTech (2018), unrestricted hardpoints caused most mechs in the same weight bracket to converge on identical medium-laser and SRM loadouts.

Cheapest Guardrail: Hard-lock flagship weapon pods to the flagship's native faction weapon pool (3 authored pods per flagship hull) and hard-code faction loss rules above tuning: Deathless section tuning only shifts hull/armor/speed (never shields), Chorus tuning never grants repair, and section tuning uses four fixed, zero-sum stances capped at +/-15 to 20 percent so a flagship cannot change weight class.

Authored Variants & Flagship Pods vs. The Capture Economy (Strip and Ransom) and Ship-Count Ramp

The Interaction: As difficulty ramps toward roughly twenty ships on the board, the player captures enemy ships under the strip-and-ransom rule: a captured ship joins the fleet if a slot is open, or auto-scraps for credits/materials if the fleet is full. If enemy ships spawn with variant loadouts or modules and the player expects to strip specific weapon pods off captured hulls into a parts inventory, strip-and-ransom bloats into a BattleTech salvage warehouse, slowing down post-battle flow.

Verdict: Paper problem if weapon pods are shipyard-fabricated; real problem if loose weapon salvage is added.

Cheapest Guardrail: Never create a loose weapon inventory. When a player captures an enemy Authored Variant with an open fleet slot, it joins the roster as that intact variant hull row. When the fleet is maxed, strip-and-ransom auto-scraps it for standard credits/materials (plus a flat +15 percent scrap bonus for variant hulls). Flagship weapon pods are built directly at shipyard nodes for credits, never looted as loose items.

4. YOUR HYBRID

Proposal: The Command Berth & Variant System (Hybrid of C + A + B)

This system concentrates all multi-layered garage tinkering on the Flagship (Candidate C), uses Shipyard credits and Nemesis clock ticks as the pacing cost (Candidate B), and handles the rest of the fleet purely through Authored Hull Variants (Candidate A) and existing single-slot modules/refits.

1. What Can Be Swapped and On Which Ships

The Flagship (1 ship per run): The Command Berth (3 Layers)

Layer 1: Dorsal Weapon Pod (1 Slot, 3 Authored Options per Flagship Hull). Swaps the flagship's secondary weapon battery between three faction-legal weapon kinds. Example for a Hegemony flagship: Pod A (Plasma Battery) for close broadsides; Pod B (Ion Lance) for long-range shield stripping; Pod C (Flak & Interceptor Bay) for anti-torp and anti-squadron screening. The flagship's primary spinal weapon stays fixed to the hull.

Layer 2: Section Trim (Prow / Mid / Engine Allocation via 4 Discrete Stances). Instead of granular 1-point sliders, the player chooses one of four structural trims for the flagship's three sections (prow, mid, engine):

Balanced Trim (Default): Base stats across prow, mid, and engine.

Armored Prow: +20 percent Prow HP and Prow weapons resist the first 2-round weapon-off critical hit each battle; -1 Engine speed.

Reinforced Midsection: +20 percent Mid HP and +15 percent max shield capacity (or +25 percent Mid HP for shieldless Deathless hulls); -15 percent Prow weapon charge rate.

Overdriven Engine: +1 Engine speed and halves the duration of temporary Engine slow criticals (from 2 rounds to 1 round); -15 percent Prow and Mid HP.

Layer 3: Command & Ship Modules (2 Slots) + Campaign Refits. The flagship holds 1 standard ship Module, 1 Flagship-only Command Module (which modifies the Admiral's Command ability or formation aura), and any campaign map Refits applied to it.

Fleet Line Ships (All Other Ships in the Roster): Blueprint Selection Only

Each of the 45 hulls has its Base Hull plus 1 to 2 Authored Variants (unlocked via faction arcs) that swap one weapon kind and trade one stat as a fixed package.

Inside a run, a line ship only has its 1 existing Module slot and any campaign Refit earned on map nodes.

2. Where and When Swaps Happen

Pre-Run Hangar (Run Start): The player picks their Admiral and chooses between the Base Flagship or an unlocked Authored Flagship Variant. It starts in Balanced Trim with its default Weapon Pod.

Shipyard Map Nodes Only (During a Run): Changing the Flagship Weapon Pod, shifting the Flagship Section Trim, or converting a base line ship into its unlocked Authored Variant can only be done at Shipyard nodes on the campaign map.

Campaign Map (Between Nodes): Swapping equipped Modules into or out of a ship's module slot can be done on the campaign map between battles without a shipyard.

3. What It Costs (Credits, Clock, Opportunity)

Flagship Weapon Pod Swap (at Shipyard): Costs Credits (medium-high dock fee) AND advances the Nemesis Clock by +1 win. If the Nemesis clock is 1 tick away from triggering, re-gunning the flagship triggers the Nemesis ambush as soon as the fleet undocks.

Flagship Section Trim Change (at Shipyard): Costs a small Credit fee (or is free when paired with a hull repair) and 0 Nemesis Clock ticks. Keeping trim adjustments off the Nemesis clock encourages players to actively tune their prow, mid, and engine before boss fights.

Line-Ship Variant Conversion (at Shipyard): Unlocking the blueprint is a meta-progression cost via Faction Arcs. In a run, refitting a base line ship into its Authored Variant at a Shipyard costs Credits and Opportunity Cost (using your shipyard visit budget instead of repairing hull or buying a module), with 0 Nemesis Clock ticks.

4. What Is Explicitly NOT Swappable

No weapon pod swaps or section trims on non-flagship hulls: The other ships in your fleet never open a hardpoint or trim screen; their hull or variant row is their loadout.

No spinal/signature weapon removal on the flagship: Every flagship retains its core hull weapon so its visual silhouette and primary firing animation stay recognizable.

No cross-faction weapon pods or negated faction loss conditions: You cannot mount Hegemony plasma on an Ithar hull or tune shields onto a Deathless hull.

No loose weapon salvage inventory: Captured ships either join the fleet as their hull/variant row or auto-scrap for credits and materials.

5. SEQUENCING

Must Be Decided or Reserved NOW (During Godot 4.7 Migration, Before Cutover)

Separate ShipInstance State from Static HullDef Lookups in Saves and Battle State: When migrating fleet state and save serialization to Godot 4.7, ensure every ship in a player or enemy fleet is stored as an instance struct (instance_id, hull_id, pod_override_id, section_trim_id, modules[], refits[], scars[]) rather than resolving weapons and section HP by querying a static hull_id row directly during combat. Adding two nullable fields (pod_override_id, section_trim_id) to the instance struct now costs almost nothing; refactoring battle code that assumes hull_id == weapon_list after cutover touches every combat, tooltip, and save file.

Variant Row Schema with base_hull_id, cost, and faction_arc_unlock: Because a story audit trigger already waits on variant rows existing in the data with cost and faction_arc_unlock fields, add a base_hull_id reference to the hull data schema now so authored variants can inherit the parent hull's 3D prefab, section hitboxes, and audio cues without duplicating Godot scene files.

One Standardized Mount_Pod_Dorsal Node3D Socket on Flagship Prefabs Only: As the 6 faction flagship hulls are set up as Godot .tscn scenes, drop one named Node3D/Marker3D child node (Mount_Pod_Dorsal) on each flagship mesh. Do not spend time rigging dynamic hardpoint sockets on the other 39 line-ship meshes.

Headless Simulation Runner Override Argument: Allow the bot simulation harness (used for the 19,500-battle baseline) to accept a flagship pod_override_id and section_trim_id alongside the admiral pick so future flagship builds can be batch-simmed as distinct rows.

Can Safely Wait Until After Cutover (With Zero Loss)

All Command Berth UI and Shipyard Customization Menus: The visual UI for swapping flagship pods and toggling the 4 section trims can wait until post-cutover.

Pod Definitions, Trim Percentages, and Variant Stat Balancing: Authoring the exact 3 pods per flagship and balancing the 4 section trim numbers is pure data work after Godot 4.7 cutover is stable.

3D Pod Sub-Meshes: Even after the feature launches, swapped flagship pods can fire from the reserved Mount_Pod_Dorsal marker using existing weapon VFX before dedicated 3D turret meshes are modeled.

Nemesis Clock Tick Hook on Shipyard Pod Swaps: Adding +1 to the Nemesis win counter on pod purchase and updating the flagship duel adaptation check is a localized post-cutover campaign script update.

Overall Verdict

Once the already-planned Authored Hull Variant data rows (Candidate A) are in place for the story audit trigger, the single customization addition I would build first is Flagship-Only Layered Customization (Candidate C) bounded by four discrete section trims, three faction-legal weapon pods, and a Shipyard Nemesis clock cost (Candidate B). It delivers the tactile BattleTech mech bay and Rogue Trader command-ship fantasy on the one hull that carries your admiral, your scars, and your Nemesis rivalry, while keeping the simulation harness intact and adding zero menu bloat to the rest of your roster. The one addition I would never make is the Full Open Hardpoint Lab across the fleet (Candidate E), because opening every weapon mount on a 20-ship board turns distinct faction warships into interchangeable stat frames, breaks simulation-led balance, and buries a sharp turn-based tactics game under pre-battle spreadsheet maintenance.
