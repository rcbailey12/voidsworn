# VOIDSWORN - FIRST-TEN-MINUTES ONBOARDING LENS

Model: Qwen3.8-Max, Thinking ON, Web search OFF. Filed verbatim from the Qwen chat report; em dashes normalized to hyphens, wording otherwise unchanged.

Method note. Everything marked OBSERVED is directly in the three granted files, with the file and the function or constant named. Everything marked INFERRED is my reasoning from that code (player behavior, difficulty, likelihood of confusion). I did not invent a start screen, tutorial, or flow the files don't show; anything I could not establish is listed under Not specified at the end. Per the brief, fixes target PC-only, preserve per-activation decision weight, and treat all vessels as spaceships.

A framing caveat that shapes the whole lens: the granted files contain two observable on-ramps. The only fully-visible cold open is the skirmish setup (showIntro, ui3d.js). The roguelite loop the brief asks about - map -> battle -> rewards - is visible from the sector map onward (mapScreen, enterNode, startBattle, rewardFlow), but the title screen and run-creation that lead into it are referenced and not defined in these files (titleScreen is called in campaign_run.js ACT.saveQuit; c3title/c3continue/changeSetup are called in ui3d.js). I therefore reconstruct the campaign path as the intended first ten minutes (it has the "first map" and "first rewards" the brief names), and flag the skirmish intro wherever it is the literal first thing a player can see.

## DELIVERABLE 1 - THE RECONSTRUCTED FIRST TEN MINUTES

### Step 0 - Cold open (minute 0:00-0:30)

- What they see: OBSERVED (ui3d.js showIntro): a panel titled "Voidsworn / 3D skirmish". Nine rows of pickers: Your fleet and Opponent (six factions each from PLAYABLE: voidsworn, hegemony, corsair, chorus, ithar, deathless), Engagement (Skirmish / Flagship battle), Battlefield, Deployment, Encounter (eight objectives from OBJS), Arena, Board, and Turn order (Alternating / Classic). A "Begin engagement" button. A one-line controls hint at the bottom.
- What they pick: OBSERVED (SETUP defaults, ui3d.js): if the player touches nothing, the game starts as voidsworn vs hegemony, Skirmish, Random map, Line deployment, Engagement (rout), Random arena/shape, Alternating turn order. Each faction shows a one-sentence blurb (blurb(f) reads FACTIONS[f].blurb).
- INFERRED: The campaign entry is a different, unshown flow. showIntro is labelled "3D skirmish," and its battle ends on a stats card with no rewards (OBSERVED ui3d.js endBattleFlow: buttons are "Fight again / Change factions / Main menu"). The roguelite reward loop lives in campaign_run.js and is only reached through the campaign. So a brand-new player who enters via the visible intro plays skirmish and never sees the map or rewards in their first session.

### Step 1 - The sector map (minute 0:30-2:00, campaign path)

- What they see: OBSERVED (campaign_run.js mapScreen): a header "Sector I : [Region]", a "Hostile presence" line naming the faction with a one-line blurb, an optional "Sector condition" line, then an SVG node map with a legend of seven node types (NODE_INFO: Battle, Elite fleet, Shipyard, Drydock, Field repairs, Unknown signal, Sector flagship). Below the map, an encounter-preview list (encprev) showing each available node's encounter name, description (ENCOUNTERS[...].d), archetype, modifier, and reward.
- The sidebar is dense: Credits, Command points (fleetCP()/RUN.cpCap), Admiral name + doctrine, the Fleet (per ship: name, hull, class, Mk, captain rank/name, "promotion ready"), a fleet-management button, refits in the hold, a Flagship aspect block, a Boons block, a "Patrons this run" line, and a Relics block.
- The one sentence of instruction: OBSERVED bottom hint: "Choose a pulsing node to jump there. You can only move forward along the lines."
- What they pick: OBSERVED (battle.js rollEncounter): the first column is always a rout Engagement. enterNode (campaign_run.js) routes it to battle.

### Step 2 - Battle start (minute 2:00-3:00)

