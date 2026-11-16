# Outside check: PR 796, Hegemony paint stack, engine fix and the R262 one-step lift

Refs #256

## Verdict: GO WITH CONDITIONS

Three conditions, all of them record-keeping rather than build faults: the direction page's section 3 mirror rule still claims more than the build does, the H10 hatchbox density flag needs the Board's explicit call (the PR itself refers it), and the sheets' own pictures still show the closed engine mouths the PR fixed. The work itself is verified end to end: the chair read the engine fix in the shipped parts.py, ran stepped() on the concept pairs and reproduced every stepped tone in the PR, and matched the audits JSONs against the PR's claims figure for figure. The section 1 and section 2 amendments land in this PR, so the opus_check_772 pattern is discharged for this PR's own changes; section 3 is a pre-existing sentence this PR's own disclosure contradicts, which is condition 1.

Council: blind Rey GO WITH CONDITIONS. DeepSeek (DeepThink on, Search off, verified both ends) GO WITH CONDITIONS. Qwen (Qwen3.8-Max, verified both ends) GO. Grok (Fast, verified both ends) GO WITH CONDITIONS. Flash (Flash-Lite, verified both ends) GO WITH CONDITIONS. ChatGPT (chat, GPT-6 at High, verified both ends) GO WITH CONDITIONS.

## The brief

opus_check_796: PR 796 (merged, head 30b3977a, merge fff644e0), the Hegemony paint stack for issue 780 with the R262 update: fix the closed engine bells in the Hegemony kit, apply the one-step plate lift to H10 and IM5, retune SAT to 1.3 to hold hue, and amend hegemony.md in the same pass. Same format as opus_check_748.

## (a) Engine fix

**Verified.** The chair read engine_bell in the merged parts.py: each solid trim band is rebuilt as four bars (top, bottom, left, right) whose inner edges sit at iw = hw + t*0.2, outside the mouth, so the centre is open and a ray from astern reaches the lining, throat plate and vanes; the code carries the R262 comment naming the fault and the fix. The open-bell tests in the pack pass (H10 4/4, IM5 6/6, rim 12/12). The A16 fixture does not hash parts.py, so its PASS is not evidence for this change, and the PR says so itself; the ray tests are the evidence. Every leg passed this item; ChatGPT adds the fair boundary that the pack holds the code excerpt and test counts, not the ray-test implementation or before-and-after pictures, so the assembled geometry is certified by the tests as reported, not independently re-derived.

## (b) The step

**Verified.** The chair ran stepped() from the merged stack.py on the concept pairs at PLATE_STEP .45 and reproduced the PR's table exactly: hull (42,55,78)/(85,94,110); hull_step (41,53,75)/(79,89,106); hull_shade (34,44,67)/(53,67,90); trim (58,76,101)/(98,109,125); nozzle (53,67,90)/(85,94,110). ChatGPT recomputed all ten endpoints independently and matched. The trim light end is the cap and is returned unchanged; liner is not stepped; glow colours, LIGHT_GAIN 1.45 and the look.gd lift are untouched by the function. Family order holds at both ends and nothing passes the cap. SAT is 1.3 in the shipped stack with the header comment giving the reason (blue-over-red 1.56 at SAT 1.5 after the step, 1.52 at 1.3, concept 1.46).

## (c) Battle read

**Delivered as specified.** H10's port battle median moved (45,53,66) to (50,61,76) against the Board's halfway aim of (52,61,76): green and blue exact, red 2 counts short. IM5's port battle median moved (39,49,61) to (43,53,67), about halfway to its concept on the same proportional step. Three views now read at or lighter than their concepts: H10 fitted (+11/+12/+10), IM5 cam170 (+9/+10/+6) and IM5 fitted (+4/+4/0). The PR calls out the first two; the third is in its tables but not its prose. This is the known whole-fleet behaviour of one shared step, the same shape as S8 under R258, and no leg treats it as a defect. Lift hue is unchanged per ship (H10 220.4, IM5 221.02, before and after in the audits).

## (d) Audits

**Verified against the JSONs.** Emissive map max 0.7605 with 0 warm pixels and every flat light under 0.8, both ships. Value-cap over-share 0.0 over #626d7d on both atlases, both ships. Hull p99 (93,106,123) on H10 and (91,103,119) on IM5, under the cap channel by channel. Surface check PASS. Symmetry 7/7 decals mirrored per ship. Density: exactly one paint flag, H10 hatchbox 0.71 against the 0.75 bar, and the PR states the step introduced it (0 flags before). The bake commit named in bake_sandbox.json is 2e66982f1, matching the PR; the chair compared it against the merged head and the head is exactly one commit ahead, changing only the bake output files themselves and pictures.py, so no paint code changed after the bake and the audits tie to the merged head (this answers DeepSeek's fourth condition at the chair).

## (e) The page, and the 772 pattern

