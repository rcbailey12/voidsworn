# Red team audit, player persona: Argon leg

Chair header: Argon (Gemini, Argon High) leg for the Oct 30, 2026 red team audit, run from the player evidence pack and the persona leg prompt. Text below is the model report verbatim, with em dashes normalized to ASCII where they appeared.

Finding 1 (Severity 1, Overturns Claim: "Nemesis snowball keeping pace not snowballing (first adaptation is the lever)"): The Nemesis snowballs severely against typical battered fleets and Chorus runs, while the "first adaptation lever" and weakness counterplay are statistical mirages

Status: OBSERVED and INFERRED.

What breaks or underperforms: The claims register states that the Nemesis is "keeping pace not snowballing" and that "(first adaptation is the lever)". The pack's high-power rerun (measurements_addendum_2026_10_29.md) overturns both claims for actual campaign play: the first adaptation is minor compared to the base trait package, degraded fleets arriving at Sector 2 suffer a massive win-rate collapse because fleetPower indexing fails to compensate in Sector 2, the Chorus fast-cadence Nemesis snowballs into a near-unwinnable Sector 3 wall, and exploiting revealed Nemesis weaknesses provides no statistically significant combat advantage.

The evidence:

OBSERVED: The rerun weakened the Sector 2 step and decomposed it into "the trait package (about 8.5pp) plus one adaptation (about 2 to 7pp)", concluding that "No single adaptation drives the step, so there is no one-line tuning fix."

OBSERVED: For damaged fleets, the Nemesis growth cost widens "from +14.6pp at full strength to +28.1pp at 65% hull and +38.1pp at 40%." Because "battered arrivals are the typical case" and fleetPower indexing "works at sector 3 scale and barely at sector 2", the standard mid-run meeting punishes attrited players by 28.1pp to 38.1pp.

OBSERVED: The Chorus fast adaptation cadence is "the one genuinely snowball-shaped channel", adding "+30.8pp [+19.8, +41.9] at sector 3" and dropping the player to a "15.8% bot win rate".

OBSERVED: The combat value of knowing a Nemesis weakness was "REFUTED" in Sector 2 ("rerun +3.8pp, interval excludes 20") and "WEAKENED" in Sector 3 ("At this power no sector shows a significant weakness value").

What it costs the game: INFERRED: Even once the settled ruling ("Loss to the Nemesis still teaches a weakness") is built in code, the weakness the player carries home is mathematically hollow (+3.8pp), while arriving at the Sector 2 Nemesis with typical hull attrition turns the game's signature rivalry into a lopsided wipeout.

Finding 2 (Severity 2, Overturns Claim: "run win rate about 20 percent cross-validated"): The 20% campaign win-rate benchmark is invalid because the campaign simulator never spawns the campaign Nemesis, and runs actually die to Sector 2 elite stat-inflation rather than boss fights

Status: OBSERVED and INFERRED.

What breaks or underperforms: The claims register relies on "run win rate about 20 percent cross-validated" to validate the settled constraint that "Loss rate about 80 percent is intended". However, the pack admits that the campaign simulator used to produce that 20% win rate never spawns the campaign Nemesis, and its battle breakdown shows that bosses are low-lethality marathons while Sector 2 elites act as the real run-ending wall.

The evidence:

OBSERVED: measurements_addendum_2026_10_29.md notes that the true three-meeting trajectory is unmeasured because "the campaign runner never spawns the campaign Nemesis".

OBSERVED: In wave3_deepqa_2026_10_29.md (60 bot runs, 425 battles), "bosses are long rather than lethal (6.2 to 7.9 rounds, win rates 82 to 92%)", whereas "sector 2 elites carry the highest attrition of any class (1.32 ships lost per fight)".

OBSERVED: In the 400-run pool cited in loop_synthesis_2026_10_28.md, "sector 2 elites are the hardest fight class in the game (69.9% bot win rate)", enemy/player CP spikes from 0.97 in Sector 1 battles to 1.63 in Sector 2 elites, and "sector 2 is where the plurality of runs end (135 of 400)".

