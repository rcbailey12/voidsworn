# Battle sound: Rey leg

## 1. Headline

The weapon and hit families are already broad, so this job is mostly timing and restraint. The single most important gap is that death has no shape in sound: a capital ship dies in one instant boom, and a small ship and a hulk are almost as flat, even though the feel pass now stages those deaths over time. Close behind it, boarding, brace, and Nemesis adaptation are completely silent (pack section 2, item 12).

## 2. Cue list

**Hand-over, player. Cue: ui_your, exists.** Sound: a short, warm, low tone, about 0.3 seconds, like a soft brass note through a console speaker. Fires only at the first hand-over of each round, as F1 already does. It must not fire on later hand-overs in the same round, during enemy activations, or while a death sequence is playing. No faction difference.

**Hand-over, enemy, and enemy turn start. Cue: ui_enemy, exists.** Sound: a cooler, lower tone, about 0.35 seconds, pitch falling a step, distinct from ui_your by colour, not loudness. Fires once per round at the enemy strip and once at the big Enemy turn banner if both occur in the same round, the banner wins and the strip stays silent. It must not fire per enemy ship.

**Plan confirm. Cue: ui_plan, new.** Sound: a very quiet, dry click with a faint rising tick, about 0.12 seconds, like a plotting table locking a line. Softer and shorter than ui_confirm, which stays for firing and end ship. Fires when a move ghost is confirmed and when a target is picked. It must not fire on hover, on every hex stepped through, on Esc (ui_cancel covers that), or for enemy plans, which the player never sees. A 0.15 second retrigger lock stops double clicks stacking.

**Fire. Cues: gun, torp and lance families, exist.** Sound: as shipped, one cue per weapon kind with salvo grouping. No new fire cue is proposed; the fix is in the mixing note, where dense volleys must not lose cue starts to the defer window. Fires per salvo group, not per gun, and no faction gets a second layered fire cue.

**Hit, light, medium and heavy. Cues: hit, hit_heavy, patter_hull, exist.** Sound: light hits are a short metallic tap, medium hits add body, heavy hits carry a low thud under the clang. At the far camera light and medium may merge, so push hit_heavy down in pitch rather than up in gain, and let patter_hull stay the only cue for repeated small impacts. Fires per impact group with the existing voice caps. It must not fire for a miss, and shield hits must never use patter_hull.

**Shield ripple and shield break. Cues: shield, patter_shield, shield_break, exist.** Sound: as shipped. One new rule: shield_break fires at most once per ship per activation, even in one salvo, because breaks are information, not texture. Eclipse ships have no shields and must never trigger any of these.

**Staged capital death, stage 1, power-down. Cue: death_powerdown, new.** Sound: a falling pitch sweep, engine and hum dropping over about 0.6 seconds, ending in near silence, like a large generator spinning down. Fires at the start of the staged death, big ships and flagships only. It must not fire for small ships, for hulks (they get their own cue below), or under the slow-motion beat a second time.

**Staged capital death, stage 2, venting. Cue: death_vent, new.** Sound: a thin, hissing gas release, about 0.5 seconds, high and quiet, panning slightly along the future cut if the engine supports it. Fires once, after power-down and before the crack. It must not loop, and it must not fire if the ship died to a ramming kill where the plan skips venting.

**Staged capital death, stage 3, crack. Cue: death_crack, new.** Sound: a slow metal groan with one sharp crack inside it, about 0.4 seconds, pitch falling, like a hull beam giving way under load. Fires once at the thermal crack line. For Glasswright ships, layer hit_glass colour into the variant set so the crack sounds like crystal splitting, which the layers field can do without a second cue.

**Staged capital death, stage 4, split and core flash. Cues: boom_l, bass_drop, wreck, exist, re-timed.** Sound: as shipped, but spread across the split instead of fired at once. The split itself takes the low end of boom_l, the counted core flash takes bass_drop inside one half, and wreck follows delayed as the halves drift, as sfx.gd already delays it for size 1.0 and up. Fires once per capital death. Under reduce flashing, the core flash has no extra audio sting; the boom alone carries it.

**Small-ship death run. Cue: death_run, new.** Sound: a short, uneven sputter and whine, about 0.5 seconds, pitch wobbling down, like a small engine tearing itself apart. Fires when the death run starts, small ships only. It must not fire if the ship is vapourised instantly by a heavy hit with no run shown, and it must stop dead at the burst so boom_s gives a clean ending.

**Small-ship burst and lingering chunk. Cues: boom_s, exists, and chunk_cool, new.** Sound: boom_s as shipped. Then chunk_cool: a very quiet ticking and cooling creak, about 1.5 seconds, fading, like hot metal contracting. Fires once per lingering chunk, at low gain, only if the chunk stays on screen, never per debris piece, and it is one of the first voices dropped when caps are hit.

**Hulk outcome. Cue: hulk_vent, new.** Sound: no explosion at all. One soft gas vent, about 0.7 seconds, then a faint, slow creak, total under 1.2 seconds, quieter than any boom. Fires once when a kill is resolved as a hulk: lights out, one vent, cold drift. It must not fire alongside any boom cue for the same ship, and it must not use bass_drop. A silent death should sound like an absence.

