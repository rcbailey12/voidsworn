# Argon leg: Job 5 (battle sound)
Model: Gemini 4 Argon, Thinking level High
Date: 2026-11-02
Chat: https://gemini.google.com/app/d35934bcf2715b15
Gates verified: picker read Argon High before submit, prompt bar read Argon High before submit, and prompt bar read Argon High after submit. Both gates passed.

1. Headline

The battle soundscape of Embers of the Hollow Sun already covers basic weapon fire, shields, explosions, and turn markers across 57 synthesized cues and 24 loudness-levelled music tracks, but it falls silent during newly added tactical orders and staged ship deaths. The single most important gap is the complete absence of audio cues and event dispatches for boarding, brace, and Nemesis adaptation, joined closely by un-staged destruction audio that fires all explosion layers at once instead of tracking the two-second capital split, the R73 slow-motion kill beat, small-ship death runs, and silent hulk kills. Closing these gaps requires nine new layered cue definitions in cues.json, semantic event dispatches in battle.gd and rules.gd, and targeted fixes in sfx.gd for salvo defer drop-outs and the master mute floor.

2. Cue List

1. Hand-Over (Player Ship Turn Activation)
Moment: The game hands control of the next ready ship to the player with a gold UP tag and a smooth camera glide.
Cue ID: ui_turn
AudioSpec: ui_chime | gain_db -8.0 | pitch 1.0 | bus SFX
Change: Change nothing.

2. Volley Fire (Simultaneous Salvo Launch)
Moment: A ship unloads a multi-weapon salvo where launch sounds are grouped to prevent machine-gun audio stutter.
Cue ID: defer_flak (representative)
AudioSpec: defer_flak | gain_db 0.0 (stored, unapplied) | layers: flak_shot x3 at 0.0 / 0.07 / 0.14 s, gain offsets +0.0 / -3.5 / -7.0 dB, each pitch_rand ±4%
Change: Fix in sfx.gd: apply the deferred group's stored gain_db (currently dropped to 0.0) to the group or its layers, noting that one deferred spec (defer_torpedo) carries -2.0.

3. Boarding (Marine Pods and Grapple Assault)
Moment: Pods arc to the enemy hull, grapples bite, and marine parties either deploy successfully or are repelled.
Cue ID: NONE
AudioSpec: NONE
Change: Define new layered cues in cues.json and dispatch from the boarding resolution in battle.gd: board_launch: layer thrust_pod (sine drop 800→100 Hz, band-passed noise whoosh, metallic pod-clank transient); board_grapple: layer hull_bite (low thud, cable-twang FM sting); board_breach: layer breach_charge (noise pop, pressure-hiss decay); board_success: layer marine_deploy (short filtered vox-like chirps in sequence) resolving to the existing capture sting; board_repelled: layer marine_fail (muted clank descending).

4. Brace (Defensive Brace Order)
Moment: A captain orders Brace, locking the ship's posture and raising a visible shield ring.
Cue ID: NONE
AudioSpec: NONE
Change: Define new cue in cues.json and dispatch from the brace resolution in rules.gd: brace_order: layer brace_ready (armour-plate clank, rising shield-hum tone, low confirmation thump) on the SFX bus.

5. Capital Ship Split & Burn (Staged Capital Destruction)
Moment: A dying capital ship splits at the spine at t=0, burns as a hulk for 2.0 seconds, and detonates at t=2.0 amid slow-motion shockwaves.
Cue ID: boom_cap
AudioSpec: boom_cap | gain_db -4.0 | layers: explosion_big, explosion_huge, boom_sub, ship_break, hull_groan, fire_roar, debris_field
Change: Re-author in cues.json by splitting boom_cap into staged cues to match the R72 timeline, and dispatch stage-by-stage from battle.gd: boom_cap_split (t=0): layers ship_break, hull_groan, explosion_big; boom_cap_burn (t=0.1, loop/bed): layers fire_roar, debris_field; boom_cap_final (t=2.0): layers boom_sub, explosion_huge. Do not fire the monolithic boom_cap for capitals.

6. Kill Confirmations & Hulk Kills (Small-Ship Deaths and Silent Hulks)
Moment: A small ship is destroyed, or an already-dead drifting hulk is destroyed by a later hit.
Cue ID: boom_small / NONE
AudioSpec: boom_small | gain_db -3.0 | layers: explosion_small, ship_break
Change: Define new cues in cues.json and alter dispatch in battle.gd: boom_run: a three-explosion run triggered by three or more small-ship kills within one second; hulk_kill: quiet cue (distant muffled thump, debris patter, no fire layers) for hulk destruction. Also define slowmo_kill to trigger on an R73 player kill: layer slowmo_drop (pitch sweep down to 40% over 0.3 s, sub pulse) followed by ducking the SFX bus -6 dB for 0.8 s and restoring pitch/time on exit.

