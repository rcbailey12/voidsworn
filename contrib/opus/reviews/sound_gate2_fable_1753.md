# Fable (audit): PR 1753 @ 72e6aa15

Run: claude-fable-5-2, high effort, through the Claude API on Ryan's PC (OPUS1752_FABLE_RUN3, request req_011ChJe3E5nxN2Evbeee7C75, Nov 22 2026 21:00 to 21:19 UTC, 127,479 tokens in, 123,620 out, about $5.96). Applied on branch claude/project-thread-3riw5a; see contrib/opus/plans/cohesive_audio_v2.md section 6.

## Summary for Ryan

- **Verdict: spend after edits.** The direction is right (clean slate, large-scale anchors, no hull-muffle suffix), but as written about a third of the weapon clips would mislead you on the listening page.
- **One shot per clip.** Twelve prompts bake a whole volley into one file, but the game already plays one sound per shot and staggers them. Wired as labelled, the heavy battery would fire 25 bangs and the null lance 9 pulses.
- **Nothing before the shot, no hit inside a fire clip.** The Doom cannon has a half-second wind-up before the bang, and the tendril and bomber clips include the hit, which would sound even on a miss or a shield block.
- **Several weapons are matched to the wrong sound.** Examples: "Acid sacs" is a strike-craft weapon but gets a giant torpedo launch, "Picket lasers" gets shrapnel flak, and the sound for a shell hitting Chorus flesh is missing.
- **Gate 1 trap words are back.** "Tearing", "sizzling", "cut-crystal", "two-note chime" (a doorbell), "bark" and "torpedo tube" all appear. Many prompts also swing from muffled to harsh ("razor-sharp", "piercing", "loud"), which you have already said you dislike.
- **Music.** The battle prototype's tempo does not fit whole bars in 90 s, and its three-part build is fine for your ear but wrong as a stem source. I add a short stem-ready loop and keep the reward theme close to the one you like.
- **Credits after my edits: 8,422 by the generator's estimate** (was 7,401), for 68 items and 130 files. Total sound-effect audio is about the same (124 s against 114 s). Gate 1 was billed at about 11 credits per second of sound effect, not the estimated 40, so real spend is likely near 4,250. A hold-back version is 7,358.
- **Three calls for you:** (1) are Sunward "Sear" guns shell guns or heat bolts; (2) should Eclipse sound like a railgun crack or a hollow low "null" note; (3) is the reward music you like the Gate 1 `reward_preview` clip.

---

## Blocking

### B1. Twelve fire clips bake a multi-shot volley; the engine plays one cue per shot

- **Where:** `elevenlabs_pilot_v2.json:29` "five distinct crisp heavy kinetic discharges rippling over 0.65 seconds"; `:40` "two crisp synchronized heavy electromagnetic-kinetic blasts separated by 0.08 seconds"; `:51` "three fast hammering mechanical-kinetic thuds"; `:247` "three razor-sharp cold dark-energy shearing pulses spaced 0.25 seconds apart". Same pattern at `:82`, `:104`, `:135`, `:145`, `:185`, `:216`, `:268`, `:279`.
- **OBSERVED:**
  - `docs/playbooks/sound.md:23` "One gun sound per shot at its own fire time".
  - `sfx.gd:315` "sv.n = sv.n + 1 if now - sv.t < 0.45 else 1" and `:319` "if sv.n == 4 and now - tail_t > 1.1:". The salvo logic counts per-shot starts and adds `salvo_tail` on the fourth.
  - `sfx.gd:485-486`: the twin style already plays `gun_shell` twice, 0.05 s apart.
  - `sfx.gd:519` "# one shot cue per fire time (the null lance), the charge leading the first".
  - `salvo_check.gd:46` requires all 20 requested starts per gun cue.
- **INFERRED:**
  - Wired to the labelled cues, `hbattery` gives 5 x 5 bangs, the twin turret 4, and `nlance` 9 pulses on a cue with "max": 3 (`cues.json:427`).
  - `gun_shell` has "max": 6, "gap": 0.045 (`cues.json:5-6`), so in a volley each voice is stolen after roughly 0.3 to 0.4 s. A 1.0 to 1.5 s gun clip never plays its tail.
- **Why it matters:** you would approve a rhythm the game cannot reproduce, and a single shot cannot be cut cleanly out of an overlapping roll.
- **Fix:** single-shot clips of 0.5 to 1.0 s for every per-shot weapon. Keep one baked heavy-battery salvo at 1 take as a reference. The listening page should stitch singles at the `cues.json` gaps so you hear what the engine will do.
- **Answer on `wep_sunward_hbattery_salvo`:** single shots staggered by `sfx.gd`, not one 5-gun clip.

### B2. Pre-roll and bundled beats inside t=0 clips break the plan's own rule

- **Rule:** `cohesive_audio_v2.md:32` "Every firing transient MUST ignite right at `0.0 s`".
- **OBSERVED violations:**
  - `json:257` "half-second terrifying gravitational vacuum suck-in slamming into a monumental deep monolithic sub-bass detonation".
  - `json:71` "clamp release and hydraulic magnetic shove at 0.0 seconds, immediately catching at 0.3 seconds into a deep roaring fusion-thruster ignition burn".
  - `json:155` "deep muscular organic contraction bursting immediately into".
  - `json:165` "muscular surge snapping instantaneously into a thunderous chitinous-bone hull impact".
  - `json:279` "pylon drop clunk followed by two compact punchy armor-piercing warhead concussive thumps".
  - `json:82` "bursting immediately into sharp metallic shrapnel airburst cracks".
  - `json:237` "followed by a brief razor-sharp Doppler hypersonic plasma-wake streak".
- **OBSERVED:** the engine already has a charge slot. `sfx.gd:493` `CHARGE_LEAD := {"lance_charge": 0.26, "torp_charge": 0.30}`.
- **Why it matters:**
  - A baked wind-up stacks on the existing lead, so the Doom bang lands about 0.5 s after the beam appears.
  - A hit baked into a fire clip plays on a miss, on a shield block (`deaths_and_hits.md:51` "A shield block is quiet"), and ignores the target-substance routing the plan itself asks for (`md:66`).
- **Fix:** split into a charge or eject clip plus a discharge at t=0 (Doom, torpedo). Make tendril, bombs and flak fire-side only.
- **Answer on `wep_eclipse_gauss_fire`:** split it. The weapon fires 3 shots a volley on a cue with "max": 4, "gap": 0.06 (`cues.json:240-241`), so three 1.1 s wakes smear into wash. The wake is also the part that failed in Gate 1 (`md:14`, duct tape). Keep a 0.7 s shot and move the wake to a pass-by candidate for `shot_pass_by`.

### B3. Roster mapping errors against `tables_weapons_excerpt.json`

All data rows are OBSERVED. What each weapon currently looks like on screen is not in the files given.

| Weapon | Plan says | Data says | Fix |
|---|---|---|---|
| `sporeb` | `json:170` "torp_sac (Chorus sporeb living bio-sac torpedo launch)", 1.6 s, "Giant alien void-leviathan" | `tables:305` "k": "sq", range 1, same shape as `bombs`; `:355` "Acid sacs" | Strike-craft acid sac, 0.6 s |
| `spores` | `md:52` maps it to `wep_chorus_spines` | `tables:181` "k": "flak"; `:354` "Spore cloud" | New spore-cloud point-defense clip |
| `bioplasma` | `json:155` "pressurized orb of boiling corrosive bile" | `tables:352` "Spine volley"; `:424` trait "spines" | Spine clip belongs here; confirm the projectile look |
| Directorate `laser` | `json:93` "directed-energy laser pulse", cue `gun_las` | `tables:337` "Plasma cannon"; `:412` trait "plasma" | Light plasma cannon shot |
| Directorate, Glasswright, Eclipse `flak` | All share `wep_flak_airburst`, "metallic shrapnel airburst" | `tables:341` "Picket lasers"; `:362` "Mirror veil"; `:368` "Null shredder" | Kinetic flak for Sunward and Hullbreakers only; add a picket pulse; Eclipse reuses `gsentry`; hold "Mirror veil" until its look is confirmed |
| Hullbreaker `torp` | `md:51` maps it to `wep_sunward_torp_launch` | `tables:347` "Rattle-rocket pod"; `sfx.gd:534` already routes corsair to `torp_rocket` | `wep_hullbreaker_rockets` covers `torp` and `htorp` |
| `doom` | `json:252` "Doom Cannon superweapon" | `tables:254` and `:366` "Corona arc" | Reword as an arc discharge |
| bio target substance | `md:66` lists `imp_bio_acid`; `json:316` cue "hit_wet (Chorus corrosive bio-acid impact on hull)"; prompt `json:321` "striking armored spacecraft plating ... eating thick alloy" | `sfx.gd:559` `HIT_BY_TARGET := {"chorus": "hit_wet", ...}`; `audio_check.gd:206` "a hit on Chorus plays hit_wet" | That prompt is acid on metal (weapon side). Rename it and add `imp_bio_flesh` for shots striking a Chorus hull |

