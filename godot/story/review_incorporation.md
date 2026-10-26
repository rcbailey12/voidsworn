# Story review incorporation (R45): the four-way blind review, checked and applied

Owner: story stream. Date: Oct 26, 2026.

**Inputs:**
- the synthesis, contrib/muse/reviews/story_review_synthesis.md (GO WITH CONDITIONS, 10 fixes);
- its four legs, each read where the synthesis cites it: DeepSeek, Argon, Qwen and Rey;
- Muse's later check of the revision, contrib/muse/reviews/story_incorporation_check.md.

No leg was edited.

**Three texts are compared:**
- **ORIGINAL**: `git show 4ec033b:godot/story/outlines.md`. This is the one all four reviewers read.
- **REVISED**: f51fcf8, after the two Claude reviewers. Muse's check read this version.
- **NOW**: round 3, this pass. Commits 401edc7 and 8f9c8c5 hold the outline and code changes; this report and the README update follow. Both outline files are marked REVISED (round 3).

**Checks, all green:**
- `python3 godot/story/test/check_outlines.py`: 36 cards, 0 fails (100 to 150 words, no em dashes);
- `python3 godot/story/test/check_personas.py`: the rival pools match stream B's personas for all six factions;
- `godot --headless --path godot --script res://story/test/story_test.gd`: PASS, 0 failed.

Ryan's rulings applied:
- Direction, voices and structure are approved, with the 10 fixes as conditions.
- His final read per faction is still the gate before any arc ships.
- Dials: Option A first, then the Option B arcs; three beats per faction; text only; glyph crests now, bust portraits later.

## 1. Verification of the synthesis's facts

| Synthesis claim | Against ORIGINAL | Against REVISED and NOW |
|---|---|---|
| Each of the 12 Beat 1 flags appears exactly once; six are picked up in Beat 2, six never used again | TRUE. Each flag name appears once (grep count 1 each), at its Beat 1 option. The pickups are prose brackets, not flag names; for example, Voidsworn Beat 2: "If you carry the hand: the saint's hand has grown warm in its casket". The six dead ones are as listed. | No longer true. Every Beat 1 choice has its own Beat 2 bracket and its own Beat 2 blue (REVISED). NOW also gives every one a Beat 3 echo (section 2, fix 2). Three flags were renamed in REVISED: `vesper_*` became `vs_*`, `ch_silence` became `ch_smell`, `dd_vengeance` became `dd_writ`. |
| Beat 3 reward shapes: three identical repair-20 against xp-20 pairs (Voidsworn, Hegemony reversed, Deathless); Chorus regrowth against weakness; Ithar xp against weakness; Corsair xp against credits | TRUE. Each pair checked in the original text. | Gone in REVISED. NOW changes Corsair again (fix 5). |
| Chorus header says "hunger, many-as-one, song, short lines" (line 109) while the body runs long | TRUE. ORIGINAL line 109 is word for word. Qwen's example ("The Chorus stirs in the dark between stars, and every throat aches with the same wanting", 20 words) is in Beat 1. | REVISED header: "sentences under eight words"; the Chorus no longer sings. NOW: no Chorus card sentence is longer than 9 words (fix 8). |
| Deathless crest "a crowned eye over a closed tomb door" (line 169); sample rival "Dynast Setekh the Patient" (line 53) | TRUE, both lines. | REVISED: "a crowned eye over a sealed vault door"; no sample names anywhere. NOW: "an open eye above a sealed vault door, a seal ring between them", with the crown removed from the crest drawing too (`godot/ui/career/crest.gd`). |
| Two sample rivals are women while the text hardcodes "he"; "learns his scent" and "He offers to return it" are in the document | TRUE. Lines 116 and 180. 72 plain he/him/his in the original. | REVISED: `{he}` `{him}` `{his}` tokens (tokens.gd: he, she, or it for a Chorus mind). The checker flags plain pronouns in cards. |
| The rival's deeds assume a humanoid in three scenes | TRUE. Line 23 "a message cut into the stone beneath it"; line 90 "sits in the front row smiling at you"; line 180 the crown "worn openly". | REVISED fixed the auction ("{His} fleet is parked off the rock") and the crown. It missed one, the Voidsworn stone: "with a line cut into the stone beneath it" (Muse spotted this too). NOW: "as plain as a promise: I will come back for this". The Deathless seal is "carried at the head of {rival}'s fleet". |
| No Beat 2 choice has a named flag | TRUE. | REVISED named all but one (Chorus "Dive and eat"). NOW: `ch_dove`. |

