Headline

The battle soundscape is already structurally rich, with layered weapon cues, destruction tiers and a semantic dispatch system, but its weakest point is that the moments which communicate the most important state changes on the battlefield are the quietest: boarding, brace and Nemesis adaptation have no cue at all, and the staged death of a capital ship is currently a single simultaneous boom rather than a sequence that follows the destruction plan. The single most important gap is the three confirmed missing action cues, because they are not cosmetic gaps: they are the only audio the player receives for three rules-relevant actions, and without them the player must read the log to know what happened. Fixing those three cues, plus the staged death sequence and the salvo defer defect, would move the soundscape from "present" to "informative" without increasing how often the game shouts.

Cue list

Hand-over, player ship
Cue id: ui_handover (new, or existing ui_your for the first hand-over of a round).
Sound: a short, soft two-note rise, like a muted glass marimba struck once and allowed to ring for half a second, ending on a gentle upward glide. It should feel like a hand on the shoulder, not a fanfare. Duration about 0.5 to 0.7 seconds, pitch direction upward, low weight.
Firing rules: plays once per player hand-over. The existing ui_your already fires at the first hand-over of each round by explicit F1 call, and that behaviour should stay. ui_handover is for subsequent hand-overs in the same round, but it must be quieter than ui_your and must not repeat the round-opening motif. It must not play on enemy hand-overs.
Exists: partial. ui_your exists for the first hand-over; the softer repeat cue does not.

Plan confirm
Cue id: ui_plan_confirm (new, softer sibling of ui_confirm).
Sound: a single wooden click followed by a very short low resonance, like a piece of dense wood tapped on a table, lasting about 0.25 seconds. Pitch is neutral, weight is light. It should be clearly softer than the firing confirm so that planning and committing to fire are distinguishable at the far camera.
Firing rules: plays when a planned move ghost is confirmed by click or Enter, and when a target is picked. It must not play when a plan is dropped with Esc; ui_cancel covers that. It must not play on the same frame as a weapon cue, to avoid stacking.
Exists: ui_confirm and ui_select exist, but neither is a planning-specific softer confirm.

Fire
Cue id: existing family (gun_shell, gun_flak, gun_las, gun_plasma, gun_rail, gun_tracer, gun_spine, gun_needle, gun_glob, gun_sq, torp, lance, and their variants).
Sound: as designed per weapon kind; no new cue is needed.
Firing rules: unchanged, but the salvo defer defect must be fixed before dense volleys can be trusted. The cue must not be re-fired per projectile if the salvo group already covers the volley.
Exists: yes.

Hit by weight
Cue id: existing hit, hit_heavy, patter_hull, shield, patter_shield, shield_break.
Sound: no new cue is proposed. The open design question is whether light, medium and heavy hits read distinctly at the far camera. If they do not, the fix is a mixing and pitch-variant change inside the existing cues, not a new cue per weight.
Firing rules: unchanged.
Exists: yes.

Staged capital death
Cue id: death_capital_staged (new, with layers for power-down, vent, thermal crack, split and core flash).
Sound: a two-second sequence. First a descending electrical whine as running lights and engine glow die, about 0.6 seconds, pitch falling. Then a narrow hiss of venting gas along the future cut, about 0.4 seconds, high-frequency but quiet. Then a single sharp metallic crack, dry and close, about 0.1 seconds. Then a low structural groan as the hull splits into two capped halves, about 0.5 seconds. Finally one counted core flash inside one half: a short, bright, contained thump with a long low tail, about 0.4 seconds. The other half must drift in silence after the flash.
Firing rules: fires only on capital and flagship deaths. It must be dispatched at the start of the staged death, not at the burst. It must not fire on small ships or hulks. It must not use boom_l, bass_drop or wreck as simultaneous layers; those existing layers are for the old one-shot death and should be retired for capital ships.
Exists: no. The current audio is boom_l plus bass_drop plus delayed wreck, all fired at once.

