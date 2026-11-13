# Outside check: PR 611, A17 through the repaired recipe, claw_arm part (issue 532)

- Repo: rcbailey12/voidsworn. Delivery branch: muse/issue-256. Refs #256.
- PR head checked: opus/issue-532-a17, 417832ae7a. The PR merged
  2026-11-12T23:41:37Z before this check ran, so this is the standing
  after-the-fact check (precedent: opus_check_524c); a finding graded
  BLOCKING must be fixed in a follow-up.
- Chair: Rey, blind. Read the PR body, the full diff (1,961 lines),
  sheet_fixture_hash.py, corsair_A17.json, the kit.py wrapper and parts.py
  builder, the two R225 (c) check fixes and the A16 sheet changes.
- Council (Ryan's Nov 12 composition): DeepSeek GO WITH CONDITIONS with one
  BLOCKING (adopted in full as Finding 1). Qwen seat empty (daily
  Qwen3.8-Max cap). Grok GO WITH CONDITIONS (ideation seat). Flash GO WITH
  CONDITIONS (ideation seat).
- Verdict: GO WITH CONDITIONS. The conditions are the follow-ups below,
  headed by Finding 1, plus the PR's own stated gate: nothing has run on
  the PC yet (A17_RUN_532.bat is queued) and every figure in the body is
  sandbox.

## The Board's four questions, answered

1. claw_arm general. PASS with notes. The part exists at two levels: the
   Kit.claw_arm wrapper (tools/blender/build_sheets/kit.py:611-623;
   shoulder, pts, w=0.42, hook=1.0, fork=0.45, optional housing) and the
   builder in tools/blender/kits/hullbreakers/parts.py (556-618), where
   every size derives from w and the segment lengths (th = w*0.36,
   rh = th*1.35, tapers 1.0-0.3*i/n). 'claw_arm' is registered in MACHINES
   and SUBPARTS (parts.py:438,447), so the stage 4 audit and the death cut
   treat it as a machine. A17's sheet passes its own points
   (corsair_A17.py:136-141). The launch_tube R224 additions in the same PR
   are proportional to r and depth, and A16's tube and bay ratios improved
   through the same kit changes (0.45/0.29 to 1.02/0.80; 0.18/0.18 to
   1.64/1.61). Minor nits: Finding 8.
2. Length one home (R225). PASS for the authored value. LENGTH = 14.6 sits
   in one place, corsair_A17.py:15; the GAME line (:16) states the class
   14.5; corsair_A17.json carries no length field (14.6 and 14.5 appear
   only in its notes prose, naming the sheet as the home); hull_table.gd
   CLS_LEN is untouched. The generated copy is mislabelled: Finding 2.
3. Fixture staleness guard. The mechanism is real and closes the hole
   opus_check_608 NOTE 3 named: sheet_fixture_hash.py hashes five files
   CRLF-normalised, and death_seam_check.gd (64-84, 89) rehashes the
   record's own list, only when running on the fixture, and fails on
   mismatch; the author proved it with a one-byte change; the fixture was
   regenerated in this PR (1,559,341 to 1,610,663 bytes) and the record
   matches the script's list. But the list itself is incomplete:
   Finding 1.
4. Nothing tuned to A17 alone (R225 (c)). PASS. authored_interiors_check.gd
   (78-90) now counts the seams in the ship's own voidsworn_destruct record
   and expects n_main == own_seams + 1; sheet_contract_selftest.py (72-79)
   drops one of the tested ship's own weapons instead of swapping in
   c_marauder, and restores it in a finally block. A16's sheet changes are
   room-box coordinates with change-log entries (corsair_A16.py:215-231,
   279-283). ships.md section 2c gained the R229 whole-concept line in this
   PR, as the build approach requires. A17's json stays "bake": "none"
   until the 601 paint stack lands.

## Findings

BLOCKING 1 (DeepSeek catch, chair adopts; the chair's pre-leg read had
half of it as a note). The fixture guard's FILES list omits two inputs
that can change the fixture's geometry. sheet_fixture_hash.py's own
header (lines 7-11) gives the regeneration procedure: step 1 runs
tools/blender/r209/sheet_hull.py with R209_SHIP set to
tools/recipe/ships/corsair_A16.json. Neither file is among the five hashed
(kit.py, hullbreakers/parts.py, build_sheets/contract.py,
tools/recipe/export7.py, the A16 design file). A change to the hull
builder or to the recipe input therefore stales the fixture silently
while the guard still reports fresh: exactly the failure the guard exists
to prevent, and the same shape as the opus_check_594 BLOCKING (a
prospective hole in a guard mechanism). Fix in a follow-up: add both
files to FILES, regenerate C19_51_unbaked.sheet.txt, and wire
sheet_fixture_hash.py --check (or a fixture run) into the job or CI,
since A17_RUN_532.bat passes an explicit installed GLB and never
exercises the guard.

NOTE 2 (DeepSeek catch, chair verified against the diff). The generated
14.6 copy lives in docs/ship_pipeline/build_sheets/corsair_A17/
checks.json, not in manifest.json as the chair's pack said (pack error,
owned). Worse than the label: checks.json still names the field
length_from_game while it now holds the sheet's 14.6, and
model_vs_game_percent changed 0.32 to 0.16 in the same edit (diff lines
240-250) while the measured lengths barely moved (length_side 14.562 to
14.613). The metric is now computed against the sheet, not against the
game's CLS_LEN 14.5 (against 14.5 the model sits about 0.53 percent off),
so the check no longer measures what its name says. Rename the field
(length_from_sheet) and keep a separate model-vs-game metric on CLS_LEN.
The A17 README's "manifest entry" wording needs the same correction.

