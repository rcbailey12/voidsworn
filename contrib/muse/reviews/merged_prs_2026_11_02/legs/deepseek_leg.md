DeepThink and Search were both verified ON (pale blue) at send time.

Gates (restated verbatim from pack.md): DeepSeek web chat, DeepThink ON and Search ON, named in this launch. If the site does not show DeepThink and Search available, stop and report; do not substitute another mode or model. No self-writing: a report DeepSeek did not produce is not a leg.

Scope: 15 merged PRs of Nov 2, 2026, main at 80307a2. Diffs read where the public tree exposes them; Godot runtime behavior is INFERRED unless a code path is shown. Chair verdicts and fixes attacked where the citations or reasoning do not hold.

Findings (cap 10)

F1. PR #83 — the chair's saneMeta fix cites the wrong file and the wrong line, so completeness is unproven. OBSERVED. The Godot saneMeta is at godot/campaign/campaign.gd:285–289, not line 354, and it does not include heirs or shadowPool in its key list. The chair says the fix adds them to “core.js:102”, but core.js:102 is inside repairRunIds, not saneMeta. If the browser saneMeta is defined in a different file, the fix may have edited the wrong function. Failure case: a meta with heirs: "vex" and shadowPool: 42 still passes saneSave, migrateMeta does not repair it, and awardLineageXP stops persisting shadow XP while ACT_nameHeir silently does nothing. The chair's regression test may pass only because it exercises the Godot path, not the browser path. This needs a re-read of the actual fix branch, not a citation that does not match the code.

F2. PR #32 — look_at_from_position local-vs-global bug is real enough to block a clean verdict. INFERRED. godot/world/blocker_visuals.gd:105 calls mi.look_at_from_position(mi.position, b, ...) with mi.position, which is local to the blocker node. look_at_from_position operates in global space. If build() runs after the blocker is in the tree, every outline segment gets a global origin derived from a local value and lands near the world origin; if build() runs before tree entry, the call is harmless. Failure case: a station or planet set-piece whose rim segments appear at the wrong place. The chair correctly flags this as needing the engine, but the verdict for #32 should be “findings, unresolved” rather than “FINDINGS, one item for Opus” only in the bigger-items section. A one-screenshot check is cheap; the code read alone cannot clear it.

F3. PR #14 — the r1 FS-2 test asserts less than its name claims. OBSERVED from the chair's own description. The test now computes the Eclipse battleship price from FAC_PRICE through the shipyard rounding instead of comparing table entries directly. It still pins 590 against the 415 cruiser, but a FAC_PRICE edit that kept the product at 590 would not be caught. Failure case: a future balance change raises the cruiser price and the battleship price in a way that preserves 590, and the test stays green while the intended 415/590 relationship is gone. The chair judges this acceptable; a hostile reviewer should not. The test name says it guards the price relationship; it guards one output number.

F4. PR #63 — trunk display uses MASTERY_XP thresholds, which are only known equal to LINEAGE_XP through level 4. INFERRED. The chair says “MASTERY_XP thresholds, which equal LINEAGE_XP for levels 1 to 4 (0, 6, 16, 30, 50 in data.js:583 and the LINEAGE_XP table), so no visible mismatch.” If LINEAGE_XP has a level 5 or higher and MASTERY_XP does not, or if the two tables diverge after level 4, the lineage trunk screen shows the wrong next-level cost. Failure case: a player with lineage level 4 sees the mastery threshold for level 5 instead of the lineage threshold, and the UI lies about the next pick. The chair checked only the first four rows. A full table comparison is required before calling #63 clean.

F5. PR #35 — the torpedo flight clamp is a pacing change that can desync visual impact from damage timing. INFERRED. godot/fx/fx_weapons.gd torp_strike clamps flight time to 0.85–1.25 s. A point-blank torpedo now flies longer than its distance implies, and a long-range torpedo flies shorter. Failure case: a torpedo fired at range 1 visually arrives after 0.85 s while the damage resolution or the next round's start is keyed to a shorter flight; the player sees the hit land after the shields have already been re-raised or after the turn has passed. The chair accepts this as “a pacing change wearing a clarity fix's clothes”; that is exactly why it should be a finding, not a note. At minimum the clamp needs a comment tying it to R80 or a named pacing brief, or Opus should veto it.

