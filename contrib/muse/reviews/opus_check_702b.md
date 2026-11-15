# Outside check: Board commit c352146f on codex/issue-92 (debrief tests follow the Muse design copy)

Verdict: GO WITH CONDITIONS.

This is the follow-up to opus_check_702's condition 1: the two suites that reported 46 PASS / 2 FAIL pinned pre-design copy, and this commit moves them onto the Muse debrief design's copy (contrib/muse/design/debrief_screen_2026_11/synthesis.md). The chair verified every changed assertion against the design text, and the move is real: the core sync progress line, the tier-up line, both empty states, and the panel headers are now the design's own words, and nothing the design states was weakened. One condition, in three parts, all the same shape: a few of the new assertions pin words or shapes the design does not contain, or stop short of the shape it does contain.

## Condition

1. The suites now certify copy the design never settled, in three places. (a) The fifth row header: the test requires "<h3>The record</h3>", but the design names row 5 "story payoff" (section 3.6; the row order at synthesis line 31 reads "5 story payoff"). The other four headers track the design's row names ("Doctrine and renown", "Core sync" and "Nemesis lesson" exact; "Lineage" shortens "lineage and tree progress"). (b) The empty-run regex accepts "All rewards owned." as the distance line; that sentence appears nowhere in the design. Section 4.7 writes lines for newly affordable, nothing newly affordable, and playtest, and is silent on the everything-owned state. (c) The lineage button's pending branch asserts the prefix "Choose (Name)'s level" and stops there; the design's label shape is "Choose (Name)'s level (N) skill" (section 6, synthesis line 165), so a build that rendered the button with no number and no "skill" would pass while breaking the stated shape. None of the three weakens an assertion past a line the design states (the design states no line for (a)'s header text or (b)'s state, and (c) is a prefix of the stated shape), but a test that pins un-designed copy is how pre-design copy becomes load-bearing again, which is the failure this commit exists to fix. Condition: the Board either ratifies "The record" as row 5's label, "All rewards owned." as the everything-owned line, and the button prefix as sufficient (and the design is amended to say so), or the assertions are brought to the design's words and full label shape.

## Verified as design-verbatim or design-following

- Core sync progress line: "(n) of (threshold) to (next tier)." and "Full sync, (n) protocols." are section 4.6's exact formats, replacing "(n) / (threshold) sync" and "(n) sync. Full sync reached." The tier-name assertion now expects the crossed tier's name on a tier-up, the current tier's at full sync, and otherwise the next tier's name, which is the name 4.6's progress line actually prints.
- The tier-up assertion, "(Core): crossed into (tier) this run at (n) protocols.", is 4.6's tier-up format word for word, and it is new, not a replacement.
- The core sync empty state: the old assertion required no Core sync panel at all when no cores ticked; the design renders row 3 with the line "No protocols taken this run." (3.4, repeated in the step list at synthesis line 191). The new assertion pins that line. DeepSeek asked whether the header should still render; the inheritance suite now asserts all five row headers unconditionally, so across the two suites it does.
- Panel headers "WHAT THIS RUN BOUGHT" and "Recorded" on an abandon are the design's own words (synthesis lines 41 to 44 and 175).
- The empty-run assertion's first half, "No renown earned this run", is 3.2's empty state verbatim; its "Next: " alternative is 4.7's nothing-newly-affordable line and "Playtest: everything unlocked" is 4.7's playtest line.
- Qwen asked whether the old assertions were removed or merely supplemented: chair-verified from the patch, the replaced lines carry minus signs in the diff. The old formats are gone.

## Notes

- The assertions check presence, not order: the tier-up line's "tier-up lines first" (3.4, 4.6) and the five rows' stated order cannot be checked with html.includes. A limit of the suites' form, not a defect of this commit. Blind Rey leg, DeepSeek and Qwen.
- The 4.6 progress-line assertion does not bind the core's name to the numbers on one line; the patron name is asserted on the same row two lines earlier, but html.includes cannot prove they are the same line. DeepSeek and Flash; the chair grades it a note because the row-level binding is present.
- Flash's indexing worry (FAVOUR_TIERS[tier+1] "might index past the target tier") is answered by the suite's own structure: that branch runs only when a next tier exists in the row computation, so tier+1 is the next tier by construction. Recorded, not adopted.
- The lineage button's other two branches ("Choose Command evolution" at capstone, "View admiral line" otherwise) pin implementation labels the design does not name; the design does not contradict them, and "View admiral line" is the pre-design shipped label retained. Blind Rey leg and DeepSeek.
- The commit message's claim that the Godot fixtures failed only because they derive from these suites is the Board's own statement; the chair did not re-run the Godot suites.

## Legs and gates

Blind Rey leg first (chair, no pack): GO WITH CONDITIONS, the condition above in its (a) and (b) parts. DeepSeek (DeepThink on, Search off, verified before and after): GO WITH CONDITIONS, converging on (a) and (b) and raising (c). Qwen (Qwen3.8-Max in the selector before sending and in the header after; single response): GO WITH CONDITIONS, raising (c) as its condition. Flash (Gemini "Quick answers 3.5 Flash-Lite", verified selected before and after): GO WITH CONDITIONS, converging on (a); its indexing point is answered above. Grok: seat empty, bot wall at grok.com, the twenty-first consecutive empty seat; recorded, never filled.

## Not checked

The suites actually passing at this commit (no run output in the fetched material), the Godot-side core_sync_test and inheritance_test fixtures, PATRONS colour rendering (3.4 specifies the core name in its PATRONS colour, which a text-inclusion suite cannot see), and any assertion outside the two diffs.
