# Leg: Gemini, run on Hydrogen (Flash seat) (issue 1572)

Model gate: picker showed Hydrogen, selected and confirmed; signed
in with no phone approval needed.
Chat: https://gemini.google.com/app/5e07e14bcfa9e0ec

CHAIR FLAGS, read first. (1) Its Godot correction is RIGHT and the
chair adopts it: AudioStreamSynchronized is the node for
simultaneous vertical stem layers; AudioStreamInteractive is a
clip graph with a transition table (horizontal switching). Neon's
plank 3 names the wrong node for stem layering. Verified against
Godot 4.3 music write-ups at the chair. (2) Its claim that ACE-Step
is "MIT on code and weights" is WRONG: the GitHub API reads the
ace-step/ACE-Step licence as Apache-2.0 (checked at the chair, Nov
22, 2026). Either licence passes R40, so the error changes no
verdict, but the record is corrected here. Its "ACE-Step 1.5"
version claim is unverified. (3) Its Stable Audio API price
($0.26 per generation) is unverified at the chair and is not relied
on. (4) Its four named skill repos all EXIST (verified at the chair
via the GitHub API: Donchitos/Claude-Code-Game-Studios, MIT, about
40k stars, active; MengTo/Skills, MIT, about 8k stars, active;
rootcastleco/rei-skills, 9 stars, licence NOASSERTION;
bestagentkits/agency-skills, MIT, 26 stars, last pushed Jun 2026),
but the chair did not independently open the SKILL.md file paths
it names inside them; those paths stand as reported by this leg.
(5) Its ElevenLabs and AudioCraft positions match the verified
record (paid tiers commercial, free tier not; AudioCraft weights
CC-BY-NC, banned by R40).

## Positions

Plan critique: keep plank 1, replace plank 2's binary with a
hybrid pipeline, reject plank 3 as stated and refine the existing
library player instead. Two additions the other legs converge on:
a stress-test mix on the listening page (overlapping lasers, a
macro cannon, a lance, UI clicks at once) so masking and fatigue
are judged, not just single sounds; and the plan's missing
loudness discipline, an automated LUFS and peak normalization pass
with a low-pass roll-off to guarantee the soft top. On production:
diffusion generators are weak at sample-accurate transients, dry
short mechanical clicks and pitched consistency across a strict
weight ladder; curated foley and hand DSP win the UI and the
transients, generators and libraries win organic faction textures
and beds.

Sources: stay inside the free-only line first (Sonniss GDC
bundles, CC0 libraries, local DSP). Its paid ask is conditional
and narrow: one ElevenLabs month ($6 to $22) only if free sources
fail on the hardest faction textures (the wet-and-breathing and
glass-and-tone families). It agrees the hosted Stable Audio output
is commercial on the ToS, rates Stable Audio Open as a decent raw
layer source under the Community License, and prices paid library
packs at $50 to $300 plus.

UI: one family of dry close physical switchgear, shutters,
magnetic latches and damped pneumatics, rolled off above about 5
to 6 kHz. Per-cue specifics folded into the synthesis: keyboard
switch or rangefinder shutter for click (pitched down, band-passed
300 Hz to 3.5 kHz); solenoid latch with 180 to 400 Hz body for
select; two-stage detent then bolt lock for confirm; a lighter
reverse unlatch for cancel; a steel drawer slide with a soft stop
for panels; flip-clock drop and low harmonic for player turn,
deeper shutter drop and an 80 to 120 Hz sub-pulse for enemy turn;
tumbler clicks resolving into a low-passed struck plate for
reward; a double bulkhead thump (120 to 250 Hz) for alert, cutting
through by rhythm rather than pitch; blast-door winch, sub-bass
hull groan and one damped plate resonance for boss entry.

Repos: Donchitos/Claude-Code-Game-Studios (team-audio skill:
phase-gate return contract, artifact verification, Godot bus and
mix checklist) as its top pick; rootcastleco/rei-skills (mix
hierarchy and adaptive transition rules); MengTo/Skills (combat
feedback priority matrix and voice-capping checklist; the rest is
web-audio boilerplate); bestagentkits/agency-skills (persona
reference only). Its TypingMind Godot audio skills are tagged
UNSURE by the leg itself.

First step: 3 runs. Run 1, a read-only audit plus a written DSP
spec mapping every cue to its ladder tier, faction family,
variation count and EQ/LUFS targets. Run 2, sourcing plus the A/B
listening page (10 cues plus the stress mix) behind a human gate.
Run 3, wiring the approved 10 cues into Godot with bus calibration.
