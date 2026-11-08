# UI and campaign map audit: chair synthesis

Chair: Rey. Date: Nov 6, 2026.
Pack: PACK.md (64 items: HD battle HUD 15, MN menus and flow 12,
MP campaign map 12, TY typography and text 10, IC icons and
markers 8, AC accessibility and settings 7).
Provenance in the pack: MEASURED 0, DERIVED 0, ANCHORED 5,
ASSUMED 59. This is, tied with the destruction stack, the
least measured stack audited in the Nov 6 program.
Argon reviewer leg: BLOCKED (Google AI Pro lapsed Nov 5,
2026). Flash ran in the ideation seat only, per the owner's
Nov 6, 2026 ruling; its claims are leads, not evidence.
Standing rules applied: uncapped tests, report do not cap,
the measured 5080 scene gate under issue 207 is the only
binding performance limit, the owner's eye decides,
settlements priced in agent terms only.

## 1. Verdict

THE STACK HOLDS ONLY WITH REPLACEMENTS.

The screens work. The frozen JS build is the playable game,
and the port's deliberate pieces are real (the lore-anchored
display face TY1, the shared body face TY2, the flagship
convention IC3, the crests IC6, the IFF colours HD10). What
fails is provenance: not one UI value in either build has
ever been measured, derived, or judged at the resolutions
the owner targets (1440p floor, 4K goal), the two builds
silently disagree on the most-seen elements, and three
structural absences (AC1 colour-vision support, AC2 UI
scale, MN8 debrief) bind every player without ever having
been chosen. Every failure is settleable by capture rounds
the project already has scheduled, one consolidated UI
specification, and three owner rulings. Nothing found
requires a redesign, which is why the strong verdict form
is not adopted (see section 2).

## 2. Legs and screening

Blind Rey leg (legs/rey_blind.md): COMPLETE, adopted as
spine. Verdict HOLDS ONLY WITH REPLACEMENTS. Hinges HD1,
HD7, AC1. Dispositions: KEEP 7 (HD10, MN11, MP4, MP5, TY1,
TY2, IC3), REPLACE 32, RE-DERIVE 24, DROP 1 (MP1).

DeepSeek leg (legs/deepseek.md, filed raw with chair
header): COMPLETE, all 64 items, all lenses. Verdict DOES
NOT HOLD, hinges HD1, TY4, MP6. Dispositions KEEP 6,
REPLACE 58. Screening: the strong verdict is threshold
rhetoric of the same kind the chair recorded on the
environment audit. Its own settlements consolidate into the
same capture round and the same consolidated specification
as the spine's; a leg that settles everything it condemns
through two shared instruments has described replacements,
not a collapse. Its item work is adopted as corroboration
where it agrees with the spine, and the spine governs
where the tables differ. Its three owner questions were
screened: the brand-face cutover (TY1) is already anchored
by lore round 5 and is KEEP in the spine; the developer
surface question is carried up inside owner Q1 below; the
accessibility scope question is carried up inside owner Q2.

Qwen leg (legs/qwen.md, filed raw with chair gate note):
COMPLETE, all 64 items, all lenses, both model gates
passed (Qwen3.8-Max before and after; single response, no
preference prompt). Verdict DOES NOT HOLD, hinges HD1,
HD7, AC1. Screening: (a) Two of its three hinges are the
spine's hinges, and its settlements are the spine's
settlements (calibration-sitting captures, consolidated
specification, campaign side-by-side, CVD simulation); the
verdict wording is not adopted for the same reason as
DeepSeek's. (b) Its disposition summary arithmetic is
wrong in two places: it claims KEEP 6 while naming five,
and claims RE-DERIVE 37 where its own table counts 38
(chair count of the table: KEEP 5, RE-DERIVE 38, REPLACE
21, DROP 0, total 64). The rows were screened, not the
summary. (c) Its first owner question (port vs JS as blanket
design authority) is NOT carried up: the spine's scripted
constant diff plus a recorded choice per divergence settles
the same ground without a blanket authority ruling that
would pre-judge divergences nobody has captured yet. Its
second question (UI scale in scope) is carried up inside
owner Q2. Its third question (reduce-flashing default on)
is NOT carried up as a standalone: the spine folds it into
the MN3 defaults block re-ruled after the issue 207
benchmark, which is where every default is decided once,
with the benchmark's numbers on the table.

