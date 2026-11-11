# #422 leg: DeepSeek (writer seat)

Run: Nov 10, 2026 20:00-20:04 CST, chat.deepseek.com, DeepThink ON and Search OFF both verified visually before sending (Search had to be toggled off, DeepThink stayed on, re-verified). Signed in as Ryan Bailey. Chat: https://chat.deepseek.com/a/chat/s/cfe4bf58-88e1-4df2-bbca-8415507fda70

Chair screening: complete across all three parts, closely tracked to the pack, careful licence discipline (marked ZapSplat UNSOURCED until checked; told the reader to verify each Sonniss bundle's own licence.txt). One catch: the Crusade palette words include "hymn". Song and choir words are banned game-wide (the #296 lore rule: no song, choir, hymn, psalm or chant anywhere), so that word does not carry into the synthesis; the palette itself is otherwise on brief. New sourced candidates it added beyond the chair's list: FreePD (CC0 music), Incompetech (CC-BY), Musopen (public domain recordings). All licence claims get a chair check at source before the synthesis asserts them.

## Full reply

## Part 1 - Sourcing table

Licence claims carry their link. Where terms have caveats I mark "verify at link". Sources I cannot confirm are marked UNSOURCED and not asserted.

### Sources by family

| Family | Free sources (licence - link) |
|---|---|
| Weapon fire | Sonniss GDC bundles (royalty-free, commercial; verify the bundle's licence.txt - https://sonniss.com/gameaudiogdc); freesound CC0 and CC-BY only (https://freesound.org/help/faq/#licenses); Kenney audio (CC0 - https://kenney.nl/assets); OpenGameArt CC0/CC-BY (https://opengameart.org/content/faq) |
| Hits | Sonniss GDC; freesound CC0/CC-BY; OpenGameArt CC0/CC-BY; Kenney impact packs (CC0) |
| Ship deaths | Sonniss GDC; freesound CC0/CC-BY; NASA audio (public domain, structural rumble - https://www.nasa.gov/nasa-brand-center/images-and-media/) |
| Engines | freesound CC0 loops; Sonniss GDC; Pixabay sound effects (Pixabay Content Licence, commercial OK, no standalone redistribution - https://pixabay.com/service/license-summary/) |
| Shields | freesound CC0/CC-BY; Sonniss GDC |
| Buttons and menus | Kenney UI audio (CC0); freesound CC0/CC-BY; OpenGameArt CC0/CC-BY |
| Map and battle ambience | NASA audio (public domain); freesound CC0/CC-BY; Pixabay (content licence); Sonniss GDC |
| Music | FreePD (CC0 - https://freepd.com/); Incompetech (CC-BY, attribution - https://incompetech.com/music/royalty-free/); Musopen (public domain - https://musopen.org/); OpenGameArt music CC0/CC-BY |

### Synthesis recipes (better made than found)

| Family | Tool | Layers and start settings |
|---|---|---|
| Weapon fire | Audacity (or Vital for tonal) | (1) 2-5 ms noise transient, high-pass 1.5 kHz, -6 dB; (2) body sine/triangle 120-300 Hz with 40 ms pitch drop, 80 ms decay; (3) tail filtered noise, 200 ms. Las: short and dry. Macro: add low thump 60 Hz and crackle. Lance: long tone 300 ms plus shimmer. Torpedo: low sine sweep 80-40 Hz plus noise body. |
| Hits | Audacity | (1) 1-3 ms click; (2) low thump 60-110 Hz, 80 ms decay; (3) material ring: metal 1.5-3 kHz, glass 400 Hz, hull 800 Hz; (4) debris: short filtered noise. Mix hot then pull back 3 dB. |
| Ship deaths | Ardour or LMMS (multi-track) | Flash: white noise 5 ms. Fire: pink noise low-pass 1.2 kHz, 0.5-0.7 s. Gas: brown noise low-pass 200 Hz, 0.7-1 s. Debris: filtered noise pops at 0.2, 0.4, 0.6 s. Layer and pan. |
| Engines | Vital or Audacity loop | Two detuned saws/sines 40-80 Hz; filtered noise 200-600 Hz; slow LFO on filter 0.1-0.3 Hz. 4-8 s loop, crossfade 100 ms. |
| Shields | Vital | Sine chord (220/330/440), filtered noise shimmer, LFO 0.5 Hz, attack 50 ms. No transient. |
| Buttons and menus | Audacity | 1-2 ms click (noise high-pass 2 kHz) plus short sine 800-1200 Hz, 20-40 ms, soft, low level. |
| Map and battle ambience | Audacity/Ardour | Map bed: low drone 30-50 Hz plus sparse noise swells. Battle bed: distant rumble plus muffled impacts every 3-7 s. |
| Music | LMMS or sourced | Drone plus slow pulse; FreePD/Incompetech beds; keep under -20 LUFS beneath the fight. |

### Licence test - fails and traps

| Source | Verdict |
|---|---|
| BBC Sound Effects | EXCLUDED. RemArc licence is personal/educational/research only, not commercial - https://sound-effects.bbcrewind.co.uk/licensing |
| freesound CC-BY-NC | EXCLUDED for a shipped game. Non-commercial only. Use CC0 or CC-BY with attribution. |
| OpenGameArt CC-BY-SA | AVOID for shipped assets. Share-alike can reach the game. Use CC0/CC-BY entries only. |
| Sonniss GDC | Verify the licence.txt inside each bundle before committing; terms are per-bundle. |
| ZapSplat free tier | Verify at https://www.zapsplat.com/license-type/; free tier carries attribution and limits. Mark UNSOURCED until checked. |
| Pixabay | Content licence permits commercial use but forbids redistributing the sound as a standalone file. Final mix only, never a bare file. |

## Part 2 - Faction palettes (one page)

| Faction | Three to five words | Guns | Engines | Death | Never sounds like |
|---|---|---|---|---|---|
| voidsworn (Sunward Crusade) | iron, fire, hymn, weight | Iron breech and low brass thump; fire crackle tail | Low furnace roar, iron vibration | Splits lengthwise; magazine row down the broadside, drumbeat quarter-second apart; spire snaps off glowing, then goes dark | Zaps, pews, clean digital |
| hegemony (Hegemony Navy) | clean, electrical, precise, cold | Capacitor discharge and tight hum; blue-white arcs | Steady electrical hum, no roar | Parts at module joints; arcs jump the gap a third of a second; lights die together | Grit, fire, rattle, wet |
| corsair (Ashfall Hullbreakers) | rattling, junk, uneven, chain | Scrap launch, chain rattle, uneven thumps | Rough growl, loose parts | Patch plates tear; chains hold half a second then snap; too many uneven secondaries | Clean, precise, tonal, hum |
| ithar (Glasswrights) | glass, tone, fracture, light | Prism lance: tone plus shatter | Glassy hum, ringing | Shatters: white fracture lines, rainbow fringe, glittering dust, no fire | Fire, smoke, thud, wet |
| deathless (Eclipse) | low, held, dark, peel | Low held note, sub thump, no top | Very low drone, near silent | Peels band by band; core gutters green-white; one hard flash; no fire | Bright, busy, fire, chatter |
| chorus (The Chorus) | wet, breathing, sacs, twitch | Wet launch, squelch, organic | Breathing pulse, wet | Bursts; sacs rupture yellow-green, wet strands, pale bloom, twitch | Metal, clean, dry, hard white |

All six share the death rules: light, then matter, then dark; flash and snuff out; starts on the ship, never in a vacuum (except for ithar, whose shards carry light briefly).

## Part 3 - The three complaints

| Complaint | What causes it | Cure |
|---|---|---|
| Thin and weak | One layer, no low body, over-high-passed, no transient weight | Layer sub 40-80 Hz, body 150-400 Hz, a 1-3 ms transient click; light saturation; keep the lows when mixing, never high-pass under the body. |
| Cheesy or arcade-like | Stock pew and whoosh, upward pitch sweeps, bright sine zaps, stock explosions | Source from mechanical and electrical recordings (relays, breech blocks, capacitors); no upward sweeps, no pew; use short, hard attacks, restrained tails and a dry mix. Test it against a Sins of a Solar Empire or EVE Online fight, not a cartoon. |
| Harsh or annoying | Energy piled in 2-5 kHz, long tails, too loud, no variation, clipping | Soft top via gentle high shelf or low-pass; short tails and little echo; -6 dB headroom; at least four takes of each sound, never the same twice; roll off 2-5 kHz rather than lifting it. |

One more rule that ties all three: every sound sits on the ladder (las, macro, lance, torpedo, death), each plainly heavier than the last, and the ambience and music sit low under the fight.