What it costs the game: INFERRED: First, adding a live campaign Nemesis (which wins 32.3% to 47.7% against full-strength bots and much more against battered fleets) onto a 20% non-Nemesis baseline will push true human win rates well below the intended 20% target. Second, runs do not end in climactic showdowns; they bleed out against over-statted Sector 2 elite nodes.

Finding 3 (Severity 3, Overturns Claim: "THE LOOP LEAKS, at run 4"): The retention loop breaks between Run 1 and Run 2 because of an unframed Run 1 loss, an unbuilt Nemesis loss debrief, and an invisible Run 2 AI difficulty step-up

Status: OBSERVED and INFERRED.

What breaks or underperforms: loop_synthesis_2026_10_28.md locates the retention failure at "THE LOOP LEAKS, at run 4", assuming novelty carries the first three runs. The pack's code evidence shows the loop breaking immediately across Run 1 and Run 2: Run 1 is near-impossible by design without telling the player, the Nemesis loss branch omits the ruled weakness debrief, and Run 2 silently promotes the enemy AI to veteran, canceling out the player's first meta-progression unlock.

The evidence:

OBSERVED: In firstrun_synthesis_2026_10_29.md, "Nothing in the first minutes frames the game's actual contract", and on the loss path nemAfterBattle "returns only the "drove you off" line", leaving the Oct 29 ruling ("a lost meeting still teaches a weakness on the debrief") "ruled and unbuilt".

OBSERVED: While a Sector 1 run that reaches the boss clears the 6 XP threshold and unlocks the "alternate fleet for run 2", loop_synthesis_2026_10_28.md reveals that "main3d.js sets AI_LEVEL to veteran once META.stats.runs is above zero" and "it is just invisible to the player".

OBSERVED: Even if a player triggers a Nemesis weakness mid-fight in Run 1, "the re-roll of weaknesses per run is fine", so that specific tactical discovery does not carry into Run 2.

What it costs the game: INFERRED: The settled constraint that Run 1 is near-impossible only works as a roguelite contract if Run 1 teaches a lesson and Run 2 feels empowered. Instead, the Run 1 loss debrief teaches nothing, the Nemesis rerolls its weakness, and an unannounced jump to veteran AI makes the player's newly unlocked Run 2 fleet feel no stronger than Run 1, driving churn before Run 4 ever arrives.

Finding 4 (Severity 4, Attacks Claim: "battle UI FRICTION (3 of 4) with phased activation ruled as the fix"): Phased activation stops accidental attack-moves, but leaves shield-blind move previews, unnamed damage targets, and 3-step manual weapon sequencing broken

Status: OBSERVED and INFERRED.

What breaks or underperforms: Phased activation is the settled battle UI direction ("a move beat with free rehearsal and inspect-only enemy clicks, then a fire beat") and claims register calls it "the fix" for battle UI friction. While phased activation prevents accidental fire-moves, it relies on "the planner's suggested position offered as a visible ghost" and does not fix defects inside the planner's math or inside the fire beat's weapon arming.

The evidence:

OBSERVED: In battleui_synthesis_2026_10_29.md, "bestFacingReach scores arrival states by ready gun count, then cost, then turns" and "it never weighs which of your own shield facings you present", while "arming a single weapon does not recompute it".

OBSERVED: This directly undercuts TIPS (ui3d.js), which instructs the player: "Keep your strongest shield facing the enemy."

OBSERVED: During move hover, "The expected-damage line for a hovered move does not name its target".

OBSERVED: During the fire beat, firing Ion shield-breakers before hull weapons is core tactics, but "the armed weapon resets after one shot and on every selection change", "so a sequenced salvo is three manual steps per ship."

