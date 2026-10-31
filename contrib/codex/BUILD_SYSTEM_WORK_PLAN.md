# Build-system work Codex can take off Opus

Prepared October 31, 2026 against main `355a2ac7` and the reconciled draft PR #1. This began as a proposed work order. The initial executable packet is now in `build_system/README.md`; its evidence and explicit limits control implementation status. It creates no new owner rulings. The five games in Ryan's linked CBR article were verified from its HTML: Wasteland 3, Baldur's Gate 3, Battle Brothers, Warhammer 40,000: Rogue Trader, and Tactics Ogre: Reborn.

Recommendation: finish the existing build design as a testable subsystem, beginning with the tree contract and progression calculator. Preserve the ruled admiral/lineage structure and existing 360 authored skill texts. Any replacement text must identify the original slot, defect, reason and proposed replacement. Do not commission another general review round or add a new progression currency.

## 1. Tree audit and implementation contract

Status: source-preserving catalog and targeted audit completed. Two pilot effects have operational contracts; 358 other effects remain explicit source contracts with unresolved implementation terms. Inputs: Muse's final tree proposal and Phase 1 / tier-2 / tier-3 assemblies. Those assemblies total 216 + 48 + 96 authored entries. The primary Command, faction tier-1 sharing, Command-family tier-2 sharing, admiral-specific tier-3 skills, and two capstone options must remain traceable.

Codex deliverables:
- Structured skill data with stable ids and original source anchors; a round-trip check that no authored slot vanished or was duplicated.
- For each effect: eligible actor/target, trigger, resolution timing, duration, limit, stacking rule, cleanup, player input and required engine hook. Mark unspecified terms as unresolved rather than inventing a ruling.
- A bounded issue ledger for redundant choices, numeric bonuses presented as new decisions, doctrine/module/perk/relic overlap, unreachable prerequisites, unsuitable hulls and extra-action/refund cycles. Distinguish proven contradictions from balance hypotheses.
- Small proposed corrections attached to individual slots, rather than an independent rewrite of every tree.

Opus verifies: source-slot coverage, the short list of actual changes, and a validator run. Static validation does not prove combat balance.

## 2. Progression calculator and legal-build validator

Status: calculator, legal-build validator, JS/Godot state model and regression fixtures implemented. First concrete planning issue: `skill_tree_proposal_final_2026_10_28.md:9,66-70` derives its run-5/10/15 examples from win XP 43, loss XP 10 and a fixed 80% loss assumption. Model that scenario alongside other outcome/depth profiles; bot win rates are not human loss probabilities. Verify actual reward code before treating 10 XP as a universal implemented loss payout.

Codex deliverables:
- Deterministic traces for trunk unlocks, three branch picks, capstone, capstone mastery, Heat, shadow XP, overflow and respec accounting.
- Enumeration of legal completed builds under the existing pick rules; reject skipped branch tiers, both sides of an exclusive pair, extra picks and invalid capstones.
- Tests for cap boundaries, repeated load/save, canceled choices and respec/refund rules. Keep unresolved rounding and refund policy explicit.
- A compact table showing when the first meaningful choice arrives and when a favorite line reaches its capstone under each stated scenario. No new campaign simulations required.

Opus verifies: formulas, assumptions, boundary fixtures and expected output. Revisit thresholds only if the results conflict with the owner's intended cadence.

## 3. One-admiral working implementation

Status: bounded Saro prototype prepared and tested. Two alternative A1 effects, browser picker/Command dialogs, native reward/save/snapshot adapters and matching Godot logic are implemented as candidates. Native Godot dialogs and the other 358 effects are not implemented. See `build_system/README.md` before adoption.

Codex deliverables: isolated browser and Godot proposed patches for choice eligibility, persistence, respec and a bounded selection of verified effects; before/after state fixtures; explicit oracle changes where behavior changes; a small adoption diff. First demonstrate two genuinely different builds for the same admiral. Do not claim that a selectable tree UI means every effect is implemented.

