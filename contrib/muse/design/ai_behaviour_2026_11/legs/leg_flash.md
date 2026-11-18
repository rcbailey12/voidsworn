# Leg: Flash (Gemini, "Quick answers 3.5 Flash-Lite", signed in; picker verified before and after)
# AI behaviour improvements, issue 1048. Model's response, verbatim.

## 1. Noticeable AI Behaviour Problems

Players can directly perceive specific flaws in the current enemy AI architecture, backed by the test findings and simulation evidence:

- **The Suicidal Carrier Launch (AI-5):** Carriers launch strike wings in their pre-move step into high-threat hexes (e.g., 9 expected threat) solely because it's the closest hex to the enemy, only to move away and instantly leave their launched wings isolated and vulnerable. A player immediately notices a carrier tossing away valuable assets into immediate crossfire.
- **The "Zombie" Advance with Empty Guns (AI-4):** Ships whose weapons are completely spent or reloading (such as a torpedo boat) continue to aggressively close distance straight toward the player's firing line rather than kiting or holding range. Players see defenseless or reloading ships mindlessly marching into danger because the approach leash calculates distance on *all* weapons rather than *bearing* weapons.
- **The Frigate-Priced Capital Death (AI-3):** The death-cliff penalty for entering a lethal hex is a flat -25 regardless of ship value. A cheap CP1 frigate and an expensive CP5 capital ship evaluate self-destruction identically, leading to capital ships casually accepting lethal damage trades that only make tactical sense for throwaway screening units.
- **The Phantom Veteran Brace (AI-1):** Veteran ships under heavy threat with spent guns choose to close distance and fire nothing, completely bypassing their veteran brace checks due to conflicting condition checks across multiple scattered functions (mid-move volley path vs. post-volley fallback vs. `aiVetBrace`). Players experience "veteran" enemies behaving bizarrely by ignoring defensive bracing when cornered.
- **The Magnetized Fleet Beeline and Clump (Sim Evidence):** The movement scorer acts as a single combat-value attractor on big maps, pulling both fleets toward each other until they devolve into predictable mid-map slugfests where flanking maneuvers or objective-based play are impossible. Objective variants failed to spread the fleets because the scorer cannot see off-fleet objective value, only combat value for the moving ship. On the feel side, at base stats, 91-94% of post-contact activations already move - the frustration isn't static fleets, it's that the moves are tiny (2.3-2.8 hexes) and tactically meaningless.

## 2. Ranked Improvement Ideas (by Player Feel)

### 1. Value-Scaled Death-Cliff Penalties (AI-3)
- **What changes:** Scale the death-cliff avoidance penalty by ship replacement/combat value (e.g., multiply the flat -25 by CP cost or hull value) so capital ships actively avoid lethal hexes while cheap screening frigates can still make sacrificial trades.
- **Benchmark & Mechanism:** *Total War* series (Unit Preservation / Route Thresholds) - higher-value high-tier units actively retreat from lethal engagements to preserve their cost, while chaff units are expended. This makes value-based risk assessment legible: you see expensive ships protecting themselves.
- **Build Cost:** **Small** - Simple parameter weighting adjustment inside the existing threat/death-cliff scoring function.
- **Sim Harness Proof:** Check veteran survivor counts and capital ship loss rates on high-difficulty maps; capital losses should drop while frigate losses remain stable, with no drop in player win rate.

### 2. Bearing-Aware Approach Leash (AI-4)
- **What changes:** Modify the approach leash to calculate minimum range only from weapons that actually have bearing and can fire, ignoring spent/reloading weapons. A ship with no ready guns will hold position or kite away instead of charging into the player's guns.
- **Benchmark & Mechanism:** *Homeworld* series (Standoff & Kiting Behaviour) - ships evaluate weapons readiness before committing to an approach, maintaining their preferred firing range only when they can actually engage.
- **Build Cost:** **Small** - Fixes the input filter on the `minR` calculation in the movement scoring block.
- **Sim Harness Proof:** Measure average distance to enemy maintained by reloading/torpedo-only ships; ships with spent weapons should maintain distance rather than closing 10 to 6 hexes, and deaths while reloading should drop.

