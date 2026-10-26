# Ship customization brainstorm synthesis, 2026-10-26

Chair synthesis of the three blind customization legs Ryan commissioned on Oct 26, 2026, judging BattleTech style swap outs against Voidsworn's current approach. This is future brainstorming, recorded at Ryan's direction. It is not a ruling and not a scope change for the Godot migration, the addendum, or any current job. Where a leg makes a technical claim about the codebase or the migration, it is listed in section 6 as a verify item for Opus, per the decision split.

Legs, all blind, all filed and verified on main:
- Qwen (Qwen3.8-Max, both gates passed, pack pasted in two parts, submitted once). contrib/qwen/reviews/customization_brainstorm_qwen_2026_10_26.md, commit 511bd230. Ran 2:34-2:38 PM PDT.
- DeepSeek (DeepThink and Search verified ON by toggle test, both pack files attached). contrib/deepseek/reviews/customization_brainstorm_deepseek_2026_10_26.md, commit 052ecfae. Ran 2:33-2:39 PM PDT.
- Argon (Gemini 4 Argon, Thinking High, verified in two places, both pack files attached). contrib/gemini/reviews/customization_brainstorm_gemini_2026_10_26.md, commit 2744ad8b. Ran 2:33-2:40 PM PDT.
Screening notes for each leg sit in the goal workspace hidden files.

## Verdict: unanimous architecture, one real split

All three legs, blind, landed on the same architecture: deep layered customization on the flagship only, authored hull variants as the fleet layer, dock refits with a Nemesis clock cost as the pacing wrapper, and a hard rejection of the full open hardpoint lab. The central question Ryan set (does flagship only customization do enough of the mech bay job on its own) got the same answer three times: yes, with one condition, and the condition was the same in substance each time. Line ships must keep selection level variety through authored variants, or the fleet becomes scenery around one tuned ship.

Candidate verdicts across the legs:

- A, authored hull variants: PRIMARY (DeepSeek, Argon), SECONDARY (Qwen). Even Qwen's hybrid lands variants in the background as planned. Chair reads this as consensus PRIMARY in effect: variants are the fleet layer in every hybrid proposed.
- B, dock refits with a Nemesis clock cost: SECONDARY in all three legs, always as the wrapper around flagship work (pod swaps tick the clock), never as a fleet wide refit loop.
- C, flagship only layered customization: PRIMARY in all three legs, unanimously the headline.
- D, section tuning for every ship: the one real split. Qwen SECONDARY as a light layer (two points, dock only), DeepSeek LATER (works better inside C than fleet wide), Argon REJECT as a fleet wide system (fold into C). Chair decision in section 3.
- E, full open hardpoint lab: REJECT in all three legs, in the strongest language each leg used anywhere (Qwen: balance cost fatal; DeepSeek: less legible and less tunable at the same time; Argon: turns distinct warships into interchangeable stat frames). This question is closed.

## The merged hybrid: Flagship Refit Bay plus Authored Variants

The three hybrids (Qwen "Flagship Bay with Fleet Touch", DeepSeek "Flagship Refit Bay plus Authored Variants", Argon "Command Berth and Variant System") agree on most of the spec. The chair merge:

Flagship (one ship per run):
- One swappable weapon pod, chosen from three authored, faction legal pods per flagship hull (Argon's count and faction lock; all three legs agree the pool is faction filtered). The flagship's primary or spinal weapon stays fixed to the hull (Argon), so the silhouette and identity survive customization.
- One module slot, changeable at dock for credits only (Qwen's costing; DeepSeek agrees the module rides with the pod layer).
- Section tuning in four discrete zero sum trims, not point sliders (Argon's form, adopted by the chair over Qwen's and DeepSeek's two point sliders: four named stances are a decision, sliders are a ritual, and the trims cap at roughly plus/minus 15 to 20 percent so the flagship cannot change weight class). Trims change at dock for free or a small fee and never tick the Nemesis clock (DeepSeek and Argon agree tuning is the cheap counter adaptation layer). Faction loss rules sit hard coded above tuning: Deathless trims never grant shields, Chorus trims never grant repair, the Hegemony anchor property is hull fixed and never appears in the customization UI (Argon and DeepSeek, same rule stated twice).

Every other ship:
- Authored variants only. One to two per hull, each swapping one weapon kind with one stat trade, unlocked through faction arcs, simmed as their own hull rows. This is already the project's planned shape (the Job 6 trigger waits on exactly these rows).
- No pod swaps, no section tuning, no hardpoint screens on line ships in the merged spec. See section 3 for the chair's handling of Qwen's dissent.

Where and when: shipyard nodes only, for pod swaps, trim changes, and variant conversions. No mid battle or between battle swapping away from a shipyard. (Argon would also allow module swaps on the campaign map between nodes; the chair keeps the simpler shipyard only rule for a first version and records Argon's version as a relaxation to consider at build time.)

Costs: pod swap, credits plus one Nemesis clock tick (all three legs put a clock cost on the pod swap; it is also the main guardrail in section 4). Module swap, credits only. Trim change, free or small fee, no clock tick. Variant conversion, credits plus the faction arc unlock.

Explicitly not swappable (merged list, no leg disagrees): hull identity and core stats, hardpoint count and class, the flagship's spinal weapon, faction affiliation and faction weapon traits (plasma stays Hegemony, ion stays a lance trait), admiral and Command, the Hegemony anchor property, and captured ships join as is. There is no loose weapon or parts inventory, ever (DeepSeek and Argon, independently).

Prototype scope (DeepSeek's, adopted): one flagship with three pods, two modules, and the four trims; six authored variants across six hulls. That is enough to answer whether the hybrid feels like a mech bay or like a menu.

## Section 3: the one split, decided

Qwen's condition for flagship only doing enough was a light fleet touch: two point section tuning on every ship at dock, so the other nineteen ships do not become scenery. DeepSeek and Argon both answer the same worry with variants instead, and Argon rejects fleet wide tuning outright as pre battle spreadsheet maintenance that optimal play would nag the player through at every shipyard.

Chair: the merged spec follows DeepSeek and Argon. Variants are the fleet layer; there is no fleet wide tuning in a first version. Reasons: variants are already planned content with a trigger waiting on them, they sim as rows, and they give line ships authored identity rather than identical sliders. Qwen's underlying concern is real, though, and it becomes the named fallback: if playtesting a built version shows line ships still feeling like scenery next to the tuned flagship, the light tuning layer (two points, dock only, reversible) is the first addition to trial, in that scoped form, not as a general system.

## Section 4: guardrails, stacked

The legs produced three different guardrails for the Nemesis adaptation interaction, and they stack rather than compete:
1. Adaptation memory window (Qwen): adaptation tracks the most used weapon kind across the last 3 to 5 battles, so a dock swap does not reset it.
2. Fleet wide usage basis (DeepSeek): adaptation keys off fleet wide weapon usage, not the flagship pod alone, so leaning on one pod is not a trap; section tuning (trims) is the player's counter lever.
3. Duel refresh (Argon): the dodge is a paper problem in fleet battles but real in the Nemesis flagship duel, so in challenge duels the Nemesis adapts to the flagship's currently mounted kinds, and the pod swap's clock tick applies regardless.
Per the Job 2 audit, adaptations already counter the most used kind; how the current code counts usage is a verify item for Opus (section 6), and these guardrails are written against the pack's description, not against code.

Capture economy (DeepSeek's catch, Argon converging): custom equipped captured ships never yield flagship grade pods or modules; captures join as intact hull or variant rows or auto-scrap, and ransom and scrap price on the base hull. The chair rejects Argon's one addition here (a flat plus 15 percent scrap bonus for variant hulls): any bonus reopens the farming incentive the rule exists to close. Recorded as a disagreement, not split.

Faction identity (all three): pod pools filtered by faction weapon kinds; modules grant passive or triggered ship effects only, never Commands (DeepSeek's rule). Argon's proposed flagship only Command Module, which modifies the admiral's Command or aura, is recorded as a design proposal for Ryan and Opus, not adopted into the merged spec: it presses directly on the admiral identity rule and deserves its own decision if it is ever pursued.

Qwen's captured tech slot (one cross faction pod opening after a campaign milestone) is likewise recorded, not adopted: it conflicts with the faction lock the other two legs treat as load bearing, and it rests on an UNSURE the leg itself flagged (whether captured weapons already transfer). A Ryan decision if it is ever pursued, not a synthesis call.

## Section 5: what the legs agree the fantasy is

Three blind legs read Voidsworn's fantasy the same way: Rogue Trader's one voidship, not Starsector's fleet fitting. The flagship is already the ship that is present in every battle, carries the admiral, accumulates scars, anchors Hegemony sync, and draws the Nemesis duel. Customization depth belongs where the history accumulates. BattleTech's mech bay works at lance scale (four units, permanent damage, salvage loop); at twenty ships with soft temporary crits, the same depth per hull becomes administration, which is why Starsector needed an autofit system (Argon) and why the open lab fails here even though it is the literal reference.

## Section 6: reserve now items, for Opus to verify

All three legs independently produced a reserve now list for the migration window, and the lists converge. Per the decision split these are verify items for Opus, not rulings; if Opus finds the current code already does one of them, that closes it.

1. Ship instance state separated from static hull rows in saves and battle state (all three legs; Argon most specific: an instance record carrying hull id plus nullable pod override and trim fields, rather than resolving weapons and section values from the hull row during combat).
2. Variant row schema carrying a base hull reference alongside cost and the faction arc unlock field (Argon, DeepSeek), so variants inherit the parent hull's prefab, section hitboxes, and audio. This is the same data the Job 6 trigger already waits on.
3. Flagship mount conventions (all three): a named mount node for the pod slot on flagship hulls only, weapon visuals as separate scenes rather than welded into the hull mesh. Qwen flags UNSURE whether the current pipeline already separates weapon meshes; Opus confirms.
4. A sim hook that resolves a customized flagship (pod, module, trim) into a simmable row (DeepSeek; Argon's version: a sim runner override argument for pod and trim alongside the admiral pick).
5. Faction weapon pool tags as a data convention (DeepSeek), so the pod pool filter exists from day one.
6. How the current Nemesis adaptation counts weapon usage (chair carry over from Qwen's screening): the guardrails in section 4 assume a memory the code may or may not have.

Everything else waits at zero cost per all three legs: the customization UI, pod and trim content and numbers, variant content beyond the schema row, AI responses, and the adaptation logic itself.

## Chair's note

Ryan's lean going in was that flagship only customization might do enough of the job on its own. Three blind legs say he is right, with the variants condition, and variants were already the plan. The brainstorm's real yield is not the architecture, which the project was most of the way to already; it is the guardrail stack in section 4 and the reserve now list in section 6, both of which are cheap now and expensive later. Nothing in this synthesis changes current scope.
