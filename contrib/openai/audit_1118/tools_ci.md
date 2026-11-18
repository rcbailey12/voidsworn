# Issue 1092: PC runner, ship tools and CI audit

Main read: `a3f5ea2f478d7adef76100a71af756e065377dba` (`a3f5ea2f`), the checkout and `origin/main` in this run.

## Top ten

1. Two launches on one Codex lane can switch the checkout under each other or overwrite the same run's status.
2. An old queue entry can start an issue after the Board has moved it to another seat.
3. The workhorse can remove its local copy after a partial push or failed checks, if cleanup is on.
4. A failed runner can send PC paths to a public issue; raw log text can also enter public commits.
5. A GPU job can wait forever before the timeout even starts.
6. A ship install can pass with the old files or leave the shared build half-updated.
7. The A16 freshness check can pass even if the baked test file is wrong.
8. Stage 7 accepts two port origins and none on starboard for braking and boarding.
9. Double-clicking Play can start a new executable after that build failed its own checks.
10. CI's punctuation check silently misses files by type and by name.

**Start with 1 and 2:** use one runner-start contract for checkout ownership and the assigned branch. Prove that a losing launch cannot touch the winner's files or start a model. [Findings and proof](#ranked-confirmed-findings).

## Files read

Full static pass over the raw blobs at the commit above: 781 tracked files, all read to EOF; 772 text files and 102,137 lines, plus nine audio blobs. The pass parsed all Python and JSON, checked all JavaScript and PowerShell syntax, and scanned launch, copy, exit and error paths. The findings below use direct code reads and caller traces or small offline reproductions; the pass did not execute each script. Generic A4 tools are inventoried, but replaced A4 hulls were excluded from findings under R323.

Inventory format: `@` gives the repo-relative directory. Each row gives the relative file name, line count, and first 40 characters of the last line as a JSON string (`""` means a blank last line). Audio rows give format-independent byte counts instead of text lines. Files over 60 KB were included in the full read; for reference, their line ranges were:

| Path | Lines in the full read |
|---|---|
| `tools/blender/build_sheets/kit.py` | 1-550, 551-1095 |
| `tools/blender/kits/chorus/parts.py` | 1-550, 551-1061 |
| `tools/blender/kits/eclipse/parts.py` | 1-500, 501-935 |
| `tools/blender/kits/hullbreakers/parts.py` | 1-550, 551-1073 |
| `tools/blender/kits/shared/paint_stack.py` | 1-450, 451-900, 901-1288 |
| `tools/blender/kits/voidsworn/parts.py` | 1-500, 501-942 |
| `tools/pc/mission/fixtures/nov17.json` | 1-350, 351-700, 701-1050, 1051-1139 |
| `tools/pc/runner_selftest.js` | 1-400, 401-800, 801-1091 |
| `tools/portraits/batches/p64ga.json` | 1-205, 206-406 |
| `tools/portraits/batches/p64gn.json` | 1-205, 206-410, 411-606 |
| `tools/portraits/batches/p64hn.json` | 1-175, 176-342 |
| `tools/portraits/batches/v64h.json` | 1-150, 151-300, 301-446 |
| `tools/portraits/batches/v64h2.json` | 1-150, 151-300, 301-446 |
| `tools/portraits/make_batches.py` | 1-300, 301-600, 601-813 |

### Workflows, recipe and other tools

