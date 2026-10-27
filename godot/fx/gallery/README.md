# Effects gallery (G4)

The six flagships at game scale (built by G2's own ShipView from `res://gen`, so they look exactly as in battle) on the dead-star board, with a scripted reel that plays every effect: each weapon look on shields and hulls, the damage ladder, the four shield breaks, three deaths and the drifting wrecks. It is where effects are judged before they go into battle.

## Running it

From the repo's `godot` folder (needs `res://gen`, which G2's `render/build_assets.gd` writes):

```
godot --path . res://fx/gallery/gallery.tscn                              free viewing: the reel loops; 1 overview, 2 orbit, R restart, F reduce flashing, Esc quit
godot --path . --fixed-fps 60 res://fx/gallery/gallery.tscn -- --shots DIR --res 3840x2160      the stills, then quit
godot --path . --disable-vsync res://fx/gallery/gallery.tscn -- --bench OUT.json --res 3840x2160  frame times, then quit
```

Options after `--`: `--quality max|high|low`, `--tonemap agx|aces`, `--reduce-flashing`, `--no-fx`, `--no-world`, `--no-physics`, `--only a,b` (stills whose names contain a or b), `--seconds S`, `--lo` (game-detail hulls even where the 8K flagships exist).

Breach close-ups on one ship, outside the reel: `godot --path . --script res://fx/test/fx_breach_probe.gd` with PROBE_FAC, PROBE_CLS, PROBE_STAGE (2 to 4), PROBE_OUT (a folder), PROBE_W and PROBE_H; it prints the hull rebuild time.

Weapon marks (R43), one at a time on a clean hull, a close-up a second after each lands, another when it has cooled, and a still from the battle camera's distance (170 units, fov 45: `_tac`), with its cost: `godot --path . --script res://fx/test/fx_marks_probe.gd` with PROBE_FAC, PROBE_CLS, PROBE_OUT, PROBE_W, PROBE_H, PROBE_SIZE and optionally PROBE_LOOKS (a comma list); prints MARKS_HULL and MARKS_COST lines (worker and main-thread ms per mark).

Hit reactions (R50): `godot --path . --script res://fx/test/fx_react_probe.gd` (PROBE_OUT for stills): each weapon weight hits a frigate and a super-dreadnought; prints the peak roll, yaw, pitch, drift and settle time per hit, writes `react_trace.csv` (every frame), and with PROBE_CLIP=1 a 30 fps JPEG sequence per hit (PROBE_ONLY picks the weapons, PROBE_STILLS=0 skips the strips). Runs headless for the numbers alone.

