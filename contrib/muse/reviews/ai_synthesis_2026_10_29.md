# Enemy AI and fleet generation audit - synthesis (Oct 29 program)

Four prongs: Qwen COMPETENT BUT HOLLOW, DeepSeek COMPETENT BUT HOLLOW, Argon COMPETENT BUT HOLLOW, Rey (blind) COMPETENT BUT HOLLOW. Four identical verdicts from four independent reads.

## Verdict: COMPETENT BUT HOLLOW (4 of 4)

The veteran battle brain is genuinely real: sticky focus fire, per-gun target re-picks with hull-capped damage, overkill handoff, threat-priced movement. Around that core, composition is a lottery, targeting cannot be read or baited, and the clever half is switched off for the players who meet the game first.

## Findings that stand

1. The brace bypass (Argon; chair verified at battle.js:1385-1387; independently found by the blind Rey leg). When a veteran ship moves with a path and mid-move fire is on, the move's late volley is stored and aiUnit returns before the veteran pre-fire brace decision, which is only reached when no volley was stored. The in-path fallback braces only when the volley fired nothing. Net effect: the brace decision is bypassed for every moving ship that shoots, which is most veteran activations. This is the item's strongest verified defect. Attached question for Opus (one line): nothing in the repo sets NOMIDFIRE outside that same line, so Argon's sim-divergence half is latent, not evidenced; confirm whether any harness sets it.

2. Composition has a readable outline and a random interior (DeepSeek; Rey in nearly the same words). Each archetype contributes exactly one act of intent (a seeded carrier, a seeded big hull, a swarm filter); the rest of the budget is weighted random CP filling with no role composition, no screen or escort logic, and no anti-wing answer. Argon sharpens it: under the light-fleet weights, carrier and default archetypes dissolve into 1-2 CP chaff, and the ceiling loop can strand budget (its magnitude is INFERRED; carry as a measured check for Opus, not an established defect).

3. Targeting is a blended scalar with no readable priority (Qwen, DeepSeek). Offense minus threat-weighted terms produces focus that works but cannot be anticipated, so the player cannot bait, screen, or sacrifice a hull deliberately. The one readable exception is Nemesis-only (nemTargetBonus), which was out of this item's scope. The proposed direction from two legs: a visible priority rule the player can play against, not a smarter scalar.

4. The cleverness is veteran-gated (Rey). Fresh profiles start on Standard AI with the focus, death-cliff, and brace machinery off, so new players meet the hollow version of the AI and the readable version only later. Combined with the first-run findings, the game's teaching problem and its AI problem are the same problem at the start.

5. Smaller verified mechanics: the death cliff is a flat -25 unscaled to ship value (Qwen, chair verified); the power-feedback compression is real arithmetic (a ship must be about 1.55-1.6x reference power to hit the 1.3 cap; the 0.75-1.3 clamp binds only the feedback factor while elite, hunted, and bounty multipliers stack outside it, Rey); the approach leash pulls a ship with no bearing guns toward the player at -4 per hex beyond minimum range instead of kiting (Argon, READ-solid); the AI launches wings before moving, from launch hexes sorted only by distance, so a launch can be baited into a kill zone (DeepSeek, Argon in different forms).

## Chair resolutions (pack gaps, not defects)

Three headline-shaped claims dissolved against code the packs did not slice, in all cases a chair scoping miss, owned: RAMP.thin and RAMP.escort are live at battle.js:322-323 (thin is a spawn-time hull/shield/damage multiplier, sector 3 at 0.62 and boss escorts about 0.48 per the Rey read; escort multiplies thin in boss fights); wing stances ARE AI-controlled (aiStance at battle.js:617, called for every living enemy ship at enemy turn start); retreat is not an aiUnit decision but battle-level script (escort breaks, Nemesis breaks, rout endings). Argon's stances claim is therefore not carried. Ceiling semantics, stated cleanest by DeepSeek: RAMP.ceil is a total-board soft cap (ceiling minus up to 7 live player ships), so sector 3 enemy fleets run about 13-16 ships.

## For Opus (observations, not a gate)

- Fix or deliberately keep the brace bypass, knowing it currently disables a veteran decision for moving shooters.
- The composition lever both DeepSeek and Rey point at is role rules in the fill (screen, escort, anti-wing), not a global difficulty multiplier.
- One-read checks both Qwen and DeepSeek name: aiVolley's internals and evalOffense/evalThreat, which the packs did not slice.

## Designer questions

None requiring Ryan. Readable targeting is a design direction Opus can prototype; if a prototype changes how baitable the AI feels, that playtest call is Ryan's at the Godot build.
