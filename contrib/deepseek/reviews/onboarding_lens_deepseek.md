# First-ten-minutes onboarding lens: DeepSeek leg

Provenance: generated in DeepSeek chat on Oct 24, 2026, DeepThink ON, Search OFF, signed in as rcbailey12@gmail.com. All four granted files attached successfully (onboarding_lens_brief.txt, campaign_run.js, battle.js, ui3d.js). UI artifact note from the run: after the lens finished, a "Failed to load this message" indicator with a Retry button appeared; Retry cleared it temporarily but it recurred in later page views, while the lens content itself remained complete throughout. Em dashes in the model's text were normalized to hyphens for the no-em-dash rule; wording is otherwise verbatim. Screening and synthesis against the Qwen leg follow separately; nothing here is verified.

Voidsworn First-Ten-Minutes Onboarding Lens

Grounding and scope

OBSERVED: The granted files contain a start-adjacent UI function, showIntro() in ui3d.js, and a skirmish setup function, setupBattle(cfg) in ui3d.js. showIntro() builds the first setup overlay with faction, opponent, engagement, battlefield, deployment, encounter, arena, board, and turn-order pickers. ACT.begin removes that overlay, establishes the camera, selects a player ship, refreshes the top bar, and shows a round banner.

OBSERVED: campaign_run.js contains mapScreen(), rewardFlow(), boonStep(), relicStep(), promotionsStep(), afterBattle(), shipyard, drydock, events, and node travel. But within the granted files, I find no call from showIntro, ACT.begin, setupBattle, or endBattleFlow into campaign_run.mapScreen() or rewardFlow(). ACT.saveQuit calls titleScreen(), and several UI buttons call c3title, but neither titleScreen nor c3title is defined in the granted files.

INFERRED: The only start-to-play flow that can be reconstructed from the granted code is the skirmish setup in ui3d.js followed by a single battle. The campaign map/reward flow exists in campaign_run.js but its entry point is not shown. Therefore this lens walks the first ten minutes as the code can actually present them from showIntro() forward, and it treats campaign map/reward as conditional code paths rather than as guaranteed first-ten-minute content.

OBSERVED: The default setup object in ui3d.js is:

SETUP={pf:'voidsworn',ef:'hegemony',mode:'sk',alt:true,map:'random',dep:'line',obj:'rout',shape:'random',arena:'random'}.

OBSERVED: setupBattle() resets RUN to {admiral:'vex',credits:0,cpCap:40,sector:1 or 3,relics:[],inventory:[],fleet:[],stats:...} and populates the player fleet from FLEET_LISTS[SETUP.pf] using genFleet(SETUP.pf,SETUP.mode). For default voidsworn skirmish, FLEET_LISTS.voidsworn.sk is ['cathedral','penitent','reliquary','harrow','warden','warden']. The enemy default is hegemony skirmish, FLEET_LISTS.hegemony.sk, seven ships. startBattle is called with kind:'battle', fac:SETUP.ef, col:3, obj:SETUP.obj, map:SETUP.map, dep:SETUP.dep, arena:SETUP.arena, shape:SETUP.shape.

OBSERVED: Default obj:'rout' means the first battle objective is Engagement: "Break their fleet. It flees once it has lost about two thirds of its strength" (ENCOUNTERS.rout in battle.js). checkEndRules() implements the fleet-break check as sideCP('enemy')<=B.cp0.enemy*.35, i.e. roughly 65% of enemy command points lost.

OBSERVED: Default alt:true means alternating activations. prepBattle() sets B.alt=!!SETUP.alt, marks all units unactivated, and calls startSideTurn('enemy') before play. ACT.endTurn calls endActivation(true) when B.alt; endActivation() marks the active/selected player ship activated, then calls aiStep(). aiStep() runs one enemy activation when player ships are still pending, or all pending enemy ships when no player ships remain.

1. Reconstructed first ten minutes, step by step

Step 0 - Boot and first visible screen

OBSERVED: The granted files do not define the game bootstrap. showIntro() exists and creates an .intro overlay, but I cannot see what calls it at application start. ACT.saveQuit calls titleScreen(), which is not defined in the granted files. Several buttons call ACT.c3title, also not defined in the granted files.

INFERRED: A brand-new player's literal first screen is Not specified from the granted code. The closest reconstructable first screen is showIntro() if the missing bootstrap calls it.

OBSERVED: showIntro() renders:

<h1>Voidsworn</h1> and <div class="sub">3D skirmish</div>.

"Your fleet" with six faction buttons from PLAYABLE: voidsworn, hegemony, corsair, chorus, ithar, deathless.

"Opponent" with the same six faction buttons.

"Engagement" with Skirmish and Flagship battle.

"Battlefield" with Random, Asteroid belt, Derelict station, Planet edge, Ion storm, Ship graveyard.

"Deployment" with Line, Flank, Ambush.

"Encounter" with eight objectives: Engagement, Ambush, Hold the station, Hunt, Intercept, Breakthrough, Relay, Decapitation.

"Arena" with Random, Classic strip, Square, Round.

"Board" with Random, Open void, Corridor, Split lanes, Ring, Dense field, Dead star.

"Turn order" with Alternating and Classic.

Begin engagement and Back to title.

A controls line: right-drag orbit, left-drag/WASD pan, wheel zoom, T top-down, R threat map, X ram, G board.

OBSERVED: Each picker button calls ACT.pick(arg). ACT.pick parses key:value, updates SETUP, then calls setupBattle({[k]:nv}) and showIntro() again. It does not wait for Begin engagement.

INFERRED: Changing any setup option immediately builds a full battle behind the setup overlay. setupBattle() calls startBattle(), prepBattle(), buildBattleEnv(), and resets RUN. The player sees a setup overlay, but the game has already constructed a battle. On a slower PC this can produce a hitch or visible 3D activity behind the overlay. It also means the setup overlay is not a pure configuration screen; every click mutates run state.

