# Cohesive Sci-Fi Audio V2: Clean-Slate Sound Bible, Gate 2 Prompt Pack, and R416 Pipeline Wiring

Issue #1752 (linked to #1585, #1572, #1741, #1743, #1689). Prepared for **Astra and Fable pressure-testing** before running Gate 2 on Ryan's PC.

---

## 1. Why Clean Slate (Gate 1 Ear-Audit Diagnosis)

Direct ear-by-ear listening of all 27 Gate 1 ElevenLabs samples (`board/pc-out-pilot1585`) against current-game baselines (`today*.ogg`, `godot/music/tracks/fac_voidsworn.ogg`) confirmed that **ElevenLabs is a massive fidelity jump** over the legacy synth and free clips, while proving Gate 1's prompt doctrine had systemic flaws:

1. **Muffled house prompt suffix ruined weapon nuance:** Appending `"Heard from inside a warship's hull: weighty low end, soft top"` to every weapon cue stripped out crisp high-frequency attack transients. On `ladder_macro` (v3), it also inserted a ~250 ms mechanical breech clack *before* the shot boom, which lags behind the visual muzzle flash at `t=0`.
2. **Literal-word AI foley misfires and household scale:**
   - `fac_chorus_burst` (`"rush of breath"`) -> sounded like a **balloon deflating**.
   - `r412_gauss_rip` (`"fast tearing rip"`) -> sounded like **ripping cloth / duct tape**.
   - `fac_deathless_peel` (`"peeling ... dry tearing hiss"`) -> sounded like **peeling Velcro / Band-Aid**.
   - `r412_chorus_lash` (`"heavy slap"`) -> sounded like a **cartoon bare-hand slap**.
   - `r412_glass_shatter` -> sounded like a **kitchen wine glass on tile**, not 10-meter crystalline armor.
   - `r412_chorus_sizzle` -> sounded like **bacon frying in a skillet**.
   - `r412_gauss_charge` -> sounded like a **hairdryer / electric trimmer**.
   - `r412_gauss_crack` -> sounded like a **dry wooden stick snap**.
   - `ui_boss` (`"bulkhead locking clamps"`) -> sounded like closet/door locks rather than a boss warship threat arrival.
3. **Single-gun "broadside" and missing weapon variety:** `r412_broadside_thump` read as a single dull boom rather than a rolling multi-gun flank salvo, and `godot/rules/data/tables.json` defines **26 distinct weapons across 6 factions** that cannot share one generic cannon cue.
4. **One-note music prompt:** `battle_preview` literally prompted `"steady energy throughout so it can loop, no lead melody"`, guaranteeing flat 2-bar trailer wallpaper (and still ended on an abrupt final hit at 45 s).

