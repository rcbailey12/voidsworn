# Outside check: PR 610, paint stack for build-sheet ships (issue 601)

- Repo: rcbailey12/voidsworn. Delivery branch: muse/issue-256. Refs #256.
- PR head checked: opus/issue-601, a7adc07084. PR still open at delivery.
- Chair: Rey, blind. Read the PR body, the full diff structure (2,423 lines,
  28 files), stack.py, paint_stack.py, surface_check.py, density.py,
  bake_sheet.py, the standing.py and env.bat changes, the A16 json change and
  the ships.md method text at head.
- Council (Ryan's Nov 12 composition): DeepSeek NO-GO (one of its two
  BLOCKING grades adopted, one graded NOTE by the chair; see the council
  record). Qwen seat empty (daily Qwen3.8-Max cap). Grok GO WITH CONDITIONS
  (ideation seat). Flash GO WITH CONDITIONS with one BLOCKING the chair
  refutes (ideation seat).
- Verdict: GO WITH CONDITIONS. Condition 1 is the PR's own stated gate: do
  not merge before the queued PC run A16_RUN_601.bat passes (RULEBOOK 0.9(a),
  (d)); every figure below is sandbox (Blender CPU, 1024 atlases) and the
  shipped atlases are 2048, with the scene gate unmeasured. Condition 2 is
  the one BLOCKING follow-up in Finding 1.

## The Board's four questions, answered

1. Faction stack purity. PASS. The shared machinery (kits/shared/
   paint_stack.py) contains no ship or faction names; every look constant
   lives in kits/hullbreakers/stack.py. A16's json change is only "bake":
   "none" to "stack" plus a notes sentence; zone placement stays the sheet's
   materials; bake_sheet.py loads the stack by the json's faction field and
   builds through the same sheet_hull stage 4 audited. The palette's
   provenance is A16's accepted concept (k-means into the stack's CONCEPT),
   declared in the stack header and the body. One impurity: Finding 2.
2. surface_check.py generality. PASS. Classes derive from material flags
   (ps_inside, p3_textured, the p3_glow/p3_ember/p3_light prefixes) and the
   interior role; six ortho views; the fail threshold is zero room or bare
   pixels; offending objects are named via a green-channel index. No ship
   names or ship numbers. Sensitivity limits: Finding 4.
3. Running lights. Size, colour and placement PASS; brightness FAILS as
   reported (Finding 1). RUNNING_LIGHTS in stack.py: world .30 diameter on a
   roughly 26-unit ship (about 0.81 px on a 70 px battle view), LIGHT_RGB
   (196, 30, 20) #c41e14, flank row plus deck points placed by rule with
   clearances; the body reports 15 lamps and +1,320 triangles (ship mesh
   129,964).
4. R224 density. PASS on paint. density.py is general (per part_kind against
   the hull, flags under 0.75, reports and never gates). The sandbox table
   has no paint flags and two mesh flags (tube 0.45/0.29, bay 0.18/0.18)
   which are build geometry. The body's summary ranges are wrong (Finding
   5). R228's method text landed in ships.md section 0 item 2 in this same
   PR, as the build approach requires.

## Findings