```text
@ .github/workflows
auto_pr.yml 106 "          fi"
checks.yml 239 "          python3 tools/recipe/sheet_fix"
main_commit_lint.yml 66 "          PY"
open_work_nightly.yml 65 "          fi"
@ tools
build_clips.py 69 "open('sfx_data.js','w').write(js); print"
onboarding_cards.json 77 "]"
onboarding_sheets.ps1 43 "Write-Output 'PASS: retained teaching ca"
pacecheck_godot.sh 46 "if [ $F -eq 0 ]; then echo \"PASS: every "
picture_font.json 1 "{\" \":[0,0,0,0,0,0,0,0,0,0,0],\"!\":[0,0,0,"
picture_provenance.py 401 "    sys.exit(main())"
test_onboarding.js 104 "fs.writeFileSync(path.join(out, 'PASS.tx"
test_onboarding_gate.js 61 "`);"
@ tools/music
catalogue.json 38 "}"
music_dl.ps1 61 "L 'MUSIC DL DONE'"
process.py 212 "    elif a[0] == 'loopfind': print(loopf"
seamcheck.py 32 "            print('%-28s jump %5.2f  ste"
selection.json 530 "}"
@ tools/music/audition_2026_11
LISTEN_SHEET.md 99 "played a battle or two."
jingle_HIT00.ogg binary 8650
jingle_HIT03.ogg binary 13944
jingle_HIT04.ogg binary 11424
jingle_HIT07.ogg binary 8707
jingle_HIT09.ogg binary 15477
jingle_HIT11.ogg binary 17932
jingle_HIT15.ogg binary 19626
jrpg_battle_theme.ogg binary 752003
orbital_colossus.mp3 binary 6066975
@ tools/portraits/batches
b1a.json 52 "}"
b1b.json 79 "}"
b1c.json 123 "}"
b1q.json 96 "}"
b2.json 75 "}"
c64.json 182 "}"
c64b.json 182 "}"
c64c.json 182 "}"
e64a.json 202 "}"
e64b.json 216 "}"
e64c.json 146 "}"
e64d.json 34 "}"
e64e.json 34 "}"
f64.json 69 "}"
f64b.json 195 "}"
k64.json 188 "}"
k64b.json 120 "}"
k64c.json 237 "}"
k64d.json 281 "}"
n1a.json 204 "}"
n1b.json 204 "}"
n1fix.json 41 "}"
n1s_a.json 195 "}"
n1s_b.json 195 "}"
n1s_c.json 90 "}"
n1s_c2.json 90 "}"
n2.json 204 "}"
n3.json 66 "}"
p64ga.json 406 "}"
p64gn.json 606 "}"
p64ha.json 230 "}"
p64hn.json 342 "}"
r8a.json 162 "}"
r8b.json 104 "}"
r8c.json 28 "}"
r8e.json 202 "}"
r8f.json 111 "}"
r8s_a.json 174 "}"
r8s_b.json 216 "}"
r8s_c.json 258 "}"
s64g.json 174 "}"
s64h.json 258 "}"
s68a.json 272 "}"
s68b.json 258 "}"
s68c.json 216 "}"
s68g.json 160 "}"
s68h.json 230 "}"
s68i.json 146 "}"
s68j.json 27 "}"
v64g.json 446 "}"
v64g2.json 438 "}"
v64g3.json 90 "}"
v64h.json 446 "}"
v64h2.json 446 "}"
v64h3.json 336 "}"
v64h4.json 146 "}"
v64h5.json 132 "}"
v64h6.json 62 "}"
@ tools/portraits
concept_sheets.py 73 "        for sp in SPECIES: sheet(src, ou"
crests.py 264 "    except ImportError as e: print('no s"
make_batches.py 813 "        print(k, len(items), 'items', su"
make_edits.py 423 "    json.dump({'out': 's68', 'budget_s':"
nemesis_crop.py 53 "    json.dump(A, open(os.path.join(out, "
nemesis_fx.py 140 "    print('frames and scars written to',"
nemesis_publish.py 87 "    main(sys.argv[1], sys.argv[2])"
p64_publish.py 94 "    elif a[0] == 'crops': crops(a[1], a["
phone_sheets.py 63 "    admirals(out); nemesis(out)"
picks_b1b2.json 16 "}"
plates.py 22 "    for f in GLOW: plate(f).save(os.path"
portrait_dl.ps1 36 "L 'PORTRAIT DL DONE'"
portrait_edit.py 41 "    main(sys.argv[1])"
portrait_run.py 162 "    elif a[0] == 'gen': gen(a[1])"
portrait_specs.py 179 "    return EDIT.format(what=what, settin"
post.py 112 "    elif a[0] == 'phone': cmd_phone_shee"
r8_prep.py 61 "    main(sys.argv[1], sys.argv[2])"
r8_publish.py 36 "    main(sys.argv[1])"
v64_publish.py 194 "    elif a[0] == 'sheet': sheet(a[1], a["
@ tools/recipe
1_concept_in.bat 23 "exit /b 1"
2_shape_ref.bat 28 "exit /b 1"
3_trace_hull.bat 55 "exit /b 1"
4_parts_kit.bat 55 "exit /b 1"
5_paint_bake.bat 72 "exit /b 1"
6_lod.bat 32 "exit /b 1"
7_export.bat 71 "exit /b 1"
audit.py 57 "sys.exit(0 if au['result'] == 'PASS' els"
audit_selftest.py 80 "sys.exit(0 if ok else 1)"
blink.py 45 "    sys.exit(main(a[0], a[1], a[2], a[3]"
check_export.py 341 "    main()"
check_export_selftest.py 240 "sys.exit(1 if bad else 0)"
contract_selftest.py 255 "    sys.exit(main())"
contract_tables_selftest.py 77 "    sys.exit(main())"
density.py 94 "    return dict(summary=summary, types=o"
env.bat 53 "if \"%HULL%\"==\"\" echo WARNING: ships\\%SHI"
export7.py 521 "print('[export7] written', OUT, flush=Tr"
gamedata.py 74 "    print(weapons(sys.argv[1]))"
interiors_export_probe.py 36 "    runpy.run_path(os.path.join(here, 'e"
interiors_sheets.py 36 "      'Issue 557 / authored joint moved "
manifest_merge.py 29 "    sys.exit(main(sys.argv[1], sys.argv["
sheet_contract_selftest.py 102 "sys.exit(1 if bad else 0)"
sheet_fixture_hash.py 66 "    print('wrote', OUT, d)"
ship.py 72 "    im.save(sys.argv[3]); print('wrote',"
stage5_fail_selftest.bat 6 "exit /b %ERRORLEVEL%"
stage5_fail_selftest.js 513 "});"
standing.py 280 "    sys.exit(main())"
station_paint.bat 4 "exit /b %ERRORLEVEL%"
station_review.bat 4 "exit /b %ERRORLEVEL%"
surface_check.py 86 "for nme, c in sorted(seen.items(), key=l"
turret_fixture.py 95 "print('[turret_fixture] written', OUT)"
@ tools/recipe/ships
C15s_23.json 301 "}"
_template.json 22 "}"
_turret_fixture.json 15 "}"
chorus_C10.json 22 "}"
chorus_C11.json 22 "}"
chorus_CS1BA2.json 22 "}"
corsair_A16.json 22 "}"
corsair_A17.json 22 "}"
corsair_A18.json 22 "}"
corsair_A19.json 22 "}"
corsair_A20.json 22 "}"
corsair_KB1CC.json 22 "}"
deathless_E11.json 22 "}"
deathless_E12.json 22 "}"
deathless_E12_turreted.json 14 "}"
deathless_E13.json 22 "}"
deathless_E13_sentinel.json 14 "}"
deathless_E14.json 22 "}"
deathless_E14_guard.json 14 "}"
hegemony_H10.json 22 "}"
hegemony_HF1D.json 22 "}"
hegemony_IM5.json 22 "}"
voidsworn_S8.json 22 "}"
voidsworn_SB4.json 22 "}"
voidsworn_SF3.json 22 "}"
@ tools/recipe/stations
station_T2.json 45 "}"
@ tools/shots
ui344_briefing_sheet.py 80 "    sys.exit(main())"
ui344_contact_sheet.py 99 "    sys.exit(main())"
```

### PC tools

```text
@ tools/pc
audio_checks.bat 49 "exit /b 0"
autostart_off.bat 9 "pause"
autostart_on.bat 16 "pause"
bake_all.bat 4 "echo done > \"%USERPROFILE%\\Downloads\\voi"
bake_uv.bat 22 "echo done > %T%\\bakeuv_done.txt"
blender_setup.ps1 26 "} catch { \"FAILED $_\" | Out-File -Encodi"
chain_issue.bat 14 "exit /b %ERRORLEVEL%"
claude_api_key.bat 16 "pause"
codex_board.bat 10 "goto loop"
codex_board.ps1 40 "if ($found -eq 0) { Write-Host \"[$stamp]"
codex_issue.bat 234 "exit /b 9"
codex_issue.ps1 139 "} else { Write-Host 'usage: codex_issue."
codex_run.bat 31 "exit /b %RC%"
comfy_dl.ps1 43 "} catch { L (\"FAILED \" + $_.Exception.Me"
comfy_probe.ps1 32 "L 'PROBE DONE'"
comfy_run.py 179 "        import traceback; log('FAILED', "
errprobe.py 22 "    print('\\n'.join(errs[:40])); b.close"
fx_run.bat 19 "echo FX DONE %date% %time% >> %T%\\fx_log"
get_ship_files.bat 94 "exit /b 0"
godot_setup.ps1 22 "} catch { \"FAILED $_\" | Out-File $log -A"
gpu_slots.js 188 "module.exports = { Slots, modeFor, weigh"
hy_bakeoff.py 27 "log('HY BAKEOFF DONE')"
issue-377-auto_pr.patch 24 "           open=$(gh pr list -R \"$REPO\" "
kimi_code_key.bat 15 "pause"
lane_tools_refresh.ps1 192 "}"
lane_tools_refresh_selftest.js 39 "console.log('PASS: lane tools refresh ke"
openai_api_key.bat 18 "pause"
parity.bat 43 "endlocal & exit /b %RESULT%"
parity_campaign.bat 73 "exit /b"
parity_sweep.bat 59 "exit /b"
pause_all.bat 7 "powershell -NoProfile -ExecutionPolicy B"
pause_all.ps1 247 "}"
pause_all_selftest.js 341 "assert.equal(run.status, 0, 'pause fixtu"
pcsync.sh 8 "ls $DST | wc -l"
play.bat 10 "start \"\" msedge --new-window \"http://127"
play_godot.bat 45 "exit /b 0"
play_godot_safe.bat 3 "call \"%~dp0play_godot.bat\" --rendering-m"
review_evidence.ps1 27 "exit $LASTEXITCODE"
rocks_bake.bat 12 "echo done > %T%\\rocks_done.txt"
rules_safety.bat 32 "exit /b %RESULT%"
run_smoke.bat 23 "echo DONE > smoke_done.txt"
run_timeout.ps1 293 "}"
runner_board_dryrun.bat 9 "exit /b %AUDIT_EXIT%"
runner_claim_fixture.js 62 "};"
runner_common.ps1 866 "exit 0"
runner_selftest.bat 6 "exit /b %ERRORLEVEL%"
runner_selftest.js 1091 "} })();"
runner_selftest_shell.js 149 "};"
runner_selftest_shell.ps1 50 "}"
saved_results.bat 28 "endlocal & exit /b %RESULT%"
setup.bat 24 "echo SETUP DONE > setup_done.txt"
sfx_dl.bat 27 "echo done > \"%USERPROFILE%\\Downloads\\voi"
sitecustomize.py 45 "except Exception as e: print('shim: goto"
tex_dl.ps1 22 "\"textures: \" + $rows.Count"
tmo.bat 15 "exit /b %ERRORLEVEL%"
trellis_bakeoff.py 64 "log('TRELLIS BAKEOFF DONE')"
trellis_dl.ps1 19 "} catch { L (\"FAILED \" + $_.Exception.Me"
trellis_fleet.py 72 "log('TRELLIS BAKEOFF DONE')"
voidsworn_prompts11.json 76 "}"
vs_art_o.py 60 "log(P['done'])"
vs_mesh12.py 38 "log('PICKS9 DONE')"
watcher.bat 38 "goto loop"
watcher_b.bat 31 "goto loop"
work_cleanup_setting.bat 34 "exit /b 0"
work_issue.bat 466 "exit /b %RC%"
work_issue.ps1 692 "else { Write-Host 'usage: work_issue.ps1"
work_pro_120.bat 43 "exit /b 0"
work_setup.bat 124 "exit /b 0"
work_trial.bat 45 "exit /b 0"
@ tools/pc/comfy_custom
voidsworn_pixal_views.py 35 "NODE_DISPLAY_NAME_MAPPINGS = {'Voidsworn"
@ tools/pc/jobs
A16_RUN_601.bat 54 "exit /b 0"
A17_RUN_532.bat 44 "exit /b 0"
A18_A20_PAINT_651.bat 90 "exit /b 0"
A18_A20_RUN_633.bat 75 "exit /b 0"
C10_C11_RUN_623.bat 73 "exit /b 0"
E11_E12_PAINT_642.bat 96 "exit /b 0"
E11_E12_PAINT_642c.bat 99 "exit /b 0"
E11_E12_PAINT_642d.bat 146 "exit /b 0"
E11_E12_RUN_618.bat 51 "exit /b 0"
HB_PAINT_726.bat 7 "exit /b %ERRORLEVEL%"
PAINT_RUN_601.bat 64 "exit /b 0"
a2_detail.bat 60 "cd /d \"%~dp0\""
a3_godot_fx.bat 37 "cd /d \"%~dp0\""
a4_barge.bat 19 "exit /b"
a4_damage.bat 27 "exit /b"
a4_lineup.bat 11 "exit /b"
a4_looks.bat 15 "exit /b"
a4_regen.bat 14 "exit /b"
a4_repaint.bat 28 "exit /b"
a4_ship.bat 42 "exit /b"
bench207_scene_gate.bat 119 "exit /b 1"
bench207_scene_gate_repeat.bat 28 "exit /b 0"
bench207_scene_gate_res.bat 29 "exit /b 0"
c19_10_kitdark_probe3.bat 29 "cd /d \"%~dp0\""
c19_11_normals_probe.bat 21 "cd /d \"%~dp0\""
c19_12_hull_face_probe.bat 29 "cd /d \"%~dp0\""
c19_13_faceout.bat 28 "cd /d \"%~dp0\""
c19_14_plating_finish.bat 67 "cd /d \"%~dp0\""
c19_14b.bat 67 "cd /d \"%~dp0\""
c19_14c.bat 70 "cd /d \"%~dp0\""
c19_14d_shots.bat 34 "cd /d \"%~dp0\""
c19_14e_probe.bat 30 "cd /d \"%~dp0\""
c19_14f_probe.bat 29 "cd /d \"%~dp0\""
c19_14g.bat 30 "cd /d \"%~dp0\""
c19_1_views.bat 6 "cd /d \"%~dp0\""
c19_1b_views_front_back.bat 8 "cd /d \"%~dp0\""
c19_2_mesh_fit_paint.bat 32 "goto :eof"
c19_3_lod.bat 33 "cd /d \"%~dp0\""
c19_4_kit_to_game.bat 49 "cd /d \"%~dp0\""
c19_5_flatten_panels.bat 39 "cd /d \"%~dp0\""
c19_6_shell_to_game.bat 55 "cd /d \"%~dp0\""
c19_7_infill.bat 37 "cd /d \"%~dp0\""
c19_7_repack_only.bat 37 "cd /d \"%~dp0\""
c19_8_kitdark_probe.bat 30 "cd /d \"%~dp0\""
c19_9_kitdark_probe2.bat 27 "cd /d \"%~dp0\""
c19_v15c.bat 62 "cd /d \"%~dp0\""
c19_v15d.bat 77 "cd /d \"%~dp0\""
eclipse_642d_proof.py 138 "    main()"
env230_motion.bat 82 "exit /b 0"
explosion_routes.bat 130 "exit /b 0"
explosion_routes_sheet.py 157 "    main()"
fx_inside_capture.bat 42 "exit /b 2"
g2_battle_shots.bat 24 "exit /b 0"
g2_checks.bat 15 "exit /b 0"
g2_export.bat 51 "exit /b 1"
g2_playtest_capture.bat 80 "exit /b 0"
godot_gpu_checks.bat 94 "goto :eof"
hb_paint_726.ps1 229 "exit 0"
hb_paint_726_logs.ps1 18 "}"
hb_paint_726_pictures.py 70 "    main()"
lb_overlay_ship.bat 50 "exit /b 0"
look_bench.bat 168 "exit /b 0"
look_bench_sheets.py 315 "    sys.exit(main())"
nem122_checks.bat 33 "exit /b 0"
planet369_bench.bat 70 "exit /b %ERRORLEVEL%"
planet369_board.patch 13 " func show_blockers(hexes: Array) -> voi"
planet369_check.bat 6 "exit /b %ERRORLEVEL%"
planet369_check.gd 113 "\tquit(1 if failures else 0)"
planet369_download.bat 8 "exit /b %ERRORLEVEL%"
planet369_download.py 111 "    run()"
planet369_pack.bat 10 "exit /b %ERRORLEVEL%"
planet369_pack.gd 49 "\tquit(0)"
planet369_pack.py 70 "    run()"
planet369_probe.gd 211 "\tPG.finish(0)"
planet369_remix.bat 10 "exit /b %ERRORLEVEL%"
planet369_remix.py 293 "        rocks()"
planet369_scale.patch 52 " When issue 368, 369 or 373 lands, it ch"
planet369_sheets.bat 8 "exit /b %ERRORLEVEL%"
planet369_sheets.py 99 "    run()"
planet369_showcase.gd 126 "\tPG.finish(0)"
q_a16_601.bat 5 "exit /b 0"
q_a17_532.bat 2 "start \"a17run\" /min cmd /c \"%USERPROFILE"
q_a633.bat 3 "start \"a633run\" /min cmd /c \"%USERPROFIL"
q_c623.bat 3 "start \"c623run\" /min cmd /c \"%USERPROFIL"
q_e618.bat 2 "start \"e618run\" /min cmd /c \"%USERPROFIL"
q_paint_601.bat 5 "exit /b 0"
q_paint_642.bat 6 "exit /b 0"
q_paint_642c.bat 6 "exit /b 0"
q_paint_642d.bat 6 "exit /b %ERRORLEVEL%"
q_paint_651.bat 5 "exit /b 0"
stall220.bat 39 "exit /b 0"
stall220_stills.bat 30 "exit /b 0"
station_blockout.bat 26 "exit /b %RC%"
tex_download.bat 6 "cd /d \"%~dp0\""
ui231_shots.bat 36 "exit /b 0"
ui271_build_shots.bat 50 "exit /b 0"
ui344_briefing_shots.bat 75 "exit /b 0"
ui344_rollout_shots.bat 63 "exit /b 0"
v13k_winding_audit.bat 29 "cd /d \"%~dp0\""
@ tools/pc/mission
PHONE_OFF.bat 10 "exit /b %RESULT%"
PHONE_ON.bat 10 "exit /b %RESULT%"
browser_test.js 419 "run().catch(error=>{console.error('FAIL "
budget.js 50 "module.exports = {Budget, sourceRecord, "
deploy.ps1 235 "}"
phone.js 158 "if (require.main === module) main(proces"
phone_selftest.js 190 "module.exports = {test};"
publisher.js 850 "}"
queue.js 146 "module.exports = {filePattern, laneId, n"
selftest.bat 9 "exit /b %RESULT%"
selftest.js 749 "if(require.main===module)test().catch(e="
start.bat 10 "exit /b %RESULT%"
tailscale.js 34 "module.exports = { findTailscale, dnsNam"
@ tools/pc/mission/fixtures
deck.json 26 "}"
flight_plan.json 24 "}"
github.json 127 "}"
night.json 118 "}"
nov17.json 1139 "}"
@ tools/pc/mission/fixtures/gap
codex_chain_fixture.txt 3 "918 end 16:29:00.00"
@ tools/pc/mission/fixtures/gap/board/issue-918
result.txt 1 "runner status: checked_push (non-partial"
status.json 7 "}"
@ tools/pc/mission/fixtures/lanes
CODEX_CHAIN_FIXTURE.bat 5 "call \"%V%\\build_b\\tools\\pc\\codex_issue.b"
CODEX_CHAIN_NEXT.bat 2 "for %%N in (923) do call :one %%N"
CODEX_LANE_B22.bat 2 "for %%N in (922) do call :one %%N"
CODEX_LANE_C19.bat 2 "for %%N in (914) do call :one %%N"
CODEX_LANE_D1.bat 2 "for %%N in (889) do call :one %%N"
DS_FIXTURE.bat 2 "call \"%V%\\RUN_RETRY.bat\" 916 deepseek 72"
codex_chain_fixture.txt 2 "918 start 16:15:00.00"
codex_chain_next.txt 1 "waiting for codex_chain_fixture.txt from"
codex_lane_b22.txt 1 "waiting for codex_lane_b21.txt from Mon "
codex_lane_c19.txt 4 "all done 16:10:00.00"
codex_lane_d1.txt 4 "all done 16:10:00.00"
ds_fixture.txt 1 "916 start Mon 11/16/2026 15:45:00.00"
@ tools/pc/mission/fixtures/lanes/board/issue-918
log.txt 2 "Fixture progress. No real log text."
result.txt 3 "agent running 16:15:04"
status.json 7 "}"
@ tools/pc/mission/fixtures/lanes/board_c/issue-914
log.txt 1 "# Codex job: issue #914, \"Runner claim c"
result.txt 1 "chain stopped: predecessor ended partial"
status.json 7 "}"
@ tools/pc/mission/fixtures/lanes/board_d/issue-889
log.txt 1 "# Codex job: issue #889, \"Review picture"
result.txt 1 "runner status: checked_push"
status.json 7 "}"
@ tools/pc/mission/fixtures/lanes/work217/issue-916-deepseek
latest.txt 1 "@ROOT@/work217/issue-916-deepseek/202611"
@ tools/pc/mission/fixtures/lanes/work217/issue-916-deepseek/20261116_154500/out
log.txt 1 "# Workhorse job: issue #916, \"Stage 5 se"
result.txt 1 "agent running 15:45:01"
status.json 7 "}"
@ tools/pc/work
README.md 239 "  variants written in, it goes out with "
kimi_effort_smoke.js 249 "})();"
mock_llm.js 124 "server.listen(port, '127.0.0.1');"
opencode.json 74 "}"
opencode_lean.json 152 "}"
opencode_mock.json 140 "}"
```

### Blender tools

```text
@ tools/blender
README.md 6 "- fxsim.py: Mantaflow explosion sims ren"
bake_all.py 22 "LOG.write('BAKE ALL DONE\\n')"
fitcam_fit.py 29 "r = {'az': az, 'el': el, 'iou': float(v)"
fitcam_render.py 19 "print('SILS DONE')"
fix_hull.py 44 "json.dump(j,open(f,'w')); print(f,'tris'"
fxsim.py 64 "print('[fx] DONE', VAR, flush=True)"
hullbake.py 195 "log('done verts', len(P), '->', len(P2),"
lod_make.py 14 "    print('LOD', n, 'from', f0, '->', le"
mv_prep.py 40 "sheet.resize((S, S)).save(os.path.join(o"
paint_level.py 27 "    print(level(sys.argv[1], sys.argv[2]"
pixal_to_game.py 128 "print(code, 'verts', n, 'tris', len(I), "
project_paint.py 200 "    bpy.ops.export_scene.gltf(filepath=o"
render_multi.py 49 "    sc.render.filepath = f'{pre}{k}.png'"
rockgen.py 75 "        t = to_json(ob, os.path.join(OUT"
rocks_bake.py 13 "LOG.write('ROCKS DONE\\n')"
trellis_bake.py 126 "log('done verts', len(P), 'tris', len(I)"
trellis_fleet_bake.sh 14 "done"
uvprep.py 23 "    print(code, res, 'charts', at.chart_"
vsm_pack.mjs 15 "console.log(code, 'verts', unique, 'tris"
wreck_kit.py 292 "    stream.write(\"\\n\")"
@ tools/blender/a1
barge_shapes.py 203 "    print(clay.render_views(pre, views=("
barge_v15.py 244 "    if '--export' in a: export(shells, k"
clay.py 71 "    print(render_views(a[0], views=('q',"
render_v15.py 31 "print(outs)"
sheet.py 41 "print('ok')"
@ tools/blender/a2detail
a2_barge.py 164 "    main()"
a2_ship.py 257 "    main()"
bakemat.py 207 "    return m, dict(albedo=albedo, orm=or"
blmesh.py 113 "    a = image_to_numpy(im)[..., :3].copy"
checks.py 110 "    return outs"
checks_glb.py 28 "except ImportError: print('[checks] rend"
checks_sheet.py 38 "          f'C19_51 Pyre-Barge v15, {res}"
dress.py 559 "    return n"
hullio.py 206 "    return dict(tris=len(I) // 3, verts="
pack_glb.py 45 "        for p in a: pack(p)"
reimport.py 17 "    print('[reimport]', os.path.basename"
spires.py 104 "    return symmetrize(out, .0045)"
@ tools/blender/a4
K1_DECISIONS.md 143 "`godot/assets/ships/README.md`."
README.md 124 "- The game's hull JSON (unchanged): x bo"
a4_ship.py 425 "    main()"
bakemat4.py 367 "    return m, dict(albedo=albedo, orm=or"
barge4.py 183 "    main()"
chain.py 38 "    main()"
compose.py 89 "    return idx[keep]"
concept.py 487 "    if '--apply' in a: apply(a[0], op, r"
cuts.py 103 "    return idx[~cut_all], rims, rep"
cview.py 77 "W.save(out, quality=88); print('sheet', "
damage.py 472 "            'edge': mk('damage_edge', ed"
dmgview.py 88 "    else: main()"
dress4.py 244 "    return made"
faired.py 122 "        i = int(np.argmin(abs(xs - x)));"
frame.py 70 "    return h"
gio.py 171 "    return dict(tris=tris, ext=[round(fl"
godot_check.gd 36 "\t\t_walk(c, d + 1)"
ingame_sheet.py 153 "        sheet(bdir, adir, fac, title, co"
ithar.py 69 "    return nm, mm"
kit.py 737 "    return made"
lineup.py 165 "    else: main()"
livery.py 87 "    return out.reshape(res, res, 3), mas"
look.py 178 "    else: main()"
manifest.py 62 "    main(*sys.argv[1:4])"
pack.py 198 "        pack(a[0], a[a.index('--hi') + 1"
probe.py 48 "        print(f'{c:+7.3f} ' + ' '.join('"
reshape.py 111 "    n = acc[w]; L = np.linalg.norm(n, ax"
sheet.py 10 "        checks_sheet.make(sys.argv[1], c"
ships.py 611 "    kit=[], notes='pass 1: stands uprigh"
stage.py 63 "    main()"
wreck.py 104 "    return out"
@ tools/blender/build_sheets
build.py 340 "print('WROTE', blend)"
clash.py 463 "    return res"
contract.py 199 "                slots=[f'{i} {wk} {arc}'"
fit.py 112 "_save_picture(Image.fromarray(dif), outp"
inventory.py 177 "sys.exit(1 if bad else 0)"
kit.py 1095 "        self.tbd.append(what)"
layout.py 590 "print('sheet', sheet.size, 'preview', pv"
paint_compare.py 146 "    main()"
paint_sheet.py 195 "json.dump(dict(shots=shots, windows=wind"
publish.py 71 "print('published', D)"
render_sheets.bat 14 "pause"
sheet_extras.py 374 "print('extras written', OUT)"
variant_parts.py 22 "    return base"
variant_review.py 103 "    main()"
variant_selftest.py 165 "    main()"
variants.py 42 "    return K"
weapon_match.py 285 "    return result, probs"
weapon_match_selftest.py 421 "    sys.exit(main())"
@ tools/blender/build_sheets/ships
chorus_C10.py 556 "    # fixes found by the fit check on th"
chorus_C10_camera.json 21 "}"
chorus_C10_inv.py 76 "STRUCTURE_NOTE = 'C10 sheet: bow = the t"
chorus_C11.py 316 "    K.open_item('The belly is designed h"
chorus_C11_camera.json 21 "}"
chorus_C11_inv.py 64 "STRUCTURE_NOTE = 'C11 sheet: bow = the t"
chorus_CS1BA2.py 232 "    K.open_item('How a sheet craft reach"
chorus_CS1BA2_camera.json 21 "}"
chorus_CS1BA2_inv.py 46 "INV_NOTES = {}"
corsair_A16.py 298 "    return bpy.data.objects[name]"
corsair_A16_camera.json 21 "}"
corsair_A16_inv.py 88 "]"
corsair_A17.py 299 "          'R289 and R292: the broad fore"
corsair_A17_camera.json 21 "}"
corsair_A17_inv.py 65 "]"
corsair_A18.py 311 "    K.open_item('Belly detail between th"
corsair_A18_camera.json 21 "}"
corsair_A18_inv.py 74 "]"
corsair_A19.py 270 "    K.open_item('Belly detail between th"
corsair_A19_camera.json 21 "}"
corsair_A19_inv.py 70 "]"
corsair_A20.py 465 "    K.open_item('Belly detail between th"
corsair_A20_camera.json 21 "}"
corsair_A20_inv.py 79 "]"
corsair_KB1CC.py 512 "    K.open_item('How a sheet craft reach"
corsair_KB1CC_camera.json 21 "}"
corsair_KB1CC_inv.py 61 "INV_NOTES = {}"
deathless_E11.py 345 "    K.fix('T1 (fore twin) firing aft blo"
deathless_E11_camera.json 21 "}"
deathless_E11_inv.py 70 "]"
deathless_E12.py 278 ""
deathless_E12_camera.json 21 "}"
deathless_E12_camera_fwd.json 21 "}"
deathless_E12_inv.py 55 "]"
deathless_E13.py 307 "    K.fix('C1 (the core) gimbal ring ins"
deathless_E13_camera.json 21 "}"
deathless_E13_inv.py 63 "]"
deathless_E14.py 365 "    K.fix('D1 to D4 (drone cradles) agai"
deathless_E14_camera.json 21 "}"
deathless_E14_inv.py 92 "]"
hegemony_H10.py 720 "INV_NOTES = {}"
hegemony_H10_camera.json 21 "}"
hegemony_H10_camera_battle.json 19 "}"
hegemony_H10_inv.py 70 "STRUCTURE_NOTE = 'H10 sheet: bow, the we"
hegemony_HF1D.py 297 "                            subs=['panel"
hegemony_HF1D_camera.json 21 "}"
hegemony_HF1D_inv.py 59 "INV_NOTES = {}"
hegemony_IM5.py 762 "INV_NOTES = {}"
hegemony_IM5_camera.json 21 "}"
hegemony_IM5_camera_battle.json 19 "}"
hegemony_IM5_inv.py 80 "STRUCTURE_NOTE = 'IM5 top view by eye: b"
ithar_CD5.py 779 "        review(Path(args[1]))"
voidsworn_S8.py 512 "INV_NOTES = {}"
voidsworn_S8_camera.json 21 "}"
voidsworn_S8_camera_battle.json 12 "}"
voidsworn_S8_inv.py 75 "INV_NOTES = {}"
voidsworn_SB4.py 240 "                            subs=['slab'"
voidsworn_SB4_camera.json 21 "}"
voidsworn_SB4_inv.py 49 "INV_NOTES = {}"
voidsworn_SF3.py 287 "                            subs=['slab'"
voidsworn_SF3_camera.json 21 "}"
voidsworn_SF3_inv.py 50 "INV_NOTES = {}"
@ tools/blender/build_sheets/ships/r2
corsair_A16.py 213 "    K.open_item('Belly detail between th"
corsair_A17.py 150 "    K.open_item('Belly detail between th"
@ tools/blender/build_sheets/studies
e14_ring_study.py 138 "print('WROTE', os.path.join(OUT, 'deathl"
eclipse_lineup.py 94 "print('WROTE', os.path.join(OUT, 'eclips"
ion870.py 182 "(out / 'checks.json').write_text(json.du"
ion870_compose.py 149 "    print(code, record['triangle_total']"
mesh_density.py 48 "    print('  ', f)"
mirror_check.py 71 "print('[mirror_check]', json.dumps(res))"
whole_compare.py 66 "print('WROTE', out)"
@ tools/blender/hs
STATION_KIT.md 62 "Studio renders are review material and a"
c19_hs.py 67 "bpy.ops.wm.save_as_mainfile(filepath=out"
c19_kit.py 557 "    bpy.ops.export_scene.gltf(filepath=p"
cleanup.py 27 "bpy.ops.wm.save_as_mainfile(filepath=out"
detail_lib.py 309 "    bm.to_mesh(me); bm.free(); me.update"
export_json.py 28 "if glb: bpy.ops.export_scene.gltf(filepa"
hs_lib.py 80 "    return o"
json2obj.py 9 "print(len(P), len(I))"
o1_hs.py 34 "print('faces', len(o.data.polygons)); bp"
panel_flatten.py 58 "bpy.ops.export_scene.gltf(filepath=dst, "
planesnap.py 72 "bpy.ops.wm.save_as_mainfile(filepath=out"
render.py 35 "print('faces', sum(len(o.data.polygons) "
station_check.gd 333 "\tquit(0)"
station_kit.py 983 "        main()"
station_paint_review.bat 51 "exit /b 1"
station_paint_sheets.py 214 "    main()"
station_preview.gd 157 "\tkey.directional_shadow_max_distance = 6"
station_readable_paint.py 84 "    return base, orm.outputs[0], emissio"
station_sheets.py 171 "    main()"
to_game.py 28 "subprocess.run([sys.executable, __import"
wavy_report.py 101 "print('wrote', pre + '_wavy.txt')"
@ tools/blender/hull_repair
README.md 27 "The outcome and remaining visual work be"
ROUND4.md 23 "The actual-game phase copies this checko"
ROUND5.md 17 "The verifier compares triangle-coordinat"
ROUND6.md 19 "Each nine-cell sheet also has a neutral "
RUN_C19_REPAIR.bat 15 "pause"
RUN_PYRE_ROUND4.bat 8 "if \"%~1\"==\"\" pause"
RUN_PYRE_ROUND5.bat 7 "if \"%~1\"==\"\" pause"
RUN_PYRE_ROUND6.bat 7 "if \"%~1\"==\"\" pause"
ai_parts.py 132 "    generate(args.work.resolve(), args.p"
assembly.gd 25 "\tcache.clear()"
build.py 513 "    main()"
checks.py 90 "if __name__=='__main__':main()"
pack_parts.py 157 "if __name__=='__main__':main()"
probe.gd 127 "\tquit(0)"
round4_build.py 221 "if __name__=='__main__':main()"
round4_hand.py 310 "        hero_objects=len(heroes),detail_"
round4_material.py 170 "        maps={p.name:lib.sha(p) for p in"
round4_probe.gd 152 "\tfor row in original:row[0].set_surface_"
round4_raw.py 72 "    assert a.work.resolve().is_relative_"
round4_reference.py 222 "    main(a.work.resolve(),a.phase)"
round4_run.py 406 "if __name__=='__main__':main()"
round5_bench.gd 34 "\tfile.close();print(\"[round5] PAIRED GPU"
round5_build.py 72 "if __name__=='__main__':main()"
round5_material.py 189 "        maps={p.name:lib.sha(p) for p in"
round5_probe.gd 49 "\tawait settle(4)"
round5_run.py 112 "if __name__=='__main__':main()"
round5_sheets.py 376 "    print('[round5] SHEETS PASS',out,flu"
round6_build.py 158 "if __name__=='__main__':main()"
round6_game.gd 20 "\tfile.close()"
round6_material.py 61 "    return result"
round6_probe.gd 103 "\tawait settle(6)"
round6_run.py 119 "if __name__=='__main__':main()"
round6_sheets.py 271 "    print('[round6] SHEETS PASS',out,flu"
run.py 313 "if __name__=='__main__':main()"
@ tools/blender/kits
README.md 73 "(the kit's `TURRET_TURN` marks turA and "
@ tools/blender/kits/chorus
README.md 55 "build as before."
parts.py 1061 "                             trails=trai"
@ tools/blender/kits/eclipse
README.md 76 "(issue 642, runs 642 and 642b)."
parts.py 935 "    return kept"
stack.py 509 "    return out"
@ tools/blender/kits/hegemony
README.md 79 "panels and the panels' sink), `panel_sla"
parts.py 840 "    return p"
stack.py 666 "    return [(tuple(int(v) for v in C[j])"
@ tools/blender/kits/hegemony_station
README.md 125 "check and Ryan's look remain open. This "
capture.gd 215 "\tquit(0)"
check.py 249 "    sys.exit(0 if success else 1)"
debris.py 317 "    main()"
debris_capture.gd 73 "\tquit(0)"
debris_check.gd 170 "\tquit(0 if failures.is_empty() else 1)"
debris_install.gd 54 "\tquit(0)"
debris_pictures.py 126 "    main()"
debris_run.bat 60 "exit /b 1"
design.py 84 "]"
inspect.gd 124 "\tquit(0)"
install.gd 51 "\tquit(0)"
parts.py 485 "        return result"
production.py 494 "if __name__ == '__main__': main()"
production_capture.gd 152 "\treturn [low.x,low.y,high.x,high.y]"
production_check.py 285 "if __name__ == '__main__': main()"
production_finish.py 235 "    return dict(lit_faces=lit_count, dar"
production_pictures.py 65 "if __name__ == '__main__': main()"
production_run.bat 62 "exit /b 1"
range_selftest.py 49 "if __name__=='__main__': main(Path(sys.a"
review.py 633 "if __name__=='__main__': main()"
review_run.bat 42 "exit /b 1"
scale.py 33 "                live_large=live['STATION"
sheets.py 151 "(OUT/'feature_table.md').write_text('\\n'"
stack.py 35 "    return mats"
@ tools/blender/kits/hullbreakers
README.md 53 "| `slit` | | the crew's vision slit: a w"
check_patchwork.py 52 "print('PASS patchwork geometry', json.du"
check_stack.py 41 "print('PASS stack: capital settings and "
craft.py 189 "    return HP"
kit.py 327 "    return PB.audit_guns()"
paint.py 261 "    return mats"
parts.py 1073 "    return p"
plating.py 175 ""
render_patchwork_close.py 40 "      (.10, 1, .30), .75)"
review_patchwork.py 175 "    main()"
stack.py 635 "                violet=km(im[(im[:, 2] >"
@ tools/blender/kits/shared
geom.py 136 "    return all(any(any(n.split('_')[-1]."
hardpoints.py 272 "    return probs"
paint_colors.py 41 "    return tuple(float(x) for x in _line"
paint_lint.py 466 "    raise SystemExit(main())"
paint_stack.py 1288 "    bake_existing_atlas(stack, args.sour"
plumbing.py 247 "                guns_with_normals=sum(1 "
turrets.py 85 "    return out"
@ tools/blender/kits/voidsworn
README.md 64 ""
parts.py 942 "SUBPARTS['bomb_tube'] = ['face', 'housin"
stack.py 611 "    return [(tuple(int(v) for v in C[j])"
@ tools/blender/r209
README.md 88 "| `pc/r6_*.bat` to `pc/r6f_*.bat` | the "
armA.py 148 "    build(a[0])"
armA2.py 258 "    build(a[0], int(a[1]) if len(a) > 1 "
armA3.py 347 "    print('[209]', json.dumps(meta), flu"
armA4.py 350 "    print('[209]', json.dumps(meta), flu"
armA5.py 437 "    print('[209]', json.dumps(meta), flu"
armA6.py 112 "    print('[209]', json.dumps(meta)[:300"
armA7.py 198 "    print('[209]', json.dumps(meta)[:300"
armA8.py 177 "    print('[209]', json.dumps(meta)[:300"
armB.py 156 "    build(a[0], a[1], a[2], a[3])"
armB2.py 80 "    build(a[0], a[1], a[2], a[3])"
armB_fix.json 46 "}"
b0trace.py 92 "    elif sys.argv[1] == 'fit': fit(*sys."
bakeAb.py 87 "    A2.build(OUT, 2, cell='Ab', hull_det"
bakeAb3.py 199 "    main()"
bakeAb4.py 207 "    main()"
bakeAb5.py 200 "    main()"
bakeAb6.py 225 "    main()"
bake_sheet.py 61 "    main()"
close5.py 46 "print('[209] CLOSE DONE', CELL, flush=Tr"
close6.py 63 "print('[209] CLOSE DONE', CELL, flush=Tr"
common.py 265 "    return o"
deck_line.py 36 "json.dump(res, open(os.path.join(out, 'd"
export3.py 93 "print('[209] export', OUT, json.dumps(in"
export_glb.py 57 "print('[209] export', OUT, 'triangles', "
fire_clip.py 82 "    print('[clip] strip', os.path.join(d"
fit8.py 228 "    OT.run(CONCEPT, CAM, os.path.join(ou"
fit8_bow.json 388 "}"
fit8_bow_try1.json 418 "}"
flat_views.py 41 "    sc.render.filepath=f'{OUT}_{n}.png';"
massing_sheet.py 82 "stack(parts, OUT)"
outline_battle.py 60 "    run(a[0], ref, [c for x in a[1:] if "
outline_thirds.py 87 "    run(sys.argv[1], sys.argv[2], sys.ar"
paint3.py 202 "    return m"
preview6.py 54 "print('[prev] done', round(time.time() -"
preview7.py 96 "print('[prev] done', round(time.time() -"
render.py 136 "print('[209] RENDER DONE', CELL, flush=T"
report3.py 35 "                  build_s=m.get('build_s"
report_table.py 14 "          f\"{len(au.get('problems', []))"
sheet_hull.py 60 "    print('[209]', json.dumps(meta)[:300"
sheets.py 90 "stack(parts, 'break.jpg')"
sheets2.py 134 "    if GOD: lod_sheet([c for c in ('A2',"
sheets3.py 180 "    if MAPS: maps_sheet('Ab3' if 'Ab3' i"
sheets4.py 186 "    if MAPS: maps_sheet('Ab4' if 'Ab4' i"
sheets5.py 202 "    if CLOSE: close_sheet()"
sheets6.py 99 "json.dump({k: dict(concept=[round(x) for"
sheets7.py 100 "stack(sp, 'silhouette.jpg')"
sheets7pc.py 184 "stack(fr, 'fire.jpg')"
sheets8.py 232 "stack(fr, 'fire.jpg')"
sil_dump.py 46 "print('[sil] dumped', OUT, T.shape, 'obj"
silhouette4.py 135 "    elif sys.argv[1] == 'score': score(s"
silsheet4.py 70 "out.save(OUT, quality=88); print('sheet'"
tune4.py 67 "json.dump(res, open(OUT, 'w'), indent=1)"
tune5.py 137 "json.dump(res, open(OUT, 'w'), indent=1)"
tune5_P.json 1098 "}"
@ tools/blender/r209/godot
bench209.gd 257 "\tquit(0)"
bench209r3.gd 364 "\tquit(0)"
project.godot 20 "gdscript/warnings/integer_division=0"
@ tools/blender/r209/pc
r2_queue.bat 9 "echo launched 209 r2"
r2_run.bat 39 "echo done > \"%OUT%\\done.txt\""
r3_queue.bat 9 "echo launched 209 r3"
r3_run.bat 34 "echo done > \"%OUT%\\done.txt\""
r3b_queue.bat 9 "echo launched 209 r3b"
r3b_run.bat 32 "echo done > \"%OUT%\\done.txt\""
r3c_queue.bat 9 "echo launched 209 r3c"
r3c_run.bat 32 "echo done > \"%OUT%\\done.txt\""
r4_queue.bat 9 "echo launched 209 r4"
r4_r3concept.bat 10 "echo done > \"%O%\\out4b\\r3\\done.txt\""
r4_run.bat 35 "echo done > \"%OUT%\\done.txt\""
r4b_queue.bat 9 "echo launched 209 r4b"
r4b_run.bat 31 "echo done > \"%OUT%\\done.txt\""
r5_queue.bat 9 "echo launched 209 r5"
r5_run.bat 38 "echo done > \"%OUT%\\done.txt\""
r5b_queue.bat 9 "echo launched 209 r5b"
r5b_run.bat 40 "echo done > \"%OUT%\\done.txt\""
r6_queue.bat 9 "echo launched 209 r6"
r6_run.bat 51 "echo done > \"%OUT%\\done.txt\""
r6b_queue.bat 9 "echo launched 209 r6b"
r6b_run.bat 52 "echo done > \"%OUT%\\done.txt\""
r6c_queue.bat 9 "echo launched 209 r6c"
r6c_run.bat 52 "echo done > \"%OUT%\\done.txt\""
r6d_queue.bat 9 "echo launched 209 r6d"
r6d_run.bat 52 "echo done > \"%OUT%\\done.txt\""
r6e_queue.bat 9 "echo launched 209 r6e"
r6e_run.bat 52 "echo done > \"%OUT%\\done.txt\""
r6f_queue.bat 9 "echo launched 209 r6f"
r6f_run.bat 52 "echo done > \"%OUT%\\done.txt\""
r7_queue.bat 11 "echo launched 209 r7 (it waits for opus2"
r7_run.bat 93 "echo done > \"%OUT%\\done7.txt\""
r7b_queue.bat 10 "echo launched 209 r7b"
r7b_run.bat 59 "echo done > \"%OUT%\\done7b.txt\""
r7c_queue.bat 10 "echo launched 209 r7c"
r7c_run.bat 28 "echo done > \"%OUT%\\done7c.txt\""
r8_queue.bat 10 "echo launched 209 r8"
r8_run.bat 87 "echo done > \"%OUT%\\done8.txt\""
r8b_queue.bat 10 "echo launched 209 r8b"
r8b_run.bat 87 "echo done > \"%OUT%\\done8b.txt\""
r8c_recheck.bat 23 "type \"%O%\\out8b\\recheck341\\result.txt\""
@ tools/blender/surface_bakeoff
README.md 17 "The temporary solver scale handles Blend"
ROUND2.md 19 "`round2_run.py` verifies exports by reim"
RUN_SURFACE_BAKEOFF.bat 15 "pause"
RUN_SURFACE_ROUND2.bat 15 "pause"
build.py 625 "    main()"
probe.gd 290 "\tquit(0)"
project.godot 20 "gdscript/warnings/integer_division=0"
round2_build.py 610 "if __name__=='__main__':main()"
round2_game.gd 99 "\tquit(0)"
round2_probe.gd 86 "\tquit(0)"
round2_run.py 234 "if __name__=='__main__':main()"
run.py 185 "    main()"
verify.py 74 "    main()"
@ tools/blender/vfx
README.md 19 "The existing weapon-only volume helper m"
bake_death.bat 10 "exit /b %ERRORLEVEL%"
bake_death.py 57 "(out/'bake.json').write_text(json.dumps("
bake_route_a.bat 15 "exit /b %ERRORLEVEL%"
bake_route_a.py 56 "    (out / 'bake.json').write_text(json."
bake_route_b.bat 15 "exit /b %ERRORLEVEL%"
bake_route_b.py 53 "        (out / 'bake.json').write_text(j"
bake_weapons.bat 10 "exit /b %ERRORLEVEL%"
bake_weapons.py 77 "(out/'bake.json').write_text(json.dumps("
check_death.bat 21 "exit /b 1"
evidence.py 43 "(out/'index.html').write_text(html,encod"
grammar.md 22 "Mantaflow is an offline artistic gas mod"
grammar_sheet.py 52 "im.save(out/'death_grammar.png')"
pack_death.py 69 "print(json.dumps(metadata,indent=2))"
pack_routes.py 223 "print('PACK_DONE', a.route, flush=True)"
pack_weapons.py 71 "print(json.dumps(metadata,indent=2))"
rebake.bat 11 "exit /b %ERRORLEVEL%"
rebake_evidence.py 83 "print(json.dumps({k: {q: v for q, v in d"
route_common.py 198 "    return time.time() - t"
```

## Ranked confirmed findings

### 1. One Codex lane has no checkout owner for the life of a run

**Confirmed / OBSERVED (high).** `tools/pc/codex_issue.bat:46`: `set "R=%ROOT%\%BOARD%\repo"`.

**Proof:** Lines 46-47 derive one checkout per lane and one output folder per issue. Lines 79-81 overwrite the result and initialize state before the issue lock at line 94. Thus a same-issue retry on that lane can reset the active run's state and confirmation files (`tools/pc/runner_common.ps1:460-468`) before being refused. For different issues, the issue locks use different names (428-439). The shared mirror lock ends before the working-tree switch (526, 542-552). If A is preempted just after switching a clean checkout and B switches it before A enters it (98-101), both can prepare and run in B's tree. If it is dirty, B may instead try to move it aside. Neither is a lane-level refusal.

**Fix, 2 agent runs:** Take a per-checkout lock before creating or updating run state; hold it through final reporting and use the same lock for lane-tools refresh. Use a unique output directory per attempt, with a last-run pointer, so a refused launch cannot overwrite a live run's files.

### 2. The runner checks that `Branch:` is present, then ignores its value

**Confirmed / OBSERVED (high).** `tools/pc/runner_common.ps1:354`: `foreach ($field in @('Owner','Brief','Deliver to','Branch','Done when')) {`.

**Proof:** `Current-Body` checks presence; `Validate-Job` (397-426) checks open/running state, other branches and open PRs, but takes only the launcher prefix and never compares it to the body assignment. `announce` uses the status branch from the launcher (632-644); the Codex branch is hardwired in `tools/pc/codex_issue.bat:48` and the workhorse branch is assembled in `tools/pc/work_issue.bat:121`. Before the new seat claims or publishes anything, the old queue can still claim first. The probe below keeps the owner and effort valid and changes only `Branch:`.

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File contrib/openai/audit_1118/tests/tools_ci/branch_dispatch.ps1
FAIL: a Codex launch accepted an issue assigned to the OpenAI delivery branch
```

**Fix, 1 agent run:** Parse the launch branch and owner from the validated fixed block and compare to the requested assignment, including the exact workhorse arm, before claiming. Keep dry-run fixture push destinations separate from the assignment being validated.

### 3. A confirmed push can trigger cleanup even when delivery was not good

**Confirmed / OBSERVED (high).** `tools/pc/work_issue.bat:408`: `set "OK=1"`.

**Proof:** An agent failure goes to `-partial` (331-340); failed post-run checks leave `CHECKS_OK=0` (380-392). Neither path prevents a successful push and readback from setting `OK=1` (396-409), the value sent to `tidy` at 465. With `remove_repo_copy_after_push=yes`, `tools/pc/work_issue.ps1:676-687` removes the whole checkout without checking delivery status or checking for local-only or ignored work. The remote verification covers the committed tree only. Even with cleanup off, `tools/pc/runner_common.ps1:450-453` sends `Runner status: finished` for `unverified` when exit is zero, so the lead status line disagrees with the reason underneath. The chain itself correctly refuses `unverified` (486-487).

**Fix, 1 agent run:** Use `checked_push`, rather than the push exit code, for both public success and any opt-in cleanup. Before cleanup, prove no local-only work would be lost, or keep the checkout and report why.

### 4. Runner failure reasons and raw log tails cross the public boundary

**Confirmed / OBSERVED (high for path flow; no credential exposure observed).** `tools/pc/runner_common.ps1:316`: `- Result: $reason`.

**Proof:** A checkout that stays locked hits the throw with `${full}` at line 155. The shared catch stores the raw exception at 856-860, then `End-Announcement` at 441-455 passes it to `Status-Body` and PATCHes the issue comment. The lane label at 650-654 avoids a path, but `Result` still carries it. Separately `tools/pc/run_timeout.ps1:54-64` copies raw agent stdout/stderr tails to `resume.txt`; `tools/pc/work_issue.ps1:442-452` and `tools/pc/codex_issue.ps1:124-138` put check logs and resume text into the commit after a path-only rewrite. The workhorse commit helper skips picture validation on partials (542-549); that branch is still public. This proves raw diagnostic text can cross, not that a real key has crossed.

**Fix, 1-2 agent runs:** Publish a fixed status reason and a bounded set of safe check rows; keep exceptions and raw logs in local output. Use one publication filter at the final commit/comment write for both runners and test it with fake paths and fake secrets.

### 5. The watchdog starts its clock after an unlimited GPU wait

**Confirmed / OBSERVED (high).** `tools/pc/gpu_slots.js:177`: `for (;;) {`.

**Proof:** `tools/pc/run_timeout.ps1:220-233` waits synchronously for `acquire` before starting its stopwatch. `gpu_slots.js:68-90,174-185` retries forever if go stays withdrawn or a shared request can never fit (for example, Blender weight 2 with configured capacity 1). The heartbeat only prints `WAIT`. `tools/pc/watcher.bat:25-37` waits for the called batch, so this can pin the serial queue for subsequent CPU jobs too. An outer agent cap helps only when there is an outer agent.

**Fix, 1 agent run:** Give GPU admission its own bounded, cancellable wait, outside the execution allowance; fail promptly on an impossible weight. On cancellation release a pending solo reservation and return a clear nonzero status to the caller.

### 6. Stage 7 does not verify that the files it installs are the checked export

**Confirmed / OBSERVED (high).** `tools/recipe/7_export.bat:53`: `copy /y "%EX%\%CODE%.glb" "%SH%\" > nul`.

**Proof:** At 48-55, Stage 7 does not test backup, move, GLB copy or texture copy results before merging the new manifest entry. If a destination file is held, copying can fail with a usable old file still present. The cache refresh and readback (59-62) then compare the cache to whatever files are installed, not to the checked export: `godot/render/test/installed_ship_check.gd:44-60` derives both its source stamp and expected nodes from the installed files. A second lane targeting the same install folder can also lose an entry: `tools/recipe/manifest_merge.py:14-20` reads the whole manifest, copies a backup named only to the second, and opens the live file for truncating write without a lock. Two installers can read the same starting manifest and both report success, with the last write dropping the first update.

**Fix, 2 agent runs:** Stage and hash the precise output set, obtain a lock per target project and abort before replacing files if any backup/copy check fails. Commit the manifest atomically and require readback to verify the intended export hashes, with a rollback to the saved files on a failed install.

### 7. The A16 check authenticates input text, not the fixture it claims is fresh

**Confirmed / OBSERVED (high).** `tools/recipe/sheet_fixture_hash.py:60`: `old = open(OUT, encoding='utf-8').read().split('\n')[0].split()[-1]`.

**Proof:** The workflow calls `--check` at `.github/workflows/checks.yml:235-239`; lines 44-49 and 57-63 of the script compare only an input digest against the record. Neither the writer nor checker reads the `.glb.gz`. An input edit plus a record-only refresh can therefore pass while the old geometry still feeds CI; a broken or missing GLB also passes this freshness step (the separate Godot seam check can still fail on a broken GLB). The input list at 18-26 also omits `tools/blender/build_sheets/variants.py`, which directly builds the fixture's design in `tools/blender/r209/sheet_hull.py:29-35`.

```text
python -B contrib/openai/audit_1118/tests/tools_ci/fixture_output_binding.py
FAIL: the fixture freshness check accepted replacement bytes: PASS fixture record matches
```

**Fix, 1-2 agent runs:** Generate the fixture and record as one bake action and bind the output bytes to the input digest. Include the geometry-writing imports in that input list and reject a standalone record refresh without a new fixture.

### 8. A ship can pass the sided-origin check with both points on one side

**Confirmed / OBSERVED (high).** `tools/blender/kits/shared/hardpoints.py:179`: `if counts.get(kind, 0) < req[key]:`.

**Proof:** `tools/recipe/check_export.py:253-266` checks whether each braking or boarding point agrees with its own side tag, but lines 302-308 only enforce totals for those types. Two individually valid port points meet the total of two. The test reads the real A16 export fixture, verifies the original passes, then separately replaces the starboard braking and boarding points with copies of the port points under the original node names. It runs the real check with inputs supplied in memory.

```text
python -B contrib/openai/audit_1118/tests/tools_ci/export_both_sides.py
FAIL: stage 7 accepted two port and zero starboard points: rcs, board
```

**Fix, 1 agent run:** Require both valid sides where the class calls for a pair. Add the same-count, same-side mutations to the export self-test so a missing-side check cannot silently regress.

### 9. A failed playtest export remains the file that Play prefers

**Confirmed / OBSERVED (high).** `tools/pc/jobs/g2_export.bat:40`: `echo OK: %ROOT%export\Voidsworn.exe >> "%LOG%"`.

**Proof:** Lines 34-40 move the previous release aside, write the new one to the live path and print OK. Either the package check or smoke battle (42-46) can then fail. The failure path (49-51) only logs and returns 1, leaving the new executable in place. `tools/pc/play_godot.bat:17-19` starts it by existence alone, even after the failed build report.

**Fix, 1 agent run:** Export and test from a distinct candidate folder. Promote the executable and its companion files together only after both checks pass, leaving the previous verified build as the Play target on any failure.

### 10. The CI punctuation check can say it scanned files it skipped

**Confirmed / OBSERVED (high).** `.github/workflows/checks.yml:63`: `for f in $files; do [ -f "$f" ]`.

**Proof:** Line 61 captures a newline-delimited name list and filters to seven extensions. PowerShell and workflow YAML are out of the list. On a changed `tools/pc/example with spaces.bat`, Bash splits `$files`; `-f` tests the fragments and never feeds the real path to `grep`. The check reaches line 65 and prints `No em dashes in changed files.` when that was the only offending file. Rename destinations are also excluded whenever Git reports `R` rather than `A` or `M`.

**Fix, 1 agent run:** Use a NUL-delimited list and safe per-path reads, covering renamed destinations and all supported text types. Test a spaced path and a PowerShell file with a planted mark.

## Suspected findings

None promoted. The ten above are demonstrated by offline probes or exact call paths; the concurrency and failure cases were not induced on the live PC.

## Frame-cost suspects

- **Unmeasured guess:** `tools/recipe/6_lod.bat:5` says `the LOD chain is an analysis product`; `tools/recipe/export7.py:315-323,445-449` writes the full ship and turret meshes. Small geometry could continue to cost draw work at the battle camera even if the analysis LOD bench reports savings. Issue 1070 should check the installed asset at fleet scale and establish what the runtime already reduces. No frame timings taken.

## Checks and impact

- Raw Git scope read: `PASS: 781 Git blobs read to EOF` (Python syntax and JSON parses clean).
- Node syntax: `PASS: parsed 20 JavaScript scripts`.
- Windows PowerShell syntax: `PASS: parsed 21 PowerShell scripts`.
- Existing `python -B tools/recipe/sheet_fixture_hash.py --check`: `PASS fixture record matches`. The three audit probes report the expected `FAIL` lines above and do not change the checked files.
- Delivery check: `PASS: 781 inventory rows match the pinned blobs; 10 exact quotes and all delivery files checked`.
- Callers: traced runner launch, finish, queue and publish paths, and stage 7 through install readback. The added probes are standalone and have no production callers.
- Saves: no profile or run-save code or fields changed; compatibility checked by delivery scope, with no save migration or load exercised.
- Twins: neither JS rules nor the Godot port or tables changed; no export or parity rerun was needed for the audit.
- UI: no UI code changed. The audit traced what Mission Control and the Play launcher read where relevant.
- CI: `checks.yml` runs standing checks, rules and campaign parity, the Godot-only rules safety net, and the Godot game checks including fixture freshness. These three intentionally failing audit probes are manual reproductions and are not registered in the standing pack.

**Not checked:** Live GitHub writes or claims, actual provider calls, destructive cleanup or a shared-build install; Godot, Blender, captures, frame timings, parity and the full standing suite were not run during issue 1070. The audio files were identified by their binary headers, not auditioned. No replaced A4 hull was evaluated.
