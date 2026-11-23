# Fable audit of Antigravity's Wave A2 ear audit (issue 1752)

Run Nov 23 2026 03:28 to 03:40 UTC through the Claude API (claude-fable-5-2, no caps, end_turn, about $3.59). Input: Antigravity's audit, the manifest at 025ee1e4, the plan, Claude's measurements and 30 spectrograms. Raw stream: voidsworn-relay branch pc-out-fable-a2-1752 at 4a3c6594. Text below is Fable's, unedited.


**Summary**
1. The keep and reject calls mostly hold, but three keepers are weak on paper (`ui_reward_vault`, `imp_bio_flesh`, `death_chorus_rupture_t1`), and the "AAA standout" `eclipse_gauss_fire_t1` is 97% below 500 Hz by my numbers.
2. Antigravity's band table disagrees with mine on four takes, so no band share should be an accept rule until one script is agreed.
3. Of the four traps, only bass-word stacking is confirmed; "smooth top end" is not supported, and the beam and breaker traps are plausible from one prompt each.
4. Of the 23 replacement prompts, 11 contain words the plan bans, and the beam rewrites give five weapons from four factions the same recipe.
5. The credit math is right (about 147); run Wave A3 with my edits (9 ids, 18 takes, about 223 credits) and hold the Wave B rewrites until it reports.

## 0. Settle these before trusting any number

- **The two measurement sets conflict.** I cannot tell which script is right without the files.

| Take | Antigravity | Mine |
|:--|:--|:--|
| `wep_directorate_laser` t1/t2 | 20% / 30% above 1 kHz, centroid 862 / 1208 | 3% / 2% above 500 Hz, centroid 138 / 131 |
| `wep_eclipse_gauss_fire_t1` | 17% above 1 kHz, centroid 793 | 3% above 500 Hz, centroid 177 |
| `shd_break_energy_t1` | 40.5% in 4 to 10 kHz, centroid 4127 | 10% above 2 kHz, centroid 694 |
| `imp_metal_heavy_t1` | 43% below 250 Hz | 33% below 500 Hz (impossible for one signal) |

- **The shield t1 spectrogram favours my numbers.** Its brightest region is a 40 to 200 Hz swell at about 0.5 s.
- **The takes are stereo; today's assets are mono.** Antigravity's table says "mono decoded". If highs cancel in the mono fold-down, the game will sound duller than what Ryan auditioned. That would also explain part of the conflict; this is a hypothesis to check per channel.
- **Some baselines are the same file.** By identical measurements, `wep_directorate_laser_today0` equals `wep_sunward_lance_beam_today0`. A 2.0 s sub rumble serves as `imp_metal_heavy_today1`, `death_chorus_rupture_today2` and `wep_eclipse_gauss_fire_today0`. Either cues share layers or the listening page maps baselines wrongly.
- **"Upgrade over today0" compares against one file of several.** I cannot tell from the names whether todayN are layers or variants.

## 1. Keep and reject verdicts