**Where I question the synthesis or a leg:**
- **"Six are never used again" is right for the original only.** Muse's check already shows REVISED reads every Beat 1 choice again at least once.
- **Argon's UNSURE on Corsair credits ("no shop or repair phase left to spend it on") is wrong for the code.** Beat 3 is shown as sector III begins. His fight sits at column 4 or earlier (`campaign_run.js nemNodeIs`: `n.col>=(RUN.map.cols.length-3)`). Column 5 is always a rest stop (`core.js:259`: `else if(c===COLS-2) type=pick(['shipyard','drydock','field'])`). Column 6 is the sector flagship, and the run ends only after it (`campaign_run.js:503`: `if(RUN.sector>=3){ endRun(true); return; }`). So credits at Beat 3 could be spent. The point is moot anyway: Corsair Beat 3 no longer pays credits.
- **DeepSeek fix 8 ("change the crests... 'Crusade' and 'Dynasty' are 40k-coded").** I changed the Deathless crest. I left the Voidsworn and Corsair crests: no leg named a specific 40k mark, and Rey marks the gear-jaw resemblance UNSURE with no source. Renaming the factions themselves is a data.js and Ryan decision, so I handed it to the rename work instead.
- **Rey fix 10 ("reserve the word choir for the Chorus") is not adopted, and the synthesis left it out of its 10.** The earlier blind pair said the opposite: three factions singing was the collision. Song now belongs to the Ithar ("The Glass Choir"), and the Chorus speaks in taste, heat and teeth. This is a direct conflict between reviewers; I followed the coordinator's round 2 must-fix list. The Chorus admiral "the Mending Choir" and stream B's Chorus name parts ("Hymn", "Choir", "Psalm") are data.js names, flagged below.
- **Muse's grade on fix 1 is LANDED. Mine for REVISED is PARTLY.** Muse's own mechanism note says the Table B hails "key off the shared counters... rather than off individual named flags". The fix asked for the rival to name the specific thing. NOW adds that line per arc (fix 1 below).

## 2. The ten fixes

Grades: ALREADY DONE (in REVISED f51fcf8), APPLIED (NOW, round 3), PARTLY, DISPUTED.

