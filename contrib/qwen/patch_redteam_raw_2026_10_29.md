# Patch pack red-team, Qwen leg (wave 5, Oct 29, 2026)

Filed verbatim from the Qwen3.8-Max run of Oct 29, 2026 (both model gates passed; chat ca8c694c-9f08-4492-8945-bef3ff491bf8). En dashes and em dashes in the original are normalized to hyphens in this copy; wording is otherwise unchanged. Method notes and the chair screening live in the screening note, not in this file.

PATCH PACK HAS HOLES
Section 1 - Veteran brace bypass (battle.js:1385-1387) | DIFF SOUND
No objections. The inserted check runs at the only point on the mid-move path where canOrder(u,'brace') is still satisfiable (no weapon has fired). The !u.isSq guard is implied by midFire, the thresholds are copied verbatim from line 1396, and giveOrder re-checks canOrder internally (line 1040), so a stale pre-move evaluation cannot force an illegal brace. The pre-move threat/offense evaluation is acknowledged by the pack and bounded by the wide thresholds.
Section 2 - Hive wings invisible to adaptation (battle.js:326) | DIFF SOUND
Objection to the rationale, not the diff: the pack states "a hull whose only hangar comes from the fitted hangar module now also counts," but derive() at core.js:214 returns (fx.hive||0) when t.hangar is falsy - fx.hangar is only additive on an existing template hangar. A module-only hangar ship still reads as hangar 0. The diff is correct for the stated hive defect; the risk note misidentifies a side-effect that does not occur.
Section 3 - Module kind-fit guard (campaign_run.js:128) | DIFF SOUND
The pack asserts line 128 is "the only enforcement point." The excerpts confirm ACT.equip (line 140) performs no kind check, but they do not cover every possible equip surface (e.g., a dedicated shipyard refit flow entered via backShipyard). If another path calls changeShip(s,sh=>sh.mods.push(m)) without passing through fleetScreen's filter, the guard is bypassed. Within the visible code the claim holds.
modFitsKind checks HULLS[s.tpl].w (the template weapon list). The pack notes variants are merged before this screen runs, but the excerpts do not include the merge step, so I cannot confirm the template list is always the fitted list at render time.
Section 4 - Elite guarantee on all-rest column (core.js:268) | DIFF RISKY
The pack states "the new elite survives generation" and points to the budgets loop. However, the shipyard guarantee at line 270 - if(!cols[3].some(n=>n.type==='shipyard')) pick(cols[3]).type='shipyard' - runs after line 268 and before the budgets loop. In the exact failing case (the column's only shipyard was converted to elite), line 270 fires and pick() selects uniformly from all nodes in the column, including the new elite. With probability 1/n (n = column size) it converts the elite back to shipyard, restoring the original defect. The pack does not address this interaction.
If the undo in objection 1 occurs, the subsequent budgets loop (line 275) converts excess rest nodes to battle, not elite, so the column ends with fights but still no elite - the guarantee the comment promises is still broken for that seed.
Section 5 - Mobile layer claims a desktop (scene3d.js:4) | DIFF SOUND
No objections. screen.width/screen.height report the physical display in CSS pixels and are unaffected by window resizing. The coarse-pointer conjunct is unchanged, so genuine phones still classify correctly. Downstream consumers in main3d.js:11 (G.quality, G.fxReduced) key off G.mobile and need no further change. Multi-monitor and small-touch-laptop edge cases are acknowledged.
Section 6 - Eclipse carrier preview naming | NON-REPRODUCTION CONFIRMED
No objections. The excerpts show both preview surfaces resolving through effArch:
Tooltip (line 40) calls archLabel(n, fac), which internally reads ARCHETYPES[effArch(n.arch,fac)] (line 17).
Encounter preview panel (line 55) calls archLabel for the name and ARCHETYPES[effArch(n.arch, ...)].d for the advice line.
No third preview surface appears in the provided excerpts.
Not checked
The contents of MOD_NEED (data.js:259) and the weapon-kind vocabulary in W are not in the excerpts, so the completeness of modFitsKind's kind mapping (e.g., whether 'lance', 'torpedoes', 'flak' match W[id].k exactly) cannot be verified.
The value of COLS is not stated in the excerpts; the section-4 interaction with line 270 assumes COLS-3 === 3. If COLS ≠ 6 the two lines address different columns and the objection weakens, but this cannot be confirmed from the provided text.
Whether any equip path other than ACT.equip (e.g., a shipyard-specific handler) exists outside the excerpted region of campaign_run.js.
The effArch implementation (battle.js:138) is referenced but not excerpted; its remap logic for 'carrier'->'heavy' is taken on the pack's word and the runtime check it cites.
The Godot oracle copies and the built page are not covered by the excerpts or the diffs.
