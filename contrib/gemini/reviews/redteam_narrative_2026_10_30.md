# Red team audit, narrative persona: Argon leg

Chair header: Argon (Gemini, Argon High) leg for the Oct 30, 2026 red team audit, run from the narrative evidence pack and the persona leg prompt. Text below is the model report verbatim, with em dashes normalized to ASCII where they appeared.

Finding 1: Round 8 Lore Invalidates the Oct 26 Story Review Verdict (godot/story/outlines.md)

Classification: OBSERVED and INFERRED

What breaks or underperforms: The Oct 26 story review synthesis ruled "GO WITH CONDITIONS" on godot/story/outlines.md, claiming that "The conditions are all in the choice architecture and the rival, not the prose" and that the outlines "do not need a redesign". That verdict is overturned by the Oct 27 Round 8 lore bible (lore_bible_r8.md) and rename_map_final.md, which invalidated the names, motifs, and core identities of four of the six factions in outlines.md. Worse, the Oct 26 synthesis instructed writers to lean on "oath and beacon for the Crusade", a motif that Round 8 explicitly banned the next day.

Evidence:

story_review_synthesis.md claims: "The conditions are all in the choice architecture and the rival, not the prose".

outlines.md is built on retired pre-Round 8 faction names ("Voidsworn", "Corsairs", "Ithar", "Deathless") and flag keys ("it_song", "dd_vengeance", "cs_rigged").

outlines.md gives Deathless "a crowned eye over a closed tomb door", "Dynast Setekh the Patient", and "the stolen crown worn openly", whereas lore_bible_r8.md replaced Deathless with Eclipse: "The Starwrights who uploaded into machines".

outlines.md fills the Crusade arc with "heresy, confessors, litanists, shrine-moon density" and "a message cut into altar stone", whereas lore_bible_r8.md states "They are a crusade, not a church" and forbids "saints, relics, an emperor's light, beacons that guide ships, lanterns, cathedrals, singing".

story_review_synthesis.md prescribes "oath and beacon for the Crusade", directly violating lore_bible_r8.md's ban on "beacons that guide ships".

What it costs the game: Treating godot/story/outlines.md as prose-ready under the Oct 26 verdict imports Necron tomb-dynasts into uploaded machine copies and church confessors into secular frontier secessionists, breaking the Godot story mode against Round 8 lore.

Finding 2: The Oct 29 Assembled Nemesis Pool Splices Perspectives, Retreats on Victory, and Breaks Round 8 Voice Rules

Classification: OBSERVED and INFERRED

What breaks or underperforms: The Oct 29 assembly (nemesis_lines_assembled_2026_10_29.md) presents its 41 lines as vetted additions to NEM_LINES. Instead, the Chair spliced incompatible narrative perspectives inside loss-reveal debrief, described the victorious enemy as retreating in a loss debrief, forced first-person singular pronouns onto the Chorus swarm across meet, again, remember, and gloat, and reintroduced the Hullbreaker smell motif that the Oct 27 text audit ordered removed.

Evidence:

In loss-reveal debrief, Rey keys lines to the player's faction ("The throats that fed on the wreckage sing uncertain" for Chorus), whereas Qwen keys lines in the same pool to the enemy's biology ("Tissue samples recovered from the retreating mass" and "though the organism was already adapting" under Chorus).

Qwen's Chorus loss-reveal debrief line recovers samples "from the retreating mass" after a fight the player lost.

The assembly notes boast that "every assembled meet line is first-person", assembling "I do not pick targets. I eat whatever is nearest" for ravenous alongside "every crew I command" in again, repeating the Oct 27 Batch 10 defect "Chorus Nemesis lines in first person".

Rey's Hullbreakers loss-reveal debrief line reads "The pack sniffed over what was left of the field and came back with a scent", violating the Oct 27 Batch 10 ruling "the Hullbreaker tracker smelling (Chorus motif against the r8 trail-and-sound ruling)" and lore_bible_r8.md ("who track by trail and sound").

What it costs the game: A Chorus swarm losing to an Eclipse or Hegemony Nemesis can roll a debrief claiming it took laboratory "Tissue samples" from a "retreating" organism, while the newly drafted lines actively undo the Oct 27 voice fixes.

Finding 3: The Oct 29 First-Run Framing Set Violates Its Own Teaching Rule and Gives Hegemony Bureaucracy to the Crusade

Classification: OBSERVED and INFERRED

