# Gate 2 sound review for Ryan

Codex (audit): PR #1753, `72e6aa15c9ec5dab5de2900420619ca270aad9a1`. Runtime checked in the runner merge `f70645fbb`, with main at `475c54882`.

**Hold the 7,401-credit batch.** First fix the shots that fire several times per muzzle and the prompts that describe a different weapon from the one on screen. Then audition one take each. The proposed 57-file first listen covers the missing medium plasma battery, miss, impacts, shield hold, drive loss, Sunward magazine, Needle beam and two bridge controls for **5,357 estimated credits**.

**P** means `contrib/opus/plans/cohesive_audio_v2.md` and **J** means `contrib/opus/sound/elevenlabs_pilot_v2.json`. Numbers are lines at the reviewed revision. The evidence index gives full paths for the runtime citations. The eight findings are ranked in reading order. The full set of prompt edits follows the weapon roster. OBSERVED records a text, routing or cost mismatch. INFERRED records an audible risk that needs Ryan's ear.

## Timing and atomicity

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | **Blocking.** A baked volley plays once per muzzle | OBSERVED | J:29 | `five distinct crisp heavy kinetic discharges` | B:2305-2326 requests each ordinary gun cue at a fire time. Five admitted plays of a five-shot file can give 25 reports for five flashes. On a miss, the baked bomb at J:279 still lands. J:257 explicitly puts the Corona arc half a second late. | Make each source one audible event. Let the FX clock own the sequence, including the charge and pass-by. See P:32 and the single-shot replacements below. | High |

**1.** For heavy battery, replay one decoded attack at the five returned fire times at normal and fast battle speed. Count five aligned attacks, with a miss on the last one. For gauss, play the charge from the coil lead (F:578-590), end it at discharge, and play the cold crack at the muzzle. Reserve Doppler for a qualifying miss at the target plane, F:2625 `fx.shot_pass_by(pass_at, point)`. S:62 `cues["shot_pass_by"] = PASS_BY_CUE` overwrites JSON at startup. Replace the sample behind the existing layer or move that default behind a missing-cue check. An audible flight wake on a hit would need its own moving event. Gauss currently reaches the ordinary rail gun path via B:2167-2168 and B:2321. Give its visual coil lead a gauss-specific charge hook. Replacing the shared lance_charge sample at S:514-525 would also change unrelated lances.

B:2310-2316 sends all fire times only for the null lance. The other lances and torpedoes currently start at the first time, including a two-launch heavy rocket rack or two-pulse pulsar. Schedule those singles per actual release, charging before the first. Keep the fallback path at B:2338-2367 in step. For ordinary guns B:2321 passes a delay into S:282-298, which can defer or drop a close repeat. For flash-critical attacks schedule on the FX clock at due time, then admit or thin without moving the sound to a later flash. Trim silence on the decoded file and compare its first audible edge with the picture. A timing instruction in a prompt alone cannot prove sync.

**Proposed edits to the plan.** Replace the sentence or table-cell wording identified by each exact old anchor. In roster rows, keep the faction and rules-ID columns and use the routing table below for the sample column.

| File:line | Old text, exact anchor | New text |
|---|---|---|
| P:32 | “Every firing transient MUST ignite right at” | Use a trimmed, single discharge at the muzzle time. Schedule wind-up, launch, flight, contact or miss at their own FX times and world positions. Judge sync on the decoded asset against the flash. |

## Roster coverage and nuance

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 2 | **Blocking.** Several weapon identities disagree with the fleet | OBSERVED | J:175 | `a massive living bio-torpedo pod` | T:1 identifies sporeb as squadron ordnance. F:34-46 and F:121-131 distinguish plasma, sear, needle, junk and faction flak. B:2149-2171 and S:477-489 collapse many of these to one family. A different filename alone cannot fix that. | Use the 26-ID routing table below. Pass weapon ID and shooter faction through the normal and fallback fire paths. Keep broad family selection as a fallback for an unknown ID. | High |
| 3 | **Blocking.** The proposed material lookup erases the gun and reverses a hit | OBSERVED | J:316 | `Chorus corrosive bio-acid impact on hull` | A projectile hitting Chorus calls hit_wet, regardless of who fired it. S:563-576 checks target faction first. Making all metal hits hit_heavy would hide the distinctions that A:199-208 requires. A:25 and S:578-579 also distinguish a shield hold from a break. | Keep each existing metal weapon contact and its critical response. Use the struck hull for a material layer, with a distinct obsidian contact. Keep ordinary shield contact quiet. Add pilot samples for las, plasma and shield hold. | High |
| 4 | **High.** A damage state can repeat, and five death samples omit Sunward | OBSERVED | P:68 | `_eng_damage_tier` | H:2073-2089 can replace an old mark. H:2454-2487 reads and reconciles slots repeatedly. H:1716-1726 and H:2530-2534 already detect changes. P:69 lists five factions and J:354-381 has no drive-loss item. A loud death fracture on a live glass hull also spends the death cue early. | Tie sound to the first accepted opening, each newly disabled slot, worsening drive tier and newly offline generator. Add one drive and one Sunward magazine sample. Keep death on the fracture clock. | High |

**2.** The rules names in T:1, FX look in F:34-46 and faction overrides in F:121-131 answer different questions. Use all three. The detailed routes below give every rules weapon one pilot identity or an explicit shared fallback. A generator `cue` field is a label for the listening sheet. S:60-88 loads the game cue table and clip index independently.

**3.** K:265-270 returns metal, glass, bio or obsidian. S:564 `if HIT_BY_TARGET.has(target_fac):` takes precedence over the weapon fallback. Keep the tested metal las/plasma/rail/ion/shell choices. On a critical glass or living hit retain its material contact and the existing delayed matching heavy tail. For obsidian carry the victim into the variant lookup. The first play in S:572 currently supplies position only. Keep the weapon accent identifiable on either surface. An acid payload splashing metal belongs to a different event from any gun striking a living ship.

