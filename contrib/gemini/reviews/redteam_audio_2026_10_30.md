# Red team audit, audio persona: Argon leg

Chair header: Argon (Gemini, Argon High) leg for the Oct 30, 2026 red team audit, run from the audio evidence pack and the persona leg prompt. Text below is the model report verbatim, with em dashes normalized to ASCII where they appeared.

Red Team Audit Report: Audio Designer (Music and Sound)

Domain Claims Register Status: The program brief contains no prior audio-domain verdict to confirm or overturn ("The claims register in the program brief contains no audio-domain bullet"). This audit evaluates the sound code and shipped audio assets directly and addresses the brief's open music credits question.

Ranked Findings (Highest to Lowest Severity)

1. Reverb Send Bypasses the Master Volume Node in sfx.js (OBSERVED / INFERRED)

What breaks or underperforms: OBSERVED: In SFX._chain, the five audio buses (weapons, impacts, explosions, ui, ambient) connect their dry output to the master gain node m, but connect their reverb send gains s directly to the convolver conv, which returns into the highpass filter hp downstream of m. INFERRED: Because setVol() and setOn() only attenuate this.master.gain (m), lowering the SFX volume slider reduces only the dry signal while the wet convolver reverb from weapons, impacts, explosions, and UI plays at full, unattenuated volume. Even setting volume to zero (without toggling mute off) leaves 100 percent of the wet reverb audible, and toggling mute via setOn(false) leaves the reverb tail ringing unattenuated for 400 ms until c.suspend() executes.

Evidence:

"m.connect(hp); hp.connect(comp); comp.connect(lim); lim.connect(trim); trim.connect(dest);"

"conv.connect(ret); ret.connect(hp);"

"g.connect(m); if(send){ const s=c.createGain(); s.gain.value=send; g.connect(s); s.connect(conv); }"

"this.master.gain.setTargetAtTime(this._mg(),this.ctx.currentTime,.04);"

"if(!on) setTimeout(()=>{ try{ if(!G.sfxOn&&c.state==='running') c.suspend(); }catch(e){} },400);"

What it costs the game: Players who lower the volume slider in META.opts.sfxVol get a progressively wetter, distant mix that never actually gets quiet at low settings, breaking basic PC accessibility and volume control in the shipped browser build.

2. Zero Music Surface in the Playable Browser Build vs. 24 Unconnected Tracks in Godot (OBSERVED / INFERRED)

What breaks or underperforms: OBSERVED: The shipped Babylon.js browser build contains only sfx.js and sfx_data.js with five buses (weapons, impacts, explosions, ui, ambient) and a single ambient clip key, while all 24 music .ogg tracks (boss_final.ogg, six fac_*.ogg themes, four hot_*.ogg tracks, six map_*.ogg tracks, four sting_*.ogg files, title_war.ogg, and two calm_*.ogg tracks) reside exclusively inside godot/music/. INFERRED: The playable browser build has no music score at all during sector navigation, faction battles, or Nemesis encounters, relying solely on a static ambient bed.

Evidence:

"the browser build is the playable truth today; the Godot tree is where the future is being built."

"sfx.js (364) and sfx_data.js: sound."

"Buses (weapons, impacts, explosions, ui, ambient) feed a short dark generated reverb send"

"11550 ~/workspace/voidsworn-fresh/godot/music/music_player.gd"

What it costs the game: The current playable build lacks musical pacing, faction identity, and emotional escalation between calm sector map nodes and high-stakes fleet combat.

3. Stale Faction Identifiers in Both sfx.js Cues and godot/music/tracks/ (OBSERVED / INFERRED)

What breaks or underperforms: OBSERVED: The game's settled design defines six factions (Sunward Crusade, Hegemony Navy, Ashfall Hullbreakers, the Chorus, Glasswrights, Eclipse), yet both sfx.js weapon helpers (lance and torp) and the godot/music/tracks/ file names (fac_chorus.ogg, fac_corsair.ogg, fac_deathless.ogg, fac_hegemony.ogg, fac_ithar.ogg, fac_voidsworn.ogg) key off four legacy or mismatched names (corsair, deathless, ithar, voidsworn). Additionally, fac_corsair.ogg is only 227,608 bytes compared to 2.2 MB to 3.7 MB for the major faction tracks. INFERRED: Unless current factions are internally aliased to dead faction IDs, four of the six factions silently lose their bespoke lance, torpedo, and music themes and fall back to generic cues; even if aliased, whichever faction maps to fac_corsair.ogg receives a tiny ~15-second audio stub that loops repetitively during turn-based battles.

