# Two ruled-but-unbuilt fixes: implementation spec

Chair spec, Oct 29, 2026, at pin 264f441d. Both fixes implement rulings Ryan already made; nothing here is a new design decision. Locations are the browser sources at the pin; the Godot equivalents are Opus's to map. Wording of player-facing lines is a proposal for Opus and Ryan to adjust, mechanics are the ruling.

## Fix 1: the Q7 spillover ruling (Oct 28) in rollBoonOffer

The ruling: off-patron boon offers stay, but off-patron picks must retain real value; the hidden rarity tax on fillers is the defect.

Current behavior, from the code at core.js:181 (read in full for this spec; the red-team evidence pack truncated the function at its first line, a pack defect the chair owns): the offer takes the patron's useful pool first (pool.slice(0,3), each rolled with the patron argument), a duo may displace the third slot, and only if slots remain unfilled does an off-patron list backfill, each backfill rolled WITHOUT the patron argument. A further subtlety the first filing missed: because the on-patron slice takes up to three first, backfill is arithmetically rare; most offers never reach it.

The change, in two parts, either of which alone is a partial fix:

1. Competition, with an explicit weight (the Argon red-team leg correctly flagged that the first filing said "the patron weighting stays" when the current code has no in-pool weight at all, only sequencing; a merged pool needs the weight stated): build one candidate pool of the patron's useful boons plus useful off-patron boons from the run's held patrons, and sample the offer slots with on-patron candidates weighted 3 against off-patron candidates weighted 1 per candidate. The 3:1 figure is a chair-proposed default for Opus to tune, chosen so a typical offer stays majority on-patron while an off-patron pick regularly competes for the third slot; what the ruling requires is that off-patron picks can appear while on-patron picks remain and carry real value, not any specific ratio.
2. Equal rarity treatment: every pick in an offer, on-patron or off, rolls rarity with the same favour inputs. Concretely, the backfill roll gains the patron argument (or the shared favour computation), so the +.12 rare / +.03 epic favour shift and the tier-3 Rare floor apply uniformly.

Acceptance checks: (a) with a seeded RNG and a fixed fixture (a named sector and patron state where the on-patron useful pool is non-empty), confirm off-patron picks can appear across the seed set; (b) sample rarity distributions for on-patron and off-patron picks under favour >= 1 and favour >= 3 and confirm they match; (c) confirm duo offers are unaffected (duos enter separately at m=1 by design). (The seeded-RNG and fixture requirements in (a) were added Oct 29, 2026 on the DeepSeek red-team leg's note; without them the check is nondeterministic.)

## Fix 2: the Q5 loss-debrief weakness reveal (Oct 29) in nemAfterBattle

The ruling: a lost Nemesis meeting still teaches a weakness on the debrief. Ryan's words on the re-roll question ride along: weaknesses are per-Nemesis and per-run, and it does not matter that a successor or a new run does not keep the same ones.

Current behavior, from the firstrun item's code read: nemAfterBattle (campaign_run.js, around :298 at the pin) reveals a weakness by name on the win branch; the loss branch returns only the drove-you-off line and reveals nothing. Weaknesses themselves are created at Nemesis generation (campaign_run.js:249-251): exactly two, drawn from the seven-pool, filtered so none cancels the Nemesis's traits, fixed for that Nemesis's life. In-battle triggering already reveals a weakness even in defeat (established by the blind Rey firstrun leg), so the debrief reveal extends an existing channel rather than inventing one.

The change: on the loss branch, after the drove-you-off line, reveal one unrevealed weakness by name, chosen from the Nemesis's unrevealed set (if both are already revealed, the line instead confirms the file is complete; wording below). The reveal uses the same revealed-set the win branch writes to, so intel state stays single-sourced, and the adaptation naming that currently appears only on the boss-win sector transition is untouched by this fix.

One refinement (Oct 29, 2026, Argon red-team leg; chair decision, flagged for the designer to veto): a single lost meeting reveals at most ONE new weakness in total. In-battle triggering already reveals weaknesses during the fight, even in defeat; if the battle itself revealed one, the debrief names and confirms that one rather than adding a second, so one defeat cannot hand over the Nemesis's whole two-weakness file. The ruling's intent (a lost meeting is never intel-zero) is fully honored either way; the cap only governs the case where the fight already taught something.

Proposed debrief wording (per-faction idiom is a later text pass; the neutral form): "Your analysts piece together the engagement: [Nemesis name] is vulnerable to [weakness name]." Complete-file variant: "The engagement confirms what your analysts already held: the file on [Nemesis name] is complete." (Wording adjusted Oct 29, 2026 on the DeepSeek red-team leg's note: the earlier "his file" was not neutral.)

Acceptance checks: (a) lose a meeting with both weaknesses unrevealed and confirm exactly one is revealed and named on the debrief; (b) lose with one revealed and confirm the other is named; (c) lose with both revealed and confirm no duplicate or phantom reveal; (d) win a meeting and confirm the win branch behavior is unchanged; (e) confirm a weakness revealed by the loss debrief is respected by the adaptation clash check Ryan ruled the same day (an adaptation may not directly counter a revealed weakness, and a loss-revealed weakness counts as revealed).
