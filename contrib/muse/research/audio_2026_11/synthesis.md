# Battle sound synthesis: cues for the feel pass, and the fixes underneath

Chair synthesis of four legs (DeepSeek, Qwen, Argon, Rey) for Job 5 of the Nov 1, 2026 four-job commission. Grounding is the verified coverage work on main (coverage_gaps_verified.md) and the shipped cue system (godot/audio/cues.json, 57 cues; sfx.gd dispatch). Licence rule R40 throughout: CC0 or CC BY only, no NC, ND, or SA material. Nobody in this process has listened to any audio file; every sound description below is a design target, and every source is an audition candidate, not a verdict.

## Verdict

GO WITH CONDITIONS. Eleven new cue ids close every gap the feel pass opened, all of them buildable inside the existing layered cue system with no engine changes. Two code-level fixes ride along because the pack verified them: the salvo defer data that drops cue starts in dense volleys, and the volume-zero floor that is not silence. The Argon leg was screened out almost in full (section 6); the design below stands on the other three legs, which converge on nearly every point that matters.

## 1. The cue list (final)

Existing cues cover weapons, hits, shields, and turn markers well. What is missing is shape: deaths happen in one instant of sound while the visuals now stage them over time, and three tactical events are silent.

New cues:

1. ui_plan. A very quiet, dry click with a faint rising tick, about 0.12 seconds, like a plotting table locking a line. Fires when a move plan is confirmed and when a target is picked. Not on hover, not on Esc (ui_cancel covers that), never for enemy plans. Softer and shorter than ui_confirm, which stays for firing and end ship. (Rey. Qwen instead proposed a -3 dB gain override on ui_confirm; the chair takes the separate cue because plan confirm fires far more often than firing and needs its own voice cap. Vetoable, see section 7.)
2. death_powerdown. A falling pitch sweep, engine and hum dropping over about 0.6 seconds into near silence. Stage 1 of a staged capital death; big ships and flagships only.
3. death_vent. A thin hissing gas release, about 0.5 seconds, high and quiet. Stage 2, once, after power-down.
4. death_crack. A slow metal groan with one sharp crack inside it, about 0.4 seconds, pitch falling. Stage 3, at the thermal crack line. Glasswright kills layer the existing glass colour into the variant set, so their crack sounds like crystal splitting.
5. Stage 4 needs no new cue: the split takes the low end of boom_l, the one counted core flash takes bass_drop, and wreck follows delayed as the halves drift. sfx.gd already delays wreck at size 1.0 and up, and battle.gd already passes 1.2 for big ships; this is re-timing, not new material. Under reduce flashing there is no extra sting; the boom alone carries it.
6. death_run. A short, uneven sputter and whine, about 0.5 seconds, pitch wobbling down. Fires when a small ship's death run starts (the spin and lurch before the burst), and stops dead at the burst so boom_s ends it cleanly. Not for instant vapour kills where no run is shown.
7. chunk_cool. A very quiet ticking and cooling creak, about 1.5 seconds, fading, for the tumbling chunk that lingers after a small-ship burst. Once per chunk, low gain, first voice stolen when caps bite.
8. hulk_vent. No explosion at all: one soft gas vent, about 0.7 seconds, then a faint slow creak, total under 1.2 seconds, quieter than any boom. Fires when a kill resolves as a hulk (lights out, cold drift). Never alongside a boom, never with bass_drop. A silent death should sound like an absence.
9. arrive_jump. A compact arrival thump with a rising edge, about 0.45 seconds, closer to the existing phase cue than to ui_alert. Fires once per arriving reinforcement ship, player and enemy alike (enemy version pitched slightly lower), staggered when several arrive in one round. Retire ui_alert from this moment. Carrier wing launches keep using launch.
10. board_grapple. A heavy clamp and cable thud, then a short cutting hiss, about 0.7 seconds, low and physical. Fires once when a board action resolves, for player and enemy alike. The Chorus variant leans wet and fleshy, matching the hit_wet family. Never on target selection, at most twice per activation. This closes the verified gap at the board branch (battle.gd:1308 in the Godot scene numbering the pack cites), which today logs and flashes only.
11. brace_lock. A solid, low mechanical lock and settle, about 0.35 seconds, like armour plates seating. Fires once when the brace order is given, from the brace branch (battle.gd:1291, verified silent). Player and enemy alike. Not on expiry, not when a braced ship is hit.
12. adapt_shift. A cold, deliberate two-note shift, the second note a step off from where the ear expects it, about 0.6 seconds, quiet and forward in the mix. Fires once per battle when Nemesis adaptation is reported (rules.gd:1252, verified to have no cue). Not per round, not per hit.