The normal shield route at B:2333-2336 is a quiet field contact. A shield break is a separate quadrant event, and the current S:578-579 helper has no victim argument. Pass the target/style into both breaking-cue paths (B:1535 and B:2573). Test an absorbed hit, a break without hull damage, and a break with hull damage. Only the last gets a hull contact. Compare the prismatic field sliding down continuously with the sharp contact of solid crystal. Retain current rail and ion contacts while auditioning las and plasma. UI clicks use the existing shared hook. A:349 and A:390 check a reward choice gets its own sound.

**4.** H:2087 `_marks.append(n2)` can describe the same opening again. Emit from the accepted cutout result, at its transformed centre, including a real surface-to-hole upgrade. An HP threshold, a raw hit or a redraw cannot tell whether an interior was actually exposed. Keep the legacy hull guard and a quiet surface contact for grazes (R:69).

H:2462-2466 reads off-slot IDs, engine hit and shield loss. H:2484-2499 knows the actual turret or fixed mount. H:2531 `if g != gen_down:` distinguishes burnout from a shield quadrant dropping. A temporary disabled slot can recover and fail again. Count one audible loss per transition, including when several turrets belong to that slot. Use a faction-safe drive loss on worsening tiers only. Keep alloy and servo samples on metal ships. For Chorus try elastic tension, for Glasswrights a short optical cutoff, for Eclipse a collapsing field. Use the neutral pilot where a separate material take is deferred.

E:3153-3169 schedules individual Sunward magazine flashes and rejects hidden hulls or missed surface anchors. A single local pulse can follow that accepted beat. D:30-52 and D:69-105 already separate hulk, small run, big bed, pre-split crack, actual split, core and wreck. Keep the -9 dB core dip for 0.6 s and -26 dB capital quiet for 0.35 s. Preserve the reduced-flashing core exception. Keep Chorus/Glasswright replacement variants across *all* death stages (A:191-198). A pre-split stress cue and a split boom must stay distinct even if a fracture finishes late.

**Proposed edits to the plan.** Replace the sentence or table-cell wording identified by each exact old anchor. In roster rows, keep the faction and rules-ID columns and use the routing table below for the sample column.

| File:line | Old text, exact anchor | New text |
|---|---|---|
| P:42 | “maps to a distinct sonic identity” | Resolve the weapon ID with the shooter faction and the existing FX look. Select an attack even where several weapons share a broad family. The table below lists Gate 2 samples and the shared sounds that still need a Gate 3 comparison. |
| P:44 | “ship-class” | Use FX weight 1, 2 or 3 from WEIGHT_BY_ID and the firing hull band small, cruiser or capital. Scale the low body, independently of the attack. The rules W table records shots, kind and damage. |
| P:49 | “rolling 5-gun capital flank salvos” | Sunward uses single sear repeater and turret pulses, one medium battery stroke, one heavier flank stroke, one solar lance, one Cinder ejection and one Spark flak shot. Derive rolling fire from the actual muzzle times. |
| P:50 | “regulated heavy twin turbolasers” | Directorate laser is the precision plasma cannon. Turbo is the fuller medium plasma battery and hturbo the heavy plasma battery. Match two, two and three flashes respectively. Ion holds a disrupted electrical beam. Picket lasers use a light pulse. |
| P:51 | “wep_sunward_torp_launch” | Hullbreakers use a ragged scatter, a short Rattle-rocket and a heavier Heavy rocket pod. Reuse kinetic sources for their autocannon, Junk turret and chaff only with identifiable changes in envelope and body. |
| P:52 | “pressurized boiling acid-glob heave” | Chorus spores disperses a cloud, bioplasma ejects a spine, tendril extends under tension and squadron sporeb releases an acid sac. Put contact at the target only on a hit. |
| P:53 | “shard” | Glasswrights distinguish a damped prism-shard stroke, a thin sustained Needle beam, a chordal pulsar, a radiant star release and a diffuse Mirror veil. |
| P:54 | “world-ending gravity-well Doom discharge” | Eclipse distinguishes Null spire, Null cannon charge and shot, one cut per Null lance fire time, a sustained electrical Corona arc, and diffuse Null shredder fire. Assign the miss cue only at a qualifying passage. |
| P:55 | “compact bomber ordnance strikes” | Small craft have a short light gun pulse or a heavier local payload release. Send the payload impact separately when it lands. |
| P:65 | “sfx.gun()” | Pass weapon ID, shooter faction and resolved weight/band into the audio dispatch for gun, beam, torpedo and squadron paths. Keep the existing family fallbacks. Match the on-screen fire list on the FX clock. |
| P:66 | “Expand `HIT_BY_TARGET`” | On bare metal retain las/lance, plasma, ion, rail or shell contact and existing heavy critical. On glass, tissue and obsidian preserve victim contact and blend a restrained weapon accent. Keep material-matched critical tails. Shield hold uses shield only for absorbed damage. Pass the victim's style to shield_break for the breaking quadrant. Allow hull contact only when hull damage also landed. |
| P:95 | “ui_click” | Pilot a dry console click and deliberate confirm on the existing UI hooks against the free switches. Keep reward claims on ui_reward. Use distinct laser and plasma contacts and a target-plane miss. Reuse existing cues for the other named fallbacks. |
| P:67 | “opening a new `K_HOLE`” | Emit a single decompression from the accepted cut in world space when a new opening exposes an interior, including an existing surface mark promoted to an opening. Ignore grazes, repeated reheats and mesh rebuilds. Dress its pressure sound by the struck hull. |
| P:68 | “shield_offline” | With Wounds V2 enabled, compare the applied state to the last presented state. Sound a newly off slot once at its turret or fixed mount, an increased eng_tier at the affected drive, and gen_down on its false-to-true edge at midship. Seed initial snapshots quietly. Clear on repair, death, revive and teardown. On glass use a short pane strain for live damage, leaving lethal fracture to the split sequence. |
| P:69 | “death_directorate_blackout” | Keep Directorate blackout on powerdown, Hullbreaker weld, Glasswright fracture and Eclipse slab on death_crack, Chorus rupture on the actual split. Add one Sunward magazine pulse at each accepted magazine flash. Preserve faction replacement, hulk-only vent, small death, bounded bed, core duck and capital quiet. Keep synthetic and sample fallbacks until their replacements have been heard. |

