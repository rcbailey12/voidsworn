# The three-way council reconciliation

Chair: Rey (external POV). Sources: Rey's council (contrib/muse/reviews/council_audit.md and council/), DeepSeek's council (extracted at contrib/deepseek/reviews/), Qwen's council (contrib/qwen/council_audit.txt). All three ran blind from the same packs at HEAD 51337c2; the two external councils had never seen Rey's. This document aligns them lens by lens. Screening note: the chair spot-checked a sample of citations against the code (results at the end). Nothing here is a verdict on the code; contested or single-source claims are Opus's to confirm or kill.

## The headline

The councils agree far more than they disagree, and they agree most on the things that matter most. Four findings carry all three families. The two external models were better at hunting fresh instances inside big files; Rey's council was better at longitudinal checks (re-verifying old findings at the new HEAD) and at quantification (the census and sim evidence neither external pack contained). The blind design worked: convergence here is evidence, not echo.

## Consensus: all three families

1. **The save-brick class.** Rey: a renamed hull or admiral id bricks the campaign save (QA N1). DeepSeek: the same class three times over, hull template (core.js:180), relic id crashing the map screen, and a captain object with no name crashing ship creation. Qwen: the v1 migration never initializes m.stats, crashing the title screen. Four mechanisms, one lesson: load-time validation checks shapes, not membership, and any renamed id is a landmine. This is now the best-attested bug class in the game.
2. **The architecture.** One concatenated global script, load order as the API, cross-file monkey-patching as the extension mechanism (top findings of all three engineer lenses, nearly in the same words). All three also found the harness drift: the simulator duplicates the game's fleet tables and bot (DeepSeek E5/E9, Qwen E3, Rey E5), and the build check and smoke check disagree about what they scan (DeepSeek E7, Qwen E4, Rey's check pack).
3. **The fiction.** Patrons are never explained (all three sci-fi lenses, plus Rey's gamer lens). The borrowed vocabulary is verbatim, faction by faction: all three mapped Voidsworn to the Imperium, Ithar to the Eldar, Deathless to the Necrons, Chorus to the Tyranids and Hegemony to Star Wars, citing overlapping term lists. Admirals are renamed copies of shared commands (DeepSeek S8, Rey's asymmetry work, Qwen's asymmetry audit).
4. **The new-player wall.** The first run front-loads its hardest permanent decisions before any battle (Rey G3, DeepSeek G1, Qwen G2), the economy starves early purchases (Rey G8, DeepSeek G3, Qwen G1 and G7), and the teaching is a text wall plus eight tip cards (Qwen G3, DeepSeek G9).

## Pairs: two of three

- **The shield colour contradiction.** Rey (designer 5) and DeepSeek (designer 1) both found fx3d.js stating a colour law and breaking it in the next breath, including the Corsair red shield colliding with enemy IFF red. Qwen missed the law but found the wider disease (below).
- **Palette dual sources.** All three designer lenses found faction colour defined twice with different values; DeepSeek and Qwen between them produced six concrete hex mismatches across data.js, ships3d.js and fx3d.js (trims, hull shades, emblem glows). Rey found the same two-sources problem from the docs side.
- **Dead Legacy.** Rey's gamer lens (dead and hidden systems) and DeepSeek's QA (LEGACY upgrades exist, newRun checks them, and no screen sells them: buyLegacy has no button). Two routes to the same dead system.
- **Cloud sync eats progress.** Rey QA N3 (settings never cloud-stamped) and Qwen QA 2 (cross-device meta sync can wipe legacy unlocks). Different fields, same sync design smell.
- **Flagship state goes stale.** Rey QA N2 (aspect dies silently with the flagship) and DeepSeek QA 2 (decommissioning the flagship leaves flagUid stale). 
- **The Command trap.** DeepSeek G6 and Qwen G8 independently: the Command is weakest exactly when a new player will use it, and the game itself warns that waiting may waste it.
- **One UI costume for six factions.** Rey designer 6 and DeepSeek designer 6 (a Gothic skin frames bio-swarm, sail and tomb factions alike).

## Unique finds worth the owner's attention

From **Qwen** (its QA lens was the sharpest single lens of the three councils):
- The Alternating-mode guard bypass (ui3d.js:410): the direct-fire path calls guard(s) and ignores its return, so a player can fire with an inactive ship. The chair spot-checked this one against the code: the quote and the contrast with the neighbouring move path (which does check the return) are exactly as Qwen describes. Player-facing, rule-breaking, and found by nobody else.
- Blink commits its position before the animation resolves, so a stalled blink teleports for free (battle.js:944). Pairs thematically with Rey's stall findings but is its own bug.
- The watchdog clears B.busy on a player stall but leaves B.activeUnit locked, softlocking ship selection until the player forfeits the turn (ui3d.js:667).
- Reward flow state passed through window._* globals (engineer 9), and data.js mutating its own tables at load (engineer 7).

From **DeepSeek** (its QA lens enumerated instances nobody else reached):
- A captured boss can join the player fleet, with NaN sell values and command points blown past the cap (QA 3). The most entertaining bug in any of the three councils, and a real one if it confirms.
- The zero-fleet win converted into a recorded loss (QA 6), towing salvage ignoring the CP cap (QA 7), a Nova cooldown consumed by an abandoned cast (QA 8), and reserve captains silently overriding event mercenaries (QA 10).
- Two structural engineer finds: the game runs two independent stat pipelines, makeUnit for enemies and derive for players (E4), and a dead duplicate COMMANDS table that looks editable and does nothing (E6). Also: the test build loads a local Babylon while the shipped game loads the CDN copy (E8).
- Designer: the Rare rarity colour and the shield colour are the same hex, #62ccff (chair-verified against fx3d.js:4 and data.js:386). Sci-fi: the word "crusade" in the patron text contradicts the per-faction run words defined 100 lines away; "The Choir" names a patron, an admiral and nearly a faction; "HNS" is never expanded; "Iron" is spent on five unrelated things.

From **Rey** (the home council's edges were history and measurement):
- Longitudinal verification: five previously reported bugs re-checked at HEAD and confirmed still open, which no blind external could do.
- The sim evidence: the admiral pick as a hidden difficulty dial (38% to 98% sector-1 boss win rates) and the sector-2 elite wall. Neither external pack contained run data, so neither could see balance as measured rather than reasoned.
- The borrowed-term census with counts (cogitator 13 uses, wraithbone 3) and the variant-hull census (12 of 45 same-stat swaps), from the strings corpus and content census.
- Art-direction state: the blank brief, one finished ship of 36, and Ithar sails existing on exactly one hull.

## Contested and suspect

- **Qwen designer 1** claims an unclosed #app CSS block in head.html swallows the global body rule for 74 lines. The chair flags this as the one probable misread of the three councils: the game is played daily and renders, and CSS nesting makes the true parse subtler than the claim. It is also the cheapest claim in the set for Opus to kill or confirm with one look.
- **Deathless reanimate** (from the asymmetry audits): DeepSeek reports the rule already exists on Deathless hulls; Rey treated a return-from-wreck rule as an engine ask. Factual, decidable, Opus's.
- Qwen designer 2 (HULLFX_STYLE styles 4 and 5 unimplemented) is stated flatly and is one grep from settlement either way.

## What the comparison itself proved

- Three unrelated families, given the same text blind, produced the same architecture verdict, the same fiction verdict, the same new-player verdict and the same bug class at the top of QA. Where a finding carries all three, it should not need a fourth opinion before it is sequenced.
- The families' failure modes differ, which is the point of running them: Qwen overreached once on CSS parsing; DeepSeek stayed closest to the text and enumerated the most instances; Rey's council reasoned from history and data the packs did not contain. Nobody hallucinated a file or a system wholesale; the junk rate across roughly 140 external findings is one probable misread.
- Single-source findings are leads, not conclusions, and the best of them (the Alternating guard) survived a chair spot-check. The right pipeline is the one now in place: externals generate, the chair screens and aligns, Opus rules.

## Suggested sequencing (chair's view, for the owner and Opus)

1. The save-brick class, all instances (three families, five mechanisms).
2. The Alternating guard bypass (single source, spot-verified, breaks a core rule in the default mode).
3. The LEGACY UI route (two families; the system exists and is unreachable).
4. Palette single source of truth plus the shield law fix (three designer lenses; also the Gemini visual pack's starting point).
5. The patron paragraph (three sci-fi lenses; one page of writing unblocks fiction, onboarding and the admiral generation work).
