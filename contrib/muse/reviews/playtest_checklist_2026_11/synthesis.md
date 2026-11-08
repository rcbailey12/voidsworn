# Playtest checklist for the next build: chair synthesis (issue 202)

The checklist in section 1 is the deliverable, ready to follow in the next playtest build (the build made from current main after g2_pt_d03ac22, the last build played). It is grounded in the verified commit delta between that build and current main (36 commits), not in anyone's summary of it. Section 2 is the not-showing list for the record. Section 3 records how the legs were merged and screened. No owner questions: the pack's facts settle everything this job needs.

## 1. The checklist (one page, plain words)

Playtest checklist for the next build

Start: On your PC, open Downloads\voidsworn_test and double-click play_godot.bat. If it will not start, use play_godot_safe.bat instead. This is the build made after the last one you played. Start a run the usual way: title screen, pick an admiral and faction, then play from the campaign map. Battles and the station screens are at their map nodes.

In battles

1. Look at: a ship that breaks apart or dies. Move in close on the pieces.
   Good: the broken pieces look solid inside, like real broken ship parts all the way through.
   Bad: any broken piece that looks hollow or empty inside, like a thin shell.

2. Look at: the moment a ship dies.
   Good: deaths feel big and loud, and they fit being out in space.
   Bad: a death that feels small, flat or quiet for a ship that size.

3. Look at: the battle backdrop and the bits of wreckage spread around the fight.
   Good: the wreckage looks like pieces of real ships that broke up.
   Bad: wreckage that still looks like plain rocks or plain blocks.

At the stations

Note: the stations are not finished yet. They have new shapes and new paint in this build, but a later pass will add much more surface detail. Judge the shapes and paint below, not the final level of detail.

4. Look at: each station, the fleet station and the refinery, on its station screen and in any view that shows it.
   Good: each station has clearly more structure than the plain shapes in the last build, and nothing looks taken away. The new shapes were added only; nothing was moved or removed.
   Bad: a station that still reads as a few plain blocks stuck together.

5. Look at: the paint on both stations.
   Good: the plates read as metal, the lighter and darker shades keep the parts separate, and there is no plastic look.
   Bad: bright panels that look like toy plastic, or paint so dark and flat that the new shapes disappear.

Screenshots to take

- One close shot of a broken ship, showing the inside of a broken piece.
- One shot of a ship death, or the wreckage left right after one.
- One shot of a wreckage spread during a fight.
- One shot of the fleet station.
- One shot of the refinery.
- One shot of anything that looks wrong, hollow, plain or toy-like, wherever you find it.

## 2. Not showing in this build yet (for the record)

- Pyre-Barge round 6 (issue 187, PR 196, ruling R108): merged as tools only. The hand-built V3 and the AI-built V1 exist as workshop builds and comparison sheets, but neither is in the game ship set, so the Barge in this build is the same one as the last build.
- Pyre-Barge round 5 (issue 163, PR 186): merged as tools only. Its paint was rejected by the owner (R103, "cluttered messy mix"), and nothing of it is in the game.
- Documents and research merged in the same window (readable-paint standard, PR 191; backlog check, PR 192; FINDINGS updates, PR 182; board bookkeeping in LOOP.md): no game change.
- Station surface detail pass (issue 199, ruling R109): not run yet. The owner ruled the repainted stations still look "super plain and just like regular shapes" and ordered way more surface detail. That job runs after the round 7 job, so in this build the stations have new shapes and new paint but not the extra surface detail. Do not judge the stations as finished.
- Pyre-Barge round 7 (issue 198, ruling R108): not run yet. The V3 hull gets its detail and outline features back (dishes, scoops, gun barrels, folded claws, chains, rocket clusters) with the red-brown plate paint, compared against V1 with the same paint. Its result will be a comparison sheet for the owner's pick, and only after that pick does a new Barge enter the game; the breakable Barge job (issue 169) waits on it too.
- Surface detail standard (issue 200): a written standard that future build jobs follow. It changes no game content directly. Its five open picks were ruled by the owner on Nov 5, 2026, with all chair picks adopted.
- Nemesis redesign (issues 120 to 122, rulings R85 and R101): none of it is built yet. The hunter drawn per story point, commanders per faction and the adopted commander voice lines (NEM_VOICE) will not appear, so the Nemesis in this build behaves exactly as in the last build, with one hunter for the whole run.
- Test checks for the Nemesis redesign (issue 201): a review document only, no game change.
- Progression steps, debrief screen, nebulas and ion storms, and rocky and terran planets (issues 24, 26, 27, 29, 30, 92, 139 and 140): queued behind the jobs above, none built.
- Tripo per-part test (issue 193) and the five ship-pipeline options (issue 194): parked proposals, nothing built. Issue 193 also waits on the owner's call because Tripo is a paid service and the house rule is free and local tools only.

