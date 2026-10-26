# Campaign screen information audit, Gemini Argon leg, 2026-10-26

Chair header: filed as the single reviews copy for the Gemini leg (house pattern). Model: Gemini 4 Argon, Thinking level High, verified in two places before submitting ("Argon High" on the mode-picker button and the prompt bar dropdown; the open picker also showed "Selected 4 Argon" and "Selected High"). The leg waited out a stated Argon rate limit (options disabled until 3:10 PM CDT) before running, 2:49-3:22 PM CDT. Six files attached (leg prompt, evidence pack, map_intel.gd, map_view.gd, campaign_host.gd, campaign_fallback_ui.gd; campaign_ui.gd and map3d.gd reached the leg through the evidence pack's quoted line references). Inline markers of the form [cite: N] in the text are Gemini interface citation artifacts, not model prose; they are preserved as returned. Model text follows verbatim.

---

Campaign Screen Information Audit (Brief muse_2026-10-26c, Job 4)

This review evaluates the information design of Voidsworn's campaign screens in Godot 4.7 against the commissioning criteria (R36 and R38) and the four reference games: Sins of a Solar Empire 2, BattleTech (2018), Warhammer 40,000: Rogue Trader, and Middle-earth: Shadow of Mordor. Visual beauty, layout feel, and visual clutter as seen on a monitor are out of scope because no screenshots exist; any judgement that depends on rendered screen appearance is tagged UNSURE. All claims about comparison games are drawn from reviewer memory of primary game systems and official documentation rather than live-opened web pages during this session, with canonical reference links provided for each title.

1. Route Planning

Verdict: PARTIAL (strong on the default 3D map, incomplete on route payout details and column danger scaling, and absent on the 2D flat map). Whether the 3D map's multi-line route overlays and node chips remain legible without visual overlap is UNSURE without screenshots.

Pack Evidence

Forward-only commitment: Movement across the column graph is one jump at a time with no undo in any fetched file (pack section 1; map3d.gd lines 630 to 639; campaign_ui.gd line 406). Reachable next nodes are marked by animated lane flow and colour on the 3D map (map3d.gd lines 419 to 429), dashed gilt lines on the 2D map (map_view.gd lines 41 to 44), and pulsing node rings on both maps (pack section 1; map3d.gd line 459; map_view.gd lines 46 to 50).

Node identity and next-fight previews: Before jumping, every node shows its type via a 3D scene or 2D icon alongside a page legend row (pack section 1; map3d.gd lines 243 to 356; campaign_ui.gd line 381; map_view.gd lines 74 to 98). Unpassed fight nodes print the encounter name and short modifier name below the node and the board name above it on both maps, while the 3D map also prints board shape and modifier under the danger chip (pack section 1; map3d.gd lines 485, 508 to 516; map_view.gd lines 56 to 59). Beneath the map, deduplicated preview panels list full text descriptions for every currently reachable encounter, archetype, and node modifier, plus the elite flag, board shape, and reward line (pack section 1; campaign_ui.gd lines 384 to 406).

Rewards on map: Boon nodes display the patron's coloured sigil disc, glyph, short name, and a star when guaranteed rare or better, while other nodes print plain labels for Refit, Credits, or Repairs (pack section 1; map3d.gd lines 513 to 519; map_view.gd lines 61 to 68; campaign_ui.gd lines 432 to 439).

Safest and richest route comparison (3D map only): Hovering any node enumerates all forward paths from currently reachable nodes through that hovered node to the sector flagship (map_intel.gd all_paths and routes_through, lines 66 to 127) and highlights the Safest route in cyan (#62ccff) and the Richest route in gold (#e0b04a) (pack section 1; map_intel.gd lines 125 to 126). Every node along a lit route receives a running-total chip showing fights so far and repair stops so far (pack section 1; map3d.gd lines 522 to 526). The cursor hover card prints totals for both routes: fight count (with elite count), repair stops, shipyards, boons, refits, relics, and the worst fight's danger band name in its band colour, excluding the sector boss because it ends every path (pack section 1; map3d.gd lines 597 to 604; map_intel.gd line 100).

Observed gaps in route planning:

Unprinted route payouts: map_intel.gd path_stats (lines 79 to 105) counts credits nodes and events nodes and uses both in the Richest route scoring formula (boons * 3 + relics * 4 + refits * 2 + credits + shops * 2 + events), and it also computes a repair_before_boss boolean and a per-node running danger sum. However, the 3D hover card (map3d.gd lines 597 to 604) never prints the credits count or events count in the route summary, and the on-node running chips (map3d.gd lines 522 to 526) omit the running danger sum (pack section 1). A route can win the "Richest" highlight because of credit and event nodes without the hover card showing why.

Only two extreme paths shown per hover: routes_through filters all paths through the hovered node down to at most two paths: Safest and Richest (map_intel.gd lines 115 to 127). If a third path offers a better balance (for example, hitting a critical late repair stop just before the boss at slightly higher danger), the player can only discover it by hovering deeper downstream nodes one by one.

Static fleet power baseline across future columns: map_intel.gd danger() (lines 29 to 58) calculates every node's threat using its column index (col * 0.9, 1.0, or 1.1) against fleet_power(), which is the player's fleet power right now (pack section 3; map_intel.gd lines 4 to 9, 17 to 36). Because the player's fleet will grow across columns through boons, relics, refits, and shipyards, late-column fights on a route are judged against an unscaled starting fleet, inflating the "worst fight" band reported for full-sector routes.

Flat 2D map omission: When use_3d_map is false, map_view.gd provides no route highlighting, no running totals, no danger bands, and no route comparison tooltip (pack section 1 and Gaps item 7; map_view.gd lines 103 to 114).

Keyboard accessibility uncertainty: Whether keyboard focus cycling (map3d.gd lines 618 to 627) visibly opens the 3D hover card and route planner in the running game is UNSURE from code alone (pack section 1).

Comparison Games

Sins of a Solar Empire 2 (from memory): The 3D star map and phase lane network allow the player to inspect gravity wells, planetary resources, and phase lane connections at any zoom level (Stardock / Ironclad Games, Sins of a Solar Empire II Manual and Steam Dev Journals: https://store.steampowered.com/app/1575940/Sins_of_a_Solar_Empire_II/). When plotting multi-jump fleet movement across phase lanes, the UI highlights the exact path, shows jump-by-jump transit nodes, and reveals known garrison fleet compositions and starbase defences at each gravity well before the fleet commits to the jump. Voidsworn's 3D lane flow and Safest/Richest path lighting match Sins 2's path clarity well, though Sins 2 lets players inspect any intermediate path freely rather than pre-selecting only two scored extremes.

BattleTech (2018) (from memory): On the Argo's Starmap, selecting a destination system plots the jump path, calculates exact travel days and financial runway costs against the upcoming monthly financial report, and displays system tags (such as manufacturing hubs, black markets, or repair facilities) before travel begins (Harebrained Schemes, BattleTech Paradox Wiki, Starmap and Contracts: https://battletech.paradoxwikis.com/Starmap and https://battletech.paradoxwikis.com/Contracts). On the Contract Board, before launching a drop, the player sees exact maximum pay, maximum salvage rights, employer/target factions, biome (which governs heat dispersion), and contract type description. Voidsworn goes further than BattleTech in multi-jump combat route scoring by aggregating boons, relics, and repair counts to the boss, but BattleTech never hides a payout category (like credits) that contributed to a route's value.

Warhammer 40,000: Rogue Trader (from memory): The Koronus Expanse voidship chart shows warp routes colour-coded by warp danger (Green/Safe, Yellow/Unsafe, Orange/Dangerous, Red/Deadly) and lets the player spend Navigator's Insight to lower route risk or carve new passages before committing to a jump (Owlcat Games, Rogue Trader Community Wiki, Voidship and Koronus Expanse Navigation: https://roguetrader.wiki.fextralife.com/Koronus+Expanse). Clicking a system displays explored points of interest, rumors, and resource extractors. Voidsworn's per-node running chips (fights and repairs so far) give better cumulative attrition pacing than Rogue Trader's single-jump warp lines, provided the player uses the 3D map.

2. Information at a Glance

Verdict: PARTIAL (fleet condition, economy, and build state are thoroughly surfaced in the side panel, but active sector rules are buried in a hover tooltip, Heat modifiers are absent from the map page, numeric sector progress is missing, and Nemesis tactical rules are omitted). How much of the scrollable 380-unit side panel is visible without scrolling at standard resolutions is UNSURE without screenshots.

Pack Evidence

Always-on resources and command cap: The 380-unit side panel (campaign_ui.gd _side, lines 462 to 514) displays Credits and Command points (used out of cap) as large readouts at the top of the panel, followed by the admiral's name, doctrine, and faction action panel (showing the faction verb, description, cost text, or "Used this sector") (pack section 2).

Fleet condition ship by ship: The side panel lists one row per ship with its name, flagship star, numeric hull and a 20-segment hull bar, hull class, Mark level, captain rank and name, a readiness status word (Ready at 70% hull or above, Damaged at 40% to 69%, Crippled below 40%), free refit slots (or "refit to fit"), and promotion-ready flags, plus a Manage fleet button that changes its label to "Promote captains and refit" when a promotion is waiting (pack section 2; campaign_ui.gd lines 462 to 514). When average fleet hull drops below 65% or any ship falls below 40% (map_intel.gd fleet_condition, lines 129 to 134), the panel prints a conditional warning with average hull percentage and states either "Plan a repair stop before the flagship" or "No repair stop is left on any route to the flagship" (pack section 2; campaign_ui.gd lines 491 to 497).

Build state (aspect, boons, relics, hold): Below the fleet list inside the side panel's ScrollContainer (campaign_ui.gd lines 466 to 468), the UI prints the count of refits in the hold, the flagship's aspect name and description, every boon with its full text, active patrons, and every relic with its full text (pack section 2 and section 5). Because the container scrolls, these lower build sections are always on the page in code but become on-demand via scrolling as the fleet and boon lists grow (pack section 5).

Buried in hover tooltips (1 hover away): The top intel strip (campaign_ui.gd _intel_strip, lines 410 to 437) draws up to five small boxes: Hostile presence, Rival raiders, Sector condition, Patrons watching, and Nemesis (pack section 2 and section 5). Crucially, the Sector condition box prints only the condition's name; its mechanical effect on the sector is written only inside the hover tooltip (campaign_ui.gd lines 424 to 425, pack section 5). Faction blurbs, the rival-raiders spawn rule (roughly 1 in 5 ordinary fights), and the patron sigil rule are likewise tooltip-only (pack section 2 and section 5).

Buried in one-time modals: Full Nemesis adaptation intelligence (why he adapted and what the adaptation does) appears only in the sector-change modal (campaign_ui.gd lines 897 to 899) and has no home on the map screen once dismissed (pack section 4 and section 5).

Absent from the map page:

Active Heat rules: Heat modifiers chosen for the run are printed on the aspect selection screen (campaign_ui.gd lines 354 to 358), but no fetched map-page code displays them during the sector (pack section 2), even though h_flag, h_hunted, and h_elite actively scale enemy budgets and threat in map_intel.gd (lines 41, 45, 53). Whether another screen outside this fetch repeats Heat rules is UNSURE (pack section 2).

Numeric sector progress: Progress is shown only spatially through darkened passed nodes, gilt traversed lanes, and the fleet token position (map3d.gd lines 402 to 408; map_view.gd lines 47 to 53); no fetched file draws a numeric counter such as current column or nodes cleared out of total columns (pack section 2 and Gaps item 6).

Nemesis behaviour and hidden counters: Faction strike rules (beh.d), persona, traits, fed, and riches are never shown on the map page (pack section 4 and Gaps item 8).

Comparison Games

BattleTech (2018) (from memory): The Argo campaign screen keeps a permanent top-left financial and morale bar (C-Bills, monthly operating expense, days until financial report, and crew morale tier), a permanent timeline/task tracker on the right showing exact days remaining for every active 'Mech repair, refit, and MechWarrior injury, and an always-visible 'Mech Bay summary (Harebrained Schemes, BattleTech Paradox Wiki, Argo and Finances: https://battletech.paradoxwikis.com/Argo). Voidsworn's per-ship readiness row and conditional "No repair stop is left on any route" warning are superior for a forward-only node runner, but BattleTech never hides an active campaign-wide difficulty modifier or time/column counter from the main HUD.

Sins of a Solar Empire 2 (from memory): The top bar permanently displays credits, metal, crystal, exotic resource counts, fleet supply cap / used supply, and research tiers, while the pinned fleet empire tree on the left lists every fleet's ships, hull/shield bars, and active empire alerts (Stardock / Ironclad Games, Sins of a Solar Empire II Wiki: https://sinsofasolarempire2.wiki.fextralife.com/). Active global or system effects (such as phase storms or culture buffs) display persistent status icons with clear inline summaries.

Warhammer 40,000: Rogue Trader (from memory): On the Koronus Expanse map, Profit Factor, Hull Integrity, Voidship Morale, Scrap (for repairs), and Navigator's Insight are pinned to the persistent HUD frame alongside a quest/rumor tracker (Owlcat Games, Rogue Trader Wiki, Voidship Management: https://roguetrader.wiki.fextralife.com/Voidship+Management). Voidsworn matches this well with its pinned Credits, Command Points, and per-ship 20-segment hull bars, falling short only where active run/sector rules (Heat and Sector condition effects) are either omitted or tucked into a tooltip.

3. Danger Readability

Verdict: PARTIAL (the 3D map's expected-threat calculation, four-band scheme, percentage hover readout, and multi-channel elite/boss/rival markings are well-designed, but the flat 2D map omits danger estimates completely, Nemesis threat omits fed/riches and unitemised multipliers, and future-column nodes are compared against unscaled current fleet power). Whether danger is shown on pre-battle or battle screens and whether the band thresholds feel accurate in live play are UNSURE (pack section 3).

Pack Evidence

Expected-strength formula and four bands (3D map): map_intel.gd danger() (lines 29 to 58) mirrors the game's actual enemy fleet generation budget (column budget, RAMP.grow, elite 1.05x budget and 1.25x threat, boss scale tables, Standard AI factor, h_hunted, h_elite, h_flag, and bounty/veteran node modifiers) and divides threat by the player's current fleet_power() (pack section 3; map_intel.gd lines 17 to 58). It classifies the ratio into four colour-coded bands (map_intel.gd line 11):

Easy: ratio under 0.8 (green #7ddc6a)

Even: ratio under 1.05 (gold #d0a64b)

Hard: ratio under 1.4 (orange #f0883a)

Deadly: ratio 1.4 and above (red #e2453a)

Where danger appears: Every unpassed fight node on the 3D map draws a coloured band chip in capitals underneath the node (map3d.gd lines 506 to 512), the hover card prints Danger: <band> plus their strength about N% of your fleet's (map3d.gd line 580), and route summaries report the worst non-boss fight band along each lit route (pack section 1 and section 3; map_intel.gd lines 90 to 94).

Is an estimate with four bands the right design call? Yes. Because battle.js rolls the exact enemy ship composition when the fight starts (map_intel.gd lines 5 to 9), showing exact ship hulls before jumping would either lie or force pre-rolling every node before fleet power changes. Coupling a four-band categorical chip on the map (for fast visual scanning) with a continuous percentage ratio (about N%) on the hover card (so a player can tell an 81% Even fight from a 104% Even fight) is strong information design.

Special fight markings (Elite, Boss, Rival, Nemesis):

Elite fights: Marked across three independent channels on the 3D map: a brighter red diamond (#ff3a2a vs normal battle #e05a4a) inside a gold crown ring (map3d.gd lines 268 to 276), animated red hazard chevrons near the far end of incoming lanes (map3d.gd lines 70 to 73, 351), and the word "elite" in preview panels and route fight counts (pack section 3; campaign_ui.gd line 393). On the 2D map, elites use a distinct color (#e07a70) and a top triangle polygon (map_view.gd lines 45, 79 to 81)[cite: 4].

Boss fight: Drawn on the 3D map using the enemy flagship's own hull model at larger scale facing back down the sector inside a large red crown ring with a red light and the label "Sector flagship" (map3d.gd lines 277 to 288, 487; pack section 3), and as a crown polygon at larger radius (26.0 vs 19.0) on the 2D map (map_view.gd lines 27, 94 to 97).

Rival raiders: Marked on the 3D map with an extra ring in the rival faction's colour (map3d.gd lines 347 to 355), drifting patrol ships around unpassed rival nodes (map3d.gd lines 357 to 375), and (rival raiders) appended to the faction line in the hover card (pack section 3; map3d.gd lines 574 to 576).

Nemesis conversion: Marked on the 3D map with a red NEMESIS chip and a 38-unit portrait beside the node's tags (map3d.gd lines 492 to 499), and on the 2D map with the red word Nemesis above the node (map_view.gd line 60; pack section 4).

Observed gaps in danger readability:

Complete absence on the flat 2D map: map_view.gd never calls map_intel.gd and shows no danger bands, ratios, or rival faction rings anywhere (pack section 3 and Gaps item 7).

Unexplained Nemesis and modifier threat spikes: When a node is converted by the Nemesis, map_intel.gd treats it as an elite and multiplies threat by (1.0 + 0.1 * scars) * (1.0 + 0.06 * adapt.size()) (lines 33 to 34, 54), and when bounty or veteran modifiers or Heat flags are active, it multiplies budget or threat (lines 45 to 53). The hover card prints only the final percentage and band without itemising these multipliers (pack section 4). Furthermore, map_intel.gd line 54 does not read the Chorus fed counter or Corsair riches counter (pack section 4).

Column ramp vs. current fleet power: Because budget grows with col (map_intel.gd line 35) while P is static (fleet_power() now), nodes 4 or 5 columns ahead look artificially dangerous until the player reaches those columns.

Comparison Games

BattleTech (2018) (from memory): Uses a half-skull to five-skull rating system in 0.5-skull increments on the Contract Board, representing Darius Oliveira's intelligence estimate of enemy DropWeight, with a built-in variance of +/- 1 skull in actual missions (Harebrained Schemes, BattleTech Paradox Wiki, Contracts Difficulty: https://battletech.paradoxwikis.com/Contracts#Difficulty). Voidsworn's system is more transparent and responsive than BattleTech's skulls because Voidsworn recalculates node danger dynamically against the player's current fleet power (fleet_power()) and exposes the exact percentage ratio on hover, whereas BattleTech skulls are static per contract and hide the +/- 1 skull variance.

Sins of a Solar Empire 2 (from memory): Displays quantitative fleet supply numbers and militia/hostile fleet ship counts directly on gravity wells once scouted, allowing exact comparison of fleet supply and capital ship levels (Stardock / Ironclad Games, Sins of a Solar Empire II Manual: https://store.steampowered.com/app/1575940/Sins_of_a_Solar_Empire_II/). Voidsworn's hover percentage (about N% of your fleet's) bridges the gap between qualitative bands and Sins 2's hard numbers.

Warhammer 40,000: Rogue Trader (from memory): Uses four warp route danger tiers (Safe, Unsafe, Dangerous, Deadly) for voidship jumps and shows enemy Threat Ratings and individual ship hull/armor/weapon stats in space combat inspection (Owlcat Games, Rogue Trader Wiki, Space Combat and Navigation: https://roguetrader.wiki.fextralife.com/Space+Combat). Voidsworn's four danger bands (Easy, Even, Hard, Deadly) use the exact same four-tier granularity as Rogue Trader's warp chart while grounding the bands in a mathematical power ratio.

4. The Nemesis as Information

Verdict: FAIL (while identity, scars, clock progress, and node conversion are clearly surfaced, the campaign UI hides every mechanical payload that defines how the Nemesis fights and punishes the player: his faction strike behaviour beh.d, his strength traits, his persona, the combat effects of his weaknesses and adaptations on the card, his revive state, and his fed/riches scaling counters). Whether any pre-battle, battle, or toast screen outside this fetch surfaces these missing facts is UNSURE (pack section 4 and Gaps items 1 to 5).

Pack Evidence

What is surfaced (campaign_ui.gd _nem_panel, lines 516 to 540; map3d.gd lines 492 to 499; pack section 4):

Identity and scars: Full name (nemFull: title + name + epithet) in red, faction name, 76-unit portrait on the card and 38-unit portrait on his converted 3D node (with hash-derived portrait index and faction-specific visual scar overlays), and text "scarred Nx" when scarred.

Clock and strike warning: "Hunting you:" dot track (filled dots vs open dots up to NEM_CLOCK) on both the side-panel card and the intel strip box, plus standing explanation text ("Every fight you win moves the clock on; when it fills, your next fight is against him. You meet him once each sector at the latest before the rest stop.") and a bold red tail when his strike flag is set: "His fleet is coming: your next fight is his." (or "(met this sector)" after meeting him).

Converted node marking: Red NEMESIS chip and portrait on the 3D map (map3d.gd lines 492 to 499), red "Nemesis" label on the 2D map (map_view.gd line 60), hover card header "Nemesis: <nemFull>'s fleet", and elite threat scaling (+10% per scar, +6% per adaptation in map_intel.gd line 54).

Weakness and Adaptation names only: The card prints "Weaknesses:" with revealed names from NEM_WEAK in gilt (or "unknown" when unrevealed) and "Adapted:" with generic adaptation names from NEM_ADAPT in red.

What is never surfaced in fetched campaign files (pack section 4 and Gaps item 8):

Faction behaviour text (beh.d): Never read or printed anywhere in the seven fetched files. The player is never told on the campaign map what a faction strike does, that a Corsair strike can raid credits or steal a crippled ship, that a Deathless Nemesis revives once, or how other faction strikes operate.

Weakness effect descriptions: Only the name string from NEM_WEAK is printed on the card; the description field explaining what the weakness actually does in battle is omitted.

Adaptation effect descriptions and reasons on the card: The card prints only the generic NEM_ADAPT name, omitting both the effect description and the "why" string (which appear only once inside the transient sector-change modal at campaign_ui.gd lines 897 to 899, and only for adaptations recorded at a sector transition). Faction-flavoured adaptation names (NEM_ADAPT_FAC) are never read by the fetched UI files.

Strength traits and Persona: Neither his two strength traits nor his persona (name or description) are read or displayed anywhere in the fetched campaign files.

Hidden scaling counters (fed and riches) and Revived state: Neither fed (Chorus growth) nor riches (Corsair extra ships) is read in any fetched file, and nothing on the card indicates whether a Deathless Nemesis can still revive or has already spent his revive. Scar causes and epithet-change history are also absent.

Which missing item costs the player the most: The faction behaviour text (beh.d), closely followed by the mechanical effect descriptions of Weaknesses and Adaptations on the card. Without beh.d and the fed/riches counters, the player cannot make strategic campaign choices around the rival (for example, repairing a Crippled ship before the clock fills so a Corsair strike cannot steal it, or preparing for a Deathless resurrection). Without weakness and adaptation effect text on the card, the core counter-play loop of a persistent rival breaks down: knowing a rival has an adaptation or weakness by its title alone does not tell the player which weapons, ships, or tactics to bring into the fight once the one-time sector modal is closed.

Which surfaced item does the most work: The hunting clock dot track paired with the bold red strike state ("His fleet is coming: your next fight is his.") and pre-jump node conversion (NEMESIS chip + portrait). Together, these turn an abstract background timer into concrete spatial anticipation on the map: the player knows exactly how many fights remain before interception and can see which specific node the Nemesis has ambushed before committing to a jump.

Comparison Games and Rival-System Literature

Middle-earth: Shadow of Mordor / Shadow of War (from memory): Monolith Productions' Nemesis System is built on an explicit Army / Sauron's Army intel screen where every Uruk Captain and Warchief displays his Power rank, title, tribe/class, and categorized lists of Strengths (Immunities, Hate triggers, Class Traits, Bonuses) and Weaknesses (Mortal Vulnerabilities, Dazed/Fear triggers, Hints), each expandable with plain mechanical text explaining how to trigger or avoid it (Michael de Plater, GDC 2015 talk Shadow of Mordor: Designing the Nemesis System, GDC Vault: https://gdcvault.com/play/1021806/Shadow-of-Mordor-Designing-the; and Shadow of Mordor Official Wiki, Nemesis System & Intel: https://shadowofmordor.fandom.com/wiki/Nemesis_System). When an Uruk adapts or gains a scar after an encounter, both his intro bark and his Army card update his trait descriptions permanently so the player can adjust loadout and approach prior to combat. Voidsworn copies the unknown -> revealed weakness pattern and procedural scar portraits from Shadow of Mordor, but leaves off the mechanical trait/weakness tooltips and hides the rival's base class/faction behaviour and innate strength traits.

Warhammer 40,000: Rogue Trader and BattleTech (from memory): When recurring bosses or rival mercenary bands appear on the campaign map (such as Marazhai's raids in Rogue Trader or Flashpoint rival lances in BattleTech), the briefing panel states the faction's tactical doctrine, special modifiers, and what is at stake if the player delays or loses (Owlcat Games, Rogue Trader Wiki: https://roguetrader.wiki.fextralife.com/; BattleTech Paradox Wiki, Flashpoints: https://battletech.paradoxwikis.com/Flashpoints).

5. Information Layering and Duplication Risks at Code Level

Verdict: PARTIAL (camera framing cleanly separates the 3D chart from the 380-unit side panel, and three-tier danger layering works well, but the UI inverts priority on several facts by putting multi-sentence reachable-fight descriptions Always-On while burying active sector and Nemesis rules in tooltips or one-time modals, and code-level table/formula mismatches risk contradicting the player). How crowded the 7-item per-node overlay stack looks in practice is UNSURE without screenshots.

Pack Evidence

Is the Always-On set the right set? Mostly yes in the side panel (campaign_ui.gd _side, lines 462 to 514), which rightly pins Credits, Command Points, fleet readiness, and the Nemesis clock while letting long lists of boons and relics scroll (ScrollContainer, lines 466 to 468; pack section 5). However, on the main map area, two structural inversions exist in the code:

Reachable-fight preview panels (campaign_ui.gd lines 384 to 406) vs. Active rules: The map page dedicates permanent always-on space below the chart to full multi-sentence descriptions of every reachable encounter, archetype, and modifier (pack section 1 and section 5). Every single fact in those preview panels is already present either on the node labels themselves or inside the 3D hover card (map3d.gd lines 548 to 606). Meanwhile, the active Sector condition's mechanical effect (campaign_ui.gd lines 424 to 425) is hidden in a tooltip, Heat modifiers (campaign_ui.gd lines 354 to 358) are omitted from the map page altogether, and Nemesis weakness/adaptation effects are omitted from the side panel (pack sections 2, 4, and 5).

Per-node overlay density (map3d.gd _draw_overlay, lines 473 to 527): Every unpassed node on the 3D chart simultaneously draws: (1) encounter or type name, (2) NEMESIS chip and 38-unit portrait when converted, (3) danger band chip, (4) board shape and modifier sub-line, (5) reward label or patron sigil + short name, (6) board name above the node, plus (7) route running-total chips across two lit routes whenever any node is hovered (pack section 5). Because board name, board shape, and encounter name are tactical details needed mainly when inspecting a jump option, drawing all of them simultaneously on every unpassed node in the sector competes with the primary route-planning signals (node type, danger band, and reward).

Is hover carrying too much or too little?

3D Node Hover Card (map3d.gd lines 548 to 606): Carries the right amount of deep node inspection and route comparison, except that it omits credits and events counts from the route summary (map_intel.gd lines 81 to 104) and does not itemise threat multipliers on Nemesis or modified nodes (pack sections 1, 3, and 4).

Intel Strip and Side Panel Tooltips: Carry too much critical rule weight where no affordance signals that hovering is required, and too little where hovering is naturally expected. Specifically, the Sector condition box prints only a title and forces a hover to learn the sector's rule (campaign_ui.gd lines 424 to 425), whereas the Nemesis card's Weaknesses: and Adapted: lines have no tooltips or inline descriptions at all (campaign_ui.gd lines 536 to 540; pack sections 4 and 5).

One-Time Modals (campaign_ui.gd lines 897 to 899): Carry permanent state information (adaptation reason and effect text) that belongs on the persistent Nemesis card or its tooltips (pack sections 4 and 5).

Does duplication help or risk contradiction?

Helpful progressive disclosure (Danger): Repeating danger across three layers (4-band chip on node -> exact N% ratio in hover card -> worst-band summary per route) is good progressive disclosure because each channel answers a different question (local scan -> exact node evaluation -> full-path comparison) and all three read from the exact same map_intel.gd danger() function (pack sections 1, 3, and 5; map_intel.gd lines 29 to 58).

Redundant clutter (Nemesis clock and Reachable-fight panels): Showing the Nemesis name and clock dots in both the top intel strip (campaign_ui.gd lines 428 to 430) and the always-visible side-panel Nemesis card (campaign_ui.gd lines 530 to 532) on the exact same screen is pure duplication; even the strip box's tooltip text is word-for-word identical to line 533 of the side-panel card (pack section 4 and section 5). Likewise, the bottom reachable-fight preview panels (campaign_ui.gd lines 384 to 406) duplicate the 3D hover card and on-node labels (pack section 5).

Contradiction risk 1 (Generic NEM_ADAPT vs. Faction NEM_ADAPT_FAC): The side-panel card and sector modal both read generic adaptation names from NEM_ADAPT (campaign_ui.gd lines 537 to 540, 897 to 899), leaving NEM_ADAPT_FAC unused in the fetched campaign UI files (pack section 4). If campaign.gd or the battle UI uses NEM_ADAPT_FAC, the campaign card and combat UI will call the same adaptation by different names.

Contradiction risk 2 (map_intel.gd Nemesis formula vs. fed / riches): map_intel.gd line 54 computes Nemesis threat from scars and adapt.size() but ignores fed and riches (pack section 4; map_intel.gd line 54). Whenever Chorus fed or Corsair riches buffs the actual enemy fleet in combat, the campaign danger estimate will under-report the fight's true strength.

Contradiction risk 3 (3D map vs. 2D map feature parity): Toggling use_3d_map off (campaign_ui.gd line 40) drops map_intel.gd entirely, stripping the player of danger estimates, route comparisons, fleet-hurt route checks on the map, and rival rings (map_view.gd; pack sections 1, 3, and 5).

(a) Ranked Fixes and Improvements (Ordered by Decision Value per Unit of Build Effort)

Surface Nemesis behaviour (beh.d), traits, persona, and Weakness/Adaptation effect descriptions on the Nemesis card (campaign_ui.gd _nem_panel, lines 516 to 540):

Why: Highest decision impact for minimal UI work; the data tables (beh.d, NEM_WEAK descriptions, NEM_ADAPT / NEM_ADAPT_FAC descriptions and reasons, traits, persona) already exist in the campaign data (pack section 4). Printing or attaching rich tooltips to each Weakness and Adaptation on the card, plus a 1-line faction strike summary (beh.d), makes the Nemesis tactically legible throughout the sector instead of only during a one-time sector modal.

Surface fed (Chorus), riches (Corsair), and Deathless revive status on the Nemesis card and wire fed/riches into map_intel.gd danger() (line 54):

Why: Very low effort (reading existing fields on C.RUN["nem"]) that closes the Job 2 visibility gap and prevents map_intel.gd from under-reporting Nemesis fleet strength when Chorus or Corsair counters scale his fleet (pack section 4; map_intel.gd line 54).

Print active Sector Condition effect text inline (or in the side panel) and add an active Heat rules box to the intel strip (campaign_ui.gd lines 354 to 358, 410 to 437):

Why: Low effort. Moves active sector-wide and run-wide combat modifiers out of hidden tooltips or pre-run screens so the player never forgets an active rule mid-sector (pack section 2 and section 5). Also replace the redundant Nemesis clock box in the intel strip (campaign_ui.gd lines 428 to 430) with the active Heat rules box + numeric sector column progress (Column X / Y), since the Nemesis clock is already always visible on the side-panel card (campaign_ui.gd lines 530 to 532).

Add credits and events counts (and repair-before-boss flag) to the 3D hover card route summary (map3d.gd lines 597 to 604):

Why: Trivial effort (path_stats in map_intel.gd lines 79 to 105 already calculates st["credits"], st["events"], and st["repair_before_boss"]). Ensures the player can see every reward category that caused a path to be scored as the "Richest" route.

Itemise threat modifiers in the 3D hover card (map3d.gd line 580) and normalize or annotate future-column danger scaling (map_intel.gd lines 35 to 56):

Why: Low-to-medium effort. Appending a short breakdown to the hover card danger line (for example, includes +20% from 2 scars, +10% bounty) explains why a node is Hard or Deadly, and either projecting expected fleet growth by column or noting (vs. current fleet) prevents late-sector route bands from looking artificially alarming at column 0 (pack sections 1, 3, and 4; map_intel.gd lines 29 to 58).

Trim always-on 3D node label stack (map3d.gd _draw_overlay, lines 473 to 527) and make bottom reachable-fight preview panels collapsible or 2D-only (campaign_ui.gd lines 384 to 406):

Why: Low effort. Moving board name and board shape from the always-on per-node overlay to the hover card (keeping node type/encounter, danger band, reward/patron sigil, and Nemesis badge on the node) reduces per-node label competition, while folding the bottom preview panels reclaims vertical screen space on the 3D map where the hover card already shows full descriptions (pack section 1 and section 5).

Wire map_intel.gd danger bands and route summaries into map_view.gd (lines 45 to 68, 103 to 114):

Why: Medium effort. Brings the flat 2D map up to informational parity with the 3D map for players who toggle use_3d_map off (pack sections 1, 3, and Gaps item 7).

(b) Complete UNSURE List (Including All Judgements Waiting for Screenshots)

UNSURE (requires screenshots / running game): Visual legibility, spatial overlap, and perceived clutter of the 7 simultaneous overlay items drawn per unpassed node on the 3D map (map3d.gd _draw_overlay, lines 473 to 527) and the label stack on the 2D map (map_view.gd lines 56 to 68) (pack Preamble and section 5)[cite: 1, 2, 4].

UNSURE (requires screenshots / running game): How much of the 380-unit scrollable side panel (campaign_ui.gd _side, lines 462 to 514) is visible above the scroll fold at target monitor resolutions without scrolling, and whether boons, relics, and flagship aspect are cut off during typical mid-run fleet sizes (pack section 2 and section 5).

UNSURE (requires screenshots / running game): Overall visual beauty, typography hierarchy, colour contrast in practice, and layout feel of the header, intel strip, 3D star chart, bottom preview panels, and side panel together (pack Preamble).

UNSURE (requires running game test): Whether cycling reachable nodes with the keyboard (map3d.gd lines 618 to 627) visibly opens and positions the 3D hover card and Safest/Richest route planner without mouse movement (pack section 1).

UNSURE (outside fetched files, in campaign.gd or battle UI): How Nemesis weaknesses transition from "unknown" to revealed, and whether a reveal is announced to the player when it happens (pack section 4 and Gaps item 1).

UNSURE (outside fetched files, in battle/event UI): Whether Nemesis faction behaviour (beh.d), persona, strength traits, or danger bands are surfaced on any pre-battle, battle, or event screen outside the campaign map fetch (pack sections 3, 4, and Gaps item 2).

UNSURE (outside fetched files, in campaign.gd): Whether Nemesis adaptations gained outside a sector transition (such as Chorus post-meeting adaptations noted in Job 2) trigger any modal or toast announcement (pack section 4 and Gaps item 3).

UNSURE (outside fetched files, in campaign.gd): What campaign events raise bottom-centre toast messages (campaign_ui.gd lines 239 to 244), and whether clock fills, adaptations, or Nemesis strikes landing (such as a Corsair raid taking credits or a ship, or a tithe draining hull) are announced via toast or modal when they fire (pack sections 2, 4, and Gaps items 4 and 5).

UNSURE (outside fetched files, in campaign.gd / battle setup): Whether fed (Chorus) and riches (Corsair) enter enemy fleet generation in campaign.gd or battle.js in a way that diverges from map_intel.gd line 54, and whether any non-map screen repeats active Heat rules during a sector (pack sections 2, 4, and Gaps item 8).

UNSURE (requires playtest telemetry): Whether the four danger band thresholds (0.8, 1.05, 1.4 in map_intel.gd line 11) are calibrated accurately against actual player win rates and hull attrition in live play (pack section 3).

(c) One-Sentence Verdicts

Area 1 (Route planning): PARTIAL: The 3D map gives strong forward route comparisons with Safest and Richest path lighting, per-node fight/repair running totals, and full next-fight previews, but it omits credit and event counts from route summaries, evaluates late-column fights against unscaled current fleet power, and leaves the 2D flat map with no route planner at all.

Area 2 (Information at a glance): PARTIAL: The always-on side panel excels at showing credits, command points, ship-by-ship readiness, and low-hull repair warnings, but the map page buries the active sector condition's effect inside a hover tooltip, omits active Heat modifiers and numeric sector progress, and hides the Nemesis's tactical rules.

Area 3 (Danger readability): PASS (3D map) / PARTIAL (overall): Computing expected threat from the real fleet-generation numbers into four colour-coded bands on nodes plus an exact percentage ratio on hover and distinct 3D markings for elites, bosses, and rival raiders works very well on the default 3D map, held back only by unitemised Nemesis/modifier multipliers, unprojected column scaling, and the complete absence of danger bands on the 2D map.

Area 4 (The Nemesis as information): FAIL: Although the UI clearly tracks who the Nemesis is, his hunting clock, his strike readiness, and which node he has converted, it fails the core rival-intelligence loop by never surfacing his faction strike behaviour (beh.d), strength traits, persona, fed and riches counters, revive state, or the actual combat effects of his weaknesses and adaptations on his card.

Area 5 (Information layering and duplication risks at code level): PARTIAL: The code cleanly separates the 3D chart from the scrollable side panel and layers danger well, but it duplicates the Nemesis clock and reachable-fight descriptions in always-on space while burying active rules in tooltips or one-time modals, and risks contradicting the player across NEM_ADAPT vs NEM_ADAPT_FAC, uncounted fed/riches threat, and the 3D vs 2D map gap.

Overall Verdict: PARTIAL: Voidsworn's 3D campaign map builds a capable, mathematically grounded route-planning and fleet-readiness foundation on par with its reference games, but to meet the R36 and R38 commissioning bar it must surface the hidden mechanical rules of the Nemesis, active Sector Conditions, and Heat modifiers directly on the campaign HUD while cleaning up redundant channels and 2D/3D parity gaps[cite: 1, 2, 3, 4].