| # | Fix | Grade | Evidence (quotes) |
|---|---|---|---|
| 1 | Rival memory in words: a flag-keyed Beat 3 line per arc (thwarted and unthwarted), plus Beat 2 callbacks | **APPLIED** (REVISED was PARTLY) | REVISED: generic Table B hails by lean, plus `{rival_line}` pools. NOW, one thwarted/unthwarted pair per arc, listed first so it always shows. Voidsworn: "[If the bell answered you: {rival}'s line has not formed cleanly since the bell; {he} heard it across the whole sector.] [If it did not: the Ashen Vigil's bell now hangs in {rival}'s line, tolling for {him}.]" Hegemony: "{rival} has read your reprimand; somebody leaked it to {him}, and {he} has sent you a copy, annotated." Corsair: "[If {rival} lost face at Rattlehold: every crew in the dens knows it, and {he} knows they know.]" Chorus: "{he} limps. We bit {him} in the shallows. {He} remembers our teeth." Ithar: "{rival}'s flagship carries one shard of the Glass Choir on its prow, still screaming faintly." Deathless: "the stolen seal is fixed to {rival}'s flagship's prow, where every trespasser can see it." Beat 2 brackets now name the rival too, for example Hegemony: "{rival} has sent a copy of it back to you, unsigned". The same applies in all B variants. |
| 2 | Wire the six dead Beat 1 flags to a Beat 3 payoff | **APPLIED** (REVISED: every flag read in Beat 2; Muse: 4 of 6 reach Beat 3) | NOW, every Beat 1 choice pays in Beat 3. Voidsworn: the hand and sale brackets and blues (already done). Hegemony `hg_orders`: new blue "Call in the commendation (40 credits)... a Hegemony picket joins"; `hg_offbook`: win "The court-martial opened over the black box is quietly withdrawn", loss "proceeds in your absence". Corsair `cs_party`: the Mott blue now needs the party directly; `cs_rigged`: win "Somebody sends {rival}'s wreck a parcel with a bow on it." Chorus `ch_ate`/`ch_smell`: win lines "The split node tasted of {him}" and "The smell from the split node fades at last". Ithar `it_mercy`: bracket "far behind you, it is still humming its warning", plus blue "Ask the buoy to wake the archive". Deathless `dd_writ`: win "The writ is marked served", loss "The writ stays open, unserved"; `dd_patient`: win "The custodian's remains are entered as the session's first exhibit." The engine now shows up to three earned ending lines (arc.gd `ending()`). |
| 3 | Rename the sample rival Setekh | **ALREADY DONE** in the outlines (no sample names at all; 0 hits for Setekh, Petra, Ilyra). APPLIED in code: test and screenshot samples now use the proposed name. | **Proposed replacement** (Ryan can veto): **Justiciar Halvane the Unpardoning**. Title from the Deathless law register (Argon suggested "Justiciar"); a non-Egyptian name; the epithet carries the faction's motif, "a debt the Court cannot forgive". Keep it consistent with contrib/opus/compute/rename_map.md when it lands (not on main yet). The source of the problem is in data.js, not the outlines (section 4). |
| 4 | De-stack the Beat 2 blues | **ALREADY DONE** (Muse agrees) | REVISED. Each blue states its cost: "Lose the relic: the hand cracks in the striking"; "Every ship takes 10% hull damage in the gap"; "spend the commendation: 50 credits... Five are not"; "Your flagship captain loses 15 experience"; "Every ship takes 8% hull damage in the chase"; "The song is spent; the archive will not have it"; "costs a refit from the hold". |
| 5 | Beat 3 choices as story decisions tied to each arc's objects, labels in faction voice | **APPLIED** (REVISED mostly done; three gaps closed) | REVISED: hand or reactor; Hunger or Memory; archive or fleet; erasure or summons. NOW: (a) Corsair, which all four legs called the weakest beat. Qwen: "the choices ignore the rival's chained-fleet gambit". The new choice: **"Double shares. We go round the gold."** or **"Shoot through it."** ("Most of the gold goes into the star with {him}"). The win line follows: "There is not much left to split. The crews will tell this one for years, and not kindly." (b) Hegemony labels as spoken lines (Qwen fix 8): **"Name, rank and number. All of them."** / **"You are not required to be brave. Only correct."** (c) Deathless lawfulness (Rey fix 9): "the vault's honour guard, lawfully woken in defence of the Court in session, asks formally for its place in the line." |
| 6 | 40k distance pass | **APPLIED** (REVISED and Muse: PARTLY) | Deathless: custodians and bailiffs replace "warden" (6 to 0 in the main file); "A Deathless destroyer joins" replaces "jackal" (the unlock is renamed "Court guard destroyer"); the crest loses its crown; no tomb, dynasty or Dynast in the cards. Crusade: "heresy/heretic" 3 to 0 (REVISED); "confessor" 3 to 0, now **oath-readers**; "litanists" now **rite-keepers**; "shrine-moon" now **beacon-moon**; "cathedrals" now **iron lanterns** (Argon's own suggestion); "The litanists read it" now "Hear the oath". Saint, relic and Rite stay as the one borrowed register (Rey: "keep saint if the faction keeps only one borrowed register word"). The same pass in the line data (Rey names "the Voidsworn row of the rival voice table"): heretic, heresy and pyre go from 7 to 2 across rival_lines.json and voices.json. For example "One more heretic for the pyre." becomes "One more oath-breaker for the fire.", and Malek's "Heresy hides. I find it." becomes "Oath-breakers hide. I find them." The two kept: the enemy flagship's "Heretic. Kneel before the saints" hail and one "pyre" line. Inquisitor-Captain Malek's "Confession extracted" stays, since his title is a data.js name. Ithar: "elders" 5 to 0, now **the First Singers** (Argon); "younger races" was gone in REVISED. "Warlord" sample names: gone in REVISED. |
| 7 | Faction-safe rival deeds; pronouns as variables | **APPLIED** (REVISED mostly done; Muse found the one nit) | REVISED: Table A by faction and personality, plus pronoun tokens. NOW: the last humanoid line is fixed (Voidsworn "as plain as a promise"); the seal is "carried at the head of {rival}'s fleet". Table A is rebuilt on **stream B's actual personas**: data.js `NEM_FAC[fac].personas` gives four per faction, cunning, zealous, cruel, patient, proud, greedy, methodical, ravenous. My earlier proposal (proud, cruel, cunning, zealous, cold, mocking) is retired, which answers Muse's caveat that "pool coverage depends on stream B emitting those ids". `test/check_personas.py` reads data.js and checks the match. |
| 8 | Chorus voice pass on the longest body sentences (scoped) | **ALREADY DONE**, finished NOW | REVISED rewrote the Chorus in sub-8-word lines. NOW split the last five 10 to 11 word sentences. Example: "{rival} stands in front of it, between us and the meat." becomes "{rival} stands in front of it. Between us and the meat." No Chorus card sentence is longer than 9 words. Not a rewrite: the scope set by the synthesis. |
| 9 | Specify the Chronicle: entries record the run's flags | **APPLIED** (REVISED: plumbing only, as Muse notes) | Spec in outlines.md ("What a Chronicle entry records"): faction and arc, the rival's full name and faction, the three choices in their own words, won or lost, first lost ship, title earned. Code: arc.gd returns option labels; `story.arc_chose` stores the label; `career.record_arc_end` adds `said`, `first_lost` and `rival_fac`; the Career screen's Chronicle tab prints them. |
| 10 | Name the Beat 2 flags in the draft | **APPLIED** (REVISED 53 of 54, Muse agrees) | `ch_dove` added to "Dive and eat". Muse's side note (both Hegemony rescues write `hg_broke`) is intended: Beat 3 only needs to know the column was saved. |

**Not disputed, but different in degree:** none of the ten fixes is disputed. The divergences are Rey's "choir" item (not among the 10) and DeepSeek's crest and faction-name item (handed to the rename work); both are explained in section 1.

**Compared with Muse's check:**
- **The three PARTIALs (2, 6, 10):** all finished now, with the same remedy Muse describes.
- **The two nits** (the Voidsworn stone line, the crowned crest): both fixed.
- **One small factual difference.** Muse lists "confess" 4 times, including "which sin you will confess". That phrase is the Voidsworn's own dilemma line and stays; the three "confessor" role mentions are gone.

## 3. The three open code questions, answered from the code

**Q1. Can a Chorus commander be the Nemesis? YES.**
- The run's foes are every faction but your own, shuffled. JS: core.js:322, `foes:shuffle(RUN_FACTIONS.filter(f=>f!==fac))`. Godot: campaign.gd:945, `var foes = shuffle(RUN_FACTIONS.filter(func(f): return f != fac))`.
- The Nemesis takes `foes[3]`. JS: campaign_run.js:246, `const fac=(RUN.foes&&RUN.foes[3])||...`. Godot: campaign.gd:1516 `newNemesis`, ported by G3 in 34d1bfa.
- Stream B's R42 `NEM_FAC.chorus` has titles "Matriarch", "Elder Throat", "Hive-mind", "Brood-queen", so fix 7 was required.
- **Side fact:** sectors I to III use `foes[0..2]` (core.js:250, `RUN.foes[s-1]`), so the Nemesis's faction is never one of the three sector factions you fight.

**Q2. Does anything follow Beat 3? YES. And Beat 3 does not always end him.**
- **The run goes on:** Beat 3 shows as sector III begins. His fight is at column 4 at the latest. A rest stop (shipyard, drydock or field) and the sector flagship follow, and the run ends only on that flagship (citations in section 1).
- **He can survive sector III** (campaign_run.js:279-286 `nemAfterBattle`):
  - he flees: `if(o.fled){ ... out.push(... breaks off and runs ...)`;
  - a Deathless rival reassembles once: `else if(flagDead&&beh.revive&&!N.revived){ N.revived=true; ... if(RUN.sector>=3) N.met=RUN.sector-1; ...` (he comes for you again in sector III);
  - he withdraws when his flagship survives: `else out.push(... withdraws to fight another day.)`;
  - only `else if(flagDead&&RUN.sector>=3){ N.dead=true; ...` ends him.
- **What I changed:** outlines.md now closes the arc on his sector III fight (on the second fight if he reassembled). A win where he escapes still finishes the arc and adds one line in your faction's voice ("If he escaped" list under "How an arc works"). The README states this rule for the arc-end hook.

**Q3. Does the built game add variation beyond the outlines? YES, in design and in plumbing; outcomes stay fixed.**
- Two versions of every beat: outlines_variants.md, with arc.gd `pick_variant` preferring the one this profile has seen less.
- Calling cards by his faction and persona (24); his lines picked from pools by a stable hash of his name, the moment and a seed (rival.gd; presentation only, never the rules PRNG).
- Conditional lines from flags and run facts; skim cards after two finished arcs; Chronicle callbacks across runs.
- Choice outcomes are fixed and stated, as in the event system today; there are no hidden dice.
- The per-faction arc files (`godot/story/data/arcs/<faction>.json`) are built only after Ryan's read, as the B5 gate requires.
- **While checking, I fixed a variety bug:** rival.gd's hash took its "one of two" pick from a low bit that follows the characters' parity, so personality hails never mixed with the faction pool. It now has a final mixing step; the test went from 4 to 7 distinct first-meeting hails over 60 generated rivals.

## 4. Handed to stream B (rename map and Nemesis fields), with evidence

- **R42 name tables in data.js sit closer to 40k than the outlines ever did.** `NEM_FAC.deathless.titles: ['Phaeron','Dynast','Tomb-lord','Overlord']` ("Phaeron" is a Necron rank); name parts `pre:['Ankh','Sekh',...,'Seth']`; scar epithet 'Cracked-Crown'. `CAPTAINS.deathless.ranks` include 'Cryptlord','Overlord','Dynast', and names include 'Setekh'. Voidsworn Nemesis parts: 'Inquisitor','Confessor','Arch-confessor','Lord Inquisitor'. Chorus parts: 'Hymn','Choir','Psalm' (this conflicts with the de-songed Chorus). Also 'Hive Leviathan', 'Gauss flayer', 'Doom arc', 'Wraithbone', 'Shuriken cannon', the Las- weapons and 'Hellfire torpedo' (reported earlier).
- **The sample replacement for Setekh** should follow the rename map: Justiciar Halvane the Unpardoning, or whatever Deathless naming the map settles on.
- **Persona ids (settled Oct 26 with the coordinator):** stream B keeps its `persona` field and its eight ids; the story pools follow them, checked by `test/check_personas.py`. A request to switch stream B to this stream's earlier six ids was cancelled, because those ids also key the battle AI weights (`NEM_PERSONA[...].ai`).
- **Still asked on `RUN.nem`:**
  - a gender field `g`;
  - `persona`, `beat`, `epithet`, `beaten` and `scars` carried into the battle's `B.nem`;
  - a `nem_signature` battle event.
- **The story pools already read** `persona`, `beat` and `epithet`, and replace the `NEM_LINES` placeholders data.js labels "until the story helper's rival line pools arrive".

## 5. What Ryan reads next

godot/story/outlines.md (REVISED round 3) and outlines_variants.md. His per-faction read of this text is the gate before the arc files are built.
