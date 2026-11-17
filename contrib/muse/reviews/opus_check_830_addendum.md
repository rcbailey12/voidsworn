# opus_check_830 addendum: KB1CC width verification on the R273 rebuild

Refs #256. Addendum to opus_check_830 (delivered Nov 15, 2026, at 9bc059f3), whose condition 2 owed a chair width verification when the R273 rebuild pushed to PR 830. PR 830 has since merged (Nov 16, 2026, 01:26 CST, final head 84d9129db, merge 51cb0bed9) with the rebuild and one further pass in it. Verified against the merged sheet on main: docs/ship_pipeline/build_sheets/corsair_KB1CC/ (README, checks.json, corsair_KB1CC_compare.jpg, viewed by the chair).

## The width judgment: R273 is answered

The rebuilt KB1CC measures 1.92 across the corner pods on a 1.60 length, 1.20 of the length (checks.json beam_top 1.922, PASS, outline overlap 81.3 percent). The first sheet held 0.98 across, 0.61, at the old beam guard. The new sheet is the render's width, as Ryan ruled at R273, and the sheet records the lift in its own header: KB1C-C's written terms stand except its beam guard, which R273 lifts for this craft. In the compare picture the build now carries the concept's broad, low stance instead of the narrow block the council saw; the wide glacis is the first thing that reads.

ChatGPT's addition to the condition (both bomb tubes still identifiable after the widening) holds: the two tubes sit at the glacis's extreme corners in dark armoured collars, visible in the compare and the fitted-camera inset.

The sheet carries one more pass the check did not see: R275 (Ryan, Nov 15, 21:28 CST, on the widened sheet: "Yes, send it back for those"). The top is now the concept's sloped glacis, low at the bow lip and rising aft to the stern bells with diagonal edge rails; height at the stern housing 0.38, against 0.27 when the top was flat. The ramp reads clearly in the compare.

Condition 3 of the original check (the plating note) is also closed as a record: the sheet now states that the pale trophy plates stay on the sheet as the pale zone and the Hullbreaker paint stack makes them dark grey metal for every ship under R274 (issue 726), which matches how the Board is landing R274 in the stack and in factions.md.

## Two Board calls the rebuilt sheet raises, carried forward

1. At its new width the bombers touch their wingmates in the game's wing formation: godot/render/squadron_wing.gd sets the offsets from the craft's length, about 0.95 of it sideways, and 1.20 of length across the pods no longer fits that spacing. The sheet flags it as a Board call (the formation, or the craft data that sizes it, needs a wider spacing for this bomber). The chair notes the overlap with the squadron formation work in PR 862 (item 4 of the current check batch): whether the arrowhead spacing accounts for the wide bomber belongs in that check's scope.
2. The ramp's front third runs between the shoulders: the shoulders' tops stand above the ramp from the bow to about station 0.13 to 0.19, so the rails start at the foot of the shoulders' inner walls and the ramp stands clear only a third of the way back. Lowering the shoulders' fore stations would bring the whole ramp into view. The sheet leaves it as a Board call; the chair agrees it is a look call, not a defect, and Ryan has the compare picture if he wants it.

With this addendum, every condition of opus_check_830 that depended on the rebuild is discharged. The remaining conditions (CS1BA2 outline rework, the data.js Chorus colour, sporeb ratification) stand as delivered.
