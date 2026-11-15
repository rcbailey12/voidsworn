# Outside check: PR 772, the Sunward paint stack and the flagship painted in the sandbox (issue 756)

Refs #256. PR 772 merged after Board review, so the condition below is a follow-up, not a merge gate.

## Verdict: GO WITH CONDITIONS

One condition: the two disclosed deviations from the approved direction (the frost clip and plate_var/island_tone no longer acting on hull panels) are recorded in RECIPE.md and flagged as Board calls in the PR, but sunward.md itself still states the rules they depart from. When the Board rules the calls, the direction document should be amended in the same pass, so the next builder reads the direction as built. On the numbers, the stack does what the direction asks: the emissive audit is clean, the glow peaks sit under the threshold on the reading the direction's own words support, and the battle-camera read is the dark iron the direction's camera 170 test specifies.

## Council

- Blind Rey (chair, before the pack): GO, notes only. Two of its readings were refined by DeepSeek's leg and the chair's verification against the full stack.py (the pack carried excerpts); both refinements are recorded where they land below.
- DeepSeek (DeepThink on, Search off, verified both ends): GO WITH CONDITIONS, six conditions. One is adopted in combined form (its points 1 and 4, the direction record). Three are answered down to notes with evidence (points 3, 5 and 8). One is adopted as a note (point 9). Its points 2, 6 and 7 agree with the blind leg.
- Flash: not attempted. The Google sign-in for the cloud browser is still blocked on the phone approval outstanding since the 767/770 attempts at 02:30 CST; per the leg discipline no new sign-in prompt was triggered overnight. The seat is recorded as blocked on that approval.
- Qwen: empty by the Qwen3.8-Max daily cap (selector verified at Qwen3.8-Max, pack attached and sent, daily-limit notice returned, no generation). The cap hit on Nov 14 had still not reset by 04:22 CST on Nov 15.
- Grok: empty, bot wall ("Your request was blocked"), 36th consecutive empty seat. Nothing was sent.

## The Board's three points

### (a)(i) Frost: the no-blue rule held by clipping the game accent

The facts are not in dispute. The direction gives the running points the game accent colour (linear 0.8, 0.9, 1.0, read from faction_looks.json) and also says "Never blue light (guide). The builder verifies no Sunward emissive has blue over green." The accent itself has blue over green, so the two sentences cannot both be followed literally; the stack's frost_rgb() holds the accent's blue to its green, and the emissive audit passes on the result (blue_over_green_px 0 across the map, p3_frost max 0.72, blue_over_green false). The chair's reading: the clip is the only resolution that honours the verified rule (no blue over green, machine-checked) at the cost of the colour's exact blue channel, and the PR discloses it in terms and flags it as a Board call. What remains is the record, covered by the condition below: sunward.md still presents the accent as the frost colour with no mention of the clip, so a future builder following the document literally would fail the audit the document also requires.

### (a)(ii) Glow thresholds read as absolute values: passes

The direction's own sentence is the support: spire bar tips "reach about 0.78, just under the threshold", which only reads naturally as an absolute value against the 0.8 threshold. The stack reads every peak that way (brightest linear channel times strength) and the measured map max is 0.7758, under the threshold on either reading of the relative sentences (bells at 0.75 of the threshold would be 0.60 absolute, also under). The peaks the direction does not name (window slits 0.62, louvres 0.45, p3_bore 0.66) are builder calls, recorded in the stack's comments and the PR. No condition.

### (a)(iii) Extra iron tones: the record overstates the endpoints, the tones themselves stay in band

DeepSeek's condition, verified and answered in part. The stack's two plate families do have endpoints outside the iron band: iron_dark runs (16,14,13) to (64,61,60), its dark end below the band's (25,22,21); iron_cast runs (30,28,27) to (88,87,86), its light end above the band's (82,81,81); and worked is the same pair as iron_cast. So RECIPE.md's "two plate-family casts inside that band" is not accurate as a statement about the family constants, and the chair's blind leg, which read the casts as inside the band from the pack's excerpts, is corrected here.