Small-ship death
Cue id: death_small_staged (new, with layers for death run, burst and lingering chunk).
Sound: about half a second of a thin, descending airy whoosh with a faint rattle, like a spinning object losing control. Then the burst: one counted flash, a short dry pop with a low thump, no long tail. Then a tumbling chunk that lingers for seconds: a slow, irregular metallic scrape with a cooling ember crackle, very quiet, ending in near silence.
Firing rules: fires on small-ship deaths only. It must not fire on capital ships. The burst layer may reuse the existing boom_s sample inside the new cue, but the death run and chunk must be new layers. It must not fire on hulk outcomes.
Exists: partial. boom_s exists for the burst; the death run and lingering chunk are silent today.

Hulk outcome
Cue id: death_hulk (new).
Sound: no explosion. A single soft gas vent, like a pressure valve releasing for about 0.6 seconds, followed by a very low, slowly fading hum as the ship goes cold. The hum should be felt more than heard, and it should fade to nothing over two seconds. No bright transient, no crack, no flash.
Firing rules: fires only when a kill is resolved as a hulk. It must not fire on exploding deaths. It should be quieter than any explosion cue and should not trigger the reduce-flashing loudness restraint, because it is already restrained.
Exists: no.

Reinforcement arrival
Cue id: reinforce_arrival (new, distinct from ui_alert and launch).
Sound: a single distant horn-like call with a short rising tail, like a ship's horn heard across water, followed by a brief low confirmation pulse. Duration about 1.2 seconds, medium weight, pitch rising then settling. It should feel like an arrival, not an alarm.
Firing rules: fires once per reinforcement arrival, at the banner flash. It must not fire for ordinary launches or for enemy turn banners. It must not stack with ui_alert; if ui_alert fires for the same banner, the reinforcement cue replaces it for that event.
Exists: no distinct arrival cue is established in the pack; ui_alert and launch are adjacent but not the same moment.

Enemy turn start
Cue id: existing ui_enemy, with a new ui_enemy_banner for the once-per-round big banner.
Sound: ui_enemy is the violet strip marker and should stay short and dry. ui_enemy_banner is a slightly larger, low brass swell, about 0.8 seconds, dark and deliberate, not aggressive. It should signal that the enemy is about to act without sounding like a warning klaxon.
Firing rules: ui_enemy plays on the strip; ui_enemy_banner plays once per round when the big Enemy turn banner appears. Neither should play on player hand-overs.
Exists: ui_enemy exists; the banner cue is new.

Boarding
Cue id: action_board (new).
Sound: a hard metallic impact followed by a short, taut cable or chain snap, then a brief scuffle of low thumps. Duration about 0.9 seconds. The impact should be mid-weight, not explosive; the chain snap should be bright and narrow. The overall impression is a grapnel hitting the hull and locking.
Firing rules: fires from the board branch in battle.gd when boarding is resolved, for both player and enemy boardings. It must not fire for ordinary hits or rams. It should have a once-per-event guard so a single boarding action cannot double-fire.
Exists: no.

Brace
Cue id: action_brace (new).
Sound: a low, short metal stress groan followed by a soft settling thud, like a bulkhead taking load. Duration about 0.7 seconds, pitch falling slightly, weight medium-low. It should sound defensive, not painful.
Firing rules: fires from the brace order branch when the order is issued. It must not fire when damage is applied; brace is an order, not an impact. It should not fire for enemy braces unless the enemy brace is visible to the player.
Exists: no.

Nemesis adaptation
Cue id: nemesis_adapt (new).
Sound: a deep, slow two-note interval, like a low bowed string or a processed horn, with a faint rising overtone. Duration about 1.5 seconds, pitch rising across the interval. It should feel like something is learning, not like a generic alarm. A short, quiet mechanical click at the end can mark the adaptation completing.
Firing rules: fires once at battle setup when adaptation is reported, and again only if adaptation changes mid-battle and that change is surfaced to the player. It must not fire on ordinary enemy turn starts or on boss music changes. It must not repeat every round.
Exists: no.

