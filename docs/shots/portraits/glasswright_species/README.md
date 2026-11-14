# Glasswright species concept sheet (issue 250)

Owner: muse. Governing documents: contrib/muse/design/glasswright_species_2026_11/design.md (the species) and concept_sheet_notes.md (the consistency bar). Branch: muse/issue-250.

## Method: consistency enforced by construction

The #48 sheet failed because four independent text prompts reinterpreted the species four times. This run inverts that. One canonical anchor figure was generated first and verified against the bar (limb counts checked by an independent visual count, not by eye alone). Every other figure was then generated FROM the anchor image, with the instruction to keep the creature identical and change only the pose, role, age or framing. Corrections were made as edits on the figure's own image state, never as fresh prompts. The generator does not expose seeds; the reproducibility record for each image is its prompt (or edit instruction) plus its generation snapshot id, both listed below.

## Round 1 (round_1/)

Figures: r1_anchor.jpg, r1_face.jpg, r1_bench.jpg, r1_admiral.jpg, r1_elder.jpg, and the contact sheet r1_sheet.jpg.

Generation record:
- Anchor, attempt 1: full-body prompt from design.md sections 2 to 5 (low wide thorax, four arms, four support limbs, flush green lens eyes, six-segment brow, flush reed grille, five vanes). Result grew SIX support limbs (verified count: 6 pads, 4 hands). Snapshot b5f964cf-0d34-476a-a633-3df4691c932d:x79dio. Rejected as the anchor.
- Anchor, attempt 2 (the delivered anchor): edit on attempt 1, "remove two of the support legs so exactly four remain, one pair forward, one pair aft". Verified count: 4 pads, 4 hands, 5 vanes. Snapshot b5f964cf-0d34-476a-a633-3df4691c932d:epreba.
- Face study: generated from the anchor image (close-up of the same head). Snapshot 984ab02d-7037-4814-a5e2-9397b3aa3367:9k4ih5.
- Bench worker: generated from the anchor image (same creature at a glass bench, working pair holding a crystal workpiece, precision pair drawing thread, one vane focusing a line of light). Snapshot bd39509e-c16d-44d0-af2b-3b031173daf0:gi3ear.
- Admiral, attempt 1: generated from the anchor (Tamsa, six vanes spread, command deck). Result: eight pointed crystal shards for vanes and a 5 pad / 3 hand limb split (verified counts). Snapshot abc5376f-cdf7-4f30-9b5d-2a25140c5251:6e008e. Rejected.
- Admiral, attempt 2 (the delivered round 1 admiral): edit on attempt 1 (six broad flat sail sheets instead of spikes; the front-right pad limb becomes the fourth arm). Verified: 4 pads, 4 hands; the layered fan's vane count stayed ambiguous (6 to 10 depending on how overlapping edges are counted). Snapshot abc5376f-cdf7-4f30-9b5d-2a25140c5251:pj6qyi.
- Ancient elder: generated from the anchor image (past 350 years: lengthened rear thorax, fuller stance, heavier brow, frosted bloom edges, deeper glow). Verified: 4 pads, 4 hands. Snapshot 959ed3a7-9f45-43ce-b4d9-66c8936d43ab:o6vmqs.

Council review of round 1 (DeepSeek, Qwen, Flash legs against the notes' bar; Grok's seat empty, bot wall, tenth consecutive muse job):
- Anchor: PASS on every line, all three legs (counts 4+4, brow 6, vanes 5).
- Bench worker: PASS with one occlusion note (the fourth support limb is present but hidden behind body and bench; three pads countable). Qwen and Flash counted the figure PASS on that basis; the chair's visual count agrees (3 pads visible, no extra limbs).
- Ancient elder: PASS (Qwen, Flash). DeepSeek failed its grille (reads toothy) and its bloom edges (reads spiky); the chair does not adopt those two: the grille matches the anchor's own grille at this scale, and frosted, chipped bloom is the design's own elder language (design.md section 6). Recorded as DeepSeek's stricter reading, kept as a minor flag.
- Face study: FAIL on the grille. Qwen and DeepSeek independently: the mouth hangs open with stretched strands spanning the gap, reading as fringe, not a small flush grille. The chair's read agrees. (DeepSeek also failed the face's surface texture as a second material; not adopted: design.md specifies a frost-like lattice texture inside the glassy regions.)
- Admiral: FAIL on the sails. DeepSeek (massive, spiky) and Flash (exaggerated display fan) fail the fan's size; Qwen passes it only under the display-pose exception while flagging that the fan carries roughly ten vanes against Tamsa's written six (design.md section 6: six vanes, all moderate). The chair adopts the flag in full: count and size both exceed the design.
- Bench worker substance (DeepSeek only): dark bands at the hand joints read as hardware. Not adopted as a fail (the design's joints are bands of the same tissue at different hydration), kept as a readability flag.
- Verdicts: DeepSeek SHEET FAILS, Qwen SHEET FAILS (on the face grille), Flash SHEET PASSES WITH FLAGS. Chair: round 1 does not yet pass the bar; exactly two figures need work, the face study's mouth and the admiral's fan.

## Round 2 (round_2/)

Only the two failed figures changed; anchor, bench worker and elder carry over unchanged. Files: r2_sheet.jpg plus r2_face.jpg and r2_admiral.jpg; the carried-over figures are the round_1 files.

- Face study, round 2: edit on the round 1 face, mouth only: "closed and small, a short row of thin, rigid, perfectly vertical crystal reeds set completely flush, no gap, nothing hanging or string-like". Result: a closed, even, flush grille; the rest of the head untouched. Snapshot 984ab02d-7037-4814-a5e2-9397b3aa3367:jyxj6u. Chair verified against the bar line that failed.
- Admiral, round 2 attempt 1: edit (exactly six vanes, two primaries and four secondaries, layered fan, modest). Limbs stayed 4+4 but the fan's edges still counted up to 10. Snapshot abc5376f-cdf7-4f30-9b5d-2a25140c5251:t9wyxy. Not delivered as the round 2 figure.
- Admiral, round 2 attempt 2 (the delivered figure): edit (exactly six SEPARATE vanes, spaced with dark gaps between them, roots visible: two larger central, four smaller angled out). Verified count: 6 vanes, 4 pads, 4 hands. Snapshot abc5376f-cdf7-4f30-9b5d-2a25140c5251:z11w81. Two of the vanes sit on short grown spars (the design's own language: died-back silver along edges and spars); flagged for Ryan's eye, not counted a fail by the chair.

Chair's round 2 position: every bar line now passes on every figure, with three standing notes: the bench worker's occluded fourth support, the elder's grille reading slightly wider than the anchor's, and the admiral's spar-mounted secondaries. Ryan picks from the round 2 sheet; if he wants the spar or occlusion notes chased, round 3 is a small edit each.
