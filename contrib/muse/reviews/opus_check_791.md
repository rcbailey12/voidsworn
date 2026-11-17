# Outside check: PR 791, Hullbreaker trophy patches bigger and paler (R252)

Refs #256

## Verdict: GO WITH CONDITIONS

Four conditions, none of them a build fault in the stack itself: A16 has to be judged against its own concept when the Board runs the PC pass, the RECIPE sentence about the shared patchwork needs its pale-zone exception, the pale-zone retune that rode in with trophy_share should be enumerated on the record, and the Board still owes its answer on the sheet-placed trophy patches. The work itself is verified: the chair read the full stack.py diff against the merged head, matched every figure in the PR table to the measure JSONs, and tied the bake records to the merged head by commit. On A20 the ruling's aim is met on area and pale share; the disclosed shortfalls on patch size and patch lightness are real, accurately stated, and the known price of the shared-stack limit the PR names.

Council: blind Rey GO WITH CONDITIONS. DeepSeek (DeepThink on, Search off, verified both ends) GO WITH CONDITIONS. Qwen (Qwen3.8-Max, verified both ends) GO. Grok (Fast, verified both ends) GO. Flash (Flash-Lite, verified both ends) GO WITH CONDITIONS. ChatGPT (chat, GPT-6 at High, verified both ends) GO WITH CONDITIONS.

## The brief

opus_check_791: PR 791 (merged 2026-11-15T19:20:31Z, head b09f4cb4, base e2b0cf33), the Hullbreaker paint change for issue 726 under R252 item 3 (trophy patches bigger and paler like the concepts), keeping R240 (patchwork stays uneven), R218 (one stack per faction) and R214 (the ruling lands with its documents). Board brief at issue 256 comment 6902790668. Same format as opus_check_796.

## (a) The stack change

**Verified against the merged diff.** The only code change is tools/blender/kits/hullbreakers/stack.py (+79 lines). A TROPHY layer is added (cell (.130, .085, .060), share .32, cluster (2.2, .45, 1.55), warp .55, band 2.0, split .22, gain 1.5, families 65 percent trophy_pale / 35 percent trophy_violet, the pairs k-means sampled from the A20 beauty with the method stated in the code comment). panel_nodes runs the shared patchwork first and unchanged on the ordinary hull zones, then lays the trophy grid on the hull atlas only, one colour per trophy cell, never per mesh island. Parts (cells is not None) return the plain patchwork. No shared module, geometry, inside, mount, lamp or decal code is touched. The pale zone is the one path that differs, and it is condition 2 below. Every leg passed this item on the ordinary zones.

## (b) The measured numbers

**Verified figure for figure.** The chair matched the PR table to the four measure JSONs, and Qwen reproduced all 28 table figures independently. A20 at 2048: patch share 0.1083 against the concept's 0.1137 (old stack 0.0316); pale share 0.0802 against 0.0791 (old 0.0041); violet share 0.0281 against 0.0346; area-weighted patch size 0.296 against 0.484; largest-10 mean 0.442 against 0.621; mean value 58.6 against 73.9 (old 48.8). The 1024 and 2048 passes agree closely. Area and pale share, the two quantities R252's wording turns on, land on the concept; size and lightness move most of the way and stop short, as the PR discloses.

## (c) A16 against its own concept

**The PR's A16 line is accurate and incomplete; this is condition 1.** The PR reports A16's patch share (0.0563 against its concept's 0.0511) and mean value (51.5 against 62.1). The same JSON shows A16 overshooting in the opposite direction on the measures the PR does not quote: 28 detected patches against its concept's 91, area-weighted patch size 0.399 against 0.291, largest-10 mean 0.399 against 0.272, pale share 0.0480 against 0.0305, and violet share 0.0083 against 0.0205. That is the expected behaviour of one stack tuned on A20 and shared per R218, and nothing in it faults the build; but a check that quotes only the two measures that moved the right way understates the trade-off. Blind Rey, ChatGPT and DeepSeek landed on this independently, from the same JSONs.

## (d) The honest-read gaps

**Stated accurately.** Patch size at about 60 percent of concept is 0.296 / 0.484 = 61 percent. The pale patches are still darker than the concept and the violet reads grey-lavender at the concept's threshold; both are disclosed with their mechanism (later AO, rust and edge-wear layers still mark each modelled plate edge, so closing the size gap needs a shared change or bigger modelled plates, outside this PR's paint-only scope). Three figures in the disclosure are tuning-stage observations rather than measure JSON fields: the pale-patch medians 141 (gain 1), 151 (gain 1.5, 2048) and the concept's 172, the strict hull-atlas violet share of about 1.3 percent, and the lavender-grey pixel rise from 5.9 to 8.9 percent. They appear in the PR body and the gain comment in the code, not in the JSONs; Qwen and DeepSeek both flagged exactly this. Their direction is consistent with the JSONs and nothing in the verdict rests on them.

## (e) The documents, and the pale zone

**R214 is satisfied in form; one sentence overstates, which is condition 2.** RECIPE.md gains the paint-stack passage describing the TROPHY layer and corrects the stale line that claimed the shared hook is absent from the Hullbreaker path; factions.md's "Patch size" point now points at TROPHY in stack.py. Both land in this PR with the code. The exception: panel_nodes does not run the shared patchwork at all on the pale-zone path. When the zone carries its own trophy_share, the code takes the other branch (seam set to None, amount recomputed as trophy_share / share) and mixes the trophy layer over the zone's incoming colour. RECIPE's sentence "which runs the shared patchwork unchanged first" is therefore true of the ordinary hull zones and not of the pale zone. The pale passage the head commit added (b09f4cb4, "the pale zone under the trophy layer, as the stack does it") describes the zone's behaviour correctly, that it keeps its own dark grey with no dark plate families over it and the trophy layer covers about 65 percent of it, but it does not qualify the general sentence. The stack.py docstring for panel_nodes makes the same unqualified claim. (DeepSeek raised this; the chair verified it in the merged code.)

