# Squadrons and carriers audit - synthesis (Oct 29 program)

Four prongs: DeepSeek MOSTLY DISTINCT; Qwen split (one response DUPLICATES WITH PAINT, one MOSTLY DISTINCT, both filed, neither selected); Argon DUPLICATES WITH PAINT; Rey (blind) DUPLICATES WITH PAINT.

## Verdict: DUPLICATES WITH PAINT (substance agreed by all four; the split is calibration)

Three of the four reads grade the wing layer as paint over one job; the fourth (Qwen's second response and DeepSeek) grade the same facts milder. No leg disputes the facts below.

## Findings that stand

1. The spore wing is a bomber reskin (4 of 4; chair verified). Spore is typed sq:'bomber' with identical speed and evasion and near-identical hull (26 vs 28). The chair resolved the delivery question from the weapon table: sporeb vs bombs differ by +1 damage, +0.1 vsSq, and -2 crit on the same shots, range, accuracy, and falloff, with the same pierce. There is no different delivery mechanism. Chorus's signature wing does the bomber's job with a Chorus label.

2. The carrier archetype is one carrier plus generic fill (4 of 4). The generator seeds a single carrier hull, then fills the remaining budget with the same weighted draw every archetype uses. No escort, screen, or formation shaping exists, and the Rey leg adds that the carrier branch is skipped entirely for boss fights, so the biggest carrier fights are gun lines with wings attached.

3. The torpedo screen's real math is now settled (Rey, from code; supersedes inference). One roll per wing per salvo at .45 (.65 with pickets), the wing stops after its first live torpedo, so stacking compounds geometrically across wings but each wing caps at one kill per salvo. The stance text never states the cap. Qwen's earlier estimate of about 83% cumulative for three wings was INFERRED; the mechanism above is the code truth, and whether the resulting numbers feel right is a tuning question the mechanism now makes askable.

4. Wing veterancy cannot be steered (Rey; Qwen and DeepSeek flagged the ladder as unjudgeable). Perks on the 3/8/15 XP ladder are random grants, so a player can feed a wing XP but cannot choose what it becomes; the pickets perk reads as dead weight. Enemy wings cannot reach the ladder at all by construction (Argon).

5. Launch occupies the carrier's only ability slot while doing nothing until a wing dies (Argon, Rey). The screen tether (WING_SCREEN_R=2) sits awkwardly against mostly speed-2 carriers.

6. Worst-carrier is two different cuts, both true (chair): the reliquary is the worst DEDICATED carrier (cp4, hangar 2, hp 130 against the Chorus hulk's cp4, hangar 2, hp 170; Qwen), and h_dominion is the worst on hangars per CP (1 hangar at cp6; DeepSeek, Rey). The best value is b_brood (3 hangars at cp5; DeepSeek, Rey).

7. The carrier preview mismatch survives in narrowed form (chair, from the Argon screening): effArch at battle.js:138 remaps a carrier roll to heavy for launch-less factions before generation, so no wingless carrier fleet is fielded; what remains wrong is the preview layer still advising anti-wing preparation against fleets that will not have wings. Argon's scarier branch (a heavy fleet built from the carrier filter) does not trigger at current data.

## Chair corrections applied

Argon's BLOCKER 1 mechanism (the generator fielding a carrier-archetype fleet with no launch hull) is wrong; the remap precedes it in code its pack slice did not include (chair pack-scoping miss, owned). Its WING_XP finding contains a garbled pseudo-quote, preserved verbatim in the filed leg and not relied on. Qwen's hive note (canStance accepting fx.hive units) remains an open Opus check: whether the wing-source ceiling exceeds the 8 launch hulls.

## For Opus (observations, not a gate)

- Give sporeb a different delivery (a lingering cloud, a hull-attached growth, anything the bomber does not do) or accept the reskin knowingly.
- State the screen's one-kill cap in the stance text.
- Fix the carrier preview to name the remapped archetype.
- One-read check: canStance and fx.hive wing sources.

## Designer questions

One, in the faction shape synthesis where it belongs: how CP should price launch capacity across factions. No separate question here.