| Item | Antigravity | My read |
|:--|:--|:--|
| `imp_metal_heavy` t1/t2 | Keep | **Holds; strongest item.** t1 is genuinely full band (40% mid, 23% hi). Trim 28 / 16 ms of dead head. Check the overs are decode overshoot, not baked clipping. |
| `death_chorus_rupture` | Keep both | **t2 holds; t1 is weak.** t1 is 89% below 500 Hz with 2% above 2 kHz. Today's set has a 60% mid file and two bright ones. Keep t1 only as an alternate with a presence lift. |
| `ui_reward_vault` | Keep with gain | **Ear-only keeper, at risk in real playback.** Both takes are 99% below 500 Hz, 0% above 2 kHz, centroid about 150 Hz. Gain will not help on laptop speakers, and "+2 dB at 2.5 kHz" boosts nothing. The peak lands 174 / 199 ms in. |
| `imp_bio_flesh` | Keep with EQ | **Conditional.** At 92% / 84% below 500 Hz, t2 is close to the rejected spines t2 profile. The crack is real but lives in the first 100 ms. The prescribed +3 dB tilt is far too timid. |
| `wep_eclipse_gauss_fire` t1 | Keep | **Keep by ear, weak on paper** (55% sub, 42% low). The spectrogram does show a broadband snap at 30 to 60 ms. Trim 21 ms. Ryan should re-check it on small speakers. |
| `wep_eclipse_gauss_fire` t2 | Reject | **Holds.** The peak arrives at 239 ms and RMS is -29.2. |
| `wep_sunward_lance_beam` | Reject | **Holds; no salvage.** Both are flat broadband bricks with 4% to 5% of energy in the first 100 ms. t2 runs to the last sample. |
| `shd_break_energy` | Reject | **Holds as a replacement.** The 500 Hz to 2 kHz band holds 4% / 2%. But today0 has the same hole (1% mid); today's body sits in today1 and today3 (92% in 120 to 500 Hz). Salvage is layering, not EQ. |
| `wep_directorate_laser` | Reject | **Holds, for a different reason.** "90% over in 0.13 s" is not the defect: today's sound has the same envelope (83% in the first 100 ms, end 0.34 s). The loss is top end: today has 21% above 500 Hz, A2 has 3%. |
| `wep_ithar_shard` | Reject | **Holds.** t2 shows faint ringing partials at 2 to 8 kHz, but lifting them 30 dB out of an MP3 is not worth it. |
| `wep_chorus_spines` | Reject | **Holds.** t1 also shows two clicks about 70 ms apart, which reads as two events. |

- **Mastering figures I would use for `imp_bio_flesh`:** high-pass at 60 to 70 Hz, about -6 dB below 200 Hz, about +6 dB above 1.5 kHz.
- **Reward bell pitch:** Antigravity reports 151 Hz and calls it D3. D3 is 146.8 Hz, so 151 is about 50 cents sharp. Measure it and correct it, because the reward music is in D.
- **Free salvage tests before paying:**
  - Use shield t1's first 150 ms of crackle over today's body.
  - Try a 6 to 8 dB tilt on the laser.
  - Low-pass the shard and spines rejects as Layer B body candidates; they are close to what `wep_layer_body_heavy` asks for.

## 2. The four traps

**Trap A, "smooth top end" muffles: not supported.**
- The membership is right: lance, shield, laser, shard and eclipse had the phrase.
- The three brightest takes in the batch all carried it: shield t2 (51% above 2 kHz) and lance t1/t2 (42% / 29%).
- The darkest takes did not carry it: spines at 99% below 500 Hz.
- The one "standout", eclipse t1, carried it.
- Mean centroid is 844 Hz with the phrase and 439 Hz without.
- Removing it is harmless, but it will not fix anything.

**Trap B, beam roar / held flat / even pressure: plausible.**
- It rests on one prompt, two takes and no control. The words were in the prompt, and both takes are flat bricks.
- The prompt literally asked for "held solid and flat" and "even pressure", and "roar" is a noise word. The model obeyed.
- The Wave B flags are accurate: ion beam has "held solid", pulsar has "roar" and "held solid", doom has "roar".

**Trap C, breaker slam plus flat pitch: plausible on wording, not shown by data.**
- It also rests on one prompt. By my numbers the laser failed the same way as shard and spines, which had no breaker wording.
- A breaker slam is a switch, so the reading is sensible.
- "All 4 remaining Directorate weapons use this exact recipe" is wrong in detail. Turbo and hturbo have both phrases, ion beam has the slam without the flat-pitch phrase, and picket has a relay snap with the flat-pitch phrase.
- The remedy swings back toward the Wave A raygun.

**Trap D, bass stacking: confirmed as a correlation.**
- Seven A2 prompts contained "sub-bass" or "sub-harmonic". Of their 14 takes, 12 are 84% or more below 500 Hz.
- The lance and metal takes, without those words, are 33% to 74%.
- **Literal Hz numbers: plausible, not isolated.** Both Hz prompts were also bass-stacked. The shard asked for 150 Hz and its energy sits below 120 Hz, so the number was not obeyed.
- **Standalone "static": not supported as written.** The A2 shield prompt has "electrostatic dissipation" and "electric crackle", not standalone "static". Removing it from Wave B is still sensible.
- **Size words are missing from this trap.** Colossal, monumental and massive also pull the model low, and the rewrites keep them.

