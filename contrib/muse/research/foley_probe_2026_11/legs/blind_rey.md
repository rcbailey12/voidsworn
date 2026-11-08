# Blind Rey leg: issue #258, HunyuanVideo-Foley licence terms and run plan

## 1. LICENCE

- The licence is the Tencent Hunyuan Community License Agreement, and the model card names it "tencent-hunyuan-community" with license "other" (Primary source 1: licence extracts and model card front matter). MEASURED
- Geography is the controlling limit: the "Territory" is the "worldwide territory, excluding the territory of the European Union, United Kingdom and South Korea" (Primary source 1: licence definition). MEASURED
- The United States is inside the Territory because the definition excludes only the European Union, the United Kingdom and South Korea (Primary source 1: licence definition). DERIVED
- The owner has already ruled that the US-only scope is acceptable, and issue #211 still requires the terms to be documented before any generated audio is kept (Issue #211, step 1). MEASURED
- The core grant is a "non-exclusive, non-transferable and royalty-free limited license" to use, reproduce, distribute, create derivative works of and modify the Materials, only under the Agreement and the Acceptable Use Policy (Primary source 1: licence Section 2). MEASURED
- In plain language, Ryan may use the model and make things with it inside the Territory, but the permission is conditional and cannot be transferred as a standalone right (Primary source 1: licence Section 2). DERIVED
- Outputs are treated differently from the model itself: "Tencent claims no rights in Outputs You generate" (Primary source 1: licence Section 6d). MEASURED
- The same section leaves Ryan and his users "solely responsible for Outputs and their subsequent uses" (Primary source 1: licence Section 6d). MEASURED
- The pack gives no clause granting a separate worldwide right in outputs, and Section 5c expressly restricts use, reproduction, modification, distribution or display of the Works, Output or results outside the Territory (Primary source 1: licence Section 5c). MEASURED
- The safe reading for this project is therefore that generated Foley may be used in the game only where the game and the audio stay inside the Territory, unless Tencent later grants wider permission (Primary source 1: licence Sections 2, 5c and 6d). DERIVED
- Commercial use is not barred by a general non-commercial clause in the extracts supplied, and the licence is royalty-free inside its terms (Primary source 1: licence Section 2). MEASURED
- A large-scale commercial trigger does exist: if the licensee's products or services have "greater than 100 million monthly active users" in the preceding calendar month on the relevant release-date test, Ryan must request a licence from Tencent and is not authorised under this Agreement unless Tencent expressly grants those rights (Primary source 1: licence Section 4). MEASURED
- For a solo developer selling a niche game, the 100 million monthly active user trigger is remote on the facts in the pack, which name no existing product anywhere near that scale (Primary source 1: licence Section 4; The job). DERIVED
- The trigger should still be written into the kept licence note because it is a condition of the grant rather than a mere reporting request (Primary source 1: licence Section 4). DERIVED
- Distribution inside the Territory carries paperwork duties when distributing the Works or products using them: every recipient must get a copy of the Agreement, modified files must carry prominent change notices, and distributions other than through a Hosted Service must include a NOTICE text file with the Tencent Hunyuan copyright and licence statement (Primary source 1: licence Section 3). MEASURED
- The blog post or public statement and the "Powered by Tencent Hunyuan" mark are "encouraged", not required, in the extract supplied (Primary source 1: licence Section 3). MEASURED
- If Ryan ships only finished audio in a game and does not ship model weights or modified model files, the practical duties still to carry with the kept audio are the licence copy and NOTICE discipline described by issue #211, which says any kept outputs carry the licence documentation with them (Primary source 1: licence Section 3; Issue #211, boundaries). DERIVED
- The no-training clause is broad: Ryan must not use the Works, any Output or any results "to improve any other AI model", except Tencent Hunyuan itself or Model Derivatives of it (Primary source 1: licence Section 5b). MEASURED
- That means probe audio, rejected takes and later kept Foley must not be fed into training, fine-tuning or improving another audio or general AI model (Primary source 1: licence Section 5b). DERIVED
- The outside-Territory clause is strict: "Any such use outside the Territory is unlicensed and unauthorized" (Primary source 1: licence Section 5c). MEASURED
- If the game is distributed or played in the European Union, the United Kingdom or South Korea with HunyuanVideo-Foley output in it, the pack's extracts point to unlicensed use rather than a paperwork defect (Primary source 1: licence Section 5c). DERIVED
- A US-only release configuration is therefore not just a preference but the compliance shape the owner already accepted: storefront regions, review keys, demo builds and public clips need the same Territory discipline as the shipped game (Primary source 1: licence Sections 3 and 5c; Issue #211, step 1). DERIVED
- The Acceptable Use Policy adds prohibited uses beyond geography, including military purposes, and it requires machine-generated information placed in a public context to be conspicuously identified as machine generated (Primary source 1: Exhibit A summary). MEASURED
- A public trailer, store page video or devlog using probe or kept Foley should therefore identify the generated audio as machine generated where the audio itself is presented in a public context (Primary source 1: Exhibit A summary). DERIVED
- The probe itself is not public distribution on the facts given, because issue #211 frames it as local generation judged by the owner's ear alongside the S15 listen pass (Issue #211, steps 2 and 3). MEASURED
- On breach, Tencent may terminate the licence, and the licensee must then delete and cease use of the Works (Primary source 1: licence Section 8b). MEASURED
- The practical consequence of termination would reach kept Foley and any product using it, because the grant is the basis for the use and distribution rights described in Sections 2 and 3 (Primary source 1: licence Sections 2, 3 and 8b). DERIVED
- The Agreement is governed by Hong Kong SAR law and courts (Primary source 1: licence Section 9). MEASURED
- For a solo US developer, the licence is workable for a Territory-only game: outputs are not claimed by Tencent, ordinary commercial scale does not trigger the special licence request, and the main burdens are region control, licence and NOTICE paperwork, no training reuse, and public disclosure under the Acceptable Use Policy (Primary source 1: licence Sections 2 to 6 and Exhibit A). DERIVED

## 2. FIT

- The PC has an RTX 5080 with 16 GB VRAM and 32 GB system RAM, runs Windows 10, and already has ComfyUI portable v0.42.1 installed (The PC). MEASURED
- The vendor table gives two variants: XXL, the default, needs 20 GB VRAM in normal mode and 12 GB with offload; XL needs 16 GB VRAM in normal mode and 8 GB with offload (Primary source 2: model specifications table). MEASURED
- XXL normal mode does not fit: 20 GB required minus 16 GB available leaves a 4 GB shortfall (Primary source 2: model specifications table; The PC). DERIVED
- XXL with offload fits by the vendor table: 16 GB available minus 12 GB required leaves 4 GB of stated headroom (Primary source 2: model specifications table; The PC). DERIVED
- XL normal mode is a paper fit only: 16 GB required against 16 GB available leaves 0 GB of stated headroom before any display, driver or application overhead is considered (Primary source 2: model specifications table; The PC). DERIVED
- XL with offload is the comfortable fit: 16 GB available minus 8 GB required leaves 8 GB of stated headroom (Primary source 2: model specifications table; The PC). DERIVED
- The weight files tell the same story on disk: the XXL set is 10.30 GB for hunyuanvideo_foley.pth plus 0.95 GB for synchformer_state_dict.pth plus 1.49 GB for vae_128d_48k.pth, which totals 12.74 GB (Primary source 2: weight files). DERIVED
- The XL set is 5.85 GB for hunyuanvideo_foley_xl.pth plus the same 0.95 GB synchformer file plus the same 1.49 GB VAE file, which totals 8.29 GB (Primary source 2: weight files). DERIVED
- Both variants need the synchformer and VAE files in addition to the main checkpoint (Primary source 2: weight files). MEASURED
- If all unique files for both variants were downloaded together, the disk total would be 10.30 plus 5.85 plus 0.95 plus 1.49, which is 18.59 GB, counting the shared synchformer and VAE once (Primary source 2: weight files). DERIVED
- Disk size is not the same as VRAM need, so the fit verdict rests on the vendor VRAM table rather than on the checkpoint file sizes (Primary source 2: model specifications table and weight files). DERIVED
- XL runs in bf16 in its supplied config, and its audio frame rate is 50 audio latents per second (Primary source 2: XL config). MEASURED
- The model output is 48 kHz audio, matching the vae_128d_48k file name and the model card statement in the pack (Primary source 2: output note). MEASURED
- Fit verdict: use XL with offload as the probe configuration; treat XXL with offload as possible but not the starting point, XXL normal as impossible on this card, and XL normal as unsafe because it leaves no stated headroom (Primary source 2: model specifications table; The PC). DERIVED
- The 32 GB system RAM figure is relevant to offload in ordinary practice, but the pack states no minimum RAM for offload, so adequate RAM headroom for the offload path is not proven by the pack (The PC; Primary source 2: system requirements). ASSUMED

## 3. RUN PLAN

- Primary route: install the if-ai/ComfyUI_HunyuanVideoFoley custom node into the owner's existing ComfyUI portable v0.42.1 and run the XL model there (The PC; Primary source 3: ComfyUI routes). DERIVED
- This route fits the PC because ComfyUI portable is already installed and carries its own embedded Python, while outside ComfyUI the PC has no working Python and python.exe is the Microsoft Store placeholder (The PC). MEASURED
- The if-ai node is also the route the official README links under its ComfyUI Integration section, alongside the phazei alternative (Primary source 3: ComfyUI routes). MEASURED
- The if-ai node's stated features match the fit problem: it supports CPU offloading and FP8 quantization through its FP8 model loader, and its pipeline is Model Loader, Dependencies Loader, Torch Compile and Generator (Advanced) (Primary source 3: if-ai node README summary). MEASURED
- Its models auto-download to ComfyUI/models/foley/ on first run or can be placed there manually from the Hugging Face repo (Primary source 3: if-ai node README summary). MEASURED
- The node's load-once behaviour matters for a three-sequence probe: the loader loads the model once and the generator can run repeatedly without reloading, "saving significant time and VRAM" (Primary source 3: if-ai node README summary). MEASURED
- The pack gives no version number or commit for either ComfyUI node, so v0.42.1 is the only ComfyUI-side version that can be named from the pack (The PC; Primary source 3: ComfyUI routes). MEASURED
- The model-side requirements to check in the installed environment are CUDA 12.4 or 11.8, which the vendor lists as recommended (Primary source 2: system requirements). MEASURED
- Starting settings for every probe sequence: XL checkpoint hunyuanvideo_foley_xl.pth, offload enabled, 50 inference steps, guidance scale 4.5, generated audio length set to the trimmed video length, and 48 kHz output expected (Primary source 2: weight files, XL config, infer.py defaults and output note). DERIVED
- The 50 steps and 4.5 guidance are the repo script defaults, carried into the ComfyUI start settings as the least invented baseline available in the pack (Primary source 2: infer.py defaults). DERIVED
- Where the if-ai generator exposes the FP8 loader rather than a bf16 load, the first probe run uses that loader because it is the node's stated path and because the VRAM case for XL with offload is already the safe one (Primary source 3: if-ai node README summary; Primary source 2: model specifications table). DERIVED
- Impose a maximum clip length of 20 seconds on every probe sequence, with shorter target trims where the event allows it (Primary source 2: infer.py audio length note and chair DERIVED note). DERIVED
- The reason for a hard cap is that neither the README nor infer.py states a maximum video duration, while latent length scales with duration at 50 audio frames per second and memory therefore grows with clip length (Primary source 2: maximum duration note and chair DERIVED note). MEASURED
- At the cap, a 20 second clip means 1,000 audio latents at 50 per second; a 15 second clip means 750; a 12 second clip means 600 (Primary source 2: XL config). DERIVED
- The cap also keeps each generated take short enough for a clean A/B listen against the current recorded takes in the S15 pass (Issue #211, step 3). DERIVED
- Fallback route: the repo's own infer.py with the XL model and the offload flag, using the README form python3 infer.py with --model_size xl and --enable_offload, if the ComfyUI node fails or its FP8 path is judged to compromise the probe (Primary source 2: infer.py and README examples; Primary source 3: ComfyUI routes). DERIVED
- The fallback is heavier to stand up on this PC because the vendor's primary OS support is Linux, Conda is recommended for environment management, Python 3.8+ is required, and this Windows PC has no working Python outside ComfyUI (Primary source 2: system requirements; The PC). MEASURED
- The repo also ships a Gradio app with MODEL_SIZE=xl and ENABLE_OFFLOAD=true options, but the pack gives it as an example surface rather than an unattended job route (Primary source 2: infer.py and Gradio note). MEASURED
- Before generation, the setup run should confirm the XL checkpoint, synchformer and VAE are the files present, confirm offload is actually enabled in the chosen route, and run the shortest sequence first as a smoke test (Primary source 2: weight files and system requirements; Primary source 3: if-ai node README summary). DERIVED

## 4. PROBE SHAPE

- Sequence (a), first priority: Foley for a capital ship death, trimmed to the decisive window from onset to aftermath, maximum 20 seconds (Issue #211, step 2; Leg prompt section 3 cap). DERIVED
- Sequence (b): Foley for a Nemesis arrival, trimmed tight to the arrival beat, target 12 to 15 seconds and maximum 20 seconds (Issue #211, step 2; Primary source 2: XL config). DERIVED
- Sequence (c), the control: Foley for one ordinary battle stretch, maximum 20 seconds, chosen to be comparable in length to the capital ship death take (Issue #211, step 2). DERIVED
- All three are probe material only, the #210 intake pause still holds, and any kept outputs carry the licence documentation with them (Issue #211, boundaries; The job). MEASURED
- Judgement stays with Ryan's ear, in or alongside the S15 listen pass, against the current recorded takes for the same moments (Issue #211, step 3). MEASURED
- One-time setup estimate: 2 agent runs, one to install and configure the ComfyUI node and download the XL file set, and one smoke-test run on the shortest clip to prove the offload path before the real sequences (Primary source 3: if-ai node README summary; Primary source 2: weight files). DERIVED
- First-pass generation estimate: 3 unattended generation runs, one per sequence, at the starting settings in section 3 (Issue #211, step 2; Primary source 2: infer.py defaults). DERIVED
- Retry budget: 1 retry run per sequence for a bad take, a failed run, a trim change or a single settings change, which is up to 3 further runs (Issue #211, step 2). ASSUMED
- Total probe estimate: 8 agent runs at the planned maximum, made of 2 setup runs, 3 first-pass generation runs and up to 3 retry runs; a clean first pass would finish in 5 runs (Issue #211; Primary source 2; Primary source 3). DERIVED
- Ryan listen rounds estimate: 2 rounds, the first covering all three first-pass takes against the current recorded takes, and the second covering only the retried or final candidate takes (Issue #211, step 3). DERIVED
- If all three first-pass takes are acceptable or clearly rejected in round 1, the second listen round can be dropped, but the plan should not promise that in advance (Issue #211, steps 3 and 4). ASSUMED
- The report back after the probe still owes a per-sequence quality verdict, the hardware cost observed on this PC, and a recommendation to adopt for cinematics and death sequences only, extend further, or drop (Issue #211, step 4). MEASURED

## 5. RISKS AND GAPS

- Every VRAM number in the fit case is vendor-stated and unmeasured on Ryan's RTX 5080, and the pack does not state the clip length, resolution or settings basis behind the table's 8, 12, 16 and 20 GB figures (Primary source 2: model specifications table). MEASURED
- The vendor table and the file sizes measure different things, so a synthesis that argued fit from the 8.29 GB XL file total alone would overstate the case; the table is the safer source and it still needs a PC smoke test (Primary source 2: model specifications table and weight files). DERIVED
- XL normal mode is the trap in the table: it exactly equals the card's 16 GB, so any overhead the table does not count turns a stated fit into an out-of-memory failure (Primary source 2: model specifications table; The PC). DERIVED
- No maximum video duration is stated by the README or infer.py, so the 20 second cap is a probe discipline chosen for this job, not a vendor limit (Primary source 2: maximum duration note). MEASURED
- The two ComfyUI routes differ materially on precision: the if-ai node is built around an FP8 loader with CPU offloading, while the phazei node advertises different precision modes and the XL config itself is bf16 (Primary source 3: ComfyUI routes; Primary source 2: XL config). MEASURED
- FP8 versus bf16 may change audio quality, and the pack contains no listening comparison, so a bad probe result on the if-ai route would not by itself prove the model is bad (Primary source 3: if-ai node README summary; Primary source 2: XL config). DERIVED
- The routes also differ in workflow: the if-ai node auto-downloads models and supports repeated generation after one load, while the repo script is a per-invocation command line route with defaults stated in infer.py (Primary source 3: if-ai node README summary; Primary source 2: infer.py). MEASURED
- Windows is a live risk for the fallback route because the vendor lists Linux as the primary supported OS, while the target machine is Windows 10 (Primary source 2: system requirements; The PC). MEASURED
- Windows compatibility of the specific ComfyUI nodes with portable v0.42.1 is not stated in the pack, even though the existing ComfyUI install makes the node route the natural first attempt (The PC; Primary source 3: ComfyUI routes). ASSUMED
- The PC's installed CUDA version and driver are not in the pack, so the recommended CUDA 12.4 or 11.8 check remains open until the setup run reads the machine (Primary source 2: system requirements; The PC). MEASURED
- Generation speed is nowhere stated in the pack, so no claim is made here about how long a 50 step run takes on this card for any clip length (Primary source 2: infer.py defaults). MEASURED
- Offload moves pressure somewhere the pack does not quantify: the pack gives 32 GB system RAM but no offload RAM requirement and no offload speed cost (The PC; Primary source 2: system requirements). MEASURED
- Licence risk is operational rather than theoretical: a Territory-only licence fails in practice if a storefront, demo, review build or public clip quietly reaches the European Union, the United Kingdom or South Korea (Primary source 1: licence Sections 3, 5c and Exhibit A). DERIVED
- The distribution duties need a human check at ship time because the extracts tie the copy, change-notice and NOTICE duties to distributing the Works or products using them, and the pack does not map each duty onto a finished game build file by file (Primary source 1: licence Section 3). MEASURED
- The Acceptable Use Policy in the pack is a summary of a 19-plus item list, so project uses beyond the items named here cannot be cleared from this pack alone (Primary source 1: Exhibit A summary). MEASURED
- Before the probe runs, the synthesis should verify on the PC: the CUDA version, that the node loads under ComfyUI portable v0.42.1, that the downloaded files are the XL checkpoint plus synchformer and VAE, that offload is on, the actual VRAM observed on the smoke clip, and that the output file is 48 kHz (The PC; Primary source 2; Primary source 3). DERIVED

## Not checked

- The full licence text beyond the operative extracts in the pack, including any definitions or sections not quoted here.
- The full Acceptable Use Policy list beyond the summary items named in the pack.
- Any Tencent FAQ, issue thread, forum post or third-party benchmark for HunyuanVideo-Foley.
- The live Hugging Face repo and GitHub repo as they stand today, including any licence or README changes after the pack was assembled.
- The if-ai and phazei node repositories beyond the README points summarised in the pack, including their current versions, commits and Windows behaviour.
- The target PC itself: no CUDA version, driver, VRAM reading, download, install or generation was performed for this leg.
- Whether the if-ai generator exposes step and guidance controls equivalent to the infer.py defaults used as the baseline here.
- Audio quality of either variant, of FP8 versus bf16, and of offload versus normal mode.
- Legal advice: the licence reading above is a plain language restatement from the pack extracts, not a lawyer's opinion.
- The current recorded takes for the three moments, and the S15 listen pass material, which belong to the judgement step rather than this research leg.
