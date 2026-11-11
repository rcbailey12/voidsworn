# Sound sources and palettes: where a clean, tactical sound set comes from at no cost

Issue 422 study for the sound redo (docs/playbooks/sound.md). Written by Rey (chair) from four model legs (leg_rey.md, leg_deepseek.md, leg_qwen.md, leg_grok.md, leg_flash.md) and the chair's own licence checks. The target, in the owner's words: the current sounds are thin and weak, cheesy or arcade-like, harsh or annoying; a battle should sound clean and tactical, restrained and clear, like Sins of a Solar Empire or EVE Online. Free tools and free sources only.

Licence method: every source below was checked against its licence text on Nov 10, 2026, by the chair or by two legs agreeing; the link is the licence, not a homepage. Anything that could not be checked is marked UNSOURCED and is not relied on.

## 1. Sources that pass the licence test

| Source | Licence | What it means for this game | Licence link |
|---|---|---|---|
| Sonniss #GameAudioGDC bundles | Royalty-free licence v2.0: unlimited projects for life, commercial use, no attribution | The spine of the found-sound half: impacts, metal stress, machinery, explosions, ambience. Never supply the sounds themselves, raw or redesigned, to anyone outside the team; no AI training use | https://sonniss.com/gdc-bundle-license/ |
| freesound.org, CC0 files only by default | CC0 (public domain) | The raw-material pool: relays, capacitors, servos, pressure, room tones, groans. Prefer known recordists and keep a download record, uploaders occasionally post material they do not own | https://freesound.org/help/faq/ |
| freesound.org, CC-BY files | CC-BY, credit the author | Usable when a CC0 version does not exist; the credit goes in the game's credits file at download time, not from memory later | https://creativecommons.org/licenses/by/4.0/ |
| Kenney audio packs | CC0 | Buttons, menus and clean interface sounds; some impact packs | https://kenney.nl/assets |
| 99Sounds | Royalty-free, personal and commercial, modification allowed | Designed packs (cinematic impacts and hits) that skip the freesound trawl. No standalone redistribution; no noise or sleep apps | https://99sounds.org/license/ |
| ZapSplat, Basic (free) account | Standard licence: unlimited commercial projects, credit to ZapSplat required wherever reasonably possible | Gap filler. Free tier is mp3 only with download limits, so prefer it for short one-off sounds, not beds | https://www.zapsplat.com/license-type/standard-license/ |
| Pixabay sound effects | Pixabay Content Licence: commercial use, no attribution | Gap filler. The sound itself may never be redistributed standalone, so files live inside the game build only | https://pixabay.com/service/license-summary/ |
| NASA audio | Public domain (US government works) | Engine and structural raw material, space ambience. No implied endorsement, no logos, and check each recording for third-party material | https://www.nasa.gov/nasa-brand-center/images-and-media/ |
| OpenGameArt, CC0 and CC-BY files only | CC0 or CC-BY per file | Scattered SFX and music; check the licence on each file page | https://opengameart.org/content/faq |
| FreePD | CC0 (public domain dedication) | Music beds and drones with no credit burden | https://freepd.com/ |
| Incompetech | CC-BY, credit Kevin MacLeod | A large scored-music library if a composed track is wanted for menus | https://incompetech.com/music/royalty-free/ |
| Musopen | Public domain or CC0 per recording | Orchestral recordings for menu music; check the release on each recording | https://musopen.org/ |

Excluded, so nobody builds on them:

| Source | Why |
|---|---|
| BBC Sound Effects | RemArc licence is personal, educational or research only. Commercial use needs a separate paid licence. Excluded, however good the archive is |
| freesound CC-BY-NC and NC variants | Non-commercial. One NC file in the build invalidates the release; exclude by filter, never by eye |
| OpenGameArt CC-BY-SA | An unmodified SA file used as-is is defensible, but game audio is almost always edited or layered, and an edited SA sound must itself be shared alike. Off the working list |
| gamesounds.xyz | Not a licensor: a file mirror of the Kenney pack and the Sonniss bundles. Download from Kenney and Sonniss directly |

Free tools the recipes assume: Audacity (editing and layering), Surge XT and the Vital free tier (synthesis), LMMS or Ardour (multi-track death builds and loops), ffmpeg (batch pitch and format work). jsfxr is prototyping only; its presets are the arcade sound this redo exists to replace.

## 2. Sourcing by family, with one synthesis recipe each

Most ladder sounds are better made than found: found material supplies the mechanical truth (a real relay, a real breech, real metal under stress), synthesis supplies the weight and the control. Every recipe follows the playbook: three layers at most (transient, body, tail), short and dry, at least four takes of anything heard often, never the same take twice in a row.