Evidence:

"Six factions: Sunward Crusade, Hegemony Navy, Ashfall Hullbreakers, the Chorus, Glasswrights, Eclipse."

"lance(ion,fac,pos){ return this.play(fac==='deathless'?'lance_dark':fac==='ithar'?'lance_choir':ion?'lance_ion':'lance',{pos}); },"

"torp(fac,pos){ return this.play({corsair:'torp_rocket',chorus:'torp_sac',ithar:'torp_star',voidsworn:'torp_heavy'}[fac]||'torp',{pos}); },"

"227608 ~/workspace/voidsworn-fresh/godot/music/tracks/fac_corsair.ogg"

"3721425 ~/workspace/voidsworn-fresh/godot/music/tracks/fac_hegemony.ogg"

What it costs the game: Faction identity fractures between audio and lore, bespoke weapon synthesis (lance_dark, lance_choir, torp_rocket, torp_star, torp_heavy) is either unreachable or tied to wrong faction strings, and one faction's battle music is an unfinished stub.

4. Open Music Credits Question: 18.7 KB CREDITS.md Has No Surface in Game Code or UI (OBSERVED / INFERRED)

What breaks or underperforms: OBSERVED: While sfx_data.js explicitly documents license clearance in its header (Kenney (CC0) and Sonniss GDC 2026 bundle (royalty free, no attribution required)), godot/music/ contains an 18,739-byte CREDITS.md file alongside 24 music tracks, and the browser code inventory (ui3d.js, data.js) lists no credits screen or music attribution data. INFERRED: An 18.7 KB credits document for 24 tracks strongly indicates third-party music licenses that require attribution (such as CC-BY or individual composer credits), yet neither the UI nor game data exposes those credits to the player.

Evidence:

"The program brief names one open item for this seat, the music credits question."

"Kenney (CC0) and Sonniss GDC 2026 bundle (royalty free, no attribution required)."

"18739 ~/workspace/voidsworn-fresh/godot/music/CREDITS.md"

"ui3d.js (747): battle and campaign UI, HUD, tips."

"data.js (697): all game data: SHIPS, WEAPONS, MODULES, RELICS, EVENTS, NEM_LINES, TIPS, factions, prices."

What it costs the game: Shipping the Godot build (or backporting its 24 music tracks) without surfacing CREDITS.md in ui3d.js or the Godot UI creates a direct license compliance risk.

5. Aggressive gap/defer Drop Logic and Per-Cue Caps Silence Volleys in 20-Ship Battles (OBSERVED / INFERRED)

What breaks or underperforms: OBSERVED: In SFX.play, overlapping calls to the same cue are staggered forward by gap*(1+Math.random()*.6) and silently dropped (return null) whenever the staggered start time exceeds now + cue.defer. gun_shell and gun_las set gap:.045, defer:.14, max:6; gun_flak sets gap:.04, defer:.1, max:4; gun_sq sets gap:.05, defer:.08, max:3. INFERRED: Because this.last[name] advances monotonically on each accepted call, firing just 3 to 4 shots of the same weapon type simultaneously pushes nt - now past 0.14s (and past 0.08s after just 2 calls for gun_sq), causing SFX.play to return null and drop the remaining weapon reports completely. Under the settled ruling that 20 space ships is a typical battle target, multi-turret salvos and strike craft squadrons will routinely misfire silently or lag up to 140 ms behind visual weapon flashes.

Evidence:

"20 ships is a typical-battle target, not a cap."

"if(gap&&t<lt+gap){ const nt=lt+gap*(1+Math.random()*.6); if(nt-now>(cue.defer||0)) return null; t=nt; }"