What breaks or underperforms: To resolve "firstrun ONE SYSTEMIC TEACHING FAILURE", the Oct 29 firstrun assembly (firstrun_framing_recommended_2026_10_29.md) stated a strict selection rule: "mechanical facts first (loss expected, learning carries and is named" and "Where a prettier line dropped the named earning, the plainer line won". The Chair then broke that rule in four of the six factions by dropping explicit "XP" naming everywhere except Crusade and Hegemony, while pasting meta-design wording ("the first is near-impossible") into Hegemony's in-universe Registry log and turning the hull-chalking Sunward Crusade into bookkeepers with "clerks" and a "ledger".

Evidence:

Only Crusade ("The line earned XP and a named lesson") and Hegemony ("the line gains XP and a Registry correction") name XP in their LESSON slots.

Hullbreakers ("a scar, a lesson, a name"), Chorus ("remembers this new verse"), Glasswrights ("with the killing flaw corrected"), and Eclipse ("with these lessons integrated") drop the explicit mechanical earning in LESSON.

Only Hegemony OPENING states "the first is near-impossible", putting design-contract wording inside a "Registry entry" while leaving the other five factions unwarned about Run 1.

Crusade OPENING, NOTHING, NEMESIS, and WIN revolve around "the ledger", "the ledger page", and "our clerks", whereas lore_bible_r8.md defines accounting as the Hegemony's sin ("the people who did the arithmetic") and gives the Crusade "chalked names" on the hull, "Roll-master", and "the Roll of Vesper".

What it costs the game: Four of the six factions still fail to teach the explicit meta-progression XP reward after a Run 1 wipe, and the Sunward Crusade's opening framing sounds like the Hegemony accountants they rebelled against.

Finding 4: The Chorus Admiral Reword Synthesis Approves Naval Water in a Space Fleet Game

Classification: OBSERVED

What breaks or underperforms: In chorus_reword_synthesis.md, the Chair rules "GO WITH CONDITIONS" and asserts that "No leg proposes a rule violation in its own replacement text". That claim is overturned by the Chair's own text pick for Voice of the Deep (Qwen B), which puts a space fleet admiral in "the dark water", violating the core fiction rule that "these are space ships, never naval ships".

Evidence:

chorus_reword_synthesis.md declares: "No leg proposes a rule violation in its own replacement text."

The Chair selects Qwen B for Voice of the Deep: "hollow bell of abyssal membrane, rim a ragged lip of regrowing flesh shedding strips into the dark water".

Both Matriarch of Nine Throats and Voice of the Deep remain in rename_map_final.md under "Looked at and kept" while their existing portraits remain unchecked against pipe-organ keyboards, comb rows, and suture thread.

What it costs the game: Implementing the Chair's selected reword for Voice of the Deep puts literal ocean water into deep-space vacuum combat.

Finding 5: The Oct 29 Event Variants and Nemesis Lines Assume Human Crews, Starwright Amnesia, and Backward-Engine Geometry

Classification: OBSERVED and INFERRED

What breaks or underperforms: Although the Oct 27 audit flagged "events addressing Chorus and Eclipse as human crews" in Batch 10, the Oct 29 assembled event variants (event_variants_assembled_2026_10_29.md) repeat the error: human mercenary crews join Chorus and Eclipse fleets as ships "of your own kind", Glasswrights and Eclipse treat their own "Starwright letters" as alien "Founders' tech", and nemesis_lines_assembled_2026_10_29.md gets spacecraft orientation backward when describing a retreating fleet.

Evidence:

In merc [DeepSeek], "A scarred destroyer captain hails you. Her crew is paid off" and if hired or sworn, "A destroyer of your own kind joins with a veteran captain".

In beacon [DeepSeek], "Your crews patch their drive", and in derelict [Rey], the player selects "Put crews aboard", even when playing "One hungry swarm" (Chorus) or uploaded machine copies (Eclipse).

derelict [Rey] treats "Old Starwright letters" as "Founders' tech", even though lore_bible_r8.md defines Glasswrights ("The Starwrights who stayed flesh") and Eclipse ("The Starwrights who uploaded into machines") as the Starwrights themselves.

In nemesis_lines_assembled_2026_10_29.md, retreat [Qwen] reads: "You turned your engines away from me. I let you. I always let you run." Because spacecraft engines sit at the stern ("big engine bells", "guns never face backward"), turning engines away from an enemy points the prow and weapons toward the enemy rather than fleeing.

