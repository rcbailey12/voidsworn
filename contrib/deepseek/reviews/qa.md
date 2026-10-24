# DeepSeek Council, Lens 1: QA

Extracted by Rey from the raw DeepSeek transcript (contrib/deepseek/council_audit.txt). Claims are DeepSeek's, unverified, reproduced for Opus to judge. Quotes are verbatim from the transcript.

Source: Pack A chat, Lens 1 (QA). 10 findings, in the model's order.

## 1. Corrupted save with an unknown hull crashes on load/map
- Citation: core.js:70
- Quote: "Array.isArray(r.fleet)&&!!r.map&&Array.isArray(r.map.cols)"
- Mark: OBSERVED
- Model's reasoning: Save validation checks only that fleet is an array, not each ship's tpl. core.js:180 then does RUN.fleet.reduce((a,s)=>a+HULLS[s.tpl].cp,0) with no guard, so a renamed or removed hull in a save throws before the player can act.

## 2. Decommissioning the flagship leaves RUN.flagUid stale
- Citation: campaign_run.js:181
- Quote: "RUN.fleet.splice(i,1); closeModal(); shipyardScreen(yardNode);"
- Mark: OBSERVED
- Model's reasoning: There is no ensureFlagship() or flagUid update on this path. battle.js:113 uses opts.ship.uid===RUN.flagUid for pflag, so the next battle can have no flagship and no aspect applied.

## 3. Captured boss can be added to the player fleet
- Citation: battle.js:676
- Quote: "t.side=u.side; t.crew=Math.max(3,Math.round(t.crewMax*.4)); t.captured=true;"
- Mark: INFERRED
- Model's reasoning: boardUnit has no boss exclusion; any non-squadron can be captured if crew reaches 0. campaign3d.js:81 then runs const sh=newShip(u.tpl); and pushes it into RUN.fleet. Boss hulls like h_boss have no cost or slots set by the roster loop, so this can create NaN sell values and blow past command points.

## 4. Unknown relic id in a save crashes the map screen
- Citation: campaign_run.js:46
- Quote: "esc(RELICS[r].d)"
- Mark: OBSERVED
- Model's reasoning: normalizeRun does not validate relic ids. unknownId exists for derive-time relic effects, but map rendering dereferences RELICS[r] directly, so a renamed or removed relic id throws when Continue opens the map.

## 5. Saved captain with a missing name crashes ship creation
- Citation: core.js:126
- Quote: "s.cap&&s.cap.name.split(' ')[0]"
- Mark: OBSERVED
- Model's reasoning: normalizeRun only creates s.cap if it is absent or not an object; it does not fill cap.name. A save with cap:{} passes saneSave, then capName throws when buying a hull, hiring an event ship, or creating a replacement.

## 6. A zero-fleet win is converted into a run loss
- Citation: battle.js:771
- Quote: "if(caps('enemy').length===0){ B.over='win'; return; }"
- Mark: OBSERVED
- Model's reasoning: Enemy annihilation is checked before player annihilation, so if ticks leave both sides at zero, B.over is set to win; then campaign3d.js:88 ("if(result==='loss' || RUN.fleet.length===0){ endRun(false); return; }") records defeat anyway.

## 7. Towing salvage ignores the command-point cap
- Citation: campaign_run.js:272
- Quote: "RUN.fleet.push(sh);"
- Mark: OBSERVED
- Model's reasoning: The tow path creates and adds a ship with no fleetCP()+HULLS[tpl].cp<=RUN.cpCap check, unlike ACT.buyHull at campaign_run.js:174. A Corsair can exceed cpCap through salvage.

## 8. Nova cooldown is consumed even when the blast is abandoned after a stall
- Citation: battle.js:953
- Quote: "const c=arg.hex; u.abCd=abilityCd(u);"
- Mark: OBSERVED
- Model's reasoning: The cooldown is set before battle.js:955 ("if(!live()) return false;"). If the animation stalls, the nova never lands but the ability is spent.

## 9. LEGACY upgrades have no UI route
- Citation: campaign_meta.js:113
- Quote: "['heat','Heat'],['fallen','Hall of the fallen']"
- Mark: OBSERVED
- Model's reasoning: LEGACY defines war chests, command authority, veteran officers, founder relic, shipwrights and salvagers, and newRun checks META.unlocked.chest1, cmd1, etc. But legacyScreen renders only variants, mastery, favour, heat and fallen; ACT.buyLegacy has no button.

## 10. Reserve captains override event mercenary veterans
- Citation: campaign3d.js:99
- Quote: "const r=RUN.reserve.shift(); sh.cap=r.cap;"
- Mark: OBSERVED
- Model's reasoning: The patched newShip replaces the captain of any new ship when no battle is active. campaign_run.js:215 ("const s=newShip(tp,r.vet);") expects the mercenary event to create a veteran captain, but a stored reserve captain silently wins.

## Not checked
"Not checked: scene3d.js, ships3d.js, fx3d.js, sfx_data.js, sfx.js, gfx3d.js, vfx3d.js, wfx3d.js, perf3d.js, main3d.js, head.html, tbot3.js, and the auxiliary Python test scripts (softlock.py, step2test.py, striptap.py, cmdui.py, yardcheck.py, healtest.py, bosscheck.py) are not in the pack. I did not execute build.py, smoke.py, sim3d.js, or any browser/runtime path."
