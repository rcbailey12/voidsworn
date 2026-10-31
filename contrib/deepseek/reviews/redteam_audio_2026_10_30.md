Audio seat report

Findings

1. Critical, INFERRED. Music credits remain unclosable from this pack.
The Godot music tree has a CREDITS.md, but its contents are not reproduced. The only credit line shown in the browser audio data covers SFX sources, not music. Evidence: 18739 ~/workspace/voidsworn-fresh/godot/music/CREDITS.md; Kenney (CC0) and Sonniss GDC 2026 bundle. Cost: the open music credits question cannot be resolved, so cutover carries unverified rights risk.

2. High, INFERRED. The playable browser build has no authored music surface in evidence.
The browser code inventory lists sfx.js and sfx_data.js as sound, while the music assets sit only under godot/music/. Evidence: sfx.js (364) and sfx_data.js: sound. The browser audio graph has an ambient bus, not a music bus. Cost: the shipped playable truth cannot validate music pacing, faction identity, or mix against combat, so music risk lands late in the Godot migration.

3. High, OBSERVED. Browser recorded SFX are single-take where Godot already has round-robin variants.
The browser clip map has 27 recorded keys, and the listing shows one clip per key for impacts, lasers, and explosions. The Godot audio tree shows multiple variants such as laserLarge_0.ogg through laserLarge_4.ogg and hullHit_0.ogg through hullHit_5.ogg. Evidence: Recorded clip keys present in SFX_DATA (27); laserLarge_0.ogg; laserLarge_4.ogg. Cost: long 20-ship battles in the playable build will repeat hull hits, laser fire, and explosions more than the migration tree will.

4. High, INFERRED. Faction music coverage does not match the six ruled factions by name.
The core lists Sunward Crusade, Hegemony Navy, Ashfall Hullbreakers, the Chorus, Glasswrights, Eclipse. The music listing has fac_chorus.ogg, fac_corsair.ogg, fac_deathless.ogg, fac_hegemony.ogg, fac_ithar.ogg, fac_voidsworn.ogg. No fac_glasswrights or fac_eclipse track appears by name, and three track names use IDs outside the public faction list. Cost: Glasswrights and Eclipse may fall back to shared or mismapped music, weakening faction identity and making credits harder to trace.

5. Medium, INFERRED. The browser mix graph has no music bus or music ducking path.
The bus set is weapons, impacts, explosions, ui, ambient. The duck helper targets the ambient bus only. Evidence: ['ui',1,.06],['ambient',.5,0]. If music is added to the playable build, it has no defined level, reverb send, or combat duck relationship. Cost: music will either mask weapon and impact cues or be buried by them, and the Godot mix will have no browser precedent to match.

6. Medium, OBSERVED. Mobile voice cap is 20 against a 20-ship typical battle target.
The code caps mobile at 20 voices and desktop at 34. Evidence: return G.mobile?20:34;. A typical battle has 20 ships, plus weapons, impacts, explosions, and UI cues. Cost: phones will steal or drop combat cues, and the player loses feedback exactly when the battle is busiest.

7. Medium, OBSERVED. Battle spatial audio is stereo pan only, not 3D positional audio.
The play path uses createStereoPanner with a pan value. Evidence: p=c.createStereoPanner(); p.pan.value=panv. There is no elevation, distance rolloff, or front/back cue in the shown audio path. Cost: in a 3D fleet battle, the player cannot reliably hear flank or rear threats, so audio contributes less to tactical readability than the visual scene does.

8. Low, INFERRED. Missing weapon-style cues collapse to the house kinetic sound.
The gun method falls back to gun_shell when a style has no cue. Evidence: this.CUES[n]?n:'gun_shell'. If any weapon style is unmapped, its fire sound becomes the same broadside cannon as the default. Cost: weapon variety erodes in battle, and the player gets less audio confirmation of what is firing.

Verdict

Audio verdict: the shipped build is all SFX and the future build is unproven music; the music credits file is the sharpest blocker. Most important attack: the game cannot close the music credits question from this pack, and the playable browser build has no authored music surface to test against.

Not checked

Actual loudness and spectral balance by ear; the contents of godot/music/CREDITS.md, music.json, and music_player.gd; runtime music behavior in the browser build; the browser ambient() implementation; Godot audio bus and ducking integration; whether internal faction IDs map Glasswrights and Eclipse to existing tracks; and the full Godot audio clip index beyond the cut listing.
