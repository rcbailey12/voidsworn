Blind Review: Job B Evidence Pack, Travel Sprint Oct 26, 2026

1. Ranked Findings (most dangerous first)

Finding 1. B-19 ordering change has no post-change sim baseline visible in this pack.
INFERRED. The commit message says sim3d.js round starts now await turn-start deaths via a roundStart helper in all battle loops. Section 5 of this pack states plainly: "Ordering changes can move sim results even when the rules text is unchanged." No sim output file, timestamp, or comparison from contrib/opus/compute/ is reproduced in this pack, and the pack's own caveat says the connector cannot list the commit's changed files. If no sim was re-run after B-19 landed, every admiral win-rate number and every balance claim that predates this commit is stale. This is the most dangerous gap because the plan's B3 and B4 exit criteria both depend on sim evidence. Closing check: produce a timestamped sim run from contrib/opus/compute/ that postdates commit beae728b, and diff it against the prior baseline.

Finding 2. Admiral-band verdict cannot be given from this pack.
INFERRED. Section 5 says: "The trigger commit message gives NO win rates, so unless you find sim output in contrib/opus/compute/ or in the commit message itself, mark admiral-band verdicts UNSURE." The commit message reproduced in section 2 contains no win-rate figures. No sim output is included in this pack. Therefore I cannot confirm or deny that all admirals sit in the 50 to 90% band. Marked UNSURE. Closing check: pull the latest sim summary from contrib/opus/compute/ and confirm every sector-1 admiral at 96 runs falls between 50% and 90%.

Finding 3. B-18 "no change in the sim" is an assertion, not a demonstrated result.
INFERRED. The commit message says: "no change in the sim, where nothing stalls." Section 5 instructs: "If a sim scenario CAN stall, the claim needs a re-run, not an assertion." I have no sim scenario file in this pack to confirm that no scenario can reach the stalled-battle path. The claim is plausible (a sim that always issues legal orders may never stall), but plausibility is not proof. Marked UNSURE until a sim scenario list or a re-run log is produced. Closing check: grep the sim scenario files for any path that could trigger the stall condition in killUnit, or re-run the sim and show identical output before and after B-18.

Finding 4. Voidsworn carrier conflict is unresolved on the record.
OBSERVED (from pack text, section 4). The rulings section states: "CONFLICT TO CHECK: an asymmetry ruling list records 'Voidsworn no carriers' as a faction loss, but approved plan B3.1 says Voidsworn KEEP carriers at a price premium because a ban would break Commodore Ashgrove." The pack further says: "Flag any stream B change that follows the loss list over the plan, and flag the conflict itself if both texts are still on main." I cannot inspect main to see whether both texts still coexist. The conflict is flagged here as directed. If any stream B change in this commit removed or gated Voidsworn carriers, it would break Commodore Ashgrove (data.js:204 per the plan text) and violate the approved record. Marked UNSURE whether both texts remain on main. Closing check: confirm on main that the asymmetry list either removes the "Voidsworn no carriers" line or annotates it as superseded by plan B3.1.

Finding 5. FID telemetry maps to B3 exit criteria but player readability is unverified.
INFERRED. The commit message lists FID outputs: average firing range, incoming damage split (shields, armor and other cuts, hull), hull regrown per ship, loss rate, damage dealt per ship. Section 5 says these "map directly onto the B3 exit criterion (factions playing differently on engagement range, shields versus armour soak, losses)." That mapping holds for the sim. However, section 5 also says: "A faction identity mechanic the player cannot see in game (sync collapse, feed heals, attrition ticks) is a readability finding even if the sim numbers are right." The FID line is a sim diagnostic. I have no evidence in this pack that the player sees, in the browser or Godot build, a visible readout for sync collapse radius, Chorus feed heals, or Deathless attrition ticks. Marked UNSURE. Closing check: point to the in-game UI element or tooltip that surfaces each of those three mechanics to the player.

Finding 6. B4 exit cannot be claimed while Ryan is traveling.
OBSERVED (from pack text, section 5). Section 5 states: "B4 exit needs Ryan to play each item, and Ryan is traveling and not playing for 4 days. Any B4 item claimed as exited before his return is a finding, not a pass." The trigger commit message does not claim a B4 exit. It addresses B-18, B-19, and FID telemetry only. No finding here, but this is noted so the chair knows the B4 gate is still closed. If any downstream document marks a B4 item as exited before Oct 30, that is a violation.