- What they see: OBSERVED (battle.js startBattle, ui3d.js prepBattle/buildHud): a 3D hex board (~13-15 units in skirmish; fleets come from FLEET_LISTS, e.g. voidsworn sk = 6 hulls, hegemony sk = 7 hulls), terrain from genTerrain, carriers already flying wings (deployWings). A log line: "Contact: The Hegemony. N ships on the auspex."
- HUD: OBSERVED (buildHud): top bar with scenario name, Round 1, turn label, Command pips, Objective: break their fleet (objectiveLabel), Threat / Fleet / Settings / End turn buttons. Left roster (both fleets with hull/shield bars). Right panel. Bottom log. A camera hint: "Right-drag orbit, Left-drag or WASD pan, Wheel zoom, F focus ship, T top-down" (camhint).
- The empty right panel is the only pre-play instruction: OBSERVED (refreshPanel empty state): "Select one of your ships to move and fire. Each ship can move, turn and fire every weapon once per turn, in any order. Click an enemy to see its weapons and firing arcs." plus a keyboard key (keysHelp).
- Tutorial tip #1: OBSERVED (ui3d.js TIPS/tutorialCheck, id start): "Select one of your ships: it has a green ring underneath. Gold hexes show where it can move, and the fans show its firing arcs."

### Step 3 - Selecting and reading a ship (minute 3:00-4:00)

- What happens: OBSERVED (ui3d.js selectUnit, bestFacingReach, battle.js computeReach): clicking a friendly ship draws a gold movement outline (reachOutline), firing-arc fans (refreshOverlays), and focuses the camera.
- What they must read: OBSERVED (refreshPanel): a full stat sheet - hull bar, three sections (prow/midships/engines) with bars, crew count, a shield dial with four facing values and a legend ("Cyan is shields... Amber is hull"; shieldDial), stats (Movement, Turns, Armor %, Evasion), the weapons list (weaponLine), a Helm section (turn buttons), Admiral's Command, Close action (Ram/Board), and an action strip with a plain-English hint (actionStrip: "Tap a gold hex to move, or a red-ringed enemy to fire.").
- Tutorial tip #2: OBSERVED (TIPS id select): "Hover a gold hex to preview the move: the ghost shows where you will end up and which way you will face. Q and E turn in place."

### Step 4 - Moving (minute 4:00-5:00)

- What happens: OBSERVED (ui3d.js refreshHover, boardTip, moveDmgLine; battle.js moveUnit): hovering a gold hex shows a dashed path, a ghost ship at the destination, and a tooltip: movement cost, movement left, thruster notes (sideslip/back off/climb over), "From here: N of M ready guns can fire (on target)," expected shield/hull damage, blocked-shot warnings, and ram spots. Clicking animates the move.
- Tutorial tip #3: OBSERVED (TIPS id move, triggered once any ship has spent movement): "Cyan is shields: four facings that soak hits and recharge each turn. Amber is hull: damage that stays. Keep your strongest shield facing the enemy."

### Step 5 - Firing (minute 5:00-6:30)