Opus verifies: one representative state transition, effect fixtures and cross-engine parity before extending the pattern.

## 4. Fleet recipes and combination checks

Status: proposed, can follow packet 1. Use Wasteland 3's complementary squad roles, BG3's class combinations and Battle Brothers' equipment/perk specialization as references.

Codex deliverables: two contrasting build recipes for one pilot faction, using real hull/module/perk/relic ids; role coverage, enabling choices, tactical sequence, costs and weaknesses; small interaction fixtures for the riskiest combinations. Review useful specialization and valid alternative builds, rather than promising an automatic universal dominance detector.

Opus verifies: ids resolve, prerequisites can be obtained, the examples produce the described behavior, and the tradeoffs are honest. Expand to the other factions after the pilot works.

## 5. Build UI and graphics packet

Status: a functional offline Saro workbench is prepared, with code-level control tests. Rendered browser verification was blocked; the full 24-admiral graphics packet remains planned. Tactics Ogre's constrained equipped skills are a useful reference for presenting a few meaningful choices clearly; Rogue Trader's specialization tiers are a reference for communicating future paths.

Codex deliverables: rendered tree, comparison and build-summary mockups; locked/available/chosen/excluded/implemented-state treatments; editable vector assets and consistent export names; actual long-text and dense-layout examples using Voidsworn's existing faction palette and crests. Show unlock cost, benefit, prerequisite, affected ship/weapon and what is given up. Reuse existing preserved artwork before creating another competing asset set.

Opus verifies: screenshots and asset manifest, with visual assets separated from gameplay behavior. This packet can make the tree easier to understand before its full rollout.

## Small coding jobs Codex can also own

The module kind-fit guard (MOD-3) is now a separately verified browser/Godot candidate in `build_system/candidates/module_fit/`. Loss-debrief reveal/adaptation clash fixes and boon backfill corrections remain bounded follow-up jobs. Each can be delivered separately as browser/Godot candidates with fixtures and expected assertion changes. They do not require a new balance or art direction decision. Keep fitting friction, migration intent and broader economy changes outside those bug fixes unless a ruling settles them.

## Delivery format for every packet

One-page adoption note, exact source pin, small diff plus proposed full files where required, a double-click Windows check launcher, expected results, and explicit implemented/proposed/unresolved labels. Visual packets include rendered examples and editable source. Opus should verify a concrete result rather than reconstruct the conversation.

## Sources and interpretation

The recommendations above are Codex's adaptations, not claims made by the article or the cited developers. The article is a lead list; primary sources establish the mechanics used here.

- [Ryan's CBR article](https://www.cbr.com/turn-based-rpgs-perfect-character-builds/), retrieved as HTML after search retrieval failed. No full article text is reproduced.
- [Wasteland 3, inXile](https://inxile-entertainment.com/games/wasteland-3): squad customization through skills, perks and quirks.
- [BG3 Community Update 21, Larian](https://forums.larian.com/ubbthreads.php?Number=860776&ubb=showflat): multiclassing and class hybrids.
- [Battle Brothers features, Overhype](https://battlebrothersgame.com/features/): development through equipment and perks without a restrictive class system.
- [Rogue Trader archetypes, Owlcat](https://roguetrader.owlcat.games/news/en/40): first- and second-tier specializations.
- [Tactics Ogre: Reborn, Square Enix](https://www.square-enix-games.com/en_US/games/tactics-ogre-reborn): combinations of classes, equipment, skills and magic. [Official preview](https://www.square-enix-games.com/pt_BR/news/tactics-ogre-reborn-preview) describes the equipped-skill limit.

## Not checked

The current packet includes a complete source-slot catalog, a targeted audit, calculator/state model, module-fit candidate, two-effect Saro prototype and proposed Chorus copy edits. It is not a 360-effect implementation, a balance verdict, a whole-port clearance or a rendered visual sign-off. See `build_system/evidence/verification_summary.json` and `reviews/build_system_audit_2026_10_31.md`. Fleet recipes and the full graphics rollout remain planned.
