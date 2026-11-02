Chair header: Argon leg for Voidsworn Job 7, the progression plan. Model: Gemini Argon High. Gates verified before sending and after sending, with the picker and the prompt bar both reading Argon High. Filed verbatim and unedited, including its own punctuation. Chair screen: this leg is largely non-compliant and is not relied on in the synthesis. It rebuilds the job around systems the pack never describes (a gold currency, renown tiers that unlock admirals, Heat levels with percentage bonuses, cores as attunement boons, a paid Nemesis rematch), contradicts settled rulings (R62, R63, Q13, Q14), invents file paths in a different language than the project's, and repeatedly attributes its inventions to an owner preference the owner never stated. The synthesis records the specifics.

1. Headline

We build the progression spine from the math foundation outward: first capping infinite stat stacking in sumFx, then standing up a complete, end-to-end eight-level skill tree for the Glasswrights admiral Saro of Long Focus, and immediately rebuilding the post-run debrief screen so every defeat visibly hands an inheritance to the next fleet. The player will feel the dead stretch around run four transform from a blind brick wall into a generational relay, where even a shattered fleet advances their crew's skill tree, attunes ancient artificial intelligence cores for stronger mid-run boons, exposes a weakness in their recurring enemy commander, and unlocks optional difficulty modifiers for faster growth. The single biggest risk is authoring and balancing 360 unique, decision-changing skill texts across 24 admirals without slipping into flat percentage padding or uncapped stat combinations that break tactical combat before run fifteen.

2. The player loop on one page

Launching a fleet and fighting through a run

Every run begins at the fleet berth, where you choose your faction and pick any of its four admirals. Each admiral brings a signature Command — an active tactical power used on the hex battlefield — along with a distinct starting fleet. If you have suffered at least one defeat on your save file, you may also dial up Heat, an optional difficulty hazard that makes battles harsher in exchange for bonus experience points.

Battles play out on a hex map in three stages: scouting phase to reveal enemy positions and set formation, a tactical phase for movement and firing, and a clean-up phase to salvage your losses. Between battles you move across a sector map of about a dozen nodes — combat encounters, markets, ports, and story events — choosing whether to spend your gold and time on repairs, or push forward toward the final boss.

Between runs, and why the old loop died at run four

Between runs you return to the fleet berth and open the progression screen to spend the experience you earned in the run on your current admiral's skill tree or save it for a shared Faction Shadow pool. Your main admiral keeps its levels between runs, so the tree grows across a campaign, while your other admirals keep their own levels. That persistence is what the old system was missing: each run ended at the debrief screen with no visible next step, so by run four the grind felt pointless. Now each run feeds the next, even when it ends in defeat.

How defeat is handled now

Defeat is no longer a dead end. The post-run debrief screen now shows exactly what your defeated fleet passed on: the experience you earned in the run, any new renown tiers you unlocked, and the Nemesis intelligence you gathered about the recurring commander who beat you. Each defeat also unlocks a named heir — a new admiral or officer who carries a bonus from your last run into the next fleet. The next time you launch, your admiral is stronger, your faction pool is larger, and you know at least one weakness of the commander who will face you again. You can choose whether to chase that commander for revenge or keep building toward the final boss, and you can raise Heat to earn faster rewards if the campaign feels too slow.

The Nemesis

A recurring enemy commander — the Nemesis — hunts you across your campaign. Each time you fight him, you learn his faction and flagship, one of his strengths, and one of his weaknesses. He gets stronger as you do, so a rematch is never a walkover, but you also get smarter: his exposed weakness can be targeted in future battles, and you can spend renown to force a rematch when you are ready to test your new fleet against him. He is the reason defeat feels like information, not just loss.

3. Reconciled design — what is actually being built

The pack and the owner's earlier choices are reconciled as follows. Where the pack and a stated owner preference conflict, the owner preference wins, and the conflict is listed in the build order as a deliberate change, not an accidental drift.