## Music and Gate 3 four-stem risk

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 5 | **High.** A synchronized silent part still gives a silent intensity change | INFERRED | J:482 | `develops at 0:30 into taut tactical drive` | The model may follow that entrance literally. At 0:10 a turn-one fight could have no percussion to bring up. Sync keeps clocks together. M:258-260 starts three existing players and M:382-384 changes their gains. G:275-278 submits a song file for separation without specifying these four orchestral groups. | Use four audible roles in every phrase and change harmony, register and motif voicing over time. Verify the actual separated files, then audition low and high intensity on the same beat. Keep the reward prototype a separate single-play piece. | High |

**5.** At the proposed 94 BPM a 90-second file is 141 beats, or 35.25 bars in 4/4. A requested duration alone cannot supply a downbeat seam. At 96 BPM, 36 complete bars occupy 90 seconds. Keep the groove available from bar one while the harmony travels and the motif changes voicing. Gate 2 auditions the stereo mix, with stems off. Gate 3 separates only an approved performance. G:275-278 sends the mix file and asks for a ZIP. It gives no contract that brass and pads will arrive as independent useful parts.

Before accepting Gate 3, solo drums, bass, motif and colour at 0:10, 0:40 and 1:10. Check each has its intended content, little bleed, the same downbeat, decoded sample length and loop boundaries. Switch low to high at 0:10 and high to low across the seam, then listen through two wraps. If the separator combines roles or returns an empty part, keep the approved stereo mix as a fallback and hold further stem purchases. M:289-305 uses proximity, recent hits, hull, flagship health, boss and surviving fleets. A breach counter would be a new input. Route all four through the existing music bus and duck. Match the current mute, sting and stop behavior.

For the reward, choose one short nonadaptive performance. Its motif should be recognizable even if the player leaves after a few seconds. Play once on reward entry after the victory fanfare, fade if the player leaves, and leave the claim acknowledgement on the button. U:133-142 currently dispatches map and title music. Reward playback needs a new entry hook if Ryan picks it. A:462-478 protects the single battle-ending fanfare and its fallback.

**Proposed edits to the plan.** Replace the sentence or table-cell wording identified by each exact old anchor. In roster rows, keep the faction and rules-ID columns and use the routing table below for the sample column.

| File:line | Old text, exact anchor | New text |
|---|---|---|
| P:70 | “one coherent 90 to 120 s track per faction” | For Gate 2 audition one 90-second battle mix and one separate 45-second reward piece. Gate 3 battle scores evolve over 90 to 120 seconds with percussion, bass, motif and colour active every phrase. Use AudioStreamSynchronized on one playback clock with matched starts, bar-aligned loops and per-part gain. Drive the mix from existing intensity inputs and route the group through music and its death duck. Treat breach and death event feeds as proposed additions. |

## Credit discipline and Godot wiring hazards

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 6 | **High.** The one-take alternative costs 5,113 on the submitted list | OBSERVED | P:97 | `~4,500 credits` | The dry planner counts each requested second, including the 20-second ambience and both scores. Duplicating all 44 short effects spends 2,288 credits before anyone can tell whether a prompt describes the right sound. | Set one take on the first sweep. Use the 244-credit gap list below and reserve second takes for disputed pairs or a failed read. Reprice prompt or duration changes before approval. | High |
| 7 | **High.** Three play calls change the mix and consume three logical voices | OBSERVED | J:284 | `salvo_tail (Layer C atomic post-shot mechanical breech and heat vent)` | S:24 caps active cues at 34. S:313-338 thins a salvo, queues an extra tail on its fourth admitted cue and steals by priority. S:340-393 gives layers separate players under one voice. C:2-34 already mixes body and attack. S:11,145-152 already supplies reverb. | Build layers within one accepted shot. Keep the old automatic tail as a group accent or use a per-shot faction return, with only one return at that beat. Compare a busy volley over a capital death and verify registration, audibility and onset separately. | High |

**6.** Offline generator dry runs at the submitted durations gave the following estimates. The original 44 short effects cost 2,288 for one take. Ambience costs 800, battle music 1,350, and reward music 675. Those last three already have one take.

| Purchase to compare | Files | Estimate | Saving against submitted batch |
|---|---:|---:|---:|
| Submitted 44 double takes plus ambience and music | 91 | 7,401 | 0 |
| Existing list with one take each | 47 | 5,113 | 2,288 |
| Recommended first listen, including ten missing cues | 57 | **5,357** | **2,044** |
| First listen plus all ten optional comparisons | 67 | 5,801 | 1,600 |

The optional 444-credit reserve covers one extra take each of heavy battery, medium and heavy Directorate plasma, spine and spore cloud, tendril, gauss fire, crystal, living armour and obsidian impact. Buy just the subset Ryan cannot identify blind or for which a good prompt produced an outlier. A wrong identity or a built-in second event needs a rewritten prompt first. G:80-90 numbers outputs by ID and take, and G:195 checks the saved file against its manifest row and byte count. Resume the same output folder for unchanged second takes so only take two is new. Give a rewritten prompt a new revision ID or output destination to avoid reusing the old result. Keep a spend cap tied to the approved subset. No stem fee is assumed here.

**7.** C:5-12 gives gun_shell six simultaneous logical voices, a 45 ms gap and a shared salvo group. S:319 `if sv.n == 4 and now - tail_t > 1.1:` already schedules a tail 60 ms later. Shared groups can count across ships. J:284 currently assigns the single global group accent to a per-shot metal return, which could put steel under a living salvo. Keep the accent independently gated and the return inside the appropriate shot. Use C:16-20's existing low body for a metal prototype, or omit a separate body if the approved take already contains it. The manifest offers no isolated body bank. Count both logical voices and actual player nodes under load. A three-layer cue creates three players even when it counts as one voice.