On Ryan's PC: `pc/g4_gallery.bat` runs as a queue job (copied to `Downloads\voidsworn_test\g4\`); it restores G4's files into `build\godot` first (other streams' jobs re-extract parts of that folder), then writes `Downloads\voidsworn_test\g4\<run>\`: `shots\` (4K, AgX), `breach_corsair\` and `breach_hegemony\` (breach close-ups on the 8K barge and super-dreadnought), `shots_aces\` (the same moments under ACES), `shots_calm\` (reduce flashing on), `marks_corsair\` and `marks_voidsworn\` (every weapon's mark on the 8K barge and a Voidsworn dreadnought), `react\` (hit-reaction strips), the smoke log and the bench JSONs.

## The stills

Each still is keyed to the moment its effect really lands on the effect clock (the reel marks the impact time each `volley` returns, the moment each shield breaks, the break-up of each death), so a still shows the same instant on every run.

| Still | What it shows |
|---|---|
| g01, g02 | Idle fleet: engine cores, plumes, the long cooling trails (Corsair sputter and soot); the dead star with lensing and its disc |
| g03 | Voidsworn heavy macro broadside: four-gun ripple, muzzle blast, smoke rings, white-core tracers, hull hits on the Chorus |
| g04 | Ithar prism needles on the Hegemony shield (blue hex lattice) |
| g05, g05b | Hegemony plasma: fat churning bolts in flight, then splashing slag on the Deathless hull |
| g06 | Corsair rattle-rocket swarm inbound (one shot down by point defence) |
| g07 | Voidsworn lance holding on the Chorus: white-hot core, molten trench, spark fountain |
| g08 | Hegemony ion beam with crawling arcs on the Ithar shield |
| g09 | Deathless gauss punching through the Hegemony with an exit spray |
| g10, g10b | Chorus spine globs in flight, then the acid splash and corrosion on the barge |
| g11 | Deathless doom arc on the Ithar (re-striking lightning) |
| g12 | Hegemony picket-laser flak bursting round the Chorus |
| g13a, g13 | Voidsworn torpedo in flight (trackable plume), then the heaviest impact (fireball, shockwave, debris) |
| g14 | Voidsworn strike craft on a run at the Ithar |
| g15a, g15 | The barge at stage 2 (the hull dented and blackened, sparking) and stage 4 (holes cut in the hull, fires, streaming debris) |
| g15b | Close on the barge's mid hole at stage 3: torn edge, plates bent back, buckled skin, the cavity lit from inside |
| g15c, g15d | The same hole grown to a breach at stage 4, straight on and from the side (frames, decks, conduits, cables, gas, sparks) |
| g15e, g15f | The bow breach, and the bite out of an upper edge that changes the silhouette |
| g16 to g19 | Shield breaks: Voidsworn gold veil tears, Hegemony lattice shatters, Corsair sputters out, Ithar veil sheets away |
| g20 | Ithar star torpedo |
| g21, g21b | Chorus death by torpedo: break-up into its own hull pieces, then 3 s later the burning wreck |
| g22, g23 | Deathless flayed by gauss; Hegemony cut by a lance |
| g24 | The wrecks drifting at the end of the reel |

## Look decisions (vetoable)

- **Weapon marks read from the battle camera (r5).** r4's close-ups showed most marks invisible or barely there: big kit plates and AI panels are a few large triangles, so a mark smaller than a triangle could neither cut the hull nor get its overlay (the overlay took only triangles whose centre lay inside it). Now coarse triangles near a mark are split first (conforming, all attributes interpolated) and the overlay takes every triangle that reaches into the mark. Each mark also lays a halo in its own signature, at least HALO_MIN world units (0.75 to 2.1; the battle camera sees about 7.7 pixels a unit at 1080p), so a mark is a readable patch from the battle camera and its detail shows when zoomed in. Fresh glow trimmed (plasma 3.0 to 1.8, shells 1.5 to 1.1) so the shape shows instead of a bloom blob.
- **Hit reactions (r5):** onset, thruster arrest, slow recovery (API.md 7), instead of a spring out and back. Peaks kept near r4's (frigate torpedo about 6.6 degrees, super-dreadnought 1.4) but they come later and leave slower.
- **Shield breaks (r5):** each faction comes apart its own way and the bubble stays see-through (API.md 4); r4's breaks were the same noise holes in a bright, nearly opaque bubble for three factions.
- **Explosion noise (r5):** the 3D noise behind fireballs and gas used a product hash and cubic fades that drew a diagonal grid of hard diamonds through big fireballs (r4 g21); now Hoskins' hash, quintic fades and rotated octaves.
- **Damage follows the hull's bob (r7):** ShipView bobs each hull 0.25 units and banks it; the damage overlay, cavities, fires, engines and shield now follow that motion (the hull frame at add_ship), and every effect position goes through it. Before, overlay-only marks (ion burns, flak) sank into the bobbing hull and vanished on the PC runs.
- **Flak rash (r7):** dark pits and bright chipped specks, so it reads on light and dark hulls; stage breaches get a soot halo; Corsair shield patches are irregular cells, not blocks.
- **Flak pocks and ram crumple (r8):** flak pocks are round specks of mixed sizes over a light grime (r7 drew square grid cells, which looked like digital camouflage). A ram folds the bow in rings round the nose, shoves the tip back and kinks it to one side (r7 only pushed the nose back, which stayed smooth).
- **Marks at battle distance (r18, Muse audit B4.3):** each weapon leaves its own shape, not only a glow: flak a dotted patch of coarse black pocks with a few still glowing; acid a green stain with drips running off it; ion a seven-spoke starburst with a cold blue glow along the spokes; ram long pale gouges along the ship's length; lance a slot with temper colours; plasma blue glass; shell and gauss dark char with a small smouldering core that lasts the battle. The brief scorch glow is tight and short (r9 to r15 left a wide orange wash). The damage and engines now hang under the hull mesh itself, so they move with the bobbing hull in the same frame (before, in stills, the overlay sank into the hull at random; that was why marks came and went between runs).
- **Safe mode (Compatibility renderer):** the marks draw there too (hull geometry plus an overlay mesh, not decals); glow is simpler and the lens is off. The r18 run records the frigate marks on both renderers.
- **Dead star close up (r18):** filaments wound along the flow, dark dust lanes, a thicker look edge-on, and two thin glowing haze layers above and below the disc.
- **Marks at battle distance (r9, Opus):** every fresh mark glows for a few seconds in its weapon's heat colour (orange for kinetic and lance hits, blue for plasma and ion, green for acid), broken up by the halo noise. It fades in over a quarter second and cools over 4 to 9 s, never jumping, so the flash budget is unchanged. The soot round each mark is darker and denser, and frigate halos may now reach 16% of the ship's length (was 12%). The ram crumple is deeper (folds, shove and kink all stronger; dent depth 3% of length, was 2.2%).
- **Lasting scars (r12, Opus):** flak pocks gather into one darker peppered patch (wider, 2.4 units at least) with a faint warm rim, instead of isolated specks. Plasma, shell and gauss scars keep darker, denser char after cooling, and every one of these four keeps a dim broken edge glow that lasts the battle (about five minutes to half strength). It comes up with the scorch and never jumps, so the flash budget is unchanged.
- **Battle asteroids (r9, to match G3's map rocks):** lumpy noise-displaced bodies with impact craters and rims, shaded smooth, no flat cut faces. Strata, dust, grit and pitting in the shading, darker crater floors, brighter worn rims, patchy albedo and varied roughness, and a warm rim from the dead star's disc on the side facing it.
- **Debris plates (r6):** twelve torn shapes (ragged outlines with notches, stretched, creased once) instead of three hexagons; the rim glows only in broken stretches and cools in half a second; the faces are rough and sooty, no longer mirror-like (r5 g15c: glowing hexagon outlines floating past the breach read as a cartoon).
- **Fireballs (r6):** a finer billow breaks the fire into lobes and smoke pockets, with less peak glow, so a big blast is not one flat bright disc.
- **Asteroids (r6, BACKLOG "asteroid rebuild"):** a finer sphere shaped by ridged noise with a few impact craters, then the flat cuts that keep blockers sharp; the cut faces shade flat and crisp, the rock between them smooth. The world's 3D noise hash changed too (the same lattice fix as the fireballs), and crystal veins are thinner.
- **Dead star (r7, to agree with G3's map):** the lens no longer bends the disc itself (only the far background), so the disc is never torn into copies round the shadow (r4 g01); the disc's far side is drawn as G3's lensed arcs instead, a broad one over the shadow and a thin secondary one under it, with Doppler beaming (the side turning toward the camera brighter and bluer, the other dimmer and redder) and G3's thin photon ring.
- **Torpedo shock ring (r5):** a soft, broken front of hot gas instead of a thin neon circle, and fewer, less regular spark lines (the r4 strips read as a cartoon burst).

- **Tonemapper: AgX** (`tonemap_check.py` replicates Godot 4.7.2's ACES and AgX exactly and scores the game's colours). ACES pushes the Corsair red 17 degrees toward orange at the brightness effects use, so Corsair and Voidsworn effects drift toward each other; AgX keeps faction hues within 8 degrees and hull colours neutral (chroma kept 0.97). Khronos PBR Neutral was the most faithful for effects (1 degree mean drift) but over-saturates hulls by about half and is not built into Godot 4.7; it would need a custom post pass, so it stays a later option. `shots_aces\` shows the same moments under ACES for Ryan's eye.
- **Dark hulls:** a Fresnel rim in the faction tint plus a small albedo lift for Chorus and Deathless (look.gd HULL_FIX), not more key light.
- **Breaches change the hull (R39):** the hole is cut out of the real mesh with its plates bent back and a lit cavity behind it; the generic cut stands in until A4's pre-cut parts arrive (API.md 14). Sizes (3% of length at stage 3, 4.6% at stage 4, a 3.2% edge bite), the four or five petals and the fire level inside are Claude's picks.
- **Flashes:** large flashes (impacts, explosions, shield breaks, gauss muzzle) go through the 3-a-second budget; small muzzle flashes are below the area that counts and become smoke-forward in reduce-flashing mode. The smoke test fails if any rolling second holds more than 3 counted flashes.

## Cost

Ryan's PC (RTX 5080), the full 26 s reel with an orbiting camera. Each feature's cost is the difference from the full run. Run r2 (Oct 26, with the shader warm-up; r1b in brackets).

Run r3 (Oct 26, the breach rework f9b60b4 to ec23549): 4K max 4.88 ms average (GPU 4.59), no effects 3.37, no world 4.40, high 3.09, 1440p max 2.65; but p99 21.5 ms and a 120 ms worst frame at the first break-up, and 5 surface pipeline compiles in the fight. After r3: the hull rebuild builds its meshes on the worker (the main thread only swaps them in), the death cut reuses the arrays already read instead of reading an 8K hull back again. r4 measures it.

| Run | Frame avg | p99 | GPU | Feature cost |
|---|---|---|---|---|
| 4K max, everything | 5.02 ms (5.78) | 9.94 ms (11.84) | 4.85 ms | inside the A3 bar of about 6 ms |
| 4K max, no effects | 3.36 ms (4.18) | 4.72 ms | 3.22 ms | the whole effects layer: 1.66 ms |
| 4K max, no world | 4.54 ms (5.30) | 9.19 ms | 4.37 ms | dead star (lens, disc), asteroids, sky: 0.48 ms |
| 4K max, no physics | 5.00 ms (5.75) | 9.48 ms | 4.83 ms | Jolt debris and wreck pieces: 0.02 ms |
| 4K high | 3.10 ms (4.03) | 5.43 ms | 2.93 ms | max-only extras (raymarched fire and vents, distortion, soft particles, parallax holes, 64 lights, SSAO and SSIL): 1.92 ms |
| 1440p max | 2.77 ms (3.40) | 5.45 ms | 2.62 ms | |

Pipeline compiles during the measured fight in r2: draw 0, surface 8 (the death pieces' material copies; removed after r2), specialization 14 (Godot's background specialisations, which do not stall). The worst frame (35 ms) was the first break-up building its piece meshes; they are now built ahead, as soon as the background cut finishes.
