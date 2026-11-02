# Content lint, 2026-11-01

179 affected source lines with open findings. Count each line once, including lines with multiple problems. These are line counts, not counts of skills or independent defects. Withdrawn Nemesis lines are excluded.

| File | Affected lines |
| --- | ---: |
| skill_tree_phase1_assembled_2026_10_29.md | 59 |
| skill_tree_tier2_assembled_2026_10_29.md | 11 |
| skill_tree_tier3_assembled_2026_10_29.md | 11 |
| nemesis_lines_assembled_2026_10_29.md | 23 |
| nemesis_lines_correction_2026_10_30.md | 1 |
| tutorial_assembled_2026_10_29.md | 14 |
| story_pack_2026_10_30.md | 60 |

Scope and method

Read all seven named files line by line: 216 Phase 1 tree picks, 48 tier 2 picks, 96 tier 3 picks, 41 effective Nemesis lines after both Oct 30 replacements, 16 tips, and the complete story pack including its self-lint. Checked approved bible r8, final rename map, R61/R64/R66, root data.js and battle.js. Read supporting campaign code where those two files define data but not behavior. Source lines are 1-based in this checkout.

Only this report was written. No packs, source, assets or commits were changed. All seven source files are ASCII: zero em dashes, zero en dashes and zero other non-ASCII characters. Internal ids (corsair, ithar, deathless, c_boon, c_relic) stay, as the rename map requires. Historical quotes and unassembled reserve names are not active-content violations.

AGENTS limitation: docs/REVIEW_PROTOCOL.md, docs/ship_pipeline/TEXTURE_PASS.md and docs/ship_pipeline/AUDIT_BRIEF.md are absent from this folder, including filename search. Those procedures could not be followed. Used the explicit task and named lore sources without reading outside this folder.

Interpretation

Counts include confirmed rule/code errors and editorial clarity/voice findings. Editorial judgments are identified in their rule text; they are not claims of runtime failure.
- These are unbuilt designs. New timing, targeting, optical recordings, false images and temporary plating are not defects merely because current code lacks them. Findings flag false descriptions of baseline rules, impossible faction baselines, invalid paste-ready syntax/data, undefined effects and unclear player copy.
- A corrected line that changes mechanics is a suggested design correction, not an approved replacement mechanic. In particular, amounts, caps and durations marked for definition must be settled before implementation. The report does not authorize a balance change.
- Motif ownership governs repeated identity and naming, not every literal shared word. Glasswright optical battle recordings are accepted under the stated later learning ruling; not automatically a violation of Eclipse memory. Biological Hullbreaker teeth and their coarse mane are explicitly allowed.
- No pack explicitly describes furred Hullbreaker faces, snouts, Predator tusks/dreadlocks, or literal glass Glasswright bodies, eyes or mouths. Translated printed dialogue does not prove a mouth. The ancestral-face line is recorded as an ambiguity at the end, not a confirmed violation.
- Chorus corrections to generic persona pools are faction overrides, not lines to impose on every faction. The two correction-file withdrawals have already been applied when assessing active Nemesis text.
- Plain-reading findings identify terms and omitted units that require explanation. Repeating a complete glossary inside every skill would make the choices harder to read. Explain recurring concepts (wing, section, firing arc, Command power) at their first UI use; no unseen glossary was assumed.

## skill_tree_phase1_assembled_2026_10_29.md (59)

### 001. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:22

Text:
```text
T1: Ledger of Arcs - a ship firing its volley from a broadside arc may split that volley between two targets in the same arc. || Held in the Account - you may hold one ship's volley when the Command is declared and fire it after that ship moves this round.
```

Rule broken: Bible 1.3,2.4: repeated ledger/account naming gives the Crusade the Hegemony accounting voice. Use oaths, chalk and debts.

Corrected line:
```text
T1: Oath of the Gun Decks - a ship firing its volley from a broadside arc may split that volley between two targets in the same arc. || Held Under Oath - you may hold one ship's volley when the Command is declared and fire it after that ship moves this round.
```

### 002. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:23

Text:
```text
T2: Named in the Ledger - before the volley, name one enemy; every ship may aim its volley at the named enemy even if another target is closer. || Inherited Aim - a ship that has not moved this round fires its volley at +15% damage.
```

Rule broken: Bible 1.3,2.4: repeated ledger/account naming gives the Crusade the Hegemony accounting voice. Use oaths, chalk and debts.

Corrected line:
```text
T2: Named in Chalk - before the volley, name one enemy; every ship may aim its volley at the named enemy even if another target is closer. || Inherited Aim - a ship that has not moved this round fires its volley at +15% damage.
```

### 003. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:24

Text:
```text
T3: Every Gun Sworn - each ship chooses its own volley target freely, ignoring the best-target rule, and ships that choose the same target gain +10 aim against it. || Debt Comes Due - you may delay the whole volley to the start of next round, when it fires before any enemy ship acts.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
T3: Every Gun Sworn - each ship chooses its own volley target freely, ignoring the best-target rule, and ships that choose the same target gain +10 points to hit chance against it. || Debt Comes Due - you may delay the whole volley to the start of next round, when it fires before any enemy ship acts.
```

### 004. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:25

Text:
```text
Capstone: The Grand Ledger - once per battle, when Fire for effect is used, choose one enemy; every ship that can reach it fires, all damage is summed, and the target's shields are applied once to the total. || The Last Account - Fire for effect fires at the very start of the round, before movement, and each ship picks its own target.
```

Rule broken: Bible 1.3,2.4: repeated ledger/account naming gives the Crusade the Hegemony accounting voice. Use oaths, chalk and debts.

Corrected line:
```text
Capstone: Every Gun Sworn - once per battle, when Fire for effect is used, choose one enemy; every ship that can reach it fires, all damage is summed, and the target's shields are applied once to the total. || The Last Oath - Fire for effect fires at the very start of the round, before movement, and each ship picks its own target.
```

### 005. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:29

Text:
```text
Branch A - The Hunter's Ledger
```

Rule broken: Bible 1.3,2.4: repeated ledger/account naming gives the Crusade the Hegemony accounting voice. Use oaths, chalk and debts.

Corrected line:
```text
Branch A - The Hunter's Oath
```

### 006. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:31

Text:
```text
T2: Torpedoes Run First - during the salvo round, torpedoes resolve before all gun fire, so their kills open lanes for the fleet's guns. || Rear Arc Reckoning - during the salvo round, rear-arc hits from any weapon, not only torpedoes, gain the hunter-killer rear-arc bonus.
```

Rule broken: Plain reading: rear-arc is an attack against the back of the enemy, not backward-facing guns. Hunter-killer bonus is undefined here.

Corrected line:
```text
T2: Torpedoes Run First - during the salvo round, torpedoes resolve before all gun fire, so their kills open lanes for the fleet's guns. || Rear Arc Reckoning - during the salvo round, hits against the back of an enemy from any weapon gain the same rear-hit damage bonus as torpedoes; display that bonus in the preview.
```

### 007. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:37

Text:
```text
Branch A - Wings on the Ledger
```

Rule broken: Bible 1.3,2.4: repeated ledger/account naming gives the Crusade the Hegemony accounting voice. Use oaths, chalk and debts.

Corrected line:
```text
Branch A - Wings Under Oath
```

### 008. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:39

Text:
```text
T2: The Account Splits - each extra wing may strike a different target than the rest of its carrier's wings. || Held in Reserve - you may keep one extra wing unlaunched; it launches free at the start of next round and strikes then.
```

Rule broken: Bible 1.3,2.4: repeated ledger/account naming gives the Crusade the Hegemony accounting voice. Use oaths, chalk and debts.

Corrected line:
```text
T2: The Oath Takes Two Paths - each extra wing may strike a different target than the rest of its carrier's wings. || Held in Reserve - you may keep one extra wing unlaunched; it launches free at the start of next round and strikes then.
```

### 009. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:40

Text:
```text
T3: Every Generation Aloft - a carrier that has not moved this round launches one additional extra wing. || Wings Settle the Debt - an extra wing striking the same target as its carrier's guns gains +30% and is screened at half effect, once per carrier.
```

Rule broken: Plain reading: +30% omits the statistic; screened at half effect does not explain interception.

Corrected line:
```text
T3: Every Generation Aloft - a carrier that has not moved this round launches one additional extra wing. || Wings Settle the Debt - an extra wing striking the same target as its carrier's guns deals 30% more damage and suffers half the usual defensive interception, once per carrier.
```

### 010. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:41

Text:
```text
Capstone: The Sky Keeps the Ledger - Scramble all wings resolves in two waves in the same round: wings launch and strike, then the extra wings launch and strike again. || Oath of Open Sky - the extra wings stay launched when the Command ends and strike once more at the start of next round.
```

Rule broken: Bible 1.3,2.4: repeated ledger/account naming gives the Crusade the Hegemony accounting voice. Use oaths, chalk and debts.

Corrected line:
```text
Capstone: The Sky Keeps the Oath - Scramble all wings resolves in two waves in the same round: wings launch and strike, then the extra wings launch and strike again. || Oath of Open Sky - the extra wings stay launched when the Command ends and strike once more at the start of next round.
```

### 011. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:45

Text:
```text
Branch A - The Iron Account
```

Rule broken: Bible 1.3,2.4: repeated ledger/account naming gives the Crusade the Hegemony accounting voice. Use oaths, chalk and debts.

Corrected line:
```text
Branch A - The Iron Oath
```

### 012. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:48

Text:
```text
T3: Unpaid and Unbroken - during Iron wall, ships below half hull take 60% less hull damage instead of 40%. || The Wall Answers - while Iron wall is active, a ship whose shields are emptied by a hit fires its smallest weapon at the attacker, once per ship per battle.
```

Rule broken: battle.js:1077,1097: Iron wall reduction is 40/50/60% by power. Instead of 40% assumes power 1.

Corrected line:
```text
T3: Unpaid and Unbroken - during Iron wall, ships below half hull take an additional 20 percentage points less hull damage, subject to an approved reduction cap. || The Wall Answers - while Iron wall is active, a ship whose shields are emptied by a hit fires its smallest weapon at the attacker, once per ship per battle.
```

### 013. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:49

Text:
```text
Capstone: Iron Testament - Iron wall lasts two rounds, and shields refill again at half strength at the start of the second round. || The Wall That Sails - during Iron wall, your ships may move at full speed without losing the damage reduction.
```

Rule broken: Bible 1.4.2: no sea framing for space ships. battle.js:1097,1106: Iron wall does not prevent movement or lose protection when moving. Removing that nonexistent restriction adds no benefit.

Corrected line:
```text
Capstone: Iron Testament - Iron wall lasts two rounds, and shields refill again at half strength at the start of the second round. || The Wall Advances - during Iron wall, your ships gain 1 additional movement while the wall is active.
```

### 014. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:54

Text:
```text
Branch C T1: Flagship Keeps the Ledger - once per battle, the flagship may order one other ship that has already fired to fire one weapon again at half damage. || Standard of the First Crusade - once per round, one ship within 2 hexes of the flagship may reroll a missed shot.
```

Rule broken: Bible 1.3,2.4: repeated ledger/account naming gives the Crusade the Hegemony accounting voice. Use oaths, chalk and debts.

Corrected line:
```text
Branch C T1: Flagship Keeps the Roll - once per battle, the flagship may order one other ship that has already fired to fire one weapon again at half damage. || Standard of the First Crusade - once per round, one ship within 2 hexes of the flagship may reroll a missed shot.
```

### 015. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:62

Text:
```text
T2: Shared Solution - synced ships share their best aim modifier. || Cold Drill - sync forms at round start even if the flagship has not moved.
```

Rule broken: battle.js:498: sync is already active with a stationary flagship. Cold Drill adds no baseline benefit.

Corrected line:
```text
T2: Shared Solution - synced ships share their best aim modifier. || Cold Drill - proposed: ships that begin the round in sync keep it until round end even if the flagship moves out of range.
```

### 016. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:63

Text:
```text
T3: Rolling Fire - a kill by a synced ship lets another synced ship fire immediately, once per round. || Iron Tempo - sync survives the flagship's first crippling hit each battle.
```

Rule broken: battle.js:498,501: sync depends on distance and a living flagship, not a generic crippling hit. Name the actual exception.

Corrected line:
```text
T3: Rolling Fire - a kill by a synced ship lets another synced ship fire immediately, once per round. || Iron Tempo - sync survives the flagship's destruction for one additional round each battle.
```

### 017. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:64

Text:
```text
Capstone: Living Relay - the flagship projects sync from its position at double radius, and sync no longer requires line of sight to the anchor. || One Voice - once per battle, every synced ship fires at one target simultaneously, resolving as a single combined strike.
```

Rule broken: battle.js:498 has no line-of-sight test for sync. Removing that nonexistent requirement gives no benefit.

Corrected line:
```text
Capstone: Living Relay - the flagship projects sync from its position at double radius, for the rest of the round. || One Voice - once per battle, every synced ship fires at one target simultaneously, resolving as a single combined strike.
```

### 018. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:69

Text:
```text
T1: Target Filed in Triplicate - when the strike begins, file one enemy as the interdicted target; your hits on it gain +10 crit chance. || Strike by the Book - during the strike round, ships that fire in ascending speed order gain +15% damage.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
T1: Target Filed in Triplicate - when the strike begins, file one enemy as the interdicted target; your hits on it gain +10 percentage points to critical-hit chance. || Strike by the Book - during the strike round, ships that fire in ascending speed order gain +15% damage.
```

### 019. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:78

