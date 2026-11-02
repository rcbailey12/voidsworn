# Admiral skill trees, Phase 1: index and chair synthesis

Board issue 31. Brief: contrib/muse/design/progression_plan_2026_11/synthesis.md, section 3, Authorship note, and the skill tree docs it builds on. Deliverable: the finalized Phase 1 tree texts for all six factions.

Verdict: GO. Phase 1 is complete: 216 texts (24 admirals x 8 Branch A and capstone texts = 192, plus 6 factions x 4 shared tier 1 texts = 24), each with its effect stated in game terms checked against data.js and core.js vocabulary. The Glasswrights file is complete first, as the brief requires, so Step 2 (issue 19) can start from it.

## Files

- glasswrights.md: Tamsa of the Clear Aperture, Saro of Long Focus, Vell of the Third Mirror, Brin of the Fourth Lens, plus the shared Glasswrights tier 1 sets.
- sunward_crusade.md: Roderic Vex, Malek Draven, Sera Ashgrove, Oryn Thale, plus shared sets.
- hegemony_navy.md: Ilsa Kassar, Dace Vorn, Corin Reyes, Oskar Maren, plus shared sets.
- ashfall_hullbreakers.md: Grax Ironmaw, Sable the Smiling Knife, Old Mott, Vesh the Collector, plus shared sets.
- the_chorus.md: The Matriarch of Nine Throats, Razormaw, Mending Throng, Voice of the Deep, plus shared sets.
- eclipse.md: Nadir Aurex, Umbra Vessane, Ostrel of the Long Copy, Seveth Twice-Restored, plus shared sets.
- legs/: the four leg reports this finalization merges (Rey blind leg, DeepSeek, Qwen, Argon with chair header), filed as the record.

## What this pass was

A complete Phase 1 draft already existed (contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md, assembled Oct 29, 2026 from three drafts; the Argon prong never landed for that assembly). Issue 31 is the verification and finalization pass over that draft against data.js, core.js, the lore bible, and the rename map. The chair took the blind Rey leg as the spine (it was the only leg to rule every pack open item in line) and adopted fixes from the other three legs where they caught something the spine missed or converged independently. Every departure from the assembled draft is recorded in a Changes line in the faction files.

## Splits settled by the chair

1. Brin capstone 1: three different answers (Rey: reflected accuracy penalty during the ward; DeepSeek: Ward Before the Hit, a timing declaration; Qwen: kept the draft two round duration). Chair: Rey version. The Wall family keeps exactly one duration capstone (Thale), and a timing declaration is weaker than a live penalty the enemy plays around.
2. Reyes capstone 1: Qwen concentration (One Target, Every Wing Filed) adopted over the draft return strike, which DeepSeek and the Rey leg kept. Qwen and Argon independently re-chassised this slot; the chair followed the convergence.
3. Voice capstone 1: kept as The Volley That Grows (Rey and Argon). Qwen shield bypass version (The Acid Eats the Shield) not adopted: the conditional hit trigger already separates it from a second Command use, and shield bypass at volley scale is a bigger balance lever than this pass should introduce.
4. Vorn capstone 1: kept as Interdiction, Permanent File in the three leg form (bonus repeats next round). Argon guaranteed crit replacement not adopted: three legs converged on the shipped form, and guaranteed crits on torpedoes stack with the T3 system crit in a way none of the legs measured.
5. Vex capstone 2: kept as The Last Account. Argon alone flagged it as a rule 6 combination of the two T3 slots and proposed a dual arc ignition replacement using a key the pack vocabulary does not contain. Recorded as a dissent for Opus; the slot stands.
6. Umbra capstones: kept in the Rey form (Noon That Does Not Pass as the Volley family one strict second use; One Sun, Copied). Argon mark and line of sight relay replacements not adopted: the relay needs a targeting hook no other leg asked for, and its mark duplicates Saro mark mechanic in Eclipse colours.
7. Ashgrove capstones: Argon replacements adopted in full (The Roll of Wings; Oath of Unbroken Wings). The draft pair used a sky word outside the faction idiom and duplicated the Tamsa chassis; the Rey and DeepSeek legs kept them unchanged, which the chair reads as a miss, not a convergence.
8. Cross-ship damage transfer: not adopted anywhere. Argon kept the draft Maren flagship transfer and added a Seveth transfer; the Rey leg repaired the Maren slot out on the ground that the pack vocabulary contains no damage allocation between ships. Chair follows the Rey ruling, consistently with the Brin ruling (pack item 2).