But no plate cell ever takes those endpoints. stack.py takes each cell's tone from the middle of its family's range (TONE = (.20, .75), applied where the cell tone is computed): iron_dark cells land between about (26,23,22) and (52,49,48), iron_cast cells between about (42,40,39) and (74,72,71), all inside the iron band. The rendered variation the direction wants (value steps between plate families, R237, never the wear tones) is what ships. NOTE, then, not a condition: RECIPE.md and the stack comment ("both between the iron pair and the shade pair") should say the tones sit in band by the TONE window, since the constants alone read as a breach. The worked pair equalling iron_cast is by design (worked iron differs by finish: the sworn zone runs rough .58 and metal .62 against the body zone's .68 and .48), though the comment calling it "the iron pair's upper half" is loose for the same reason.

### (a)(iv) plate_var and island_tone no longer acting on hull panels

A real deviation from sunward.md section 1, which says the two values "carry the forged variation instead". It is disclosed in the PR's own table, explained (the shared base's broad noise between the pair's ends read as camouflage blotches at the first 2048 bake), and recorded in RECIPE.md where builders work; the variation itself still exists, as one calm per-cell tone drawn from the families above. The chair accepts the deviation on that evidence. What is missing is only the direction document, covered by the condition.

**CONDITION.** When the Board rules the two calls the PR puts to it (the frost clip, (a)(i), and this deviation, (a)(iv)), amend sunward.md in the same pass: note the clip beside the accent in section 5, and correct section 1's sentence so plate_var and island_tone are no longer described as carrying the hull variation. Until then the approved direction, read literally, instructs a build the stack deliberately does not make, in one case (frost) a build that would fail the direction's own audit. (DeepSeek's points 1 and 4, adopted in combined form; DeepSeek would have the ruling precede any reliance, and the chair notes the stack is sandbox-stage with the PC run still to come, so the amendment can land with the Board's ruling rather than before the sandbox work is used.)

### (b) The hull median (26,27,28) against the concept's lighter grey

The audit's inside_band test is weak evidence and the check should not pretend otherwise: the median sits essentially on the band's dark floor (the iron dark end is (25,22,21)), and its channel order is cool (blue over green over red) while both iron pair ends are warm-ordered. DeepSeek's condition (accept the darker read with a stated reason, or adjust) is answered down to a note on the fuller evidence. The albedo does not swing: median_albedo_lin is [0.01764, 0.01681, 0.01681], red highest, so the cool lean enters with the render light, not the paint. The like-for-like against the concept is the lit deck median in the top view, (52,50,48), mid-band and warm-ordered, in the same mid-grey family as the concept's lit hull (the direction's own concept cluster is #434242, about (67,66,66)); the concept's lighter read is a beauty render under stronger rim light, and the chair's side-by-side at the fitted camera shows the painted hull's lit faces matching that family. The direction's camera 170 test asks for one main colour, black iron, with the hull median inside the band, and that is what the battle picture shows: dark charcoal iron with the ember spires as the one accent. Whether the battle read should sit lighter is a picture judgement for the Board and Ryan, not a stack error. NOTE: the paint README's inside_band framing should carry the dark-floor position with it, so the number is not quoted later as a mid-band pass.

### (c) R243 and the other factions' outputs: passes

The forged panel order is implemented as directed (patch_warp 0, patch_band 0, patch_split 0, held in the layer table with the R243 reasoning in the comments), and panel_nodes draws the panels so the shared _grid never sees the zeros that would divide by band 0. The Eclipse and Hullbreaker outputs are untouched by construction: the PR adds one new file in the Sunward kit and modifies no file under kits/eclipse, kits/hullbreakers or kits/shared; the PR states the git diff on those trees against main is empty and sheet_fixture_hash passes. Nothing in the pack contradicts either claim.

## Other findings

NOTE (DeepSeek point 9, adopted as a note). The direction gives the spire bars their own material values (rough .55, metal .50, the heat scale), and no zone in the stack carries them: the radiator parts take the body zones (siron .68/.48, siron2 .72/.35) with only their grime overridden (.20), and the bars themselves are the emissive fins. The affected iron is the spire sockets and posts, a small area beside the glow, so the chair grades it a note: either give the radiator kind a rough/metal override or record the deviation in RECIPE.md with the others.

NOTE (DeepSeek point 8, answered down). The missing Blender 4.5 proof and the unrun stage 5 steps (render.py, close6.py, blink.py, standing.py paint) are disclosed in the PR in terms, with the reason (no Blender 4.5 in the sandbox) and the mitigation (glow_vertex follows the 4.5-safe attribute order). That is the known next stage of the job, not a hidden gap; the PC run remains the reliance point, as the PR itself frames it. The same applies to the bells reading darker than S8's at the fitted camera (deep-set throats at 0.75; stern-on they glow fully) and to paint_sheet.py's cam170 camera fault, which the PR flags and routes around rather than fixing in this PR.

Accepted as reported: the rivet pitch kept at .011 (the A/B against .013 differs by 0.005 of 255 on average at true pixel size); frost coverage at 0.11 percent top and 0.02 to 0.03 percent sides against the 6 percent cap; RUNNING_LIGHTS = None, the sheet's own 14 frost lamps being the running points; grime .60 applied to gun parts by kind because the hull's gun deck band has no zone of its own; the spine-line decal redrawn along the hull after the first close-up. Budget noted: at 1024 maps the S8 Sunward bake totals 238.5 s against E11 Eclipse's 153.3 s; the 2048 sandbox bake (1981 s on shared cores) is a noisy figure and the PR says so.

## Verified by the chair against the sources

sunward.md in full against the PR's four calls; the stack.py source (the CONCEPT pairs, PATCH_FAMILIES and the TONE window where cell tones are computed, the ZONES table and the radiator grime override, frost_rgb and the glow peaks) against both legs' claims; audits_sandbox.json (emissive, frost cap, lift hue, battle and deck medians) against the PR body; the PR file list for the untouched-trees claim; the battle and concept pictures side by side at the fitted camera.

## Not checked

The PC stage 5 run and the in-game pictures, which do not exist yet; panel_nodes and the rest of stack.py beyond the sections the findings rest on; whether the Board rules the two calls as the PR frames them.
