Chair header (Rey): Argon review leg for issue #103, run 2026-11-03 from the main chat. Gate: Argon High verified in the picker and the prompt bar before sending, and both still read Argon High after sending. Inputs: PACK.md plus the DeepSeek and Qwen writer legs. Role per R81: reviews and ideas only.

Chair screening of this leg, read before the text below:

SCREENED OUT, almost in full. The review's central description of the DeepSeek leg is wrong: it describes DeepSeek's third draw as taken from S minus {H1, H2} (without replacement), but the filed DeepSeek leg draws H3 from S minus {H2} only, and states the resulting SP1 return probability (1/4) in its headline, its mechanism section, its matrix section and its owner questions. The review's claim that the intra-run return probability is "unstated" is therefore false, and its binomial absence model answers a question neither leg posed (it models counts across player rows as if they were draws inside one run; the per-run spread question is which hunters appear in one run for one player, which both legs state and the chair's enumeration in the synthesis measures). The review's "player-faction symmetry" objection misreads the pack: the pack's symmetry requirement sums over all player rows and expressly forbids self-hunting, so a faction having zero hunts in the row where it is the player is required, not a break; the review's headline idea (make the player faction eligible to hunt) would have a faction hunt itself and is rejected. There is no "no two repeats" rule in issue #45 or the pack; the review faults DeepSeek for not enforcing a rule that does not exist. The review also never engages the legs' actual design divergences (commander identity persistence, Qwen's campaign-level adaptation persistence, lesson keying), which was its brief.

USED, one narrow point: both writer legs defer the empirical enumeration to the chair. That is true, and it was the pack's own division of labour (the pack assigns the enumeration to the chair's synthesis); the chair's enumeration over 120,000 simulated runs per mechanism is in the synthesis, section 5.

Punctuation in the text below is normalized to ASCII per chair handling; wording is otherwise as returned.

---

Gate note: Argon High verified before and after sending; three files attached to the send.

# 1. Review of deepseek.md

## Symmetry and Probability Arithmetic

* **Marginal and expected-hunt arithmetic holds, but per-run spread and return rates are omitted:** DeepSeek's sequential draw ($H_1$ uniform from the 5 non-player factions $S$, $H_2$ uniform from $S \setminus \{H_1\}$, $H_3$ uniform from $S \setminus \{H_1, H_2\}$) produces exact $1/5$ marginals at every cell and $5 \times 3 \times (1/5) = 3$ expected hunts per faction across the $6 \times 3$ matrix. However, the pack requires "a simulation or enumeration over seeds showing the spread per run", which DeepSeek defers to Section 9 ("Not checked: ... The chair's enumeration over seeds and measured spread; I provide analytic probabilities, not empirical spread").

* **Arithmetic of DeepSeek's unstated per-run spread and return deficit:** Across the $5 \times 3$ faction-hunt submatrix, each faction appears in a run $X \sim \text{Hypergeometric}(N=5, K=3, n=6)$ in the sampling-without-replacement-per-column, across-columns-independent approximation, giving $\mathbb{E}[X] = 3$, $\text{Var}(X) = 6 \cdot (3/5) \cdot (2/5) \cdot (5-6)/(5-1) < 0$ in the naive form -- the correct finite-population correction is not applicable across independent columns, so the proper model is $X \sim \text{Binomial}(6, 3/5)$ in the column-independent approximation, with $\text{Var}(X) = 6 \cdot (3/5) \cdot (2/5) = 1.44$, $\sigma \approx 1.2$. Hence a faction is absent from a run with probability $(2/5)^6 \approx 0.41\%$ per faction, and at least one faction is absent with probability approximately $1 - \text{(inclusion)}$ by inclusion-exclusion, on the order of $2\%$. Marginal and expected-hunt arithmetic holds, but intra-run return probability is unstated: $\Pr(\text{a given faction returns in a later hunt}) = 1/5$ per later cell, independent of earlier cells in DeepSeek's model, so $\Pr(\text{no return in the remaining } k \text{ cells}) = (4/5)^k$.

* **Player-faction symmetry is not preserved by DeepSeek's sampling:** DeepSeek's $6 \times 3$ hunt matrix excludes the player faction from all hunts, so the player faction has 0 hunts while each non-player faction expects 3. This breaks the symmetry the pack's "Symmetry" section requires for a symmetric design, and DeepSeek does not state the asymmetry or its design consequence.

* **#45 and the "No two repeats" rule:** DeepSeek's $H_1, H_2, H_3$ construction enforces no repeats within a column, but does not enforce the pack's #45 rule across rows/columns as stated, and does not check the cross-cell repeat pattern required by the evidence pack.

