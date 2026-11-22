# Leg: Qwen (Qwen3.8-Max) (issue 1572)

Model gate: selector Qwen3.8-Max before sending, header after.
Chat: https://chat.qwen.ai/c/625108b7-ebf3-4be4-b032-6caecc3a32e4

CHAIR FLAGS, read first. This leg's central licence claim is
wrong: it says AudioCraft is MIT with unencumbered outputs and
picks AudioCraft as the primary free generator. The AudioCraft
code is MIT, but the model weights are CC-BY-NC 4.0, so generated
output is NC-encumbered and R40 bans it from the game. DeepSeek
and the blind leg both have this right, and the synthesis
follows them, not this leg. Two smaller errors: Stable Audio
Open is not Apache-2.0 (it is the Stability AI Community
License), and the hosted Stable Audio free tier is not
non-commercial (Stability's own licensing KB permits commercial
use on the Free plan). The leg's design and process material
below is unaffected and is used in the synthesis.

## 1. Neon plan critique

Right: the listening page is the correct way to set a tonal
target before production, and framing production as an explicit
fork is correct because it changes the pipeline, the licence
posture and the iteration speed.

Wrong or missing: the one-song music plank is a regression (the
current system is already a reactive library; AudioStreamInteractive
should be wired into the existing multi-track structure for
crossfades and a calm-to-hot transition clip, not used to flatten
it into one song). Ten sounds is too few and the wrong axis: the
page should present cue chains (fire, impact, death) across the
ladder, plus all 11 UI moments, about 18 clips, with
faction-family variants for at least two factions. The plan does
not address the specific complaints (thin means missing low-mid
and sub; cheesy and harsh mean high-frequency content and
stock-shaped transients; beeps mean the Kenney and synth UI set),
which need EQ, layering and sourcing guidance, with the house
rules carried as acceptance criteria. No mention of the
four-takes rule or of the free-only and R40 gate. Additions: an
explicit kill list of the 10 to 15 worst current cues, and a
mix-bus and loudness spec.

## 2. Sources

- ElevenLabs: commercial on paid plans (terms UNSURE, verify);
  tiers from about $5 a month (figures superseded by the blind
  leg's checked pricing: Starter $6, Creator $22). Competent
  one-shots, generic character; prototype role only unless the
  free-only line lifts.
- Stable Audio 3 hosted: commercial on paid (UNSURE to Qwen);
  stronger for textured and musical content. Prototype role.
- Stable Audio Open: free, textures and ambience, not tight
  transients (licence corrected in the chair flags above).
- AudioCraft: this leg's pick as primary free generator. NOT
  ADOPTED, see the chair flags: the weights are CC-BY-NC, so R40
  bans its output.
- ACE-Step: Qwen could not verify it and stated none (the blind
  leg confirms Apache-2.0 code, music only).
- Paid libraries (BOOM and similar): royalty-free perpetual,
  packs roughly $40 to $150 (UNSURE, unchecked); the ask is a
  one-time exception of about $50 to $80 for capital death and
  hull-groan material, where free sources are genuinely thin.
- Free libraries: Sonniss GDC bundles plus filtered Freesound
  CC0 and CC-BY as the backbone; Kenney is CC0 but is the sound
  being replaced; BBC treated as not safe for commercial release
  (RemArc).

## 3. UI sounds

Naval and industrial control room vocabulary, transients short,
body 80 to 300 Hz, top rolled off above about 6 kHz. Click: a
12 V relay tick or a dampened mechanical keyboard switch, under
80 ms, four takes. Select: a rotary detent or ratchet click,
about 120 ms, a low thunk layer plus a high tick layer. Confirm:
a breaker lever snap or bolt locking, two layers with a 60 to
80 Hz thump, about 150 ms, feels final. Cancel: a spring release
or toggle snapping back, softer and lower than confirm. Panel
open: a drawer on metal runners or a server tray, faint rail
texture, no whoosh. Panel close: the same drawer with a magnetic
catch tick. Turn announcement: a small brass ship's bell or a
mechanical tally counter, one clean hit, about 400 ms. Reward:
coins or a token onto a steel tray, or a register ka-chunk, dry,
no arpeggio. Alert: one industrial buzzer pulse or a click
cluster, rolled off above 4 kHz, two pulses max. Boss entry: a
pitched-down foghorn or a diesel starting, 40 to 60 Hz
fundamental, the one UI sound allowed a long tail. Production
notes: 48 kHz and 24-bit, high-pass at 60 Hz except the horn,
low-pass 6 to 8 kHz, no reverb on clicks, four takes for
anything firing more than once a minute, consistent peaks.

## 4. Repos

facebookresearch/audiocraft (named for AudioGen and MusicGen;
the licence error in the chair flags applies, so reuse is
limited to code study); Stability-AI/stable-audio-open (path and
licence UNSURE to Qwen); godotengine/godot (AudioStreamInteractive
and bus reference); godotengine/godot-demo-projects (audio demos
with transitions, bus routing and randomised playback patterns
for the four-takes system); a Freesound Python client under the
MTG org (exact name UNSURE) to automate CC0 and CC-BY search and
download by tag; librosa/librosa (loudness and spectral checks
against the house EQ rules); pyloudnorm (owner UNSURE) for an
asset-validation script. ACE-Step and Godot audio plugins:
declined to name, unverified.

## 5. First step (3 runs)

Run 1: audit and shortlist. Analyse all 71 cues, flag the 10 to
15 worst offenders, group by ladder tier and faction family,
produce kill, fix and keep lists, and draft the 18-slot page
structure (7 ladder cue chains plus 11 UI moments) as a manifest
with file paths, complaints and target descriptions. Run 2:
source and generate candidates, 2 to 3 per slot (library pull,
generated, second generated source), trimmed, loudness-normalised
and EQ'd to the house spec, every licence verified and logged;
36 to 54 files out. Run 3: build the listening page (HTML or a
Godot scene) with current and candidates side by side, metadata
(source, licence, LUFS, spectral centroid) and a pick button that
writes choices to JSON. The production path decision is
deliberately deferred until the picks show which sources won.
