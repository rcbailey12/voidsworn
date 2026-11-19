# Workhorse job: issue #1147, "Truth pass 2: the audits' remaining text and gating fixes"

You are the coding seat on the Voidsworn job board (github.com/rcbailey12/voidsworn/issues/1147), doing the job Codex used to do.
This folder is a fresh checkout of main on the branch work/issue-1147-openai. Follow AGENTS.md and CLAUDE.md, except the
"work in your own folder" rule: you are the main coding seat for this job, so edit the game files the job names.
Nobody is watching this run and nobody can answer questions. Make the sensible call, say what you chose in your report, and keep going.
Base already merged by the runner: origin/work/issue-1144-openai (0116d6a48984da8dfee78f47b6064fc410c654de). The merge is committed; do not merge it yourself.

Rules:
- Do exactly what the job below asks. Change nothing else. Read the brief it names first.
- No em dashes in anything you write. Plain words, plain ASCII.
- Do not commit and do not push: the runner does that after you finish.
- The runner handles Base and resume merges before you start. Do not run git merge; report a missing base in your report.
- GPU work must use tools/pc/tmo.bat <seconds> <exe> [args]. Shared capacity comes from Downloads\voidsworn_test\gpu_slots.json (default 2).
  Captures weigh 1, Blender weighs 2; set PC_GPU_WEIGHT=2 for other heavy bakes, or the Board's chosen weight;
  frame-time scripts take solo automatically. For a new timing script set PC_GPU_MODE=solo before calling tmo.bat.
  gpu_go.txt must say GPU cleared. Lane C is code only. Never launch GPU executables directly.
- Keep scratch output (logs, temp files) out of this folder, in the system temp folder.
- Save review pictures and their .provenance.json sidecars in C:\Users\rcbai\Downloads\voidsworn_test\work217\issue-1147-openai\20261119_084751\out\shots (create it). Link them as shots/<file> so the
  runner can copy them into docs/shots/issue-1147-openai and rewrite the links before publishing.
- Link pictures already in the checkout by repo-relative path, and keep every picture link relative.
- Finish with a short report: what you changed (files), each check you ran and its result (paste the PASS or FAIL lines),
  anything you skipped and why. Your report goes at the top of the pull request description; the runner runs the standing
  checks and parity itself after you stop and adds their real rows under it, so write it for a reviewer.

Before you finish, check how your change reaches the rest of the game (the reviewer checks all five, so do it first):
- Callers: search the whole repo for every function, constant and save field you changed or added, and check or fix each use.
- Saves: a player profile or run save written before your change must still load and behave; say how you checked.
- Twins: rules that live in both the JS root files (battle.js, data.js and core.js) and the Godot port must change on both sides. The root files are the only copy (the oracle folders were deleted in PR 381). If you change one of them, re-export both tables (godot/rules/data/tables.json and godot/campaign/data/campaign_tables.json) and run contrib/opus/tools/oracle_copy_test.js last; rules parity and campaign parity prove the two sides match.
- UI: every screen that shows what you changed (campaign map, intel, panels, HUD) must read the new value the same way.
- CI: a new test file must be added to contrib/opus/tools/run_all_checks.js, or GitHub never runs it; say which checks GitHub runs.
Put one line per item in your report with what you found.

How to run things on this PC (Windows 10; your shell is Git Bash):
- Standing checks: node contrib/opus/tools/run_all_checks.js
- Rules parity and campaign parity (needs Godot, a few minutes): cmd.exe //c "tools\\pc\\parity.bat nopause"
  It prints PASS or FAIL per check; campaign parity runs at the end. Both must PASS. One shell command may run up to
  30 minutes, so run parity in the foreground and wait for it.
- Godot 4 console exe: C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe
  Before any Godot run that loads scenes, UI or textures, import once: "C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path godot --import
- Screenshots of the campaign UI: godot/campaign/test/r1_ui_shots.gd is a worked example of a script that builds a campaign
  screen and saves a PNG (run it without --headless so it can capture). Copy its pattern for your own shot script.

## The job

Owner: codex
Brief: below; the first-player audit (Google Drive, embers_first_player_audit_2026-11-18.md, gaps 2 to 5, line references at dfbb5ef6) and Rey's chair handoff (chair_handoff_for_claude.md, items F3, F4, F6 to F11 and its corrections 4 and 5), both summarised below so you do not need Drive; godot/ui/battle/ledger.gd, godot/scenes/battle/battle.gd (TIPS, _tutorial, _arrive, Brace tooltip), godot/rules/rules.gd (canFade, fire, cmdDesc, braceCover, canOrder, FAC_GATES), godot/ui/campaign/campaign_tips.gd, godot/ui/campaign/campaign_ui.gd, godot/ui/campaign/campaign_view.gd, godot/campaign/campaign.gd, godot/campaign/data/campaign_tables.json, tools/onboarding_cards.json, godot/campaign/test/onboarding_test.gd, godot/campaign/test/boon_fleet_test.gd
Deliver to: the files above that each fix needs, tests under godot/**/test/ with their lines in godot/tools/ci/godot_checks.txt, contrib/openai/truth_pass2_1119/README.md (one row per item: fixed, or why not, with the test that covers it)
Branch: work/issue-1147-openai
Base: work/issue-1144-openai
Effort: OpenAI seat (openai arm, gpt-6.2-sol, high), cap 10800 s
Done when: every item below is fixed as text or gating, or explained in the README with the caller trace that shows it is not visible; a test covers each fix where one fits; the onboarding test, rules parity, the standing checks and the Godot game checks pass. What Ryan will see: tooltips, cards and selection text that say what the game actually does.