| Family | Take from | Recipe (free tool, layers, starting settings) |
|---|---|---|
| Weapon fire | Sonniss machinery and gun mechanisms; freesound CC0 searches: relay, capacitor, servo, pneumatic; 99Sounds | Audacity and Surge XT. The weapon's own mechanical action first (breech slam, relay click, charge rising in the circuity, never a rising pitch sweep), a body thump (sine or triangle 50 to 300 Hz by ladder step, short pitch drop, 80 ms decay), a filtered noise tail under 200 ms. Las is the same recipe at its smallest and driest; torpedo adds a low sweep 80 to 40 Hz and an ignition |
| Hits | Sonniss impacts; freesound CC0: metal impact, welding, thud; Kenney impact packs | Audacity. A 1 to 3 ms click, a low thump 60 to 110 Hz, a material ring (hull metal around 800 Hz, Glasswright fracture much higher and shorter), a short debris noise burst shaped along the surface's outward direction. The wound that glows and cools gets a cooling tick or sizzle tail of 1.5 to 4 s by row, at low level |
| Ship deaths | Sonniss explosions and metal groans; NASA structural and pressure audio; freesound CC0: metal creak, pressure release | LMMS or Ardour, built to the three beats of deaths_and_hits.md. Tell: things switching OFF (engine loop cut, relay drops, lights-out clicks bow to stern) plus the faction's tell material; never a rising charge sweep. Break: pitched-down metal impact (about -12 semitones) with a 30 to 50 Hz sub boom. Wreck: stretched, reversed groan, low-passed at 600 Hz, secondaries as damped interior thuds. Totals: frigate under 1 s, cruiser about 3.5 s, capital about 4.5 s, cooling tail cheap and quiet. A torpedo hit and each death duck the battle bed about 4 dB for a quarter second (Flash leg) |
| Engines | Sonniss engines and drones; NASA engine recordings; freesound CC0: hum, transformer, diesel idle | Vital or Surge XT over a recorded hum at low level: two detuned oscillators 40 to 80 Hz, filtered noise 200 to 600 Hz, slow filter LFO 0.1 to 0.3 Hz, 4 to 8 s seamless loops. Faction tuning carries the palette (section 3) |
| Shields | freesound CC0: electric hum, tesla coil; Sonniss electrical | Vital. At rest, nothing (the shield look rule is invisibility at rest; the sound matches). On a hit: a fast pitch-bend sine (about 600 down to 150 Hz in 120 ms) with a short noise splash, sized to the staging table's ripple, plus the faction's material colour. On a side dropping: the hum reversed and faded over 300 ms into a low thud, then a gap of near silence where that side was |
| Buttons and menus | Kenney UI audio (CC0 spine); freesound CC0 clicks and toggles | Audacity. A real mechanical click or relay, 10 to 30 ms, low-passed at 4 kHz so the top is soft, mixed low (-18 to -24 dBFS in the mix). Four variants: confirm a touch lower, back a touch higher, hover barely there, error a short 200 Hz buzz. No reverb, no chime |
| Map and battle ambience | NASA space and telemetry audio; Sonniss ambience; freesound CC0 room tones | Audacity. Map bed: filtered noise low-passed at 200 Hz at about -30 dB, a 50 to 80 Hz sine drone, a distant metallic creak every 8 to 15 s. Battle bed adds faint engine rumble and a muffled distant thud at long intervals. 60 to 120 s seamless loops. The bed is a floor, never a feature |
| Music | FreePD (CC0) for beds; Incompetech (CC-BY) if a composed menu track is wanted; OpenGameArt CC0 and CC-BY | LMMS for original beds: a sustained pad through a 400 Hz low-pass at about -20 dB under the effects, a slow sub pulse for battle tension, nothing with a hook. Music that asks for attention fails the playbook's quiet-bed rule |

## 3. Faction palettes

Each faction's guns and engines share one sound family, and its death is that family breaking. The flash core of a death stays neutral for everyone; the faction colours everything around it.