**Sections 1 and 2 verified; section 3 is condition 1.** The merged hegemony.md records the as-built faint seams on plated zones with the actual joint widths in section 1, and in section 2 the hue hold with the SAT 1.3 retune and the full R262 step (five tones, the formula, the cap hold, the unchanged items). Those are the amendments the 772 pattern requires for this PR's own deviations, and they landed in the same PR. Section 3 (line 63) still reads "every decal, wear patch and scuff on one side is mirrored on the other", while the PR's first look discloses that the shared wear and scuff noise is not mirrored port to starboard and that fixing it needs a shared change outside this PR. The 7/7 audit covers decals; it does not cover that noise. The page therefore states a rule the build does not meet.

## Conditions

1. **Record the section 3 exception, or land the fix.** Amend hegemony.md section 3 so the mirror rule matches the build (decals, bands and grid mirrored; shared wear and scuff noise not), or make the shared change that mirrors the noise. Until one of those lands, the page overclaims. Two wording points belong in the same pass: the page (line 43) calls #888f9f "a light catch and a wear tone" while the R262 text names the cap #626d7d as the worn-edge tone, so two tones carry the wear name in different places; and the page never names a hull_step pair, though stack.py carries the pair and steps it. (Blind Rey, DeepSeek and ChatGPT landed on the section 3 point independently; DeepSeek and ChatGPT raised the wording points.)
2. **Board call on the H10 hatchbox density flag.** The step introduced 1 paint flag, 0.71 against the 0.75 bar. Accept it on the record, or ask for the hatchbox zone's small grid to be strengthened. The PR frames this as the Board's call and every leg agrees it cannot be silently read as a pass. (All legs.)
3. **The sheets' own pictures still show closed mouths.** The PR discloses this and leaves the re-render for the Board. Re-render them so the sheets show the open bells, or record explicit acceptance that they stay stale; as they stand, a reader of the sheets sees the fault the PR fixed. (DeepSeek, ChatGPT, Grok, Flash.)

## Notes

- **The PR's hue figure is H10's.** "Lift hue unchanged (220.4)" quotes H10; IM5's figure is 221.02, also unchanged. The claim holds per ship; the sentence should carry both numbers or neither. (Blind Rey, DeepSeek.)
- **IM5's port-to-starboard spread widened.** The step scales proportionally, so the gap between IM5's battle port median (43,53,67) and its cam170 (61,72,85) grew from about 13 counts to about 18. Not a defect against R262, which orders the proportional step, but it is the mechanism behind the lighter-than-concept views and worth the Board seeing stated plainly. (Blind Rey.)
- **IM5's hull atlas runs at about half H10's texel density.** IM5 uses 27 percent of its hull atlas area; the 2048 density figures are 819,768 texels per unit squared for H10 against 420,955 for IM5. A known consequence of the shared atlas layout, recorded here because it bounds how much more detail IM5 paint can carry. (Blind Rey, ChatGPT.)
- **"Doubles" in the pack's density wording.** A 4096 bake doubles linear resolution; texels per unit squared quadruple. Wording only, in the evidence pack, not the PR. (ChatGPT.)
- **Glow appearance.** The PR's unchanged claim covers the authored glow constants; whether rendered glow is identical through the retuned saturation is not established by the pack. No leg treats this as more than a precision note. (ChatGPT.)
- **Standing, not a condition on this PR:** the PC run (Blender 4.5, GPU, 4096 bake), the in-game pictures and the stage 7 death seam check were not run, as the PR states. Sandbox correctness is what this check establishes; production acceptance stays with the Board's pipeline, as with 772 and 787.

## Leg notes and slips

- Grok says H10 landed "one unit short on the red channel"; the figures are (50,61,76) against the aim (52,61,76), which is 2 short. Grok also counts two views lighter than concept where there are three (it misses IM5 fitted, +4/+4/0). Recorded; its verdict and conditions are unaffected, and nothing in this delivery rests on either figure from Grok.
- Flash reads the A16 fixture PASS as support for the engine fix. The fixture does not hash parts.py, so its PASS is not evidence for the change; the open-bell tests are. Flash also does not raise the section 3 gap. Its sole stated condition (the hatchbox flag) stands and is condition 2 here.
- Qwen's clean GO accepts the surface check on the PR's attestation; the raw surface field is not reproduced in the audits JSON excerpts in the pack. The chair verified surface_check PASS from the merged surface_check.json files directly, so the acceptance holds on repo evidence rather than attestation.
- DeepSeek's generation stopped once mid-thinking and was continued in the same chat on the same settings; DeepThink on and Search off were verified before sending and after completion. Recorded for completeness.

## Not checked

- The paint pictures at picture level; the numeric audits over them are verified above.
- The PC run of the stack and the stage 7 checks; the sandbox figures are the record the PR stands on.
- The shared wear/scuff mirroring fix itself; condition 1 records the gap, and the fix is a shared-code change for the Board to schedule.