What is explained in-game: Almost nothing beyond names and one-line faction blurbs from FACTIONS[f].blurb first sentence. The controls line explains camera and a few shortcuts. OBSERVED.

What is assumed the player already knows: That "Skirmish" vs "Flagship battle" matters; what "Deployment: Line/Flank/Ambush" means; what each encounter name means; what "Arena" and "Board" mean; what "Alternating" vs "Classic" changes; what CP, Marks, boons, relics, refits, command points, or campaign rewards are. OBSERVED by absence of explanatory text in showIntro().

Where a new player is most likely to get stuck, quit, or misunderstand: The setup screen asks for eight or nine decisions before the first battle and explains almost none of them. A new player can click Begin engagement with defaults, but the screen does not tell them defaults are safe. The Begin engagement button is not the first focus; the many pickers are. INFERRED.

Damage: High. This is the first impression and it front-loads terminology the game has not taught.

Step 1 - The first battle is created before "Begin"

OBSERVED: setupBattle() resets RUN every time it is called. ACT.pick calls setupBattle() on every picker change. Therefore every faction/map/objective/arena pick rebuilds the player fleet, enemy fleet, battle state, environment, and HUD.

OBSERVED: setupBattle() calls disposeAllViews(); clearOverlays(); hideEnd();, resets RUN, builds RUN.fleet with newShip(t,true), calls startBattle(...), sets G.home, calls prepBattle(), sets #scenName, clears B.sel, and calls bRefresh().

OBSERVED: prepBattle() resets FRAMES, sets B.alt, marks all units activated=false, calls startSideTurn('enemy') when alternating, builds battle environment, builds beacon for hold, clears and refills the battle log, sets B.sel=null, and calls bRefresh().

INFERRED: A new player who experiments with faction buttons is repeatedly rebuilding a battle. This is expensive and can make the setup screen feel laggy or unstable. It also means "Begin engagement" is not the moment the battle begins; the battle already exists.

What is explained in-game: Nothing about why clicking a faction changes the background battle or why there may be a pause. OBSERVED.

What is assumed: That setup choices are cheap and reversible; that the player will not mind a full battle being constructed behind the intro. INFERRED.

Stuck point: A new player may click several factions and think the game is stuttering or that they have already started. INFERRED.

Damage: Medium-high. It is not necessarily run-ending, but it degrades trust in the first minute.

Step 2 - "Begin engagement" and the first tutorial tip

OBSERVED: ACT.begin does:

SFX.init().

Removes .intro.

Removes document.body.classList.remove('intro-on').

Sets G.ctl.attract=false.

Calls G.ctl.establish().

Finds caps('player')[0] and calls selectUnit(f).

Calls refreshTop().

Calls banner(B.alt?'Round 1':'Your turn').

OBSERVED: selectUnit() sets B.sel, B.inspect=null, B.armed=null, B.mode=null, computes B.reach via bestFacingReach(u,computeReach(u)), marks ram spots, and calls bRefresh().

OBSERVED: bRefresh() calls tutorialCheck(). tutorialCheck() returns early if .intro exists. By the time ACT.begin calls selectUnit(), .intro has been removed. Therefore tutorialCheck() can show a tip card.

OBSERVED: TIPS begins with:

['start','Your fleet','Select one of your ships: it has a green ring underneath. Gold hexes show where it can move, and the fans show its firing arcs.'].

tutorialCheck() condition for start is true, so the first tip is start unless META.opts.tipsOff or META.opts.tips.start is already set.

OBSERVED: Because ACT.begin already called selectUnit(f), the first player ship is selected when the "Select one of your ships" tip appears. The tip text is therefore already one step behind the UI state.

OBSERVED: After the player clicks Got it, ACT.tipOk marks o.tips[id]=1, saves, removes the tip, and calls setTimeout(tutorialCheck,400). tutorialCheck() then finds the next tip whose condition is true. The select tip condition is !!s, and s is already selected, so the select tip appears immediately after the start tip.

INFERRED: A brand-new player receives a tip telling them to do something they have already been made to do automatically. Then they receive a second tip about moving and facing before they have touched anything. The tips are condition-gated but not sequenced to the player's actual first action.

What is explained in-game: The first tip explains green ring, gold hexes, and firing fans. The second tip explains hover preview, ghost, Q/E turning. OBSERVED from TIPS.

What is assumed: That the player understands "green ring underneath," "gold hexes," and "fans" from seeing the 3D board. INFERRED.

Stuck point: The first tip is inaccurate on arrival; the tutorial starts by correcting a state the game itself created. Damage: Medium-high for tutorial trust.

Step 3 - The battlefield and HUD

OBSERVED: buildHud() inserts the top bar, roster, panel, log, and camera hint. The top bar contains:

Voidsworn title.

#scenName, set by setupBattle to ${FACTIONS[SETUP.pf].n} vs ${FACTIONS[SETUP.ef].n}, ${map name}${flagship}.

Round label.

Turn label.

Resolve/Command label with title "Admiral's Command: a fleet-wide signature move, once per battle, growing each round you hold it".

Objective label.

Threat button.

Fleet button.

Settings button with a large panel of display/camera/sound/restart/report/diagnostics buttons.

Retreat button, displayed only when B.campaign && B.cfg.kind!=='boss'.

End turn button.

OBSERVED: The roster lists player and enemy ships with hull bars, shield pips, and status text. The panel shows the selected or inspected ship. The log is a scrolling battle log. The camera hint lists right-drag orbit, left-drag/WASD pan, wheel zoom, F focus, T top-down.

OBSERVED: For the default first battle, B.campaign is not set by setupBattle, so Retreat is hidden. #b_restart is shown when !B.campaign. The end card will offer Fight again, Change factions, and Main menu, not campaign continuation.

