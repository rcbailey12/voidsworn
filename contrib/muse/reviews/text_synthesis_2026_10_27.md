Chair synthesis: player-facing text quality audit (Oct 27 program item 2). Four blind legs on the same pack pinned to 68b42ce406286eb95ea7df6aaf3f683c1231b51d: DeepSeek (not ready as player-facing copy; BLOCKERs in help text, hangar wording, Deathless Nemesis card), Qwen (the pack is "in strong shape", two BLOCKERs), Argon (FAIL, ten BLOCKER tags), and Rey (this chair's own leg, verified core only). The spread between Qwen's verdict and the other three is itself a finding, addressed under leg weights.

OVERALL VERDICT: NOT READY as player-facing copy, with no BLOCKER surviving at that weight. The round 8 rename landed cleanly in the data tables; what failed is everything around them: a help screen that contradicts the game on four points, purchase surfaces that name weapons differently from the cards the player keeps, variant cards that silently remove weapons, one event whose promised repair targets the wrong ship, and a scatter of card-accuracy and voice defects. Ranked fix batches below; most are one sitting of text work, two need small code changes (shipwright targeting, flags comparison, shared with the events synthesis).

FIX BATCHES, RANKED

1. Help screen rewrite (all chair-verified). The availability claim (campaign_meta.js:150) is false against renown costs and LEGACY gates and is contradicted by the unlock text on the same screen; the shipyard-after-flagship promise (line 151) describes a flow afterBattle does not contain; the aspects count and the rarity list (line 167) both omit the fourth tier the game ships. DeepSeek found this family; it is the audit's top batch because help text is where a new player builds their model of the game.

2. The shipwright repair (Argon, chair re-verified in campaign_run.js). The text promises a second ship fully repaired; the index arithmetic heals the wrong one (details in the Rey leg). One code fix; the text is already right.

3. Purchase-surface naming (Argon). Shipyard and Hull Variant cards render base weapon names while ship cards render faction names, and variant description prose does the same ("Turret laser" for Plasma cannon). The h_picket_i instance is confirmed by two legs; the render-path claim is Argon's, flagged for Opus to confirm while fixing.

4. Variant cards that delete weapons silently (Argon, first case chair-verified). Four variants whose descriptions omit a removed weapon or ability. The Turreted zenith case is verified line by line; the other three are table-verified as data.

5. Crusade RANKS hardcoded for all factions (Argon). Promotion notices, blue-option requirements and the shipyard lede read the Crusade rank table (RANKS) instead of the faction's own rankName, so a Glasswright captain is announced as promoted to "Commander" and an event demands "a Captain or better" in factions with no Captain. Code-side fix, text-visible everywhere.

6. Flags, from the text side (events audit finding 1, chair-confirmed). Five descriptions promise choice-specific unlocks the mechanism grants on any outcome. Recorded in full in the events synthesis.

7. Card accuracy family (three-leg convergent across two audits). Hidden sqHp:.25 on five carrier admirals; vaelen's global aim scoped to lances in text; kassar's damage called accuracy; undefined mechanic names in the verbs ("synchronized fire" with no stated baseline, "Archive restore" named nowhere else); weapon trait descriptions omitting their numbers (Qwen and Argon converge almost item for item: las, hellfire, scrap, needle, star plus the pickets wing perk). One pass over cards and traits.

8. Carriers-versus-launch wording (DeepSeek, chair-verified). "Carriers only" on a module keyed to launch ability, with a cruiser and a battleship carrying that ability; same error in the launch ability text and the Hegemony blurb.

9. Nemesis card and pronouns (DeepSeek, chair-verified in part). The Deathless card's "He never retreats" against a behaviour object with no noFlee and a known escape outcome (26c prior art); the hardcoded "His fleet is coming" panel line bypassing nemSay.

10. Voice family (Argon-led). Chorus Nemesis lines in first person (shared with the admirals audit), shared Nemesis lines in Glasswright and Hegemony mouths, events addressing Chorus and Eclipse as human crews, the Hullbreaker tracker smelling (Chorus motif against the r8 trail-and-sound ruling), nekhet "regrow", "prow gun" and "its guns" wording, the undefined "Archive restore". L-lane judgement calls, grouped for one pass.

11. The retired "Legacy" pointer (Argon). Locked admiral cards direct the player to unlock "in Legacy", a screen renamed Progression, behind which the purchase buttons do not exist (an independent Oct 22 audit found buyAdmiral and buyLegacy have no UI). The pointer and the missing UI are one fix.

SMALL CONFIRMED ITEMS (single pass, no discussion needed): "6 more harder to hit" (data.js:484, three legs); "Bigger crew" describing a fleet-size effect (data.js:482); "the Eclipse" produced by the endRun recap against the no-"the" ruling (Argon 1.4, new instance of a ruled fix); the starlight blurb itself is already ruled and sits in the item 9 pack; Eclipse green is kit-confirmed; "Acceptable Loss" in the Crusade ship pool is flagged as a voice candidate for the same treatment as Thornback and Moonveil, Ryan's call if he wants it (question 1).

WHAT DISSOLVED

- Argon's decommission price mismatch: the button label formula and prizeScrap agree for every priced hull (both are cost times .35 via shipValue); the divergence exists only for cost-less hulls, where the label computes NaN. That residue joins the kit audit's unpriced-hull NaN family at the same line (campaign_run.js:174).
- Qwen's pronoun clearance: nemSay works where applied, but the hardcoded panel line is a verified counterexample, so the blanket PASS does not stand.
- Qwen's completeness claims generally: its "all other names match exactly" and "all other numbers match" verdicts are contradicted by the chair-verified findings above. Its pack was identical to the other legs'; the misses are depth, concentrated in the campaign files' behaviour rather than the data tables, which it read closely and well (traits, duplicates, internal keys all sound, and its check 2 PASS independently confirms the item 1 sweep).

LEG WEIGHTS

Argon was this audit's strongest leg (the shipwright bug, variants, RANKS, purchase surfaces) under its usual tag inflation. DeepSeek found the help family, the launch wording and the Nemesis card, the findings a new player would hit first. Qwen corroborates the data-table layer and contributes one original NOTE (help's generic 10% rake against the Voidsworn 40%). The chair's code verifications settled every dispute the legs raised between themselves.

QUESTIONS FOR RYAN

1. "Acceptable Loss" in the Crusade ship name pool: same treatment as Thornback and Moonveil (swap it out), or acceptable as gallows humour in a Crusade pool? Voice call only; no defect either way.
2. No other human-direction questions arise from this audit. The help rewrite, naming passes and card fixes are Opus's work within recorded rulings.
