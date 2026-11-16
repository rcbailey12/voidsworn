# DB1, The Ledger Page, issue 805

The after-run page now puts the run's figures and timeline above renown, the admiral and three heir cards. The one ember
box confirms the heir, then advances to the next faction. Exits are inert until confirmation. The receipt's original
sentences remain behind named keys, hovers and the existing progression screens. Spend renown uses P, resolving DB1's
duplicate R; The record keeps R. The complete moved-items table is in docs/playbooks/screens.md, "The after-run screen".

The implementation is in godot/ui/campaign/campaign_ui.gd, debrief_ledger.gd and ledger_ship.gd. Shared theme additions are
in glass_shell.gd. debrief_ledger_test.gd is registered in godot/tools/ci/godot_checks.txt. The browser template, rule twins,
campaign payout functions and save format have no changes.

Real 1920x1080 Godot captures, beside the picked DB1, reduced to 720 px tall:

- [Win beside DB1](DB1_win_beside_pick.jpg)
- [Loss beside DB1](DB1_loss_beside_pick.jpg)
- [First loss beside DB1](DB1_first_loss_beside_pick.jpg)

Other states and details: [abandoned](DB1_abandoned.jpg), [zero earnings and no battle history](DB1_zero.jpg),
[empty fleet](DB1_empty.jpg), [confirmed heir](DB1_confirmed.jpg), [core sync](DB1_core_sync.jpg),
[Nemesis](DB1_nemesis.jpg), [the record and first-loss teaching](DB1_record.jpg), [full receipt](DB1_receipt.jpg),
and [portrait hover](DB1_portrait_hover.jpg).

The fixture calls the real newRun and endRun functions, with a seeded prior profile and run statistics. Its numbers come
from the actual paid receipt, rather than copying the mockup's example figures. The model is Cinder Vow, the run's actual
Vigil-class flagship (template penitent). The viewport uses ShipView's V16_37 from the installed cache in
C:\Users\rcbai\Downloads\voidsworn_test\build\godot. Only this hull and its existing texture dependencies were staged into
this checkout's ignored cache for the captures. No concept art or new ship assets are included. Loss captures label the
retained actual flagship LOST; the empty-fleet case shows a truthful empty state. Capturing with a missing model fails.

Validation:

- Standing checks: exit 0, no new failures; the existing baseline has seven findings failures and twelve constant differences.
- DB1 headless check: pass for win, loss, first loss, abandonment, zero earnings, no recorded sequence, no current heir,
  no surviving hull, every faction at 1080 and 1440, a long flagship name and 20 ships. Actual font sizes are at least
  17 px at 1080, the name face at least 28, all three text strengths are used, and measured contrast is at least 6.03:1
  over white and black backdrops. No measured text overlaps or leaves the viewport.
- The same check with the RTX 5080 and Forward+: pass; original captures are 1920x1080.
- Existing inheritance, core-sync and shadow-XP Godot tests: pass against freshly generated browser fixtures.
- Final script and scene loader: 190 scripts and 11 scenes, zero failures.
- Headless bot battle: pass, using the usual CI stand-ins for hulls outside the staged flagship.
- Unrelated GPU effect and performance benches were not run; this job calls for short UI captures.
- Windows Godot reports a root-certificate-store warning; this does not change any test result. The installed hull uses
  the existing hp_rcs surface-ray fallback. No placeholder hull was used in the UI captures.

Original PNGs and the reduced review pictures are saved in
C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-805\shots. Scratch logs and fixtures stay in %TEMP%.
build_sheets.py reproduces the review sheets from those originals. No commit or push was made by this worker.
