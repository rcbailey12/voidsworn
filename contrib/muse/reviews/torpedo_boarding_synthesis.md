# Torpedo and boarding synthesis: DeepSeek + Qwen 3.8-Max (chair: Rey)

Job: draft hex-grid torpedo rules and boarding rules from the Rogue Trader verbs, without importing officer posts, preserving per-activation decision weight. Both legs filed under contrib/deepseek/reviews/torpedo_boarding_deepseek_draft.md and contrib/qwen/reviews/torpedo_boarding_qwen38max_draft.md. Screening notes in the goal hidden_files folder.

Chair verdict: GO WITH CONDITIONS, with a reframing both legs missed. Torpedoes and boarding both already exist in code. This is a revision job, not a greenfield design, and the merged proposal below is written as revisions to existing code paths. Nothing here should be implemented as a parallel system.

## What already exists (verified by grep, neither leg was granted code)

Torpedoes: data.js torp (dmg 42, range 6, accuracy 64, pierce .3, crit 15, cooldown 2, evasion multiplier 2), plus htorp and startorp variants and per-faction names. They fire instantly like other weapons. Flak exists as the "Point defense" weapon kind (range 2).

Boarding: boardTargets (battle.js:652) gates on adjacency (distance exactly 1), not braced, not already boarded, crew at or above max(4, 40% of crewMax), and no weapon fired yet. boardUnit (battle.js:667-679) runs an opposed crew-count roll with faction multipliers (BOARD_MULT, CREW_MULT), a repel flag (defender 2.25x instead of 1.5x), crew kill/loss math, and an asymmetric capture rule: enemy ships flip sides when their crew hits 0, but player ships are never captured (overrun path: bridge hold plus two systemDamage hits). systemDamage (battle.js:554) already covers engine (speed -1), shields (offline 2 turns), weapon (offline 2 turns), and fire (st.fire = 2, ticking fireDmg at turn start). Crew exists as counts: crewMax = (12 + size x 40) x faction multiplier x 1.8 if boss, and damage reduces crew proportionally.

## Consensus (adopt)

- Launching torpedoes costs a full weapon activation. Boarding costs a full activation. Both legs agree, and both match the existing activation economy (boardTargets already requires no weapon fired).
- Torpedoes are visible, fixed-course, non-homing hazards: the herding mechanic is the point. Both legs agree, and DeepSeek's "telegraphed threat lanes" is the same idea as Qwen's visible course line plus arrival reticle.
- Target chosen on the arrival turn, within the arrival hex and its ring. Both legs agree.
- Boarding resolves in one opposed check in one activation, no multi-turn sub-game, no officer posts. Both legs agree, and the existing boardUnit already works this way.
- No per-turn bookkeeping beyond status tokens that tick down automatically. Both legs agree, and st.fire / weapon-off / shieldOff already implement that pattern.

## Where the legs differ, and the chair's call

Interception: DeepSeek invented Point Defense / Boarding Rating / Crew Defense stats; Qwen spends a weapon activation on a screening attempt (one per torpedo per turn, size-class-modified flat check). Chair: Qwen's model fits the activation economy and needs no new stats. Further simplification available from code: flak already exists as a weapon kind, so interception can reuse flak arcs and ranges instead of inventing either a stat or a free-form screening action. Opus to decide between Qwen screening and flak reuse; do not implement both.

Torpedo motion: DeepSeek used fuel; Qwen used fixed speed (3 hexes per turn). Chair: speed-based. Fuel is another tracked quantity, which both legs were told to avoid, and speed plus a fixed course already produces the herding window (2-4 turns at 10-hex range).

Boarding currency: DeepSeek invented stats; Qwen invented crew sections (1-2 committed, 2-4 per ship); code uses crew counts with faction multipliers. Chair: code wins. Any revision to boardUnit keeps crew counts and BOARD_MULT/CREW_MULT, and Qwen's "sections" language should be dropped.

