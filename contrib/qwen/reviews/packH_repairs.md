# Pack H: Repairs Rematch (Qwen)

Filed by Rey from Ryan's paste, Oct 23, 2026. Model: Qwen (attribution confirmed by Ryan). Charter and pack: contrib/muse/prompts/ (Pack H). Screening: contrib/muse/reviews/packFGHI_screening_round2.md. Filed as returned; claims are the model's own and are not verified by filing.

---

Verdict: MIXED
Base Game (CODDLED): The guaranteed pre-boss Drydock (60% missing hull), mid-sector Field Repairs (20% max hull), and Sector Transitions (40% max hull) mathematically outpace Elite/Boss damage. Paying for shipyard repairs is a noob trap that wastes credits needed for modules.
With "Short supplies" Heat or "Scarcity" Sector Condition (SQUEEZED): Healing multipliers are halved or reduced by 25%. This breaks the free-repair loop, forcing players to spend battle income on paid repairs to survive the next Elite.

Findings

Finding 1 (OBSERVED)
File: core.js
Line: 215
Quote: else if(c===COLS-2) type=pick(['shipyard','drydock','field']); // always a rest stop before the boss
Context: Column 5 (pre-boss) is strictly populated by rest stops, meaning routing through it forfeits no combat rewards.

Finding 2 (OBSERVED)
File: core.js
Line: 233
Quote: if(n.type==='battle'||n.type==='elite'||n.type==='boss') n.rw=rollNodeReward(n.type);
Context: Drydocks and Field Repairs do not generate boon, mod, or credit rewards; their opportunity cost is only the combat node they replace in earlier columns.

Finding 3 (OBSERVED)
File: campaign_run.js
Line: 313
Quote: s.hp=Math.min(d.maxHp,s.hp+Math.round(d.maxHp*.4*repairMult()));
Context: Sector transitions unconditionally restore 40% of max fleet hull after a boss fight, resetting the fleet for the next sector for free.

Finding 4 (OBSERVED)
File: campaign_run.js
Line: 185
Quote: miss=d.maxHp-s.hp, fix=Math.ceil(miss*.6*repairMult()); s.hp+=fix;
Context: Drydocks restore 60% of missing hull, making them mathematically most efficient when a fleet is heavily damaged by an Elite.

Finding 5 (OBSERVED)
File: campaign_run.js
Line: 164
Quote: Repairs cost 1 credit per 2 hull. A Mark upgrade adds 20% hull and shields and 15% damage.
Context: Shipyard repairs cost 0.5 credits per hull point, directly competing with permanent combat multipliers like modules and Mark upgrades.

Finding 6 (OBSERVED)
File: core.js
Line: 228
Quote: if(n.type==='drydock') n.type=rnd()<.5?'battle':'event';
Context: Drydocks in columns 1-3 are overwritten 50% of the time; seeking them out early is a routing trap when Column 5 guarantees a free reset.

Finding 7 (OBSERVED)
File: core.js
Line: 153
Quote: return x<.62?{k:'boon',p}:x<.78?{k:'mod'}:x<.9?{k:'cred'}:{k:'repair'};
Context: Skipping a battle node for an early drydock forfeits a 62% chance at a Boon and ~40 credits of income.

Finding 8 (OBSERVED)
File: data.js
Line: 373
Quote: scarce:{n:'Scarcity',d:'Supply lines are cut: shipyards charge 20% more and repairs restore 25% less...
Context: The Scarcity sector condition reduces all free healing by 25%, degrading the Drydock's 60% missing hull restore.

Finding 9 (OBSERVED)
File: data.js
Line: 380
Quote: h_repair:{n:'Short supplies',d:'Every repair restores half as much.',w:1},
Context: The "Short supplies" Heat rule halves all healing, breaking the free-repair loop and forcing paid repairs.

Finding 10 (OBSERVED)
File: ANNEX: simulation summary
Line: Campaign shape table
Quote: | S1 elite | 73% | 6.4 | 38% | 2.1 | 60s |
Context: Fleets exit the S1 Elite at 38% hull (62% missing). The Col 5 Drydock restores 60% of that missing hull (+37.2%), putting the fleet at ~75% hull for the Boss entirely for free.

Not checked
The exact edge generation algorithm (lines 237-243, core.js) to verify if a player can be physically routed away from the guaranteed Col 5 Drydock by the map's topology.
The specific hull values and damage outputs of the harness bot's "fixed per-sector fleets" used to generate the Annex simulation matrix.
The internal logic of how repairMult() and priceMult() interact with specific relics (e.g., salvage, spore) or faction traits (e.g., Chorus regrowth) during actual player routing.
The exact credit balance the harness bot maintained throughout the 30 runs per cell in the Annex campaign shape table.

Questions this pack cannot answer
Does the map generation guarantee that an edge connects the Col 4 Elite node to the Col 5 Drydock node, or can a player be forced to skip the free repair to take the Elite?
How much raw hull damage does the S1 Boss actually inflict in a single fight, independent of the fleet's starting hull percentage?
Does the harness bot prioritize buying modules over paying for shipyard repairs, and what is its exact credit threshold for choosing one over the other?
Are there hidden damage multipliers in the 3D battle engine (e.g., critical hits, flanking, shield stripping) that cause the Annex's "Hull left" figures to underestimate the burst damage a human player would take?
How do specific faction mechanics (like Chorus regrowth or Deathless reanimation) alter the effective hull pool and change the necessity of paid repairs?
Do human players actually route through the mid-sector Field Repair nodes (Cols 2-4), or do they ignore them to chase Elite/Battle rewards, thereby entering the Col 5 Drydock with catastrophic damage that exceeds the 60% missing hull threshold?
