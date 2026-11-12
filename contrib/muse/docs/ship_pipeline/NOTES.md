# Part D fix 2 (issue 558): RECIPE.md retired outline gate

Two edits in the copy of docs/ship_pipeline/RECIPE.md in this folder:

1. Stage 3's row in the stage table: "Gate: 90 percent overlap, and each third at least `outline_third_slack` (default 5) below it" now reads "Reported score: the outline overlap (not a pass bar since R147, RULEBOOK 5.8; the stage still exits non-zero below 0.90 until the workhorse fix lands), and each third at least `outline_third_slack` (default 5) below it".
2. The per-ship data list: "`outline_gate`: 0.90" now carries the note "(the scoring threshold the stage still enforces in code; as a rule the overlap is reported, not a pass bar, RULEBOOK 5.8)".

Why: RULEBOOK 5.8 records that the outline overlap is reported, not a pass bar; the 90 percent bar was retired by R147. RECIPE.md still stated it as a gate. Caught by the DeepSeek leg of the issue 558 Part B method audit, verified verbatim by the chair (method_audit_2026_11_12.md, Finding 3). Lines that describe the code's actual behaviour are deliberately untouched: the worked example's "the outline stays at 90 percent or better" and the standing checks table's "each at least the gate minus `outline_third_slack`" both describe what the stage code does today, and ships.md section 4 already records the transitional state.
