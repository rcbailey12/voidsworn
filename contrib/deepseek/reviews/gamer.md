# DeepSeek Council, Lens 3: Gamer

Extracted by Rey from the raw DeepSeek transcript (contrib/deepseek/council_audit.txt). Claims are DeepSeek's, unverified, reproduced for Opus to judge. Quotes are verbatim from the transcript.

Source: Pack A chat, Lens 3 (Gamer). 10 findings, in the model's order. Each finding pairs an OBSERVED citation with the model's INFERRED impact, as the model presented them.

## 1. The first real screen asks for a permanent flagship aspect before the player has fought once
- Citation: campaign_meta.js:94
- Quote: "const opts=shuffle(Object.keys(ASPECTS)).slice(0,(RUN.mastery||0)>=2?4:3);"
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: ACT.startRun goes straight to aspectScreen() before the map or any battle (campaign_meta.js:77). Six aspects with rule-changing text, chosen blind, is a likely first-session confusion and quit point.

## 2. Sector 1 makes the player fight before they can shop or repair
- Citation: core.js:213
- Quote: "if(c===0) type=s>=2?'shipyard':'battle';"
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: Sector 1 column 0 is always a battle; the first guaranteed shipyard is column 3 (core.js:224). The player starts with 120 credits (core.js:278) but cannot spend them until after at least one fight, and only gets a free 15% patch on a win (campaign3d.js:80). The model flags this as an attrition quit risk.

## 3. Battle pay is far below the hull prices the shipyard shows
- Citation: campaign_run.js:237
- Quote: "let credits=Math.round((25+12*s+3*(cfg.col||0))*kindMult"
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: A sector-1 column-0 battle pays 25 credits, while a Penitent costs 200 (data.js:63) and a Cathedral 340 (data.js:65). Even several wins leave the mid and heavy hulls unbuyable, so the shipyard reads as a tease rather than a decision.

## 4. The help screen lies about unlocks, which damages trust immediately
- Citation: campaign_meta.js:143
- Quote: "every faction, admiral and ship is available from the start."
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: Admirals have cost:30/45/80 (data.js:203-205), and META.admirals starts with only {vex:true} (core.js:46). A new player reads Help, then sees locked admirals on the next screen.

## 5. Boarding is a high-friction subsystem with asymmetric rules
- Citation: battle.js:652
- Quote: "u.crew<Math.max(4,u.crewMax*.4)||u.weapons.some(w=>w.fired)"
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: Boarding needs an adjacent enemy, 40% crew, and unfired weapons; capture odds depend on crew multipliers; enemy boarders can never capture player ships (battle.js:675). Most new players will ignore it or misread it as a reliable capture tool, making it a dead or confusing system.

## 6. Command is "ready" in round 1 but deliberately weak, so waiting is a hidden trap
- Citation: battle.js:828
- Quote: "return Math.max(0,Math.min(2,B.round-1+bonus+lost-(heatOn('h_cmd')?1:0)));"
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: Tier 0 is available in round 1, full power only from round 3, and losing a ship charges it (battle.js:828). The UI shows "Command" with its charge pips; a new player can burn it immediately for a fraction of its power, or hold until the fight ends.

## 7. Six-round objective timers decide fights before the player understands them
- Citation: battle.js:19
- Quote: "const ENC_ROUNDS=6;"
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: A Hunt flagship jumps out after round 6 (battle.js:761), and Hold the Station is won or lost at round 6 (battle.js:779). A slow, armored starting fleet can lose an objective to a timer while the player is still learning arcs and movement.

## 8. Patron offers can include another patron's boon, breaking the map's promise
- Citation: core.js:150
- Quote: "BOONS[id].p!==p"
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: rollBoonOffer(p) fills short offers from other patrons watching the run, while map badges say "Boon of Kharon" (campaign_run.js:20). A new player chooses a node for a patron and can receive an off-patron boon, which confuses the reward loop.

## 9. The first battles can roll objective types the tutorial has not taught yet
- Citation: core.js:216
- Quote: "type = x<.48?'battle':x<.61?'elite':x<.78?'event':x<.9?'shipyard':'drydock';"
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: Special encounters are forced into every column after the first (core.js:235), but the objective tutorial tip is only one of eight sequential tips (ui3d.js:630). A new player can hit Hunt, Intercept, or Breakthrough before the tip appears.

## 10. One bad fight feels run-ending because reinforcement is thin
- Citation: campaign3d.js:51
- Quote: "if(RUN.fleet.length<=1&&(RUN.reinf||0)<RUN.sector){ RUN.reinf=RUN.sector;"
- Mark: OBSERVED, with INFERRED impact
- Model's reasoning: Reinforcement only arrives when the fleet is down to one ship, once per sector. Starting fleets are 2 to 4 ships (data.js:202-205), and losing the last one ends the run (campaign3d.js:88), so losing two ships leaves almost no recovery path and the first bad fight can be the quit point.

## Not checked
"Not checked: I did not examine scene3d.js, ships3d.js, fx3d.js, sfx_data.js, sfx.js, gfx3d.js, vfx3d.js, wfx3d.js, perf3d.js, main3d.js, meshopt3d.js, head.html, tbot3.js, or the external Python scripts softlock.py, step2test.py, striptap.py, cmdui.py, yardcheck.py, healtest.py, bosscheck.py. I did not play the game or measure session length; all pacing claims are reasoning from the listed costs, odds, timers, and flows."