That is 11 new ids (items 1 to 4 and 6 to 12, with item 5 a re-timing). DeepSeek's five-layer single-cue capital sequence and Qwen's five separate stage cues are both workable shapes; the chair follows Rey's three new stage cues plus re-timed existing layers because it matches how cues.json already expresses staged sounds and keeps the new-id count lowest.

Hand-over sounds need nothing: ui_your already fires only at the first hand-over of each round (explicit dispatch), and ui_enemy covers the enemy strip. DeepSeek's proposed ui_handover duplicates ui_your and is not adopted.

## 2. Sources (audition list, licences verified as marked)

Metal, clamps, groans, cooling (board_grapple, brace_lock, death_crack, chunk_cool): Kenney Impact Sounds (Kenney, CC0, kenney.nl); 75 CC0 Breaking / Falling / Hit SFX (rubberduck, CC0, OpenGameArt); 100 CC0 SFX (rubberduck, OpenGameArt), which DeepSeek verified includes metal and wood hits. Sci-Fi Sound Effects Library (Little Robot Sound Factory, CC BY 3.0, OpenGameArt) as the attributed option.
Power falls, gas, small engines, arrivals (death_powerdown, death_vent, death_run, hulk_vent, arrive_jump): Kenney Sci-Fi Sounds (Kenney, CC0); the same Little Robot Sound Factory library (CC BY 3.0); Glitterglass, Ship Creaking B (CC0, OpenGameArt, DeepSeek verified) for creaks; NenadSimic, Muffled Distant Explosion (CC0) as a hulk_vent base.
Interface and the adaptation shift (ui_plan, adapt_shift): Kenney Sci-Fi Sounds and Kenney Interface Sounds (CC0); unfa, Braam (CC0) as raw material for the two-note shift.
Flagged and not relied on: Qwen's leg named many Freesound and OpenGameArt files from memory and marked them unverified itself; treat any specific filename from that leg as a search hint, not a source. DeepSeek honestly flagged its own unverified items (two Pixabay files whose licences it could not confirm) and named one Envato file only to reject it, since Envato licensing sits outside R40's free-licence rule. Prefer the CC0 packs wherever the sound is equal, because of the credits debt in section 5.

## 3. The Hullbreaker track