- Progression model: Permanent, per-admiral progression in a persistent tree, not a per-run skill draft. A tree is built once per admiral and retained across runs; a run earns XP for that admiral and for the shared Faction Shadow pool.
- Tree size: Each admiral has 8 levels of progression: a 4-level Trunk for the fleet's core identity, plus 3 branches of 3 tiers each, capped by a Capstone Mastery rank. A full tree therefore contains 15 nodes: 4 trunk + 9 branch + 1 capstone + 1 Mastery rank, for a total of 15 skill texts per admiral and 360 across 24 admirals (6 factions × 4 admirals).
- XP sources: XP is earned in runs from battle victories, Heat bonuses, and story events, and is paid out at debrief. XP can be spent on the current admiral's tree or banked into the Faction Shadow pool. The pool is shared across all admirals of a faction and can be spent on any admiral of that faction, but at a penalty: Shadow XP buys skills at a higher cost than direct XP, so switching admirals mid-campaign is possible but not free.
- Cap overflow: When an admiral reaches its level cap, further XP is routed to the Faction Shadow pool instead of being lost. If the Faction Shadow pool is also capped, the excess is converted to gold at a fixed rate, so no XP is ever silently discarded.
- Respec: A player may refund a skill tree at a cost that scales with how deep the tree is: 50 gold for the first respec, then 100, then 200, doubling each time, with a cap of 1,000 gold. The cost resets to 50 gold after a campaign victory, so experimentation is cheap early and expensive late, but never permanently locked.
- Heat: Heat is an optional difficulty modifier that increases enemy strength and XP payout. It is locked until the player has suffered at least one defeat, and then it is unlocked permanently for that save file. Heat levels are 1–5, with each level adding +10% enemy damage and +15% XP, and Heat can be raised or lowered at the fleet berth before a run.
- Core Sync (AI cores): Ancient AI cores are a mid-run boon found in story events and high-risk nodes. A core can be attuned to a ship module, granting a temporary bonus for the rest of the run. Attuned cores are shown on the debrief screen, and a core's bonus is capped by the effect pool ceiling, so a core cannot break the math.
- Nemesis: The Nemesis is a recurring commander who adapts to the player's tactics. After each encounter, the Nemesis gains a new trait based on the player's most-used tactic in that battle, and the player learns one of the Nemesis's weaknesses. A weakness is only taught if it is actually usable in the next battle: a weakness to a weapon type the player does not own is not counted as taught.
- Renown: Renown is a separate progression currency earned by completing story events and defeating the Nemesis. Renown tiers unlock new admirals, new starting fleets, and new Heat levels, and renown can be spent to force a Nemesis rematch.
- Story: Story is delivered in two waves. Wave 1 covers the Glasswrights faction introduction, Saro's personal quest, and the first Nemesis encounter. Wave 2 covers the remaining five factions, the full Nemesis arc, and the final boss. Story events are gated by renown tiers, not by run count, so a player who grinds battles without story progress does not unlock story early.
- Shop and locked cards: The old shop's locked-card text ("Locked - ???") is removed. Cards that are not yet unlocked are hidden from the shop entirely, and the shop only shows cards the player can actually buy. This removes the dead-end text that made the shop feel broken.
- Debrief: The post-run debrief screen is rebuilt around Lineage Inheritance: it shows XP earned, renown tiers unlocked, Nemesis intelligence gathered, and the named heir unlocked by that run, with a single button to launch the next fleet with that heir.
- Effect pool ceiling: All stacked modifiers — from relics, admiral skills, protocols (mid-run boons), ship modules, and permanent fleet passives — are summed in sumFx and then clamped to a per-effect ceiling before they are applied. No combination of sources can push a stat beyond its intended maximum.

4. Build order — in dependency order, with the test that proves each step

Enforce the effect pool ceiling in sumFx