Weapons already get a wet mix of 0.22 x 0.9 and manual camera-distance gain (S:11,149,323-325). Leave generated shots dry. Listen through the real bus at normal distance for masking and an over-bright top. Retain longer tails for heavy hits, shield breaks and death. A:150 checks `listed.has(n)` for each new runtime cue, A:161-190 checks registered playable layers and variants, and A:223-225 and A:247-296 cover ducking and the fracture sequence. Import selected takes to supported audio assets and list their clip keys before exposing a cue. Clip replacements under existing cue IDs preserve the family registration. A:152-159 tests the picker on a synthetic four-take array. A green result cannot prove four real takes exist, a new cue fired at a muzzle, or that a new stem is audible. At production, exercise actual shots and routes, including a busy salvo over a late split. Keep the current fallback until all layer files are playable. For the 20-second bridge loop, S:605-630 has two playback paths. The baked bed has a 1-second loop offset, 121 beats and a random start over 119 seconds. Use the length-aware ambient clip path for this pilot and audition it with the bed, or derive offset, length and random start from the approved file before replacing the baked bed.

**Proposed edits to the plan.** Replace the sentence or table-cell wording identified by each exact old anchor. In roster rows, keep the faction and rules-ID columns and use the routing table below for the sample column.

| File:line | Old text, exact anchor | New text |
|---|---|---|
| P:36 | “2 takes per SFX” | Start all Gate 2 items at one take. Listen blind at equal gain, then buy one more only for a named uncertainty. Gate 3 starts frequently heard cues at four distinct takes with no consecutive repeat (rule 8.4). |
| P:85 | “47 items” | Current comparison is 47 items. Proposed first pass is 57 files, one per item, including ten short gap tests. No Gate 2 stems. |
| P:86 | “7,401 credits” | Original two-take estimate 7,401. Proposed 57-file first pass 5,357. Hold a maximum of 444 more for the ten listed comparisons, subject to the listening results. Recalculate from the final manifest. |
| P:97 | “~4,500 credits” | The submitted 47 one-take files cost 5,113. Compare the planned 57 at 5,357 with up to ten selective second takes at 5,801 total. |
| P:33 | “ship-class EQ” | Use dry clear attacks. Godot applies manual distance gain and short dark bus reverb. Set proposed class and caliber body gains per layer so pitch changes cannot blur the attack. |
| P:45 | “Faction-specific mechanical/energy recoil tail” | Attach an optional local return to the same logical cue with a layer delay. Use a metal return only for an appropriate mechanism. At a group accent choose between this return and salvo_tail. Keep body and tail below the onset. |
| P:98 | “voice-cap” | At Gate 3 trace accepted shots, scheduled attacks and audible starts during a dense volley, concurrent breach and late capital split. Register new runtime cue IDs, check layers resolve and faction replacements stay clean. Verify the existing duck, quiet, menu, and ending tests on the live route. |

## Prompting traps and scale drift

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 8 | **Medium.** Concrete props can overwhelm the scale in the first sentence | INFERRED | J:452 | `magnetic titanium latch release` | The Gate 1 diagnosis at P:13-21 describes a household lock, a kitchen-glass hit and frying sounds. Wet pops, bell/chime chains, sizzling, a transformer or a latch may recreate those results. A buried attack can also survive a request for a crisp one. J:442 asks for a reverberant brass drone beside orchestral music. | Describe the emitter, first transient, resonant mass and decay. Keep orbital context positive. Compare level-matched dry files and the actual bus mix before commissioning variations. | Medium |

**8.** At P:31 the maritime words are examples in the plan, outside the sent prompts. J:5 is metadata. The stronger remaining risks are indirect: propellant and rolling flank artillery can suggest historical ship guns. A bay clamp or vault latch can become a door, spines can become small clicks, and crystal chimes can sound decorative. A cavernous boss drone can merge with the score. Anchor the cause in magnetic, optical, living or structural spacecraft hardware. Keep pressure and mass in the low mids with an audible leading edge. Compare clean singles at equal loudness in shuffled order, then listen to a real volley with the bridge bed and music. Ryan should hear which weapon fired and whether the target held, broke or died without reading its name. Ryan's first listen supplies that evidence.

**Proposed edits to the plan.** Replace the sentence or table-cell wording identified by each exact old anchor. In roster rows, keep the faction and rules-ID columns and use the routing table below for the sample column.

| File:line | Old text, exact anchor | New text |
|---|---|---|
| P:34 | “substation transformer” | Describe the pressure, pitch range, material mass and envelope of one orbital emitter. Omit everyday objects, animal gestures, terrestrial scenery and negative object lists. Keep clear upper-mid definition with a short, smooth top. |

## Weapon roster checked against Godot

T:1 is a checksum-locked one-line JSON file. These are the 26 distinct keys in its decoded `tables.W`, with shared keys listed once. Counts come from `shots`. The faction pools and display names were checked separately. FX weights and hull bands come from F:43-46 and F:92-95.

| Rules IDs | Shots, in order | Fleet | Proposed sound and any shared fallback |
|---|---|---|---|
| battery / hbattery | 4 / 5 | Sunward | J:18 / 29. Medium compact stroke versus a lower, wider single heavy stroke. |
| turret / autocannon | 2 / 3 | Sunward and Hullbreakers (turret also Glasswrights) | Sunward J:40 / 51 as focused sear and shorter repeater. Hullbreakers use the ragged J:125 family, short rotary impulse for autocannon, heavier frame for Junk turret. Test distinct Hullbreaker sources at Gate 3. Glasswright turret gets the new Needle beam. |
| flak | 3 | Shared | J:82 is Spark flak. For Picket lasers use a short optical pulse, for Chaff guns a dry scrap pulse, Mirror veil a diffuse prism wash, Null shredder a thin magnetic grain. Identify these as shared pilot sources until each passes a blind comparison. Chorus spore cloud is keyed separately. |
| lance / torp | 1 / 1 | Sunward (torp also Hullbreakers) | J:61 steady thermal beam and J:71 ejection. Hullbreaker torp uses the J:135 rocket family with a shorter ragged impulse than htorp. |
| laser / turbo / hturbo / ion | 2 / 2 / 3 / 1 | Directorate | J:93 narrow plasma, new medium plasma battery, J:104 broad heavy plasma and J:114 interrupted ion beam. Judge the three plasma singles at equal loudness before hearing their cadence. |
| scatter / htorp | 5 / 2 | Hullbreakers | J:125 is one wide cluster at a muzzle. J:135 is one heavy rocket ignition per launch. |
| spores / bioplasma / tendril / sporeb | 3 / 2 / 2 / 2 | Chorus | J:155 cloud, J:145 spine, J:165 loaded extension, J:175 small acid-sac release. The last is craft ordnance. The boarding order retains its own grapple. |
| shard / pulsar / startorp | 3 / 2 / 1 | Glasswrights | J:185 simultaneous prism partials, J:195 sustained full chord, J:205 broad stellar release. The new Needle beam stays thinner than the pulsar and sustains longer than a shard. |
| gsentry / gauss / nlance / doom | 2 / 3 / 3 / 1 | Eclipse | J:216 short spire, J:226 separate charge and J:237 single rail stroke, J:247 one hollow cut, J:257 Corona arc. Keep the rare Doom weight in its duration and spectrum. |
| guns / bombs | 3 / 2 | Strike craft | J:268 light attack, J:279 one payload release. Dispatch each by ID before the generic squadron return. |