## Screening notes

- Rey leg (blind, spine): strongest structural work; ruled all ten pack items. Missed five motif strays the Argon leg caught (Tamsa capstone memory word, Vesh T3 memory word, Umbra T1 bright word, Ostrel T1 filed word, Seveth T2 filed word) and the Draven T3 rule 6 pair. All adopted into the final files.
- DeepSeek leg: sound, largely reproduces the assembled draft with Changes lines. Its numbers audit claims zero pure numerics while its printed set keeps flat items (Kassar Wide Net +1 hex; shared sets at +10 aim). The claim is not carried into the audits below; the chair position is in the numbers audit. Its Brin timing capstone and its Seveth stance capstone were considered and not adopted.
- Qwen leg: genuine re-chassis work (Reyes concentration adopted; Mending floor heal and Voice shield bypass considered, not adopted). Its reply ended mid-audit as generated, so its Flags section never arrived; nothing in the final files depends on it. Its position that all four Wall duration capstones may stand was not adopted. It also kept the flat numerics its audit claims are absent.
- Argon leg: filed with a chair header as a record. Unusually productive on lint and motif catches this time (seven adopted fixes, listed in the faction Changes lines), and its Seveth re-grounding converges with the Rey rework. Its numbers audit zero claim fails against its own printed set the same way. Novel effect keys it proposes (bastion, riposte, wallBrace, chainBoom, fade, broodTithe, feast) are not core.js vocabulary and none were imported; where an Argon mechanic was adopted, it is stated in pack terms and flagged for Opus to confirm the key at build.

## Audits (chair, final set)

- Numbers audit (rules 1 and 2): no skill in the final set is a standalone unconditional numeric. Percentage effects are all at or above the 15 percent floor and gated by a named target, a position, a facing, a movement choice, a timing choice, or a stated trigger. The smaller values in the set are flat point effects under the pack section 5 point caps (+10 aim, +10 evasion, +10 crit chance, 10 and 20 point accuracy penalties), concentrated in the shared tier 1 sets, which keep the assembled draft values. Two draft numerics were repaired for rule 1 in this pass: Saro Long Light gained a no turn condition, and Ostrel Silent in the Archive was rebuilt from a flat penalty into a positioned +15 evasion. The Seveth draft shield refill numerics were removed because his Command grants no shield refill.
- Rule 4 audit: no final skill duplicates any of the 12 LEGACY effects. No skill grants starting credits, fleet command points, shipyard hull availability, a dreadnought allowance, shipyard price changes, run start salvage, starting captain rank or perks, or credit gains from battles. Reserve entry skills deploy ships already in the fleet.
- Rule 6 audit: five restating pairs were found and separated. Matriarch T3 first slot and capstone first slot both added extra swarms; T3 now pays +25 percent damage for an unmoved brood. Tamsa T3 second slot and capstone second slot both sent a recorded strike into next round; T3 now launches and strikes this round. Umbra T3 second slot and capstone first slot both fired the volley a second time; T3 now pays damage and aim for an unmoved ship. Seveth T3 second slot and the draft duration capstone both extended the wall; T3 now pays aim next round. Draven T3 first slot restated the capstone torpedo reload at single tube scale; it now converts side arc hits to rear arc hits for the closest ship. All other tier 3 and capstone pairs differ in scope, timing, target, or payoff.
- Capstone chassis audit: Volley family: one strict second use survives, Umbra Noon That Does Not Pass; the Voice repeat is conditional on a hit and pays per ship at half damage, a strike component, not a second Command use. Salvo family: no second Command use survives; Draven Salvo Without End reloads torpedoes a second time, a component reload, and the other salvo capstones extend or retarget the bonus. Wings family: no second Command use survives; the surviving capstones are a concentration decision (Reyes), an ignition and escort pair (Ashgrove), a split launch across one turn (Old Mott), a delayed recorded strike (Tamsa), and a delayed swarm strike (Matriarch), each at a distinct timing and scope. Wall family: one duration extension survives, Thale Iron Testament; the Maren, Brin, and Seveth duration and refill capstones were replaced. Burn family: one carry over survives, Grax Burn Until the Hulls Meet; the Razormaw carry over was replaced. Restore family: one second heal survives, Mending Throng Tide Without End; the Nadir second rebuild was replaced.