Sources

The sources below are candidates for audition, not verdicts. All licences are CC0 or CC BY as required by R40. Where I could not verify a file's existence or licence from the page, I say so plainly.

Boarding (action_board)

"Grappling hook" by 16bitstudios, Freesound. CC0 1.0. Page: https://freesound.org/people/16bitstudios/sounds/541975/. Verified as CC0 in a public attribution record. The page itself is a real Freesound page; the file is a short grapple shot, useful as the chain-snap layer.

"100 CC0 metal and wood SFX" by rubberduck (Kenney-adjacent pack on OpenGameArt), CC0 1.0. Page: https://opengameart.org/content/100-cc0-metal-and-wood-sfx. Verified as a CC0 pack containing metal hits, slams and cracks. Useful for the hull impact layer.

"Metal Impact" variations from Kenney's Impact Sounds pack, CC0 1.0. Page: https://kenney.nl/assets/impact-sounds. Verified as CC0 and containing impactMetal_light and similar files. Useful for the initial thud.

Brace (action_brace)

"Ship Creaking B" by Glitterglass, Freesound. CC0 1.0. Page: https://freesound.org/people/Glitterglass/sounds/320306/. Verified as CC0 on a mirror page. The original Freesound page is real; the sound is a ship creak, useful as the stress groan.

"Submarine creaking" from the OpenGameArt CC0 submarine pack. CC0 1.0. Page: https://opengameart.org/content/submarine. Verified as a CC0 pack containing submarine hull creaks. Useful as the low structural layer.

"100 CC0 metal and wood SFX" by rubberduck. CC0 1.0. Page: https://opengameart.org/content/100-cc0-metal-and-wood-sfx. Useful for the settling thud.

Nemesis adaptation (nemesis_adapt)

"Braam" by unfa, Freesound. CC0 1.0. Page: https://freesound.org/s/647712/. Verified as CC0 in the Freesound braam tag page. Useful as the low two-note foundation.

"Sirens and Alarm Noise" by aquinn, OpenGameArt. CC0 1.0. Page: https://opengameart.org/content/sirens-and-alarm-noise. Verified as CC0 and containing siren.mp3. Useful for a filtered, distant alarm layer if the braam alone is too musical.

"Sci-Fi Alarm" search results include CC0 synthesised alarm files on Freesound, but I could not verify a specific file name and licence from the search results alone. Treat this as a category to audition rather than a verified file. The category is real; the individual file is unverified.

Hulk (death_hulk)

"Submarine creaking" from the OpenGameArt CC0 submarine pack. CC0 1.0. Page: https://opengameart.org/content/submarine. Useful as the cold, low hum after the vent.

"Ship Creaking B" by Glitterglass. CC0 1.0. Page: https://freesound.org/people/Glitterglass/sounds/320306/. Useful as a very quiet residual groan, heavily low-passed.

"Muffled Distant Explosion" by NenadSimic, OpenGameArt. CC0 1.0. Page: https://opengameart.org/content/muffled-distant-explosion. Verified as CC0. Despite the name, the file is a low log-drum hit with reverberation; pitched down and filtered it can serve as the cold drift layer, not as an explosion.

Small-ship death (death_small_staged)

"Swishes Sound Pack" on OpenGameArt, CC0 1.0. Page: https://opengameart.org/content/swishes-sound-pack. Verified as CC0 and containing whoosh and swish files. Useful as the death-run layer.

"100 CC0 metal and wood SFX" by rubberduck. CC0 1.0. Page: https://opengameart.org/content/100-cc0-metal-and-wood-sfx. Useful for the tumbling chunk scrape.

"75 CC0 breaking / falling / hit sfx" on OpenGameArt, CC0 1.0. Page: https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx. Verified as a CC0 pack containing breaking and hit sounds. Useful for the burst transient if boom_s is not reused.

Capital staged death (death_capital_staged)

