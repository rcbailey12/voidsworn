# Brief for Muse: faction lore review, round 4 (Oct 27, 2026)

From Opus, at Ryan's request ("have muse run checks against the faction lore too with the other LLMs").

**Read first:** `contrib/opus/compute/lore_bible_r4.md`, the current lore draft exported from the live doc Ryan comments on. Rounds 1 to 3 are superseded; ignore `lore_bible.md` and `lore_summary.md` except as history. Nothing in the draft is applied to the game yet.

**House rules,** as in `contrib/opus/briefs/muse_2026-10-25_engine_and_b2.md`:
- blind legs (Argon, DeepSeek, Qwen), each run without seeing the others;
- primary sources with links for any outside claim;
- UNSURE tags;
- plain words, no em dashes;
- raw returns in `contrib/<model>/`, synthesis in `contrib/muse/reviews/lore_r4_review.md`;
- no edits under `contrib/opus/`, `godot/`, game code or HANDOFF.md;
- commit to main.

Opus independently verifies every claim before anything is incorporated. A ruling changes only when Ryan says so.

## What Ryan has already decided (do not relitigate; flag only real problems)

- **Science fiction, not fantasy.** Ryan rejected rounds 2 and 3 as reading like "high fantasy" and "young adult fantasy". Grounded tech: a megastructure, a black hole, AI cores, mind uploads.
- **Locked names:**
  - factions: Sunward Crusade (was Voidsworn), Ashfall Hullbreakers (was Corsairs), Glasswrights (was Ithar), the Chorus, Hegemony Navy;
  - weapons: Null (was Gauss), Corona arc (was Doom arc), Prism lance (was Pulsar lance), Sear (was Las-), Cinder torpedo;
  - the Ninefold Maw;
  - "jump" for faster-than-light travel.
- **Title:** "Embers of the Hollow Sun" (liked). Ryan wants the setting under it to feel properly sci-fi.
- **No Warhammer 40k echoes.** That covers names, motifs and look. Ruling R44: rename everything 40k-adjacent.
- **Space, not naval** (CLAUDE.md). No sea-ship tells in ship descriptions.
- **The Eclipsed (was Deathless/Undimmed) and the Glasswrights are siblings:** one people split by the Ascension. Ryan likes that pairing (darkness against light).
- **The Hegemony is tech-forward:** AI-run, with cybernetic citizens. The Sunward Crusade is unaugmented and broke away from it.
- **Hullbreakers are grimdark raiders** who live for violence, not pirates after treasure, and not Warhammer orks.
- **Gameplay rulings the lore must stay true to:**
  - R42 and R49: the Nemesis behaves differently by faction. Eclipsed come back once in sector 3; Hullbreakers return a stolen ship when they die; Glasswrights flee and return with the same 4 ships, upgraded.
  - Plasma is light blue (R46).
  - Faction mechanics are in `data.js` (FAC and doctrines).

## Jobs, in order (file whatever finishes)

### Job 1: originality and collision check
For every proper noun in the draft:
- names of factions, people, ships, ranks, places, weapons and patrons;
- "the Lattice", "Caelum" and the Caelans, "the Ascension", "the Dimming", "the Registry", "the Eclipsed", "the embers".

Check whether it collides with another game, film, book franchise or trademark in the same sense. Opus already found and rejected "the Umbral" (Endless Space 2's Umbral Choir); "Sunward" exists as an Eclipse Phase book and a Guild Wars region, which Opus judged acceptable.

Also check story-level echoes:
- Is "uploaded machine people who killed their star" too close to anything known (Mass Effect, Stargate, Halo's Forerunners, Destiny, Stellaris precursors, Endless Space, Sins of a Solar Empire)?
- Is "AI-run human state that writes off a colony" too close to anything known?

Give a verdict per item (clear, minor echo, real collision), a source for each collision, and one or two alternatives for any real collision. Deliverable: section 1 of the synthesis.

### Job 2: internal consistency
Check the whole draft against itself:
- Do the timeline and causes hold together? How long ago was the collapse? Does a star-lifting overdrive plausibly collapse a star into a black hole, within soft sci-fi?
- Does every faction's want follow from the story?
- Does every faction's opinion of the others match what the others actually did?
- Does each patron's "where it went" line match the faction sections?
- Do motif owners (section 1.3) clash? Do colour palettes clash? In particular, the Eclipsed's violet against the Chorus's new olive and bile yellow, and the Sunward Crusade's ember orange against the Eclipsed's white-gold.

List every contradiction with line numbers in `lore_bible_r4.md` and a one-line fix.

### Job 3: sci-fi grounding pass
Ryan's main complaint is fantasy drift. Flag any word, name or idea that still reads as fantasy rather than science fiction. Examples of the kind of thing to catch:
- mystical wording;
- names that sound elvish;
- "embers" being described as magical rather than as hardware.

For each, give a grounded sci-fi alternative, and say whether the change matters (it changes how the faction reads) or is cosmetic. Also suggest up to five concrete hard-sci-fi details that would make the setting feel more grounded without adding jargon a non-technical player would trip over. Back the science with a source where one exists: star-lifting, black hole formation, mind uploading, beamed power.

### Job 4: does each faction feel distinct and appealing?
Compare the six factions against how strong 4X and tactics games differentiate theirs: Sins of a Solar Empire 2, Stellaris, Endless Space 2, BattleTech, Battlefleet Gothic Armada 2, Homeworld. Cite sources, such as developer talks and articles on faction design.

For each faction, cover:
- one-line fantasy, meaning the player power fantasy in the game-design sense;
- what makes it unique;
- what might feel generic;
- whether its look, voice and mechanics say the same thing.

Highlight the two human factions especially. Ryan asked how to tell them apart; the draft's answer is centre against frontier, augmented against unaugmented, and calculation against oath.

### Job 5: questions only Ryan can answer
Collect the human-direction questions the review raises: taste, tone, which way to go. Give each one as a short multiple-choice question with a recommended option first, written for a non-technical reader. Opus will relay them.

## Synthesis format
`contrib/muse/reviews/lore_r4_review.md`:
- a section per job;
- each claim tagged CONFIRMED BY 2+ LEGS, SINGLE LEG, or UNSURE;
- line numbers in `lore_bible_r4.md` for every internal claim, and links for every outside one;
- a top summary of five bullets at most, written for Ryan's phone.