- **INFERRED:** `sfx.gd:481-483` returns `gun_flak` for any `k == "flak"` before style is read. `spores` and `gsentry` are both `k: flak`, so their labelled cues (`gun_spine`, `gun_rail`) may never be reached without a code change.
- **Why it matters:** `json:5` claims "all 26 weapons" and "all 4 target armor substances". Neither holds, and metal-plate wording on a Chorus hull breaks audit trap 2.

---

## High

### H1. Trap words still in the prompts

All phrases OBSERVED; the risks are INFERRED from the Gate 1 results in `md:13-21` and from each word's everyday meaning.

| Phrase (json line) | Risk | Replace with |
|---|---|---|
| "tearing into" (341), "ripping open" (361), "tearing apart" (412) | Gate 1 cloth, tape, Velcro; `md:34` bans "tearing rip" | "collapsing into", "shearing open", "parting" |
| "volatile sizzling chemical fume trail" (155), "boiling roar and violent bubbling" (321) | Gate 1 bacon (`md:18`); kettle | "deep corrosive chemical roar, like an industrial acid vat eating steel" |
| "two razor-sharp dry magnetic snap-cracks" (216), "dry chitinous snapping tendon clicks" (145) | Same recipe as Gate 1's stick snap (`md:20`): dry, snap, crack, no body | "short cold magnetic snap with a hollow dark low tone"; "deep muscular thud with a hard dense chitin crack" |
| "cut-crystal harmonic snaps" (185), "optical-aperture chime" (205), "glass-organ sub-hum" (195) | Tableware, wind chime, wine-glass rim (`md:17`) | "a huge quartz block struck once, with a firm low-mid thump" |
| "warm two-note harmonic chime" (452) | A doorbell | "one warm low struck bronze bell tone" |
| "whip-crack" (237, 402) | Bullwhip | "hard heavy magnetic slam"; "hard heavy snap of giant steel structural cables parting" |
| "explosive breech bark" (125), "shrapnel-shotgun blast" (125) | Dog; 12-gauge and pump rack | "ragged overdriven propellant blast"; "scrap cannon" |
| "space torpedo launching from an orbital bay tube" (71) | Submarine tube; `md:31` bans submarine triggers | "anti-ship missile", "launch cell" |
| "bio-leviathan" (155), "void-leviathan" (175, 412), "abyssal" (247, 257), "plasma-wake" (237), "warship" (104, 145, 195, 205, 442) | Sea monster, whale, deep sea, boat wake, naval | "giant living alien starship creature"; "hollow", "dark"; "starship" |
| "low-brass war-drone swelling smoothly" (442) | A ship horn; `md:31` bans "foghorn" | Bass drum strike with brass and basses holding a low D |
| "organ rupture" (412), "horn-chitin" (412) | Pipe organ; brass or car horn | "rupture of dense tissue"; "rigid chitin armor plates" |
| "kinetic pops" (82, 268) | Cap gun, popcorn | "short hard reports" |
| "ricochet ping" (301) | Western ricochet; `sound.md:25` "No arcade" | "short spray of heavy steel fragments" |
| "steam vent hiss" (290), "decompression hiss" (361) | Kettle, iron; tire, balloon (`md:13`) | "pressurized coolant gas vent"; "roaring jet of escaping pressurized air" |
| "vacuum suck-in" (257), "vacuum sub-bass implosion" (341) | Vacuum cleaner | "inward-pulling pressure swell"; "low-end collapse" |
| "wet cartilaginous valve pop", "chamber heave" (175), "boiling corrosive bile" (155) | Comic pop, retching | "compact dense organic pressure thump" |
| "hydraulic servo motor" (371), "skittering" (381), "dart discharges" (145) | Small servo or drill; insects; toy darts | "heavy drive-gear grind"; "one short burst of arc crackle"; drop |
| "dry glassy stone-plate fracture" (331) | Dinner plate | "brittle crack of a massive basalt slab" |
| "downward cascading harmonic force-field pitch drop" (341), "turbolaser" (104), "laser pulse" (93) | Arcade power-down and pew; `sound.md:25` | "deep heavy low-end collapse"; "plasma cannon", "capacitor-bank discharge" |
| "spitting", "raspy", "sputtering exhaust tails" (135) | Mouth, voice, small engine | "rough roaring solid-fuel burn", "uneven crackling exhaust" |
| "echoing across cold space" (257), "heavy echoing iron vibration" (402), "dark reverb fade" (442) | Baked reverb, against `md:33` | Drop; add "no reverb" |
| "no pre-delay click" (18), "no gunshot" (290), "no shot" (226), "no big bass boom" (82), "zero metal boom" (351), "no distinct repeating bangs or creaks" (473) | Breaks the plan's own rule at `md:34` on concrete nouns in negatives | Positive wording only |

### H2. Over-correction from muffled to harsh, and everything is "Colossal"

- **OBSERVED:** `sound.md:15` "Weight without harshness. Body in the low and low-mid range, a soft top. Nothing shrill." and `sound.md:9` lists "Harsh or annoying" among your dislikes.
- **OBSERVED:** "razor-sharp" appears at `json:93, 145, 185, 216, 237, 247, 402`; "piercing" at `:195`; "shattering" at `:237`; "loud" twice at `:125`. "Colossal" appears in 14 prompts, from a lance to an ordinary hull hit (`:301` "Colossal space armor impact").
- **OBSERVED:** `md:33` says to let "Godot's bus reverb, distance attenuation, and ship-class EQ shape depth". `sfx.gd` has no EQ or filter. Distance only scales gain (`sfx.gd:325`) and `sfx.gd:357` sets `ATTENUATION_DISABLED`.
- **INFERRED:** far ships will be as bright as near ones, so harsh tops pile up. With one size word on everything, the playbook ladder (`sound.md:27`, each step "plainly heavier than the last") flattens.
- **Fix:**
  - Use "crisp, firm, clean attack" with a stated low body.
  - Tier the size words: light for point defense and craft, mid for guns, heavy for lances and torpedoes, "colossal" only for Doom and deaths.
  - Land a playbook edit (audit trap 8, R214): `md:33` contradicts `sound.md:15`, and `sound.md:34` "Free tools and free sources only" now conflicts with ElevenLabs.

### H3. The three-layer design is not what the manifest generates, and Layer C trips a check

- **OBSERVED:** `md:43-45` defines layers A, B and C. The JSON has no Layer B item and one Layer C item. The "Layer A" prompts contain B and C already: `json:18` "dense forged-iron structural recoil thump, brief pressurized thermal vent decay"; `json:104` "heavy regulated sub-bass thump, and brief sterile heat-sink dissipation whine".
- **OBSERVED:** `sound_weight_check.gd:66-69` fails any `gun_` cue with a layer delay above 0.001 ("weapon shots stay dry (no gun cue has a delayed tail layer)"). `sound.md:16` "Weapon shots stay short and dry".
- **OBSERVED:** `json:284` labels the tail "salvo_tail", but `sfx.gd:319-321` fires `salvo_tail` once per volley on the fourth shot and at most once per 1.1 s. It is a different thing.
- **INFERRED:** if the tail becomes its own cue at "pri": 1, the global steal at `sfx.gd:330-338` lets tails cut off gun voices of equal priority under the 34-voice cap (`sfx.gd:24`).
- **Fix:**
  - Treat Gate 2 clips as composites for judging identity, and say so in the plan.
  - Test the layer idea on one weapon only: I add one low-body clip (`wep_layer_body_heavy`).
  - Make the tail its own per-volley cue at "pri": 0, as `PASS_BY_CUE` does (`sfx.gd:49`).

### H4. "t=0" cannot be delivered by prompt wording alone

- **OBSERVED:** `elevenlabs_gen.js:82` writes `${it.id}_t${t}.mp3`.
- **INFERRED:** MP3 files carry encoder padding at the head, and generated audio often has a few tens of ms of lead-in. Numeric timings in prose ("0.08 seconds", "at 0.0 seconds") are unlikely to be followed.
- **OBSERVED:** the Gate 1 breech clack came from prompt order, not the suffix. `gate1_manifest.jsonl:6` reads "heavy breech block slamming, a deep cannon thump". `md:11` blames the "soft top" suffix.
- **OBSERVED:** `md:35` routes 15 items to v2 on the claim that "Gate 1 showed v2 held tighter onset timing". Gate 1 had one percussive A/B pair, one take each (`gate1_manifest.jsonl:6-7`). `elevenlabs_gen.js:21` notes "eleven_text_to_sound_v2 removed Mar 1 2027".
- **Why it matters:** any top-up take after that date comes from a different model than the approved family.
- **Fix:**
  - Add a post-step that measures and trims the onset of every file and prints it on the listening page.
  - Remove numeric timings from prompts.
  - Add two same-prompt v3 twins so the v2 claim is tested, not assumed.

