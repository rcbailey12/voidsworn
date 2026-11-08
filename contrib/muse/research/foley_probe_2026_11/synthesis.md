# HunyuanVideo-Foley: licence terms and run plan (issue #258, #211 steps 1 and 2)

Chair: Rey. Legs: blind Rey (written first, pack only), DeepSeek, Qwen, all in legs/ beside this file. Argon seat empty (blocked since Nov 5). Date: Nov 8, 2026. Primary sources: the LICENSE file and model card at huggingface.co/tencent/HunyuanVideo-Foley, the GitHub README and infer.py at github.com/Tencent-Hunyuan/HunyuanVideo-Foley, config_xl.yaml, and the if-ai ComfyUI node README. Every claim below names its source and is tagged MEASURED (stated in a primary source), DERIVED (follows from measured facts) or ASSUMED (believed, not verified). Vendor figures are vendor-stated and unmeasured on the target PC until the probe's smoke test.

Verdict in one line: the licence permits this probe and a US-only commercial future for its outputs, with region discipline as the standing cost; the XL variant with offload is the configuration that fits the 16 GB card; the probe runs through the if-ai ComfyUI node in the already installed portable build. Nothing here unpauses #210's audio intake pause; all generated audio stays probe material, and any kept outputs carry this licence record with them (issue #211 boundaries). MEASURED (issue #211).

## 1. Licence: the operative terms (Tencent Hunyuan Community License Agreement)

Geography. The Territory is "the worldwide territory, excluding the territory of the European Union, United Kingdom and South Korea" (licence, Definitions). MEASURED. The United States is inside the Territory. DERIVED. The exclusion reaches outputs, not just the model: "You must not use, reproduce, modify, distribute, or display the Tencent Hunyuan Works, Output or results of the Tencent Hunyuan Works outside the Territory. Any such use outside the Territory is unlicensed and unauthorized" (Section 5c). MEASURED. The model card's front matter matches: licence "other", name "tencent-hunyuan-community", tag "region:us", extra_gated_eu_disallowed: true. MEASURED.

