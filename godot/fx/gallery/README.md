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

On Ryan's PC: `pc/g4_gallery.bat` runs as a queue job (copied to `Downloads\voidsworn_test\g4\`); it restores G4's files into `build\godot` first (other streams' jobs re-extract parts of that folder), then writes `Downloads\voidsworn_test\g4\<run>\`: `shots\` (4K, AgX), `shots_aces\` (the same moments under ACES), `shots_calm\` (reduce flashing on), and the bench JSONs.

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
| g15a, g15 | The barge at stage 2 (dented, sparking, venting) and stage 4 (hull breach, fires, streaming debris) |
| g16 to g19 | Shield breaks: Voidsworn gold veil tears, Hegemony lattice shatters, Corsair sputters out, Ithar veil sheets away |
| g20 | Ithar star torpedo |
| g21, g21b | Chorus death by torpedo: break-up into its own hull pieces, then 3 s later the burning wreck |
| g22, g23 | Deathless flayed by gauss; Hegemony cut by a lance |
| g24 | The wrecks drifting at the end of the reel |

## Look decisions (vetoable)

- **Tonemapper: AgX** (`tonemap_check.py` replicates Godot 4.7.2's ACES and AgX exactly and scores the game's colours). ACES pushes the Corsair red 17 degrees toward orange at the brightness effects use, so Corsair and Voidsworn effects drift toward each other; AgX keeps faction hues within 8 degrees and hull colours neutral (chroma kept 0.97). Khronos PBR Neutral was the most faithful for effects (1 degree mean drift) but over-saturates hulls by about half and is not built into Godot 4.7; it would need a custom post pass, so it stays a later option. `shots_aces\` shows the same moments under ACES for Ryan's eye.
- **Dark hulls:** a Fresnel rim in the faction tint plus a small albedo lift for Chorus and Deathless (look.gd HULL_FIX), not more key light.
- **Flashes:** large flashes (impacts, explosions, shield breaks, gauss muzzle) go through the 3-a-second budget; small muzzle flashes are below the area that counts and become smoke-forward in reduce-flashing mode. The smoke test fails if any rolling second holds more than 3 counted flashes.

## Cost

Ryan's PC (RTX 5080), the full 26 s reel with an orbiting camera, run r1b (Oct 26). Each feature's cost is the difference from the full run.

| Run | Frame avg | p99 | GPU | Feature cost |
|---|---|---|---|---|
| 4K max, everything | 5.78 ms | 11.84 ms | 5.09 ms | (the A3 bar: about 6 ms) |
| 4K max, no effects | 4.18 ms | 5.53 ms | 3.49 ms | the whole effects layer: 1.60 ms |
| 4K max, no world | 5.30 ms | 11.06 ms | 4.59 ms | dead star (lens, disc), asteroids, sky: 0.48 ms |
| 4K max, no physics | 5.75 ms | 11.43 ms | 5.06 ms | Jolt debris and wreck pieces: 0.03 ms |
| 4K high | 4.03 ms | 11.36 ms | 3.29 ms | max-only extras (raymarched fire and vents, distortion, soft particles, parallax holes, 64 lights, SSAO and SSIL): 1.75 ms |
| 1440p max | 3.40 ms | 7.16 ms | 2.71 ms | |

The p99 and the 47 ms worst frames were first-use shader compiles; round 2 adds `fx.warmup()` and records pipeline compiles during the run (target 0).