## Manifest edits for all 47 submitted items

Keep the existing ID as the lookup key for these edits. In each **New prompt** cell replace the entire old prompt. Rows marked **Keep** give the reason to retain the existing text. Take counts and cue labels have separate edits below. Each old anchor is exact. The risks behind the changes are ranked above.

### Weapon attacks, charge and recoil

| File:line and item | Old text, exact anchor | New prompt or keep decision |
|---|---|---|
| J:18 `wep_sunward_battery` | “brief pressurized thermal vent decay” | One spacecraft mass-driver discharge. The magnetic edge and a short, dense midrange impulse begin together on frame one. Dry cutoff. |
| J:29 `wep_sunward_hbattery_salvo` | “five distinct crisp heavy kinetic discharges” | One capital flank emitter fires. Immediate wide, low-register magnetic stroke with a hard leading edge and a short resonant decay. Single discharge. |
| J:40 `wep_sunward_turret_twin` | “two crisp synchronized heavy electromagnetic-kinetic blasts” | One sear-turret pulse starts fully formed, focused and narrow, with a sustained band of hot harmonics and a dry cutoff. |
| J:51 `wep_sunward_autocannon` | “three fast hammering mechanical-kinetic thuds” | One light sear-repeater pulse. Immediate thin-band electrical bite over a firm midrange core. Shorter and tighter than the turret pulse. |
| J:61 `wep_sunward_lance_beam` | “fierce directional heat-radiation hiss” | One solar lance opens at full energy on frame one. A dense low-mid furnace tone sustains under a clear edge until the beam cuts. |
| J:71 `wep_sunward_torp_launch` | “immediately catching at 0.3 seconds” | A single massive Cinder torpedo leaves its emitter on the first sample. One broad electromagnetic thrust pulse with a dry falling resonance. |
| J:82 `wep_flak_airburst` | “rapid three-shell proximity detonation burst” | One short Spark flak muzzle stroke, a bright compressed edge over a small low-mid impulse, close and dry. |
| J:93 `wep_directorate_laser` | “instantaneous razor-sharp focused optical crack” | One precision plasma cannon discharges instantly. Narrow bright electrical edge over a compact, clean ionized midrange pulse. Dry fast decay. |
| J:104 `wep_directorate_hturbo` | “two deep authoritative supercharged plasma-bolt blasts” | One heavy regulated plasma emitter fires immediately. A broad saturated low-mid core holds under a clean electric edge, then cuts short. |
| J:114 `wep_directorate_ion_beam` | “snapping immediately into a sustained crackling blue-arc EMP beam” | Keep. Immediate onset into the same continuous beam. Compare its interrupted electrical texture against the steady Sunward thermal tone. |
| J:125 `wep_hullbreaker_scatter` | “shrapnel-shotgun blast” | One uneven, wide-band discharge from a spacecraft scrap accelerator. Ragged simultaneous high partials over a short blunt frame resonance. |
| J:135 `wep_hullbreaker_rockets` | “two mismatched unguided heavy warheads” | One heavy salvage rocket ignites on the first sample. Uneven bands of combustion noise over a short, rough low-mid impulse. Local emitter only. |
| J:145 `wep_chorus_spines` | “three fast dry chitinous snapping tendon clicks” | One massive living spine battery releases. Immediate hard asymmetric chitin impulse with a pitched low structural resonance and a short fibrous decay. |
| J:155 `wep_chorus_bioplasma` | “boiling corrosive bile” | A single spore-cloud discharge from a living orbital hull, immediate dense unpitched pressure front spreading into fine granular midrange noise, short dry release. |
| J:165 `wep_chorus_tendril` | “whipping across vacuum and crushing into heavy spacecraft armor” | A sixty-metre tendon array extends under load. Immediate taut low-register fibre impulse with a short descending resonance, heard at the living hull. |
| J:175 `wep_chorus_sporeb` | “wet cartilaginous valve pop” | One acid sac releases from a small alien strike craft. An immediate compact elastic pressure pulse, low-mid and slightly unstable, ending cleanly at the craft. |
| J:185 `wep_ithar_shard` | “three razor-sharp resonant cut-crystal harmonic snaps” | One prism-shard emitter fires. Three close harmonic partials sound together at onset and decay as one brief dense optical stroke. |
| J:195 `wep_ithar_pulsar` | “piercing luminous resonant chord” | One optical lance pulse starts at full strength. Stable quartz partials sustain as a smooth chord over a deep fundamental, then stop together. |
| J:205 `wep_ithar_startorp` | “receding smoothly across space” | One stellar containment field releases at the emitter. Immediate radiant low chord with a broad corona of soft upper harmonics, short local decay. |
| J:216 `wep_eclipse_gsentry` | “two razor-sharp dry magnetic snap-cracks” | One Null spire pulse, immediate and narrow. A short pair of simultaneous inharmonic tones loses power sharply, leaving silence. |
| J:226 `wep_eclipse_gauss_charge` | “substation transformer sub-groan” | Deep stepped magnetic harmonics increase in density along one capital accelerator coil. End cleanly at peak field strength. Charge only. |
| J:237 `wep_eclipse_gauss_fire` | “followed by a brief razor-sharp Doppler hypersonic plasma-wake streak” | One hypervelocity rail discharge at the emitter. Immediate broad magnetic crack underpinned by a short, cold resonant impulse, then silence. |
| J:247 `wep_eclipse_nlance` | “hollow deep sub-bass abyssal hum punctuated by three” | One null-lance cut. A hard cold edge and hollow fundamental begin together, hold for one brief beam, then stop abruptly. |
| J:257 `wep_eclipse_doom` | “half-second terrifying gravitational vacuum suck-in” | A capital Corona arc strikes at full strength on frame one. Dense branching electrical texture around a deep continuous field tone with a dry cutoff. |
| J:268 `wep_craft_guns` | “five tight crisp light metallic kinetic pops” | One compact interceptor shot starts immediately, dry narrow midrange impulse, light low end and very short decay. |
| J:279 `wep_craft_bombs` | “followed by two compact punchy armor-piercing warhead concussive thumps” | One bomber payload separates on frame one. Compact heavy electromagnetic impulse and a short resonant fall at the pylon. |
| J:290 `wep_mech_recoil_tail` | “dense steel breech lock seating solidly” | One capital recoil carriage returns under load. A short low steel-frame resonance with a damped hydraulic finish. Isolated mechanical return. |