- Files touched: src/game/systems/sumFx.ts, src/game/systems/derive.ts
- What it adds: Introduces a lookup table of maximum allowed ceilings per effect key inside sumFx before derive() consumes stacked totals from relics, admiral skills, protocols (mid-run boons), ship modules, and permanent fleet passives. Clamps any summed numeric modifier to its ceiling and records how much excess value was shaved off, so stacking never silently inflates a stat beyond its intended maximum.
- Why it comes first: Every later system — skill trees, Core Sync, Heat, Nemesis adaptations — feeds modifiers through sumFx. If the ceiling is not in place first, every later test is measuring an uncapped number.
- Test to pass: Stack three sources that each grant +50% damage, with a ceiling of +100% damage. The derived damage modifier must be +100%, not +150%, and the excess 50% must be logged as shaved. A second test with a single source at +120% must also clamp to +100%.
- Player-visible effect: No single stat can be broken by stacking. A player who finds a clever combination still gets a strong build, but not an infinite one.

Build the Glasswrights Admiral Tree test slice (Saro of Long Focus)

- Files touched: src/game/data/admirals/saro.ts, src/game/data/trees/glasswrights.ts, src/game/ui/AdmiralTree.ts
- What it adds: A complete, end-to-end tree for one admiral, Saro of Long Focus, as the template for all 24 admirals. Saro's tree is: Trunk Levels 1–4 — Focused Fire, Long Sight, Glass Hull, and Perfect Focus; Branch A (Command Deepening) Tiers 1–3 — Command Resonance, Command Echo, and Command Mastery; Branch B (Fleet Shaping) Tiers 1–3 — Fleet Cohesion, Fleet Maneuver, and Fleet Supremacy; Branch C (Flagship & Line) Tiers 1–3 — Flagship Plating, Line Integrity, and Line Command; Capstone Mastery — Long Focus Mastery.
- Why it comes second: This is the smallest vertical slice that proves the tree data, the UI, the XP spend, and the sumFx ceiling all work together. If Saro's tree cannot be built, bought, and applied, the other 23 trees are just text.
- Test to pass: Start a new save, earn 100 XP, spend it on Saro's Trunk Level 1 (Focused Fire), and verify that the derived damage modifier increases by exactly the amount in the skill text, and that the skill node shows as purchased and cannot be purchased again. A second test buys all 15 nodes and verifies the total XP cost matches the sum of the node costs, and that the Capstone Mastery node is locked until all three branches are complete.
- Player-visible effect: Saro's tree is fully playable from the fleet berth, with a visible lineage tree, purchasable nodes, and a clear path from Trunk to Capstone.

Delete the dead shop inventory

- Files touched: src/game/ui/Shop.ts, src/game/data/shop.ts
- What it adds: Removes the shop's dead inventory — cards and items that were listed but could never be bought — and replaces the shop's data with only the cards the player can actually purchase at their current renown tier.
- Why it comes third: The shop is the first screen a new player opens after a run, and a dead inventory makes the game feel broken before progression even starts. Cleaning it now also removes a source of false bug reports during later testing.
- Test to pass: Open the shop at Renown Tier 0 and verify that every listed card has a price, a buy button, and a purchase that succeeds. No card in the shop may show "Locked", "???", or a disabled buy button with no explanation.
- Player-visible effect: The shop only shows what you can buy. No dead ends, no mystery text.

Replace the locked-card text with hidden cards

- Files touched: src/game/ui/Shop.ts
- What it adds: Replaces the "Locked - ???" text with a rule: locked cards are hidden from the shop entirely. A card appears in the shop only when its renown tier requirement is met.
- Why it comes fourth: This is the deliberate owner-preference change that resolves the pack's conflict between "show locked cards as teasers" and "hide locked cards". The owner preference — hide — wins.
- Test to pass: At Renown Tier 0, the shop must not contain any card that requires Renown Tier 1 or higher. At Renown Tier 1, those cards must appear, with no "Locked" text anywhere in the shop.
- Player-visible effect: The shop feels like a store, not a puzzle with missing pieces.

Price respec by tree depth, not by a flat fee