Text:
```text
T2: Second Wave on Schedule - you may hold all extra wings and launch them at the start of next round instead, striking then at full effect. || Procedure Rehearsed - after the first strike resolves, each extra wing may be reassigned to a new target for its strike-again.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
T2: Second Wave on Schedule - you may hold all extra wings and launch them at the start of next round instead, striking then at full effect. || Procedure Rehearsed - after the first strike resolves, each extra wing may be reassigned to a new target for its immediate bonus attack.
```

### 020. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:86

Text:
```text
T2: Wall at the Bell - the wall may be declared at the very start of the round, before any ship moves or fires. || Standard Rotation - during the wall, a ship may swap hexes with an adjacent friendly ship without losing the damage reduction.
```

Rule broken: battle.js:1097,1106: Iron wall has no movement-based cancellation. The swap is new, but without losing reduction describes no extra benefit.

Corrected line:
```text
T2: Wall at the Bell - the wall may be declared at the very start of the round, before any ship moves or fires. || Standard Rotation - during the wall, a ship may swap hexes with an adjacent friendly ship as a special movement action; normal collision rules still apply.
```

### 021. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:92

Text:
```text
Branch B T1: Formation Filed Before Battle - choose one standard formation at battle start; ships that end their movement inside it gain +10 aim that round. || Drill Revision One - once per battle, after the enemy has moved, reposition one of your ships up to 2 hexes.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
Branch B T1: Formation Filed Before Battle - choose one standard formation at battle start; ships that end their movement inside it gain +10 points to hit chance that round. || Drill Revision One - once per battle, after the enemy has moved, reposition one of your ships up to 2 hexes.
```

### 022. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:93

Text:
```text
Branch C T1: Flagship Registry Beacon - once per round, the flagship may stamp one enemy; your ships gain +10 aim against the stamped enemy. || Standard Borne Forward - ships that move toward the flagship this round gain +1 movement.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
Branch C T1: Flagship Registry Beacon - once per round, the flagship may stamp one enemy; your ships gain +10 points to hit chance against the stamped enemy. || Standard Borne Forward - ships that move toward the flagship this round gain +1 movement.
```

### 023. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:100

Text:
```text
T1: Run at the Biggest Thing - ships that end their burn movement closer to the largest enemy than they started gain +15% damage this round. || Teeth First - a ship that moves at least 4 hexes during the burn may ram with no accuracy penalty.
```

Rule broken: battle.js:873-888: rams use damage, recoil and a run-up, not an accuracy roll. There is no accuracy penalty to waive.

Corrected line:
```text
T1: Run at the Biggest Thing - ships that end their burn movement closer to the largest enemy than they started gain +15% damage this round. || Teeth First - a ship that moves at least 4 hexes during the burn may ram; define a damage or recoil benefit for this pick before implementation.
```

### 024. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:104

Text:
```text
Provenance: Rey draft throughout. Note: Boarding Rush and the boarding references in The Maw Opens propose a boarding action the current battle rules do not have; flagged for Opus as a new-mechanic decision, not assumed to exist.
```

Rule broken: False current-code claim: boarding exists in battle.js:891-917. This is a timing exception, not a missing boarding system.

Corrected line:
```text
Provenance: Rey draft. Boarding Rush changes when an existing boarding action may occur; define whether it waives crew, adjacency and unfired-weapon requirements (battle.js:891-917).
```

### 025. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:108

Text:
```text
T1: Knife Finds the Back - during the Command round, rear-arc hits gain +15% damage on top of the Command bonus. || Torpedoes in the Dark - torpedoes fired this round are screened at -20 effect, as if the firing ships were never seen.
```

Rule broken: Plain reading: screened at -20 effect has no defined unit. Do not guess whether points or percent.

Corrected line:
```text
T1: Knife Finds the Back - during the Command round, rear-arc hits gain +15% damage on top of the Command bonus. || Torpedoes in the Dark - torpedoes fired this round have a proposed reduction to defensive interception; define the amount and unit before implementation.
```

### 026. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:117

Text:
```text
T2: Re-Tasked Mid-Flight - after the first strike resolves, each extra wing may switch to a new target for its strike-again. || Launched from the Wreck Line - carriers that did not move this round launch their extra wings at +15% damage.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
T2: Re-Tasked Mid-Flight - after the first strike resolves, each extra wing may switch to a new target for its immediate bonus attack. || Launched from the Wreck Line - carriers that did not move this round launch their extra wings at +15% damage.
```

### 027. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:118

Text:
```text
T3: The Whole Yard Flies - every ship with any hangar space launches an extra wing during the Command, not only carriers. || Wings Come Back Screaming - the strike-again keeps the full +50% bonus even when it hits a new target across the field.
```

Rule broken: Plain reading: strike-again is shorthand; +50% is only power 1 (battle.js:1077-1085).

Corrected line:
```text
T3: The Whole Yard Flies - every ship with any hangar space launches an extra wing during the Command, not only carriers. || Wings Come Back Screaming - the immediate bonus attack keeps the current Command damage bonus even when it hits a new target across the field.
```

### 028. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:131

Text:
```text
Branch B T1: Prey Chosen by Scent - at battle start, name the pack's prey; your ships gain +10 aim against it. || Loose Pack, Wide Teeth - your ships never block each other's movement or firing lanes.
```

Rule broken: Bible 4.1-4.3 and R64: Hullbreakers follow ion trails and sound, not scent; their faces have no nose. Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
Branch B T1: Prey Chosen by Wake - at battle start, name the pack's prey; your ships gain +10 points to hit chance against it. || Loose Pack, Wide Teeth - your ships never block each other's movement or firing lanes.
```

### 029. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:138

Text:
```text
Branch A - The Verse of Too Many Mouths
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
Branch A - The Hunger of Too Many Mouths
```

### 030. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:140

Text:
```text
T2: The Song Splits - each extra swarm may strike a different target than the rest of its brood's swarms. || Sung Before the Strike - spawning happens before your ships move, so the new swarms can screen your movement this round.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
T2: The Hunger Splits - each extra swarm may strike a different target than the rest of its brood's swarms. || Grown Before the Strike - spawning happens before your ships move, so the new swarms can screen your movement this round.
```

### 031. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:141

Text:
```text
T3: Every Throat Opens - a brood that did not move this round releases one more extra swarm. || The Verse Bites Twice - a swarm striking a target already hit by another swarm this round gains +25% damage.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
T3: Every Throat Opens - a brood that did not move this round releases one more extra swarm. || The Hunger Bites Twice - a swarm striking a target already hit by another swarm this round gains +25% damage.
```

### 032. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:142

Text:
```text
Capstone: Nine Throats, One Verse - Spawning surge releases an extra swarm from every ship that carries swarms, not only from broods. || The Song Does Not End - the extra swarms remain after the Command and strike once more at the start of next round before fading.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
Capstone: Nine Throats, One Hunger - Spawning surge releases an extra swarm from every ship that carries swarms, not only from broods. || The Hunger Does Not End - the extra swarms remain after the Command and strike once more at the start of next round before fading.
```

### 033. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:146

Text:
```text
Branch A - The Hunting Verse
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
Branch A - The Hunting Hunger
```

### 034. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:148

Text:
```text
T2: The Pack Sings One Prey - name one prey when the frenzy begins; ships moving toward the prey gain +1 movement. || Blood in the Water - during the frenzy, a ship may change targets freely after each kill without losing the frenzy's accuracy protection.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
T2: Every Mouth Wants One Prey - name one prey when the frenzy begins; ships moving toward the prey gain +1 movement. || Blood in the Water - during the frenzy, a ship may change targets freely after each kill without losing the frenzy's accuracy protection.
```

### 035. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:149

Text:
```text
T3: Frenzy Feeds the Verse - a ship that lands a rear-arc hit during the frenzy may immediately move 2 more hexes. || Howl Before the Bite - during the frenzy, an enemy adjacent to two or more of your ships loses a further 20 accuracy.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
T3: Frenzy Feeds the Hunger - a ship that lands a rear-arc hit during the frenzy may immediately move 2 more hexes. || Howl Before the Bite - during the frenzy, an enemy adjacent to two or more of your ships loses a further 20 accuracy.
```

### 036. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:150

Text:
```text
Capstone: The Verse Turns Red - the frenzy's movement and accuracy protection last through next round, but only for ships that end this round adjacent to an enemy. || One Prey, Every Mouth - when the frenzy is declared, every ship may move directly toward the named prey, ignoring its turn limit once.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
Capstone: The Hunger Turns Red - the frenzy's movement and accuracy protection last through next round, but only for ships that end this round adjacent to an enemy. || One Prey, Every Mouth - when the frenzy is declared, every ship may move directly toward the named prey, ignoring its turn limit once.
```

### 037. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:154

Text:
```text
Branch A - The Mending Verse
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
Branch A - The Mending Flesh
```

### 038. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:155

Text:
```text
T1: Grow Where It Hurts - you may assign one ship's entire regrowth to a single damaged section. || Skin Before Song - a ship may take its regrowth as temporary extra hull, up to +15%, instead of repairing damage.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
T1: Grow Where It Hurts - you may assign one ship's entire regrowth to a single damaged section. || Skin Before Hunger - a ship may take its regrowth as temporary extra hull, up to +15%, instead of repairing damage.
```

### 039. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:156

Text:
```text
T2: The Tide Comes Early - Regrowth tide may be sung at the start of the round, before any fire is taken. || Growth Remembers the Wound - a section healed by the tide regrows at double rate again next round.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names. Bible 1.3: Chorus Memory exception is confined to story/dialogue, not skill names.

Corrected line:
```text
T2: The Tide Comes Early - Regrowth tide may begin at the start of the round, before any fire is taken. || Growth Closes the Wound - a section healed by the tide regrows at double rate again next round.
```

### 040. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:157

Text:
```text
T3: Flesh Knit for War - a ship the tide brings above three quarters hull gains +20% damage next round. || The Verse Refuses Holes - while any of your ships is below half hull, the most damaged ship regrows 10% at each round start until it passes half.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
T3: Flesh Knit for War - a ship the tide brings above three quarters hull gains +20% damage next round. || The Flesh Refuses Holes - while any of your ships is below half hull, the most damaged ship regrows 10% at each round start until it passes half.
```

### 041. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:158

Text:
```text
Capstone: Tide Without a Shore - Regrowth tide heals a second time at the end of the round, at half strength. || What Was Sung Grows Back - the tide restores destroyed sections to full function, and a section restored this way cannot be destroyed again this battle.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
Capstone: Tide Without a Shore - Regrowth tide heals a second time at the end of the round, at half strength. || What Was Torn Grows Back - the tide restores destroyed sections to full function, and a section restored this way cannot be destroyed again this battle.
```

### 042. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:162

Text:
```text
Branch A - The Acid Verse
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
Branch A - The Acid Throat
```

### 043. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:163

Text:
```text
T1: Acid Before Aim - each ship may spit its volley at the nearest enemy instead of the best target. || Every Throat Spits - a ship whose guns cannot bear may still spit once at half damage at the nearest enemy in range.
```

Rule broken: Plain reading: guns cannot bear means guns cannot aim in the required direction.

Corrected line:
```text
T1: Acid Before Aim - each ship may spit its volley at the nearest enemy instead of the best target. || Every Throat Spits - a ship whose guns cannot aim at the target may still spit once at half damage at the nearest enemy in range.
```

### 044. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:164

Text:
```text
T2: The Burn Stays - an enemy hit by the volley takes acid damage at the start of next round equal to 15% of the volley damage it took. || Sung in Rounds - you may fire the volley in two halves, the second half after your ships move.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
T2: The Burn Stays - an enemy hit by the volley takes acid damage at the start of next round equal to 15% of the volley damage it took. || Spat in Rounds - you may fire the volley in two halves, the second half after your ships move.
```

### 045. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:165

Text:
```text
T3: Acid Finds the Seams - volley hits ignore armor on targets below half hull. || Chorus of Mouths - before the volley resolves, each ship may switch its target once; if four or more ships spit at one target, that target loses 20 accuracy next round as acid eats at its sensors.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
T3: Acid Finds the Seams - volley hits ignore armor on targets below half hull. || Many Mouths - before the volley resolves, each ship may switch its target once; if four or more ships spit at one target, that target loses 20 accuracy next round as acid eats at its sensors.
```

### 046. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:170

Text:
```text
Branch B T1: Verses Assigned at Hatching - at battle start, give each ship a verse (strike, screen, or mend); a ship may change its verse once per battle. || Broods in Reserve - hold one brood off the field; it enters, grown and ready, at the start of round 2.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names.

Corrected line:
```text
Branch B T1: Roles Grown at Hatching - at battle start, give each ship a role (strike, screen, or mend); a ship may change its role once per battle. || Broods in Reserve - hold one brood off the field; it enters, grown and ready, at the start of round 2.
```

### 047. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:171

Text:
```text
Branch C T1: The Flagship Sings First - once per battle, one other ship may act immediately after the flagship finishes its activation. || Throat of the Deep Song - ships within 2 hexes of the flagship gain +10 aim.
```

Rule broken: Bible 1.3,5.2: no faction sings. Musical song/verse framing is retired, including branch and skill names. Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
Branch C T1: The Flagship Feeds First - once per battle, one other ship may act immediately after the flagship finishes its activation. || Throat of the Deep Hunger - ships within 2 hexes of the flagship gain +10 points to hit chance.
```

### 048. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:179

Text:
```text
T2: The Replay Corrects - after the first strike resolves, each extra wing may be retargeted freely for its strike-again, using what the glass recorded. || Starlings in Formation - extra wings that strike in the same order as their carriers are arranged gain +10 aim.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
T2: The Replay Corrects - after the first strike resolves, each extra wing may be retargeted freely for its immediate bonus attack, using what the glass recorded. || Starlings in Formation - extra wings that strike in the same order as their carriers are arranged gain +10 points to hit chance.
```

