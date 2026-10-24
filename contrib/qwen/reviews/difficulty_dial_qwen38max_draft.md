# Difficulty dial draft: Qwen3.8-Max leg

Provenance: generated in Qwen chat on Oct 24, 2026, model Qwen3.8-Max, Thinking ON, Search OFF, signed in as rcbailey12@gmail.com. The chat's attachment UI exposed no observable file-input element, so the brief's verbatim text was pasted into the chat message instead of uploaded. Em dashes in the model's text were normalized to hyphens for the no-em-dash rule; wording is otherwise verbatim. Screening and synthesis against the DeepSeek leg follow separately; nothing here is verified.

VOIDSWORN DIFFICULTY DIAL DRAFT
Tag key
- OBSERVED: direct claim from the Oct 23 brief / sim evidence provided.
- INFERRED: my design reasoning, proposed value, or provisional formula. This is not a claimed sim result.

1. Difficulty dial design
1.1 Problem framing
The Oct 23 sim matrix had 300 fuzz runs clean with zero exceptions and zero invariant breaks (OBSERVED).
The same evidence shows that the current difficulty is effectively hidden inside admiral selection:
- Sector 1 boss win rates range from 38% for Grax to 98% for Maren and Voice (OBSERVED).
- Therefore, admiral pick is currently functioning as a hidden difficulty dial (OBSERVED from the brief's interpretation).
- A hidden difficulty dial is a defect, not a feature (OBSERVED from the brief's requirement).
- Sector 2 elite is the current wall, at 57% overall win rate (OBSERVED).
- Average battle length is 6.6 rounds (OBSERVED).
- Late-fight animation wait is 95-120 seconds and is designated a pacing problem, not a difficulty input (OBSERVED from the brief).
- The dial must not be tuned around late-fight animation wait (OBSERVED constraint).
Design consequence (INFERRED): the dial must move difficulty out of hidden admiral pick effects and into explicit, player-visible campaign and battle modifiers.

1.2 Dial name
Command Threat Dial (INFERRED).

1.3 What the dial adjusts
The Command Threat Dial adjusts the following systems (INFERRED):
1. Enemy scaling: Enemy Threat Budget; Enemy damage; Enemy survivability; Elite/boss special pressure.
2. Sector modifiers: Player relief points on low notches; Enemy pressure points on high notches.
3. Explicit admiral calibration: Admirals receive visible, numeric calibration offsets; these offsets are separate from admiral identity and are shown in the UI.
4. Admiral pick weighting: The dial changes admiral pick weighting by 0. Admiral pick weighting is not used as a hidden difficulty lever (INFERRED).
The dial does not adjust animation timing, turn-resolution speed, or late-fight wait behavior (INFERRED, following the brief's pacing constraint).

1.4 Number of notches
The dial has 5 notches (INFERRED). Five notches are sufficient to create a full easy-to-hard range while keeping the choice readable for PC UI and roguelite campaign flow (INFERRED).

1.5 Notch definitions
All notch values below are provisional draft values (INFERRED). They are intended to be refined by the pending mega sim.
Notch table (columns: Notch | Player-facing label | Enemy Threat Budget multiplier | Approx. enemy ship-count offset | Enemy damage multiplier | Enemy survivability multiplier | Elite/boss special gauge multiplier | Sector modifier points | Provisional average sector 1 boss win-rate shift vs Standard):
1 | Recruit | 0.80 | -2 | 0.90 | 0.90 | 0.80 | -2 player relief | +30 pp
2 | Line Officer | 0.90 | -1 | 0.95 | 0.95 | 0.90 | -1 player relief | +15 pp
3 | Commander | 1.00 | 0 | 1.00 | 1.00 | 1.00 | 0 | 0 pp
4 | Flag Officer | 1.15 | +1 | 1.08 | 1.05 | 1.10 | +1 enemy pressure | -15 pp
5 | Voidsworn | 1.30 | +2 | 1.16 | 1.10 | 1.20 | +2 enemy pressure | -30 pp
All numeric values in the table are INFERRED draft tuning values.

Definitions of table columns:
- Enemy Threat Budget multiplier (INFERRED): A campaign-level budget used to buy enemy ships, ship tiers, reinforcements, elite upgrades, or boss pressure. If the current game does not have this abstraction, it should be implemented as a weighted sum of enemy encounter strength.
- Approx. enemy ship-count offset (INFERRED): A provisional translation of Threat Budget into encounter size. Because battles are around 20 ships (OBSERVED context), ship-count offsets are kept small: minimum -2, maximum +2, subject to encounter design floors and caps.
- Enemy damage multiplier (INFERRED): Applies to enemy weapon damage or equivalent offensive stats. This is preferred over large survivability increases because it can raise difficulty without necessarily extending late fights.
- Enemy survivability multiplier (INFERRED): Applies to enemy hull, shield, defense, or damage mitigation. Increases are intentionally capped at +10% at the top notch because average battle length is already 6.6 rounds (OBSERVED) and late-fight animation wait is a known pacing problem (OBSERVED).
- Elite/boss special gauge multiplier (INFERRED): Scales elite/boss special abilities, overcharge, phase triggers, reinforcement meters, or equivalent boss pressure resources.
- Sector modifier points (INFERRED): Signed sector pressure. Negative values are player relief points. Positive values are enemy pressure points. One point buys or removes one visible sector modifier tier. Until measured, one sector modifier point is provisionally valued at about 5 percentage points of win rate or 5% effective fleet power (INFERRED).
- Provisional win-rate shift (INFERRED): This is not a sim result. It is a design target: each notch should move the average admiral's sector 1 boss win rate by roughly 15 percentage points relative to the adjacent notch, for a total range of roughly 60 percentage points. This range is chosen because the current hidden admiral spread is 60 percentage points: 38% to 98% (OBSERVED).

1.6 Total threat formula
The dial, admiral calibration, and fight-specific corrections combine into a single visible threat multiplier (INFERRED):
M_total = clamp(M_dial x M_admiral x M_fight, 0.60, 1.60)
Where: M_dial = Enemy Threat Budget multiplier from the notch table; M_admiral = 1 - C_admiral; M_fight = 1 - C_fight.
C_admiral is the visible admiral calibration offset. C_fight is a visible fight-specific correction, such as sector 2 elite wall relief. Positive C values reduce enemy threat. Negative C values increase enemy threat. The final multiplier is clamped between 0.60 and 1.60 to avoid absurd extremes (INFERRED).

1.7 How the dial stays visible to the player
A hidden dial is a defect (OBSERVED requirement). Therefore, every difficulty input must be inspectable by the player (INFERRED).
- Campaign setup screen: The player sees a physical or UI dial with five detents (INFERRED): Recruit, Line Officer, Commander, Flag Officer, Voidsworn. The screen displays all active numeric modifiers: Enemy Threat Budget multiplier, Enemy damage multiplier, Enemy survivability multiplier, Elite/boss pressure multiplier, Sector modifier points, Approximate ship-count offset.
- Pause screen: The current notch and all active modifiers remain visible in the pause menu (INFERRED).
- Admiral selection screen: Admiral selection shows explicit calibration, not hidden difficulty (INFERRED). For each admiral, the UI displays: Admiral identity kit; Visible calibration offset; Expected difficulty tag after calibration; Whether the admiral is currently tuned toward Easy, Standard, Hard, or Brutal. Example display language (INFERRED): "Grax: Threat relief 30% / Maren: Threat pressure 30% / Voice: Threat pressure 30%". The exact percentages may be replaced by icons or pips, but the numeric value must remain inspectable.
- Pre-battle intel screen: Before a battle, the player sees: Enemy Threat Budget, Sector modifiers, Elite/boss pressure, Admiral calibration, Final displayed threat tag.
- In-battle HUD: A compact HUD element shows: Current dial notch, Active sector modifiers, Elite/boss pressure state.
- Sim logging: Every sim run must log: Dial notch, M_dial, C_admiral, C_fight, M_total, Active sector modifiers, Encounter composition. If a difficulty modifier cannot be displayed to the player or logged for sim analysis, it should not ship as a difficulty input (INFERRED).

2. Recommendations for flattening the Grax-to-Maren spread and the sector 2 elite wall
The goal is to reduce the current hidden difficulty spread without flattening admiral identity.
Current evidence: Grax sector 1 boss win rate: 38% (OBSERVED). Maren sector 1 boss win rate: 98% (OBSERVED). Voice sector 1 boss win rate: 98% (OBSERVED). Sector 2 elite overall win rate: 57% (OBSERVED).
The recommendations below use provisional targets and formulas. They are draft values pending mega-sim confirmation (INFERRED).

Recommendation 1: Adopt explicit Standard win-rate targets
Set explicit Standard-difficulty targets for major fights (INFERRED).
Sector 1 boss target: Target sector 1 boss win rate at Standard notch: 0.70; Acceptable overall band: 0.65 to 0.75; Acceptable per-admiral band: 0.65 to 0.80; Maximum admiral spread after calibration: 0.20 percentage points. This means that after tuning, no admiral's sector 1 boss win rate should be below 65% or above 80% on Standard, and the difference between hardest and easiest admiral should be no more than 20 percentage points (INFERRED). This directly addresses the current Grax-to-Maren/Voice spread of 60 percentage points (OBSERVED).
Sector 2 elite target: Target sector 2 elite win rate at Standard notch: 0.70; Acceptable overall band: 0.65 to 0.75; Minimum per-admiral floor: 0.60; Maximum per-admiral ceiling: 0.85. The current sector 2 elite overall win rate is 57% (OBSERVED), which is below the proposed wall-relief target.

Recommendation 2: Apply a visible Admiral Calibration Offset
Replace hidden admiral difficulty with a visible Admiral Calibration Offset (INFERRED). For each admiral A:
C_admiral,A = clamp(1.5 x (0.70 - W_A,S1), -0.30, +0.30)
M_admiral,A = 1 - C_admiral,A
Where: W_A,S1 = observed sector 1 boss win rate for admiral A at Standard dial; 0.70 = target sector 1 boss win rate; 1.5 = provisional correction gain; -0.30 = maximum visible threat pressure; +0.30 = maximum visible threat relief.
Using Oct 23 values:
- For Grax: W_Grax,S1 = 0.38; C_Grax = clamp(1.5 x (0.70 - 0.38), -0.30, +0.30) = clamp(0.48, -0.30, +0.30) = +0.30; M_Grax = 0.70. Result: Grax receives 30% visible threat relief against sector 1 boss pressure (INFERRED).
- For Maren: W_Maren,S1 = 0.98; C_Maren = clamp(1.5 x (0.70 - 0.98), -0.30, +0.30) = clamp(-0.42, -0.30, +0.30) = -0.30; M_Maren = 1.30. Result: Maren receives 30% visible threat pressure against sector 1 boss pressure (INFERRED).
- For Voice: W_Voice,S1 = 0.98; C_Voice = -0.30; M_Voice = 1.30. Result: Voice receives 30% visible threat pressure (INFERRED).
These offsets must be shown on the admiral selection screen (INFERRED).

Recommendation 3: Use an iterative calibration controller, not a one-shot guess
The pending mega sim should be used to recalibrate offsets with a dampened controller (INFERRED). For each admiral:
C_admiral,new = clamp(C_admiral,old + 0.5 x (0.70 - W_measured), -0.30, +0.30)
Where: W_measured = measured sector 1 boss win rate after applying the previous offset; 0.5 = damping factor to reduce overshoot. This prevents overcorrection if the relationship between threat and win rate is nonlinear (INFERRED).

Recommendation 4: Apply explicit sector 2 elite wall relief
The sector 2 elite is currently a wall at 57% overall (OBSERVED). Apply a fight-specific correction (C_fight) to the sector 2 elite (INFERRED):
C_S2E = clamp(1.5 x (0.70 - W_S2E), 0.00, +0.30)
M_S2E = 1 - C_S2E
Using the observed overall sector 2 elite win rate: W_S2E = 0.57; C_S2E = clamp(1.5 x (0.70 - 0.57), 0.00, +0.30) = clamp(0.195, 0.00, +0.30) = +0.195; M_S2E = 0.805. Result: reduce sector 2 elite effective threat by 19.5% on Standard (INFERRED). This should be displayed as a sector 2 elite calibration, for example: "Sector 2 elite: threat relief 19.5%".
Per-admiral sector 2 floor: If an admiral's sector 2 elite win rate is below the floor, apply an additional admiral-specific sector 2 correction (INFERRED):
C_A,S2 = clamp(1.5 x (0.60 - W_A,S2), 0.00, +0.15)
Where: W_A,S2 = admiral A's sector 2 elite win rate; 0.60 = minimum acceptable per-admiral sector 2 elite win rate; 0.15 = maximum additional admiral-specific sector 2 relief.

Recommendation 5: Add a sector 2 entry attrition guard
The sector 2 elite wall may be caused by enemy strength, but it may also be caused by player attrition during sector 1. This needs mega-sim measurement (INFERRED). Define: P_entry = average player fleet power at sector 2 elite entry divided by expected post-sector-1 fleet power. If P_entry is low, grant visible refit relief before the sector 2 elite (INFERRED):
R_refit = clamp(0.85 - P_entry, 0.00, 0.15)
Examples: If P_entry = 0.85, R_refit = 0.00; If P_entry = 0.80, R_refit = 0.05; If P_entry = 0.70, R_refit = 0.15. R_refit should be delivered as a visible emergency refit, repair credit, temporary fleet-power bonus, or equivalent pre-battle resource. It should not be hidden (INFERRED).

Recommendation 6: Use a smooth sector difficulty ramp
Sector 2 elite should not be a sudden wall relative to sector 1 boss (INFERRED). Proposed mandatory major-fight win-rate targets: Sector 1 boss target: 0.70; Sector 2 elite target: 0.70; Sector n target for n >= 3: T_n = max(0.55, 0.70 - 0.04 x (n - 2)). This produces: Sector 1 boss: 0.70; Sector 2 elite: 0.70; Sector 3 major: 0.66; Sector 4 major: 0.62; Sector 5 major: 0.58; Floor: 0.55. Additional rule (INFERRED): No mandatory fight may have a target win rate more than 0.05 below the previous mandatory fight unless it is explicitly labeled as an optional elite, super-elite, or challenge encounter. This prevents future hidden walls while still allowing late-game difficulty to rise.

Recommendation 7: Preserve admiral identity with explicit correction caps
Flattening the hidden difficulty spread must not flatten admiral identity (INFERRED). Use the following caps:
Ability/stat identity cap: No admiral ability, ship stat, cooldown, or unique perk may be changed by more than 5% solely to correct win-rate spread.
Resource offset cap: If threat correction is insufficient, use visible campaign resource offsets of no more than 15% of baseline fleet power.
Formula form: |Δ_ability| <= 0.05 x base_ability_value; ResourceOffset <= 0.15 x baseline_fleet_power.
Preferred correction order (INFERRED): 1. Visible Enemy Threat Budget correction. 2. Visible sector modifier correction. 3. Visible pre-battle resource correction. 4. Last resort: small ability/stat adjustment within the 5% cap. This keeps admirals distinct while preventing the current hidden Grax-to-Maren/Voice spread (OBSERVED spread, INFERRED solution).

Recommendation 8: Show projected difficulty tags
Convert hidden win-rate differences into visible difficulty tags (INFERRED). After applying dial, admiral calibration, and fight correction, compute projected win rate W_projected. Display: Easy: W_projected >= 0.80; Standard: 0.65 <= W_projected < 0.80; Hard: 0.50 <= W_projected < 0.65; Brutal: W_projected < 0.50. These tags should appear: On admiral selection; On sector map nodes; On pre-battle intel; On boss/elite encounters. This makes the previous hidden admiral difficulty visible and player-controllable (INFERRED).

3. Mega-sim data needed to confirm or overturn each recommendation
The following are measurements requested from the pending mega sim. They are named specifically so they can be queried directly. All confirmation criteria below are draft criteria (INFERRED). They are not claimed sim results.

Dial stability guardrail - Measurement: stability.exceptions.by_notch; stability.invariant_breaks.by_notch. Confirm if: All dial notches produce zero exceptions and zero invariant breaks, matching the Oct 23 clean baseline (OBSERVED baseline, INFERRED requirement). Overturn or adjust if: Any notch produces exceptions or invariant breaks. In that case, the offending modifier must be reduced, clamped, or removed before tuning win rates.

Recommendation 1: Standard win-rate targets - Measurement: win_rate.sector1_boss.by_admiral.by_notch; win_rate.sector2_elite.by_admiral.by_notch; at Notch 3 / Commander / Standard. Confirm if: Overall sector 1 boss win rate is between 0.65 and 0.75 (INFERRED target); Per-admiral sector 1 boss win rates are between 0.65 and 0.80 (INFERRED target); Max admiral spread is <= 0.20 (INFERRED target); Overall sector 2 elite win rate is between 0.65 and 0.75 (INFERRED target); No admiral is below 0.60 at sector 2 elite (INFERRED floor). Overturn or adjust if: The targets are unreachable without exceeding the calibration caps, or if the mega sim shows that the current player power curve makes the targets systematically too easy or too hard. Adjust target bands before increasing correction caps.

Recommendation 2: Admiral Calibration Offset formula - Measurements: win_rate.sector1_boss.by_admiral.by_notch; win_rate_elasticity.threat_multiplier.by_admiral; admiral_calibration.C_admiral.by_admiral. Confirm if: After applying C_admiral,A = clamp(1.5 x (0.70 - W_A,S1), -0.30, +0.30), Grax, Maren, and Voice fall inside the per-admiral Standard band of 0.65 to 0.80 (INFERRED target). Overturn or adjust if: The measured win-rate response to threat multiplier is much stronger or weaker than assumed. In that case, adjust the gain 1.5 or the caps -0.30 / +0.30. Specifically: If dW/dM is low, increase gain or caps. If dW/dM is high, reduce gain or caps.

Recommendation 3: Iterative calibration controller - Measurements: win_rate.sector1_boss.by_admiral.iteration_N; admiral_calibration.C_admiral.iteration_N. Confirm if: The controller converges within two iterations: |W_measured - 0.70| <= 0.05 and |C_new - C_old| <= 0.05 after the second iteration (INFERRED convergence target). Overturn or adjust if: The controller oscillates or overshoots. Reduce damping factor from 0.5 to 0.25, or reduce maximum step size to 0.10.

Recommendation 4: Sector 2 elite wall relief - Measurements: win_rate.sector2_elite.overall.by_notch; win_rate.sector2_elite.by_admiral.by_notch; threat_multiplier.sector2_elite.applied. Confirm if: After applying C_S2E = +0.195, M_S2E = 0.805, overall sector 2 elite win rate moves into 0.65 to 0.75, and no admiral is below 0.60 (INFERRED targets). Overturn or adjust if: Sector 2 elite becomes too easy: overall win rate > 0.80. Sector 2 elite remains a wall: overall win rate < 0.62. Specific admirals remain below floor. In those cases, adjust C_S2E coefficient, cap, or per-admiral sector 2 relief.

Recommendation 5: Sector 2 entry attrition guard - Measurements: fleet_power.player_at_sector2_entry.relative; attrition.sector1.loss_ratio.by_admiral; fleet_power.player_post_sector1.expected; win_rate.sector2_elite.by_admiral. Confirm if: Sector 2 elite difficulty correlates primarily with elite threat, not with abnormal player attrition: P_entry >= 0.85 for most admirals (INFERRED threshold). Overturn or adjust if: P_entry < 0.85 for admirals that also show low sector 2 elite win rates. In that case, the wall is at least partly attrition-driven, and the refit formula should be applied: R_refit = clamp(0.85 - P_entry, 0.00, 0.15). If attrition is extreme, consider sector 1 recovery changes before further reducing sector 2 elite threat.

Recommendation 6: Smooth sector difficulty ramp - Measurements: win_rate.major_fight.by_sector.by_notch; target_win_rate.major_fight.by_sector. Confirm if: Mandatory major fights follow the proposed ramp: Sector 1 boss: 0.70; Sector 2 elite: 0.70; Sector 3 major: 0.66; Sector 4 major: 0.62; Sector 5 major: 0.58; Floor: 0.55; and no mandatory fight is more than 0.05 below the previous mandatory fight target (INFERRED rule). Overturn or adjust if: The measured campaign power curve requires a different slope. For example, if player power grows faster than expected, later targets may need to be lower. If player power drops sharply after sector 2, later targets may need to be higher.

Recommendation 7: Admiral identity preservation - Measurements: identity.ability_usage_rate.by_admiral; identity.fleet_composition_entropy.by_admiral; win_rate.conditional_on_build.by_admiral; ability_changes.delta_percent.by_admiral. Confirm if: After flattening: Admiral win rates are inside the target band; Ability usage rates and fleet composition distributions have not collapsed toward a single common pattern; No ability/stat changed by more than 5% solely for difficulty flattening (INFERRED cap); Any resource offset used is <= 15% of baseline fleet power (INFERRED cap). A provisional identity-preservation criterion: Post-tuning composition/ability distribution divergence from pre-tuning <= 10%, where divergence is measured by entropy loss, Jensen-Shannon divergence, or equivalent. Overturn or adjust if: Admirals become statistically interchangeable, or if the strongest builds converge. In that case, reduce global flattening and rely more on visible campaign resource offsets.

Recommendation 8: Projected difficulty tags - Measurements: displayed_tag.projected_win_rate.by_admiral.by_encounter; win_rate.actual.by_admiral.by_encounter; displayed_tag.accuracy. Confirm if: Displayed tags match actual measured win rates within ±0.10 (INFERRED accuracy target). Example: If tag is Standard, actual win rate should usually be 0.55 to 0.89. More tightly, the tag bucket itself should be correct at least most of the time once the mega sim has enough coverage. Overturn or adjust if: Tags systematically mislead the player. For example: If displayed Standard fights repeatedly measure below 0.50, move threshold. If displayed Hard fights repeatedly measure above 0.80, move threshold.

Pacing guardrail, not difficulty input - Measurements: battle.rounds.mean.by_notch; battle.rounds.p95.by_notch; battle.entity_count.mean.by_notch; battle.entity_count.p95.by_notch. Late-fight animation wait is a pacing problem, not a difficulty input (OBSERVED constraint). These measurements are guardrails only. Confirm if: Difficulty changes do not materially increase average battle length beyond the current 6.6 rounds baseline (OBSERVED baseline, INFERRED guardrail). Overturn or adjust if: High notches increase battle length or entity count enough to worsen late-fight congestion. In that case, reduce survivability and ship-count offsets, and use damage, sector pressure, or elite behavior instead. This is not tuning difficulty around animation wait; it is avoiding making a known pacing problem worse (INFERRED).

Not specified
The following could not be decided from the brief alone:
- The exact in-game implementation of Enemy Threat Budget.
- Whether enemy scaling is currently done through ship count, ship tier, stats, reinforcements, AI behavior, or a mix.
- The current list of sector modifiers and their mechanical values.
- The exact composition of the sector 2 elite encounter.
- Whether admirals are player-selected, randomly offered, unlocked, or weighted.
- Whether admiral pick weighting exists outside the hidden win-rate spread.
- The exact meaning of "fleet power" in the current sim.
- The current player economy, repair rules, and sector transition attrition model.
- The desired final difficulty fantasy: whether Standard should feel forgiving, neutral, or punishing.
- The acceptable UI surface area for difficulty modifiers on PC.
- The final branding of the five dial notches.
- The exact statistical confidence requirements for the mega sim.
