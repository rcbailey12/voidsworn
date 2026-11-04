# Issue 173 chair synthesis: Nemesis commander writing (R85)

Verdict: DONE. One merged, paste-ready NEM_VOICE table is delivered in text_table.md, screened against the shipped game text, alongside the four legs. Everything #120, #121 and #122 need from the writing side is in the table; the only open items are the five owner questions at the end, none of which blocks pasting the table in.

## What was delivered

- text_table.md: the final NEM_VOICE table in data.js format. Five factions, four personas each (the shipped NEM_PERSONA pools, exact), two variants per spoken slot, again and remember lines with the {beat} token, six adaptation lines per faction naming the shipped NEM_ADAPT_FAC names, and eight faction-keyed lesson lines per faction (the seven NEM_WEAK keys plus strike). Verified mechanically: the table parses as JS, pools are exact, every again and remember line carries {beat}, Chorus carries no gendered pronouns and no song or choir words, the file is pure ASCII with no em dashes.
- legs/rey_blind.md, legs/deepseek.md, legs/qwen.md: the three writer legs.
- legs/argon_review.md: the Argon review, filed with a chair screening header (see Screening).

## Method and gates

The pack was built from the shipped sources (data.js NEM_WEAK, NEM_ADAPT, NEM_ADAPT_FAC, NEM_FAC, NEM_LINES, NEM_BEAT_WORD; campaign_run.js nemSay). DeepSeek ran with DeepThink and Search verified on. Qwen ran on Qwen3.8-Max, verified in the selector before sending and in the chat header after generation. Argon ran as a review-only leg against the pack. The blind Rey leg was written before the other legs were read.

## Screening

- DeepSeek: ADOPTED as the base for Hegemony, Hullbreakers, Chorus and Glasswrights personas, adaptations and lessons. One lesson was wrong and is replaced: its Hullbreaker strike lesson advised keeping a credit reserve, but the shipped raid takes 25% of credits whenever the clock fills (data.js:464), so a reserve prevents nothing. The merged line states the mechanic instead.
- Qwen: ADOPTED for the Eclipse fall structure (a separate fall_final key) and for the persona reads listed below. Its Eclipse strike numbers (half-speed clock, 6% hull tithe) were verified against data.js:467 and are in the merged lesson. Its self-flagged items were resolved by line choice: no "tonnage", no "blade" metaphor, no precognition wording survives in the merge.
- Blind Rey leg: ADOPTED for the Eclipse spoken content (meet, win, again, remember, adaptations, and the fall lines) and for the fall_final line content. Two of its choices were screened out: part of its flee pool was written as taunts at a fleeing player (that context belongs to the shipped gloat.retreat pool, not to flee), and its Eclipse fall lines opened with the meta labels "Destroyed early." and "Destroyed in the last sector."; the labels are stripped in the merge, the lines themselves kept.
- Argon: SCREENED OUT for the DeepSeek and Qwen legs. Its three per-leg sections are near-identical and attribute the same quoted lines to all three legs; the chair grep-verified 15 sampled quotations: 11 exist only in the blind leg, 4 in no leg, none in DeepSeek or Qwen. It also cites lesson keys and personas (hegemony.cruel, chorus.proud) that exist in no leg. For the blind leg it made three catches the chair verified independently and acted on: the fall label openers, the flee-slot mix, and a sailing term ("trimmed for drift") in an adaptation line that the merge does not use. Its claim that Chorus again and remember lines invent a return mechanic is rejected: the pack mandates those slots for every faction and commanders recur across story points within a run under the #103 design.
- Chair verification against data.js: the adaptation names in the legs are the shipped NEM_ADAPT_FAC names (data.js:482), including Hegemony "Deflector drills"; the strike facts in every merged strike lesson were checked against the NEM_FAC behaviour text (data.js:464-476), including Chorus growth at 4% per ship lost up to 32% and the Glasswright duel withdrawal condition.

## Merge decisions

1. Table shape matches the pack exactly. The persona reads the blind leg added as a table field are delivered in this synthesis instead (below), so the paste-ready table carries no extra keys. One deliberate addition: Eclipse carries fall_final beside fall (decision 2).
2. Eclipse fall split: fall is destroyed early (the copy reassembles and returns); fall_final is destroyed in the last sector, and its lines anticipate the rise once more for one final fight, matching the shipped behaviour text. Qwen's alternative reading (fall_final as the true final death, lines declaring the archive closed) is owner question 1; its variants are filed in legs/qwen.md if that reading is preferred.
3. Flee lines are the commander's own withdrawal in every faction, per the pack. Eclipse flee stays empty (never retreats).
4. Adaptation lines name the shipped NEM_ADAPT_FAC adaptation in faction voice, and where a shipped effect has numbers the line carries them (Chorus Hunger regrows 3 more hull each turn; Deeper veil is 6 harder to hit; Tight formation reaches one hex further). Lines are written to be spoken through nemSay, so pronouns swap at runtime.
5. Lessons are written to the player in a plain debrief register, pronoun-free as a set, and every mechanical claim in them traces to the pack or to data.js. Three lessons are chair-written or chair-adjusted (Hullbreaker strike, Chorus strike, Eclipse strike); the rest are leg lines.
6. Two wording screens at merge: a Hegemony fall variant naming "the Navy" was replaced (space, not naval), and "marines" in the boarding lessons was replaced with "defenders" to match the pack's boarding-crews vocabulary.