**Influence 0.50 to 0.55: no A2 evidence.** Take-to-take variance is already large at 0.65 (eclipse t1 and t2 differ by 9 dB RMS). Changing the prompt and the influence together means A3 cannot say which one worked.

**Under 360 characters:** harmless margin. I hand-counted four of Antigravity's prompts (325, 328, 346, 252) and all matched, so I accept the other counts.

## 3. Prompt check

**General findings**
- **Banned words.** The "verified" label covered length, em dashes and negations, not the plan's ban list. Eleven of the 23 prompts contain a banned word.
- **Negations.** There are no literal ones. The residue is comparatives ("lighter than a main plasma cannon") and "before the end" in four beams; the model has no clip clock.
- **Model.** None of the 23 sets a per-item model, so all inherit v3. Do not paste the table shorthand "v3" as a model id.
- **Durations.** All are unchanged and sane on paper.
- **Beam recipe.** Lance, ion beam, needle, pulsar and doom all become "ignition snap, singing harmonic tone, bass hum, cutoff". That repeats the Wave A mistake of one tail on every prompt. "Singing" is also a voice word.

**Per prompt**

| Prompt | Problem | Action |
|:--|:--|:--|
| A3 `wep_sunward_lance_beam` | "singing"; "plasma" is the Directorate's word; "before the end"; influence changed | Rewrite, hold 0.60, add a 0.45 twin |
| A3 `shd_break_energy` | "Loud", "shattering" banned; "explosive" re-adds the Wave A explosion leak; "crystal glass" is the wine-glass trap and collides with the prismatic variant; "groan" | Rewrite |
| A3 `wep_directorate_laser` | "bark", "warship" banned; "plasma cannon bolt" reverses section 7; pitch guard dropped | A/B two recipes |
| A3 `wep_ithar_shard` | "razor-sharp", "whip-crack" banned; scale anchors removed | Rewrite |
| A3 `wep_chorus_spines` | "warship" banned; "air-whip"; "chest-thump"; ballista reads medieval | Rewrite |
| A3 `wep_eclipse_gauss_fire` | Text is clean, but prompt and influence both change | Keep text at 0.65, add unchanged control twin |
| `wep_directorate_turbo` | "bark"; comparative | Rewrite |
| `wep_directorate_hturbo` | "warship"; comparative | Rewrite |
| `wep_directorate_ion_beam` | "singing"; sustained "crackling"; "before the end" | Rewrite |
| `wep_directorate_picket` | Comparative only | Light edit |
| `wep_ithar_needle` | "Razor-sharp", "razor-clean"; "singing" | Rewrite |
| `wep_ithar_pulsar` | "cathedral" plus "singing" plus "chord" invites real voices; the old instrumental guard was dropped | Rewrite |
| `wep_eclipse_nlance` | Near copy of the gauss prompt; comparative | Rewrite |
| `wep_eclipse_doom` | "before the end"; shared beam template | Light edit |
| `shd_break_prismatic` | "Loud", "shattering" twice; "explosive"; "panes" and "glass fallout" are a window smash | Rewrite |
| `wep_chorus_bioplasma` | "pop"; generic mortar. The plan lists it as an alternate to spines for the same weapon | Hold until the look is confirmed |
| `wep_chorus_tendril` | "whip-crack" banned; "groan"; the whoosh builds into the crack, so the transient is late | Rewrite |
| `imp_energy_sear` | "sizzling" banned | Edit |
| `imp_las` | "sizzle" | Edit |
| `death_eclipse_shear` | None | Keep as written |
| `death_metal_break` | "tearing" banned; "full-band" is jargon | Edit |
| `dmg_engine_fail` | "choking" plus "cough" risks a human cough | Rewrite |
| `shd_hit_absorb` | "Quiet" belongs in the mix gain, not the source | Edit |

**Paste-ready block.** Character counts are hand counts; let the generator guard confirm them. Influence stays at the A2 values so wording is the only variable. Add twin ids the way the `_v3ab` twins were added.