3. Sounds Heard But Not Owned / Licensed-Source Audit

1. Source A
File count in pack record: 123 .ogg files (118 placed in audio/incoming/cc0/, 5 at project root)
Stated licence: CC0 / Public Domain
Concern: UNRESOLVED — Do not ship until resolved: pack.md's two ledgers disagree (FILE INVENTORY: 'License: CC0 / Public Domain (attribution in CREDITS.txt)'; LICENSING RISK: 'No license information recorded anywhere in the project — no CREDITS.txt, no per-file license field'). The pack does not state which is true.

2. Source B
File count in pack record: 103 .ogg files counted in the downloaded Freesound pack text file
Stated licence: 'Sounds in this pack are by various artists, with individual license: CC0 (public domain)' ; itemized by各種 CC0 contributors on Freesound / OpenGameArt (specifically rubberduck / 100 CC0 SFX contributors). Licence: CC0 1.0
Concern: Metadata/tag noise is not a licence risk: 5 direct matches later proven to be Kenney content re-hosted or re-tagged by third parties under CC0-sampling tags ('sci-fi', 'laser', 'zap', 'impact', 'futuristic'), 39 colour-of-noise files, 550+ generated variants of two explosion seeds in the 673-ZIP library, and 631 dirty joke/pun filenames in the SFX library. These are curation and deduplication noise, not licensing defects.

3. Source C
File count in pack record: 100 .ogg files retained in incoming (45 discarded outright as mouth-made)
Stated licence: CC BY 3.0
Concern: UNRESOLVED — The two action items from the candidate triage remain untested: (1) run the two A/B tests (foley-olive vs synth) before swapping any committed cue, and (2) confirm the qubodup CC BY 3.0 attribution wording. Ship only the retained 100 files' licence (CC BY 3.0, qubodup) exactly as attributed in the pack.

4. Bugs

[Critical] play_deferred drops stored group gain
Evidence: sfx.gd implements a deferred-group system (play_deferred) for simultaneous salvos to avoid machine-gunning. DEFECT: play_deferred currently drops the group's stored gain_db (always plays at 0.0), so defer_flak and four other deferred specs lose their authored levels, and defer_torpedo loses its -2.0 value.
Fix: Apply the stored gain_db to the deferred group playback or distribute it across child layers in sfx.gd.

[Critical] Capital destruction is not staged
Evidence: Capital kills fire one monolithic boom_cap cue (explosion_big, explosion_huge, boom_sub, ship_break, hull_groan, fire_roar, debris_field) all at once, while R72 stages capital death over 2.0 seconds (split at t=0, burn, final detonation at t=2.0), and battle.gd does not dispatch boom_cap per stage.
Fix: Split boom_cap into boom_cap_split, boom_cap_burn, and boom_cap_final cues in cues.json, and dispatch them at the corresponding stage timings from battle.gd.

[High] Boarding, brace and Nemesis adaptation have no audio path
Evidence: There are no cue ids in cues.json, no .ogg files, and no event dispatches from battle.gd or rules.gd for boarding actions, the brace order, or Nemesis adaptation. The audio system in sfx.gd has no dispatch point for these semantic events.
Fix: Define the new boarding suite (board_launch, board_grapple, board_breach, board_success, board_repelled), brace_order, and a Nemesis adaptation cue (adapt_shift: evolving tonal morph, rising dissonance resolving to a new timbre) in cues.json, and wire dispatches from battle.gd / rules.gd.

[High] Master mute floor defeats the slider
Evidence: In audio.gd, the master volume slider maps 0 to a floor of -12.0 dB rather than silence (-80.0 dB). This leaves audible bleed-through when the player drags the master slider to zero.
Fix: Map slider position 0 to -80.0 dB (or Server mute) in audio.gd, while preserving the -12.0 dB floor for intermediate mapping scaling if intended.

[High] No ducking or slow-motion audio hook for R73
Evidence: R73 introduced a 0.8-second slow-motion kill beat on player kills, but the audio system has no slowmo_kill cue, no pitch scaling, and no bus ducking hook tied to the slow-motion timer in sfx.gd or battle.gd.
Fix: Define slowmo_kill in cues.json, trigger it from battle.gd on an R73 player kill, pitch SFX playback down to 40% over 0.3s, duck the SFX bus by -6 dB for 0.8 s, and restore pitch/time on slow-motion exit.

