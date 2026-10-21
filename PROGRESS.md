# Voidsworn 3D: fidelity pass progress
Live artifact: https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH
Working dir: /home/claude/v3d (git); source backup: /mnt/user-data/outputs/voidsworn/src

## Status
- [x] Last published build: Veteran AI, mobile map, onboarding (smoke passed)
- [~] Interrupted turn added (unverified, committed as checkpoint): bevels, parallax plating, decals/emblems,
      scorch damage, section-down fx, faction materials (clearcoat/iridescence/subsurface), fireball/beam textures,
      asteroid belt, distant traffic, colour grading, god rays, TAA
- [x] Verify headless ship build (ntest): all 30 hulls OK; bevels limited to structural blocks (battleship 187k verts)
- [x] Browser verified: screenshots saved; fixed god-rays WebGL warning (0 warnings now)
- [ ] Smoke test, publish
- [ ] Remaining from plan: shield ripple shader, heat distortion, baked sky cubemap, living planets, DoF action cam, turret tracking
- [x] Found invisible-hull bug: leak fix disposed shared BRDF lookup texture; fixed + committed
- [x] Attrition fix: enemy fleets scale to player's damage-weighted strength; garrison reinforcement at 1 ship (commit 65b8da9)
- [x] P-key perf readout (fps, draws, verts, errors)
- [x] PREVIEW published (fidelity pass + fixes): https://claude.ai/artifact/SsYAN6xuWhpSo86FjWzX57  (main game untouched)
- [ ] Verify preview on Ryan's GPU via Claude in Chrome (screenshots, perf readout)
- [ ] Chain sim old vs new (chain_old.log / chain_new.log)
- [x] Caps lowered (commit above); chain_new2.log pending
- [x] Found via Ryan's GPU: close-ups froze renderer; disabled parallax occlusion (kept plain parallax). Preview rebuilt.
- [x] Elite cap .85x; chain sim before it: 0/24 clears, deaths mostly elite@2 (12) and boss (5)
- [x] Ryan confirmed preview smooth + hulls visible. PROMOTED to main after smoke passed (fixed VLS watcher crash found by smoke)
## Next (small steps, preview first)
- [ ] Small texture creep: +1 texture per battle (80,81,82) since graphics pass
- [ ] Re-sim campaign chain with elite cap .85
- [ ] Shield ripple shader, heat distortion, living planets, action-cam depth of field
- [x] Post-victory 15% patch; chain sim w/ economy running (chain_econ.log)
- [x] Texture creep fixed (orphaned rockMaps ORM)
## Travel week (no home PC): phone first
- [x] Phone pass committed: auto-detect, medium default, half-res textures, 40% fewer greebles, 3v3 title showcase, ~30/15 fps battery saver
- [x] Boss hull scales with player strength (min 55%); econ chain sim before: 1/24 clears, boss killed 10/24
- [x] Phone test passed: mobile+medium detected, 3v3 showcase, 412x915 render, 32px node tap -> battle -> win -> map, 0 errors
- [ ] Texture cache (IndexedDB), smoke, publish
- [ ] Architecture brief (Claude Doc) for ChatGPT/Gemini review
- [ ] Path B groundwork (repo layout, build tooling) in sandbox