What it costs the game: Non-human and Starwright runs break immersion whenever generic events assume human crews or treat the player's own civilization as an unknown precursor race, while the retreat gloat reverses basic spacecraft orientation.

Finding 6: Confirming the Oct 27 "NOT READY" Verdict While Overturning Its Removal of All BLOCKER Tags

Classification: OBSERVED and INFERRED

What breaks or underperforms: The Oct 27 synthesis (text_synthesis_2026_10_27.md) correctly judged player-facing copy "NOT READY", and the pack's evidence confirms that verdict. However, the Chair stripped all ten of Argon's and DeepSeek's BLOCKER tags to "no BLOCKER surviving at that weight". In a roguelite where "about 80 percent of runs are lost by design" and "run 1 is near-impossible", help screens, unlock pointers, and Nemesis cards that state false rules are narrative-mechanical blockers.

Evidence:

campaign_meta.js:150 makes a false availability claim against renown costs and LEGACY gates, contradicted by unlock text on the same screen.

campaign_meta.js:151 promises a "shipyard-after-flagship" flow missing from afterBattle, and campaign_meta.js:167 omits the fourth tier of aspects and rarity.

Locked admiral cards direct players to unlock "in Legacy", a screen renamed "Progression" behind which "buyAdmiral and buyLegacy have no UI".

Five event descriptions promise choice-specific flag unlocks that the code grants on any outcome.

The Deathless/Eclipse Nemesis card states "He never retreats" against a behavior object with no noFlee and a known escape outcome, whereas lore_bible_r8.md assigns the never-flees rule to the Sunward Crusade ("their Nemesis never flees").

What it costs the game: New players learning a punishing tactics game are fed false rules on the help screen, directed to a missing UI to unlock admirals, and deceived by Nemesis and event cards.

Finding 7: Hardcoded Crusade Ranks and Male Pronouns Break Faction and Rival Identity Across Code and Story

Classification: OBSERVED

What breaks or underperforms: Confirming Findings 5 and 9 of text_synthesis_2026_10_27.md and the chair-verified checks in story_review_synthesis.md, both the shipped browser code and the Godot story outlines hardcode Sunward Crusade ranks and male pronouns across all factions and rivals.

Evidence:

Promotion notices, blue-option gates, and the shipyard lede read the Crusade RANKS table instead of rankName, so "a Glasswright captain is announced as promoted to 'Commander'" and an event demands "a Captain or better" in factions with no Captain.

A hardcoded "His fleet is coming" panel line bypasses nemSay in the browser build, and "the Eclipse" is produced by the endRun recap against the no-"the" ruling.

In godot/story/outlines.md, two sample rivals are women ("Petra Lindqvist, Ilyra Glasswing"), while rival prose hardcodes "learns his scent" and "He offers to return it".

In godot/story/outlines.md, the rival performs humanoid acts ("sitting in the auction's front row smiling", "the stolen crown worn openly", "a message cut into altar stone") that cannot apply to a Chorus swarm rival that "does not answer in words".

What it costs the game: Faction identity fractures every time promotions, event requirements, or rival scenes force human male Crusade templates onto Glasswright lens-keepers, Chorus swarms, or female rivals.

Finding 8: Confirming the Choice Architecture Failure in godot/story/outlines.md

Classification: OBSERVED

What breaks or underperforms: Confirming the structural findings of story_review_synthesis.md, the three-beat faction arcs in godot/story/outlines.md drop half of their narrative flags after Beat 1, assign zero flags to Beat 2 choices, make Beat 2 blue options strictly dominant over standard options, and reduce Beat 3 finales to identical resource trades where the rival never reacts in dialogue to Beats 1 and 2.

Evidence:

Six of the 12 Beat 1 flags ("vesper_sold, hg_orders, cs_party, ch_ate, it_mercy, dd_vengeance") appear once at Beat 1 and "are never used again".

"No Beat 2 choice in any arc has a named flag in the document", blocking any Beat 3 callback to Beat 2.

Beat 2 blue options combine standard rewards while removing costs: "weakness plus experience, weakness at a discount with no ambush, weakness plus the clock going back".

Three of the six Beat 3 finales use the exact same reward pair: "repair 20 percent against captain experience 20".

The rival's "hail, last words and gloat are fixed per faction; nothing he says changes" based on Beats 1 and 2.

What it costs the game: Across repeat runs in a generational roguelite, each faction arc collapses into one solved path and a static rival who never remembers what the player did.

