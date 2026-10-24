# Independent audit: the whole game, nobody prompted this one

Reviewer: Muse. Basis commit: 03e149f. Date: 2026-10-22.

Scope: everything the earlier reviews did not cover. Read whole: campaign3d.js (122 lines), campaign_run.js (321), campaign_meta.js (209), core.js (302), main3d.js (20). Surveyed with counts: data.js (448). Spot-read: the campaign-facing parts of battle.js (enemy fleet generation, encounter tables, regions) and the keyboard handler in ui3d.js. Not a REVIEW_PROTOCOL review: this one mixes verified bugs with a player's opinion, and the two are labelled. Bug quotes were re-checked against the files. Findings from the six earlier reviews (ship pipeline, plain parts, ship loading, battle rules, enemy AI, effects/world, UI) are deliberately not repeated.

## The verdict, as a player

Voidsworn's battle engine is ahead of its campaign. The fight itself has real texture: arcs, facings, rams, boarding, Commands that charge while you hold them, bosses that telegraph. Around it sits a competent Slay the Spire / Hades skeleton (branching map, boons from patrons, relics, Heat) that is thinner than it looks, because several of its systems are either coin flips, reskins, or switched off. The game's most distinctive assets are barely exploited: captains with names and graves, wrecks that remember how they died, six factions with real doctrines, and an enemy that already adapts to your fleet. The best version of this game leans into those four things. Details below, bugs first.

## Part 1: new bugs

### 1. OBSERVED. The retreat confirmation can be bypassed by the keyboard, and a stale "Jump out" can overwrite a finished battle

The battle keyboard handler never checks whether a modal is open:

- ui3d.js:484: `if(!B||e.target.tagName==='INPUT'||document.body.classList.contains('app-on')) return;` and the only overlay check after it is for `.intro`. There is no `.modal` check anywhere in the handler.

The retreat modal (campaign3d.js:94) is the one modal that appears mid-battle, over the canvas. While it is up, Enter still ends the turn, Q/E still turn ships, number keys still arm weapons, X still rams. The battle can run to completion behind the dialog; the end card (z-index 25) renders underneath the modal (z-index 40), so the player may not even see it.

The confirm handler does not revalidate the battle:

- campaign3d.js:95: `ACT.c3retreatYes=()=>{ closeModal(); if(B&&B.campaign) finishBattle('retreat'); };`

It checks neither B.over nor B.busy, unlike ACT.c3continue right above it, which checks both. finishBattle itself (campaign3d.js:65) only guards on B.finished, which the normal end-of-battle flow never sets. So: open the retreat dialog, finish the battle by keyboard, then tap "Jump out". A win is converted into a retreat: no reward flow, no boon, no credits beyond what was already banked, surviving ships still pay the 10% retreat hull tax. A loss with hulls still in the campaign fleet becomes a passed node instead of a run end. Fix: gate the keyboard handler on an open modal, and re-check `!B.over && !B.busy` inside c3retreatYes.

### 2. OBSERVED. The seeded "reload replays the node" promise is only half built, and a mid-battle reload silently eats the node

The design intent is written at the top of campaign3d.js: every fight node gets a seed when the map first shows it, "so a mid-battle reload replays the same fight". The seed half exists (nodeSeeds, campaign3d.js; seeds saved with the run in mapScreen). The replay half does not. Searching all game files, RUN.curNode is only ever set (campaign_run.js:73), cleared by completeNode, and read by the event-fight path. Nothing on the continue path re-enters it.

What actually happens after a mid-battle reload: the saved run has RUN.pos and RUN.curNode on the node, done still false. availableNodes (core.js:297) only offers forward edges from RUN.pos, and ACT.enterNode refuses anything not in that list. The node can never be fought again, never completes, and pays nothing. The player just walks past a dead node. Worse, the reward chain saves mid-flow (ACT.takeSalvage calls saveRun explicitly, campaign_run.js), so a reload during the post-battle reward modals can bank the battle credits and a salvage pick while the node itself never completes.

Event fights have the same hole from the other side: battleScreen skips node seeding when cfg.eventRelic is set, so the one class of campaign battle the seed system was built for is excluded from it.

Fix options: on continue, if RUN.curNode names an unfinished fight node, re-offer it (a "return to the battle" entry on the map, reusing the saved seed). That also closes the reward-chain partial-banking hole, because the node then completes properly through afterBattle.

### 3. OBSERVED. The Legacy and admiral unlock economy is dead code, and the UI still pretends it is alive

