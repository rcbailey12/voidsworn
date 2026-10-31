Red Team Audit Report: Narrative and Lore Seat
Game: Voidsworn, "Embers of the Hollow Sun"
Seat: Story, text, tone, lore consistency
Date: October 31, 2026
Pack pin: main head b3a3b802, browser build 264f441d

Finding 1: The Nemesis does not speak your history back to you
Severity: CRITICAL
What breaks: The game's central narrative promise is a Nemesis who "hunts across the run and adapts between meetings." The story outlines deliver a rival whose hail, last words, and gloat are fixed per faction. Nothing the rival says changes with what the player chose in Beats 1 and 2. The adaptation is mechanical only; the fiction is a recording.
Evidence (OBSERVED): The synthesis states: "His hail, last words and gloat are fixed per faction; nothing he says changes with what you did in beats 1 and 2." All four audit inputs independently ranked a flag-keyed rival line at or near the top of their fix lists. The machinery already exists: "Beat 2 bodies carry flag-conditional sentences about the player's fleet."
Cost: In a roguelite where 80 percent of runs are lost by design, the Nemesis is the thread that stitches losses into a story. A rival who cannot say "you ran from me at Vesper Gate" or "you sacrificed the Harrow to save your carrier" is not a character. The player learns the adaptation is a stat block, not a grudge. The emotional engine of the run goes silent.

Finding 2: Beat 3 is the least argued moment in every faction arc
Severity: HIGH
What breaks: The finale of every faction arc, the narrative climax, is structurally the weakest beat. Three of six endings are the identical reward pair. The choice at the end of a three-beat arc, where the player should feel the weight of their faction's identity, is a resource trade with no dilemma.
Evidence (OBSERVED): The synthesis records: "three of the six finales are the identical pair, repair 20 percent against captain experience 20." DeepSeek calls Beat 3 "the weakest in all six." Argon, Qwen, and Rey converge from different angles: "resource trade with no dilemma, generic choice labels, a promise the coda does not honour."
Cost: A player who survives a full arc reaches the climax and receives a menu, not a culmination. The faction voice that was "distinct enough to identify blind" in Beats 1 and 2 flattens into a repair voucher. The final impression of each arc is mechanical, not mythic. For a game whose meta-progression depends on the player wanting to run the same faction again, the ending must be the hook, not the receipt.

Finding 3: Half the Beat 1 branching is dead fiction
Severity: HIGH
What breaks: Twelve Beat 1 flags exist in the outlines. Six are picked up narratively in Beat 2. Six are never referenced again. The player's choice in Beat 1 produces a flag that the story never acknowledges, never consequences, never remembers.
Evidence (OBSERVED): The synthesis names them exactly: "Six are never used again (vesper_sold, hg_orders, cs_party, ch_ate, it_mercy, dd_vengeance)." This was mapped independently by Argon and the Rey review. The document is explicit: "Each of the 12 Beat 1 flags appears exactly once in the document, at its Beat 1 option."
Cost: A roguelite sells replayability through the promise that different choices yield different stories. When half the opening branches lead nowhere in the text, the player who chose "sell the vessel" and the player who chose "keep the vessel" receive the same Beat 2, the same rival, the same ending. The branching is decorative. On a second or third run of the same faction, the player will notice the flag they chose is never spoken of, and the fiction collapses into a single rail.

Finding 4: The Chorus rival cannot exist as written
Severity: HIGH
What breaks: The outlines script at least three rival scenes requiring a humanoid actor: sitting in an auction's front row smiling, wearing a stolen crown openly, cutting a message into altar stone. The Chorus is a swarm. The outlines' own Chorus text states the swarm "does not answer in words." These scenes are lore-impossible for a Chorus-faction run.
Evidence (OBSERVED): The synthesis records: "The rival's scripted deeds assume a humanoid actor in at least three scenes... which cannot be true of a Chorus swarm rival." Argon found all three; the Rey review found two of three. The Chorus faction description in the bible r8 confirms: "One hungry swarm, coming to the Sun."
Cost: If a player runs the Chorus arc and the rival sits smiling in an auction house, the fiction breaks completely. The Chorus is the faction most defined by its alienness, the one that "consumed its makers." Giving it a humanoid rival in a chair contradicts the core concept. This is not a tone adjustment; it is a scene that cannot be written as outlined for one of six factions.