## Persona reads (chair final, from the Qwen leg)

- Hegemony, methodical: Treats your fleet as a data set to be solved on paper before the guns speak; every engagement is a projection to be confirmed.
- Hegemony, proud: Believes the Registry's authority is absolute and your resistance is a clerical error to be corrected with force.
- Hegemony, patient: Holds position and lets your own urgency feed you into his guns; time is on the side of the one who does not move.
- Hegemony, cunning: Feigns a gap, splits the line, and finds the seam you did not know you had; wins by making you solve the wrong problem.
- Hullbreakers, cunning: Sets traps with wreck hulks and hits you from the side you are not watching; takes things by being smarter, not bigger.
- Hullbreakers, greedy: Ignores your escorts and goes straight for your richest ship; wants the prize, not the fight.
- Hullbreakers, proud: Wants you to see the kill happen; stands in the open and dares you to stop it.
- Hullbreakers, cruel: Lets your crippled ships sit, then finishes them one by one while you watch; the slow break is the point.
- Chorus, ravenous: Eats everything closest first; does not choose, consumes; the fleet is a mouth and everything is food.
- Chorus, cruel: Tastes your crippled ships and finishes them slow, savouring the break; the suffering is flavour.
- Chorus, cunning: Waits in the dark between stations, strikes where your hull is thinnest; hunger makes it patient and precise.
- Chorus, patient: Lets you come close, lets you think you are winning, then swallows the gap; the mouth does not chase.
- Glasswrights, cunning: Finds the angle you did not guard and strikes through it like light through a crack in glass.
- Glasswrights, proud: Duels you openly, flagship against your fleet, and expects the exchange to be clean; honour is precision.
- Glasswrights, patient: Holds at the edge of range, watching, waiting for you to overextend into the kill zone.
- Glasswrights, cruel: Picks your most damaged ships and finishes them while you watch; precise, unhurried, grief-coloured.
- Eclipse, patient: Waits across centuries; the hunt is a record being written and it will not rush the entry.
- Eclipse, proud: Remembers every fleet it has archived; yours will be another line in the record, shorter than most.
- Eclipse, cruel: Erases your ships one by one and files the memory of each breaking; the archive keeps everything.
- Eclipse, methodical: Processes your fleet as data, each engagement a correction pass; the model improves with every loss you take.

## Integration notes for the build issues

- #121 (persistence and voice): the table keys are the data ids (hegemony, corsair, chorus, ithar, deathless) and the shipped persona ids. fall_final needs one wiring decision: fire it when the Eclipse commander is destroyed in the last sector. If the final fight itself needs distinct death lines later, that is a third key (fall_last) and a small follow-up writing job, not a change to this table.
- The placeholder pools in NEM_LINES (meet by persona, again, remember, gloat) are superseded by this table for meet, again and remember. Gloat is not covered here; the shipped gloat placeholders stand.
- Adaptation lines assume the panel also shows the adaptation name (the NEM_ADAPT_FAC n field). The lines still read correctly if rendered as panel text only.
- Lessons keying: weakness lessons are keyed by the weakness the beaten commander actually had (per-commander keying per R85), the strike lesson by the faction strike. The lines are written about the beaten commander, not about the faction in general.

## Owner questions (chair picks stated)

1. Eclipse fall_final semantics. The merge reads fall_final as destroyed in the last sector, lines anticipating the rise (matching the shipped behaviour text). Qwen's reading makes fall_final the true final death, with lines declaring the archive closed. Chair pick: the merged reading. The alternative only matters if #121 gives the final fight its own death event.
2. Chorus again and remember frame. The merged lines use taste and heat memory ("The taste is known") rather than describing the fleet physically returning. Chair pick: keep. The Chorus commander's continuity is appetite, and the slots are mandated for every faction.
3. Persona reads live in this synthesis, not in the table. If a codex or inspection screen wants them in data, they can move into a NEM_READS table later without touching NEM_VOICE. Chair pick: keep them out of the voice table.
4. Adaptation lines are spoken by the commander through nemSay, with the panel showing the adaptation name. Chair pick: spoken. Nothing in the lines breaks if #121 renders them as panel text instead.
5. Lessons are pronoun-free as a set (no he, she or it for the commander). Chair pick: keep. It keeps the debrief about the player's next move, and it sidesteps Chorus pronoun questions in shared UI code.

## Not checked

- No line was tested in the running game; pronunciation, line length in the actual dialogue UI, and nemSay substitution against every {beat} value were checked by reading the substitution table (NEM_BEAT_WORD), not by rendering. The build issues own the in-game pass.
- The Voidsworn (player faction) has no Nemesis commander and no table here, per the issue scope.