ADDENDUM (Nov 6, 2026, after delivery): a SECOND Qwen run
from the original browser task returned late and is filed
at legs/qwen_run2.md with chair screening. Same verdict
form, same three hinges, near-identical settlements; its
disposition table counts KEEP 7, REPLACE 24, RE-DERIVE 33.
Its verdict-change condition (captures plus a CVD pass
would move it to HOLDS ONLY WITH REPLACEMENTS) describes
settlements U-A and U-D exactly. Its second owner question
would defer reduce-motion where Q2 below decides it in the
same ruling; the difference is timing and stays inside Q2
as delivered. No change to the verdict, adopted table,
settlement program, or owner questions.

Flash ideation leg (legs/flash_ideation.md, chair header,
ideation seat only): COMPLETE. Screened in section 5.

No Argon screen exists for this audit. If the owner renews
Google AI Pro, an Argon leg can run post-hoc against this
synthesis; nothing in the settlement program waits on it.

## 3. Hinges

1. HD1, the scaling law (with TY4 and TY5). One formula,
s(v) = round(v * k), k = clamp(height/1080, 0.6, 2.2),
denominates every size in the Godot battle HUD, and the
same idea exists in three copies with two different clamp
ranges (battle 0.6 to 2.2, campaign 0.6 to 2.5, fallback
0.6 to 2.2). It was designed at 1080p and never judged at
1440p or 4K. If the design point or a clamp is wrong, every
screen is wrong by the same factor at once. No other item
has this blast radius.
2. HD7, nameplate geometry. JS plates are 54 px; the port's
are s(90), 67 percent larger at the shared design height,
on the element attached to every ship in every battle. The
plate-to-ship proportion inverts with zoom (pack X3), and
the owner plays at the standard radius and zooms in for
effects, so the disagreement sits exactly at his two
working zooms. HD7 is also the strongest single evidence
for the pack's H1: the port transcribed the JS UI by eye,
not by table (colours exact, layout values near-miss, feel
values far off), which is why the settlement is one scripted
constant diff rather than 64 small rulings.
3. AC1, no colour-vision support. No colourblind mode, no
palette variant, no redundant encoding rule exists in
either build. IFF (HD10), danger bands (MP8), and hull-low
(HD9) all speak colour first; roughly 1 in 12 male players
reads red-green distinctions poorly. The map's route lines
(MP4, colour plus width plus dash) prove redundant encoding
is possible in this codebase. This is an unchosen absence,
not a tuned value, and it is the audit's most consequential
settlement (one script build, section 6, U-D).

Secondary flags: AC5, invisible focus on the battle HUD
(the Godot battle theme sets the Button focus stylebox to
empty while the title screen cites WCAG 2.1.1; the cheapest
fix in the pack, folded into the specification). MP6, the
campaign map's medium change (SVG diagram to 3D orrery
whose entire written design record is six constants; the
old map's elite marking and icon legend have no located
equivalent in the port). HD9, the 0.35 vs 0.34 hull-low
disagreement (invisible in play, which is the finding: the
drift pattern, not the value). MN8, no debrief screen in
either build (the run-learning loop's teaching surface is a
paragraph inside other screens).

## 4. Adopted dispositions

The blind Rey table governs, in full, at
legs/rey_blind.md section 5: KEEP 7, REPLACE 32,
RE-DERIVE 24, DROP 1 (MP1, the superseded SVG frame; its
figures remain in the record as the baseline, and no live
surface loses a protection because the port already
replaced the form).

Chair notes on the table:
- The four shared settlements the table is built from are
  named in section 6. Almost nothing in this audit needs a
  standalone spend; the table's discipline is consolidation.
- HD1 is REPLACE in the spine (its numbers are re-ruled
  from captures) where Qwen and DeepSeek say RE-DERIVE.
  The distinction is bookkeeping only; the settlement is
  identical (the calibration sitting).
- MP4 and TY1 are KEEP in the spine where Qwen says
  RE-DERIVE. MP4's three-way encoding is the project's own
  standard and needs no re-derivation; TY1's face change is
  lore-anchored, and what the specification records is the
  cutover as the change point, not a new judgement of the
  face.
- IC3 is KEEP in the spine (the convention stands); Qwen's
  point that the port bakes the star into the name string
  is adopted as an implementation note inside the
  specification, not as a disposition change.

## 5. Flash ideation: screening

