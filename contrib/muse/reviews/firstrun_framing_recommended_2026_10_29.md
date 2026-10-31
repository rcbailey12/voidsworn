# First-run framing text: chair recommended set (savings pass, Oct 29, 2026)

Assembled from the three filed external drafts (DeepSeek, Qwen, Argon, all on main under contrib/deepseek/reviews/, contrib/qwen/reviews/, contrib/gemini/reviews/ as firstrun_framing_2026_10_29.md), one unit picked per slot, source marked. This completes the firstrun framing item: the Argon draft landed Oct 30, 2026 (commit 8c605276), unblocking the set. No Rey draft exists for this item by design; the savings-pass framing legs were the three external prongs, and this set is the chair's merge.

Selection principle: the pack's own rule, mechanical facts first (loss expected, learning carries and is named, nothing-earned said honestly, Nemesis inference less certain than a victory report), idiom second. Where a prettier line dropped the named earning, the plainer line won.

### Sunward Crusade
OPENING [Argon]: Each Crusade is one generation's march. Most fleets will be lost; the oath expects it. Whatever this generation learns is written into the ledger, and the next inherits the account.
LESSON [DeepSeek]: The line earned XP and a named lesson; the debt is acknowledged and carried.
NOTHING [Argon]: The fleet is gone and the ledger page remains blank. The Crusade learned nothing new from this loss; the debt stands.
NEMESIS [Argon]: From the last fragmentary entries in the burned ledger, our clerks can almost trace the killer's flaw: every incomplete account points toward [WEAKNESS].
WIN [Qwen]: The crusade returns whole. The oath is kept, and the ledger passes to the next generation, richer by this victory.

### Hegemony
OPENING [DeepSeek]: This generation's expedition is filed as one Registry entry. Most entries close in loss; the first is near-impossible. Lessons filed are inherited by the next generation.
LESSON [DeepSeek]: The loss is filed with a lesson earned: the line gains XP and a Registry correction.
NOTHING [Argon]: The fleet was lost before any actionable data could be filed. No updates have been entered into the Registry; standard procedure remains unchanged.
NEMESIS [DeepSeek]: The report infers one Nemesis weakness from incomplete records: [WEAKNESS]. Filed as probable, pending confirmation.
WIN [Argon]: Objective secured and the fleet returns intact. This campaign's record is ratified into permanent doctrine for the next generation of command.

### Ashfall Hullbreakers
OPENING [Argon]: One generation runs this hunt together. Most packs die in the cold between stars: that is the way of the hunt. What survivors carry home in scars and trophies teaches the next litter how to kill.
LESSON [DeepSeek]: The pack carries home a new scar and a named lesson: the line gains XP.
NOTHING [Qwen]: The pack is broken, and nothing comes home. No trophy, no scar worth naming. The next hunt starts where the last one ended.
NEMESIS [Qwen]: The pack scattered before the Nemesis, but the ones who ran saw something: maybe [WEAKNESS]. It is not certain. But the survivors remember, and memory is a kind of tooth.
WIN [Argon]: The pack returns heavy with trophies and living blood. The next litter inherits a stronger den and the memory of this kill.

### Chorus
OPENING [Qwen]: This generation's fleet grows and sings its passage outward. Most songs end in silence; the Chorus knows this. But what is heard before the silence becomes a verse the next generation's flesh keeps.
LESSON [DeepSeek]: The song keeps a new verse from this loss: the line gains XP and a named lesson.
NOTHING [Argon]: Their throats were cut before a new note could form. The song learned no new verse from this dying.
NEMESIS [Qwen]: The Nemesis drowned the fleet's song. But in the last moments, something was almost heard: a shape like [WEAKNESS]. It is half-remembered, uncertain. The next throats will sing it and test whether it holds.
WIN [Argon]: The brood returns whole, their throats full of triumph. This verse is woven into the flesh; the next growth will sing it from birth.

### The Glasswrights
OPENING [Argon]: This fleet is the next casting in our deep-time queue. Expect it to shatter; most castings do. Gatherers will recover the shards, read the light of battle inside, and recast the next lineage stronger.
LESSON [DeepSeek]: The glass recovers a lesson from this loss: the line gains XP and a named shard.
NOTHING [Argon]: The gatherers returned with dark, clouded shards that held no light. This casting taught the forge nothing new.
NEMESIS [Argon]: Peering through the crazed, heat-warped shards of the fallen fleet, our glaziers think they can trace the breaker's flaw in the refracted light: [WEAKNESS].
WIN [Argon]: A casting returns unbroken, blazing with recorded light. The forge sets this pattern as the new mold for every generation queued behind it.