- main3d.js:11, at boot: `if(o.unlockAll!==false){ for(const k in LEGACY) META.unlocked[k]=true; for(const k in ADMIRALS) META.admirals[k]=true; }`. Unless a save carries unlockAll set to false, every Legacy unlock and every admiral is granted free at launch.
- ACT.buyLegacy and ACT.buyAdmiral (campaign_meta.js:136-137) have no render site anywhere. The Progression screen's tabs are variants, mastery, favour, heat and fallen; the 12-entry LEGACY table in data.js (war chests, command authority, veteran officers, master shipwrights, salvage protocols) has no shop.
- The fiction of the shop survives in the UI: admiral cards still say "Unlock for {cost} renown in Legacy", and shipyardStock gates the carrier, battleship and dreadnought hulls behind META.unlocked.u_carrier / u_battleship / u_dread, gates the boot code has already opened.

Net effect: renown buys hull variants and nothing else, three shipyard tiers are effectively base content, and the help screen's progression paragraph describes an economy that does not run. This may be a deliberate prototype choice ("everything available from the start" is also in the help text), but right now both designs are present at once and they contradict each other. Pick one: either restore the Legacy tab and stop auto-granting, or delete the costs, the locked card state and the unlock gates so the all-unlocked design is honest.

### 4. OBSERVED. The sector garrison always sends a Voidsworn frigate, whatever faction you are playing

campaign3d.js, battleScreen: `if(RUN.fleet.length<=1&&(RUN.reinf||0)<RUN.sector){ RUN.reinf=RUN.sector; const sh=newShip('warden'); ... }`.

data.js:61 defines warden with `fac:'voidsworn'`. Every other hull grant in the campaign goes through equivHull to map the hull into the player's faction (shipyard stock, event rewards, admiral fleets). This one does not. A Chorus or Deathless player at one hull receives a Voidsworn Warden-class frigate, with a Voidsworn captain name and a Voidsworn ship name, described in the toast as a gift from "the sector garrison". One line to fix: newShip(equivHull('warden', RUN.fac)).

### 5. OBSERVED. Toasts all render in the same spot, so simultaneous toasts hide each other

campaign_meta.js: `function toast(msg){ const t=document.createElement('div'); t.className='toast'; ... }` creates an independent element per call, and the .toast style is a single fixed position (bottom center). There is no container or stacking. finishBattle is the worst case: it can queue the prize toast (300 ms), the escaped-captains toast (1800 ms) and a boon-favour toast on top of each other, and only the last one is readable. A small toast stack (a flex column container, max 3) fixes every case at once.

### 6. INFERRED (latent). changeFleet turns a ship's hull into NaN if the callback ever changes the fleet's size

core.js:179: changeFleet snapshots maxHp by fleet index, runs the callback, then walks the (possibly different) fleet by the same indexes, adjusting hp by the delta. If the callback adds a ship, the new ship's before-value is undefined, the delta is NaN, and clamp(NaN) is NaN, so that ship's saved hp becomes NaN permanently. No current caller grows the fleet inside changeFleet (checked takeBoon, takeRelic, pickAspect and the event relic path), so this is a trap, not a live bug. It is exactly the kind of trap that gets stepped on the first time someone writes changeFleet(()=>{ RUN.fleet.push(...) }). Reason given, per protocol habit: the arithmetic above is read directly from clamp and changeFleet; the "no live caller" half is from reading every changeFleet call site found by search.

### 7. OBSERVED (minor). The title-screen showcase can field a mirror match with duplicate ship names

campaign3d.js, setupShowcase: the player and enemy factions are drawn independently (`pf` and `ef` are separate random picks from PLAYABLE), so the attract battle can be a faction fighting itself. Ship names come from per-faction pools, and nothing dedupes names across the two fleets in a showcase, so the title screen can show two ships with the same name shooting each other. Cosmetic only, but it is the first thing a new player sees. Excluding ef===pf costs one line.

## Part 2: the game as a player

### What already sings

- **Commands that charge while held.** A once-per-battle fleet move that grows from round 1 to round 3, and charges faster when you lose a ship, is a genuinely good decision engine. Few tactics games make "not yet" this tense.
- **Captains who can die twice.** The lifepod system (60% of dead captains escape, wounded, and take your next hull) plus the Hall of the Fallen gives losses a story instead of a spreadsheet. This is the game's heart. It is also underused; see proposal 4.
- **Salvage with a memory.** Wrecks know what killed them (flayed and dissolved wrecks yield less; a lance kill yields a lance crystal) and Corsairs can tow small hulls home. That is Starsector-grade flavor, already working.
- **An enemy that adapts.** genEnemyFleet reshapes itself around archetypes, and startBattle bolts point defense onto enemy hulls when you bring carriers, with a scout report in the log telling you it happened. The player is told the game is watching. Almost nothing else in the genre does this outside Starsector's bounty fleets.
- **The map shows its work.** Encounter type, archetype, node reward sigil, terrain and sector condition are all visible before you commit to a route. Into the Breach taught the genre that shown information beats hidden dice; Voidsworn already believes it.

