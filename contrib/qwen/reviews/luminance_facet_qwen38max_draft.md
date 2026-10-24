# Luminance Reference Facet Spec - DRAFT

Model: Qwen3.8-Max, Thinking ON, Search OFF. Filed verbatim from the Qwen chat report (chat titled "Luminance Reference Facet Spec"); em dashes normalized to hyphens if any, wording otherwise unchanged. The granted brief file could not be attached in chat (no usable file-input target); the brief's full verbatim text was pasted into the prompt instead, followed by "Draft the deliverable exactly as the brief specifies."

Project: Voidsworn (PC, Babylon.js)
Prepared for: Ryan (owner, final ruling authority), Opus (coder/verifier)
Status: DRAFT. Nothing in this document is a ruling. All decisions await Ryan.

## 0. Scope and Constraint
OBSERVED: The art pack states once that no background pixel inside the board area may exceed 40% of the luminance of an unlit hull facet. Backgrounds are the theatre; ships are the actors. This is PC-only. There is no phone tier, no phone frame, and no phone acceptance check anywhere in this spec.
OBSERVED: Pack J audit (verified) found the reference facet is UNNAMED. Which hull, which facet, lit how, and where the swatch lives are all unspecified. Two people following the current beauty corner procedure today can derive two different caps.
OBSERVED: The chair recommended (not ruled) a fixed mid-grey swatch so the cap collapses to one number independent of any hull choice.

## 1. Facet Spec (the reference itself)
Decision: Fixed mid-grey swatch. PROPOSED. I pick this over a named hull facet and defend it below.

### 1.1 Why not a named hull facet
A named hull facet still requires someone to specify render conditions (camera angle, ambient term, whether PBR environment contributes, which LOD). Every one of those is another place two verifiers can diverge. It also couples a background luminance cap to a ship-art asset, meaning a hull re-texture silently shifts every board's pass/fail line. The mid-grey removes the hull from the equation entirely.

### 1.2 Exact definition
Parameter / Value / Label
Colour space / sRGB, D65 / PROPOSED - matches Babylon.js default and any standard monitor profile Opus already uses.
RGB value / 128, 128, 128 (hex 808080) / PROPOSED - the most widely recognised "mid-grey"; trivially reproducible in any tool; no rounding ambiguity.
Linear luminance of swatch / 0.2159 (computed via IEC 61966-2-1 transfer) / PROPOSED - derived, not chosen.
Swatch size / 64 x 64 px, rendered flat, no bevel, no border / PROPOSED - large enough for stable sampling, small enough to sit in a corner of the reference doc without confusion.
Lighting / None. The swatch is an unlit flat colour. No scene lights, no IBL, no ambient term in Babylon. Rendered as an UnlitMaterial or equivalent. / PROPOSED - "unlit" is already the OBSERVED requirement for the hull facet; keeping it removes every lighting variable.
Where it lives / (a) A PNG file at /art/ref/luminance_swatch_808080.png in the repo. (b) A constant in code: LUMINANCE_REF_LINEAR = 0.2159 with a comment pointing to the PNG. / PROPOSED - file for human eyeball checks, constant for automated scripts.

### 1.3 The cap as one number
OBSERVED: The cap is 40% of the reference luminance.
PROPOSED cap: 0.0864 linear luminance (that is, 0.40 x 0.2159, rounded to four decimal places).
Rationale: one multiplication, no hull lookup, no render-condition debate. Any background pixel inside the board area whose computed luminance exceeds 0.0864 fails.
For quick eyeball reference, 0.0864 linear corresponds to roughly sRGB 83, 83, 83 for a neutral grey, but the pass/fail test is always on computed luminance, never on a single channel value.

## 2. Measurement Procedure (step by step)
Goal: two different people, same plate, same pass/fail. PC-only.