### H5. Weapons that will still sound alike

All INFERRED from wording.

- **Sunward vs Eclipse.** `json:18` "magnetic muzzle crack" and `json:40` "electromagnetic-kinetic" share vocabulary with Eclipse's railgun (`:237`). Fix: Sunward is iron and propellant only (`sound.md:31` "iron and fire for the Crusade"); reserve "magnetic" for Eclipse.
- **Directorate laser vs Eclipse gsentry.** Both are 0.7 s "razor-sharp" cracks with a dead cutoff (`:93`, `:216`). Fix: Directorate becomes a capacitor thump; Eclipse gets a hollow low tone, which also restores `sound.md:32-33` "a low held note for Eclipse", absent from every Eclipse gun prompt.
- **Autocannon, craft guns, flak.** All are fast runs of small kinetic hits at 0.7 to 0.9 s (`:51`, `:268`, `:82`).
- **Electric cluster.** "high-voltage" appears in the ion beam, gauss charge, shield break, turret knockout and shield burnout (`:114, 226, 341, 371, 381`).
- **Glass cluster.** `imp_glass_armor` (`:311` "thick heavy crystal slabs shearing apart") describes destruction on an ordinary hit and overlaps `death_ithar_shatter`. `hit_glass` plays on every hit on a Glasswright (`sfx.gd:564-565`).
- **Hullbreakers** borrow Sunward's turret, autocannon and torpedo (`md:51`), against `sound.md:32` "rattling junk for the Hullbreakers".

### H6. Coverage gaps

OBSERVED by absence from the JSON.

- **Most-heard impacts:** an ordinary metal hit (`hit`), an energy hit (`hit_las`, `hit_plasma`), and an ordinary shield block (`shield`). Every Gate 2 impact is a heavy one.
- **UI:** only `ui_boss` and `ui_reward` are covered, yet `json:5` claims "intuitive sci-fi UI cues". Click and confirm are the most-heard sounds in the game. Answer to `md:95`: yes, test them now, as acoustic mechanical objects.
- **Missed-shot pass-by:** today one generic clip serves every weapon (`sfx.gd:51` `"s": "whoosh"`).
- **Engine loss:** `md:68` names a "faction-safe drive sputter" but there is no prompt.
- **Base death break:** no candidate for `boom_l`, which every death plays (`death_audio.gd:81`). A Sunward death would stay 100% old clips, and each faction death would mix one new stage with old ones. That is the patchwork `md:25` says it wants to avoid.
- **Layer B** and the four non-kinetic Layer C tails named at `md:45`.

### H7. Music prototypes

- **Bar math (OBSERVED arithmetic).** `json:482` "94 BPM" at 90 s is 141 beats, or 35.25 bars. "0:30" and "0:58" fall at bars 11.75 and 22.7. It cannot loop on a bar line. At 96 BPM a bar is 2.5 s, so 90 s is 36 bars with sections at bars 12 and 24. The reward track at "76 BPM" and 45 s is 14.25 bars; 80 BPM and 48 s is 16 bars.
- **Named works.** `json:482` "Inspired by Homeworld and Battlestar Galactica". INFERRED: named works can trip content filters, and both scores are known for voices and ethnic percussion, against "no vocals". Describe the traits instead.
- **Palette leak (OBSERVED).** The Sunward prototype asks for "cold metallic glass harmonics", "pulsing sub-synth heartbeat" and "industrial sci-fi percussion". By `md:75-78` those belong to the Glasswrights, Chorus, Directorate and Hullbreakers. `md:74` gives Sunward brass, cellos, forge metal and war percussion.
- **Shared motif.** `md:73` promises a "4-note recurring motif" on every screen. INFERRED: two separate text prompts will invent two different tunes. I name the notes (D, A, F, E) in both prompts as a cheap test. If the two outputs do not share it, drop the motif claim before Gate 3 and rely on key, tempo family and shared instruments.
- **Reward theme.**
  - OBSERVED: `music.json` has no reward track or slot (`:495-530`), and `music_player.gd` has no reward mode.
  - INFERRED: the reward music you like is Gate 1's `reward_preview` (`gate1_manifest.jsonl:3` "warm brass and strings, quietly triumphant, calm, not cheesy").
  - OBSERVED: the Gate 2 prompt moves to "solitary echoing cello and subtle shimmering glass harmonic" with a fade ending (`json:491`), and `md:25` discards all Gate 1 clips.
  - Fix: keep `reward_preview` on the listening page as the control, and keep the new prompt close to its wording.

### H8. Direct answer: a 3-part build inside 90 s does break synchronized 4-stem mixing

- **OBSERVED, today's player:** three independent loops started by separate `play()` calls (`music_player.gd:258-260`), crossfaded by one smoothed number (`:380-384`). The tracks are unrelated and of different lengths (`music.json:165` 64.0 s, `:205` 108.0 s). Nothing is stem-synced today.
- **INFERRED:** the song's own arc and the game's stem gains are two intensity controls that multiply.
  - Raise percussion at 0:10 and you get silence until 0:30, as `md:96` notes.
  - The reverse also fails: in a calm phase at 1:00, the "calm" stems are playing the climax.
  - A turn-based battle outlasts many loops, so the arc becomes a 90 s cycle unrelated to play.
- **Recommendation:** Gate 3 tracks keep all four parts playing in every bar at even density. They evolve through chord progression and motif variation over 90 to 120 s, and only the mixer changes intensity.
- **Caveat:** such a track sounds flat as a single mixed file, which was your Gate 1 complaint (`md:23`). So Gate 2 needs two prototypes with different jobs: the showcase arc for your ear, and a short stem-ready loop.
- **Unverified and decisive (INFERRED):** whether ElevenLabs stem separation can return "brass/motif" apart from "pads" on an orchestral track. Many separators return vocals, drums, bass and "other", which would put brass, cellos and pads in one stem. Prove it on the 40 s loop with a one-item Gate 3 list (`elevenlabs_gen.js:78` allows stems only at gate 3) before designing around four stems.
- **Fallback that fits today's code:** three layers map onto the existing `calm`, `intense` and `bed` slots (`music.json:531-555`).

### H9. Wiring hazards to write into the plan now

All OBSERVED unless marked.

- **Impact routing.** `md:66` "Expand `HIT_BY_TARGET` ... to cover all 4 substances". `impact_cue` returns the target cue first (`sfx.gd:564-565`), so adding metal makes `hit_las`, `hit_plasma`, `hit_rail`, `hit_ion` and `hit` unreachable and fails `audio_check.gd:199-208`. Fix: keep target-first only for non-metal, or use two layers (substance contact plus weapon colour).
- **New cue ids fail CI** unless listed: `audio_check.gd:150` "belongs to a cue family (add it to CUE_FAMILIES)". Prefer faction variants of existing cues.
- **Clips get cut.** `lance_charge` "duration": 0.32 (`cues.json:389`), `death_crack` 0.4 (`:2306`), `death_powerdown` 0.6 (`:2092`), `arrive_jump` 0.45 (`:2549`). The 0.9 to 1.5 s replacements are faded at those lengths (`sfx.gd:373-376`) unless each variant sets its own duration.
- **Shield burnout cadence.** `fx_ship_capability_excerpt.gd:10` `GEN_GAP := Vector2(1.4, 3.0)` repeats the crackle for the rest of the battle on every affected ship. The prompt is a 1.8 s "controllable damage bed" (`json:381`). INFERRED: near-continuous static. Fix: a 0.6 s single crackle, full level on the first (`:121`), then quiet with max 1.
- **Turret knockout.** `:133-134` skips sparks on Chorus ("flesh: the mount's spore wisp only"), but `md:68` has no faction guard. A lost section sets many slots off at once (`:5` "a lost section's 999"), so one sync can fire several knockouts. Fix: one per ship per sync.
- **Breach on non-metal hulls.** `md:67` "(alloy shear + rapid vacuum decompression hiss)" for every hull puts metal on Chorus and Glasswright breaches (audit trap 2). Fix: split into a metal shear and a shared vent.
- **Feature flag.** Capability hooks sit behind `VS_WOUNDS_V2` (`fx_wounds_flag.gd:3-7`). Audio must read the same flag.
- **Music looping.** `music_player.gd:132-134` sets loop only on Ogg streams, and the generator writes MP3. Stems need transcoding and identical cut points.
- **Faction preview.** `music_player.gd:194` needs ids that begin with "fac_", or the faction desk silently falls back to title music (audit trap 7).
- **Boss swap.** `music_player.gd:253-254` replaces the hot layer with an unrelated boss track.
- **Intensity inputs.** `feed()` has no breach or death inputs (`:291-307`), which `md:70` assumes.

