# Port notes for the Godot helpers (stream B, JS rules oracle)

Stream B lands rule changes in the JS game first (battle.js, core.js, data.js, campaign_run.js, campaign_meta.js), sim-checks them, and lists them here for G1 (battle rules) and G3 (campaign rules). Each step says what changed, in which functions, which random draws were added, removed or moved (every one of these shifts parity), and suggests golden scenarios. The scripted proofs in `contrib/opus/tools/b3_tests.js` and `b4_tests.js` set up each scenario in a few lines and are a good template for the GDScript goldens.

Commits are on main; the newest step is at the bottom.

## Step 0: harness fixes (commit beae728)

- **B-18** `killUnit`: the stalled-battle check after `animExplode` was hidden inside a comment. It now runs: `if(!live()){ if(B===b0&&!B.over) checkEnd(); return; }`. No rules change when nothing stalls (always true in the sims and in Godot's headless runs).
- **B-19** `sim3d.js`: every alternating round start now awaits the turn-start deaths, exactly as the game does. Use `roundStartBoth()` (step 1) as the reference order.
- No random draws changed.

## G3 findings fixed in the oracle (Oct 26, from the campaign port)

- **Decorative battles no longer move the rules random numbers.** The title screen's showcase battle (`setupShowcase`) and the map's fleet showcase (`setupFleetShowcase`) call `startBattle` with no seed, which drew one number and reseeded the rules generator, so campaign rolls after a map visit depended on what was shown. Both now save `RNG_S` before and restore it after. Godot: the campaign rules generator should never be touched by anything decorative. Behaviour change: campaign rolls (event picks, shop stock, rewards) after visiting the map differ from older builds.
- **Wounded reserve captains now take hulls bought at a shipyard.** campaign3d.js's `newShip` wrapper checked `!B`, but the map's decorative battle is loaded while you shop, so the reserve hand-off never happened. Now `(!B||B.showcase)`. Godot: a hull bought at a shipyard (not a veteran hire) takes the first reserve captain, keeping the new ship's hull fraction.

## Step 1: B3 faction identity (commits f7bfe70, 5294612)

### Data (data.js)
- `FAC_PRICE[fac][cls]` multiplies shipyard prices at load (the `for(const [fid,F] of Object.entries(FACTIONS))` loop keeps `h.cost0` as the old price). Hegemony 1.0; Voidsworn Carrier 1.25; Corsair Frigate .8, Destroyer .85, Cruiser 1.05, Carrier 1.15; Chorus .65 / .75 / 1 / 1.2; Ithar 1.3 / 1.3 / 1.15 / 1.1; Deathless 1.45 / 1.5 / 1.55. Rounded to the nearest 5. Enemy fleets are still bought with command points (unchanged).
- `FAC_GATES` and `factionGate(fac,tpl)`: Corsair cannot field hulls carrying lance-kind weapons (prize Add and towing refuse them); Ithar `noBrace`.
- The JSON exporter should pick up `FAC_PRICE`, `FAC_GATES` and the new `cost` values.

### Battle rules (battle.js), all keyed on the hull's own faction `u.fac`
- `setupFactionRules()` runs in `startBattle` right after `setupObjective`. It sets `B.syncMark`, `B.syncLost`, `B.legion` and `B.torps`, picks one Hegemony anchor per side (player: the flagship `pflag`, else the biggest Hegemony hull; enemy: boss, else objective flagship, else biggest by cp then max hull) and the Deathless legion size (1, or 2 when the side fields 6+ reanimating Deathless hulls).
- **Hegemony synchronized fire**: `inSync(u)` = Hegemony capital within `SYNC_R`=3 of its living anchor. `syncOn(u,t)` = u in sync and another synced ship of its side already fired at t this round (`B.syncMark[side][t.id]={r,ids}`). Effects: `hitChance` +`SYNC_AIM`=8; `dmgMult` adds `max(stillPct, SYNC_DMG=.15)` (never both). `syncMarkShot` runs after a shot lands (after the live check) and at torpedo launch. `syncLose` when the anchor dies (`killUnit`) or is captured (`boardUnit`), for the rest of the battle.
- **Ithar prism charge**: `applyHit` marks `t.shHit[quad]=1` for any landed hit on a non-squadron. In `startSideTurn`, after the normal shield regen, `ithChargeTurn(u)` refills every unmarked facing to `shMax` (skipped while `st.shieldOff>0`), then clears the marks.
- **Ithar cannot Brace**: `canOrder(u,'brace')` is false for Ithar hulls (the AI and the bot already go through canOrder).
- **Chorus feed** `chorusFeed(t,by)` in `killUnit`, after `t.dead=true`: when a capital ship dies, Chorus capitals of the opposite side regrow hull: the killer (a squadron's carrier counts) `FEED_KILL`=15% of max hull, others within `FEED_R`=2 hexes of the dead ship `FEED_NEAR`=8%, capped at `FEED_CAP`=25% of max hull per ship per round (`u.fedR`, `u.fed`). Pyre-marked ships do not feed.
- **Deathless endless legion** replaces the random reanimate for Deathless hulls (`legionCan`). The fallen ship is dead (no hulk terrain), with `riseAt=B.round+1`; `legionTurn(side)` at the start of `startSideTurn` (before the unit loop) stands it up on its hex or the nearest free hex within 2, at `LEGION_HP`=35% hull, sections repaired to 35%, statuses cleared; it gets the normal turn ticks and then all its weapons are marked fired for that turn. Never the flagship (`pflag`, `boss`, objective `flagship`), never a pyre-marked ship. A player ship still reassembling when you win stands up silently (`checkEnd`). Non-Deathless hulls that reanimate (the Undying foes heat) keep the old random roll.
- **Travelling torpedoes** (weapon kind `torp`, not squadron bombs): `fireWeapon` spends the gun and calls `launchTorp`, which stores a salvo `{side, by, w (copy), tid, aim (target hex), from, r (round), base, rearAdd, ghost, called}`. `base`/`rearAdd` are `dmgMult` at launch (no rear / rear minus no rear), so launch-time multipliers (Commands, volley, bloodied, sync) are kept. Impact: `resolveTorps(side)` at the firing side's next turn start, in launch order. `torpImpact`: the original target is hit if it is within 2 hexes of the aim hex (to-hit penalty `TORP_RING`=[0,10,25] by distance); else an enemy capital on the aim hex is hit at -`TORP_STRAY`=10; else the salvo runs wide. Hit chance is `hitChance(ghost,w,t)` from the launch hex at impact time, minus the penalty. Then rocket point defense, the shots land through `landVolley` (shared with direct fire), kill credit goes to the launching ship even if it died.
- **Turn order (new, important for parity)**: `turnStart(side)` = `startSideTurn(side)`, await its tick deaths, then `resolveTorps(side)`. `roundStartBoth()` (alternating) = player ticks, enemy ticks (skipped if the battle ended), await both, then player torpedoes, then enemy torpedoes. ui3d.js and sim3d.js both call these, so the order lives in battle.js only.
- **AI**: `aiUnit` scoring subtracts `torpThreat(u,v)*.9` (step out of lanes aimed at you) and `syncPull(u,v)*(veteran?2:1.2)` (Hegemony stays within reach of its anchor).
- **B-20**: `fireWeapon` reads the rangefinder relic (`runFx().firstSure`) with the shot count from before this shot; it never applied before. Torpedo ghosts carry the pre-shot count too.
- `fireWeapon` was split: `rocketDefense(w,t,shots,res)` and `landVolley(u,w,t,o)` (shots land, callouts, log, riposte, kill). Same order and same numbers as before for direct fire.

### Random draws
- **Moved**: every draw of a torpedo shot (hit rolls, rocket point defense, per-hit damage variance, critical rolls, system damage) moves from the launch activation to the impact at the next turn start. A salvo that runs wide draws nothing.
- **Removed**: Deathless hulls no longer draw for reanimation in `killUnit` (one draw per death before). Undying-heat reanimators still draw.
- **Unchanged count, different values**: B-20 changes the first shot's hit chance when the rangefinder relic is held.
- AI move choices change (torpedo dodging, Hegemony formation), so whole-battle parity shifts even where no draw changed.

### Suggested golden scenarios
1. Sync: Hegemony anchor + two synced ships 1 and 2 hexes away, one Voidsworn target 3 hexes out. Ship A fires, then check ship B's `dmgMult` (+.15 x weapon damage) and `hitChance` (+8); move B 4 hexes from the anchor (no bonus); kill the anchor (no bonus, `syncLost`).
2. Anchored Volley plus sync on one shot: the larger of the two only.
3. Ithar: `sh=[5,5,5,5]`, regen 2, facing 0 hit last round: next turn start gives `[7,max,max,max]`; with `st.shieldOff>0` nothing changes.
4. Chorus: razorfiend at 20 hull kills three pickets in one round: +15%, then capped at +25% total; a spitter 1 hex from the first kill gets +8%.
5. Deathless legion: kill two jackals in round 1 (4-ship fleet): the first gets `riseAt=2`, the second stays dead; at round 2 start the first stands at 35% (plus its normal regrowth) with every weapon fired.
6. Torpedo: harrow fires at a dominion 4 hexes away in round 1 (no RNG draw at launch); round 1 turn start again does nothing; round 2 `turnStart('player')` lands it. Repeat with the target moved 3 hexes from the aim hex: "runs wide", no draws.
7. Alternating round start with a fire tick death on each side and one torpedo in flight per side: check the order player ticks, enemy ticks, player torpedo, enemy torpedo.

## Step 2: B4 ship-five (commits f1435e5, 9eaeb15)

### Campaign (G3: campaign_run.js, core.js, campaign3d.js, data.js)
- **Run fields** (`runDefaults`): `flags:{}`, `nem:null`, `verbUsed:0`, `verbNext:null`. `newRun` sets `RUN.flags={}` and `RUN.nem=newNemesis()` right after `genSector(1)`.
- **Events**: `nextEvent()` picks from events not yet seen this run and not barred for the faction (`not`), with `EVENT_FALLBACK` ('quiet') once all are seen; the old reset of `seenEvents` is gone. Blue options carry `need:{...}`; `needMet(need)` and `needText(need)` are pure functions (kinds: fac, kind, carrier, shields, relic, mod, cred, vet, flag, intel). `eventOptOk(o)` = affordable and need met. `eventFlags(ev,o,i)` writes `RUN.flags[ev.id]=o.k||i` plus `o.fl` counters (greed, mercy, loud, intel, purge, fed). New outcome keys in `applyOutcome`: payMod, payXp, payRelic, repairOne, dmgBig, xpTop, modId, shipRaw, wingPerk, nemIntel, nemClock; `healAll:1` means full repair.
- **Nemesis** (`RUN.nem`): `newNemesis()` = faction `RUN.foes[3]`, a name and top rank from `CAPTAINS[fac]`, two weaknesses (`shuffle(keys(NEM_WEAK)).slice(0,2)`), revealed [], adapt [], clock 0, met 0 (sector last met), beaten, scars, dead, strike, seen {}. `nemClockAdd(n)` clamps 0..`NEM_CLOCK`=4; reaching 4 before he is met this sector sets `strike`. `nemNodeIs(n)`: battle or elite node, not met this sector, and (strike or column >= cols-3). `ACT.enterNode` turns such a node into `battleScreen({kind:'elite',fac:nem.fac,col,node,nemesis:nemBattleCfg()})`. `finishBattle` (campaign3d.js): `nemLearn(B.usage, evasive flag)`; for his fight `nemAfterBattle(result, flagshipDead)`; otherwise a win does `nemClockAdd(1)`. `afterBattle` at a sector change calls `nemAdapt()` (at most sector-1 adaptations in total; picks the counter to what `seen` counted most: lance/ion -> shields, torp/sq -> pd, ram/board -> armor, battery/broadside -> evasion, evasive fleet -> aim; ties go in the order shields, pd, armor, evasion, aim).
- **Faction verbs** (`FAC_VERBS`): `verbCanUse()`, `useVerb()`, `verbCostText()`. Once per sector (`RUN.verbUsed=RUN.sector`), cost waived when `RUN.flags[V.free]` exists, writes `RUN.flags['verb_'+id]`. Next-battle verbs set `RUN.verbNext`; `battleScreen` passes it as `cfg.verb` and `finishBattle` clears it. Immediate verbs: shake (credits 30+10 per greed flag, clock +1, greed +1), gorge (20% hull, 30% if `flags.spawn==='feed'`).
- **Wing veterancy**: `ship.wingVet={kills,perks}`; `wingVetAfter(ship,kills)` grants a random perk at 3, 8 and 15 wing kills (max 3); `wingPerkGrant` also used by the 'pilot' event.

### Battle (G1: battle.js)
- `startBattle`: after `setupFactionRules()`, `applyNemesis(cfg.nemesis)` and `applyVerb(cfg.verb)`.
- `applyNemesis`: every enemy capital gets `u.nem`; the biggest (cp, then max hull) gets `u.nemFlag`, elite, his name, `dmg *= 1+.1*scars`, and becomes the Hegemony anchor if Hegemony. Weaknesses: board (crewMax x.7), slow (speed -1, min 1), flank (`dmgMult` +.25 on rear hits against him), ion (`ionVs`: ion and lance hits x1.5 shield strip against him, used by `applyHit` and `expectedVs`), torp (+15 to land torpedoes on him), brawl (his ships -10 to hit at 2 hexes or less), anchor (`nemBreak()` at turn start: his escorts flee once his flagship is under 60%). Adaptations: shields x1.2, armor +.1 (cap .6), evasion +8, aim +8, pd (flak, or spores for Chorus, on up to two ships without flak).
- `applyVerb`: vigil (player `fx.lineGuard` +.15), drill (`B.syncR.player=4`, `B.syncDmg.player=.2`; `syncR(side)` and `syncDmg(side)` replace the constants), attune (player shields x1.25), waken (`B.legion.player.max+1`).
- **Wing doctrines**: carrier `u.stance` in strike / screen / hunt (default strike), `u.stanceRound`; `setStance` allows one change per round. `sqPlan`: with no explicit order, a screening wing guards its carrier (stay within 3 hexes of it, enemy craft x2 value); a hunting wing gets +4 leash and crippled ships x1.6 value. `dmgMult`: hunting wings +.2 against ships below half hull; 'killers' perk +.15 against ships. `hitChance`: shots at a hunting wing +10. `screenTorps(t,shots,res)` in `torpImpact` after `rocketDefense`. Perks at `makeWing`: aces aim +10, jinkers ev +8, armored hull x1.25; reserve: +1 spare in `deployWings`. `aiStance(u)` at the enemy's `startSideTurn` (and by the sim bot for the player): screen when the other side has torpedoes in flight or more than one more wing, hunt when it has a crippled capital, else strike.
- `fireWeapon` counts player usage by kind (`B.usage.kind`, `B.usage.ion`) for the Nemesis.

### Random draws
- **Added**: `screenTorps` draws once per screening wing within 2 hexes of a torpedo's target, while that wing still has a hit shot to remove (after the rocket point defense draws).
- **Campaign**: `newNemesis` draws (faction fallback pick, name, weakness shuffle) right after `genSector(1)` in `newRun`; `wingPerkGrant` draws one pick per perk; `nextEvent` draws one pick from a pool that no longer resets.
- Stance choices change wing movement and targets, so battles with carriers shift.

### Suggested golden scenarios
1. Nemesis fleet build: elite Hegemony fleet with weaknesses [slow, board] and adaptation [armor]: speed -1, crew x.7, armor +.1, flagship named and anchored.
2. Nemesis flank: a rear-arc hit on his ship gets +.25 in `dmgMult`; ion: a lance hit on his shields strips x1.5.
3. Proud flagship: drop his flagship to 59% and start a turn: escorts `fled`.
4. Verb drill: Hegemony ship 4 hexes from the anchor is in sync only with `cfg.verb='drill'`.
5. Wing stance: switch strike -> hunt (allowed), hunt -> screen in the same round (refused); a hunting bomber's `dmgMult` against a ship at 30% hull is +.2 over strike.
6. Torpedo into a screen: a salvo whose target has a screening wing beside it loses up to one shot per wing.
7. Campaign (G3): `nextEvent` never repeats in a 40-draw run and ends on 'quiet'; `nemClockAdd` four times sets strike; `nemAfterBattle('win',true)` in sector 3 sets dead.

## Step 1 tuning (commit c7b1a78, after the first PC pass)

- `FEED_KILL` .15 to .12, `FEED_NEAR` .08 to .06, `FEED_CAP` .25 to .2.
- Torpedoes: `TORP_RING` [0,10,25] to [0,5,15]; `TORP_WARHEAD`=1.2 multiplies `S.base` and `S.rearAdd` at launch; when the original target is dead at impact, the nearest enemy capital within 1 hex of the aim hex is hit at the stray penalty (ties by unit id), otherwise only a hull on the aim hex.
- `BOSS_FAC.hegemony` .95 to .85.
- Ithar prism charge: an unhit facing refills to full; a hit facing gets its regen a second time (after the normal regen), both skipped for an ion-locked facing.
- Telemetry only: `fstat` counts shots, syncShots, braces, fade. No rules effect.

## Step 3: game backlog (commits 02e55fc, 7f74d94 and the step 1 tuning above)

### Battle (G1)
- **Move, then fire (v54, decided)**: the first non-flak shot of a capital ship sets `u.postFire=true` and `u.postMp` = half the movement left for Ithar (`canFade`: Ithar or the Slip the Net boon), else 0. `computeReach` uses `MP=postFireMp(u)` and forbids climbing or diving after firing. `moveUnit` spends `postMp` too. Cleared at turn start. Rotating in place and rams are not limited. A Command barrage saves and restores `postFire`. An abandoned shot restores it. The AI and the bot always move before firing, so only the new fade moves show up in the sims: `fadeMove(u)` after the volley (AI in `aiAfterFire`, the bot after its guns) steps to the reachable hex with the least `evalThreat + torpThreat` if that cuts the threat by a quarter.
- **Chorus bite (v54)**: `landVolley`, direct fire only: a Chorus capital that deals hull damage at 1 to 2 hexes regrows `CHORUS_BITE`=20% of it through `chorusRegrow` (the same per-round cap as feed).
- **Voidsworn brace cover (v54)**: `giveOrder(u,'brace')` calls `braceCover(u)`: the most damaged adjacent same-side capital with the same facing gets `coverBy=u.id`; with the Shield Wall boon (`fx.wallBrace`, any faction) every adjacent ally does. `braceMul(t)` replaces the brace term in `applyHit`, `expectedVs` and `aiFocusVal`.
- **Hegemony ion lock (v54)**: `applyHit`: a Hegemony attacker's ion weapon sets `t.regenLock[quad]`; that facing skips its regen (and Storm Mantle and prism charge) at the next turn start, then the lock clears.
- **Boon rules**: chainSh (Chain Lightning: a broken facing's two neighbours lose a third), broodTithe (a free wing from the nearest carrier with a free hex on each capital kill), markLance (first lance hit each round marks the target: +10 aim for the side), fade, spread (a salvo that runs wide bursts on enemies within 1 of the aim hex for `S.base*spread`, through `applyHit`), lanceSure (lances 95% and pierce 1), lanceRange (`mkWeapon`), lineEv (-5 to hit next to an ally), chainFire (chain blasts set fire 2 turns), endless (spares 99).
- **AI polish**: `aiHurtW(u,prof)` replaces the 30% step with a smoothstep from 60% to 30% hull and a latch (`u.aiHurt` on below 30%, off above 45%); `aiPickPrimary` keeps `u.aiLastT` while it is worth at least `AI_STICK`=85% of the best.

### Campaign (G3)
- `RARITY[3]` Legendary. `rollBoonOffer(p,minR)` excludes `leg` boons from every pool and, when `minR>=1` and you hold two non-legendary boons of patron p, puts `legendaryFor(p)` in slot 3 with r 3.
- Boon offer screen: `boonDecline()` (30 + 10 per sector credits) and `boonReroll(p,minR)` (once per reward, `RUN.reward.rerolled`; cost 25 + 15 x `RUN.boonRerolls`; rerolls up to 4 times to avoid the same three).
- Class refit track: `RUN.classTrack[cls]` 0..3, `buyClassTrack(cls)` at 60 + 50 x level (times priceMult); `derive` adds .06 x level to the hull multiplier and to dmg.
- Corsair prize money (finishBattle): on a win with at least one prize, a refit from the first prize's salvage yield (else a random refit) and 20 credits.

### Random draws
- Added: Spread Pattern bursts draw through `applyHit` (crit and fire rolls per enemy caught); Brood Tithe and fade draw none; `boonReroll` draws a new offer (up to five offers); legendary offers draw none.
- AI behaviour changes (caution curve, target stickiness, fade) shift whole-battle parity without new draws.

### Suggested golden scenarios
1. Penitent fires a battery: `computeReach` is empty after; an Ithar songship with 6 movement fires: reach costs at most 3, no over-moves.
2. Voidsworn brace with a same-facing neighbour and a cross-facing neighbour: only the first gets `braceMul` .6.
3. Hegemony ion hit on facing 0 at sh 1, regen 5: next turn start facing 0 stays 1, others +5.
4. Legendary: two iron boons held, elite reward: slot 3 is L_iron with r 3; at a normal reward it never appears.
5. Class track: three Frigate levels: warden max hull 45 x 1.18 = 53, dmg 1.18.
6. AI stickiness: a dominion with two equal targets keeps last activation's target.
