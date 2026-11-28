# H9E Spineguard | Vanguard cruiser

Meridian Directorate, issue 2094 run 5. Ryan approved [H9E Spineguard](../../../shots/issue-2094-codex/vanguard_sheet_e.png) on Nov 26, 2026, with the condition that it fit the other ships in the faction. The [accepted beauty](../../../shots/issue-2094-codex/vanguard_beauty_e.png) guides the heavy bow collar, raised cannon housing and four capacitor hoops. Its views are not measurements of a single model.

- **Design source** [hegemony_H9E.py](../../../../tools/blender/build_sheets/ships/hegemony_H9E.py) defines the shell, stations, fittings, attachments and interior. The [feature table](feature_table.md) describes the route for each part.
- **Game target** `h_vanguard`, cruiser, 14.5 world units, slot `H9_23`. Godot currently displays the rules entry as Vector cruiser. The recipe does not change rules or the installed ship.
- **Route per part** One hand-built faceted saddle, octagonal barrel jacket, bow collar, concentric bore liner and four grooved clamps. The emitter and fixed mount, rectangular drives, lances, fin, doors, vents, windows, hatches and panel grid reuse the Directorate kit and the H7/H8/H10 build pattern. No generated geometry ships.
- **Paint stack** Shared `hegemony/stack.py` via `bake: stack`. Pale steel-slate plate, steel-blue trim, an even two-size plate grid, recessed dark seams, blue side strips and blue-white drives. Hull masks, shared trim and decals, no projected concept.
- **Inside** Two module joints make three pieces. Each has decks, framing and machinery with Directorate Interior Kit V2 trim. Forward capacitor rooms and crew spaces, a middle reactor and gunnery deck, and an aft drive and drone handling section. The two flush side doors serve the same rules hangar.
- **Budget** Unpainted test export has 54,060 triangles across 15 GLB primitives, including 21,840 interior triangles and 5,184 turning turret triangles. Baked materials, draw calls and the installed scene gate remain for the queued build.

## Changes from the picture

The concept's round muzzle becomes a heavy chamfered octagon. Four nested metal rings line the recess, with the kit lens about 0.55 u behind the bow face. The jacket has two sizes of machined plates and paired longitudinal rails. It tapers into the saddle without a gap. Four separate steel-blue hoops stand above it, with blue contacts below the bevelled rims. The second hoop sits aft of the lance sweep so both turrets keep their original stations and full turn.

The waist still pulls in before the square stern, but the deep V becomes a flat, worked belly with faceted shoulders like Picket and Cordon. The slit lights stop at the module joints. The kit defines the gun mounts, one per existing turbo slot, and the four nozzles share one flat transom. The paired flush doors are marked for the real launch ability rather than decorative bays. Run 5 did not change those features or the interior layout.

The [same-length comparison](../../../shots/issue-2094-codex/vanguard_family_lineup_r5.png) shows the three recipe models with matched cameras, kit materials and bow-to-stern scale. The [orthographic sheet](../../../shots/issue-2094-codex/vanguard_build_sheet_r5.png) shows the port side, top, underside, bow, stern and centreline cutaway at one scale. These are CPU sheet previews before paint, not game captures.

The CPU fit report found zero clashes, mount faults, blocked firing arcs or turret sweeps, and zero exhaust, launch exit or shared lane conflicts. The recipe kept both module seams and all 20 required or authored hard points on GLB readback, including four joint breach anchors and paired braking and boarding points. Paint and the exterior surface check wait for the approved PC build.