What that means for this project. The owner already ruled the US-only scope acceptable (Nov 6, 2026: "US only is fine"). MEASURED (issue #211). If a future release of the game carries Foley-generated audio, the release inherits the Territory rule: storefront regions, review keys, demo builds and public clips need the same EU, UK and South Korea exclusion as the shipped game, or the audio must be replaced for those regions. DERIVED (Sections 3, 5c). All three legs read this the same way.

Outputs and ownership. "Tencent claims no rights in Outputs You generate. You and Your users are solely responsible for Outputs and their subsequent uses" (Section 6d). MEASURED. The grant is "a non-exclusive, non-transferable and royalty-free limited license" for the Territory (Section 2). MEASURED. No per-sale royalty or revenue share appears in the licence. DERIVED.

Chair correction to one leg claim. The Qwen leg derived that "the only licence conditions attach to the model weights and derivatives of the model, not to the audio output". That overreaches: Section 5c names Output expressly, and Section 5b restricts outputs too. The chair does not adopt that sentence; the Territory and no-training rules bind outputs as written. MEASURED (Sections 5b, 5c, against legs/qwen.md section 1.2).

Commercial terms and the user-count clause. "If, on the Tencent Hunyuan version release date, the monthly active users of all products or services made available by or for Licensee is greater than 100 million monthly active users in the preceding calendar month, You must request a license from Tencent" and the rights may not be exercised until Tencent grants them (Section 4). MEASURED. For a solo developer's game this trigger is remote, but it is a condition of the grant, so it stays in this record. DERIVED.

Attribution and notice duties. Section 3 conditions distribution of the works or products using them on: (a) every recipient gets a copy of the Agreement; (b) modified files carry prominent change notices; (c) a blog post or public statement and marking products "Powered by Tencent Hunyuan" are "encouraged", not required; (d) distributions other than through a Hosted Service include a NOTICE text file with the Tencent Hunyuan licence and copyright statement. MEASURED. Whether those duties attach to a game binary that contains only generated audio is a grey zone the text does not settle (the Qwen leg's natural reading is no, because Section 6d disclaims rights in outputs; untested). ASSUMED. The project's own discipline removes the practical risk: kept outputs carry the licence documentation with them regardless (issue #211 boundaries). MEASURED.

No training on outputs. "You must not use the Tencent Hunyuan Works or any Output or results of the Tencent Hunyuan Works to improve any other AI model (other than Tencent Hunyuan or Model Derivatives thereof)" (Section 5b). MEASURED. Probe takes, rejected takes and kept Foley must never feed another model's training or fine-tuning. DERIVED.

Acceptable Use Policy (Exhibit A, last modified Nov 5, 2024). A 19-plus item prohibited list, including use outside the Territory and military purposes. MEASURED. One item matters for later publicity: machine-generated information placed in a public context must be conspicuously identified as machine generated (Exhibit A item 12). MEASURED. Practical shape: a trailer, store video or devlog that features generated Foley should label it as machine generated. DERIVED. Whether in-game audio during private play counts as a public context is unresolved. ASSUMED.

Termination and law. On breach Tencent may terminate, and the licensee must "delete and cease use" of the works (Section 8b). MEASURED. Governing law and courts are Hong Kong SAR (Section 9). MEASURED.

## 2. Fit on the RTX 5080 (16 GB VRAM, 32 GB RAM, Windows 10)

Vendor VRAM table (GitHub README, model specifications): XXL (default) checkpoint needs 20 GB normal, 12 GB with offload; XL needs 16 GB normal, 8 GB with offload. MEASURED. Weight files (Hugging Face API): hunyuanvideo_foley.pth 10.30 GB, hunyuanvideo_foley_xl.pth 5.85 GB, synchformer_state_dict.pth 0.95 GB, vae_128d_48k.pth 1.49 GB; both variants also need the synchformer and VAE. MEASURED. XL set on disk: 5.85 + 0.95 + 1.49 = 8.29 GB. XXL set: 12.74 GB. DERIVED.

| Variant and setting | Vendor VRAM | Against 16 GB | Verdict |
|---|---|---|---|
| XXL, normal | 20 GB | 4 GB over | Does not fit. DERIVED |
| XXL, offload | 12 GB | 4 GB headroom | Fits; not the starting point. DERIVED |
| XL, normal | 16 GB | 0 GB headroom | Paper fit only; any uncounted overhead (display, driver, ComfyUI) turns it into an out-of-memory failure. DERIVED |
| XL, offload | 8 GB | 8 GB headroom | The probe configuration. DERIVED |

All three legs agree on this table and the verdict. The XL config runs bf16 with an audio frame rate of 50 latents per second, and output is 48 kHz. MEASURED (config_xl.yaml; model card). No offload RAM requirement is stated in the sources, so 32 GB system RAM sufficiency is expected but unproven. ASSUMED.

## 3. Run plan

Primary route: the if-ai/ComfyUI_HunyuanVideoFoley custom node inside the owner's existing ComfyUI portable v0.42.1 (Downloads\ComfyUI_windows_portable). All three legs chose this route. Reasons: ComfyUI is already installed and carries its own embedded Python, while outside ComfyUI the PC has no working Python (python.exe is the Store placeholder); the official Tencent README itself links this node under its ComfyUI Integration section; the node supports CPU offloading and FP8 quantization, auto-downloads models to ComfyUI/models/foley/ on first run (or accepts manual placement), and loads the model once so the generator can run repeatedly without reloading. MEASURED (PC record; GitHub README; if-ai node README). Versions named: ComfyUI portable v0.42.1 (installed), CUDA 12.4 or 11.8 recommended by the vendor, models as file-named above. The pack found no version number or commit for the node itself; the setup run pins whatever it installs in its report. MEASURED (absence).

Fallback order. Fallback 1: phazei/ComfyUI-HunyuanVideo-Foley, the alternative node with different precision modes, still inside ComfyUI (DeepSeek and Qwen ordering). Fallback 2: the repo's own infer.py with --model_size xl and --enable_offload, which first needs a Python environment built on this Windows PC (vendor's primary OS support is Linux, Conda recommended, Python 3.8+ required). The blind leg named infer.py as its fallback to stay closest to the vendor's reference implementation; the chair ranks it second because standing up that environment is the heaviest step on this PC and both ComfyUI nodes avoid it. MEASURED (sources as above); ordering DERIVED.

Starting settings for every sequence: XL checkpoint, offload enabled, 50 inference steps, guidance scale 4.5, generated audio length matched to the trimmed clip, 48 kHz output. Steps and guidance are infer.py's defaults, the least invented baseline in the sources. MEASURED (infer.py); carried into the node route as DERIVED. Two cautions ride with the route: the if-ai loader is an FP8 loader while the XL config is bf16, so the node path may sound different from the repo path at the same settings, and a bad probe result on the node would not by itself convict the model (blind leg; FP8 quality delta unmeasured, ASSUMED). The setup run must also confirm the node actually exposes the XL checkpoint choice and step/guidance controls before the probe trusts it. DERIVED (blind leg Not checked).

Clip length. No maximum video duration is stated in the README or infer.py; by default the generated audio matches the input video's length (infer.py --audio_length). MEASURED. Latent length scales with duration at 50 audio frames per second, so memory grows with clip length. DERIVED. The legs proposed caps of 5 seconds (DeepSeek), 8 and 6 seconds (Qwen) and 20 seconds (blind Rey). Chair ruling for the probe: a smoke test at about 3 seconds first to observe real VRAM on this stack, then probe generations capped at 10 seconds per sequence (500 audio latents), with the capital death allowed toward 15 seconds only if the smoke test and the first generation leave comfortable headroom. Five seconds truncates the very arc the listen pass has to judge; twenty seconds (1,000 latents) is unproven memory territory. This cap is a probe discipline, not a vendor limit. DERIVED with ASSUMED elements.

## 4. Probe shape (issue #211 step 2, with the cap applied)

1. (a) A capital ship death, first priority, trimmed to the decisive window, cap 10 seconds (15 only on proven headroom).
2. (b) A Nemesis arrival, trimmed tight to the arrival beat, cap 10 seconds.
3. (c) One ordinary battle stretch as the control, comparable in length to (a), cap 10 seconds.

Sequences named in issue #211 step 2. MEASURED. Caps per section 3. DERIVED.

Estimate in agent terms (R99; no human-hour estimates). One-time setup: 2 agent runs (install and configure the node and download the 8.29 GB XL set; then the smoke test). First-pass generation: 3 unattended runs, one per sequence (the node's load-once design means they can queue in one ComfyUI session). Retries: up to 3 runs, one per sequence, for a bad take, a failed run or one settings change. Total: 8 agent runs at the planned maximum, 5 to 7 expected. DERIVED from the three legs' convergent estimates (5 to 7, 7 to 9, 8 maximum). Ryan listen rounds: 1 planned round covering all three takes against the current recorded takes, inside or alongside the S15 listen pass, with a second round budgeted for retried or borderline takes: 1 to 2 rounds. DERIVED (issue #211 step 3; legs).

## 5. Pre-probe verification checklist (run during setup, before sequence generation)

- ComfyUI portable v0.42.1 launches and sees the RTX 5080 and its 16 GB. ASSUMED until run.
- The if-ai node installs cleanly into the portable build and loads; record its installed version or commit. ASSUMED until run.
- Embedded Python and CUDA versions read from the machine and compared with the vendor's CUDA 12.4 or 11.8 recommendation. MEASURED (recommendation); machine values ASSUMED until run.
- Downloaded files match the expected set and sizes: hunyuanvideo_foley_xl.pth 5.85 GB, synchformer_state_dict.pth 0.95 GB, vae_128d_48k.pth 1.49 GB (8.29 GB total). MEASURED (expected sizes).
- Offload is confirmed on, the XL checkpoint is the one selected, and step/guidance controls are exposed. ASSUMED until run.
- Smoke generation at about 3 seconds: record observed peak VRAM and confirm the output file is 48 kHz. ASSUMED until run.

## Not checked

- Actual VRAM, speed and stability of any variant on this PC, in any route (no generation was run for this research).
- The if-ai and phazei nodes beyond their READMEs: current versions, Windows behaviour under ComfyUI v0.42.1, and whether their controls match the infer.py baseline.
- FP8 versus bf16 audible quality, and XL versus XXL audible quality.
- Any maximum stable clip length on this stack; the 10 second cap is a planning choice.
- The full Acceptable Use Policy text beyond the pack's summary, and any Tencent FAQ or guidance on storefront distribution of outputs.
- Legal advice: section 1 is a plain-language restatement of the licence text, not a lawyer's opinion; the two grey zones (distribution duties on output-only binaries, the public-context identification scope) are recorded as open.
- The current recorded takes for the three moments and the S15 listen pass itself, which belong to #211 steps 3 and 4, after this research.
