## Eclipse

### Core decision: The Final Backup Window

Node:
```
id:"arc_ec_count", t:"The Final Backup Window", fight:false,
o:[
 {"t":"Reserve the last clean Archive sync for the command frame","r":{"xp":25},"tx":"You lock the high-bandwidth uplink onto the flagship's bridge core before committing to the stellar frame. If the command hull breaks, your tactical memory survives intact; the escort minds go in knowing they'll wake missing months."},
 {"t":"Spread the Archive pass across the escort crews","r":{"repair":0.25},"tx":"You divert the backup window and repair swarms across every escort in the line, leaving your own mind running on an older stamp. 'If I wake up missing this sector,' you signal across the formation, 'tell me whether the new sun lit.'"}
]
```

Text lines:
- Flag officer: "The stellar frame sits dead ahead, Commander, waiting on the last cores. Interference from Ardent's gravity well gives us bandwidth for one clean Archive sync before contact."
- Commander: "A thousand years in cold metal teaches you what's worth preserving. Allocate the window and bring the corona arcs online."

Debrief: "Before opening fire, every ship displayed the last optical capture of Ardent's noon across its bridge glass, holding it three seconds past regulation."

Learning payoff: "Win or lose, the Archive retains this entire engagement. Eclipse won't send strangers back to Ardent's rim; it will wake this exact fleet again with every mistake corrected."

### Admiral spotlights

- Nadir Aurex, Ninth Frame: "Aurex's monumental ring of floating plates shifts half a degree toward the stellar frame, white-gold light steady behind the visor."
- Umbra Vessane, Third-Housed: "Vessane counts the opposing hulls one by one, verifying every hull's drone-weld tolerance against a thousand-year ignition chart."
- Ostrel of the Long Copy: "Ostrel trims every stray emitter down to background noise. 'Continuity takes discipline; panic is what corrupts a backup.'"
- Seveth, Twice-Restored: "Seveth checks the twice-welded bow plates and signals ready. After two restorations, another siege at Ardent's rim feels almost routine."

### Flags

- Node, second option: the source result text set the admiral's quoted words in single quotes inside a single-quoted string, which breaks the node literal, and the string never closed. The quoted words now use double quotes and the text is otherwise unchanged, so the node parses as shipped. Flagged by the Argon leg; no other leg caught it, and the Qwen leg reproduced the broken string verbatim.
- Learning payoff: the source line sent out a "next fleet" that "will not know the names of the minds that paid for them." That contradicts the settled Eclipse fiction: every mind is backed up in the shared Archive with its lessons intact, and Eclipse sends the same fleet again, corrected. The line now says exactly that. Flagged by the Argon leg and the blind Rey leg.
- Vessane spotlight: the source line read "someone reading a list of the dead they once knew," a pronoun for an unnamed character. Now "an archivist reading a list of known dead." Flagged by the Argon leg; the Qwen leg flagged the pronoun as well.
- Ostrel spotlight: the source line read "'Grief is what happens when you skip it.'" Bible 1.3 splits the shared grief: the Glasswrights mourn, Eclipse regret. The line now reads "'Regret is what happens when you skip it.'" Flagged by the Argon leg; the DeepSeek leg also rewrote the line.
- Context only, not beat 3 content and not changed here: the finale mechanic text speaks of "its crew's minds," but bible 7.2 gives Eclipse minds, bodies and backups, never crews; and the Nemesis introduction describes "plate over trapped light," using the Glasswrights' light. Flagged by the Argon leg.
