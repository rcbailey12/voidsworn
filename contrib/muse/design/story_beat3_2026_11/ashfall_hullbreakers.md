## Ashfall Hullbreakers

### Core decision: Rook in the Wreck Field

Node:
```
id:"arc_hb_rook", t:"Rook in the Wreck Field", fight:false,
o:[
 {"t":"Hold heavy guns off the core and breach for Rook intact","r":{"dmgFlag":0.15,"core":1},"tx":"Your gunners hold fire on the core's containment cage while your flagship eats the return salvo head-on. If your crews drag Rook out of those wrecks in chains, every den in the Ashfall will hear about it."},
 {"t":"Open every weapon and smash straight through","r":{"xp":25},"tx":"Nobody holds back for clean salvage. Your crews push the reactors red-hot and tear into the enemy line full tilt, ready to crack the wrecks and Rook right along with them if that's what winning takes."}
]
```

Text lines:
- Howler: "Scope lock confirmed, Warlord! R-5 Rook's sitting right in the middle of that wreck pile, pulsing hotter than a cruiser core!"
- Warlord: "Good! Means we didn't haul all this iron across three sectors for nothing. Arm the breach clamps!"

Debrief: "No cheering on the open band after the guns cool. Just captains tallying kills, hauling intact plates, and checking who didn't make it back."

Learning payoff: "The plates bolted to your hulls tell the whole belt what worked out here, and the next pack that hunts the Hollow Sun will study every weld seam."

### Admiral spotlights

- Warlord Grax Ironmaw: "Grax slams the throttle past the redline and laughs over open comms as the breach clamps bite into enemy plate, half the pack howling back on the same channel."
- Sable the Smiling Knife: "Sable kills all exterior lights until only the red cockpit glow remains. 'Big proud ships always forget to armor their radiator vents.'"
- Old Mott: "Old Mott spits a chewed rivet pin into a scrap bucket and checks the bay telemetry. 'Forty captains tried taking my command chair. Don't make me count to forty-two today.'"
- Vesh the Collector: "Vesh zooms the tactical feed onto the opposing flagship's bow trim, muttering measurements to her weld crew. 'Don't you dare slag that dorsal array!'"

### Flags

- Spotlight header: the story pack header reads "Warlord Grax Steelgrin." The shipped data.js display name is Warlord Grax Ironmaw (owner ruling 3, the Oct 27 rename applied in data). Ironmaw is used here, and the story pack header is flagged for correction. All four legs caught this one.
- Node, second option: the source label and result text used sea language for a destroyed flagship ("sink it all," "goes down with the flagship," "The biggest ones sink"). Ships here are space ships and the lint bans naval metaphor, so the option now reads "break it all" and the result text runs on breaking and scrap, the pack's own idiom. Reward unchanged: xp:25. Flagged by the Argon leg.
- Grax spotlight: the source line ran "teeth-first" with claws that "bite." Teeth and hungry bite imagery belong to the Chorus under bible 1.3. The line now runs on claws, grapples and torn plate. The blind Rey leg and the Argon leg both flagged the teeth; the Argon wording is adopted.
- Sable spotlight: the source line brought Sable in "from behind the light" and "smiling with every tooth." Light belongs to the Glasswrights and teeth to the Chorus under bible 1.3. Sable now comes in out of the dark, matching the shipped Command name, Knife in the dark, with a blade-thin smile. Flagged by the blind Rey leg and the Argon leg.
- Learning payoff: the source line covered only what the pack takes from a fight. The settled Hullbreaker fiction carries what killed the pack in the open as well, and R62 requires the learning to land after a loss, so the line now carries both, with the trophies, the dens and the next litter. Flagged by the blind Rey leg.