**The pale-zone retune is condition 3.** The pale entry changed more than the trophy_share addition: rust .25 to .20, plate_var .30 to .22, grime 1.0 to .70, patchwork .5 to 1.0 (rough .74 and metal .25 unchanged), verified by the chair against base and head. The PR body describes the zone's resulting behaviour but does not enumerate the retune. Qwen noted the same values and judged the effect accurately conveyed; the chair sides with enumerating them on the record, because R252's order was the trophy patches and the retune rides with it.

## (f) Bake cost and provenance

**Supported at the one compared setting, and the records tie to the merged head.** The only old-against-new comparison is A20 at 1024: 742 cpu s old against 749 new (+0.94 percent, the PR's "+1 percent (noise)"), from bake_sandbox.json (stack commit ac3453bf9, old stack main 608fe532d). DeepSeek asked whether those commits tie to the PR; the chair checked. ac3453bf9 is an ancestor of the merged head, and the three commits after it add only the sandbox pictures and numbers, the 2048 pass, and the RECIPE pale passage; stack.py does not change after ac3453bf9, so the measurements were taken on the merged stack. stack.py at 608fe532d is byte-identical to stack.py at the PR base e2b0cf33, so the old comparator is the true pre-PR stack. No old-stack comparator exists for A16 or for 2048, so "same cost" is established at A20 1024 and unmeasured elsewhere; the PR's claim is scoped "at the same settings", and ChatGPT and DeepSeek both asked for that scope to be kept explicit, which this paragraph does.

## Conditions

1. **Judge A16 against A16's own concept in the PC run, and record the trade-off.** When the Board runs the issue 726 PC pass (A16 to A20, stages 4 to 7), A16's acceptance should be read against its own concept numbers (patch count 28 against 91, weighted size 0.399 against 0.291, violet share 0.0083 against 0.0205, pale share 0.0480 against 0.0305), not only against A20's table, and the shared-stack trade-off should be written into the issue record. (Blind Rey, ChatGPT, DeepSeek.)
2. **Record the pale-zone exception in the patchwork sentence.** Amend the RECIPE paint-stack sentence (and the panel_nodes docstring, which makes the same claim) so "runs the shared patchwork unchanged first" carries its exception: on a zone with its own trophy_share the patchwork call is skipped and the trophy layer mixes over the zone's own colour. Wording only; the code behaviour is intended and is already described in the pale passage. (DeepSeek; chair-verified in the merged code.)
3. **Enumerate the pale-zone retune on the record.** Note in the issue 726 record that the pale entry also changed rust .25 to .20, plate_var .30 to .22, grime 1.0 to .70 and patchwork .5 to 1.0 alongside trophy_share .65, so the zone's new read is not attributed to the trophy layer alone. (DeepSeek; chair-verified against base and head.)
4. **Board call on the sheet-placed trophy patches.** As built, A20's sheet-placed patches TP1, TP3 and TP5 read pale, violet or dark grey by where the trophy cell falls. The PR poses the Board the question whether those named patches should always be pale; it needs a recorded answer, because a named sheet patch reading dark grey by chance sits oddly against the sheet's own placement. (Blind Rey; posed by the PR itself.)

## Notes

- **Flash's sole condition is the Board's own step.** Flash conditions its GO on the PC paint run of A16 to A20. That run is issue 726's done-when and the Board's step, not part of this PR, and names no defect in it; the same disposition as Flash's condition on 787. Condition 1 above covers what that run should measure.
- **The A16 fixture PASS is attested, not re-derived.** The PR states sheet_fixture_hash.py --check passes with the record unchanged, and that neither stack file is a fixture input. The output is not in the pack (DeepSeek, Qwen); given the paint-only scope the chair accepts it as reported.
- **Standing, not a condition on this PR:** the PC paint run itself, with its stage 4 to 7 checks and the hb682out comparison, remains the Board's, as the PR states. Sandbox correctness is what this check establishes.

## Leg notes and slips

- ChatGPT's pack reached it in condensed form: the paste route summarised the code section, so the full panel_nodes body was not in front of it, and its finding 1 "not in pack" entries on direct code verification are an artifact of that delivery. The chair verified the full diff directly against the merged head. Its A16 finding rests on the measure JSONs, which reached it in full, and matches blind Rey and DeepSeek.
- Grok's table dropped the 2048 patch-size column in rendering; the value is 0.296, identical to its 1024 figure, and nothing rests on the omission. Grok does not raise the A16 granularity point or the pale-zone wording.
- Qwen and Grok return clean GOs. Both accept the bake claim as scoped; Qwen's figure-by-figure reconciliation of the PR table against the JSONs is the most complete of the round and agrees with the chair's.
- DeepSeek's sign-in needed Ryan himself: the cloud session had expired, and he signed in with Google through a browser takeover before the leg ran. DeepThink on and Search off were verified before sending and after completion. Recorded for completeness.

## Not checked

- The paint pictures at picture level; the numeric measures over them are verified above.
- The PC paint run (Blender, GPU, stages 4 to 7) and the hb682out comparison; the sandbox records are what this PR stands on.