```text
== WAVE A3 ==
wep_sunward_lance_beam | 1.8 s | 0.60 | 314
Capital starship solar-thermal lance firing a sustained beam: an immediate hard bright ignition crack, then a powerful steady pitched beam drone with a bright ringing molten-metal core over a deep reactor furnace hum, holding one strong clear note, then a fast falling power-down into silence. Hot, focused, tonal.

wep_sunward_lance_beam_inf45 | 1.8 s | 0.45 | same string as above

shd_break_energy | 1.6 s | 0.65 | 328
Capital starship energy forcefield collapsing, heard close: an immediate hard bright electrical arc crack and a short burst of crackling high-voltage discharge, straight into a strong descending power-down tone, a huge generator winding down fast through the midrange into a low hum, fading cleanly. Clear, forceful, electrical.

wep_directorate_laser | 0.7 s | 0.65 | 298
Single shot from a military starship high-voltage energy cannon: an immediate hard bright electric arc-flash crack, a dense capacitor-bank discharge with a tight buzzing electrical body and a short firm low punch, steady pitch, abrupt clean cutoff. Disciplined, cold, powerful, crisp bright attack.

wep_directorate_laser_b | 0.7 s | 0.65 | 310
Single shot from a military starship plasma cannon: an immediate crisp superheated plasma-arc crack and a focused directed-energy discharge punch with a strong bright midrange snap and a tight firm low recoil, steady pitch, abrupt controlled cutoff. Cold, disciplined, authoritative capital-ship energy weapon.

wep_ithar_shard | 0.8 s | 0.65 | 329
Crystalline prism cannon on a capital starship firing one hyper-velocity shard: an immediate hard bright crack like a vast sheet of thick ice splitting under tension, with a clear ringing glass-harmonic tone and a tight solid low-mid punch, then a short bright shimmering ring fading cleanly. Crystalline, fast, monumental scale.

wep_chorus_spines | 0.8 s | 0.65 | 304
Massive calcified-bone starship launching one dense petrified spine at extreme velocity: an immediate hard dry crack of thick bone splitting, a tight forceful pressurized-gas launch burst and a fast rushing projectile pass, over a firm solid low-mid punch. Dry, brittle, hard, powerful, monumental scale.

wep_eclipse_gauss_fire | 0.9 s | 0.65 | Antigravity's A3 string unchanged (322)
wep_eclipse_gauss_fire_ctl | 0.9 s | 0.65 | the current manifest string unchanged (the one that made t1)

== WAVE B (Directorate lines assume recipe A wins in A3) ==
wep_directorate_turbo | 0.85 s | 307
Single shot from a military starship medium-heavy high-voltage energy cannon: an immediate hard bright electric arc-flash crack, a thick dense capacitor-bank discharge with a full buzzing electrical midrange body and a solid weighted low punch, steady pitch, crisp clean cutoff. Disciplined, cold, forceful.

wep_directorate_hturbo | 1.0 s | 327
Single shot from a capital starship heavy high-voltage energy cannon: an immediate huge bright electric arc-flash crack, a thick powerful capacitor-bank discharge with a broad buzzing electrical midrange body and a heavy low punch, steady pitch, ending in a brief controlled electrical hum decay. Disciplined, cold, commanding.

wep_directorate_ion_beam | 1.8 s | 323
Capital starship ion disruption beam firing: an immediate crisp electric ignition snap, then a thick steady buzzing high-voltage arc tone like a giant Tesla coil holding one pitch, bright and harmonically rich over a strong transformer hum, then a fast falling power-down into silence. Cold, disciplined, industrial, tonal.

wep_directorate_picket | 0.5 s | 240
Single rapid point-defense energy pulse from a military starship turret: an immediate tight crisp electric arc snap with a short bright buzzing edge and a compact firm low-mid punch, cutting off instantly. Fast, small, precise, disciplined.

wep_ithar_needle | 0.8 s | 284
Crystalline optical beam turret on a starship firing one thin focused pulse: an immediate clean bright prism snap, then a brief pure ringing glass-harmonic tone holding one high clear note over a tight low-mid hum, ending in a crisp clean cutoff. Thin, precise, luminous, crystalline.

wep_ithar_pulsar | 1.6 s | 324
Massive crystalline capital starship firing a sustained harmonic light lance: an immediate luminous prism ignition, then a majestic sustained chord of bowed crystal and glass-harmonica tones, bright and pure, over a warm resonant low drone, then powering down into a brief shimmering tail. Monumental, radiant, instrumental.

wep_eclipse_nlance | 0.9 s | 306
Single dark-energy beam pulse from an ancient alien monolith starship: an immediate cold hard electrostatic snap, then a short hollow bowed-obsidian tone, a dark resonant mid-low drone holding one cold note with a heavy low pulse beneath, cutting abruptly into dead silence. Ancient, cold, ominous, hollow.

wep_eclipse_doom | 2.0 s | 323
Colossal ancient alien flagship superweapon discharging a gravitational void arc: an immediate seismic-charge electrostatic crack expanding into a terrifying sustained hollow bowed-obsidian tone, a vast dark resonant drone with a cold clear pitch over crushing cinematic bass, then dropping abruptly into dead cold silence.

shd_break_prismatic | 1.6 s | 326
Crystalline optical barrier collapsing across a capital starship, heard close: an immediate hard bright crack like a vast sheet of thick ice splitting, a fast cascade of ringing crystal-slab fractures racing outward, and a clear descending glass-harmonic power-down tone, with a short bright shimmering scatter fading cleanly.

wep_chorus_bioplasma | 0.9 s | 291 (hold until the projectile look is confirmed)
Massive calcified-bone starship launching one heavy molten mineral slug: an immediate forceful pressurized-gas launch burst with a thick dense midrange body and a hard dry crack of bone plating, over a firm heavy low thump, ending in a quick vent cutoff. Heavy, solid, dry, monumental scale.

wep_chorus_tendril | 1.0 s | 289
Massive petrified-bone and fibrous-timber limb lashing out from a starship: an immediate hard dry crack of thick bone and timber under tension with a fast heavy rushing sweep through air and a deep timber-and-bone strain, ending in a firm solid stop. Dry, brittle, heavy, monumental scale.

imp_energy_sear | 0.7 s | 263
High-energy plasma bolt striking thick armored starship hull plating: an immediate sharp bright thermal-arc flash and a forceful pressurized heat-impact punch on solid steel, followed by a brief crisp electric weld-arc crackle decaying cleanly. Hot, hard, bright.

imp_las | 0.55 s | 236
Focused thermal energy beam striking thick armored starship steel: an immediate bright sharp concentrated weld-arc flash and crisp scorching metal contact with a tight punchy midrange bite and a quick clean decay. Hot, focused, compact.

death_metal_break | 2.2 s | 314
Large armored capital starship breaking apart: an immediate enormous deep structural break, a massive blast with thick steel plating wrenching and rupturing in hard metallic cracks and heavy wreckage tumbling away, decaying into a long dark low rumble. Huge, wide, heavy, with crisp metal detail and natural decay.

dmg_engine_fail | 0.9 s | 267
Massive starship main fusion thruster losing power: an immediate hard metallic turbine misfire, two uneven strained power surges stuttering and dropping sharply in pitch, then winding down into quiet. Heavy mechanical propulsion failure, clear midrange turbine whine.

shd_hit_absorb | 0.65 s | 226
Incoming shot deflected by a starship electromagnetic forcefield: an immediate soft rounded energy thud with a brief clear resonant harmonic pulse rippling outward and fading gently. Clean, controlled, tonal energy deflection.

death_eclipse_shear | keep Antigravity's string

== MISSED BY THE 17 (same bass trap, phrase swaps) ==
wep_eclipse_gsentry: "paired with a compact deep hollow sub-bass drop" -> "paired with a compact hollow low-mid knock"
wep_ithar_startorp: "an instant deep booming sub-harmonic crystal impulse" -> "an immediate bright ringing crystal impulse with a firm low-mid push"
imp_glass_armor: "crushing seismic ice-and-crystal impact boom with deep resonant glacier stress-groans" -> "hard bright ice-and-crystal impact crack with a firm low-mid slab thud"; delete ", deep low end"
wep_chorus_spore_cloud: delete "subterranean"; "deep pressurized gas blowout thump" -> "hard pressurized gas blowout burst"; "deep and dense" -> "dry and dense"
wep_chorus_sporeb: "tight low-end air-pressure thump with a brief thick muffled dry crack" -> "tight air-pressure launch burst with a brief hard dry crack"
```