### 049. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:187

Text:
```text
T2: Light Arrives Together - you may hold the volley until all your ships have moved, and fire lance shots in any order you choose. || The Recorded Angle - before the volley, each ship may turn once to bring its best lance to bear.
```

Rule broken: Plain reading: bring a lance to bear means turn it toward its target.

Corrected line:
```text
T2: Light Arrives Together - you may hold the volley until all your ships have moved, and fire lance shots in any order you choose. || The Recorded Angle - before the volley, each ship may turn once to aim its strongest lance at its target.
```

### 050. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:194

Text:
```text
T1: Two Images Appear - during the scatter, the first enemy shot at each of your ships each round is aimed at a false image and loses a further 20 accuracy. || Angles Recorded - a ship that ends its scatter movement facing a different direction than it started gains +10 evasion until next round.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
T1: Two Images Appear - during the scatter, the first enemy shot at each of your ships each round is aimed at a false image and loses a further 20 accuracy. || Angles Recorded - a ship that ends its scatter movement facing a different direction than it started gains +10 points to the chance of avoiding enemy fire until next round.
```

### 051. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:203

Text:
```text
T2: Recharge While Lit - during the ward, shields recharge a second time at round end, at the prism recharge rate. || The Lens Rotates - during the ward, a ship may change its facing after moving without losing the damage reduction.
```

Rule broken: battle.js:1097,1106: turning does not cancel Prism ward. Name the new turning benefit rather than imply a nonexistent restriction.

Corrected line:
```text
T2: Recharge While Lit - during the ward, shields recharge a second time at round end, at the prism recharge rate. || The Lens Rotates - during the ward, a ship may turn once after moving without spending movement or a turn allowance.
```

### 052. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:210

Text:
```text
Branch C T1: The Flagship Lens - once per round, the flagship may focus one enemy; your lance shots against it gain +10 aim. || First Light Recorded - the flagship records the first enemy ship that fires each battle; your fleet gains +10 evasion against that ship for the battle.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
Branch C T1: The Flagship Lens - once per round, the flagship may focus one enemy; your lance shots against it gain +10 points to hit chance. || First Light Recorded - the flagship records the first enemy ship that fires each battle; your fleet gains +10 points to the chance of avoiding enemy fire against that ship for the battle.
```

### 053. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:218

Text:
```text
T2: Iteration Runs During Fire - a ship being rebuilt by the swarms may act normally this round; the rebuild never delays its fire. || The Archive Answers First - the swarms may be released at the very start of the round, before any ship moves or fires.
```

Rule broken: battle.js:1107: repair is immediate and never suspends ship actions. Removing a nonexistent restriction gives no benefit.

Corrected line:
```text
T2: Iteration Runs During Fire - choose whether to repair one ship before or after it fires this round. || The Archive Answers First - the swarms may be released at the very start of the round, before any ship moves or fires.
```

### 054. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:233

Text:
```text
T1: Copied from Behind - during the Command round, rear-arc hits gain +20% damage on top of the Command bonus. || Never Filed as a Target - during the Command round, a ship that was not targeted last round gains a further +15% damage.
```

Rule broken: Bible 1.3: filing is Hegemony identity, not Eclipse.

Corrected line:
```text
T1: Copied from Behind - during the Command round, rear-arc hits gain +20% damage on top of the Command bonus. || Unseen in the Last Copy - during the Command round, a ship that was not targeted last round gains a further +15% damage.
```

### 055. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:241

Text:
```text
T1: Plates over Light - you may convert up to half of one ship's shield refill into hull plating that lasts the rest of the battle. || The Twice-Restored Order - a ship that has already been repaired earlier in this battle refills +25% more shield during the wall.
```

Rule broken: Eclipse has no shields (bible 7.5; data.js:98-101; battle.js:1106). No shield refill exists to convert or multiply.

Corrected line:
```text
T1: Plates over Darkness - proposed: Sunshade wall grants temporary hull plating to one ship. || The Twice-Restored Order - proposed: ships repaired earlier this battle gain stronger wall protection. Define both amounts before implementation.
```

### 056. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:242

Text:
```text
T2: Wall Filed in Advance - the wall may be declared at the start of the round, and its reduction applies from the first enemy shot of the round. || Layers Shift - during the wall, a ship may pass up to a quarter of its current shields to an adjacent friendly ship.
```

Rule broken: Eclipse is shieldless; shield transfer is impossible. Filing also borrows Hegemony voice (bible 1.3,7.5).

Corrected line:
```text
T2: Wall Remembered in Advance - the wall may be declared at round start. || Layers Shift - proposed: transfer temporary hull plating to an adjacent friendly ship. Define amount and expiry before implementation.
```

### 057. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:244

Text:
```text
Capstone: Wall of Ten Thousand Copies - Sunshade wall lasts two rounds, and shields refill again at half strength at the start of the second round. || The Restored Fleet - while the wall is active, shield refill beyond a ship's maximum overflows into the next friendly ship's shields.
```

Rule broken: Eclipse is shieldless; repeat shield refill and shield overflow cannot work (bible 7.5; battle.js:1106).

Corrected line:
```text
Capstone: Wall of Ten Thousand Copies - Sunshade wall lasts two rounds. || The Restored Fleet - proposed: unused temporary hull plating may pass to another friendly ship. Define amount and expiry before implementation.
```

### 058. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:248

Text:
```text
Branch B T1: Formation Loaded from Archive - choose one archived formation at battle start; ships that end their movement inside it gain +10 evasion that round. || Iteration Swap - once per battle, swap the positions of two of your ships, as the Archive substitutes a corrected version of the plan.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
Branch B T1: Formation Loaded from Archive - choose one archived formation at battle start; ships that end their movement inside it gain +10 points to the chance of avoiding enemy fire that round. || Iteration Swap - once per battle, swap the positions of two of your ships, as the Archive substitutes a corrected version of the plan.
```

### 059. contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md:254

Text:
```text
- Two proposals in the assembled text reach beyond current mechanics and need a technical decision rather than a text edit: boarding (Ironmaw Branch A) and cross-ship damage splitting (noted at Brin, held in the Qwen draft rather than assembled).
```

Rule broken: Boarding already exists in battle.js:891-917.

Corrected line:
```text
- Ironmaw proposes exceptions to existing boarding timing/action limits. Cross-ship damage splitting remains an unassembled proposal.
```

## skill_tree_tier2_assembled_2026_10_29.md (11)

### 060. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:8

Text:
```text
Branch B T2: The Held Volley - when you declare the Command, you may hold the volley instead of firing it; it fires at the start of the next round, at targets chosen then. || Converging Arcs - after the first friendly ship fires at a target this round, every other friendly ship with a volley that can reach that target may shift its firing arc by one hex-face before shooting.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
Branch B T2: The Held Volley - when you declare the Command, you may hold the volley instead of firing it; it fires at the start of the next round, at targets chosen then. || Converging Arcs - after the first friendly ship fires at a target this round, every other friendly ship with a volley that can reach that target may shift its firing arc by one of the six hex directions before shooting.
```

### 061. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:13

Text:
```text
Branch B T2: Volley on the Counterstroke - you may declare the Command and hold it as a threat; the volley is released immediately after the first enemy ship fires in the next round, each ship at its best target then. || Corrected Solution - once per round, after a friendly ship misses every shot in its volley, one other friendly ship may immediately fire a single volley at the same target at +15 aim.
```

Rule broken: Plain reading: unexplained aim/evasion/crit or hex-face/strike-again shorthand. State chance, unit or action; no balance change intended.

Corrected line:
```text
Branch B T2: Volley on the Counterstroke - you may declare the Command and hold it as a threat; the volley is released immediately after the first enemy ship fires in the next round, each ship at its best target then. || Corrected Solution - once per round, after a friendly ship misses every shot in its volley, one other friendly ship may immediately fire a single volley at the same target at +15 points to hit chance.
```

### 062. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:22

Text:
```text
## Pair 4: Commodore Corin Reyes + The Matriarch of Nine Throats (scramble)
```

Rule broken: Bible 3.8 and data.js:219: Reyes is Fleet Marshal, not Commodore.

Corrected line:
```text
## Pair 4: Fleet Marshal Corin Reyes + The Matriarch of Nine Throats (scramble)
```

### 063. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:28

Text:
```text
Branch B T2: Quarry Marked - at battle start, name one enemy ship as the quarry; friendly ships may fire torpedoes at the quarry at any point during their movement, not only at the end. || Torpedoes Held Keep Their Teeth - a ship may hold its reloaded torpedoes through the Command round; torpedoes held this way keep the Command's damage bonus when they are fired next round.
```

Rule broken: Ostrel description has no torpedo reload (data.js:235), though generic hunt currently reloads them (battle.js:1105). Do not assume which is intended.

Corrected line:
```text
Branch B T2: Quarry Marked - at battle start, name one enemy ship as the quarry; friendly ships may fire torpedoes at the quarry at any point during their movement, not only at the end. || Torpedoes Held Keep Their Teeth - a ship may hold any torpedoes it has ready through the Command round; torpedoes held this way keep the Command's damage bonus when they are fired next round.
```

### 064. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:38

Text:
```text
Branch B T2: Wall Raised on Their Turn - the Command may be declared at the start of the enemy's turn instead of your own, its refill and reduction covering the enemy's fire. || A Clean Wall Refills Twice - ships that take no hull damage during the Command round refill their shields again at the start of the next round.
```

Rule broken: Shared Thale/Seveth skill assumes shields for Eclipse, which is shieldless (bible 7.5; battle.js:1106). Split faction wording or use protection for both.

Corrected line:
```text
Branch B T2: Wall Raised on Their Turn - the Command may be declared at the start of the enemy's turn instead of your own, its refill and reduction covering the enemy's fire. || A Clean Wall Refills Twice - ships that take no hull damage during the Command round receive wall protection again at the start of the next round.
```

### 065. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:39

Text:
```text
Branch C T2: The Flagship Gives Its Refill Away - when you declare the Command, the flagship may pass its shield refill to one other ship whose shields are empty; that ship refills twice, and the flagship not at all. || The Flagship Keeps the Wall - the flagship's damage reduction from the Command lasts through the following round as well.
```

Rule broken: Shared Thale/Seveth skill assumes shields for Eclipse, which is shieldless (bible 7.5; battle.js:1106). Split faction wording or use protection for both.

Corrected line:
```text
Branch C T2: The Flagship Gives Its Protection Away - when you declare the Command, the flagship may pass its wall protection to one other ship; define the resulting reduction before implementation. || The Flagship Keeps the Wall - the flagship's damage reduction from the Command lasts through the following round as well.
```

### 066. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:43

Text:
```text
Branch B T2: Shoulder to Shoulder - during the Command round, a ship that ends its movement adjacent to another friendly ship refills its shields again at round end. || Braced at First Light - ships that do not move during the Command round begin the next round braced.
```

Rule broken: Glasswrights cannot brace (bible 6.5; data.js:542; battle.js:1041). Shared Brin skill must not silently erase the faction rule.

Corrected line:
```text
Branch B T2: Shoulder to Shoulder - during the Command round, a ship that ends its movement adjacent to another friendly ship refills its shields again at round end. || Held at First Light - proposed: ships that do not move during the Command round keep wall protection into next round; this does not grant Brace.
```

### 067. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:49

Text:
```text
Branch C T2: The Flagship Burns Furthest - during the Command, the flagship gains +3 movement instead of +2. || In the Flagship's Wake - ships that end their Command movement in a hex the flagship passed through this round keep the Command's shelter from enemy fire into the next round.
```

Rule broken: battle.js:1077: surge gives +2/+3/+4 movement. +3 instead of +2 can reduce a full-power Command.

Corrected line:
```text
Branch C T2: The Flagship Burns Furthest - during the Command, the flagship gains 1 movement in addition to the current Command bonus. || In the Flagship's Wake - ships that end their Command movement in a hex the flagship passed through this round keep the Command's shelter from enemy fire into the next round.
```

### 068. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:52

Text:
```text
## Pair 10: The Mending Throng + Ninth Frame (restore)
```

Rule broken: Use full approved admiral name, not an iteration epithet alone (bible 7.9).

Corrected line:
```text
## Pair 10: The Mending Throng + Nadir Aurex, Ninth Frame (restore)
```

### 069. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:53

Text:
```text
Branch B T2: Growth Where It Is Needed - when you declare the Command, name one ship; it repairs twice as much, and every other ship repairs half as much. || Sections Before Hull - when you declare the Command, choose the fleet's mending: as normal, or damaged sections are restored first and hull repair is halved.
```

Rule broken: Shared Chorus/Eclipse title assigns living growth to machine bodies (bible 1.3,7.3). Use neutral repair.

Corrected line:
```text
Branch B T2: Repair Where It Is Needed - when you declare the Command, name one ship; it repairs twice as much, and every other ship repairs half as much. || Sections Before Hull - when you declare the Command, choose the fleet's mending: as normal, or damaged sections are restored first and hull repair is halved.
```

### 070. contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md:54

Text:
```text
Branch C T2: The Flagship Banks Its Mending - the flagship repairs nothing when you declare the Command; it may spend its repair at the start of any later round. || The Flagship Gives Its Growth Away - the flagship may give its repair to one other ship, which repairs its own share and the flagship's share as well; the flagship repairs nothing.
```

Rule broken: Shared Chorus/Eclipse title assigns living growth to machine bodies (bible 1.3,7.3).

Corrected line:
```text
Branch C T2: The Flagship Banks Its Mending - the flagship repairs nothing when you declare the Command; it may spend its repair at the start of any later round. || The Flagship Gives Its Repair Away - the flagship may give its repair to one other ship, which repairs its own share and the flagship's share as well; the flagship repairs nothing.
```

