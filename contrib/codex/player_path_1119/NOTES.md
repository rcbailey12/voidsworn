# Player-path recorder

Run `tools\pc\jobs\player_path.bat` on the PC with a shared Windows install that includes the recorder. The launcher
uses `Downloads\voidsworn_test\build\export` by default. To use a particular branch's installed build and choose the output
folders, pass the export folder, an unused full recording folder, and the review folder in that order. The installed pack
needs the ordinary export's `res://build_info.json` revision metadata from a clean commit.
Pass seed `10` or `121` as the fourth argument to rerun just that route.
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
are Hegemony Navy with seed 10 and Ashfall Hullbreakers with seed 121. Both second battles use the relay and its
teaching reinforcement.

The build hash is SHA-256 of the installed `Voidsworn.pck`. The manifest hash is SHA-256 of the
`res://gen/manifest.json` read from inside that pack. Provenance also includes the source commit. The encoder verifies
the JPGs and MP4s through `tools/picture_provenance.py verify` as it writes them. The contact sheets and clips use the
battle's own clock. The two 1080p AVI masters keep
the opening menu and the campaign screens between battles. The JSONL beside each master records the source frame
of each cue, including the start and release of each cut-in.
