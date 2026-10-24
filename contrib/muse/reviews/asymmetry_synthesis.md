# Asymmetry decision briefs: synthesis (chair)

Legs: contrib/qwen/reviews/asymmetry_briefs_qwen38max_draft.md and
contrib/deepseek/reviews/asymmetry_briefs_deepseek_draft.md. Both legs are
decision support only; neither makes an owner decision. This synthesis
recommends defaults for Ryan to rule on. Nothing here is a verdict until he
rules.

Chair verdict: GO WITH CONDITIONS. The five decisions are ready to rule on.
Two grep checks (below) change the calculus on Decisions 4 and 5, and both are
reported as observations for Opus to confirm, not as chair verdicts.

## Recommended defaults (the five rulings to make)

1. Adopt the six identities as the design direction, not as final balance or
   final mechanics. Both legs agree. Lower-risk variant, if wanted: adopt the
   direction but require the distribution test and an owner playtest (one
   battle as Chorus, one as Ithar) before locking presentation and narrative.
2. Approve the merged first-three order as a sequence, not a single pass:
   data-only price ladder and roster gates plus the hard prohibitions first;
   the per-faction economy hook as a separately scoped engine spike. DeepSeek's
   split formulation; Qwen's flat "approve all three in order" reaches the same
   destination but risks the engine item delaying or contaminating the cheap
   test. If one verdict is wanted: approve all three in principle, gate the
   engine item behind a small Opus scope.
3. Sim first with the no-Brace prohibition alone. Do not add Ithar shield
   recharge now. Both legs agree. Qwen's Option C (recharge prepped as a
   toggle) is kept as the follow-up implementation path if the sim justifies
   recharge, not built in the same pass.
4. Feed in, staged, with a tuning cap reserved up front. Enforce no shipyard
   repair first; implement kill-heal only as its own scoped item (see the
   avenge finding below: it is not a cheap repurpose). Qwen's cap plus
   DeepSeek's staging are compatible; adopt both.
5. Yes: Opus reports what reanimate currently does before any Deathless
   design builds on it. Both legs agree. The grep below strongly indicates
   Branch A (exists and works), so the expected report confirms rather than
   discovers; the design question then becomes visibility and tuning.

## What the chair verified by grep (observations for Opus to confirm)

### Decision 5: reanimate exists and works (Branch A indicated)
- All three standard Deathless hulls carry reanimate:true: d_scythe (Frigate),
  d_jackal (Destroyer), d_harvester (Cruiser) (data.js:96-98). The boss hull
  does not carry the flag.
- battle.js:702: on death, if the ship has reanimate, has not reanimated yet,
  and is not pyre-blocked, it reassembles once at 30% max HP: 20% chance on
  the enemy side, 35% on the player side, with fx text and a log line.
- Heat h_undying (data.js:378, battle.js:314) grants reanimate to every enemy
  non-boss ship, so the mechanic is also a campaign modifier.
- Counter exists: the Funeral Pyre boon (data.js:431) blocks regrow and
  reanimate on ships hit while below half hull.
- Do not conflate with Nekhet's Command "Reanimation protocol" (data.js:230),
  which rebuilds 25% hull and mends sections "even destroyed ones." That is a
  command ability, not the reanimate flag.
- Consequence: DeepSeek's Branch A handling applies. Do not fund a new
  return-from-wreck rule. The open items are visibility (does it appear in
  telemetry and sim win/loss causes?), the pyre interaction, and one tuning
  fact worth surfacing: the player-side chance (35%) is higher than the
  enemy-side chance (20%).

### Decision 4: avenge exists but does NOT make kill-heal cheap
- Avenge exists: battle.js:704. When a PLAYER ship is destroyed, if
  runFx().avenge is set, every other damaged player ship repairs by that
  fraction of max HP.
- Its only source found: the Reliquary of the Martyr relic (data.js:187),
  run.avenge = .15.
- The feed proposal mismatches avenge on three axes: trigger (own-ship death,
  not a kill), scope (fleet-wide, not nearby kills), gating (a relic, not a
  faction rule, and player-side only).
- Consequence: Qwen's "repurposing the existing avenge logic" framing is
  corrected. The kill-heal half is small-to-medium code (new trigger,
  proximity scope, faction gating), not a data-only repurpose. DeepSeek's
  staged default survives, but its condition resolves against cheap: scope
  kill-heal separately, do not wait on avenge to confirm it.
- Scope question for the no-repair half: shipyard repair, Drydock free
  repairs, and Field repairs (20%) are three separate campaign paths
  (campaign_run.js:3). The prohibition must say which it covers.

### Decision 3: no-Brace is confirmed cheap
- canOrder for brace is a single function (battle.js:790): not a squadron, no
  non-flak weapon fired. Adding a faction condition is a boolean check.
- Scoping question: AI also braces (battle.js:1137, 1141). The prohibition
  must say whether it covers AI Ithar, player Ithar, or both.

### Decision 2: the price ladder premise is exact, and the fix is data-only
- data.js:329: hulls without an explicit cost get
  h.cost = Math.round((60*cp+10)/5)*5. Every cp-1 frigate therefore costs 70
  unless overridden. "Frigates stop costing 70 everywhere" is literally the
  shared formula, and breaking it means per-faction cost overrides or a
  faction term in the formula.
- Roster gating mechanism was not verified by this screening. Opus to confirm
  how faction rosters are gated.

## Where the legs agree and where they differ
- Agreement on all five directions: adopt the direction; approve the
  first-three order; sim first with no-Brace alone; feed in staged; Opus
  reports reanimate first.
- Differences are sequencing and conditions, all resolved above:
  DeepSeek's split execution beats Qwen's flat approval for Decision 2
  (attribution); Qwen's toggle idea is a follow-up path, not a same-pass item,
  for Decision 3; Qwen's tuning cap plus DeepSeek's staging combine for
  Decision 4.
- DeepSeek's contribution beyond Qwen: explicit cost / buys / breaks-if-wrong
  per option; Decision 5 branch analysis with handling per branch; Decision 1
  Option C (pilot one or two identities) as a genuine third path.
- Qwen's contribution beyond DeepSeek: the Decision 3 toggle idea; the
  Decision 4 tuning cap; the framing of Chorus as the reference swarm.

## What is NOT decided here
- The five owner rulings themselves. Ryan rules; this synthesis recommends.
- Economy hook scope, shield recharge rate, feed heal rate, price-ladder
  values, salvage multipliers, roster-gate lists, and acceptance thresholds
  for metric divergence. None of these have numbers yet, and none should be
  set before the data-only pass and the mega sim.
- Campaign and map-layer faction asymmetry beyond the economy notes. Neither
  leg covers it.

## Recommended next step
Ryan rules on the five recommended defaults in one message (adopt / sequence /
sim-first / staged-with-cap / report-first, or any variation). Then Opus
confirms the two code observations (reanimate report, avenge scope) and scopes
the economy hook, and the data-only pass (price ladder, roster gates,
prohibitions) runs first. No code changes are commissioned by this synthesis.

## Not checked
- Roster gating mechanism (see above).
- Whether reanimate appears in telemetry or sim win/loss causes.
- The full Deathless design implications once reanimate is confirmed as the
  signature; that design work waits on the report.
- Any owner playtest outcome (the Chorus/Ithar battle check has not happened).