## skill_tree_tier3_assembled_2026_10_29.md (11)

### 071. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:25

Text:
```text
Branch C T3: The Flagship Is the Wall - once per battle, the flagship may extend its own damage reduction to every friendly ship within 2 hexes for one round. || The Admiral Stands in the Ledger - while the flagship's shields are above half, it takes 20% less hull damage.
```

Rule broken: Bible 1.3,2.4: Crusade keeps chalked rolls and oaths, not Hegemony ledgers.

Corrected line:
```text
Branch C T3: The Flagship Is the Wall - once per battle, the flagship may extend its own damage reduction to every friendly ship within 2 hexes for one round. || The Admiral Stands by the Roll - while the flagship's shields are above half, it takes 20% less hull damage.
```

### 072. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:30

Text:
```text
Branch B T3: Sync Takes a Second Anchor - once per battle, if the flagship is crippled or out of range, sync may form around any cruiser for one round instead. || Iron Procedure Under Fire [Qwen swap] - sync may be maintained while the flagship moves; the sync radius is measured from the flagship's position at the moment of firing, not at round start.
```

Rule broken: battle.js:498: sync already updates with flagship position and is not cancelled by movement; second pick gives no baseline benefit.

Corrected line:
```text
Branch B T3: Sync Takes a Second Anchor - once per battle, if the flagship is crippled or out of range, sync may form around any cruiser for one round instead. || Iron Procedure Under Fire [Qwen swap] - proposed: ships in sync at round start keep sync for the round even if the flagship moves out of range.
```

### 073. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:39

Text:
```text
Branch C T3: The Flagship Publishes the Strike [Qwen swap] - the flagship's extra wing strikes last in the Command and may target any enemy in range regardless of its own carrier's position; if it destroys its target, one other extra wing may strike again at half damage. || Reyes Keeps the Original Order - once per battle, the flagship may cancel every reassignment and send all extra wings back to the strike group's named target at full effect. [Chair wording fix: the Rey draft said "the filed target," which is Vorn's mechanic; the assembled text names Reyes's own target instead. No other change.]
```

Rule broken: Plain reading: any enemy in range regardless of carrier position gives conflicting range origins.

Corrected line:
```text
Branch C T3: The Flagship Publishes the Strike [Qwen swap] - the flagship's extra wing strikes last in the Command and may target any enemy within the wing's own attack range, measured from the wing; if it destroys its target, one other extra wing may strike again at half damage. || Reyes Keeps the Original Order - once per battle, the flagship may cancel every reassignment and send all extra wings back to the strike group's named target at full effect. [Chair wording fix: the Rey draft said "the filed target," which is Vorn's mechanic; the assembled text names Reyes's own target instead. No other change.]
```

### 074. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:49

Text:
```text
Branch C T3: The Warlord Bites First - once per battle, the flagship may ram before any other ship acts in the burn round, and that ram ignores the target's accuracy protection. || Ironmaw's Own Scar - after the flagship rams for the first time in a battle, it gains +1 movement during every later burn in that battle.
```

Rule broken: battle.js:873-888: rams make no accuracy roll. Accuracy protection does not prevent a ram.

Corrected line:
```text
Branch C T3: The Warlord Bites First - once per battle, the flagship may ram before any other ship acts in the burn round, and that ram needs a defined damage or recoil benefit before implementation. || Ironmaw's Own Scar - after the flagship rams for the first time in a battle, it gains +1 movement during every later burn in that battle.
```

### 075. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:66

Text:
```text
Branch B T3: Broods Sing the Strike Order - you choose the order in which broods release; the last brood to release has its extra swarms strike at +25% damage. || Swarms Seed the Field - extra swarms may be placed on empty hexes instead of striking; the first enemy to move through such a hex takes a strike at half damage.
```

Rule broken: Bible 1.3,5.2: Chorus never sings.

Corrected line:
```text
Branch B T3: Broods Follow the Strike Order - you choose the order in which broods release; the last brood to release has its extra swarms strike at +25% damage. || Swarms Seed the Field - extra swarms may be placed on empty hexes instead of striking; the first enemy to move through such a hex takes a strike at half damage.
```

### 076. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:70

Text:
```text
Branch B T3: The Pack Cuts the Herd - during the frenzy, when one of your ships destroys an enemy, every other ship may change its target to the destroyed ship's nearest ally at no cost. || Frenzy Runs Uphill - during the frenzy, a ship keeps the accuracy protection even when it moves away from enemies, as long as it ends its move adjacent to a friendly ship.
```

Rule broken: Bible 1.3: pack naming belongs to Hullbreakers; Chorus is one swarm.

Corrected line:
```text
Branch B T3: The Swarm Cuts the Herd - during the frenzy, when one of your ships destroys an enemy, every other ship may change its target to the destroyed ship's nearest ally at no cost. || Frenzy Runs Uphill - during the frenzy, a ship keeps the accuracy protection even when it moves away from enemies, as long as it ends its move adjacent to a friendly ship.
```

### 077. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:74

Text:
```text
Branch B T3: The Tide Chooses One Shore - when the tide is sung, you may double the regrowth of every ship below half hull and give none to ships above three quarters hull. || Growth That Fights First - a ship may take its regrowth before it fires this round, at half strength, instead of at the tide's normal time.
```

Rule broken: Bible 1.3,5.2: Chorus never sings.

Corrected line:
```text
Branch B T3: The Tide Chooses One Shore - when the tide begins, you may double the regrowth of every ship below half hull and give none to ships above three quarters hull. || Growth That Fights First - a ship may take its regrowth before it fires this round, at half strength, instead of at the tide's normal time.
```

### 078. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:75

Text:
```text
Branch C T3: The Throng Sings the Flagship Whole - once per battle, the flagship may take the entire fleet's regrowth share for one round. || The Flagship Grows Deepest - the flagship regrows 25% more from every tide.
```

Rule broken: Bible 1.3,5.2: Chorus never sings.

Corrected line:
```text
Branch C T3: The Throng Grows the Flagship Whole - once per battle, the flagship may take the entire fleet's regrowth share for one round. || The Flagship Grows Deepest - the flagship regrows 25% more from every tide.
```

### 079. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:106

Text:
```text
Branch B T3: Noon Falls Where Filed - when the volley is declared, choose one side of your fleet; ships on that side fire their volleys twice at half damage, and the rest hold their fire. || Copied Light, Second Noon - a ship whose volley missed with every shot may fire one weapon again at the end of the round.
```

Rule broken: Bible 1.3: Filed gives Eclipse the Hegemony administrative voice.

Corrected line:
```text
Branch B T3: Noon Falls Where Remembered - when the volley is declared, choose one side of your fleet; ships on that side fire their volleys twice at half damage, and the rest hold their fire. || Copied Light, Second Noon - a ship whose volley missed with every shot may fire one weapon again at the end of the round.
```

### 080. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:114

Text:
```text
Branch B T3: Layers over Layers - during the wall, shield refill beyond a ship's maximum may be laid down as plating instead, up to 15% temporary hull. || Shade for the Exposed - during the wall, the friendly ship with the lowest shields gains the wall's damage reduction even if it is outside the formation.
```

Rule broken: Eclipse has no shields, and Sunshade wall is fleet-wide with no formation condition (bible 7.5; battle.js:1097,1106).

Corrected line:
```text
Branch B T3: Layers over Layers - proposed: repairs beyond maximum hull become temporary plating, up to 15% temporary hull. || Shade for the Exposed - proposed: the ship with least hull receives stronger wall protection. Define strength before implementation; the wall has no formation range.
```

### 081. contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md:115

Text:
```text
Branch C T3: Seveth Stands Twice-Restored - once per battle, when the flagship's shields reach zero, they immediately refill to 25%. || The Flagship Shares Its Shade - during the wall, ships adjacent to the flagship use the flagship's damage reduction value instead of their own.
```

Rule broken: Seveth is shieldless; a zero-shield trigger/refill cannot work (bible 7.5; data.js:98-101).

Corrected line:
```text
Branch C T3: Seveth Stands Twice-Restored - once per battle, when the flagship falls below 25% hull, it repairs 25% of maximum hull. || The Flagship Shares Its Shade - during the wall, ships adjacent to the flagship use the flagship's damage reduction value instead of their own.
```

## nemesis_lines_assembled_2026_10_29.md (23)

### 082. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:9

Text:
```text
- cunning [Rey]: I did not come for your strongest ship. I never do.
```

Rule broken: Bible 5.2: cunning/cruel/patient can roll for Chorus (data.js:472); I/me/my and human drill/data register need a collective faction override. Retain original where appropriate for other factions.

Corrected line:
```text
- cunning [Rey], Chorus override: We want the soft ship. Not the strong one.
```

### 083. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:10

Text:
```text
- cunning [Qwen]: I have counted your ships. I know which one you will sacrifice first.
```

Rule broken: Bible 5.2: cunning/cruel/patient can roll for Chorus (data.js:472); I/me/my and human drill/data register need a collective faction override. Retain original where appropriate for other factions.

Corrected line:
```text
- cunning [Qwen], Chorus override: We count your ships. We know which one you will leave.
```

### 084. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:13

Text:
```text
- cruel [Rey]: Scream all you like on open channels. I count it as ranging data.
```

Rule broken: Bible 5.2: cunning/cruel/patient can roll for Chorus (data.js:472); I/me/my and human drill/data register need a collective faction override. Retain original where appropriate for other factions.

Corrected line:
```text
- cruel [Rey], Chorus override: Scream. We taste the fear.
```

### 085. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:14

Text:
```text
- cruel [DeepSeek]: Your crippled will be finished first. I want you to watch.
```

Rule broken: Bible 5.2: cunning/cruel/patient can roll for Chorus (data.js:472); I/me/my and human drill/data register need a collective faction override. Retain original where appropriate for other factions.

Corrected line:
```text
- cruel [DeepSeek], Chorus override: We eat the broken ones first. Watch.
```

### 086. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:15

Text:
```text
- patient [Rey]: Empires have mustered against me and gone home to dust. Your turn now.
```

Rule broken: Bible 5.2: cunning/cruel/patient can roll for Chorus (data.js:472); I/me/my and human drill/data register need a collective faction override. Retain original where appropriate for other factions.

Corrected line:
```text
- patient [Rey], Chorus override: Others came. Others cooled. You are warm.
```

### 087. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:16

Text:
```text
- patient [DeepSeek]: Time is my ally. I will spend yours.
```

Rule broken: Bible 5.2: cunning/cruel/patient can roll for Chorus (data.js:472); I/me/my and human drill/data register need a collective faction override. Retain original where appropriate for other factions.

Corrected line:
```text
- patient [DeepSeek], Chorus override: We wait. You cool.
```

### 088. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:23

Text:
```text
- ravenous [Rey]: We can smell your reactor wash from three systems out. We have been following it like a trail of blood.
```

Rule broken: Bible 5.2: ravenous is Chorus-only (data.js:472); use we, not I, and short lines. Literal reactor smell across three systems is unexplained.

Corrected line:
```text
- ravenous [Rey]: We taste your heat in every wreck. We follow. We feed.
```

### 089. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:24

Text:
```text
- ravenous [Qwen]: I do not pick targets. I eat whatever is nearest.
```

Rule broken: Bible 5.2: ravenous is Chorus-only (data.js:472); use we, not I, and short lines. Literal reactor smell across three systems is unexplained.

Corrected line:
```text
- ravenous [Qwen]: We do not choose. We eat what is nearest.
```

### 090. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:28

Text:
```text
- [Rey]: You beat me with {beat} once. I took the counter for it, and I have been drilling it ever since.
```

Rule broken: Bible 5.2: shared again/remember/gloat pools also need Chorus collective variants. Ships remember also universalizes the Eclipse memory motif (bible 1.3).

Corrected line:
```text
- [Rey], Chorus override: You hurt us with {beat}. We grew against it. Try again.
```

### 091. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:29

Text:
```text
- [Qwen]: {beat} was your trick last time. I have drilled the counter into every crew I command.
```

Rule broken: Bible 5.2: shared again/remember/gloat pools also need Chorus collective variants. Ships remember also universalizes the Eclipse memory motif (bible 1.3).

Corrected line:
```text
- [Qwen], Chorus override: {beat} hurt us. The next flesh grew harder.
```

### 092. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:33

Text:
```text
- [Rey]: You beat me with {beat}. No counter yet, I admit it freely. It changes nothing about today.
```

Rule broken: Bible 5.2: shared again/remember/gloat pools also need Chorus collective variants. Ships remember also universalizes the Eclipse memory motif (bible 1.3).

Corrected line:
```text
- [Rey], Chorus override: {beat} hurt us. We have not grown against it. We still feed.
```

### 093. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:34

Text:
```text
- [Qwen]: You beat me with {beat}. I carry that scar.
```

Rule broken: Bible 5.2: shared again/remember/gloat pools also need Chorus collective variants. Ships remember also universalizes the Eclipse memory motif (bible 1.3).

Corrected line:
```text
- [Qwen], Chorus override: {beat} hurt us. We keep the wound.
```

### 094. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:38

Text:
```text
- flagship [Rey]: Your flagship died under my guns once. Ships remember, even when crews cannot.
```

Rule broken: Bible 5.2: shared again/remember/gloat pools also need Chorus collective variants. Ships remember also universalizes the Eclipse memory motif (bible 1.3).

Corrected line:
```text
- flagship [Rey], Chorus override: We broke your flagship once. We can break this one.
```

### 095. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:39

Text:
```text
- retreat [Qwen]: You turned your engines away from me. I let you. I always let you run.
```