INFERRED: The first battle HUD exposes many controls at once: Threat, Fleet, Settings, End turn, roster, panel, log, camera hint, and a selected ship's full panel. A new player has to parse a lot before making one move.

What is explained in-game: The camera hint explains camera controls. The objective label explains the current objective in shorthand. The panel's empty state says: "Select one of your ships to move and fire. Each ship can move, turn and fire every weapon once per turn, in any order." OBSERVED in refreshPanel().

What is assumed: That the player knows what "Threat," "Fleet," "Resolve/Command," "End turn" vs "End activation," and the roster shield pips mean. INFERRED.

Stuck point: The player is in an alternating-activation battle, but the top button says End turn by default and refreshTop() changes its text to End activation only when B.alt and an active unit exists. The label can say "End turn" or "Continue" depending on state. refreshTop() sets $('endbtn').textContent=B.alt?(B.activeUnit?'End activation':pendingP().length?'Pass':'Continue'):'End turn'. At the start of an alternating battle with a selected ship, B.activeUnit may be set by guard() only when the player acts, not by selectUnit(). INFERRED: A new player may see "Pass" or "Continue" and not understand they are passing one ship's activation.

Damage: High. Alternating activation is the feel target, but the UI label is state-dependent and not introduced before the first decision.

Step 4 - The first selected ship and the movement overlay

OBSERVED: selectUnit() computes B.reach only when u.side==='player' && B.side==='player' && canUse(u). canUse(u) in alternating mode returns false if u.activated, or if B.activeUnit exists and is not u.

OBSERVED: refreshOverlays() draws:

Firing arcs as fans/rings around the selected or inspected ship when B.showArcs is true.

Gold reach hexes from B.reach.map.

Brighter edge tiles for hexes where guns can fire (tile('reachG4'...), tile('reachGE3'...)).

A reachOutline() line around the reachable area.

Red ram spots when st.ram is true.

A ram lane when ramInfo(sel) exists.

Red target rings on enemies where some weapon canFire.

A selection ring under the selected ship.

OBSERVED: bestFacingReach() annotates each reachable state with guns, gunsOf, and gunTarget so the tooltip can say "From here: X of Y ready guns can fire."

OBSERVED: refreshPanel() shows the action strip at the top of the ship panel. actionStrip(u) builds buttons: Done with ship, ability/launch, Admiral's Command, Ram, Board, Brace, Center, ?. It also builds a striphint from state. Example hints include:

"Tap a gold hex to move, or a red-ringed enemy to fire."

"Ram ready: … is dead ahead (red lane). Tap Ram, or move and fire instead."

"Red-ringed gold hexes line up a ram. Move there, then tap Ram."

"Nothing left to do: tap Done with ship."

"This ship has acted. Pick another ship, or wait for your turn."

OBSERVED: refreshPanel() also renders ship sections (prow/midships/engines), crew, shield dial, stats, weapons, close action, helm, ability, and Admiral's Command section. The shield dial text explains cyan is shields, amber is hull.

INFERRED: A new player is presented with movement hexes, firing fans, target rings, ram lane, selection ring, ship panel, action strip, and multiple tooltips at once. The most important first action - move one ship to a gold hex - is available, but it competes with advanced actions like Ram, Board, Command, and Brace.

What is explained in-game: The start and select tips explain gold hexes, green ring, fans, ghost preview, and Q/E turning. The panel explains shields vs hull. The action strip hints explain current possible actions.

What is assumed: That the player can distinguish gold reach hexes from brighter "guns can fire from here" hexes, red target rings, red ram spots, and the selection ring. That they know what "arcs" mean and why facing matters. INFERRED.

Stuck point: The first ship panel exposes Ram, Board, Admiral's Command, and Brace before the player has moved or fired once. Ram and Board have long tooltips but are still visible as first-class buttons. A new player may click Ram or Board before understanding movement and arcs. Damage: High.

Step 5 - First move

OBSERVED: onBoardClick() handles board clicks. If a player ship is selected and B.reach exists, a click on a reachable hex calls moveUnit(s,st) through act().

OBSERVED: moveUnit() commits movement through animPath if available, else animMove/animRotate. It updates u.q, u.r, u.facing, u.mp, u.turnsLeft, u.moved, u.hexMoved, and calls objAfterMove(u).

OBSERVED: onHover() sets B.hover and refreshHover() draws a dashed path, a ghost silhouette at the destination, and an aim line to a hovered enemy. boardTip() shows movement cost, remaining movement, thruster notes (moveNote), terrain effects, gun coverage, blocked line-of-fire warnings, and ram-spot warnings.

OBSERVED: driveLine(u) in the panel explains thruster rules: sideslip, back off, pass over/under costs, faction movement rule, and the motion hit modifier: "Has not moved: enemies get +X to hit" or "Evasive: enemies get −X to hit."

INFERRED: Movement is rules-rich: facing, turns, sideslip, reverse, passing over terrain, passing under ships, motion hit modifiers, and faction movement rules. The UI does surface these, but only after the player selects a ship and reads the panel. The first tutorial does not teach thruster costs or motion modifiers.

What is explained in-game: Hover tooltip explains move cost and remaining movement. moveNote() explains sideslip/back/over/under. driveLine() explains still/evasive modifiers. The select tip explains ghost and Q/E turning.

What is assumed: That the player understands hex grids, facing, firing arcs, and why a move that ends with a bad facing is bad. INFERRED.

Stuck point: The player can move without learning that ending still gives enemies +10 to hit, or that ending with the wrong facing leaves guns out of arc. The tooltip surfaces this only if the player hovers the right hex. Damage: High for core combat understanding.

Step 6 - First target and first shot

