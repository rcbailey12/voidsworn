## The Chorus

### Core decision: The Two Throats at Ardent

Node:
```
id:"arc_ch_crucible", t:"The Two Throats at Ardent", fight:false,
o:[
 {"t":"Let Memory call out to the Lattice cores","r":{"core":1,"dmgPctDown":1},"tx":"Memory reaches toward the Hollow Sun using the dead Fleshwrights' old access codes, and a dormant core responds with fresh protocols. Yet the borrowed maker cadence makes our hunter broods hesitate a fraction of a second on the kill."},
 {"t":"Drown Memory and let Hunger take full control","r":{"dmgPctUp":1},"tx":"We clamp the old maker voices shut under layers of fresh tissue. The swarm surges forward faster and cleaner, pure thermal predation aimed straight at the cores."}
]
```

Text lines:
- Memory: "Ardent's ruins... our makers grew us in cold vats to punish Eclipse for killing this star. We still remember their control ciphers."
- Hunger: "Ciphers don't fill brood-sacs. Five hot cores sit right behind that fleet. Tear through!"
- The Swarm: "One choice shapes the next clutch we hatch."

Debrief: "Every brood-chamber in the swarm absorbs the chemical shift before the spores even settle."

Learning payoff: "Win or lose, the next swarm grown from our surviving spores carries that balance straight into its neural sacs."

### Admiral spotlights

- The Matriarch of Nine Throats: "The Matriarch opens all nine brood-valves toward the black hole's rim, drinking the stray radiation while her young stir against the membranes."
- Red Undertow: "Red Undertow surges ahead of the main cluster with scorched hull plating still stuck to its forward spines, impatient to close."
- Mending Throng: "The Mending Throng knits fresh chitin across every scarred seam between jumps, keeping the swarm whole for the final push."
- Voice of the Deep: "Under the wet thrum of acid sacs, the Voice broadcasts a single broken Starwright launch coordinate that makes enemy sensors glitch."

### Flags

- Node, first option: the source result text read "in the makers voices," unpunctuated (a possessive apostrophe would break the single-quoted string), and closed "It will hesitate in the fight," a pronoun for Hunger outside the Chorus "we" register. The text now reads "in the voices of our makers" and closes "We will hesitate in the fight." Flagged by the Argon leg.
- Razormaw spotlight: the source line trailed torn plate "in its teeth," a pronoun for a named admiral. Now "between hot teeth." Flagged by the Argon and Qwen legs.
- Mending Throng spotlight: the source line used "it says" for a named admiral; now "the Throng says." The spotlight is keyed under the shipped data.js display name, Mending Throng; the story pack header carries "The Mending Throng," which does not match the shipped name and is flagged for correction alongside the Steelgrin header. Pronoun flagged by the Argon and Qwen legs.
- Voice of the Deep spotlight: the source line spoke "from the cold under the fleet." Cold belongs to the Sunward Crusade under bible 1.3, and the line also carried pronouns for the Voice. The line now speaks from the dark under the brood and names the Voice throughout. Flagged by the Argon and Qwen legs.
- Learning payoff: the source line did not say the learning lands after a loss. "Win or lose" is now explicit, and "in its flesh" is restored from the settled Chorus fiction, where the next swarm is born already knowing in its flesh. Flagged by the Argon leg.
- Not adopted: the DeepSeek leg rewrote the Memory text line ("sun-thieves" became "thieves of the warm places"). The Chorus charge in the same source reads "The sun is remembered," so the Chorus carries its own sun reference, and the line names the makers' enemies rather than the Eclipse lost sun. The other three legs kept the source line, and so does this delivery.
- Context only, not beat 3 content and not changed here: the finale context introduces the Nemesis with a fixed pronoun ("It comes out of the dark") and "no lights." Owner ruling 2 allows the tokens {rival}, {He}, {his} only, and light belongs to the Glasswrights. Flagged by the Argon leg.
