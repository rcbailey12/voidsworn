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

## B-21 fix (from G1)

- `startBattle`, the carrier-fleet adaptation: the point defense bolted onto escorts (`u.pdRefit`) was pushed straight from `mkWeapon`, without the per-battle fields `fired`, `cdLeft` and `off`, so `weaponReady` was false and the squadron flak gauntlet (`x.off===0`) skipped it; it only ever thinned rocket salvos. It now gets `{fired:false,cdLeft:0,off:0}` and its faction name (`nameWeapons`), like every other gun. The Nemesis pd adaptation does the same.
- Behaviour change: against fleets with two or more carriers (or a carrier admiral or the Hive aspect), refit escorts now intercept your wings (up to 2 per turn each) and add flak fire. Random draws: one more intercept volley per wing attack that passes a refit escort within range.
- Golden scenario: two Reliquaries and a Penitent in sector 2 against a generated Hegemony fleet; the refit escort's last weapon is flak with fired false, cdLeft 0, off 0; a bomber attacking it spends one of its intercepts.

## Pass 2 tuning (commit 7b313c4)

- data.js `MOVE_RULES`: Voidsworn `rake` .2 to .3; Ithar `evade` 10 to 14.
- battle.js: `SYNC_DMG` .15 to .12, `SYNC_AIM` 8 to 6; `FEED_CAP` .2 to .15; `CHORUS_BITE` .2 to .12; Ithar star torpedoes (`w.trait==='star'`) use ring penalties [0,0,10] instead of `TORP_RING`.

## R42 Nemesis v2 (commit 7b313c4)

