# Pack G: Guard-Pattern Hunt (Qwen)

Filed by Rey from Ryan's paste, Oct 23, 2026. Model: Qwen (attribution confirmed by Ryan). Charter and pack: contrib/muse/prompts/ (Pack G). Screening: contrib/muse/reviews/packFGHI_screening_round2.md. Filed as returned; claims are the model's own and are not verified by filing.

---

Findings

1. ui3d.js:410 (DISCARDED)
Quote: if(set.length){ guard(s); await act(async()=>{
Guard: guard(s)
Protecting: Prevents a ship that has already activated (or isn't the active unit in alternating mode) from taking further actions like firing weapons.
Exploit/Impact: Syntactically, the return value of guard(s) is discarded and the code proceeds immediately to await act(...) to fire the weapons. However, this specific call site is currently unexploitable because the outer if condition already checks canUse(s). Since guard(u) internally relies on canUse(u) to return true, the action is already permitted by the time the discarded guard(s) call executes. If canUse(s) were ever removed or refactored from this block without restoring the if(guard(s)) check, players could select an already-activated ship in Alternating mode, click an enemy, and fire all its weapons again, completely bypassing the activation limit.
No other instances of a boolean-returning guard being called as a bare statement while the forbidden action proceeds were found in this pack. The codebase is otherwise highly disciplined about checking these predicates before executing state-changing actions.

Call-Site Classification Table

| Guard / Predicate | File:Line | Classification | Notes |
|---|---|---|---|
| guard(u) | ui3d.js:403-406 | CHECKED | Gates boarding, blinking, nova, and launching via click. |
| guard(u) | ui3d.js:410 | DISCARDED | Redundantly gated by canUse(s) in the same block. |
| guard(u) | ui3d.js:411, 414 | CHECKED | Gates attack-move and standard movement. |
| guard(u) | ui3d.js:499-515 | CHECKED | Gates keyboard shortcuts and UI button actions. |
| canUse(u) | ui3d.js:410 | CHECKED | Outer gate for firing on enemy click. |
| canFire(u,w,t) | battle.js:569 | CHECKED | Enforced inside fireWeapon (unless opts.intercept is true for flak). |
| weaponReady(w) | battle.js:456 | CHECKED | Enforced inside canFire. |
| canAbility(u) | battle.js:933 | CHECKED | Enforced at the start of useAbility. |
| canOrder(u,o) | battle.js:799 | CHECKED | Enforced at the start of giveOrder. |
| canCommand(side) | battle.js:848 | CHECKED | Enforced at the start of useCommand. |
| inThisBattle(u) | battle.js:432, 449, 567, 933 | CHECKED | Enforced at the start of movement, rotation, firing, and abilities. |
| boardTargets(u) | battle.js:668 | CHECKED | Enforced at the start of boardUnit. |
| ramInfo(u) | battle.js:638 | CHECKED | Enforced at the start of ramUnit. |
| aiRefreshFocus() | battle.js:356 | SIDE-EFFECT ONLY | Returns the focus target object, but called primarily to update the sticky B.aiFocus state at turn start. |

Not checked
External Files: data.js (hull/weapon definitions, factions, admirals), math.js / hex.js (hex math, inArc, hdist), scene3d.js / anim3d.js (BabylonJS rendering, animations, animPath, animWeapon), and persist.js / meta.js (save/load logic).
CSS/HTML: The index.html and stylesheet files were not examined for UI-level bypass vulnerabilities (e.g., disabled buttons being forced enabled via DOM manipulation).
Network/Telemetry: The tel() function and backend validation of telemetry reports were not audited.

Questions this pack cannot answer
Flak Intercept Rules: In battle.js:569, fireWeapon skips the canFire check if opts.intercept is true. Does the flak weapon's cdLeft or fired state get manually decremented/set elsewhere during the intercept sequence, or can a single flak gun intercept multiple squadron waves in the same activation without reloading?
Stall Guard Epochs: stallGuard increments B.epoch if an action takes too long. If a player triggers a stall during a multi-shot volley, fireWeapon aborts and restores the gun's fired/cdLeft state. Does the UI properly reflect this restored state immediately, or does the player see the gun as "fired" until the next refresh?
Classic Mode Activation: In Classic mode (B.alt === false), canUse(u) returns true regardless of u.activated. Is there a hard rule in the unprovided data.js or UI layer that prevents a player from manually clicking "End Turn" before all ships have acted, or can a player intentionally skip ships in Classic mode?
Boss Command Targeting: bossCmdFire executes the enemy flagship's command. If the flagship is destroyed after the command is announced but before the round it fires, bossCmdTick sets B.cmdEUsed = true. Does the UI properly clear the "Preparing..." banner, or does it persist as a ghost overlay?
Squadron Leash: sqPlan uses SQ_LEASH (8 hexes). If a carrier is destroyed, sqPlan attempts to fly the squadrons "home" toward the carrier's last known location. Do the squadrons despawn when they reach the dead carrier's hex, or do they remain on the board indefinitely as stranded units?
Relic/Boon Stacking: The pack references runFx() and BOONS but doesn't contain their definitions. Do boons like s_arc (shorts the generator) and s_ion (strips extra shield) stack multiplicatively or additively, and is there a cap on shield stripping that could cause negative shield values?
Dead Star Gravity: wellTick applies tidal stress and gravity pulls. If a ship is pulled into a hex occupied by a wreck (hulk), does passable or canEnd correctly prevent the overlap, or does the gravity well force ships to stack on top of wrecks?