"gun_shell:{bus:'weapons',g:.42,max:6,gap:.045,defer:.14,salvo:'gun',n:4,len:1,first:1"

"gun_sq:{bus:'weapons',g:.25,max:3,gap:.05,defer:.08,n:3,len:.3"

What it costs the game: Large fleet exchanges lose audiovisual sync and punch: visual projectiles fire from forward mounts in wfx3d.js with no accompanying sound, making 20-ship battles feel hollow rather than massive.

6. Core Battle Mechanics, Nemesis Encounters, and the 80% Loss Loop Lack Dedicated Audio Cues (OBSERVED / INFERRED)

What breaks or underperforms: OBSERVED: battle.js implements boarding, brace, phased activation, and in-battle Nemesis adaptations, and the settled design dictates that roughly 80 percent of runs end in defeat. However, SFX_DATA includes a recorded victory clip but no defeat clip, and SFX exposes no public methods or clip keys for boarding, bracing, or Nemesis adaptations (banner() only triggers ui_boss on the exact string 'Sector flagship'). INFERRED: The game's signature Nemesis hunter and core tactical actions (boarding and bracing) have no distinct sonic identity, and the outcome players hear on 80 percent of their runs (sting_loss) relies solely on offline procedural synthesis while the rarer 20 percent outcome (sting_win) gets a recorded victory sample.

Evidence:

"about 80 percent of runs are lost by design; run 1 is near-impossible"

"battle.js (1,402): battle rules, activation, AI calls, boarding, brace, adaptations in battle."

"uiClick uiConfirm uiDeny uiPanel uiSelect victory whoosh yourTurn"

"if(s==='Sector flagship') return this.play('ui_boss'); return null;"

"sting(win){ this.duck(.8,3); return this.play(win?'sting_win':'sting_loss'); }"

What it costs the game: The central roguelite hook (the adapting Nemesis and generational loss) and key tactical maneuvers fail to register aurally, weakening combat readability and dramatic payoff.

7. Offline 32 kHz Synthesis with 3 to 4 Baked Takes Causes Severe Repetition Across Runs (OBSERVED / INFERRED)

What breaks or underperforms: OBSERVED: SFX renders synthesized cues once at initialization using an OfflineAudioContext at SR:32000 (16 kHz Nyquist limit) into n:3 (gun_plasma, gun_tracer, gun_sq) or n:4 (gun_shell, gun_flak, gun_las) static buffers, applying a default synth pitch jitter pj of .03 (±3 percent) via playbackRate at play time. INFERRED: Baking random oscillator and burst timing parameters (K.rv) into only 3 or 4 buffers at 32 kHz dulls high-frequency crispness and locks the rhythm of multi-burst weapons (gun_flak, gun_tracer, gun_sq); stretching playbackRate by ±3 percent cannot disguise 3 static takes repeated thousands of times across multi-generation campaigns.

Evidence:

"into a few round-robin AudioBuffers (OfflineAudioContext, 32 kHz)."

"gun_plasma:{bus:'weapons',g:.34,max:5,gap:.05,defer:.14,salvo:'gun',n:3,len:.9"

"pj:cue.pj==null?.03:cue.pj"

"for(let i=0;i<3;i++){ const u=t+i*d; }"

What it costs the game: Long sessions suffer from noticeable "machine-gunning" ear fatigue because every weapon salvo cycles through the exact same 3 or 4 band-limited renders.

8. Shared Master Compressor/Limiter Pumps UI Audio and duck() Cancels Active Holds (OBSERVED / INFERRED)

What breaks or underperforms: OBSERVED: The ui bus (lvl=1) sums into the same master comp (threshold:-22, ratio:2.6) and brickwall lim (threshold:-6, ratio:20) as explosions (lvl=1), weapons (lvl=.8), and impacts (lvl=.8). Separately, SFX.duck(depth,hold,at) only attenuates this.bus.ambient and unconditionally calls a.gain.cancelScheduledValues(t) before scheduling its release. INFERRED: Heavy space ship explosions (boom_l plus bass_drop plus wreck) drive the master compressor and limiter deep into gain reduction, ducking simultaneous UI clicks, turn banners, and warnings; meanwhile, any minor ducking cue triggered during a 3-second win/loss sting (this.duck(.8,3)) cancels the sting's 3-second ambient duck and prematurely restores the ambient bed.

