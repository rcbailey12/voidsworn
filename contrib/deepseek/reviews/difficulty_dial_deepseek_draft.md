# Difficulty dial draft: DeepSeek leg

Provenance: generated in DeepSeek chat on Oct 24, 2026, DeepThink ON, Search OFF, signed in as rcbailey12@gmail.com. Unlike the torpedo run, the brief file uploaded and attached successfully here (TXT 1.74KB); the model printed the brief verbatim to read it, then posted the draft below in the chat. Em dashes in the model's text were normalized to hyphens for the no-em-dash rule; wording is otherwise verbatim. Screening and synthesis against the Qwen leg follow separately; nothing here is verified.

Here is my difficulty dial draft for Voidsworn, written to the brief. Please keep it on file; no response needed beyond confirming receipt.

VOIDSWORN DIFFICULTY DIAL - DRAFT v1

Basis (OBSERVED, Oct 23 sim matrix): 300 fuzz runs clean, zero exceptions, zero invariant breaks. Admiral pick is a hidden difficulty dial: sector-1 boss win rates 38% (Grax) to 98% (Maren, Voice). The sector-2 elite is the wall at 57% overall. Average battle length 6.6 rounds. Late-fight animation wait 95-120s is a pacing problem, not a difficulty input - not tuned here.

1. DIAL DESIGN

What the dial adjusts (INFERRED): explicit, player-visible enemy combat scaling plus per-sector encounter modifiers, applied uniformly after admiral pick. Admiral pick is decoupled from difficulty - the hidden dial currently inside admiral pick (OBSERVED) is the defect this design fixes.

Notches: 5 numbered notches. Default: notch 3.

Notch effects, numeric (INFERRED - draft values to be calibrated by the mega sim):
- Notch 1 "Cadet": enemy hull x0.80, enemy damage x0.85, sector-2 elite encounter strength x0.75.
- Notch 2 "Ensign": enemy hull x0.90, enemy damage x0.92, elite strength x0.88.
- Notch 3 "Veteran" (default): x1.00 / x1.00 / x1.00.
- Notch 4 "Brutal": enemy hull x1.12, enemy damage x1.08, elite strength x1.12, +1 elite escort.
- Notch 5 "Nightmare": enemy hull x1.25, enemy damage x1.15, elite strength x1.25, +2 elite escorts.

Visibility (INFERRED): the dial is a labeled 1-5 slider on the run-setup screen showing each notch's numeric effects; the active notch and its numbers are restated on the pause menu and the sector-transition banner (e.g., "Veteran 3/5 - enemy hull x1.00, damage x1.00"). The admiral-select screen additionally shows each admiral's measured sector-1 boss win-rate band (OBSERVED data), so any remaining admiral variance is visible, not hidden.

2. RECOMMENDATIONS (all at default notch 3; values INFERRED proposals unless marked OBSERVED)

R1 - Grax floor. OBSERVED: Grax sector-1 boss win rate 38%, bottom of the spread. Raise Grax to >= 60% by scaling Grax's starting fleet strength by factor g = 1 + (0.60 - 0.38) / k, where k = measured win-rate gain per +10% starting strength (mega sim to measure). If k = 0.05 (5pp per 10% strength), g = 1.44; cap g at 1.30 and cover any remainder with a Grax-specific kit buff (e.g., Grax flagship +10% hull) so the change stays inside admiral identity.

R2 - Maren/Voice ceiling. OBSERVED: Maren and Voice at 98%. Bring each to <= 80% via factor m = 1 - (0.98 - 0.80) / k. If k = 0.05, m ≈ 0.64 is too coarse for pure strength, so implement as kit-specific trims preserving identity (INFERRED proposals): Maren starts with 1 fewer upgrade choice; Voice's signature ability cooldown +1 round. Recalibrate from the mega sim's k before locking numbers.

R3 - Sector-2 elite wall. OBSERVED: 57% overall; average battle length 6.6 rounds must not bloat. Multiply elite encounter combat strength by e = 0.88 (elite hull x0.90, elite damage x0.95), targeting sector-2 elite win rate >= 65% at notch 3. Final calibration formula: e = 1 - (0.65 - observed_elite_wr) / k_e, where k_e = measured win-rate gain per 10% elite-strength change (mega sim to measure). Constraint: average battle length must stay within 6.6 ± 1.0 rounds (OBSERVED baseline); if it drifts beyond, prefer damage reduction over hull reduction.

3. MEGA-SIM CONFIRMATION / OVERTURN (name the measurement, not "more data")

- R1: measure "sector-1 boss win rate per admiral at notch 3 with compensation applied." Confirm: Grax >= 60% and every admiral inside [60%, 80%]. Overturn: any admiral outside the band → recalibrate that admiral's factor; do not move the band.
- R2: same measurement. Confirm: Maren and Voice <= 80% with kits otherwise intact. Overturn: either below 60% → the trim was too strong, halve it.
- R3: measure "sector-2 elite encounter win rate at notch 3" and "average battle length in rounds." Confirm: elite win rate >= 65% AND battle length within 6.6 ± 1.0 rounds. Overturn: elite win rate < 65% → deepen the reduction per the formula; battle length outside the band → shift the reduction from hull to damage.
- Calibration inputs the mega sim must provide: k (win-rate pp per +10% starting fleet strength, per admiral), k_e (win-rate pp per 10% elite-strength change), per-admiral sector-1 boss win rates at each notch, elite win rate at each notch.

NOT SPECIFIED (could not decide from this brief):
- Final numeric values for g, m, e and the notch table - pending mega-sim calibration of k and k_e.
- Whether any intentional admiral power variance should be kept as an explicit feature (e.g., labeled "challenge admirals") - the brief only establishes the hidden dial is a defect.
- Per-admiral kit details beyond the names Grax, Maren, Voice - no kit data in the brief.
- The 95-120s late-fight animation wait (OBSERVED) - a pacing problem, explicitly out of scope for this dial.
- Long-term default notch - notch 3 is a proposal, not evidence.