The incumbent, fac_corsair.ogg ("Heavy battle music" by Davieplier, CC0), is defined in music.json but its audio file is absent from this snapshot, so nobody has heard it. The job is therefore an audition list, not a replacement verdict. The shape wanted (Rey): hunters who run silent and then strike. Long, low, sparse stretches with empty space, short violent swells that stop fast, room for battle cues on top, a loop point that never feels heroic, and nothing that sings or sounds noble.
Candidates: Perpetual Tension (Zander Noriega, CC BY 3.0, OpenGameArt; Rey's most promising pick for the quiet stretches); Laments of the War (Cethiel, CC0, OpenGameArt; DeepSeek verified); Fight Them Until We Can't (Zander Noriega, CC BY 3.0; may be all attack, no silence); Space Boss Battle Theme (Matthew Pablo, CC BY 3.0; may read as a boss track, not a faction track); Horde War Drums loop (WilliamHectorMusic, licence unverified, audition only if its licence checks out). Audition all five against the incumbent once its file is present. Any CC BY winner's credit goes through the music pipeline (tools/music/process.py); CREDITS.md is generated and must not be hand-edited.

## 4. Mixing note (final)

Salvo defer: the pack verified that dense salvos drop cue starts past the defer window (gun_sq gap .05 against defer .08; gun_shell gap .045 against defer .14), so later voices in a capped group never start. Fix in data first, per the Rey leg: raise each cue's defer window to at least its gap times the salvo group size it is capped at, or clamp the effective stagger so the last voice still lands inside its window. Adopt Qwen's form of the same fix as a validation rule in cues.json review: defer at least 2.5 times gap, checked for every gun cue. Add the test both legs asked for in different words: fire the largest legal salvo of each gun kind and count started voices against the cap. DeepSeek's one-slot defer queue with merge-by-gain is the fallback if the data fix alone still drops starts at 20 ships; do not build it first.
True mute: the pack verified that volume zero yields about minus 98 dB, not silence, at sfx.gd:97, while the music bus mutes properly. When the player sets volume to zero, set the SFX bus mute flag the way the music bus does. A player who chose silence should get silence.
Slow-motion beat (R73, big ships and flagships only): do not slow the audio with the picture; slowed booms turn to mud. Dip instead: duck music and ordinary battle cues briefly at the beat start using the existing duck field, let death_powerdown and death_crack play at normal speed inside the beat, and land bass_drop as the beat releases (Rey; Qwen's 6 dB bus dip with the core flash landing as speed returns is the same shape). DeepSeek's low-pass plus pitch dip is a colour option on top of the dip, not a substitute for it.
Restraint: loud deaths need the audio analogue of reduce flashing, and three legs converge on building one. Starting shape (Rey): cap simultaneous boom voices at one, drop bass_drop, replace boom_l with boom_m at lower gain, silence chunk_cool. Add DeepSeek's peak cap and high-frequency roll-off as tuning on the same setting. Whether it folds into the reduce flashing setting or ships as a sibling option is an owner call (section 7).
Voice caps at 20 ships: start from a global SFX ceiling near 20 simultaneous voices, with per-family caps of guns 6, hits 6, deaths 4, UI 3, actions 2, and the quiet new cues (chunk_cool, death_vent) stolen first. Qwen's tighter combat-bus 16 and Rey's looser 24 bracket the chair's 20; Opus tunes by ear with caps logging on.
Gains: death stage cues start near two thirds of boom_l gain, chunk_cool and hulk_vent near one third, board_grapple and brace_lock near hit_heavy, adapt_shift near ui_boss. Nothing new is louder than boom_l.

## 5. The credits surface (adjacent, but it gates CC BY)

The pack verified that eight CC BY music tracks have credit records and no in-game surface reads them. Every CC BY source above adds to that debt. Build the credits surface before or alongside this job's CC BY intake, or hold this job to CC0 material until it exists. The chair's recommendation: build the surface; it is small, and the music side already owes it.

## 6. Screening: the Argon leg

The Argon leg is filed as a record and was not relied on, beyond three intuitions the other legs establish with evidence (boarding, brace, and adaptation need cues; hulks should be quiet; the slow-mo beat needs a duck). The leg describes a different evidence pack than the one it was sent: it audits three unnamed sound sources with file counts (123, 103, 100 ogg files) and licence ledgers that do not exist in the real pack, names cue ids absent from the shipped cues.json (boom_cap, boom_small, defer_flak, emp_pulse, rail_hit, sensor_ping, and others), reports a deferred-group gain bug in terms the pack never raises (the verified salvo problem is stagger against defer windows, section 4), puts the mute floor in a different file at a different value (audio.gd at -12 dB, against the verified sfx.gd:97 at about -98 dB), and closes with loudness tables and a voice-processing chain (a detune and ring-modulator recipe validated on a test word) that belong to no part of this game. Its staged-capital timing also contradicts the Job 1 timings the pack carried (split first, then the core flash, not a two-second burn before detonation). Treat the whole leg as a caution about the model, not as input.

## 7. Owner calls

1. ui_plan as a new cue (chair) versus a gain override on ui_confirm (Qwen). Minor and vetoable either way.
2. The restraint setting for loud deaths: fold into reduce flashing, or a separate option next to it.
3. Whether the credits surface (section 5) lands before this job or with it.

## 8. Build list

1. cues.json: add the 11 new cue ids from section 1 in the existing style (layers, bus, gain, voice cap, stagger, defer), with the Chorus wet variant for board_grapple and the glass layer for death_crack.
2. battle.gd and rules events: dispatch brace_lock from the brace branch, board_grapple from the board branch, and adapt_shift from the adaptation report, following the verified gap item's smallest-fix shape (three ids, semantic dispatch).
3. battle.gd: re-time the staged capital death (power-down, vent, crack, split with boom_l and bass_drop, delayed wreck) and wire the slow-motion duck to the R73 beat for big ships and flagships only.
4. battle.gd: dispatch death_run and chunk_cool around boom_s for small ships, hulk_vent instead of any boom for hulk outcomes, and arrive_jump at reinforcement arrival; retire ui_alert from the arrival moment.
5. cues.json data fix: defer windows per the section 4 rule across the gun families, plus the largest-salvo voice-count test.
6. sfx.gd: true mute at volume zero, matching the music bus.
7. Settings: the restraint behaviour for loud deaths (section 4), per the owner's call in section 7.
8. Music: audition the five section 3 candidates against fac_corsair once its file is restored; route any CC BY winner's credit through tools/music/process.py.
9. Credits surface for CC BY material (section 5), sequenced per the owner's call.
10. Verification pass at 20 ships with caps logging: one full round plus a staged capital death, a hulk outcome, a boarding, a brace, a reinforcement arrival, and a Nemesis battle, confirming each new cue fires once, at its moment, and no salvo loses starts.

## Not checked

No audio was listened to by any leg or by the chair, including the shipped cues and the incumbent Hullbreaker track (whose file is absent from the snapshot). Source verification stops at pack and page level; individual files inside packs are un auditioned. Whether the data-only defer fix fully holds at the densest legal 20-ship salvo is asserted by two legs and untested until build step 5's test exists. Positional panning for death_vent was assumed by one leg and is not established in the shipped system.