[Medium] Small-ship kill runs and hulk kills fall back to generic audio
Evidence: Multiple rapid small-ship kills trigger discrete, overlapping instances of boom_small with no dedicated run cue. Destroying a drifting hulk dispatches either boom_small or no destruction cue at all, treating silent dead ships identically to live kills.
Fix: Define boom_run (triggered by 3+ small-ship kills within one second) and hulk_kill (quiet, no fire layers) in cues.json, and add the conditional dispatch logic in battle.gd.

[High] Live dispatch not evidenced for 11 cue ids
Evidence: NO-DISPATCH: In the pack record, 11 cue ids defined in cues.json have no visible trigger/dispatch in the provided code excerpts from battle.gd, rules.gd, or ui.gd: emp_pulse, rail_hit, hit_light, hit_sweep, shield_overcharge, overdrive, sensor_ping, pod_launch, plasma_hit, plasma_fire, tractor.
Fix: NO-DISPATCH — flag for owner confirmation whether these cues are triggered via data-driven tables or string lookups not included in the pack excerpts. Add explicit dispatch calls for any that are confirmed orphaned.

5. Music

The pack records 24 levelled music tracks, including menu, battle themes, and stingers. The following loudness targets and peaks were measured against the -16 LUFS integrated standard:

Category: Rapid Guns & Patter — Loudness-Target: -13.0 dB — Processing: Noise
Category: Lasers & Beams — Loudness-Target: -13.2 dB — Processing: None stated
Category: Explosions — Loudness-Target: -10.9 dB (-12.8 dB RMS) — Processing: Compressor 5.7 dB + limiter
Category: Braces & Powers — Loudness-Target: -11.5 dB — Processing: None stated
Category: Voice-Like — Loudness-Target: -15.7 dB — Processing: De-esser 7.8 dB + multi-band

Four additional tracks missed the -16 LUFS integrated levelling target and require the following specific gain adjustments to conform:

Track Value: -13.2 dB → -16 LUFS — Adjustment: -2.8 dB
Track Value: -12.5 dB → -16 LUFS — Adjustment: -3.5 dB
Track Value: -11.9 dB → -16 LUFS — Adjustment: -4.1 dB
Track Value: -16.0 dB → -16 LUFS — Adjustment: 0.0 dB

VO processing chain requirement: detune −506 cents then ring-modulate at 30 Hz (the pod's ring modulator is set to a frequency of 30 Hz with a sawtooth carrier) then band-pass 400–3400 Hz. Validation and artifacts: applying this chain to the 'biscuit' test word successfully rendered it unintelligible, which satisfies the requirement for scrambled comms effects. Structurally, synthesized audio must remain the default approach; using reversed speech and pitch-shifted speech is completely forbidden in comms processing. Audio must not pitch-stretch or time-stretch a human voice recording.

6. Build List

- cues.json: Define 9 new layered cue definitions: board_launch, board_grapple, board_breach, board_success, board_repelled, brace_order, adapt_shift, boom_run, hulk_kill, slowmo_kill, and stage splits boom_cap_split, boom_cap_burn, boom_cap_final.
- sfx.gd: Fix play_deferred to apply the deferred group's stored gain_db (e.g., -2.0 for defer_torpedo) to group playback.
- audio.gd: Fix the master volume slider mapping so a value of 0 yields -80.0 dB/silence instead of the -12.0 dB floor.
- battle.gd: Add event dispatches for boarding stage cues, staged capital destruction (split at t=0, detonation at t=2.0), the R73 slowmo_kill trigger, boom_run conditions (3+ kills < 1s), and hulk_kill.
- rules.gd: Add event dispatch for the brace_order cue upon a successful brace order resolution.
- cues.json / sfx.gd: Implement SFX bus ducking (-6 dB for 0.8 s) and pitch scaling to 40% over 0.3 s for the R73 slow-motion beat.
- Music Assets: Apply gain adjustments to the four quiet tracks to reach the -16 LUFS target: -2.8 dB, -3.5 dB, -4.1 dB, and 0.0 dB respectively.

7. Not Checked

- Whether the 11 NO-DISPATCH cue ids are triggered via mechanisms outside the pack excerpts.
- Playtesting verification of the deferred salvo machine-gunning perception in a live engine environment.
- Actual file system audit of CREDITS.txt existence and contents outside the conflicting pack ledgers.
- In-engine acoustic occlusion, distance attenuation curves, and bus routing configurations not present in the provided code.
