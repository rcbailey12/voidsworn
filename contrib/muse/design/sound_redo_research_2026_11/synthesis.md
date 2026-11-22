# Sound redo research: synthesis (issue 1572)

Research only. No audio was made, edited, generated or wired.
Council: blind Rey leg first, then DeepSeek, Qwen, Gemini on
Hydrogen (the Flash seat); Grok seat empty (bot wall, see
leg_grok.md). Rey chairs. Licence and price claims below were
checked against official pages or the GitHub API at the chair on
Nov 21 and 22, 2026; where a leg's claim failed that check, the
correction is stated and collected again at the end.

## Verdict in one paragraph

Neon's plan gets one plank right, one framed wrong, and one
backwards. The listening page is right, and it is the playbook's
own section 2a idea; build it first, extended as below. Hand-made
versus generator is a false binary against this game's layered
cue architecture; the answer is per family. One-song battle music
contradicts the shipped library and should be dropped; the only
piece worth testing is interactive transitions, and even there
the plank names the wrong Godot node. The redo should lead with
the UI family, the 11 cues Ryan quoted verbatim, sourced free:
Sonniss GDC bundles and CC0/CC-BY libraries for the mechanical
material, the hosted Stable Audio free tier for beds and
textures. No paid ask up front; two named fallback asks, each
gated on the listening page failing by ear, are at question 2.

## 1. The Neon plan, chaired

All four legs agree on the shape; the differences are in the
page's composition, and the chair takes all of them because they
compose:

- Keep the listening page, and build it to the playbook's
  section 2a spec extended: about 18 clips, not 10 singletons.
  The ladder steps are judged as cue chains (fire, impact, death)
  because that is how they are heard (Qwen); the current sound is
  a reference, and the actual choice is forced between candidates
  (DeepSeek); all 11 UI moments appear, not a sample (Qwen, blind
  leg); and the page carries two tests no leg would drop: a
  many-at-once stress mix (DeepSeek, Gemini) and a four-take
  fatigue row for the cues heard constantly (DeepSeek).
- Before the page, write the acceptance spec (DeepSeek, Gemini):
  per cue family, target duration, tail length, spectral balance
  (body low and low-mid, soft top), loudness (integrated LUFS and
  peak), and bus. Picks made against a written spec become a
  standard; picks made by vibe do not survive contact with the
  other 60 cues.
- Apply a kill list (Qwen): name the 10 to 15 worst current cues
  first. The redo's first production target is that list, not a
  blanket pass over all 71.
- Plank 2 resolved per family. Generators return one baked stereo
  clip; cues.json builds cues from layers and routes hits by
  weapon and target, and faction deaths are composed from layers.
  So: recorded and library material, layered by hand, for the
  ladder, the hits and the whole UI family (transients are where
  diffusion generators are weakest, Gemini, DeepSeek); generated
  material for beds, ambience and one-off textures where a baked
  clip is fine (blind leg, Gemini).
- Plank 3 dropped as stated. The game already ships a reactive
  library (faction, calm, hot and boss tracks; a player reacting
  to shots fired and close enemies). Collapsing that into one
  song deletes the faction voice the playbook asks for (all
  legs). The mechanism is still worth one trial, with a
  correction: vertical stem layering in Godot is
  AudioStreamSynchronized, not AudioStreamInteractive, which is
  a clip graph with a transition table (Gemini, verified at the
  chair against Godot 4.3 music references). Trial scope: the
  existing calm-to-hot pair in one battle context, re-exported as
  stems, judged against the current crossfade. Nothing else in
  the music library changes.
- Order of work: UI first. Ryan's complaint names the UI cues;
  they are 11 cues, heard constantly, and the cheapest family to
  replace well. Every leg puts the UI pass at or near the front;
  the chair makes it the first production target after the page.

## 2. Sources, chaired

Settled facts, with the check behind each:

- ElevenLabs SFX: commercial use on paid plans only; the free
  tier is personal use only. Starter $6/mo (30k credits, about
  150 generations at roughly 200 credits each), Creator $22/mo
  (about 605). Four takes per generation, seamless looping, the
  strongest text-to-SFX of the set for mechanical and foley
  prompts (https://elevenlabs.io/pricing; blind leg and Gemini
  agree). Music is a trap: ElevenLabs' music terms exclude
  Studio Games and cap indie games by revenue
  (https://elevenlabs.io/music-terms). SFX only, never music,
  if it is ever bought.
- Stable Audio, hosted: Stability's licensing KB states
  commercial use is permitted on every plan including Free, and
  names video games and embedded assets explicitly (verified at
  the chair, Nov 22, 2026:
  https://kb.stability.ai/knowledge-base/stable-audio-commerical-and-usage-licensing).
  It is the only generator whose free output can ship. Good at
  beds, ambience and textures; weak at short dry one-shots.
- Stable Audio 3 is real (DeepSeek doubted it; the same KB names
  Stable Audio 3.0 Small and Medium as open weights under the
  Community License). Open weights, including Stable Audio Open
  1.0: commercial use under $1M annual revenue with registration
  and attribution duties, and the licence is revocable
  (https://huggingface.co/stabilityai/stable-audio-open-1.0/blob/main/LICENSE.md).
  Passes R40 (it is not an NC licence), but a CC0 clip carries no
  such duties; self-hosting is the high-effort route and only
  worth it for batch volume.
- AudioCraft (Meta): code MIT, weights CC-BY-NC 4.0. R40 bans
  the output. Out. (Qwen's leg calls the weights unencumbered
  and picks AudioCraft as its primary generator; that is wrong,
  see Corrections.)
- ACE-Step: Apache-2.0 (GitHub API, checked at the chair; the
  Gemini leg's "MIT" is wrong, and its "1.5" version claim is
  unverified). A music generator only. Licence-clean, allowed,
  not needed: the music library exists and Ryan likes the
  reward-screen music.
- Sonniss GDC bundles: the current licence (v2.0, effective Aug
  27, 2026, checked at the chair on sonniss.com) is royalty-free
  for personal and commercial projects, unlimited projects for
  life, no attribution, modification allowed. Two restrictions
  that matter here: the sounds may not be resold or supplied as
  sound effects, and they may not be used for AI training, so
  Sonniss clips stay out of any fine-tuning set. This settles
  the blind leg's UNSURE: the GDC bundles are the best free fit
  for recorded mechanical and foley material (DeepSeek, Gemini).
- Freesound and OpenGameArt: per-clip licences. CC0 and CC-BY
  pass R40 (CC-BY carries an attribution duty); NC, ND and SA
  clips are out. Kenney is CC0 and stays useful as layers, but
  its interface pack is the beep family being replaced.
- Paid libraries (BOOM, A Sound Effect and peers): standard
  royalty-free commercial game licences, one-time prices roughly
  $50 to $300 a pack. What the money buys is curation and
  licence simplicity, not a different layering workload.

The paid ask, resolved. The legs disagreed: the blind leg would
ask for ElevenLabs first; DeepSeek and Qwen would ask for one
targeted library pack; Gemini would stay free and ask for
ElevenLabs only if faction textures fail. The chair sequences
them by evidence instead of picking a winner in the abstract:

1. No paid ask now. The free stack (Sonniss GDC, Freesound
   CC0/CC-BY, hosted Stable Audio free tier) covers the UI
   family, the ladder's recorded layers, beds and textures on
   paper. The listening page tests that claim by ear.
2. First fallback, if the death row or the UI material fails on
   the page: one targeted mechanical and capital-ship library
   pack, one-time, about $50 to $80 (DeepSeek, Qwen). This is a
   change to the playbook's free-only line and needs Ryan's
   ruling.
3. Second fallback, if bespoke faction textures (the
   wet-and-breathing and glass-and-tone families) cannot be
   sourced free: one ElevenLabs Creator month, $22, SFX only,
   never music (blind leg, Gemini).

## 3. The UI family, chaired

One mechanism family across all 11 cues (all legs converge):
dry, close, physical switchgear, low-mid body, top rolled off
(about 5 to 6 kHz, Gemini), four takes each, no civilian
real-world reads (no mouse clicks, no phone taps). Per cue:

- ui_click: a relay snap or metal toggle, single and dry; a
  rangefinder shutter pitched down is the alternate take.
- ui_select: a rotary detent or solenoid latch, 80 to 120 ms,
  body at 180 to 400 Hz; selecting should feel like locking a
  fire-control switch.
- ui_confirm: a two-stage latch: detent click, then a damped
  bolt or breaker throw seating. Confirm and cancel are one
  mechanism in two directions.
- ui_cancel: the same latch releasing, lighter and shorter,
  pitch falling slightly.
- ui_panel: a steel drawer or hatch slide on rails, 200 to
  300 ms, ending in a soft felt or magnetic stop; close is the
  same slide, shorter.
- Turn announcements (ui_round, ui_your, ui_enemy): not clicks.
  A low hull thunk, a distant relay bank firing (blind leg), or
  a heavy card drop (Gemini); the enemy turn colder, with a
  faint pressure change or an 80 to 120 Hz sub-pulse, never a
  siren.
- ui_reward: a metal token set down on a steel tray (Qwen), or
  tumbler clicks resolving into one low-passed struck plate
  (Gemini). The one bright moment, and it stays small and real;
  no chime arpeggio.
- ui_alert: a circuit breaker trip (blind leg) or a double
  bulkhead thump at 120 to 250 Hz (Gemini). It cuts through by
  rhythm and weight, not by pitch; no klaxon.
- ui_boss: a heavy contactor closing (blind leg), a blast-door
  winch and sub-bass hull groan at 40 to 90 Hz with one damped
  plate resonance (Gemini), or a foghorn-class low note (Qwen).
  Deep, slow, singular.

## 4. Repos, chaired

Existence and licence for every repo below were checked at the
chair via the GitHub API on Nov 22, 2026. File paths inside
repos are as reported by the legs unless noted.

- The game's own prior work first (blind leg): the Nov 11
  sourcing study at contrib/muse/design/sound_sources_2026_11/
  with its per-family licence table, and the audio checks in
  godot/audio/test/, which already encode the ladder and routing
  rules as tests. Any pipeline plugs into those.
- Donchitos/Claude-Code-Game-Studios (MIT, about 40k stars,
  active): the Gemini leg's top pick; its team-audio skill's
  phase-gate return contract, artifact verification pattern and
  Godot bus/mix checklist are the reusable pieces (paths as
  reported by the leg, not independently opened at the chair).
- thedivergentai/Game-Dev-Agentic-Skills (LGPL-3.0, about 1k
  stars, active): found at the chair; carries a godot-audio-systems
  skill covering AudioStreamPlayer variants, bus architecture,
  pooling and interactive music patterns, including the
  Synchronized/Interactive distinction above. Read and adapt;
  the LGPL licence argues against lifting text wholesale into
  anything shipped.
- Stability-AI/stable-audio-tools (MIT): inference code for the
  Stable Audio open models; reuse for batch generation if the
  self-hosted route is ever taken.
- spotify/pedalboard: DeepSeek cites it for offline DSP. Its
  licence is GPL-3.0, not Apache-2.0 as that leg states (GitHub
  API, checked at the chair). Fine as an offline processing
  tool; its code does not ship in the game.
- MengTo/Skills (MIT, about 8k stars, active): web-audio focused;
  the combat feedback priority matrix and voice-capping
  checklist are reusable, the rest is browser boilerplate
  (Gemini, partial fit).
- rootcastleco/rei-skills (9 stars, licence NOASSERTION): a
  game-audio skill exists there per the Gemini leg. Read for
  ideas; lift nothing until the licence is clarified.
- bestagentkits/agency-skills (MIT, 26 stars, last pushed Jun
  2026): a game-audio-engineer persona prompt; reference only.
- facebookresearch/audiocraft and ace-step/ACE-Step: pipeline
  shape only (batching, take curation, local inference and
  looping workflow). AudioCraft's weights never touch the game
  (CC-BY-NC).
- DeepSeek's closing suggestion stands: once the listening
  page's recipe settles, write it down as a small in-house skill
  (cue spec, DSP chain, page builder) instead of adopting a
  general framework. The game's own checks are the harness.

## 5. First step, chaired

Three runs to a wired vertical slice, with Ryan's ear as the
gate in the middle. (The blind leg sizes the page alone at one
run; DeepSeek, Qwen and Gemini all size the full sequence at
three. The chair's run 1 is the blind leg's run, widened to
carry the spec and the kill list, which the page needs anyway.)

- Run 1: write the acceptance spec (question 1) and the kill
  list from cues.json and the routing rules, then build the
  listening page to the extended section 2a spec: ladder chains,
  a cruiser death and a capital death, all 11 UI moments, a map
  bed and a battle bed, plus the stress mix and the four-take
  fatigue row. Candidates sourced free only (Sonniss GDC,
  Freesound CC0/CC-BY, hosted Stable Audio free tier), so the
  page also tests the free stack. No game files change.
- Gate: Ryan rules on the page. His picks become the standard,
  and the page's failures, if any, decide which fallback ask
  from question 2 is put to him, with the pack or the ElevenLabs
  month named and priced.
- Run 2: produce the full UI family (11 cues, four takes each)
  to the winning recipe, plus the ladder and death-row cues on
  the kill list.
- Run 3: wire the approved cues into Godot (AudioStreamRandomizer
  for the takes, bus calibration so big events stay deep rather
  than loud), and run the calm-to-hot AudioStreamSynchronized
  trial against the current crossfade.

## Corrections recorded at the chair

- Qwen's leg states AudioCraft's licence as "MIT, outputs
  unencumbered" and picks it as the primary free generator. The
  code is MIT; the weights are CC-BY-NC 4.0, so R40 bans the
  output. The synthesis follows DeepSeek and the blind leg.
  Qwen also guesses Stable Audio Open might be Apache-2.0 (it
  is the Community License) and that the hosted free tier is
  non-commercial (Stability's KB permits commercial use on
  Free). Its design material (cue chains, kill list, mix-bus
  spec, plank 3 as regression) is unaffected and is used.
- DeepSeek's leg doubts Stable Audio 3 exists. It does; see
  question 2. The same leg gives spotify/pedalboard's licence
  as Apache-2.0; it is GPL-3.0.
- The Gemini leg gives ACE-Step's licence as MIT; it is
  Apache-2.0. Its Stable Audio API per-generation price is
  unverified and not relied on. Its named repos exist; the
  skill file paths inside them are as reported by the leg.
- The blind leg's Sonniss UNSURE is settled at question 2
  (licence v2.0, checked on sonniss.com).