**Reinforcement arrival. Cue: arrive_jump, new.** Sound: a compact arrival thump with a rising edge, about 0.45 seconds, like air and light arriving in a space that was empty, closer to the existing phase cue than to ui_alert. Fires once per arriving ship at the banner and flash, player and enemy alike, with the enemy version pitched slightly lower. It must not fire for carrier wing launches (launch covers that), and same-round arrivals are staggered, not stacked. Retire ui_alert from this moment if arrive_jump lands.

**Boarding. Cue: board_grapple, new.** Sound: a heavy clamp and cable thud, then a short cutting hiss, about 0.7 seconds, low and physical, like a docking claw biting and a torch starting. For Chorus boarding, the variant set leans wet and fleshy, using the same family colour as hit_wet, because tendrils are not clamps. Fires once when a board action resolves, for player and enemy alike, because a generic UI confirmation does not cover enemy actions. Never on target selection, and at most twice per activation.

**Brace. Cue: brace_lock, new.** Sound: a solid, low mechanical lock and settle, about 0.35 seconds, pitch level, like armour plates seating and a ship hunkering behind them. Fires once when the brace order is given, dispatched from the brace order branch (battle.gd:1291 in the pack, confirmed silent in code), for player and enemy ships alike. It must not fire when brace expires, when a braced ship is hit (hit cues cover that), or more than once per ship per round.

**Nemesis adaptation. Cue: adapt_shift, new.** Sound: a cold, deliberate two-note shift, the second note a step off from where the ear expects it, about 0.6 seconds, quiet and unsettling rather than loud, like a machine changing its mind. Fires once per battle at setup when adaptation is reported (rules.gd:1252 in the pack), and once more only if a mid-battle adaptation event is ever added. It must not fire per round, per hit, or for ordinary enemy ships. Because it fires once, it can sit slightly forward in the mix.

## 3. Sources

All licences below are CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/) or CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), inside rule R40. CC BY attribution goes into the credits records.

For board_grapple, brace_lock, death_crack and chunk_cool (metal, clamps, groans, cooling metal): Kenney Impact Sounds, Kenney, CC0, page https://kenney.nl/assets/impact-sounds (verified: the pack and its CC0 status are described in search results and cited with this exact page link in third party credits); 75 CC0 breaking / falling / hit sfx, rubberduck, CC0, page https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx (verified: title, author and CC0 status confirmed in third party credits quoting this page); Sci-Fi Sound Effects Library, Little Robot Sound Factory, CC BY 3.0, page https://opengameart.org/content/sci-fi-sound-effects-library (verified: title, author and CC BY 3.0 licence confirmed in third party credits quoting this page; attribution required).

For death_powerdown, death_vent, death_run, hulk_vent and arrive_jump (power falls, gas, small engines, arrival): Kenney Sci-Fi Sounds, Kenney, CC0, page https://www.kenney.nl/assets/sci-fi-sounds (verified: pack name and this page link appear in third party credits, and Kenney audio packs are CC0); Sci-Fi Sound Effects Library, Little Robot Sound Factory, CC BY 3.0, page as above; 150 Game Sound Effects, a CC0 compilation on OpenGameArt, page https://opengameart.org/node/195932 (verified as a search result: 23 explosion and destruction sounds and a CC0 compilation notice; the individual file inside the pack that fits each cue is unverified and must be picked by ear at audition).

For ui_plan and adapt_shift (soft lock clicks and a cold two-note shift): Kenney Sci-Fi Sounds, Kenney, CC0, page as above, for the clean interface tones; Sci-Fi Sound Effects Library, Little Robot Sound Factory, CC BY 3.0, page as above; Kenney Interface Sounds, Kenney, CC0, page unverified: the pack itself is well attested in search results as a 100 sound interface pack, but I could not verify the exact kenney.nl page link in this pass, so treat the page link as unverified and confirm it before download.

## 4. Hullbreaker track

What the track must do: sound like hunters who run silent and then strike, not like a standing navy in parade formation. In practice: long, low, sparse stretches on drums, low strings or synth pulse and empty space, short violent swells that arrive fast and stop, room for battle cues on top, and a loop point that never feels heroic. It should never sing, chant, or sound noble.

Candidates to audition against the incumbent: Fight Them Until We Can't, Zander Noriega, CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/), page https://opengameart.org/content/fight-them-until-we-cant (verified: title, author and CC BY 3.0 licence confirmed in third party credits); it may fit the strike half but risks being all attack with no silence. Space Boss Battle Theme, Matthew Pablo, CC BY 3.0, page https://opengameart.org/content/space-boss-battle-theme (verified: title, author and CC BY 3.0 licence confirmed in third party credits); worth testing for weight, though it may read as a boss track rather than a faction track. Perpetual Tension, Zander Noriega, CC BY 3.0, page https://opengameart.org/content/perpetual-tension (verified on the same credits evidence as the first candidate); the name alone matches the stalking half of the brief, and it is the most promising of the three for the quiet stretches.

