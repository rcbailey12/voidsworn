# Screening: Pack D (economy) and Pack E (onboarding) audits

Chair: Rey. Sources: the two audits pasted by the owner on Oct 23, 2026 (model not stated at paste time; local copies at files/voidsworn-audit/pasted/). Compared against Rey's council and asymmetry work, the DeepSeek and Qwen councils, and the compute pack. Screening only; Opus owns code truth.

## The verdict in one line

Both audits are good. Pack D is the first real economy audit anyone has produced and it lands; Pack E is the most concrete onboarding audit of the four now on file. Two Pack D findings are pack artifacts and should not travel further as game bugs (details below). The rest either converge with earlier work or add genuinely new, checkable claims.

## Convergences (now multiply attested)

- **The Legacy economy is dead UI.** Pack D F1 (no button invokes buyLegacy; the Legacy screen has no Legacy tab) is the third independent route to this: Rey's gamer lens (dead and hidden systems), DeepSeek QA 9 (LEGACY upgrades have no UI route), now Pack D with the mechanism spelled out. Pack D extends it: buyAdmiral is also uninvoked, so admiral unlocks are unpurchasable too, and buyLegacy ignores its own req prerequisites. Treat as settled pending Opus's confirmation.
- **Front-loaded permanent choices before play.** Pack E F1, F3, F5 and F10 converge with all three councils' gamer lenses (Rey G3, DeepSeek G1/G4/G9, Qwen G2/G3), now with screen-level receipts.
- **Patrons unexplained at the moment they matter.** Pack E F7 (route choice shaped by undefined boons) is the onboarding face of the triple-consensus sci-fi finding.
- **Economy starvation.** Pack D F4 quantifies what Rey G8 and Qwen G1/G7 argued: fixed battle pay, repair at half the missing hull, elite payouts roughly equal to the repair bill on the sim's own numbers. Pack D is the first to do the arithmetic against the sim annex, which is exactly what the annex was annexed for.

## Genuinely new claims (single-source, checkable, worth Opus's time)

Pack D:
- **Corsair tow bypasses the CP cap** (F2). campaign_run.js:272 pushes the towed ship with no fleetCP check. If it confirms, it is a live exploit and the strongest single bug in the pack. Nobody else found it.
- **"Crack it open" strictly dominates +45 credits** (F8). Every module costs 55 or more; the alternative pays 45. Clean dominance argument from the pack's own tables.
- **Scarce costs 1.6x per hull repaired** (F9). price 1.2 divided by repair 0.75; the +25% pay does not cover it. A small, exact, decision-relevant number.
- **Decommission ignores damage and Mark** (F10), with the corollary that repairing a ship you plan to sell is pure waste.

Pack E:
- **All admirals unlocked by default** (F4, main3d.js:11). The most consequential claim in either pack: if the boot default really sets every admiral unlocked, the entire renown/admiral progression is decorative. Also the cheapest claim here to settle, one look at the boot path and the default opts.
- **The aspect screen has no Back** (F1) and **the first tip contradicts the auto-selected ship** (F6, campaign3d.js:57 vs ui3d.js:623). Both concrete, both one grep from settlement, both exactly the kind of paper cut a first-time player feels and a veteran dev no longer sees.
- **The revised sequence** is disciplined: existing text only, every structural change flagged UI CHANGE. The strongest moves are reusing the Help paragraphs (campaign_meta.js:143-144 and :160) as a first-run modal and patron explainer, and showing the selected faction's existing blurb on the faction picker (Pack E F3's fix).

## Pack artifacts: discount these two

- **Pack D F3 (runRenown undefined).** True of the pack, which contained only data.js, campaign_meta.js, campaign_run.js and core.js. The function is referenced behind a typeof guard at campaign_meta.js:187; whether it is defined elsewhere in the game cannot be decided from Pack D's contents. As stated it is a question for Opus, not a finding about the game.
- **Pack D F7 (capture has no economy wiring).** Same cause, larger error. DeepSeek's council cites campaign3d.js:81 creating a ship from a captured unit and pushing it into RUN.fleet, and its QA 3 builds the captured-boss finding on that path. campaign3d.js was not in Pack D. Capture is wired; what remains open is whether it is priced (DeepSeek's version suggests it is not, and over-generously so). Do not let F7 reach a verdict in its pasted form.

## What this pair adds up to

The councils mapped the game's structure and fiction; these two packs mapped its money and its first ten minutes, and the maps agree where they overlap. The economy audit's centre of gravity (pay fixed by formula, repairs and losses eating it, high-tier sinks unreachable) and the onboarding audit's (permanent choices before comprehension, systems named before they are defined) are the same complaint from two sides: the game's systems were built in an order the player never experiences. That sentence is the chair's synthesis, not any single model's.

## Recommended routing

1. Opus: tow CP check (Pack D F2), admirals-unlocked default (Pack E F4), aspect Back and first-tip contradiction (Pack E F1/F6), and the runRenown definition (Pack D F3, to close the question).
2. Owner verdicts when ready: the Legacy UI route (now triple-sourced), the Cache dominance and Scarce math (balance calls), and Pack E's revised sequence (the UI CHANGE list is the decision).
3. Filing: the pasted audits are held locally until the owner names the model that produced them, so they land in the right contrib folder.
