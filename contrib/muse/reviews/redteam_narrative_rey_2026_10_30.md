# Red team leg: Narrative and lore seat (blind Rey leg, Oct 30, 2026)

Seat: story, text, tone, lore consistency. Basis: the narrative evidence pack (core pack, claims register, Oct 27 text synthesis, Oct 26 story synthesis, Chorus reword synthesis, event variants assembly, Nemesis lines assembly, firstrun framing recommended set, lore bible r8 excerpt, rename map excerpt), plus direct source checks in the local clone at the audit pin, cited by file and line where used. Prior verdicts were treated as claims under attack.

## Findings, ranked by severity for this seat

### 1. The Chorus sings everywhere, under a written ban on Chorus singing (OBSERVED)

The approved lore bible is explicit. lore_bible_r8.md:333: "Never sings. No song words in any Chorus name or line." Its voice line, lore_bible_r8.md:332, gives the Chorus "Taste, heat, smell, teeth" instead. Against that, the program's newest Chorus text is built on song at every layer:

- The firstrun framing idiom spec itself defines the Chorus as "the song remembers; lessons are verses the flesh keeps", and the recommended set's Chorus units sing in all five slots (a verse the next generation keeps, a dying strain, a drowned song, throats that will sing it from birth).
- The Nemesis lines assembly gives the Chorus "Every throat sings it now, and the song does not waver" as its certain-register debrief, and a singing uncertain register to match.
- The tier 3 tree assembly (skill_tree_tier3_assembled_2026_10_29.md:66 and :75) ships Chorus skills named "Broods Sing the Strike Order" and "The Throng Sings the Flagship Whole".
- The shipped admiral is still "the Mending Choir" in data.js names, where the bible's beings list, lore_bible_r8.md:338, names her "the Mending Throng".

The Godot story stream already complies with the ban: godot/story/review_incorporation.md:43 records that "the Chorus speaks in taste, heat and teeth" and that song was reassigned to the Glasswrights. So the two halves of the game now speak two different Choruses, and the half that violates the bible is the half with the most new text. Cost: dozens of drafted lines across four assemblies sit on a banned motif. Every week both stand, more content accrues on the wrong side, and whichever way Ryan eventually rules, one corpus gets rewritten.

### 2. The Oct 27 NOT READY verdict was never remediated, even in its cheapest items (OBSERVED)

The text synthesis verdict stands at the current pin, confirmed by direct checks, including items that synthesis filed as "single pass, no discussion needed":

- campaign_meta.js:68 still renders "Unlock for ${a.cost} renown in Legacy", pointing new players at a screen that was renamed Progression, behind which the purchase buttons do not exist.
- data.js:482 still describes a fleet-size effect as "Bigger crew" ("One more ship joins his fleet."), and data.js:484 still reads "His ships are 6 more harder to hit."
- The Crusade RANKS table still speaks for every faction on the two most visible surfaces: event requirement text at campaign_run.js:227 ("a Captain or better" in the gate builder) and promotion notices at campaign_run.js:411, though the same file uses the faction rankName elsewhere.
- A surface the first audit did not enumerate: every NEM_ADAPT_FAC description at data.js:482-487 genders the Nemesis male ("his fleet", "His ships regrow", "his ships reassembles"), while the Nemesis name lists roll gender by faction, the exact defect the new Nemesis lines assembly had to engineer around.

Cost: three content waves were drafted on top of a text layer whose known-broken pointers and mislabeled cards still ship. The verdict did not fail; the follow-through did.

### 3. "Acceptable Loss" was ruled out of the Crusade pool and is still in it (OBSERVED)

Ryan ruled on Oct 28, 2026 (recorded in the text synthesis) to swap "Acceptable Loss" out of the Crusade ship name pool, the same treatment as Thornback and Moonveil. At the audit pin it is still in the shipped pool at data.js:254, and it is still canonized as an example name in the lore source of truth itself, lore_bible_r8.md:192. Cost: a ruled voice fix landed in neither the data nor the bible, so any future pool regeneration from the bible restores it silently. This is the same failure shape as Finding 2, one level up: rulings are being recorded in syntheses and then not propagated to the two places that actually generate text.

### 4. The Crusade's flagship story arc is built from its own banned materials (OBSERVED)

lore_bible_r8.md:156, the Crusade's prohibition list: "Not allowed: saints, relics, an emperor's light, beacons that guide ships, lanterns, cathedrals, singing." The Godot Crusade arc's Beat 1 is titled "The Saint's Hand" (godot/story/outlines.md:54), and its first option reads "Gain a relic: the saint's hand." (outlines.md:58). The Beat 3 win line burns the saint's hand while the rite-keepers add a verse (outlines.md:87). The incorporation document records that saint, relic and Rite were kept deliberately as "the one borrowed register", following one reviewer's preference. The bible's list was never amended to match. Cost: the approved source of truth forbids the centerpiece object of the Crusade's own arc. Any later bible-faithful pass, by any writer or model, will read the arc as a violation and start deleting its core dilemma.

### 5. The pack's story evidence describes a superseded draft, and its conditions were closed by self-grading (OBSERVED, risk INFERRED)

The story synthesis in this pack returns GO WITH CONDITIONS on the original outlines. godot/story/review_incorporation.md:27-45 shows the document has since been revised twice: flags renamed (vesper_ became vs_, dd_vengeance became dd_writ), every Beat 1 flag given Beat 2 and Beat 3 payoffs, Beat 3 reward pairs dissolved, pronouns tokenized. The fixes are real and several are excellent. But the grades in that document are the implementer's own ("Mine for REVISED is PARTLY" against another checker's LANDED), and no blind re-review of the current arcs exists anywhere in the evidence. Cost: the council's story conclusions no longer describe the story the game has. The one content area with the deepest revision history is the one with no independent verification of its current state.