F6. PR #83 — the overflow-pool redistribution termination proof is not in the code, only in the chair's summary. INFERRED. The chair says “each pass either spends the pool or caps at least one benched line,” but the actual loop is not shown in the pack. Failure case: a benched line with a zero or negative XP rate, or a pool that is smaller than the smallest line's capacity, could leave the pool unchanged across a pass and loop indefinitely or cap all lines without spending. The chair's word “terminates” is not evidence. This needs the actual while condition and a fixture with a zero-rate benched line.

F7. PR #38 — clamping after summing is correct for caps, but FX_CAPS keys that are lower bounds would be inverted. INFERRED. core.js:249–253 does o[k]=Math.min(o[k],FX_CAPS[k]). If any FX_CAPS entry is intended as a floor (a minimum, not a maximum), Math.min caps it downward and makes the penalty worse. The chair says “single effects stay intact per the fixture suite,” but the fixture suite may only cover positive caps. Failure case: a future FX_CAPS entry for a stat that should never drop below a floor is instead clamped to that floor as a maximum, so a penalty can never make the stat go below the floor. The naming FX_CAPS implies maxima, but the code has no assertion that every key is a maximum. This is a latent trap for the next contributor.

F8. PR #47 — _exit_tree detaches only under headless or dummy renderer; a normal export smoke path with a real renderer still leaks. INFERRED. The chair says the guard “detaches render instances only under the headless or dummy renderer, the exact case the issue describes, and returns early otherwise.” If the export smoke ever runs with a real but unattended renderer (for example a CI runner with a virtual GPU), the early return leaves render instances attached and the smoke still fails. Failure case: a CI job that does not set the headless flag but has no window manager; _exit_tree returns early, the renderer keeps the instances, and the export smoke reports a leak that #47 was supposed to close. The fix is correct for the exact issue, but the guard is narrower than the class of export smoke environments.

F9. PR #39 — the flake fix seeds the RNG in the test, but the shipped nemAfterBattle randomness is unchanged. OBSERVED. The test now calls rndSeed(37) and pins N.weak. That removes the flake, but a player can still get a random torp weakness that blocks the pd adaptation the test asserts. Failure case: a live run reveals the torp weakness at random, the player's Nemesis then fails to adapt pd as the player expected, and the only record is the test's seeded path. This is not a shipped bug, but the verdict “CLEAN” overstates what the PR does: it makes the test deterministic, not the game.

F10. PR #68 — the removed NEB_SHEET shader string is dead code, and the chair's “harmless” note misses the drift risk. OBSERVED. godot/ui/campaign/map3d_shaders.gd still defines the shader string after godot/ui/campaign/map3d.gd stopped using it. Failure case: a future contributor sees the defined NEB_SHEET, assumes it is live, and edits it for a visual fix that never reaches the campaign map. The chair says Opus can delete it “whenever”; a hostile reviewer should say the PR should delete it now or add a comment saying it is unused. Dead code that looks live is a documentation bug waiting to happen.

Per-PR verdicts

PR #10 (wording): CLEAN. Text only; the Godot cmdDesc and both regenerated tables carry the new scramble text and not the old carrier text (string search, OBSERVED). No code claim to attack.

PR #14 (price tests): FINDINGS, F3. The tests pass and pin 590, but the FS-2 check is weaker than its name. A FAC_PRICE edit that preserves 590 slips through.

PR #32 (playtest batch 1): FINDINGS, F2. The blocker outline call is a real local-vs-global risk. The rest of the batch reads clean on the chair's evidence: cache keys include seed/settings/shader source/dimensions, and hull debris cuts real loaded hulls on a joined worker.

PR #35 (playtest batch 2): FINDINGS, F5. Glide timing and removed fields are clean, but the torpedo clamp is an unowned pacing change. Accept only with a comment tying it to a brief or a veto.

