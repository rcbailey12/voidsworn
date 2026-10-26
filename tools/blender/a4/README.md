# A4 kit rollout: the ship chain

Plan section 4 "A4" and "Travel sprint" (R34). One script chain takes every AI hull in `hulls_hi/` to Godot-ready files in
`godot/assets/ships/`, following the ship-kit skill (build, check, export). The barge (C19_51) keeps its own approved chain
(`tools/blender/a1/barge_v15.py`, `assets/ships/C19_51/`) and is converted into the same Godot format at the end.

Decisions this rests on: `K1_DECISIONS.md` (Claude's calls, Ryan can veto).

## The chain, per ship

1. **Ship file** (`ships.py`): faction, class, what AI parts to cut out, which hand-built parts go where, weapon mounts per data.js slot.
   `check_entry()` refuses unknown keys, sizes outside the table, backward aims and weapon slots without a mount.
2. **Build** (`a4_ship.py`, Blender 4.5 on the PC or the bpy module in the cloud):
   - load the hull with true chirality (`frame.py`, K1 decision 2) and the game's yaw fix;
   - cut what the blob sweep rebuilds by default (`cuts.py`: guns, towers, masts, engine crowns, thin AI sticks, loose debris);
   - refine (adaptive PN, `a2detail/hullio.py`), fill the cut holes with soft patches;
   - hand-built parts (`kit.py`): turrets, casemates, spinal mounts, launchers, Chorus grown emitters, engine bells, thruster pods,
     radiators, antenna arrays, sensor domes, bridges, tanks, hangar bays. Each sits on a plinth that reaches below the hull's lowest point
     under its footprint (never floating, never a light gap), stands square to its side, and records its hard point;
   - faction surface detail: `a2detail/dress.py` (Voidsworn, Hegemony, Chorus, Ithar, Deathless), `dress4.py` (Corsair salvage);
   - breach anchors on open hull, centre of mass.
3. **Audit** (blocking): every part touches the hull or a chain of parts that does; no gun rests aimed backward; P mounts on the port
   side, S on starboard; every weapon slot has a mount. Dress parts that float are removed; kit parts that float fail the build.
4. **Bake** (PC GPU, `bakemat4.py`): albedo, ORM, emissive, normal at 4096 on one atlas. Engine glow comes from the modelled bells.
5. **Wreck** (`wreck.py`): the finished ship cut into chunks, capped, each with its own centre of mass.
6. **Pack** (`pack.py`, needs PIL): `godot/assets/ships/<CODE>/` with the ship glb (hard point nodes), the wreck glb and four shared
   JPEG maps at 2048; the 4096 set on the PC. Structural checks on both files (`gio.check`), reimport check in Blender.
7. **Review**: `look.py` (Workbench clay with a coordinate grid and close-ups, cloud), the studio views and 9-cell blob sweep from the bake
   job (Cycles, PC), and the faction lineup sheet (`lineup.py`).

## Running it

- Cloud, shape only: `python3 tools/blender/a4/a4_ship.py CODE OUTDIR --nobake --look` (Workbench sheets `CODE_a4look.png` and
  `CODE_a4close.png`, hard points drawn as cones: red weapons, orange engines, green bays, blue breach anchors).
- Height profiles for setting cut boxes: `python3 tools/blender/a4/probe.py CODE top|below|port|stbd x0 x1 dx [rows]`.
- PC, full: `python3 tools/blender/a4/stage.py STAGE_DIR TAG CODE...` stages `a4tools\` and one queued job per ship
  (`tools/pc/jobs/a4_ship.bat`, about 4 to 8 minutes a ship); copy `a4tools\` into `voidsworn_test\build\`, then the job files into
  `voidsworn_test\queue\`. Results in `voidsworn_test\a4\`.

## Frames

- Ship files and kit: x bow, y port, z up, length 1.0 (true chirality, right-handed).
- Exports (glTF, Godot): +X bow, +Y up, -Z port, +Z starboard.
- The game's hull JSON (unchanged): x bow, y up, z port, read by Babylon (left-handed).