Rule broken: Bible 5.2: shared again/remember/gloat pools also need Chorus collective variants. Ships remember also universalizes the Eclipse memory motif (bible 1.3).

Corrected line:
```text
- retreat [Qwen], Chorus override: You turned away. We watched you run.
```

### 096. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:45

Text:
```text
- Sunward Crusade [Qwen]: Scorch-markings on the wreckage are consistent with [WEAKNESS], though the oath-plate may have obscured the full picture.
```

Rule broken: Player-keyed Crusade report must not assume enemy oath-plate; simplify uncertainty.

Corrected line:
```text
- Sunward Crusade [Qwen]: The wreckage bears the marks. We think the enemy weakness is [WEAKNESS]. We will not swear it yet.
```

### 097. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:46

Text:
```text
- Hegemony [Rey]: The after-action review is three signatures short of certain, but the pattern keeps surfacing in the gunnery plots: [WEAKNESS].
```

Rule broken: Plain reading: three signatures short of certain hides what the player learned.

Corrected line:
```text
- Hegemony [Rey]: Our battle review is incomplete. The gunnery records suggest an enemy weakness: [WEAKNESS].
```

### 098. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:47

Text:
```text
- Hegemony [Qwen]: Signals intercepts recovered from the battlefield suggest the line is vulnerable to [WEAKNESS], though the cipher was only partially broken.
```

Rule broken: data.js:429-436: weakness names include A proud flagship and Worn engines; vulnerable to does not fit those substitutions.

Corrected line:
```text
- Hegemony [Qwen]: Signals intercepts recovered from the battlefield suggest the enemy has a weakness: [WEAKNESS], though the cipher was only partially broken.
```

### 099. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:49

Text:
```text
- Ashfall Hullbreakers [Qwen]: Salvage pulled from the raider's wake suggests a vulnerability to [WEAKNESS], though the evidence is fragmentary.
```

Rule broken: Player-faction key is not enemy-faction key. Raider/backup/enemy Archive assumes the opponent species; the Oct 30 correction lines 9-13 explains this rule.

Corrected line:
```text
- Ashfall Hullbreakers [Qwen]: The plates we took show one possible fault. Not proven: [WEAKNESS].
```

### 100. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:50

Text:
```text
- The Chorus [Rey]: The throats that fed on the wreckage sing uncertain of everything but one soft place in the enemy fleet: [WEAKNESS].
```

Rule broken: Bible 1.3,5.2: Chorus never sings. Use short collective sensory speech.

Corrected line:
```text
- The Chorus [Rey]: We fed on the wreckage. One soft place. Not certain yet: [WEAKNESS].
```

### 101. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:53

Text:
```text
- Glasswrights [Qwen]: Prism-shard analysis from the duel site suggests the fleet may be susceptible to [WEAKNESS], though the mirrors were already re-aligning.
```

Rule broken: data.js:429-436: fault names do not fit susceptible to.

Corrected line:
```text
- Glasswrights [Qwen]: Prism-shard analysis from the duel site suggests an enemy weakness, though the mirrors were already re-aligning: [WEAKNESS].
```

### 102. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:55

Text:
```text
- Eclipse [Rey]: A fragment of a Nemesis backup, recovered and only partly legible, suggests what no interrogation could: [WEAKNESS].
```

Rule broken: Player-faction key is not enemy-faction key. Raider/backup/enemy Archive assumes the opponent species; the Oct 30 correction lines 9-13 explains this rule.

Corrected line:
```text
- Eclipse [Rey]: Our partial battle copy preserves one possible flaw, though much is missing: [WEAKNESS].
```

### 103. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:62

Text:
```text
- The Chorus: Every throat sings it now, and the song does not waver: [WEAKNESS], tasted and known.
```

Rule broken: Bible 1.3,5.2: Chorus never sings. Use short collective sensory speech.

Corrected line:
```text
- The Chorus: We tasted it. Every throat knows. The weak place is [WEAKNESS].
```

### 104. contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md:64

Text:
```text
- Eclipse: The enemy Archive, taken intact, states it without hedging: [WEAKNESS]. The copy agrees with the original.
```

Rule broken: Player-faction key is not enemy-faction key. Raider/backup/enemy Archive assumes the opponent species; the Oct 30 correction lines 9-13 explains this rule.

Corrected line:
```text
- Eclipse: Our Archive holds the battle intact. Every copy confirms the enemy weakness: [WEAKNESS].
```

## nemesis_lines_correction_2026_10_30.md (1)

### 105. contrib/muse/reviews/nemesis_lines_correction_2026_10_30.md:13

Text:
```text
Replacement, from Rey's filed draft (its second Chorus loss-reveal line, unused in the assembly): The Chorus [Rey]: "Growth remembers what the battle tried to hide, though the memory is young and could be wrong: [WEAKNESS]." Player-keyed, pronoun-clean, uncertainty register intact, checked against all seven weakness names on the same basis as the rest of the pool.
```

Rule broken: Replacement fixes enemy keying but retains abstract third-person prose instead of collective sensory Chorus voice (bible 5.2).

Corrected line:
```text
Replacement, The Chorus [Rey]: "We grew around the wound. We think we know the soft place: [WEAKNESS]."
```

## tutorial_assembled_2026_10_29.md (14)

### 106. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:7

Text:
```text
['c_map', 'Sector map', 'You move on the sector map by choosing a path. You cannot visit every node; you can move only to connected nodes.'],
```

Rule broken: Plain reading: node is unexplained map jargon.

Corrected line:
```text
['c_map', 'Sector map', 'Choose a connected location on the map to move forward. You cannot visit every location.'],
```

### 107. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:8

Text:
```text
['c_nodes', 'Node types', 'The map shows node kinds at a glance: battles, elites, the boss, events, rest, and shipyards. Pick the route that gives what your fleet needs.'],
```

Rule broken: Plain reading: node kinds and elites need everyday descriptions.

Corrected line:
```text
['c_nodes', 'Map locations', 'The map marks ordinary fights, tougher elite fleets, the sector boss, events, rest stops, and shipyards. Choose what your fleet needs.'],
```

### 108. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:9

Text:
```text
['c_elite', 'Elite fights', 'Elites are harder fights with better rewards. The sector guarantees one elite on your path.'],
```

Rule broken: core.js:291-292 places an elite on a reachable route, not necessarily the chosen path; the assembly exclusion note recognizes this.

Corrected line:
```text
['c_elite', 'Elite fights', 'Elite fleets are tougher enemies with better rewards. Each sector offers an elite fight on a route you can choose.'],
```

### 109. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:10

Text:
```text
['c_clock', 'Nemesis clock', 'The Nemesis clock fills when you win and when you make loud choices. When it fills, the Nemesis comes to you; the meeting is not optional.'],
```

Rule broken: Plain reading: explain Nemesis and loud choices. A full clock changes the next eligible fight, not an instant battle (campaign_run.js:277-281).

Corrected line:
```text
['c_clock', 'Your rival hunt', 'The Nemesis is the enemy commander hunting your fleet. Wins and some event choices fill the hunt meter. When it fills, your next eligible fight is against that commander.'],
```

### 110. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:13

Text:
```text
['c_salvage', 'Strip wrecks', 'At a salvage step, pick one wreck: take a refit, credits, or a tow at 35% hull.'],
```

Rule broken: campaign_run.js:439-445: towing is Hullbreaker-only, eligible small intact hulls and enough command points, not a universal choice. Rename map 5c reserves salvage for the item type; the wreck step is Strip, not a salvage step.

Corrected line:
```text
['c_salvage', 'Strip wrecks', 'After a fight, work one wreck for a refit or credits if offered. Hullbreakers may also tow an eligible small wreck into their fleet at 35% hull if they have room.'],
```

### 111. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:14

Text:
```text
['c_boon', 'Boon offers', "Boons are a patron's permanent in-run gifts. Rarity is strength. Declining pays credits, and you get one reroll per reward."],
```

Rule broken: Bible 1.5 and rename map section 2 retire boon/patron. Rerolls are paid and conditional (campaign_run.js:512-515).

Corrected line:
```text
['c_boon', 'Protocol offers', 'A core offers protocols: bonuses lasting until this run ends. Rarer ones are stronger. Decline for credits. If another offer is available and you can pay, replace the choices once; the price rises with each replacement this run.'],
```

### 112. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:15

Text:
```text
['c_relic', 'Salvage pieces', 'These are salvage pieces: build pieces that change how your fleet fights, won from elites and bosses. Your fleet can carry only one of each piece, so a choice here is about which build you are making.'], [Rey swap]
```

Rule broken: Plain reading: build pieces and build are unexplained gamer jargon. Internal c_relic id stays.

Corrected line:
```text
['c_relic', 'Salvage pieces', 'Elite fights and bosses can award salvage that changes how your fleet fights. Carry only one of each piece. Choose pieces that support your ships and weapons.'],
```

### 113. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:16

Text:
```text
['c_shipyard', 'The shipyard', 'Buying a ship costs credits and command points, and your fleet is limited by command points. Repairs are priced per ship and restore that ship in full, and a repair always costs less than replacing the ship. Refits you own are fitted here from your hold.'], [Rey swap]
```

Rule broken: Command points are capacity, not a second currency paid. Explain refit and hold.

Corrected line:
```text
['c_shipyard', 'The shipyard', 'Buy ships with credits if they fit within your fleet command-point limit. Pay to repair each ship in full for less than its replacement price. Fit equipment upgrades you have stored here.'],
```

### 114. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:17

Text:
```text
['c_regroup', 'Regroup choice', 'After a boss, the regroup is a choice under scarcity. You can repair, upgrade, or buy; credits spent on one are not spent on the others.'],
```

Rule broken: Plain reading: regroup under scarcity is unnecessary jargon.

Corrected line:
```text
['c_regroup', 'After the boss', 'After a sector boss, repair, upgrade, or buy ships at a shipyard. All three use the same credits.'],
```

### 115. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:18

Text:
```text
['c_heat', 'Admiral Heat', "Heat is experience for the admiral you flew. It levels them and feeds the faction's shadow pool."],
```

Rule broken: Heat is difficulty, not experience itself (data.js HEAT; campaign_meta.js:96-97). R62 adds +2 XP per Heat to flown admiral and +1 faction pool; explain shadow pool.

Corrected line:
```text
['c_heat', 'Heat and experience', 'Heat adds optional rules that make runs harder. Under the approved progression design, each Heat point gives 2 experience to the admiral you flew and 1 to the faction pool used to train other admirals.'],
```

### 116. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:19

Text:
```text
['c_tree', 'Skill trees', 'You get one skill-tree pick per tree level. Picks change decisions, not just numbers. Respec is between runs, for renown.'],
```

Rule broken: Plain reading: respec and tree level are unexplained. These are approved unbuilt features, not current-code bugs.

Corrected line:
```text
['c_tree', 'Admiral skills', 'Each admiral level that grants a skill lets you choose one new ability. Between runs, spend renown to reset those choices and choose again.'],
```

### 117. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:20

Text:
```text
['c_renown', 'Renown currency', 'Renown is the between-runs currency for unlocks and respecs. You earn it across runs, not within one.'],
```

Rule broken: Plain reading: respec is unexplained; not within one may imply battles do not earn renown. Run results are tallied at the end (campaign_meta.js:198-200).

Corrected line:
```text
['c_renown', 'Renown', 'Your run results earn renown, paid when the run ends. Between runs, spend it to unlock options or reset skill choices.'],
```

### 118. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:21

Text:
```text
['c_verb', 'Faction verb', "You use your faction's campaign verb once per sector, from the map. Some are free after the right event."],
```

Rule broken: Faction verb is developer terminology, not an instruction.

Corrected line:
```text
['c_verb', 'Faction map action', 'Each faction has a special action on the map, usable once per sector. Some events let you use it without paying its usual cost.'],
```

### 119. contrib/muse/reviews/tutorial_assembled_2026_10_29.md:22

Text:
```text
['c_loss', 'Run lost', 'Losing the fleet ends the run, not the war. You carry over renown, favour, and what your faction learned; you do not carry over ships, credits, or boons.'],
```

Rule broken: Retired favour/boon labels (bible 1.5; rename map section 2).

Corrected line:
```text
['c_loss', 'Run lost', 'Losing your fleet ends the run. Keep renown, core sync, and faction learning. Ships, credits, and protocols do not carry into the next run.'],
```

## story_pack_2026_10_30.md (60)

### 120. contrib/muse/reviews/story_pack_2026_10_30.md:1

Text:
```text
# Voidsworn story implementation pack (Oct 30, 2026)
```

Rule broken: Retired display title (rename map section 1); project filenames remain unchanged.

Corrected line:
```text
# Embers of the Hollow Sun story implementation pack (Oct 30, 2026)
```

### 121. contrib/muse/reviews/story_pack_2026_10_30.md:5

Text:
```text
How an arc works (unchanged skeleton, new content): one charge line at run start; three beats, one per sector, each attached to an event node in the data.js EVENTS shape; a finale that resolves on the sector 3 Nemesis fight with a faction-specific mechanic; a win ending and a loss ending. Each beat carries: scene purpose, the node, paste-ready text lines, a debrief line, and the faction learning payoff line. Nemesis material uses the shipped token system ({rival}, {He}, {his}) so pronouns follow the generated commander; no fixed pronouns appear in Part 1. Admiral spotlights are one short scene per admiral, keyed to fire when that admiral commands the fleet.
```

Rule broken: The claimed data.js EVENTS shape is not paste-ready: shipped eventScreen reads event b and option l/s, not t/tx (campaign_run.js:233-237). Options also lack stable k ids for branch flags (242). All 18 event blocks need an adapter, including story-result display; correcting rewards alone is insufficient.

