# Open checks from the Oct 28-29 programs, resolved by direct code read

Chair pass, Oct 29, 2026, at pin 264f441d (working clone current). Each item was parked in a synthesis as an Opus check; each is answered here from the code itself, with the file and mechanism, so confirmation replaces investigation. Verdicts are observations for Opus to confirm, per the standing role split.

## 1. NOMIDFIRE: no harness sets it (AI item, CLOSED)

Repo-wide search at the pin: NOMIDFIRE appears exactly once in game code, at battle.js:1385, inside the guard that disables mid-move fire when the environment variable is set, and once in the built page (voidsworn-3d.html) carrying the same line. The two Godot oracle copies of battle.js carry the same single reference. No script, harness, test, config, or shell file in the repo assigns it. Argon's sim-divergence half is therefore latent in fact, not only in evidence: the brace bypass at battle.js:1385-1387 stands as a pure code defect, and the fix does not need to preserve a harness behavior nobody uses. If a harness outside the repo sets it, that harness is not in this tree.

## 2. h_board sabotage: implemented, but not as the text promises (boons item, ANSWERED with a twist)

The boon text (data.js:646) promises that "a failed boarding always sabotages a system," and its fx emits only boardPct. Boarding resolution (boardUnit, battle.js:901) has three outcomes. On a capture, no sabotage. On the bridge-holds outcome (target crew reaches zero but the hull cannot be captured), two systemDamage calls fire unconditionally, for any attacker, boon or not. On the partial outcome (the boarding resolves without capture), sabotage is a coin flip: a system is damaged when rnd() < .5 OR the attacker holds any boardPct. So sabotage itself happens on two of the three branches; what the boon adds exists only on the partial branch, where it converts a 50 percent chance into a certainty. On the bridge-holds branch the guarantee is already universal without the boon, and on a capture there is no sabotage for anyone. Verdict: the description overpromises in scope, not in existence. The defect is wording: "a failed boarding" should read as the partial outcome the boon actually governs, or the fx should carry the guarantee into the capture branch. One-line text fix candidate for Opus.

Correction (Oct 29, 2026, after the DeepSeek red-team leg, commit 1da30590): the original filing of this item said the promise "is kept only on the partial-outcome branch," which reads as sabotage occurring only there. That phrasing was wrong, and the paragraph above replaces it: sabotage occurs on the bridge-holds branch unconditionally; the partial branch is only where the boon's own contribution lives. The mechanism analysis and the verdict are unchanged. The same leg correctly noted that several answers in this document rest on full-repo reads beyond the evidence pack's slices (the mount separation in item 4, the install consequence in item 3, the launch count in item 5); those are chair reads at the pin, marked here as beyond-pack rather than pack-proven, and the leg's pack-bound CANNOT DECIDE verdicts on them are a scoping fact, not a refutation.

## 3. Weapon-kind modules: no fit guard exists in the browser layer (modules item, CLOSED)

The MODULES table carries exactly one `only` field (hangar, only:'launch', data.js:165). A search of the browser sources finds no fit-check function at all: no canFit, fitCheck, or install guard exists in the files at the pin. The synthesis left open whether UI code outside the pack's slice checks kind compatibility; at the pin, nothing does. A crystal, magazine, capacitor, regen, loaders, or flakplus module can be installed on a hull with no matching weapon kind and silently does nothing. The hangar `only` proves the pattern; applying it (or an equivalent kind check at install) is the fix shape.

## 4. battery versus hbattery: dominance is table-real, mount-separated (weapons item, CLOSED)

On the table, hbattery strictly dominates battery (shots 5 vs 4, dmg 7 vs 6, crit 6 vs 5, identical range, optimal, accuracy, falloff; data.js:5-6), as DeepSeek said. Mounts separate them in practice: plain battery appears on the penitent cruiser (cp3) and its variants only, while hbattery appears only on the cathedral battleship (cp5) and the ascendant dreadnought (cp8). Weapon cost is not priced per mount; hull cost derives from CP by formula (round((60cp+10)/5)*5) with explicit overrides, so the dominance never arbitrages: no hull offers the player a choice between the two. Verdict: a table-level wart, not an in-game defect. If a future hull ever mounts both, it becomes a real one; a data comment or a checkpack rule (no hull mounts both battery and hbattery) is the cheap guard.

## 5. Hive wing sources: the ceiling is higher than the launch count (squadrons item, ANSWERED)

canStance (battle.js:614) accepts a unit whose ability is launch OR whose folded fx carries hive. The hive fx comes from boons and the hive aspect, and core.js:214 folds fx.hive into a hull's derived hangar even when the base hull has none (hangar becomes fx.hive when the template has no hangar at all). Two consequences the squadrons item asked about: a ship with no launch ability can become a wing source through boon or aspect, so the wing-source count is not capped by the 8 launch hulls; and battle.js:326-327 already treats a hive flagship as a second carrier for enemy-response purposes, so the generation side knows about non-launch sources in at least one place. Whether stance control was intended for boon-granted sources is a design read for Opus; mechanically, they get it today.

## 6. The ceiling fill loop can strand budget (AI item, MEASURED BY READING)

genEnemyFleet's fill loop (battle.js:156) runs while budget >= 1 AND the list is under the ceiling AND a guard counter lasts. Argon's stranding claim was marked INFERRED in its leg; the loop's structure confirms the mechanism: because hull CP costs are integers of 1 or more and the loop exits on the ceiling as well as the budget, any fleet that hits the ceiling with budget left over strands the remainder by construction. The CP sims commissioned alongside this pass measure the magnitude per faction and sector; this item records only that the mechanism is real, not how much it costs.

## 7. The Godot oracle carries the boot grant (drift item, ANSWERED)

unlockAll appears in the Godot tree in exactly one place: godot/campaign/test/oracle/campaign3d.js, the copied browser oracle file. It does not appear in any .gd source at the pin, so the port's own code does not execute the grant; the exposure is precisely the one the drift synthesis named, a parity test comparing against an oracle whose shipped state is fully unlocked. The drift cleanup shape (exclude unlock state from the oracle explicitly) is the right-sized fix, and no wider contamination exists to hunt.

## What this pass did not do

It did not re-run sims (the CP and repair measurements are a separate commissioned pass), did not check Godot-side behavior beyond presence searches, and did not touch any code. Every answer above is a read at the pin; line numbers are the browser sources unless a Godot path is named.
