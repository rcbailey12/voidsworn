# Blind leg: Rey (written before any model leg, and before reading the parallel Opus write-up)

Evidence I worked from: the issue brief; docs/playbooks/sound.md
(the target, Ryan's complaints, where the redo stands);
godot/audio/cues.json on main (71 cues, 11 of them ui_*); the
godot/music tree on main (31 files, faction tracks, calm and hot
tracks, music.json and music_player.gd); the prior Muse sourcing
study already in the repo (contrib/muse/design/
sound_sources_2026_11/); official licence and pricing pages
checked Nov 21, 2026 and linked inline. Anything I could not
check is tagged UNSURE.

## 1. The Neon plan, critiqued

The plan has three planks: a listening page of 10 sounds (now
vs. candidates) so Ryan picks by ear; hand-made vs. Stable Audio
3 as the production question; and one-song battle music through
Godot's AudioStreamInteractive.

- The listening page is the right centre of the plan, and it is
  not new: the sound playbook's own section 2a already specifies
  exactly this page (ten key sounds, present sound beside two
  candidates, Ryan's pick sets the standard), and a first version
  exists for the weight pass (docs/shots/sound_weight/LISTEN.md,
  four sounds, before and after). So the plan's real contribution
  is scope, extending the page from the ladder to UI and beds,
  not the idea. Risk: a 10-sound page with two candidates each is
  30 clips to judge in one sitting; the weight page worked at
  four sounds. Keep the page at 10 but let Ryan rule in two
  passes (ladder first, UI and beds second) or the UI half gets
  rubber-stamped.
- Hand-made vs. Stable Audio 3 is framed as either/or, and the
  current game says the answer is layered. cues.json builds
  almost every cue from layers; the faction death work (issue
  1238) already composes faction variants from clips in the game.
  A generator that returns one finished stereo clip fights that
  architecture: you cannot re-layer a baked clip under a faction
  variant. The right question is per family: generators for beds,
  ambience and one-off textures where a baked clip is fine;
  hand-made layers for the ladder and hits, where the routing
  rule (the gun chooses the hit sound) needs separable parts.
- One-song battle music via AudioStreamInteractive is the plank
  most out of step with the current game. godot/music already
  ships a library, not a song: faction tracks (fac_chorus,
  fac_hegemony, and more), calm tracks (calm_tactical,
  calm_darktimes), hot tracks (hot_pursuit, hot_heat, hot_theme_a),
  a boss track, a music.json and a player that already reacts to
  the battle (the 1448 wiring notes describe the music hearing
  this round's shots and counting close enemies). Replacing that
  with one interactive song throws away the faction voice the
  playbook asks for. What is worth testing from the plank is the
  mechanism, not the one song: AudioStreamInteractive's clip
  transitions on the existing calm-to-hot pair would prove
  whether interactive stems beat the current crossfade, at the
  cost of re-exporting two tracks as stems. Pick: keep the
  library, trial the mechanism on one battle context.
- What the plan misses entirely: the UI family. Ryan's complaint
  names the ui_* cues as beeps and boops, and all 11 ui cues in
  cues.json are electronic tones (Kenney Interface sounds plus
  synth renders). A plan for the redo that leads with battle
  sounds and music and says nothing about the family Ryan quoted
  verbatim has its order wrong. The listening page should carry
  at least two UI slots, and the redo should probably start
  there: 11 cues, heard constantly, cheapest to replace.

## 2. Sources compared

House constraints first: the playbook line is "Free tools and
free sources only", and R40 bans NC, ND and SA licences. Every
option below is judged against both.

- **ElevenLabs SFX** (paid). Licence: commercial use on any paid
  plan, royalty-free, rights survive cancellation; the free tier
  is personal use only, so free ElevenLabs output cannot ship.
  Cost: Starter $6/mo (about 150 generations), Creator $22/mo
  (about 605), roughly 200 credits a generation at auto duration,
  40 credits a second at set duration
  (https://elevenlabs.io/pricing). Music is a separate trap:
  ElevenLabs' music terms exclude "Studio Games" and allow indie
  games only under revenue caps
  (https://elevenlabs.io/music-terms), so SFX yes, music no
  without an enterprise deal. Quality: the strongest text-to-SFX
  of the set for mechanical and foley prompts, four takes per
  generation, seamless looping. Effort: lowest, API and web, no
  local setup. Verdict: the one paid option worth putting to
  Ryan. A single Creator month at $22 would cover a full UI
  family plus ladder candidates with takes to spare; it breaks
  the free-only line, so it needs his ruling, and the ask should
  be scoped to SFX only, never music.
- **Stable Audio (hosted)** (free tier usable). Stability's own
  licensing KB says commercial use is permitted on every plan
  including Free, and names video games and embedded assets
  explicitly (https://kb.stability.ai/knowledge-base/stable-audio-commerical-and-usage-licensing).
  That makes the hosted tool the only generator whose free output
  can ship in a commercial game, subject to its terms and
  acceptable use policy. Quality: good beds, ambience and
  textures; weaker at short dry mechanical one-shots, which is
  this game's core need. Effort: low. Verdict: the default
  generator under the current free-only line, aimed at beds and
  ambience.
- **Stable Audio Open 1.0 and Stable Audio 3 open weights**
  (free, self-hosted). Governed by the Stability AI Community
  License: commercial use allowed under $1M annual revenue with
  registration and attribution ("Powered by Stability AI" and
  the licence notice travel with distribution)
  (https://huggingface.co/stabilityai/stable-audio-open-1.0/blob/main/LICENSE.md,
  https://stability.ai/community-license). Not an NC licence, so
  R40 does not ban it, but the attribution and registration
  duties are real and the licence is revocable, which a CC0
  library never is. Stable Audio 3's Small SFX model is the
  interesting one for this game (on-device short effects).
  Effort: highest of the hosted-or-open set (GPU, pipeline,
  batch curation), though Ryan's RTX 5080 makes it feasible.
  Verdict: viable, second to the hosted tool unless batch volume
  or offline work matters.
- **AudioCraft (Meta: MusicGen, AudioGen)** (free, local). Code
  is MIT; the model weights ship under CC-BY-NC 4.0
  (https://github.com/facebookresearch/audiocraft). NC means R40
  bans the output from the game outright. Verdict: out, and
  worth naming because it is the generator most tutorials reach
  for first.
- **ACE-Step** (free, local, music). Apache-2.0 code; a music
  generator, not an SFX tool (https://github.com/ace-step/ACE-Step).
  Licence-clean under R40. Quality for full songs is respectable,
  but this game's music problem is not song supply (the library
  exists) and Ryan likes the reward-screen music as it stands.
  Verdict: allowed, not needed; keep in the drawer if a faction
  track gap ever opens.
- **Free libraries.** Kenney (CC0, https://kenney.nl): already in
  the game and part of the problem for UI, its interface pack is
  exactly the beep family Ryan wants gone; its other packs stay
  useful as layers. Freesound (mixed CC): only CC0 and CC-BY
  clips pass R40; CC-BY-NC, ND and SA clips are out, so every
  clip needs its licence read, which the Nov 11 sourcing study
  already did for the main families. Sonniss GDC bundles: free
  downloads under Sonniss's own licence, which allows use in
  games; UNSURE whether the current year's bundle terms match
  the older ones, check before relying. OpenGameArt: mixed
  licences, same per-clip discipline as Freesound.
- **Paid libraries.** The honest comparison: a single broad
  royalty-free library (for example a Soundly or Epidemic-style
  subscription, or a one-off BOOM-style bundle) buys curation and
  licence simplicity at recurring cost. UNSURE on current prices,
  not checked. For a game whose core sounds must be layered and
  faction-flavoured, library clips still need the same layering
  work as free ones, so the money buys search time, not a
  different result. Verdict: not the first paid ask; ElevenLabs
  is, because generation makes the exact sound the ladder needs
  instead of the nearest clip a library happens to hold.

## 3. Non-electronic UI sounds for "clean and tactical"

The playbook already points here: "Mechanical and electrical
sources: relays, capacitors, breech blocks, hull groans,
pressure." For the 11 ui_* cues, a foley vocabulary that fits a
fleet command deck:

- ui_click: a relay snap or a metal toggle switch, single, dry.
- ui_select: a rotary detent, one notch of a knurled dial.
- ui_confirm: a breech or latch closing, two parts, seat and
  lock; the sound of something mechanical agreeing.
- ui_cancel: the same latch opening, or a switch thrown back;
  pairs with confirm so the two are one mechanism in two
  directions.
- ui_panel: a hatch or panel slide, short, with a soft end stop.
- ui_round, ui_your, ui_enemy: these are announcements, not
  clicks; keep them as low mechanical thunks through the hull
  (a distant relay bank firing) with the faction-neutral one
  drier than the enemy one, and let the enemy turn carry a
  faint pressure change, air moving, rather than a tone.
- ui_reward: the one place a bright sound is earned; a metal
  key or token set down on a hard surface, real and small, not a
  chime arpeggio.
- ui_alert: a circuit breaker trip. Unmistakable, mechanical,
  impossible to confuse with a tone.
- ui_boss: a heavy contactor closing, the lights-dimming thunk
  of a big circuit energising.

Rules that keep it tactical instead of novelty: one mechanism
family across all 11 (the same switchgear, recorded or generated
as a set), four takes each per the variation rule, dry and
short, low-mid body, and no real-world sounds with a modern
civilian read (no mouse clicks, no phone taps, no camera
shutters except possibly a rangefinder-style shutter for a
target lock, UNSURE, test by ear).

## 4. Public repos worth reusing

Checked at the level of repo and licence, Nov 21, 2026:

- facebookresearch/audiocraft: reuse the pipeline shape only
  (prompt batching, take curation), never the weights (CC-BY-NC,
  R40). https://github.com/facebookresearch/audiocraft
- ace-step/ACE-Step: Apache-2.0; reuse its local inference and
  looping workflow if a music gap opens.
  https://github.com/ace-step/ACE-Step
- Stability-AI/stable-audio-tools: the inference and training
  code for the Stable Audio open models; reuse for batch
  generation and for fine-tuning on the game's own clips, which
  is how a generator learns this game's switchgear instead of
  generic foley. Licence: the repo's own terms plus the
  Community License on the weights; check before lifting code.
  https://github.com/Stability-AI/stable-audio-tools
- The game's own prior work is the most reusable pipeline of
  all: contrib/muse/design/sound_sources_2026_11/ (the Nov 11
  sourcing study and its per-family licence table) and
  godot/audio/test/ checks (audio_check.gd, faction_death_check.gd)
  already encode the ladder and routing rules as tests. Any new
  pipeline should plug into those checks rather than invent new
  ones.
- UNSURE, flagged for the chair to verify: dedicated Godot audio
  agent skills and MCP servers exist in the wild (Godot MCP
  servers with audio bus control), but I did not verify a named
  repo's licence and maintenance state, so I name none rather
  than guess.

## 5. First step, sized in agent runs

One run: rebuild the listening page at the playbook's section 2a
spec, extended. Ten slots: the five ladder steps, a cruiser
death, ui_click, ui_confirm, a map bed, a battle bed. For the
two UI slots the candidates are mechanical (section 3's latch
pair), one from free sources and one generated on the hosted
Stable Audio free tier, so Ryan's ear also rules on the source
question while he rules on sounds. No game files change; the
page is the deliverable, and his picks become the redo's
standard. If the UI pair lands, the ElevenLabs question (one
Creator month, SFX only) becomes a decision with evidence
behind it instead of a guess.
