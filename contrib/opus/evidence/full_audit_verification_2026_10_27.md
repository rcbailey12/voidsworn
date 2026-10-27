# Opus verification of Muse's full catch-up audit (Oct 27, 2026)

Subject: `contrib/muse/reviews/full_audit_2026_10_27.md` (1a47b0b, rulings recorded in e1dcb26). Legs: Rey, DeepSeek, Argon (contrib/gemini/), Qwen, pinned at 172f019.

## Checked and confirmed
| Claim | Verdict | How checked |
|---|---|---|
| Lore lines 12, 45 say one merged mind | CONFIRMED | lore_bible_r6.md read |
| 1.5 heading "(the patrons)", line 120 "boons"/"Favour" | CONFIRMED | lines 116, 120 |
| "ascended" at 458; shapes at 339; remembered names at 374 | CONFIRMED | read |
| Generations tension (73, 395, 429) | CONFIRMED | read |
| Astra line 413; Roll and Registry at 233; Dusk at 103 and 511 | CONFIRMED | read |
| Grand Admiral 248; Eclipse-lord 511; flare 512; Corona-ward 513; Listening Post K-7 251 | CONFIRMED | read |
| Broadside 30% at 173 vs data.js 40% after 2+ hexes | CONFIRMED | data.js line 104 (rake .4) |
| Faction verb strings: void-shrine, joined the song, tomb-world | CONFIRMED | data.js FAC_VERBS; go in the rename map |
| Parity README counts seed 4 twice | CONFIRMED | README lines 43 and 79 |
| Exe smoke test pending | CONFIRMED | godot/main/FEATURES.md line 15 |
| "Admiral: Admiral ..." and duplicate weakness line | CONFIRMED in code | godot/ui/campaign/campaign_ui.gd lines 625, 722 |
| 24 Nemesis portraits in game (audit: UNSURE) | CONFIRMED | godot/portraits/index.json has 24 nemesis entries; nemesis/pool holds 156 files (base plus burn, cyber, eye bakes and patches) |
| 24 music tracks (audit: UNSURE) | CONFIRMED | 24 audio files under godot/music/tracks |
| DeepSeek "Terran Totality" collision | REJECTED (agree with chair) | moot: Ryan reopened the name |

Not separately re-checked: the image-based reads (marks at distance, zoom clutter, V1b window rows, Warden blob, black-hole disc). They are routed to the owning helper for a fix and re-shoot, which settles them either way.

## Routed (Oct 27)
- G2: launch the exe via play_godot.bat; explain the 2 unclean bot runs; worst-round pace; drive drops to pilot glow when the push ends; FEATURES.md campaign rows and G5 title.
- G1: unique-battle count; one named run at a current commit after steps 7/7b; oracle re-pin; exceptions in the headline.
- G3: the two sidebar text bugs; zoom declutter (labels, belt label, shipyard, rings); campaign test record file; map_view.gd status.
- G4: per-weapon marks readable at battle distance; 20-ship frame-time record on both renderers; Compatibility decal note; black-hole disc; re-shoot for the fan fix; unused faction_looks fields.
- A4: V1b porthole rows; Warden turret blob.
- B: show the step 5 start fleets reach battles.
- Opus: lore round 7 from Ryan's rulings (R56); the rename map gets the three verb strings.