NOTE 3 (DeepSeek catch, chair verified). docs/playbooks/deaths_and_hits.md
says "A17 is zero too", while the PR body's own A17 death_seam row
reports outside own piece 1, varying 0 to 4. Name which counts are zero
(machines split 0 of 29, outside the ship 0) and qualify the third.

NOTE 4 (DeepSeek catch, chair verified). The A17 README and the body's
R224 bullet still call prongs the lowest-density part (1.50/1.29), but
this PR replaced the prongs with claw_arm at 2.53/2.33 and removed prong
from the kit sub-parts. Recompute the line.

NOTE 5 (DeepSeek catch, chair verified). The dish colour change is
kit-wide, not A17-only: the A17 sheet's own change log says "the kit's
dish colour is rusted grey, not white". A16's dishes take the same change
with no re-render in this PR. Record it as a kit change, or make it a
per-part override if A17 alone was meant.

NOTE 6 (chair, standing position from opus_check_608 NOTE 2). A17 carries
1 outside-own-piece triangle at the B-1 deck edge, varying 0 to 4 as the
arm geometry moves the cut, and death_seam_check asserts none of its
counts: it prints them. A16 on the regenerated fixture is clean (0 of 37,
0, 0). The count stands as recorded, not as passed.

NOTE 7 (DeepSeek, open question). corsair_A17.json sets outline_gate 0.9
while the sheet reports outline IoU 73.8 percent. The json's notes say
stage 3 only reports the outline for sheet hulls; confirm it does not
gate before the PC run, or stage 3 fails at 0.738 against 0.9.

NOTE 8 (minor group, DeepSeek unless marked). (a) The parts.py builder
docstring names A17 (556-558); the pack's "no A17-specific names" was too
broad. No A17 numbers exist in the code; the names are provenance in
documentation. Pack wording owned. (b) The wrapper emits kind='claw'
while the part type is claw_arm; the audit works off the part type, so
cosmetic. (c) The builder's rivets=4 is not exposed at the wrapper.
(d) The bay's rivet pitch is an absolute 0.25 where the tube additions
are proportional; reads as a hardware constant. (e) The GDScript guard
rehashes get_file_as_string re-encoded to UTF-8 while Python hashes raw
bytes, and the digest concatenates files with no names or lengths; exact
for today's sources, brittle at the edges. (f) authored_interiors_check
sums destruct records across every node; a duplicated record would double
own_seams and fail the check for the wrong reason.

## Council record

- DeepSeek: GO WITH CONDITIONS, one BLOCKING (Finding 1, adopted in full)
  plus the NOTEs folded into Findings 2, 3, 4, 5, 7 and 8. Chat:
  https://chat.deepseek.com/a/chat/s/6144bc9c-25de-4b5a-98cd-c6598eec8419
  (DeepThink on, Search off, both verified before and after; generation
  stopped once mid-thinking and was continued.)
- Qwen: seat empty. Qwen3.8-Max hit its daily cap again; selector and
  header both verified Qwen3.8-Max before and after the attempt. The
  prompt and all five files (pack, pr611.txt, pr_body.md,
  sheet_fixture_hash.py, corsair_A17.json) wait in
  https://chat.qwen.ai/c/6a8b5432-ffb8-470c-a309-2225571b6114 for a retry
  after the reset. Eighth empty Qwen seat on Nov 12.
- Grok: GO WITH CONDITIONS (ideation seat; verdict recorded, not adopted
  as reviewer evidence). All findings NOTE. The leg ran on pasted text
  without the 137 KB diff and scoped itself honestly to that evidence;
  its conditions 1 and 2 (read the claw_arm source and both check files)
  are discharged by the chair's own diff read, and its condition 3 is
  NOTE 6. One slip: it wrote that death_seam_check asserts the three zero
  counts; the check prints them and asserts none. Chat:
  https://grok.com/c/e8029e6d-34a2-4c94-85ff-ab7a8d3615d4
- Flash: GO WITH CONDITIONS (ideation seat). All four Board answers
  verified against the files, and its line citations checked out. Its one
  condition (clarify the sheet_fixture_hash.py header's relation to
  sheet_hull.py) is Finding 1 seen from the documentation side. Chat:
  https://gemini.google.com/app/421ed8aade9e0123
- Rey (chair): all four questions verified against the head files as
  above. Finding 1 is DeepSeek's upgrade of the chair's own note (the
  chair had sheet_hull.py only); Finding 6 is the chair's standing note;
  the pack's two errors (manifest for checks.json, the too-broad
  no-names line) are owned in Findings 2 and 8.

## Method compliance

The PR body carries its done-when evidence well: stage results, the
death_seam rows for both ships, the density table, the one-byte guard
proof, and the explicit not-yet-run PC gate. The R229 method line landed
in ships.md section 2c in this same PR, per the build approach. Three
evidence defects, all in the paper around the build rather than the
build: the mislabelled length metric (Finding 2) and the two stale texts
(Findings 3 and 4). This delivery follows the standing rule: one file, on
muse/issue-256, saying Refs #256.