---

## Medium

- **M1. The 1-take figure is wrong.** `md:97` "`takes: 1` on the first sweep (~4,500 credits)". OBSERVED by the generator's rates: 2,288 + 800 + 2,025 = 5,113.
- **M2. The estimate overstates sound-effect cost about 3.6 times.** OBSERVED in `gate1_manifest.jsonl`: every sound effect was charged about 11 credits per second (11 for 1 s, 22 for 2 s, 132 for 12 s) against an estimate of 40. Totals were 473 charged against 1,712 estimated; music rows show "charged": null. INFERRED: the second take across the pack costs about 630 real credits, half a percent of the pool. See the credit section for what follows from this.
- **M3. UI prompts lean synthetic.** `json:452` "for a space strategy game" and "high-craft sci-fi UI"; `json:442` "sci-fi threat signal". INFERRED: "sci-fi UI" pulls toward electronic bleeps, which you dislike. Describe a physical object.
- **M4. Tonal effects against the music key.** The pulsar chord, star-torpedo tone, reward bell and boss brass are pitched, and cue jitter is up to 7% (`cues.json` "spj": 0.07), more than a semitone. INFERRED: clashes with D minor. Fix: zero jitter on tonal cues and tune them to D or A at wiring.
- **M5. Design notes inside prompts.** `json:462` "Crisp tail so staggered fleet arrivals stack cleanly"; `:473` "built for seamless looping behind tactical strategy"; `:268` "distinct from capital artillery"; `:432` "violet-arc". The model cannot act on these, and some add stray nouns. Remove.
- **M6. "dark" on attack-critical prompts** (`json:18`, `:61`, `:247`). INFERRED: in audio terms "dark" means low high-end, the muffle Gate 2 is trying to leave. Keep it for music and ambience.

## Low

- **L1.** `md:51`, `:53`, `:54` list `flak` under weapons but give no flak prompt id. `md:49` lists `wep_mech_recoil_tail` as a weapon prompt.
- **L2.** `json:5` claims "all faction death beats". There is no Sunward item.
- **L3.** `md:73` "every screen", but title, map and the victory and defeat stings stay on the old free tracks (`music.json:495-530`). State this as out of scope for Gate 2.
- **L4.** `md:68` reuses `death_ithar_shatter` as a quiet strain layer. INFERRED: it dilutes the death. Use a separate take at Gate 3.

---

## Line-level edits

### `elevenlabs_pilot_v2.json`: changed items

Merge by id. Fields not shown stay as they are.