### Contacts, shields, damage and first death beats

| File:line and item | Old text, exact anchor | New prompt or keep decision |
|---|---|---|
| J:301 `imp_metal_heavy` | “brief flying alloy shrapnel ricochet ping” | Single heavy contact at onset. Dense low-mid shock travels through metres of armoured frame and decays from the same strike point. |
| J:311 `imp_glass_armor` | “dense cascades of thick heavy crystal slabs shearing apart” | One blow on intact ten-metre crystal armour. Immediate deep plate fundamental with two uneven high partials damping inside the same slab. |
| J:321 `imp_bio_acid` | “corrosive chemical boiling roar” | A single contact on the thick ribbed carapace of a living spacecraft. Immediate dense elastic flex with a brief low, fibrous resonance. |
| J:331 `imp_obsidian_eclipse` | “instantaneous cold brittle monolithic basalt slab crack” | Keep. Dry low stone resonance is distinct from the sustained crystal partials. Use it as target contact, including on a noncritical hit. |
| J:341 `shd_break_energy` | “downward cascading harmonic force-field pitch drop” | Keep. The continuous falling field marks a break. Reserve its long low end for the quadrant that fails. |
| J:351 `shd_break_prismatic` | “cascading shimmering refraction chimes” | One prismatic field drops. A continuous descending fan of optical harmonics cuts to silence over a deep field pulse. Smooth spectral fall. |
| J:361 `dmg_breach_open` | “violent heavy alloy-frame shear” | One opening into a pressurized spacecraft compartment. A broad immediate pressure differential falls into a short thinning band of airflow at the opening. |
| J:371 `dmg_turret_knockout` | “sharp hydraulic servo motor grinding to a violent mechanical lock clunk” | One powered alloy turret loses drive. Its loaded midrange actuator tone cuts off unevenly with a single dry electrical discontinuity. |
| J:381 `dmg_shield_burnout` | “controllable damage bed” | One failing shield emitter loses its carrier. A brief irregular field pulse fractures into thin electrical noise and stops. |
| J:391 `death_directorate_blackout` | “massive main power-relay breaker slam” | An entire orbital power grid drops together. Its dense layered reactor harmonics fall steeply from the first instant into silence. |
| J:402 `death_hullbreaker_snap` | “giant structural tension cables breaking with heavy echoing iron vibration” | One load-bearing weld lets go on a capital scrap hull. A broad low frame resonance breaks sharply at onset and dies in the adjoining plate. |

### Remaining deaths, interface, ambience and music

| File:line and item | Old text, exact anchor | New prompt or keep decision |
|---|---|---|
| J:412 `death_chorus_rupture` | “deep visceral sub-bass organ rupture” | A vast pressurized carapace separates. Load-bearing chitin gives one deep uneven impulse, followed by a low fibrous decay across the living hull. |
| J:422 `death_ithar_shatter` | “fast racing cascades of sharp thick crystal stress-cracks” | Keep for lethal fracture only. The corresponding contact at J:311 has one damped resonance. |
| J:432 `death_eclipse_shear` | “massive dry basalt-stone slabs grinding and shearing cleanly apart” | Keep for the Eclipse death crack. Its prolonged sliding stone layer distinguishes it from a single cold impact. |
| J:442 `ui_boss_arrival` | “cavernous low-brass war-drone swelling smoothly” | Flagship threat registered. Two immediate, low detuned field tones converge into one grave electronic interval, then stop cleanly. |
| J:452 `ui_reward_vault` | “magnetic titanium latch release” | Salvage accepted on an orbital command console. A firm dry electrical onset resolves into a warm, restrained two-note acknowledgement. |
| J:462 `evt_fleet_warp_in` | “brief clean decaying plasma-drive rumble” | Keep. Listen to staggered arrivals at equal gain for cumulative low end. |
| J:473 `amb_bridge_bed` | “no distinct repeating bangs or creaks” | A continuous, quiet tactical spacecraft interior. Steady low reactor partials under smooth filtered life-support airflow. Uniform texture and level across the loop point. |
| J:482 `mus_battle_sunward_proto` | “develops at 0:30 into taut tactical drive” | Dark Sunward tactical score. 96 BPM, 4/4, D minor, 36 bars. From bar one every phrase carries a measured percussion pulse, bowed low ostinato, four-note weathered brass motif and sustained orbital field texture. Keep each in its own register. Revoice the motif and move the harmony through three twelve-bar phrases. End on a pickup into bar one at matching pulse and level. Instrumental. |
| J:491 `mus_reward_proto` | “before fading gently on an open fifth” | Quiet single-play salvage underscore. 64 BPM, 4/4, D Dorian, twelve bars. State the four-note motif on cello in bar one. Answer it twice with warmer horn voicings over moving bass. Resolve on open D and A with a short natural release inside the final bar. Instrumental. |

### Cue labels and take fields

Rename these pilot IDs before the first purchase so the listening sheet and saved filenames identify the revised sounds. The prompt table uses the submitted names to locate each edit. Keep the new IDs for unchanged second takes.

