# Plate-to-Terrain Mapping Synthesis (chair, TWO LEGS)

Legs: contrib/deepseek/reviews/plate_mapping_deepseek_draft.md (DeepSeek)
and contrib/qwen/reviews/plate_mapping_qwen38max_draft.md (Qwen, Oct 25
retry). Nothing in it is a ruling. Model caveat on the Qwen leg: the
generating continuation reported Qwen3.8-Max / Thinking ON / Search
OFF, but a later check observed Qwen3.7-Plus in the composer header,
so confirm the model badge on the generating response in the thread
before citing the leg as a pure Qwen3.8-Max leg. A second near-identical
Qwen generation arrived later in the same thread with the same
mappings, triggers, and recommendation, differing only in wording and
formatting; the filed leg is the first of the two.

Chair verdict: GO WITH CONDITIONS (two-leg agreement on the table,
genuine disagreement on Dead Star and on the specials shape).

## Headline
Both legs map all 18 plates exactly once, keep the five code terrain
kinds unchanged, and refuse a hollow sixth kind. The five anchors map
to the five kinds, the six variants inherit their parent's kind with
one show-instead rule each, and Dead Star Companion is best left
dependent on the Dead Star call (the Qwen framing) rather than fixed
early. Where the legs disagree, the disagreement is the decision: Qwen
recommends the well mechanic for Dead Star with a boss-fight fallback,
while DeepSeek recommends the finale role outright; and Qwen splits the
six specials across home-ground seasoning, anomaly, boss fight, and
finale, while DeepSeek puts all six in one anomaly bucket. Neither
specials shape is an observed system, and neither Dead Star branch is
free: the well is new engine work, and the finale role presumes a
finale structure that is not established in the brief.

## Where the legs agree (adoptable as decisions, with the trigger caveat below)
- Anchors: Belt, Storm, Graveyard, Planet, Station map to their
  same-named kinds. Chair downgrade: Qwen marks these OBSERVED on name
  match, DeepSeek marks them PROPOSED, and DeepSeek is right. A name
  match is a strong argument, not a code reference. Treat all five as
  PROPOSED (strong name match) until Opus confirms how plates reference
  terrain kinds in code or data.
- Variants inherit their parent's kind. Fresh Battlefield (graveyard),
  Ring World (planet), Dockyard Dawn (station) are OBSERVED per the
  brief; Belt Core, Crimson Storm, Dead Star Companion are name-inferred.
- No plate goes to menu/backdrop in either leg. Both legs flag that
  explicitly, so a menu plate would be a scope addition, not a remap.
- Dead Star has no terrain kind (OBSERVED, Pack J verified). Both legs
  agree a sixth kind with no mechanic would be a dead label, and both
  agree the well mechanic, if chosen, is new engine work, not a mapping
  decision.

## Conditions
1. Dead Star ruling (the central decision, Ryan's call): well mechanic
   vs non-terrain role. If the well is chosen, it must be scoped as its
   own engine work item with an Opus estimate first (encounter-type
   branch, interaction logic, AI behaviour, balance, QA), and the well
   design itself still needs to be written, since no well mechanic is
   defined anywhere today. If the well is rejected, the fallback choice
   is boss fight (Qwen's pick) vs finale (DeepSeek's pick); Dead Star
   Companion follows whichever role is chosen. Until this ruling lands,
   Dead Star Companion stays dependent, not fixed.
2. Opus hook check (the blocker for all triggers): for each variant and
   special rule in both legs, report whether the state hook exists in
   code or data, or whether the rule needs a new system. The mapping
   table stands regardless; the triggers stand or fall on this check.
   Rules that fail both the code check and a build ruling fall back to
   TBD placeholders, not shipped rules. This covers both variants of
   the contested rules: Crimson Storm as storm recurrence (Qwen) vs
   crimson rotation slot (DeepSeek), and Fresh Battlefield as
   same-session recency (Qwen) vs last 3 turns (DeepSeek).
3. Specials shape: single anomaly bucket (DeepSeek) vs split roles
   (Qwen). Do not adopt either as a system yet. Both presume trigger
   systems that are unverified: safe-harbour scenes, anomaly encounters
   with sub-type tags, boss-type encounters, a campaign finale. The
   sub-type tag mechanism Qwen uses to split shared roles (cold vs
   energetic anomalies, physical vs energy bosses) is itself a
   possible small schema addition Opus must confirm. Keep the word
   "anomaly" marked PROPOSED wherever it appears until an anomaly
   system is ruled or confirmed.
4. Anchor mechanism: Opus confirms how plates reference terrain kinds
   in code or data today, since even the name-match mappings are
   PROPOSED until that reference is confirmed.

## Recommended next step
Ryan rules the Dead Star call in condition 1 (well vs boss fight vs
finale), and Opus runs the hook check in condition 2 across both legs'
rules in parallel. The Dead Star ruling unblocks Dead Star Companion;
the hook check turns the trigger tables from proposals into something
shippable. Neither step needs the other to start.

## Not checked
- The model badge on the Qwen generating response (see caveat above).
- Whether plates are referenced from code or data at all today.
- The finale concept, boss phases, and any event system the triggers
  presume.
- The economy hook and all other second-wave jobs, which are out of
  scope for this synthesis.
