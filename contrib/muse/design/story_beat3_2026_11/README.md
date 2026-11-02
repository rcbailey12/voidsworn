# Story beat 3 pieces: progression step 12 (issue #28)

Final authored beat 3 content for all six factions, built from the story pack (contrib/muse/reviews/story_pack_2026_10_30.md) under lore bible r8 and the FINDINGS rulings, through the usual four-leg panel (DeepSeek, Qwen, Argon, and a blind Rey leg) with a chair merge. Finales are out of scope for this step and are not touched.

## Files

- sunward_crusade.md: arc_vs_owed, "What Is Owed"
- hegemony_navy.md: arc_hg_minute, "The Unlogged Minute"
- ashfall_hullbreakers.md: arc_hb_rook, "Rook"
- the_chorus.md: arc_ch_crucible, "The Second Throat"
- the_glasswrights.md: arc_gw_flaw, "The Killing Flaw"
- eclipse.md: arc_ec_count, "The Count of Years"
- legs/: the four leg drafts this delivery was merged from, filed as records.

Each faction file holds the core decision scene (scene purpose, the event node in shipped shape, the spoken text lines, the debrief line), the learning payoff line, and four admiral spotlights in admiral table order, plus a Flags section recording every change the chair made to the source text and why.

## How Opus wires this in

- The node blocks are drop-in event nodes in the shipped shape. Node ids, fight:false, the two options per node, and every reward flag and value are identical to the story pack source; only text changed, and only where a pack rule required it (each change is listed in that file's Flags).
- Text lines are keyed by speaker as written. The debrief line renders on the battle debrief. The learning payoff line renders on the run debrief and must render after a lost run exactly as after a won one (R62).
- Spotlights are keyed by the admiral display name at the head of each bullet and fire when that admiral commands the fleet.
- The {rival} token in arc_gw_flaw is the shipped Nemesis token and resolves through the existing token system. No beat 3 text names or implies a Nemesis faction (owner ruling, Nov 2, 2026).
- Step test from the plan: each learning line and spotlight renders in its screen with no placeholder text.

## Name conflicts for Opus

- Hullbreakers: the story pack spotlight header reads "Warlord Grax Steelgrin." Shipped data.js: "Warlord Grax Ironmaw" (the Oct 27 rename, applied in data). This delivery uses Ironmaw everywhere. The story pack header needs correcting at source.
- Chorus: the story pack spotlight header and the step 12 pack table read "The Mending Throng." Shipped data.js: "Mending Throng." This delivery keys the spotlight as Mending Throng. The pack texts need correcting at source.

## Screening summary

- Method: source text kept word for word unless a binding rule in the pack required a change. Fixes were adopted where legs converged on a change the pack backs. The blind Rey leg and the Argon leg converged on nearly every fix, and that convergence carries most of the adopted set.
- DeepSeek: sharp flags, unreliable text. Its printed Hullbreaker lines kept the Chorus teeth motif and the naval label its own flags claimed to fix; its spotlights repeat each admiral's full name and title inside the line; its Glasswright learning line stayed loss-only with "continuity," and its Eclipse learning line kept "will not know the names of the minds that paid," the exact clause that contradicts the settled Archive fiction. None of that propagated. Its Hegemony flags (the courier-speed learning line, the "lit" link) were pack-backed and match the adopted fixes.
- Qwen: mostly a transcription of the source. It left standing the Thale memory line, Maren's "shield reading," the Reyes pronouns, the Hullbreaker teeth lines, the loss-only Glasswright learning line, the Eclipse "next fleet" learning line, and the broken single quotes in arc_ec_count, which it reproduced verbatim. Its genuine catches (the Steelgrin header, the Voice of the Deep "cold," the Chorus spotlight pronouns) were adopted through the convergent fixes.
- Argon: screened hard, per the brief. Nothing from the Argon leg is used unless the pack or the bible backs it; on that test its fixes were the strongest of the panel and converge with the blind Rey leg. Its context flags (the Crusade charge and rivalry beat, the Chorus and Eclipse finale context) are recorded in the faction files as out-of-scope notes, not edits.
- Dialogue lines: the spoken text lines are settled story pack material and are kept word for word in every file. The pronoun lint was applied where the pack aims it: spotlights, learning lines, result texts, and Nemesis references.

## Lint results

Method: vocabulary greps run over the authored content of each faction file (everything above its Flags section). The Flags sections quote source wording to document the changes and are excluded from the vocabulary counts. The dash count covers whole files, Flags and this README included.

- Em dashes and en dashes, all seven chair-authored files: 0.
- Node ids: all six match the story pack source exactly (arc_vs_owed, arc_hg_minute, arc_hb_rook, arc_ch_crucible, arc_gw_flaw, arc_ec_count).
- Reward sets: all twelve r:{...} blocks match the source exactly (diff clean).
- Song vocabulary (song, choir, hymn, psalm, chant, sing, sings, singing, whole words), authored content: 0 hits.
- Naval vocabulary (sea, sail, anchor, port, starboard, keel, mast, harbor, ashore, whole words; plus sink and goes down in ship contexts), authored content: 0 hits.
- Retired vocabulary spot check (warp, auspex, cogitator, archeotech, xenos, saint, relic, rite, heresy, litany, patron, sigil, boon, favour), authored content: 0 hits.
- Data ids as display text (voidsworn, hegemony, corsair, chorus, ithar, deathless), authored content: 0 hits.
- Motif ownership, authored content: light, glass and reflection words appear only in the Glasswrights file (10 hits; zero in the other five). Teeth appear only in the Chorus file (zero in Hullbreakers, where the source had them). Registry and projection words appear only in the Hegemony file (8 hits). Chalk, Roll and oath words appear only in the Crusade file (11 hits). Remember, memory and archive words appear only in the Eclipse file (4 hits) and the Chorus file (10 hits, all the second throat named Memory, the bible's built-in exception, in story and dialogue only).
- Chorus register: node result texts, text lines, debrief and learning payoff all speak as "we"; the one source line that broke register ("It will hesitate in the fight") was fixed.
- Spotlight pronouns: she/her appears in spotlights only for Commodore Sera Ashgrove and Tamsa of the Clear Aperture, the two cases the pack allows, and nowhere else.