Also bass-stacked or risky and not on the list: `imp_obsidian_eclipse`, `imp_acid_on_metal`, `evt_pass_by_slug`, `evt_fleet_warp_in`, `death_ithar_shatter` and `death_hullbreaker_snap`. The last two open on "groan" before the break.

## 4. Credit math

- **Rate.** A2 requested 24.4 s and billed 272 credits, which is 11.15 per second.
- **A3 as written.** 6.6 s per take set, two takes, 13.2 s, about 147 credits. The "about 148" claim holds.
- **Cap.** The tool will estimate 528, so `--max-credits` must exceed that. The handoff text names neither the cap nor the fresh-folder dry-run check the plan requires.
- **My version.** 9 ids, 18 takes, 20.0 s, about 223 credits. The tool estimate is 800; set the cap to 900.

## 5. What the audit missed

- **The whole palette moved down three to four octaves.** Today's set has bright files (centroids 2.5 to 5.5 kHz). Eight of the nine keepers sit at centroids of 150 to 850 Hz. The score is low brass, cellos, basses and war drums in the same band. Masking is raised only for `imp_bio_flesh`.
- **Peak normalisation is the wrong loudness tool.** Keeper RMS spans -17.5 to -25.2 and crest factors differ widely. Match loudness per category, then set role levels in the cue table. Fade every tail by 10 to 20 ms.
- **Onset trim is never mentioned.** The plan requires it. Eleven of 20 takes have 10 to 32 ms of dead head, including eclipse t1 and both metal takes.
- **Infrasonic waste.** My shares do not sum to 100 on the laser, shard and bio takes. If the remainder is below the script's lowest band, it is infrasonic and eats headroom. Put a high-pass on the battle SFX bus.
- **Volley build-up.** Three staggered copies of a 97% low-end shot stack into mud. I cannot check the gaps or voice caps without `cues.json`.
- **Beam length.** Today's lance is effectively over by 0.34 to 0.47 s; the new one sustains 1.6 s. Nobody has checked the beam visual time. A short ignition, a looped body and a release assembled in Godot would fit any duration, though that is my suggestion, not something tested here.
- **Faction identity.**
  - Chorus has drifted to medieval siege gear and rock.
  - The three target impacts (bio, glass, obsidian) are all written as "monumental geological impact" and will converge, which defeats the point of substance cues.
  - nlance duplicates gauss.
