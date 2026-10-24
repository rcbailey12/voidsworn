# DeepSeek Council, Lens 2: Engineer

Extracted by Rey from the raw DeepSeek transcript (contrib/deepseek/council_audit.txt). Claims are DeepSeek's, unverified, reproduced for Opus to judge. Quotes are verbatim from the transcript.

Source: Pack A chat, Lens 2 (Engineer). The model's final answer contained 11 findings plus a restructure order; all are reproduced here in the model's order.

## 1. The whole game is one concatenated global script; there are no modules, imports, or exports
- Citation: build.py:8
- Quote: "''.join(open(f).read()+'\n' for f in ['meshopt3d.js','data.js','core.js','battle.js',"
- Mark: OBSERVED
- Model's reasoning: Eighteen files are pasted into one script tag at build.py:17. Every top-level const, let, and function is a global; name collisions are resolved by load order or become a parse error. The model says to restructure this first (ES modules or IIFE namespaces plus a real bundler), because until then every new feature is a global-scope negotiation.

## 2. Features are added by reassigning globals; load order is the real dependency graph
- Citations: campaign3d.js:10 and campaign3d.js:99
- Quotes: "show=function(html){ showApp(); appEl.classList.remove('see3d'); _show(html);" and "const _newShip=newShip; newShip=function(t,vet){ const sh=_newShip(t,vet);"
- Mark: OBSERVED
- Model's reasoning: mapScreen, titleScreen, show, and newShip are all wrapped by reassignment, each capturing the previous value. This only works because build.py:8 loads campaign_meta.js, campaign_run.js and ui3d.js before campaign3d.js; a reorder, a second wrapper, or a call during load silently breaks. The model recommends explicit hooks or events, or an extension point registered by name.

## 3. One mutable B/RUN plus fire-and-forget async, defended by ad-hoc epoch and stall guards
- Citations: battle.js:339, ui3d.js:50, ui3d.js:579
- Quotes: "startSideTurn('player');" (not awaited at battle start), "if(B.alt) startSideTurn('enemy');" (not awaited in prep), "const d1=startSideTurn('player'), d2=B.over?null:startSideTurn('enemy'); if(d1) await d1;"
- Mark: OBSERVED
- Model's reasoning: startSideTurn returns a promise for tick deaths (battle.js:379), but several call sites drop it, and nextRound starts both sides before awaiting either. liveFrom, inThisBattle, B.epoch and stallGuard exist only because a single global B cannot isolate a battle. The model recommends making battle state an object passed through the turn engine and making every startSideTurn awaited.

## 4. Two independent stat pipelines: makeUnit for enemies, derive for player ships
- Citations: battle.js:101 and core.js:168
- Quotes: "s={maxHp:Math.round(t.hp*sc*(opts.elite?1.1:1)), shMax:Math.round(t.sh*sc), regen:Math.round(t.rg*sc), armor:t.ar," versus "const maxHp=Math.round(t.hp*mm*(1+(fx.hpPct||0)));"
- Mark: OBSERVED
- Model's reasoning: Adding a stat (armor pierce, regen, a new module fx) requires editing both paths or enemies and players diverge. The model calls this the most likely silent balance bug as features accrue.

## 5. The simulator carries its own copy of the hand-built fleets
- Citation: sim3d.js:49
- Quote: "voidsworn:{sk:['cathedral','penitent','reliquary','harrow','warden','warden'],fl:["
- Mark: OBSERVED
- Model's reasoning: The entry duplicates ui3d.js:26 verbatim. Change a skirmish fleet in ui3d.js and every balance sim still measures the old composition. The model says FLEET_LISTS belongs in data.js (or a shared module) imported by both.

## 6. COMMANDS in battle.js is a dead duplicate of the admiral cmd objects
- Citation: battle.js:822
- Quote: "const COMMANDS={vex:{id:'barrage',n:'Fire for effect',d:'Every ship fires a free volley"
- Mark: OBSERVED
- Model's reasoning: data.js:209-212 assigns .cmd to vex, malek, ashgrove and thale, and battle.js:844 prefers a.cmd||COMMANDS[id], so COMMANDS is unreachable for every entry it defines. Editing it looks like a balance change but does nothing.

