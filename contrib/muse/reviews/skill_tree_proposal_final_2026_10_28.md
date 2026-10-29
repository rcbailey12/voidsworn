# Skill tree and admiral leveling: final proposal for Opus (Oct 28, 2026)

Status: chair proposal, validated by three blind legs (Qwen, Argon, DeepSeek; synthesis at contrib/muse/reviews/tree_validation_synthesis_2026_10_28.md). The spine is the designer's ruling (Oct 28, 2026, progression questions Q2 and Q8): progression centers on leveling the admirals, admirals are early style choices rather than a renown unlock ladder, and leveling includes skill choices in a small tree per admiral, light RPG elements in the Hades / BattleTech register, scaling at runs 5, 10, 15, and beyond. Everything below the spine is the chair's validated design, offered for Opus to verify and implement against. Two items remain the designer's to rule on when the redesign is taken as a whole: the Heat payout rule in section 7 (his parked Q3, with the validation's composed answer offered as the candidate) and renown's long-term role (section 8 states the chair's answer with its reasoning).

## 1. What exists today (the backbone)

Mastery as built: each of the 24 admirals (4 per faction, 6 factions) earns XP across runs. A winning run pays roughly 43 XP; thresholds at 6, 16, 30, 50 XP grant four fixed perks in order: alternate starting fleet, wider counsel (4 aspects offered instead of 3), a second Command option, and a veteran flag captain with a boosted flagship. There are no choices anywhere in it. The fiction ruled for this track is lineage: mastery belongs to the admiral's line, not to the captain who dies.

One number the v1 draft never stated and the validation forced: **a lost run pays 10 XP to the flown admiral.** All traces below use it, at the ruled loss rate of about 80 percent, giving a focused admiral an expected 16.6 XP per run (0.2 x 43 + 0.8 x 10).

## 2. The proposal in one paragraph

Keep the four fixed perks as the trunk every admiral shares. Hang a small choice tree on it: three branches per admiral, one pick per tree level, a capstone that evolves the Command. A finished build is three branch picks plus a capstone, which is deliberately sparse: each pick is a commitment the player feels, respec is possible but priced, and depth past the capstone comes from capstone mastery and from the other 23 lines, not from filling a grid.

## 3. Structure (the pick rule, stated once)