What it costs the game: INFERRED: Because space ships have four directional shields and forward-arc weapons (guns never face backward), following the phased-activation ghost preview baits players into exposing battered shield facings just to bring an extra gun into arc, and executing a proper shield-strip salvo across a fleet remains high-friction busywork.

Finding 5 (Severity 5, Overturns Claim: "firstrun ONE SYSTEMIC TEACHING FAILURE"): First-run onboarding fails across three independent mechanisms, including a Battle 1 modal kill-switch trap paired with missing keysHelp bindings

Status: OBSERVED and INFERRED.

What breaks or underperforms: firstrun_synthesis_2026_10_29.md claims that all onboarding failures are "ONE SYSTEMIC TEACHING FAILURE" caused by "tutorialCheck returns whenever there is no battle object". The pack's own evidence refutes this single-root diagnosis: even during Battle 1 (when tutorialCheck is running), rapid-fire modal tips push players to click a permanent "Hide tips" button, and the help screen omits the exact combat hotkeys those suppressed tips were meant to introduce.

The evidence:

OBSERVED: In Battle 1, "Battle 1 can stack up to five modal tip cards 400 ms apart", "each carrying a permanent "Hide tips" kill switch".

OBSERVED: TIPS (ui3d.js) is the primary teacher for "Ramming speed (X)", "Boarding (G)", and "Press R, or Threat in the top bar", yet battleui_synthesis_2026_10_29.md confirms that "keysHelp omits R, X, G, F, T, and Home, several of them core combat inputs."

OBSERVED: Independently of both tutorialCheck and keysHelp, nemAfterBattle lacks the loss-branch weakness reveal and "Adaptation debriefing exists only on the boss-win path at sector transition."

What it costs the game: INFERRED: Fixing tutorialCheck on the campaign map will not fix Battle 1 modal spam or debrief omissions; a player who dismisses the 400ms popup stack in minute one loses all teaching for Threat (R), Ram (X), and Board (G) and cannot look them up in keysHelp.

Finding 6 (Severity 6, Attacks Campaign Routing & Boon Tax): Unlabeled map boon badges interact with patron kit-coverage and pool-exhaustion fillers to turn route planning into a blind trap

Status: OBSERVED and INFERRED.

What breaks or underperforms: loop_synthesis_2026_10_28.md places "Visible node routing with rewards shown on the map" on the protect list. Yet boons represent 62% of normal battle rewards and 100% of elite/boss rewards (economy_synthesis_2026_10_29.md), and the pack shows that map boon badges hide their meaning while the boon offer generator injects filler boons when fleet kits mismatch or a single patron is stacked past three boons.

The evidence:

OBSERVED: In firstrun_synthesis_2026_10_29.md, the map's boon badge strips a node to a glyph, short name, and star, "never printing the word "Boon" or what the star means", so "routing decisions (the campaign layer's core decision) are made blind".

OBSERVED: In measurements_addendum_2026_10_29.md, patron offers degrade into filler through two triggers: pool exhaustion ("exactly 1 filler per offer at 4 held and 2 at 5 held") and kit mismatch ("a gun-only fleet under Hunger starts with 2 fillers from the first node").

OBSERVED: Additionally, in wave3_deepqa_2026_10_29.md, "column 4 offers no elite" (1.87% of maps) because genSector at core.js:268 fails to convert rest-only columns ([drydock, drydock]), silently erasing the guaranteed pre-rest elite option.

What it costs the game: INFERRED: Because only 4 of 6 patrons appear per run and map nodes fail to explain their patron or star tier, players routing across the sector map unknowingly steer gun-only fleets into Hunger nodes (getting 2 fillers immediately) or over-stack one patron into guaranteed filler offers.

Finding 7 (Severity 7, Attacks Economy & Rulings Interaction): Accepting 0.0% repair tension eliminates credit scarcity after Sector 1, while a live repairMult wiring defect turns the h_repair Heat modifier into an unintended penalty

