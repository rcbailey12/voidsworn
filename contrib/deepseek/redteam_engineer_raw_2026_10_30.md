Software engineer seat: architecture and cutover risk

Findings, ranked by severity

1. CRITICAL, OBSERVED. Save continuity fails twice: no importer exists, and the Godot write is non-atomic.
What breaks: the browser profile and run cannot enter the Godot build, and the new build can truncate its own save on a mid-write crash. Evidence: campaign.gd's persistence header states "browser saves are not carried over"; the fixtures README says without an importer "all META progression and any in-progress run are lost at cutover"; the migration review calls the Godot write "copy to .bak, then overwrite in place." The fixtures are an oracle only, not an implementation. Cost: every existing player loses all meta and any live run at cutover, and week-one save loss lands when there is no browser build to fall back on. The 80 percent loss design means players have many runs of meta invested.

2. CRITICAL, OBSERVED. A clean checkout cannot build the shippable game, and the package is untested.
What breaks: build reproducibility and package verification. Evidence: "godot/gen/ has zero files on main"; "A clean checkout cannot build the shippable game"; "ship_view.gd falls back silently to a plain BoxMesh"; the needed additions list includes "Export preset excludes all test trees" and notes no test covers export contents. Cost: the cutover binary cannot be reproduced or audited from the repo. A missing generated asset ships as a box or a blank, and test trees can leak into the .pck with no check to stop them.

3. HIGH, OBSERVED. Parity is single-threaded by construction and cannot see the port's concurrency.
What breaks: the migration's safety net cannot validate the threaded shell. Evidence: "step() is the only locked method in battle_api.gd"; "threat_map() runs eval_begin() on a worker thread and clears the six shared eval caches over live units"; jsm.gd keeps "one static 8-byte scratch buffer behind every float-word conversion." Cost: race bugs pass parity and become player-facing after cutover, when the browser build no longer exists to bisect against.

4. HIGH, OBSERVED. Silent degradation can ship a build that looks alive but is missing real UI, effects and story.
What breaks: cutover honesty. Evidence: "ResourceLoader.exists soft dependencies can ship the facts-and-buttons fallback campaign UI"; "fx_stub.gd still runs beside the real fx"; "NOT PORTED clears and plays a partially computed batch in live battles." Cost: a cutover build can pass a smoke check while showing fallback UI and stub effects. The failure is invisible until a player sees it, and no existing test treats it as an error.

5. HIGH, OBSERVED. Oracle drift can make parity certify the wrong rules.
What breaks: the hard safety net for the whole rules port. Evidence: both oracle READMEs document a manual "Catching up" re-copy; "nothing automatically checks that the two vendored copies" match each other; "a one-sided manual re-pin would drift silently." Cost: parity can report PASS against a stale battle.js or data.js, so a rules regression lands at cutover with a green dashboard. The fix is cheap (a hash compare in the existing runners), which makes its absence a choice, not a constraint.

6. HIGH, INFERRED from an OBSERVED divergence. CUT/SOLID hash coverage is unresolved, so a terrain-state bug class may be invisible to parity.
What breaks: the completeness of the canonical state hash. Evidence: the pack and legs say "the canonical hash excludes CUT and SOLID module state"; rules_test_README describes golden state including "the board cut-outs, the hexes that block sight." Cost: if the pack is right, terrain bugs pass every parity check. If the README is right, the pack's claim is wrong and the parity design is misdocumented. Either way the cutover safety case has an open hole that one line of code reading should close.

7. MEDIUM-HIGH, OBSERVED. Silent data deletions intersect the importer and the balance oracle.
What breaks: save compatibility and data integrity. Evidence: "b_razor_s drops bioplasma undisclosed" is the third silent weapon deletion; "Data is code"; fixtures say "Ids in saves are data ids" and "Preserve them verbatim." Cost: a save carrying a deleted id loads as a dangling weapon or silently loses it. The balance oracle and the live game can disagree with no test flagging the deletion, and the importer's verbatim policy makes the dangling id survive into Godot.

8. MEDIUM-HIGH, INFERRED from OBSERVED statements. The engine-call gate record is not in the pack while migration work is on main.
What breaks: traceability of the architecture decision. Evidence: the port plan says "nothing in this plan executes until contrib/opus/enginetest/RESULTS.md lands on main"; the pack's check says "RESULTS.md does not exist on main" as of Oct 25; the platform state says the migration "is underway." Cost: C# versus GDScript and Forward+ rest on a spike whose result is not in evidence. If the gate was bypassed, the migration has no traceable decision to defend. If it landed after the check, the evidence pack is incomplete for the seat that owns cutover risk.

9. MEDIUM, OBSERVED. Telemetry is a proposal and performance has no runtime capture, so the cutover playtest cannot answer the questions it exists for.
What breaks: measurement readiness. Evidence: the telemetry spec is a "Chair proposal for Opus to verify and implement"; three designer rulings end "revisit with actual play data"; the perf audit says "no runtime profiling was done" and does not check "actual frame times on any hardware." Cost: the playtest phase produces no Q-A, Q-B or Q-C data, and the "two named fixes" for desktop performance stay unmeasured on the PC-only floor. The deferred rulings stay deferred by default.

10. MEDIUM, OBSERVED. The music blocker in the Oct 26 review is stale at the Oct 30 pin.
What breaks: the credibility of the pack's file-existence verdicts. Evidence: the review says "music.json, tracks/*.ogg and CREDITS.md do not exist"; the Oct 30 directory listing shows music/CREDITS.md, music.json and music/tracks/. The same review says "music_check.gd cannot pass as written." Cost: the cutover checklist may chase a closed item, and the pack mixes tree states from different dates. Any "NEEDS WORK" verdict that depends on file existence needs re-checking against the pin before it drives cutover work.

Verdict

Verdict: the port is well instrumented but its safety net is narrower than the claims register says, and the save path is not cutover-safe. The single most important attack: there is no importer and the Godot save write is non-atomic, so cutover can lose every existing profile and then lose new saves in week one.

Not checked

Runtime frame times and draw-call counts; whether RESULTS.md landed after the Oct 25 check; the importer implementation, since none is in the pack; the contents of music/tracks/*.ogg; whether export_presets.cfg actually excludes test trees; cloud conflict behaviour beyond stamp comparison; save size growth across a long run; the C# versus GDScript spike outcome; PowerShell 5.1 compatibility of the planned runner; whether the CUT/SOLID golden writer includes terrain state. No code was run.