## 3. How this was built, and the screening record

Basis: the last played build is g2_pt_d03ac22 (LOOP.md records it as having no deaths 2 and no station detail yet). The delta to current main is 36 commits, verified through the GitHub compare API when the pack was built. The visible changes are exactly four: deaths 2 (issue 167, PR 185), the ship-derived wreckage kit (issue 60, PR 143), the station detail shapes (issue 183, PR 190) and the station repaint (issue 195, PR 197). Everything else in the window is tools-only merges or documents, and the changes already in the last build (automatic squadrons, deaths round 1, flipbook weapon hits, the campaign map fixes, the admiral balance changes) are not listed as new anywhere in section 1.

Four legs ran from that pack: a blind Rey leg first, DeepSeek (DeepThink on, Search off), Qwen (Qwen3.8-Max gates passed both ends), and an Argon review leg (Argon High gates passed both ends) that checked the three writer legs against the pack. The three writer legs agree on the substance almost completely; the synthesis follows the blind leg's structure (the deaths item split into its two named changes, the station caution inside the checklist, the six-shot list) with these chair amendments:

- Battle backdrops restored to check 3 (the blind leg dropped the location; DeepSeek and Qwen kept it, and the Argon review flagged the drop).
- The not-showing entries for the station detail pass and round 7 use the full text (the owner's quoted words and the round 7 feature list), where the blind leg had shortened both; the Argon review flagged both shortenings.
- Louder stays in the deaths check (DeepSeek's version dropped it; flagged by the review).
- The station shapes check names both stations and states the additions-only point in full (DeepSeek's version missed both; the blind version had them).
- No issue numbers, PR numbers or build hashes anywhere in section 1 (DeepSeek's title line and Qwen's header carried them; flagged by the review and cut).
- Qwen's jargon and inventions are cut: "current main", the paragraph listing already-in-last-build features by their technical names, "torn metal with depth", "panels, struts, hull fragments", "grey blobs" (flagged by the review; the fidelity risk is real, a checklist that names parts the build may not show sends the owner hunting for them).
- DeepSeek's gloss "more bumps and features on the outside" is cut ("bumps" is not in the record; flagged by the review).
- DeepSeek's fidelity note claims its start line covers the build time; it does not. The build time is build-side information and stays out of the checklist entirely, as the blind leg had it.
- Qwen's checklist part left the not-finished station caution to its record section; the caution belongs in the checklist, where the blind and DeepSeek versions carry it (flagged by the review).

Two review objections were considered and not adopted. First, the split of the deaths item into two checks: the pack names two changes in that item (solid insides; louder, more space-real deaths), and the second check's Bad line is the direct negation of its stated Good, not an invention; the blind leg's fidelity note already discloses that no specific sound or moment is named in the record, so the check can only ask for the overall feel. Second, the death-moment screenshot: two writer legs added it independently because check 2 otherwise has no shot that carries it, and the pack's screenshot brief asks for the few shots that carry the decisions rather than capping the list at four. Qwen's word "explosion" is dropped (not in the record); the shot is phrased as a ship death or the wreckage right after one.

Fidelity limits, carried from the blind leg: the record names no specific battle, admiral, faction or map stop that guarantees a ship death, a wreckage spread or a station view, so the checklist says any battle and each station in any view that shows it, rather than inventing a named place. The record gives the run flow only in broad terms, and the checklist adds no menu names or steps beyond it.