| Faction | Its sound in a few words | Guns | Engines | Death | Never sounds like |
|---|---|---|---|---|---|
| Sunward Crusade (voidsworn) | iron, fire, weight, conviction | Breech-block slam and a low thump; macro rings like a hammer on an anvil; fire crackle kept short in the tail | Low furnace roar over a 50 to 70 Hz drone, iron vibrating | The magazine row: an even drumbeat of detonations a quarter second apart down the broadside, a tearing iron groan at the break, the spire line cracking off, then ticking metal as the wreck cools | Zaps, pews, anything clean, digital or precise. No sung or chanted anything: the spires shed heat, they do not sing |
| Hegemony Navy (hegemony) | clean, electrical, precise, cold | Capacitor discharge: a tight snap with almost no tail; ion fire a focused crack in blue-white | A steady 120 to 200 Hz electrical hum with a faint fan whisper under it; identical on every ship | One clean crack at the module joints, arcs snapping dryly across the gap for a third of a second (top rolled off, no sizzle tail), lights dying on every module at the same instant, few secondaries, evenly timed; its drones cut off mid-hum | Fire, rattle, grit, anything uneven or warm |
| Ashfall Hullbreakers (corsair) | rattling, junk, uneven, chained | Clank, rattle, bang, in that order and never twice the same; a torpedo coughs before it ignites | A lumpy diesel loop with loose parts clinking and a slight wobble, held together with wire | Patch plates tearing loose through the tell, a grinding parting, chains holding half a second then snapping with a second jolt, too many secondaries at uneven times, small metal scattering as loot and frames spill | Clean, precise, musical, any single pure tone |
| Glasswrights (ithar) | glass, tone, fracture, light | The prism lance is a pure sustained tone with the shimmer at its edge; smaller lenses crack like thick panes under pressure | A soft glassy hum, 400 to 800 Hz, faint vibrato, almost no mechanical noise | Fracture first: short bright cracks racing across the optics, panes shearing off with individual clinks, then the stored light leaving as a tone that decays over 1 to 2 s. Glittering dust, no boom. No fire, no smoke, no sub-bass | Kitchen glass, wind chimes, singing bowls, anything hot, dirty or grinding. The failure mode is cuteness: thickness and pressure, never tinkling |
| Eclipse (deathless) | low, held, dark, patient | Muffled and subdued, low-passed around 500 Hz; a torpedo is felt more than heard; everything quieter than the other factions | One held note, 30 to 60 Hz, barely modulated, near silent mechanically | The peel: shade plates lifting with a soft dry shush, a beat apart; the trapped core guttering, its tone wavering and dropping; one small hard crack, then silence, and the scene's sound dims with its light. The held note cutting out IS the death | Loud, bright, sharp, busy. No fire, no drone pad that lingers and masks the ladder: the note is gated to the ship, and it stops |
| The Chorus (chorus) | wet, breathing, vast, eyeless | A damp thwack like packed soil; acid a soft sizzle through filtered noise; spines quick soft thips; nothing with a dry sharp transient | A breathing loop, a 4 to 6 s rise and fall on a muffled 80 to 150 Hz body, a faint wet texture underneath, occasional cartilage clicks | The burst: sacs rupturing (band-passed noise pops 300 to 800 Hz with a liquid tail), a slow fibrous rip as the body tears, one dry crack where bone shows, a pale bloom with no hard transient, two or three wet clicks as the pieces twitch, the sac glow fading last | Metal, machinery, electricity, horror gore, vocal screeches. It breathes and tears; it never screams |

## 4. The three complaints: causes and cures

| Complaint | What causes it | Cure |
|---|---|---|
| Thin and weak | Single-layer sounds; no energy below 200 Hz; sources recorded thin (phones, preview mp3s) or high-passed in the mix; loudness raised instead of weight added | Build every hit as transient plus body plus tail, with a dedicated sub layer (30 to 90 Hz) on torpedo hits and deaths; keep the 80 to 400 Hz body when mixing; source WAV masters, never previews |
| Thin and weak | The same take repeated until the ear memorises it | At least four takes of anything heard often, pitch-varied a few tens of cents, never the same take twice in a row (playbook rule) |
| Cheesy or arcade-like | Stock zaps, pews, rising whooshes and pitch sweeps; clean sine presets; the explosions everyone has heard in a hundred games | Source from mechanical and electrical recordings (relays, capacitors, breech blocks, pressure valves, hull groans); ground every weapon in a physical action; pitch down; if a sound could sit in a mobile puzzle game, delete it |
| Cheesy or arcade-like | Cartoon material in serious palettes: kitchen glass for the Glasswrights, trash-can crashes for the Hullbreakers, gore for the Chorus | Each faction's guard in section 3: thickness and pressure, structural weight, breathing and tearing |
| Harsh or annoying | Energy stacked at 2 to 5 kHz; raw unfiltered metal clangs and noise bursts; clipping used as a shortcut to power | A soft top on everything: low-pass or shelf down what the sound does not need (most effects are done by 6 to 8 kHz, ambience by 3 kHz); mix with headroom (common hits around -12 to -18 dBFS, big events around -6) and gentle compression, not hard limiting |
| Harsh or annoying | Long bright tails and reverb fighting the next sound; everything at one loudness for hours | Short, dry tails; the 0.70 s flame cap is also an audio cap for hit tails; a quiet bed under the fight, ducked about 4 dB by torpedo hits and deaths |

## 5. Disagreements the chair settled

- ZapSplat: the Flash leg called the free tier disqualified for commercial games. The licence text says the opposite (unlimited commercial projects, credit required). ZapSplat is usable, with credit; the leg's claim is recorded as refuted in leg_flash.md.
- OpenGameArt CC-BY-SA: Qwen argued share-alike is safe in-game; DeepSeek and Grok said avoid. Ruling: avoid in practice, because edited audio is an adaptation and game audio is always edited (section 1).
- The death tell: Qwen's recipe opened the tell with a rising sweep. The playbook bans rising whooshes and the deaths design's tell is a ship dying inside, so the tell is built from things switching off, never from a charge-up.
- Sonniss terms: the legs cited the bundle page; the chair read licence v2.0 itself. It confirms commercial use with no attribution, and adds two terms the legs missed: the sounds may not be supplied to anyone outside the team even redesigned, and AI training use is prohibited. Neither affects building the game; both bind how the raw library is handled.
