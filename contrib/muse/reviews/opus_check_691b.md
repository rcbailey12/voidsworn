# Outside check: Board commit 8c265330 on codex/issue-676 (publish.py PASS guard, ships.md rule 11)

Verdict: GO.

The commit is a merge of main into the weapon-match branch whose own changes are exactly two files, and both do what opus_check_691's conditions 3 and 4 asked. The commit message records the ratifications conditions 1, 2 and 5 asked for. (Condition 6 was record-keeping for the Board's own notes and is not graded here.)

## Condition 3: publish.py refuses a non-PASS sheet

The weapon_match.json load moved to the top of tools/blender/build_sheets/publish.py, ahead of the output folder creation and every image conversion and copy, and the script exits with a named message when the record's result is not PASS: "weapon match is %s for %s: fix the ship, do not publish (ships.md rule 11)". It reads the same record the publish step later copies into the sheet folder, so the guard covers the build's own record, including the failed-build case the condition named (build.py writes the JSON before exiting 1, so a hand-run publish of a failed build's folder now stops). The old duplicate load further down is removed. The comment cites R241 and this check.

## Condition 4: rule 11 now states what the check enforces

docs/playbooks/ships.md rule 11 reads: a visible weapon "belongs to a data.js weapon slot: its kind and mount fit that weapon (data.js carries no mount size, so size is judged by eye against the class, and checked only between mounts of one slot)". That is the check's actual enforcement (kind and mount absolute under the FITS table; size relative within a slot under SAME, x1.3), and the rule no longer promises an absolute size check that does not exist.

## Conditions 1, 2 and 5: the ratifications are on the record

The commit message states: "Board ratifies conditions 1 (A19 bow launcher cut: R241 is Ryan's later ruling), 2 (SAME and SPLIT, marked as a Board reading per R251) and 5 (E11's seam and deck changes as destruction-proof fallout)." Rule 11 itself now carries the R251 marking in the standing text, not only in the message: SAME and SPLIT "are the Board's reading of Ryan's 'consistent and line up with the in game behavior' (Nov 15, ratified on PR 691), not his words: change them if he rules otherwise." That is the discipline the conditions were protecting: an arm's or Board's reading stays labelled as a reading wherever it lands.

## Notes

- DeepSeek graded GO WITH CONDITIONS on two points about the commit message, both answered here. First, its R251 query: the pack did not include R251 (a chair pack gap). R251 is the repo memory discipline ruling (a standing rule comes only from Ryan's quoted words; a Board reading is marked as a Board reading), verified in the opus_check_719 inputs; the citation is correct. Second, the message's condition 5 parenthetical names "seam and deck" and omits the third item condition 5 listed, the frame station move (4.6 to 4.3). That is a real one-item shortfall in the summary line. It does not unsettle the ratification: the message ratifies condition 5 by number, and the itemised record of all three changes lives in deathless_E11.py's change log, which opus_check_691 verified. Noted for the Board's record-keeping, no more.
- DeepSeek also noted the A19 parenthetical is terse about the supersession. The full record sits where opus_check_691 verified it: corsair_A19.py's change log names the Nov 12 arrangement and R241's replacement of it explicitly. The commit message's "R241 is Ryan's later ruling" is a fair compression of that.
- If the weapon_match.json file is missing entirely, publish.py now dies on the open with a traceback instead of the clean refusal message. It still refuses (fail-closed), so this is cosmetic; naming the missing-file case in the same message would be tidier whenever the file is next touched. Blind Rey leg.

## Legs and gates

Blind Rey leg first (chair, no pack): GO, the missing-file note above. DeepSeek (DeepThink on, Search off, verified before and after): GO WITH CONDITIONS, both answered above. Flash (Gemini "Quick answers 3.5 Flash-Lite", verified selected before and after): GO. Qwen: seat empty, the Qwen3.8-Max daily limit was reached earlier in the evening (two confirmed attempts); no substitution was made. Grok: seat empty, bot wall at grok.com, the twenty-fifth consecutive empty seat. Both recorded, never filled.

## Not checked

The rest of the merge (the files it brought in from main are main's own content, not this commit's work), publish.py running against a real failed build folder, and whether PR 691's merge carried this commit's text unchanged.