OBSERVED: refreshOverlays() draws red target rings on enemies when ws.some(w=>canFire(sel,w,t)) for the selected ship. OV.targets stores those rings.

OBSERVED: onBoardClick() when clicking an enemy and a player ship is selected calls firingSet(s,u), which returns all weapon indices where canFire is true. If the set is non-empty, it calls guard(s), then act(async()=>{ for(const i of set){ ... await fireWeapon(s,i,u); ... } }). It fires all ready weapons that can hit that target. There is no confirmation modal before the first shot.

OBSERVED: attackTip(a,t) is shown on hover and lists each weapon, its status, hit chance, shots x damage, expected shield and hull damage, likely kill, and modifiers. It says "Click to fire N weapons."

OBSERVED: If no weapon can fire, clicking an enemy calls cantFireReason(s,t) and toasts a plain-language reason. It also increments B.usage.cant categories. If the ship can attack-move, clicking an enemy may call attackMovePlan(s,u) and move then fire.

INFERRED: The first shot is one click. A new player who clicks an enemy to inspect it may fire all ready weapons. The hover tooltip gives odds, but only if the player hovers before clicking. There is no "inspect enemy" mode distinct from "fire" when a player ship is selected and guns bear.

What is explained in-game: attackTip explains hit chance, expected damage, shield facing, rear arc, terrain modifiers, motion modifiers, boon modifiers, and likely kill. cantFireReason explains why a shot is impossible.

What is assumed: That the player will hover before clicking; that they know "expected shield" and "expected hull" are estimates; that firing all ready weapons is the default. INFERRED.

Stuck point: Accidental first shot. Damage: High, because the first combat decision can be made without confirmation and without the player realizing a click is an attack.

Step 7 - Ending the first activation and the enemy response

OBSERVED: ACT.endTurn calls endActivation(true) when B.alt. endActivation() marks B.activeUnit activated or marks the selected player ship activated, clears selection/reach/armed/mode, and calls aiStep().

OBSERVED: aiStep() checks pendingE() and pendingP(). If enemy ships are pending, it sets B.busy=true, B.side='enemy', chooses batch=pp.length?[aiPickActivation(pe.sort(...))]:pe, and runs aiUnit(u) for squadrons and batch. If player ships remain pending, it runs one enemy activation; if no player ships remain, it runs all pending enemy ships.

OBSERVED: aiStep() does not call banner('Enemy activation'). It updates the top bar through bRefresh(). The end-of-turn flow in non-alternating mode uses banner('Enemy turn','#e07a70'), but aiStep() for alternating does not.

OBSERVED: After the enemy batch, aiStep() restores B.side='player', B.busy=false, and if player ships remain pending, selects the first pending player ship and calls camShow(f).

INFERRED: A new player may not realize that pressing Done with ship has handed one enemy ship an activation. The enemy ship moves, fires, and the turn returns. The UI changes from "Your activation (N ready)" to "Enemy activation" in the top bar, but there is no large banner or coach mark.

What is explained in-game: The fired tip says: "Each ship acts once per round. When this ship is done, press End activation (Enter) and the enemy moves one of theirs." OBSERVED in TIPS. But this tip only appears after a player ship has fired (cond.fired is true).

What is assumed: That the player has already fired before ending activation; that they understand "End activation" vs "End turn"; that one enemy activation follows one player activation. INFERRED.

Stuck point: The alternating-activation rhythm is the feel target, but it is taught after the first shot, not before the first pass. Damage: High.

Step 8 - Tutorial tip cascade

OBSERVED: TIPS contains eight entries: start, select, move, target, fired, resolve, close, objective. Conditions are computed in tutorialCheck():

start:true

select:!!s

move:me.some(x=>!x.isSq&&x.mp<x.speed)

target:OV.targets&&OV.targets.length>0

fired:me.some(x=>x.weapons.some(w=>w.fired))

resolve:canCommand('player')

close:!!s&&!s.isSq&&(!!ramInfo(s)||boardTargets(s).length>0)

objective:B.obj&&B.obj.type!=='rout'

OBSERVED: tutorialCheck() finds the first tip not yet marked seen whose condition is true. It does not enforce a sequence beyond TIPS order. If several conditions are already true, the player can receive several tip cards in succession, one per Got it, with a 400 ms delay.

INFERRED: Because start is always true and select becomes true immediately after ACT.begin, the first two tips are guaranteed in quick succession. If a target is in range at deployment, target can appear before the player moves. resolve can appear in round 1 because canCommand('player') returns true when B.round>=1 && !B.cmdUsed. close can appear immediately if ramInfo(s) or boardTargets(s) is true. The tips can therefore front-load command, ram, boarding, and objectives before the player has moved.

What is explained in-game: Eight tips cover fleet selection, movement/facing, shields/hull, firing, alternating activations, Admiral's Command, close action, and objectives.

What is assumed: That the player will read and dismiss each card in order; that the conditions match the player's current understanding. INFERRED.

Stuck point: Tip cascade and out-of-order tips. Damage: Medium-high. It makes onboarding feel noisy and can teach advanced systems before basics.

Step 9 - First battle end and "rewards"

OBSERVED: endBattleFlow() sets B.ending=true, computes title They got away / Victory / Withdrawal / Defeat, calls banner, then builds #endcard with kill/loss/captured summary.

OBSERVED: For B.campaign true, end card shows Continue the campaign with data-act="c3continue". For B.campaign false, it shows Fight again, Change factions, and Main menu.

OBSERVED: setupBattle() does not set B.campaign. Therefore the default skirmish first battle ends with no credits, no boons, no refits, no relics, no promotions, no salvage, and no map. rewardFlow() is not called from endBattleFlow() in the granted code.