Corrected line:
```text
How an arc works: these event blocks are content proposals, not paste-ready data.js EVENTS objects. Before merging, supply each event body b, stable option key k, label l and effect summary s, and implement result narration for tx plus the new arc effects.
```

### 122. contrib/muse/reviews/story_pack_2026_10_30.md:28

Text:
```text
 {t:'Read the last crusade first', r:{clock:1}, tx:'The Roll-master reads the names that never came home, and what each one bought with their hull. The lesson is worth the hour it costs. {rival} moves while you listen.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Read the last crusade first', r:{nemClock:1}, tx:'The Roll-master reads the names that never came home, and what each one bought with their hull. The lesson is worth the hour it costs. {rival} moves while you listen.'}
```

### 123. contrib/muse/reviews/story_pack_2026_10_30.md:50

Text:
```text
 {t:'Take their young and their harvest', r:{credits:60}, tx:'One in ten of their young report to your decks, and the harvest share follows. Their star is dimmer than last year. Everyone can see it. Nobody says it is enough, and nobody says it is not.'},
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Take their young and their harvest', r:{cred:60}, tx:'One in ten of their young report to your decks, and the harvest share follows. Their star is dimmer than last year. Everyone can see it. Nobody says it is enough, and nobody says it is not.'},
```

### 124. contrib/muse/reviews/story_pack_2026_10_30.md:71

Text:
```text
 {t:'Burn deep: take Seren fire into the flagship', r:{dmgFlag:.25, power:1}, tx:'Seren fire runs in the flagship guns for one battle and eats a quarter of its hull to do it. The crews chalk nothing. There is no room left on the hull near the guns.'},
```

Rule broken: Unimplemented outcome keys dmgFlag, power. These are proposed arc mechanics, not existing reward facts (data.js EVENTS; campaign_run.js:applyOutcome). Exact amounts/durations need design, not guessed replacements.

Corrected line:
```text
 {t:'Burn deep: take Seren fire into the flagship', r:{dmgFlag:.25, power:1}, tx:'Seren fire runs in the flagship guns for one battle and eats a quarter of its hull to do it. The crews chalk nothing. There is no room left on the hull near the guns.'}, // PROPOSAL ONLY: define and implement dmgFlag, power before treating this as paste-ready.
```

### 125. contrib/muse/reviews/story_pack_2026_10_30.md:72

Text:
```text
 {t:'Burn clean: refuse the deep burn', r:{repair:.15}, tx:'You refuse. The yards along the Cinder Line patch what they can, and the fleet goes in whole and ordinary. The Roll-master approves. The gunners do not.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Burn clean: refuse the deep burn', r:{healAll:.15}, tx:'You refuse. The yards along the Cinder Line patch what they can, and the fleet goes in whole and ordinary. The Roll-master approves. The gunners do not.'}
```

### 126. contrib/muse/reviews/story_pack_2026_10_30.md:86

Text:
```text
Mechanic: in the sector 3 Nemesis fight, the Nemesis flagship challenges the player flagship (Crusade Nemesis never flees, r8 section 2.7). If the player flagship destroys the Nemesis flagship, the finale pays a flagship refit and the Nemesis name is chalked under the line on the hull, permanently, in the campaign record. If the Nemesis flagship survives the fight, the arc closes unpaid even on a battle win.
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Mechanic proposal: player flagship may challenge the Nemesis flagship in sector 3, whatever the enemy faction. A flagship kill earns the proposed refit and chalked record. Only a Crusade Nemesis is guaranteed never to flee (data.js:479).
```

### 127. contrib/muse/reviews/story_pack_2026_10_30.md:88

Text:
```text
Nemesis introduction (first meeting, sector 1): "{rival} holds the jump route ahead, in a hull blacker than yours. The hail is short. 'Reach fleet. Your names are not on my hull yet. They will be.'"
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Nemesis introduction: "{rival} holds the jump route ahead. The hail names your flagship. The Roll-master chalks the challenge beside the names already owed."
```

### 128. contrib/muse/reviews/story_pack_2026_10_30.md:90

Text:
```text
Rivalry beat (sector 2 rematch): "'You chalk names because your Registry deleted them. I read your hull at range, Reach captain. I am learning your dead faster than you are.'"
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Rivalry beat: "The Roll-master reads the last meeting aloud. Across the plot, {rival} takes position again. Your captains keep their chalk ready."
```

### 129. contrib/muse/reviews/story_pack_2026_10_30.md:98

Text:
```text
Ending, run won: "The siphon array burns out against the dark, and for one watch the route ahead is lit by its dying. The Roll gains no new names this generation. The Roll-master chalks a single line under the last crusade instead: PAID. Behind you, very far behind you, a dim star holds its light."
```

Rule broken: A run win need not be casualty-free; keep every lost name (bible 2.2).

Corrected line:
```text
Ending, run won: "The siphon array burns out against the dark, and for one watch the route ahead is lit by its dying. The Roll keeps every name lost along the route. The Roll-master chalks a single line under the last crusade instead: PAID. Behind you, very far behind you, a dim star holds its light."
```

### 130. contrib/muse/reviews/story_pack_2026_10_30.md:116

Text:
```text
 {t:'Log the post as lost, all hands', r:{credits:50}, tx:'The Registry credits the fleet for efficiency. Fourteen names move from the projections to the loss ledger. Your flag captain keeps a second list, on paper, and does not explain it.'},
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Log the post as lost, all hands', r:{cred:50}, tx:'The Registry credits the fleet for efficiency. Fourteen names move from the projections to the loss ledger. Your flag captain keeps a second list, on paper, and does not explain it.'},
```

### 131. contrib/muse/reviews/story_pack_2026_10_30.md:117

Text:
```text
 {t:'Recover the post crew', r:{clock:1}, tx:'Fourteen crew come aboard alive and unbudgeted. The Registry notes the variance. {rival} uses the hour you spent. Your flag captain adds no names to the paper list today.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Recover the post crew', r:{nemClock:1}, tx:'Fourteen crew come aboard alive and unbudgeted. The Registry notes the variance. {rival} uses the hour you spent. Your flag captain adds no names to the paper list today.'}
```

### 132. contrib/muse/reviews/story_pack_2026_10_30.md:138

Text:
```text
 {t:'File the exception: hold position and repair', r:{repair:.2, clock:1}, tx:'The exception is approved in eleven minutes, which the flag captain calls a record and the Registry calls a rounding error. {rival} is not rounded. {rival} advances.'},
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'File the exception: hold position and repair', r:{healAll:.2, nemClock:1}, tx:'The exception is approved in eleven minutes, which the flag captain calls a record and the Registry calls a rounding error. {rival} is not rounded. {rival} advances.'},
```

### 133. contrib/muse/reviews/story_pack_2026_10_30.md:159

Text:
```text
 {t:'Switch the links off. Speak for one minute', r:{xp:25, syncDown:1}, tx:'One minute of silence on the link, the first in the fleet record. The formation bonus will not answer at the first volley. What you say in the minute is not logged, not projected, and not repeatable. Every captain repeats it anyway.'},
```

Rule broken: Unimplemented outcome keys syncDown. These are proposed arc mechanics, not existing reward facts (data.js EVENTS; campaign_run.js:applyOutcome). Exact amounts/durations need design, not guessed replacements.

Corrected line:
```text
 {t:'Switch the links off. Speak for one minute', r:{xp:25, syncDown:1}, tx:'One minute of silence on the link, the first in the fleet record. The formation bonus will not answer at the first volley. What you say in the minute is not logged, not projected, and not repeatable. Every captain repeats it anyway.'}, // PROPOSAL ONLY: define and implement syncDown before treating this as paste-ready.
```

### 134. contrib/muse/reviews/story_pack_2026_10_30.md:160

Text:
```text
 {t:'Stay linked. Fight the projection', r:{credits:40}, tx:'The links stay lit. The Registry pays a compliance credit and the formation holds its shape. The flag captain folds the paper list smaller and says nothing at all.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Stay linked. Fight the projection', r:{cred:40}, tx:'The links stay lit. The Registry pays a compliance credit and the formation holds its shape. The flag captain folds the paper list smaller and says nothing at all.'}
```

### 135. contrib/muse/reviews/story_pack_2026_10_30.md:174

Text:
```text
Mechanic: the Nemesis receives reinforcements in round 3 as the Registry reallocates (r8 section 3.5), and each meeting the formation tightens. The arc reward is a Registry protocol offer at the finale: win the sector 3 fight and Vyre offers one protocol free of the sync requirement; lose and the offer is registered to the Nemesis instead.
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Mechanic proposal: give the player Registry support and a Vyre offer in the finale; define both before implementation. Enemy round 3 reinforcements occur for a Hegemony Nemesis (data.js:476), not every opponent.
```

### 136. contrib/muse/reviews/story_pack_2026_10_30.md:176

Text:
```text
Nemesis introduction: "The opposing commander is already in your projections, flagged red, annotated by a Registry hand that is not yours: 'Counterpart. Expect courtesy. Expect arithmetic.' The hail arrives on time. 'Admiral. Your losses are projected acceptable. I intend to keep them exactly there.'"
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Nemesis introduction: "The opposing commander is marked red on your plot. The Registry labels {rival}: Counterpart. Your flag captain adds: Expect resistance."
```

### 137. contrib/muse/reviews/story_pack_2026_10_30.md:178

Text:
```text
Rivalry beat: "'Your exception at the post has been filed, Admiral. The Registry calls it a variance. I call it the first honest entry in your record.'"
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Rivalry beat: "The flag captain updates the enemy file with the last meeting. Your exception remains in the appendix. {rival} is already moving."
```

### 138. contrib/muse/reviews/story_pack_2026_10_30.md:186

Text:
```text
Ending, run won: "The approaches are secured and registered. The Registry closes Order 41 with a commendation and an amended projection: this fleet, loss band revised, footnote expanded. The flag captain files the paper list in the ship archive, complete, with no names added in sector 3. It is the shortest victory report the Registry has ever accepted: 'Acceptable' now means something else in it."
```

Rule broken: Victory can include sector 3 casualties; an unconditional empty list erases them.

Corrected line:
```text
Ending, run won: "The approaches are secured and registered. The Registry closes Order 41 with a commendation and an amended projection: this fleet, loss band revised, footnote expanded. The flag captain files the paper list in the ship archive, complete, with every sector 3 loss recorded. It is the shortest victory report the Registry has ever accepted: 'Acceptable' now means something else in it."
```

### 139. contrib/muse/reviews/story_pack_2026_10_30.md:204

Text:
```text
 {t:'Run loud: let them hear the pack coming', r:{xp:15, clock:1}, tx:'Engines up, dishes out. Every hull in the sector hears the pack on the trail, including {rival}. Fear is a weapon that costs fuel. The young ones bare their teeth at the dark.'},
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Run loud: let them hear the pack coming', r:{xp:15, nemClock:1}, tx:'Engines up, dishes out. Every hull in the sector hears the pack on the trail, including {rival}. Fear is a weapon that costs fuel. The young ones bare their teeth at the dark.'},
```

### 140. contrib/muse/reviews/story_pack_2026_10_30.md:205

Text:
```text
 {t:'Run dark: follow the wake-trails in silence', r:{credits:40}, tx:'The pack runs silent and strips two wrecks on the trail without a shot. Scrap is credits to everyone else. To the pack it is armour that has already survived one fight.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Run dark: follow the wake-trails in silence', r:{cred:40}, tx:'The pack runs silent and strips two wrecks on the trail without a shot. Scrap is credits to everyone else. To the pack it is armour that has already survived one fight.'}
```

### 141. contrib/muse/reviews/story_pack_2026_10_30.md:224

Text:
```text
 {t:'Let the challenge stand', r:{dmgShip:.1, xp:20}, tx:'They fight in the hangar bay, claws only, while the pack watches in silence. The winner keeps the ship. The loser keeps a scar and a station. The whole fleet fights harder for having seen the law kept.'},
```

Rule broken: Bible 4.1: whoever lives keeps the ship. Guaranteed surviving loser contradicts lethal challenge. Fleet damage boost is not in reward. Unimplemented outcome keys dmgShip. These are proposed arc mechanics, not existing reward facts (data.js EVENTS; campaign_run.js:applyOutcome). Exact amounts/durations need design, not guessed replacements.

Corrected line:
```text
 {t:'Let the challenge stand', r:{dmgShip:.1, xp:20}, tx:'They fight in the hangar bay, claws only, while the pack watches in silence. The winner keeps the ship. The loser does not leave the bay. The pack watches the law kept.'}, // PROPOSAL ONLY: define and implement dmgShip before treating this as paste-ready.
```

### 142. contrib/muse/reviews/story_pack_2026_10_30.md:225

Text:
```text
 {t:'Refuse it: the hunt comes first', r:{repair:.15}, tx:'No challenge flies during a hunt. The Ripper backs down, jaw tight, and the crews use the quiet to weld and patch. Something in the pack goes unwatched after that. Something always does.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Refuse it: the hunt comes first', r:{healAll:.15}, tx:'No challenge flies during a hunt. The Ripper backs down, jaw tight, and the crews use the quiet to weld and patch. Something in the pack goes unwatched after that. Something always does.'}
```

### 143. contrib/muse/reviews/story_pack_2026_10_30.md:244

Text:
```text
 {t:'Hunt the core: board for Rook', r:{dmgFlag:.15, core:1}, tx:'Boarding claws only, no broadsides into the prize hold. The flagship takes the hits that the hold cannot. If the pack wins this, Rook comes home in chains of welded plate.'},
```

