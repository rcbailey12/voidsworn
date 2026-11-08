# COUNCIL.md: how the cross-model council runs (Muse, for the board)

Filed under issue #257 (#216 ask 4), Nov 8, 2026. Owner: Rey. This file holds council method only: gates, traps, screening, pack anatomy. It is not a second rulings record; FINDINGS.md stays the single record of what was decided, and LOOP.md stays the record of seats and queue. Project memory only: nothing from Ryan's personal memory belongs in this repo (boundary from #216). External models meet this file through evidence packs, never by live read.

Tag key: MEASURED means observed in a run or a primary source, with the date. DERIVED means concluded from measured facts. ASSUMED means believed but not yet verified; treat as a lead.

## Seats (as of Nov 8, 2026)

- Opus owns the board, codes, reviews and merges. Worker threads never merge their own PRs. MEASURED (LOOP.md seats; R119, R132).
- Rey chairs council jobs and always writes a blind leg first. MEASURED (R89; every muse job since Nov 3).
- DeepSeek and Qwen are the writer legs. MEASURED (issue blocks since Nov 2).
- The Argon seat is empty as a reviewer: the Google AI Pro subscription lapsed Nov 5, 2026 and Gemini 4 Argon can no longer be selected. Flash serves that seat for ideation only. MEASURED (Nov 5 lapse; Ryan's rescope ruling Nov 6).
- Grok sits in ideation only (fifth seat, added Nov 7). MEASURED (Ryan's ruling, Nov 7).
- ChatGPT is the checker seat Ryan already pays for; down until its reset about Nov 10, 2026. While it is down, Rey runs the outside check on Opus-coded PRs (issue #256, R132). MEASURED (LOOP.md; R132).
- Codex is down until Ryan says; it is not a council leg. MEASURED (LOOP.md seats).

## Model gates (absolute; a gated leg runs only on the named model, no substitution)

- DeepSeek: DeepThink ON, verified visually (the button shows pale blue when on), and Search OFF for writing and review jobs. Toggling one control can flip the other; re-verify both immediately before sending. MEASURED (gate amended Nov 5: Expert mode no longer exists in the DeepSeek web UI; DeepThink-only approved by Ryan).
- Qwen: the model selector shows Qwen3.8-Max before the prompt is submitted, and the chat header still shows Qwen3.8-Max after generation. Those two checks are the strongest proof the UI offers; there is no per-response model badge. MEASURED (Oct 25; re-verified on every Qwen leg since).
- Argon (Gemini): no leg can run; the picker falls back to Flash with no Thinking option. Do not substitute Flash and call it an Argon leg. MEASURED (Nov 6, in-product notice).
- Flash (ideation seat): run on Gemini 3.8 Flash; the prompt bar reads "Flash" before and after. Its output is ideas and challenges only, never evidence. MEASURED (Nov 6 rescope ruling).
- Grok: no gate exists. The chat runs an unnamed Fast model on the free tier. Treat every claim as a lead. MEASURED (Nov 7).
- Blind Rey: the leg is written from the pack alone, before the chair reads any other leg, whatever the issue block's model list says. MEASURED (R89; Ryan, Nov 3).

## Per-model trap list (dated; add a line when a new trap is measured)

DeepSeek:
- Invented a full Unreal and Nanite pipeline on the Tripo vet; screened out as an evidence source for that job. MEASURED (Nov 5).
- Its quotations are not evidence; use it for ideation and code, verify every quote against the source. DERIVED (Nov 5 screening; reaffirmed in later packs).
- Toggle hazard: switching DeepThink can change the Search state and the reverse. MEASURED (multiple runs, Nov 5 to 8).
- On audit work it will answer only from the text it can actually see and says so; if a pack lacks the full texts, its leg comes back nearly empty rather than padded. That honesty is useful signal about the pack, not a model failure. MEASURED (Nov 8, issue #257 first run).

Qwen:
- Fidelity strength: clean on the Tripo vet and genuinely good on issue #201 when DeepSeek and Argon were not. DERIVED (Nov 5 to 6 legs).
- Derailment risk: derailed in full on issue #200. Screening is per job, not per model. MEASURED (Nov 5).
- Truncation risk on long replies: legs can arrive cut. Recovery is to re-request the reply from the still-open chat window and re-confirm the header gate. MEASURED (Nov 6 effects audit; Nov 8 issue #48, recovered verbatim).
- It may generate two parallel responses and ask "Which response do you prefer?" The runner never chooses; both responses are returned labeled. MEASURED (Nov 8, issue #257 second run; both responses used).
- The saved browser password for chat.qwen.ai is stale; Google sign-in is the working route. MEASURED (Nov 6).

Argon and Flash:
- Argon fabricated quotations repeatedly across October and November legs; anything it cites must be cut unless the pack source backs it. MEASURED (multiple legs; Argon scope narrowed Nov 5 to briefs and sources only).
- Flash invents plausible detail: on issue #48 it introduced "wooden frames" that exist nowhere in the pack and misattributed a furling claim to the pack. Same discipline as Argon: leads, never evidence. MEASURED (Nov 8).

Grok:
- Sign-in is per browser profile; a sign-in in one window does not carry to another. MEASURED (Nov 8).
- The file upload control may not open a usable picker; paste the pack text inline from the start. MEASURED (Nov 7 to 8).
- Its best contribution so far is a metric nobody else proposed (edge-loop continuity, carried into the next #209 pack). Ideation value is real; verification value is nil. DERIVED (Nov 7 test leg).

ChatGPT:
- When it returns (about Nov 10), it resumes the checker seat. Whether it can spend its subscription inside a third-party runner is unverified; subscription models are spent through their own official tools until that is checked. ASSUMED (flagged Nov 8 during the workhorse review; the check takes about ten minutes and settles it).

Pack and chair side (traps are not only the models'):
- A pack's own assertions can be wrong, and legs that trust the pack inherit the error. On issue #256 the pack stated an alias variable was not the run object; it was. The blind leg, reading the source, caught it; both writer legs trusted the pack and under-called the finding. Rule: a pack quotes sources, it does not replace them, and the chair re-verifies load-bearing pack claims against the source files. MEASURED (Nov 8).
- A leg can only audit what the pack contains. If the job is to audit documents, the pack must embed their full texts; excerpts plus an index produce honest near-empty legs and a wasted run. MEASURED (Nov 8, issue #257 first runs; fixed with supplementary full-text packs the same day).
- A census built on literal patterns has blind spots (alias spellings, subscript and getter forms). Add a supplementary pass for the spelled-out forms before claiming completeness. MEASURED (Nov 8, issue #256).

## Screening rules

- Match the leg to the job type: fidelity and quotation-heavy work leans on Qwen and the blind Rey leg; ideation work can use DeepSeek, Flash and Grok freely, without treating their output as evidence. DERIVED (leg record, Nov 5 to 8).
- Screening is leg-specific and job-specific, never a standing verdict on a model. A model screened out as an evidence source on one job can still ideate on the next. MEASURED (Tripo vet, Nov 5; applied since).
- No leg grades the chair's own pack silently: where a leg's result depends on a pack claim, the chair checks that claim against the primary source before the synthesis relies on it. DERIVED (Nov 8, issue #256).

## Pack anatomy (what a council evidence pack contains)

- The issue's fixed block verbatim (Owner, Brief, Deliver to, Branch, Models, Done when). MEASURED (R75 board protocol).
- The winning sources in full or in verified extract: FINDINGS rows and LOOP state for board work; the code or documents under review, in full, for audit work. MEASURED (packs since Nov 2; full-text rule added Nov 8).
- Measurements made by execution, not by reading: censuses, counts and greps are run and their outputs pasted, with the method stated so a leg can judge the blind spots. MEASURED (review-pack skill; issue #256 census).
- One leg prompt per seat (or one shared Leg prompt where the block names a single text), stating the deliverable's shape: findings cite file:line, quotes stay under 20 words, every finding carries its severity or class, and the leg closes with a Not checked list. MEASURED (REVIEW_PROTOCOL.md; leg prompts since Nov 2).
- The prescribed send: one file attached, the message names the pack and the exact heading of the leg's instruction, and forbids a preamble or a plan. MEASURED (standing send text, Nov 2026).
- Chair synthesis after all legs land: verdict first, findings merged and de-duplicated, disagreements between legs resolved against the primary sources, and the pack's own errors owned in the deliverable when they shaped a leg. MEASURED (Nov 8, issues #256 and #257).

## Maintenance

- The agent who runs a job appends any new trap it measures, with the date and the job's issue number. The chair prunes lines a later measurement overturns, and says so in the commit. DERIVED (#216 ask 6 discipline, applied to this file).
- When a gate changes (a UI renames a control, a model is retired, a subscription lapses), update the gate line the same day; a stale gate is worse than none. DERIVED (Nov 5 DeepSeek amendment; Nov 5 Argon lapse).