## 7. The build-time static check and the smoke-time static check disagree, and both are weaker than they look
- Citations: build.py:11 and smoke.py:6
- Quotes: "re.finditer(r'^(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(',js,re.M)" and "FILES=['data.js','core.js','battle.js','scene3d.js','ships3d.js','fx3d.js','sfx_data.js',"
- Mark: OBSERVED
- Model's reasoning: The build regex catches only plain function declarations, while smoke.py omits meshopt3d.js, which build.py:8 includes. smoke.py:15 scans const|let|var|class but over a different file set, so duplicate arrow-function bindings or a collision in meshopt3d.js pass both checks until runtime.

## 8. What is tested is not what ships: the build selects a different Babylon source by mode
- Citation: build.py:3
- Quote: "src='node_modules/babylonjs/babylon.js' if mode=='test' else 'https://cdnjs..."
- Mark: OBSERVED
- Model's reasoning: smoke.py and sim3d.js exercise the local node_modules Babylon; voidsworn-3d.html loads the CDN copy. A CDN version bump or a stale local copy is invisible to the test suite.

## 9. sim3d.js reimplements the presentation layer and a player AI, so it will drift from the game it is meant to test
- Citations: sim3d.js:3, sim3d.js:5, sim3d.js:63
- Quotes: "eval(['data.js','core.js','battle.js'].map(f=>fs.readFileSync(f,'utf8')).join('\n')+", "async function animMove(u,q,r,f){ u.q=q; u.r=r; u.facing=f;", "async function botUnit(u){"
- Mark: OBSERVED
- Model's reasoning: The file is followed by hand-written stubs and a hand-written player bot. The stubs must mirror real signatures, and botUnit is a second player AI; every AI or fx-signature change must be mirrored here or the sim measures a different game.

## 10. smoke.py asserts exact literal UI strings and shells out to seven scripts not present in the pack
- Citations: smoke.py:77 and smoke.py:68
- Quotes: "check('frame error does not stop rendering','rendering continued = True | error reports = 1' in s2," and "subprocess.run(['python3',os.path.join(os.path.dirname(os.path.abspath(__file__)),'softlock.py'),"
- Mark: OBSERVED
- Model's reasoning: A wording change or a refactor of any of softlock.py, step2test.py, striptap.py, cmdui.py, yardcheck.py, healtest.py, bosscheck.py (none in the pack) silently fails or silently passes. The model calls this the test suite most likely to rot first.

## 11. stallGuard converts an action exception into a normal resolution
- Citation: battle.js:818
- Quote: "return Promise.race([Promise.resolve(p).catch(e=>{ try{ if(typeof tel==='function') tel('action_error',"
- Mark: OBSERVED
- Model's reasoning: If the guarded action rejects, the catch logs telemetry and resolves undefined; Promise.race therefore resolves undefined, and callers such as swarmPhase (battle.js:900) only compare against 'stall'. A thrown error in a move, shot, or ability is silently treated as success, which hides real failures from both the player and the test net as features add async paths.

## The model's restructure order
"Restructure first, in this order: (a) replace the concatenated globals with ES modules and a bundler so name and load-order problems become compile errors; (b) replace show/mapScreen/newShip reassignment with named hooks; (c) move battle state out of the global B and make startSideTurn/endActivation/nextRound fully awaited; (d) collapse makeUnit and derive into one stat function; (e) move FLEET_LISTS and COMMANDS into data.js and delete the duplicates; (f) unify the build and smoke static checks over the same file list; (g) make the test build load the same Babylon version as the shipped build."

## Not checked
"Not checked: scene3d.js, ships3d.js, fx3d.js, sfx_data.js, sfx.js, gfx3d.js, vfx3d.js, wfx3d.js, perf3d.js, main3d.js, meshopt3d.js, head.html, tbot3.js, and the external Python scripts smoke.py invokes (softlock.py, step2test.py, striptap.py, cmdui.py, yardcheck.py, healtest.py, bosscheck.py) are not in the pack. I did not execute build.py, smoke.py, sim3d.js, or any browser path; runtime performance claims are from reading core.js:136,166 (fleetFxList rebuilt inside every derive), not measurement."