Status: OBSERVED and INFERRED.

What breaks or underperforms: The designer ruled that "Repair always beats scrap-and-replace per ship by design" and accepted that "repair tension binds in 0.0 percent of 60,000 modeled regroups". With repair priced at half the missing hull alongside four generous free-repair sources, credits stop mattering after Sector 1, and repairMult is wired to scale free healing rather than paid shipyard repair.

The evidence:

OBSERVED: Free healing saturates the campaign: "winning any battle patches every survivor 15% of max hull free", and "the post-boss transit patches 40% free, drydock nodes repair the whole fleet free", plus 20% at field repair nodes.

OBSERVED: As a result, "the pinch is sector 1 only; from the sector 2 yard onward, shopping replaces scarcity", and credits cease to be a tactical tradeoff.

OBSERVED: In code, "repairMult is live code at four call sites, all scaling FREE repair amounts", while "the shipyard's paid price (missing/2 x priceMult) never passes through it", meaning "the h_repair Heat condition at 0.5 halves free healing, functioning as a penalty".

What it costs the game: INFERRED: Regroup and shipyard stops in Sectors 2 and 3 become automatic shopping checklists rather than hard strategic choices, and players who take h_repair expecting a shipyard discount are punished with halved free hull recovery.

Finding 8 (Severity 8, Attacks Faction Economy & Capture Rules): Chorus carrier pricing and class-track upgrades violate the settled faction CP/price principle, while capture math rewards an add-then-decommission exploit

Status: OBSERVED and INFERRED.

What breaks or underperforms: A standing constraint sets the "CP principle: Eclipse stronger and pricier, Chorus the opposite, faction appropriate across stats, price, and CP." The economy audit (economy_synthesis_2026_10_29.md) proves that Chorus capstone pricing and class-track upgrades violate this constraint, while ship capture payouts ignore priceMult and ship hull condition.

The evidence:

OBSERVED: "The Chorus carrier at 370 is the most expensive carrier in the game", inverting the Chorus swarm discount on its flagship hull.

OBSERVED: "Class track costs are gated by priceMult but not FAC_PRICE", stripping faction price identity out of class upgrades.

OBSERVED: In capture resolution, "add-then-decommission at a flat 35% can beat a late-decay ransom", "Decommission pays the same 35% regardless of ship condition", and "Prize valuation ignores priceMult", losing roughly 20% of its buying power under the coffers Heat modifier.

What it costs the game: INFERRED: Optimal play after five captures requires gaming the UI by adding a crippled 1-HP captured space ship to the fleet and immediately decommissioning it for a flat 35% payout, while Chorus fleets pay top-tier prices for their carrier and class tracks in violation of their faction contract.

Finding 9 (Severity 9, Confirms Claim: "AI COMPETENT BUT HOLLOW (4 of 4)"): At equal fleet CP the enemy AI loses 94% of battles in 3.8 rounds, forcing the campaign to manufacture difficulty via raw CP inflation

Status: OBSERVED and INFERRED.

What breaks or underperforms: Confirming "AI COMPETENT BUT HOLLOW (4 of 4)" from the pack's data shows why normal battles lack tactical tension: when enemy/player CP is near parity (0.97 in Sector 1 normal battles), the AI loses almost every fight in under four rounds, so the game can only threaten the player by inflating enemy CP to 1.40 through 2.03 in later sectors.

The evidence:

OBSERVED: In wave3_deepqa_2026_10_29.md, across 162 Sector 1 normal battles (enemy/player CP at 0.97), the player bot wins "94%" in "3.8" rounds while losing only "0.28" space ships per fight.

OBSERVED: Across 216 skirmish battles in sim3d matrix mode, the player bot wins "75 to 89" percent across all six factions (Sunward Crusade 89%, Eclipse 89%, Hegemony 86%) with "0 timeouts in 216 battles".