### 3. Post-Move Carrier Launch Sequencing
- **What changes:** Shift carrier wing deployment from the pre-move step to a post-move or conditional safe-launch check, where the carrier evaluates launch hexes *after* it moves and only launches into low-threat hexes.
- **Benchmark & Mechanism:** *Battlestar Galactica Deadlock* (Carrier & Squadron Management) - deployment zones are evaluated for safety after fleet positioning, not before, so wings spawn in protected positions that support the carrier's new location.
- **Build Cost:** **Medium** - Requires reordering the activation sequence step for carriers to evaluate launch hexes post-move.
- **Sim Harness Proof:** Track strike wing survival rates in the first 2 rounds post-launch; wing survival should increase, and wings launched into threat hexes above 5 expected threat should fall to near zero.

### 4. Consolidated Veteran Brace Priority Fix (AI-1)
- **What changes:** Unify the three conflicting brace evaluation checks into a single clean gate at the start of the activation (before movement), where a veteran ship under heavy threat (incoming threat >45% of HP, own offense <35% of that threat, hull <70%) will brace instead of moving to fire.
- **Benchmark & Mechanism:** *Into the Breach* (Defensive Intent Prioritization) - defensive states lock in before offensive movement decisions are made, making the AI's defensive intent readable to the player.
- **Build Cost:** **Medium** - Deduplication and clean-up of scattered condition sets across `aiUnit`, mid-move checks, and `aiVetBrace`.
- **Sim Harness Proof:** Monitor veteran ship longevity and damage-taken-per-round ratios; veteran survivability should improve and unbraced ships under high threat (e.g., 32 expected threat at 63% hull) should become rare.

### 5. Objective-Aware Score Bumping
- **What changes:** Inject an off-fleet objective scoring term into candidate hex evaluation that scales with the objective's value, allowing the scorer to see and value non-combat hexes. This breaks the single-attractor beeline by giving ships a reason to diverge toward objectives.
- **Benchmark & Mechanism:** *Stellaris* / 4X Tactical AI (Strategic Objective Weighting) - AI weights capture and control objectives alongside combat value, leading to divergent fleet movements that create flanking opportunities.
- **Build Cost:** **Large** - Requires tuning objective weights against combat scores to avoid the performance penalty seen with multiplicative scoring (player win rate jumped from 5/24 to 13/24) and to prevent objectives from distracting the AI from combat.
- **Sim Harness Proof:** Measure map spread (clustering index) and objective control distribution across multiple map sizes; fleet spread and objective diversity should improve without the player win rate spiking as it did with multiplicative scoring.

## 3. Recommended First Three (In Order)
1. **Value-Scaled Death-Cliff Penalties (AI-3)**
2. **Bearing-Aware Approach Leash (AI-4)**
3. **Consolidated Veteran Brace Priority Fix (AI-1)**

### Why this order matters:
- **Foundational Logic Integrity First:** Fixing AI-3 and AI-4 eliminates glaring, immersion-breaking tactical errors that undermine player trust in the AI's basic competence. These are low-cost fixes that address the most visible "dumb AI" moments - capital ships suiciding and empty ships charging - before any higher-order behaviour is tuned.
- **Veteran Consistency Second:** Once baseline movement sanity is restored, fixing the veteran brace bypass ensures the veteran tier actually feels different and smarter. This prevents the player from seeing the "elite" AI making rookie mistakes after the cheaper fixes have raised expectations.

## 4. Anti-Patterns & Feel Traps to Avoid
To keep the AI fun, readable, and fair, avoid these traps:
- **Hyper-Optimized Kiting (The "Untouchable Stutter-Step"):** If the approach leash or fade moves are over-tuned, enemy ships will perpetually kite at maximum range, turning battles into tedious chases where the player can never close. This makes the AI feel cowardly and the game feel stalled rather than tactical.
- **Opaque Defensive Bracing ("Invincible Bricks"):** If veteran brace timing becomes unpredictable or overly frequent, players will face ships that seem arbitrarily invulnerable. Bracing should be telegraphed and tied to visible hull/threat states, not hidden calculations.
- **Objective-Camping Stalls:** If objective weights are cranked too high in an effort to fix clumping, fleets will sit on objectives and refuse to engage, creating a stalemate where neither side fights. This repeats the spread-vs-combat tradeoff seen in the multiplicative scoring test, where battles ran 1.5 rounds longer (9.5 to 11.0 median) because less damage landed per round.
