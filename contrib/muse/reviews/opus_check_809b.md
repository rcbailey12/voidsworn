# Outside check: PR 809 beat 3 test change (opus_check_809b)

Refs #256

## Verdict: GO WITH CONDITIONS

The Board's question is answered yes: the check still proves the player can reach the payoff, but the proof now lives in two tests in the same PR, and the Board should know which half sits where. The amended story_beat3_test proves the payoff content renders inside The record for every faction and both outcomes, opening the detail by direct call. The PR's new debrief_ledger_test proves the input step itself: a constructed R key event through the UI's own input handler opens the record overlay, and the overlay's own text contains the faction's learning. One condition, a test-hardening item: scope the beat3 learning assertion to the record overlay, so that test stays self-contained if the two tests are ever split. The chair read both test files and the input chain in full at the merged head and verified all four CI check runs green on it.

Council: blind Rey GO. DeepSeek (DeepThink on, Search off, verified both ends) GO WITH CONDITIONS. Qwen (Qwen3.8-Max, verified both ends) GO. Grok (Fast, verified both ends) GO. Flash (Flash-Lite, verified both ends) GO. ChatGPT (chat, GPT-6 at High, verified both ends) GO WITH CONDITIONS. All six legs agree on the analysis; they differ only on whether the hardening items are conditions.

## The brief

opus_check_809b: PR 809 (merged 2026-11-15T22:31:36Z, head eddc9823, base 1b9aa298), the DB1 after-run rebuild for issue 805 under R261 (Codex lane B). The Board's question is narrow: DB1 moved the beat 3 payoff into The record (key R) and the change to godot/campaign/test/story_beat3_test.gd now opens The record before asserting the payoff text; does the check still prove the player can reach the payoff? Board brief at issue 256 comment 6902790668.

## (a) What the amended beat3 check proves, and what it skips

**Content, for all factions and both outcomes; the input step, not at all.** The hunk is the only change to story_beat3_test.gd in the PR. Inside the loop over every faction in RUN_FACTIONS and won in [false, true], the test now ends the run, calls ui.debrief.open_detail("record"), asserts text_of(ui) contains the faction's STORY_BEAT3 learning text, and closes the detail. That proves the payoff renders once The record is open, for all five factions, after a win and after a loss. It opens the detail by calling the function directly, so on its own it says nothing about whether the player can open it. Its text scope is also loose: text_of walks the whole UI tree, so the assertion would pass if the learning text sat in any node while the record was open. At this head that looseness is sound in fact, because the learning text is rendered in exactly one place (section (c)), but the test itself does not enforce it. Every leg landed on both points.

## (b) The sibling test closes the input step

**Yes, and it is registered in CI.** debrief_ledger_test.gd is new in this PR and added to godot/tools/ci/godot_checks.txt as a headless check ("issue 805: DB1 receipt reachability..."). Its key() helper builds a real InputEventKey (keycode set, pressed true) and passes it to ui._unhandled_input(e), the same entry point a physical press reaches. Its main loop presses KEY_R among the detail keys and asserts the overlay exists (is_instance_valid), that opening the detail is read-only (save_text unchanged), and that all_text scoped to the overlay contains the run faction's STORY_BEAT3 learning, check name "record keeps story payoff", plus the c_loss teaching card the record section also carries. Escape closes the overlay. The council is unanimous that calling _unhandled_input directly is a fair stand-in for a headless CI check: everything from that entry point onward is the game's own code, identical for a physical press, and what remains untested is engine dispatch (viewport routing, focus and GUI consumption), which is engine behaviour rather than game code. ChatGPT and DeepSeek both marked that boundary explicitly; it is recorded as a note below, not a condition.

## (c) The production path the tests exercise

**Verified in full at the merged head.** campaign_ui._unhandled_input routes end-page key events to debrief.handle_key. handle_key looks the keycode up in the KEYS map (KEY_R: "record") and calls open_detail("record"). open_detail builds the LedgerDetail overlay and fills it from _end_detail_body(d, "record"), whose record section adds the c_loss card text, the story text, and the payoff label taken from STORY_BEAT3[fac].learning (campaign_ui.gd line 1612). A search of campaign_ui.gd at the head finds the learning text used only there, so the payoff is not duplicated on the ledger main page. There is also a mouse route: the ledger page's "The record R" link calls the same open_detail("record"). No test simulates that click; the link and the key converge on the one function both tests exercise.