```json
[
{"id":"wep_sunward_battery","cue":"gun_shell (Sunward battery: ONE shot; sfx.gd staggers the 4)","seconds":0.8,"prompt":"Single heavy sci-fi starship cannon shot, close and dry: an immediate hard explosive propellant crack with a dense forged-iron barrel ring and a deep solid low thump, decaying fast. Large-caliber military gun, mid-heavy scale, full crisp attack with a strong low body, no reverb."},
{"id":"wep_sunward_hbattery_salvo","cue":"REFERENCE ONLY, not for wiring: what five staggered wep_sunward_hbattery shots should add up to","takes":1,"prompt":"Five very heavy sci-fi capital starship guns firing one after another in a fast rolling sequence along one flank of the hull, close and dry: five separate massive propellant blasts in quick succession, each with a forged-iron ring, over a deep overlapping hull-frame shudder. Starts on the first blast, deep and weighty, no reverb."},
{"id":"wep_sunward_autocannon","cue":"gun_tracer (autocannon: ONE round; sfx.gd staggers the 3)","seconds":0.5,"prompt":"Single round from a sci-fi starship autocannon, close and dry: one immediate hard tight report with a short metallic action cycle and a compact low-mid punch, very short decay. Lighter and faster than a turret gun but still solid, no reverb."},
{"id":"wep_sunward_lance_beam","prompt":"Huge sci-fi starship heat lance firing, close and dry: an immediate searing beam ignition into a steady white-hot roar like a steel-mill arc furnace, with a deep reactor drone underneath, then a clean cutoff and a brief cooling shimmer. Heavy sustained energy beam, far larger than any gun, full strength from the first instant, no reverb."},
{"id":"wep_sunward_torp_launch","cue":"torp_heavy (Sunward torp: ignition at t=0; the eject is wep_torp_eject in the torp_charge slot)","seconds":1.8,"prompt":"Heavy sci-fi anti-ship missile igniting as it leaves a starship, close and dry: an immediate deep thruster ignition blast that surges into a smooth powerful burn and accelerates away into the distance, fading naturally. Massive ordnance, much heavier than a rocket, full ignition from the first instant, no reverb."},
{"id":"wep_flak_airburst","cue":"gun_flak (kinetic flak for Sunward and Hullbreakers only: ONE shot, fire side only)","seconds":0.5,"prompt":"Single shot from a sci-fi starship point-defense flak gun, close and dry: an immediate short hard report with a compact mid-weight punch and a quick gritty burst of fragments, very short decay. Fast defensive gun, lighter than a turret gun, tight and controlled, no reverb."},
{"id":"wep_directorate_laser","cue":"gun_plasma light (Directorate laser, shown to the player as Plasma cannon: ONE shot)","seconds":0.6,"prompt":"Single shot from a military sci-fi starship plasma cannon, close and dry: an immediate tight capacitor-bank discharge thump with a short hot ionized energy crack and a clean regulated low-mid punch, fast clean cutoff. Precise and controlled, firm attack with a smooth top, no reverb."},
{"id":"wep_directorate_hturbo","cue":"gun_plasma heavy (Directorate turbo and hturbo, shown as Plasma battery: ONE shot; sfx.gd staggers the 2 or 3)","seconds":0.9,"prompt":"Single shot from a heavy military sci-fi starship plasma battery, close and dry: an immediate deep capacitor-bank discharge with a dense ionized energy blast and a heavy regulated low thump, ending in a brief clean power-supply wind-down. Clearly larger and deeper than a light plasma cannon, controlled, no reverb."},
{"id":"wep_hullbreaker_scatter","cue":"gun_shell variant (Hullbreaker scatter: ONE blast; sfx.gd staggers the 5)","seconds":0.8,"prompt":"Single blast from a crude salvaged sci-fi starship scrap cannon, close and dry: an immediate ragged overdriven propellant blast with a heavy spray of tumbling steel fragments and a loose bolted-iron housing rattle shaking after it. Dirty, rough, heavy industrial scale, no reverb."},
{"id":"wep_hullbreaker_rockets","cue":"torp_rocket (Hullbreaker torp and htorp: ONE rocket)","seconds":1.4,"prompt":"Single crude heavy sci-fi rocket igniting and leaving a steel rack on a starship, close and dry: an immediate gritty ignition blast into a rough roaring solid-fuel burn that streaks away with an uneven crackling exhaust, fading into the distance. Unrefined, dirty, heavy, no reverb."},
{"id":"wep_chorus_spines","cue":"gun_spine (Chorus bioplasma, shown to the player as Spine volley: ONE spine)","seconds":0.6,"prompt":"Single huge bone spine fired from a giant living alien starship creature, close and dry: an immediate deep muscular thud of release with a hard dense chitin crack and a short heavy tail, quick decay. Large predatory alien biology, heavy and solid, no metal, no reverb."},
{"id":"wep_chorus_bioplasma","cue":"gun_glob (Chorus bile glob: ONE glob; confirm which Chorus weapon shows a glob before wiring)","seconds":0.9,"prompt":"Single dense glob of corrosive fluid launched from a giant living alien starship creature, close and dry: an immediate deep muscular pressure thump with a thick heavy viscous surge and a short rough chemical vent trailing off, abrupt end. Huge organic mass, heavy and menacing, no metal, no reverb."},
{"id":"wep_chorus_tendril","cue":"new cue: Chorus tendril lash, fire side only (the hit comes from imp_*)","seconds":0.9,"prompt":"Giant armored alien tendril of bone and sinew lashing out from a living starship creature, close and dry: an immediate deep heavy muscular lunge, a thick low surge of great mass moving fast, and a taut fibrous strain creak at full stretch. Enormous creature scale, heavy low end, no metal, no reverb."},
{"id":"wep_chorus_sporeb","cue":"gun_sq variant (Chorus sporeb, shown as Acid sacs, k is sq: ONE sac, strike-craft scale)","group":"weapon_craft","seconds":0.6,"prompt":"A small alien bio-craft releasing one acid sac at close range, dry: one immediate compact dense organic pressure thump with a short thick viscous burst, tight and quick. Strike-craft scale, clearly smaller than a capital creature's weapons but solid, no metal, no reverb."},
{"id":"wep_ithar_shard","cue":"gun_needle (Glasswright shard and Needle beam turret: ONE shot)","seconds":0.6,"prompt":"Single shot from a crystalline alien starship prism weapon, close and dry: an immediate bright clear crystal-tone strike, like a huge quartz block struck once, with a firm low-mid thump under it and a short pure ringing overtone that fades fast. Luminous and precise, solid and weighty, no metal, no reverb."},
{"id":"wep_ithar_pulsar","seconds":1.5,"prompt":"Crystalline alien starship firing a focused prism light lance, close and dry: an immediate bright sustained beam tone built from pure quartz-bell overtones over a deep steady resonant hum, held even, then a clean cutoff with a short fading ring. Majestic and lethal, smooth and full, no vocals, no metal, no reverb."},
{"id":"wep_ithar_startorp","prompt":"Crystalline alien starship releasing a small captive star as a weapon, close and dry: an immediate single deep struck-crystal tone with a strong radiant energy hum that recedes into the distance on a smooth shimmering tail. Pure, luminous, massive energy, no vocals, no metal, no reverb."},
{"id":"wep_eclipse_gsentry","cue":"gun_rail light (Eclipse gsentry Null spire and flak Null shredder: ONE shot)","seconds":0.5,"prompt":"Single shot from an ancient alien machine starship point-defense weapon, close and dry: an immediate short cold magnetic snap with a hollow dark low tone under it, like a struck stone column, and an abrupt dead cutoff. Cold and precise, hollow and heavy, no reverb."},
{"id":"wep_eclipse_gauss_charge","cue":"new cue: Eclipse null cannon charge, once per volley (guns have no charge hook today; lance_charge is cut at 0.32 s)","prompt":"Huge ancient alien machine weapon charging, close and dry: a deep ominous power-station transformer hum swelling under heavy magnetic coil strain, then stopping dead on one hard heavy relay clack. Cold, dread-filled, low and heavy, no reverb."},
{"id":"wep_eclipse_gauss_fire","cue":"gun_rail (Eclipse gauss, shown as Null cannon: ONE shot, no wake)","seconds":0.7,"prompt":"Single shot from a huge ancient alien machine starship null cannon, close and dry: an immediate hard heavy magnetic slam with a crushing low-end punch and a short hollow cold tone that drops away fast into silence. Cold and lethal, deep and weighty with a firm clean attack, no fire, no reverb."},
{"id":"wep_eclipse_nlance","cue":"lance_dark (Eclipse nlance: ONE pulse; sfx.lance already plays one per fire time)","seconds":0.8,"prompt":"Single pulse from an ancient alien machine starship null lance, close and dry: an immediate cold dark energy cut, a short hollow shearing tone over a deep low hum, ending in a brief dry static crackle. Menacing, hollow, ancient, heavier than a gun shot, no fire, no reverb."},
{"id":"wep_eclipse_doom","cue":"lance_dark heavy (Eclipse doom, shown as Corona arc: discharge at t=0; the pull-in is wep_eclipse_doom_charge)","seconds":1.8,"prompt":"Ancient alien flagship superweapon discharging, close and dry: an immediate monumental deep low-end slam, then a sustained hollow roaring arc of dark energy over a huge vibrating low drone, ending in a slow heavy decay. The single largest weapon in the fleet, world-ending dread, enormous low end, no fire, no reverb."},
{"id":"wep_craft_guns","cue":"gun_sq (strike craft guns: one short burst, the only baked burst kept; check the gun() call site first)","seconds":0.6,"prompt":"Sci-fi space fighter firing one short rapid cannon burst at close range, dry: an immediate tight run of fast small hard reports, each with a compact low-mid punch, ending cleanly. Strike-craft scale, quick and solid, no reverb."},
{"id":"wep_craft_bombs","cue":"new cue: strike craft bomb release, fire side only (the hit comes from imp_*)","seconds":0.6,"prompt":"Sci-fi strike craft releasing one heavy bomb at close range, dry: an immediate solid magnetic rack release thunk with a short dense mechanical drop and a brief thruster kick as the bomb leaves. Compact, heavy for its size, no explosion, no reverb."},
{"id":"wep_mech_recoil_tail","cue":"new cue: per-volley mechanical tail, its own cue at pri 0 (not salvo_tail, not a delayed gun_ layer)","prompt":"Heavy industrial machine mechanism cycling once, close and dry: a damped hydraulic piston returning, a dense steel block seating solidly into place, and a short pressurized coolant gas vent. Large heavy machinery, low and solid, no reverb."},
{"id":"imp_metal_heavy","prompt":"Heavy armor-piercing shell slamming into thick starship armor plating, close and dry: an immediate crushing metallic crunch with a deep resonant hull-frame boom and a short spray of heavy steel fragments scattering. Massive armor impact, deep and weighty, no reverb."},
{"id":"imp_glass_armor","seconds":1.0,"prompt":"Heavy projectile striking a massive thick crystalline starship hull, close and dry: an immediate deep stone-like crystal impact boom with a low bell tone from the whole mass and a short run of heavy cracks spreading through thick quartz. Monumental scale, low-pitched and dense, a hard hit that the hull survives, no metal, no reverb."},
{"id":"imp_obsidian_eclipse","prompt":"High-energy projectile striking thick obsidian armor on an ancient alien starship, close and dry: an immediate cold brittle crack of a massive basalt slab with a hollow low stone-and-metal resonance and a brief dry static crackle. Cold, ancient, dense and heavy, no fire, no reverb."},
{"id":"shd_break_energy","prompt":"Giant starship energy shield collapsing under heavy fire, close and dry: an immediate hard high-voltage snap, then the whole field giving way in a deep heavy low-end collapse with a wide dying electrical crackle spreading outward. Clearly a large power barrier failing, heavy and final, no explosion, no reverb."},
{"id":"shd_break_prismatic","prompt":"Crystalline alien starship light barrier breaking, close and dry: an immediate bright resonant crystal tone that fractures and collapses into a heavy run of thick splintering crystal tones over a deep low-end drop. Clearly a large crystalline energy barrier failing, heavy and dense, no metal, no explosion, no reverb."},
{"id":"dmg_turret_knockout","cue":"new R416 cue: weapon slot knocked out (metal hulls only; fx_ship skips sparks on Chorus)","seconds":0.8,"prompt":"Armored starship gun turret seizing from battle damage, close and dry: an immediate heavy drive-gear grind into a hard mechanical jam, then two short high-voltage arc snaps. Short, heavy, industrial machinery scale, no explosion, no reverb."},
{"id":"dmg_shield_burnout","cue":"new R416 cue: ONE generator crackle (fx_ship repeats it every 1.4 to 3.0 s)","seconds":0.6,"prompt":"Damaged starship shield emitter arcing once across hull plating, close and dry: one short burst of dry high-voltage arc crackle with a brief low electrical buzz under it, ending fast. Small, tense, contained, no explosion, no reverb."},
{"id":"death_hullbreaker_snap","prompt":"Huge welded scrap-metal starship hull breaking apart under strain, close and dry: a short deep steel-girder strain groan, then a hard heavy snap of giant steel structural cables parting, with a deep ringing iron shudder after. Massive industrial scale, heavy and blunt, no explosion, no reverb."},
{"id":"death_chorus_rupture","prompt":"Colossal armored living alien starship creature splitting apart, close and dry: an immediate heavy cracking of thick rigid chitin armor plates, then a deep visceral low-end rupture of dense tissue and thick sinew cords parting under enormous pressure, settling into silence. Terrifying monster death, dense and heavy, no fire, no metal, no reverb."},
{"id":"ui_boss_arrival","prompt":"Ominous orchestral arrival sting: one deep slow strike of a large orchestral bass drum, with low brass and bowed double basses holding a dark low D and a heavy iron shudder beneath, fading out naturally. Real acoustic orchestra, grave and threatening, no vocals."},
{"id":"ui_reward_vault","prompt":"Heavy precision vault mechanism releasing, close and dry: a damped solid machined-metal latch movement with a deep soft thud, then one warm low struck bronze bell tone that rings briefly and fades. A real recorded physical object, fully acoustic, dignified and restrained, no reverb."},
{"id":"evt_fleet_warp_in","seconds":1.2,"prompt":"Heavy sci-fi starship arriving from a faster-than-light jump, close and dry: a very short tight inward pressure snap, then an immediate deep low-end displacement boom and a brief clean engine rumble that decays fast. Heavy, clean, contained, no explosion, no reverb."},
{"id":"amb_bridge_bed","prompt":"Quiet sci-fi starship command bridge room tone: a very low steady reactor hum, faint smooth ventilation air, and a soft constant electrical presence. Perfectly even, calm and unbroken from start to finish, low and warm, no vocals."},
{"id":"mus_battle_sunward_proto","cue":"battle music prototype, SHOWCASE ARC for Ryan's ear (palette, motif, weight); not the stem source","prompt":"Dark orchestral space fleet battle score, instrumental, 96 BPM, 4/4, D minor, 36 bars. Weathered low brass, solemn cellos and double basses, deep measured war drums, subtle struck forge-metal resonances. A grave four-note motif on low brass and bowed cello, the notes D, A, F, E, three long notes then a falling last note, returning and developing throughout. Three 12-bar sections: bars 1 to 12 tense and restrained, low cellos and a quiet drum pulse; bars 13 to 24 a driving tactical build with layered brass chords and firmer drums; bars 25 to 36 a solemn, powerful brass and string climax, the last two bars easing back to the opening texture so the piece can repeat. Clear harmonic movement, real emotional weight, restrained and tactical, no vocals, no choir."},
{"id":"mus_reward_proto","seconds":48,"prompt":"Quietly triumphant instrumental reward-screen theme for a dark space strategy game, 80 BPM, 4/4, D Dorian, 16 bars. Warm brass and strings, calm and dignified, not cheesy. A solo cello states a warm four-note motif, the notes D, A, F, E; muted French horns and full low strings answer and swell to hard-won relief, then settle on a held open fifth that can lead back to the start. Real acoustic orchestra, mature and restrained, no vocals, no choir."}
]
```

