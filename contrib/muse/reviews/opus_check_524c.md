# Outside check: PR 524 fix 1 against the opus_check_524b BLOCKING (opus_check_524c)

Issue 256 standing check. Checked at PR 524 head 05dd879ba3d4 (opus/issue-461). The only code commit since opus_check_524b is 9cb647c2c9c1 (fx.gd, fx_weapons.gd, hit_recipe_check.gd); the other new commit, 05dd879b, is the deaths_and_hits.md wording fix from the method audit and changes no code. Council: DeepSeek and Qwen writing, Rey chairing (issue 256 block; Argon off, R216). Both legs returned CLEARED WITH NOTES and agree with the chair on every point below.

## Verdict: the BLOCKING is CLEARED. PR 524 may merge on the comfort question.

opus_check_524b blocked on one point: yielded gun flashes drew soft and were remembered nowhere, so the number of peaked soft flashes in one 10 degree field in one second was bounded by nothing. The Board applied the check's own clearing route 1. The fix does what the route said, and the bound now holds in the code, not only in the report.

## What the fix does, verified in the code

- fx.gd flash_at (head): on the yield path (area over the limit, yield_last set), the flash now asks _soft_full(T, c) before drawing. Yielded soft flashes are remembered in _soft_mem as [T, screen x, screen y]; a flash told to lift is not remembered.
- _soft_full counts two populations in the rolling second: every counted bright flash anywhere on screen (deliberately conservative, the code says so), plus remembered soft flashes inside the field. The field test compares screen distance against flash_box_px() in both axes; because it uses the full box side as the reach, the tested square is wider than one field, so it can only over-count, never under-count. At FLASH_CAP (3) the field is full.
- The decision is taken before the current flash is remembered, so the trace is exact: flashes 1 to 3 in a field draw peaked soft and are remembered; the 4th and every later one in the same second set flash_lift and are not remembered; the remembered three expire after one second and the field frees. Both legs traced this independently and got the same table.
- The lift draw: in _burst (fx_weapons.gd), power 0.6 and duration at least 1.2 s, against the soft draw's 1.25 and 0.4; in _staged_hit, intensity 0.6 and duration 1.2, against the soft 1.25 and 0.42. The bright draws it protects are power 4.2 and intensity 5.2.
- No leak paths: the FLASH_WINDOW salvo merge and the behind-camera path return true (bright), never soft; non-yield refusals (torpedoes, deaths) are untouched and still never yield; the no-camera path draws no field because there is no screen, and its peaked draws stay under flash_ok's global 3-per-second counter.

## The one wording correction (NOTE, not a condition)

The commit message and the fx.gd comment say the lift has "no peak". It does peak: the lift keeps the soft shader envelope (ALBEDO multiplied by sin(age * pi)), so it rises to its maximum at mid-life. What is true, and what clears the question, is the size and speed of that peak: 0.6 is about an eighth of the bright staged intensity and about half the soft draw, and the rise takes 0.6 s, three times slower than the soft draw and roughly eight times slower than a bright flash. A single 1.2 s pulse peaking once at 0.6 s is not a rapid luminance change in the sense the 524b check raised, and the rate of peaked draws per field is now capped at the counter's own FLASH_CAP. The record should describe the lift as a slow, dim peak, not as no peak; the Board can fix the comment wording whenever the file is next touched. DeepSeek raised this wording point; the chair adopts it.

## Regression

None found. The bright branch of flash_at, _flash_count, _flash_remember and the torpedo and death paths are untouched by the patch; flash_lift is written only inside the yield branch and read only by _burst and _staged_hit (and the check). The five conditions opus_check_524 verified, and the five opus_check_524b re-verified as MET, are unaffected: the fix commit touches none of their code except the two draw sites above, and only on the lift branch.

## Notes (none blocks the merge)

1. flash_lift can be read stale in one mode: _burst and _staged_hit compute soft as "fx.reduce_flashing or not fx.flash_at(...)". When reduce_flashing is true, GDScript's short circuit skips the flash_at call, so flash_lift keeps the value the last real call left. Both directions are comfort-safe: a stale true makes a reduce-mode draw slower and dimmer, a stale false reproduces exactly the pre-fix reduce-mode draw. Worth a one-line guard if the file is touched again (set the flag from the reduce_flashing branch too), not worth a round trip now.
2. The new assertions in hit_recipe_check.gd prove the flag sequence soundly (first three keep the soft rise, the fourth and later lift, the field frees after a second; the setup forces the yield path and cannot trip the salvo merge, since yielded flashes live in _soft_mem, not _flashes). They do not prove per-field separation (all six calls share one position) or the draw-side values in fx_weapons.gd, which rest on code reading. The Board's report that the check passes on the PC is consistent with the code; the chair did not run it.
3. Lifts are not area-accounted after the cap trips. Their safety rests on the slow envelope and the 0.6 ceiling, both verified above; if a future change raises the lift's power or shortens its duration, this clearance should be re-read before it is relied on.

Council record: DeepSeek, CLEARED WITH NOTES (chat https://chat.deepseek.com/a/chat/s/31a84a8b-a919-49df-a88c-be7d9b9d63af; DeepThink on, Search off, verified before the run). Qwen, CLEARED WITH NOTES (chat https://chat.qwen.ai/c/268ac088-8b8f-490d-a283-375b7dc6b6df; Qwen3.8-Max verified in the selector before and in the header after). One sentence in Qwen's leg (that staleness can only run one way) is corrected in Note 1's framing; its verdict is unaffected.