### Data (data.js)
- `NEM_TRAITS` (14 strength traits), `NEM_PERSONA` (8 personalities with AI weights), `NEM_FAC[fac]` (name parts pre/post, titles, persona pool, trait pool, scar epithets, behaviour `beh`), `NEM_ADAPT_FAC[fac]` (faction names for the five counters plus one `special`), `NEM_LINES` (placeholder taunts by persona plus the "again" line; the story helper's pools replace these), `NEM_BEAT_WORD`.

### Campaign (G3, campaign_run.js and campaign3d.js)
- `newNemesis()` draws, in order: faction fallback pick (only if `RUN.foes` is missing), `nemName` (pick pre, pick post, retried up to 12 times while the name appears in an admiral's name; post parts starting lower case join without a space), title pick, persona pick, trait shuffle (first two), portrait (1 + floor(rnd x 6)), weakness shuffle (anchor removed for Voidsworn and Deathless). Fields: persona, traits, portrait, scars, scarList (causes plus 'ep:' epithet markers), epithet, beat, fed, riches, revived. `ensureNemesis` upgrades a B4 save (keeps clock, weaknesses, adaptations).
- `nemFull()` = title + name + epithet. Clock: `nemClockAdd(n)` multiplies gains by `beh.clock` (Deathless .5, Voidsworn 1.5) and rounds to halves. On filling: `nemStrike()`: raid (Corsair: take 25% of credits if 30 or more; else, with 3+ ships, cut out the lowest-hull non-flagship ship under 25% hull, riches +1), tithe (Deathless: every ship loses 6% max hull, min 1); other strikes act in battle.
- `nemAfterBattle(result, flagDead, {fled, beat, cause})`: fled (scar 'fled', riches +1 for factions with a flee rule); flagDead with `beh.revive` and not yet revived (revived, scar, and in sector 3 `met` drops back one so he can meet you again); flagDead in sector 3 (dead); flagDead earlier (scar); Chorus (`adaptFast`) adapts after every meeting. `nemScar(cause)` adds a scar and picks an unused epithet. `nemFeedLosses(n)`: Chorus fed +n (max 8), called from finishBattle for every battle with player losses. `nemBeatOf(usage)` picks what beat him (lance, torp x2, sq, battery, ram x3, board x3, ion).
- `nemAdapt()`: cap = sector-1, plus beaten + scars for Chorus, max 6; picks the highest-scoring counter with a score above 0 (aim now weighs evaded x3), else the faction special, else the first unused counter.
- Hegemony Nemesis fights force the reinforcement event at round 3 (campaign3d.js battleScreen).

### Battle (G1, battle.js)
- `applyNemesis`: Ithar duel fleet (keep the flagship and the three biggest, all elite with +6 aim, +5 crit); Corsair riches (one `cheapHull` per riches level, plus one for the 'riches' special, placed at `edgeHex('enemy')`); traits (gunnery +6 aim, armored +.08 armor, swift +1 speed, deadeye +10 crit, veil +8 ev, regrowth +4 hull regen, veterans x1.12 hull incl. sections, shielded x1.2 shields, boarders x1.3 crew, artillery +1 range and opt on guns, rockets torpedo cd -1, brood +1 hangar and spare, undying legion +1); Chorus fed x(1 + .04 x fed, max .32) hull; specials (veil +6 ev, hunger +3 regen, zeal +.08 dmg, legion +1, formation enemy sync radius +1). `B.cp0.enemy` recomputed. A log line with his taunt (or the "again" line if he has been beaten before).
- `nemFleeCheck()` at the enemy's turn start: Corsair flagship hull <= 35%; Ithar every flagship shield <= .5 and hull <= 60%: he and all his capital escorts are `fled`, `B.nemFled`, checkEnd (a win for you).
- `B.nemNoRout` (Voidsworn, Deathless): the 35% rout rule never applies.
- `dmgMult`: challenge (+.2 between his flagship and your `pflag` ship, both ways); zeal trait (+.12 at 1 hex).
- AI: `nemProf(u,prof)` (persona tw and range; proud flagship tw x.6) in `aiUnit`; `nemTargetBonus(u,t)` in `aiPickPrimary` (cruel and cunning: +20 x missing hull share; greedy: +25 on your flagship).

### Random draws
- Campaign: the identity draws above at run start; `nemScar` one pick per survival; Corsair riches spawn draws nothing.
- Battle: none added (riches ships are made without draws; duel pruning has none).

### Suggested golden scenarios
1. Corsair Nemesis at clock 3 with 200 credits: one win fills it and takes 50 credits; in his fight, flagship at 30% hull at the enemy turn start: `nemFled`, win.
2. Deathless Nemesis: clock +1 per win gives .5; flagship killed in sector 3: revived, met 2; killed again: dead.
3. Chorus Nemesis with fed 3: his flagship's max hull is 1.12 x the fed-0 battle with the same seed.
4. Voidsworn Nemesis: your flagship's `dmgMult` against his flagship is +.2 x weapon damage; the enemy never routs.

## Step 4: R42 story fields, R41 arc hulls, R42 and R49 Nemesis behaviour, customization reserve (Oct 26 evening; commits c88567c, 69bddcf, ae22b11, d8b47c6)

Second stream B helper. Carries over the first helper's uncommitted R42 alignment work.

### Checks confirmed, no change
- **Round start order** (Muse must-fix 1): the game (ui3d.js alternating mode) and every sim loop call the same `roundStartBoth()` in battle.js, so they cannot drift; Muse's ordering claim was rejected in X20.
- **Faction identity counters** (Muse must-fix 2): `fstat` producers are live (feed, charge, syncShots, torpLaunch, torpHit, torpDodge, torpGone, revive, braces, fade). `node sim3d.js fmatrix 1` prints non-zero definers for all six factions.
- **B-21**: fixed in b8d1a97 with its own check in b3_tests.js (the refit gun gets fired, cdLeft, off; intercepts are counted after it is added).

### Campaign (G3)
- **Nemesis fields**: `persona` and its ids stay exactly as R42 (NEM_PERSONA, four per faction in `NEM_FAC[fac].personas`). New: `g` ('m', 'f', 'n'): 'n' for the Chorus (`NEM_FAC.chorus.g`), 'f' when the name starts with one of `NEM_FAC[fac].fem`, else 'm'; `nemGender(fac,name)`, **no random draw**. `last_beat` replaces `beat` (ids lance, torp, sq, ram, board, battery, evasive; `nemBeatOf(usage, evasive)`, evasive when the fleet's average evasion is 20+). `scarKinds` (causes) and `epithets` replace `scarList`. `signatures` (last 40 kinds). `loot`, `held`, `honed`, `gloat`. `ensureNemesis` upgrades older saves (beat to last_beat with ion mapped to battery, pronoun to g, scarList split) and keeps met, beaten, scars.
- **Name tables** (strings only): Deathless, Voidsworn and Chorus name parts and titles, Chorus scar epithets, Hegemony "Lindqvist", five NEM_ADAPT_FAC names, "the Unsunk" to "the Uncaught". `NEM_FAC[fac].scarBy` {fled, burn, wound} lists. Hegemony `beh.formation` removed (nothing read it; the +1 sync radius is the 'formation' adaptation only); `beh.line` added. `beh.ai` for Ithar {range:3, focusWeak:1} and Voidsworn {hunt:1, charge:1}.
- **newNemesis draw order** (unchanged order, one change): name (pre, post, up to 12 retries), title, persona, trait shuffle, portrait, weakness shuffle. The weakness pool now drops a weakness that cancels a drawn strength (slow with swift, board with boarders, ion with shielded), so that shuffle can be one element shorter (**one draw fewer**).
- **nemStrike** raid: credits taken go to `N.loot`; a towed ship goes to `N.held` (only one at a time; riches +1 as before).
- **nemWarnLine** on his card when the next win fills the clock (R7): what the raid will take (and how to stop the ship cut: repair above 25% or keep 30 credits), the tithe, or that the next fight is his.
- **nemAfterBattle** (new branch order): win: beaten+1, gloat cleared, last_beat set and `nemBeatTeach(beat)` adds 8 to the matching `seen` counter (so his next adaptation counters what beat him), weakness reveal as before; then fled (riches+1 only for a raid faction, `honed`+1 for the duel faction, scar 'fled'); else flagship dead in sector 3 with revive unused (revived, scar, met = sector-1: one last fight); else flagship dead in sector 3 (dead); else flagship dead earlier (scar; every faction, the Deathless one too, R49); else withdraws. Then, only when he is dead, `loot` and `held` come back (R49). Then `arcComplete(RUN.fac)` on any sector 3 win that does not bring him back. Loss: clock 1, `gloat` = 'flagship' (your flagship died, `o.myFlagDead`), 'retreat' or 'loss'. Chorus fast adaptation line now carries the why text.
- **nemScar(cause)**: the epithet is picked from `scarBy[tag]` (fled; melt, flay, tidal = burn; the rest = wound), falling back to any unused one. Still one draw.
- **nemFeedLosses** returns a line (fed and the hull bonus) shown in the battle summary. **nemFoundMerge(B.nemFound)** in finishBattle adds weaknesses found in battle to `revealed`.
- **ACT.enterNode**: his fight passes `arch: beh.fleet` when it is an ARCHETYPES key (Corsair and Chorus swarm, Deathless and Hegemony heavy), so `genEnemyFleet` draws differ for those fights.
- **R41 arc hulls**: six `HULL_VARIANTS` rows with `cost:0` and `arc`, `ARC_VARIANT[fac]`. `arcComplete(fac)` sets `META.variants[id]` once (above). `ACT.buyVariant` refuses arc rows; the Progression tab says "Finish the <faction> story to unlock".

### Battle (G1)
- **nemSig(kind)**: pushes `{kind, r}` to `B.nemSigs` (and the campaign record). G1: emit `{t:'nem_signature', kind}` there. Kinds in battle: challenge, duel, line (at setup), flee_battle, reinforce (when the round 3 reinforcements arrive, in `eventTick`). Campaign kinds: raid, tithe, flee, revive, feed, fast_adapt.
- **applyNemesis**: riches ships only for a raid faction (R49: an Ithar who fled no longer brings extra ships); duel faction `honed` h (max 3): aim +3h and shields x(1+.1h) on his ships; `beh.line`: his escorts' non-flak, non-wing guns get opt +1; `B.nemAi`, `B.nemLine`; memory line: gloat line if he won last time, else the "again" line only when his adaptations hold the counter (`NEM_BEAT_COUNTER`), else "remember".
- **Voidsworn duel** (R49): `nemDuelTarget()` = your flagship, else your biggest living ship (cp, max hull, id); stored in `B.nemDuel`, logged at setup and when it changes. `dmgMult` challenge +.2 now between his flagship and `B.nemDuel` (was `pflag`). `nemTargetBonus` +30 for his flagship on that ship.
- **AI**: `nemProf` applies `beh.ai` after the personality (range max, charge: flagship tw x.7); `nemTargetBonus` focusWeak also from `beh.ai`; `syncPull` weight x2 for his ships when `B.nemLine`.
- **Weakness found in battle** `nemTrip(k)`: landVolley after the hit loop (your hit on his ship: flank on a rear-arc hit, ion when an ion or lance hit took shield, torp on a torpedo hit; his ship hitting yours at 2 hexes or less: brawl), boardUnit after the boarders land (board), nemBreak (anchor), enemy turn start from round 2 (slow). Logs once, adds to `B.nem.revealed` and `B.nemFound`.

### Random draws
- Campaign: weakness shuffle can be one draw shorter; arch-built Nemesis fleets draw differently; everything else in this step draws nothing new.
- Battle: none added or moved. AI behaviour (duel hunt, Ithar range and focus, the line pull) shifts whole-battle parity in Nemesis fights.

### Sims
- `node sim3d.js varmatrix N` (VK=battle: sector 2 generated fleets; VK=boss: sector 1 flagships): each arc hull against its base, paired seeds, as the second ship in the faction's first admiral's start fleet.

### Customization reserve (brainstorm section 6), schema only
1. Ship instance state: already separate. A fleet ship is `{uid, tpl, name, mk, hp, mods, cap}` and `derive()` resolves numbers from `HULLS[tpl]` at battle time. Reserved: `ship.fit = {pod, module, trim}` (absent until used) and `shipFit(ship)` in core.js; `FIT_SLOTS` describes the slots. Nothing applies it. Godot: keep the field in the save schema.
2. Variant row schema: `{base, n, d, w, mod, cost, arc}`, merged into HULLS with `variant` and `base`; documented in data.js. Done.
3. Flagship mount conventions: not stream B (A4 and G4).
4. Sim hook: `FIT='{"pod":..,"module":..,"trim":..}'` puts a fit on the flagship of every sim run (`simFit()`); inert until a resolver exists.
5. Faction weapon pool tags: `FAC_WPOOL[fac]` (weapon ids carried by that faction's hulls, variants included), computed at load. The exporter should pick it up.
6. How the Nemesis counts usage today: `fireWeapon` counts the player side's shots by weapon kind (`B.usage.kind`, plus ion, rams, boards, broadside fire), fleet-wide, every battle; `nemLearn` adds each battle into `RUN.nem.seen`; `nemAdapt` reads it at a sector change (the Chorus after every meeting) and then clears it. So the window is "since his last adaptation" (about a sector), the basis is the whole fleet, not the flagship, plus the +8 for what beat him. Cheap later: a rolling list of the last four battles instead of a sum (guardrail 1). Not cheap now: the duel refresh (guardrail 3) needs per-ship usage; `B.usage` is per side.

### Review open questions (contrib/muse/reviews/nemesis_review.md), answered from the code
1. Tithe: clamps each ship at 1 hull remaining (`max(1, hp - 6%)`); it never destroys a ship.
2. Branch order: the old code checked revive first, so a Deathless kill in sectors 1 and 2 spent his comeback. Fixed above (R49).
3. Hegemony formation: only the 'formation' adaptation gives +1 sync radius; the unused innate flag is gone.
4. A full clock does both: the raid or tithe lands at once, and the next battle or elite node becomes his fight.
5. Duel and swarm strikes only force the fight; their behaviour lives in his battle rules (duel fleet, honed; Chorus feed and swarm archetype).
6. `ensureNemesis` keeps met, beaten, scars, dead, strike, seen, weaknesses, revealed, adaptations and the old beat.
7. Card (browser): faction behaviour text with his pronouns, the warning line, fed, what he holds, weaknesses (known ones named), adaptations with their effect, and what beat him. Godot shows the same from these fields.

### Suggested golden scenarios
1. Deathless: flagship killed in sector 2: scar 1, revived false; sector 3 kill: revived, met 2; again: dead and the arc variant unlocked.
2. Corsair: 10 credits, three ships, one at 1 hull, clock 3: one win tows it (`held`); he flees: still held; killed in sector 3: back in the fleet.
3. Ithar: fled once: same fleet count (4 or fewer), flagship shields x1.1, aim +3, riches 0.
4. Voidsworn: `nemTargetBonus(flag, yourFlagship) - nemTargetBonus(flag, other) == 30`; kill your flagship: the duel moves to your biggest ship and `dmgMult` between them gets +.2.
5. Weakness: Hegemony rival with flank; your rear-arc hit lands: `B.nemFound` = ['flank'] and the log line.
6. Beat sync: beaten with lance (seen battery 5): next `nemAdapt()` is shields, and the next meeting's line is the "again" line.
7. Hegemony line: an escort's battery opt is the table opt + 1; `syncPull` doubled for his ships.

## Step 5: admiral band (Oct 27; data.js only)

Third stream B helper. Band: the plan's starting band is no admiral below 50% or above 90% against a sector 1 flagship (plan B2 exit). Vetoable call: tune to about 55 to 85% so a 100-run sample cannot drift across the 50 and 90 lines on noise alone (about 5 points either way at 100 runs, FINDINGS S10).

### Data (data.js `ADMIRALS`), for the exporter
- Kassar: start `h_vanguard, h_picket` (was `h_vanguard, h_interdictor`).
- Reyes: `sqPct` .25 to .1; text "+10% damage".
- Maren: start `h_dominion, h_picket` (was two pickets).
- Grax: start `c_marauder, c_reaver, c_reaver` (was `c_marauder, c_reaver, c_raider`).
- Matriarch: start `b_brood, b_drone, b_drone` (one more drone).
- Mending Choir: `hullRegenPct` .06 to .04; text "4%".
- Nekhet: `hullRegenPct` .06 to .04; text "4%".
- No battle.js or campaign code changed. Random draws: none added or moved; a different start fleet changes the draws a battle makes (more or fewer ships), so admiral parity goldens that use these four start fleets need new expected values.

### Sim (sector 1 bossmatrix, 100 runs per admiral per leg; each admiral's legs are independent, so single legs equal the combined change)
| Admiral | Before (pass 2, PC) | Change | After |
|---|---|---|---|
| Grax | 34% | start marauder, 2 reavers | 63% (PC) |
| Kassar | 91% | start vanguard, picket | 82% (PC) |
| Matriarch | 50% | one more drone | 66% (PC) |
| Nekhet | 90% | regrow 4% | 77% (cloud) |
| Mending | 87% | regrow 4% | 80% (cloud) |
| Maren | 88% | start dominion, picket | 79% (cloud) |
| Reyes | 86% | squadrons +10% | 80% (cloud) |
Rejected legs (same sample size): Grax two marauders 40, Grax four ships 70; Kassar vanguard and two pickets 92, Kassar guns 10% lighter 87; Matriarch brood and spitter 80; Nekhet harvester and scythe 71, harvester and two scythes 79; Maren hull +5% 86; Reyes vanguard and picket 61, squadrons +15% 84, +15% with no squadron hull bonus 83.
Untouched admirals stay at their pass 2 numbers (51 to 85%). Confirmation run: PC lane B, 200 runs per admiral, all 24 (jobs `sb_band1_1` to `_6`); results in `contrib/opus/compute/streamb/band1_bm.txt`.

### Suggested golden scenarios
1. New run as Grax: fleet is marauder, reaver, reaver (7 command points).
2. Mending Choir ship at 100 of 150 hull at turn start: +6 hull (4%), not +9.