### Where it thins out

**Content census** (counted from data.js and battle.js at this commit): 34 hulls and 12 variants, 25 weapons, 37 boons (about 6 per patron, plus 6 duos), 12 relics, 13 refit modules, 14 captain perks, 6 flagship aspects, 24 admirals, 8 encounter types, 12 board shapes, 5 regions, 5 sector conditions, 7 Heat rules, 3 fleet archetypes, 2 node modifiers, 11 events. A run visits roughly 15 to 18 fight nodes and 2 to 4 event nodes. The battle-facing pools (hulls, boons, encounters) are deep enough. The campaign-facing pools are not: 11 events with a no-repeat rule inside a run means a second run shows you the whole deck; 3 archetypes and 2 node modifiers means the map's texture repeats within one sector; 5 sector conditions, never repeated within a run, means the third run has seen every sky the game can paint.

**Events are coin flips wearing costumes.** applyOutcome (campaign_run.js) resolves nearly every event outcome with a flat rnd(): board the derelict and win a module 60% of the time, or take 25% hull damage. Your fleet's composition never changes the odds or opens an option. FTL's blue options and Crying Suns' officer-gated choices are the genre standard here, and Crying Suns is carried by exactly this layer (its reviews praise the story and officers, and pan its combat; Voidsworn has the opposite profile, strong combat and thin events, which makes the fix cheaper: the hard half is done).