Finding 5: Faction rank tables leak across every faction at the UI surface
Severity: HIGH
What breaks: Promotion notices, blue-option requirements, and the shipyard lede all read the Crusade rank table instead of the faction's own rankName. A Glasswright captain is announced as promoted to "Commander." Events demand "a Captain or better" in factions that have no Captain rank.
Evidence (OBSERVED): The text synthesis states: "a Glasswright captain is announced as promoted to 'Commander' and an event demands 'a Captain or better' in factions with no Captain." This is Argon-found and chair-verified. The Crusade rank list in the bible r8 reads: "Lieutenant, Commander, Captain, Commodore, Fleet captain."
Cost: The Glasswrights are "few, long-lived, grieving masters of light, optics and crystal." The Chorus is a swarm. Neither has a naval rank structure that mirrors the Crusade. When the game tells a Glasswright player they have been promoted to "Commander," the faction voice dies at the moment of player reward. Promotion is a dopamine beat; getting the noun wrong there is getting the fiction wrong at the exact moment the player is most attentive to it.

Finding 6: The 40k shadow is concentrated and unresolved
Severity: MODERATE
What breaks: Two factions read as Warhammer 40,000 pastiche in specific beats. The Deathless (now Eclipse) cluster hits the Necrons: tomb, crown, warden, long sleep, contempt. The Crusade cluster hits the Imperium: heresy, confessors, litanists, shrine-moon density. All four inputs flag the same two locations.
Evidence (OBSERVED): The synthesis states: "All four inputs clear Hegemony and Corsairs, rate Ithar low, and put the risk in the same two places." The remedy direction is agreed: "lean on each faction's own obsession... and thin the borrowed furniture." The bible r8 still lists Crusade motifs including "oath brands" and ship names like "Debt of Vesper," which are the faction's own, but the density of borrowed ecclesiastical language in the drafted beats remains.
Cost: The Crusade's voice in the bible is strong and specific: "a whole frontier's fleets under one oath, proud, tired, stubborn and desperate." That voice does not need confessors and litanists. Every borrowed 40k noun is a slot where a Crusade-specific noun should live. For a game building six distinct faction identities, two of them carrying visible IP fingerprints weakens the set's claim to originality and invites comparison the game cannot win.

Finding 7: The help screen teaches the player a wrong game
Severity: MODERATE
What breaks: The help screen, the first place a new player builds their mental model, contradicts the game on four points. The availability claim is false against renown costs and LEGACY gates. The shipyard-after-flagship promise describes a flow that does not exist in code. The aspects count and rarity list omit the fourth tier.
Evidence (OBSERVED): The text synthesis records: "The availability claim (campaign_meta.js:150) is false against renown costs and LEGACY gates and is contradicted by the unlock text on the same screen." Also: "the aspects count and the rarity list (line 167) both omit the fourth tier the game ships." This is the audit's top-ranked fix batch.
Cost: A new player in a roguelite where run 1 is near-impossible by design needs the help text to set accurate expectations. When the help says a system is available and it is not, or lists three tiers where four exist, the player's first model of the game is a lie. In a game that teaches through loss, the player must trust that the text is honest about what they are losing and why. A wrong help screen poisons that trust before the first battle starts.

Finding 8: The rival's gender is hardcoded male in a system that rolls both
Severity: MODERATE
What breaks: Two of the bracketed sample rivals in the outlines are women (Petra Lindqvist, Ilyra Glasswing). The rival text across all beats hardcodes male pronouns. The Nemesis name system carries both masculine and feminine name lists. Half of all Nemesis rolls will produce a "she" who is called "he" in every scripted line.
Evidence (OBSERVED): The synthesis states: "Two bracketed sample rivals are women (Petra Lindqvist, Ilyra Glasswing) while rival text across the beats hardcodes male pronouns." Specific lines cited: "learns his scent" and "He offers to return it." The assembly notes confirm: "the Nemesis's gender varies by roll (NEM_FAC carries masc and fem name lists)."
Cost: The Nemesis is the narrative through-line of the entire run. If the player's Nemesis rolls a feminine name and every hail, gloat, and death line says "he," the fiction breaks on a pronoun. This is not a cosmetic issue; it is a first-pass error on the most repeated character in the game. Every assembled Nemesis line in the additions pack is pronoun-clean, which makes the outlines' hardcoding a known regression.