Gate 1 spent ~1,587 credits (~1.3% of Ryan's 121,000 Creator pool). Keeping a patchwork of inconsistent Gate 1 clips saves almost nothing while locking in broken sonic habits. Gate 2 starts cleanly from one unified dark space/sci-fi sound bible.

---

## 2. Core Sonic Identity & Prompting Rules (Strictly Space / Sci-Fi)

- **Space / sci-fi only, never ocean/naval:** Every ship is a colossal void-borne spacecraft fighting around a dying star (RULEBOOK / `docs/playbooks/factions.md`: *"Space ships, not sea ships"*). Ban ocean/maritime triggers (`naval`, `boat`, `submarine`, `wooden deck`, `gunpowder cannonball`, `foghorn`, `broadside` inside ElevenLabs prompts) so the model stays locked on orbital kinetic railguns, thermal lances, directed-energy turbolasers, optical prisms, alien bio-leviathans, and ancient obsidian monoliths.
- **Zero pre-delay on `t=0` weapon attacks:** Every firing transient MUST ignite right at `0.0 s` to lock cleanly onto visual muzzle flashes in `godot/fx/fx_weapons.gd`. Post-shot breech cycling, servo returns, and heat vents live in a separate Layer C tail (`+80` to `+250 ms`), never before the blast.
- **Remove `"soft top"` from weapon prompts:** Record full, crisp, physical transients in ElevenLabs and let Godot's bus reverb, distance attenuation, and ship-class EQ shape depth cleanly without sounding muffled.
- **Ban literal domestic foley words AND pink-elephant negative nouns:** Never prompt `"tearing rip"`, `"peeling"`, `"slap"`, `"rush of breath"`, `"locking clamps"`, or bare `"glass shatter"`. Equally important, **never put concrete unwanted nouns inside negative phrases** (like `"no balloon"`, `"no Velcro"`, `"no boat wood"`, `"no kitchen glass"`), because generative audio models can still attend to those concrete nouns! Use pure positive physical-scale anchors (`"ten-meter-thick crystal hull"`, `"glacier-sheet fracture"`, `"monolithic basalt slab"`, `"substation transformer"`, `"sixty-meter bone-and-sinew tendril"`), keeping negatives strictly to universal acoustic classes (`"no explosion"`, `"no fire"`, `"no metal"`, `"no vocals"`, `"no reverb"`).
- **Model selection learned from Gate 1 A/B:** Use `eleven_text_to_sound_v2` for crisp percussive/kinetic transients (`t=0` sharp cannons, rail cracks, flak, structural cable snaps) where Gate 1 showed v2 held tighter onset timing than v3; use `eleven_text_to_sound_v3` for sustained beams, plasma/ion energy, alien organic textures, crystal harmonics, shield collapses, UI drones, and seamless ambience.
- **Take count discipline:** Gate 2 uses **2 takes per SFX** (to expose take-to-take variance and avoid unfairly rejecting a strong prompt on one odd roll) and **1 take per music prototype / 20 s ambience**. Gate 3 expands approved core combat cues to **3 takes** (or 4 per RULEBOOK 8.4 for ultra-frequent shots) for true round-robin variation, and pulls **4 stems** only on Ryan-approved Gate 3 songs.

---

## 3. Complete 26-Weapon Roster -> 3-Layer Atomic Audio Map

Every weapon in `godot/rules/data/tables.json` (`W` table) maps to a distinct sonic identity using **3 timed atomic layers** in `godot/audio/cues.json` + `godot/audio/sfx.gd`:
- **Layer A (`t = 0.00 s`):** Crisp weapon-specific attack transient (never muffled, zero pre-delay).
- **Layer B (`t = 0.00 s`):** Caliber (`w`) and ship-class (`S/M/L/XL`) scaled low-end body weight (frigates sound tight and surgical; capitals shake the hull).
- **Layer C (`t = +0.08` to `+0.25 s`):** Faction-specific mechanical/energy recoil tail (`wep_mech_recoil_tail` on kinetic hulls, electronic heat-sink whine on Directorate, wet valve recoil on Chorus, prism harmonic fade on Glasswrights, cold magnetic cutoff on Eclipse).

| Faction | `tables.json` Weapons | Gate 2 Prompt ID(s) | Sonic Signature |
|---|---|---|---|
| **Sunward Crusade** (`voidsworn`) | `battery` (4), `hbattery` (5), `turret` (2), `autocannon` (3), `lance` (1), `torp` (1), `flak` (3) | `wep_sunward_battery`, `wep_sunward_hbattery_salvo`, `wep_sunward_turret_twin`, `wep_sunward_autocannon`, `wep_sunward_lance_beam`, `wep_sunward_torp_launch`, `wep_flak_airburst`, `wep_mech_recoil_tail` | Forged-iron kinetic mass-drivers, rolling 5-gun capital flank salvos, scorching solar-furnace thermal lances, fusion-boosted heavy space torpedoes |
| **Meridian Directorate** (`hegemony`) | `laser` (2), `turbo` (2), `hturbo` (3), `ion` (1), `flak` (3) | `wep_directorate_laser`, `wep_directorate_hturbo`, `wep_directorate_ion_beam`, `wep_flak_airburst` | Cold clinical directed-energy pulses, regulated heavy twin turbolasers with heat-sink whine, overpowering blue-arc EMP ion beams |
| **Ashfall Hullbreakers** (`corsair`) | `scatter` (5), `htorp` (2), `torp` (1), `autocannon` (3), `turret` (2), `flak` (3) | `wep_hullbreaker_scatter`, `wep_hullbreaker_rockets`, `wep_sunward_torp_launch`, `wep_sunward_autocannon`, `wep_sunward_turret_twin` | Brutal raw shrapnel-cannon bark with rattling iron scrap, raspy dual solid-fuel salvage rockets |
| **The Chorus** (`chorus`) | `spores` (3), `bioplasma` (2), `tendril` (2), `sporeb` (2) | `wep_chorus_spines`, `wep_chorus_bioplasma`, `wep_chorus_tendril`, `wep_chorus_sporeb` | Dry snapping chitin spines, pressurized boiling acid-glob heave, colossal 60 m bone-and-sinew tendril hull crush, heavy living bio-torpedo launch |
| **The Glasswrights** (`ithar`) | `shard` (3), `turret` (2, prism), `pulsar` (2), `startorp` (1), `flak` (3) | `wep_ithar_shard`, `wep_ithar_pulsar`, `wep_ithar_startorp` | Razor cut-crystal prism snaps, singing quartz-chord solar pulsar beams, radiant star-corona torpedo chimes |
| **Eclipse** (`deathless`) | `gsentry` (2), `gauss` (3), `nlance` (3), `doom` (1), `flak` (3) | `wep_eclipse_gsentry`, `wep_eclipse_gauss_charge`, `wep_eclipse_gauss_fire`, `wep_eclipse_nlance`, `wep_eclipse_doom` | Cold automated magnetic double-snaps, substation-transformer charge into shattering supersonic railgun whip-crack + hypersonic wake, triple cold void cuts, world-ending gravity-well Doom discharge |
| **Strike Craft** | `guns` (3), `bombs` (2) | `wep_craft_guns`, `wep_craft_bombs` | Agile rapid interceptor bursts and compact bomber ordnance strikes, clearly lighter than capital weapons |

---

## 4. Tying Audio Directly into the Cohesive R416 Pipeline (`#1741`)

Audio reads the exact same runtime events and faction metadata (`godot/fx/faction_looks.json`, `HULL.target_substance`, `voidsworn_destruct`) as visual Wounds V2 (`#1741`):

| R416 Stage | Runtime Signal / Hook | Audio Cue(s) Triggered |
|---|---|---|
| **1. Ship Build -> Weapons** | `tables.json` `w`, ship class band (`S/M/L/XL`), shooter `faction` | `sfx.gun()` scales Layer B body gain/rate by ship band + weapon weight; Layer C adds faction mechanical/energy tail. |
| **2. Weapon Effects (Shields & Target Armor)** | `HULL.target_substance(target_fac)` (`metal`, `glass`, `bio`, `obsidian`) + `shield_style` (`0..3`) | Expand `HIT_BY_TARGET` in `godot/audio/sfx.gd` to cover all 4 substances (`imp_metal_heavy`, `imp_glass_armor`, `imp_bio_acid`, NEW `imp_obsidian_eclipse`); split `shield_break` into `shd_break_energy` (`veil`/`hex`/`patchy`) and `shd_break_prismatic` (Glasswrights). |
| **3. Weapon Damage (Graze vs Real `K_HOLE` Cutout)** | `#1741` `fx_breach.gd` opens a new mid-battle 3D cutout into authored interiors | Surface grazes keep standard contact hit; opening a new `K_HOLE` triggers `dmg_breach_open` (alloy shear + rapid vacuum decompression hiss) anchored at the open breach position. |
| **4. Ship Damage & Capability Loss** | `u["weapons"][i]["off"] > 0`, `_eng_damage_tier`, `shield_offline`, Glasswright fractured panes | Exact slot knockout -> `dmg_turret_knockout` at that turret; engine loss -> faction-safe drive sputter (matching the `#1741` `fx_ship.gd:331` soot-leak fix); shield-generator offline -> intermittent `dmg_shield_burnout` crackles; Glasswright structural strain -> `death_ithar_shatter` light layer. |
| **5. Ship Destruction** | `godot/audio/death_audio.gd` synced to FX fracture clock | `death_directorate_blackout` (Directorate), `death_hullbreaker_snap` (Hullbreakers), `death_chorus_rupture` (Chorus), `death_ithar_shatter` (Glasswrights), `death_eclipse_shear` (Eclipse), retaining `death_audio.gd` core-flash ducking (`-9 dB`) and capital near-silence beat (`-26 dB`). |
| **6. Adaptive Multi-Stem Music** | `godot/music/music_player.gd` reading battle intensity (`shots`, breached ships, flagship presence, deaths) | Replace unrelated calm/hot crossfades with **one coherent 90 to 120 s track per faction**, split into 4 ElevenLabs stems in Gate 3 (`drums/perc`, `bass/low strings`, `brass/motif`, `pads/faction color`) played in lockstep (`AudioStreamSynchronized`): maneuvering (low strings + faction color) -> mid-battle breaches (percussion + drive) -> flagship climax (full motif), ducking under capital death beats. |

### Music Palette Across All 6 Factions (Shared 4-Note *Embers* Motif, Distinct Instruments)
- **Shared Signature:** A dark, austere 4-note recurring motif in D minor / D Dorian (weathered low brass + bowed cello) so every screen feels like *Embers of the Hollow Sun*.
- **Sunward Crusade:** Weathered low brass, solemn cellos, subtle forge-metal resonances, measured war percussion.
- **Meridian Directorate:** Taut cold rhythmic strings, precise electronic pulse, clipped dry brass stabs.
- **Ashfall Hullbreakers:** Gritty bowed metal, heavy syncopated industrial scrap drums, rough detuned low bass.
- **The Chorus:** Unsettling low contrabassoon/reeds, organic slow pulsing sub-bass, eerie scraping bone-like string harmonics.
- **The Glasswrights:** Shimmering glass harmonica, high ethereal sustained strings, crystalline bell overtones over a warm deep pulse.
- **Eclipse:** Glacial hollow sub-brass, sparse resonant obsidian chimes, tense wide pockets of dark silence.

---

## 5. Gate 2 Budget & Dry-Run Math

- **Manifest:** `contrib/opus/sound/elevenlabs_pilot_v2.json` (**47 items**: 44 short SFX x 2 takes + 1 seamless 20 s bridge ambience x 1 take + 2 multi-section music prototypes x 1 take = **91 files**).
- **Verified `elevenlabs_gen.js --dry` estimate:** **7,401 credits** (~6.1% of the 121,000 Creator monthly credit pool; Gate 1 + Gate 2 combined stay under 8% of one month's pool, leaving >110,000 credits for Gate 3 full 3-take production + 4-stem music!).

---

## 6. Explicit Pressure-Test Checklist for Astra and Fable

Before Ryan runs Gate 2 on the PC, please attack this plan and every prompt in `contrib/opus/sound/elevenlabs_pilot_v2.json` on:
1. **Prompting traps & scale drift:** Are there ANY remaining phrases in the 47 prompts that could trigger ElevenLabs into domestic/small-scale foley (like Gate 1's Velcro, duct tape, kitchen glass, balloon hiss, or bare-hand slap) or ocean/naval ship cliches?
2. **Timing & `t=0` sync discipline:** Do any `wep_*` or `imp_*` prompts accidentally invite pre-delay build-up before the visual flash/impact, or try to cram two separate gameplay beats into one clip when Godot should trigger them separately (e.g., should `wep_eclipse_gauss_fire` stay unified shot+wake or split back into shot vs Doppler flyby)?
3. **Overlap vs gaps across the 26-weapon roster:** Which weapons will feel too close together in battle, and are any high-frequency cues missing (for example, missed-shot pass-by whooshes, plasma/las impacts vs heavy metal impacts, or `ui_click`/`ui_confirm`; note PR #1590 left menu clicks to free Sonniss/CC0 switches, so should we test 2 ElevenLabs mechanical sci-fi bridge UI switches in Gate 2 too)?
4. **Music prompt & Gate 3 stem-separation risk:** Does `mus_battle_sunward_proto` pack too much structural change into 90 s for clean looping and 4-stem adaptive mixing in Godot `AudioStreamSynchronized` (e.g., if the percussion stem is silent in the first 30 s, turning up the percussion stem at `t=0:10` during an intense turn 1 gives silence until `0:30`! Should Gate 3 tracks be **consistent-groove multi-section** where all 4 stems have musical content throughout while the *melodic/harmonic progression* evolves over 90 to 120 s, so Godot can freely fade stems in and out at any timestamp)?
5. **Credit optimization:** Should Gate 2 run `takes: 2` on all 44 SFX (7,401 credits) or `takes: 1` on the first sweep (~4,500 credits) with `takes: 2` only on the hardest 10 weapon/impact prompts?
6. **Godot wiring (`sfx.gd`, `death_audio.gd`, `music_player.gd`):** Any voice-cap, bus-reverb, `salvo_tail`, or `audio_check.gd` hazards when introducing 3-layer weapon composition, `K_HOLE` breach-open triggers, and `AudioStreamSynchronized` 4-stem playback?
