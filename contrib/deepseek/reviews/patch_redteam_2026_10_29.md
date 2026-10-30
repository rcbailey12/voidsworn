PATCH PACK HAS HOLES

1. Veteran brace bypass | DIFF RISKY
2. `if(!u.isSq && !runner && await tacticBoard(u)){` — the inserted guard returns after bracing before this board check; on the `boardTargets(u).length` path the original suppresses the volley and can still reach `tacticBoard`, while the new code braces and skips it.
3. `const pf=alive('player'), myOff=evalOffense(u,u.weapons.filter(weaponReady),pf), thr=evalThreat(u,pf);` — the brace decision is evaluated pre-move, while the sibling line 1396 decision is evaluated post-move; marginal veterans can brace where post-move numbers would have said fire.
4. Hive wings invisible to enemy point-defense | DIFF RISKY
5. `n=Math.min(cand.length,nCar>=3?cand.length:Math.ceil(cand.length/2));` — raising `nCar0` through `derive(sh).hangar` can push `nCar` to 3 and refit all escorts instead of half, a count change the section does not claim.
6. `B.adaptWings=nCar>=3?2:1;` — the same new `nCar` value can set two adapted wings instead of one, another unclaimed threshold effect.
7. Module kind-fit guard | DIFF RISKY
8. `ACT.equip=arg=>{ const [i,uid]=arg.split(':');` — the equip handler still performs no compatibility check; a direct or stale `data-act` call can equip an incompatible module, so the defect survives outside `fleetScreen`.
9. `const kind=need==='batt'?'battery':need;` — only the `batt` abbreviation is mapped; if any other `MOD_NEED` key does not exactly equal `W[...].k` (e.g. torpedo/torp), the guard silently rejects every hull, and the excerpts do not contain `MOD_NEED` / `W.k` to prove completeness.
10. Elite guarantee on all-rest column 4 | DIFF SOUND
No objections. The conversion survives the later drydock/rest and field passes shown in the excerpts; the acknowledged rest-loss risk is bounded by the separate `COLS-2` rest guarantee.
11. Mobile layer can claim a real desktop | DIFF SOUND
No objections. Replacing the resizable window dimension with the physical screen dimension removes the desktop-resize misclassification; the remaining small-screen touch-device cases are acknowledged and acceptable under the PC-only ruling.
12. Eclipse carrier preview naming | NON-REPRODUCTION CONFIRMED
No objections. The excerpts show `archLabel` resolving through `effArch`, and the encounter preview advice line also reads `ARCHETYPES[effArch(n.arch, ...)].d`; the two named preview surfaces are already effective-archetype-based.

Not checked: runtime acceptance checks and sweeps were not executed; `moveUnit`, `tacticBoard`, `boardTargets`, and `derive()` internals are only partially visible; exact `MOD_NEED` and `W.k` key sets are absent from the excerpts; all callers of `ACT.equip` outside `fleetScreen` are not shown; `effArch`, the Deathless roster, and `FACTIONS.deathless.sq` are not in the excerpts, so section 6 relies on the pack's runtime claim for that part.
