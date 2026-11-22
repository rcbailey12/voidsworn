# Sound redo research: one write-up (PRs 1577 and 1718, issue 1572)

Nov 22 2026, Opus, for the Board's cleanup pass (Ryan, 17:38 UTC). Merges the Opus research
(contrib/opus/reviews/sound_redo_research_1122.md, PR 1577) and the Muse council synthesis
(contrib/muse/design/sound_redo_research_2026_11/synthesis.md, PR 1718). Research only. Wiring sound into the game stays
parked until the ship rebuilds are done (Ryan, Nov 21). Where the two disagree, both sides and the pick are below.

## What changed since both were written

Ryan bought ElevenLabs Creator monthly on Nov 22 ($11 first month, then $22; 121,000 credits a month). So the paid ask
both write-ups held back is already made. The next step is the issue 1585 Gate 1 pilot (PR 1590): about 2,840 credits
for 27 takes, then a listening page with today's sound, a free candidate and the ElevenLabs take side by side.

## The pick

1. **Listening page first; Ryan's ear is the gate.** Both agree. The 1585 page is that page. Its free column fills once
   Sonniss or CC0 candidates are pulled (a separate small job), so it also tests the free stack, as Muse wants.
2. **Menus from real recordings, not AI.** Both agree: Ryan's "beeps and boops" are all 11 ui_* cues, and the fix is dry
   physical switchgear (relays, latches, breakers, a drawer slide) from Sonniss GDC and Freesound CC0. The UI family is
   the first production target. Muse's per-cue recipe (section 3 of its synthesis) is the brief for that job. Two pilot
   rows (ui_boss, ui_reward) test whether ElevenLabs beats a recording for the heavy one-offs.
3. **Weapons, hits and deaths: recorded layers first, generated beats where free material runs out.** Both agree that
   the game's layered cues (cues.json, death_audio.gd) want short atomic layers, not baked stories. The pilot follows
   that: every beat is one moment (a crack has no boom). Faction textures (Chorus wet, Glasswright glass) are where AI is
   most likely to help.
4. **Beds and ambience: generated is fine.** Both agree. A baked loop is what a bed is.
5. **Battle music: keep today's library; one trial only.** See row 1 below.

## Where they disagree

| Topic | Opus (PR 1577) | Muse (PR 1718) | Pick |
| --- | --- | --- | --- |
| 1. One-song battle music | Keep the idea; needs music made as parts of one song; ElevenLabs stems are the one thing nobody else gives | Drop it; one song deletes the faction voice. Worth one trial of calm-to-hot stems only | Muse's scope, Opus's tool. Today's faction, calm, hot and boss tracks stay. Trial: one battle context as stems (Gate 3, only on a song Ryan picks), judged against today's crossfade. |
| 2. ElevenLabs for music | Allowed: Music Terms let paid plans use it in an Indie Game (under $500k game revenue, under $1M a year studio) | "Never music": the terms exclude Studio Games and cap indie revenue | Allowed now, with the growth clause written down: if the game stops qualifying there are 60 days to move plan, and copies already out keep their music (contrib/opus/sound/README.md). Muse's caution stays a watch item, not a ban. |
| 3. Godot node for stems | AudioStreamInteractive (Neon's plan) | AudioStreamSynchronized for layers; Interactive is a clip graph | Muse is right. Use AudioStreamSynchronized for the trial. |
| 4. ACE-Step licence | 1.5 is MIT (HF model card) | Apache-2.0 (GitHub API on the repo) | Both can be true: repo code Apache-2.0, 1.5 weights MIT. Either passes R40. Not needed now. |
| 5. ElevenLabs SFX cost | 40 credits a second with a set duration (API docs, Nov 22) | About 200 credits a generation | Both right: 200 is the flat price without a duration. The pilot sets durations, so a 1 s beat costs 40. |
| 6. Paid ask order | Free first, ElevenLabs if free falls short | No paid ask; then a $50 to $80 library pack; then one ElevenLabs month | Overtaken: Ryan bought ElevenLabs. A library pack stays the fallback if the page shows recorded mechanical material is the gap. |
| 7. Stable Audio | Stable Audio 3 Small SFX run locally on the PC | Hosted free tier; Stability's KB allows commercial use on Free | Both pass R40. The hosted free tier is the lower-effort test for beds. Local only if batch volume ever needs it. |

## Agreed facts (each checked first-hand by one or both)

- Sonniss GDC licence v2.0: free commercial use, no credit, no AI training or usage. Never feed it to any generator.
- AudioCraft and MMAudio weights are CC-BY-NC: out (R40).
- Stable Audio open weights: Community Licence, commercial under $1M with registration and a credit line.
- pedalboard is GPL-3.0: fine as an offline tool, never shipped.
- ElevenLabs Free-plan output is personal use only: never use it.

## Muse additions to keep for the production job

- Acceptance spec before picking, per cue family: duration, tail, low and low-mid body with a soft top (roll off near
  5 to 6 kHz), loudness (integrated LUFS and peak) and bus.
- Kill list: name the 10 to 15 worst current cues and replace those first, not all 71.
- Two page rows nobody drops: a many-at-once stress mix and a four-take fatigue row for constant cues.
- Ladder rows heard as chains (fire, impact, death), not singletons.
- Once the recipe settles, write a small in-house sound skill (spec, processing chain, page builder) rather than adopt a
  general framework.

## Repos worth reading (none installed)

- elevenlabs/skills (MIT): official, now relevant since ElevenLabs is bought.
- thedivergentai/Game-Dev-Agentic-Skills (LGPL-3.0): godot-audio-systems skill; read, do not lift text.
- Donchitos/Claude-Code-Game-Studios (MIT): audio phase-gate and Godot bus checklist pattern.
- GhazaGG/Game-Sound-Effect-for-Claude (MIT): borrow the loudness and spectrogram check idea only.
- Stability-AI/stable-audio-tools (MIT): only if local Stable Audio is ever used.
- Skip: sfxr makers (the arcade sound Ryan dislikes), the archived elevenlabs-mcp, AudioCraft weights.

## Order from here

1. Gate 1 pilot on the PC (issue 1585, PR 1590), when Ryan pastes the key from his Pick Sheet.
2. Pull free candidates (Sonniss GDC, Freesound CC0) for the same rows and the 11 UI cues; rebuild the page.
3. Ryan picks by ear. Picks plus Muse's acceptance spec become the standard.
4. Gate 2 production of the winners; Gate 3 stems only for the one music trial.
5. Wiring into Godot waits for Ryan to unpark it after the ship rebuilds.