- What happens: OBSERVED (ui3d.js refreshOverlays, attackTip, onBoardClick; battle.js fireWeapon, cantFireReason, attackMovePlan): enemies a ready weapon can hit get pulsing red rings. Hovering one shows target stats, which shield facing will be struck, rear-arc note, a per-weapon table with hit % (or the exact reason it can't fire), expected damage, and "Click to fire N weapons." Clicking fires every bearing weapon. If the target is out of range but reachable, the game offers an attack-move ("Click to burn N movement into position and fire on the way"). If nothing can fire, cantFireReason explains in plain words.
- Tutorial tips #4 and #5: OBSERVED (TIPS id target then fired): the firing tip, then "Each ship acts once per round. When this ship is done, press End activation (Enter) and the enemy moves one of theirs."

### Step 6 - The activation economy (minute 6:30-7:30)

- What happens: OBSERVED (ui3d.js endActivation, aiStep, battle.js aiPickActivation): default is Alternating (SETUP.alt=true). "Done with ship" ends one ship, the enemy activates one of theirs, then the game auto-selects your next ready ship (pendingP()[0]) and pans to it. When both fleets are spent, nextRound fires a "Round N" banner.

### Step 7 - Admiral's Command (overlaps minutes 4-8)

- What they see: OBSERVED (battle.js cmdTier/commandFor/COMMANDS, ui3d.js actionStrip, ACT.command): a gold Command button (default admiral vex -> "Fire for effect"), shown at power in round 1, growing each round held and when a ship is lost. It uses a two-tap confirm with a visible countdown. Tip #6 (resolve) explains it.

### Step 8 - The enemy turn and threat (recurring, minutes 5-9)

- What happens: OBSERVED (battle.js aiUnit/evalThreat; ui3d.js ACT.threat, computeThreat, inspThreat, aiFocusMark): a "Enemy turn" banner, the AI moves and fires. The Threat toggle (R) paints hexes by expected enemy damage. Inspecting an enemy shows its reach and "Its next move can bring guns to bear on [your ships]." The default AI is Veteran (battle.js aiVet returns true when AI_LEVEL is undefined), and Veteran focus-fire is surfaced with corner brackets, a "Targeted" tag, and "The enemy fleet is focusing its fire on this ship."

### Step 9 - Attrition: sections, brace, status (minutes 6-9)

- What happens: OBSERVED (battle.js damageSection, giveOrder; ui3d.js stripHelp): hull damage lands on sections; a destroyed section disables something and the log says exactly what ("Midships destroyed. Broadsides and shield generator gone."). Brace (B) trades the shot for -40% hull damage.

### Step 10 - Victory and the reward chain (minute 9:00-10:00+)

- Skirmish: OBSERVED (ui3d.js endBattleFlow): a stats card - kills, rounds, losses, captures - and "Fight again / Change factions / Main menu." No rewards.
- Campaign: OBSERVED (campaign_run.js rewardFlow -> salvageStep -> boonStep/takeMod -> relicStep -> promotionsStep): a victory modal (credits, losses, a "Salvage the field" button if there are wrecks). Salvage lets you work one wreck: strip it for a specific refit module (salvageYield), scrap it for credits, or (Corsair only) tow it home. Then the node payout: a boon (pick 1 of 3 from a patron, with rarity) or a refit (pick 1 of 3) or credits or field repairs. Elite/boss fights add a relic choice. Captains with pending XP get a promotion (pick 1 of 2 perks, promoteModal). Then back to mapScreen.

## DELIVERABLE 2 - PER-STEP CRITIQUE, THEN STUCK POINTS RANKED BY DAMAGE

### Per step: explained / assumed / where they break

**Step 0 - Cold open**

- Explained in-game: faction one-liners; Skirmish = "Equal fleets of about 16 points"; Flagship = "Both sides bring their titan"; Alternating vs Classic one-liners (OBSERVED showIntro).
- Assumed: hex-tactics vocabulary; what "titan" and "16 points" mean; what each of the eight encounters actually involves (OBSERVED: the intro's encounter buttons show names only from OBJS - no descriptions, even though ENCOUNTERS[...].d descriptions exist in battle.js and are unused here).
- Stuck: INFERRED: nine rows of options with no guidance = choice overload and an "this is complicated" first impression. Players default-through, so the damage is tonal, not a hard block. Also INFERRED: a player who enters here gets skirmish and misses the actual roguelite loop.

**Step 1 - Sector map**

- Explained: node legend, forward-only movement, encounter previews with descriptions (OBSERVED mapScreen, encprev).
- Assumed: what Credits and Command Points are for; what boons, patrons, relics, Marks, and captain ranks are. OBSERVED: the sidebar's own placeholder text admits these are unknown ("None yet. Win at a node with a patron's sigil to earn one," "None yet. Elite fleets and flagships carry them").
- Stuck: INFERRED: the sidebar front-loads five unexplained economies before the player has fought once. The patron-sigil reward badges on nodes (glyph + short name, rewardBadge) have no legend, so a sigil node is unreadable.

**Step 2 - Battle start**

- Explained: the core verb in one sentence, camera controls, tip #1 (OBSERVED refreshPanel, camhint, TIPS.start).
- Assumed: which ships are yours on a 3D board of 13+ units; hex-grid literacy; that "move, turn, fire once each, any order" is the whole turn.
- Stuck: INFERRED: (a) camera/3D navigation is the first physical hurdle; (b) nothing tells you "your ships are on the left / marked gold, enemies red" - you must infer it from the roster.

**Step 3 - Reading a ship**

- Explained: move preview, shield/hull color legend (OBSERVED shieldDial, tip select).
- Assumed: what Armor %, Evasion, sections, crew, and arc letters (F/P/S/R/T) do mechanically.
- Stuck: INFERRED: the panel is a dense stat sheet with no prioritization; the action-strip hint rescues it by naming the next action, but a reader who tries to parse everything stalls here.

**Step 4 - Moving**

- Explained: move cost, guns-that-bear from the destination, expected damage (OBSERVED boardTip, moveDmgLine) - this is the best teaching in the game.
- Assumed: that movement changes how likely you are to be hit. OBSERVED (battle.js motionHit/MOVE_BASE): sitting still gives enemies +10 to hit; moving 3+ hexes gives -5. This is surfaced only in tiny text (driveLine/motionNote), never taught.
- Stuck: INFERRED: new players park their ships (the natural turn-based instinct), get hit more, and never learn why. This silently punishes the default behavior of a core feel-target mechanic.

**Step 5 - Firing**

- Explained: red rings, hover odds, plain-English "why can't I fire," attack-move (OBSERVED attackTip, cantFireReason). Strong.
- Assumed: shield-quadrant geometry, rear-arc armor/crit interaction, criticals and system damage.
- Stuck: INFERRED: minor - "click fires all bearing weapons" vs "1-6 arms one weapon" isn't obvious, though the tip mentions the keys.

**Step 6 - Activation economy**

- Explained: one tip, after the first shot (OBSERVED TIPS.fired); the intro's Alternating/Classic picker is long forgotten.
- Assumed: that the player retained the picker's one-liner.
- Stuck: INFERRED: moderate - auto-select of the next ship and the "Already activated" feedback (guard()) catch most errors, but the turn structure is the game's spine and gets one late tip.

**Step 7 - Admiral's Command**

- Explained: tip resolve, panel text with concrete numbers and an explicit risk warning ("Waiting risks the fight ending first," OBSERVED cmdDesc/cmdNext).
- Stuck: INFERRED: timing anxiety - use it weak at tier 0 or hoard it and never use it. The two-tap confirm prevents accidents. Low-moderate.

**Step 8 - Enemy turn / threat**

- Explained: Threat button tooltip only ("Where the enemy can hit next turn (R)").
- Assumed: that the player discovers and uses Threat; that they understand focus fire.
- Stuck: INFERRED: the default opponent is Veteran (OBSERVED aiVet), which focus-fires and can delete a ship in rounds 1-2 before the player understands why. The best defensive tool (Threat) is never prompted.

**Step 9 - Attrition**

- Explained: excellent log feedback on section loss (OBSERVED damageSection); Brace via the ? help (stripHelp).
- Stuck: INFERRED: Brace is hidden value new players skip; section loss surprises them but is explained in the log. Low-moderate.

**Step 10 - Rewards (campaign)**

- Explained: almost nothing. OBSERVED: the chain uses salvage, refit, boon, relic, Mark - none defined at point of use. The only context lines are generic ("Refits can be moved between ships freely," in fleetScreen, which the player hasn't opened yet).
- Assumed: that the player already knows what a refit slot is, what rarity means, what a boon's trigger condition is.
- Stuck: INFERRED: the roguelite's core reward loop lands as a wall of jargon; the player picks by flavor, learns nothing, and the dopamine of "win -> get stronger" is diluted. Also OBSERVED (TIPS.objective condition B.obj.type!=='rout'): the objective tutorial tip cannot fire in the guaranteed first rout battle - it only triggers later, mid-run.

### Stuck points ranked by damage (likelihood x severity)

1. HIGH - First fight defaults to Veteran AI (OBSERVED aiVet). INFERRED: new players lose ships to focus fire they can't read, feel outplayed, and quit at the exact moment the game should be winning them over.
2. HIGH - The "sitting still = easier to hit" rule is invisible (OBSERVED motionHit). INFERRED: silently punishes the default turn-based behavior; a core defensive verb goes unlearned.
3. HIGH-MED - Reward jargon dumped with zero context (OBSERVED rewardFlow/salvageStep/boonStep). INFERRED: the loop that defines the roguelite teaches nothing on first contact.
4. MED - Skirmish-first mismatch / choice-overload intro (OBSERVED showIntro, OBJS names only). INFERRED: intimidating open, and the visible entry leads to the mode with no progression.
5. MED - Dense first-ship panel (OBSERVED refreshPanel). INFERRED: stalls readers; mitigated by the strip hint.
6. MED - Alternating activation explained by one late tip (OBSERVED TIPS.fired). INFERRED: the turn economy is under-taught.
7. MED - Shield-facing model never explicitly mapped to the ship (OBSERVED shieldDial; tip move says "keep your strongest shield facing the enemy" without showing which way "facing" points).
8. MED-LOW - Threat never prompted (OBSERVED ACT.threat). INFERRED: best defensive tool stays hidden.
9. LOW-MED - Admiral's Command timing anxiety (OBSERVED cmdTier).
10. LOW - Objective tip can't fire on the first battle (OBSERVED TIPS.objective + rollEncounter).
11. LOW - Camera/3D navigation (OBSERVED camhint exists). INFERRED: manageable with the hint.
12. LOW - Touch-flavoured wording on PC (OBSERVED actionStrip calls touchWords; PC output Not specified). INFERRED: "Tap" vs "Click" friction if unconverted.

## DELIVERABLE 3 - CONCRETE FIXES, ORDERED BY VALUE

Each fix names the file and the function/constant it changes, or gives the new UI text. None redesigns the game; all preserve per-activation decisions.

**Fix 1 - Make the first battle fair (targets stuck #1). Highest value.**

- Change: ui3d.js - initialize AI_LEVEL to 'standard' for a fresh profile (persisted via the existing META.opts / saveOpts), keeping ACT.aiLevel as the toggle. Or battle.js aiVet(): default to Standard when no opts exist.
- Optional reinforcement: keep Veteran but add a one-time callout the first time B.aiFocus is set on a player ship: reuse the existing panel warning but raise it to a toast: "The enemy is focusing the [ship]. Brace it or pull it back."
- New settings tooltip text: "Standard fights fair while you learn. Veteran concentrates fire - unlock it once you've won a battle."

**Fix 2 - Teach "move or be hit" (targets stuck #2).**

- Change: ui3d.js TIPS, rewrite the move tip to carry the motion rule (the numbers already exist in battle.js MOVE_BASE):
"Shields (cyan) soak hits on the facing that's struck and recharge; hull (amber) damage stays. A ship that sits still is easier to hit - burn 3+ hexes and you're harder to hit. Keep your strongest shield toward the enemy."
- Also: ui3d.js driveLine already shows this on the panel - no change needed there, just the tip so it's seen once, early.

**Fix 3 - Explain the activation economy at battle start, not after the first shot (targets stuck #6).**

- Change: ui3d.js refreshPanel empty-state - append one sentence:
"Turn order is Alternating: you act with one ship, then the enemy acts with one. When a ship has moved and fired, choose Done with ship (Enter)."
- Keep tip fired as reinforcement.

**Fix 4 - Give the first reward context before the jargon (targets stuck #3).**

- Change: campaign_run.js salvageStep header - add: "A refit is a module you bolt into a ship's empty refit slots; swap them anytime from Fleet."
- Change: campaign_run.js boonStep under the patron header - add: "Boons last the whole run and trigger on their own in battle."
- Change: campaign_run.js relicStep - add: "Relics are permanent for this run." (The existing line already says this - just ensure it's present on the first elite, not only boss.)

**Fix 5 - Shrink and inform the intro (targets stuck #4).**

- Change: ui3d.js showIntro - collapse Battlefield, Deployment, Arena, Board into a single "Advanced" disclosure for new profiles. Keep Fleet, Opponent, Engagement, Turn order.
- Change: ui3d.js showIntro encounter buttons - add the descriptions that already exist: render ENCOUNTERS[k].d (battle.js) as <small> under each OBJS name. This costs nothing and makes "Encounter" legible.

**Fix 6 - Prompt Threat once (targets stuck #8).**

- Change: ui3d.js - add a new TIPS entry fired on the first enemy turn of a run:
id threat, condition B.round===1 && B.side==='enemy' (once): "Enemy turn: press R (Threat) to paint where they can hit next turn. Keep fragile ships out of the red."

**Fix 7 - Put a boon legend on the map (targets stuck at Step 1).**

- Change: campaign_run.js mapScreen bottom hint - append: "A node marked with a coloured sigil pays a boon from that patron when you win it." This matches the existing sidebar placeholder wording and makes rewardBadge glyphs readable.

**Fix 8 - Map shield facing to the ship (targets stuck #7).**

- Change: ui3d.js shieldDial or tip move - add one clause: "The dial's Prow points where the ship's nose faces." Minimal, no new overlay needed.

**Fix 9 - Let the objective tip fire early (targets stuck #10).**

- Change: ui3d.js TIPS.objective condition - broaden from B.obj.type!=='rout' to also fire once when any objective is present, or gate a rout-specific line ("Break their fleet: destroy enough and the rest flee"). This teaches the non-rout objectives before the player is mid-run in a Relay or Intercept.

**Fix 10 - Cut noise from the first ten minutes (targets stuck #4/#5).**

- Change: ui3d.js showIntro (Advanced collapse, above). campaign_run.js mapScreen - optionally collapse the Relics/Boons sidebar blocks until first earned (they currently read "None yet..." and are pure noise at minute one). Cosmetic, low value.
- Do NOT change: the move/fire tooltips, cantFireReason, attackTip, and the action-strip hint - these are already the strongest onboarding in the codebase and should be left intact.

## NOT SPECIFIED

I could not determine the following from the three granted files; these are real gaps for a full onboarding pass, not omissions in this lens:

- The title screen and campaign run-creation. titleScreen (called in campaign_run.js ACT.saveQuit) and c3title/c3continue (called in ui3d.js) are referenced but not defined. I cannot confirm what a new player picks to start a run (faction, admiral, difficulty), whether campaign is the default mode, or whether it's gated behind anything.
- battleScreen. Called by campaign_run.js ACT.enterNode and ACT.eventChoice, but not defined in the granted files. I cannot confirm whether there is a pre-battle briefing/deployment screen in the campaign path before startBattle.
- The choice between campaign and skirmish for a first-time player, and which is the default landing.
- Data definitions referenced but absent: HULLS, FACTIONS, ADMIRALS, PERKS, RARITY, BOONS, PATRONS, RELICS, MODULES, ABILITIES, ARC_NAME, ORDERS, ASPECTS, QUAD_NAME, WTRAITS, MOVE_RULES, sectorCond, priceMult, repairMult, fleetCP, derive, newShip, shieldQuad, hasBoon, runFx, rollNodeReward, rollBoonOffer, genSector, availableNodes, nodeFaction, randomModule, randomRelic, modulePool, saveRun, and the tel/Persist telemetry layer. Rarity names, patron themes, and admiral identities are therefore unknown.
- touchWords output on PC (ui3d.js actionStrip/tips). I could not confirm whether "Tap" is rewritten to "Click" for mouse users.
- Default camera/quality/follow settings (G.follow, initial G.quality) - persisted via META.opts but initial values not in the files.
- SFX content and any voice/animation that might carry onboarding.

End of lens.