Capture: Qwen excludes capture as a standard outcome; code HAS asymmetric capture (enemies capturable, player ships immune). Chair: the question for Ryan is not whether capture exists but whether to keep it, and how it composes with Qwen's consequence menu. The clean merge: on a successful boarding, if defender crew hits 0, the existing capture/overrun outcome applies; otherwise the attacker picks one consequence from Qwen's menu (fire, engine cripple, sabotage, crew damage). That keeps the existing economy and adds Qwen's decision point without a second capture system. Ryan decides; Opus does not merge unilaterally.

Torpedo crit severity: Qwen proposes permanent system destruction on a catastrophic crit. Code's crit model is temporary (2-turn disables, fire). Chair: keep temporary as the default; permanent destruction is a new severity tier needing Ryan's sign-off, not a quiet escalation.

## DeepSeek-only, carried

- Concrete battle-zoom read tables (what the player sees at each stage). Adopt as the presentation spec for both systems.
- Honest open-questions list, including the cap-exceedance and fuel-exhaust edge cases that Qwen does not cover. Those edge cases transfer to the speed model as: what happens when a torpedo's arrival hex is off-board or occupied by a friendly ship (chair: detonate harmlessly, same as Qwen's empty-hex rule, extended to friendlies).
- Telegraphed threat lanes as the herding mechanism, which Qwen independently converged on.

## Qwen-only, carried

- Screening interception (adopted over DeepSeek's invented stats, per above).
- Splash damage (one-third to the arrival hex only, no crit on splash). Genuinely new; code has no splash concept for torpedoes.
- Consequence menu on boarding success, with crit success granting two consequences. Adopt via the capture merge above.
- Damage-control recovery action (spend an activation to end fire or sabotage early). Genuinely new; code has brace and campaign Drydock repair but no in-battle damage control.
- Adjacent-ship repel bonus (+1). New mechanic, distinct from code's repel flag. Do not stack blindly with the flag; Opus to reconcile (flag source in code is not established by this screening).
- Animation-time warning, grounded in the sims' 95-120 second late-fight animation waits. Torpedo flight animation must be compressible (jump-cut or sub-second steps), or the herding mechanic becomes a waiting mechanic.

## Qwen slips corrected (minor)

- Failure text contradicts itself (crew sections "lost (returned to the pool as wounded, unavailable)"). Pick one meaning when merging.
- "Unused intercept action" is referenced but interception is defined as spending a weapon activation, not a separate pool. Unify the terminology.
- Engine cripple "half movement" differs from code's engine damage (speed -1). If the menu is adopted, state which one wins; chair leans to code's speed -1 for consistency with systemDamage.

## Open decisions (Ryan's or Opus's, not the chair's)

- Torpedo range: current 6 versus proposed 10-hex launch range. A range-10 torpedo outranges every current torp stat; if adopted, torp/opt stats change with it.
- Magazine (2-4 per ship) versus the current cooldown 2. Magazine is the bigger change; cooldown already enforces scarcity.
- Shield interaction for travelling torpedoes: which facing is struck, does pierce .3 still apply, do shields soak before hull as with other weapons. Partially answerable from code (four facings, pierce exists); the facing rule for an arriving torpedo is new.
- Capture-versus-consequences merge (above). Ryan's call.
- Damage control as a new activation type: does it displace brace, or sit alongside it?
- Delta-v band interaction with torpedo courses. Bands are a design proposal, not implemented mechanics, so this is TBD without invalidating the flat-board geometry both legs assume.
- Evasion interplay with alternating activation: Qwen ties evasion to hexes moved "this turn"; in alternating mode a ship's "turn" is its activation, so the evasion window needs a precise definition (hexes moved in the ship's last activation, or since the torpedo launched).

## Recommended next step

Opus maps the merged proposal onto existing code paths (torp branch of fireWeapon, boardUnit, systemDamage, st.fire, flak) and reports which parts are parameter changes (range, cooldown, pierce, crit) versus new systems (travelling projectiles, screening, splash, damage control, consequence menu), before any implementation. Ryan decides capture-versus-consequences and range/magazine at that point. No code changes are commissioned by this synthesis.
