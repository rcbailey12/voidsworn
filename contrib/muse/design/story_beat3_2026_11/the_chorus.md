## The Chorus

### Core decision: The Second Throat

Scene purpose: Crucible, the Hunger Below, is in range, and the swarm must decide what Memory is for. Letting Memory speak to the core gains its protocols and dulls Hunger's edge in the fight; closing the second throat makes the swarm stronger and smaller forever.

Node:
```
id:'arc_ch_crucible', t:'The Second Throat', fight:false,
o:[
 {t:'Let Memory speak to the core', r:{core:1, dmgPctDown:1}, tx:'Memory speaks to Crucible in the voices of our makers, and the core answers an old name. Protocols come like remembered food. But Hunger hesitates at the kill now, listening for a voice under the hunger. We will hesitate in the fight.'},
 {t:'Close the second throat', r:{dmgPctUp:1}, tx:'We close Memory for the fight. The swarm is one throat, one want, nothing wasted. We are faster and emptier. Something that knew our name is quiet, and the quiet is also a kind of food.'}
]
```

Text lines:
- Memory: "We were made to kill the sun-thieves. We remember their faces. They had our faces."
- Hunger: "Faces are meat. Throats are meat. Choose."
- The swarm: "We choose what the next brood keeps."

Debrief: "Every throat in the swarm tastes the decision. The young taste it first."

Learning payoff: "Win or lose, the next generation is grown from this choice in its flesh. Broods after this one will be born knowing whether the swarm feeds its memory or eats it."

### Admiral spotlights

- The Matriarch of Nine Throats: "The Matriarch opens all nine throats before the fight, tasting the dark in every direction at once. The swarm goes still. Prey is near."
- Razormaw: "Razormaw goes first and comes back last, trailing torn plate between hot teeth. Hunger approves. Memory counts the missing and approves of nothing."
- Mending Throng: "Mending Throng knits the swarm closed between volleys, patient as weather. 'We are not finished,' the Throng says, in many voices. 'We are never finished.'"
- Voice of the Deep: "The Voice speaks from the dark under the brood, where the voices of our makers pool. Every throat answers the Voice without deciding to. 'Deeper,' the Voice says. 'The warm thing is deeper.'"

### Flags

- Node, first option: the source result text read "in the makers voices," unpunctuated (a possessive apostrophe would break the single-quoted string), and closed "It will hesitate in the fight," a pronoun for Hunger outside the Chorus "we" register. The text now reads "in the voices of our makers" and closes "We will hesitate in the fight." Flagged by the Argon leg.
- Razormaw spotlight: the source line trailed torn plate "in its teeth," a pronoun for a named admiral. Now "between hot teeth." Flagged by the Argon and Qwen legs.
- Mending Throng spotlight: the source line used "it says" for a named admiral; now "the Throng says." The spotlight is keyed under the shipped data.js display name, Mending Throng; the story pack header carries "The Mending Throng," which does not match the shipped name and is flagged for correction alongside the Steelgrin header. Pronoun flagged by the Argon and Qwen legs.
- Voice of the Deep spotlight: the source line spoke "from the cold under the fleet." Cold belongs to the Sunward Crusade under bible 1.3, and the line also carried pronouns for the Voice. The line now speaks from the dark under the brood and names the Voice throughout. Flagged by the Argon and Qwen legs.
- Learning payoff: the source line did not say the learning lands after a loss. "Win or lose" is now explicit, and "in its flesh" is restored from the settled Chorus fiction, where the next swarm is born already knowing in its flesh. Flagged by the Argon leg.
- Not adopted: the DeepSeek leg rewrote the Memory text line ("sun-thieves" became "thieves of the warm places"). The Chorus charge in the same source reads "The sun is remembered," so the Chorus carries its own sun reference, and the line names the makers' enemies rather than the Eclipse lost sun. The other three legs kept the source line, and so does this delivery.
- Context only, not beat 3 content and not changed here: the finale context introduces the Nemesis with a fixed pronoun ("It comes out of the dark") and "no lights." Owner ruling 2 allows the tokens {rival}, {He}, {his} only, and light belongs to the Glasswrights. Flagged by the Argon leg.