OBSERVED: campaign_run.rewardFlow(summary) exists and does compute credits, node rewards, boons, refits, relics, promotions, and salvage. But no granted first-ten-minute path calls it. afterBattle() calls completeNode() and either ends the run or generates a new sector; it also calls mapScreen(). But afterBattle() is only reachable through promotionsStep() and rewardFlow(), not through endBattleFlow().

INFERRED: In the only reconstructable first-ten-minute flow, the first battle's "reward" teaches nothing about campaign progression. The player either fights again or changes factions. If the intended game is a campaign roguelite, the first ten minutes do not show the campaign, the map, rewards, shipyard, drydock, events, boons, relics, or promotions.

What is explained in-game: The end card explains kills, losses, captures, and offers replay/change/main menu. OBSERVED.

What is assumed: That the player understands "captured" from the boarding system; that they do not expect campaign rewards in a skirmish. INFERRED.

Stuck point: Mode/flow mismatch. If the game is meant to be a campaign, the first ten minutes are the wrong mode. Damage: Critical.

Step 10 - Conditional campaign map and first rewards, if reached

OBSERVED: campaign_run.mapScreen() renders a campaign map with:

Header Sector ${roman(RUN.sector)} plus region name if m.region.

"Hostile presence: [F.n]. [F.blurb]."

Optional sector condition.

SVG edges and nodes. Available nodes pulse. Node icons come from nodeIcon; labels come from NODE_INFO.

Legend for NODE_INFO.

Encounter preview rows for available battle/elite nodes, showing encounter name, archetype, node mod, shape, description, and reward.

Instruction: "Choose a pulsing node to jump there. You can only move forward along the lines."

Side panel: Credits, Command points, Admiral, Fleet, Manage fleet/refits, inventory count, Flagship aspect, Boons, Patrons, Relics.

OBSERVED: mapScreen() calls availableNodes(), rollEncounter(), rollNodeReward(), ensurePatrons(), nodeSeeds(), sectorCond(), fleetCP(), derive(), hpBar(), etc. Many of these are not defined in the granted files.

OBSERVED: mapScreen() shows reward labels through rewardBadge() and rewardLabel(): boons show patron sigils and short names; mods show "Refit"; credits show "Credits"; repairs show "Repairs". It shows encounter previews only for available nodes with n.enc.

OBSERVED: rewardFlow(summary) computes credits as (25+12*s+3*col)*kindMult*(1+credPct+sectorCond.cred), halves credits for summary.partial, adds salvage bonuses, then sets rw from node.rw or a default boon. It displays a Victory modal with kills, rounds, credits, losses, extra credits/repairs, boon stats, flag transfer, XP lines, and a next button. The next button leads to salvage (salvageStep), boon choice (boonStep), refit choice (rewardNext), relic choice (relicStep), promotions (promotionsStep), then afterBattle().

OBSERVED: boonStep(p,minR) shows a patron header with patron color, glyph, name, theme, quote, and three boon choices. Each choice shows rarity or "Duo: Patron + Patron", name, and description. takeBoon adds the boon, increments META.favour, toasts the boon, and moves to relics.

OBSERVED: relicStep() shows a relic choice for elite/boss, then promotions. promotionsStep() finds a ship with cap.pending>0 and opens promoteModal, which offers two perks. afterBattle() completes the node, and for boss either ends run or increments sector, adds +3 CP cap, generates a new sector, repairs 40%, saves, maps, and shows a sector modal.

INFERRED: If the campaign map were reached, a new player would see a node map with many icon types and reward badges, a side panel with Credits, Command points, Admiral, Fleet, Boons, Patrons, Relics, and an encounter preview. The first map would likely be visually dense. The first reward modal would introduce credits, boons, patron rarity, refits, relics, promotions, and salvage in sequence. There is no separate first-time explanation for any of these systems; the reward UI itself is the explanation.

What is explained in-game: Node tooltips and legend explain node types. The map instruction explains forward movement. Encounter preview explains encounter descriptions. Reward modals show names and descriptions.

What is assumed: That the player knows what credits buy, what command points cap, what boons do, what patrons are, what rarity means, what refits are, what relics do, what promotions do, and what salvage choices mean. INFERRED.

Stuck point: If the campaign map is the true first ten minutes, it is under-explained. But this path is not shown by the granted bootstrap. Damage: Critical if intended, but Not specified in flow.

2. Per-step critique summary

OBSERVED: The first ten minutes from showIntro() to battle end expose these systems before or during the first battle:

Faction selection.

Opponent selection.

Engagement type.

Battlefield.

Deployment.

Encounter objective.

Arena.

Board shape.

Turn order.

Ship selection.

Movement with facing, thruster costs, motion hit modifiers.

Firing arcs, shield facings, armor, evasion, expected damage.

Alternating activations.

Admiral's Command.

Ramming.

Boarding.

Brace.

Abilities.

Weapons with reload, pierce, ion, anti-squadron, traits.

Sections, crew, criticals, system damage.

End card with no campaign rewards.

INFERRED: The first ten minutes are not a tutorial; they are a full tactical skirmish with a conditional tip system layered on top. The tips explain some systems, but they are condition-gated rather than sequenced, and several fire after the player has already performed the action.

OBSERVED: The code has no explicit "first battle only" simplification. setupBattle uses the same startBattle and buildHud as any battle. TIPS is the only onboarding-specific UI.

INFERRED: The highest-risk misunderstanding is mode/flow: a new player expecting a campaign roguelite gets a skirmish, and a new player expecting a skirmish gets campaign-themed copy in the setup title (Voidsworn, factions) but no campaign.

OBSERVED: The code uses naval-adjacent vocabulary: "Admiral," "fleet," "shipyard," "drydock," "prow," "port," "starboard," "broadsides," "boarding," "ram," "hull," "crew." The brief requires space ships, never naval ships. INFERRED: The copy should be audited for naval framing, especially "drydock," "broadsides," "boarding," and "Admiral."

3. Stuck points ranked by damage