- **Round-robin partner.** Small random pitch and volume on eclipse t1 in Godot costs nothing.
- **Shield break.** Today's works because it is several files with different jobs. One prompt is being asked to do all of them; layer it, or keep today's.
- **Plan conflict.** Syncing these prompts into the plan needs an explicit decision on the ban list. I would relax "sharp" and "loud"-type words, since everything is now dark. I would keep the literal-foley bans (bark, whip, sizzle, tearing, cough, groan, glass shatter).

## 6. Verdict

**Run Wave A3 with my edits; do not run it as written.** Antigravity's version would spend about 147 credits on prompts that break the plan's own ban list and change two variables at once.

**Next steps, in order**
1. Re-measure all 20 takes with one agreed script, per channel and mono-summed.
2. Master the nine keepers (trim, mono check, high-pass, tilt, loudness match, reward pitch) and audition them in engine against the battle music.
3. Run the free salvage and layer tests from section 1.
4. Read the beam visual durations and the volley gaps, and confirm the baseline file mapping.
5. Patch the manifest with the A3 block and twins, dry run into a fresh folder, then generate with `--max-credits 900`.
6. Ryan listens to mastered mono files and picks the Directorate recipe, the beam recipe and the influence.
7. Apply the Wave B block and the missed items, reconcile the ban list in the plan, then release Wave B.