Evidence:

"for(const [k,lvl,send] of [['weapons',.8,.22],['impacts',.8,.2],['explosions',1,.3],['ui',1,.06],['ambient',.5,0]])"

"const comp=c.createDynamicsCompressor(); comp.threshold.value=-22; comp.knee.value=14; comp.ratio.value=2.6;"

"const lim=c.createDynamicsCompressor(); lim.threshold.value=-6; lim.knee.value=0; lim.ratio.value=20;"

"a.gain.cancelScheduledValues(t); a.gain.setTargetAtTime(base*Math.max(.12,1-depth),t,.04);"

What it costs the game: UI responsiveness feels inconsistent during combat animations, and victory/defeat stings lose clarity because neither combat buses nor overlapping duck envelopes are properly managed.

9. Godot Audio Migration Bakes Static Clips Without Showing a Runtime SFX Graph (OBSERVED / INFERRED)

What breaks or underperforms: OBSERVED: While godot/music/ includes a runtime GDScript player (music_player.gd) and test suite (music_check.gd), the godot/audio/ listing contains offline build scripts (render_ambient_bed.py, render_synth.js) and exported .ogg clip variations (boomBig_0.ogg through laserSmall_1.ogg), with no GDScript runtime SFX controller shown in the listed portion of godot/audio/. INFERRED: Pre-rendering sfx.js cues into static .ogg files strips out dynamic parameter scaling unless a companion GDScript runtime faithfully ports sfx.js's spatial panning (_where), salvo gain scaling (1/Math.sqrt(1+.3*(s.n-1))), salvo_tail triggering, and composite capital ship destruction layers (boom_l + bass_drop + delayed wreck).

Evidence:

"11550 ~/workspace/voidsworn-fresh/godot/music/music_player.gd"

"3794 ~/workspace/voidsworn-fresh/godot/audio/build/render_ambient_bed.py"

"3627 ~/workspace/voidsworn-fresh/godot/audio/build/render_synth.js"

"if(s>=1.1) this.play('bass_drop',{pos,gain:Math.min(1,s/1.5)}); if(s>=1) this.play('wreck',{pos,delay:.7,gain:Math.min(1,s/1.4)});"

What it costs the game: If the Godot migration treats SFX as simple one-shot clip playback without porting the sfx.js voice, salvo, and composite layering logic, Godot battles will sound flatter and more chaotic than the browser build.

Verdict

One-line register verdict: A clever offline-synthesized WebAudio engine in sfx.js is undermined by a broken reverb routing graph that ignores the volume slider, aggressive volley-dropping in 20-ship battles, zero music in the playable browser build, and stale faction IDs across both SFX code and Godot music tracks.

Single most important attack: In SFX._chain, the reverb sends (s) tap off the sub-buses before this.master (m) and return into hp after this.master, meaning setVol() never attenuates the wet reverb signal and players cannot turn down the reverb volume in the shipped game.

Not checked

Contents of godot/music/CREDITS.md, README.md, music.json, music_player.gd, and test/music_check.gd: Only file sizes and paths were included in the pack, so exact track licenses, composer attributions, crossfade rules, and loop points could not be inspected.

Truncated lines of sfx.js (lines 43 to 200 and individual cue recipes after gun_tracer): The pack omits _makeIR, _decodePending, _renderAll, _where, ambient(), SFX.MAP, and the synthesis definitions for non-gun cues (lance_*, torp_*, boom_*, sting_*, ui_*), preventing inspection of spatial attenuation math and non-gun synth recipes.

Truncated portion of godot/audio/ file listing and build scripts: The listing cuts off after laserSmall_1.ogg at the pack budget, and the contents of render_ambient_bed.py, render_synth.js, and clips/index.json were not provided.

Call sites in battle.js, wfx3d.js, fx3d.js, ui3d.js, and campaign_run.js: Because those files are not excerpted in this pack, how frequently and with what arguments gameplay code invokes SFX methods had to be judged strictly from sfx.js entry points.