**Remove:** `wep_sunward_turret_twin`, `imp_bio_acid`, `dmg_breach_open` (each replaced below).

**Unchanged:** `wep_directorate_ion_beam`, `death_directorate_blackout`, `death_ithar_shatter`, `death_eclipse_shear`.

### `elevenlabs_pilot_v2.json`: items to add

```json
[
{"id":"wep_sunward_turret","kind":"sfx","cue":"gun_shell (Sunward turret: ONE shot; sfx.gd twin style already plays it twice)","group":"weapon_sunward","seconds":0.6,"model":"eleven_text_to_sound_v2","influence":0.65,"takes":2,"prompt":"Single shot from an armored sci-fi starship gun turret, close and dry: an immediate tight hard propellant crack with a short bright steel ring and a compact punchy low thump, very short decay. Medium caliber, quicker and tighter than a main battery gun, no reverb."},
{"id":"wep_sunward_hbattery","kind":"sfx","cue":"gun_shell heavy (Sunward hbattery: ONE shot; sfx.gd staggers the 5)","group":"weapon_sunward","seconds":1.0,"model":"eleven_text_to_sound_v2","influence":0.65,"takes":2,"prompt":"Single very heavy sci-fi capital starship main gun shot, close and dry: an immediate massive explosive propellant blast with a long deep forged-iron barrel ring and a heavy hull-frame low-end shudder under it. The largest gun in the fleet, slower and deeper than a standard cannon, full crisp attack, no reverb."},
{"id":"wep_sunward_battery_v3ab","kind":"sfx","cue":"A/B: same prompt as wep_sunward_battery on v3 (keep the two prompt strings identical)","group":"weapon_sunward","seconds":0.8,"influence":0.65,"takes":1,"prompt":"Single heavy sci-fi starship cannon shot, close and dry: an immediate hard explosive propellant crack with a dense forged-iron barrel ring and a deep solid low thump, decaying fast. Large-caliber military gun, mid-heavy scale, full crisp attack with a strong low body, no reverb."},
{"id":"wep_torp_eject","kind":"sfx","cue":"torp_charge (heavy torpedo eject before ignition; CHARGE_LEAD is 0.30 s today)","group":"weapon_shared","seconds":0.5,"influence":0.65,"takes":2,"prompt":"Heavy starship launch cell pushing out a massive missile, close and dry: one deep compressed-gas thump with a dense steel rail slide and a solid mechanical stop. Short, heavy, industrial, no reverb."},
{"id":"wep_directorate_picket","kind":"sfx","cue":"gun_flak variant (Directorate flak, shown as Picket lasers: ONE pulse)","group":"weapon_directorate","seconds":0.5,"model":"eleven_text_to_sound_v2","influence":0.65,"takes":2,"prompt":"Single pulse from a military sci-fi starship point-defense energy emitter, close and dry: an immediate very short tight energy snap with a small firm capacitor thump of low-mid body and an instant clean cutoff. Light, fast, precise, smooth-edged, no reverb."},
{"id":"wep_hullbreaker_junk_gun","kind":"sfx","cue":"gun_shell variant (Hullbreaker Junk turret and autocannon: ONE shot)","group":"weapon_hullbreakers","seconds":0.6,"model":"eleven_text_to_sound_v2","influence":0.65,"takes":2,"prompt":"Single shot from a worn salvaged sci-fi starship gun turret, close and dry: an immediate rough hard propellant crack with a loose clattering steel-housing rattle and a blunt low thump, short decay. Crude, heavy, badly maintained machinery, no reverb."},
{"id":"wep_chorus_spore_cloud","kind":"sfx","cue":"gun_flak variant (Chorus spores, shown as Spore cloud, k is flak)","group":"weapon_chorus","seconds":0.8,"influence":0.65,"takes":2,"prompt":"Giant living alien starship creature venting a dense defensive cloud of spores, close and dry: an immediate short heavy pressurized gas burst carrying a thick grainy spray of particles that spreads outward and thins fast. Large creature scale, low and heavy, no metal, no reverb."},
{"id":"evt_pass_by_slug","kind":"sfx","cue":"shot_pass_by (missed heavy shot passing; today one generic whoosh for every weapon)","group":"weapon_shared","seconds":0.7,"influence":0.65,"takes":2,"prompt":"A massive projectile passing close by at extreme speed in a sci-fi space battle, dry: one very fast deep heavy pass with a short pressure thump at the closest point and a quick dark tail falling away. Heavy and brief, low and solid, no reverb."},
{"id":"wep_eclipse_doom_charge","kind":"sfx","cue":"lance_charge variant (Eclipse doom pull-in; needs its own lead, CHARGE_LEAD is 0.26 s today)","group":"weapon_eclipse","seconds":0.6,"influence":0.65,"takes":2,"prompt":"Ancient alien flagship superweapon gathering power, close and dry: a fast deep inward-pulling pressure swell, as if all sound is being drawn into one point, cutting to dead silence at the end. Terrifying, dark, heavy, no reverb."},
{"id":"wep_layer_body_heavy","kind":"sfx","cue":"Layer B test: low body only, to prove the three-layer idea before Gate 3","group":"weapon_layer","seconds":0.6,"model":"eleven_text_to_sound_v2","influence":0.65,"takes":2,"prompt":"One deep heavy low-end thump felt through a massive steel structure, close and dry: a single immediate sub-bass punch with a short dense hull-frame shudder and a soft rounded top. Pure low body, no reverb."},
{"id":"imp_metal_light","kind":"sfx","cue":"hit (ordinary shell hit on metal, the most-heard impact)","group":"impact","seconds":0.6,"model":"eleven_text_to_sound_v2","influence":0.65,"takes":2,"prompt":"Medium cannon shell striking thick starship armor plating, close and dry: an immediate hard dense metallic thud with a short dull plate ring and a small scatter of fragments, quick decay. Solid and contained, clearly smaller than a heavy armor breach, no reverb."},
{"id":"imp_metal_heavy_v3ab","kind":"sfx","cue":"A/B: same prompt as imp_metal_heavy on v3 (keep the two prompt strings identical)","group":"impact","seconds":1.0,"influence":0.65,"takes":1,"prompt":"Heavy armor-piercing shell slamming into thick starship armor plating, close and dry: an immediate crushing metallic crunch with a deep resonant hull-frame boom and a short spray of heavy steel fragments scattering. Massive armor impact, deep and weighty, no reverb."},
{"id":"imp_energy_sear","kind":"sfx","cue":"hit_las and hit_plasma (energy bolt on metal)","group":"impact","seconds":0.7,"influence":0.65,"takes":2,"prompt":"Hot energy bolt striking thick starship armor plating, close and dry: an immediate dense searing impact thump with a short flash-burn of metal and a brief fading heat crackle. Solid and hot, weighty with a smooth top, no explosion, no reverb."},
{"id":"imp_acid_on_metal","kind":"sfx","cue":"new cue: Chorus acid on a metal hull (weapon side; was imp_bio_acid)","group":"impact","seconds":1.2,"influence":0.65,"takes":2,"prompt":"Mass of alien acid striking thick starship armor plating, close and dry: an immediate dense heavy liquid impact, then a deep corrosive chemical roar, like an industrial acid vat eating steel, in a thick seething burn that fades. Heavy industrial scale, low-mid weight, no fire, no explosion, no reverb."},
{"id":"imp_bio_flesh","kind":"sfx","cue":"hit_wet (any shot striking a Chorus hull: the bio target substance)","group":"impact","seconds":0.9,"influence":0.65,"takes":2,"prompt":"Heavy projectile striking the thick armored hide of a giant living alien starship creature, close and dry: an immediate deep dense thud into chitin plate and heavy muscle, a hard shell crack, and a short thick low burst of fluid pressure. Enormous creature scale, heavy and blunt, no metal, no reverb."},
{"id":"shd_hit_absorb","kind":"sfx","cue":"shield (ordinary shield block; R412 rule 4: a shield block is quiet)","group":"shield","seconds":0.6,"influence":0.65,"takes":2,"prompt":"Weapon shot absorbed by a large starship energy shield, close and dry: an immediate soft deep energy thud with a short smooth resonant hum that spreads and fades quickly. Quiet, rounded, contained, a clean deflection, no explosion, no reverb."},
{"id":"dmg_breach_shear_metal","kind":"sfx","cue":"new R416 cue: breach opening, metal hulls only (glass, bio and obsidian reuse their imp_ cue)","group":"r416_damage","seconds":0.8,"influence":0.65,"takes":2,"prompt":"Thick armored starship hull plating shearing open, close and dry: an immediate violent heavy steel-plate rupture with structural girders snapping and a deep wrenching metal strain. Massive, heavy, industrial, no explosion, no reverb."},
{"id":"dmg_breach_vent","kind":"sfx","cue":"new R416 cue: breach decompression, shared by every hull","group":"r416_damage","seconds":1.2,"influence":0.65,"takes":2,"prompt":"Atmosphere blasting out of a breached starship compartment, close and dry: an immediate fierce roaring jet of escaping pressurized air, as strong as a burst industrial pressure line, thinning quickly to nothing. Large and violent, wide, deep and forceful, no explosion, no reverb."},
{"id":"dmg_engine_fail","kind":"sfx","cue":"new R416 cue: engine tier loss, metal hulls (md line 68 names it; the pack had no prompt)","group":"r416_damage","seconds":0.9,"influence":0.65,"takes":2,"prompt":"Large starship main engine losing power, close and dry: an immediate deep thruster roar stumbling and choking off in two uneven low surges, then dropping to nothing. Heavy, low, mechanical, no explosion, no reverb."},
{"id":"death_metal_break","kind":"sfx","cue":"boom_l base (the break every non-variant death plays)","group":"death_beat","seconds":2.2,"influence":0.65,"takes":2,"prompt":"Large armored starship breaking apart, close and dry: an immediate enormous deep structural break, a heavy low-end blast with thick steel plating rupturing and large wreckage tumbling away, decaying into a long low rumble. The heaviest event in a space battle, deep and wide with a smooth top, no reverb."},
{"id":"ui_click_switch","kind":"sfx","cue":"ui_click","group":"ui_event","seconds":0.5,"influence":0.6,"takes":3,"prompt":"One heavy precision mechanical toggle switch on a military control console being pressed, close and dry: a single short solid low-mid click with a soft damped stop. A real recorded physical object, fully acoustic, weighty and quiet, no reverb."},
{"id":"ui_confirm_latch","kind":"sfx","cue":"ui_confirm","group":"ui_event","seconds":0.5,"influence":0.6,"takes":2,"prompt":"One heavy machined control lever on a military console seating firmly into place, close and dry: a short two-stage solid mechanical clunk, deeper and more final than a button press. A real recorded physical object, fully acoustic, weighty, no reverb."},
{"id":"ui_turn_start","kind":"sfx","cue":"ui_your","group":"ui_event","seconds":0.8,"influence":0.6,"takes":2,"prompt":"One soft low strike on a large bronze plate, close and dry, with a short warm fade. A real recorded physical object, fully acoustic, calm and grave, no reverb."},
{"id":"mus_battle_sunward_stemloop","kind":"music","cue":"battle music prototype, STEM-READY LOOP (source for the first stem-separation test)","group":"music","seconds":40,"takes":1,"prompt":"Dark orchestral space fleet battle score built as one continuous loop, instrumental, 96 BPM, 4/4, D minor, 16 bars. Four parts that all play in every bar from the first to the last: deep measured war drums; cellos and double basses on a driving low ostinato; low brass carrying a grave four-note motif, the notes D, A, F, E, varied every four bars; a sustained pad of strings and forge-metal resonance. Even energy and density from start to finish; the interest comes from a chord progression that moves every two bars and from the motif's variations. Starts at full texture and the final bar leads straight back into the first. No vocals, no choir."}
]
```