Finding 7. The commit's file list is unverified.
OBSERVED (from pack text, section 2). The pack states: "the connector used for this pack cannot list a commit's changed files, so the file list behind this message is unverified." I cannot confirm that battle.js, sim3d.js, and the fmatrix sim file were actually touched in commit beae728b. I also cannot confirm that no other files were touched. Marked UNSURE. Closing check: run git show or git diff-tree on beae728b and list every changed file.

Finding 8. No evidence that the FID telemetry is not sim-only.
INFERRED. The FID line is described as printed by "fmatrix" in the sim. The plan's B3 exit says "Ryan plays each faction once and says whether it feels like itself." If the only place a designer can see "average firing range" or "damage split by shields, armor, hull" is a sim log, that is fine for balance work but does not by itself satisfy the "feels like itself" playtest gate. This is not a code bug; it is a process gap. Closing check: confirm Ryan's playtest is scheduled and that the FID output will be shown to him as context.

2. Verdicts on Trigger Items

B-18 (killUnit stalled-battle check):
Flagged, UNSURE. The fix described (a comment swallowed the check; it now runs) is consistent with the plan in the sense that it restores intended logic. However, the claim "no change in the sim, where nothing stalls" is unverified. I have no sim scenario list, no re-run output, and no file:line in this pack showing the restored check in battle.js. The fix is plausible but I cannot confirm it exists in current code or that it is benign. Verdict: consistent with plan intent, but UNSURE on execution and sim impact until a re-run or scenario audit is produced.

B-19 (roundStart helper, turn-start death ordering):
Flagged, UNSURE. The change is described as making sim round starts await turn-start deaths "the way the game does." This is consistent with the plan's principle that the JS game is the rules oracle and sims must mirror it. However, section 5 warns that ordering changes can move sim results. No post-B-19 sim output is visible in this pack. No file:line for the roundStart helper in sim3d.js is provided or verifiable here. Verdict: consistent with plan intent (sim mirrors game), but UNSURE on balance impact until a post-change sim run is produced and compared to the prior baseline.

FID telemetry:
Consistent with plan, with one caveat. The metrics listed (average firing range, damage split by shields/armor/hull, hull regrown, loss rate, damage per ship) directly address the B3 exit criterion of "factions playing differently on engagement range, shields versus armour soak, losses." This is a positive match. The caveat: I cannot confirm the code exists (no file:line for the fmatrix FID print is verifiable from this pack), and I cannot confirm the player has any in-game counterpart for these numbers. Verdict: consistent with B3 exit measurement. UNSURE on existence in current code and on player readability.

3. Not Checked

Actual file contents of battle.js, sim3d.js, and the fmatrix sim file. The pack's connector cannot list changed files, and I have no repo access. I could not confirm that killUnit contains the restored stall check, that sim3d.js contains a roundStart helper, or that the fmatrix sim prints FID lines. All three are UNSURE.
contrib/opus/compute/ sim outputs. No sim output file is reproduced in this pack. I could not verify whether any sim run postdates commit beae728b, nor could I check admiral win rates against the 50 to 90% band.
data.js:204 (Commodore Ashgrove). Referenced in the plan text. I could not open data.js to confirm the entry or its current state.
battle.js:702 (reanimate rule). Referenced in the plan text for Deathless elite attrition. I could not confirm the line exists or is unchanged.
The asymmetry ruling list on main. Section 4 flags a conflict between the loss list and plan B3.1 regarding Voidsworn carriers. I could not check whether both texts are still present on main.
Any GDScript or Godot-side changes. The plan says rules land in JS first, then GDScript with a golden scenario. This pack gives no GDScript evidence. Not checked.
Ryan's playtest status. The pack says Ryan is traveling for 4 days. I cannot confirm his return date or whether any playtest has been scheduled.
Whether the FID telemetry has a player-visible counterpart in the browser or Godot build. Not verifiable from this pack.

4. Basis of Claims

Every claim in this review is drawn from the pack text alone. The only file:line references I can cite are those the pack itself provides: data.js:204 (plan B3.1, Commodore Ashgrove) and battle.js:702 (plan B3.5, reanimate rule). Both are cited from the plan text in section 3, not from my own reading of those files. All other file references (killUnit in battle.js, roundStart in sim3d.js, FID print in fmatrix) come from the commit message in section 2 and are UNVERIFIED. I did not observe any line number for them. All findings that depend on the actual state of code are marked UNSURE or INFERRED as appropriate.
No em dashes appear in this review. No external model's output was consulted. This is a blind leg working solely from the pack above.

END OF REVIEW TEXT.
