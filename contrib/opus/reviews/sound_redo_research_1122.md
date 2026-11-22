# Sound redo: Neon plan audit and tool options

Nov 22 2026, Opus, thread "Research sound redo options". Research only: the redo stays parked until the ship rebuilds are
done. Live copy (Claude Doc): https://claude.ai/artifact/3DNMT2uRS1TbwQ4eTbAtJs. Not a ruling; the pick below is Opus's.
Muse's blind research on the same question is issue 1572; Muse legs should not read this file first.

## The pick

**Real recordings for the spine, Stable Audio 3 on the PC for the gaps, ElevenLabs only if those fall short.**

- **Buttons and menus (Ryan's "beeps and boops" complaint):** swap the electronic tones for real mechanical recordings:
  switches, relays, latches, a soft breaker thunk. Free from the Sonniss GDC bundle and Freesound CC0. Cheapest, surest
  win; no AI needed.
- **Weapons, hits, deaths, ambience:** recorded material from Sonniss and Freesound, layered and shaped, as the playbook and
  the Nov 10 Muse study already say. Stable Audio 3 Small SFX (free, runs on the RTX 5080) fills the gaps, mainly the odd
  faction sounds (Chorus wet, Glasswright glass).
- **Battle music as one song:** where paid AI earns its keep. ElevenLabs Music gives stems (2 to 4 parts of one song) on
  paid plans, which is what one-song adaptive battle music needs. Free route: ACE-Step 1.5 or Stable Audio 3 Medium on the
  PC, quality unproven.
- **First step, unchanged from Nov 19:** the listening page (sound.md 2a step 2). Ten key sounds plus a menu row, today's
  version beside two candidates; Ryan picks by ear.

Open for Ryan later: docs/playbooks/sound.md says "Free tools and free sources only" (his Nov 10 scope). ElevenLabs is paid,
so using it changes that line. The pick stays free unless the listening page shows free music is not good enough.

## What the game plays today (main e41b5570)

- 71 cues in godot/audio/cues.json from 180 recorded clips (Kenney CC0, Rubberduck CC0, Little Robot CC BY, older Sonniss
  clips) plus 137 code-made synth takes.
- All 11 ui_* cues are electronic tones: Kenney Interface sounds plus render_synth takes.
- 24 music tracks, all CC0 or CC BY from OpenGameArt. Battle music crossfades two unrelated songs (calm and intense) plus a
  faction flavour track (music_player.gd); they are not parts of one song.
- Issue 1448 (Nov 21) wired menu, reward and boss cues and made battle music hear gunfire. No new sounds.

## Audit of Neon's Nov 19 plan

| Neon proposed | Verdict | Why |
| --- | --- | --- |
| Listening page first: 10 sounds, now vs candidates | Keep, do first | Never built. Cheapest way to let Ryan's ear set the standard. About 2 agent runs. |
| Stable Audio 3 as the AI candidate | Keep | Licence read first-hand: free commercial use under $1M revenue, outputs owned. Small SFX does sound effects. |
| Hand-made (recorded, layered) as the other candidate | Keep | Matches the playbook; best fit for weapons, hits, UI. |
| One-song battle music (AudioStreamInteractive) | Keep the idea, fix the plan | Godot 4.7.2 supports it (checked Nov 19), but today's tracks have no stems, so it needs new music made as parts of one song. Neon's 3-track example cannot happen: the Sunward flavour replaces the intense layer. |
| Sonniss as a new source | Not new | Already in the game; spine of the Nov 10 Muse study. |
| Sonniss into Stable Audio (audio to audio) | Drop | Sonniss licence v2.0: "NO AI TRAINING OR USAGE". Use Freesound CC0 or our own clips as AI input. |
| ACE-Step Apache, pedalboard MIT, Stable Audio Open NC | Wrong | ACE-Step 1.5 is MIT (model card). pedalboard is GPLv3, fine as a tool. Stable Audio Open is Community License. |
| Hunyuan Foley | Low value | Video-to-audio, not text brief. US-only terms accepted Nov 6 (issue 211); fits cutscenes more than battle cues. |
| Menu sounds | Gap | Ryan's new complaint. Add a menu row to the listening page: today's beep, a recorded switch, a recorded relay. |

## Tool options (official pages read Nov 22 2026 through the PC browser)

| Option | Cost | Commercial game licence | Quality for us | Effort for Ryan |
| --- | --- | --- | --- | --- |
| Sonniss GDC bundle | Free | Yes, no credit, lifetime. No AI use, no resale of raw sounds. | Pro recordings, best for weight. | None. |
| Freesound CC0, Kenney CC0 | Free | Yes (CC0). CC BY needs a credit line. No NC (R40). | Mixed; good for relays and switches. | None. |
| Stable Audio 3 Small SFX (local) | Free | Yes under $1M revenue. Register with Stability, keep their Notice file, show "Powered by Stability AI" in credits (safest reading, unsure whether a game using outputs needs it). Model also carries Gemma Terms (text encoder). | Unproven on our sounds. | None if the Board queues it on the PC. ComfyUI support was promised, not confirmed. |
| Stable Audio 3 Medium (local music) | Free | Same. Up to about 6 min, inpainting, continuation. | Unproven. | Same. |
| ACE-Step 1.5 (local music) | Free | MIT; model card says outputs may be used commercially. Windows portable package. | Unproven. Under 4 GB VRAM. | Same. |
| ElevenLabs Sound Effects | Starter $6/mo 150 generations; Creator $22/mo 605; extra $0.03 to $0.04 | Paid plans "Commercial"; Free is personal use only. Max 30 s, WAV 48 kHz on paid. Rights after cancel not read (icon row). | Unproven on ours. | Sign up, API key. |
| ElevenLabs Music | Starter about 33 min/mo (no streaming); Creator $22/mo about 134 min, 2 and 4 stems (pricing page; the Music Terms table shows lower limits, conflict). One 121k credit pool on Creator is shared with sound effects (605 sounds = 121k / 200). | Music Terms (Oct 9 2026): self-serve plans allow games except "Studio Games"; an Indie Game is under $500k game revenue and the studio under $1M a year. No attribution on paid plans. Output stays under the plan it was made on after a downgrade. | Stems are the one thing nobody else gives. | Same. |
| Meta AudioCraft, MMAudio | Free | No: weights CC BY-NC 4.0. | n/a | n/a |
| BBC Sound Effects | n/a | No (Muse study, Nov 10). | n/a | n/a |

Rough spend if paid: one or two months of ElevenLabs Creator. Not checked: Soundly, BOOM Library, Splice, Epidemic Sound.

## Public repos and skills

| Repo | What it is | Worth it? |
| --- | --- | --- |
| elevenlabs/skills | Official ElevenLabs agent skills (sound effects, music). MIT, about 580 stars. | Only if we pick ElevenLabs. |
| GhazaGG/Game-Sound-Effect-for-Claude | Offline synth recipes plus loudness and spectrogram checker. MIT, 2 stars. | Borrow the automatic loudness check idea; skip the synth (cartoon/retro). |
| zeveck/audiogen, majidmanzarpour/threejs-game-skills | ElevenLabs wrappers for other setups. | No; the official one is better. |
| raysan5/rfxgen, tomeyro/godot-sfxr, timothyqiu/gdfxr | Retro sfxr makers. | No: the arcade sound Ryan dislikes. |
| elevenlabs/elevenlabs-mcp | Archived Aug 2026. | No. |
| anthropics/skills | No audio skill found at top level. | n/a |

None vetted; nothing installed.

## Sources

- https://elevenlabs.io/pricing (Sound Effects and Music plan tables)
- https://elevenlabs.io/music-terms (last updated Oct 9 2026)
- https://stability.ai/news-updates/meet-stable-audio-3-the-model-family-built-for-artistic-experimentation-with-open-weight-models
- https://stability.ai/community-license-agreement (last updated Jul 5 2024)
- https://huggingface.co/stabilityai/stable-audio-3-small-sfx
- https://huggingface.co/ACE-Step/Ace-Step1.5
- https://sonniss.com/gdc-bundle-license/ (v2.0, Aug 27 2026)
- https://github.com/facebookresearch/audiocraft/blob/main/LICENSE_weights
- https://github.com/hkchengrex/MMAudio
- Repo: godot/audio/cues.json, godot/music/CREDITS.md, docs/playbooks/sound.md,
  contrib/muse/design/sound_sources_2026_11/synthesis.md
