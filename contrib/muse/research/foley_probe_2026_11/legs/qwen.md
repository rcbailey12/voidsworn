Research Leg – Issue #258: HunyuanVideo-Foley Licence Terms and Run Plan
Model leg: Qwen (council member)
Date: 2026-11-09
Serves: issue #211 probe (research half)

1. LICENCE

1.1 Geographic scope
The Tencent Hunyuan Community License Agreement defines the permitted territory as: "'Territory' shall mean the worldwide territory, excluding the territory of the European Union, United Kingdom and South Korea." MEASURED (licence, Definitions section, Primary source 1).
Section 5c makes the exclusion absolute: "You must not use, reproduce, modify, distribute, or display the Tencent Hunyuan Works, Output or results of the Tencent Hunyuan Works outside the Territory. Any such use outside the Territory is unlicensed and unauthorized." MEASURED (licence §5c, Primary source 1).
Plain-language meaning for Ryan (solo US developer): He may use the model, generate Foley, and distribute the resulting game audio while he and his users are inside the United States or any other non-excluded country. The moment the game (or its generated audio) is distributed, downloaded, or played within the EU, the UK, or South Korea, that use is "unlicensed and unauthorized" under the licence's own words. MEASURED (licence §5c). DERIVED: this is not a soft preference; it is a hard territorial prohibition with a termination trigger (§8b). If the game is later listed on a storefront that serves EU/UK/SK customers, the generated Foley audio would need to be replaced or the game's availability restricted in those regions, unless Tencent grants a separate licence. ASSUMED (no Tencent guidance on storefront availability vs. direct distribution is quoted in the pack).
The model card front matter reinforces this technically: tag "region:us", extra_gated_eu_disallowed: true. MEASURED (model card front matter, Primary source 1).

1.2 What may be done with outputs
Section 6d: "Tencent claims no rights in Outputs You generate. You and Your users are solely responsible for Outputs and their subsequent uses." MEASURED (licence §6d, Primary source 1).
DERIVED: Ryan owns the generated Foley outright; no royalty, no licence-back, no obligation to Tencent for the audio files themselves. He may ship them in a commercial game, edit them, mix them, or discard them. The only licence conditions attach to the model weights and derivatives of the model, not to the audio output.
However, the Acceptable Use Policy (Exhibit A, last modified Nov 5 2024) includes a prohibition on "placing machine-generated information in a public context without conspicuously identifying it as machine generated." MEASURED (Acceptable Use Policy, Primary source 1). DERIVED: if Ryan ships Foley audio in a game and that audio is presented in a public context (e.g., a trailer, a demo, a marketing clip), the policy's plain wording suggests it should be identified as machine-generated. Whether in-game audio during normal play counts as "a public context" is not defined in the pack. ASSUMED (interpretation question; the pack does not resolve it).

1.3 Commercial terms and the user-count clause
Section 4: "If, on the Tencent Hunyuan version release date, the monthly active users of all products or services made available by or for Licensee is greater than 100 million monthly active users in the preceding calendar month, You must request a license from Tencent." MEASURED (licence §4, Primary source 1).
DERIVED: For a solo developer making an indie game (Voidsworn), 100 million MAU is effectively unreachable. The clause is a gate aimed at platform-scale companies. Ryan's commercial use of generated Foley in a game he may one day sell is unrestricted by this clause in any realistic scenario.
The grant itself is "royalty-free." MEASURED (licence §2, Primary source 1). DERIVED: no per-unit, per-sale, or revenue-share obligation attaches to the licence.

1.4 Attribution and notice duties
Section 3(c): the licensee is "encouraged" (not required) to publish a blog post or public statement and to mark products "Powered by Tencent Hunyuan." MEASURED (licence §3(c), Primary source 1). DERIVED: this is optional; Ryan owes no public credit to Tencent for using the model.
Section 3(d): distributions other than through a Hosted Service must include a NOTICE text file stating: "Tencent Hunyuan is licensed under the Tencent Hunyuan Community License Agreement, Copyright (c) 2025 Tencent. All Rights Reserved. ..." MEASURED (licence §3(d), Primary source 1). DERIVED: this applies when distributing the model weights or derivatives, not when distributing a compiled game containing only generated audio. If Ryan never redistributes the weights, this duty does not attach to the game binary. ASSUMED (the licence does not explicitly state whether embedding generated audio in a distributed binary counts as "distribution" of the Tencent Hunyuan Works; the most natural reading is that it does not, since §6d disclaims rights in outputs).
Section 3(a): give every recipient a copy of this Agreement. MEASURED (licence §3(a), Primary source 1). DERIVED: again, this attaches to distributing the model/derivatives, not to distributing outputs.