### Eclipse
OPENING [Qwen]: A new iteration deploys. Most copies are terminated in the field; the Archive expects this. What data persists is written back, and the next version begins with the corrections applied.
LESSON [DeepSeek]: This loss archives a lesson earned: the line gains XP and a named correction.
NOTHING [Argon]: The copies were wiped before any new telemetry could sync. The Archive records zero learning from this iteration; the next version boots unchanged.
NEMESIS [Qwen]: The Nemesis terminated the iteration. Residual telemetry is fragmentary, but pattern-matching across surviving copies suggests, low confidence, that [WEAKNESS] may be a vector. Flagged for the next version's attention.
WIN [Argon]: Iteration successful; the active copies survived the run. The Archive locks this version as the new baseline for all subsequent generations.

## Assembly notes

Mix (as corrected Oct 30, 2026, see the chair correction below): Argon 12, Qwen 7, DeepSeek 11 of 30 units. DeepSeek carries all six LESSON slots, because it is the only draft that names the earning in every one; Argon carries the voice of the openings and debriefs; Qwen carries the Nemesis inference slots where its hedged register works.

Edits made by the chair (the only changes to filed text): two punctuation normalizations where the filed drafts' dash-to-hyphen conversion had fused clauses. Hullbreakers OPENING (Argon) "stars-that is" becomes "stars: that is"; Eclipse NEMESIS (Qwen) "suggests-low confidence-that" becomes "suggests, low confidence, that". No words added, removed, or reordered anywhere.

Flags for Opus, all excluded from the set:
- Argon's Hegemony OPENING overstates the contract ("Total loss of the fleet is projected") where the design says most fleets are lost. Not used.
- Argon's Chorus OPENING introduces "mother-flesh," an entity the settled Chorus idiom does not name. Unruled lore; not used.
- Qwen's Hullbreakers WIN ("licks the blood off its elders' jaws") is the strongest single image in any draft and the reserve pick if Opus wants the pack bloodier; held out of the recommended set on register, not quality.
- DeepSeek's set is the complete fallback: every unit is plain, exact, and shippable as-is if Opus prefers one voice over the merged set.

## Chair correction, Oct 30, 2026

The Argon narrative leg of the Oct 30 red team audit (finding 3) charged that this set breaks its own selection principle: only the Crusade and Hegemony LESSON slots named the earning, while the other four factions' LESSON slots dropped it. The chair verified the charge against this file (grep: "XP" appeared exactly twice, both in LESSON slots already held by DeepSeek) and it HOLDS. The principle printed at the top of this file says the plainer line wins where a prettier line drops the named earning; the original assembly did the opposite in four slots.

Fix applied before this file was ever pushed: the four non-naming LESSON slots are swapped to the DeepSeek lines, which name XP in each faction's own idiom.

- Ashfall Hullbreakers: Qwen's "The pack is broken, but not empty-pawed..." replaced by DeepSeek's scar-and-XP line.
- Chorus: Argon's "The brood died in the dark..." replaced by DeepSeek's verse-and-XP line.
- The Glasswrights: Qwen's "The casting shattered..." replaced by DeepSeek's shard-and-XP line.
- Eclipse: Argon's "The active copies were terminated..." replaced by DeepSeek's correction-and-XP line.

The four displaced lines are not deleted from the record; they are the prettier reserves, quoted in the leg and in the screening notes, and Opus may restore any of them if he judges the teaching cost worth it. The mix line in the assembly notes is updated to match.

One part of the same finding is NOT resolved here and is flagged for the narrative synthesis: the Crusade units lean on "ledger" and "our clerks" (Argon's OPENING, NOTHING, NEMESIS, WIN), while lore bible r8 gives accounting to the Hegemony and gives the Crusade chalked names, the Roll, and the debt. Both alternative drafts also write the Crusade in a bookkeeping register (DeepSeek's OPENING is also "entered in the ledger"; Qwen's NEMESIS also uses "analysts"), so no clean swap exists in the filed drafts; a Crusade re-voice in chalk-and-Roll idiom is a drafting task, not a swap. Left open deliberately rather than papered over.