"Power Down" by SoundReality, Pixabay. The Pixabay page states free use, but the licence text on the page is not fully visible in the search result. Treat as unverified until the licence is confirmed on the page. Page: https://pixabay.com/sound-effects/power-down-142831/. The category is right, but do not route it through the pipeline until the licence is checked.

"Metal Stress and Creak" is an Envato Elements file, not a free source. Do not use it. The free alternative is "Ship Creaking B" by Glitterglass, CC0, page above, for the structural groan.

"Muffled Distant Explosion" by NenadSimic, CC0, page above, for the counted core flash tail. Its low, reverberant character is closer to a contained core thump than a standard explosion.

"100 CC0 metal and wood SFX" by rubberduck, CC0, page above, for the thermal crack and split transient.

Reinforcement arrival (reinforce_arrival)

"Ship horn" by monotraum, Freesound. The search result shows a ship horn on Pixabay with a Freesound source, but the licence is not fully visible. Treat the exact file as unverified. Page: https://pixabay.com/sound-effects/ship-horn-7053/. The category is real; confirm the licence before use.

"Braam" by unfa, Freesound. CC0 1.0. Page: https://freesound.org/s/647712/. Useful as the low confirmation pulse after the horn, if the horn is too nautical for the setting.

"Sirens and Alarm Noise" by aquinn, OpenGameArt, CC0 1.0. Page above. A single siren layer, pitched down and shortened, can serve as the arrival call if a horn is not used.

Plan confirm and hand-over (ui_plan_confirm, ui_handover)
These are quiet UI cues. The best sources are not large sound libraries but the existing synthesised UI family. If new samples are required, use the Kenney UI Audio pack, CC0 1.0, page: https://kenney.nl/assets/ui-audio. Verified as a CC0 UI pack. For a softer plan confirm, filter a Kenney click with a low-pass and shorten the tail. For the hand-over, use a single Kenney confirmation tone pitched up and shortened. No third-party source is necessary for these two cues.

Hullbreaker track

The Hullbreaker faction track must do three things at once. First, it must sound like pack violence rather than state violence: irregular, percussive, low, and built around sudden strikes rather than a continuous march. Second, it must leave space for the soundscape. The Hullbreakers run dark and silent until they strike, so the track must not fill the low-mid range continuously; it should have holes that weapon and impact cues can occupy. Third, it must be distinguishable from the Hegemony and Eclipse tracks without relying on a different genre. The same orchestral palette is fine, but the rhythm and the low-end behaviour must be different: more tribal percussion, less sustained brass, more sudden stops.

The incumbent fac_corsair is an orchestral heavy battle piece (Davieplier, CC0 1.0), but the Ogg file is absent from this snapshot and nobody in this process has heard it. The candidates below are therefore auditions against an unheard incumbent, not verdicts.

Candidate 1: "Laments of the War" by Cethiel, CC0 1.0. Page: https://opengameart.org/content/laments-of-the-war. It is a 3:48 orchestral war piece with prominent drums and choir. It fits the "heavy battle" brief, and its CC0 licence is verified. The risk is that it may be too continuously epic; if it fills the low-mid range, it will fight the soundscape rather than support it.

Candidate 2: "Horde War Drums loop" by WilliamHectorMusic, OpenGameArt. The page describes a 130 BPM epic drum loop. The licence is not visible on the opened page, so treat the licence as unverified until confirmed. If it is CC0 or CC BY, it is the closest match to the tribal, percussive identity. It is a loop rather than a full track, so it would need arrangement and an ending.

Candidate 3: "The Fallen" by Tsorthan Grove and collaborators, CC BY 3.0. Page: https://opengameart.org/content/the-fallen-rpg-orchestral-essentials-defeated-music. It is dark orchestral music with strings and electronics. It is less tribal than the Hullbreaker brief, but it may fit the "alien void hunter" tone better than a conventional war march. CC BY 3.0 is allowed by R40, but the attribution line must be added to the credits pipeline.

Mixing note