1.5 The no-training-on-outputs clause
Section 5b: "You must not use the Tencent Hunyuan Works or any Output or results of the Tencent Hunyuan Works to improve any other AI model (other than Tencent Hunyuan or Model Derivatives thereof)." MEASURED (licence §5b, Primary source 1).
DERIVED: Ryan cannot feed generated Foley back into a training pipeline for a different audio model. For the probe (generate, listen, judge, possibly adopt), this clause is irrelevant. It would matter only if Voidsworn later used generated Foley as training data for a proprietary audio system.

1.6 Termination
Section 8b: on breach, Tencent may terminate; the licensee must then delete and cease use of the works. MEASURED (licence §8b, Primary source 1). DERIVED: any breach (e.g., distributing in the EU, using outputs to train another model) risks losing the licence entirely, requiring deletion of model weights and cessation of use. Outputs already generated and shipped are in a grey zone the licence does not explicitly address post-termination. ASSUMED.

1.7 Governing law
Section 9: Hong Kong SAR law and courts. MEASURED (licence §9, Primary source 1). DERIVED: any dispute would be litigated in Hong Kong, not the US. For a solo developer, this is a practical deterrent to both enforcement and defence.

1.8 Owner ruling
The owner ruled (Nov 6, 2026): "US only is fine." MEASURED (issue #211 text, Primary source 1 pack). DERIVED: the geographic restriction is accepted for the probe. The licence terms must still be documented before any generated audio is kept. MEASURED (issue #211, "Licence verification first" paragraph).

2. FIT

2.1 Hardware
RTX 5080, 16 GB VRAM; 32 GB system RAM; Windows 10. MEASURED (owner setup record, Primary source 1 pack / PC section).

2.2 VRAM requirements (vendor-stated)

| Variant | Normal VRAM | Offload VRAM | Source |
|---|---|---|---|
| XXL (default) | 20 GB | 12 GB | MEASURED (model card table, Primary source 2) |
| XL | 16 GB | 8 GB | MEASURED (model card table, Primary source 2) |

2.3 Weight file sizes

| File | Size | Source |
|---|---|---|
| hunyuanvideo_foley.pth (XXL) | 10.30 GB | MEASURED (Hugging Face API, Primary source 2) |
| hunyuanvideo_foley_xl.pth (XL) | 5.85 GB | MEASURED (Hugging Face API, Primary source 2) |
| synchformer_state_dict.pth | 0.95 GB | MEASURED (Hugging Face API, Primary source 2) |
| vae_128d_48k.pth | 1.49 GB | MEASURED (Hugging Face API, Primary source 2) |

Both variants require the synchformer and VAE in addition to the main checkpoint. MEASURED (Primary source 2: "Both variants also need the synchformer and VAE files").

2.4 Arithmetic: what fits 16 GB VRAM
XXL normal (20 GB required):
20 GB > 16 GB available. Does not fit. Headroom: −4 GB. DERIVED (20 − 16 = 4 GB over).
XXL with offload (12 GB required):
12 GB < 16 GB available. Fits. Headroom: 16 − 12 = 4 GB. DERIVED.
Disk footprint for XXL + dependencies: 10.30 + 0.95 + 1.49 = 12.74 GB. MEASURED (sum of HF file sizes). System RAM (32 GB) must hold offloaded layers; 12.74 GB of weights in RAM is within 32 GB. DERIVED.
XL normal (16 GB required):
16 GB = 16 GB available. Fits with zero headroom. DERIVED (16 − 16 = 0). In practice, the OS, display driver, and ComfyUI overhead consume some VRAM, so "zero headroom" means the model will very likely OOM under normal inference. ASSUMED (no measurement on this exact PC; general GPU behaviour).
XL with offload (8 GB required):
8 GB < 16 GB available. Fits. Headroom: 16 − 8 = 8 GB. DERIVED.
Disk footprint for XL + dependencies: 5.85 + 0.95 + 1.49 = 8.29 GB. MEASURED (sum of HF file sizes). Well within 32 GB system RAM for offloaded layers. DERIVED.

2.5 Fit verdict
XXL normal: does not fit. DERIVED.
XXL offload: fits with 4 GB headroom. DERIVED.
XL normal: nominally fits but zero headroom; effectively unusable. DERIVED/ASSUMED.
XL offload: fits with 8 GB headroom. Recommended. DERIVED.
The XL variant with offload is the clear choice: 8 GB VRAM headroom, 8.29 GB disk, well within all hardware limits. DERIVED (from MEASURED VRAM table, MEASURED file sizes, MEASURED PC spec).
The XL config uses model_precision bf16 and audio_frame_rate 50. MEASURED (config_xl.yaml description, Primary source 2).

3. RUN PLAN

3.1 Primary install route: ComfyUI custom node (if-ai/ComfyUI_HunyuanVideoFoley)
Reason: Ryan's PC has no working Python outside ComfyUI. "Outside ComfyUI, the PC has no working Python: python.exe is the Microsoft Store placeholder." MEASURED (owner setup record, Primary source 1 pack). The repo's own infer.py requires Python 3.8+ and a CUDA environment. MEASURED (README system requirements, Primary source 2). Setting up a standalone Python + CUDA + conda environment on Windows 10 is possible but adds a full environment-build step the PC is not currently equipped for. ASSUMED (feasibility; not tested).
The ComfyUI portable build (v0.42.1) "carries its own embedded Python." MEASURED (owner setup record). The if-ai node installs into ComfyUI's custom_nodes directory and uses ComfyUI's embedded runtime. MEASURED (ComfyUI architecture, Primary source 3). The node's README states: "supports CPU offloading and FP8 quantization (its model loader node is an FP8 loader); models auto-download to ComfyUI/models/foley/ on first run." MEASURED (if-ai README, Primary source 3).
Pipeline: "Model Loader, Dependencies Loader, Torch Compile, Generator (Advanced); the loader loads the model once and the generator can run repeatedly without reloading, 'saving significant time and VRAM'." MEASURED (if-ai README, Primary source 3).
Versions stated in the pack: ComfyUI portable v0.42.1. MEASURED (owner setup record). CUDA 12.4 or 11.8 recommended by the model README. MEASURED (Primary source 2). The pack does not state a specific version number for the if-ai node or the phazei node. ASSUMED (version not given).

3.2 Fallback route: phazei/ComfyUI-HunyuanVideo-Foley
"An alternative node implementation supporting different precision modes." MEASURED (Primary source 3). DERIVED: if the if-ai node has a compatibility issue with ComfyUI v0.42.1 or the RTX 5080, the phazei node is the in-ComfyUI fallback that avoids the standalone-Python problem.

3.3 Tertiary fallback: repo's own infer.py
Would require installing Python 3.8+, CUDA toolkit, and dependencies outside ComfyUI. MEASURED (README system requirements: "Python 3.8+; CUDA 12.4 or 11.8 recommended; Conda recommended"). DERIVED: this is the most effort-intensive route on this PC and should only be used if both ComfyUI nodes fail.

3.4 Per-sequence starting settings

| Parameter | Value | Source / basis |
|---|---|---|
| Variant | XL (hunyuanvideo_foley_xl.pth) | DERIVED (fits with 8 GB headroom) |
| Offload | Enabled (--enable_offload / CPU offload in node) | DERIVED (required to fit; MEASURED flag exists in infer.py and node README) |
| Precision | bf16 (repo default for XL) or FP8 (if-ai node's FP8 loader) | MEASURED (config_xl.yaml; if-ai README) |
| Steps | 50 | MEASURED (infer.py default num_inference_steps 50, Primary source 2) |
| Guidance scale | 4.5 | MEASURED (infer.py default guidance_scale 4.5, Primary source 2) |
| Audio frame rate | 50 latents/sec | MEASURED (config_xl.yaml, Primary source 2) |

3.5 Clip length limits
"Neither the README nor infer.py states a maximum video duration." MEASURED (Primary source 2). The chair's DERIVED note: "latent length scales with duration at 50 audio frames per second, so memory grows with clip length; the project demos use short clips." MEASURED as a DERIVED note from the chair in the pack.
DERIVED: with offload, the model occupies ~8 GB of the 16 GB VRAM. The remaining 8 GB must hold activations, latents, and intermediate tensors. At 50 audio-frames/sec in bf16, each additional second of audio adds a proportional latent block. Without a measured bytes-per-second figure in the pack, I cannot compute the exact breaking point. ASSUMED (no per-second VRAM cost is given).
Imposed limits (conservative, to be verified on the PC):

| Sequence | Suggested max length | Reason |
|---|---|---|
| (a) Capital ship death | 8 seconds | High visual complexity, likely the longest Foley tail; 8 s keeps latent count at 400 frames, well within headroom. ASSUMED. |
| (b) Nemesis arrival | 8 seconds | Similar reasoning; a single dramatic entrance. ASSUMED. |
| (c) Ordinary battle stretch (control) | 6 seconds | Shorter because it is a control; less needs to be proved. ASSUMED. |

DERIVED rationale: the project demos "use short clips." MEASURED (chair's note, Primary source 2). Staying at ≤ 8 s keeps the probe in the same regime as vendor demos and avoids untested long-generation memory behaviour. If the first generation at 8 s succeeds with VRAM headroom visible in the ComfyUI log, the synthesis may extend to 10–12 s. ASSUMED.

4. PROBE SHAPE

4.1 Three sequences (from issue #211)

| # | Sequence | Length limit | Priority |
|---|---|---|---|
| a | Capital ship death | ≤ 8 s | First |
| b | Nemesis arrival | ≤ 8 s | Second |
| c | Ordinary battle stretch (control) | ≤ 6 s | Third |

MEASURED (issue #211 text: "(a) a capital ship death (first priority), (b) a Nemesis arrival, (c) one ordinary battle stretch as a control"). Length limits DERIVED/ASSUMED as above.

4.2 Agent-run estimate

| Phase | Runs | Basis |
|---|---|---|
| One-time setup: install ComfyUI node, download weights (~8.29 GB), verify load | 1–2 agent runs | DERIVED (auto-download on first run; MEASURED from if-ai README) |
| Per-sequence generation (unattended) | 1 run each × 3 sequences = 3 runs | DERIVED (ComfyUI queue; MEASURED pipeline: load once, generate repeatedly) |
| Expected retries (OOM, config error, node version conflict) | 1–2 additional runs across the whole probe | ASSUMED (no failure-rate data in pack) |
| Total estimated agent runs | 5–7 | DERIVED/ASSUMED |

DERIVED: because the if-ai node "loads the model once and the generator can run repeatedly without reloading" (MEASURED, if-ai README), the three sequences can run in a single ComfyUI session as a queued batch, meaning one unattended job covers all three generations. ASSUMED (batch queuing in ComfyUI v0.42.1 is standard but not explicitly confirmed in the pack for this node).

4.3 Ryan listen rounds
Judgement: "the owner's ear, in or alongside the S15 listen pass, against the current recorded takes for the same moments." MEASURED (issue #211, Judgement line).

| Round | Content |
|---|---|
| Round 1 | Ryan listens to all three generated sequences against existing recorded takes; gives per-sequence verdict (adopt / extend / drop). |
| Round 2 (conditional) | If any sequence is borderline, a regeneration with adjusted settings (e.g., different guidance or step count) followed by a second listen. |
| Expected listen rounds | 1 (minimum) to 2 (if retries needed) |

DERIVED from MEASURED judgement structure. No human-hour estimates per R99. MEASURED (issue #258 brief: "No human-hour estimates (R99)").

5. RISKS AND GAPS

5.1 Vendor-stated, unmeasured on this PC
The VRAM figures (20/12/16/8 GB) are from the model card table. MEASURED as vendor claims. They have not been measured on an RTX 5080 with Windows 10 and ComfyUI v0.42.1. ASSUMED (transferability to this exact stack).
The "XL offload = 8 GB" figure may not account for ComfyUI's own VRAM overhead (model manager, preview, torch compile cache). ASSUMED.
FP8 quantization in the if-ai node may alter quality vs. the bf16 path described in config_xl.yaml. The pack does not compare them. ASSUMED (quality delta unknown).

5.2 Route differences
The if-ai ComfyUI node uses an FP8 loader by default. MEASURED (Primary source 3). The repo's infer.py and config_xl.yaml specify bf16. MEASURED (Primary source 2). DERIVED: the ComfyUI route may produce numerically different audio from the repo-script route at the same settings. Whether this is audible is unknown. ASSUMED.
The phazei node supports "different precision modes." MEASURED (Primary source 3). The pack does not enumerate them. ASSUMED (unknown whether it offers bf16 to match the repo default).

5.3 OS and environment
Primary OS support is Linux. MEASURED (README: "OS: Linux (primary support)", Primary source 2). Ryan runs Windows 10. MEASURED (PC spec). DERIVED: Windows is not the primary support target; CUDA kernel availability and path handling may differ. No Windows-specific instructions appear in the pack. ASSUMED (risk of friction).
ComfyUI portable v0.42.1 embeds Python, but the embedded Python version is not stated in the pack. ASSUMED (likely ≥ 3.10 given the ComfyUI release era, but unverified).

5.4 Clip length unknown
No maximum video/audio duration is documented. MEASURED ("Neither the README nor infer.py states a maximum video duration", Primary source 2). The 8 s / 6 s limits imposed above are conservative assumptions. ASSUMED.

5.5 Licence grey zones
Whether shipping generated audio inside a game binary constitutes "distribution" triggering §3(a) and §3(d) notice duties is not explicitly resolved by the licence text in the pack. ASSUMED (most natural reading: no, because §6d disclaims rights in outputs; but untested).
The Acceptable Use Policy's "public context" identification requirement for machine-generated content is undefined in scope. ASSUMED (unclear whether in-game audio during private play triggers it).

5.6 Items the synthesis should verify on the PC before the probe runs
Confirm ComfyUI v0.42.1 launches and reports the RTX 5080 with 16 GB VRAM visible. ASSUMED (needs on-PC check).
Confirm the if-ai node installs without error into the portable build's custom_nodes directory. ASSUMED (needs on-PC check).
Confirm the embedded Python version satisfies the node's requirements. ASSUMED (version not stated in pack).
Confirm CUDA toolkit version available to ComfyUI's embedded runtime meets the "CUDA 12.4 or 11.8 recommended" requirement. MEASURED (recommendation, Primary source 2); ASSUMED (actual installed version unknown).
Run a single short (≤ 3 s) test generation to observe actual peak VRAM before committing to the 8 s probe sequences. ASSUMED (no VRAM telemetry in pack).
Verify the downloaded weights match the HF file sizes (5.85 + 0.95 + 1.49 = 8.29 GB for XL set). MEASURED (expected sizes, Primary source 2).

Not checked
- Actual VRAM consumption of XL-offload on RTX 5080 / Windows 10 / ComfyUI v0.42.1 (no measurement exists in the pack).
- Embedded Python version inside ComfyUI portable v0.42.1.
- CUDA toolkit version present in the ComfyUI portable runtime.
- Whether if-ai/ComfyUI_HunyuanVideoFoley or phazei/ComfyUI-HunyuanVideo-Foley has been tested against ComfyUI v0.42.1 specifically (no compatibility matrix in the pack).
- Audible quality difference between FP8 (if-ai node) and bf16 (repo default) inference.
- Exact per-second VRAM growth rate at 50 audio-frames/sec in offload mode.
- Whether the Tencent Hunyuan licence has been tested or interpreted in any jurisdiction regarding output distribution in game binaries.
- Whether the Acceptable Use Policy's "public context" clause applies to in-game audio experienced during private play.
- Network download time and Hugging Face availability from Ryan's location (no connectivity data in pack).
- Any post-XXL/XL model updates or licence amendments after the pack's quoted dates (licence last-modified date for the AUP: Nov 5 2024; model release: Sep 29 2025; no later amendments quoted).
- The phazei node's specific precision modes and whether it supports offload.
- Whether ComfyUI v0.42.1's queue supports multi-prompt batch execution with this specific node without session interruption.

End of leg. All claims sourced to the evidence pack (PACK.md). No external information used.
