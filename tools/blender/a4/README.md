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
6. **Breach damage** (`damage.py`, numpy, R39): per breach anchor a hull patch (`skin_<n>`, `skin_<n>_heavy`) split out of the ship
   mesh, and `<CODE>_damage.glb` with the hole and the heavy damage (torn plates bent outward in the ship's paint, a cavity with frame
   rings, stringers, decks, conduits and fire glow). Review sheet: `dmgview.py` (intact, hole, heavy per anchor).
7. **Pack** (`pack.py`, needs PIL): `<CODE>/` with the ship glb (hard point nodes, skins, Ithar sails as a see-through second surface),
   the wreck glb, the damage glb and four shared JPEG maps at 2048; the 4096 set on the PC. Structural checks (`gio.check`), reimport
   check in Blender. The job then copies the folder into the PC game build (`build\godot\assets\ships\<CODE>\`) and `manifest.py`
   writes the manifest and previews that go into the repo (the glbs stay out of git for now).
8. **Review**: `look.py` (Workbench clay with a coordinate grid and close-ups, cloud), the studio views and 9-cell blob sweep from the bake
   job (Cycles, PC), and the faction lineup sheet (`lineup.py`: a phone-width WebP, the whole line at true relative size on top, then
   one framed card per ship, biggest first, with name, class, length and weapons).

## Review pass 2 (Oct 26, after every hull was built once)

- Bake: hulls_hi normal-map texels that tip the surface past about 60 degrees fade back to the true normal (H4's belly baked black in
  patches; every Chorus belly had white streaks); hand-built parts on metal factions take the panel seams too (they read as plain blocks).
- Naval tells cut: B20 and B21 conning towers, masts, stay wire and bow whiskers; Hegemony antenna masts rebuilt as slim sensor
  arrays (spires style `array`, dress4.py) instead of fat tubes that read as funnels.
- H9: melted bridge rebuilt by hand, aft cut floor at the deck.
- Damage: `acid` and `board` variants per section (damage.py), finer patches for splash and acid.
- dmgview's sheet step no longer imports bpy (it stopped every breach review sheet in the first pass).

## Review pass 3 (Oct 27, lore notes while lore round 3 is open)

- Corsairs grimmer and more menacing, still junky: `kit.hook_prow` (a boarding claw under the chin or on the prow: collar, boom with
  hydraulic rams, a toothed hub and curled grapple tines; boarding gear, not a sea ram), trophy plates in the dress (`dress4.trophy_plates`:
  armour torn off Hegemony, Voidsworn and Chorus ships in the victim's paint and trim stripe, bolted on crooked with clamps, a bone kill
  tally; Ithar and Deathless are not used while their looks change).
- Naval tells cut: the Corsair pole antennas with dish balls read as masts with a crow's nest, now `kit.sensor_array` (low base, phased
  panels in an A, a dish on a ball mount, short whips); C13s and C15s chin fins read as boat keels, cut; C16s bow prongs cut.
- Voidsworn spires: style `radiator` (`dress4.build_radiator_spires`): a square core, a cross of flat vanes with heat-pipe ribs, ember
  vent slits, a flat emitter cap. No points, finials or bands (a first try with stepped collars read as a pagoda).
- Breach anchors keep off the bow and stern tips and the end faces (a nose-tip hole faced forward with its guts out past the bow).
- Ithar and Deathless: no repaint or restyle (their looks are changing); shape fixes only.

## Pass 4 (Oct 27, Ryan on the barge and Opus relaying the standing rulings)

- Pyre-Barge (C19_51) rebuilt in the family grammar: `compose.py` welds captured C16s, C15s, C13s and C14s hulls (each with its own
  blob-sweep cuts, plus `cuts_extra` in its own frame) into one lopsided war-barge, with the parts' AI maps tiled into one 2x2 atlas.
  Three boarding claws, more trophy plates (dress over 1.2), dirty orange engines on every hull. It now builds through `a4_ship.py`
  like any ship; `barge4.py` (the v15 path) stays for reference, with its mast towers swapped for low sensor arrays.
- `reshape.flat_bow` (ship key `reshape`): naval side profiles (raked stem, sheer deck, forefoot) become a chisel wedge with a flat
  belly; the top view is untouched. Hegemony H4, H7 to H10 and V1b.
- Hegemony: the painted waterline stripe is gone, windows only in small clusters, recessed light clusters with sensor housings.
- V1b: the cathedral tower top is a command tower with radiator banks and sensor arrays; V17: the three peaks are a radiator bank.
- I16: the two upright masts are emitter booms laid along the deck (`kit.boom`); the fan vane stays.
- Cut holes with a simple rim are filled by a beauty triangulation (a radial fan on V1b's spine showed in G4's marks sheet).

## Running it

- Cloud, shape only: `python3 tools/blender/a4/a4_ship.py CODE OUTDIR --nobake --look` (Workbench sheets `CODE_a4look.png` and
  `CODE_a4close.png`, hard points drawn as cones: red weapons, orange engines, green bays, blue breach anchors).
- Height profiles for setting cut boxes: `python3 tools/blender/a4/probe.py CODE top|below|port|stbd x0 x1 dx [rows]`.
- PC, full: `python3 tools/blender/a4/stage.py STAGE_DIR TAG CODE...` stages `a4tools\` and one queued job per ship
  (`tools/pc/jobs/a4_ship.bat`, about 4 to 8 minutes a ship); copy `a4tools\` into `voidsworn_test\build\`, then the job files into
  `voidsworn_test\queue\`. Results in `voidsworn_test\a4\`.

## Hulls the AI got wrong

- Turned: `yaw` (quarter turns, 2 = back to front: C15s, V14, V16, B19, B21, B22, I11, D9; -1: D20 meshed side-on).
- Slanted: `pitch` and `roll_deg` level a hull the AI meshed at an angle (`frame.tilt`; I15 bow up 13.5 degrees, D22's ring rolled 26).
- Ithar (`ithar.py`, R28 "Ithar broken"): the AI sails are thick lumps, so they are cut (box cuts, or `needle` cuts that keep only the
  spindle) and rebuilt with `kit.sail` (membrane, gold ribs, lit rim, hub ring). Where the body itself is unusable (I8, I11) the hull is
  lofted by hand (`loft`: a faceted porcelain spindle with a hub bulge and a flat stern face for the engine).

## Frames

- Ship files and kit: x bow, y port, z up, length 1.0 (true chirality, right-handed).
- Exports (glTF, Godot): +X bow, +Y up, -Z port, +Z starboard.
- The game's hull JSON (unchanged): x bow, y up, z port, read by Babylon (left-handed).
