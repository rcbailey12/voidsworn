## 1. LICENCE

| Term | Plain-language operative effect for this project | Evidence tag and source |
|---|---|---|
| Territory | The licence territory is worldwide excluding the EU, UK and South Korea: "worldwide territory, excluding the territory of the European Union, United Kingdom and South Korea." The US is therefore inside the Territory; the EU, UK and South Korea are outside it. | MEASURED quote (PACK.md §Primary source 1, LICENSE definition); DERIVED US-in-Territory conclusion (same definition). |
| Grant and commercial use | Tencent grants a "royalty-free limited license" "for the Territory only" to use, reproduce, distribute, create derivatives of, and modify the Materials. A US solo developer selling a game in the Territory is within the stated grant, subject to the notice and use rules; no separate output royalty is stated in the extracts. | MEASURED quotes (PACK.md §Primary source 1, Section 2); DERIVED commercial-sale reading (same grant plus Section 3 distribution terms); ASSUMED solo-US-developer scenario (PACK.md Leg prompt). |
| Distribution duties | Distributing the works or products using them in the Territory requires giving "every recipient a copy of this Agreement"; modified files need prominent change notices; the licensee is "encouraged" to mark products "Powered by Tencent Hunyuan"; distributions other than through a Hosted Service must include a NOTICE file stating "Tencent Hunyuan is licensed under the Tencent Hunyuan Community License Agreement." | MEASURED quotes (PACK.md §Primary source 1, Section 3). |
| User-count clause | If all products or services made available by or for the licensee had "greater than 100 million monthly active users" in the preceding calendar month on the Tencent Hunyuan version release date, the licensee must request a licence from Tencent and may not exercise the rights until Tencent grants them. A solo game is assumed below this threshold. | MEASURED quote (PACK.md §Primary source 1, Section 4); ASSUMED threshold not triggered (basis: PACK.md Leg prompt solo-developer scenario; not verified). |
| Outputs | "Tencent claims no rights in Outputs You generate." The developer and users are solely responsible for outputs and later uses, but outputs remain subject to the territory, no-training and acceptable-use restrictions. | MEASURED quote (PACK.md §Primary source 1, Section 6d); DERIVED restriction conclusion (Sections 5b, 5c, Exhibit A). |
| No training on outputs | The licensee "must not use" the works or outputs "to improve any other AI model" other than Tencent Hunyuan or its Model Derivatives. | MEASURED quote (PACK.md §Primary source 1, Section 5b). |
| Use outside the Territory | Use, reproduction, modification, distribution or display of the works or outputs outside the Territory is "unlicensed and unauthorized." If the game is distributed or played in the EU, UK or South Korea, that is outside the Territory and falls outside the stated grant; breach can lead to termination. | MEASURED quote (PACK.md §Primary source 1, Section 5c); DERIVED EU/UK/South-Korea consequence (same section plus Section 8b); ASSUMED "played" counts as use/display (not legally verified). |
| Termination and law | On breach Tencent may terminate; the licensee must "delete and cease use" of the works. Governing law is Hong Kong SAR. | MEASURED quotes/facts (PACK.md §Primary source 1, Sections 8b and 9). |
| Acceptable Use Policy | Prohibited uses include use outside the Territory, military purposes, and placing machine-generated information in a public context without conspicuously identifying it as machine generated. | MEASURED (PACK.md §Primary source 1, Exhibit A). |
| Model-card front matter | The model card lists license "other," license_name "tencent-hunyuan-community," tag "region:us," and extra_gated_eu_disallowed: true. | MEASURED (PACK.md §Primary source 1, model card front matter). |
| Owner ruling | The owner has ruled the US-only licence scope acceptable: "US only is fine." The terms still must be documented before generated audio is kept. | MEASURED (PACK.md §Issue #211, item 1, owner ruling Nov 6 2026). |

## 2. FIT

Arithmetic from the pack's weight sizes: XL weights are 5.85 GB + 0.95 GB + 1.49 GB = 8.29 GB; XXL weights are 10.30 GB + 0.95 GB + 1.49 GB = 12.74 GB. Both variants need the synchformer and VAE files. MEASURED sizes (PACK.md §Primary source 2, weight files); DERIVED sums (same).

| Variant / setting | Vendor-stated VRAM | Arithmetic against 16 GB | Fit judgement |
|---|---|---|---|
| XXL default, normal | 20 GB | 16 − 20 = −4 GB | Does not fit; exceeds by 4 GB. MEASURED table + DERIVED arithmetic (PACK.md §Primary source 2; PC spec). |
| XXL default, offload | 12 GB | 16 − 12 = 4 GB headroom | Nominally fits with 4 GB headroom. MEASURED table + DERIVED arithmetic (same). |
| XL, normal | 16 GB | 16 − 16 = 0 GB headroom | Nominally fits exactly, with no headroom for ComfyUI/Windows overhead. MEASURED table + DERIVED arithmetic (same). |
| XL, offload | 8 GB | 16 − 8 = 8 GB headroom | Fits with the largest stated headroom. MEASURED table + DERIVED arithmetic (same). |

Recommended starting fit: XL with offload enabled, because it is the only variant that fits with substantial stated headroom; XL normal nominally fits at exactly 16 GB but leaves zero headroom. ASSUMED recommendation (basis: PACK.md §Primary source 2 VRAM table and PC spec). The VRAM figures are vendor-stated, not measured on Ryan's RTX 5080; actual Windows/ComfyUI overhead is not checked. MEASURED vendor table (PACK.md §Primary source 2); ASSUMED/Not checked actual fit (same).

The PC has 32 GB system RAM, but the pack gives no offload RAM requirement, so offload sufficiency on 32 GB is not verified. MEASURED PC RAM (PACK.md §The PC); Not checked offload RAM requirement (PACK.md §Primary source 2 gives no RAM figure).

## 3. RUN PLAN

Primary install route: if-ai/ComfyUI_HunyuanVideoFoley custom node in the existing ComfyUI portable v0.42.1. Reasons: the official README links this node (MEASURED, PACK.md §Primary source 3); the node supports CPU offloading and FP8 quantization (MEASURED, same); it auto-downloads models to ComfyUI/models/foley/ or accepts manual placement (MEASURED, same); and the PC already has ComfyUI portable v0.42.1 with embedded Python, while outside ComfyUI there is no working Python (MEASURED, PACK.md §The PC). The node version compatible with ComfyUI v0.42.1 is not given in the pack. Not checked.

Fallback route: phazei/ComfyUI-HunyuanVideo-Foley, the alternative node supporting different precision modes. MEASURED existence (PACK.md §Primary source 3). The repo's own infer.py route is a second fallback only after solving Python/CUDA: the README recommends CUDA 12.4 or 11.8 and Python 3.8+, and primary OS support is Linux, while this PC has no working Python outside ComfyUI. MEASURED (PACK.md §Primary source 2; PACK.md §The PC).

Starting per-sequence settings:

| Setting | Start value | Evidence tag and source |
|---|---|---|
| Variant | XL (hunyuanvideo_foley_xl.pth) | ASSUMED choice from fit arithmetic (PACK.md §Primary source 2; PC spec). |
| Offload | Enabled | ASSUMED choice from fit arithmetic; --enable_offload exists and XL offload is stated at 8 GB (PACK.md §Primary source 2). |
| Precision/config | bf16 per XL config | MEASURED (PACK.md §Primary source 2, config_xl.yaml). |
| Steps | 50 | MEASURED default in infer.py (PACK.md §Primary source 2). |
| Guidance | 4.5 | MEASURED default in infer.py (PACK.md §Primary source 2). |
| Output rate | 48 kHz | MEASURED (PACK.md §Primary source 2, VAE vae_128d_48k). |
| Audio length | Explicit 5 s per probe clip, not default video length | ASSUMED conservative limit; basis: no maximum duration is stated, and latent length scales at 50 audio frames/s, so memory grows with clip length. DERIVED memory-growth note (PACK.md §Primary source 2); ASSUMED 5 s choice (not specified in pack). |

Clip-length limit: 5 seconds per probe sequence as the starting limit. Reason: the pack states no maximum video duration; the chair's derived note says latent length scales at 50 audio frames per second, so longer clips increase memory; 5 s is a conservative probe limit that can be raised only after a smoke test. DERIVED (PACK.md §Primary source 2); ASSUMED 5 s limit (not in pack).

## 4. PROBE SHAPE

| Priority | Sequence from #211 | Length limit applied | Settings |
|---|---|---|---|
| 1 | Capital ship death | 5 s | XL, offload, 50 steps, guidance 4.5. ASSUMED settings from §3 (PACK.md §Issue #211 sequence list; PACK.md §Primary source 2 defaults). |
| 2 | Nemesis arrival | 5 s | XL, offload, 50 steps, guidance 4.5. ASSUMED settings from §3 (same sources). |
| 3 | Ordinary battle stretch as control | 5 s | XL, offload, 50 steps, guidance 4.5. ASSUMED settings from §3 (same sources). |

Agent-run estimate: one-time setup 2–3 agent runs (install node, model download/placement, smoke test); per-sequence unattended generation 3 runs (one per sequence); expected retries 2–3 runs for OOM/settings/quality; total roughly 7–9 agent runs. ASSUMED/DERIVED from §3 choices and pack's three-sequence probe (PACK.md §Issue #211; PACK.md §Primary source 2; PACK.md §Primary source 3). No human-hour estimates are given, per the job. MEASURED prohibition (PACK.md §The job, "No human-hour estimates (R99)").

Ryan listen rounds: 1 primary listen round over the three clips against the current recorded takes, with 1 possible tie-break/second round if the verdict is unclear. ASSUMED probe-shape estimate (basis: PACK.md §Issue #211, owner's ear in or alongside S15 listen pass; no round count is specified).

## 5. RISKS AND GAPS

The VRAM table is vendor-stated and was not measured on the RTX 5080; XL offload's 8 GB nominal figure may not equal actual Windows/ComfyUI usage. MEASURED vendor table (PACK.md §Primary source 2); Not checked actual VRAM (PACK.md §The PC).

The pack states no maximum video duration; the 5 s limit is a conservative assumption, not a vendor limit. MEASURED absence (PACK.md §Primary source 2); ASSUMED 5 s limit.

The ComfyUI node version compatible with ComfyUI portable v0.42.1 is not in the pack; verify before the probe. Not checked (PACK.md §Primary source 3 gives no node version; PACK.md §The PC gives ComfyUI v0.42.1).

The if-ai node's loader is an FP8 loader; the pack does not quantify FP8 quality or VRAM effect versus bf16 XL. MEASURED FP8-loader statement (PACK.md §Primary source 3); Not checked quality/VRAM effect.

The repo route requires Python 3.8+ and CUDA 12.4 or 11.8, and primary OS support is Linux; this PC has no working Python outside ComfyUI. MEASURED (PACK.md §Primary source 2; PACK.md §The PC). Do not treat the repo script as the primary route without fixing that.

The two ComfyUI nodes differ materially: if-ai supports CPU offloading/FP8 and auto-download; phazei supports different precision modes. MEASURED (PACK.md §Primary source 3). The synthesis should verify which node exposes XL plus offload cleanly on v0.42.1.

The pack does not state offload RAM requirements, so 32 GB system RAM sufficiency is unverified. MEASURED PC RAM (PACK.md §The PC); Not checked offload RAM requirement (PACK.md §Primary source 2).

Kept outputs must carry the licence documentation, and generated audio remains probe material; #210's intake pause holds. MEASURED (PACK.md §Issue #211 boundaries).

Not checked

- Actual VRAM use on Ryan's RTX 5080 under Windows/ComfyUI v0.42.1.
- Whether 32 GB system RAM is sufficient for XL offload.
- Exact if-ai or phazei node version compatible with ComfyUI v0.42.1.
- Whether the if-ai node's FP8 path preserves quality versus bf16 XL.
- Whether the repo's infer.py can run under ComfyUI portable's embedded Python.
- Disk space and model-download completeness for the required XL, synchformer and VAE files.
- Actual maximum stable clip length on this PC; only the 5 s probe limit is assumed.
- Legal treatment of "played in" the EU/UK/South Korea; the pack gives licence text, not legal advice.
