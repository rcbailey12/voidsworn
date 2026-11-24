# Cohesive Sci-Fi Audio V2: Clean-Slate Sound Bible, Gate 2 Prompt Pack, and R416 Pipeline Wiring

Issue #1752 (linked to #1585, #1572, #1741, #1743, #1689). Prepared for **Astra and Fable pressure-testing** before running Gate 2 on Ryan's PC. Fable's review (Nov 22, claude-fable-5-2 through the Claude API) is folded in; see section 6.

---

## 1. Why Clean Slate (Gate 1 Ear-Audit Diagnosis)

Direct ear-by-ear listening of all 27 Gate 1 ElevenLabs samples (`board/pc-out-pilot1585`) against current-game baselines (`today*.ogg`, `godot/music/tracks/fac_voidsworn.ogg`) confirmed that **ElevenLabs is a massive fidelity jump** over the legacy synth and free clips, while proving Gate 1's prompt doctrine had systemic flaws:

1. **Muffled house prompt suffix ruined weapon nuance:** Appending `"Heard from inside a warship's hull: weighty low end, soft top"` to every weapon cue stripped out crisp high-frequency attack transients. Separately, the `ladder_macro` prompt listed "heavy breech block slamming" before the thump, so the model played a ~250 ms breech clack first, lagging the muzzle flash at `t=0`. Prompt order is playback order.
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