- Levels 1 to 4 (XP 6, 16, 30, 50, as built): the trunk perks, unchanged, in the current order.
- Levels 5 to 8 (XP 75, 110, 160, 230): tree levels. **At each of levels 5, 6, and 7 the player makes exactly one pick: choose a branch, then choose one of that branch's two skills at its next untaken tier; the unchosen skill locks (respec, section 6).** Branches advance independently, so a build may go deep in one branch or spread across all three.
- Level 8: the capstone. **Two evolutions of the admiral's Command are hand-authored per admiral; the player chooses one.** 48 authored capstones across the roster.
- The branches: A deepens the Command. B shapes the fleet (formation, doctrine-flavored composition, deployment). C is the flagship and the line (the flagship as an object, inheritance and debrief advantages in the lineage idiom).
- **Primary Command rule:** Branch A and the capstone author against the admiral's primary Command only. The trunk's second Command option remains a trunk benefit; tree skills do not duplicate for it. This keeps authorship bounded and identity sharp (standing rule: an admiral's design matches their special ability).

## 4. Authorship budget (honest numbers, replacing v1's)

Branch A cannot be shared: its skills are written against each admiral's own Command, so all six Branch A slots (3 tiers x 2 choices) are unique per admiral. Branches B and C share where sharing is safe: tier 1 shared within a faction, tier 2 shared within a **Command-family pair** (admirals paired by what their Commands do: volley, summon, control, endure, and so on; the pairing table is an appendix Opus authors once, 12 pairs), tier 3 unique per admiral.

Per admiral unique: Branch A 6 + Branch B tier 3 (2) + Branch C tier 3 (2) + capstone (2) = 12, so **288 unique skills** across 24 admirals. Shared sets: tier 1, 4 skills per faction (B and C, 2 each) x 6 factions = 24; tier 2, 4 skills per pair x 12 pairs = 48; **72 shared-set skills**. Total authored texts: **360**, each a one-to-two-line effect in the faction's learning idiom. This is the real cost and the proposal does not shrink it by sleight of hand.

Phased build order, so the cost is not a wall: Phase 1 is Branch A plus capstones (192 texts) plus the faction tier-1 sets (24), which makes every admiral's identity path playable. Phase 2 adds pair tier-2 sets and the unique tier-3 skills for B and C. If the skeleton must shrink, shrink Phase 2's sharing tiers before touching Branch A or the capstone.

## 5. Skill design rules (restated precisely)

1. A skill must change a decision the player makes in battle, at the map, or at the debrief. A pure numeric effect ships only if it meets a 15 percent floor.
2. At most one in three skills in a tree may be a pure numeric effect; pure numeric effects live only on Branch C, and Rule 1's floor applies to them without exception.
3. Every skill is written in the faction's learning idiom. The tree screen is a lineage document, not a vending machine.
4. No skill may duplicate a LEGACY doctrine item's effect (the 12 items are listed in the appendix so this audit can be run mechanically). Doctrine (renown) is faction-wide and permanent; lineage (XP) is per-admiral and personal.
5. Nothing in a tree may reward losing, dying, or retreating. A skill may convert a catastrophe into continued fighting; it may not pay out because something was lost. Progression pays for fighting.

## 6. Worked example, revised (Kassar, Hegemony: synchronized fire)

Trunk: alternate fleet, wider counsel, second Command, flag captain (as built).
Branch A, Synchrony. Tier 1: Wide Net (synchronized fire radius +1 hex) or Second Volley (the first synced target each round may be fired on by one additional ship out of arc). Tier 2: Shared Solution (synced ships share their best aim modifier) or Cold Drill (sync forms at round start even if the flagship has not moved). Tier 3: Rolling Fire (a kill by a synced ship lets another synced ship fire immediately, once per round) or Iron Tempo (sync survives the flagship's first crippling hit each battle).
Branch B, the Line. Tier 1: Close Order (escorts may deploy in the flagship's forward arc, inside sync radius, instead of the standard line) or Deep Magazine (flagship and escorts start with torpedoes loaded). Tier 2: Cadet Volleys (ships below cruiser class gain the sync aim bonus at half value even unsynced) or Replacement Pool (once per sector, one escort class of the player's choice is offered at the next shipyard at half price, whether or not one was lost). Tier 3: Second Anchor (a cruiser may act as a secondary anchor at half sync values; losing the flagship degrades sync to the anchor instead of collapsing it) or Sealed Orders (at battle start, name one ship class in the fleet; it holds sync at full value outside the radius).
Branch C, the Flagship. Tier 1: Reinforced Bridge (flagship +20 percent hull) or Ceremonial Broadside (the flagship's first volley each battle ignores the target's evasion bonus). Tier 2: Martyr Protocol (when the flagship falls, the fleet keeps sync for 2 rounds; wording guard: the fleet fights on, nothing is gained by the fall itself) or Line Standard (the flagship's presence extends the debrief: one extra named lesson shown). Tier 3: the Admiral's Chair (flagship gains a second ability slot) or the Admiral's Own Hand (once per battle, the flagship may reroll one failed hit).
Capstone (choose one): Living Relay (the flagship projects sync from its position at double radius, and sync no longer requires line of sight to the anchor) or One Voice (once per battle, every synced ship fires at one target simultaneously, resolving as a single combined strike).

Changes from v1, per the validation: Reinforced Bridge now meets the Rule 1 floor; Registry Priority is removed (it spent the core sync track, which is not the lineage tree's to spend); Replacement Pool no longer pays out on a loss; Screen Doctrine's command point discount is replaced by a deployment decision (Close Order); Heir Apparent is removed from the tree (section 7); Ceremonial Broadside no longer depends on an unstated aim base.

## 7. Respec, catch-up, and the relocated heir

- Respec: between runs only, priced per pick at 25 renown for the first respec of a line, +10 renown for each prior respec of that same line. Per-pick pricing keeps early experimentation cheap (Qwen's burden concern) and makes respec a standing late-game sink (Argon's inversion concern).
- Catch-up (shadow XP): admirals of the same faction who did not fly earn 25 percent of the XP the flown admiral earned. The rate is a tuning guess and is flagged as one.
- Heir Apparent, relocated: naming an heir is a lineage-system choice made at the debrief, not a tree skill. A line with a named heir earns shadow XP at double rate while benched. It lives with the catch-up rules because that is the system it modifies.

## 8. Neighboring systems, with honest numbers

- Renown and LEGACY: doctrine stays the faction-wide track bought with renown. Deleting the admiral unlock ladder (designer direction: admirals are style choices, not purchases) leaves **885 total renown sinks (LEGACY 635 + hull variants 250)**, not the 1,815 v1 quoted. At measured earn rates that is roughly a 15-run horizon, after which renown's job changes: it becomes the experimentation currency (respecs, variant purchases for new lines) rather than a progression gate. The chair's position: that is an acceptable endgame role for a secondary currency, provided respec pricing escalates as in section 7; if the designer wants renown to stay a gate past run 15, the honest lever is new doctrine content, not re-inflating prices.
- Heat (candidate answer to the parked Q3, composed from the three validation legs): Heat pays bonus XP. Each Heat point adds +2 XP to the flown admiral's run payout and +1 XP to the faction shadow pool. **Overflow rule:** XP that would exceed the level 8 cap (or a mastery cap, section 9) routes into the line's shadow XP instead, so Heat never pays into a wall. This is offered for the designer's ruling with the redesign as a whole; Q3 was parked as dependent on it.
- The debrief: tree progress is named at the debrief alongside doctrine and Nemesis adaptation (both ruled visible), and a pending level-up choice is the screen's strongest run-again hook.
- Hull variants and story arcs are untouched: variants remain the fleet layer, trees the admiral layer.

## 9. Scaling past the capstone, and the traces

Capstone mastery: XP past 230 buys mastery levels on the chosen evolution at 320, 440, and 600 XP. Each mastery level deepens the evolution (its numeric terms improve, or at mastery 3 it gains a rider the author specifies). A favorite line therefore keeps deepening past run 15, while breadth across 24 lines is the wide game and doctrine is the faction game. The three layers peak at different times on purpose.

Traces at the stated rates (win 43 XP, loss 10 XP, 80 percent loss rate, one focused admiral, before Heat):
- Run 1: level 0 to 1. Correct per the near-impossible ruling: run 1 is the line's first sailing, and its debrief shows the trunk's first step as inheritance.
- Run 5 (about 83 XP): level 5 reached, first tree pick made. The player has a build, not just a roster.
- Run 10 (about 166 XP): level 7, third pick made; a same-faction bench admiral has earned about 40 shadow XP and is mid-trunk.
- Run 14 to 15 (about 230 to 249 XP): capstone chosen; mastery underway. A second line is at its first pick via a mix of flying and shadow XP.

## 10. Known risks

- Content cost: 360 authored skill texts is the largest design lift in the redesign. The phase order in section 4 is the mitigation; shrinking Branch A or the capstone to save cost would spend the identity the trees exist to create.
- Balance surface: 48 capstones that evolve Commands will each need sim attention; the measured bossmatrix admiral band (55 to 85 percent) will widen before it narrows.
- Rule 4 drift: the doctrine-versus-lineage line needs the mechanical audit against the appendix list after the first full tree list exists, not before (there would be nothing to audit).
- Shadow XP flattening: at too high a rate the flown admiral's premium vanishes. 25 percent is a guess wearing a number's clothes; it is the first tuning lever to reach for in playtest.

## Appendix: the 12 LEGACY doctrine items (for the Rule 4 audit)

From data.js at 264f441d (LEGACY, line 239): u_carrier (Carrier hulls in shipyards, 30), u_battleship (Battleship hulls in shipyards, 60), u_dread (one Daybreak-class dreadnought, 120, requires u_battleship), chest1/2/3 (War chest I-III, +75 starting credits each, 20/40/65), cmd1/2 (Command authority I-II, +2 fleet command points each, 35/70), vets (Veteran officers, starting captains at Commander rank with a perk, 50), founder (Founders' salvage, a random piece of salvage at run start, 60), wrights (Master shipwrights, shipyard prices -15 percent, 45), salvagers (Recovery crews, +20 percent credits from battles, 40). Total 635 renown. Tree skills must not duplicate these effects; economy and shipyard-availability effects are doctrine's ground in particular.