## Flags carried to Opus

1. Boarding (pack item 1): ruled repair, done. All Grax boarding references are restated as rams in existing vocabulary. No boarding action is assumed anywhere in the final set. No decision needed unless boarding is wanted as a new mechanic on its own merits. Argon concurs and suggests retiring boardPct from FX_CAPS if boarding is not built; that call is yours.
2. Cross-ship damage splitting (pack item 2): ruled out. No final skill splits or transfers hull damage between ships. Whole hit interceptions at a stated cost (Hullbreakers Branch C first slot, Ashgrove T1 escort, and the new Ashgrove escort capstone) are a different mechanic already present in the draft and are kept.
3. Fleet composition (pack item 3): line drawn at deployment. Holding a ship already in the fleet off the field into round 2 (Crusade Debts in Reserve, Chorus Broods in Reserve) is deployment and stands. No final skill adds a roster ship, grants command points, or changes what the fleet may field. Temporary extra wings and swarms under a Command are not fleet composition. Argon rules the same way.
4. Chorus retired vocabulary (pack item 4): repaired across all four admirals and both shared sets, in throat, mouth, taste, brood, and hunger terms. Mechanics changed only where a Changes line says so.
5. Motif strays (pack item 5): repaired. The full list is in the faction Changes lines: Grax teeth names, Hullbreaker Branch B teeth name, Seveth and Umbra and Ostrel light and filed words, Vesh and Tamsa memory words, Razormaw sea word, Thale shield wording, Voice sensors to scanners.
6. Kassar framing (pack item 6): confirmed. All eight of her Branch A and capstone skills read as sync skills (radius, synced targets, shared aim, sync formation, synced fire, sync survival, sync projection, combined synced strike), per the ruled design layer. One wording repair: line of sight to the flagship, not the anchor.
7. Vorn Command name (pack item 7): this set uses Interdiction strike, as the draft and the design docs do. The data.js display name for the same Command is Reload and strike. The mismatch is in the shipped data.
8. Kassar sync implementation: her sync radius, flagship line of sight, and sync formation terms come from the ruled design layer and her proposal provenance, not from separate keys in the pack vocabulary. Confirm the sync implementation exists or is planned Step work before her tree ships. All four legs flag this in some form.
9. Bespoke hooks: six slots use activation order interrupts or wings and swarms that stay launched between rounds (Vell capstone 1, Vesh capstone 2, Reyes capstone 2, Old Mott capstone 2, Ashgrove capstone 2, Tamsa capstone 2), and three shared or tier 1 slots swap ship positions mid-battle (Maren T2, Glasswrights Branch B second slot, Eclipse Branch B second slot), and three slots give non-carrier hulls a temporary wing launch (Reyes T1, Old Mott T1 and T3). Effects are stated in pack terms, but Opus should confirm each is implementable as timed state or targeting support in core.js, or those slots need a further repair pass.
10. Admiral name form: all four legs headed one Chorus admiral The Mending Throng. The shipped name is Mending Throng; the final files use the shipped name. Worth a look at where the extra word entered the draft chain.

## Owner questions

None. Every open item is an Opus technical call, listed above.

## Not checked

- No code was run. Implementability of the flagged hooks is asserted from the pack vocabulary, not tested against a build.
- Balance of the finalized numbers was not simulated; this pass checked the design rules, the vocabulary, and the lint, not win rates.
- Branch B and C tiers 2 and 3, and trunk texts, are Phase 2 scope and are not in these files.