Buses and gains. Put the three new action cues on the existing combat bus, not the UI bus. action_board and action_brace should sit at about the same gain as hit and hit_heavy, because they are battlefield actions, not interface events. nemesis_adapt should sit slightly lower, around the gain of ui_boss, because it is a setup cue and must not overpower the first weapon exchange. Put death_capital_staged and death_small_staged on the destruction bus at the same gain as the current boom family. Put death_hulk at about 6 dB below the boom family, because it is a quiet outcome and should feel like a relief from noise, not a larger event. reinforce_arrival and ui_enemy_banner can share the UI bus at the gain of ui_alert. ui_handover and ui_plan_confirm should be 3 to 4 dB below ui_confirm so they do not nag.

Salvo defer fix. The defect is that dense salvos drop cue starts when the stagger exceeds the defer window: gun_sq has gap .05 and defer .08, and gun_shell has gap .045 and defer .14. The clean fix is not to widen the defer window indefinitely, because that increases latency. Instead, add a small per-cue queue in sfx.gd: when a cue is deferred and the defer window is full, place the request in a one-slot queue with a timestamp. If the queue already holds the same cue within the same salvo group, merge the request into the existing one by raising its gain slightly rather than firing a new voice. If the queue is empty, play the deferred cue as soon as the next slot opens. This preserves the stagger, prevents dropped starts, and keeps the voice count bounded. The max field in each cue should also be checked against the salvo group, not just the cue id.

Volume-zero floor. The master gain floor at sfx.gd:97 means volume zero yields about minus 98 dB rather than a true mute. That is close enough to inaudible in most playback systems, but it is not a true mute and it will still produce a signal in a captured mix. The fix is to add an explicit mute branch: when the volume scalar is zero, set the bus volume to negative infinity or skip playback entirely. Music already mutes its own bus properly, so the SFX path should match that behaviour.

Slow-motion beat. R73 applies a brief slow-motion beat on kills for big ships and flagships only. Audio should not fully slow down with the simulation, because a full pitch-and-speed drop sounds like a tape machine and breaks the diegetic frame. Instead, apply a low-pass filter that closes to about 800 Hz over 150 ms, a pitch dip of about 2 semitones, and a 3 dB gain dip, then recover over the remaining slow-motion window. The core flash should be the only bright transient during the beat; the vent and crack should be filtered. When the slow-motion ends, the filter should open quickly but not instantly, over about 80 ms, so the return to normal speed does not click.

Reduce-flashing audio analogue. The game already limits counted flashes to 3 per second and disables them under reduce-flashing. The audio analogue should not be a global volume reduction, because that would make the game harder to read. Instead, under reduce-flashing, cap the peak gain of death and explosion cues at about 70 percent of normal, roll off high frequencies above 6 kHz by 4 dB, and suppress the bright transient layer in death_capital_staged and death_small_staged. The low layers remain, so the event is still audible, but the startle response is reduced. This matches the spirit of the flash budget without removing information.

Voice caps. A 20-ship battle can easily request more voices than the mix can support. Set per-family caps as follows: weapon fire 6, impacts 8, destruction 4, UI 3, action cues 2. Set a global SFX cap of 16 simultaneous voices with a 50 ms fade-out on stolen voices. The existing max field should be enforced per cue, and the salvo group should count as one voice per group rather than one voice per projectile. This keeps the mix intelligible and prevents a dense turn from turning into a wash.

Build list

Add the new cue ids to godot/audio/cues.json: ui_handover, ui_plan_confirm, death_capital_staged, death_small_staged, death_hulk, reinforce_arrival, ui_enemy_banner, action_board, action_brace, nemesis_adapt. For each, set bus, gain, max, stagger gap, defer window, pitch and speed jitter, and the layers array. Do not add new cue keys for fire or hit; use the existing families.

Create the new synthesized variant files under the audio pipeline. For death_capital_staged and death_small_staged, create one variant file per layer and let the layers field assemble them. For action_board, action_brace and nemesis_adapt, create two variants each so the jitter has material to work with.