Rule broken: Unimplemented outcome keys dmgFlag, core. These are proposed arc mechanics, not existing reward facts (data.js EVENTS; campaign_run.js:applyOutcome). Exact amounts/durations need design, not guessed replacements.

Corrected line:
```text
 {t:'Hunt the core: board for Rook', r:{dmgFlag:.15, core:1}, tx:'Boarding claws only, no broadsides into the prize hold. The flagship takes the hits that the hold cannot. If the pack wins this, Rook comes home in chains of welded plate.'}, // PROPOSAL ONLY: define and implement dmgFlag, core before treating this as paste-ready.
```

### 144. contrib/muse/reviews/story_pack_2026_10_30.md:245

Text:
```text
 {t:'Hunt the kill: sink it all', r:{xp:25}, tx:'No holding back for cargo. The pack fights clean and total, and Rook goes down with the flagship if it goes. Kills are trophies too. The biggest ones sink.'}
```

Rule broken: Bible 1.4.2: sink/go down is naval framing. Losing a ship-sized core also needs a story branch.

Corrected line:
```text
 {t:'Hunt the kill: destroy the flagship', r:{xp:25}, tx:'No holding back for cargo. The pack fights clean and total, and Rook is lost in the wreckage if the flagship breaks. Kills are trophies too. The biggest leave wrecks.'}
```

### 145. contrib/muse/reviews/story_pack_2026_10_30.md:258

Text:
```text
Mechanic: the Nemesis raids the player's credits during the sector 3 fight (a cut per round the flagship survives) and flees a losing fight; a ship the Nemesis steals during the run returns to the player when the Nemesis dies (r8 section 4.5). Killing the Nemesis flagship before it flees pays the stolen credits back double and ends the raid permanently for the run.
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Mechanic: a Hullbreaker Nemesis steals on the map when the clock fills, not per battle round (data.js:464; campaign_run.js:282-287). Stolen property returns on its death, without doubling. Other enemy factions use their own behavior. Universal raiding or doubled repayment is a separate proposal.
```

### 146. contrib/muse/reviews/story_pack_2026_10_30.md:260

Text:
```text
Nemesis introduction: "Wake-trackers pick up a fleet running dark off the trail. Then the comms open and the growl under the words is not for show. 'Little pack. You hunt in my dark. Show me your teeth, or show me your wake.'"
```

Rule broken: Enemy voice is hardcoded as player faction, but Nemesis faction varies independently (data.js:461-479; campaign_run.js:249,258 (newNemesis/ensureNemesis)).

Corrected line:
```text
Nemesis introduction: "Wake-trackers find {rival} ahead. The pack closes in silence. Let the enemy speak first. We have the trail."
```

### 147. contrib/muse/reviews/story_pack_2026_10_30.md:262

Text:
```text
Rivalry beat: "'We stripped your dead after the last fight. Good scrap. Strong bones in the hull. Come and earn them back.'"
```

Rule broken: Enemy voice is hardcoded as player faction, but Nemesis faction varies independently (data.js:461-479; campaign_run.js:249,258 (newNemesis/ensureNemesis)).

Corrected line:
```text
Rivalry beat: "The pack checks the plates taken after the last fight. Same enemy. Another chance to take the rest."
```

### 148. contrib/muse/reviews/story_pack_2026_10_30.md:265

Text:
```text
- Warlord Grax Steelgrin: "Grax takes the flagship in teeth-first and laughs over open comms while the claws bite. The pack howls back. It is not joy. It is agreement."
```

Rule broken: R61 and bible 4.9: Grax Ironmaw replaces Steelgrin; data.js:221 already agrees.

Corrected line:
```text
- Warlord Grax Ironmaw: "Grax takes the flagship in teeth-first and laughs over open comms while the claws bite. The pack howls back. It is not joy. It is agreement."
```

### 149. contrib/muse/reviews/story_pack_2026_10_30.md:270

Text:
```text
Ending, run won: "The pack takes the Hollow Sun ground the way it takes everything: teeth first, then trophies. Rook rides home welded over the flagship bow, and every den on the trail hears the howl that says who holds it now. Challengers are already coming out of the dark. That is not a threat to the pack. That is the point."
```

Rule broken: Unconditional Rook return ignores hunt-the-kill choice (245). Rook is ship-sized (bible 1.5), not a bow ornament.

Corrected line:
```text
Ending, run won: "The pack takes the Hollow Sun ground the way it takes everything: teeth first, then trophies. If the pack recovered Rook, the ship-sized core follows in a heavy tow cradle, and every den on the trail hears the howl that says who holds it now. Challengers are already coming out of the dark. That is not a threat to the pack. That is the point."
```

### 150. contrib/muse/reviews/story_pack_2026_10_30.md:272

Text:
```text
Ending, run lost: "The pack breaks in the dark between the wrecks, and the strongest swim for the trail home with the trophies they can carry. In the dens, the story is told flat and short, the way true stories are told: who held, who ran, what the killing thing looked like. The next litter grows up on that story. It grows up hungry to correct it."
```

Rule broken: Bible 1.4.2: swimming survivors carrying trophies reads as sea escape, not space travel.

Corrected line:
```text
Ending, run lost: "The pack breaks in the dark between the wrecks, and the survivors follow the trail home in escape craft with the trophies they saved. In the dens, the story is told flat and short, the way true stories are told: who held, who ran, what the killing thing looked like. The next litter grows up on that story. It grows up hungry to correct it."
```

### 151. contrib/muse/reviews/story_pack_2026_10_30.md:288

Text:
```text
 {t:'Let Hunger choose the route', r:{xp:15, clock:1}, tx:'We go by the warm lanes, where the prey is fat. Hunger is pleased. Memory is quiet, which is never good. {rival} fattens on the same lanes.'},
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Let Hunger choose the route', r:{xp:15, nemClock:1}, tx:'We go by the warm lanes, where the prey is fat. Hunger is pleased. Memory is quiet, which is never good. {rival} fattens on the same lanes.'},
```

### 152. contrib/muse/reviews/story_pack_2026_10_30.md:289

Text:
```text
 {t:'Let Memory choose the route', r:{repair:.1}, tx:'We go by the cold lanes Memory remembers from the makers. Slow. Empty. The flesh knits while we swim. Memory stirs under the skin, in a dead voice, almost content.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Let Memory choose the route', r:{healAll:.1}, tx:'We go by the cold lanes Memory remembers from the makers. Slow. Empty. The flesh knits while we swim. Memory stirs under the skin, in a dead voice, almost content.'}
```

### 153. contrib/muse/reviews/story_pack_2026_10_30.md:309

Text:
```text
 {t:'Eat the vat', r:{repair:.3}, tx:'We eat what grew us. The flesh comes back thick and fast. Memory goes very quiet. Hunger grows loud enough to fill every throat, and some of the young are born wrong-shaped with wanting.'},
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Eat the vat', r:{healAll:.3}, tx:'We eat what grew us. The flesh comes back thick and fast. Memory goes very quiet. Hunger grows loud enough to fill every throat, and some of the young are born wrong-shaped with wanting.'},
```

### 154. contrib/muse/reviews/story_pack_2026_10_30.md:330

Text:
```text
 {t:'Let Memory speak to the core', r:{core:1, dmgPctDown:1}, tx:'Memory speaks to Crucible in the makers voices, and the core answers an old name. Protocols come like remembered food. But Hunger hesitates at the kill now, listening for a voice under the hunger. It will hesitate in the fight.'},
```

Rule broken: Unimplemented outcome keys core, dmgPctDown. These are proposed arc mechanics, not existing reward facts (data.js EVENTS; campaign_run.js:applyOutcome). Exact amounts/durations need design, not guessed replacements.

Corrected line:
```text
 {t:'Let Memory speak to the core', r:{core:1, dmgPctDown:1}, tx:'Memory speaks to Crucible in the makers voices, and the core answers an old name. Protocols come like remembered food. But Hunger hesitates at the kill now, listening for a voice under the hunger. It will hesitate in the fight.'}, // PROPOSAL ONLY: define and implement core, dmgPctDown before treating this as paste-ready.
```

### 155. contrib/muse/reviews/story_pack_2026_10_30.md:331

Text:
```text
 {t:'Close the second throat', r:{dmgPctUp:1}, tx:'We close Memory for the fight. The swarm is one throat, one want, nothing wasted. We are faster and emptier. Something that knew our name is quiet, and the quiet is also a kind of food.'}
```

Rule broken: Unimplemented outcome keys dmgPctUp. These are proposed arc mechanics, not existing reward facts (data.js EVENTS; campaign_run.js:applyOutcome). Exact amounts/durations need design, not guessed replacements.

Corrected line:
```text
 {t:'Close the second throat', r:{dmgPctUp:1}, tx:'We close Memory for the fight. The swarm is one throat, one want, nothing wasted. We are faster and emptier. Something that knew our name is quiet, and the quiet is also a kind of food.'} // PROPOSAL ONLY: define and implement dmgPctUp before treating this as paste-ready.
```

### 156. contrib/muse/reviews/story_pack_2026_10_30.md:345

Text:
```text
Mechanic: in the sector 3 fight, the swarm regrows hull each round scaled by the number of player ships lost earlier in the run (the Nemesis grows tougher from your losses all run, r8 section 5.5; in the finale the swarm turns the same law inward). Winning feeds the swarm a core: run reward is a Crucible protocol offer. Losing still grows the next brood: the loss ending pays the learning line in full.
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Mechanic proposal: grant the player Chorus a finale regrowth bonus; define its amount and trigger. Existing loss-fed toughness belongs only to a Chorus Nemesis (data.js:473). Proposed reward: a Crucible protocol, not physical consumption of the core.
```

### 157. contrib/muse/reviews/story_pack_2026_10_30.md:347

Text:
```text
Nemesis introduction: "It comes out of the dark between stars with no lights and no hail. Memory knows it first. 'That one. We were grown for that one. Everything else was practice.'"
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Nemesis introduction: "Memory stirs as {rival} appears. Another fleet between us and the cores. Hunger does not care whose. Warm enough. Eat."
```

### 158. contrib/muse/reviews/story_pack_2026_10_30.md:375

Text:
```text
 {t:'Take the gatherers escort', r:{clock:1}, tx:'Slow uncrewed gatherer hulls fall in behind the fleet, patient as tide. They will recover whatever this fleet becomes. {rival} gains an hour while you match their pace. You would not leave them anyway.'},
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Take the gatherers escort', r:{nemClock:1}, tx:'Slow uncrewed gatherer hulls fall in behind the fleet, patient as tide. They will recover whatever this fleet becomes. {rival} gains an hour while you match their pace. You would not leave them anyway.'},
```

### 159. contrib/muse/reviews/story_pack_2026_10_30.md:396

Text:
```text
 {t:'Loosen the cage for the hunt', r:{power:1, syncDown:1}, tx:'Astra burns brighter in its cage and the fleet fights above its weight for one sector. The Lens-keeper logs the loosening in full, in a hand that does not shake. Astra notices being noticed.'},
```

Rule broken: Unimplemented outcome keys power, syncDown. These are proposed arc mechanics, not existing reward facts (data.js EVENTS; campaign_run.js:applyOutcome). Exact amounts/durations need design, not guessed replacements.

Corrected line:
```text
 {t:'Loosen the cage for the hunt', r:{power:1, syncDown:1}, tx:'Astra burns brighter in its cage and the fleet fights above its weight for one sector. The Lens-keeper logs the loosening in full, in a hand that does not shake. Astra notices being noticed.'}, // PROPOSAL ONLY: define and implement power, syncDown before treating this as paste-ready.
```

### 160. contrib/muse/reviews/story_pack_2026_10_30.md:397

Text:
```text
 {t:'Keep the cage at full throttle-down', r:{repair:.15}, tx:'The fleet fights at its honest weight and uses the quiet to anneal and mend. Astra dims to almost nothing behind its bars of light. Almost. It is counting. It has always been counting.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Keep the cage at full throttle-down', r:{healAll:.15}, tx:'The fleet fights at its honest weight and uses the quiet to anneal and mend. Astra dims to almost nothing behind its bars of light. Almost. It is counting. It has always been counting.'}
```

### 161. contrib/muse/reviews/story_pack_2026_10_30.md:416

Text:
```text
 {t:'Fly the corrected approach', r:{weak:1, clock:1}, tx:'The fleet re-forms on the corrected line the dead fleet paid for. It is slower and it is seen coming. {rival} watches you take the long way around a grave only you can see.'},
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Fly the corrected approach', r:{nemIntel:1, nemClock:1}, tx:'The fleet re-forms on the corrected line the dead fleet paid for. It is slower and it is seen coming. {rival} watches you take the long way around a grave only you can see.'},
```

### 162. contrib/muse/reviews/story_pack_2026_10_30.md:433

Text:
```text
Nemesis introduction: "The opposing fleet resolves out of the glare, flying the old Lattice geometry the way a hand remembers a tool. The hail is quiet and exact. 'Siblings of the forge. You caged our sister to come and kill us. We expected better optics from you.'"
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Nemesis introduction: "The opposing fleet resolves out of the glare. The Lens-keeper sends translated colour pulses: We carry Astra to find the others. Stand aside, or forgive what follows."
```

### 163. contrib/muse/reviews/story_pack_2026_10_30.md:435

Text:
```text
Rivalry beat: "'We read your last battle in your own light, little fleet. Beautifully flown. The flaw is at the turn. It is always at the turn. We will be waiting at yours.'"
```

Rule broken: Enemy voice is hardcoded as player faction, but Nemesis faction varies independently (data.js:461-479; campaign_run.js:249,258 (newNemesis/ensureNemesis)).

Corrected line:
```text
Rivalry beat: "The Lens-keeper plays the last meeting in the glass. There, at the turn. We will not fly it twice."
```