## Week of Oct 3: Ryan traveling (phone only, no 5080 testing)
- [x] Phone pass + boss scaling (f39b4e5); IndexedDB texture cache with 3s deadline (cec4a96, 1b87842); phone flow test passed
- [ ] Smoke test -> publish to PREVIEW -> Ryan tests on Pixel -> promote
- [ ] Re-run economy chain sim with boss scaling (last run: 1/24 clears, boss@6 10 deaths)
- [ ] Architecture brief for ChatGPT/Gemini; path B groundwork (sandbox only)
Paused until back on PC: DoF/heat distortion, promoting shield-ripple preview, path B verification.
Live main: https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH | Preview: https://claude.ai/artifact/SsYAN6xuWhpSo86FjWzX57
## Debug log: intermittent boot stall in sandbox tests (cache work NOT published)
- Sandbox pauses between replies: background jobs only progress while a reply is active. Run tests in-reply, max ~2 waits.
- Bisect: pre-cache f39b4e5 booted in 27s, current HEAD in 23s (no errors) -> no deterministic hang.
- cache_test/cache_test2/cache_diag/hangcatch stalled with no output (even goto/commit), so possibly harness/headless flakiness under load, OR a random-combination hang in title showcase.
- Ruled out: fire loop (addFire always pushes), dist loops are bounded.
- Next: single headless boot with stdout per step + 'Runtime.evaluate' via CDP w/ timeout; or test repeatable seeds for showcase factions/maps.
- [x] Published HEAD (phone pass + cache, no demo) to PREVIEW for Ryan's Pixel test
- [x] Ryan Pixel feedback: action strip in collapsed panel; camera follow + action cam default OFF (settings). Commit above.
- [x] Phone test passed: strip works (End activation, Center), camera stays put, loading veil failsafe. Published to PREVIEW (ae6bcaa).
- [x] Plain-language strip + help + abilities; everything unlocked by default; strip wraps (preview)
- [x] Architecture brief doc: https://claude.ai/artifact/C4fzieckCd2HY9fH8jpaM8
- [x] Path B phase 1 repo: /mnt/user-data/outputs/voidsworn-web.zip (build + sims verified in sandbox; GPU smoke test runs on Ryan's PC)
## After independent review (Muse + Gemini)
- [x] Decision record added to the brief doc (top section)
- [x] Fuzz 40 battles: 0 exceptions
- [x] Slow first boot found + fixed: cache WebP encoding was forced into boot; now one per idle period (title 29s, page responsive after)
- [ ] Promote phone batch to main; republish preview with db+user so Ryan's preview fights are recorded
- [ ] Rework repo to revised phase 1: Vite, ES modules, strict TS on rules engine, telemetry + save backend
- [x] Smoke 10/10 (boot 28s). PROMOTED phone batch to MAIN (tag promoted-phone-batch)
- [x] Preview republished with db+user: preview fights now recorded server-side
- [ ] NEXT: repo rework for revised phase 1 (Vite, ES modules, strict TS rules engine, telemetry+save backend)
## Telemetry review (Oct 5): first sector-1 boss kill on Pixel (cathedral+warden start, bought ascendant); Resolve unspent (5/5) nearly every fight; tips off on both devices; one 11-round phone fight took 21 min; lost run: hold-retreat then boss with no rest.
- Recommended: guaranteed rest node before boss; automatic Resolve "Rally"; profile AI time on phone + Quick enemy turns; trim tips to 3.
## Repo phase 1
- [x] Workspace + strict TS base; packages/core/src/data.ts: 0 type errors (commit in voidsworn-web)
- [ ] Extract rules engine (battle.js) into core with render hooks (commands in, events out)
- [ ] Storage adapters: artifact DB / localStorage / HTTP (Vercel function + hosted DB)
## Ryan feedback (Oct 5): freeze after a few rounds persisting across fights; boarding captured own ship; tap enemy -> camera moves, no reason why not firing; Resolve duplicative -> Admiral's Command approved; rest stop approved; audit unused capabilities (broadside vs prow)
- [x] FOUND + FIXED leak: hulk fires never disposed between battles (+ permanent wrecks burned forever), ship fires/vents only stopped not disposed. Leak check: 79 particle systems after one battle. (needs re-verify)
- [x] Boarding: no counter-capture rule existed; AI captured the crew-thinned ship next. Added capture % on Board button + boarders 'repel' (defense x1.5) until next round
- [x] Why-can't-fire reasons (braced/spent/range/arc/LOS), keeps selection; 2nd tap inspects
- [x] Rest stop before every boss: mapcheck 300 sectors -> 902/902 rest nodes, 0 columns without a fight
- [ ] Admiral's Command (replace Resolve spends)
- [ ] Capability audit + richer telemetry (weapons by arc, abilities, orders) + facing helper
- [ ] Carriers confusing on phone: audit launch + squadron control (Ryan likes carriers)
- [x] Smoke 11/11 incl. new effect check (15 particle systems after a battle, was 79). PUBLISHED to main (tag promoted-step1)
## Next (Ryan, Oct 5)
- [x] Squadron swarm built: exact in-reach (reachable hex + legal weapon), bombers->ships, fighters->craft first, 8-hex leash, fly home if stranded; flak automatic point defense only; one-tap launch. Audit 30 battles: 0 illegal, 0 role violations, 0 idle-with-target, 4/276 stranded not closing (boxed in). NOT yet smoke-tested/published
- [ ] Campaign faction choice: all six playable (start fleets, shipyard roster, enemy pools exclude own faction)
- [ ] Admiral's Command; facing helper; usage telemetry
- [x] Battle length unchanged with swarm: fuzz60 10.4 rounds, matrix144 9.5 (earlier 13.2 was noise)
- [~] Smoke on swarm build: 4/10 so far; skirmish round step slow (watch sqPlan cost in browser)
- [x] Recovered interrupted turn: commit c417492 (swarm try/finally + timing logs) intact
- [x] Swarm planning cost in browser: 0-1 ms per squadron (not the bottleneck)
- [x] Round timing probe (software GPU): AI activations ~20 s, test-bot activation up to 75 s, round start 6 s -> smoke's skirmish step is slow, not hung; game loops guard flak via canFire
- [ ] NEXT: full smoke with patience (don't kill early), then preview publish for Ryan to try carriers
- [!] Smoke on swarm build: 10/11. FAIL effect build-up: 183 particle systems after battle (prev build 15). New leak, likely squadron views (engine trails/extras of launched or destroyed squadrons, or flak intercept fx) not disposed across battles. DO NOT PUBLISH until fixed.
- Note: textures steady at 121 across battles (higher baseline than before, but no growth)
- [~] Leak hunt: squadron battle + switch -> only dust (no squadron leak). Campaign path census: title stack21, battle stack4, after kills sp12 bs12 hf4 (transient/expected). 183 must appear at continue -> rewards -> map (fleet showcase). NEXT: extend psprobe2 through c3continue + takeLoot + map, list names.
- [~] KEY LEAD: after a campaign battle, on the map: frames drawn in 3s = 0 (via engine.frameId), 0 errors, only one runRenderLoop and no stopRenderLoop in sources. Effects can't finish without frames (explains 'build-up'); fleet showcase builds fine via manual call. Fresh run map renders fine.
  NEXT: verify frame counting via scene.onAfterRenderObservable + engine.activeRenderLoops; if truly stalled, find what starves rendering after finishBattle (likely related to Ryan's freeze).
- [x] Recovered commit b96b47d: "0 frames" was sandbox frame time (seconds per frame), not a stall. Fixed fleet showcase missing after battle (show() wrapper covers every map route). Smoke now counts persistent effects only (transient sparks need frames to expire).
- [~] Smoke on b96b47d running: 4/11 so far (skirmish round step ~10 min on software GPU). Resume waiting next reply; then publish carriers to PREVIEW.
- [x] Smoke 11/11 on b96b47d (2 persistent effects after battle). PUBLISHED carriers swarm + auto flak + one-tap launch + fleet showcase fix to PREVIEW (tag preview-carriers). Main untouched.
- [ ] NEXT: campaign faction choice (all six); then Admiral's Command, facing helper, usage telemetry
- [!] Ryan: preview froze twice (bottom panel unresponsive, couldn't move carrier). Repro with clean taps: no freeze, busy false, no overlay. Telemetry: no errors; frozen battles never logged an end.
- [x] Fix (3dab084): touch tracking self-heals (fresh primary touch clears stale fingers; window-level pointerup/cancel cleanup); busy watchdog (20s); Settings > Report a problem (snapshot to telemetry + save). Verified: stuck finger planted -> real tap still selects. Published to PREVIEW.
- [!] Froze again on a carrier turn (screenshot: turn label gone, Pass/Retreat greyed -> mid-sequence await never finished, not touch).
- [x] Stall guards (squadron 15s, player 25s, enemy 30s) + auto 'stall' telemetry saved immediately + toast. Verified: hung squadron action -> round completes after ~15s, report names the wing. Published to PREVIEW. NEXT: read Ryan's stall reports to find the real hang and fix its root cause.
- [x] Freeze analysis: screenshot = side stuck 'enemy' + busy (endActivation ignores Done unless side==='player' && !busy). Static audit of squadron/carrier paths (projectiles, animWeapon, fireWeapon intercepts, tween, moveUnit, launch): no self-hanging wait found.
- [x] Gap found: caught errors were only saved at battle end, so abandoned frozen battles lost them. Now errors/action errors/stalls persist immediately (9ac4bef). Published to PREVIEW.
- [x] Faction choice + per-run shuffled enemies (Ryan asked: vary opponents): RUN.fac, RUN.foes (5 others shuffled; sectors 1-3 use foes[0..2]); rival raiders ~27% of ordinary fights from foes[3..4]; shipyards/starts via equivHull (closest CP, carriers->carriers, ties to stronger). factioncheck: 0 own-faction, 0 repeats; starts 5-8 vs 6-7 CP. NOT yet browser-tested/published.
- [ ] NEXT: browser test new-run faction picker + non-Voidsworn campaign battle, smoke, preview publish; then Admiral's Command, facing helper, usage telemetry, rules-engine extraction
- [x] Phone browser test of faction flow: 6 buttons, Chorus start (razorfiend+spitter+drone), foes shuffled (corsair/deathless/ithar + rivals voidsworn/hegemony), first fight Chorus vs Hegemony (rival), win -> map, run_start telemetry, 0 errors. Map header now names rival factions.
- [x] Smoke 11/11 (now 3v3 skirmish step so it fits one reply; sandbox timeout killed the long version while paused). Stall guards fired in sandbox only (seconds-long frames). PUBLISHED factions + shuffled enemies + carriers + stall guards to PREVIEW (tag preview-factions).
- [x] Admiral's Command built (commit above): Vex Fire for effect (free volley, weapons state restored), Malek Hunter's salvo (torps reload, +30% dmg this round), Ashgrove Scramble all wings (launch + immediate swarm strike, squadrons +50%), Thale Iron wall (shields full, hull dmg x0.6 this round). Meter = Resolve renamed 'Command' (5 to use). Aim free; Shield boost removed; AI no meter spends. Fuzz30 clean. UNVERIFIED effects.
- [ ] NEXT: cmdcheck sim per admiral + phone strip check + smoke + preview; then facing helper, usage telemetry, rules-engine extraction
- [!] Freeze report #1 (Oct 6): side player, busy false, activeUnit set, no overlay/fingers -> taps never reached ACT. Fixes: command dispatch runs even if SFX.click throws; report now captures element under Done/End/board, last 10 taps, last 8 commands, panel render rate (bcdb6bd).
- [x] 24 faction admirals (4/faction) with own names, doctrines (engine fx keys), starts from own roster (5-8 CP), named Command moves; carrier doctrines only where carriers exist (not Deathless). New commands: restore (25% hull + sections), surge (+2 mp, +1 turn, -20 enemy accuracy). Admiral screen filtered by faction. Validated data; fuzz20 clean.
- [ ] NEXT: cmdcheck sim (all 6 commands), phone check admiral screen + Command button, smoke, publish preview
- [x] Faction ship names + captains (Ryan asked): CAPTAINS per faction (ranks, name styles), FNAMES + MORE_SHIP_NAMES (20/faction), rankName() at all 6 display sites, prizes keep origin faction naming, no repeated first names in fleet. namecheck sim verified.
- [ ] NEXT: cmdcheck sim (6 commands), phone check of admiral screen + Command button + names, smoke, publish PREVIEW
- [x] cmdcheck: all 6 Command moves PASS by effect (barrage dmg + weapons kept; hunt x1.30; scramble launch+strike; iron x0.60; restore +25%; surge +2 mp, -20 hit). Scramble wings can die to flak before landing (intended counter).
- [x] Smoke 11/11 (run inside one reply; sandbox kills background jobs across long pauses). PUBLISHED to PREVIEW (tag preview-admirals): faction admirals + Command + faction names + freeze fixes + richer report.
- [x] Phone check: Ithar admirals listed, strip shows 'Starling flight (5/5)', top 'Command', Ithar names. Fixed: selected faction unreadable, Command button not prominent (gold now). Published to PREVIEW.
- [x] Facing helper (02b596b): per-hex best facing by guns bearing (cheapest tie), preview line 'From here: N of M ready guns can fire (on X)'. UNVERIFIED in browser.
- [x] Facing helper verified: 13 ms (software GPU, battleship), 0 wrong choices over 9 hexes.
- [x] Usage telemetry in battle_end: fire by arc, aim, abilities, orders, Command, moves, can't-fire reasons; usagecheck verified.
- [ ] NEXT: smoke + PREVIEW publish (facing helper + telemetry); then rules-engine extraction
- [!] Smoke 10/11 on telemetry build: FAIL 'telemetry recorded' - battle_end missing (run_start,node,battle_start present; map reached). tel() has no size cap. Probe without tapping Continue: finishBattle not yet called (expected). NEXT: probe tapping c3continue with error capture; suspect finishBattle path/B.usage. DO NOT publish until fixed.
- [~] battle_end telemetry: isolated probe (campaign battle first in session, tap Continue) -> battle_end recorded, 0 errors. Full smoke (after skirmish + 3 leak battles) -> battle_end missing twice, with busy_watchdog/stall logged earlier. ACT.c3continue = finishBattle(B.over) (no busy gate). NEXT: instrument smoke (wrap finishBattle: called? threw? tel tail) to find the session-state cause.
- [x] Oct 10: sandbox reset wiped /home/claude/v3d + git history. Restored all 15 files from backup (verified latest markers), reinstalled babylonjs, rewrote tbot3.js (now backed up). New git history.
- [x] ROOT CAUSE of missing battle_end: turn logic from an earlier battle (nextRound/aiStep chains, stall-skipped hung actions) kept running into the next battle. Fix: aiStep/nextRound/endBattleFlow/swarmPhase capture their battle and stop when replaced; fireWeapon/moveUnit/useAbility refuse ships not in current battle. stalecheck: old ship can't fire/damage/move/ability. Endcard names real enemy faction (was hardcoded Hegemony). Smoke ignores blocked font loads.
- [x] Smoke 11/11 on stale-guard build. PUBLISHED to PREVIEW (version 16, tag preview-stale-guard): stale-battle fix, facing helper, usage telemetry, endcard faction. db+user capabilities carried forward. Main game still at promoted-step1 (older).
- [ ] NEXT: Ryan plays preview (carriers, factions, admirals, Command, facing helper). Then promote to main; then rules-engine extraction (voidsworn-web repo).
- [x] Oct 10: PROMOTED preview-stale-guard build to MAIN (version 14). Saves/db carried forward. Live main had only superseded code (diffed).
- [x] Oct 10: audit bundle built at outputs/voidsworn-audit (prompt, context brief, source/tools concatenated, telemetry, prior reviews, 5 screenshots, runnable zip; sims verified from zip)
## Audit round (Oct 10): Muse ("Rey"), Claude, Gemini
- Gemini audit DISCARDED: 34 of 35 cited functions don't exist; ran nothing.
- [x] CRITICAL (Claude audit, verified by me): battle ending at round start (relay 3/3 in objectiveTick, squadron kill in swarmPhase) never called endBattleFlow -> soft-lock = Ryan's screenshot 4. Fix f5fefa0: checkEnd owns the end (scheduleBattleEnd), nextRound/endTurn stop when over, strip hides, label 'Battle over'. Real-flow softlock.py: BEFORE both SOFT-LOCK, AFTER both END CARD. Added to smoke (now 14 checks) + smoke fails on error/action_error. PUBLISHED to main (v15) and preview (v17).
- Settled: preview/main saves are separate (separate DB docs); 14/16 'full meter' battles predate Admiral's Command (screenshots show Resolve UI).
- NEXT (consensus order): per-event telemetry + build id + bootMs + Copy report; frame try/catch + projectile promises settle; guards cancel (visibility pause, epoch, act pins B, progress watchdog); strip direct input; called shots + emergency shields cut; Command once-per-battle; Orders cut except Brace; capture formula unify; phone HUD pass; phone render budget (778 draws/2.6M verts, gridTex); bot full toolkit; content freeze.
- [x] Ryan: no escort missions; keep Breakthrough; encounter list = Ambush, Hold the station, Hunt, Intercept, Breakthrough (+ rout/flagship/relay). Command: ready round 2, once per battle, sole use of meter.
- [x] Step 1 telemetry verified (reload mid-battle keeps battle_start; bootMs 13.8s SwiftShader phone; Copy report JSON), smoke 14/14, PUBLISHED main v16 / preview v18 (tag step1-telemetry).
- [x] Step 2 freeze causes (efab7e3): frameError try/catch (render loop + per-frame body), projectile/torpedo promises settle in finally and on dispose, stallGuard counts visible time only + bumps B.epoch, liveFrom() checks after awaits in fireWeapon/moveUnit/aiUnit/sqAct/player volley, act() pins B, progress-aware busy watchdog. step2test: frame error -> rendering continues + 1 report; hidden 40s mid enemy turn -> 0 stalls, completes; hung volley -> abandoned, never lands.
- [x] Step 3 (072a3b9): strip buttons call ACT.endTurn/ram/board/brace/center directly; ACT.key removed; striptap verified with real taps.
- [x] Smoke now 18 checks (17 pass + frame check fixed for slow renderer). PUBLISHED main + preview (tag step3-direct-input).
- [ ] NEXT step 4: Command once/battle from round 2 (sole meter use); cut called shots, emergency shields, Orders except Brace, unlock shop/renown currency; capture formula unify.
- [x] Step 4 (458de8f): Command once/battle from round 2 (sole use; top bar Command from round 2/ready/used); cut called shots, emergency shields, Orders except Brace, legacy shop + renown (Best: sector record); exact capture model (capcheck: <=0.3 pt vs 10k rolls); tooltip + AI use real %; Vorn/Anuket torpedo doctrines fixed (Hegemony/Chorus/Deathless have NO torpedo ships); cmdcheck now non-vacuous + checks round-1 lock and single use. cmdui phone check. Smoke 19/19. PUBLISHED both (tag step4-command).
- [!] Flake watch: battle_end missing once in smoke after a skirmish stall; 3 traced reruns fine; trace kept in smoke.
- [ ] NEXT step 5: battle variety part 1 (readable terrain + legend, board shapes, encounters: Ambush, Hold the station, Hunt, Intercept, Breakthrough). No escort.

## Step 5: battle variety part 1 (Oct 10)
- [x] 5a readable terrain: TERRAIN_INFO table, per-type hex tints, legend chip (tap to expand), tap-to-explain, move preview names the terrain
- [x] Board shapes: open, corridor (rows cut), split lanes (rock wall with 2 gaps), ring (rock core), dense field, close quarters (small fleets); connectivity BFS with retry
- [x] Encounters: Ambush, Hold the station (5 integrity, batteries, 6 rounds), Hunt (flagship jumps after round 6), Intercept (transports to the far edge, need total-1), Breakthrough (half the fleet off the far edge; enemies ahead and behind), Relay, Decapitation (3+ ships only)
- [x] Failure modes: partial win (half pay) for Hunt/Intercept; withdrawal (retreat) for station/breakthrough
- [x] Campaign: encounters rolled per node at sector gen (lazy for old saves), labels on the map + preview cards; first fight is always an Engagement; bosses unchanged
- [x] Bug: act() post-action refresh had been swallowed by a comment (B.sel dead-clear, updateReach, bRefresh never ran)
- [x] Bug: systemDamage on a weapon-less ship crashed
- [x] Sims: fuzz covers all encounters/shapes (0 exceptions); per-encounter bot win rates ~50-60%; chain sim bot clears ~0-3/40 on baseline AND new build (bot weakness, step 8)
- [x] Verified (enccheck 10/10, exittest, mapprev, smoke 20/20, no stalls). PUBLISHED preview v21 + main v19, build 20261010-2354-7716e52, tag step5-variety
## Step 6: phone HUD pass (Oct 11)
- [x] 44px tap targets on touch (hudaudit.py: 0 small targets in battle), keyboard/mouse hints hidden on touch, touchWords() (Tap again to fire, Tap elsewhere to cancel)
- [x] Phone tooltip docked above the bottom panel; legend chip + tip card stack under the wrapping top bar (stackTop)
- [x] Enemy diamond marker on plates; flashes reduced by default on phones until the player picks (opts.fxSet); toasts last by length
- [x] Smoke 20/20. PUBLISHED preview v22 + main v20, build 20261011-0705-a00519c, tag step6-phone-hud
## Step 7: phone render budget (Oct 11)
- [x] Live ships render from a merged per-material copy; fore/aft split copy swapped in at death (break-apart intact); plumes merged (nozzle pivot); one flare on phones; emblems merged
- [x] Graveyard wrecks baked per material; no distant traffic on phones; hull out of glow at medium; 1536 grid texture + 1024 shadow map on phones
- [x] 16-ship battle: 822-992 -> ~407 draw calls, 1.48M -> 0.69M active verts; 6-ship battle 248 draw calls (renderbudget.py SMALL=1)
- [x] Smoke 20/20. PUBLISHED preview v23 + main v21, build 20261011-0806-7cbeea9, tag step7-render-budget
## Step 8: variety part 2 (Oct 11)
- [x] Faction biomes: sky nebula re-tinted + reseeded per enemy faction; 55% of fights on faction home ground (FAC_MAP)
- [x] Mid-battle events (campaign only, 45%, never bosses, warned a round ahead): enemy reinforcements, friendly garrison ship (leaves after), solar flare (all shields 0 for a round). evcheck 3/3, evtest PASSED
- [x] Boss arenas: home map + ring/dense/open
- [x] Sim bot uses Command and Brace (BOTCMD/BOTBRACE=0 to compare): chain 4/40 vs 3/40 without; bot movement is the weak link, so no balance tuning from it yet
- [x] How to play covers encounters and events; touch wording
- [x] Smoke 20/20. PUBLISHED preview v24 + main v22, build 20261011-0824-300e73d, tag step8-variety2
- [x] Plan steps 1-8 complete. Content freeze on new hulls/admirals.
- [ ] Open: balance needs Ryan's real play on the new encounters (telemetry battle_end now carries obj, shape, partial, event)

## Feedback round (Oct 11): "same grid", weak carrier, weak graphics
- Telemetry: Ryan's 3 battles on the new build were all Engagement/lanes (first fight always Engagement + an Engagement node + replay). Fix: every column after the first offers a special fight; no two neighbours share a type (enccount 300/300)
- Carriers: sims in non-alternating mode never let squadrons act after their first move (harness bug, ALT=1 added). Alternating mode: carrier fleets 0-12% -> after fix 68% vs gun fleets 65%. Wings start in flight, launch replaces losses; bomber 28hp/12dmg, spore 26hp/10dmg, fighters 2.2x vs craft, flak 3x; Ithar carrier hangar 3; scramble adds an extra wing past the hangar
- Art direction (Ryan: combine cinematic + holo war table): holo cyan grid lit around the selected ship + board frame; outline arcs/move range; lighter terrain tints; warm key/cool rim, teal-orange curves, stronger bloom/vignette, brighter biomes; portrait phones look up the field from behind your fleet
- Perf: instanced squadron craft, 14 clouds on phones, wreck emblems merged; small fight ~320 draw calls, full ~590, verts <1M
- BUG fixed: stale stall guard bumped the next battle's epoch (stallscope)
- BUG fixed: busy watchdog ignored movement/shots (squadron phases looked idle); stall guards now count game time (4x real-time backstop). Smoke 19/19 with zero stalls
- PUBLISHED preview v25 + main v23, build 20261011-1127-aee5a65, tag art-pass-1

## Oct 11: one link
- Ryan chose a single link. Publish ONLY to main: https://claude.ai/artifact/QZ7pVvYuupUHFZkFGwxsaH (file /mnt/user-data/outputs/voidsworn-3d.html). Preview (SsYAN6xuWhpSo86FjWzX57) DELETED at Ryan's request; local preview file removed
- Faction weapon looks (shells, twin turbolasers, tracers, bio globs, needles, gauss rails). Smoke 19/19, 0 stalls. PUBLISHED main v24, build 20261011-1215-f6b86f3

## Oct 11: Ryan's Ithar run (aelith) fixes
- Boss false win: ascendant (Voidsworn boss) had no boss flag -> bossDown true from the start -> first death ended the fight as a win (and hull unscaled). All faction bosses now flagged in data.js post-process
- Shipyard: non-Voidsworn hulls had no cost/slots ("Buy for NaN", no refits). Default cost round((60*cp+10)/5)*5, slots by cp (1/1/2/2/3)
- Carriers: fighter-only factions (Ithar; player Hegemony) field a bomber/fighter mix (wingKind); enemy Hegemony keeps fighters; two spare wings per hangar slot (enemy cruiser relaunched ~8 fighters/battle into endless dogfights). Ithar carrier vs Hegemony 33% -> ~56-73%, rounds 12.7 -> ~8
- Bosses (bot win %): Voidsworn 25->40 (370hp/32sh), Ithar 100->68 (660hp, turret lance), Hegemony 48, Deathless 43
- Smoke now 20 checks (yardcheck added), 0 stalls. PUBLISHED main v25, build 20261011-1246-faeb2d5

## Oct 11: second Ithar run (lost to Chorus boss, sector 2)
- Ram: base (14+46*size)*(1.2 ram factions), facing shield soaks up to half, capped at 40% of target max hull, recoil .35/.5. Boss ram was ~150-190 (one-shot frigates and carriers)
- Brace: only before the ship has fired (was free at end of every activation; Ryan braced 5x in the boss fight)
- Launch button names the wing kind it launches; carrier panel lists bombers/fighters/spares; strip help explains wings
- Sector 2 Chorus boss vs [i_carrier,warden,i_carrier]: bot 90% both before/after; rams/battle .40 -> .28
- Smoke 20/20, 0 stalls. PUBLISHED main v26, build 20261011-1318-bfb8636
- Adaptive wings: no enemy craft -> all bombers; fighters only when the enemy has carriers/squadrons; bombs 12->10. Carriers vs no-air 93-100%, vs Hegemony air 33-68%. Smoke 20/20. PUBLISHED main v27, build 20261011-1344-b447232

## Oct 11: render freeze (Ryan's report, sector 2 Hold the station, Ithar 2 carriers vs Deathless)
- Every frame threw "Cannot read properties of undefined (reading 'boundingSphere')" in _renderTransparentSorted; game state fine (player turn, not busy) but nothing drew
- Not reproduced in replays. Strongest lead: merged ship/craft templates (perf merge) lacked bounding data; clones copy it. Templates now refreshBoundingInfo at creation
- Safety net: frameError -> healScene() refreshes or hides enabled meshes with missing bounding data / orphaned instances, logs tel 'scene_heal' with mesh names. healtest forces the exact failure; render continues. Smoke now 21 checks
- PUBLISHED main v28, build 20261011-1431-ebcc039. If it recurs, scene_heal telemetry names the mesh

## Oct 11: after Ryan's first victory (Ithar, 3 carriers + warden)
- Blocking terrain: red no-go outline + fill on asteroid/wreck hexes (refreshBlockTint, refreshed when hulks appear); legend red
- Line of sight: hovering an enemy draws a thick gold aim tube if clear, red tube + X on the blocking hex if not; move tooltip lists enemies blocked from that hex (losshot.py)
- Enemy adapts to 2+ player carriers: point defense bolted onto half the escorts (all at 3+), factions with craft fly a fighter screen (1 wing, 2 at 3+); logged; tel adapt. Bomber deaths 21% -> 48% vs 3-carrier fleet, still wins
- Boss fights: ring/open only (no dense), 45% of rocks cleared, flagship deploys mid-board, boss hull ~-11%, burning at half hull always applies (bug: skipped when escorts already dead). Bot rounds 11.7 -> 8.7 (Hegemony s3)
- Victory recap screen with per-ship career stats, standout ship, factions won, next-crusade nudge (recapshot.py); run_end telemetry
- Smoke 21/21, 0 stalls; fuzz 120 clean. PUBLISHED main v29, build 20261011-1555-e91d89f

## Oct 11: Ryan's Hegemony run (reyes, vanguard + 2 dominions) - WON, 12 battles, 0 ships lost, 108 min
- Telemetry: command (scramble) used in round 2 every battle; no brace/aim; adapt fired (fighter screens w1/w2); battles 2-6 rounds; bosses 5-6 rounds
- Spawn lanes: clearSpawns() removes rock/hulk within 2 hexes of player ships (1 for enemy) and along a lane toward the enemy; graveyard wreck visuals filtered. spawncheck: lane blocked 34% -> 15% (remainder all station objectives)
- Command power: tier 0/1/2 at rounds 2/3/4 (CMD_POW); cmdDesc/cmdNext wording; HUD pips; panel shows what waiting adds. cmdcheck passes at CMDROUND 2/3/4
- Duplicate run_end telemetry removed. Smoke 21/21, 0 stalls; fuzz 120 clean. PUBLISHED main v30, build 20261011-1829-dbd4eb9
- Open: run was easy (0 losses with 3 carriers); offered a difficulty step
- Oct 11 evening: Ryan asked for Hades-style input randomness (patrons/boons, flagship aspects, organic maps) and space-opera motion. PUBLISHED update 1 motion as main v31, build 20261011-2012-445206f (from worktree v3d_pub). Update 2 WIP committed.
- Update 2 (patrons): 6 patrons (4 per run), 30 boons + 6 duos, rarities, node payouts shown as sigils on the map, boon offers skip useless boons, 6 flagship aspects (3 offered at run start; flag passes on if the flagship dies), enemy budget two-way from fleetPower (none upward in sector 1, max +30%), random shipyard hulls, telemetry boon_pick/aspect_pick/reward_pick/shop. booncheck 17/17, boonsim, budgetcheck, boonflow.py
- Update 3 (battlefields): ragged edges on every board; new shapes deadstar (black core + accretion disc), rift (violet chasm + bridges), shoals (holes), hourglass, archipelago; establishing camera shot at battle start; AI/squadrons/sim bot approach by path distance (pathField) -> battles shorter on all shapes; dead star excluded from boss fights. shapecheck all combos clean, fuzz clean
- Smoke 21/21 (0 stalls), fuzz 120 clean, booncheck 17/17. PUBLISHED updates 2+3 as main v32, build 20261011-2119-3826b3b

## Oct 11 night: Ryan's Corsair run (Mott, Hive aspect) - lost sector 3 Breakthrough with 2 hulks, 10 battles, 24 min
- He took Juggernaut but rammed 0 times; ram needed a target exactly 2-3 hexes dead ahead with full movement
- Fixes: solid gold move range + outline; ram rule (player: one clear hex + movement to cross; damage x.75/1/1.15 by run-up; AI needs 2+ run-up), red ram lane, red ram-spot rings, hints; boon callouts (boonFx), boon bonuses in attack preview, Fleet boons panel section, battle-start boon toast, victory recap; holes filled with set pieces (asteroid/station/moon/hulk/comet) that block LOS via SOLID; Colossus shape; telemetry boons/ecp/pcp/ramReady
- Smoke 21/21, fuzz clean, booncheck 17/17. PUBLISHED main v33, build 20261011-2229-90628bf

## Oct 12 morning: two runs lost at the sector 1 boss with gun fleets (Hegemony/Kassar, Chorus/Voice); ecp 13 vs pcp 6-7
- bossmatrix (24 starting fleets x 5 bosses): s1 gun fleets 27% vs carriers 64%. Damage breakdown: boss itself ~15-25 dmg; escorts ~145 and boss wings ~90-110; and ENEMY BOARDING CAPTURED 1.4-2.3 PLAYER SHIPS PER BOSS FIGHT (flipped sides)
- Fixes: player ships can't be captured (overrun: crew to 15%, 2 sabotaged systems); boss wings 1/2/3 by sector, spares 0/1/2; escorts deploy back, boss mid-board; BOSS_SCALE [.5,.55,.7], BOSS_DMG [.85,.88,.95]; i_boss 590/40; chorus small hulls buffed
- Result (bot, no boons): s1 gun 87% / carrier 96%; s2 (GROW 11, Mk2) 85/85; s3 (GROW 15, Mk2) 75/78. chain sim clears s1 6/10 (was 1-4/10)
- Smoke 21/21, 0 stalls. PUBLISHED main v34, build 20261012-0803-7f5b866

## Oct 12: full game audit doc (https://claude.ai/code/artifact/765de4dd-0f30-4fb6-a429-c606c0136c43)
- 14 sections: summary, method, faction balance, faction identity, hulls/weapons, carriers, admirals/Commands, boons/relics/modules, enemy AI, run structure, player skill, visuals, controls, 40-item prioritized fix list. 3 charts (faction win rates, hull damage per CP, admiral boss wins).
- New sims on build 20261012-0803: fmatrix 792 battles; bossmatrix s1 n=4 (carrier fleets 68% vs gun 52%; Ithar boss 23%, Corsair boss 83%; Vesh 10%, Voice 20%, Sable 25%); boonsingle 50/boon on penitent+2 harrow+warden vs Hegemony (base 22%; s_arc/s_ion/s_ev/a_aim/asp:admiral 50%; i_brace/s_regen/a_crit/d_inferno/bulwark at base).
- Telemetry (tel5): ordinary fights 38/40 won, bosses 9/12; s1 boss ecp/pcp 2.0 vs 0.6 in battles; 48 Commands: 33 in round 2, 0 at full power; battles mean 5.1 rounds; 0 called shots, 5 broadside shots, 6 rams, 3 boardings in 50 battles; 96 failed fire taps.
- Top quick wins: Command charge/timing, phone Cinematic defaults, filter module offers by kit, Dominion and Spitter retune, AI reload/surge/brace rules.

## Oct 12 midday: v35 (build 20261012-1126-064f594) PUBLISHED main: audit top-ten fixes except #7 enemy intent and #9 two-tap fire/undo (Ryan's call)
- Commands: usable from round 1, full power round 3, losing a ship charges a level; Admiral aspect full power round 2; Full burn text now mentions -20 accuracy; shieldless Iron wall gives +10% instead of shields
- Carriers: wing orders (tap wing, tap enemy = strike / own ship = guard); bombs pierce 1 -> .6; adaptation counts a carrier admiral or Hive flagship as a second carrier; PD added: Marauder flak, Harvester gauss sentries, shuriken anti-craft
- Faction abilities: Hegemony picket evasive / interdictor ion pulse; Corsair raider+marauder overburn, reaver reload; Chorus drone+spitter regrow, razor frenzy; Ithar wisp+blade phase jump (tap a hex within 3), song surge; Deathless scythe+jackal dimensional shift, harvester reanimation beam
- Balance: Dominion 1 wing, hturbo to broadsides + turbo turret; Spitter turret + prow bioplasma; Corsair hull/shield buffs, scatter dmg 5, raider turret autocannon, hulk 170/16; Ithar boss 520; blade 55, wraithcarrier 140; razor 150; harvester 150; harrow 72; Sekhmar/Voice/Vesh fixes
- Difficulty: fixed column budgets [4.2,9.5,14]+col, soft floor only (-25% max), elites x1.05, boss escort .28/.33, guaranteed elite in column before rest stop
- Enemy AI: reload/surge-by-facing/brace-by-expected-damage rules, all new abilities, FACTION_AI profiles (threat weight, range), flagship Commands (BOSS_CMD) announced a round ahead + shown on boss panel
- Rewards: modules filtered by fleet kit (MOD_NEED); faction names for modules/relics (MOD_NAMES/RELIC_NAMES); run word per faction; events skip own faction and have faction variants; mercenary gives own-faction destroyer; relics Martyr (avenge 15%), Rangefinder (first shot 95%), Banner (bloodied +15% per kill) now change rules
- Boons: Iron Discipline riposte, Storm Mantle all facings, Killing Light wrecks systems, Chain Reaction 2 hexes, Funeral Pyre stops regrow/reanimate, Broadside Inferno hotter/longer, Bulwark +70% and taunt; Arc 9, Reflex +6, Silent Aim +5, evasion cap 45
- Phone: cinematic default (full flashes, action camera on kills/boss, follow on), one-line top bar with gear, sheet tucks away on enemy turns, fleet-fit camera framing
- Sims: fmatrix (10cp) as player V47 H58 C53 Ch40 I38 D58 (was 58/74/40/48/48/56); runsim new harness; bosscmd all six fire. Smoke 21/21 PASS.

## Oct 12 afternoon: v36 (build 20261012-1413-7f1f97b) PUBLISHED main: set pieces overlapping the board
- Ryan's run (Deathless/Sekhmar): battle 1 dense+planet (flank), battle 2 deadstar+station (ambush); asteroids/planets on top of each other, ships inside them
- Causes: near planet rim (8*HW+5=143) reached past the blocked hex-distance-8 area (nearest open row ~135 away), so enemy flank spawns and dense-shape rocks sat under the planet; station map station could be sited in a hole (on top of the dead star / hole fills); hole fills sized max-dist+7 with chunks out to 1.25R spilled over neighbouring hexes; graveyard wrecks larger than a hex
- Fixes: planet blocks hexes by its actual circle (planetEdge = R*1.5*HS+HS/2, hexXZ in battle.js for sims) and rocks keep 1.8 hexes off its rim; station sited on the board, ring on board, 3+ hexes from any hole; hole fills capped at nearest board hex - 0.55 hex, asteroid chunks inside R, station/hulk/comet scaled down; wrecks fit their hex
- New overlapprobe.py (phone browser, 90 boards: 10 shapes x 5 maps x 3 deployments): before, 54 of 90 boards flagged (units under the planet, hexes under fills, station in the dead star 7x); after, 0 boards with any unit inside a set piece, 1 marginal hex. Fuzz 100 clean, smoke 22/22.

## Oct 12 afternoon: v37 (build 20261012-1503-458af35) PUBLISHED main: calm phone camera + current run review
- Run so far (Deathless/Sekhmar, Spear aspect): 5 of 5 fights won incl. sector 1 Chorus boss (ecp 14 vs pcp 9, 7 rounds, lost a scythe); now sector 2 with 2 Harvesters, 315 credits, relics Martyr + Banner. Commands: rounds 3,2,4,2 at power 3,2,3,2 (full power twice; never before v35). Used phase shift 4, reanimation beam 4, brace 3.
- Found: Capacitor Surge, Bastion and Storm Mantle were offered to a shieldless fleet (took Capacitor and Bastion, both dead). Fixed: BOON_NEED shields; Xeno shield lattice relic skipped for shieldless fleets.
- Elite at sector 1 col 4 started then the app closed; on return a different column-4 battle was taken (no penalty for leaving mid-fight). Noted, not changed.
- Camera cause: v35 turned camera-follow on by default; it jumped to every enemy ship at zoom <=190, and after every enemy move (alternating activations) it snapped to your first ready ship, again zoomed to <=190.
- Fix: the game never changes zoom on its own; it pans only when the ship that matters is off screen (allowing for the top bar and ship sheet); your view is saved before each enemy move and restored after, unless you moved the camera yourself meanwhile. Center button still zooms in on request. camtest.py: zoom held at 320 across 3 enemy moves. booncheck 17/17 (updated Admiral aspect test for new timing), fuzz clean, smoke 22/22.

## Oct 12 evening: v38 (build 20261012-1903-cbf8574) PUBLISHED main: progression between runs
- Loss review (Deathless, sector 2 Corsair fight): bot wins the same fleet/setup 93-95% (no boarding by bot). Causes: 2-ship action economy vs ~5 Corsairs, boarding attempt next to Corsairs then 2 overruns, Spear aspect on a turn-1 hull (7 prow shots in 12 rounds), 315 credits/9 CP unspent with no shop after the boss, 2 dead shield boons.
- Post-boss shipyard: sectors 2 and 3 open with a shipyard node (col 0).
- Admiral mastery (META.mastery): xp = battles won 1, elite 2, flagship 5, victory 10; levels at 6/16/30/50: alternate fleet (altFleet splits a 4+ CP hull or merges the two smallest), 4 aspect choices, second Command (altCommand: next distinct Command in the faction), flag captain (flagship Mk II, Captain rank + perk). Admiral screen: mastery bar, fleet/Command toggles.
- Hull variants (HULL_VARIANTS, 12, two per faction, 15-30 renown, META.variants), sold beside the base hull in shipyards. Harvester tomb-turret (turret doom arc) answers the turn-1 problem.
- Patron favour (META.favour): +1 per boon (+rarity); Favoured 4 (more rares), Devoted 12 (starting gift boon if watching), Chosen 25 (never common).
- Heat (after first win): 7 rules, weights 1-2, +10% renown per level; META.heatBest per faction. Hooks: boss scale, budget, elite escort, enemy reanimate, priceMult, repairMult, cmdTier.
- Renown was no longer being paid (removed with unlock-all); now paid at run end (runRenown x heat). Progression screen (title button) with tabs: variants, mastery, favour, heat, fallen. Recap shows "Carried forward".
- One-time backfill from telemetry on load: mastery and favour from past runs; renown credit capped at +60 (Ryan's save: 11 -> 71; aelith L3, reyes L3, mott L2, sekhmar L1).
- Checks: progcheck 18/18 (new), booncheck, fuzz 100 clean, mapcheck, smoke 22/22, phone screenshots of every new screen.

## Oct 12 night: v39 (build 20261012-2149-4b69164) PUBLISHED main: elite + Deathless tuning
- Run (desktop, Deathless/Sekhmar, Spear aspect again, bought Harvester tomb-turret for 30 renown): won battle 1 (lost both Scythes), won battle 2, lost the sector-1 Corsair elite (ecp 11 incl. transports vs pcp 8) with 2 Harvesters. 8 shots out of range (gauss range 4 vs Corsair torpedoes at 6). One boundingSphere frame error, healed.
- acccheck (new sim: real shot hit rates and hull-damage sources): Deathless gauss hit 61% vs Corsairs (Corsair guns 72% into 0-evasion Harvesters); torpedoes 24% of Deathless hull damage, bombers 9%. Not an accuracy bug: no shields + 0 evasion means every hit lands, and range 4 couldn't answer range-6 torpedoes.
- scen2: his exact fleet vs that elite: Spear 70%, Bulwark 90%; a Scythe instead of the Mk II upgrade 95%.
- Elite fights were brutal for everyone (sector-1 elites: e.g. Hegemony/Ithar 0-8% vs Deathless elites): every enemy ship was elite (+15% hull, +10 aim). Now only the bigger half is elite, elite = +10% hull, +6 aim.
- Deathless: gauss range 4->5, shield pierce .7->.55, armor -.05 on all three hulls, Harvester 150->135, enemy reanimation 35%->20% (player keeps 35%).
- Spear aspect: also +1 turn per round for the flagship.
- After: sector-1 elites mostly 45-70% for a 10 CP fleet (Ithar vs Deathless elite still 15%: shield-reliant fragile hulls vs gauss). fmatrix 10cp: as player V52 H63 C36 Ch59 I56 D50; as enemy V64 H54 C48 Ch46 I31 D42. fuzz, progcheck, booncheck, smoke 22/22.

## Oct 13 morning: v40 (build 20261013-0939-f183211) PUBLISHED main: full balance patch
- Baseline (fmatrix 10cp x12, bossmatrix s1, boonsingle 24): player V64 H61 C40 Ch50 I57 D36; hulls 30-75 dmg/CP (Cathedral 75, Spitter 30); bosses Corsair 94%, Ithar 21%; Thorne 95%; Ion Lash, Silent Aim, Reload hymn strong; Storm Mantle, Bastion, Starlight Lances weak.
- Changes: heavy macro battery 5x8 -> 5x7; Harrow 78 hull; Dominion turbo turret removed (hturbo broadsides + ion + flak); Interdictor 74/18; laser 7; turbolaser 9; turret 8; Hulk two turrets; scatter acc 78; Spitter 82 hull, bioplasma 12; Wraithcarrier + turret; Shadowblade 60, star torpedo 38; Deathless back up (Harvester 145, Jackal 88, Scythe 56 ev 14, gauss pierce .6); bombs 10 -> 9; Thorne +8 ev; Maren starts with 2 pickets; per-boss scale BOSS_FAC (corsair 1.45, voidsworn 1.25, hegemony 1.05, ithar .9) plus Pyre-Barge 600/30, Worldsong Ark 470/34; Ion Lash .22, Storm Mantle .18, Bastion +10% brace, Starlight Lances +35%.
- After (fmatrix 10cp x20): as player V42 H42 C48 Ch52 I48 D53 (spread 11 pts, was 28); as enemy 40-64; hull dmg/CP 39-65 (was 30-75). Bosses s1 49-88% (Corsair still easiest even after 1.45x); carrier fleets 76% vs gun 65% (was 77/63).
- fuzz, progcheck, booncheck, smoke 21/22 with heal test flaking under CPU load; rerun alone passed.

## Oct 17: adversarial review package (v40 code), /mnt/user-data/outputs/voidsworn-review/
- New sandbox: /home/claude/v3d gone (no git history); restored from outputs/voidsworn/src into scratchpad, npm babylonjs@8.20.0.
- Package: README, AUDIT_PROMPT (8 personas incl. balance/progression analyst), AUDIT_CONTEXT (v40 claims, change history v26-v40, reversals, risks), RUNNING, BUILD_LOG, code/ (game + tools + live voidsworn-3d.html f183211), results/ (Oct 17 runs), telemetry/ (summary + raw, 471 events incl. Oct 17 Voidsworn/Vex victory), prior_reviews/ (Oct 4 arch, Oct 10 Muse + Claude audits, Oct 12 builder audit), screenshots/ (owner Oct 10-11 + fresh v40 phone captures). Also voidsworn_review_bundle.txt (~184k tokens) and voidsworn_prior_reviews.txt.
- Fixed stale sim test: cmdcheck expected Commands locked in round 1 (v35 made them usable from round 1); now 6/6. booncheck possibly flaky (one 16/17 run, five 17/17).
- Oct 17 sims: smoke 21/21 (not 22: earlier counts included the "SMOKE PASSED" line), fuzz clean; fmatrix 10cp n8 as player V48 H44 C46 Ch50 I46 D52, as enemy I31..V64/Ch64; bossmatrix s1 n3 carriers 67 vs gun 57, Hegemony boss hardest 37%.

## Oct 18: v41 (build 20261018-1239-48ba570) PUBLISHED main: correctness patch from the four-audit review
- Audits (Claude, ChatGPT, Muse, Argon) verified one by one; combined doc "Voidsworn v40: four audits, verified and combined". Stale claims dropped (NaN prices, victory faction, half pay, unlockAll).
- Rules match cards: fire can kill (checkEnd after side start); Restore repairs broken sections, weapons, shield generator and engines (repairSection, secSave); Surge blocked while generator destroyed; Rangefinder once; Blink scores objectives; wing orders drop when target changes side; squadron leash same for move and attack.
- Async liveness: ramUnit, boardUnit, nova, killUnit and Command barrage check the battle is still live after every await; classic enemy turn wrapped in stallGuard(90 s); aiStep prefix in try/finally; busy watchdog hands a stuck enemy turn back to the player.
- Alternate fleet (altFleetPlan) keeps CP equal and carriers; carrier-only admirals get a hangar refit instead.
- Seeded rules RNG (mulberry32, B.seed logged at battle_start; sim SEED env). Save keeps a .bak and toasts once on write failure. Recovered the Oct 11 Ithar win missing from wonFacs.
- Phone: Command needs a second tap within 4 s; hints say tap twice; Threat button in the top bar. Bosses roll rout/ambush/flagship. Spare wings = hangar slots (was x2). Phase +22 evasion/+2 move, Jackal 110, Hegemony boss scale .95. Emblems kept out of the merged hull.
- build.py: fails on duplicate top-level functions and runs node --check (a // comment swallowed a line once).
- Checks: rulecheck 10/10 (stalled volley and stale explosion fail on old code), progcheck 24/24, softlock incl. throwrefresh, cmdui two-tap pass, smoke otherwise green. bossmatrix s1 n12: by boss He62 Co63 Ch74 It50 De57 Vo80; carriers 63% vs guns 65%.

## Oct 18 afternoon: v42 (build 20261018-1455-34b6694) PUBLISHED main: AAA-direction graphics pass, every quality level
- New gfx3d.js (GPU shader library; all generated, no art files).
- Hull shading (MaterialPluginBase inside PBR, no extra draw calls): faction rim light that strengthens at tactical zoom; grime and exhaust streaks in ship-local space; faction energy (Deathless circuit traces with pulses, Chorus veins with a heartbeat, Ithar light sweeping the hull). HULLFX_HI define: Medium skips the streak layer.
- Planets: procedural shader for gas giants (warped bands, storm), rocky worlds (relief on High/Ultra, shelves, ice caps, two cloud decks, city lights) and ice worlds; limb darkening and scattering shell. The Planet edge set piece now uses it (per-faction world, lit by the key light so its board-facing side is in daylight) instead of the painted 2048 texture.
- Nebula banks: live domain-warped shader on High/Ultra; phones bake six into 256 textures once via ProceduralTexture (re-baked per battle colours).
- Effects: shader fireballs (noise-displaced, cooling ramp) on big hits and capital deaths; shader lance beams (core + sheath + crawl); shield collapse shatters into hex shards; plumes fade nozzle to tip with scrolling streaks (shorter, d*1.9); flares smaller.
- Finish: per-faction highlight grade blended with the map grade; Ultra supersamples 1.25x below 4K; Medium renders ~1.5x CSS pixels (cap 720 wide) with no glow layer; ships scale up to 1.38x as the camera pulls back.
- Frame telemetry: FRAMES p50/p90, draws, render size and quality in battle_end; P overlay shows p50/p90.
- Checks: smoke 22/22 PASSED on v42; zero console errors on desktop High/Ultra and phone Medium shot runs; renderbudget phone BASE draw calls 107 (v41 172 on a different random fleet; texture count 79 vs 63, the 2048 planet texture gone).
- Not measured: real frame times on the Pixel and the 5080 (software GPU only). The battle_end perf block will show them after real play.

## Oct 18 evening: v43 (build 20261018-1909-2780c1f) PUBLISHED main: battle damage, rifts, sector conditions, fleet archetypes
- Graphics part 2:
  - Per-ship battle damage: below 80% hull a ship gets its own copies of its hull and dark materials (shared textures re-attached; clones of generated textures come back blank otherwise). Scorched plating spreads and glowing cracks flicker as hull drops. The copies are disposed on death or view disposal.
  - Asteroid surface shading (RockFxPlugin on the StandardMaterial): dust, basalt, faint veins in rock-local space.
  - Hyperspace rift: a faction-coloured ring tears open where each ship drops in.
  - Ultra: high-quality shadow filtering, wider bloom, up to 4 weapon lights (was 2).
- Variety (plan doc's v43 list):
  - Sector conditions, one per sector and never repeated in a run: Ion season (storms; shields recharge 25% slower on both sides), Dark sector (nebulae), Wreck belt (debris; +15% credits), War zone (every fight gets reinforcements, 60% enemy; +20% credits), Scarcity (prices +20%, repairs -25%; +25% credits). Shown in the sector intro, on the map and in the battle-start toast; condition logged in battle_start.
  - Enemy fleet archetypes on battle and elite nodes (swarm, heavy, carrier; named per faction, e.g. Wolfpack, Line of battle); carrier falls back to heavy for factions without carriers.
  - Node modifiers from column 2: Bounty (+50% credits, +10% ships) and Veteran captain (their largest ship is elite).
  - Phone: Battle log toggle in Settings (overlay above the ship sheet); enemy elites show their names on plates.
- Checks:
  - smoke 22/22 twice (graphics build and the merged build); fuzz 100 battles with 0 exceptions; mapcheck, rulecheck, progcheck and shapecheck pass.
  - New probes cond.js and arch.js confirm terrain, regen and price effects and that conditions never repeat.
  - New archmatrix sim (s2 col3, n2, all admirals): win rates 84% with no archetype, 86% swarm, 82% heavy, 87% carrier.
- Fixed: a symlinked node_modules got committed from the v44 worktree and the merge deleted the real folder. It is reinstalled and now ignored.

## v44: ship fidelity and full broadsides
- Ships (answering "they look like Legos"):
  - Hulls are lofted with Chaikin-bevelled cross-sections, spline-resampled stations, smooth normals and separate flat end caps. Corsair hulls are no longer flat-shaded.
  - New tapered superstructure primitive (`slab`): sloped walls, raked ends and machined edge bevels. It replaces the plain boxes in Voidsworn deck cities, towers, keel, turrets and prow collar; Hegemony terraces, bridge neck and command deck; the Corsair bridge; and the Deathless spine and monoliths.
  - Surface detail on designed factions is mirrored and laid out in rows, and is thinned on narrow hull sections. Corsairs keep their lopsided scatter. Greebles are lower-relief. Gun-deck rails are rounded mouldings.
  - Nearly every box is bevelled. Cylinders are 16-sided on desktop. Spheres have at least 10 segments.
  - Desktop gets real dorsal turrets that traverse onto the target. SSAO is on for High desktop.
  - Plate-to-plate tone variation and underside darkening come from the hull shader.
  - Asteroids are smooth-shaded, multi-octave and cratered (previously faceted icospheres).
  - Navigation lights on capital ships: red to port, green to starboard, white strobes fore and aft.
- Weapons (answering "so many guns, but only one or two shots"):
  - Volleys: every barrel on the engaged side now fires, rippling bow to stern. Sources are the exact Voidsworn gunports, Hegemony batteries, Deathless glyph emitters, real turret barrel tips, and synthesised hull ports for the other factions.
    - Caps: 42 bolts on Ultra, 30 on High, 9 on phone.
    - Lead bolts still carry the dice. Extra bolts are visual only, so rules and balance are unchanged.
  - New GPU sprite pool: one draw call for hundreds of flashes, stars, rings and streak sparks. It drives per-barrel muzzle flashes, hull sparks fans, shield-ring hits, a glow riding every bolt, and point defence (tracer streams and flak pops around incoming torpedoes).
  - Flak joins volleys at half density.
  - A distant fleet action plays on the skyline (flashes, tracer streaks, the odd big detonation).
- Also in this pass:
  - Chorus (organic) and Ithar (porcelain) hulls no longer get riveted plating.
  - Deathless ziggurats have sloped tiers, and their crescent blades have more facets.
  - Shield hits from volley bolts are spread across the dome.
- Budget:
  - Tiny kit parts aren't bevelled on desktop, and phones skip bevels below 2% of hull length.
  - Per-ship vertex counts are now below v43 on both desktop (Voidsworn Dreadnought 244k vs 272k) and phone (183k vs 193k).
  - The volley cap keeps phones to 9 extra bolts. Bolt halos only ride the lead bolts on phones.
- Checks:
  - smoke 22/22; rulecheck and shapecheck pass.
  - renderbudget base draw calls are 115 (v44 pre-pass: 158 in the same harness).
  - Isolated flagship renders reviewed for all six factions.
  - Combat captures show both sides' broadsides.
  - Phone Medium renders with no errors.
- Also in v44 (combat pass, commit ce5b67a): glowing bolts, muzzle blasts, shock and plasma rings, burning debris, staged capital deaths with kill cam, wreck cook-off, shader plumes, procedural plating bump (High/Ultra), torpedo trails, lance charge, damage sparks, fighter trails, exposure flare.

## Oct 19: v44.1 performance patch (owner: "it lags at multiple points now, especially when enemy ships explode")
- Evidence:
  - Phone telemetry (Medium, 664×1186) gave a median frame time of 20.7 ms on v43 vs 23.7, 31.1 and 26.7 ms on v44. p90 went from 41 ms to 44–60 ms.
  - New profiler script `profexp.py` (Chrome sampling profiler plus shader-link counter, phone or desktop, modes explode, idle and volley).
- Causes and fixes:
  - Exposure flare re-dirtied every material each frame. It now rides bloom weight.
  - Every small effect created a mesh, material or particle system, about 20 per ship death plus cook-offs, debris trails and two persistent particle systems per wreck. Two sprite pools (additive and alpha-blended smoke) now carry flash, burst, sparks, star and soft fxSprite, debris trails and wreck smoke.
  - Effect shaders compiled on the first kill. `warmFx` at battle start fixes this: a small blast far off on the skyline, plus wreck and decal materials force-compiled against real and split-model meshes.
  - On desktop, flash lights were created and removed per blast, so the light count changed and material variants recompiled (31 and 25 program links in two High explosions). A fixed pool of flash lights (2 High, 3 Ultra, 0 Medium) now stays in the scene, and dying ships' engine lights go dark and are freed at battle end.
  - A detached SSAO left the geometry buffer rendering every mesh every frame on all qualities. It is now emptied while SSAO is off.
  - Graveyard and station debris was about 190 instanced hierarchies (about 380 active meshes). It is now thin instances (`debThinUpdate`).
  - Phones get lighter explosions (3 blasts, smaller star, fewer sprites and fireball particles), one storm card and two nebula cards per hex, and half the glow blur.
- Telemetry: `battle_end.perf` adds p99, max, h50, h100 and `hitch`, a per-cause count of frames over 100 ms (explode, volley, lance, torp, craft, warmup, other).
- Measured on the software renderer (relative only):
  - phone explosion window: frames 16/8 → 18/20, first-kill long tasks up to 287 ms → 54 ms, program links 5 → 0;
  - desktop High explosions: links 31/25 → 0/0;
  - idle phone: material readiness JS about 1,000 ms per 8 s → under 60 ms, frames 24 → 48;
  - graveyard active meshes: 595 → 131.
- Checks: smoke 22/22; rulecheck passes. A multi-battle leak check (`leakcheck.py`) found only effects still in flight (the software renderer advances game time 0.05 s per 1 s frame). Debris smoke now spawns on game time so slow frames can't flood the pool.
- Review package for round 2 of the cross-model audit: /mnt/user-data/outputs/voidsworn-review-v44/.
- Follow-ups:
  - The warm-up blast is now placed on screen. Off screen it was culled, so the fire and shock shaders still compiled on the first kill.
  - The uneven-scale streak variant is warmed too.
  - Final profile (`results/perf_*`): phone explosion long tasks 327/192/1818/157/107 ms → none; links 5 → 0; desktop High links 58/6 → 0/0.
  - booncheck's Arc Discharge test was flaky under random terrain. It now clears terrain and tries every facing (8/8).
  - Build 20261019-0147-38c14f0 published.

## v45 (Oct 19): reliability, honest volleys, relight, cut-ins, tuning
- Reliability: called-shot buff applied only after the live check; killUnit re-checks battle end after its explosion; warm-up scoped to its battle; pagehide logs battle_abandon and saves.
- Honest volley: the number of visible hits matches the rolled hit rate (at least one when anything hit).
- Pooling: capital-death fireball (3-layer pooled), thin-instance debris batches per faction, shield-dome pool (max 8), shock-ring shader pool; reinforcements get no engine point lights (avoids mid-battle recompiles).
- Relight: sun 3.2 / fill .6 / hemi .1, shadow darkness .12, biome star tint on the sun, vignette 2.0, chromatic aberration and grain off on all tiers.
- Faction shield colours on rings, domes, breaks and impacts.
- Command confirm: 6 s with a live countdown. Boss commands get a "next round" banner. Torpedoes labelled slow (evasion counts 2x).
- Cut-ins (setting: key moments default / every attack / off): letterbox, HUD and board overlay fade, "Tap to skip". Key moments are capital kills, Commands, lance/torp/nova on bosses or low-hp targets (always on desktop), and big-ship volleys on bosses/low-hp targets. Verified headless: bars on, HUD hidden, tap restores.
- Tuning at n=12 (seeded): boss multipliers voidsworn 1.25->1.40, chorus 1->1.10, ithar .9->.8 (by-boss player win spread 53-78% -> 53-68%); Deathless jackal regen 4->3 (Deathless stays top but less so). Torpedo evMult 1.5 tested, not shipped (no clear signal).
- Fixed: a v45 comment had swallowed the shock-ring and beam warm-up calls; effect shaders are now force-compiled at warm-up even if the blast lands off screen.
- Renamed "Dominion star destroyer" to "Dominion star dreadnought" (keep inspirations, not borrowed names).
- New smoke gates: scene budget (active meshes <= 340, draws <= 420; measured 285-312 / 222-229) and effect shaders warmed.
- Asset lab: FLUX schnell (GGUF Q8, ungated parts) runs locally on the 5080, ~9 s per 1024px image; Hunyuan3D 2.1 shape meshing ~71 s per ship. Round 1 concepts: voidsworn-asset-lab/concepts_flux. Ryan's picks: V b-variants, H1a/H2a (carrier must have enclosed hangars), C b but jankier, B a but less animal (hive bioship / infestation), I a with sails and grace, D1b good, D3b needs revision, no literal pyramids.

## v46 (Oct 19, published): faction identity + concept-art hulls
- Faction bible in the plan doc. Palettes: Voidsworn black/ember, Hegemony light grey/blue, Corsair blood/rust, Chorus plague flesh/bile, Ithar pearl/jade, Deathless black/terminal green (hulls, glows, bolts, beams, shields, emblems, UI).
- Movement feel per faction (MOVE_FEEL in ships3d.js): heavy/crisp/jerky afterburner/writhing/gliding/phase-blink.
- Weapon reskin (names via FAC_WNAMES + wName; bolt styles las/plasma/tracer/spine/needle/rail; torpedo flavours). Numbers unchanged; v47 = mechanics (acid DoT, interceptable rockets, gauss pierce) with sim tuning.
- 28 concept-art hulls (FLUX concept -> Hunyuan3D 2.1 on Ryan's 5080 -> bexport 16k tris JSON) loaded from hulls/*.json (published as artifact files); procedural build still supplies guns/engines/stats; fore/aft split at the break line; turrets snapped to hull top; engines moved to stern. Settings toggle "Concept-art hulls".
- Asset pipeline scripts: /mnt/user-data/outputs/hy3d (vs_art_*.py FLUX, vs_mesh*.py Hunyuan), scripts/bexport.py. Hangar viewer: https://claude.ai/artifact/WABMRapCwpZfQ1EthmFgrT
- Smoke 24/24 (active-mesh gate now 420).

## v46.1 (Oct 19, evening)
- Black boxes over ships (High/Ultra, desktop GPUs): ambient occlusion and god rays were attached behind the bloom/tone-map chain, so they ran out of order and the bloom blur smeared bad pixels into squares. `orderPostFx()` rebuilds the default pipeline last whenever quality changes. Verified on Ryan's RTX in Chrome (order now SSAO > vls > bloom > imageProcessing > sharpen > fxaa).
- Movement signatures rebuilt much stronger: Voidsworn overshoot + haul-back with pitch, Hegemony dead-straight lines with hard burn and retro-thrust stop, Corsair drift/correct + smoke coughs + roll wobble, Chorus side-to-side swim with stroke surges and squash, Ithar wide banked arc with lift, Deathless dissolve/phase (no traversal, column flash at both ends). Verified the phase on Ryan's GPU.
- Diagnostics panel (Shift+D or Settings > Diagnostics): toggles for every render feature + live draw/mesh counts and post-process order.
- battle_end telemetry now carries a scene census (meshes, enabled, active, materials, particles, observers, top names) to pin down the draw-call creep across a run (pre-existing: 231>494 on phone in Oct 18 builds, 451>1144 on PC in v46).
- Wakes from moves cut short by a battle ending are now disposed.

## v47 (Oct 19): arenas, approaches, gravity wells, regions and biomes, board readability
- Board canvas 30x22 with arenas: strip, square and round. Approach deployments (diagonal, cross, head-on, pincer) place fleets by angle around the arena centre; the camera opens with the player on the left.
- Dead-star gravity wells: +1 movement within 6 hexes (slingshot), a pull of 1 hex inward, and damage on the rim. The AI scores the well.
- Sector regions (frontier, nebula, world, boneyard, deep) keep maps coherent across a run. Each node's map fits its objective. Biomes vary inside a region: asteroid kinds, gas giants with rings and moons vs rocky worlds, ring/rig/spire stations.
- A smoked-glass underlay under the hexes keeps the grid and move highlights readable over planets and bright nebulae.

## v48 (Oct 19): faction weapon traits
- Lasers (accurate, less falloff), hellfire torps (ignite), plasma (pierces armour), scrap guns (more shots, less accurate), Corsair rockets (swarm, shot down by point defence), spines (shred armour), acid (damage over time), needles (crit), star torps, gauss (half armour ignored). Tuned with sims.
- Per-faction gun, torpedo and lance sounds. Lit ports and spine trim on concept-art hulls.
- Leaks fixed: overlay materials, glow exclusion list, flag ring material (materials flat across battles, observers about 33).

## v49 (Oct 19): weight and destruction
- Mass-spring ship motion: lag, overshoot, yaw and roll springs; hits push hulls; firing gives recoil.
- Asteroids: 8 high-detail noise shapes (ridges, craters), region-tinted. Desktop loads 20k to 38k triangle hulls (hulls_hi/).
- Deaths: staged pre-blasts, then the hull splits into 3 to 7 jagged sections that tumble apart with fire venting from torn faces; per-faction blast colour, random size, a chance of a late secondary blast; shard debris.

## v50 (Oct 19): thrusters and movement incentives; new hulls
- Thrusters: sideslip into either forward-diagonal hex or back off one hex holding heading (2 movement; a slow hull can always spend its whole move on one hop). Climb over rocks/wrecks or dive under enemy ships (+1, can't stop there), animated with altitude and pitch.
- Motion modifiers: sat still last turn +10 to be hit, moved 3+ hexes -5, raking pass (broadsides after 2+ hexes) +10% damage. Per-faction drive rules (MOVE_RULES).
- Round 8 hulls: Corsair B set, Chorus A set.

## v51 (Oct 20): underway, fire on the move, rim fill
- Burns start and end at cruise, ships coast on after a move (critically damped, no swing-back), idle surge/sway, engines at cruise. Voidsworn haul-back removed.
- Fire on the move: AI volleys start two thirds into the burn; player attack-move (tap an out-of-reach enemy to burn into position and fire on the way).
- Every cut hex gets a reason: asteroid walls, wreck debris, ion cloud banks, planet haze, plus derelict centrepieces in the deepest rim pockets.
- Round 10 hulls: Deathless destroyer/cruiser/tomb-ark (B set, flat-concept alignment in bexport), Corsair bolt-on pass. Deathless frigate B meshed as a plaque, old frigate kept.
- Fixed: sector intro modal never showed after a sector boss (m.region ReferenceError).

## v52 (Oct 20): audits round one, surface and death upgrades
- Baked ambient occlusion + cavity per vertex on every concept hull (scripts/bao.py, BVH ray casts), applied as vertex colour.
- Cause-driven deaths: lance cuts the hull in two, torpedoes/rams blow it apart at once, gauss flays it into dissolving shards, acid/spines sag and melt it, burn-outs go dark and drift.
- Readability (Gemini audit): distance-scaled rim and running lights, stronger rim on Voidsworn/Deathless, lighter Deathless hull, backdrop ~30% darker, derelict station lights cut, hollow move hexes, matte asteroids, nameplates hang under the ring, prow chevron on every ship ring.
- Salvage: after a win, pick one wreck from the ships you destroyed (shows how it died and who killed it): strip a themed refit, scrap for credits, or (Corsair) tow small hulls home.
- Audits: Fable (independent), ChatGPT (design), Gemini (visual); Muse pending. Merged plan: "Voidsworn audit merge and next steps" doc.

## v53.1 (Oct 20): board readability and correctness
- Adversarial review round (ChatGPT, Gemini Argon High, Muse, Fable with code access) collapsed the plan to three big versions; queue now lives in NEXT.md.
- Board: ships sit on their hex (coast drift capped at about 0.1 hex, was up to 0.77), side-coloured fill and edge on every occupied hex (brighter on hover, selection and valid targets), contact shadows, outline-only move hexes, darker board plate so the grid reads over nebulae, expected-damage line in the move tooltip, clean ghost ship on first tap; guns/target lines now show from the first selection.
- Correctness: movement animation no longer writes rules state (ram and rotate commit their own), blink re-checks, battle seed no longer overwritten (telemetry seeds are real), hazard/station deaths awaited in order with a shared kill-cause list (new tidal cause), squadron phases under the stall guard, abandoned shots refund the gun, stalled activations log "orders lost in interference", seeded lifepod roll, finishBattle runs once and the Continue button is gated.
- Saves: run vs meta timestamps split for cloud sync, error/stall saves local only, one normalizeRun with defaults, malformed saves fall back to the backup, renamed module/perk/relic ids are skipped instead of crashing.
- Mid-battle reload replays the same node, seed and enemy fleet.
- Tests: 8 new rulecheck checks (seed replay and one per bug class); smoke now reloads mid-fight and wins a sector boss through to the next sector intro. Full smoke now runs on the owner's PC (real GPU, about 4 minutes) via Downloads/voidsworn_test.
- Repo backed up to github.com/rcbailey12/voidsworn (private).

## v53.2 (Oct 20): AI that reads, enemy intent
- Enemy AI re-picks targets per gun (no overkill), fires shield strippers first, keeps a sticky focus (veteran), ignores guns that already fired when judging danger, avoids hexes where it would die, plays objectives with a round clock, uses abilities after moving, spaces escorts.
- Enemy focus target shows on the board (red brackets, TARGETED tag on the ship and roster row). Tap an enemy to see where it can bring guns to bear next move and which of your ships are inside it (fill toned down to 0.011 after desktop screenshots).
- Threat overlay about 2x faster. 5 new rulechecks. Balance matrix flat overall (player win 75.7% -> 77.1%).
- Gates: rulecheck, fuzz 20 sandbox; full smoke on PC passed (14:50).
- Owner feedback logged: lag much better on v53.1; nameplates sit under the wrong hex (root cause found, workstream E); sounds janky (workstream F started with Kenney + Sonniss clips).

## v53.3 (Oct 20): ship status stays in its own hex
- Floating name/health bars under ships removed by default (they were pushed about a hex down screen, onto the neighbour). Shields stay on the shield ring; damaged ships get a hull gauge on their own hex footprint; name and full bars only for the selected, hovered or inspected ship, above its own hull.
- updateWorld takes canvas size from the engine (no per-frame layout read).
- Gates: rulecheck (one flaky fail in 10 runs, logged), fuzz 20; PC smoke passed 15:14.
- Owner playtest (v53.2): 4 wins / 0 losses, every battle over in round 3 (sector 1 too easy). Big call-out: close-up graphics look haphazard (floating window lights, stray procedural parts on mesh hulls, faceted asteroids, box squadrons). Workstream G started for ship close-ups; E told asteroids are top priority.

## v53.4 (Oct 20): sound rebuild
- New sfx.js: buses (weapons, impacts, explosions, UI, ambient) into a generated dark reverb, compressor and limiter; pan from screen position and distance falloff; voice limits with oldest-voice stealing; overlapping guns become a rolling salvo with a low body from the 4th gun; synth cues pre-rendered once, no per-frame audio JS.
- 52 recorded clips embedded (sfx_data.js, ~470 KB Opus): Kenney CC0 sci-fi/interface and Sonniss GDC 2026 (booms, debris, metal hits, force fields, lasers, arcs, UI, turn cues, roomtone ambient), layered with synth and per-faction pitch.
- Volume slider in Settings; ?sfx=1 audition panel / sfxTest(); menu and reward-pick clicks now play UI sounds.
- Gates: rulecheck, fuzz 20; PC smoke passed 15:31.

## v53.5 (Oct 21): ships up close, new meshes, performance
- Concept-mesh hulls no longer carry leftover procedural parts or floating window quads; lit ports are drawn in the hull shader; engines, muzzles, nav lights and decals sit on the mesh surface.
- Per-hull baked detail (Blender on the owner's RTX 5080 from the 400k-face Hunyuan originals): tangent normal + AO/curvature maps for all 36 hulls, xatlas UVs; desktop 2K/1K/512, phone half; loaded per class, released at battle end.
- New concept meshes: Voidsworn Reliquary carrier (V18_51), Corsair Pyre-Barge (C19_51), squadron fighter/bomber/spore craft (S1_51, S2_23, B23_51) in formations, defend station (O1_37), intercept transport (O2_37), relay beacon (O3_11).
- Faction fixes: no windows on Chorus, thinner Deathless circuits, Pyre-Barge burn edge as ember runs, hex fill fades on zoom-in, sun lens-flare ghosts removed. Ithar fly bow-first with a matte pearl material; asteroid blockers rebuilt.
- Performance (workstream C): parallel hull loading before the title, one-draw shield rings, scene-graph diet (frozen statics, pruned glow list, throttled shadows), pooled text; phone draws 391 -> 294, phone CPU/frame 5.8 -> 5.0 ms; profiler CSV (?prof=1).
- Cleanup: dead title canvas/preview demo/hexTex/low tier removed; 30 unused hull files deleted.
- Bugs found on the real GPU and fixed: invisible then black hulls (NaN/undefined shader uniforms, GLSL comment breaking Babylon's preprocessor), single-threaded test server stalling parallel loads.
- Gates: rulecheck, fuzz 20; PC closeshot (no console errors) and full smoke passed 07:44.
- Known: a small orange glow still floats above some hulls; Ithar sail still a flat sheet; desktop CPU/frame higher than v53.1 (15 vs 10 ms) though frame pacing is smoother.

## v53.6 (Oct 21): weapon effects, doubled down
- Every weapon family has its own look and timing (wfx3d.js):
  - plasma: tight electric-blue bolt with a white-hot core, crackle arcs and an orange-hot molten impact;
  - laser: thick white core inside a coloured halo, with a muzzle flash and impact flare;
  - rail: white-hot slug, fading green wake, accelerator rings and debris spraying out the far side;
  - tracers: five long flickering brass tracers per shot;
  - also lance, ion, needle, spine, flak, and torpedoes twice the old size.
- Explosions use flame and smoke flipbooks. Capital deaths walk blasts along the hull and end in a flash, a fireball and one flat ring.
- Game feel: hits are sized small to extra large, each with matching shake, hit-stop, flash and bloom. Settings has separate Reduce flashing and Reduce shake toggles.
- Fix: effect sprites draw after the board plate, grid and rings, so the grid no longer paints over them. This was what made plasma look white with a dark line through it.
- Fix: the instanceColor shader error on the board footprint marks.
- Effect textures build in idle slices on the title screen, not at battle start.
- Checks: PC fxshot ran 100 shots in 3 rounds with no console errors; rulecheck, fuzz 20 and full PC smoke pass.

## v53.7 (Oct 21): Pixel feedback fixes (artifact Version 64)
- The "broken station" was the old procedural spire station (floating windows, spikes, loose slabs), still built on Engagement fights on station maps. Every station map now uses the O1_37 mesh; the procedural spire/rig/ring are only the fallback when meshes fail to load.
- Close-up camera floor: the closest view keeps the biggest ship on the board to about half the screen (CamCtl.minR = 1.5 x largest ship length, 26-55); scripted cinematics are exempt.
- Board overlays fade as the camera closes in (ovFadeTick): move range, arcs, rings, aim lines, hex marks and the shield/side rings (ring shader 'fd' uniform). About 5% in the tightest view, full at board zoom.
- closeshot.py: stkind:spire|rig|ring, SEL=1, EVAL=, ZOOMFREE=0 (respect the camera floor), DSF (phone pixel density), one structure at a time.
- Checks: rulecheck, fuzz 20, PC closeshot (phone) and full PC smoke passed.

## v53.8 (Oct 21): sculpted rocks, battle cover, denser big ships (artifact Version 65)
- Merged v53-E: 32-rock sculpted library (rocks/ phone, rocks_hi/ desktop) and the Ithar jade sail glass.
- Battle cover ("Entering battle"): every battle start goes through the establishing shot; a dark cover holds until the ships are built, this battle's hull maps are loaded and uploaded, the sculpted rock set has swapped in and the ships' shaders have compiled (4 s cap, 8 s failsafe). PC load probe (phone size, RTX 5080): before, 6-9 hitches of 100-230 ms in the first 3 s of the battle; after, 0 frames over 50 ms once the cover lifts (cover 2.5-2.9 s; loadprobe e1/e2). Rock files uploaded with the publish (rocks/, rocks_hi/, index.json last).
- Checks: rulecheck, fuzz 20, PC closeshot + worldshot rocks, full PC smoke passed.
- Map-screen prefetch: the fleet's and the sector enemy's hull maps, and the four rock sets, are fetched in the background.
- The twelve biggest hulls (AI_HI_ON_PHONE) load the desktop mesh (38k triangles) and 2K maps on phones and Medium.
- Close-up plating on baked concept hulls (gfx3d HULLFX_AI): staggered panel seams, hatches, raised blocks, faded by pixel footprint so it never shimmers.
- Owner verdict (Oct 21, Pixel and desktop): "everything still feels pretty low poly". Root cause is the Hunyuan image-to-3D shapes themselves (soft, lumpy, the station is not even round), not poly count or textures. Shape bake-off started (see NEXT).