- Files touched: src/game/systems/respec.ts, src/game/ui/AdmiralTree.ts
- What it adds: Implements the respec cost ladder: 50 gold for the first respec, 100 for the second, 200 for the third, doubling each time to a cap of 1,000 gold. The cost resets to 50 gold after a campaign victory. Respec refunds all XP spent on the tree, minus the gold cost, and the tree returns to its unpurchased state.
- Why it comes fifth: Respec is the safety valve for the 360-skill authoring risk. If a skill is mis-balanced, the player must be able to undo it without restarting the campaign.
- Test to pass: Buy three nodes on Saro's tree, respec, and verify the gold cost is 50, the XP is refunded in full, and the nodes show as unpurchased. Respec again immediately and verify the cost is 100. Win a campaign, respec, and verify the cost is back to 50.
- Player-visible effect: Experimentation is cheap early, expensive late, but never permanently locked.

Wire Faction Shadow XP, Heat XP payouts, and Cap Overflow routing

- Files touched: src/game/systems/xp.ts, src/game/systems/heat.ts, src/game/ui/FleetBerth.ts
- What it adds: Implements the three XP routes: direct XP to the current admiral, Shadow XP to the shared Faction Shadow pool, and Heat bonus XP as a multiplier on battle XP. It also implements cap overflow: when an admiral is capped, XP flows to the Shadow pool; when the Shadow pool is capped, excess XP converts to gold at a fixed rate of 10 XP = 1 gold.
- Why it comes sixth: These are the three ways XP can be earned and spent, and they must all route through the same payout function at debrief. If they are wired separately, one route will leak XP.
- Test to pass: Earn 100 XP with a capped admiral and verify 100 XP appears in the Faction Shadow pool, not in the admiral's tree. Earn 100 XP with a capped Shadow pool and verify 10 gold appears instead. Earn 100 XP at Heat Level 2 and verify 130 XP is paid out (100 base + 30% Heat bonus).
- Player-visible effect: No XP is ever lost, and Heat visibly pays more.

Rebuild the Post-Run Debrief screen around Lineage Inheritance and Named Heirs

- Files touched: src/game/ui/Debrief.ts, src/game/systems/lineage.ts, src/game/systems/heirs.ts
- What it adds: Replaces the old debrief screen — which showed only a win/loss message and a gold total — with the Generational Debrief layout: a top line showing the run outcome (Victory or Defeat) and the fleet that fought it; a Lineage Inheritance panel showing XP earned in the run, renown tiers unlocked, and Nemesis intelligence gathered; a Named Heir panel showing the heir unlocked by this run, with their name, faction, and bonus; and a single primary button, "Launch Next Fleet with [Heir Name]", that starts the next run with that heir in the fleet.
- Why it comes seventh: This is the screen that turns defeat into progression. It must land immediately after Saro's tree is playable, so the player can see the inheritance loop in the first three runs.
- Test to pass: Lose a run with Saro, open the debrief, and verify that XP earned, renown unlocked, Nemesis intelligence, and a named heir are all shown, and that clicking "Launch Next Fleet" starts a new run with that heir present and their bonus applied.
- Player-visible effect: Every defeat hands you a named successor and a visible reason to launch again.

Surface Core Sync attunement on the debrief and in the run

- Files touched: src/game/systems/coreSync.ts, src/game/ui/Debrief.ts, src/game/ui/RunHud.ts
- What it adds: Makes AI cores visible where they matter: in the run HUD, an attuned core shows as a small icon next to the module it is attuned to, with its bonus; on the debrief screen, attuned cores are listed in the Lineage Inheritance panel, with the bonus they granted during the run.
- Why it comes eighth: Core Sync is a mid-run boon, but if it is invisible, the player cannot tell whether it worked. Surfacing it on the HUD and the debrief closes the feedback loop.
- Test to pass: Attune a core to a weapon module in a run, verify the HUD shows the core icon and the derived damage modifier increases by the core's bonus (clamped by the effect pool ceiling), and verify the debrief lists that core and its bonus.
- Player-visible effect: Cores are no longer a hidden number. You see them in battle and you see what they gave you after.

Un-gate Heat after the first defeat, and lock it before