Adopted as settlement forms (leads that improve a
settlement already in the program, no new spends):
1. Static literal extraction as the FORM of the H1 diff:
  a script that extracts hardcoded hex values and numeric
  layout literals from both builds into one table is the
  diff instrument inside the consolidated specification
  (settlement U-B). This is the spine's scripted constant
  diff, mechanised; adopted.
2. Logistic-fit danger bands as an implementation option
  inside the MP8 Monte Carlo script build (settlement
  U-D): fitting the band cut points to measured bot
  outcomes instead of re-ruling them by hand is the same
  settlement with a better last step. Opus chooses the fit
  method; the labels still land in the specification.
3. The deliberate-ergonomics caution on H1: a divergence
  in the diff is a question, not an automatic reversion.
  The spine's table already works this way (the diff forces
  a recorded choice per divergence); the caution is
  recorded here so the specification run does not flatten
  deliberate port choices by default.
4. Height-scaling framing: height-denominated scaling is
  standard practice; the failure is the unjudged clamps and
  the missing player scale offset. The spine already keeps
  the mechanism and re-rules only its numbers, and the
  offset is owner Q2. Recorded as agreement, not a change.

Not adopted: the radial selection HUD redesign, audio and
haptic redundant cues, the unified pause-ledger modal, and
billboarded orrery markers. Each is a design direction, not
a settlement of an inventoried gate; the first three are
outside this audit's commissions, and the fourth is a lead
Opus may weigh inside the campaign capture round (U-C)
without chair adoption. The in-engine CVD shader toggle is
not adopted over the simulation pass: the simulation over
captures (U-D) matches the colour-vision run already added
to issue 208, and one instrument should serve both. The
live slider harness for HD7 is left to Opus's discretion
inside the calibration sitting; static plate-at-zoom
captures remain the commissioned form.

## 6. Settlement program (agent terms)

U-A. Calibration-sitting capture round. Rides the issue
212 S-E camera calibration sitting, which already puts the
owner at 1440p and 4K: HUD and title captures at both
resolutions plus one small windowed size, panels over the
brightest nebula patch, full-fleet roster, plate-at-zoom at
the standard radius and the owner's effects zoom (carrying
HD8's encoding pick, IC4 and IC5 presence checks). One
owner review round; no new run. Carries HD1, HD2, HD3,
HD4, HD7, HD11, HD13, HD15, MN1, MN5, MN7, TY5, AC4, and
inputs to TY3, TY4, TY6, TY10.
U-B. One consolidated UI specification. One Opus run:
the scripted two-build constant diff (Flash form, section
5.1), palette consolidation (MP3, MP11, IC8, the lavender
family given a stated meaning or replaced), one shared
scale function (TY4), base-size and minimum-size rules
(TY3, TY6), tier naming tied to the 207 benchmark (MN4),
the AC5 focus stylebox, the IC3 string-mechanism note, and
every one-line recording in the adopted table (HD5, HD9,
MN6, TY9, TY10, IC7 application). This is the audit's main
deliverable to Opus.
U-C. Campaign capture round. One Codex run, one owner
review round: side-by-side SVG and 3D captures of the same
sector, two flight times, one unmuted variant, event
screens (MN12), and a stop-type recognition pass (IC1).
Carries MP2, MP6, MP7, MP10, MP12, IC2, and the map half
of IC7.
U-D. Two one-time script builds. (1) MP8 danger-band Monte
Carlo on the existing campaign sim harness (Flash fit
option, section 5.2); labels re-ruled on the result inside
U-B; no owner round for the data. (2) AC1 CVD simulation
over the U-A and U-C captures (deuteranopia, protanopia,
tritanopia); failures are specified as redundant encodings
inside U-B on the MP4 precedent, and the owner rules on
failures inside the U-A and U-C review rounds. The U-D.2
instrument is the same method as the issue 208 colour-
vision addendum; the two runs share captures where they
overlap and neither is a gate.
U-E. Standalone pieces. HD6 log soak: one Codex run (soak
capture plus line count; cap decision from evidence).
MN8 debrief specification: one Opus run plus one owner
review round on a mock capture (MN9 folds in). MN10 host
read: one Opus run (which campaign presentation ships;
fallback is scaffold or surface). MP9 precedence read
folds into U-B. MN3 defaults block: re-ruled as one block
after the issue 207 benchmark reports, one owner review
round (AC3 folds in there, per section 2).
Relations: U-A rides issue 212 S-E and must land in the
same sitting or the calibration data and the UI captures
split across two owner sessions. HD12 rides the fx E6
salvo round under issue 210. TY8 rides the playtest
checklist route (issue 202 successor). Nothing here
reopens a ruling from issues 208 to 213.