## THIS IS THE JOB NOW (Board, Nov 19 2026, 13:20 UTC): the rest of the audits' text and gating fixes

Why. Ryan approved the review and asked that no finding be dropped, code ones first (R328, Nov 19 12:53 UTC). Issue 1144 (your Base) fixes the volley preview, the Warden reinforcement, the Placeholder text, the Nemesis banner and the onboarding test. This job takes every other text and gating item. Rule for every item: re-locate the line on your checkout (audit line numbers drift), trace the caller to what actually renders, and fix only what is provably shown wrong. Text follows code; do not change rules or prices in this job.

Battle (first-player audit gaps 2 and 3):
1. The "Fired" keyword tooltip (ledger.gd keyword_tip) promises half movement after firing for every faction; only Glasswrights or the r_slip protocol keep post-fire movement. Make it conditional, matching battle.gd's own conditional phrasing.
2. Admiral's Command: show what it does (cmdDesc for the current tier, and what waiting a round adds) in its tooltip before it is used. The resolve card says the button "glows gold while it is ready", but it renders bone white until armed: make the card and the button agree (pick the smaller change).
3. Sunward Brace gives adjacent same-facing allies cover (braceCover); say so in the Brace tooltip and order text for Sunward ships.
4. The objective teaching card is gated to Battle 3 but Battle 2 always has a non-rout objective: show it from Battle 2 and add a Battle 2 test to onboarding_test.gd. The card says "the bar at the top": point it at the top-left cluster. reinforce_warn says "a banner will name the ship" but the name is in the toast; align the words, and trigger it from the rules' own warning round, not only round + 1.

Campaign cards and screens (gap 4 and 5):
5. c_shipyard fires on free Drydocks and Field Repairs and promises credits, gun swaps and buying ships: fire it only at shipyards, and say refits swap modules, not guns. Give drydock and field repair stops a true line of their own if they need one.
6. c_reward promises "guns and parts" and automatic scrapping when the fleet is full: describe protocols, refits, and Strip or Ransom for a full fleet. c_clock says the clock "runs out": it fills and pulls one Nemesis meeting forward. c_tree is dead (admiralXPToSpend does not exist): hook it to a lineage pick being available, or remove it. Keep tools/onboarding_cards.json in sync.
7. The shipyard header prints "Repairs cost 1 credit per 2 hull" even when priceMult() is not 1: print the real rate.
8. Glasswrights cannot Brace, but Brace protocols (d_bastion, i_brace, i_wall) are offered and the #1075 note says they affect Glasswright ships: make the relevance note say they do nothing for this fleet (read-only, keep offer RNG unchanged), and add an ithar case to boon_fleet_test.gd. The select card tells every faction to Brace: add the Glasswright exception.

Council fix-now text items (chair handoff):
9. F3: the Beat 3 payoff prints on Sector I and II losses (pixel-confirmed): gate it on the run flag; beat3Debrief repeats on every Sector III win: show it once. Trace the formatter, caller, gates and saved flags before changing; test runs ending in Sectors I, II and III with a save and reload.
10. F4: Ostrel's command text advertises torpedo reload to Eclipse: fix the displayed text to the implemented effect, after checking the real eligible fleet including captured hulls. No mechanics change.
11. F6: "The The Unbroken joins the fleet": no doubled article in any generated join message. F7: "win against him" in campaign_view.gd: pronouns follow the Nemesis's set (545 row 8).
12. F8: selection text says carriers cost 25% more; FAC_PRICE says 1.1: text follows code. Check every faction rule line the same way.
13. F9: retired and banned strings (Zealots, "A zealot:", "Crusader's wrath", "Pale Crusader", solar vane, starwind, and class names such as Tomb-ark, Bio-titan, Battle-barge) only where a caller renders them past clsName(); do not rename lookup keys.
14. F10: the admiral selection subtitle says "sets your ships and shipyards" to factions with no shipyards: neutral wording for Chorus, Eclipse and Glasswrights. F11: each faction's selection view names its two most distinctive implemented mechanics and its tradeoff, checked against live rules.
15. The Career flagship paint toggle has no render caller: hide it until the paints are wired (they unlock with the held story arcs). Do not touch arcs_on.


---
_Generated by [Claude Code](https://claude.ai/code)_