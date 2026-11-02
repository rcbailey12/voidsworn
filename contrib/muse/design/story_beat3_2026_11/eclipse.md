## Eclipse

### Core decision: The Count of Years

Scene purpose: One full backup window remains before the fight, and it cannot cover the admiral and the fleet both. Spending it on the admiral means a fall is restored whole; spending it on the fleet gives every hull its restoration pass and sends the admiral in on an old backup. A mind too long without a backup goes dark, the only death Eclipse recognises.

Node:
```
id:'arc_ec_count', t:'The Count of Years', fight:false,
o:[
 {t:'Spend the Archive window on the admiral', r:{xp:25}, tx:'The last full backup window before the fight goes to the admiral alone. If the admiral falls, the restoration will be whole. The rest of the fleet fights with gaps in its continuity and knows it.'},
 {t:'Spend the window on the fleet', r:{repair:.25}, tx:'Every hull gets its restoration pass and the admiral goes into the fight with an old backup and a quiet expression. "If I come back missing the last year," the admiral says, "tell me we won it. Tell me slowly."'}
]
```

Text lines:
- Admiral: "I have worn nine bodies and outlived my sun by a thousand years. Permanence is very long, Captain. Let us spend some of it correctly."

Debrief: "The fleet shows the last image of Ardent once more. This time, several ships hold it a moment past the minute."

Learning payoff: "Win or dark, the Archive keeps this fight in full. Eclipse does not send a new fleet out of the dark: it sends this same one again, its minds restored from the Archive with every lesson and correction intact."

### Admiral spotlights

- Nadir Aurex, Ninth Frame: "Aurex speaks last in every council and first in every battle. 'We remember noon,' Aurex says, and the great ring of plates around the core turns, very slightly, toward the enemy."
- Umbra Vessane, Third-Housed: "Vessane counts the enemy fleet aloud, hull by hull, in the voice of an archivist reading a list of known dead. In a sense, Vessane is."
- Ostrel of the Long Copy: "Ostrel has been copied more times than any mind in the fleet and has lost the least. 'Continuity is a discipline,' Ostrel says. 'Regret is what happens when you skip it.'"
- Seveth, Twice-Restored: "Seveth went dark once, for eleven minutes, and came back. Seveth does not discuss the eleven minutes. The fleet does not ask. Some restorations are private."

### Flags

- Node, second option: the source result text set the admiral's quoted words in single quotes inside a single-quoted string, which breaks the node literal, and the string never closed. The quoted words now use double quotes and the text is otherwise unchanged, so the node parses as shipped. Flagged by the Argon leg; no other leg caught it, and the Qwen leg reproduced the broken string verbatim.
- Learning payoff: the source line sent out a "next fleet" that "will not know the names of the minds that paid for them." That contradicts the settled Eclipse fiction: every mind is backed up in the shared Archive with its lessons intact, and Eclipse sends the same fleet again, corrected. The line now says exactly that. Flagged by the Argon leg and the blind Rey leg.
- Vessane spotlight: the source line read "someone reading a list of the dead they once knew," a pronoun for an unnamed character. Now "an archivist reading a list of known dead." Flagged by the Argon leg; the Qwen leg flagged the pronoun as well.
- Ostrel spotlight: the source line read "'Grief is what happens when you skip it.'" Bible 1.3 splits the shared grief: the Glasswrights mourn, Eclipse regret. The line now reads "'Regret is what happens when you skip it.'" Flagged by the Argon leg; the DeepSeek leg also rewrote the line.
- Context only, not beat 3 content and not changed here: the finale mechanic text speaks of "its crew's minds," but bible 7.2 gives Eclipse minds, bodies and backups, never crews; and the Nemesis introduction describes "plate over trapped light," using the Glasswrights' light. Flagged by the Argon leg.