### 2.1 Tool
PROPOSED: A small Babylon.js inspector script (Opus owns it) that reads the final composited frame buffer of the board scene at 1920 x 1080 (or the dev's native resolution if different, but the script records the resolution in its output). The script samples pixel RGB, converts sRGB to linear per IEC 61966-2-1, and computes relative luminance L = 0.2126 R + 0.7152 G + 0.0722 B on the linear values.
Fallback if the script is unavailable: export the frame as a 16-bit PNG, open in a tool that reports linear luminance (e.g. a Python/Pillow one-liner, or the GIMP luminance readout with the correct transfer curve). The method must be recorded in the measurement log.
PROPOSED rationale: a script removes human sampling error; 16-bit export avoids 8-bit banding near the cap.

### 2.2 Sample points per plate
OBSERVED (from beauty corner spec): at least 20 points per plate, covering corners, centre, brightest visible feature, and plate edges.
PROPOSED fixed grid (to remove "brightest visible feature" judgement):
- 4 corners, inset 8 px from the plate boundary.
- 1 centre point.
- 4 edge midpoints (top, bottom, left, right), inset 8 px.
- 4 points at the ends of the two diagonals, inset 8 px.
- 6 additional points placed on a 3 x 2 grid across the plate interior.
- 1 point at the single brightest pixel in the plate, found by a full-plate luminance scan in the script.
Total: 20 fixed points + 1 brightest-pixel point = 21 points per plate.
PROPOSED rationale: the full-plate scan for the brightest pixel removes the subjective "brightest visible feature" call. The remaining 20 are deterministic coordinates.

### 2.3 Luminance computation
For each sampled pixel (R8, G8, B8 in 0-255):
1. Normalise: r = R8/255, g = G8/255, b = B8/255.
2. Linearise each channel: if c <= 0.04045 then c_lin = c / 12.92, else c_lin = ((c + 0.055)/1.055)^2.4.
3. Luminance: L = 0.2126 r_lin + 0.7152 g_lin + 0.0722 b_lin.
PROPOSED: this is the standard sRGB relative-luminance formula. Rationale: it is the same formula Babylon uses internally, so there is no conversion mismatch.

### 2.4 Pass / fail threshold
PROPOSED: A plate FAILS if any of its 21 sampled points has L > 0.0864.
One number. No averaging. The maximum recorded value per plate is written to the measurement log. If max L <= 0.0864, the plate passes regardless of how it looks. If max L > 0.0864, the plate fails regardless of how it looks.
Region tinting (a whisper of home-faction glow in the far gradient) is OBSERVED as allowed only inside this cap.

### 2.5 Output
The script (or the manual operator) writes a one-line-per-plate log entry:
plate_id | resolution | max_L | pass/fail | date | operator | method(script/manual)

## 3. Re-measurement Plan for the Existing 18 Plates

### 3.1 Schedule
PROPOSED: Opus runs the measurement script against all 18 existing plates within one working week of Ryan approving this spec. Rationale: small set, one script pass, no reason to stagger.

### 3.2 Recording
Each of the 18 plates gets the log entry from section 2.5. Plates that pass are marked PASS and need no further action unless their art changes.

### 3.3 What happens to a plate that fails
PROPOSED escalation order:
1. The plate changes. The background artist darkens or adjusts the failing region so max L <= 0.0864. This is the default and expected fix. The artist resubmits; Opus re-measures.
2. If the artist believes the cap is wrong for that plate's design intent, they raise it with Ryan. Ryan may adjust the plate, or may rule that the cap itself needs revision for a stated reason. The cap does not change by artist or coder decision.
3. The spec changes only if Ryan rules it. No one else edits the 0.0864 number or the swatch definition.
PROPOSED rationale: the cap exists to protect readability. Letting plates negotiate individual exemptions recreates the ambiguity the spec is trying to remove. Ryan is the single authority who can move the number.

### 3.4 Transition
PROPOSED: plates that fail get a two-week fix window from the date Opus posts the re-measurement log. After that window, a failing plate is treated the same as a future submission over cap (section 4). Rationale: the 18 plates predate this spec; a short grace period is fair but bounded.

## 4. Failure Handling for Future Plate Submissions
PROPOSED procedure when a new plate is submitted and measures over cap:
1. Opus (or the automated script in CI) runs the measurement from section 2. The log entry is generated.
2. If max L > 0.0864, the plate is rejected at intake. It does not enter the board build. Opus posts the log line and the sampled coordinates of the offending points to the art channel.
3. The background artist revises the plate. There is no partial acceptance, no "we will fix it later." The plate resubmits and is re-measured.
4. If the artist disputes the measurement (believes the script or sampling is wrong), they may request one manual re-measure by a second person using the same procedure. If both measurements agree the plate is over cap, the rejection stands. If they disagree, the discrepancy is escalated to Ryan with both logs.
5. The cap (0.0864) and the swatch definition are not negotiable at the plate level. Only Ryan can change them, and any change requires updating this spec document, the code constant, and the reference PNG in the same commit.
PROPOSED rationale: hard rejection at intake keeps the rule simple and prevents a growing backlog of "technically over cap but shipped" plates that erode the standard.

## 5. Weakest Point of This Spec
PROPOSED acknowledgement: the fixed grey value 128, 128, 128 is arbitrary. It is not derived from any existing hull facet in the Voidsworn art pack. It was chosen for convenience and reproducibility, not because it matches the luminance the original (unnamed, OBSERVED-unspecified) hull facet would have produced. If the actual intended hull facets are significantly darker or lighter than mid-grey, then 0.0864 is either too lenient or too strict relative to the original artistic intent, and every one of the 18 existing plates could pass or fail differently than Ryan originally envisioned.

What would settle it: Ryan reviews the 18 plates under the 0.0864 cap. If the results match his intent for the theatre-vs-actor balance, the number stands. If several plates that "should" pass are failing (or plates that feel too bright are passing), Ryan adjusts the swatch grey value (or the 40% multiplier) and the spec is re-issued. That single review by Ryan is the only thing that can confirm or replace the arbitrary grey.

End of draft. Awaiting Ryan's ruling.