Finding 9: The Chorus voice rule contradicts its own drafted text
Severity: LOW-MODERATE
What breaks: The Chorus arc header in the outlines defines the faction voice as "hunger, many-as-one, song, short lines." The Chorus body prose includes long descriptive sentences that violate the "short lines" rule. The stated voice and the executed voice are in conflict within the same document.
Evidence (OBSERVED): The synthesis records: "The Chorus arc header states its voice as 'hunger, many-as-one, song, short lines' (outlines line 109), while Chorus body prose includes long descriptive sentences." Qwen's premise is confirmed by the chair. The bible r8 describes the Chorus as: "One hungry swarm, coming to the Sun."
Cost: The Chorus is the faction most dependent on voice to sell its alienness. If the design document says "short lines" and the drafted text delivers paragraphs, the writer working from this document will produce inconsistent Chorus text across events, tutorials, and battle lines. The firstrun framing for Chorus already navigates this tension carefully; the outlines' own prose undermines the rule that makes those framings work.

Finding 10: Voice family leaks across faction boundaries
Severity: LOW-MODERATE
What breaks: Multiple text surfaces break faction voice by cross-contamination. Chorus Nemesis lines appear in first person (the Chorus is many-as-one; first person singular is wrong). Shared Nemesis lines appear in Glasswright and Hegemony mouths. Events address the Chorus and Eclipse as human crews. The Hullbreaker tracker uses "smelling," which is a Chorus motif, contradicting the bible r8 trail-and-sound ruling for Hullbreakers.
Evidence (OBSERVED): The text synthesis lists: "Chorus Nemesis lines in first person (shared with the admirals audit), shared Nemesis lines in Glasswright and Hegemony mouths, events addressing Chorus and Eclipse as human crews, the Hullbreaker tracker smelling (Chorus motif against the r8 trail-and-sound ruling)." Also flagged: "nekhet 'regrow', 'prow gun' and 'its guns' wording."
Cost: The four-input story review's strongest praise is that "faction voices are the set's strength" and "All four inputs identify factions from vocabulary alone." Every cross-contamination erodes that strength. A Hullbreaker who "smells" the enemy is borrowing the Chorus's sensory register. A Chorus Nemesis speaking as "I" instead of "we" or "the song" breaks the many-as-one conceit at the moment the Nemesis should be most alien. These are small leaks, but they compound across 41 Nemesis lines, 33 events, and 216 tree texts.

Verdict
REGISTER: The fiction's architecture is sound and the faction voices are the strongest asset in the pack, but the narrative layer that should make the Nemesis feel personal and the endings feel earned is not yet written into the text. The single most important attack: the rival speaks the same words regardless of what the player did, which means the game's central narrative promise (an adaptive hunter who remembers you) exists only in mechanics and never in language.

Not checked
The 216 tree texts (tiers 1-3), 33 event variants, and 16 tutorial tips were not read line-by-line in this pack; their individual voice compliance is unjudged here.
The Godot migration tree's story and text files (godot/story/) were not excerpted in the pack; lore parity between browser and Godot text cannot be assessed.
The Chorus admiral portraits (Matriarch v2, Voice of the Deep, Mending Choir v2) were not examined; the reword-vs-regenerate call remains open per the synthesis.
The Eclipse battleship entry (d_meridian vs d_wraith) is listed as left to Opus and was not in the pack's evidence; its lore fit is unjudged.
Audio, music, and sound design text (sfx.js, sfx_data.js, godot/audio/) were not examined for voice or tone compliance.
The full rename_map_final was excerpted only in section 14 ("Looked at and kept"); applied rename rows and their in-code landing were not re-verified in this pass.
Whether the Argon prong for event variants and Nemesis lines, still outstanding at assembly time, introduces new voice defects.