**There is no on-ramp and no relief valve.** AI_LEVEL defaults to veteran, the settings toggle is the only difficulty control, and Heat (the game's own difficulty ladder) is locked until after your first victory. A new player who bounces off veteran AI has nowhere to go but away. FTL ships an Easy mode; Void War ships a named difficulty ladder (Torment) that players climb voluntarily and brag about. Difficulty as identity works better than difficulty as a settings row.

**Every faction plays the same campaign.** Factions have real battle doctrines (each bends a thruster rule), faction-flavored module and relic names, and their own run word (crusade, raid, hunt, voyage, reclamation). But on the map, a Corsair raid and a Voidsworn crusade are the same nodes paying the same rewards. The one exception proves the appetite: towing wrecks home is Corsair-only, and it is the most faction-flavored moment in the campaign. Six factions deserve six campaign verbs (proposal 3).

**Wings risk the Crying Suns critique.** Carriers launch automatically, wings choose their own targets, and player orders are two sticky modes (strike this, guard that). The most common complaint about Crying Suns' combat is that squadrons degenerate into spam you watch rather than tactics you play. Voidsworn's wings are better (they have real orders and the strike/guard choice matters), but the next step is doctrines and veterancy, not more wings (proposal 5).

**There is no sound of space.** The SFX layer is synthesized effects; a search of the game files finds no music system at all. Space opera lives on its score. Reviewers of Void War, the closest aesthetic competitor (gothic FTL, 91% positive on Steam, June 2025), single out its synth-industrial score by name. Voidsworn's battles deserve the same dread (proposal 10).

**Nothing to do with a won run but start another.** No seeded challenges, no daily, no shareable skirmish seed, no codex, no way to look at the 36 hand-built hulls outside a fight. The telemetry and seed infrastructure to support all of these already exists; what is missing is the surface.

## Part 3: proposals (ambitious, on theme)

### 1. The Nemesis: one rival admiral per run, who learns

At run start, draw a named enemy admiral from the three foe factions. They appear on the map screen ("Auspex has a name for the raids in this sector: ..."). Their fleet ambushes you once per sector (the ambush event machinery and rival-raider node factions already exist), each time built by genEnemyFleet with an adaptation pointed at your last battle: if you won with torpedoes, they bring flak; if you rammed, they bring screens (B.adapt already computes exactly this kind of answer for carriers; extend it). In sector 3 they command the flagship, with a BOSS_CMD themed to their faction and one line of dialogue per phase. Kill them in sector 1 and their second-in-command takes over, angrier and worse-equipped. Why it works: Battlestar's Cylons and Shadow of Mordor's nemesis system both prove that a recurring, adapting enemy converts random battles into a feud. The game already tracks how you fight (B.usage counts rams, boardings, captures per battle in telemetry). This is the single highest-value addition in this document.

### 2. Events with blue options, and event arcs

Two moves. First, gate event choices on what you brought: a choice unlocked by a captain perk ("Your engineer captain can vent the reactor safely"), a module ("The lance crystal sings back"), a boon, a faction, or a flagship aspect, with better odds or a better outcome, shown in the patron's color like FTL's blue text. applyOutcome already special-cases a few outcomes; the data shape only needs an optional requires field checked in eventScreen. Second, grow the pool from 11 toward 30+, and chain a few into arcs across sectors: the seer who takes a refit in sector 1 returns in sector 3 to collect or repay; the escaped captain from a lifepod (the reserve system) can be the distressed officer in someone else's event. Events are the cheapest content in the game to write (data rows, no art) and currently the fastest to exhaust.

### 3. A campaign verb per faction

One rule each, applied at the map layer, named on the admiral screen like the doctrines are:

- **Voidsworn, Vow:** sanctify one node per sector before entering; winning there pays a second reward (a relic choice at elites).
- **Hegemony, Requisition:** once per sector, buy from any shipyard's stock at a 25% markup without visiting it. Logistics as identity.
- **Corsair, Raid:** skip the salvage choice and take both the module and the scrap from one wreck per battle; you are already the faction that tows hulls home.
- **Chorus, Infest:** consume a battle node without fighting it; it becomes a field-repairs node at half strength. The swarm eats the sector.
- **Ithar, Foresight:** event nodes and node rewards are revealed one column further than other factions see. The Veil sees ahead.
- **Deathless, Raise:** once per sector, raise one of your own wrecks from the last battle as a ship at 50% hull with its captain already dead and gone (the ship flies; nobody is home; it cannot gain XP). The Dynasty does not waste hulls.

Each is a small hook into systems that exist (salvageYield already special-cases Corsair; node rewards already roll in mapScreen). Together they make the faction pick a campaign decision, not just a roster swap.

### 4. Scars, legends, and careers

Captains already have names, ranks, perks, graves and a 60% chance of a lifepod. Finish the job:

- **Scars:** a ship that ends a battle under 25% hull, or a captain who escapes a wreck, gains a scar quirk drawn from a paired list (one gift, one flaw: "+10 aim, -1 speed: she sees the shot coming and hates to run"). Starsector's d-mods and Battle Brothers' permanent injuries are the proof this creates attachment.
- **Legends:** when a run is won, its surviving captains retire into the Hall beside the Fallen. In later runs they can surface: as the veteran who commands a prize ship, as a rival captain in the Nemesis's fleet (fighting your own legend is a gut-punch no other game offers), or as the officer in an event. META.fallen already persists across runs; a legends list is the same shape.
- **Service records:** the run recap already computes per-ship damage and kills. Persist a one-line record per captain across runs (battles, kills, runs survived) and show it on the captain's card. Players protect ships with histories.

### 5. Wing doctrines and veteran wings

Give each carrier three wing stances, set per battle and changeable per round: Screen (wings stay close, intercept enemy craft and torpedoes first), Strike (current behavior), and Hunt (wings range ahead and pick crippled targets). Wings that survive battles gain veterancy like captains do, one perk per run of battles, chosen from a small wing list (extra strike damage, one free re-launch, kamikaze on death for Chorus). This answers the genre's squadron-spam critique with control and investment instead of more micromanagement, and it makes the carrier admirals (Ashgrove, Reyes, Mott, Aelith) feel different from each other.

### 6. Salvo warfare: torpedoes that travel, mines, and sensor ghosts

Three battle mechanics, all space-opera native:

- **Torpedo flight time.** Torpedoes launched this round arrive at the start of your next round, tracking the target's hex, dodgeable by moving 3+ hexes (the evasion rule already rewards moving 3+). The salvo cloud is visible and telegraphed, Into the Breach style: the danger is known, the answer is maneuver. This makes speed and thruster rules matter offensively, not just for arcs.
- **Minefields.** A module (and a Chorus spore variant) that seeds two mine hexes at deployment; mines are hidden from the enemy AI's pathing only if the layer's auspex is low, visible to the player always. Terrain that players author is the difference between a board and a battlefield.
- **Sensor ghosts.** In nebula and storm maps (and against Ithar), enemy ships leave a ghost marker at their last sensed position and are targeted at the ghost with an aim penalty until re-acquired by proximity or auspex modules. The Expanse and every submarine film ever made run on this tension; no hex tactics game I know uses it. Even a light version (ghosts only in storm maps) would be a signature.

### 7. Flagships that come apart

Bosses are already built from the biggest hull plus an escort budget, and every ship in the game already has prow, midships and engine sections with their own damage states (crits target sections today). Make the sector flagship a scripted multi-phase fight: at 66% it sheds its engine section as a burning hulk that becomes terrain and gains speed; at 33% the Deathless flagship reassembles its escort wrecks into a screen, the Chorus flagship births a brood it should not have, the Hegemony flagship calls its reserve wing. One bespoke phase per faction, telegraphed a round ahead like BOSS_CMD already telegraphs. Boss fights are the run's punctuation; right now all six end the same way.

### 8. The Drydock Gallery and a photo mode

The project has 36 hand-built hulls, faction paint schemes and a showcase mode that already flies your fleet in formation behind the map. Turn that inward: a gallery on the title screen where any hull can be orbited, in any faction's paint, with its class line, weapons and one paragraph of lore (faction blurbs and hull names already carry the voice). Add a photo mode in battle (hide UI, free camera, one key) next to it. The dev-side artshot tooling proves screenshots are how this game gets judged and shared; give players the same camera the builder uses. This is also the cheapest proposal here relative to visible payoff.

### 9. Seeds, dailies, and a ladder with a name

B.seed already makes a battle replayable, node seeds already make a run's fights deterministic, and the copy-report flow already serializes a run's state. Surface it: (a) a daily seeded run (same map seed and patrons for everyone that day, runRenown as the score, best-of shown on the title screen), (b) shareable skirmish codes (faction, setup and seed in one string, pasted like the Claude report), (c) rename and extend Heat into a 10-step named ladder in the Void War Torment style, unlocked step by step per faction with the existing heatBest tracking as its spine. Retention in this genre is competitive seeds and visible ladders; the plumbing is done.

### 10. Patron miracles and a synth score

Two presence upgrades. First, patrons are gods who currently only hand out passive percentages. Give each patron one active miracle, usable once per run from the Command slot's neighborhood: the Ember Throne restarts every fire on the field at double strength; the Pale Saint returns one ship lost this battle at 1 hull for one round, long enough to matter. A god intervening visibly, once, is worth ten +8% boons for theme. Second, a generative synth score through the existing WebAudio SFX engine: a low drone layer on the map, a pulse layer in battle that thickens when B.cmd charges and when the flagship phase breaks. Adaptive music is a solved pattern (the docs/skills folder already carries an adaptive-music reference); even three loops and a stinger would change how the game feels on a phone speaker.

### 11. Run shape options

Offer, on the admiral screen: the standard three-sector crusade, an Expedition (two sectors, faster rewards, less renown), and a Gauntlet (one sector, Heat pre-loaded, double renown). Add a starting difficulty beside AI_LEVEL (Cadet: enemy budget x0.85 and standard AI; Admiral: as today; Voidsworn: budget x1.12 and veteran). Both are presentation over existing knobs (genEnemyFleet's budget line, the sector count in endRun's win check), and they fix the on-ramp problem in Part 2 without touching balance for veterans.

## If I could only ship five

1. **The Nemesis** (proposal 1). Identity, narrative and difficulty adaptation in one system, built from parts that exist.
2. **Event blue options plus 20 more events** (proposal 2). Cheapest content, biggest replay gap, genre-proven.
3. **Faction campaign verbs** (proposal 3). Six small hooks that make the biggest choice in the game (your faction) mean something between battles.
4. **Wing doctrines** (proposal 5). Fixes the one combat system reviewers of the closest cousin pan, and deepens four admirals at once.
5. **The two reload bugs and the retreat modal** (Part 1, findings 1 and 2). Not glamorous; they are the findings in this audit that can eat a player's victory or their node, and trust is the currency everything above spends.

Runners-up: torpedo flight time (proposal 6) is the most original battle idea here and the one I would prototype first in a skirmish; the gallery (proposal 8) is the one the hull pipeline has already earned.

## Not checked

sfx.js internals (the no-music finding is from a whole-repo search for a music system, not a read of the synth engine); sim-only balance numbers (boss scale tables were read as constants, not re-simulated); the built voidsworn-3d.html against these sources; phone performance of any proposal; whether the unlockAll auto-grant is a deliberate shipping decision (flagged as a contradiction in the code as written, not ascertainable from the repo alone).
