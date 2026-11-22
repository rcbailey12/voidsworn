# Leg: DeepSeek (issue 1572)

Model gate: DeepThink on, Search off, verified at both ends.
Chat: https://chat.deepseek.com/a/chat/s/1800401f-dfc3-4127-8ca9-620cfbad4f30

## 1. Neon plan critique

Right: the listening page is the correct centrepiece and "the
picks set the standard" is the right governance; framing
production as a question is honest; AudioStreamInteractive is
the right Godot tool for stem-based adaptive music and the state
signals already exist in the reactive player.

Wrong or missing:
1. Ten sounds is far too few for 71 cues. The ladder is a
   relational judgment (each rung plainly heavier than the last)
   and only works heard in one sequence; the page also needs a
   death per faction family and four-take tests.
2. "Current vs candidate" is the wrong A/B: the current sounds
   are known-bad, so the comparison is biased. Use forced choice
   between two plausible candidates, current shown only as a
   reference at the end.
3. The UI problem is the headline complaint and gets no
   dedicated pass; it is the cheapest fix and should have its own
   session with non-electronic candidates.
4. The four-take rule is untested; fatigue is the real risk in a
   game played for hours. Include one event rendered as four
   takes in rotation.
5. Faction families are untested; include one death per family
   in one pass or the families blur in the rebuild.
6. No mix or stress test: weight without harshness is also a bus
   problem (low-mid body, soft top, sub-bass only on big events,
   ducking). Include a "many at once" demo.
7. No acceptance spec: picks must become a written spec
   (duration, tail, spectral balance, loudness, bus) or
   production of the remaining cues drifts.
8. The one-song music plank is the weakest and should be split
   off and deferred; the complaint is SFX and UI, not music, and
   the existing library music's licence must be checked against
   R40 first.
9. Hand-made vs Stable Audio 3 is a false binary; it omits
   library editing and hybrid (recorded transient plus generated
   or synthesized low tail), which is usually what weight without
   harshness requires.
10. The plan never mentions the free-only line or R40, the
    binding constraint.

Change: two listening passes (UI first, then ladder plus faction
row), forced-choice A/B, four-take and stress tests, written
spec at the end, music deferred, licence gate before sourcing.

## 2. Sources

- ElevenLabs SFX: commercial on paid plans (terms wording
  UNSURE); roughly $5 to $99 a month (UNSURE, current). Good
  foley-ish textures, weak on sustained heavy impacts, tends
  generic-Hollywood. Paid, needs a rule change. Not recommended
  as the ask; quality fit is poor for the house sound.
- ElevenLabs Music: song-oriented, not stems. Not recommended.
- Stable Audio 3: DeepSeek could not verify a product under this
  name (it verified Stable Audio 2.0 and Stable Audio Open).
  CHAIR NOTE: Stable Audio 3.0 does exist; Stability's own pages
  describe the 3.0 family, with Small, Small SFX and Medium as
  downloadable weights under the Community License and Large via
  API. See the blind leg and synthesis.
- Stable Audio 2.0 and Open: Community License, commercial free
  under about $1M revenue (threshold UNSURE to DeepSeek, verified
  $1M in the blind leg). Strong on ambience, loops and textures;
  smeary on short dry transients, weak exactly where weapon
  one-shots need to be clean.
- AudioCraft: code MIT, weights CC-BY-NC 4.0; blocked by R40.
  Named as a common trap.
- ACE-Step: Apache-2.0 (UNSURE to DeepSeek; confirmed in the
  blind leg). Full-song music, not SFX.
- AudioLDM 2 and Tango 2: weights believed CC-BY-NC-SA; blocked.
- Sonniss GDC packs: royalty-free, commercial, no attribution;
  high quality real recorded foley; best free fit.
- Kenney: CC0, compatible, but it is the problem, not the fix.
- Freesound: filter to CC0 (and CC-BY with an attribution
  decision); NC and SA banned.
- BBC Sound Effects: RemArc licence, not commercial. Blocked.
- Paid libraries (BOOM, Pro Sound Effects, A Sound Effect):
  royalty-free perpetual; packs roughly $50 to $500 (UNSURE,
  unchecked); exactly the mechanical material needed.

The paid ask: one targeted library purchase, not a subscription:
a mechanical and foley pack (keyswitches, relays, solenoids,
latches, valves, breech blocks) to replace all 11 UI cues and
supply the game's switchgear vocabulary. Frame it as cheaper
than agent runs spent curating scattered CC0. AI generation
verdict: useful for beds and tails, unreliable for dry short
transients; the strongest model is hybrid. Notes Steam's
AI-content disclosure if generated assets ship.

## 3. UI sounds

Design rules: dry, close, soft top (low-pass about 6 to 8 kHz),
body 120 to 400 Hz, short, one shared room send, four takes
varied in timing and level rather than pitch. Click: mechanical
keyswitch or solenoid clack, 40 to 80 ms thock. Select: relay
pull-in, two-part. Confirm: rotary detent or latch snapping
home, two-stage. Cancel: spring release, relay dropping out.
Panel: pneumatic hiss plus latch, drawer on rails, 300 to 600
ms. Turn announcements: soft-struck ship's bell or metal bar,
two-note motif over a low held tone. Reward: latch opening plus
a ball bearing into a felt-lined tray, or one low bell strike.
Alert: relay chatter and a hissing valve, two pulses, no siren.
Boss: deep held note, hull groan, hangar door mechanism, distant
turbine spool, no riser. Practical sourcing: record real objects
(keyboard, light switch, car latch, camera shutter, stapler,
valve, drawer); supplement with Sonniss and CC0 Freesound;
retire the Kenney Interface pack entirely.

## 4. Repos

Verified and useful: spotify/pedalboard (Apache-2.0, batch DSP
to enforce the spec and render takes); librosa/librosa (ISC,
analysis as an automated spec checker); Stability-AI/
stable-audio-tools (pipeline for the open models, verify
licence); facebookresearch/audiocraft (experiments only, R40
blocks its output); ffmpeg (conversion, loudnorm, trimming);
godotengine/godot docs for AudioStreamInteractive. Could not
verify any dedicated game-audio agent skill repo, a named Godot
audio-manager addon, or awesome-list contents, and guessed at
none. Recommendation: write a small house skill around
pedalboard, librosa and ffmpeg instead of hunting for one.

## 5. First step (3 runs)

Run 1: licence gate and candidate shortlist, a one-page
allow/deny table across all candidate sources, ending in the
allowed set plus the explicit paid-library ask. Run 2: build the
listening page from allowed sources only, forced-choice A/B: six
UI moments, the full ladder in one sequence, one death per
faction, a four-take rotation demo, a many-at-once stress clip.
Run 3: the developer session, converting picks into a one-page
spec plus a priority and ducking scheme. Music deferred until
the SFX and UI spec is signed off and the existing music is
confirmed R40-clean.
