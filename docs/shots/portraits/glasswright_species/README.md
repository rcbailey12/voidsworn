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

## Round 3 (round_3/)

Ryan's direction (Nov 14, 2026): push the variety harder, different poses, same central theme, keep to the faction life and bible, cohesive with the ships. The anchor carries over unchanged as figure 1. The other four figures were re-derived from the anchor with the bible's own variation axes pushed: emotion colour in the stored light (design.md section 1), the work of the culture (section 7), the admirals' individual sail plans (section 6), and the ancient elder's full expression (section 6).

- Face study, round 3: the anchor's head in three-quarter profile, brow drawn inward in focus, the near lid half lowered in contemplation, a cold blue tinge (the focus colour) in the glow. Snapshot bf049339-face-4d5a-8c72-faf9a234e390:ak3jlr.
- Bench worker, round 3: side view at the forge, weaving a large curved sail panel for a starship on a grown frame, both precision wrists drawing thread at once and braiding it onto the panel edge, the panel's edge lit at the join, an open lattice apron of woven glass thread over the thorax front (section 7 clothing). Two earlier attempts were corrected: one put the work-light in an overhead lamp (the bible's work-light is the focusing vane's edge, never a device), one lost the vanes to a smooth dome; the delivered figure restores furled vane sheets along the thorax. Final snapshot fa834d1f-bdb1-47ef-99cf-54298330153e:n10dh6.
- Admiral, round 3: Tamsa settled on the command deck, her six vanes spread toward the viewport light in the grief gesture (section 5: the sails open toward where the sun was), one working arm lifted toward the light, glow bright and steady, the sigil apron worn over the thorax (sections 6 and 7). After the council round, one correction pass thinned the vane frames to fine silver edges and grown spars and made the sigil read as light recorded in the weave rather than a plate. Final snapshot 390b1bd2-2072-4463-ba97-acd47f9dc4cd:k3cawc. The ship's own vanes through the viewport echo hers, the same growth at two scales (section 1).
- Ancient elder, round 3: the far end of the elder band pushed to its limit: lengthened rear thorax, the low wide fuller stance, frosted bloom over the whole body, eight or more large bloom-edged vanes furled down the long back, deep saturated green core glow, archive hall with woven recording vessels. A first attempt rendered the body brown and leathery (age as decay, which the substance system forbids) and was rejected; a later correction edit that removed the arms was also rejected. The delivered figure is snapshot 7bc11368-254f-4c0b-92e5-03076ab8300b:aa905b.

Council review of round 3 (same bar; Grok's seat empty, bot wall, eleventh consecutive muse job):
- DeepSeek: SHEET PASSES WITH FLAGS. Counts 4+4 on every full figure; elder brow 9 and bloom vanes PASS. Its only FAILs: the lattice aprons on the bench worker and admiral, read as a second material.
- Flash: SHEET PASSES WITH FLAGS. Counts 4+4 on every full figure (admiral's raised arm and occluded fourth arm noted); the same two apron FAILs as its only flags.
- Qwen: SHEET FAILS. It counted extra support pads on the three working-pose figures (bench 5, admiral 5, elder 6) and failed line 1 on each; it also failed the admiral's vanes as framed rig-sails on metal spars, and joined the apron FAILs.
- Chair's rulings on the disagreements:
  1. The aprons (all three legs): NOT a failure. Design.md section 7 prescribes this clothing by name: open lattice aprons of the species' own woven glass thread at the bench, longer sigil-recorded aprons for admirals, rank shown in the weave. The review pack's bar summary omitted the clothing allowance; that omission is the chair's pack defect, recorded here. The legs judged correctly against the text they were given.
  2. The admiral's spars (Qwen): adopted as a fix and corrected (see above).
  3. The support counts (Qwen against DeepSeek and Flash): genuinely contested. The chair's own mechanical counter also finds five to six pad-like endpoints on the working-pose figures; DeepSeek and Flash each counted exactly four supports. The body is translucent glass, so far-side supports show through the thorax and several endpoints are the far pair at depth; even so, the chair cannot certify an unambiguous four from the pixels alone, and two correction edits aimed at the counts either changed nothing (bench) or broke the figure (elder, arms lost) and were rejected. The delivered figures are the council-reviewed ones. If Ryan wants the counts bulletproof, the reliable route is plainer stances for the bench worker and elder (the anchor's open stance is what made its count unambiguous), at some cost in drama. His pick governs.

## Variant exploration (round_3/variant_exploration/)

At Ryan's request (Nov 14, 2026), two upright variants were generated as explorations: a slim upright weaver in an atelier and an upright dancer drawing thread into a woven spiral, both keeping the species' head, substance, vanes and weaving. They sit outside the bar by construction: design.md sections 2 and 7 forbid an upright stance outright, so neither can be the species sheet unless Ryan rules a design change. They are filed here, unreviewed, pending his ruling on whether they are exploration only or a direction for the Board.