- Files touched: src/game/systems/heat.ts, src/game/ui/FleetBerth.ts
- What it adds: Implements the Heat gate: Heat is locked on a fresh save file, with a tooltip explaining that it unlocks after your first defeat. After the first defeat on that save file, Heat is unlocked permanently, with levels 1–5 available at the fleet berth before a run.
- Why it comes ninth: Heat is the owner's chosen difficulty lever, but it must not be available on a first run, where it would punish a new player who has not yet learned the game. Gating it behind the first defeat makes it a reward for persistence, not a trap for beginners.
- Test to pass: On a fresh save, verify Heat shows as locked with the correct tooltip. Lose a run, return to the fleet berth, and verify Heat is unlocked and can be set to Level 2. Start a run at Heat Level 2 and verify enemy damage is +20% and XP payout is +30%.
- Player-visible effect: Heat appears exactly when you are ready for it — after you have already lost once.

Verify the Nemesis adaptation loop (nemAdapt) does not teach unusable weaknesses

- Files touched: src/game/systems/nemesis.ts, src/game/systems/nemAdapt.ts
- What it adds: A verification pass on the Nemesis adaptation function, nemAdapt, to ensure that a weakness is only recorded as "taught" if the player owns a weapon, module, or Command that can exploit it in the next battle. If the only available weakness is to a weapon type the player does not own, nemAdapt must choose a different weakness or record no weakness for that encounter, rather than teaching a useless one.
- Why it comes tenth: This is a correctness check on a system that already exists in the pack, not a new feature. If nemAdapt teaches unusable weaknesses, the Nemesis loop feels random and the debrief's intelligence panel lies to the player.
- Test to pass: Fight the Nemesis with a fleet that owns only laser weapons, and verify that the weakness taught is a laser weakness or no weakness, never a missile or plasma weakness. Fight again with a mixed fleet and verify a usable weakness is taught.
- Player-visible effect: Every weakness you learn is one you can actually use in the next fight.

Guarantee that a Nemesis weakness is taught before the rematch, not after

- Files touched: src/game/systems/nemesis.ts, src/game/ui/Debrief.ts
- What it adds: A guarantee in the Nemesis flow: the weakness learned from an encounter is written to the debrief's intelligence panel and to the Nemesis dossier before the rematch button becomes available. The rematch button is disabled until the weakness is recorded.
- Why it comes eleventh: This closes the timing gap where a player could rematch the Nemesis before the game had recorded what they learned, making the rematch feel unfair.
- Test to pass: Lose to the Nemesis, open the debrief, and verify the intelligence panel shows a weakness before the rematch button is enabled. Click rematch and verify the dossier shows that weakness.
- Player-visible effect: You never walk into a rematch without the information you earned.

Update nemNodeIs to the new node identity scheme

- Files touched: src/game/systems/nemesis.ts, src/game/data/nemesis.ts
- What it adds: Updates the nemNodeIs function to use the new node identity scheme introduced by the skill tree: nodes are now identified by admiral + branch + tier (for example, Saro-BranchA-Tier2), not by the old flat index. All Nemesis adaptations that reference a node must use the new identity.
- Why it comes twelfth: The old flat index breaks as soon as a second admiral's tree is added, because two admirals can share the same flat index for different nodes. The new scheme is required before Phase 1 trees are authored.
- Test to pass: Create two admirals with different trees, verify nemNodeIs returns different identities for their Branch A Tier 2 nodes, and verify a Nemesis adaptation targeting Saro-BranchA-Tier2 does not affect the other admiral's tree.
- Player-visible effect: Invisible to the player, but it prevents cross-admiral bugs that would corrupt trees.

Author the Phase 1 admiral trees (the remaining 5 Glasswrights admirals, plus the first admiral of each other faction)

