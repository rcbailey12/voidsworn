# B2 ramp and capture sanity check synthesis (chair, TWO LEGS)

Legs: contrib/deepseek/reviews/b2_ramp_capture_deepseek_2026_10_25.md (DeepSeek)
and contrib/qwen/reviews/b2_ramp_capture_qwen_2026_10_25.md (Qwen, Oct 25 brief Job 2).
Nothing in it is a ruling. R1 (10/14/20 as a guide, not a cap; player fleet small and elite at 4 to 7)
and R4 (add, strip, or ransom after a win; full fleet auto-scraps; sector flagships never
capturable) stand unchanged.

Chair verdict: GO WITH CONDITIONS (strong two-leg agreement on the spine, with the
conditions below as B2 requirements, not polish).

## Headline

Both legs independently land on the same spine: the 10/14/20 ramp is viable only if the
design buys back the protections the old 8-ship cap was providing for free. Raw count
alone breaks tempo, focus fire, turn length, and readability. What saves it is structure:
batched or squadron activation, telegraphed enemy intent, a bounded effective activation
ratio, and fragile filler around a small number of real threats. On capture, both legs
converge on the same guardrails: adding a prize must cost something recurring, ransom
must diminish or delay, strip must convert to specific value rather than generic currency,
and the post-battle choice must be batched with defaults so it does not become busywork.

## Where the legs agree

1. Tempo and activation economy is the top risk. The nominal gap is 3 to 4 enemy
activations per player activation at 20 ships. Both legs say the fix is to cap effective
activations, not board count: squadrons that move and fire as one, a per-turn active-enemy
budget, or pod-style staggered activation. Lifting the board cap is fine; lifting the
activation cap is the dangerous part.
2. The enemy must not bring everything to bear. Qwen's framing is Lanchester's square
law: an unconstrained 3x force is roughly 9x stronger in ranged combat. DeepSeek's
framing is structural brakes: telegraphing in the Into the Breach model, firing arcs and
facing in the Battlefleet Gothic model, or initiative phases and reserve actions in the
BattleTech model. Same conclusion, different vocabulary.
3. Filler versus threats. Qwen's shape: at 20 enemy ships, 3 to 5 elites plus the
flagship, the rest fragile escorts that die in one or two volleys. DeepSeek's shape: 4
squadrons of 5 with distinct roles. These are compatible, and the synthesis adopts both
as the same rule stated twice: few real threats, distinct roles, fragile filler.
4. The ramp scales count AND quality, with different jobs. Count carries the
sector-to-sector ramp (10, 14, 20). Quality carries within-sector escalation and the
difficulty spikes. Scaling only count makes long turns and trivial filler; scaling only
quality makes HP sponges and slow attrition duels.
5. Difficulty shifts the mix, not just the number. Separate levers: enemy count
(intensity), elite share and accuracy (lethality), prize and credit values (economy).
Qwen adds the Hades Pact of Punishment model (named conditions, rewards scale with
them) and the Starsector option of letting players cap battle size in settings. Both
are Opus items, not rulings.
6. Capture guardrails converge exactly. Add carries recurring cost (upkeep, crew, or a
fleet-slot cost that pushes out a better ship; Starsector supplies and combat readiness
is the cited model). Ransom diminishes with repeats or flooding, or pays out delayed,
and strong sinks (repairs, refits, module installs) must exist. Strip converts to
specific modules, not generic currency, so the three options are not secretly all money.
The post-battle decision is batched (one screen for all prizes, side-by-side values,
per-class default policies, remember last choice, single undo), and auto-scrap on a full
fleet must show what was lost and why. Both legs independently use an 80 percent
dominant-option flag: if one of add, strip, or ransom is chosen 80 percent of the time,
reprice the others.
7. The old 8-ship cap was doing hidden work. Both legs say it explicitly: the cap was
protecting turn time and readability. At 20 ships those protections must be designed in,
not assumed.

## Where the legs differ or add