## (d) The seams, weighed

**Two are real and small; one flagged seam is a pack artifact, corrected here.** First, the cross-product: the key-path proof in the ledger test runs on the single fixture its state loop leaves in place ("empty": a voidsworn run, ended as a loss, fleet emptied), so R is pressed for one faction and one outcome, while beat3 covers all factions and both outcomes for content. The handler is a faction-independent map lookup, so the combined coverage is complete in substance; no leg treated this as more than a note. Second, physical dispatch and the link click are unproven, as bounded in section (b). Third, three legs (DeepSeek, Qwen, ChatGPT) flagged KEY_P and KEY_V as untested, working from the pack, whose ledger-test excerpt ended at the key loop (line 190). The chair corrects that: lines 191 to 195 of the same test, immediately below the excerpt, press KEY_P and assert the legacy page and prog_tab ("P opens actual renown spending"), return, press KEY_V and assert the variants tab ("V opens real hull rewards"), and return to the end page. The body's "All moved details remain reachable; Spend renown uses P and The record keeps R" is therefore supported by test as well as code, and the "all" qualification those legs raised falls away.

## (e) The history

**Handled honestly, and it reflects well on the pipeline.** The PR body's Board note (Nov 15 22:20 UTC) states plainly that the Godot game checks failed on story_beat3_test on the first head because DB1 moved the payoff, that the test now opens The record, and names the fix commit eddc982, which is the merged head. The chair verified all four check runs (Standing checks, Godot rules parity, Godot game checks, open-pr) successful on eddc9823 via the check-runs API. CI caught the stale test, the fix is the head, and the body says so. No leg found any concealment; ChatGPT notes the original failure log itself is not in the pack, which is true and immaterial given the head is verified green.

## Conditions

1. **Scope the beat3 learning assertion to the record overlay.** In story_beat3_test.gd, assert the learning text against the overlay's text (the all_text pattern debrief_ledger_test.gd already uses), with the overlay's validity asserted, instead of the whole-tree text_of. Today the tight proof lives in the ledger test and both tests run in the same CI list, so coverage is complete; the condition is so the beat3 check cannot pass on a stray copy of the text if the two tests are ever split or the ledger test is renamed away. Test wording only; no behaviour change. (ChatGPT, DeepSeek; the seam was noted by all six legs.)

## Notes

- **DeepSeek's win-fixture condition is not carried.** It asked for KEY_R exercised on at least a win fixture. The key handler and open_detail are outcome-independent, and beat3 proves the win and loss content once the record is open; the marginal coverage does not justify a condition. Recorded here so the ask is on the record.
- **Physical dispatch stays an accepted boundary.** A viewport-level input test (ChatGPT's follow-up suggestion) would prove engine delivery as well as game code. The repo's own headless pattern is the direct _unhandled_input call, and the ledger test follows it; the Board may still want the stronger test someday, but nothing in this PR is weaker than the standing pattern.
- **The clickable link is code-verified only.** "The record R" calls open_detail("record"), the function both tests exercise through the key path and the direct call. No click simulation exists in either test.

## Leg notes and slips

- DeepSeek, Qwen and ChatGPT flagged KEY_P and KEY_V as untested. That was accurate against the pack, whose excerpt of debrief_ledger_test.gd ended at line 190; the assertions sit at lines 191 to 195 of the file. The chair takes the pack boundary as its own and corrects the point in section (d).
- No leg slipped on the Board's question itself; all six separated the content proof from the input proof the same way, and the two GO WITH CONDITIONS verdicts rest on the hardening items dispositioned above.

## Not checked

- The rest of PR 809 (the DB1 rebuild itself: ledger layout, heir gating, readability and contrast assertions, the DB1 captures). The Board's brief for 809b was the beat 3 test change only; the rebuild's own evidence is the PR's and its checks.
- The DB1 pictures at picture level. Ryan accepted the screen in R271 ("Screen looks good", Nov 15, 2026), which is the owner pass on the look.