### 6. The story stream is minting vocabulary the final rename map retired (OBSERVED)

rename_map_final.md states that "Deathless Court, writ/warrant/edict, the Court words and others are all retired", and that the file supersedes the Oct 26 rename map. The incorporation, written after that map was approved, proposes a replacement rival built on "a debt the Court cannot forgive" (review_incorporation.md:54), prints "The writ is marked served" as a Beat 3 win line (review_incorporation.md:53), defends "the Court in session" (review_incorporation.md:56), and cites the superseded document for consistency: "Keep it consistent with contrib/opus/compute/rename_map.md when it lands". Cost: two naming authorities in one repo give opposite instructions, and the newer content follows the retired one. Every line written under Court and writ vocabulary is a future rename sweep.

### 7. The Eclipse flagship displays a class name from its own forbidden list (OBSERVED)

lore_bible_r8.md, section 7.2, orders: "Avoid every Necron tell: tomb, dynasty, overlord, cryptek, necropolis, living metal, gauss, doom, scarab" and more of the same register. The Eclipse boss hull at data.js:101 is The Unsetting, class "Tomb-ark". The other Eclipse classes display clean (Frigate, Destroyer, Cruiser), so the one hull every player is guaranteed to read carries the banned word in its class label. Cost: small in text volume, large in placement. The 40k proximity the story review worked to thin out of the arcs is sitting in the shipped data on the faction's signature ship.

### 8. The Chorus bell question was already answered by the naming authority (OBSERVED)

rename_map_final.md:537, in the looked-at-and-kept list: "Judgement Bell (bells belong to the Crusade)". The Chorus reword synthesis nonetheless presents bell versus dome for the Voice of the Deep as an open aesthetic choice for Ryan, and its chair pick is Qwen B, a "hollow bell of abyssal membrane". Cost: if the pick stands, the Chorus's most visible admiral wears the Crusade's signature object, and the collision will surface the first time both factions are on screen in text. The synthesis treated an owned motif as a coin flip because the rename map was not in its evidence. That is a pack-building failure as much as a wording one.

### 9. The contract layer still speaks in developer voice (OBSERVED)

Two instances in the newest, most-taught text:

- The firstrun framing set, whose whole job is to teach the generational contract in faction idiom, gives the Crusade "The line earned XP and a named lesson" and the Hegemony the same construction. "The line" is design-document shorthand no player has seen defined, and "XP" is patch-note vocabulary, in the two factions whose openings otherwise speak pure ledger and Registry.
- The haven variant in the event variants assembly carries the chair's editorial bracket inside the option's result text, closing with implementation shorthand "r {}", in the slot a player would read. Assemblies are drafts for an implementer, but the note sits in a content field, not in the assembly notes where the same document correctly puts its other commentary.

Cost: modest per instance, corrosive in aggregate. These are the screens and strings that teach players how to read everything else; scaffolding left in them teaches players that the text is not finished.

### 10. The newest tutorial still teaches a one-way Nemesis clock (OBSERVED)

The firstrun synthesis's headline was one systemic teaching failure: the tip system cannot fire where the teaching is needed. The assembled tutorial's clock tip (tutorial_assembled_2026_10_29.md:10) reads "When it fills, the Nemesis comes to you; the meeting is not optional." and says nothing about pushing the clock back. The assembly's own notes (same file, line 31) record that three shipped events, haven tribute, scout and saboteur, do exactly that. Cost: a new player who learns the clock from the tip will misread three event options when they appear, pricing a delay tool as flavor. The teaching failure the audit named is being reproduced by the content drafted to fix the teaching layer.

## Verdict

NOT READY, on the bible's own testimony: the drafted Chorus sings under a written ban, the Crusade's arc is built from its banned list, and ruled text fixes from a month of audits are still live in the shipped data. The single most important attack is Finding 1: two halves of the game now speak two different Choruses, and the violating half is the one still growing.

## Not checked

- Tree tier 1 and phase 1 texts line by line; tiers 2 and 3 were spot-checked only (the Chorus singing instances above, plus negative checks: no naval terms and no "the Eclipse" in the assemblies).
- The full event variant set; the pack elided most events, so voice and accuracy were judged on the shown subset plus the assembly notes.
- The Eclipse battleship entry text itself; only its open name question (d_meridian against d_wraith) was in the pack. On the evidence available this seat sides with the darkness pattern: the bible's Eclipse owns darkness and its ladder runs mote, flare, zenith to The Unsetting, and "meridian" names the sun at its height.
- The current outlines in full; story findings rest on the incorporation document's own quotations plus spot checks of outlines.md lines 9, 54, 58 and 87.
- Bible sections 3, 4 and 6 in full; the Chorus and Eclipse sections were read at the cited lines, the Crusade section via the pack excerpt and cited lines.
- Checked and cleared, for the record: the internal ids gauss, doom and phylactery, which sit on the bible's Eclipse avoid list as words, display clean ("Null cannon" at data.js:21, "Corona arc" at data.js:23, "Eclipse backup frame" at data.js:193). No player-facing violation there. Likewise "the Eclipse" no longer appears in the shipped JS files checked.
- Whether fixes exist in work beyond the clone's pin state; this leg audited the pin it was given.
- Portrait art, audio and music text, and the Godot UI strings; outside this pack.
