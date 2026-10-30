# Modules and fitting audit - synthesis (Oct 29 program)

Four prongs: Qwen MOSTLY DISTINCT, DeepSeek MOSTLY DISTINCT, Argon STAT CONFETTI, Rey (blind) MOSTLY DISTINCT.

## Verdict: MOSTLY DISTINCT JOBS, NO BUILD LAYER (3 of 4 on grade; substance agreed by all four)

The 13 modules mostly do separable jobs. The system's problem is not the catalog; it is that two structures around the catalog erase the decisions the catalog could support.

## Findings that stand

1. Free, instant, fully reversible fitting collapses modules into a pre-battle checklist (4 of 4; the item's shared blocker). Equip and unequip carry no cost, cooldown, or location restriction, and refitting between battles is always available, so optimal play is to refit the whole fleet before every fight. A module layer that can be perfectly re-aimed at each opponent is not a build system; it is a loadout screen. Argon's remedy is the most concrete candidate on file: keep install free, charge for detach (or restrict fitting to a drydock), and return modules on hull loss. Candidate for Opus to evaluate, not a ruling.

2. Five modules duplicate five captain perks effect-for-effect (Qwen, Rey; chair verified against data.js and the shared effect pool). Gunnery/auspex (+10 aim), killer/cogitator (+10% crit), ironhull/prow (+15% hull; prow adds +5% armor, so near-verbatim), helm/drive (+1 speed), and the deflector/regen pair on shield regeneration. Because every effect source folds through one additive pool, the pairs stack rather than substitute, so the duplication is invisible in play and doubles the same lever. Argon extends the point to a third system: drive, the helm perk, and the compass relic all grant +1 speed, and MODULES.cogitator and RELICS.cogitator collide on the same key in different tables. The standing no-duplication discipline covers doctrines and the skill tree; it does not cover modules, perks, or relics. That is the constitution hole all four legs point at from different angles.

3. Weapon-kind modules can be fitted for zero effect with no warning (Argon, Rey). Only hangar carries an only field in the data; crystal, magazine, capacitor, regen, loaders, and flakplus can be installed on hulls lacking the relevant weapon kind and silently do nothing, unless UI code outside the pack's data slice checks it (Opus check). The hangar only field proves the guard pattern exists; it just was not applied.

4. Strict takes and dominated picks (Qwen, Argon, Rey agree in substance): prow and auspex are strict takes at their prices; damcon at 85 credits is mathematically dominated by prow at 70 (the Rey leg prices damcon needing about four turns to match prow's upfront buffer). DeepSeek's arithmetic frames the whole layer: the hull cost formula puts a cp1 hull at 70 credits, so a top module at 80-90 credits costs more than a frigate.

5. The slot ladder is coarse and the flagship reserve collides with it (all legs in some form). One, two, or three slots across all hulls gives 13 to 286 possible fits with little middle; FIT_SLOTS reserves a flagship module slot that stacks on the normal ladder, and the customization work from Oct 26 leaned flagship-only, so the reserve and the universal ladder cannot both ship as designed without a decision about which layer is real. The trims are the only zero-sum element in the whole customization system (Rey).

## Chair corrections applied

Qwen graded the FIT_SLOTS reserve a NOTE and DeepSeek made the same substance a BLOCKER; the synthesis carries it as a structural decision (finding 5), between the two grades. No factual claims failed verification on this item.

## For Opus (observations, not a gate)

- Apply the hangar-style only guard to every weapon-kind module, in data or UI.
- Decide the duplication constitution: extend the no-duplication rule across modules, perks, and relics, and resolve the cogitator key collision.
- Price pass on damcon vs prow.

## Designer questions

One, for Ryan, in the program report: whether fitting should gain friction (Argon's detach-fee shape, a drydock-only rule, or stay free as an intentional loadout layer). The legs agree the current state is a checklist; whether that is a defect depends on the intended fantasy, which is a direction call, not a technical one.
