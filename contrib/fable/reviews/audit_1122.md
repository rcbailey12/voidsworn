# Fable (audit): the Nov 22 merges, read blind

Status: IN PROGRESS. Findings below are saved as they are confirmed; the probe results and the final table follow.

Commit read: main at 513731da. Blind: issue 1723 and contrib/codex/reviews/astra_audit_1122.md were not opened.

Merged PRs read: 1631, 1646, 1666, 1699, 1719, 1709, 1715, 1643, 1698, 1706, 1710, 1714. PR 1721 is not on main and was
not read.

## Findings so far (draft, most important first)

1. SHOULD-FIX (pending a Godot probe). PR 1719 with the death code. A hull that dies while its lights are dipped keeps the
   dip for its whole death. godot/fx/fx_death.gd:2512 `mat = source.duplicate()` copies the live damage surface, with
   whatever fx_flick it holds, into the death material. godot/fx/fx_ship.gd:2424 `_write_flick(1.0)` then resets only the
   live `_damage_surfaces` entries, which are no longer on the mesh.
2. SHOULD-FIX, OBSERVED. PR 1666. A ram kill reaches the effects as "ram" (godot/scenes/battle/battle.gd:2796
   `return "ram"`), so the two "big" branches no longer run for it: godot/fx/fx_death.gd:875
   `if cause == "big" or cause == "flay":` and godot/fx/fx_death.gd:3056 `if cause == "big":`.
3. SHOULD-FIX, OBSERVED. PRs 1631 and 1666. New debris calls use the plain metal shard on every faction:
   godot/fx/fx_ship.gd:2492, godot/fx/fx_death_beats.gd:190, :374. The shard shader glows orange
   (godot/fx/fx_shaders.gd:1088 `EMISSION = vec3(1.0, 0.33, 0.06) * vHeat * 1.2 * fx_gain;`).
4. SHOULD-FIX, OBSERVED (ran the hook). PR 1706. .claude/hooks/guard.cjs:309 refuses any shell command with a word that
   ends in `.key`, such as `board.key(`.
5. SHOULD-FIX, OBSERVED. PR 1710. docs/RULEBOOK.md:296-298 and CLAUDE.md:15-16 still send ship weapon list edits to data.js;
   tools/recipe/gamedata.py no longer reads data.js.
6. SHOULD-FIX, INFERRED. PR 1714. godot/render/build_assets.gd:345-351: a time-limited run starts hashing at the first ship
   folder again each run.
7. NOTE. PR 1666. The rolling burnout archetype ends without the core flash (godot/fx/fx_death.gd:3663), against rule 6.10.
8. NOTE, OBSERVED (ran the hook). PR 1706. `git -c alias.p=push p origin HEAD:main` passes the main guard.
9. NOTE. PR 1699. The pass-by cue is one take of "whoosh", defined in code (godot/audio/sfx.gd:48-52).
10. NOTE. PRs 1699 and 1666. Faction colours typed in by hand in three places.