| File:line | Old ID | New ID |
|---|---|---|
| J:21 | `wep_sunward_hbattery_salvo` | `wep_sunward_hbattery_single` |
| J:74 | `wep_flak_airburst` | `wep_sunward_flak_muzzle` |
| J:138 | `wep_chorus_spines` | `wep_chorus_bioplasma_spine` |
| J:148 | `wep_chorus_bioplasma` | `wep_chorus_spores_cloud` |
| J:314 | `imp_bio_acid` | `imp_chorus_carapace` |

At J:5 replace the note that promises “all 26 weapons” and “all faction death beats” with “Gate 2 calibration. The routing table covers 26 weapon IDs. Some faction variants retain a named fallback. Gate 2 auditions one take per item and two stereo prototypes. Gate 3 selects production takes and verifies stems.” The generator records a cue label in its receipt. A label alone cannot select the runtime sound.

| J line | Old cue, exact anchor | New cue label |
|---|---|---|
| J:12 | “gun_shell (Sunward battery, 4-shot cruiser flank kinetic” | gun_shell, Sunward battery single |
| J:23 | “gun_shell (Sunward hbattery, 5-shot capital rolling flank” | Sunward hbattery, one heavy muzzle stroke |
| J:34 | “gun_shell (twin armored turret kinetic double-tap)” | Sunward turret, one sear pulse |
| J:45 | “gun_tracer (autocannon, rapid 3-round rotary kinetic burst)” | Sunward autocannon, one light sear-repeater pulse |
| J:66 | “torp_heavy (Sunward heavy forged-iron space torpedo)” | Sunward torp, local ejection only |
| J:76 | “gun_flak (proximity space flak barrage)” | Sunward flak, local muzzle only |
| J:87 | “gun_las (Directorate crisp precision laser pulse)” | Directorate laser, precision plasma cannon |
| J:98 | “gun_plasma (Directorate turbo and hturbo heavy turbolaser” | Directorate hturbo, one heavy plasma bolt |
| J:119 | “gun_shell (Hullbreaker scatter, 5-shot ragged scrap-shrapnel blast)” | Hullbreaker scatter, one emitter discharge |
| J:130 | “torp_rocket (Hullbreaker htorp twin salvage rocket rack” | Hullbreaker htorp, one heavy rocket ignition |
| J:140 | “gun_spine (Chorus spores rapid chitinous spine volley)” | Chorus bioplasma, one spine emission |
| J:150 | “gun_glob (Chorus bioplasma corrosive acid glob launch)” | Chorus spores, one spore-cloud emission |
| J:160 | “board_grapple (Chorus tendril colossal bio-whip strike)” | Chorus tendril weapon, extension only |
| J:170 | “torp_sac (Chorus sporeb living bio-sac torpedo launch)” | Chorus sporeb, squadron acid-sac release |
| J:180 | “gun_needle (Glasswright shard and prism turret optical” | Glasswright shard, prism-shard emitter |
| J:190 | “lance_choir (Glasswright pulsar harmonic choir-lance beam)” | Glasswright pulsar, one beam pulse |
| J:200 | “torp_star (Glasswright startorp radiant star-torpedo release)” | Glasswright startorp, local release only |
| J:210 | “gun_rail (Eclipse gsentry cold automated gauss defense)” | Eclipse gsentry, one Null spire pulse |
| J:221 | “lance_charge (Eclipse gauss beat 1: magnetic accelerator” | Eclipse gauss, FX coil lead only |
| J:231 | “gun_rail (Eclipse gauss beat 2+3: hypervelocity crack” | Eclipse gauss, single muzzle discharge |
| J:242 | “lance_dark (Eclipse nlance triple-pulse void beam)” | Eclipse nlance, one null cut |
| J:252 | “lance_dark (Eclipse flagship Doom Cannon superweapon)” | Eclipse doom, Corona arc at emitter |
| J:262 | “gun_sq (strike craft interceptor rapid strafing burst)” | Strike craft guns, single interceptor shot |
| J:273 | “torp (strike craft bomber ordnance drop and” | Strike craft bombs, single payload separation |
| J:284 | “salvo_tail (Layer C atomic post-shot mechanical breech” | Optional metal return inside a weapon cue |
| J:316 | “hit_wet (Chorus corrosive bio-acid impact on hull)” | hit_wet, blow on living target armour |
| J:326 | “hit_heavy (deathless variant: impact on Eclipse obsidian” | Obsidian contact on Eclipse, any hull hit |
| J:336 | “shield_break (veil, hex, and patchy energy shield” | shield_break, ordinary field collapse |
| J:346 | “shield_break (ithar variant: prismatic optical barrier shatter)” | shield_break, target prismatic variant |
| J:356 | “new R416 cue: mid-battle armor cutout breach” | Accepted breach, material-neutral pressure layer |
| J:366 | “new R416 cue: exact disabled weapon-slot turret” | Newly disabled metal slot at turret or fixed mount |
| J:376 | “new R416 cue: midship shield-generator burnout and” | Generator newly offline, bounded emitter fault |
| J:478 | “battle music prototype (Sunward multi-section tactical score)” | Sunward evolving battle loop, stereo audition |
| J:487 | “reward screen music prototype (dying-sun salvage cadence)” | Reward entry, separate single-play underscore |

On each of these 44 J lines replace `"takes": 2` with `"takes": 1` for the first listen: 17, 28, 39, 50, 60, 70, 81, 92, 103, 113, 124, 134, 144, 154, 164, 174, 184, 194, 204, 215, 225, 236, 246, 256, 267, 278, 289, 300, 310, 320, 330, 340, 350, 360, 370, 380, 390, 401, 411, 421, 431, 441, 451, 461. Keep J:472, 481 and 490 at one. Keep J:470's loop setting for the ambience if confirmed at the decoded loop seam.

### Ten additions for the recommended first listen

J:492 closes the reward item. Old boundary at J:492-493 is `}` followed by `]`. Add a comma after that last item and append these objects before the array closes. Each row specifies the fields `id`, `seconds`, `group`, `cue` and `prompt`. Set `kind` to `sfx` and `takes` to 1 throughout. Use the manifest's v3 default for field, tonal and organic cues. For the two console transients and the magazine pulse set `model` to `eleven_text_to_sound_v2`. These are proposed pilot IDs.

| New ID | Seconds | Group | Cue / trigger | Prompt |
|---|---|---|---|---|
| `wep_directorate_turbo` | 0.7 | `weapon_directorate` | turbo fire (medium plasma) | One orbital plasma battery emits a rounded, dense midrange pulse from frame one. A slow oscillation closes into a dry cutoff. |
| `wep_ithar_needle` | 0.5 | `weapon_ithar` | ithar turret fire | Single narrow optical beam. A clear sustained harmonic filament starts immediately above a quiet low fundamental and cuts squarely. |
| `miss_transit` | 0.5 | `weapon_shared` | shot_pass_by | A brief orbital projectile crossing at closest approach. The pitch is already high at onset, glides down once and dies dry. |
| `imp_las` | 0.5 | `impact` | hit_las | Single focused thermal contact on spacecraft armour. A narrow bright onset heats a small area and damps immediately into the plate. |
| `imp_plasma` | 0.7 | `impact` | hit_plasma | One ionized mass strikes spacecraft armour at onset. Broad hot midrange splash with a short turbulent decay inside the plate. |
| `shd_hold` | 0.6 | `shield` | shield | A local force field takes one impulse. Quiet rounded elastic field tone dips briefly and returns to its original pitch. |
| `dmg_drive_loss` | 0.8 | `r416_damage` | drive tier increases | One orbital propulsion field drops a harmonic at full load. Wavering low-mid thrust stabilizes at a reduced level in one short pulse. |
| `death_sunward_magazine` | 0.8 | `death_beat` | Sunward magazine flash | One isolated internal magazine pressure pulse in an armoured orbital hull. Deep short frame shock with a small incandescent upper edge. |
| `ui_bridge_click` | 0.5 | `ui_event` | ui_click | One dry low-level electronic contact on a tactical spacecraft console, an immediate short filtered impulse with a firm centre. |
| `ui_bridge_confirm` | 0.5 | `ui_event` | ui_confirm | One brief two-pitch electronic acknowledgement from a tactical spacecraft console. The second pitch settles slightly lower. Quiet and dry. |

## Evidence index

Offline checks matched the 47 prompt decisions to their source lines and all 26 weapon IDs and shot counts to the decoded rules. Reconstructing the proposed list from the edit tables produced 57 unique items. The generator dry run priced them at 5,357 credits and sent nothing.

The standing suite finished with 109 passes, two known-baseline results and four failures outside the two reviewed files. The picture-provenance fixture called `save_jpg` with two arguments where Godot requires four, including on an isolated rerun. The runner fixture failed its missing-effort report assertion, the export fixture could not find its expected log, and the Stage 5 sheet-paint fixture failed its success case.

The two PR files were read end to end from the local raw checkout. For large supporting files the table lists the inspected line ranges. The last column is the first 40 characters of the final physical line, or the whole line if shorter, in JSON string notation so tabs and empty lines survive Markdown rendering.

| Ref | Raw repository file | Lines | Read ranges | Last line prefix |
|---|---|---|---|---|
| P | `contrib/opus/plans/cohesive_audio_v2.md` | 98 | 1-98 | `` "6. **Godot wiring (`sfx.gd`, `death_audi" `` |
| J | `contrib/opus/sound/elevenlabs_pilot_v2.json` | 494 | 1-494 | `"}"` |
| T | `godot/rules/data/tables.json` | 1 | 1 (decoded W, FAC_WNAMES, FAC_WPOOL, HULLS) | `"{\"sha256\":\"5afc47785c4854e6ebcdd616e7c21"` |
| F | `godot/fx/fx_weapons.gd` | 2693 | 16-46, 79-95, 121-137, 142-172, 430-607, 2613-2634 | `""` |
| B | `godot/scenes/battle/battle.gd` | 7036 | 1535, 2148-2171, 2228-2244, 2297-2367, 2478-2490, 2573-2582 | `"\tget_tree().quit(code)"` |
| S | `godot/audio/sfx.gd` | 631 | 1-110, 112-202, 225-261, 269-398, 416-434, 477-535, 538-579, 603-631 | `"\tcreate_tween().tween_property(_amb, \"vo"` |
| C | `godot/audio/cues.json` | 2669 | 2-36, 237-269, 294-326, 424-455, 704-771, 1438-1463, 1942-1968 | `"}"` |
| D | `godot/audio/death_audio.gd` | 112 | 1-112 | `"\t\tsfx.death_beat(false)"` |
| M | `godot/music/music_player.gd` | 414 | 1-84, 99-136, 172-183, 207-228, 237-305, 312-352, 375-414 | `"\t\t\"bed_db\": _bed.volume_db, \"single\": _s"` |
| A | `godot/audio/test/audio_check.gd` | 520 | 16-36, 107-129, 139-227, 229-306, 340-349, 387-400, 462-478 | `"\t\tawait process_frame"` |
| H | `godot/fx/fx_ship.gd` | 2854 | 1715-1728, 2028-2044, 2047-2100, 2426-2466, 2469-2546 | `"\t\t_dmg_request(fx)"` |
| G | `contrib/opus/tools/sound/elevenlabs_gen.js` | 335 | 13-24, 31-53, 70-94, 179-196, 219-235, 248-250, 260-278 | `"module.exports = { plan, args };"` |
| R | `.claude/rules/godot-battle.md` | 142 | 69, 123-142 | `"R37). Set: Ryan (R37, R40). Ids: R37b, R"` |
| K | `godot/fx/fx_hull.gd` | 1917 | 264-270 | `"\t\t\t\t(lb[\"node\"] as Node3D).transform = ("` |
| E | `godot/fx/fx_death.gd` | 4246 | 2334, 3151-3172 | `"\t\tnd.global_position -= back"` |
| U | `godot/main/campaign_host.gd` | 455 | 118-143 | `"\trun_over.emit({\"result\": \"win\" if won e"` |

**One recommended next step.** Revise the two source files using these edits, dry-run the resulting manifest, then give Ryan the priced first-listen sheet before authorizing generation.

Not checked: Gate 1 clips were not re-auditioned. Their reported sound comes from Ryan's documented observations. Gate 2 audio, stem separation, real account charges, loop seams and in-game playback of the proposed assets have no listening evidence in this review. No service was contacted and no key was read.