Finding 9: Standing Rulings on Repair and Crusade Ship Naming Collide with Code Bugs and Unupdated Lore Docs

Classification: OBSERVED and INFERRED

What breaks or underperforms: Two settled designer rulings ("Repair always beats scrap-and-replace per ship by design" and Ryan's Oct 28 ruling to "SWAP 'Acceptable Loss' OUT of the Crusade ship name pool") are undermined by unfixed code/UI defects in campaign_run.js and drift inside lore_bible_r8.md.

Evidence:

In campaign_run.js, the shipwright repair event "promises a second ship fully repaired; the index arithmetic heals the wrong one".

At campaign_run.js:174, the decommission button label computes NaN for cost-less hulls.

Ryan ruled on Oct 28 to "SWAP 'Acceptable Loss' OUT of the Crusade ship name pool", yet lore_bible_r8.md Section 2.10 at head b3a3b802 still lists "Acceptable Loss" as a canonical Crusade ship name, even though Section 2.1 attributes "within acceptable limits" to the Hegemony Registry that wrote Vesper off.

data.js still carries "RELICS", core.js carries "relic helpers", and rename_map_final.md keeps "Lantern Gut", clashing with lore_bible_r8.md's ban on "saints, relics, an emperor's light, beacons that guide ships, lanterns".

What it costs the game: Players obeying the repair-first ruling get the wrong ship healed at the shipwright, while lore_bible_r8.md still instructs writers to use a Crusade ship name that Ryan already ordered removed.

Finding 10: Shipyard Purchase Surfaces, Hull Variants, and Cards Contradict Combat Rules and Strip Faction Naming

Classification: OBSERVED

What breaks or underperforms: Confirming Findings 3, 4, 7, and 8 of text_synthesis_2026_10_27.md, purchase surfaces and variant cards strip faction weapon names back to base placeholders, silently delete weapons, hide squadron health bonuses, and misstate targeting and fleet-size mechanics.

Evidence:

Shipyard and Hull Variant cards render base weapon names ("Turret laser") while ship cards render faction names ("Plasma cannon"), confirmed on h_picket_i.

Four hull variants ("The Turreted zenith case is verified line by line") silently remove a weapon or ability without disclosing it.

Five carrier admirals hide sqHp:.25, vaelen scopes global aim to lances in text, kassar calls damage "accuracy", and weapon traits ("las, hellfire, scrap, needle, star") omit their numbers.

A module keyed to launch says "Carriers only" despite a cruiser and a battleship carrying launch, while data.js ships broken phrasing ("6 more harder to hit" at data.js:484, "Bigger crew" for fleet size at data.js:482) and undefined terms ("synchronized fire", "Archive restore").

What it costs the game: The shipyard strips faction flavor at the moment of purchase and hides deleted weapons and stat modifiers on cards the player relies on to survive.

Verdict

The Round 8 bible gave Voidsworn a sharp, distinct voice, but the Oct 26 and Oct 29 chair assemblies are actively re-infecting the game with pre-Round 8 lore rot, spliced perspectives, and broken teaching copy. The single most important attack is that the newly assembled Oct 29 content waves (nemesis_lines_assembled_2026_10_29.md, firstrun_framing_recommended_2026_10_29.md, event_variants_assembled_2026_10_29.md, and chorus_reword_synthesis.md) violate the project's own Round 8 lore bible, fiction rules, and Oct 27 audit fixes by putting Chorus admirals in "the dark water", having a defeated Chorus swarm take laboratory "Tissue samples" from a "retreating" Nemesis, turning hull-chalking Crusaders into ledger-keeping "clerks", and dropping explicit XP teaching from four of the six factions on Run 1.

Not checked

The 216 assembled tree texts (tiers 1 to 3), the 16 tutorial tips, the remaining 26 of 33 event variants elided from event_variants_assembled_2026_10_29.md, and the Eclipse battleship entry (d_meridian vs d_wraith), none of which were included in the pack's text excerpts.

The full rename_map_final.md replacement rows (sections 1 through 13 are elided in the pack) and the full lore_bible_r8.md sections 3 through 7 beyond the summary table.

The raw source code of data.js, campaign_run.js, campaign_meta.js, ui3d.js, and battle.js beyond the specific lines quoted and verified in the synthesis reports.

The actual portrait image files for Matriarch of Nine Throats v2, Voice of the Deep, and Mending Choir v2.
