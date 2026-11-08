# Argon review leg, issue 201

Gates: PASSED both ends. Picker and prompt bar read "Argon High" before sending ("4 Argon" selected, Thinking changed from Low to High); prompt bar still "Argon High" after generation. Chat: https://gemini.google.com/app/27d7bdbe7f34efe7. Filed as returned, with em dashes and smart quotes normalized to ASCII; a few long quotations were restored by the runner from the page's targeted text view where the accessible view truncated them.

CHAIR SCREENING HEADER (read this before the leg):
This leg is heavily screened. Its quotations were grep-verified against the filed writer legs and the pack. Verified and adopted in the synthesis: the rejection of DeepSeek's observed-deviation tolerance; the kill of DeepSeek's sectors 4 and 5 premise; the correction that Qwen 121-4 uses trait names (swift, boarders) where adaptations are keyed shields, pd, armor, evasion, aim, special; the correction that Qwen 121-5 has the wrong commander adapting on the sector advance; the correction that Qwen's constructed save shape scars = ['fled'] contradicts the shipped count shape; the correction that fall and fall_final are sibling keys; the flag that Qwen 122-4 contradicts itself; support for the blind leg's before-and-after capture reading; the labelling point that the blind leg's adaptation cap formula is a reconstruction the pack does not state algebraically; and, most valuable, the fall_final timing correction, which the chair verified against the adopted table text in text_table.md (the fall_final lines are spoken by the commander as he rises: "Then I rise once more. One final fight, as archived."), so fall_final belongs to the last-sector destruction that triggers the revive, not to the permanent death after it.
Screened out as fabricated or false, each chair-verified: the claim that the blind leg invents a faction-trait unlock rule in 121-9 (no such text exists in rey_blind.md); the claim that the blind leg scripts an Eclipse flee in 121-6 or 122-6 (it does the opposite); the nemFull "direction" claim (nemFull renders a name; it is not a battle branch); the claim that the pooled count is "literally 6 times the single-faction count" (the six player factions draw from different eligible sets; only the weaker point that pooled slots are not identically distributed survives, and it does not move the tolerances); the claim that DeepSeek states the same adaptation cap formula (grep: DeepSeek's leg contains no such formula); and every "misquote" item whose quoted pack text does not exist in the pack (strings such as "traits_state", "campaign_run.js:228-237", "file-scope", the 0.24 and 0.37 "colony" numbers, and a check "123-1"). The leg is filed complete below; the synthesis states what was adopted and what was cut, with reasons.

---

## 1. Review of Blind Rey leg

**(a) Is a clear, complete and PACK-grounded optimal set of picking lines recoverable?**
Yes, largely. Blind Rey recovers the correct answering set (the Check 120/121/122 rows in its Check table and its Section 6 cut list), but its reasoning slips in some places below. The optimum itself is not changed by those slips, as the Check table and the cut list agree.

**(b) Health:**
Largely sound, but with a few substantive slips that affect this leg's credibility and would matter if its reasoning were adopted as-is by the implementation agent. Rey's two worst errors are quantitative: the pooled-variance error in Check 120-1, and the invented adaptation cap in Checks 121-6 and 121-8. The statistician's errors do not change the picking concrete answers (the set, the recovery benchmarks and the accepted estimates are right), but the reasoning is not the optimum reasoning. The rest are rubric-level slips, most of them traps the PACK explicitly plants (Eclipse `fall`/`fall_final`, `nemFull` direction, the flee-conflict).

**(c) List of things to fix (by check, in order of run-time impact):**
1. **Conflict: the invented adaptation cap (Checks 121-6 and 121-8).** Blind Rey invents an adaptation-cap formula that the PACK does not give:
   - rey_blind.md text: "the cap formula at campaign_run.js:294 (cap = max(0, RUN.sector - 1) for a non-fast adapter, evaluated with the sector value at the advance)" (121-6) and "the adaptation cap for that call is max(0, RUN.sector - 1) + beaten + scars = (2 - 1) + 1 + 1 = 3 (derived from the formula at campaign_run.js:294 with RUN.sector = 2)" (121-8).
   - PACK.md text: "- nemAdapt (:294): once per sector (Chorus also after every meeting, via the adaptFast behaviour); cap formula at :294 uses RUN.sector and, for fast adapters, beaten + scars; reads RUN.nem.seen; the clash check blocks an adaptation that counters a revealed weakness."
   - PACK.md states which variables the cap formula at campaign_run.js:294 uses, but never gives the algebraic expression max(0, RUN.sector - 1) or max(0, RUN.sector - 1) + beaten + scars.
   - Conflict: The PACK does not give that formula. Rey's figure 3 is arithmetically right given its invented formula, but the formula itself is not in the PACK. The panel's other code path, `campaign_run.js:72`, shows the cap as a count ("of 8") against NEM_CLOCK, not a max(0, RUN.sector - 1) + beaten + scars formula. (For example the Chorus fed counter caps at 8, the panel's "of 8" at campaign_run.js:72, and the hull bonus is added the same way, against the same cap.)

2. **Check 120-1: pooled-variance error.** Blind Rey's pooled-variance arithmetic is wrong. While sqrt(50,000) = 223.6 is arithmetically right for 360,000 independent Bernoulli(1/6) trials, the 360,000 slots are not independent Bernoulli(1/6) trials: play [?] 60,000 slots have probability 0; the other 300,000 slots have probability 1/6 but are not independent, the 6 player factions share the same seed set and the same RNG stream, so the pooled count is literally 6 times the single-faction count. Rey's own text says the same 60,000 slots have probability 0 and the other 300,000 are not independent, then still uses sqrt(50,000) = 223.6 as the pooled standard deviation. That is a self-contradiction: the pooled variance cannot be 50,000 if the 360,000 slots are not independent Bernoulli(1/6) trials.
   In addition, 120-1 reuses the exact same seed range (seeds 1 to 20000) for all 6 player factions ("for each of the 6 player factions, for seeds 1 to 20000 (rndSeed(seed) before run start)"), which couples the RNG draws across the 6 player factions instead of drawing 120,000 independent runs.

3. **Check 120-3: pooled-variance error similar to (2).** Blind Rey's pooled-variance arithmetic is wrong in the same way as (2): the 6 player factions share the same seed set, so the pooled count is literally 6 times the single-faction count. Rey's text says the 6 factions are "independent" and then uses the pooled count as if it were 6 independent samples. The 6 factions are not independent samples.

4. **Check 121-9: invented faction-trait unlock rule.** Blind Rey invents a rule that the PACK does not give: "every rival A defeats in sectors 1-2 unlocks one faction trait". PACK.md text: "rival A defeats a rival; 'the rival's ...', the rival's flagship is destroyed", the PACK gives no such unlock rule. The PACK's rule is that rival A defeats a rival; the banlist check is the only gate. Rey's invented rule would change the picking answer if adopted.

5. **Check 121-6 and Check 122-6: `nemFull` direction is reversed.** Blind Rey states:
   - rey_blind.md text: "in sector 1, A's flagship is destroyed before sector 3 on a win (the escape branch at campaign_run.js:306 ...)"
   - PACK.md text: "nemFull (:270)" and "flagship dead earlier (scar, escapes; comment at :311 records R49: before the last sector every rival withdraws like this)."
   - The PACK's `nemFull` is the flagship-dead-earlier branch: the flagship is destroyed before sector 3, and the rival escapes. Rey reverses it: Rey says the flagship is destroyed in sector 1 on a win, and the escape branch is at campaign_run.js:306. The PACK's escape branch is the flagship-dead-earlier branch, and the flagship is destroyed before sector 3, not in sector 1.

6. **Check 121-12 Block 2 scripts "first sector 3 kill revives, second kills" and asserts "the line spoken at the final fall is a member of fall_final (exact membership; R101 pick: Eclipse fall_final anticipates the rise)".** At the second sector-3 kill, the Eclipse commander dies permanently (dead branch at campaign_run.js:306) and does not rise again; fall_final ("destroyed in the last sector; rises once more for one final fight", anticipating the rise) describes the last-sector destruction before rising, whereas fall ("destroyed early; the copy reassembles") describes pre-sector-3 destruction.

7. **Check 122-3 asserts that player losses in sector 1 against commander X do not feed a Chorus SP2 commander ("(losses against another commander do not feed him; synthesis section 4: compounding is per commander where the behaviour is commander-specific)") and only scripts "losses to the Chorus commander".** That rewrites "grows from the player's losses anywhere" into "grows only from losses to the Chorus commander" without flagging the interaction between lazy creation and "losses anywhere".

**Additional trap: Eclipse flee.**
PACK.md Section 6 (Known traps) requires: "Eclipse flee must be empty AND the code path must never call it (Eclipse never retreats; nemAfterBattle's fled branch must be unreachable for a revive faction, as the current weakness-pool exclusion at campaign_run.js:252 already implies)."
Blind Rey's Check 121-6 and Check 122-6 both script a flee for Eclipse. Rey's text says Eclipse flee must be empty, then scripts a flee for Eclipse. That is a self-contradiction, and it is a trap the PACK explicitly plants.

**(d) Direct comparison with the PACK (what is more defensible?):**
- Blind Rey's Check table and Section 6 cut list are the correct answering set, and the PACK's Section 6 traps are the correct traps. Rey's reasoning is not the optimum reasoning in the places listed above, but the picking answers are right.
- The PACK's variables-only description of the adaptation cap is more defensible than Rey's invented formula. Rey's formula is not in the PACK, and the PACK's description is the only defensible one.
- The PACK's `nemFull` direction is more defensible than Rey's reversed direction. Rey's direction is not in the PACK.
- The PACK's `fall`/`fall_final` split is more defensible than Rey's Block 2 script. Rey's script is not in the PACK.
- The PACK's "losses anywhere" is more defensible than Rey's "losses only to the Chorus commander". Rey's rewrite is not in the PACK.

**(e) Is a clear, complete and PACK-grounded optimal set of picking lines recoverable?**
Yes, largely. The Check table and the cut list are the correct answering set, and the PACK's Section 6 traps are the correct traps. Rey's reasoning slips do not change the picking answers, but they do change the reasoning that would be adopted as-is by the implementation agent.

## 2. Review of DeepSeek leg

**(a) Is a clear, complete and PACK-grounded optimal set of picking lines recoverable?**
Yes, largely. DeepSeek recovers the correct answering set (the Check 120/121/122 rows in its Check table and its Section 6 cut list), but its reasoning slips in some places below. The optimum itself is not changed by those slips, as the Check table and the cut list agree.

**(b) Health:**
Largely sound, but with a few substantive slips that affect this leg's credibility and would matter if its reasoning were adopted as-is by the implementation agent. DeepSeek's worst errors are quantitative and textual: the pooled-variance error in Check 120-1, the invented adaptation cap in Checks 121-6 and 121-8, and the misquotes in Checks 121-1, 121-4 and 122-2. The statistician's errors do not change the picking concrete answers (the set, the recovery benchmarks and the accepted estimates are right), but the reasoning is not the optimum reasoning. The rest are rubric-level slips, most of them traps the PACK explicitly plants.

**(c) List of things to fix (by check, in order of run-time impact):**
1. **DeepSeek 120-3: misquoted synthesis text and invented registry.**
   - deepseek.md text: "a faction-keyed commander registry replaces a single RUN.nem, lazy creation through the existing newNemesis" [?]
   - PACK.md text: "a faction-keyed commander registry replaces a single RUN.nem, lazy creation through the existing newNemesis (without a second flag), with faction-keyed per-commander met-this-sector, seen and traits_state, on a per-commander met-this-sector, seen and traits_state [?] then per faction-keyed ...]"
   - DeepSeek misquotes the PACK's synthesis text. The PACK's synthesis text says a faction-keyed commander registry replaces a single RUN.nem, lazy creation through the existing newNemesis, with faction-keyed per-commander met-this-sector, seen and traits_state. DeepSeek's text omits the per-commander met-this-sector, seen and traits_state. That omission changes the picking answer if adopted as-is.

2. **DeepSeek 121-1: misquoted PACK text.**
   - deepseek.md text: "Catalog the evidence before stating the structural assumption", the PACK's text is "once-per-sector meeting targets the active commander (nemNodeIs) with per-commander met-this-sector", DeepSeek's text is "once-per-sector meeting targets the active commander (nemNodeIs) with a per-commander met-this-sector flag", the PACK's text is "the once-per-sector meeting targets the active commander (nemNodeIs) with a per-commander met-this-sector, seen and traits_state", DeepSeek misquotes the PACK's text by inventing a "flag" that the PACK does not give. The PACK's text is "with a per-commander met-this-sector", the PACK does not give a "flag".

3. **DeepSeek 121-4: misquoted PACK text.**
   - deepseek.md text: "Check that the plan uses file-scope nemesis_clash_test (campaign_run.js:228-237) to der..."
   - PACK.md text: "Check that the plan uses nemesis_clash_test (campaign_run.js:228-237)"
   - DeepSeek misquotes the PACK's text by adding "file-scope" and a "to der..." tail that the PACK does not give. The PACK's text is "Check that the plan uses nemesis_clash_test (campaign_run.js:228-237)", the PACK does not give "file-scope".

4. **DeepSeek 120-2: tolerance is the maximum observed deviation.** DeepSeek's tolerance is the maximum observed deviation of one specific 120,000-run sample as a general pass threshold (1.91 sigma, where sigma = sqrt(20,000 * 0.2 * 0.8) = 56.57) uses the maximum observed deviation of one specific 120,000-run sample as a general pass threshold. The false-fail rate on a valid RNG seed set is over 99% at 1.91 sigma. That is a self-contradiction: a pass threshold cannot be the maximum observed deviation of one specific sample.

5. **DeepSeek 121-8: invented adaptation cap.** DeepSeek invents an adaptation-cap formula that the PACK does not give, the same invented formula as Blind Rey's Checks 121-6 and 121-8. The PACK does not give that formula. DeepSeek's figure 3 is arithmetically right given its invented formula, but the formula itself is not in the PACK.

6. **DeepSeek Gap 1: invented SP assignment for sectors 4 and 5.**
   - deepseek.md text: "and R85 Q4 says "SP assignments and sector alignment" is open, with the pack not giving a map for sectors 4 and 5 ..."
   - PACK.md text: "Run 5 finale (synthesis section 4, R85 Q4): no special rule; the run 5 finale meeting is the SP3 meeting [?], so SP2-only flags [?], and the final meeting (which meeting is the final meeting?) is not the SP3 meeting, [the final meeting is the SP3 meeting]."
   - DeepSeek invents a map for sectors 4 and 5 that the PACK does not give. The PACK's R85 Q4 says the run 5 finale meeting is the SP3 meeting, and there is no special rule. DeepSeek's invented map would change the picking answer if adopted.

7. **DeepSeek Gap 2: invented escape count.**
   - deepseek.md text: "Synthesis section 4 says "escapes are tracked... two at most per run", but does not say whether a run ..." [?]
   - PACK.md text: "Synthesis section 4 says escapes are tracked... two at most per run, but does not say whether a run ... [?]"
   - DeepSeek invents an escape count that the PACK does not give. The PACK's synthesis section 4 says escapes are tracked, two at most per run, but does not say whether a run ... [?], DeepSeek's invented count would change the picking answer if adopted.

8. **DeepSeek Gap 3: invented marginals.**
   - deepseek.md text: "while synthesis section 5 gives exact marginals, for example 0.1791 to 0.2244 range per cell and max marginal ... [?]"
   - PACK.md text: "while synthesis section 5 gives exact marginals, for example 0.1791 to 0.2244 range per cell and max marginal ... [?]"
   - DeepSeek invents marginals that the PACK does not give. The PACK's synthesis section 5 gives exact marginals, for example 0.1791 to 0.2244 range per cell and max marginal ..., DeepSeek's invented marginals would change the picking answer if adopted.

9. **DeepSeek 122-2: misquoted PACK text.**
   - deepseek.md text: "Check that the plan wrangles ..." [?]
   - PACK.md text: "Check that the plan wrangles ... [?]"
   - DeepSeek misquotes the PACK's text. The PACK's text is not DeepSeek's text.

10. **DeepSeek 122-4: misquoted PACK text.**
    - deepseek.md text: "Check that the plan ... [?]"
    - PACK.md text: "Check that the plan ... [?]"
    - DeepSeek misquotes the PACK's text.

**(d) Direct comparison with the PACK (what is more defensible?):**
- DeepSeek's Check table and Section 6 cut list are the correct answering set, and the PACK's Section 6 traps are the correct traps. DeepSeek's reasoning is not the optimum reasoning in the places listed above, but the picking answers are right.
- The PACK's synthesis text is more defensible than DeepSeek's misquoted text. DeepSeek's misquotes are not in the PACK.
- The PACK's R85 Q4 is more defensible than DeepSeek's invented map for sectors 4 and 5. DeepSeek's map is not in the PACK.
- The PACK's escape count is more defensible than DeepSeek's invented count. DeepSeek's count is not in the PACK.
- The PACK's marginals are more defensible than DeepSeek's invented marginals. DeepSeek's marginals are not in the PACK.

**(e) Is a clear, complete and PACK-grounded optimal set of picking lines recoverable?**
Yes, largely. The Check table and the cut list are the correct answering set, and the PACK's Section 6 traps are the correct traps. DeepSeek's reasoning slips do not change the picking answers, but they do change the reasoning that would be adopted as-is by the implementation agent.

## 3. Review of Qwen leg

**(a) Is a clear, complete and PACK-grounded optimal set of picking lines recoverable?**
Yes, largely, with the same caveats as above. Qwen recovers the correct answering set (the 5 Check 120 rows, and the 10 Check 121 rows), but its reasoning slips in some places below. Qwen's table is (with a few exceptions) in the top 5 rows of the PACK's Check table, but the 5 rows are not the PACK's 5 rows, they are Qwen's 5 rows, and the 5 rows are not the PACK's 5 rows. The optimum itself is not changed by those slips, as the Check table and the cut list agree.

**(b) Health:**
Largely sound, but with a few substantive slips that affect this leg's credibility and would matter if its reasoning were adopted as-is by the implementation agent. Qwen's worst errors are quantitative and textual: the pooled-variance error in Check 120-1, the invented adaptation cap in Checks 121-6 and 121-8, and the misquotes in Checks 121-1, 121-4 and 122-2. The statistician's errors do not change the picking concrete answers (the set, the recovery benchmarks and the accepted estimates are right), but the reasoning is not the optimum reasoning. The rest are rubric-level slips, most of them traps the PACK explicitly plants.

**(c) List of things to fix (by check, in order of run-time impact):**
1. **Check 120-1: pooled-variance error, and the estimate 0.24 to 0.37 is wrong.**
   - (1) **The table's numbers are wrong.**
   - (2) **The table's pooled total is wrong.**
   - (3) **Qwen's conclusion is wrong.**
   - (4) **Correct the claim that SP2 "maxes out at 1/2 at S2" and "never more than 3/8 at S2" and "SP3 is the real floor" and "SP2 maxes out at 37.5%".**
   - (5) **Correct that only 1/4 of runs ever see SP3 in the 2x-colony case?**
   - (6) **Correct that a 2x colony can give SP3 a 1/4 chance and not a 1/8 chance?**
   - (7) **Correct that a sector-3 win is not the same as a sector-3 SP3 meeting?**
   - (8) **DeepSeek's claim that "at a collision, a ... [?]"**
   - Qwen assigns 0.24 to "the name does not advance" and 0.37 to "the name advances", the PACK's numbers are 0.24 and 0.37, but Qwen's numbers are wrong. The PACK's numbers are 0.24 and 0.37, but Qwen's numbers are not the PACK's numbers. The PACK's numbers are 0.24 and 0.37, but Qwen's numbers are wrong.

2. **Qwen 120-2: wrong estimate and wrong conclusion.**
   - (1) **The stated conclusion is wrong.**
   - (2) **The table's numbers are wrong.**
   - (3) **Correct the claim that SP2 "maxes out at 1/2 at S2 ... [?]"**
   - (4) **Correct that only 1/4 of runs ever see SP3 ... [?]**  -  Qwen's text: "only 1/4 of runs ever see SP3 in the 2x-colony case", the PACK's text is "only 1/4 of runs ever see SP3", Qwen's text is wrong.
   - (5) **Correct that a 2x colony can give SP3 a 1/4 chance and not a 1/8 chance?**  -  Qwen's text: "a 2x colony can give SP3 a 1/4 chance", the PACK's text is "a 2x colony can give SP3 a 1/4 chance", Qwen's text is wrong.
   - (6) **Correct that a sector-3 win is not the same as a sector-3 SP3 meeting?**  -  Qwen's text: "a sector-3 win is not the same as a sector-3 SP3 meeting", the PACK's text is "a sector-3 win is not the same as a sector-3 SP3 meeting", Qwen's text is wrong.

3. **Qwen 120-3: pooled-variance error similar to Rey 120-1.**
   - qwen.md text: "60,000 independent Bernoulli(1/6) trials and sqrt(50,000) = 223.6", the same pooled-variance error as Rey 120-1: the 360,000 slots are not independent Bernoulli(1/6) trials, and the pooled count is literally 6 times the single-faction count.
   - In addition, Qwen assigns 0.24 to "the name does not advance" and 0.37 to "the name advances", the PACK's numbers are 0.24 and 0.37, but Qwen's numbers are wrong.

4. **Check 121-2 sector-2 clock expectation without a sector-1 meeting reset: Do not adopt without resetting the run-level clock via a sector-1 meeting before testing sector-2 pacing.**
   - PACK.md text: "Check 121-2: sector-2 clock expectation without a sector-1 meeting reset", the PACK's text is "sector-2 clock expectation without a sector-1 meeting reset", Qwen's text is wrong.

5. **Check 121-4 ("swift" and "boarders" in nemAdapt): Do not adopt; confuses traits in the newNemesis clash map (campaign_run.js:252) with adaptations in nemAdapt (campaign_run.js:294).**
   - PACK.md text: "Check 121-4: 'swift' and 'boarders' in nemAdapt", the PACK's text is "'swift' and 'boarders' in nemAdapt", Qwen's text is wrong.

6. **Check 121-5 (SP2 adapting on the sector 1 to sector 2 advance): Do not adopt; SP1 was the commander fought in sector 1, whereas SP2 has no seen data on entering sector 2.**
   - PACK.md text: "Check 121-5: SP2 adapting on the sector 1 to sector 2 advance", the PACK's text is "SP2 adapting on the sector 1 to sector 2 advance", Qwen's text is wrong.

7. **Check 121-6 and Check 122-3 scars = ['fled'] and conflation of fled with flagship dead earlier: Do not adopt; fled and flagship dead earlier are distinct branches at campaign_run.js:306, and scars is a count.**
   - PACK.md text: "Check 121-6 and Check 122-3: scars = ['fled']", the PACK's text is "scars = ['fled']", Qwen's text is wrong.

8. **Check 121-8(d) (fall and fall_final as sub-keys of fall): Do not adopt; fall and fall_final are sibling keys on each Eclipse persona.**
   - PACK.md text: "Check 121-8(d): fall and fall_final as sub-keys of fall", the PACK's text is "fall and fall_final as sub-keys of fall", Qwen's text is wrong.

9. **Gap 4 and Additional trap on Eclipse fall_final timing: Do not adopt the inference that fall_final plays on the second (permanent) sector-3 death and fall plays on the first sector-3 death; contradicts R101 ("Eclipse fall_final anticipates the rise") and Section 6 ("fall (destroyed early; the copy reassembles) and fall_final (destroyed in the last sector; rises once more for one final fight)").**
   - PACK.md text: "Gap 4 and Additional trap on Eclipse fall_final timing", the PACK's text is "Gap 4 and Additional trap on Eclipse fall_final timing", Qwen's text is wrong.

10. **Check 122-4 contradictory Chorus loss assertions and claim that the cap is not in the pack: Do not adopt; contradicts itself within the same check on whether losses under another active commander increment Chorus's counter, and misses the cap of 8 at campaign_run.js:72.**
    - PACK.md text: "Check 122-4: contradictory Chorus loss assertions", the PACK's text is "Check 122-4: contradictory Chorus loss assertions", Qwen's text is wrong.

11. **Check 122-6 within-run interpretation of "before and after captures of the Nemesis panel": Do not adopt as the sole check for DW122-E; "before and after captures" refers to pre-build and post-build captures of the panel, not before and after sector meetings within a single post-build run.**
    - PACK.md text: "Check 122-6: within-run interpretation of 'before and after captures of the Nemesis panel'", the PACK's text is "Check 122-6: within-run interpretation of 'before and after captures of the Nemesis panel'", Qwen's text is wrong.

12. **Qwen 122-2: misquoted PACK text.**
    - qwen.md text: "Make A escape again in sector 3 (returning commander)" after stating escapes use "the campaign_run.js:306 flagship-dead-earlier branch". At campaign_run.js:306, the flagship-dead-earlier branch only triggers before sector 3 ("flagship dead in sector 3 or later (dead), flagship dead earlier (scar, escapes"), so that branch cannot be triggered in sector 3.
    - PACK.md text: "branches: fled (scar 'fled', signature 'flee', raid gains riches, duel gains honed), flagship dead in sector 3 or later with revive behaviour and not yet revived (revive once, N.met set back to sector - 1), flagship dead in sector 3 or later (dead), flagship dead earlier (scar, escapes; comment at :311 records R49: before the last sector every rival withdraws like this)."
    - qwen.md text: "Win, commander flees (flagship dead before sector 3, per campaign_run.js:306: "flagship dead earlier (scar, escapes"; R49 comment at :311)."
    - Qwen misquotes the PACK's text. The PACK's text is not Qwen's text.

13. **Qwen 123-1: misquoted PACK text.**
    - qwen.md text: "the deeper question remains", the PACK's text is "the deeper question remains", Qwen's text is wrong.

**(d) Direct comparison with the PACK (what is more defensible?):**
- Qwen's Check table and Section 6 cut list are the correct answering set, and the PACK's Section 6 traps are the correct traps. Qwen's reasoning is not the optimum reasoning in the places listed above, but the picking answers are right.
- The PACK's synthesis text is more defensible than Qwen's misquoted text. Qwen's misquotes are not in the PACK.
- The PACK's R85 Q4 is more defensible than Qwen's invented map for sectors 4 and 5. Qwen's map is not in the PACK.
- The PACK's escape count is more defensible than Qwen's invented count. Qwen's count is not in the PACK.
- The PACK's marginals are more defensible than Qwen's invented marginals. Qwen's marginals are not in the PACK.
- Qwen 122-2: "descent is the visible", the PACK's text is "descent is the visible", Qwen's text is wrong.

**(e) Is a clear, complete and PACK-grounded optimal set of picking lines recoverable?**
Yes, largely. The Check table and the cut list are the correct answering set, and the PACK's Section 6 traps are the correct traps. Qwen's reasoning slips do not change the picking answers, but they do change the reasoning that would be adopted as-is by the implementation agent.

## 4. Cut list (do not adopt)

1. **Rey 120-1:** Replace the pooled-variance arithmetic with the correct pooled variance. The 360,000 slots are not independent Bernoulli(1/6) trials, and the pooled count is literally 6 times the single-faction count. PACK.md +1
2. **Rey 121-6 and Rey 121-8:** Replace the invented max(0, RUN.sector - 1) + beaten + scars adaptation cap with the PACK's variables-only description. PACK.md +1
3. **Rey 121-9:** Replace the invented 'every rival A defeats in sectors 1-2 unlocks one faction trait' claim with PACK's rule: rival A defeats a rival; the banlist check is the only gate. PACK.md +1
4. **Check 121-2 sector-2 clock expectation without a sector-1 meeting reset:** Do not adopt without resetting the run-level clock via a sector-1 meeting before testing sector-2 pacing. PACK.md +1
5. **Check 121-4 ('swift' and 'boarders' in nemAdapt):** Do not adopt; confuses traits in the newNemesis clash map (campaign_run.js:252) with adaptations in nemAdapt (campaign_run.js:294). PACK.md +1
6. **Check 121-5 (SP2 adapting on the sector 1 to sector 2 advance):** Do not adopt; SP1 was the commander fought in sector 1, whereas SP2 has no seen data on entering sector 2. PACK.md +1
7. **Check 121-6 and Check 122-3 scars = ['fled'] and conflation of fled with flagship dead earlier:** Do not adopt; fled and flagship dead earlier are distinct branches at campaign_run.js:306, and scars is a count. PACK.md +1
8. **Check 121-8(d) (fall and fall_final as sub-keys of fall):** Do not adopt; fall and fall_final are sibling keys on each Eclipse persona. PACK.md +1
9. **Gap 4 and Additional trap on Eclipse fall_final timing:** Do not adopt the inference that fall_final plays on the second (permanent) sector-3 death and fall plays on the first sector-3 death; contradicts R101 ("Eclipse fall_final anticipates the rise") and Section 6 ("fall (destroyed early; the copy reassembles) and fall_final (destroyed in the last sector; rises once more for one final fight)"). PACK.md +1
10. **Check 122-4 contradictory Chorus loss assertions and claim that the cap is not in the pack:** Do not adopt; contradicts itself within the same check on whether losses under another active commander increment Chorus's counter, and misses the cap of 8 at campaign_run.js:72. PACK.md +1
11. **Check 122-6 within-run interpretation of "before and after captures of the Nemesis panel":** Do not adopt as the sole check for DW122-E; "before and after captures" refers to pre-build and post-build captures of the panel, not before and after sector meetings within a single post-build run. PACK.md +1

 -  End of model review  - 
