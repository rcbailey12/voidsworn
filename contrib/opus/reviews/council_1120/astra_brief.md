# Astra pass (held until the Board confirms)

One gpt-6.2-astra run (openai arm on the PC, $8 in and $40 out per million tokens; Ryan has one shot in the next two days).
Not started until the council's ranked list exists and the Board says go.

Budget (Ryan, Nov 20 16:59 UTC: about $33 left on the key): hard stop at $30 in the spend ledger (Ryan, Nov 20 17:00 UTC). Model gpt-6.2-astra, effort high (not xhigh: extra thinking is billed as output at $40 a million). Scope is focused, not the whole
repo: the ranked list, the Godot dev legs, and godot/scenes/battle, godot/render, godot/main, godot/world plus the fx files the
legs name (about 250k tokens). Expected $14 to $20 at the Nov 17 price at high effort.

Input: draft_ranked_list.md (its "Engineering items for Astra" section first) and fable/legs/fable_godot_dev.md, plus the Godot dev seat's questions for Astra.

Job: the deep engineering and Godot pass the council could only point at. For the top items with an engineering cause,
find the cause in the code, confirm it with a run where possible, and give the smallest fix. Then a whole-codebase pass for
what an expert Godot engineer would fix before shipping to strangers' PCs: frame time, loading, memory, export and driver
safety. Findings only, file:line for every claim, no code changes. Write contrib/openai/astra_council_1120/report.md.