## 7. Owner questions

Put to the owner with this synthesis; picks are the
chair's. Rulings will be appended as section 8 and filed
to Opus as one outcome issue.

Q1. Does the shipped game show its developer surface?
(HD14, MN2) The playable build's battle bar carries Report
a problem, Copy report, and Diagnostics, plus a test-hull
toggle in battle settings; the port deleted them without a
decision, and moved all settings to the title screen.
Pick: no. The player surface ships clean, developer tools
live behind a dev flag, and the comfort settings (shake,
flash, speed) stay reachable mid-battle in the port's
single architecture. Stakes: free now, a redesign later;
it also decides what every player's battle bar looks like.

Q2. Is a player-facing UI scale setting in scope for the
port, with a reduce-motion entry decided in the same
ruling? (AC2, AC7) Pick: yes to UI scale, implemented on
the consolidated scale function (inside U-B's scope, one
Opus run already counted); reduce-motion decided alongside
it rather than in a later audit. Stakes: without a scale
setting, reading comfort is set entirely by window size;
the 1440p and 4K targets are render targets and say nothing
about whether the text is comfortable to read. If ruled
out, AC2 and AC7 convert to KEEP as recorded decisions and
the absence stops being an accident.

Q3. Should faction colour enter the battle UI, or stay on
the ships alone? (IC7) Pick: map yes, battle plates no.
The campaign map already carries faction colour (crests,
system looks) and should keep it under a stated rule
written in U-B; in battle, the friend/foe channel is never
diluted, and enemy faction is carried by crest and name,
not by recolouring IFF. Stakes: faction identity in battle
currently rides on ship models alone, while the map mutes
station colours by an unrecorded amount (MP12); ruling
this once settles both directions.

## 8. Not checked

Carried from the pack and all legs, chair-verified as
still open: the Godot port's underlying battle log array
cap (HD6's data half; U-E's soak settles the behaviour,
not the array), floating combat text location in the port
(HD12), campaign_host.gd's fallback choice (MN10; settled
by the U-E read), map3d_system.gd's LOOKS values (IC7's
map half), the JS map generator's column structure (MP5),
the JS nameplate's full showing rules (HD7), UI constants
set in Godot scene files, the patron colour table (IC2),
and a full diff of the duplicated stylesheet. No captures
were run for this audit; every settlement above is priced,
none is executed.

## 9. Owner rulings (Ryan, Nov 6, 2026, about 19:32 CST)

Ryan ruled: agree with all chair picks on this audit (his
message adopted the six plain-English questions across this
audit and issue 201 in one ruling, with the single exception
recorded in the issue 201 synthesis).

R1 (Q1, developer surface): RULED per chair pick. The
shipped game does not show its developer surface. Developer
tools (Report a problem, Copy report, Diagnostics, the
test-hull toggle) live behind a dev flag; the player surface
ships clean; comfort settings (shake, flash, speed) stay
reachable mid-battle in the port's single settings
architecture. HD14 and MN2 settle on this ruling inside
settlement U-B and the one Opus application run it names.

R2 (Q2, UI scale and reduce-motion): RULED per chair pick.
A player-facing UI scale setting IS in scope for the port,
implemented on the consolidated scale function inside
settlement U-B (AC2 REPLACE stands). The reduce-motion
question is decided in this same ruling, not deferred: a
reduce-motion entry covering UI animation (map pulse,
ambient drones, floating text) is also in scope, inside
U-B (AC7 REPLACE stands). Qwen run 2's deferral variant is
superseded by this ruling.

R3 (Q3, faction colour in UI): RULED per chair pick.
Campaign map: faction colour stays, under a stated rule
written into settlement U-B, including the recorded muting
amount (settles MP12's unrecorded lerp as a decided value
or a removed one, per the U-C captures). Battle: faction
colour does NOT enter the nameplates or the friend/foe
channel; IFF stays friend/foe only, and enemy faction is
carried by crest and name. IC7 settles on this ruling.

With R1 to R3 ruled, this audit is complete. The settlement
program in section 6 goes to Opus as one outcome issue.