PR #36 (onboarding tests): CLEAN. The tests evaluate the real TIPS table, which is stricter than the regex scrape they replaced. No finding.

PR #38 (effect caps): FINDINGS, F7. The clamp is correct for positive caps; the Math.min assumption is a latent trap if any cap is ever a floor. The fixture suite covers the current keys; it does not cover the invariant.

PR #39 (b4 flake): FINDINGS, F9. The flake is fixed in the test, but the game's random torp weakness remains. Verdict should be “CLEAN for CI, note on shipped randomness,” not flat CLEAN.

PR #46 (Nemesis clash tests): CLEAN. Tests only; two new files; no shipped code changed. The browser suite passes 12,330 cases and the Godot fixture replay exists.

PR #47 (export smoke guard): FINDINGS, F8. Correct for headless/dummy, but the early return is narrower than the class of export-smoke environments. A real-renderer CI runner still leaks.

PR #63 (lineage): FINDINGS, F4. The port mirrors the browser on validation, respec pricing, and gating, but the trunk display's MASTERY_XP thresholds are only verified equal through level 4. A full table comparison is missing. Also note the chair's own caveat: Codex was cut off before validation on this PR.

PR #64 (free exit tests): CLEAN. Tests only; the browser suite drives the real picker and handlers for every fight event and faction at 0 and 120 credits.

PR #68 (playtest batch 3): FINDINGS, F10. Damage staging matches R80, engine trails are world-space, and removed trail fields have no references. The unused NEB_SHEET shader string should be deleted or commented in the same PR.

PR #69 (fx guards): CLEAN. The typeof guards are systematic on every fx and animation entry point; a grep finds no unguarded calls to the named functions outside try blocks and definitions. Both oracle copies are updated in step.

PR #83 (shadow XP): FINDINGS, F1 and F6. The saneMeta gap is real, but the chair's fix citation does not match the code, and the overflow-loop termination is asserted, not shown. The rest of the port (heir naming gated to debrief, duplicate endRun protection, importer fixtures) reads clean.

PR #85 (deaths): CLEAN on code, docs fixed on branch. Code matches the issue: Chorus ruptures, ordinary blast kills split, debris and wreck lock to the board plane, and death_plane_check.gd is wired into check_destruction.bat. The docs were stale and are fixed on muse/issue-86. No code finding.

Attack on the chair's fixes

saneMeta fix (F1): The intent is correct, but the location citations are not. core.js:102 is repairRunIds, and the Godot saneMeta is at campaign.gd:285, not :354. Until the fix branch is read at the actual function, the completeness claim is unproven. The regression test must exercise a malformed browser meta, not only the Godot path.

Docs fix for #85: The stale passages are correctly identified (godot/fx/API.md:118 and :360). No attack on the content, only the evidence: the chair says “all four passages now match the code,” but the pack does not show the fixed lines. This is a trust-me claim.

Blocker inference (#32): The chair's reasoning is sound, but the verdict for #32 should not be grouped with “findings, one item for Opus” while the PR is also called clean in the batch. A local-vs-global call at blocker_visuals.gd:105 is a code-level bug class, not a presentation note.

Not checked

Godot runtime behavior of any .gd change. No Godot binary was available; all Godot-side claims are code reads or INFERRED.

The actual diffs of the 15 merge commits. The public tree at 80307a2 exposes the current code, not the per-PR git diff <merge>^1 <merge>. Findings rest on the current code and the chair's cited evidence.

The fix branch muse/issue-86 itself. The saneMeta fix and the docs fix could not be read at their claimed lines; only main at 80307a2 was inspected.

PC-only checks (Godot parity, campaign parity) were not re-run. The browser suites described in synthesis.md were not re-run here.

The exact FX_CAPS table contents. F7 is a class-of-future-change risk, not a current failure.

The overflow-pool loop in PR #83. F6 is a missing-proof finding, not a reproduced infinite loop.

PRs merged Nov 2 that are not code PRs in the issue list (docs and design merges such as #73, #74, #84) are out of scope.