OBSERVED: Even in Sector 2 and Sector 3 normal battles (1.40 and 1.49 enemy/player CP), the bot wins "88%" and "89%" in 4.4 to 4.5 rounds.

What it costs the game: INFERRED: Standard battle nodes (88% to 94% win rate in ~4 rounds) feel like routine cleanup chores rather than tense turn-based fleet tactics, leaving all real danger concentrated in CP-inflated Sector 2 elites and battered Nemesis encounters.

Finding 10 (Severity 10, Confirms Battle UI Micro-Traps Outside Phased Activation): Un-cancelable squadron selection, premature "Nothing left to do" hints, and off-screen 20-ship camera pans cause unforced tactical errors

Status: OBSERVED and INFERRED.

What breaks or underperforms: Three smaller UI defects confirmed in battleui_synthesis_2026_10_29.md sit outside the move-then-fire boundary and directly sabotage turn execution during 20-ship battles.

The evidence:

OBSERVED: "Esc, selectUnit, and rosterPick never clear wingSel", so the next board click unexpectedly issues a wing order instead of selecting or firing.

OBSERVED: After moving out of gun range, the hint strip displays "Nothing left to do: tap Done with ship." "regardless of remaining movement or an unspent Brace."

OBSERVED: TIPS (ui3d.js) states that a stationary ship gives enemies +10 to hit and "Bracing cancels the sitting-still penalty."

OBSERVED: At the ruled 20-ship typical battle scale, "the pan-without-zoom camera can leave an enemy activation half off-screen at 20 ships".

What it costs the game: INFERRED: The game's best micro-teacher (the hint strip) actively tricks players into ending their turn without spending Brace (+10 enemy hit penalty if stationary, or unspent defensive mitigation), sticky wingSel states hijack board clicks, and enemy activations resolve off-screen in full-sized fleet battles.

Verdict

TACTICAL CORE PROMISING, CAMPAIGN CONTRACT BROKEN BY UNBUILT DEBRIEFS AND UNCALIBRATED ATTRITION.
The single most important attack found is that the claims register's twin pillars of campaign balance ("Nemesis snowball keeping pace not snowballing (first adaptation is the lever)" and "run win rate about 20 percent cross-validated") collapse under the pack's own measurements_addendum_2026_10_29.md: the 20% campaign simulator never spawns the campaign Nemesis, knowing a Nemesis weakness adds a statistically insignificant +3.8pp to win rate, and for the battered fleets that actually reach Sector 2 ("battered arrivals are the typical case"), the Nemesis snowballs by +28.1pp to +38.1pp (+30.8pp and a 15.8% win rate against Chorus fast cadence).

Not checked

Weapon, squadron, module, relic, event, and boon data tables (data.js): The claims register grades weapons "DUPLICATES WITH PAINT (4 of 4)", squadrons "DUPLICATES WITH PAINT", modules "MOSTLY DISTINCT JOBS / NO BUILD LAYER", boons "DUPLICATES WITH PAINT (3 of 4)", and event free-exit "26 of 33 pass", plus the "boon tax staircase (about 15pp at favour tiers 1-2, about 52pp at tier 3)", but player_pack.txt omits data.js and truncates measurements_addendum_2026_10_29.md right after "Three qualifications:", so those specific item tables and favour-tier staircase numbers could not be independently verified from code.

Text drift and HUD readiness (ui3d.js outside lines 642-652): The claims register cites "drift ROT (3 of 4)" and "Oct 27 text and HUD NOT READY", which could not be audited beyond the ten TIPS entries and synthesis summaries included in the pack.

Human playtest feel vs bot driver (sim3d.js): All battle and campaign win rates in the pack are driven by the sim3d.js bot, not human players, and roster-depth extremes (all-swarm or all-capital fleets) were not run in the faction matrix.

Godot 4.7 migration tree (godot/): The pack contains no source files or test outputs from the godot/ directory, so rules parity and UI implementation in the Godot build could not be checked.
