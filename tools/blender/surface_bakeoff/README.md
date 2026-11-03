# Issue 75 prototype runner

Double-click `RUN_SURFACE_BAKEOFF.bat` from this checkout. It queues lane A work, uses the existing PC watchdog, and waits if the game is open. Blender 4.5.14 uses OPTIX. Godot 4.7.2 uses the RTX 5080. ComfyUI's bundled Python provides NumPy and Pillow. No downloads or paid tools are needed.

Results go to `docs/shots/ship_pipeline/issue75/`. All intermediate GLBs, Blender files, maps, individual captures and logs stay in `%TEMP%\voidsworn_issue75\`. The runner never writes to game source, the live build or shipping hull folders. Rerunning replaces only this prototype's temp results and review sheets.

`build.py` builds four prototypes. Route B loads the current A4 `<CODE>_ship.npz`, voxel-remeshes it, removes detached debris, smooths with a stable factor, runs QuadriFlow, unwraps UVs and bakes the high mesh into tangent normals. The normal map keeps fine residuals and caps their tilt at about 12 degrees. Colour, roughness, metal and emission come from new faction material rules, without concept pixels. The Maw uses flesh, veins, chitin and bile; its metal channel is zero. Removing debris can also lose small intentional fittings, which is part of the route's visual cost.

Route A authors three joined salvage hull masses in the C19 loft and bevel kit pattern, with a mounted bridge, radiators, forward launcher rack, matched forward/outward guns, ducts, hatches and engines. All parts share one eight-band trim sheet. A contact graph must connect every part to the main hull; gun directions must have a nonnegative bow component. The build refuses disconnected parts, backward guns or failed export round trips.

`run.py` snapshots today's actual packed Godot ships and referenced compressed textures into an isolated temp project. `probe.gd` uses the battle's home camera, ship lengths, G4 lights, sky, AgX and quality settings. Every route gets the same views and scale. Both current and prototype textures use mipmaps and BC7/BC5 compression. Runtime effects, board terrain, damage and game logic are absent, so the timings measure the hull/material routes, not a complete battle. Single-ship and 20-copy tests each warm for 100 frames and retain 360 frames, with an empty-scene control. Frame p99 is a sampled percentile, not a full-run 1% low.

For a retained run, use bundled Python with `run.py --sheets --work <temp-folder>` to recompose sheets, or `verify.py <temp-folder>` to verify all 35 captures, the four exports, the seven timing rows, zero Maw metal and unchanged live ship inputs. `run.py --worker --only CODE:ROUTE` supports a single prototype iteration through the watchdog; GPU work still belongs on lane A.

Source hashes, measured costs, build checks and visual limitations accompany the comparison sheets. The comparison is a route decision, not approval to replace any of the 28 hulls.

The temporary solver scale handles Blender 4.5's absolute edge-length guard in [`mesh_is_manifold_consistent`](https://github.com/blender/blender/blob/blender-v4.5-release/source/blender/editors/object/object_remesh.cc). It does not enlarge the exported ships.
