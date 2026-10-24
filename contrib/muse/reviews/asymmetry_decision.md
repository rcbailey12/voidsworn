# Faction asymmetry: the decision page (three audits merged)

Type: synthesis and shortlist for the owner's verdict (Rey, external POV). Sources: Rey's audit (contrib/muse/reviews/faction_asymmetry.md), DeepSeek's audit (extracted at contrib/deepseek/reviews/faction_asymmetry.md from the raw transcript), Qwen's audit (contrib/qwen/faction_asymmetry_audit.txt). All three ran blind from the same pack at HEAD 51337c2. Claims are unverified; Opus owns code truth. This page exists so the owner reads one document instead of three.

## Where all three agree (treat as settled)

1. The sameness is real and measured, not a feeling. All three independently produced the same headline evidence: frigates at 70 and destroyers at 130 in every faction, admirals at 0/30/45/80 drawing on a shared command pool, one squadron system, weapon and class stat bands that overlap almost completely, and no faction economy anywhere.
2. The six identities. Despite writing blind, the three audits converged on the same six playstyles, faction by faction (details below). When three unrelated model families assign the same identity to every faction, the identities are probably just what the data already wants to be.
3. Prohibitions create identity cheapest. DeepSeek derived each faction's prohibition from what its roster already lacks, Qwen proposed enforcing prohibitions through existing boolean checks, and Rey proposed them as law. Same conclusion from three directions.
4. The proof is distributions, not win rates. All three said some version of: if the factions still fight at the same ranges, with the same hull counts and the same damage mix, they are still costumes, whatever the text claims.

## The six identities, merged

**Voidsworn: the armored broadside line.** Consensus: slow, facing-dependent, wins a sustained line fight, loses when flanked or forced to chase. Rey adds broadside arc asymmetry as the faction rule (its P/S batteries are already its identity). Qwen's cheap trick: lock the faction to its Anchored Volley (stillPct) trait and strip slip/blink from its drive rules. Profile contested: DeepSeek says elite, Qwen standard, Rey fortress-standard. Recommendation: standard count, elite durability; the line is the plan, frigates are escorts.

**Hegemony: the standard, and the shield-stripper.** Consensus: the control group, long-range ion fire, fighter screens, no gimmick and proud of it. DeepSeek notes its prohibition already exists in fact (no torpedo weapon in any Hegemony roster). Qwen adds the sharpest version of its win condition: strip shields, let bombers execute, and pay for it with constant wing replacement. Recommendation: change Hegemony least, as all three said.

**Corsairs: close-range raiders paid in salvage.** Consensus: shortest range band, speed, boarding and capture, wins inside the enemy's range and loses when kited. DeepSeek and Qwen both call it a swarm of cheap hulls; Rey had it as mid-count raiders. Recommendation: take the swarm version, it differentiates harder against Voidsworn's line. Economy: all three independently gave Corsairs a capture/salvage income loop (Qwen's version is the most complete: captures grant credits and repairs, nothing else does).

**Chorus: the swarm that eats.** The strongest consensus of the three audits: massive cheap bodies, zero shields, regeneration, wins by attrition, loses to burst. Two standout concepts: the brood-mother as a true mid-battle spawner (Rey and DeepSeek both), and Qwen's feed mechanic (no shipyard repair at all; nearby kills restore hull, repurposing the existing avenge logic), which gives Chorus an economy no other faction shares and a reason to stay in the fight. Recommendation: adopt both; Chorus becomes the reference swarm.

**Ithar: the elite glass skirmishers.** Consensus: fewest and most expensive hulls, strongest shields over the frailest hulls, blink, long-range lances, wins by alpha and fade, loses the moment it is caught in a brawl. Shield recharge is the contested mechanic: Rey and Qwen both proposed it (Qwen: faster recharge, hull repairs 50% dearer), DeepSeek thinks shield cycling with existing surge is enough. Qwen's prohibition is the cheapest identity move in any of the three audits: Ithar cannot Brace, enforced by one check in the order code. Recommendation: adopt the no-Brace prohibition now; let the sim judge whether recharge is also needed.

**Deathless: the attrition engine.** Consensus: zero shields, highest armor, phase movement, wrecks as a resource, wins long battles, loses to decisive alpha. One factual contest for Opus: DeepSeek reports a reanimate rule already exists on Deathless hulls (reanimate:true, with a check in the battle code), while Rey's audit treated a return-from-wreck rule as an engine ask. If DeepSeek is right, Deathless's signature is already built and merely quiet. Qwen adds the flavourful cheap bits: no crew (boarding immunity) and acid as its specific counter. Recommendation: Opus confirms what reanimate currently does before anyone designs around it.

## The three changes to make first (merged list)

1. **Break the shared price ladder and gate the rosters** (all three audits, first or near-first). Frigates stop costing 70 everywhere; Chorus and Corsair hulls get cheaper and more numerous, Ithar and Voidsworn dearer, and each faction loses access to something (classes, weapons, or systems) per its prohibition. Data-only, one pass, immediately visible in every fleet-building decision.
2. **Enforce the hard prohibitions** (Qwen's framing, DeepSeek's evidence). Most already exist as facts of the rosters; making them rules costs a handful of boolean checks: Ithar cannot Brace, Hegemony cannot board, Chorus cannot fit shield modules or repair at shipyards, Deathless cannot launch squadrons or be boarded.
3. **Add the per-faction economy hook** (DeepSeek flags this as the one true ENGINE CHANGE). A small faction modifier table read by shipyard, repair and reward code. The Corsair capture loop and Chorus feed loop are special cases of it. Without it, every economy proposal in all three audits stays fiction.

## How to prove it worked (merged test)

Run the harness on fixed seeds and budgets and compare distributions per faction, using telemetry the game already records (DeepSeek's list): engagement-range histogram, hulls and squadron share per battle, damage absorbed by shields vs armor vs regeneration, command and ability timing, the economy ledger (credits gained, repair spend, hull losses), and win/loss causes. Qwen's three clusters are the quick version: range at time of death, shield-vs-hull damage ratio, resource delta per battle. Acceptance criterion, in DeepSeek's words: "pairwise metric vectors diverge beyond noise while mirror win rates remain roughly balanced. If a faction only wins more but uses the same range, same command timing, and same hull-count curve, it is still a costume."

## What each auditor uniquely brought

- DeepSeek: the discovery that range identities already exist, but only inside the enemy AI's doctrine table, never in player rules; and that boss scaling is the one faction-specific table in the game, also enemy-side only.
- Qwen: the implementation tricks. One-line boolean gates for prohibitions, the avenge relic repurposed as Chorus's feed mechanic, crew removal as Deathless's boarding immunity.
- Rey: the variant-hull census (12 of 45 hulls are same-stat weapon swaps) and the observation that the presentation layer (MOVE_FEEL) is already more asymmetric than the rules layer.

## Decisions for the owner

1. Adopt the six identities above as the design direction? (Yes unlocks everything below.)
2. Approve the merged first-three order: price ladder and roster gates, prohibitions, economy hook?
3. Ithar shield recharge: new rule now, or sim first with no-Brace alone?
4. Chorus feed mechanic (no shipyard repair, kills heal): in or out?
5. Deathless reanimate: Opus to report what the existing rule actually does before any design builds on it? (Recommended yes; it is a factual question with a definite answer in the code.)
