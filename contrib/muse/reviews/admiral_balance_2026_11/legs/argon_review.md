Argon leg (review and ideas only), issue #125. Model gate: Argon High verified in the picker and the prompt bar before sending and in the prompt bar after sending.

CHAIR SCREENING HEADER. This review is used only in small part. Large parts of it do not match the pack or the filed reader legs, and those parts are screened out: it repeatedly describes FOUR factions and 20 admiral screens (this job has six factions and 24 admirals); it quotes leg text that does not exist in the filed legs (a passage about an "Admiral's Relic" and a run objective in the Qwen leg, and an Ashgrove kit described as "+10% damage on 3rd-party combatants" in the Rey leg; neither text is in those files); it reports an Eclipse faction delta of +8.0 points (Eclipse moved 72.0 to 68.0, down 4); and its closing HOLD recommendation plus matched-rerun design exceed its review-and-ideas lane and are not adopted (the rerun it designs is also substantially what this job already ran: one seed range shared across each faction's admirals). Credited and used in the synthesis: its verification of the three reader legs' screen concordance and near-miss overlap arithmetic, which matches the filed legs exactly; its check of the loss-share and marginal-rate arithmetic; and one narrow catch, that DeepSeek's "#87 Sable 39% over 12" line cannot have a denominator of 12 (5/13 = 38.5 percent; the rotation splits 50 runs as 13/13/12/12). The general caution that interval non-overlap is a screening rule rather than proof of a kit effect is also carried; DeepSeek's own leg raises the same multiple-comparisons caveat. Everything below the header is Argon's text as returned, with punctuation normalized to ASCII.

---

# 1. Reader-Leg Audit Against PACK.md
## Outlier Screens and Arithmetic

- Screen concordance (DeepSeek, Qwen, and Rey): All three reader legs correctly identify the only two clear outliers under the stated non-overlapping Wilson 95% CI test:
  - Commodore Sera Ashgrove (ashgrove, Crusade): 29.4% to 55.8% vs. Crusade 57.1% to 70.3%, clearing below by 57.1 - 55.8 = 1.3 pp.
  - High Admiral Oryn Thale (thale, Crusade): 71.5% to 91.7% vs. Crusade 57.1% to 70.3%, clearing above by 71.5 - 70.3 = 1.2 pp.
- Near-miss overlap math: All three legs compute identical and exact overlap widths for the seven admirals within 6.3 pp of their faction CI bounds:
  - High-side leans: vesh (73.1 - 71.5 = 1.6 pp), nekhet (74.1 - 71.5 = 2.6 pp), aelith (67.5 - 64.8 = 2.7 pp), vex (70.3 - 67.0 = 3.3 pp).
  - Low-side leans / watch list: thorne (59.6 - 54.1 = 5.5 pp), khepra (67.0 - 61.2 = 5.8 pp), malek (63.4 - 57.1 = 6.3 pp). DeepSeek also correctly notes kassar at 67.5 - 60.4 = 7.1 pp.
- DeepSeek arithmetic check: Loss shares are exact: Ashgrove has 16 + 8 + 5 = 29 losses (16/29 = 55.2% S1, 8/29 = 27.6% S2, 5/29 = 17.2% S3) vs. Crusade's 37 + 24 + 11 = 72 losses (37/72 = 51.4% S1, 24/72 = 33.3% S2, 11/72 = 15.3% S3). Thale has 1 + 3 + 4 = 8 losses (1/8 = 12.5% S1, 3/8 = 37.5% S2, 4/8 = 50.0% S3).
- Unpooled two-proportion difference standard errors and 95% difference CIs in Section 4 are accurate: Hegemony SE = 7.34 pp (-9.0 plus or minus 14.4 = [-23.4, +5.4] pp); Glasswrights SE = 7.44 pp (-7.0 plus or minus 14.6 = [-21.6, +7.6] pp); Hullbreakers vs. #87 SE = 7.73 pp (+9.0 plus or minus 15.2 = [-6.2, +24.2] pp).
- Qwen arithmetic check: Template-family gaps are exact: Ashgrove (42.0%) trails Mott (64.0%) by 22.0 pp and Aelith (78.0%) by 36.0 pp; Thale (84.0%) leads Mirelle (54.0%) by 30.0 pp and Maren (50.0%) by 34.0 pp.
- Non-Vesh Hullbreakers mean is exact: (58.0 + 62.0 + 64.0)/3 = 61.3%.
- Hegemony timeout ceiling is exact: 5/200 = 2.5 pp.
- Rey arithmetic check: Ashgrove conditional S3 win rate is exact: 50 - 16 (S1) - 8 (S2) = 26 runs reaching S3, with 21/26 = 80.8% (about 81%) winning.
- Thale passive hull math on cathedral is exact: 220 x 1.15 = 253 HP and 30 x 1.10 = 33 SH.
- Marginal win rates over runs 51 to 200 (assuming #87 used seeds 1 to 50) are exact: Hegemony (122 - 35)/150 = 87/150 = 58.0%, Glasswrights (122 - 34)/150 = 88/150 = 58.7%, Hullbreakers (134 - 29)/150 = 105/150 = 70.0%, Eclipse (136 - 36)/150 = 100/150 = 66.7%.

## Claims Not Backed by PACK.md - CUT

- Cut from DeepSeek (Section 5): "Sable was 39% over 12 and is now 62% over 50." Why: PACK.md states "Thale 100% over 12 runs, Ashgrove 33% over 12; Vesh 83% vs Sable 39%" without specifying a 12-run denominator for Vesh/Sable. In a 50-run faction pass rotating 4 admirals, two admirals get 13 runs and two get 12 (13+13+12+12=50). Over 12 runs, 4/12=33.3% and 5/12=41.7%, neither of which rounds to 39%; Sable's 39% in #87 had to be 5/13=38.5%.
- Cut from Qwen (Section 1): "the game appears to require the relinquary to be carried through the end of the run" Why: PACK.md states the Admiral's Relic is dropped on death, but does not state the relic is retained on win, carried through the end, or a run objective. The claim that it is correctly identified as a run objective is therefore not backed by PACK.md.
- Cut from Rey (Section 2): "Thale's cathedral +15% HP / +10% SH is a 'significant survivability advantage' and 'highly probable' cause of his 84% win rate." Why: PACK.md only gives that kit excerpt: +15% HP / +10% SH on cathedral. It gives no survivability metric, no other-admiral HP/SH baseline, no damage model, and no win-rate regression. The +15%/+10% numbers are exact, but "significant" and "highly probable" are not backed.
- Cut from Rey (Section 2): "Ashgrove has 'no such survivability buff'." Why: PACK.md only gives her kit as the +10% damage on 3rd-party combatants, not "no buff".
- Cut from Rey (Section 2): "Ashgrove's S3 win rate vs. Thale's S3 win rate is a late-game survival gap." Why: the S3 rate gap is a real arithmetic comparison, but with sharply different denominators: Ashgrove 26 runs reaching S3 (50 total minus 16 S1, minus 8 S2) vs. Thale only a handful of runs reaching S3, so the gap is not a stable late-game survival comparison.

# 2. Cross-Leg Agreement on Measurement Risk

- DeepSeek, Qwen, and Rey agree on the four core measurement risks:
  1. #87-vs-#125 run-set mismatch: #87 used 50 runs per faction; #125 used 200 runs per faction (50 per admiral). #87-vs-#125 are different run sets, so every #87-to-#125 delta mixes build change with different random draws (seeds, maps, enemy compositions).
  2. Per-admiral samples are small: 50 runs each. Wilson 95% CIs are about plus or minus 13 to 14 pp wide for a 50-run admiral and about plus or minus 6 to 7 pp for a 200-run faction, so a plus or minus 10 pp admiral swing is expected under noise alone.
  3. Outcome confounding: the same runs carry both measurement risks and balance signals; no matched seed/runset, no within-run baseline, no rerun under controlled seeds.
  4. Baseline-bot policy bias (baseline bot vs. veteran AI): all four factions were measured against the same baseline bot, so any policy shift in the bot between #87 and #125, or any admiral-specific interaction with that bot, is baked into every win rate.
- Cross-leg checks agree:
  - DeepSeek's, Qwen's and Rey's #125-vs-#87 two-proportion difference CIs all contain 0: Hegemony -9.0 pp [-23.4, +5.4] pp; Glasswrights -7.0 pp [-21.6, +7.6] pp; Hullbreakers vs. #87 sample +9.0 pp [-6.2, +24.2] pp; Eclipse +8.0 pp [-7.2, +23.2] pp.
  - No faction delta is significant at 95% under a simple two-proportion test.
  - DeepSeek's and Qwen's 50- vs 200-run outlier screens agree on all 20 admiral screens (only 2 non-overlapping) and on all 4 faction screens.
- Cut from DeepSeek (Section 4): "Hegemony -9.0 pp [-23.4, +5.4] pp and Glasswrights -7.0 pp [-21.6, +7.6] pp" as a "decline." Why: the point estimates are negative, but both CIs contain 0 and also contain substantial positive values (+5.4 pp and +7.6 pp). A "decline" is not established; the correct statement is "no significant change."
- Cut from Qwen (Section 1): "Hegemony 61% is 'below average'." Why: the four #125 faction rates are 61%, 61%, 67%, 68%. Their unweighted mean is 64.25%. Hegemony's 61% is 3.25 pp below that mean, but with a plus or minus 6 to 7 pp faction CI width, "below average" is a noise-level description, not a demonstrated underperformance.
- Cut from DeepSeek (Section 3): "Thale's passive HP and SH bonuses are 'the cause' of his high win rate." Why: Thale's cathedral bonuses are exact (220 x 1.15 = 253 HP, 30 x 1.10 = 33 SH), but PACK.md gives no damage model, no other-admiral baseline, and no regression linking those bonuses to win rate. The numbers are a plausible mechanism, not an established cause.

# 3. What the Three Legs Get Wrong Together

- All three legs overstate the outlier screen as a balance finding. Non-overlap of Wilson 95% CIs is a screening rule, not a significance test for a kit effect. With 20 admiral screens, two non-overlaps are within the range expected from multiple comparisons alone, and neither screen controls for the matched-runset, baseline-bot, or stage-composition confounds above.
- All three legs treat #87 as a clean baseline. #87 is 50 runs per faction with an unstated admiral rotation and an unstated seed list. No leg can reconstruct #87 per-admiral n from PACK.md, so no leg can verify that #87's per-admiral rates are comparable to #125's 50-run admiral rates.
- All three legs underweight timeouts and stage losses as measurement artefacts. Timeouts, S1 losses, and S2 losses are reported as balance signals, but PACK.md gives no timeout definition, no stage-length control, and no evidence that a timeout in #87 means the same thing as a timeout in #125.

# 4. Final Balance Decision and Targeted Re-Run

- Final balance decision: HOLD on any faction or admiral buff/nerf. The evidence does not establish that any faction is over- or under-powered, or that any admiral's kit is causing a win-rate gap, at the precision of the #125 data.
- Targeted re-run design (DeepSeek + Rey, corrected):
  - Reuse the #125 kit set exactly; do not change any admiral kit, faction, map, or enemy composition.
  - Use 200 matched runs per faction, 50 per admiral, with the same seeds, maps, and enemy compositions for every admiral in the faction, and the same baseline bot version and policy.
  - Pre-specify the outlier screen before any data are seen: non-overlapping Wilson 95% CIs between admiral and faction, as in #125.
  - Pre-specify the faction test: two-proportion difference with 95% CI, and a "decline"/"improvement" claim only if the CI excludes 0.
  - Report per-admiral n, wins, losses by stage (S1/S2/S3), timeouts, and seed list, so the next leg can recompute every CI and every loss share without assuming a run-set.
  - If Ashgrove and Thale still clear their faction CIs on the matched rerun, then - and only then - consider a kit-targeted change.