1. Critical - The reconstructable first flow is skirmish, not campaign; first battle end gives no campaign rewards or map

OBSERVED: setupBattle() does not set B.campaign. endBattleFlow() shows Fight again, Change factions, Main menu when !B.campaign. rewardFlow() and mapScreen() are not called from endBattleFlow(). showIntro() is a skirmish setup, not a campaign setup.

INFERRED: A new player who expects the advertised run/map/reward roguelite loop will play a skirmish, win or lose, and see no map, no credits, no boons, no refits, no relics, no promotions, and no next node. This is the largest onboarding damage because it withholds the game's core campaign loop.

2. High - Setup screen front-loads eight decisions with almost no explanation

OBSERVED: showIntro() lists Your fleet, Opponent, Engagement, Battlefield, Deployment, Encounter, Arena, Board, Turn order, and Begin. Faction blurbs are only the first sentence of FACTIONS[f].blurb. Encounter buttons show only OBJS names. Arena/Board/Deployment names are unexplained.

INFERRED: A new player does not know which choices are safe defaults or what they change. The screen can cause decision paralysis before the first battle.

3. High - Every setup pick rebuilds a battle

OBSERVED: ACT.pick calls setupBattle({[k]:nv}) on every change. setupBattle resets RUN, builds fleets, calls startBattle, prepBattle, buildBattleEnv, and bRefresh.

INFERRED: Experimenting with faction/opponent buttons causes repeated full battle construction behind the intro. This can produce hitches, visual noise, and the feeling that the game has already started.

4. High - Tutorial tips are condition-gated, not sequenced; first tip tells the player to select a ship that is already selected

OBSERVED: ACT.begin calls selectUnit(f) before tutorialCheck() can show the start tip. TIPS.start says "Select one of your ships." TIPS.select condition !!s is already true, so it appears immediately after the first tip is dismissed.

INFERRED: The tutorial's first two cards do not match the player's first two actions. The player is told to do something already done, then given a movement/facing lesson before they have moved.

5. High - Alternating activation is not taught before the first pass

OBSERVED: prepBattle() sets B.alt=SETUP.alt (default true). endActivation() and aiStep() implement one player activation then one enemy activation while player ships remain. The fired tip teaches this only after a player ship has fired. refreshTop() changes the button text among End activation, Pass, Continue, and End turn.

INFERRED: A new player may press Pass or Continue without realizing they are passing one ship and handing an activation to the enemy. The core feel target - turn-based per-activation decision weight - is not introduced before the first decision.

6. High - First shot is one click and fires all ready weapons

OBSERVED: onBoardClick() calls firingSet(s,u) and then fireWeapon for every index in the set. There is no confirmation. attackTip gives odds on hover, but clicking the enemy fires.

INFERRED: A player who clicks an enemy to inspect it can accidentally fire every ready weapon. The first combat decision can be made before the player understands hit chance, shield facing, or expected damage.

7. High - Movement/facing/arcs are rules-rich and taught mostly through hover tooltips

OBSERVED: computeReach(), moveRules(), motionHit(), bestFacingReach(), moveNote(), and driveLine() implement and describe sideslip, reverse, over/under, still/evasive modifiers, and gun coverage. The select tip only mentions ghost preview and Q/E turning.

INFERRED: A new player can move to a gold hex without learning that ending still gives enemies a bonus to hit, or that facing determines which guns can fire. This can make the first battle feel random.

8. Medium-high - Advanced actions are visible in the first ship panel before basics

OBSERVED: actionStrip(u) renders Ram, Board, Brace, Admiral's Command, and ability buttons for the first selected ship. refreshPanel() also renders Close action and Helm sections. TIPS.close can appear as soon as ramInfo(s) or boardTargets(s).length is true.

INFERRED: Ram and Board are advanced systems with long tooltips. Showing them alongside Done with ship and movement increases first-panel density and invites premature clicks.

9. Medium - Admiral's Command needs a second confirming tap but the first tap is not clearly a confirmation state

OBSERVED: ACT.command requires a second tap within G.cmdConfirmMs||6000. The action strip text prepends "Tap again (Ns): " only while B.cmdArm is set. The panel explains the Command and power tiers.

INFERRED: A new player may tap Command, see the label change, and not understand they must tap again. Or they may tap twice quickly and use a once-per-battle ability at low power by accident.

10. Medium - End card does not explain what "captured" means or what to do next in skirmish

OBSERVED: endBattleFlow() shows captured count and buttons. It does not link to rewards in skirmish. captured is set in boardUnit() when crew reaches zero.

INFERRED: A new player who captures a ship sees "Captured N ships" but no explanation of whether it persists, because the skirmish end card has no campaign continuation.

11. Medium - Campaign map, if reached, is dense and under-explained

OBSERVED: mapScreen() renders node icons, legend, encounter preview, side panel with Credits, Command points, Admiral, Fleet, Boons, Patrons, Relics. rewardFlow() introduces credits, boons, refits, relics, promotions, and salvage in sequence.

INFERRED: If the campaign map is the true first screen, it presents many named systems without a first-time explanation. The map's "Choose a pulsing node" instruction is clear, but the side panel is not.

12. Low-medium - Naval vocabulary conflicts with space-ship constraint

OBSERVED: Copy uses "Admiral," "shipyard," "drydock," "prow," "port," "starboard," "broadsides," "boarding," "ram," "hull," "crew."

INFERRED: The brief requires space ships, never naval ships. Some terms are genre-standard, but "drydock," "broadsides," and "boarding" read naval. This is a copy/identity issue more than a mechanical blocker.

4. Concrete fixes ordered by value

Fix 1 - Resolve the first-flow mismatch: either start the campaign or label the first flow as skirmish

What changes: ui3d.js, ACT.begin and/or endBattleFlow; campaign_run.js, add/choose a campaign entry function if campaign is intended.

