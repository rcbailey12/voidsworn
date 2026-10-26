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

Weapon marks (R43), one at a time on a clean hull, a close-up a second after each lands and another when it has cooled, with its cost: `godot --path . --script res://fx/test/fx_marks_probe.gd` with PROBE_FAC, PROBE_CLS, PROBE_OUT, PROBE_W, PROBE_H; prints MARKS_COST lines (worker and main-thread ms per mark).

Hit reactions (R50): `godot --path . --script res://fx/test/fx_react_probe.gd` (PROBE_OUT for stills): each weapon weight hits a frigate and a super-dreadnought; prints the peak roll, yaw, pitch, drift and settle time per hit.

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