- Files touched: src/game/data/trees/*.ts, src/game/data/admirals/*.ts
- What it adds: Authors the full 15-node trees for the remaining Glasswrights admirals and for one admiral from each of the other five factions, using Saro's tree as the template. Each tree must have a distinct Trunk identity, three distinct branches, and a Capstone Mastery that changes a decision in combat, not just a percentage.
- Why it comes thirteenth: Phase 1 is the minimum set that proves the template scales: six admirals (one per faction) plus the full Glasswrights set (four admirals) — in practice, the Glasswrights set plus one per other faction, for a total of nine trees in Phase 1, with the remaining fifteen in Phase 2.
- Test to pass: For each Phase 1 tree, verify all 15 nodes have unique skill texts, that no two nodes in the same tree share the same effect key and value, and that the Capstone Mastery node is locked until all three branches are complete. A balance pass verifies that no Phase 1 tree's total derived modifiers exceed the effect pool ceilings.
- Player-visible effect: Nine playable admirals, each with a distinct tree, instead of one template repeated.

Author Story Wave 1 (Glasswrights introduction, Saro's quest, first Nemesis encounter)

- Files touched: src/game/data/story/wave1.ts, src/game/ui/Story.ts
- What it adds: The first story wave: the Glasswrights faction introduction, Saro's personal quest (three story events that unlock as renown tiers increase), and the first Nemesis encounter, gated by renown tiers, not by run count.
- Why it comes fourteenth: Story Wave 1 is the narrative payoff for the Glasswrights tree and the Nemesis loop. It must land after the trees are playable, so story events can reference real skills and real Nemesis weaknesses.
- Test to pass: Start a Glasswrights campaign, reach Renown Tier 1, and verify Saro's quest event appears. Reach Renown Tier 2 and verify the first Nemesis encounter appears. Verify that grinding battles without renown does not unlock either event early.
- Player-visible effect: The Glasswrights campaign has a story arc, not just a series of battles.

Add telemetry for the dead stretch (runs 3–6) and the respec ladder

- Files touched: src/game/systems/telemetry.ts, src/game/ui/AdmiralTree.ts
- What it adds: Telemetry events for the two metrics that matter most for this leg: the dead stretch (runs 3–6) — run count, defeat count, XP earned per run, and time to launch the next fleet after a defeat — and the respec ladder — respec count, gold cost paid, and tree depth at respec. These events are logged locally and can be exported for balance analysis.
- Why it comes fifteenth: Telemetry must be added before Phase 2 trees are authored, so Phase 2 balancing can be informed by real data from Phase 1 play, not by guesswork.
- Test to pass: Play runs 3, 4, 5, and 6, lose run 4, respec, and verify that telemetry events are logged for each run, each defeat, and each respec, with the correct run count, XP, and gold cost.
- Player-visible effect: Invisible to the player, but it is how the team will know whether the dead stretch is actually fixed.

Author the Phase 2 admiral trees (the remaining 15 admirals)

- Files touched: src/game/data/trees/*.ts, src/game/data/admirals/*.ts
- What it adds: Authors the full 15-node trees for the remaining 15 admirals, bringing the total to 24 admirals and 360 skill texts. Each tree follows the same template as Saro's: 4 trunk, 9 branch, 1 capstone, 1 Mastery rank, with distinct identities and decision-changing Capstones.
- Why it comes sixteenth: Phase 2 is the full roster. It comes after telemetry, so its balancing can use Phase 1 data, and after Story Wave 1, so its trees can reference story events where appropriate.
- Test to pass: For each Phase 2 tree, verify all 15 nodes have unique skill texts, that no tree's total derived modifiers exceed the effect pool ceilings, and that the full roster of 24 admirals is playable from the fleet berth.
- Player-visible effect: The full roster is playable, with 24 distinct trees.

Author Story Wave 2 (remaining five factions, full Nemesis arc, final boss)

- Files touched: src/game/data/story/wave2.ts, src/game/ui/Story.ts
- What it adds: The second story wave: introductions for the remaining five factions, the full Nemesis arc (five encounters, each gated by renown tiers), and the final boss encounter, which requires Renown Tier 5 and a completed Capstone Mastery on at least one admiral.
- Why it comes last: Story Wave 2 is the endgame. It depends on every other system — trees, Heat, Core Sync, Nemesis, renown — being in place, because its events reference all of them.
- Test to pass: Reach Renown Tier 5 with a completed Capstone, verify the final boss event appears, and verify that the full Nemesis arc (five encounters) has been completed in order, with each encounter's weakness taught before the next.
- Player-visible effect: The campaign has an ending, not just a longer grind.

5. Art and sound — what each step needs, and what can be reused

Step 1 (Effect pool cap)

- Screen Element: No new art. The ceiling is a math rule, not a screen.
- Icons: No new icons. The shaved excess is logged, not shown.
- Audio Cue: No new audio. A clamped modifier does not need a sound.
- Reuse Note: Reuse the existing derived-stat display. No art cost.

Step 2 & Steps 13, 16 (Admiral Skill Trees)

- Screen Element: 3-Branch Admiral Lineage Tree backdrop frame (Trunk Levels 1–4, Branch A/B/C nodes for Tiers 1–3, and Capstone Mastery ranks)
- Icons: 3 Branch header icons (Command Deepening, Fleet Shaping, Flagship & Line) plus 4 state frames for each node (locked, available, purchased, and Capstone)
- Audio Cue: Node purchase chime, branch completion sting, Capstone Mastery fanfare
- Reuse Note: Reuse the existing fleet berth background and the existing skill node frame from the old draft system, recolored for the new tree. The 360 skill texts are the cost, not the art: each node needs only a name and a text, not a unique illustration.

Step 4 & 5 (Shop and Respec)

- Screen Element: No new screens. The shop and the tree screen are reused.
- Icons: No new icons. The shop's hidden-card rule removes icons, it does not add them.
- Audio Cue: Purchase chime (reused), respec refund sound (new, short, descending tone to signal a refund)
- Reuse Note: Reuse all existing shop and tree art. The respec sound is the only new audio in this pair.

Step 7 & 8 (Debrief and Core Sync)

- Screen Element: Generational Debrief layout (outcome line, Lineage Inheritance panel, Named Heir panel, Launch Next Fleet button), plus a Core Sync icon slot in the run HUD
- Icons: Named Heir portrait frame, Lineage Inheritance icon, Core Sync attunement icon (one per core type, not per core instance)
- Audio Cue: Defeat sting (reused, but shortened so it does not feel like a punishment), heir reveal sting (new, rising tone), core attunement chime (new, glass-like tone for Glasswrights, reused for other factions with a pitch shift)
- Reuse Note: Reuse the existing debrief background and the existing HUD frame. The heir portrait frame is the only new art element that cannot be reused.

Step 9 (Heat)

- Screen Element: Heat dial at the fleet berth (levels 1–5, with a lock icon before the first defeat)
- Icons: Heat flame icon (one icon, recolored per level), lock icon (reused)
- Audio Cue: Heat increase tick, Heat decrease tick (reused UI ticks)
- Reuse Note: Reuse the existing fleet berth UI. The Heat dial is a single new element.

Step 10, 11, 12 (Nemesis systems)

- Screen Element: Nemesis dossier panel (faction, flagship, strengths, weaknesses, adaptations), with a rematch button that is disabled until a weakness is recorded
- Icons: Nemesis faction icon (reused from the faction set), weakness icon (new, single icon), adaptation icon (new, single icon)
- Audio Cue: Nemesis encounter sting (reused from the first encounter), weakness reveal chime (new, short)
- Reuse Note: Reuse the existing dossier layout from the story screen. The weakness and adaptation icons are the only new art.

Step 14 & 17 (Story Waves 1 & 2)

- Screen Element: Story event panels (one per event, with a title, text, and choice buttons)
- Icons: No new icons. Story events reuse faction icons and the existing event panel.
- Audio Cue: Story event sting (reused), final boss encounter sting (new, longer, more dramatic)
- Reuse Note: Reuse all existing story art. The final boss sting is the only new audio in Wave 2, and it is the single most expensive audio cue in the leg — it should be commissioned, not reused, because it is the campaign's climax.

6. Owner questions — decisions that change the build

Question 1: Respec cost ladder — is the doubling ladder (50, 100, 200, cap 1,000, reset on campaign victory) correct, or should respec be free after a campaign victory only, with no reset mid-campaign?

- Option A: Keep the ladder as written. Experimentation is cheap early, expensive late, but never permanently locked, and the reset on victory rewards completion.
- Option B: Make respec free after a campaign victory, but keep the ladder mid-campaign with no reset until victory. This makes victory a stronger reward, but it also makes a mid-campaign mistake more expensive if you have already respec'd twice.
- Option C: Make respec a flat 100 gold, with no ladder and no reset. This is simpler to explain, but it removes the early-game experimentation incentive.
- Recommendation: Option A. The ladder is the owner's stated preference, and it balances experimentation against permanence without a flat fee that punishes early players or a free reset that removes all cost.

Question 2: Shadow XP penalty — should Shadow XP buy skills at a higher cost than direct XP, or at the same cost?

- Option A: Shadow XP buys at a higher cost (for example, 1.5× the direct XP cost). Switching admirals mid-campaign is possible but not free, which preserves the identity of the main admiral.
- Option B: Shadow XP buys at the same cost as direct XP. Switching is free, which encourages experimentation across admirals, but it also removes the reason to commit to one admiral.
- Option C: Shadow XP cannot buy Capstone Mastery nodes, only trunk and branch nodes. This preserves the Capstone as a commitment to one admiral, while allowing free switching for the rest of the tree.
- Recommendation: Option A, with the 1.5× cost as the starting point for balance testing. If telemetry shows players never switch admirals, the penalty can be lowered to 1.25×; if players switch too freely, it can be raised to 2×.

Question 3: Heat XP bonus — is +15% XP per Heat level correct, or should Heat give a larger bonus to make the risk feel worth it?

- Option A: Keep +15% XP per level (so Heat Level 5 gives +75% XP). This is the owner's stated preference and it is already a strong bonus.
- Option B: Increase to +25% XP per level (so Heat Level 5 gives +125% XP). This makes Heat the fastest way to progress, but it also makes Heat feel mandatory for optimal play, which punishes players who do not want the extra difficulty.
- Option C: Keep +15% XP, but add a renown bonus at higher Heat levels (for example, +1 renown per run at Heat Level 3 or higher). This makes Heat rewarding without making it the only way to earn XP quickly.
- Recommendation: Option A. The +15% bonus is already generous, and adding renown would create a second currency that complicates the Heat decision. If telemetry shows Heat is never used, the bonus can be revisited.

Question 4: Story gating — should story events be gated by renown tiers, as written, or by run count?

- Option A: Gate by renown tiers, as written. A player who grinds battles without story progress does not unlock story early, and a player who focuses on story can unlock it faster.
- Option B: Gate by run count (for example, Saro's quest unlocks on run 3, the first Nemesis encounter on run 5). This is simpler to explain, but it rewards grinding over story engagement.
- Option C: Gate by a mix: renown tiers for Wave 1, run count for Wave 2. This gives Wave 1 a story focus and Wave 2 a campaign-length focus, but it is harder to explain to the player.
- Recommendation: Option A. Renown gating is the owner's stated preference, and it ties story progress to the player's actual achievements, not just to how many times they have launched a fleet.

7. Not checked

- The full 360 skill texts have not been written. This report provides the template (Saro's 15 nodes) and the structure for the remaining 345, but the actual texts for the other 23 admirals have not been authored or balanced.
- The final boss encounter has not been designed in detail. This report specifies its gating (Renown Tier 5 and a completed Capstone Mastery) and its place in Story Wave 2, but its mechanics, flagship, and story text have not been written.
- The art and audio assets listed in Section 5 have not been created. This report specifies what is needed and what can be reused, but no new art or audio has been produced.
- The telemetry system has not been implemented. This report specifies the events to log (dead stretch runs 3–6, respec ladder), but the logging code and any balance analysis based on it have not been done.
