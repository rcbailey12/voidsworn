# Listen sheet: audio intake (issue 101)

For Ryan, after this pull request merges. Play the game and check the items
below by ear. This pass is the sign-off (step 6): anything that sounds wrong
gets fixed or reverted, and any stripped cue that sounds thin gets its synth
layer back from git. Nobody has listened to any of the new takes yet; every
pick was made from file names, durations and the design spec, so judge
freely.

## 1. The synth strip (step 1)

24 cues that used to play a recorded clip and a computer synth sound at the
same time now play the recorded part only: gun_shell, gun_las, gun_plasma,
gun_needle, gun_rail, salvo_tail, lance, lance_ion, lance_dark, lance_choir,
torp, torp_star, torp_heavy, hit, hit_las, hit_plasma, hit_rail, hit_glass,
hit_ion, shield, shield_break, boom_s, sting_win, sting_loss. The Glasswright
variant of death_crack got the same strip. Also, ui_enemy (the enemy turn
banner) now plays a recorded alert that was already in the game files instead
of a synth blip.

What to listen for: weapons and hits should sound less tinny and buzzy. If
any one sounds thinner or weaker than before, name it; that cue alone gets
its synth layer back.

## 2. New recorded takes (steps 3 and 4)

Every cue below gained real recorded sounds. "Hear it" is where the sound
plays in a normal battle.

| Cue | Hear it when | Listen for |
|---|---|---|
| gun_shell | A ship fires shell guns | A heavier, real detonation under the shot |
| gun_flak | Flak guns fire | Short cracks, not firework tails |
| gun_las | Laser guns fire (Little Robot takes) | A clean beam zap with no synth buzz |
| gun_plasma | Plasma guns fire | A hot energy shot, distinct from lasers |
| gun_tracer | Tracer guns fire | A quick punchy thump (was pure synth) |
| gun_spine | Chorus spine guns fire | A resonant organic snap (was pure synth) |
| gun_needle | Needle guns fire | A light crystalline tick over the shot |
| gun_rail | Railguns fire | A hard metal strike under the launch |
| gun_glob | Chorus glob guns fire | A wet slime launch (was pure synth) |
| salvo_tail | The last shot of a full salvo lands | A longer rolling boom tail |
| lance | A lance fires (Little Robot takes) | A sustained beam, weightier than gun lasers |
| lance_ion | An ion lance fires | An electric field shimmer over the arc |
| lance_dark | A Deathless lance fires | Lower and darker than the other lances |
| lance_choir | A Chorus lance fires | A resonant bell like strike, not a chord |
| torp | A torpedo launches | A short thruster burn under the launch whoosh (the 5 second source loops were trimmed to 1.4 s) |
| torp_rocket | A rocket torpedo salvo launches | Staggered launch bangs, not fireworks |
| torp_sac | A Chorus sac torpedo launches | A wet expulsion swell (was pure synth) |
| torp_star | A Glasswright star torpedo launches | A glassy shimmer over the whoosh |
| torp_heavy | A heavy torpedo launches | Heavy plate weight under the whoosh |
| hit | A hull takes a plain hit | A real metal tick on top of the thud |
| hit_las | A hull is hit by lasers | A short laser sear, no synth sizzle |
| hit_plasma | A hull is hit by plasma | A big cracking impact |
| hit_rail | A hull is hit by a railgun | A sharp plate strike |
| hit_wet | A Chorus hull is hit | A wet slime impact (was pure synth; the named Freesound flesh file needs an account to download, so this is a pack fallback) |
| hit_glass | A Glasswright hull is hit | Real glass hits (this cue wrongly used the shield sound before; the named Freesound glass file is a fallback for the same account reason) |
| hit_ion | A hull is hit by ion fire | A short electric zap over the hit |
| shield | A shield takes a hit | A recorded shimmer instead of synth sine tones |
| shield_break | A shield collapses | Real shattering glass and breakage |
| patter_hull | Light fire rattles a hull | Quiet metal ticks (was pure synth) |
| patter_shield | Light fire rattles a shield | Quiet glass ticks (was pure synth) |
| engine | Ships move under orders | A real engine rumble bed (was pure synth) |
| cough | A damaged ship's engine sputters | Machine chuffs (was pure synth) |
| puff | A ship vents or adjusts with thrusters | Short air puffs (was pure synth) |
| board_grapple | A boarding action, especially Chorus | A wet latch sound on the Chorus variant |
| boom_s | A small ship dies | A crunchy recorded explosion over the boom |
| wreck | A capital ship dies | Falling metal and cracking as the wreck settles |
| death_crack | A ship's hull cracks apart at death | Cracking debris; Glasswright ships get falling glass |
| death_run | A dying ship's engines run down | Engine loops winding down (pack fallback; no true wind down recording exists in the free packs) |
| ui_round | Each battle round starts | A recorded bell strike instead of a synth chord (was pure synth) |

## 3. Music audition (step 5)

Candidates live in this folder (tools/music/audition_2026_11). Incumbents
stay in the game unless you say a candidate wins. Nothing below was changed
in the game by this pull request.

| Slot | Incumbent | Candidate | Status |
|---|---|---|---|
| fac_corsair (Hullbreakers battle) | Heavy battle music, Davieplier | orbital_colossus.mp3: Space Boss Battle Theme by Matthew Pablo, CC BY 3.0 | Loop check scored 0.814 (bar is 0.55), but the author publishes it as not looping; whether a pipeline seam cut is acceptable is your call at this pass |
| fac_hegemony (Hegemony battle calm) | Some Militaristic Tune, Spring Spring | None sourced | The directed search (modern sampled brass marches) found no specific verified free track; incumbent stays |
| title_war (title screen) | War Theme ver 2, Spring Spring | None sourced | Same directed search, no verified candidate; incumbent stays |
| hot_theme_a (battle intense layer) | Battle Theme A, cynicmusic | jrpg_battle_theme.ogg: JRPG Battle Theme by NorthFantasyMusic, CC BY 4.0 | Loop check 0.648 at a 24.0 s loop point, passes the 0.55 bar; listen decides |
| sting_victory | VICTORY, Spring Spring | jingle_HIT15.ogg (1.16 s), jingle_HIT11.ogg (0.96 s), Kenney Music Jingles, CC0 | The Kenney pack has no brass; these are percussion hits, character long shots |
| sting_fanfare | Just a random fanfare, Spring Spring | jingle_HIT03.ogg, jingle_HIT09.ogg (0.75 s), CC0 | Same note as victory |
| sting_champion | WIN AGAINST CHAMPION, Spring Spring | jingle_HIT15.ogg, jingle_HIT04.ogg (0.64 s), CC0 | Same note as victory |
| sting_lose | LOSE, Spring Spring | jingle_HIT00.ogg, jingle_HIT07.ogg (0.28 s), CC0 | Same note as victory |

Two candidate citations from the research phase failed their recheck and
were dropped: the cynicmusic Battle Theme A and War Theme downloads turned
out to be Spring Spring pages (one of them is the title screen incumbent
itself), so there was no distinct cynicmusic candidate to audition.

## How to report back

Just name the cue or slot and what sounded wrong (thin, too loud, wrong
character, annoying). Fixes, synth restorations and music swaps all happen
as small follow ups; nothing in this sheet needs a decision before you have
played a battle or two.