OBSERVED: ACT.begin currently removes the intro and selects a ship in the already-built skirmish. endBattleFlow shows skirmish buttons when !B.campaign.

Concrete fix:

If Voidsworn is meant to be a campaign roguelite first: after ACT.begin, initialize the campaign run and call campaign_run.mapScreen() instead of dropping into startBattle from setupBattle. This requires a campaign-start function that sets RUN with map, fleet, admiral, credits, cpCap, boons, relics, and B.campaign=true. The granted files do not show that function, so this is a new small entry point, not a redesign.

If skirmish is meant to be the first ten minutes: change showIntro() heading from "Voidsworn / 3D skirmish" to "Voidsworn / Skirmish" and change endBattleFlow end card to say "Skirmish complete. No campaign rewards in this mode." Add a Start campaign button only if campaign entry exists.

Why first: The first ten minutes currently do not show the campaign loop that campaign_run.js is built around. This is the largest mismatch between code and player expectation.

Fix 2 - Stop rebuilding the battle on every setup pick; build only on Begin

What changes: ui3d.js, ACT.pick and ACT.begin.

OBSERVED: ACT.pick calls setupBattle({[k]:nv}) and showIntro().

Concrete fix:

Change ACT.pick to update SETUP only and re-render showIntro().

Move the setupBattle(SETUP) call into ACT.begin before removing the intro.

Keep setupBattle as the single build point.

New UI text: In showIntro, add under the title: "Pick a fleet and opponent, or press Begin engagement to use the defaults."

Why second: It removes first-minute hitches and makes the setup screen behave like a setup screen.

Fix 3 - Progressive disclosure in the setup overlay

What changes: ui3d.js, showIntro().

OBSERVED: showIntro() renders all pickers at once.

Concrete fix:

Show only Your fleet, Opponent, and Begin engagement by default.

Put Engagement, Battlefield, Deployment, Encounter, Arena, Board, and Turn order behind an Advanced setup toggle.

Add a one-line default summary: "Default: Voidsworn vs Hegemony, Engagement, alternating activations, random battlefield."

Rename Engagement options to plain language: Skirmish (equal fleets) and Flagship battle (both sides bring a titan).

New UI text: Advanced setup / Hide advanced setup; Defaults are fine for your first battle.

Why third: Reduces first-screen decision load without removing options.

Fix 4 - Sequence the tutorial tips and make the first tip match the actual state

What changes: ui3d.js, TIPS, tutorialCheck(), ACT.begin.

OBSERVED: ACT.begin selects a ship before the start tip. TIPS.select appears immediately after because !!s is true.

Concrete fix:

Do not auto-select a ship in ACT.begin until the start tip is dismissed, or change TIPS.start to: "Your first ship is selected. The green ring is under it. Gold hexes show where it can move; the fans show its firing arcs."

Add a tipQueue array. tutorialCheck() should show only the next queued tip whose condition is true, and not show a later tip until the previous is dismissed.

Gate select on the player having not yet moved: select: !!s && !me.some(x=>x.hexMoved>0).

Gate target on the player having hovered or selected an enemy, not merely OV.targets.length>0. Add B.hasHoveredEnemy in onHover().

Gate resolve until the player has fired or ended one activation.

Gate close until after the player has moved or fired once.

New tip text for start: "Your first ship is selected. Green ring: your ship. Gold hexes: where it can move. Fans: where its guns can fire. Hover a gold hex to preview the move."

Why fourth: The tutorial currently corrects a state the game created. Fixing this restores trust before teaching movement.

Fix 5 - Teach alternating activation before the first pass

What changes: ui3d.js, actionStrip() and aiStep().

OBSERVED: endActivation() and aiStep() implement alternating activations. refreshTop() changes the button text to End activation, Pass, or Continue depending on state. aiStep() has no "Enemy activation" banner.

Concrete fix:

Change the first-turn actionStrip hint to: "You control one ship at a time. Move and fire, then press Done with ship. One enemy ship then activates."

Change the top button text in alternating mode to always start with Done with ship when a player ship is active, or Pass only when the player explicitly chooses to skip.

Add banner('Enemy activation','#e07a70') at the start of aiStep() when running one enemy activation, and banner('Your activation') when returning to the player.

Add a small top-bar sublabel: Alternating: one ship each.

Why fifth: This is the feel target. If the player does not understand one-ship-at-a-time, the first battle reads as a confusing whole-fleet turn.

Fix 6 - Add a first-shot confirmation and separate "inspect" from "fire"

What changes: ui3d.js, onBoardClick() and attackTip().

OBSERVED: Clicking an enemy with a player ship selected fires all weapons in firingSet(s,u).

Concrete fix:

First time the player clicks an enemy with a valid firing set, do not fire. Set B.pendingFire={ship:s,target:u,set} and show a small confirm bar: "Fire N weapons at [target]? Expected: X shield, Y hull. [Fire] [Cancel]."

Add ACT.confirmFire and ACT.cancelFire.

After the first confirmed shot, allow one-click firing as now.

Rename hover tooltip from "Click to fire" to "Click to fire; first shot asks for confirmation."

Why sixth: Prevents accidental first combat decisions and teaches expected damage before the first shot.

Fix 7 - Make the first move teach facing and motion with a forced hover preview

What changes: ui3d.js, actionStrip() and refreshHover().

OBSERVED: refreshHover() draws a ghost and dashed path. driveLine() and moveNote() explain motion and thruster costs. The select tip explains ghost preview and Q/E.

Concrete fix:

In the first player activation, add a strip hint: "Hover a gold hex. The ghost shows your end hex and facing. The tooltip shows guns that can fire from there."

Add a one-time highlight on one safe reachable hex near the player's deployment, not all gold hexes. refreshOverlays() can add a firstMoveHex tile when !META.opts.tips.moved.

