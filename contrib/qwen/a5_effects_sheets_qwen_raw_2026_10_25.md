# Raw return: A5 effects sheets, Qwen, Oct 25, 2026

Source: fresh Qwen chat (chat.qwen.ai/c/3ecd5563-75dc-42f5-b4c3-8ef2624493f0, titled "Voidsworn Weapon Effects Sheets"), Qwen3.8-Max with two-gate verification (selector before submit, header after generation), Thinking ON, Web search ON. Ran Oct 25, 2026, 2:50-3:00 PM CDT (runtime-measured). The evidence pack could not be attached to the chat (no file input element exposed), so repo-specific values are tagged UNSURE in the sheet. Filed verbatim below; the working copy is reviews/a5_effects_sheets_qwen_2026_10_25.md.

## Voidsworn A5 Effects Pass: Per-Weapon Effects Sheets (Job A)

Status: research deliverable, engine-neutral. Written so either candidate engine (Godot 4.7 or Babylon 9.30, decision pending per the evidence pack, UNSURE on final call) can build from it. All implementation terms are generic: emitters, decals, lights, particles, meshes, shaders, ribbons, audio cues.

### 0. How to read this sheet

Source discipline:
- Repo facts come only from the authoritative brief in the task prompt. The evidence pack (job_a_evidence.md) exists but could not be attached, so anything that lives only inside it is tagged UNSURE. That includes: specific faction names and colour values from the faction colour table, the exact wording of the R16 bar and R3 shield-colour rule beyond what the brief states, the K2 A5 item list, and which specific feel values the batch 7 legs disputed.
- No file:line citations are invented anywhere in this document.
- Web sources are used only for external comparable games and effects technique, and are cited with links in section 12. (Note: sources actually appear in section 13; the sheet's internal cross-reference says 12.)
- Every numeric feel or timing value is a screen-tuned guess expressed as a RANGE, never a single number. Batch 7 disagreed on some feel values; since the pack cannot be read here, contested status is marked UNSURE on each appendix entry and all of them need screen tuning on real hardware before lock.

Key rules carried through every sheet:
- The R16 bar (Ryan): damage reads as holes with streaming parts, fire, and other damage states, not orange lines. Weapon effects and engine trails must feel more realistic and cinematic, up to the standard of BattleTech, Sins of a Solar Empire, and Warhammer 40,000: Rogue Trader. Comparable-game reference points: a community visual overhaul for BattleTech exists specifically because players wanted richer laser colours, PPC and gauss effects, and muzzle flashes (https://www.nexusmods.com/mechwarrioronline/mods/63); Rogue Trader shipped patch-level VFX work so blasters and dark lances fire visible beams from the barrel (https://roguetrader.owlcat.games/news/en/45) and later reworked torpedo destruction effects for readability (https://www.rpgsite.net/news/18770-warhammer-40000-rogue-trader-update-1-5-full-patch-notes-gameplay-trailer); Sins of a Solar Empire II shipped discrete impact-effect sets per weapon class, including point defence autocannon impacts and medium torpedo impacts (https://www.stardock.com/news/522357/spheres-of-influence-update---sins-of-a-solar-empire-ii). A common failure mode to avoid is the one players describe in X4: tiny spark hits and single-puff deaths that do not read at battle distance (https://steamcommunity.com/workshop/filedetails/?l=dutch&id=3711529445).
- Shields keep faction colours (R3 rule as stated in the brief). Shield impact colour always comes from the defending ship's faction entry in the faction colour table. Specific colour values: UNSURE (table unreadable here). Never guess hex values; this sheet describes colour roles only.
- Accessibility: hard cap of at most 3 flashes per second anywhere on screen, plus a reduce-flashing option. Applied per effect in section 11. Basis: WCAG 2.3.2 (do not flash content more than 3 times a second) (https://www.w3.org/WAI/WCAG22/Understanding/three-flashes.html), the international photosensitive epilepsy guidelines (https://pmc.ncbi.nlm.nih.gov/articles/PMC11872230/), Xbox Accessibility Guideline 118 on photosensitivity testing (https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/118), and the Game Accessibility Guidelines flicker item (https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/).

Conventions used below:
- Weight tiers: each weapon kind is assumed to come in light, medium, and heavy weights (data.js holds the truth; exact tier names UNSURE). Impact response scales with weapon weight and with target hull size.
- Ripple timing: the stagger between individual shots within one salvo or burst, as distinct from the fire rate between salvos.
- Colour roles: "faction accent" means the faction's primary energy colour role; "faction secondary" means its support colour role. Values come from the faction colour table, UNSURE here.
- Flash counting rule: one flash = one brightness transition pair (dark to bright to dark) on a given emitter. All counts below are per second at peak salvo density.

### 1. BATTERY (kinetic gun line, shell-firing naval guns)

Role: the workhorse projectile weapon. Tracer shells with visible ballistic travel, the closest thing to real naval gunnery.

1.1 Fire
- Wind-up: brief barrel recoil settle and a charge glow at the breech for medium and heavy weights. Range 0.05 to 0.15 s. Light weight: no wind-up, instant shot.
- Muzzle effect: layered, not a single sprite. Three parts: (a) a short additive flash at the muzzle (1 flash per shot, duration 0.05 to 0.12 s), (b) a forward cone of smoke and gas particles that drift and thin over 0.4 to 1.0 s, (c) 2 to 6 small ember sparks thrown forward and to the sides. Add a momentary point light at the muzzle for 0.05 to 0.15 s so nearby hull plating lights up. This layered muzzle treatment is what "BattleTech feel" mods specifically add (https://www.nexusmods.com/mechwarrioronline/mods/63).
- Projectile count per salvo: light 1 shell; medium 2 to 3 shells; heavy 3 to 5 shells fired as a tight ripple.
- Ripple timing: 0.06 to 0.12 s between shells inside one salvo. Salvo-to-salvo cadence is a balance value, not effects-owned; UNSURE.
- Recoil: the gun mesh or turret nudges backward 0.5 to 2 percent of turret length and returns over 0.1 to 0.25 s. Screen shake on the firing ship's own camera only if the player ship fires: light 0, medium very small, heavy small. Amplitude and decay are screen-tuned guesses, ranges in appendix.

1.2 Travel
- Projectile: glowing tracer shell with a slight hot core and cooler outer tint. Not a thin line; a short tapered bolt with a visible head, roughly 1 to 3 ship-metres long depending on weight (scale guess, UNSURE, needs screen check at battle zoom).
- Speed: fast but trackable. Light faster than heavy so weight reads differently. Relative speeds: light 1.0, medium 0.8 to 0.9, heavy 0.6 to 0.8 of the light baseline (baseline itself is a balance value; UNSURE).
- Trail: thin smoke wisp plus a short fading light trail behind the tracer. Trail lifetime 0.1 to 0.3 s. At long range the tracer should stay visible against black space; boost tracer emissive with distance rather than thickening geometry. EVE's module visual-cue guide is a good model for making each weapon family instantly recognisable in flight (https://wiki.eveuniversity.org/Visual_effects).

1.3 Impact
On shields (shield colour always the defender's faction colour, values UNSURE):
- Flash: single small bloom at the hit point, 0.08 to 0.2 s, in faction shield colour. 1 flash per shell.
- Ripple: a ring pulse spreading from the hit point across the shield surface over 0.15 to 0.4 s. Technique: mask a radial pulse with the shield's hex or panel grid texture and add it to surface alpha, the standard approach documented in the Rift Core shield VFX breakdown (https://straypixels.net/riftcore-shield-fx/) and force-field shader tutorials (https://unitycodemonkey.com/video.php?v=6AKR4b4C5jo).
- Particles: 4 to 12 short-lived sparks that ricochet tangentially off the shield surface, plus a faint smoke puff. No debris on shields.
- Decal stage: none on shields (shields are energy, they leave no mark).
On hull, by weapon weight:
- Light: small spark burst (6 to 15 sparks, 0.15 to 0.4 s), tiny grey scorch decal (diameter roughly 0.5 to 1.5 m on a cruiser-scale hull, guess), no structural damage read.
- Medium: brighter flash (0.1 to 0.25 s), spark burst plus 2 to 5 small debris chips tumbling away with slight drift, scorch decal with a shallow dent normal-map ring. Advances the damage ladder one small step toward "dented" on repeated hits.
- Heavy: strong impact flash (0.15 to 0.3 s, counts as 1 flash), directional debris spray of 5 to 12 fragments plus a dust plume, a short fire lick at the hit point (0.3 to 0.8 s) if the hit crosses into the fire-damage band, and a scorched-plus-dented decal with exposed-metal highlights. Heavy battery hits are the first tier where the R16 bar applies directly: the result should read as a punched hole with torn edges and streaming bits, not a painted orange streak. Procedural scorch materials with layered noise are the recommended technique for these decals (https://realtimevfx.com/t/scorch-marks-whats-your-process/1157).
- Damage-state streaming: on any hit that crosses a ladder threshold, spawn 1 to 3 small streaming parts (loose panel shards, a snapping cable whip, a venting gas jet) that detach and drift. Streaming parts live 2 to 6 s or until off-screen.

1.4 Sound cue (words only)
- Fire: deep mechanical thump with a metallic crack on top; heavier weights get a lower, longer boom and more chamber-reverb tail. Light reads as a sharp knock.
- Travel: none for the player's own shots; a faint distant whoosh only if the salvo passes very close to camera.
- Shield impact: dull thud filtered through a resonant hum, pitch rising slightly with weapon weight.
- Hull impact: crunch of tearing metal plus a short debris rattle; heavy hits add a low structural groan.

1.5 Faction differences
- Shell tracer core stays neutral hot white for all factions so friend-foe identification never depends on tracer colour at distance.
- Muzzle flash takes a slight tint from the firing ship's faction accent (values UNSURE): the tint lives in the outer glow, not the white-hot core.
- Smoke density and colour temperature vary by faction role: one faction role runs dirty and heavy on smoke (chemical-propellant flavour), one runs clean and short (coil-assisted flavour), one runs a faint accent-coloured vapour (exotic-propellant flavour). Which faction gets which role: UNSURE, faction colour table unreadable here.
- Shield impacts always use the defender's faction shield colour per the R3 rule (values UNSURE).

### 2. FLAK (point-defence burst gun, proximity-fuzed shells)

Role: anti-strike-craft and anti-torp screening fire. Reads as puffs and airbursts, never as clean tracer lines.

2.1 Fire
- Wind-up: none. Flak should feel panicky and immediate.
- Muzzle effect: small, fast, dirty. A tiny flash (duration 0.03 to 0.08 s) with a soot puff. Because flak fires in long bursts, keep each individual muzzle flash small and dim so the burst as a whole stays under the flash cap; see section 11.
- Projectile count: burst of 4 to 10 shells per trigger pull, fired at 0.04 to 0.1 s ripple. Heavy flak mounts throw 3 to 6 shell bursts of larger shells at a slower ripple (0.08 to 0.15 s).
- Visual grouping: flak barrels visibly lead the target; add a faint aiming cone gizmo only in player-controlled manual mode (design question, UNSURE).

2.2 Travel
- Projectile: dim tracer with a heavy smoke trail. Flak tracers should be less bright than battery tracers so the burst cloud, not the streak, is the signature.
- Speed: fastest projectile in the game (point defence). Relative speed roughly 1.2 to 1.5 times battery light (guess, UNSURE).
- Trail: thick-ish sooty trail, lifetime 0.15 to 0.35 s, slight gravity-free drift and wobble so bursts look like a stream of fire, matching real flak behaviour. Real-world airburst behaviour and the FLAK naming are documented in the airburst round literature (https://en.wikipedia.org/wiki/Airburst_round).

2.3 Impact
Flak mostly does not impact; it airbursts.
- Airburst (the primary read): spherical burst 0.2 to 0.5 s, made of a quick bright core pop (1 flash, 0.05 to 0.12 s), an expanding ring of 8 to 20 shrapnel sparks, and a smoke ball that hangs and dissipates over 2 to 6 s. Flight sims are a good persistence reference: DCS players note real bursts hung around 7 s or more while the sim showed about 3 s (https://forum.dcs.world/topic/262457-effects-flak-burst-dissipation-time/), and IL-2 communities report single bursts fading over 10 to 12 s (https://forum.il2-series.com/topic/4384-flak-clouds-disappear-much-too-quickly/). For a tactics game, keep smoke balls at the short end (2 to 4 s) so the battlefield does not fill with fog, but let them overlap into a visible screening cloud.
- Fuse timing: proximity burst when within 1 to 4 m of a strike craft or torp (guess, UNSURE); backup time fuse 1.0 to 2.5 s after firing. Helldivers 2's RL-77 flak mode is a useful comparable for proximity-fuse plus lifetime-fuse behaviour (about 0.2 s proximity delay, 1.5 s lifetime fuse) (https://helldivers.wiki.gg/wiki/RL-77_Airburst_Rocket_Launcher).
- Impact on shields (rare, direct hits): tiny faction-coloured bloom, 0.05 to 0.12 s, no ripple ring. Flak should read as harmless to shields.
- Impact on hull: light only. Small spark tick, 3 to 8 sparks, pinhole scorch decal. Flak never advances the damage ladder past "scorched" by itself.
- Kill confirmation: when a burst destroys a strike craft or torp, add one secondary fireball (0.3 to 0.8 s) with 3 to 8 debris chunks. Torp destruction effects specifically needed a readability pass in Rogue Trader, so make this read clearly (https://www.rpgsite.net/news/18770-warhammer-40000-rogue-trader-update-1-5-full-patch-notes-gameplay-trailer).

2.4 Sound cue
- Fire: rapid mechanical chugging, higher pitch and looser rattle than battery; heavy flak is a slower, harder hammering.
- Airburst: sharp crack with a papery tear, smoke hiss underneath. Bursts at distance become soft thumps.
- Kill: short whoomph plus debris tinkling.

2.5 Faction differences
- Burst core colour stays neutral white-yellow for readability of the screen-fire role.
- Smoke tint takes the faction secondary colour at very low saturation (values UNSURE), so each faction's flak cloud has a faint identity: one sooty grey-black, one faintly tinted warm, one faintly tinted cool.
- Shield blooms use defender faction colour per R3 (values UNSURE).

### 3. LANCE (sustained beam weapon)

Role: continuous cutting beam. The cinematic centrepiece weapon. The R16 bar matters most here: the damage must read as a widening molten cut with streaming debris and fire, never as an orange line painted on the hull.

3.1 Fire
- Wind-up: charge phase 0.3 to 0.8 s for medium and heavy lances. During charge: a growing light at the emitter lens, a rising hum audio cue, lens flare petals closing inward, and a faint heat shimmer. Light lances: 0.05 to 0.15 s snap-charge.
- Muzzle effect: no muzzle flash in the gun sense; instead an emitter bloom (steady glow while firing, not a repeating flash, so it does not count against the flash budget) plus a heat-haze distortion cone.
- Beam count: 1 beam per lance mount. Heavy lance = one thick beam, not several thin ones, so weight reads as thickness and brightness.
- Ripple timing: not applicable (continuous). Instead define a beam "breathing" flicker: slow amplitude modulation over 0.3 to 0.8 s cycles, deliberately slower than 3 Hz; see section 11.

3.2 Travel
- Beam: instantaneous hitscan read with a visible core-plus-glow structure: a thin white-hot core inside a wider coloured glow shell, plus rolling internal noise scrolling along the beam length at moderate speed so the beam feels like flowing energy, not a static line. Rogue Trader's 1.3 pass making blasters and dark lances emit proper visible beams from the barrel is the comparable standard (https://roguetrader.owlcat.games/news/en/45).
- Speed: hitscan or near-hitscan (a very fast projectile at 5 to 10 times battery speed can be used instead of true hitscan for dodge-readability reasons; design choice, UNSURE).
- Trail: the beam is its own trail. Add drifting motes shedding off the beam and a faint volumetric light shaft along its length. Beam impact point sprays continuous sparks while cutting.

3.3 Impact
On shields (defender faction colour, values UNSURE):
- Flash: no repeating flash. A single brighter bloom when the beam first touches (1 flash, 0.1 to 0.25 s), then a sustained contact glow.
- Ripple: continuous slow rings pushing outward from the contact point, one ring every 0.4 to 1.0 s (well under the flash cap), masked by the shield grid texture per the standard hex-grid pulse technique (https://straypixels.net/riftcore-shield-fx/).
- Particles: sustained spray of 10 to 30 concurrent sparks splashing tangentially off the contact point, plus shield-coloured energy wisps.
- Decal stage: none.
On hull (the R16 showcase):
- Contact point: molten white-hot spot with a dark red cooling ring, continuous spark and droplet spray (molten metal droplets, 15 to 40 concurrent), small smoke plume.
- The cut: as the beam tracks, it leaves a widening molten trench. Technique: a scrolling decal strip or shader-driven trail on the hull surface with emissive edges that cool from white to orange to dark char over 1.5 to 4 s. This is a damage state, not a weapon line; it must connect visually to the damage ladder (section 9), transitioning into "exposed structure" and then "hull breach" as DPS accumulates.
- Streaming parts: while cutting, spawn 1 to 4 streaming elements per second of sustained fire at the contact area: sparking cables, venting gas jets, peeling panel strips that flutter free. On crossing to hull breach, add fire plumes (fire VFX layering guidance: base flame, secondary licks, ember particles, smoke column (https://www.vfxapprentice.com/blog/everything-know-about-fire-fx)).
- By weapon weight: light lance = thin cut, small spark spray, scorched-to-dented progression only. Medium = visible trench, intermittent fire licks, dented-to-exposed-structure progression. Heavy = wide trench, continuous fire, debris chunks spalling off the far side of the cut, exposed-structure-to-breach progression, and a low-frequency hull groan audio bed.

3.4 Sound cue
- Charge: rising capacitor whine with a sub-bass swell.
- Sustained beam: loud electrical roar with a sawing undertone, plus a continuous sizzling crackle layer for the cutting contact. Heavy lances add a deep hull-resonance drone.
- Shield contact: the sizzle layer becomes a bubbly resonant hum.
- Beam end: quick power-down chirp, steam-like hiss from the cooling trench.

3.5 Faction differences
- Beam colour: the beam glow shell takes the firing faction's accent colour role; the white-hot core stays white for all factions so beam direction and danger read at distance. Specific colours UNSURE.
- One faction role gets a clean surgical beam (narrow, steady, minimal smoke), one gets a rough overcharged beam (wider flicker, more sparks and debris spall), one gets an exotic beam (faint secondary-coloured outer sheath and unusual hum). Mapping to actual factions UNSURE.
- Shield impacts use defender faction colour per R3 (values UNSURE).

### 4. TORP (torpedo, slow heavy guided ordnance)

Role: the dread weapon. Slow, visible, threatening, and the biggest single-hit payoff in the game.

4.1 Fire
- Wind-up: tube door open and flood/vent sequence, 0.4 to 1.2 s. Visible: tube glow, a puff of venting gas at the tube mouth, small warning light cycling on the mount (slow cycle, 1 flash per second or slower).
- Muzzle effect: cold-launch feel. A blunt gas shove: expanding vapour ring plus a short burst of particulate wash, no bright flash. Torp launch should be quiet-bright compared to guns: dim flash (0.1 to 0.2 s), lots of gas.
- Projectile count per salvo: 1 to 4 depending on mount weight. Ripple timing 0.3 to 0.8 s between tubes, wide enough that each torpedo is individually trackable.
- Launch kick: the firing ship shows a tiny counter-thrust shudder (0.05 to 0.15 s), heavy torps only.

4.2 Travel
- Projectile: full mesh torpedo with visible body, nose, and engine nozzle glow. Not a sprite. It should be readable as a physical object a player can point flak at.
- Speed: slowest projectile in the game, roughly 0.15 to 0.3 of battery light speed (guess, UNSURE), with a short boost phase after launch (0.3 to 0.8 s of acceleration).
- Trail: the signature. A long persistent engine plume ribbon, lifetime 3 to 8 s so torpedo tracks lace the battlefield, plus intermittent vapour puffs at steering moments so course changes read. Heavy torps get a thicker, brighter plume than light ones. The plume should use the torpedo's own engine-trail style from section 8 (tied to the firing ship's faction), which is how players learn to attribute incoming torps to a faction at a glance.
- Audio: a low warbling drive tone that dopplers as it passes, plus a proximity warning tick when it nears any ship (tick rate must stay under the flash and audio-spam caps; see section 11).

4.3 Impact
On shields (defender faction colour, values UNSURE):
- Flash: the largest single shield flash in the game, 1 flash, duration 0.2 to 0.5 s, with a full-surface shield brightness surge and 2 to 4 expanding ripple rings over 0.5 to 1.2 s.
- Particles: heavy splash of 30 to 80 shield-coloured sparks and a shockwave distortion ring in screen space.
- If the torpedo is intercepted or destroyed short of the shield: secondary airburst fireball, 0.5 to 1.2 s, with 4 to 10 debris chunks. Sins II treats torpedo impacts as a named VFX category of their own, which matches the priority here (https://www.stardock.com/news/522357/spheres-of-influence-update---sins-of-a-solar-empire-ii).
On hull, by weapon weight:
- All torp weights are heavy events. Light torp = the floor: big flash (0.2 to 0.4 s), fireball 0.8 to 1.5 s, debris spray of 8 to 20 chunks plus panel strips, immediate jump to at least "dented," usually straight to "exposed structure" or "hull breach" on small ships.
- Medium torp: fireball 1.2 to 2.5 s, two-stage explosion (initial blast then a secondary sympathetic pop 0.2 to 0.5 s later), debris 15 to 35 chunks including 2 to 5 large streaming hulks that tumble away trailing smoke, hull breach decal with glowing interior visible through the hole.
- Heavy torp: fireball 2.0 to 4.0 s with an expanding shockwave ring, ember rain, 25 to 50 debris pieces, guaranteed hull-breach-stage crater with interior structure mesh visible, fire plumes anchored in the crater lasting 3 to 10 s, and a brief camera shake even at distance. This is the R16 centrepiece: a hole with torn, glowing edges, streaming cables and atmosphere jets, and real fire, never a flat orange streak.
- Damage-state persistence: torp craters keep a fire-and-smoke loop until repaired or until the ship dies; they are the primary carriers of the "hull breach" ladder stage (section 9).

4.4 Sound cue
- Launch: heavy clunk, gas hiss, tube resonance.
- Travel: throbbing low drive tone with a warble, dopplering; proximity tick near ships.
- Shield impact: massive boom wrapped in a shield resonance sweep that bends pitch downward.
- Hull impact: crunch, then blast, then a rolling debris rattle tail; heavy torps add a deep ship-groan and a muted pressure-pop for the breach.
- Interception: short crack and tinkle of碎片 (debris bells).

4.5 Faction differences
- Torpedo body mesh silhouette differs per faction role (stubby, long and slim, or organic-curved) so factions read at distance without colour. Actual faction mapping UNSURE.
- Drive plume colour follows the launching faction's engine-trail role from section 8 (values UNSURE).
- Warhead flash core stays neutral white-yellow for all factions; faction tint lives in the outer fireball edge.
- Shield impacts use defender faction colour per R3 (values UNSURE).

### 5. BIO (biological weapon, living ordnance)

Role: the weird one. Organic projectiles, acid-spit impacts, infestation damage states. Must feel alive without breaking readability against conventional weapons.

5.1 Fire
- Wind-up: a swelling, peristaltic pulse along the launcher organism, 0.2 to 0.6 s, with a wet stretching sound. The launcher "inhales" visibly (mesh scale pulse or shader bulge).
- Muzzle effect: no flash. A wet expulsion: spray of viscous droplets, a stretching mucus strand that snaps, and a faint vapour. Replace the point light used by guns with a brief subsurface glow at the orifice.
- Projectile count: light bio spits 1 to 3 blobs per volley; heavy bio launches 1 large organism. Ripple timing 0.1 to 0.3 s, irregular on purpose (add 20 to 40 percent random jitter so it never feels mechanical; jitter range is a screen-tuned guess).

5.2 Travel
- Projectile: living blob with wobble deformation, trailing filaments, and a faint internal pulse (pulse rate 1 to 2 per second, slow, within the flash cap as brightness modulation not full flash). Large bio organism: mesh with undulating motion and small limb or frond movement.
- Speed: slow to medium, roughly 0.4 to 0.7 of battery light (guess, UNSURE). Heavy organism is slower (0.25 to 0.4).
- Trail: dripping particulate trail of small droplets that shrink and vanish, lifetime 0.3 to 0.8 s, plus a faint spore haze. No hard-edged ribbon; bio trails should look soft and discontinuous, the opposite of torp plumes, so the two never confuse.

5.3 Impact
On shields (defender faction colour, values UNSURE):
- Flash: dull bloom, 0.1 to 0.2 s, lower brightness than kinetic impacts of the same weight. Shields should visibly "repel" bio: the blob splats, sizzles, and slides off.
- Ripple: single soft ring, 0.2 to 0.5 s.
- Particles: splat of 10 to 25 viscous droplets that arc and fade, plus a brief discoloured smear on the shield surface that fades over 0.5 to 1.5 s (shield-coloured base with a sickly secondary tint; tint values UNSURE).
- Decal: none.
On hull, by weapon weight:
- Light: acid splat, hissing sizzle, a spreading corrosion decal (etch pattern, matte, no glow) growing over 0.5 to 1.5 s then static. Advances ladder toward "scorched" but with a corrosion skin variant instead of a burn variant (the damage ladder gets a bio-flavoured decal family; see section 9).
- Medium: splat plus 0.3 to 0.8 s of smoke, 5 to 12 dripping debris bits (viscous, not metallic), corrosion-pit decal reaching "dented" equivalent. Small tendrils visibly anchor into the pit and retract over 1 to 3 s: the ship was briefly infected and fought it off.
- Heavy organism: impact thud, the organism bursts into a clinging mass that crawls and dissolves the hull over 0.8 to 2.0 s, spewing acid sprays and 8 to 20 organic debris chunks, leaving a "hull breach" stage hole with organic growth fringing the edges and slow dripping. Growth fringe persists 4 to 10 s then chars and sloughs off. This gives bio its own lane on the ladder: breaches look infested rather than blasted.

5.4 Sound cue
- Fire: wet stretch-snap, pressurised expulsion, organic chirp underneath.
- Travel: faint pulsing squelch for the heavy organism only.
- Shield impact: thick splat with an electric sizzle.
- Hull impact: hiss of acid on metal, bubbling, and for heavy impacts a short organic shriek cut off by the crunch.

5.5 Faction differences
- Bio is assumed to belong primarily to one faction role, but any faction fielding bio weapons uses the same behaviour family with palette swaps: the organism body and blob take the firing faction's secondary colour role; the acid glow takes the accent role (values UNSURE).
- The faction that "owns" bio most should get the richest variants (extra tendrils, louder shriek); which faction: UNSURE.
- Shield impacts use defender faction colour per R3 (values UNSURE).

### 6. GAUSS (mass-driver slug, hyper-velocity kinetic)

Role: the railgun sniper. Long wind-up, near-invisible flight, devastating single hit. The contrast weapon: quiet travel, loud arrival.

6.1 Fire
- Wind-up: the longest in the game, 0.5 to 1.5 s. Visible charge sequence: capacitor banks along the barrel light in sequence from breech to muzzle (each segment a small step-glow, sequenced not flashing), magnetic shimmer along the rail, a growing whine, and a targeting laser-thin alignment line that appears in the last 20 to 30 percent of the charge (optional, design call UNSURE).
- Muzzle effect: violent and brief. A single hard flash (1 flash, 0.05 to 0.12 s), a shockwave distortion ring at the muzzle, forward ionisation streak, and a recoil shove visibly larger than any battery: the whole mount or ship nose dips for 0.1 to 0.3 s. Muzzle point light bright enough to silhouette nearby geometry. Community BattleTech overhauls treat the gauss rifle effect as its own signature category, distinct from lasers and PPCs (https://www.nexusmods.com/mechwarrioronline/mods/63).
- Projectile count: always 1 slug per shot. No ripple. The wind-up IS the ripple.
- Heavy gauss: wind-up 1.0 to 2.0 s, and the charge hum is felt as a subtle screen-edge vignette pulse (very slow, 0.5 to 1 Hz, within caps).

6.2 Travel
- Projectile: near-invisible. A thin hypervelocity streak, essentially a momentary line of ionised glare with a tiny bright head. Lifetime of the visible streak 0.05 to 0.15 s. Deliberately hard to see: the counterplay is dodging during the wind-up, not during flight.
- Speed: fastest thing in the game, roughly 2 to 4 times battery light speed, effectively instant at typical engagement ranges (ratio is a guess, UNSURE).
- Trail: a very thin wake that lingers 0.2 to 0.5 s and dissipates from the back forward, plus a faint sonic-boom-style distortion ring at the muzzle that expands and fades over 0.3 to 0.6 s.
- Sins II community discussion treats beam, gauss, and rail as distinct feel categories, which supports giving gauss its own hyper-fast kinetic identity separate from lance energy reads (https://steamcommunity.com/app/1575940/discussions/0/4038104598696926116/).

6.3 Impact
On shields (defender faction colour, values UNSURE):
- Flash: sharp single bloom, 0.1 to 0.25 s, with a distinctive puncture read: the ripple rings are tight and fast (2 to 3 rings in 0.2 to 0.5 s) as if the shield was pierced rather than splashed.
- Particles: narrow forward-and-back spray of 15 to 40 sparks, plus a brief shield-coloured afterglow hole that closes over 0.3 to 0.8 s.
- Decal: none.
On hull, by weapon weight (gauss is all about penetration, the R16 bar at its purest):
- Light gauss: clean punched hole. Entry decal small and neat on the near face; the exit side (if the slug overpenetrates, a design rule, UNSURE) gets a larger blown-out crater with 6 to 15 debris fragments streaming out the far side plus internal fire flicker visible through the hole for 1 to 3 s.
- Medium: through-and-through penetration with a visible interior light pass (a momentary glow traveling through the ship's interior volume), 12 to 30 debris chunks, streaming atmosphere jet from both holes lasting 2 to 6 s, and ladder jump to at least "exposed structure."
- Heavy: structural event. Flash 0.15 to 0.3 s, entry crater with peeled-back plating, guaranteed "hull breach," 20 to 45 debris pieces including 3 to 6 large streaming hull sections, interior fires ignited along the slug path (2 to 5 fire plumes over 0.5 to 1.5 s), heavy camera shake on nearby views, and a 1 to 3 s structural groan. Against small ships a heavy gauss hit can directly trigger the wreck sequence (section 10).
- Signature detail: gauss holes glow from residual heat, cooling white to red to black over 2 to 5 s, and the debris fragments leave brief hot contrails. Procedural layered scorch and char materials recommended (https://realtimevfx.com/t/scorch-marks-whats-your-process/1157).

6.4 Sound cue
- Charge: rising electromagnetic whine with layered capacitor clicks, ending in a tense silence beat of 0.05 to 0.15 s before the shot (the silence sells the power).
- Fire: thunderclap crack, sharper and dryer than any battery.
- Travel: a zip or tear sound that passes through the stereo field; distant gauss shots arrive as a delayed crack.
- Shield impact: high-pitched puncture ping under a heavy thud.
- Hull impact: metallic ring-through, like a bell struck inside the ship, over the crunch; heavy adds the groan.

6.5 Faction differences
- Charge-sequence colour follows the firing faction's accent role (capacitor segment glows, values UNSURE).
- Slug wake tint: neutral white core for all; a faction-role variation adds a faint accent sheath on heavy gauss only, so faction identity never compromises the "hard to see, impossible to ignore" flight read.
- Impact fire colour is neutral (fire is fire); faction identity lives in the decal trim glow colour of the hot hole edges (values UNSURE).
- Shield impacts use defender faction colour per R3 (values UNSURE).

### 7. SQ (strike craft, launched small craft)

Role: not a direct-fire weapon. SQ launches living (or crewed) aircraft that then fight with their own small weapons. The effects job is launch, in-flight presence, and dogfight-scale weapon fire that must not pollute the fleet-scale readability.

7.1 Fire (launch)
- Wind-up: bay doors open 0.4 to 1.0 s with interior lights visible, catapult charge glow, deck-crew-style activity lights (slow pulse, 1 per second or slower).
- Launch effect: short catapuff of vapour plus a small thruster flare per craft as it clears the bay. Craft leave in a stream, 1 to 4 per bay cycle.
- Ripple timing: 0.2 to 0.5 s between individual craft launches; squadrons of 4 to 12 craft total per launch event (squadron size is a balance value, UNSURE).
- Count discipline: at fleet scale, cap concurrent visible craft effects (emitters per craft reduced at distance via LOD rules; distance thresholds are screen-tuned guesses, UNSURE).

7.2 Travel
- Craft presence: each strike craft has a tiny persistent engine glow (section 8 style, faction-matched, miniature) and no trail ribbon at fleet zoom; at close zoom it gets a short 0.2 to 0.5 s vapour trail.
- Speed: fast relative to ships, slow relative to projectiles. They should read as insects around whales.
- Formation: craft fly loose formations with 1 to 3 m separation jitter; formation coherence is a feel value, UNSURE and batch-7-adjacent, screen-tune.

7.3 Craft weapons (mini-scale, derived from the parent kinds)
- Craft guns: miniature battery tracers, 60 to 80 percent brightness of ship-scale tracers, no decals at fleet zoom, small spark impacts on hulls.
- Craft torps (if the squadron type carries them, UNSURE): miniature torp with a thin plume, impact scaled to light torp minus one step.
- Impact on shields: tiny faction-coloured pinpricks (0.05 to 0.1 s), no ripple rings below heavy craft ordnance.
- Impact on hull: spark ticks and pinhole scorch only; squadrons advance the ladder by accumulation, never by single hits.

7.4 Craft death (important, happens often)
- Each craft death: one small fireball 0.3 to 0.7 s, 3 to 8 debris sparks, a brief smoke wisp 0.5 to 1.5 s. One flash per death. If many die in the same second, the flash budget system (section 11) throttles to keep the total under cap by dimming and merging concurrent fireballs.
- EVE's Viridian update explicitly reworked missile and impact VFX for gameplay readability, a good precedent for keeping small-craft deaths readable but budgeted (https://www.facebook.com/eveonline/videos/eve-online-new-missile-impact-vfx/153546001025191/).

7.5 Sound cue
- Launch: bay door rumble, catapult thump per craft, tiny engine flare chirps.
- Presence: at close zoom only, a mosquito swarm buzz bed whose density tracks craft count.
- Craft death: small pop with a metallic tinkle; distant deaths drop to soft ticks.

7.6 Faction differences
- Craft silhouette differs per faction role (angular, insectile, or sleek), the primary faction read at distance.
- Miniature engine glow and craft-gun tracer sheath take the faction accent and secondary roles (values UNSURE), matching the parent ship's engine trail family from section 8.
- Shield pinpricks use defender faction colour per R3 (values UNSURE).

### 8. Engine trails per faction

Ryan called out engine trails specifically as too basic; the bar is realistic and cinematic plumes, comparable to Sins-era capital ship exhaust reads.
Physics grounding for realism: real nozzle exhaust plumes expand, develop shock-cell structure (the diamond pattern of over-expanded nozzles), and glow from hot species, all documented in the classic shuttle-era plume flowfield literature (https://ntrs.nasa.gov/api/citations/19750008553/downloads/19750008553.pdf). In atmosphere-free space the plume is a broadening cone, not a tube. Kerbal Space Program's developer insights on exhaust VFX are the best practical write-up of common trail pitfalls, notably particle spawn tick-rate causing disconnected spottiness at high speed (https://forum.kerbalspaceprogram.com/topic/204884-developer-insights-11-%E2%80%93-engine-exhaust-visual-effects/page/4/); fix by spawning along the swept segment or using a stretched ribbon.
Structure every faction trail with the same four layers, then vary shape, behaviour, and colour role:
1. Nozzle glow: emissive disc or cone at the nozzle mouth, steady (not flashing), brightness scales with throttle.
2. Core plume: bright inner cone, roughly 1 to 3 nozzle diameters wide, length scaling with ship mass and throttle (2 to 10 ship-lengths, screen-tuned guess).
3. Outer plume and haze: wider, dimmer, softer cone with rolling noise, giving the cinematic volumetric look. Add faint shock-diamond banding for the "realistic" faction roles.
4. Wake: a long, very faint lingering ribbon or particle wake, lifetime 1 to 4 s, so fleet movements leave readable tracks. This is also what torps borrow (section 4.2).
Per-faction behaviour archetypes (assign actual factions from the faction colour table; assignment and colour values UNSURE):
- Faction archetype A, "industrial burn": long, dirty, slightly sooty plume with heavy outer haze and visible shock diamonds; warm accent colour role at the core edge; loud low rumble audio.
- Faction archetype B, "clean ion": short, tight, intensely bright core with almost no haze; cool accent role; near-silent hum with a high overtone; wake is thin and glows briefly then vanishes.
- Faction archetype C, "exotic drive": pulsing plume (slow pulse, 0.5 to 1.5 Hz, within caps) with drifting mote shedding and a secondary-colour sheath; the wake shimmers; audio is a warbling drone.
- If the faction table has more than three factions, extend by mixing archetype parameters; faction count UNSURE.
Shared rules:
- Engine brightness is a throttle and damage signal: damaged ships (ladder stage 3 and beyond) get sputtering, asymmetric, smokier trails with intermittent misfire coughs (slow, capped flicker, see section 11).
- Trails use the defender-neutral rule in reverse of weapons: engines are always the OWNER's faction colour role, since they identify your ships at a glance.
- Strike craft use miniature single-layer versions of their parent faction trail.
- No faction trail may strobe faster than the 3 flashes per second cap under any damage state.

### 9. Staged damage ladder

Five stages per the brief: scorched, dented, exposed structure, hull breach, wreck. Each stage is a persistent state on the ship, expressed through layered decals, meshes, emitters, and audio beds. This is where the R16 bar lives: every stage reads as physical damage with streaming parts and fire, never as flat orange paint.
Stage rules (thresholds are balance values, UNSURE; the ranges below are the effects-side durations and densities, all screen-tuned guesses):

1. Scorched
- Visual: dark procedural scorch decals over impact zones, soot streaking running "downhill" along hull panels; paint blistering texture variation. No glow, or only faint residual warmth on the newest scorch (emissive fading over 2 to 5 s).
- Streaming parts: none or at most 1 wispy smoke trail per major hit zone, lifetime 3 to 8 s, looping while stage persists.
- Audio: occasional faint ticking of cooling metal, every 2 to 6 s.
- Engine effect: none yet.
- Technique note: procedural scorch materials layered in the shader are the recommended approach over baked textures (https://realtimevfx.com/t/scorch-marks-whats-your-process/1157).

2. Dented
- Visual: add dent normal-map decals and bent panel mesh swaps on edges; plate seams split with thin dark gaps; scorch coverage grows to roughly 1.5 to 2 times stage 1 area.
- Streaming parts: 1 to 3 per damage zone: a loose panel strip fluttering on one attachment point, sparking wire bursts every 1 to 3 s (each spark burst counts as sub-flash flicker, throttled per section 11), thin steam or gas jets.
- Audio: sporadic metallic creaks and pops every 3 to 8 s.
- Engine effect: trails gain slight asymmetry if engine zones are near damage.

3. Exposed structure
- Visual: hull plating gone in patches, revealing an interior structure layer (girder mesh, conduit runs, dull machinery volumes) with scorching on the exposed frame. This requires an interior structure representation per ship; asset cost noted, method UNSURE.
- Streaming parts: 3 to 6 per zone: hanging cables swinging and sparking, slower gas vents with visible vapour, small debris still shedding occasionally (1 piece every 2 to 5 s).
- Fire: the first persistent fire stage. 1 to 3 small fire plumes per zone using layered fire technique (flame core, licks, embers, smoke) (https://www.vfxapprentice.com/blog/everything-know-about-fire-fx), each plume anchored to a structural point, flickering slowly (fire flicker is amplitude noise, not full on-off flashes; see section 11).
- Audio: continuous low fire roar bed plus intermittent sparks and groans.
- Engine effect: one or more engine nozzles visibly sputter; plume length drops to 60 to 80 percent and gains smoke.

4. Hull breach
- Visual: actual holes. Breach decals become breach geometry: open craters with peeled, glowing-edged plating, visible interior volume with fire and machinery inside, and atmosphere jets (white vapour cones) streaming from the hole along the local normal, bending slightly with ship rotation.
- Streaming parts: heavy. 4 to 8 per breach: atmosphere jets (looping, 3 to 15 s or permanent while stage holds), debris pouring out in bursts every 1 to 4 s, large torn panel pieces tumbling away with smoke trails, whipping cables.
- Fire: 2 to 6 plumes, some venting out of the breach into space (flame tongues that stretch and thin in the jet).
- Audio: pressure hiss bed, deep intermittent structural groans every 2 to 6 s, fire roar up one level.
- Engine effect: trails unstable, brightness oscillating slowly (0.5 to 1.5 Hz), intermittent misfire puffs; one engine may cut to a stub plume.
- Ship death warning: at the low-hull end of this stage, add a klaxon-light pulse on the hull (slow, 1 per second or slower) and an audio alarm layer, telegraphing the wreck.

5. Wreck (ship disabled but not yet gone, or the terminal state before removal depending on design; treatment UNSURE)
- Visual: the ship stops fighting. All weapons dark. Multiple breaches, listing rotation if the game allows slow tumble, heavy interior glow through every hole.
- Streaming parts: maximum density: continuous debris shedding, 4 to 10 fire plumes, atmosphere jets everywhere, occasional internal secondary explosions (one every 1 to 3 s, each a small fireball 0.3 to 0.8 s, counted against the flash budget).
- Audio: groaning hull bed, distant internal booms, fire hiss.
- This stage should look mournful and cinematic, the payoff of the whole ladder: a BattleTech-style wreck reads as a machine dying, and community VFX overhauls for Sins target exactly this richer death-explosion feel (https://mod.io/g/sins2/m/improved-vfx-tec-damage-explosions).
- Bio-weapon variant: stages 1 to 4 accept a corrosion and growth skin variant (section 5.3): etch decals instead of scorch, organic fringe on breaches, dripping instead of sparking. Same stage logic, different decal family.

### 10. Ship death and wreck

Death sequence (all timings screen-tuned guesses):
1. Kill moment: a held beat of 0.1 to 0.3 s where the ship's lights and engines stutter (one brightness dip, not a flash).
2. Cook-off phase, 0.8 to 2.5 s: 3 to 8 internal explosions rippling along the hull in sequence (each 0.3 to 0.8 s fireball, budget-managed), engines flare once then die, trails collapse.
3. Break-up: the ship splits into 4 to 10 major wreck sections (pre-fractured meshes or section groups; method UNSURE) that separate with slow tumble, each section trailing fire, smoke, and debris. Hot glowing cross-sections at the breaks, cooling over 5 to 15 s.
4. Final blast (optional per ship size, design call UNSURE): for heavy ships, one large fireball 1.5 to 3.5 s with an expanding shockwave ring and ember field. This is 1 big flash, budgeted.
5. Wreck field: the drifting sections and debris persist 10 to 30 s (or until the battle ends), slowly dimming, still venting small jets and occasional sparks. This gives the battlefield history, the cinematic quality the R16 bar asks for, and matches how community VFX mods frame death explosions as a lasting spectacle rather than a single puff (https://mod.io/g/sins2/m/improved-vfx-tec-damage-explosions). The X4 community critique of "ships pop in a single puff" is the failure mode to avoid (https://steamcommunity.com/workshop/filedetails/?l=dutch&id=3711529445).
6. Audio: the whole sequence rides a low boom, tearing-metal layer, and a fading fire bed; then near-silence with only debris ticks, which is the emotional beat. Owlcat and Audiokinetic describe driving VFX, animation, and sound off one master timeline for exactly this kind of synchronised sequence (https://www.audiokinetic.com/en/community/blog/wh40k-rogue-trader); whatever engine wins, the effects sheet assumes one timeline-driven sequence asset per ship class.
Camera and feedback: on player-ship kill, brief slow-motion (50 to 80 percent speed for 0.3 to 0.8 s, design call UNSURE) and one shake pulse. On losing a player ship, desaturate the wreck slightly so it reads as "gone."

### 11. Accessibility

Hard rule from the brief and from WCAG 2.3.2: no content may flash more than 3 times per second (https://www.w3.org/WAI/WCAG22/Understanding/three-flashes.html). The international photosensitivity guidance notes the sensitive band and brightness-change thresholds, and that moderate brightness changes (10 to 20 percent) are treated differently from large ones (https://pmc.ncbi.nlm.nih.gov/articles/PMC11872230/); Xbox Guideline 118 requires photosensitivity testing regardless of intent (https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/118). Practical rules for Voidsworn:
Definitions:
- Counted flash: any full brightness transition pair (dark-bright-dark) above a moderate contrast step, on any single emitter or light. Slow amplitude breathing, fire flicker, and sub-20-percent brightness shimmer are NOT counted flashes, but are still subject to the reduce-flashing option's smoothing.
- Global flash budget: a screen-space counter tracks counted flashes per rolling second across ALL effects. Cap: 3. This is stricter and safer than per-effect caps when many things happen at once, and follows the Game Accessibility Guidelines advice to avoid flicker build-up from overlapping sources (https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/).
Per-effect application:
- Battery: each shell's muzzle flash and each impact is 1 counted flash. A 5-shell heavy salvo at 0.06 to 0.12 s ripple can reach 5 muzzle events per second. Mitigation: the global budget merges concurrent salvo flashes into one combined brightness event (shells fired inside the same 0.33 s window share one counted flash), and per-shot flash brightness scales down as salvo density rises.
- Flak: burst rate would exceed the cap massively if each shell counted. Mitigation: flak muzzle flashes are individually small and dim (below the counted-flash contrast step), and airburst pops inside the same 0.33 s window merge into one counted flash. A full-screen flak war must stay at or under 3 counted bursts per second globally; individual bursts beyond the budget render as smoke and sparks without the bright core pop.
- Lance: no counted flashes while sustained (steady contact glow, slow ripple rings at 1 to 2.5 per second which are brightness ripples on an already-lit surface, under the cap). Only the initial touch bloom counts, 1 flash. Beam breathing modulation is kept at 1.2 to 3.3 Hz amplitude ripple under 20 percent so it does not count; final frequency is a screen-tuned guess, UNSURE and possibly batch-7-contested.
- Torp: launch is dim (no counted flash). Impact is 1 counted flash regardless of weight. Secondary sympathetic pops are dimmed under the counted threshold or merged with the primary when within 0.33 s.
- Bio: no counted flashes at all by design; impacts are splats and sizzles. The organism internal pulse is a slow 1 to 2 per second brightness modulation under 20 percent.
- Gauss: charge sequence is step-glows (slow, not counted). The firing flash is 1 counted flash. Impact is 1 counted flash. Muzzle ring and impact rings are non-counted expansions.
- SQ: each craft death is 1 counted flash. Mass craft deaths in one second are merged and dimmed by the global budget; if more than 3 craft die within a second, extra fireballs render at reduced brightness without the peak pop.
- Damage ladder: stage 2 spark bursts and stage 4 secondary events are sub-flash flicker (under 20 percent brightness step or merged), stage 3 and 4 fire uses amplitude flicker only.
- Ship death: cook-off explosions and the final blast total no more than 3 counted flashes per rolling second even for the largest ship; extras merge.
- Engine trails: misfire coughs and damaged-sputter modulation are slow (0.5 to 1.5 Hz) and under 20 percent brightness step; never counted flashes, never above 3 Hz under any state.
Reduce-flashing option (settings toggle, behaviour):
1. All counted flashes are replaced by non-flashing equivalents: bright core pops become expanding rings plus particle bursts plus a one-time gentle brightness lift (under 20 percent) with no rapid fall-off.
2. The global flash budget drops from 3 per second to 0 counted flashes per second: nothing produces a full contrast-step flash at all.
3. Muzzle flashes become smoke-forward (keep the gas cone and ember sparks, drop the additive core).
4. Impact blooms lengthen and soften: same information, stretched over 0.3 to 0.8 s with no peak.
5. Fire and explosion amplitude flicker is smoothed to slow sine breathing.
6. Camera shake from effects is reduced by half (independent shake settings still apply; the linkage is a design call, UNSURE).
7. Shield ripples and grid pulses keep full contrast (they are slow and informative) unless a separate reduce-motion setting also applies.
8. The option is honoured identically in all scenes, including the death sequence and heavy gauss, and the game ships with it defaulting to off plus a first-run photosensitivity notice (notice wording is a separate task, not effects-owned).
Testing requirement: every weapon kind plus a worst-case mixed salvo (heavy gauss, heavy torp volley, mass SQ deaths, flak screen) must be tested against the 3-per-second budget on real hardware before A5 sign-off, per the testing expectation in Xbox Guideline 118 (https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/118).

### 12. Values appendix

ALL values below are screen-tuned guesses expressed as ranges. None are locked. The evidence pack records batch 7 feel-value disagreements; because the pack could not be read for this chat, the specific contested items cannot be enumerated, so entries most likely to be contested are additionally marked UNSURE (disputed, needs screen tuning). Everything here needs a screen-tuning pass on target hardware, at battle zoom and close zoom, before lock.
Firing and wind-up:
- Battery wind-up: 0.05 to 0.15 s (medium and heavy). UNSURE (disputed).
- Battery salvo ripple: 0.06 to 0.12 s. UNSURE (disputed).
- Battery muzzle flash duration: 0.05 to 0.12 s.
- Flak burst size: 4 to 10 shells; heavy flak 3 to 6 larger shells. UNSURE (disputed).
- Flak ripple: 0.04 to 0.1 s light, 0.08 to 0.15 s heavy. UNSURE (disputed).
- Flak proximity fuse radius: 1 to 4 m; time fuse 1.0 to 2.5 s.
- Lance charge: 0.3 to 0.8 s medium and heavy, 0.05 to 0.15 s light. UNSURE (disputed).
- Lance ripple-ring cadence: one ring per 0.4 to 1.0 s.
- Torp tube sequence: 0.4 to 1.2 s; salvo ripple 0.3 to 0.8 s. UNSURE (disputed).
- Bio wind-up: 0.2 to 0.6 s; volley ripple 0.1 to 0.3 s plus 20 to 40 percent jitter.
- Gauss charge: 0.5 to 1.5 s standard, 1.0 to 2.0 s heavy. UNSURE (disputed).
- SQ bay cycle: 0.4 to 1.0 s; craft launch ripple 0.2 to 0.5 s; 1 to 4 craft per bay cycle.
Travel:
- Relative projectile speeds (battery light = 1.0): battery medium 0.8 to 0.9, heavy 0.6 to 0.8; flak 1.2 to 1.5; torp 0.15 to 0.3 with a 0.3 to 0.8 s boost phase; bio 0.4 to 0.7 (heavy organism 0.25 to 0.4); gauss 2 to 4. All UNSURE as balance-adjacent.
- Battery tracer trail lifetime: 0.1 to 0.3 s. Flak trail: 0.15 to 0.35 s. Bio droplet trail: 0.3 to 0.8 s.
- Torp plume ribbon lifetime: 3 to 8 s. UNSURE (disputed; leg disagreement on long-lived ribbons is plausible, verify against pack).
- Gauss wake lifetime: 0.2 to 0.5 s; muzzle distortion ring 0.3 to 0.6 s.
Impacts:
- Shield bloom durations: flak 0.05 to 0.12 s; battery light to heavy 0.08 to 0.3 s; lance initial 0.1 to 0.25 s; bio 0.1 to 0.2 s; gauss 0.1 to 0.25 s; torp 0.2 to 0.5 s. UNSURE (disputed for torp).
- Shield ripple duration: 0.15 to 0.4 s single ring; torp 2 to 4 rings over 0.5 to 1.2 s.
- Hull spark counts: light hits 6 to 15; medium hits sparks plus 2 to 5 chips; heavy hits 5 to 12 fragments; torp light 8 to 20 chunks, medium 15 to 35, heavy 25 to 50. UNSURE (disputed for torp heavies).
- Fireball durations: flak kill 0.3 to 0.8 s; SQ death 0.3 to 0.7 s; torp light 0.8 to 1.5 s, medium 1.2 to 2.5 s, heavy 2.0 to 4.0 s; death cook-off pops 0.3 to 0.8 s; final blast 1.5 to 3.5 s. UNSURE (disputed for torp heavy and final blast).
- Fire lick on heavy battery impact: 0.3 to 0.8 s. Lance trench cooling: 1.5 to 4 s. Gauss hole glow cooling: 2 to 5 s. Torp crater fire: 3 to 10 s.
- Debris and streaming-part lifetimes: 2 to 6 s typical; wreck field persistence 10 to 30 s. UNSURE (disputed).
- Flak smoke ball hang time: 2 to 6 s (recommended working band 2 to 4 s).
Ladder and death:
- Stage spark cadence (stage 2): one burst per 1 to 3 s. Stage 3 debris shed: one per 2 to 5 s. Stage 4 internal secondaries: one per 1 to 4 s; wreck-stage secondaries one per 1 to 3 s.
- Stage 3 fire plumes: 1 to 3 per zone; stage 4: 2 to 6; wreck: 4 to 10. UNSURE (disputed).
- Death cook-off length: 0.8 to 2.5 s; break-up sections 4 to 10; kill-moment held beat 0.1 to 0.3 s; slow-motion 0.3 to 0.8 s at 50 to 80 percent speed (design call UNSURE).
Engine trails:
- Core plume length: 2 to 10 ship-lengths by mass and throttle. UNSURE (disputed).
- Wake lifetime: 1 to 4 s.
- Damaged-sputter modulation: 0.5 to 1.5 Hz, under 20 percent brightness step; damaged plume length 60 to 80 percent of normal.
Accessibility:
- Counted flash cap: 3 per second rolling, global. Reduce-flashing mode: 0 counted flashes, all replacements per section 11.
- Merge window for concurrent flashes: 0.33 s. UNSURE (needs screen tuning).
- Non-counted modulation ceiling: under 20 percent brightness step, under 3 Hz for any repeating modulation; recommended working band 0.5 to 1.5 Hz for fire, beams, and damaged engines.
- Faction colour values: every specific colour in this sheet is a ROLE reference only. Actual values: UNSURE, sourced from the faction colour table in the evidence pack.

### 13. Sources

Repo facts: authoritative brief in the task prompt only; evidence pack unreadable in this chat, hence the UNSURE tags above.
External comparable-game and technique sources:
- WCAG 2.3.2 Three Flashes: https://www.w3.org/WAI/WCAG22/Understanding/three-flashes.html
- International Guidelines for Photosensitive Epilepsy (Jordan, 2024): https://pmc.ncbi.nlm.nih.gov/articles/PMC11872230/
- Xbox Accessibility Guideline 118, Photosensitivity: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/118
- Game Accessibility Guidelines, avoid flickering: https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/
- Rift Core Shield VFX Breakdown (hex-grid masked pulse): https://straypixels.net/riftcore-shield-fx/
- Shield force-field shader technique overview: https://unitycodemonkey.com/video.php?v=6AKR4b4C5jo
- RealTimeVFX forum, scorch mark process (procedural scorch materials): https://realtimevfx.com/t/scorch-marks-whats-your-process/1157
- VFX Apprentice, fire FX properties: https://www.vfxapprentice.com/blog/everything-know-about-fire-fx
- Kerbal Space Program Developer Insights 11, engine exhaust VFX (spawn tick-rate pitfall): https://forum.kerbalspaceprogram.com/topic/204884-developer-insights-11-%E2%80%93-engine-exhaust-visual-effects/page/4/
- Penny (1975), nozzle exhaust plume flowfield summary, NASA NTRS: https://ntrs.nasa.gov/api/citations/19750008553/downloads/19750008553.pdf
- EVE University, visual effects cue guide: https://wiki.eveuniversity.org/Visual_effects
- EVE Online Viridian missile impact VFX readability update: https://www.facebook.com/eveonline/videos/eve-online-new-missile-impact-vfx/153546001025191/
- Sins of a Solar Empire II update notes (per-weapon impact effect sets): https://www.stardock.com/news/522357/spheres-of-influence-update---sins-of-a-solar-empire-ii
- Sins II community VFX mod, TEC damage and explosions: https://mod.io/g/sins2/m/improved-vfx-tec-damage-explosions
- Sins II Steam discussion, beam vs gauss vs rail feel: https://steamcommunity.com/app/1575940/discussions/0/4038104598696926116/
- Rogue Trader 1.3 patch notes (blaster and dark lance beams): https://roguetrader.owlcat.games/news/en/45
- Rogue Trader 1.5 patch notes coverage (torpedo destruction VFX): https://www.rpgsite.net/news/18770-warhammer-40000-rogue-trader-update-1-5-full-patch-notes-gameplay-trailer
- Audiokinetic blog, sound and music in Rogue Trader (timeline-driven VFX and audio): https://www.audiokinetic.com/en/community/blog/wh40k-rogue-trader
- BattleTech Feel weapon visuals mod (lasers, PPC, gauss, muzzle flashes): https://www.nexusmods.com/mechwarrioronline/mods/63
- X4 community critique of flat weapon impacts: https://steamcommunity.com/workshop/filedetails/?l=dutch&id=3711529445
- Airburst round reference: https://en.wikipedia.org/wiki/Airburst_round
- DCS forum, flak burst dissipation time: https://forum.dcs.world/topic/262457-effects-flak-burst-dissipation-time/
- IL-2 forum, flak cloud persistence: https://forum.il2-series.com/topic/4384-flak-clouds-disappear-much-too-quickly/
- Helldivers wiki, RL-77 airburst fuse behaviour: https://helldivers.wiki.gg/wiki/RL-77_Airburst_Rocket_Launcher

End of sheet. This is the complete Job A deliverable, ready to file verbatim. Open items for the next pass: read the evidence pack to resolve all UNSURE tags (faction names and colour values, K2 A5 item mapping, exact batch 7 disputed entries), confirm the engine call, then run the screen-tuning pass to collapse every range in section 12 to locked values.