### `cohesive_audio_v2.md`: old and new

| Line | Old | New |
|---|---|---|
| 11 | "On `ladder_macro` (v3), it also inserted a ~250 ms mechanical breech clack *before* the shot boom" | "Separately, the `ladder_macro` prompt listed 'heavy breech block slamming' before the thump, so the model played a ~250 ms breech clack first. Prompt order is playback order." |
| 31 | "(`naval`, `boat`, `submarine`, `wooden deck`, `gunpowder cannonball`, `foghorn`, `broadside` inside ElevenLabs prompts)" | Same list plus: "`warship`, `torpedo tube`, `leviathan`, `abyssal`, `wake`, and sustained low-brass swells on UI stings" |
| 32 | "Post-shot breech cycling, servo returns, and heat vents live in a separate Layer C tail (`+80` to `+250 ms`), never before the blast." | "Wind-ups go in the engine's existing charge slot (`CHARGE_LEAD`, `sfx.gd`), never inside the shot clip. Fire clips contain no impact. Every delivered file is onset-measured and trimmed; prompt wording alone does not guarantee t=0. Mechanical tails are a separate per-volley cue at pri 0, not a delayed layer inside a `gun_` cue (`sound_weight_check.gd`)." |
| 33 | "Remove `\"soft top\"` from weapon prompts: Record full, crisp, physical transients ... without sounding muffled." | "Replace the hull-muffle suffix with 'close and dry, firm clean attack, strong low body'. Keep the playbook's 'weight without harshness': no 'razor-sharp', 'piercing', 'shattering' or 'loud'. `sfx.gd` has no distance or class filter today, so the source must not be shrill. This needs a matching edit to docs/playbooks/sound.md section 1." |
| 34 | "Never prompt `\"tearing rip\"`, `\"peeling\"`, `\"slap\"`, `\"rush of breath\"`, `\"locking clamps\"`, or bare `\"glass shatter\"`." | Add: "Also never: `tearing`, `ripping`, `sizzling`, `boiling`, `bubbling`, `hiss` without a scale anchor, `chime`, `cut-crystal`, `whip-crack`, `bark`, `shotgun`, `pops`, `ping`, `steam`, `vacuum`, and words with a second meaning (`organ`, `horn`). One size word per tier; 'colossal' only for Doom and deaths. No numeric timings and no design notes in prompts." |
| 35 | "where Gate 1 showed v2 held tighter onset timing than v3" | "where Gate 1's single A/B pair suggested tighter onsets on v2. Gate 2 re-tests with two same-prompt v3 twins. v2 is listed for removal on Mar 1 2027, so any family approved on v2 must have all its takes generated before then." |
| 36 | "Gate 2 uses **2 takes per SFX**" | "Gate 2 uses 2 takes per SFX (3 for `ui_click`, 1 for reference and A/B items), run in two waves with `--only`: a 14-item wave first, the rest after onset and scale checks." |
| 43-45 | The three "Layer A/B/C" bullets | "Gate 2 clips are single-shot composites, one per shot, for judging identity by ear. The three-layer split is a Gate 3 question, tested now on one item (`wep_layer_body_heavy`). The engine staggers shots (`cues.json` gap and defer); no clip bakes a volley except the labelled reference salvo." |
| 49 (prompt ids) | "`wep_sunward_hbattery_salvo`, `wep_sunward_turret_twin`, ... `wep_mech_recoil_tail`" | "`wep_sunward_battery`, `wep_sunward_hbattery`, `wep_sunward_turret`, `wep_sunward_autocannon`, `wep_sunward_lance_beam`, `wep_torp_eject` + `wep_sunward_torp_launch`, `wep_flak_airburst`" |
| 50 | "`wep_directorate_laser`, `wep_directorate_hturbo`, `wep_directorate_ion_beam`, `wep_flak_airburst`" | "`wep_directorate_laser` (Plasma cannon), `wep_directorate_hturbo` (Plasma battery), `wep_directorate_ion_beam`, `wep_directorate_picket` (Picket lasers)" |
| 51 | "`wep_hullbreaker_scatter`, `wep_hullbreaker_rockets`, `wep_sunward_torp_launch`, `wep_sunward_autocannon`, `wep_sunward_turret_twin`" | "`wep_hullbreaker_scatter`, `wep_hullbreaker_junk_gun` (turret, autocannon), `wep_hullbreaker_rockets` (torp and htorp), `wep_flak_airburst`" |
| 52 | Weapon order and "heavy living bio-torpedo launch" | "`bioplasma` to `wep_chorus_spines` (Spine volley) or `wep_chorus_bioplasma` (confirm the look); `tendril` to `wep_chorus_tendril`; `spores` to `wep_chorus_spore_cloud`; `sporeb` to `wep_chorus_sporeb` (strike-craft Acid sacs, `k: sq`)" |
| 53 | "`wep_ithar_shard`, `wep_ithar_pulsar`, `wep_ithar_startorp`" | Same, plus: "`flak` (Mirror veil): no clip until its look is confirmed" |
| 54 | "world-ending gravity-well Doom discharge" | "`wep_eclipse_doom_charge` + `wep_eclipse_doom` (Corona arc); `flak` (Null shredder) reuses `wep_eclipse_gsentry`; `nlance` is one pulse per fire time" |
| 66 | "Expand `HIT_BY_TARGET` ... to cover all 4 substances (`imp_metal_heavy`, `imp_glass_armor`, `imp_bio_acid`, NEW `imp_obsidian_eclipse`)" | "Add `deathless` to `HIT_BY_TARGET` (`imp_obsidian_eclipse`) and replace `hit_wet` with `imp_bio_flesh`. Metal stays on the weapon-family path (`imp_metal_light`, `imp_metal_heavy`, `imp_energy_sear`) so the `audio_check.gd` impact asserts hold. `imp_acid_on_metal` is a weapon-side cue." |
| 67 | "triggers `dmg_breach_open` (alloy shear + rapid vacuum decompression hiss)" | "triggers `dmg_breach_vent` on every hull, plus `dmg_breach_shear_metal` on metal hulls only; glass, bio and obsidian use their own impact cue for the opening" |
| 68 | "Exact slot knockout -> `dmg_turret_knockout` at that turret; ... intermittent `dmg_shield_burnout` crackles" | "Slot knockout: `dmg_turret_knockout`, metal hulls only, at most one per ship per sync. Engine loss: `dmg_engine_fail` (not Chorus). Generator: one 0.6 s `dmg_shield_burnout` at full level on the first crackle, later ones quiet with max 1. All behind `VS_WOUNDS_V2`." |
| 70 | "**one coherent 90 to 120 s track per faction**, split into 4 ElevenLabs stems in Gate 3" | "one coherent 90 to 120 s loop per faction in which all parts play in every bar (evolution by harmony and motif, not by adding instruments), split into stems in Gate 3 only after one stem-separation test on `mus_battle_sunward_stemloop` shows which stems the service returns. Fallback: three layers on the existing calm, intense and bed slots." |
| 73 | "A dark, austere 4-note recurring motif in D minor / D Dorian" | Add: "Target notes D, A, F, E. Whether separate prompts can share a motif is a Gate 2 test, not a given." |
| 85-86 | "(**47 items** ... = **91 files**)" and "**7,401 credits**" | "(**68 items**, **130 files**)" and "**8,422 credits** by the generator's estimate. Gate 1 billed sound effects at about 11 credits per second against the estimated 40, so real spend is expected near 4,250." |
| 97 | "`takes: 1` on the first sweep (~4,500 credits)" | "`takes: 1` on every SFX would be 5,113 credits by the generator's rates" |