- DeepSeek leans on Into the Breach, BattleTech, and Battlefleet Gothic: Armada, with
wiki-level sourcing it flags as directional. Qwen adds XCOM pods, Fire Emblem cannon
fodder versus juggernaut patterns, Alpha Strike batching, Hades, Starsector, Sins of a
Solar Empire, Assassin's Creed IV: Black Flag, and Master of Orion 2. The wider shelf
strengthens the same spine rather than contradicting it.
- Hardspace: Shipbreaker was named in the brief and covered only by Qwen, correctly
characterized as a real-time salvage sim, not a tactics game. Its use is narrow: the
feel of stripping a big hull into clean, sorted, valuable parts, and an economy kept
non-trivial by a debt tab. It is a reference for the strip option only, not for tempo.
- Qwen proposes a fourth capture lane, "send prize home" for later payout (Black Flag's
Kenway's Fleet model). This is OUTSIDE R4, which defines exactly three post-win
options. It is recorded here as a proposal for Opus to consider, not as an addition
to R4 and not as a recommendation from the chair.

## The sim metric set (merged, for the B2 sim's first run)

1. Player activation share per battle, by sector (DeepSeek: below roughly one in three
flags tempo trouble), paired with Qwen's effective action ratio: enemy actions versus
player actions per round after batching, with a target of pulling the nominal 3 to 4x
down toward 2x or less. Also log how many enemy ships actually get in range and fire
each round; if all 20 always fire, the Lanchester problem is live.
2. Focus-fire loss rate: how often a player ship dies in a single enemy turn, plus
rounds to first player ship lost per sector, plus first-mover win rate. A high
first-mover win rate flags an alpha strike problem.
3. Player alpha-strike effectiveness: enemy ships destroyed per player turn as a
fraction of total enemy ships. If it collapses from sector 1 to sector 3, the elite
fleet fantasy is being eroded by count and quality scaling must compensate.
4. Battle length and enemy-phase workload: rounds to battle end and simulated steps per
enemy phase at 10, 14, and 20 ships. These must not blow up at sector 3; this is the
proxy for real turn time.
5. Wealth curves: credits earned, credits spent, total prize value, and player fleet
value after each battle. Snowballing shows as fleet value growing faster than enemy
value each sector; floods show as cash exceeding everything the shops sell by sector 2.
6. Prize choice distribution and auto-scrap rate: percent added versus stripped versus
ransomed, and how often auto-scrap fires. The 80 percent dominant-option flag applies.
Frequent auto-scrap means prizes arrive too fast or the 4 to 7 cap is too tight for
late sectors.
7. Turn duration and capture-decision time (median and 90th percentile, by sector),
plus a readability proxy: distinct enemy ship types on the board at once. More than a
handful of types at sector 3 means the 20-ship board is noise, not a puzzle.

## Conditions for GO

- B2 ships the structural protections (squadron or batched activation, telegraphed
intent or an equivalent brake, bounded effective activations) as requirements in the
implementation, not as follow-up tuning.
- The capture rework ships with its guardrails (recurring cost on add, diminishing or
delayed ransom, specific-value strip, batched UI with defaults).
- The sim tracks the merged metric set above from the first B2 run. Until those metrics
pass, 10/14/20 is a feel target, not a balance target.

## Open items for Opus (not Ryan decisions)

- The "send prize home" fourth lane: consider or reject; R4 stands either way.
- Exact threat/filler split (3 to 5 elites versus squadron-of-5 roles): the sim decides.
- Player-set battle-size cap (Starsector model): consider as an options-screen item.
- Whether the Hades-style named-condition difficulty levers fit this game's difficulty
settings, versus the simpler three-lever mix above.

## Sourcing note

Both legs cite their comparables with links. DeepSeek's game claims rest on community
wikis and are flagged directional. Qwen's shelf mixes primary documents (Alpha Strike
rulebook, Game Developer articles) with forums and Steam discussions (directional).
Neither leg makes repo claims beyond the brief's context, so no file:line checks were
needed. Qwen leg model-badge caution: the run reports Qwen3.8-Max explicitly selected
and verified, but the sign-in step observed the selector defaulting to Qwen3.7-Plus,
so cite it as a Qwen leg with that caution.
