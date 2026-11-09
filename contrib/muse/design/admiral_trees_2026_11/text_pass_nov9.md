# Tree text pass, Nov 9 2026 (issue #311)

Every change this pass makes to the finalized faction files, old text and new text, with the effect key or hook each rewrite rides on. Ruled by FINDINGS R145: every pick changes a battle, rewrites use the plan's existing effect keys (tree_effects_plan.md section 1) or listed hooks (section 3), no new mechanics. Chaired by Rey from five legs: blind Rey, DeepSeek and Qwen (writers), Flash and Grok (ideation).

This file grows faction by faction. The Glasswrights pilot is first because board job #312 waits on its 12 Glasswright rewrites.

## Glasswrights (pilot, delivered first)

### Rewrites: rows that did nothing (bucket x) or needed a new mechanic (bucket c)

**Tamsa T1a, Flight Paths in the Glass** (x)
Old: record each extra wing strike path before launching; a wing that follows its recorded path exactly strikes at +15% damage
New: an extra wing that strikes the target its carrier last fired at gains +15% damage
Rides on: dmgPct / sqPct room; the carrier's last-fired target is the tracked condition (the plan's own suggested rewrite; all five legs converged on it).

**Tamsa T2a, The Replay Corrects** (x)
Old: after the first strike resolves, each extra wing may be retargeted freely for its strike again, using what the glass recorded
New: an extra wing's strike again against a target already hit this round gains +10% damage
Rides on: H2 hits-per-target counter, sqPct room. (DeepSeek and Qwen form; the blind leg's +10 aim variant lost to damage on a known target, which is what a replay corrects.)

**Tamsa T2b, Starlings in Formation** (x)
Old: extra wings that strike in the same order as their carriers are arranged gain +10 aim
New: extra wings that strike the same target as another extra wing gain +10 aim
Rides on: aim key; convergence condition from wing orders. (DeepSeek form; Flash and Qwen's within-3-hexes-of-carrier variant dropped, formation is about the target, not the carrier.)

**Tamsa Cap1, Flight Cast Perfectly** (c, C1)
Old: during Starling flight, all wings striking the same target combine their attacks into a single simultaneous strike that ignores point defence and deals +25% damage to the target's most damaged section
New: during Starling flight, wings striking the same target ignore its flak, its shields stop only the first wing hit, and wing hits after the first deal +25% damage to its most damaged section
Rides on: H2 counter; the plan section 4 drop-to-b rewrite for C1 (shields stop only the first hit) carrying the original's flak ignore and +25% to the most damaged section. No summed-hit mechanic.

**Tamsa Cap2, The Forge Casts Ahead** (x to b)
Old: after the Command, one extra wing per carrier stays aloft and repeats its recorded strike at the start of next round
New: after the Command, one extra wing per carrier strikes the same target again at the start of next round, at +15% damage
Rides on: H3 next round plus H6 wing tag; the recorded target is the only new part (wings already stay and strike every round), priced at +15%.

**Saro T1b, One Lens, One Target** (x; the plan left the reading to Muse)
Old: a ship may fire its volley as a single shot at +25% damage instead of firing every gun
New: choose one of your ships: it fires its whole volley at a single target you name, and its shots gain +25% damage against that target
Rides on: H1 choice, H5 Command targeting, dmgPct room. The one-gun reading is a strict downgrade and the merged-hit reading is C1; concentration plus the draft's +25% is the honest middle. (Blind Rey form; DeepSeek's concentration variant agreed at +15%.)

**Saro T2a, Light Arrives Together** (x)
Old: you may hold the volley until all your ships have moved, and fire lance shots in any order you choose
New: during the volley, a shot at a target already hit by one of your other ships this round gains +15% damage
Rides on: H2 hits-per-target counter, dmgPct room. (Blind Rey form. Three legs priced the already-free timing instead, which is plan pattern 1; Qwen's ships-that-did-not-move variant was the strongest alternative.)

**Saro Cap1, Sun Through One Lens** (c, C1)
Old: Burning glass may concentrate every ship's volley on one target, resolving as a single combined strike that ignores range penalties
New: Burning glass may concentrate every ship's volley on one target; its shields stop only the first hit, and no shot suffers range falloff
Rides on: H1 choice, H2 counter; the plan section 4 C1 rewrite, keeping the original's no-falloff term. (Qwen form; DeepSeek's agreed with a +10% on later hits added, dropped to keep the capstone at its promised terms.)

**Vell T2a, The Mirror Steps Aside** (x to b)
Old: during the scatter, a ship may pass through one enemy-held hex without stopping
New: during the scatter, a ship may dive under one enemy-held hex at no extra cost
Rides on: H11; waives the existing +1 movement surcharge once. All five legs agreed.

**Vell T2b, Light Split Three Ways** (x to b)
Old: during the scatter, a ship may split its movement, half before it fires and half after
New: during the scatter, a ship may move its full remaining movement after it fires
Rides on: H11; raises the faction's built-in half to full for the scatter. All five legs agreed.

**Vell Cap1, The Fleet Is Elsewhere** (c, C2)
Old: Scatter the light may be declared after the first enemy ship fires; your ships move immediately, interrupting the enemy turn
New: the first time an enemy fires at your fleet this battle, every ship gains +2 movement and may turn once for free
Rides on: H2 first-fire trigger, speed key, H11 free facing; the plan section 4 automatic form of C2, keeping the original's movement payoff (+2 is the surge Command's own low tier). (Qwen form; Grok's agreed, DeepSeek's evasion-only variant dropped the movement the skill is named for.)