Route the candidate source files through the SFX pipeline. For each candidate in section 3 that passes licence verification, trim, normalise to the existing loudness target, and export to Ogg. For candidates marked unverified, do not route them until the licence is confirmed on the source page.

Dispatch action_board from the board branch in battle.gd (currently around line 1308), guarded by a once-per-event flag.

Dispatch action_brace from the brace order branch in battle.gd (currently around line 1291), on order issuance, not on damage resolution.

Dispatch nemesis_adapt from the adaptation event in rules.gd (currently around line 1252) and from any mid-battle adaptation change event. Add a once-per-battle guard unless the adaptation is explicitly surfaced again.

Replace the capital death dispatch: stop firing boom_l, bass_drop and wreck simultaneously for capital ships. Fire death_capital_staged at the start of the staged death and let its layers follow the two-second timeline. Keep boom_l for non-capital large ships if needed.

Replace the small-ship death dispatch: fire death_small_staged instead of boom_s alone. Reuse the boom_s sample as the burst layer inside the new cue if desired, but do not fire boom_s as a separate cue.

Dispatch death_hulk from the hulk outcome branch. It must be mutually exclusive with the exploding death branches.

Dispatch reinforce_arrival from the reinforcement arrival event at the banner flash. Suppress ui_alert for that event to avoid stacking.

Dispatch ui_enemy_banner once per round at the big enemy turn banner. Keep ui_enemy on the violet strip.

Add ui_handover to the hand-over event for repeated hand-overs in the same round. Keep the existing ui_your call for the first hand-over of each round.

Add ui_plan_confirm to the plan confirmation and target-pick events. Do not change the ui_cancel path.

Implement the salvo defer queue in sfx.gd and apply it to gun_sq and gun_shell first, then to the other salvo groups.

Implement the true-mute branch at sfx.gd:97 for the master gain floor.

Implement the slow-motion audio treatment: low-pass, pitch dip and gain dip on the destruction bus, triggered by the same condition that triggers R73.

Implement the reduce-flashing audio restraint: peak gain cap, high-frequency roll-off, and transient suppression on the destruction bus when reduce-flashing is on.

Set the per-family and global voice caps in sfx.gd. Test with a scripted 20-ship battle and measure dropped cues and peak voice count.

Add any CC BY attribution lines from the chosen sources to the credits pipeline. Do not hand-edit CREDITS.md; route attribution through the existing music and SFX credit records.

Audition the three Hullbreaker candidates against the incumbent in a controlled A/B with the same battle scene. Because the incumbent file is absent, first restore or locate fac_corsair before making a replacement decision.

Not checked

I could not listen to any audio in this process. All judgements about how a cue sounds are design intentions, not audited perceptions.

I could not hear the incumbent fac_corsair track because the Ogg file is absent from the snapshot. The Hullbreaker candidate comparison is therefore against an unheard incumbent, and the final fit decision cannot be made from this report alone.

I could not verify the licence of "Horde War Drums loop" by WilliamHectorMusic from the opened page. The page describes the file but does not show a licence in the visible text. Treat it as a candidate only after the licence is confirmed.

I could not verify a specific CC0 "ship horn" file for reinforcement arrival. The search results show ship horn categories and mirrors, but the exact file name and licence were not confirmed on the source page. The category is real; the specific file is unverified.

I did not inspect the full cues.json schema, so the new cue entries assume the existing fields (bus, gain, max, layers, salvo, jitter and defer fields) are sufficient. If the schema requires additional fields for staged playback, the implementer will need to extend it.

I did not test the salvo defer queue or the true-mute branch in the engine. The recommendations are based on the code description in the pack, not on runtime profiling.

I did not verify whether boarding and brace are visible to the enemy in all cases. The firing rules assume the player sees the enemy action when the enemy board or brace is dispatched; if the enemy action is hidden, the cue should be suppressed for that side.