---

## Recomputed Gate 2 estimate

**Rates** (`elevenlabs_gen.js:34-35`, `:85`, `:88`): sound effects `ceil(seconds * 40)` per take; music `ceil(seconds / 60 * 900)`.

**Original, verified by hand:** the 44 short effects total 57.2 s, or 2,288 per take.
- 2,288 x 2 = 4,576
- ambience 20 s = 800
- music 90 s + 45 s = 1,350 + 675 = 2,025
- **Total 7,401** (matches `md:86`)

**After edits:**

| Group | Items | Credits |
|---|---|---|
| Weapons (35 items; the reference salvo at 1 take) | 35 | 2,484 |
| v3 A/B twins (0.8 s and 1.0 s, 1 take each) | 2 | 72 |
| Impacts (80 + 48 + 56 + 80 + 96 + 72 + 80) | 7 | 512 |
| Shields (120 + 112 + 48) | 3 | 280 |
| Damage (64 + 96 + 64 + 48 + 72) | 5 | 344 |
| Deaths (104 + 80 + 136 + 112 + 104 + 176) | 6 | 712 |
| UI and events (176 + 112 + 96 + 60 + 40 + 64) | 6 | 548 |
| **Short effects subtotal** (123.8 s billed) | 64 | **4,952** |
| Ambience 20 s x 1 | 1 | 800 |
| Music: 90 s (1,350) + 40 s (600) + 48 s (720) | 3 | 2,670 |
| **Total** | **68 items, 130 files** | **8,422** |

- **Hold-back option:** leave out the stem loop (600) and six optional items (`wep_hullbreaker_junk_gun` 48, `wep_layer_body_heavy` 48, `dmg_engine_fail` 72, `death_metal_break` 176, `ui_turn_start` 64, `evt_pass_by_slug` 56). That is 8,422 - 1,064 = **7,358**.
- **Likely real billing (INFERRED from Gate 1):** 123.8 s x 11 is about 1,362; ambience about 220; music 2,670 at estimate. About **4,250**. The original pack on the same basis is about 3,500.

**Takes 2 versus 1:**
- On the original pack, the second take costs 2,288 estimated and about 630 real credits.
- Keep 2 takes. One take per prompt in Gate 1 could not tell a bad prompt from a bad roll, and the saving is half a percent of the pool. The scarce resource is your listening time.
- The better control is staging. Gate 1's flaws were systemic and were found only after all 27 clips were bought.

**Wave A** (14 ids, 1,060 estimated; run with `--only` and `--max-credits 1200`): `wep_sunward_battery`, `wep_sunward_battery_v3ab`, `wep_directorate_laser`, `wep_chorus_spines`, `wep_ithar_shard`, `wep_eclipse_gauss_fire`, `wep_sunward_lance_beam`, `imp_metal_heavy`, `imp_metal_heavy_v3ab`, `imp_bio_flesh`, `shd_break_energy`, `death_chorus_rupture`, `ui_click_switch`, `ui_reward_vault`.

**Wave B:** the rest, with `--max-credits 9300`, after checking Wave A for onset, scale and v2 against v3.

---

## Not checked:

- **No audio was heard.** Every prompt-risk finding is INFERRED from wording plus the Gate 1 results reported in `cohesive_audio_v2.md:11-23`.
- **Call sites of `sfx.gun`, `sfx.lance`, `sfx.torp`** (`battle.gd`, `fx_weapons.gd`): whether guns are requested per shot or per volley, and which style each weapon passes. B1 rests on `sound.md:23` and the salvo logic in `sfx.gd`.
- **What each weapon looks like on screen** (`faction_looks.json`, `fx_weapons.gd`): Sunward "Sear" guns, Chorus spine versus bile, "Mirror veil", "Corona arc". `fx_breach.gd` and `fx_ship.gd:331` were not seen.
- **`elevenlabs_gen.js` past line 100:** how `influence`, `loop`, `model` and instrumental flags are sent, output format options, handling of rejected prompts, and any prompt length check.
- **ElevenLabs behaviour:** adherence to numeric timing, filtering of named works, text length limits, v2 against v3 onsets, which stems separation returns and its cost, and whether the 11 credits per second rate still applies.
- **Whether the `--dry` run was actually executed.** I re-derived 7,401 by hand only.
- **The MP3 to Ogg conversion and clip index step,** and `tools/music/process.py`.
- **Godot `AudioStreamSynchronized` looping behaviour** with separated stems.
- **`faction_death_check.gd`, any music check script, `docs/RULEBOOK.md` 8.4, `docs/playbooks/factions.md`.**
- **Which reward music you like.** I assumed Gate 1's `reward_preview`.