The caveat: the incumbent, fac_corsair, credited as Heavy battle music by Davieplier, CC0 1.0, is defined in music.json but its Ogg file is absent from this snapshot, and nobody in this process has heard it. These are auditions, not verdicts. If the incumbent already does this shape well, keep it.

## 5. Mixing note

Buses and gains: put board_grapple, brace_lock and the four death stage cues on the same category bus family as the hit and boom cues, so the existing bus reverb treats them as world sounds, not interface. Keep ui_plan and adapt_shift on the UI bus. Start gains low: death_powerdown, death_vent and death_crack at about two thirds of boom_l gain, chunk_cool and hulk_vent at about one third, brace_lock and board_grapple near hit_heavy, adapt_shift near ui_boss. Nothing new should be louder than boom_l.

Salvo defer fix: the pack confirms cue starts drop when stagger exceeds the defer window, with gun_sq at gap .05 and defer .08 and gun_shell at .045 and .14 as the named cases (sfx.gd behaviour, pack section 2). Fix the data, not the code shape: raise each defer window to at least the gap times the salvo group size the cue is capped at, or clamp the effective stagger so the last voice in a group still lands inside its defer window. Then add a simple test: fire the largest legal salvo of each gun kind and count started voices against the cap.

Volume-zero floor: the pack confirms volume zero yields about minus 98 dB, not silence, at sfx.gd:97, while music mutes its own bus properly. Treat true mute as a correctness fix: when the player sets volume to zero, set the SFX bus mute flag the way the music bus does, rather than relying on the gain floor. A player who chose silence should get silence, especially in a game with this many booms.

Slow-motion beat: under the R73 beat for big ships and flagships only, do not slow the audio down with the picture. Slowed booms turn to mud and fight the music. Instead, dip: duck music and ordinary battle cues briefly at the beat start using the existing duck field, let death_powerdown and death_crack play at normal speed inside the beat, and land bass_drop as the beat releases. One dip per death, never per kill for small ships, because small ships get no beat.

Restraint setting: yes, loud deaths need an audio analogue to reduce flashing. Add a reduce intensity option, or fold it into the same setting, that caps simultaneous boom voices at one, drops bass_drop, replaces boom_l with boom_m at lower gain, and silences chunk_cool. Flashing and loudness hit some players the same way, and the flash budget already accepts the principle: no more than three counted flashes per second, and none under the restraint setting. Sound should accept the same discipline.

Voice caps at 20 ships: keep total simultaneous SFX voices at or below about 24. Suggested caps: guns 6 per kind group, hits 6, patter 2, booms 2 (1 under restraint), death stage cues 3, UI 2, with the new quiet cues stolen first when a cap is hit. Priority: adaptation and brace first, booms second, texture last.

Credits note: pack item 3 confirms eight CC BY music tracks have credit records and no in-game surface reads them. The CC BY sources here add to that debt, so build that credits surface before adding more CC BY material, or prefer the CC0 packs where the sound is equal.

## 6. Build list

1. Add the nine new cue entries to godot/audio/cues.json in the existing style: ui_plan, death_powerdown, death_vent, death_crack, death_run, chunk_cool, hulk_vent, arrive_jump, board_grapple, brace_lock, adapt_shift. ui_plan and adapt_shift sit on the UI bus, the rest on world buses.
2. Synthesise or cut four variants per new cue through the existing pipeline, using the section 3 sources as audition material, with the Chorus wet variant for board_grapple and the glass variant layer for death_crack.
3. Dispatch brace_lock from the brace order branch in battle.gd, board_grapple from the board branch, and adapt_shift from an explicit adaptation event at battle setup in the rules events, following the semantic dispatch the pack describes.
4. Dispatch arrive_jump at reinforcement arrival and retire ui_alert from that moment.
5. Re-time the capital death in battle.gd and sfx.gd: power-down, vent, crack, split, then bass_drop and delayed wreck, with the slow-motion duck wired to the R73 beat for big ships and flagships only.
6. Dispatch death_run and chunk_cool around boom_s for small ships, and hulk_vent instead of any boom for hulk outcomes.
7. Fix the salvo defer data for gun_sq and gun_shell and add the voice-count salvo test.
8. Fix the volume-zero floor so SFX mute matches the music bus.
9. Add the restraint behaviour for loud deaths, tied to the reduce flashing setting or a sibling option.
10. Audition the three Hullbreaker candidates against fac_corsair once its file is present, store CC BY attribution for any winner through the music pipeline, and do not hand edit CREDITS.md.
11. Screenshot and sound check pass at 20 ships: one full round with caps logging on, confirming no moment fires twice and no death stacks cues.

## 7. Not checked

I did not listen to any audio in this pass, including the incumbent track, the source packs, or the shipped cues; every description is a design target, not a report of how a file sounds. I verified packs, not individual files inside them, and the Kenney Interface Sounds page link is unverified in section 3. I searched battle.gd and found no sound dispatch tied to the brace or board branches in the lines I read, and I checked the volume code at sfx.gd around line 97 as cited; I did not read every line of sfx.gd or cues.json, and I did not run the game. Positional panning for death_vent is assumed, not established.