**Brin T1a, Light Bent to the Weak Side** (x)
Old: you may give one ship's shield refill to the friendly ship with the lowest shields instead
New: during the ward, the friendly ship with the lowest shields takes 20% less hull damage until the start of next round
Rides on: H8 hull cut family, treeHullCut room. (Blind Rey form; Flash's lowest-hull variant agreed on the mechanism. Overcharge and temporary-hull variants lost: both duplicate the sibling picks T1b and Cap2.)

**Brin T1b, Prisms Face the Fire** (x to b)
Old: a ship facing its nearest enemy refills +25% more shield during the ward
New: a ship facing its nearest enemy gains shields above its maximum equal to 25% of its maximum shields during the ward
Rides on: H7 overcharge, treeShOver cap (.25). All five legs agreed on the mechanism; the new text states what the 25% is of.

**Brin T2b, The Lens Rotates** (x)
Old: during the ward, a ship may change its facing after moving without losing the damage reduction
New: during the ward, a ship that changes its facing gains +10 evasion until its next turn
Rides on: ev key through evBuff, whose own duration is until the ship's next turn. Four legs converged on this form.

**Brin Cap2, Every Facet Lit** (x to b)
Old: during the ward, shield strength refilled beyond a ship's maximum becomes temporary hull of hard light, up to +20%
New: during the ward, each warded ship gains temporary hull equal to 20% of its maximum shields
Rides on: H10 temporary hull, treeTempHp cap (.2). All five legs agreed, near-verbatim.

### Wording fixes on rows that already work

**Tamsa T3a, Flaw in the Flight Removed**: "point defence" becomes "flak", the game's one term. New: extra wings ignore the flak of one chosen enemy ship for this Command.
**Saro T1a, Focus Drawn Long**: "the firing ship's range" becomes "the weapon's range". New: volley shots at targets beyond half the weapon's range gain +20% damage.
**Vell T3a, Refraction Deepens**: "moves its full distance" becomes "spends all its movement".
**Brin T3a, Flaw in the Glass Corrected**: shields are four facings. New: while the ward is active, the first ship that has a shield facing emptied refills that facing to 15%, once per battle.
**Brin T3b, Hard Light**: names the facing. New: during the ward, a ship with shield left on the struck facing takes no section damage from its first hit.

### Chair notes

- The pack header and the blind leg first scoped this pass as 12 x rows and 1 c row. The sort table and the plan's counts say 3 c rows (Tamsa Cap1, Saro Cap1, Vell Cap1). DeepSeek and Grok caught it; the pass covers all 15 rows. No row was left unrewritten.
- One leg proposed respelling "defence" to match data.js instead of using "flak". Rejected: the plan rules one term, the flak gauntlet.
- The five stale data.js Glasswrights texts (Tamsa T3b and Cap1, Saro T3b, Vell Cap2, Brin Cap1) are unchanged by this pass; copying the final texts into data.js is the pilot build job's data step (#312), as is wiring these rewrites into TREE_FX.

## Later parts (not in this delivery)

The other five factions' rewrites and wording fixes, the eclipse.md shield corrections, the Grax boarding skills and the Dace Vorn Command rename from the issue's done-when list, and the 144 capstone mastery texts, follow in the same file order the issue sets: Glasswrights first (this delivery), then the other five factions, then the mastery texts.
