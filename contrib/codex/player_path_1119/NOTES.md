# Player-path recorder

Run `tools\pc\jobs\player_path.bat` on the PC with a shared Windows install that includes the recorder. The launcher
uses `Downloads\voidsworn_test\build\export` by default. To use a particular branch's installed build and choose the output
folders, pass the export folder, an unused full recording folder, and the review folder in that order. The installed pack
needs the ordinary export's `res://build_info.json` revision metadata from a clean commit.
Pass seed `10`, `31` or `121` as the fourth argument to rerun just that route. The default run records `31` and `10`.
The launcher retries once if the first map jump times out before Battle 1.
Use a new review folder when keeping earlier media, such as `shots\run2` under the issue's output folder.

The launcher uses the PC's Python with Pillow and FFmpeg. It finds FFmpeg through `FFMPEG`, the PATH, or the installed
`imageio_ffmpeg` package. Every seed and retry gets a new app data folder under `%TEMP%`. Before the game reads settings,
the recorder checks where `user://` resolved and claims the fresh profile. Settings, teaching history, campaign and career
then use the usual `user://` paths inside that folder. The run log includes the resolved path and effective settings.
The launcher clears inherited `VS_*` test overrides for the game, including any external world cache path.
The recording window is 1920 by 1080. Godot Movie Maker records the normal viewport and audio at 30 frames per second.
The launcher runs the game through `tmo.bat`, one shared GPU slot per seed.

The driver opens New run, takes the normal map and reward actions, and uses the same battle controls as a player.
It reads reach, odds, objectives and the visible battle state to choose inputs. It records presentation cues on the
movie frame clock. The fresh-run teaching rules pin the first two opponents. The sector faction and third opponent
are Hegemony Navy with seed 10 and Ashfall Hullbreakers with seed 31. Both second battles use the relay and its
teaching reinforcement.

Routes (issue 1457). Each seed has planned stops. When a planned stop is not an offered battle, the recorder writes a
`route_drift` row with the whole offer and takes the best offered battle instead (Battle 2 a relay hold, Battle 3 the
sector enemy, a rout first). The console prints `ROUTE DRIFT` and the closing line counts the drifts, so a changed map
shows up in the run. Add `--player-path-strict` after `--` to fail on drift instead. Seed 10 drifts once on Nov 21 main:
its planned 2-2 became an event stop, so it fights the Navy flagship battle at 2-1.
Seed 121 is a diagnostic, not an acceptance route: its only Battle 3 is a relay hold against a Hullbreaker hulk-carrier
and two raiders, and the scripted player loses it on Nov 21 main. Keep it to see whether that fight changes.
Each battle also writes one `round` row per round (every ship's hex and hull, the objective score), so a lost or stuck
battle can be read without the video. The recorder steers around blocking terrain, reads a teaching card that opens
during a preview before confirming, plans a move again once if the preview drops it, and takes a new ship as a prize
before a refit.

The build hash is SHA-256 of the installed `Voidsworn.pck`. The manifest hash is SHA-256 of the
`res://gen/manifest.json` read from inside that pack. Provenance also includes the source commit. The encoder verifies
the JPGs and MP4s through `tools/picture_provenance.py verify` as it writes them. The contact sheets and clips use the
battle's own clock. The two 1080p AVI masters keep
the opening menu and the campaign screens between battles. The JSONL beside each master records the source frame
of each cue, including the start and release of each cut-in.
