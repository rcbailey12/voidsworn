# Screening, round 2: the second model's Pack D and Pack E audits

Chair: Rey. Sources: the pair pasted by the owner on Oct 23, 2026 (attribution unconfirmed, presumed Qwen; local copy at files/voidsworn-audit/pasted/round2_packD_packE_audits.md), screened against the repo, the DeepSeek Pack D/E audits, and the councils. Two claims in this pair were settled outright by the chair against the code; they are marked below. The rest is alignment and judgment, with final rulings for Opus.

## The headline: same pack, opposite discipline

Both models received identical packs. On the pack's biggest trap, they behaved oppositely. DeepSeek flagged runRenown as missing from the pack and declined to conclude. This model published it as finding 1, OBSERVED, headline: the meta-progression economy is "completely broken", players earn "exactly 0 Renown per run".

**That claim is false.** runRenown is defined at campaign3d.js:30: battles x2, elites x4, bosses x15, kills/4, plus 5 per sector past the first. campaign3d.js was not in Pack D, which is precisely why the protocol says a pack absence is a question, not a finding. The same error repeats at economy finding 6: Heat is called unwired, but battle.js (also not in the pack) applies it, e.g. battle.js:139 scales the enemy budget when h_hunted is on. Two headline-grade claims, both artifacts of the pack boundary, both stated flatly. This pair is the strongest evidence yet for the screening pipeline: the failure was not intelligence, it was one model treating the edge of its input as the edge of the world.

## Where this pair is strong

- **Onboarding convergence.** Its onboarding audit independently lands on blind permanent choices, the Help text wall, abstract patrons and gated Command explanation, and adds three finds nobody else made: Retreat and its 10% hull penalty are invisible until a player is already losing; objective rules hide behind tapping a map chip; and arcs are taught as 2D colours in a 3D game where the ship's facing is the actual mechanic. The onboarding core now has four independent audits behind it (both councils' gamer lenses plus both Pack E runs).
- **Mercenary arbitrage** (economy F10): 80 credits for a 130-credit Harrow plus a veteran captain. New, concrete, checkable.
- **Module stripping over scrapping** (F8) converges with DeepSeek's cache-dominance logic from a different door: modules are worth more than credits throughout this economy.
- **Shipwrights over War Chests** (F2) is sound arithmetic, with one cross-audit caveat: DeepSeek's Pack D established that the Legacy purchase UI is dead, so F2 is currently a comparison between two unpurchasable items. Both findings can be true; only one is operational.

## Where it overreaches, beyond the two settled claims

- **Economy F4's "net credit profit" is wrong as stated.** Selling a 1-HP Penitent returns 70 and repairing it costs 60, but replacing it costs 200. The sale is only a profit if the fleet shrinks; as a repair alternative it loses 130 against repairing. The underlying threshold observation is real; the headline verb is not.
- **Economy F7's Salvage Rig estimate** (about 450 credits over a run) assumes heavy repairable damage after every battle and prices the 8% at shipyard rates. Direction fine, number optimistic.
- **Economy F3 ("never pay for repairs is mathematically optimal")** rests on drydock and field-repair frequency from the sim annex (about two free-repair nodes per sector). It ignores route opportunity cost: a drydock node is a node not spent on rewards, and the map does not guarantee reachability when the damage happens. Plausible strategy, overstated proof.

## The one real contest: what is wrong with repairs?

DeepSeek's economy audit: elite pay roughly equals the repair bill, so the player is squeezed. This audit: free repairs are so abundant that paying is a trap, so the player is coddled. Both agree on the load-bearing fact, that **paid shipyard repairs are a bad deal**, and disagree on the player's resulting position. The difference is route modelling, which neither audit could do from the pack (the map and route code were not in it). This is now the sharpest open question in the economy file, and it is decidable: the campaign sim's own route data, or one instrumented human run, settles whether free repairs are reliably reachable. Routed to Opus and the owner as the economy question, ahead of any repair-price change.

Related contest: sector 3 pressure. This audit (F5) says income outruns sinks and pressure drops, citing the sim's S3 boss line (100% win, 64% hull left). DeepSeek said pressure rises through losses. The chair notes the S3 boss figure comes from a scripted-fleet harness mode and was flagged as an artifact in the sim matrix work; treat F5's evidence as weak until a campaign-mode number exists.

## Charter discipline

The onboarding charter required a revised sequence using only existing text, screens and systems, with new UI flagged. DeepSeek's revision complied strictly (existing text, every change flagged). This revision's centrepiece, a forced prologue skirmish before faction select, is a new flow assembled from existing systems; it flags its smaller changes (showcase hover, tooltips, toast text) but not the prologue itself. The prologue may well be the better design (learning by doing beats modal text), but it is a bigger build than the charter priced, and it should be judged as a proposal for new work, not as a rearrangement.

## Updated routing

1. Closed by screening: renown accrues (campaign3d.js:30 formula above); Heat is wired in battle.js. Neither claim should reach a verdict queue.
2. Opus: the repairs contest (route reachability of free repairs in campaign sims), the mercenary price (80 vs 130 plus captain), and the F4 threshold restated correctly (sell-vs-repair when replacement is not intended).
3. Owner: the prologue skirmish proposal, judged as new build work; the Retreat-visibility find, which is cheap to fix and embarrassing to leave.