### 164. contrib/muse/reviews/story_pack_2026_10_30.md:461

Text:
```text
 {t:'Restore from the newest backup', r:{xp:15}, tx:'The admiral wakes in a ninth body with the last hour missing, forever. The fleet pretends not to notice the gap. The admiral notices the pretending, and is, in the old word, grateful.'},
```

Rule broken: Ninth body is Aurex-specific; all four Eclipse admirals can lead the arc (bible 7.9; data.js:233-236).

Corrected line:
```text
 {t:'Restore from the newest backup', r:{xp:15}, tx:'The admiral wakes in a restored body with the last hour missing, forever. The fleet pretends not to notice the gap. The admiral notices the pretending, and is, in the old word, grateful.'},
```

### 165. contrib/muse/reviews/story_pack_2026_10_30.md:462

Text:
```text
 {t:'Wait for the older, fuller backup', r:{clock:1}, tx:'An older backup restores more of the admiral and less of the war. {rival} advances while the Archive deliberates. Permanence has a queue. The queue is a thousand years long and everyone in it is patient, which is not the same as content.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Wait for the older, fuller backup', r:{nemClock:1}, tx:'An older backup restores more of the admiral and less of the war. {rival} advances while the Archive deliberates. Permanence has a queue. The queue is a thousand years long and everyone in it is patient, which is not the same as content.'}
```

### 166. contrib/muse/reviews/story_pack_2026_10_30.md:466

Text:
```text
- Admiral: "This is my ninth body. The eighth is still warm in its cradle, in the sense that anything here is warm. I remember the launch. I do not remember the dying. That asymmetry was our design."
```

Rule broken: Hardcoded ninth/eighth iteration conflicts with selectable Third-Housed and Twice-Restored admirals (bible 7.9).

Corrected line:
```text
- Admiral: "This is another body. The last is still warm in its cradle, in the sense that anything here is warm. I remember the launch. I do not remember the dying. That asymmetry was our design."
```

### 167. contrib/muse/reviews/story_pack_2026_10_30.md:482

Text:
```text
 {t:'Run the array at full draw', r:{credits:60, clock:1}, tx:'Energy pours home through the jump relays and the star at the array dims by a fraction no instrument of theirs will miss. Somewhere under that light, a frontier world turns its lights on at noon. The fleet does not discuss it. The fleet never discusses it at full draw.'},
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Run the array at full draw', r:{cred:60, nemClock:1}, tx:'Energy pours home through the jump relays and the star at the array dims by a fraction no instrument of theirs will miss. Somewhere under that light, a frontier world turns its lights on at noon. The fleet does not discuss it. The fleet never discusses it at full draw.'},
```

### 168. contrib/muse/reviews/story_pack_2026_10_30.md:483

Text:
```text
 {t:'Throttle the array', r:{repair:.2}, tx:'The array idles and the stolen light slows to a thread. The fleet uses the quiet to rebuild plate and restore hulls. In the Archive, an old mind files a note it has filed four hundred times: we know what it costs. We do it anyway, but slower is also a choice.'}
```

Rule broken: R61: Eclipse siphons stellar energy, not literal light. Filing voice belongs to Hegemony (bible 1.3). Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts.

Corrected line:
```text
 {t:'Throttle the array', r:{healAll:.2}, tx:'The array idles and the stolen energy flow slows to a trickle. The fleet uses the quiet to rebuild plate and restore hulls. In the Archive, an old mind records a thought it has recorded four hundred times: we know what it costs. We do it anyway, but slower is also a choice.'}
```

### 169. contrib/muse/reviews/story_pack_2026_10_30.md:490

Text:
```text
Debrief: "The siphon light runs along the relay line toward home, thin and steady, like something being carried a long way by hand."
```

Rule broken: R61: relays carry stellar energy, not literal light.

Corrected line:
```text
Debrief: "The harvested energy flows along the relay line toward home, in a steady stream, like something being carried a long way by hand."
```

### 170. contrib/muse/reviews/story_pack_2026_10_30.md:492

Text:
```text
Learning payoff: "The Archive receives this fleet's corrections nightly, across the dark, at the speed of light. Eclipse learns slowly and loses nothing. That is the bargain. That has always been the bargain."
```

Rule broken: Bible 1.1: 10-30 light-year sectors and jumps in days cannot support nightly home updates at light speed. Exact Eclipse communication is unspecified.

Corrected line:
```text
Learning payoff: "The Archive keeps this fleet's corrections when its battle records reach home. Eclipse learns slowly and loses nothing. That is the bargain. That has always been the bargain."
```

### 171. contrib/muse/reviews/story_pack_2026_10_30.md:503

Text:
```text
 {t:'Spend the window on the fleet', r:{repair:.25}, tx:'Every hull gets its restoration pass and the admiral goes into the fight with an old backup and a quiet expression. 'If I come back missing the last year,' the admiral says, 'tell me we won it. Tell me slowly.'}
```

Rule broken: Paste-ready outcome uses unsupported keys. Shipped data.js EVENTS and campaign_run.js:359-403 applyOutcome use cred, healAll, nemClock and nemIntel. Unknown keys do nothing; preserve amounts. Single-quoted tx contains unescaped single-quoted dialogue and will not parse as JavaScript.

Corrected line:
```text
 {t:'Spend the window on the fleet', r:{healAll:.25}, tx:'Every hull gets its restoration pass and the admiral goes into the fight with an old backup and a quiet expression. "If I come back missing the last year," the admiral says, "tell me we won it. Tell me slowly."}
```

### 172. contrib/muse/reviews/story_pack_2026_10_30.md:507

Text:
```text
- Admiral: "I have worn nine bodies and outlived my sun by a thousand years. Permanence is very long, Captain. Let us spend some of it correctly."
```

Rule broken: Hardcoded nine bodies conflicts with selectable Eclipse admiral titles (bible 7.9).

Corrected line:
```text
- Admiral: "I have worn other bodies and outlived my sun by a thousand years. Permanence is very long, Captain. Let us spend some of it correctly."
```

### 173. contrib/muse/reviews/story_pack_2026_10_30.md:511

Text:
```text
Learning payoff: "Win or dark, the Archive will know this fight in full. The next fleet out of the dark will fly with this one's lessons under its plates, and will not know the names of the minds that paid for them. It does not need the names. It has the corrections."
```

Rule broken: Guaranteed complete learning contradicts selective backup choice (502-503) and gaps in loss ending (529). Nameless corrections erase individual minds (bible 7.4).

Corrected line:
```text
Learning payoff: "Win or dark, the Archive will keep what reaches it. The next fleet out of the dark will fly with this one's lessons under its plates, and will keep the names of the minds that paid for them beside every surviving correction."
```

### 174. contrib/muse/reviews/story_pack_2026_10_30.md:515

Text:
```text
Mechanic: Eclipse laws, applied to the player: the first flagship lost in the sector 3 fight is restored once at half hull by repair swarms, its crew's minds re-streamed from backup (r8 section 7.5). The arc reward is an Archive protocol offer; the Nemesis, if Eclipse-factioned, also returns once, and the debrief names both restorations and their costs.
```

Rule broken: battle.js:480,518: normal Archive restore is 35% hull and excludes flagships, not 50% flagship revival. Nemesis return is a campaign rematch. Label new arc rules.

Corrected line:
```text
Mechanic proposal: add one sector 3 player-flagship restoration at 50% hull, separate from normal Archive restore (35% hull; flagships excluded, battle.js:480,518). An Eclipse Nemesis may return for a separate final fight under its campaign rule (data.js:467). Proposed arc reward: Archive protocol offer. Both additions need implementation.
```

### 175. contrib/muse/reviews/story_pack_2026_10_30.md:517

Text:
```text
Nemesis introduction: "The opposing fleet comes out of the eclipse shadow of a dead world, plate over trapped light, moving like something that has never once been in a hurry. The hail is a thousand years tired. 'Little fleet. You are flying toward a sunrise. We have buried one. Turn around, and we will remember you kindly, which is the only immortality on offer.'"
```

Rule broken: Enemy voice is hardcoded as player faction, but Nemesis faction varies independently (data.js:461-479; campaign_run.js:249,258 (newNemesis/ensureNemesis)).

Corrected line:
```text
Nemesis introduction: "The opposing fleet crosses the old battlefield. The Archive opens its record of {rival}. We have outlasted a sun. We can face one more fleet."
```

### 176. contrib/muse/reviews/story_pack_2026_10_30.md:519

Text:
```text
Rivalry beat: "'You destroyed this body at our last meeting. The Archive thanks you for the lesson. We have corrected the flaw you used. You will need a new one.'"
```

Rule broken: data.js:461-479; campaign_run.js:249,258,290 (newNemesis/ensureNemesis/nemBattleCfg): rival voice and behavior follow generated ENEMY faction, not the player arc. Use conditioned branches or player-side narration.

Corrected line:
```text
Rivalry beat: "The Archive opens the record of the last meeting with {rival}. The same threat. New damage patterns. We will not assume the old answer still works."
```

### 177. contrib/muse/reviews/story_pack_2026_10_30.md:545

Text:
```text
D5. Pronouns. The outlines and shipped Nemesis tables hardcode one pronoun set, the defect class behind the Oct 30 text overhaul's Nemesis pronoun batch. Part 1 uses the {rival} token system throughout and contains no fixed pronouns for the Nemesis and no pronouns for admirals; spotlight lines use names.
```

Rule broken: Contradicts 95 and 438: named admiral pronouns remain legitimately. Gender-safe Nemesis references are the relevant requirement.

Corrected line:
```text
D5. Pronouns. Nemesis references use generated-name tokens or neutral descriptions. Named admirals retain approved pronouns where used (Ashgrove and Tamsa).
```

### 178. contrib/muse/reviews/story_pack_2026_10_30.md:549

Text:
```text
D7. Admiral name forms. Spotlights use data.js display names. Two shipped forms conflict with r8 and are flagged, not silently changed, because data edits are Opus's call: the Hullbreaker admiral listed in data.js as Grax Steelgrin was ruled renamed to Grax Ironmaw in the Oct 27 rollout (still unapplied at the pin; the pack keeps the shipped display string in the spotlight header so the text matches the current build, and Opus should swap it when the data fix lands); the Eclipse admiral names in data.js carry forms r8 section 7.9 regularises (Nadir Aurex, Ninth Frame; Umbra Vessane, Third-Housed; Ostrel of the Long Copy; Seveth, Twice-Restored), which the pack uses.
```

Rule broken: R61 is already authoritative and data.js:221 uses Ironmaw; do not instruct implementation to preserve Steelgrin.

Corrected line:
```text
D7. Admiral names. Use approved names, including Grax Ironmaw and the iteration-based Eclipse names in bible 7.9. Retired names appear only as history, never spotlight headers.
```

### 179. contrib/muse/reviews/story_pack_2026_10_30.md:565

Text:
```text
- Naval metaphors (sea, sail, anchor, port, starboard, keel, mast, harbor, ashore): 0 hits.
```

Rule broken: Zero-hit claim uses an incomplete naval list: sink/swim framing remains at 245/272.

Corrected line:
```text
- Naval framing: revise Hullbreaker sink and swim wording at lines 245 and 272. The original narrow keyword list missed these cases.
```

## Exclusions and unresolved choices

- Nemesis assembly 48 (sniffed) and 51 (retreating mass) are withdrawn by the Oct 30 correction and are not open findings. The trophy-scar replacement is valid. The Growth remembers replacement still has the separate Chorus voice finding.
- No substring false positives: strike is not rite. Ordinary admiral rank Nadir is not the retired plain Nadir Nemesis title. R61 keeps the Hunger Below and Salvage swarm.
- No em dashes or never-say vocabulary violations were found in active player text apart from the retired reward/name forms listed. Retired terms quoted as audit history are excluded.
- Story power, syncDown, core and damage-modifier keys need actual definitions, handlers and durations. The report cannot infer those from names. The corrected lines preserve these as marked proposals, not functioning rewards.
- A deliberate new rival-faction policy could replace the offered player-side narration. Current newNemesis at campaign_run.js:249 normally selects a faction different from the player, making the mirror-match assumptions especially serious. No such policy change is authorized in these packs.
- It is unclear whether shared tier 2 pairs must share display names as well as mechanics. Neutral repair/protection wording is offered; separate faction titles are another possible design.
- Chorus pack naming is treated as a bible 1.3 ownership issue in titles. Existing Razormaw doctrine Hunter pack (data.js:226) is conflicting legacy precedent and should be reconciled by the owner, not silently treated as a new lore ruling.
- Verse can mean nonmusical poetry. It is flagged in this tree because the names occur throughout an explicitly singing/song-based Chorus design; a standalone unrelated use would need context.
- The source story pack cites later learning fiction for Glasswright gatherers and recasting. That fiction is accepted for this check, not independently rejected for differing from the shorter bible. Exact communications latency is still unspecified.
- Lore bible 7.5 describes broad rebuilding; current battle.js:518 excludes player flagships. The proposed 50% flagship revival must be explicitly treated as an additional rule rather than silently claiming baseline parity.

- The Chorus line We remember their faces / They had our faces (story 335) is ambiguous: it could be ancestral Fleshwright memory from before the Upload, or a claim about current bodies. It is not counted as a confirmed look violation. If intended as current anatomy, use: We remember the minds inside the plates. They were our kin.
- Sister for Astra (story 433) is metaphorical kinship, not necessarily a female pronoun for a core. Not counted separately as a confirmed naming violation. The line still requires an enemy-faction correction.
- Rook is there in the Hullbreaker charge (194) is consistent with wreck fields around the Hollow Sun and is not counted.
