# Voidsworn (Embers of the Hollow Sun): handoff (updated Nov 10, 2026, 19:30 CST)

## 0. Status at Nov 10, 2026, 19:30 CST (Nov 11 01:30 UTC; read this first)

**Read in this order:** this section; contrib/opus/LOOP.md "Current state" (the live board: what is running, what waits on Ryan, the exact state of every unfinished job); docs/playbooks/PROGRAM.md (the plan); the playbook for the area you are working in; contrib/opus/FINDINGS.md from R163 on (Ryan's rulings of Nov 10).

**The plan (R167, issue 405): one finished battle, and a playbook per area that any model can run.** Ryan: "codebase is yours with my direction and vision, you bring it to life with the decisions needed from me. I want this to end with something that opus or other models can run from". Every item flows the same way: the Board makes two or three options, Ryan picks ("Options first, then build"), the right seat builds one worked example, the look bench proves it, the recipe goes into the playbook, and the rest is rolled out from the playbook.
- docs/playbooks/PROGRAM.md: the end state, the tracks (battle effects, ships, space and the board, then screens and sound), who does what, the decisions Ryan owes in order.
- docs/playbooks/factions.md: a sheet per faction from the current lore, and three concept directions per faction.
- docs/playbooks/ships.md, effects.md, screens.md: target, inputs, steps, the checks that prove it, traps, a worked example and a job template each.

**The Board.** The Board thread in the Claude Code Project owns the design, the final technical call and every merge (R119, R167); no merge waits on Ryan. He sees options before a new look is built and one image when it lands. Every pull request gets a diff review plus the R129 impact sweep; a Claude-built change gets Muse's outside check before or straight after the merge. The Board ran on Fable 5.2 from Nov 9 (R152) through the design window of Nov 10; Ryan is moving it back to Opus for the build-out (R169). Rulings go to FINDINGS, live state to LOOP.md, and only those two files are pushed straight to main.

**Seats (R164, R166, R168, R169, R170).**
- Design, options sheets, picture reviews, picks put to Ryan, playbooks: the Board.
- GPU work and finishing builds (bakes, captures, recipe runs, bench runs): Codex on the PC, un-parked Nov 10. The Board launches it through the PC queue; LOOP.md says exactly how.
- Well-specified code: the DeepSeek workhorse on the PC (two runs at most, never on the same files).
- Research, pictures, design text, outside checks: Muse (Rey chairs; a blind Rey leg first).
- Claude helpers: only for a job no other seat can do, with the effort stated at launch: high for design and deep reviews, medium for first builds judged by eye, low for well-specified work (R168).
- Picks, looks, money: Ryan. Message him only for picks and landings: two lines and one image. He often cannot see an image the first time: send images one at a time, small enough for a phone.

**Decided on Nov 10 (his words are in FINDINGS).** The campaign map is the Briefing layout over the real 3D scene (R165), with the approach to the star across three sectors and stops readable by icon still to build (R170, issue 420). Every explosion is route B with flash plus hot core, to Muse's staging table (R170). Every ship concept is redone from the current lore, direction first (R169): the 36 old concepts are history. Eclipse keeps a green light, as the thin green-white rim of an eclipse's corona; the Glasswrights lose their wings and become optical instruments; the Chorus loses the grub. Hard points vary by hull class and faction (R164). Shields are invisible at rest (R163). The sounds so far are "bad" and get a redo after scope questions (R163).

**Checks.** Every push to a codex/, muse/, work/ or opus/ branch gets one real run: the standing checks (a truthful table: PASS, KNOWN, FAIL, SKIP), no em dashes, rules parity, and the Godot game checks (every script loads, the headless checks, one bot battle). A script under godot/**/test/ needs its line in godot/tools/ci/godot_checks.txt. A listed known failure that starts passing is a FAIL until its id leaves the list.

**The outside audit (R154 to R161) is done.** Its three root causes are standing rules for every job: a check's state comes from the real functions, never typed by hand; missing things fail loudly; one source per fact. Its 28 jobs are issues 350 to 377; PROGRAM.md orders the ones that matter to the finished battle.

The Oct 26 to Nov 7 history (sections 0a to 6 and the Nov 1 block, including "Gotchas" and "PC test runner") is in docs/archive/handoff_history_2026_11.md.