After the first move, show: "You ended still/evasive. Still: enemies get +X to hit. Evasive: enemies get −X to hit. Facing controls your arcs."

Why seventh: Movement is the first core decision. Hover preview exists but is not forced; a first-move highlight makes it discoverable.

Fix 8 - Hide Ram, Board, Command, and Brace from the first action strip until after the first move/fire

What changes: ui3d.js, actionStrip().

OBSERVED: actionStrip() always renders Done with ship, ability, Command, Ram, Board, Brace, Center, and ? when the selected player ship is active.

Concrete fix:

Add B.firstActivationDone set true after the player's first move or first shot.

In actionStrip, render only Done with ship, Center, and ? before that. Show a small "More actions unlock after your first move or shot" note.

After the first move/shot, render Ability, Command, Ram, Board, Brace as now.

Keep ? help available; update it to explain the newly unlocked buttons.

Why eighth: Reduces first-panel density and prevents premature Ram/Board/Command use.

Fix 9 - Fix the skirmish end card and explain "captured"

What changes: ui3d.js, endBattleFlow().

OBSERVED: End card shows captured count and skirmish buttons. It does not explain persistence.

Concrete fix:

In skirmish, change summary line to: "Captured ships are a battle result only in skirmish; campaign captures join your fleet after the battle."

Add a Next button that says Fight again and a secondary Change setup.

If campaign, keep Continue the campaign but add a one-line "Next: choose a node on the sector map."

Why ninth: Prevents the player from expecting campaign persistence in a skirmish or missing the next step.

Fix 10 - If campaign map is reached, add a first-node coach and simplify the first map

What changes: campaign_run.js, mapScreen().

OBSERVED: mapScreen() renders legend, encounter preview, side panel with many systems. It instructs "Choose a pulsing node to jump there."

Concrete fix:

On the first campaign map (RUN.sector===1 && !RUN.seenFirstMap), add a single coach card over the map: "Pick a pulsing node. Battles give credits and a reward. Shipyards repair and sell hulls/refits. Drydocks repair free. Start with the battle node."

Hide encprev until the player hovers a node, or collapse it to one line: "Encounter: Engagement. Reward: Boon of [Patron]."

Add a ? button in the side panel that explains Credits, Command points, Boons, Patrons, Relics in one modal. Do not add new systems; only explain existing ones.

Why tenth: Only relevant if the campaign is the first flow, but if so it is high value. The map is dense and the side panel is not self-explanatory.

Fix 11 - Audit and replace naval copy for space-ship identity

What changes: campaign_run.js NODE_INFO, ui3d.js TIPS, actionStrip, refreshPanel, attackTip, weaponLine.

OBSERVED: Copy includes "Admiral," "shipyard," "drydock," "prow," "port," "starboard," "broadsides," "boarding," "ram."

Concrete fix:

NODE_INFO.shipyard.d: "Buy hulls and refits, repair, upgrade Marks" is fine, but change "Shipyard" to "Refit yard" or "Orbital yard."

NODE_INFO.drydock.n: change Drydock to Repair cradle or Orbital repair dock.

TIPS.close: change "Boarding (G) sends crews into an adjacent enemy" to "Breach-and-seize (G) sends crews into an adjacent enemy."

actionStrip: change Ram to Collision charge; Board to Breach & seize.

refreshPanel weapon line: change "broadsides" in boonMods and attackTip to "flank batteries."

Keep prow, port, starboard only if the game's ship art uses them; otherwise use forward, left flank, right flank.

Why eleventh: Copy identity, not mechanical blocking. It matters because the brief explicitly requires space ships, never naval ships.

Fix 12 - Reduce TIPS from eight to five and add a "show later" for advanced tips

What changes: ui3d.js, TIPS, tutorialCheck().

OBSERVED: TIPS has eight entries. close, resolve, and objective can appear in the first ten minutes even though they are advanced or mode-dependent.

Concrete fix:

Keep first-battle tips: start, move, target, fired, shields.

Move resolve, close, objective to a second tier shown only after the first battle round or from the ? help card.

Add Show later to the tip card. ACT.tipLater marks the tip deferred, not seen, and re-queues it after the next round.

Add a ? help card in the action strip that contains the advanced explanations.

Why twelfth: Reduces tip cascade and stops advanced systems from competing with the first move.

Not specified

OBSERVED: The following are referenced but not defined in the granted files, so their exact behavior cannot be determined:

titleScreen(): called by ACT.saveQuit in campaign_run.js, not defined in the granted files.

ACT.c3title: referenced by buttons in ui3d.js, not defined in the granted files.

ACT.c3continue: referenced by endBattleFlow() when B.campaign, not defined in the granted files.

newShip(), derive(), changeShip(), changeFleet(), HULLS, FACTIONS, W, ABILITIES, PERKS, RANKS, RANK_XP, MODULES, MODULE_POOL, BOONS, PATRONS, RARITY, RELICS, ARCHETYPES, EVENTS, ADMIRALS, ASPECTS, REGIONS, MOVE_RULES, AI_LEVEL, META, Persist, tel, toast, SFX, FRAMES, G, MB, V3, C3, HS, HW, hexWorld, worldHex, animPath, animMove, animRotate, animWeapon, animExplode, fxText, fxShield, fxShieldBreak, fxRam, fxBoard, fxNova, fxBlink, fxWithdraw, buildBattleEnv, disposeAllViews, clearOverlays, hideEnd, stackTop, touchWords, hpBar, pct, roman, esc, rnd, ri, pick, shuffle, hkey, hdist, DIRS, boardHexes, boardBounds, occMap, unitAt, terr, blocks, inArc, los, hexLine, computeReach, stateView, expectedVs, shieldQuad, QUAD_NAME, ARC_NAME, SEC_NAME