BLOCKING 1 (DeepSeek catch, chair verified by recomputation). The running
lamps render at about half the brightness the PR claims. In stack.py,
glow_material sets the 'light' colour as [c / LIGHT_GAIN for c in
lin(LIGHT_RGB)]; lin() already divides by LIGHT_GAIN (1.45). Linear red is
therefore 0.5518 / 1.45 / 1.45 = 0.2625, and times LIGHT_STRENGTH 1.4 the
emission is about 0.37, not the 0.77 the body and the Board's pass 3 relied
on ("red 0.77, under the 0.8 glow threshold"). The inline comment states the
opposite intent ("lin() divides by the light gain; the lens wants the colour
itself"), which is a multiply: 0.5518 x 1.4 = 0.77, still under the
threshold. Two consequences: the R228 rule (brightness, not size, carries
the read) is undermined as shipped, and the sandbox pictures the Board
reviewed in passes 2 to 4 were rendered with the dimmer lamps, so the
approval of the lamp read was made at half brightness. Fix the division
before merge, or record a Board decision to accept 0.37 with fresh eyes on
a render.

NOTE 2. The decal atlas is one fixed faction drawing. decal_atlas cell 1 in
stack.py draws the literal glyphs "C 1 9" (A16's game code is C19_51), and
fixed RNG seeds (atlas 601, trim 209) make the kill tallies and wear
identical on every ship the stack paints. A16 itself is correct (C19 is its
class code), and A17 is still "bake": "none" until 601 lands (PR 611), so
nothing wrong ships with this merge. But the stack is written once for the
faction, and the next Hullbreaker through it would wear C19 and A16's
tallies unless the atlas learns the ship's own code. Fix before the stack
paints a second ship. DeepSeek graded this BLOCKING on one-home grounds
(R225); the chair grades NOTE for the reasons above, with the
fix-before-second-ship requirement stated. The disagreement is recorded,
not hidden.

NOTE 3. standing.py's point-light exemption from the 2 px floor is
self-declared by the stack's own lights.json (written by paint_stack.run
during the same job). The measured px is printed in the PASS line, so the
exemption stays visible, but the check now trusts the producer's own "point"
mark for the one property the floor exists to police. Acceptable while one
stack exists; worth a second look when a second faction stack writes its
own lights.json.

NOTE 4 (chair, with DeepSeek additions). surface_check sensitivity. The zero
threshold is the strictest available, but at the default 640x320 per view a
sub-pixel leak can pass unseen; the camera frame (positions plus/minus 3,
ortho_scale 1.12) presumes the recipe's normalised blend scale, so a much
larger ship could clip; only the six axis views are checked, so a room
colour visible only at an oblique angle would pass; and the check trusts
material flags, so a p3_textured surface with a partly blank atlas passes.
None of these is A16 tuning; they are the check's known reach.

NOTE 5 (DeepSeek catch, chair verified against density_sandbox.json). The
body's R224 ranges are wrong at both ends. The table in the PR gives texel
ratios 1.61 (thruster) to 1.81 (vent, slit), not "1.63 to 1.84", and paint
detail 0.99 (dish) to 2.26 (lamp), not "1.09 to 2.19". No flag changes:
dish at 0.99 is still above the 0.75 flag line, and paint_flags is empty.
The chair's pack repeated the body's numbers as established facts; that
error is the chair's as much as the author's, and it is corrected here.

NOTE 6. The R224 mesh flags (tube, bay) are carried on the sheet for the
532 line, not paint's to fix. R224's wording is "flagged on the sheet and
fixed in the build"; the body discloses them as build geometry, which is
the right home, but the check records them as open, not satisfied.

NOTE 7 (DeepSeek catch, chair verified). Latent KeyError in the shared
machinery: paint_stack.py add_running_lights falls back to h = R['px'] /
70.0 when r209_length_world is unset or 0, but RUNNING_LIGHTS has no 'px'
key. The sandbox run had the length set, so the branch never fired. Add the
key or raise a clear error before a second faction's rule trips it.

## Council record

- DeepSeek: NO-GO, two BLOCKING (lamp brightness; C19 atlas) plus the NOTEs
  folded into Findings 4, 5, 6 and 7. The brightness BLOCKING is adopted in
  full; the C19 grade is the chair's one disagreement (NOTE 2). Chat:
  https://chat.deepseek.com/a/chat/s/7e3f4dc7-cc10-40bc-89dc-d3a886f11ace
  (DeepThink on, Search off, both verified before and after.)
- Qwen: seat empty. Qwen3.8-Max hit its daily cap; selector and header both
  verified Qwen3.8-Max around the attempt. The prompt and five attached
  files (pack, pr610.txt, stack.py, surface_check.py, density.py) wait in
  https://chat.qwen.ai/c/a68a2fcc-92bd-4e2e-ad37-fbfc877ecbc5 for a retry
  after the reset. Sixth empty Qwen seat on Nov 12.
- Grok: GO WITH CONDITIONS (the PC run), notes matching Findings 2 and 4
  (ideation seat; verdict recorded, not adopted as reviewer evidence). The
  leg ran on pasted text without the 162 KB diff; a few pasted lines were
  reworded by the paste, none of them load-bearing, and Grok scoped its
  judgement to the supplied files. Chat:
  https://grok.com/c/919cd6bb-e267-49b0-9e01-fc97d2140796?rid=36a83528-aaee-460a-b730-d6d4601cd127
- Flash: GO WITH CONDITIONS, its condition being a BLOCKING the chair
  refutes: Flash claimed corsair_A16.json sets "faction": "corsair", so
  bake_sheet would look for kits/corsair/stack.py and fail. Chair-verified
  false: the json at head carries "faction": "hullbreakers" (the field sits
  in the file's unchanged head; fetched from the repo during this check),
  stack_for finds kits/hullbreakers/stack.py, and the body's stage 5
  evidence (ran end to end, 7 decals placed) cannot happen on the unpainted
  route. Flash appears to have promoted the game-side word "corsair" in the
  json's notes into the faction field. Its four answers were otherwise
  accurate but shallow. Chat: https://gemini.google.com/app/4693716f88b6b2a6
- Rey (chair): all four questions verified against the head files as above;
  Findings 3 and 4 are the chair's, Finding 1 adopted from DeepSeek after
  recomputation, Finding 5 owned jointly (the pack repeated the body's
  wrong ranges).

## Method compliance

The PR body carries its done-when evidence well: stage results, the surface
check before/after counts, the density table, the budget, and the explicit
not-proven-yet PC gate. Two evidence defects: the R224 summary ranges do
not match the table the body itself attaches (Finding 5), and the lamp
brightness figure the Board approved in pass 3 is not the figure the code
computes (Finding 1). The R228 method text landed in ships.md section 0
item 2 in this same PR, per the build approach. This delivery follows the
standing rule: one file, on muse/issue-256, saying Refs #256.
