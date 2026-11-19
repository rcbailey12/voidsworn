# Blind leg: Rey (written before any council leg, from the evidence pack only)

## Problems a player notices, tied to evidence

1. Veteran ships die dumb: they end turns unbraced in obvious danger (AI-1, BLOCKER at the findings pin). The brace decision lives in three places with three different condition sets, so whether a hurt ship braces depends on which path its activation happened to take. A player reads this as the AI not knowing it is about to die.
2. A frigate and a capital price death identically (AI-3, measured: both first accept the same lethal hex at kill value 40). Cheap ships are too careful or capitals too careless; either way target and movement choices look wrong for the ship's value.
3. Torpedo ships charge into gun range with nothing loaded (AI-4, measured: closed 10 to 6 against unarmed targets). The approach leash reads all weapons including spent ones, so a ship with no bearing gun behaves like a brawler.
4. Wings launch into kill zones and get left behind (AI-5, measured: launch into 9 expected threat with safe hexes available, from the pre-move position). Carrier play reads as free kills for the player.
5. The whole fleet beelines and clumps (sim, map package): one attractor in the scorer, no ship prices what its fleet-mates are already doing or what ground is worth holding. Battles feel like two mobs colliding, whatever the objective says.
6. Spread fixes cost combat power (sim retests): multiplicative scoring and two-pass both move the fleet more and fight worse when the AI alone adopts them (player wins 5/24 to 13/24 against multiplicative; about 1.5 rounds longer). The AI has no way to buy positioning without paying damage it cannot afford.
7. Damage spreads instead of finishing (partially evidenced: the veteran focus is a sticky fleet target checked once per activation; nothing in the scorer prices a kill-securing shot on a nearly dead ship above fresh damage elsewhere). Marked as the weakest-evidenced item here; the harness can measure it before anyone builds on it.

## Ideas, ranked by player feel

### 1. One brace decision, priced by ship value (fixes AI-1 and AI-3 together)
Collapse the three brace sites into one decision evaluated at the same point for every activation path, and scale the death cliff by the ship's value (CP, or CP against remaining hull), so a cp5 capital refuses a lethal hex a cp1 frigate may accept. Feel: the AI stops donating capitals and stops hiding frigates; hurt veterans visibly dig in. Games: BattleTech's AI and XCOM 2 both gate retreat and defence by unit value and remaining health in one place, which is why their hurt heavies fall back instead of wandering. Cost: small (one decision point, one scaled constant; the findings tests already pin the acceptance checks). Proof: AI-1 and AI-3 tests pass; harness duel set shows capital survival up, frigate aggression unchanged.

### 2. Launch after movement, from the safest good hex (fixes AI-5)
Move wing launch to the post-move ability step and score launch hexes by threat first, distance second. Feel: wings stop being free kills and carriers stop stranding them. Games: FTL and Battletech carrier play both treat launch position as the decision; Into the Breach teaches the readability half: a launch the player can predict is fair, a launch into a kill zone just looks broken. Cost: small to medium (ability step already re-runs after the move; the launch hex picker gains a threat term). Proof: AI-5 test passes; wing survival per launch in the harness.

### 3. The leash reads ready weapons only (fixes AI-4)
The approach pull should be computed from weapons that can fire this activation; a ship with only a reloading torpedo holds at torpedo range or kites instead of closing. Feel: torpedo ships behave like torpedo ships, the single most readable class behaviour in the game. Games: any naval or submarine game (Cold Waters, Rule the Waves) where a spent platform keeps its distance; StarCraft's siege units never walk into range unloaded. Cost: small (the ready list already exists in the activation). Proof: AI-4 test passes; minimum-range violations per battle in the harness.

### 4. An objective-aware scorer (the attractor fix)
Teach the movement scorer to price ground: a candidate hex gains value for objective coverage the fleet does not already have (nearest-fleet-mate distance to the same objective, unheld site value), so ships distribute across sites instead of stacking one attractor. This is the untested step 3 from the map package and the only idea here aimed at how battles LOOK, not just how ships die. Games: Company of Heroes and Dawn of War, where AI squads fan across capture points because the points themselves carry the value; Total War's AI holding multiple objectives in siege play. Cost: medium to large (new scoring term plus tuning; the harness work is the real cost). Proof: the map package's own metrics: coverage and clustering improve on 34x24 and 38x26 WITHOUT the win-rate and rounds costs the multiplicative retest paid; if it pays those costs too, it fails its own bar.

### 5. Adopt multiplicative scoring with an offense floor
The retest showed multiplicative scoring spreads fleets but taxes damage. Pair it with a floor: a candidate whose offense falls below a fraction of the ship's best-hex offense is rejected unless no firing hex exists, so spread is bought only when it is cheap. Feel: fleets manoeuvre like the package's best rows without the 1.5 extra rounds of slap-fighting. Games: this is the classic XCOM lesson in reverse: positioning terms must never fully outvote the shot. Cost: medium (the multiplicative form exists in the retest patch; the floor is one gate). Proof: rerun the exact retest spec; pass bar is coverage gains kept with player win rate and median rounds back near base.

### 6. Kill-securing weight
Add a scorer term that prices finishing: expected damage beyond a target's remaining hull is wasted, and a shot that kills removes that ship's whole next activation, so targets near death gain value in evalOffense for veterans. Feel: the AI focuses like a player does; damaged ships stop surviving on 3 hull to fire again. Risk: reads as cruelty at normal difficulty, so veteran only. Games: XCOM's AI overkills rookies for exactly this reason; Slay the Spire's elites teach the player-side version. Cost: small to medium (offense evaluation gains a target-value term). Proof: overkill waste and time-to-first-kill metrics; watch that player frigate loss rate does not spike past the fairness bar.

### 7. Threat memory: do not re-enter last turn's kill zone without a reason
The fade move exists, but nothing stops a ship fading out and drifting back next activation. A one-turn memory of the hexes that hurt it (decaying threat bonus) makes movement look intentional across turns. Feel: ships look like they learn inside a battle. Games: Fear and F.E.A.R.'s squad memory is the famous version; Battletech's AI remembers firing positions per lance. Cost: medium (per-ship state plus decay tuning). Proof: repeat-exposure metric (activations ending in a hex threatened last turn by the same foe) falls; no change in battle length.

## Recommended first three

1, 2, 3 in that order: they are the tested defects, each with an acceptance test already written, each cheap, and each removes a moment where the player watches the AI do something plainly stupid. Idea 4 is the biggest prize and the right fourth job, scoped as its own measured experiment with the map package's metrics as its pass bar. Ideas 5 to 7 are seasoning after the defects are gone.

## What would feel worse

Kill-securing (6) at normal difficulty and any version of 4 that makes the AI camp objectives without engaging: both play better and feel worse. The AI's job is to lose interestingly at normal and press hard at veteran; every idea above should be graded on that split, not on raw win rate.
