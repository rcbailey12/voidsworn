# H9E Spineguard | Vanguard cruiser

Meridian Directorate, issue 2094 run 4. Ryan approved [H9E Spineguard](../../../shots/issue-2094-codex/vanguard_sheet_e.png) on Nov 26, 2026, with the condition that it fit the other ships in the faction. The [accepted beauty](../../../shots/issue-2094-codex/vanguard_beauty_e.png) guides the massing and four capacitor hoops. Its views are not measurements of a single model.

- **Design source** [hegemony_H9E.py](../../../../tools/blender/build_sheets/ships/hegemony_H9E.py) defines the shell, stations, fittings, attachments and interior. The [feature table](feature_table.md) describes the route for each part.
- **Game target** `h_vanguard`, cruiser, 14.5 world units, slot `H9_23`. Godot currently displays the rules entry as Vector cruiser. The recipe does not change rules or the installed ship.
- **Route per part** One hand-built faceted saddle, barrel jacket and bow collar. The emitter accelerator, rectangular drives, lances, fin, doors, vents, windows, hatches and panel grid reuse the Directorate kit and the H7/H8/H10 build pattern. No generated geometry ships.
- **Paint stack** Shared `hegemony/stack.py` via `bake: stack`. Pale steel-slate plate, steel-blue trim, an even two-size plate grid, recessed dark seams, blue side strips and blue-white drives. Hull masks, shared trim and decals, no projected concept.
- **Inside** Two module joints make three pieces. Each has decks, framing and machinery with Directorate Interior Kit V2 trim. Forward capacitor rooms and crew spaces, a middle reactor and gunnery deck, and an aft drive and drone handling section. The two flush side doors serve the same rules hangar.
- **Budget** Unpainted test export has 51,396 triangles across 15 GLB primitives, including 21,720 interior triangles and 5,184 turning turret triangles. Baked materials, draw calls and the installed scene gate remain for the queued build.

## Changes from the picture

The high circular muzzle becomes a lower, blunt chamfered collar around the same recessed accelerator design as Cordon. The four shorter external hoops remain countable, with inset blue contacts instead of bright rings. The jacket is tied into the saddle, not standing above a gap. The waist still pulls in before the square stern, but the deep V becomes a flat, worked belly with faceted shoulders like Picket and Cordon. The slit lights stop at the module joints. The kit defines the gun mounts, one per existing turbo slot, and the four nozzles share one flat transom. The paired flush doors are marked for the real launch ability rather than decorative bays.

The [same-length comparison](../../../shots/issue-2094-codex/vanguard_family_lineup_r4.png) is a CPU sheet preview of all three recipe models in matched cameras and kit materials. The [orthographic sheet](../../../shots/issue-2094-codex/vanguard_build_sheet_r4.png) shows the port side, top, underside, bow, stern and centreline cutaway at the same scale. Neither is baked paint or a game capture.
