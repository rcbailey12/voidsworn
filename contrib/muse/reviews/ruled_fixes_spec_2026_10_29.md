# Two ruled-but-unbuilt fixes: implementation spec

Chair spec, Oct 29, 2026, at pin 264f441d. Both fixes implement rulings Ryan already made; nothing here is a new design decision. Locations are the browser sources at the pin; the Godot equivalents are Opus's to map. Wording of player-facing lines is a proposal for Opus and Ryan to adjust, mechanics are the ruling.

## Fix 1: the Q7 spillover ruling (Oct 28) in rollBoonOffer

The ruling: off-patron boon offers stay, but off-patron picks must retain real value; the hidden rarity tax on fillers is the defect.

Current behavior, from the boons chair leg's code read: an offer is built from the patron's useful pool first; off-patron boons backfill only when that pool runs short; and backfill picks roll rarity through rollRarity without the patron argument, so they receive no favour bonus and no tier-3 Rare floor.

The change, in two parts, either of which alone is a partial fix:

1. Competition: off-patron candidates enter the same selection pool as on-patron candidates instead of a backfill tier, so an off-patron pick can appear while on-patron picks remain. The patron weighting that makes on-patron picks more likely is the design's business and stays; what goes is the hard sequencing that guarantees off-patron picks only ever appear as leftovers.
2. Equal rarity treatment: every pick in an offer, on-patron or off, rolls rarity with the same favour inputs. Concretely, the backfill roll gains the patron argument (or the shared favour computation), so the +.12 rare / +.03 epic favour shift and the tier-3 Rare floor apply uniformly.

Acceptance checks: (a) with a seeded RNG and a fixed fixture (a named sector and patron state where the on-patron useful pool is non-empty), confirm off-patron picks can appear across the seed set; (b) sample rarity distributions for on-patron and off-patron picks under favour >= 1 and favour >= 3 and confirm they match; (c) confirm duo offers are unaffected (duos enter separately at m=1 by design). (The seeded-RNG and fixture requirements in (a) were added Oct 29, 2026 on the DeepSeek red-team leg's note; without them the check is nondeterministic.)

## Fix 2: the Q5 loss-debrief weakness reveal (Oct 29) in nemAfterBattle

The ruling: a lost Nemesis meeting still teaches a weakness on the debrief. Ryan's words on the re-roll question ride along: weaknesses are per-Nemesis and per-run, and it does not matter that a successor or a new run does not keep the same ones.

Current behavior, from the firstrun item's code read: nemAfterBattle (campaign_run.js, around :298 at the pin) reveals a weakness by name on the win branch; the loss branch returns only the drove-you-off line and reveals nothing. Weaknesses themselves are created at Nemesis generation (campaign_run.js:249-251): exactly two, drawn from the seven-pool, filtered so none cancels the Nemesis's traits, fixed for that Nemesis's life. In-battle triggering already reveals a weakness even in defeat (established by the blind Rey firstrun leg), so the debrief reveal extends an existing channel rather than inventing one.

The change: on the loss branch, after the drove-you-off line, reveal one unrevealed weakness by name, chosen from the Nemesis's unrevealed set (if both are already revealed, the line instead confirms the file is complete; wording below). The reveal uses the same revealed-set the win branch writes to, so intel state stays single-sourced, and the adaptation naming that currently appears only on the boss-win sector transition is untouched by this fix.

Proposed debrief wording (per-faction idiom is a later text pass; the neutral form): "Your analysts piece together the engagement: [Nemesis name] is vulnerable to [weakness name]." Complete-file variant: "The engagement confirms what your analysts already held: the file on [Nemesis name] is complete." (Wording adjusted Oct 29, 2026 on the DeepSeek red-team leg's note: the earlier "his file" was not neutral.)

Acceptance checks: (a) lose a meeting with both weaknesses unrevealed and confirm exactly one is revealed and named on the debrief; (b) lose with one revealed and confirm the other is named; (c) lose with both revealed and confirm no duplicate or phantom reveal; (d) win a meeting and confirm the win branch behavior is unchanged; (e) confirm a weakness revealed by the loss debrief is respected by the adaptation clash check Ryan ruled the same day (an adaptation may not directly counter a revealed weakness, and a loss-revealed weakness counts as revealed).