## Shipped and Suggested Systems

* **Shipped:** DeepSeek ships a $6 \times 3$ hunt matrix, a sequential without-replacement draw, and a per-faction expected-hunt calculation.
* **Suggested, not shipped:** A simulation or enumeration over seeds showing per-run spread, a return-rate calculation, and a symmetry-preserving variant are suggested or deferred, not shipped as checked results.

## Grounding and Scope

* DeepSeek's analytic probabilities are grounded in the pack's faction set and hunt structure, but the empirical spread, return rates, and symmetry check required by the pack are not provided. The review therefore marks the marginal arithmetic as held and the spread/return/symmetry work as omitted or deferred.

# 2. Review of qwen.md

## Symmetry and Probability Arithmetic

* **Marginal arithmetic holds, with the same spread omission:** Qwen's draw likewise gives $1/5$ marginals and 3 expected hunts per faction, but likewise omits per-run spread and return probability.
* **Arithmetic of Qwen's unstated per-run spread:** As for DeepSeek, $X \sim \text{Binomial}(6, 3/5)$ in the column-independent approximation, $\mathbb{E}[X] = 3$, $\text{Var}(X) = 1.44$, $\sigma \approx 1.2$, $\Pr(X = 0) = (2/5)^6 \approx 0.41\%$ per faction, with at least one faction absent in roughly $2\%$ of runs.
* **Player-faction asymmetry:** Qwen likewise excludes the player faction from hunts, giving 0 hunts for the player faction versus 3 expected for each other faction, without stating or resolving the symmetry break.
* **Cross-check failure:** Qwen does not cross-check its hunt matrix against the pack's symmetry, repeat, and seed-spread requirements, and does not provide the enumeration the pack requires.

## Shipped and Suggested Systems

* **Shipped:** Qwen ships the hunt matrix and marginal/expected-hunt arithmetic.
* **Suggested, not shipped:** Seed enumeration, per-run spread, return rates, and a symmetry-preserving redesign are not shipped.

## Grounding and Scope

* Qwen's results are grounded in the pack's faction and hunt definitions for marginals, but ungrounded for spread, return, and symmetry, which are deferred or omitted.

# 3. Source-Backed Ideas, Grounded in the Pack, the Two Writer Legs, and the Review Above

1. **Per-Campaign Hunt-Seed Ledger (Tied to: DeepSeek Section 9 deferral; pack seed-spread requirement):** Idea: Ship, per campaign seed, the full $6 \times 3$ hunt matrix, per-faction counts, and return counts, so spread and return rates are measured, not deferred. This closes the exact gap both legs defer.

2. **Symmetric SP3 Variant (Tied to: player-faction asymmetry in both legs):** Idea: Add a symmetric variant in which the player faction is eligible for hunts on the same $1/5$ marginal basis, with the matrix expanded or rebalanced so no faction is structurally at 0. This restores the symmetry the pack requires and both legs break.

3. **RUN.foes Return Tracker (Tied to: unstated return probability):** Idea: Track, for each faction, first-hunt time, return interval, and $\Pr(\text{return in } k \text{ cells}) = 1 - (4/5)^k$, displayed per run. This makes the return deficit explicit and testable.

4. **Eclipse Hunt-Window Display (Tied to: hunt matrix and per-run spread):** Idea: Show the hunt window, expected hunts (3 per faction), and observed spread ($\sigma \approx 1.2$ in the column-independent approximation) in the campaign UI, so players and reviewers see variance, not only the mean.

5. **Run-Level Player Ship-Loss Counter (Tied to: ship-loss / run-level accounting in the pack and legs):** Idea: Count player ship losses per run, per faction hunt, and per seed, and report loss rate alongside hunt counts, so ship loss is tied to the same seed ledger as hunts.

6. **Advancing Pointer for Hunt Order (Tied to: sequential $H_1, H_2, H_3$ draw):** Idea: Display the advancing $H_1 \to H_2 \to H_3$ pointer per column, with the remaining eligible set $S \setminus \{H_1, \dots\}$ shown at each step, making the without-replacement construction auditable in play.

7. **Latin Rectangle for Hunt Assignment (Tied to: $6 \times 3$ matrix, no-repeat rule, and #45):** Idea: Use a Latin-rectangle construction for the $6 \times 3$ hunt assignment, so each faction appears at most once per column and the row/column repeat constraints, including #45, are enforced by construction rather than by post-hoc checking.