- **Space / sci-fi only, never ocean/naval:** Every ship is a colossal void-borne spacecraft fighting around a dying star (RULEBOOK / `docs/playbooks/factions.md`: *"Space ships, not sea ships"*). Ban ocean/maritime triggers (`naval`, `boat`, `submarine`, `wooden deck`, `gunpowder cannonball`, `foghorn`, `broadside`, `warship`, `torpedo tube`, `leviathan`, `abyssal`, `wake`, and sustained low-brass swells on UI stings inside ElevenLabs prompts) so the model stays locked on orbital kinetic railguns, thermal lances, directed-energy turbolasers, optical prisms, alien bio-leviathans, and ancient obsidian monoliths.
- **Zero pre-delay on `t=0` weapon attacks:** Every firing transient must start at `0.0 s` to land on the muzzle flash in `godot/fx/fx_weapons.gd`. Wind-ups go in the engine's existing charge slot (`CHARGE_LEAD` in `sfx.gd`), never inside the shot clip. Fire clips contain no impact (a hit baked into a fire clip would play on a miss or a shield block). Every delivered file is onset-measured and trimmed; prompt wording alone does not guarantee t=0, so prompts carry no numeric timings. Mechanical tails are a separate per-volley cue at pri 0, not a delayed layer inside a `gun_` cue (`sound_weight_check.gd` fails that).
- **Close and dry, firm clean attack, no harshness:** Replace the hull-muffle suffix with "close and dry, firm clean attack, strong low body". Keep the playbook's "weight without harshness" (`docs/playbooks/sound.md` section 1): no "razor-sharp", "piercing", "shattering" or "loud". `sfx.gd` has no distance or class filter today (distance only scales gain), so the source itself must not be shrill. One size word per tier: light for point defense and craft, mid for guns, heavy for lances and torpedoes, "colossal" only for Doom and deaths.
- **Ban literal domestic foley words AND pink-elephant negative nouns:** Never prompt `"tearing rip"`, `"peeling"`, `"slap"`, `"rush of breath"`, `"locking clamps"`, or bare `"glass shatter"`. Also never: `tearing`, `ripping`, `sizzling`, `boiling`, `bubbling`, `hiss` without a scale anchor, `chime`, `cut-crystal`, `whip-crack`, `bark`, `shotgun`, `pops`, `ping`, `steam`, `vacuum`, and words with a second meaning (`organ`, `horn`). No design notes inside prompts ("so fleet arrivals stack cleanly"); the model cannot act on them. Equally important, **never put concrete unwanted nouns inside negative phrases** (like `"no balloon"`, `"no Velcro"`, `"no boat wood"`, `"no kitchen glass"`), because generative audio models can still attend to those concrete nouns! Use pure positive physical-scale anchors (`"ten-meter-thick crystal hull"`, `"glacier-sheet fracture"`, `"monolithic basalt slab"`, `"substation transformer"`, `"sixty-meter bone-and-sinew tendril"`), keeping negatives strictly to universal acoustic classes (`"no explosion"`, `"no fire"`, `"no metal"`, `"no vocals"`, `"no reverb"`).
- **Model selection learned from Gate 1 A/B:** Use `eleven_text_to_sound_v2` for crisp percussive/kinetic transients (`t=0` sharp cannons, rail cracks, flak, structural cable snaps) where Gate 1's single A/B pair suggested tighter onsets on v2 (Gate 2 re-tests this with two same-prompt v3 twins, `wep_sunward_battery_v3ab` and `imp_metal_heavy_v3ab`; v2 is listed for removal on Mar 1 2027, so any family approved on v2 must have all its takes generated before then); use `eleven_text_to_sound_v3` for sustained beams, plasma/ion energy, alien organic textures, crystal harmonics, shield collapses, UI drones, and seamless ambience. **Updated by the Wave A ear audit (section 7):** v2 is now only for fast dry kinetic shell guns; rail cracks, Eclipse, impacts, deaths and all energy weapons go on v3.
- **Wave A lesson (Nov 23 2026): identity first, weight second.** (Superseded for the prompt wording by the Wave A ear audit and Wave A2 rewrite, section 7, PR 1794; the identity-first rule stands.) Every weapon prompt carried the same "close and dry, firm attack, strong low body, deep and weighty" tail, so every take came back as the same low boom (spectral centre 50 to 400 Hz on all five factions). It suits the Sunward shell guns and nothing else: Ryan heard the Directorate plasma, every Chorus sound and the Eclipse gun as off. Non-Sunward prompts now open with what makes the faction different (plasma zap, wet gristle and bone, cold magnetic crack and hollow ring), drop the low-body boilerplate, run on v3 at influence 0.75, and leave weight to the engine's Layer B body test (`wep_layer_body_heavy`). Re-rolled ids: `wep_directorate_laser`, `wep_chorus_spines`, `imp_bio_flesh`, `death_chorus_rupture`, `wep_eclipse_gauss_fire`. The same rule applies to every Wave B prompt for those factions before Wave B runs.
- **Take count discipline:** Gate 2 uses **2 takes per SFX** (3 for `ui_click_switch`, 1 for the reference salvo and the A/B twins; one take could not tell a bad prompt from a bad roll in Gate 1, and the second take costs about half a percent of the pool at Gate 1's real billing), run in two waves with `--only`: Wave A (14 items, see section 5) first, the rest after onset, scale and v2 versus v3 checks, and **1 take per music prototype / 20 s ambience**. Gate 3 expands approved core combat cues to **3 takes** (or 4 per RULEBOOK 8.4 for ultra-frequent shots) for true round-robin variation, and pulls **4 stems** only on Ryan-approved Gate 3 songs.

---

## 3. Complete 26-Weapon Roster -> One Shot per Clip

Every weapon in `godot/rules/data/tables.json` (`W` table) maps to a distinct sonic identity. Gate 2 clips are **single-shot composites, one per shot**, for judging identity by ear: the engine already plays one gun cue per shot and staggers a volley (`battle.gd` per-shot call, `cues.json` gap and defer, `sfx.gd` salvo logic), so no clip bakes a volley except the labelled reference salvo `wep_sunward_hbattery_salvo` (1 take, never wired).
- **Three-layer split is a Gate 3 question:** an attack (t=0), a caliber and ship-class low body (t=0), and a faction tail.
- **Tested now on one item only:** `wep_layer_body_heavy` (low body alone). If it does not add weight under a single-shot composite, Gate 3 stays single-clip.
- **The tail is its own per-volley cue at pri 0** (`wep_mech_recoil_tail`), like `PASS_BY_CUE`; it is not `salvo_tail` (which fires once per volley on the fourth shot) and never a delayed layer inside a `gun_` cue.

| Faction | `tables.json` Weapons | Gate 2 Prompt ID(s) | Sonic Signature |
|---|---|---|---|
| **Sunward Crusade** (`voidsworn`) | `battery` (4), `hbattery` (5), `turret` (2), `autocannon` (3), `lance` (1), `torp` (1), `flak` (3) | `wep_sunward_battery`, `wep_sunward_hbattery` (+ reference `wep_sunward_hbattery_salvo`), `wep_sunward_turret`, `wep_sunward_autocannon`, `wep_sunward_lance_beam`, `wep_torp_eject` + `wep_sunward_torp_launch`, `wep_flak_airburst` | Iron and propellant shell guns ("magnetic" is reserved for Eclipse), heavy flank battery staggered by the engine, scorching solar-furnace thermal lances, fusion-boosted heavy space torpedoes |
| **Meridian Directorate** (`hegemony`) | `laser` (2), `turbo` (2), `hturbo` (3), `ion` (1), `flak` (3) | `wep_directorate_laser` (shown as Plasma cannon), `wep_directorate_turbo` (Plasma battery), `wep_directorate_hturbo` (Heavy plasma battery), `wep_directorate_ion_beam`, `wep_directorate_picket` (flak, shown as Picket lasers) | High-voltage substation breaker slams, dense strictly flat-pitch electric arc pulses (v3, zero laser chirps), overpowering continuous ion beams |
| **Ashfall Hullbreakers** (`corsair`) | `scatter` (5), `htorp` (2), `torp` (1), `autocannon` (3), `turret` (2), `flak` (3) | `wep_hullbreaker_scatter`, `wep_hullbreaker_junk_gun` (turret, autocannon), `wep_hullbreaker_rockets` (torp and htorp; `sfx.gd` already routes corsair torps to `torp_rocket`), `wep_flak_airburst` | Ragged overdriven scrap cannon with a loose rattling housing, rough solid-fuel rockets (rattling junk, per `sound.md`) |
| **The Chorus** (`chorus`) | `spores` (3), `bioplasma` (2), `tendril` (2), `sporeb` (2) | `bioplasma` (shown as Spine volley) -> `wep_chorus_spines` or `wep_chorus_bioplasma` (confirm the projectile look before wiring); `tendril` -> `wep_chorus_tendril` (fire side only); `spores` (k flak, Spore cloud) -> `wep_chorus_spore_cloud`; `sporeb` (k sq, strike-craft Acid sacs) -> `wep_chorus_sporeb` | Colossal non-vocal bio-structural physics: deep hydrostatic pressure-cannon thumps, fracturing petrified bone/carapace cliffs, ancient hollow timber-and-bone hull strains, pressurized mineral gas blowouts (zero creature/monster/flesh vocal triggers) |
| **The Glasswrights** (`ithar`) | `shard` (3), `turret` (2, prism), `pulsar` (2), `startorp` (1), `flak` (3) | `wep_ithar_shard`, `wep_ithar_needle` (turret, shown as Needle beam, thinner and longer than a shard), `wep_ithar_pulsar`, `wep_ithar_startorp`; `flak` (Mirror veil): no clip until its look is confirmed | Hyper-velocity crystalline prism discharges over 150 Hz cathedral sub-harmonics, sustained optical choir-beams, glacier-scale crystalline fractures |
| **Eclipse** (`deathless`) | `gsentry` (2), `gauss` (3), `nlance` (3), `doom` (1), `flak` (3) | `wep_eclipse_gsentry` (also `flak`, Null shredder), `wep_eclipse_gauss_charge` (once per volley, needs a new hook), `wep_eclipse_gauss_fire` (one shot, no wake), `wep_eclipse_nlance` (one pulse per fire time), `wep_eclipse_doom_charge` + `wep_eclipse_doom` (Corona arc) | Seismic-charge / gravitational void tears on v3: dark electrostatic void snaps into crushing 40 Hz sub-bass drops and cold bowed-obsidian resonance cutting abruptly into dead silence |
| **Strike Craft** | `guns` (3), `bombs` (2) | `wep_craft_guns` (the one baked burst kept), `wep_craft_bombs` (release only, the hit comes from the impact cue) | Agile rapid interceptor bursts and compact bomber ordnance strikes, clearly lighter than capital weapons |

| **Shared** | missed shots | `evt_pass_by_slug` | Today one generic whoosh serves every weapon (`sfx.gd` `PASS_BY_CUE`) |
---

## 4. Tying Audio Directly into the Cohesive R416 Pipeline (`#1741`)

Audio reads the exact same runtime events and faction metadata (`godot/fx/faction_looks.json`, `HULL.target_substance`, `voidsworn_destruct`) as visual Wounds V2 (`#1741`):

| R416 Stage | Runtime Signal / Hook | Audio Cue(s) Triggered |
|---|---|---|
| **1. Ship Build -> Weapons** | `tables.json` `w`, ship class band (`S/M/L/XL`), shooter `faction` | One single-shot clip per weapon family, played once per shot by the existing per-shot path. Body weight by ship band is a Gate 3 test (`wep_layer_body_heavy`); a faction tail is its own per-volley cue at pri 0. |
| **2. Weapon Effects (Shields & Target Armor)** | `HULL.target_substance(target_fac)` (`metal`, `glass`, `bio`, `obsidian`) + `shield_style` (`0..3`) | `impact_cue` returns the target cue first, so metal must not join `HIT_BY_TARGET` (that would make `hit_las`, `hit_plasma`, `hit_rail`, `hit_ion` and `hit` unreachable and fail `audio_check.gd`). Add `deathless` -> `imp_obsidian_eclipse` and replace `hit_wet` with `imp_bio_flesh`; `ithar` keeps `hit_glass` <- `imp_glass_armor`. Metal stays on the weapon-family path (`imp_metal_light` for `hit`, `imp_metal_heavy` for `hit_heavy`, `imp_energy_sear` for `hit_las`/`hit_plasma`). `imp_acid_on_metal` is a weapon-side cue. Shields: `shd_hit_absorb` for an ordinary block (quiet, R412 rule 4), `shd_break_energy` (`veil`/`hex`/`patchy`) and `shd_break_prismatic` (Glasswrights). Prefer faction variants of existing cues: a new cue id fails `audio_check.gd` unless it joins `CUE_FAMILIES`. |
| **3. Weapon Damage (Graze vs Real `K_HOLE` Cutout)** | `#1741` `fx_breach.gd` opens a new mid-battle 3D cutout into authored interiors | Surface grazes keep the contact hit; a new `K_HOLE` plays `dmg_breach_vent` on every hull, plus `dmg_breach_shear_metal` on metal hulls only (glass, bio and obsidian use their own impact cue for the opening, so no metal sound on a Chorus or Glasswright breach). |
| **4. Ship Damage & Capability Loss** | `u["weapons"][i]["off"] > 0`, engine tier, shield generator offline (`fx_ship.gd` capability block, `GEN_GAP` 1.4 to 3.0 s) | Slot knockout: `dmg_turret_knockout`, metal hulls only (`fx_ship` already skips sparks on Chorus), at most one per ship per sync (a lost section sets several slots off at once). Engine loss: `dmg_engine_fail` (not Chorus). Generator: one 0.6 s `dmg_shield_burnout` crackle at full level on the first, later repeats quiet with `max` 1 (it repeats for the rest of the battle). Glasswright strain uses a separate Gate 3 take, not the death clip. All behind `VS_WOUNDS_V2` (`godot/fx/fx_wounds_flag.gd`), the same flag the visuals read. |
| **5. Ship Destruction** | `godot/audio/death_audio.gd` synced to FX fracture clock | `death_metal_break` (the `boom_l` base every death plays), `death_sunward_magazine` (one pulse per accepted Sunward magazine flash; `fx_death.gd` already schedules them and rejects hidden hulls), `death_directorate_blackout`, `death_hullbreaker_snap`, `death_chorus_rupture`, `death_ithar_shatter`, `death_eclipse_shear`, keeping `death_audio.gd` core-flash ducking (`-9 dB`) and the capital near-silence beat (`-26 dB`). New clips are longer than today's cue durations (`death_crack` 0.4 s, `death_powerdown` 0.6 s, `lance_charge` 0.32 s, `arrive_jump` 0.45 s), so each variant sets its own duration or it gets faded. |
| **4b. Event edges (Astra review 1754)** | Accepted cutout result, capability snapshot, quadrant break | Sound a breach from the accepted cutout at its world centre, including a surface mark promoted to an opening, never on a graze, reheat or mesh rebuild. Capability cues fire on transitions only: a newly off slot once at its turret or fixed mount, an increased engine tier, `gen_down` on its false-to-true edge; seed the first snapshot quietly and clear on repair, death, revive and teardown. Pass the victim's shield style into both shield-break paths, and allow a hull contact only when hull damage also landed. Lances and torpedoes other than the null lance start only at their first fire time today; schedule each release (two-pulse pulsar, two-launch rocket rack) with the charge before the first. Gauss needs its own charge hook: replacing the shared `lance_charge` sample would change every lance. The 20 s bridge bed uses the length-aware ambient clip path, not the baked bed's loop offset. |
| **6. Adaptive Multi-Stem Music** | `godot/music/music_player.gd` (today: three independent loops crossfaded by one smoothed intensity; `feed()` has no breach or death inputs yet) | One coherent 90 to 120 s **loop** per faction in which all parts play in every bar: it evolves by chord progression and motif variation, never by adding instruments, and only the mixer changes intensity. A built-in three-part arc would fight the stem gains (raise percussion at 0:10 and hear silence until 0:30; at 1:00 the "calm" stems play the climax). Split into stems in Gate 3 only after one stem-separation test on `mus_battle_sunward_stemloop` shows which stems the service returns (it may return drums, bass and "other", not brass apart from pads). Fallback that fits today's code: three layers on the existing `calm`, `intense` and `bed` slots. Gate 3 wiring plan (Ryan, Nov 22 2026): build on Godot 4.7's native `AudioStreamSynchronized` (stems in lockstep) and `AudioStreamInteractive` (clip transitions), plus a slow-motion low-pass filter on the `battle_sfx` bus. Wiring notes: loop is set only on Ogg streams (MP3 stems need transcoding and identical cut points); faction preview ids must begin `fac_`; the boss swap replaces the hot layer. |

### Music Palette Across All 6 Factions (Shared 4-Note *Embers* Motif, Distinct Instruments)
- **Shared Signature:** A dark, austere 4-note recurring motif in D minor / D Dorian (weathered low brass + bowed cello) so every screen feels like *Embers of the Hollow Sun*. Target notes D, A, F, E. Whether separate prompts can share a motif is a Gate 2 test, not a given; if the two prototypes do not share it, drop the motif claim before Gate 3 and rely on key, tempo family and shared instruments. Title, map and the victory and defeat stings stay on today's tracks for Gate 2.
- **Sunward Crusade:** Weathered low brass, solemn cellos, subtle forge-metal resonances, measured war percussion.
- **Meridian Directorate:** Taut cold rhythmic strings, precise electronic pulse, clipped dry brass stabs.
- **Ashfall Hullbreakers:** Gritty bowed metal, heavy syncopated industrial scrap drums, rough detuned low bass.
- **The Chorus:** Unsettling low contrabassoon/reeds, organic slow pulsing sub-bass, eerie scraping bone-like string harmonics.
- **The Glasswrights:** Shimmering glass harmonica, high ethereal sustained strings, crystalline bell overtones over a warm deep pulse.
- **Eclipse:** Glacial hollow sub-brass, sparse resonant obsidian chimes, tense wide pockets of dark silence.

---

## 5. Gate 2 Budget & Dry-Run Math

- **Manifest:** `contrib/opus/sound/elevenlabs_pilot_v2.json` (**72 items, 138 files**): 68 short SFX at 2 takes (3 for `ui_click_switch`, 1 for the reference salvo and the two A/B twins), the 20 s bridge ambience at 1 take, and 3 music prototypes at 1 take (90 s showcase arc, 40 s stem-ready loop, 48 s reward theme).
- **`elevenlabs_gen.js --dry` estimate: 8,954 credits** (generator rates: 40 per second of SFX, 900 per minute of music; updated after Wave A2 duration/model upgrades). Wave A billed SFX at ~11 real credits per second against the estimated 40 (298 charged against 1,060 estimated), so real spend for the full pack is expected near **4,500**, about 3.7% of the 121,000 pool. Music rows count at the estimate.
- **Hold-back option (7,574):** leave out the stem loop and six optional items (`wep_hullbreaker_junk_gun`, `wep_layer_body_heavy`, `dmg_engine_fail`, `death_metal_break`, `ui_turn_start`, `evt_pass_by_slug`). Not recommended: each fills a gap a reviewer found.
- **Takes 2 versus 1:** 1 take on every SFX would be 5,113 by the generator's rates; the second take costs about 630 real credits. Keep 2: the scarce resource is Ryan's listening time, not credits.
- **Run in waves:**
  - **Wave A (done, 298 real credits billed):** 14 items, 27 takes (`board/pc-out-wavea1752`). Exposed 3 systemic prompt traps; only 3 of 14 items cleared an AAA bar (see section 7).
  - **Wave A2 (historical, 10 items, 20 takes, 272 real credits billed):** the command and its manifest revision are recorded in section 7.
  - **Wave B:** run the remaining items with `--max-credits 9600` after Wave A3 clears Ryan's ear check and the prompt updates in section 8 are applied. Any re-roll writes to a fresh, revision-named output folder and its dry run must show every take as still to make (the generator skips a file whose name and size match, whatever the prompt).
- **Listening page:** each item's `today` field names its baseline cue exactly (`cue` or `cue:variant`, null for no clip today); `listen_page.js` reads it before the free-text `cue` label (Artoo, PR 1753 finding 1). The page should also stitch single shots at the `cues.json` gaps so Ryan hears what the engine will do with a volley.

---

## 6. Pressure-Test Results and Ryan's Open Calls

**Reviews.** Artoo (technical review, PR 1753 @ 72e6aa15): listening-page variant parsing and per-shot versus per-volley wiring, both applied. Fable (claude-fable-5-2, Nov 22, full text `contrib/opus/reviews/sound_gate2_fable_1753.md`): verdict "spend after edits"; its Blocking and High fixes are applied in this file and the manifest (one shot per clip; no wind-up or hit inside a fire clip; roster mapping corrected against `FAC_WNAMES`; trap words removed; harsh words removed; impact routing, breach, capability and music wiring notes above; reward and battle music rebuilt on whole bars). Astra's blind review (issue 1754, PR 1762, `contrib/codex/reviews/astra_sound_gate2_1753.md`) is folded in too: it independently found the same baked volleys, wind-ups, roster mismatches, impact-routing trap and 94 BPM bar problem, and added four sounds (`wep_directorate_turbo`, `wep_ithar_needle`, `imp_las`, `death_sunward_magazine`) and the event-edge rules in row 4b. Artoo's second pass (PR 1761 @ 3afd6670): the listening page now honours `replace` variants and synth fallback the way `sfx.gd` does.

**Where Astra and Fable disagree (this file follows the pick shown):**
- **Takes.** Astra: 1 take on everything first (about 5,357 estimated with its additions), buying a second take only for a named doubt. Fable: 2 takes, run in two waves, because Gate 1 billed about 11 credits per second, so the second take costs roughly 650 real credits. **Kept 2 takes and two waves.** If real billing in Wave A is near the generator's 40 per second, drop Wave B to 1 take.
- **UI and boss sting.** Astra proposes electronic console clicks and an electronic boss interval. Fable proposes recorded mechanical switches and an orchestral boss sting. **Kept Fable's:** Ryan dislikes electronic UI cues.
- **Reward music.** Astra: 64 BPM, 12 bars, a single-play underscore. Fable: 80 BPM, 16 bars, close to the Gate 1 `reward_preview` wording. **Kept Fable's;** it rides on Ryan's call 3 below.
- **Doom.** Astra: the Corona arc strikes at full strength with no pull-in. Fable: a separate pull-in clip in the charge slot, then the discharge at t=0. **Kept both clips;** the listening page decides if the pull-in earns its place.
- **Mechanical tail.** Astra: a return layer inside one accepted shot cue. Fable: its own per-volley cue at pri 0 (a delayed layer inside a `gun_` cue fails `sound_weight_check.gd`). **Kept Fable's** for Gate 2; it is a Gate 3 wiring choice either way.
- **Sunward Sear guns.** Astra wrote them as sear pulses (heat bolts); Fable as shell guns. That is Ryan's call 1 below. No Gate 2 credits are spent before the Board merges.

**Ryan's three calls: all three locked as A (Ryan, Nov 22 2026, 21:41 UTC). The manifest carries A; B stays written out below as the record.**
1. **Sunward "Sear" guns: shell guns or heat bolts?**
   - **A, shell guns (picked, in the manifest):** iron and propellant cracks with a forged-iron ring (`wep_sunward_battery`, `wep_sunward_hbattery`, `wep_sunward_turret`, `wep_sunward_autocannon`).
   - **B, heat bolts:** the same four ids reworded as superheated plasma bolts from a solar furnace: "an immediate dense searing heat-bolt discharge with a deep furnace roar and a solid low thump", keeping iron for the hull and recoil only. Same seconds and credits; it moves Sunward closer to the Directorate's plasma, so the Directorate keeps its capacitor-bank thump to stay apart.
2. **Eclipse: railgun crack or hollow low "null" note?**
   - **A, railgun (picked, in the manifest, softened):** a hard heavy magnetic slam with a short hollow cold tone (`wep_eclipse_gauss_fire`, `wep_eclipse_gsentry`).
   - **B, null note:** the same ids reworded to lead with "a deep hollow low tone that swells and cuts dead, like air pulled out of a vast stone hall", the magnetic slam reduced to a soft onset. Closer to `sound.md`'s "a low held note for Eclipse" and further from the Sunward guns; less punch in a volley.
3. **Reward music: is the one Ryan likes the Gate 1 `reward_preview` clip?**
   - **A, yes (picked):** `mus_reward_proto` keeps that clip's wording ("warm brass and strings, quietly triumphant, calm, not cheesy") on 16 whole bars, and the listening page plays `reward_preview` beside it as the control.
   - **B, no, it is a track already in the game:** name it on the Pick Sheet; the prompt is rewritten to describe that track's instruments and tempo, and `reward_preview` drops to an ordinary candidate.

**Follow-ups outside this pack (not Gate 2 blockers):** `docs/playbooks/sound.md` still says "Free tools and free sources only" and "a soft top"; both need a matching playbook edit with Ryan's ElevenLabs ruling when Gate 3 is planned (R214). The `eleven_text_to_sound_v2` removal date (Mar 1 2027) bounds any v2 family.

---

## 7. Wave A Ear-Audit Verdict and Global Prompt Upgrades

Wave A (`board/pc-out-wavea1752`, 27/27 takes generated, **298 real credits billed**, ~11 real credits/sec) succeeded as a calibration gate by exposing **3 systemic prompt traps** before spending Wave B (~111 files). Applying a strict AAA space-tactics bar across all 14 items / 27 takes showed **only 3 items currently clear the bar**:
- **PASS (keep):** `wep_sunward_battery` (`v2`, `t1` & `t2`; plus `wep_sunward_battery_v3ab_t1` as a heavier flagship reference), `imp_metal_heavy_v3ab` (`v3`, `t1`, proving `v3` owns heavy armor hits), and `ui_click_switch` (`v3`, `t1` & `t2` only; drop `t3` double-bounce).
- **REWORK (10 items -> 9 archetype rewrites + 1 `v2`-to-`v3` switch):** `wep_directorate_laser` (80s toy raygun chirp), `wep_eclipse_gauss_fire` (metal blast-door slam / pipe knock), `wep_chorus_spines` (wet meat slap / whip), `imp_bio_flesh` (fist punch into beef / mud stomp), `death_chorus_rupture` (literal zombie/monster vocal groan over celery crunch), `wep_ithar_shard` (teaspoon tapping a wineglass / marble on countertop), `wep_sunward_lance_beam` (fiery flamethrower blast / distant explosion instead of sustained focused cutting beam), `imp_metal_heavy` on `v2` (dumpster lid / dropped steel wrenches), `shd_break_energy` (70% fiery explosion BOOM / crumbling rocks), and `ui_reward_vault` (cold harsh iron prison padlock slam).

### Three Global Rules Applied Across `elevenlabs_pilot_v2.json` (50 of 72 Items Upgraded, Ryan Picks All A, Nov 22 2026)

1. **Fix the Tabletop Foley Scale Trap:** Replace literal tabletop/biological objects (`quartz block struck once`, `magnetic slam`, `creature`, `monster`, `flesh`, `sinew`, `muscle`, `hide`, `fluid`, `machined-metal latch`) with macro-scale physical anchors:
   - **Meridian Directorate (all 5 weapons, moved to `v3`):** High-voltage electrical substation breaker slam + dense high-current electric arc snap + pressurized electromagnetic sub-bass thump, **strictly flat steady pitch**, zero `"laser"` / `"sci-fi plasma"` phrasing.
   - **The Chorus (all 7 weapons/impacts/death, `v3`):** Colossal **non-vocal bio-structural physics**: deep hydrostatic pressure-cannon thumps, fracturing ten-meter petrified bone/calcified carapace cliffs, ancient hollow timber-and-bone tectonic collapse, pressurized gas blowouts. Zero creature/monster/flesh/muscle words.
   - **Eclipse (all 8 weapons/impacts/death, moved to `v3`):** **Seismic-charge / gravitational void tear**: crisp dark electrostatic void snap + crushing 40 Hz sub-bass drop + cold hollow bowed-obsidian resonance cutting abruptly into dead silence.
   - **The Glasswrights (all 7 weapons/impacts/shield/death, `v3`):** Hyper-velocity crystalline prism discharge + deep 150 Hz cathedral sub-harmonic punch + glacier-scale crystalline fractures.
2. **Eliminate Pink-Elephant Negative Leaks & Lock Model Routing:** Strip `"no explosion"`, `"no fire"`, and `"under heavy fire"` (which leaked explosion tokens directly into `shd_break_energy`). Restrict `eleven_text_to_sound_v2` strictly to fast dry kinetic shell guns (`wep_sunward_*` shell guns, `wep_flak_airburst`, `wep_hullbreaker_scatter`, `wep_hullbreaker_junk_gun`, `wep_craft_guns`); move **all impacts, all deaths, Directorate energy, Eclipse, and sub-bass layers to `v3`**.
3. **Stop Starving Beams, Shields, Cosmic Weapons, and Rewards with `"close and dry, no reverb"`:** Keep rapid shell guns and switch clicks dry; give sustained lances (`wep_sunward_lance_beam`), shield collapses (`shd_break_energy`), Glasswright crystal fire, Eclipse void drops, and UI rewards (`ui_reward_vault` blooming into warm low bronze + solemn cello/muted low-brass fifth) natural controlled acoustic decay.

### Historical Wave A2 Calibration Command

Wave A2 used **10 items / 20 takes** and a fresh output folder. This historical recipe requires the Wave A2 manifest at commit `183cd881111114acd1c422b5c477b69f418b591d` (the last A2 prompt edits before A3). Section 8 gives the current Wave B gate.

```bash
node contrib/opus/tools/sound/elevenlabs_gen.js \
  --list <wave_a2_manifest_from_pinned_commit> \
  --out <fresh_wavea2_out_folder> \
  --only wep_directorate_laser,wep_eclipse_gauss_fire,wep_chorus_spines,imp_bio_flesh,death_chorus_rupture,wep_ithar_shard,wep_sunward_lance_beam,shd_break_energy,ui_reward_vault,imp_metal_heavy \
  --max-credits 1200
```

- **Dry-run estimate:** ~976 credits (generator ceiling at 40/sec).
- **Expected real billing:** **~270 real credits** at Wave A's observed ~11 real credits/sec (~0.22% of the 121,000 credit pool).


## 8. Wave A2 Verdict and Wave A3 (Fable audit, Nov 23 2026)

Wave A2 (20 takes, 272 real credits) was ear-audited by Antigravity, and Fable audited that audit against the real files (`contrib/opus/reviews/sound_wavea3_fable_1752.md`).

- **Keepers:** `imp_metal_heavy` t1 and t2, `death_chorus_rupture` t2 (t1 only as an alternate with a presence lift), `ui_reward_vault` t1 and t2, `imp_bio_flesh` t1 and t2 (mastering below), `wep_eclipse_gauss_fire` t1. Re-check `ui_reward_vault` and the Eclipse take on small speakers: both are almost all below 500 Hz.
- **Measurement settled.** Claude re-measured all 20 takes per channel and mono-summed. Every channel agrees with Claude's table, not with Antigravity's (for example, the Directorate laser is 2% above 1 kHz on both channels). The takes are stereo and the game files are mono. Mono fold-down barely dulls most takes; the exceptions are very wide takes (Eclipse t1, shield t1, lance t1), so fold to mono before judging those. Several takes carry 4% to 14% of their energy below 20 Hz: high-pass the battle SFX bus.
- **Shared game files are real.** In the current game, `lance` and `gun_las` play the same file, and `imp_metal_heavy`, the Chorus death and the Eclipse gun share one 2 s rumble. That is the old game's file reuse, not a listening-page mistake.
- **Traps.** Bass-word stacking ("sub-bass", "sub-harmonic", literal Hz, and size words like colossal and monumental pulling low) is confirmed. "Smooth top end" is not the cause (the brightest takes carried it), but removing it is harmless. The beam and breaker wording traps are plausible, from one prompt each.
- **Influence.** Unchanged in Wave A3 except one lance twin, so each test changes one thing.
- **Wave A3:** 9 ids, 18 takes, about 223 real credits (tool estimate 800, cap 900). The six re-rolled prompts are `wep_sunward_lance_beam`, `shd_break_energy`, `wep_directorate_laser`, `wep_ithar_shard`, `wep_chorus_spines` and `wep_eclipse_gauss_fire`. There are three twins:
  - `wep_sunward_lance_beam_inf45`: same text at influence 0.45.
  - `wep_directorate_laser_b`: plasma-cannon wording, recipe B.
  - `wep_eclipse_gauss_fire_ctl`: the A2 prompt unchanged, as a control for the keeper.
- **Mastering for every keeper, before it goes in game:**
  - Trim the 10 to 32 ms of dead head.
  - Fold to mono.
  - High-pass at 30 to 40 Hz (60 to 70 Hz for `imp_bio_flesh`, about -6 dB below 200 Hz, about +6 dB above 1.5 kHz).
  - Match loudness per category rather than peak-normalising.
  - Fade every tail by 10 to 20 ms.
  - Tune the reward bell to D (it measures about 50 cents sharp of D3).
- **Wave B stays held** until Wave A3 clears Ryan's ear check. Fable's Wave B pre-flight rewrites (17 prompts plus 5 missed bass-trap items, section 3 of the review) are applied only after A3 shows which Directorate recipe, beam recipe and influence won. The ban-list question (relax "sharp" and "loud", keep the literal-foley bans) is decided at the same time.
- **Not generated:**
  - A beam may work better as ignition, a looped body and a release assembled in Godot, so it fits any beam length.
  - Shield break may be better layered (a new crackle over today's body) than one prompt.
  - Both are tried with the A3 takes before more spend.

### 8.1 Wave A3 Results and Neon's Ear Notes (Nov 23 2026, input until Ryan's own picks)

Wave A3 ran Nov 23 (`OPUS1752_WAVEA3B.bat`): all 18 takes, 224 credits. Relay: voidsworn-relay `pc-out-opus1752wavea3b`, folder `out_20261122_222753_165`. Listening page: https://claude.ai/artifact/FK5VJ8DZgzA3nuAAzWL6Am.

Neon's full notes are in `contrib/neon/reviews/sound_wavea3_ear_1752.md` (PR 1856). Claude re-checked Neon's stereo correlation, below-500 Hz share and loudness on all 18 takes with its own script, and they match to the decimal. These are Neon's calls. **Ryan's ear picks decide**, and Wave B stays held until he gives them.

- **Neon's keeps (7 of 18):**
  - `shd_break_energy` t1
  - `wep_directorate_laser_b` t1 and t2
  - `wep_ithar_shard` t1
  - `wep_sunward_lance_beam` t2
  - `wep_chorus_spines` t2 and `wep_eclipse_gauss_fire` t2 (dark-leaning: loudness match and a small-speaker check)
- **Neon's rejects:** everything else. `wep_ithar_shard` t2 is out of phase between left and right (correlation -0.29) and falls apart in mono.
- **Directorate: recipe B (plasma cannon wording) wins.** Recipe A came out small and quiet, like a relay spark. If Ryan agrees, the Wave B Directorate prompts (turbo, hturbo, picket, and the ignition of ion_beam) are rewritten on recipe B wording, not on Fable's recipe A block in section 3 of the Fable review.
- **Beams: influence 0.60 beats 0.45.** At 0.45 the takes went thin and hissy and lost 2 to 3 dB in mono.
  - Every lance take spends 95% of its energy by 0.3 to 0.5 s. The "fast falling power-down into silence" clause makes the model rush to the end.
  - For any Wave B beam that must sustain (ion_beam, pulsar, doom), drop that clause and build ignition, a looped body and a release in Godot, as section 8 already proposes.
- **Eclipse control: the new wording fixed mono, not the bass.** New t1 is 97% below 500 Hz.
  - Wave B Eclipse prompts drop "crushing seismic-charge cinematic bass" for midrange-anchored wording ("hard cold electrostatic snap", "hollow bowed-obsidian mid-low knock").
  - This adds to Fable's bass-trap phrase swaps.
- **Still open from section 8:** almost every keeper sits mostly below 500 Hz (the Directorate B lead take is 79%). Mastering (high-pass, presence lift, loudness match, mono fold) is required before any of them go in game, and the in-engine check against the battle music still decides.

**Ryan's Wave A3 ear picks (Nov 23 2026, 11:23 AM CT, on headphones). These decide; Neon's notes above are input.**

- **Sunward lance:** `wep_sunward_lance_beam` t1, not Neon's t2. That keeps influence 0.60 for beams.
- **Directorate:** recipe B t1. `wep_directorate_laser_b` t2 is not a variant: Ryan hears it as much lighter. Variation comes from small random pitch and volume on t1 in Godot, or from a later re-roll. Wave B Directorate prompts use recipe B wording.
- **Shield break:** `shd_break_energy` t1.
- **Glasswright:** `wep_ithar_shard` t1.
- **Chorus:** `wep_chorus_spines` t2.
- **Eclipse:** `wep_eclipse_gauss_fire_ctl` t2 (the old A2 wording), not Neon's new-wording t2.
  - This is the opposite of Neon's call.
  - On one speaker this take loses about 3 to 4 dB of its mids and highs and is 94% below 500 Hz.
  - A one-speaker check of this pick and the lance pick is on the listening page, because the game plays mono.
  - Mono or stereo (checked in `godot/audio/sfx.gd`, Nov 23): every battle sound with a position already plays through an `AudioStreamPlayer3D` with `panning_strength` 0.72. So players hear direction, left or right, from where the shot is on screen. Battle sounds stay mono files, and the game supplies the stereo placement. Music and big one-off moments without a position (`AudioStreamPlayer`) can stay stereo. The same file also has per-layer pitch jitter (`pj`), which is how the Directorate t1 variation gets made.
  - If Ryan still prefers it in mono, it stands. Mastering then adds a presence lift, and the Wave B Eclipse wording question is reopened with Ryan before Wave B.
- **Stereo or mono (Ryan, Nov 23 11:28 AM CT): B.** He heard a 6 s offline battle mix of his picks two ways: stereo files as made, and folded to mono then panned by position the way `sfx.gd` does. He chose B. Battle sounds ship as mono files placed by the game. Music and unpositioned moments may stay stereo. His lance t1 and Eclipse ctl t2 picks were in that mono mix and stand.
- **Eclipse wording for Wave B follows Ryan's pick, not Neon's swap.** Ryan preferred the old big seismic wording. So the Eclipse prompts keep that character, still without literal Hz numbers, and mastering adds the presence lift.

### 8.2 Wave B Pre-Flight (Nov 23 2026)

The manifest prompts are rewritten to Ryan's A3 picks:
- **Directorate:** turbo, hturbo, picket and ion_beam use the recipe B plasma-cannon wording.
- **Sustained beams:** ion_beam, pulsar and doom hold evenly to the end with no power-down clause. Their body is looped in Godot, with ignition and release as separate pieces.
- **Eclipse:** keeps the big deep character Ryan chose. Only the literal "35 Hz" and the beam power-down wording go.
- **Fable's fixes:** the banned-word and bass-trap fixes (review section 3) are applied to the other items. "Groan" is removed from the Glasswright and Hullbreaker deaths.
- **Held:** `wep_chorus_bioplasma` stays as written until its projectile look is confirmed.

**Size:**
- Wave B is the 55 sound effects not yet made: 108 takes, about 128 s of audio.
- Expected cost is about 1,410 real credits at 11 per second. The tool estimates 5,112, so the cap is 6,000.
- The three music prototypes are not in Wave B; they move to Gate 3 with the Godot 4.7 music plan.

**Gate:** Wave B runs only on Ryan's typed "go wave b". The runner copies the Wave A3B skeleton whole: a fresh folder, a list sha256 gate, a dry run requiring "108 steps, 108 still to make", and the wave and listening page outside the step wrapper.

### 8.3 Wave B Ear Picks and Wave C (Ryan, Nov 23 2026, 12:41 PM CT)

Wave B ran with 108 takes for 1,421 credits. Relay: voidsworn-relay `pc-out-opus1752waveb`. Listening page: https://claude.ai/artifact/MzdPpBUbFsJt1fNi5WgjHx. Neon's notes are PR 1865. Claude re-measured all 108 takes, and Neon's numbers match on 107. Ryan's picks decide.

**Keeps, Ryan's calls:**
- **Sunward:** autocannon t1 (the game already staggers 3 rounds), torp_launch t1.
- **Directorate:** turbo t2 (t1 as a variant), hturbo t1, ion_beam t1.
- **Glasswright:** needle t1, pulsar t2 (Ryan prefers it over Neon's t1 as more distinctive; needs cleanup), startorp t2.
- **Eclipse:** gauss_charge t2, nlance t1.
- **Chorus:** none. tendril t1 was dropped: Ryan scrapped the tendril weapon (R437, Nov 23), so wep_chorus_tendril is replaced pending issue 1877 and gets a new sound once the replacement weapon is picked. No re-roll.
- **Hullbreakers:** scatter t2, rockets t2 (needs more ignition and trail: layer a torp ignition in Godot).
- **Shared and craft:** flak_airburst t1, craft_guns t2, mech_recoil_tail t1, layer_body_heavy t1.
- **Hits:** imp_glass_armor t1.
- **Shields:** shd_break_prismatic t1 (close; check mono at mastering), shd_hit_absorb t1 (t2 is too high).
- **Damage:** dmg_turret_knockout t2, dmg_engine_fail t2 (closer, but short).
- **Deaths:** death_metal_break t1 (close, but does not sound like things breaking), death_hullbreaker_snap t2 (close, short), death_directorate_blackout as a t1 plus t2 mix.
- **UI:** ui_boss_arrival t1, ui_confirm_latch t1, ui_turn_start t2.

**Dropped:** `wep_sunward_hbattery_salvo` is one blast that rings out, not five shots. The game staggers five hbattery shots itself, so this reference is retired.

**On hold:** `wep_chorus_bioplasma` waits for the projectile look.

**"Too short" is a layering question, not a re-roll.** A ship death in game stacks the size boom (`boom_s/m/l`), the faction crack, and a `death_bed` loop of 3 to 16 s (`sfx.gd` `death_bed`). Before more death spend, Claude builds a full-moment preview that stacks the picked pieces the way the game does, so Ryan judges the whole moment.

**Wave C re-roll (25 ids, 49 takes, about 707 real credits; tool estimate 2,572, cap 3,000).** Prompts rewritten to Ryan's notes and Neon's fixes:
- The shell guns (turret, hbattery) ask for a bright breech crack and barrel ring.
- All four metal hits (metal_light, energy_sear, las, acid) ask for a clear armored-steel clang first.
- Eclipse doom is a crackling dark lightning arc, to match the Corona arc look.
- The breach shear asks for buckling and ripping, and is lengthened to 1.4 s.
- The spores and deaths are close and centered, with no "wide" or "outward" wording.
- sporeb is reworded away from electrical static.
- The craft bombs ask for a clamp release and thruster ignition.
- The bridge bed drops the words that leaked a voice ("no vocals", "command bridge") and moves to influence 0.50.

The run needs Ryan's typed "go wave c".

## 8.4 Wave C result, Ryan's picks, and Wave D

Wave C ran with 49 takes for 716 credits (relay `pc-out-opus1752wavec`). Listening page: https://claude.ai/artifact/191G3WngtXJgaAeg45wXuv. Neon's notes are issue 1891 (PR 1894). Neon's numbers match Claude's.

**Ryan's call (Nov 23, 3:46 PM CT):** "neon nailed this". He takes Neon's picks with two exceptions:
- `death_eclipse_shear`: it should not sound like rock. It should be a metallic material, darker and deeper. The prompt now uses black alloy armor plates instead of obsidian stone.
- `wep_hullbreaker_junk_gun`: t2 ends in a whine like a tinnitus effect. Claude measured a 12.5 kHz tone in its tail at 0.15 to 0.25 s. The prompt drops "bright" and ends on a short dry rattle.

**Keeps (Neon's picks):**
- turret t2 and hbattery t2 (t1 as an alternate).
- torp_eject t1.
- pass_by_slug t2.
- spore_cloud t2.
- sporeb t1.
- doom t2, which can loop 0.15 to 0.85 s for long arcs.
- doom_charge t1.
- craft_bombs t2.
- obsidian_eclipse t1.
- acid_on_metal t1.
- breach_shear_metal t1.
- breach_vent t1.
- ithar_shatter t2.
- sunward_magazine t2.
- fleet_warp_in t2.
- amb_bridge_bed t1.

Neon's mastering notes (40 Hz high-pass, head trims, level lifts) carry into mastering.

**Wave D re-roll (8 ids, 16 takes, tool estimate 484, about 135 real credits):**
- The two ids above.
- Neon's six, with Neon's prompt fixes: `wep_directorate_picket`, `wep_eclipse_gsentry`, `imp_metal_light`, `imp_energy_sear`, `imp_las` and `dmg_shield_burnout` (lengthened to 0.7 s, because the Wave C t2 peaked at its last sample).

All of these are close and centered, with no banned words. The run needs Ryan's typed "go wave d".

## 8.5 Wave D result, Ryan's picks, and Wave E

Wave D ran with 16 takes for about 138 credits (relay `pc-out-opus1752waved`). Listening page: https://claude.ai/artifact/UdWWLKAYaP7tkKkofF15hZ. Neon's notes are issue 1899 (PR 1901).

**Ryan's call (Nov 23, 7:58 PM CT):** he agrees with Neon across the board, with one exception. For `imp_las` he picks t1 over Neon's t2, because it is close to the energy sear but different and lighter.

**Keeps:**
- junk_gun t2, which has no whine. Wave D t1 had a new one at 15.7 kHz.
- energy_sear t1.
- las t1.
- shield_burnout t1.

**Wave E re-roll (4 ids, 8 takes, tool estimate 280, about 80 real credits):** these are the ids Neon marked as still needing work.
- `wep_directorate_picket`: two waves of muffled thumps. The prompt now asks for a small, thin, high electric crack and drops the starship-turret framing.
- `wep_eclipse_gsentry` and `imp_metal_light`: the tone was right but came back wide stereo. Both now ask for "one dry point source", and metal_light drops the ringing plate tone.
- `death_eclipse_shear`: the metal was right but sat below 100 Hz. The prompt now asks for grinding, scraping and strain in the midrange, and drops deep, massive and heavy, since boom_l and death_bed already own the sub-bass.

If Wave E still misses, the fallbacks are: today's gun_flak for picket, and a single channel of Wave D t1 or t2 for metal_light and gsentry. The run needs Ryan's typed "go wave e".

## 8.6 Wave E result: every Gate 2 sound has a keeper

Wave E ran with 8 takes for about 80 credits (relay `pc-out-opus1752wavee`). Listening page: https://claude.ai/artifact/U1dLvaKMJuQXnN9JGWwaEA. Neon's notes are in issue 1918 (PR 1919). Ryan agreed with all of Neon's final picks at 8:36 PM CT on Nov 23.

**Final picks for the last four:**
- `wep_directorate_picket`: Wave E t1. Fold to mono, trim the 24 ms lead-in, and high-pass at 40 Hz.
- `wep_eclipse_gsentry`: Wave D t2, left channel only. Do not fold, because (L+R)/2 cancels the midrange. High-pass at 40 Hz.
- `imp_metal_light`: Wave D t1, left channel only. Do not fold, for the same reason. High-pass at 40 Hz.
- `death_eclipse_shear`: Wave E t2. Fold to mono, lift 3 dB, trim 9 ms, and high-pass at 40 Hz.

**Mastering source rule:** each keeper's mastering note in 8.3 to 8.6 says either "fold" or "one channel". A wide take (correlation under about 0.3) uses one channel unless a note says otherwise.

**Scope of Gate 2:**
- Gate 2 is closed for these sounds.
- Bioplasma stays on hold until the projectile look is set.
- The tendril sound waits for issue 1877.
- Next is mastering the keepers to mono game files, then the Gate 3 music plan.
