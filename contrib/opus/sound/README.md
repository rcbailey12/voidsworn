# ElevenLabs sound candidates (issue 1572 follow-up)

Ryan, Nov 22 2026: ElevenLabs Creator, monthly ($11 first month, then $22), for sound redo candidates. Generation now;
wiring into godot/ stays parked until the ship rebuilds are done, and only after Ryan listens.

- `elevenlabs_batch1.json`: batch 1. 3 battle music songs (180 s, each split into stems), 2 reward-screen takes, 1 map
  music bed, then 112 sound effect takes (menus as mechanical clicks and relays, the five ladder steps, deaths, hits,
  faction guns and deaths, map and battle beds). About 34,100 of the 121,000 monthly credits (pricing FAQ: 200 per
  sound effect, 900 per music minute; stem splitting cost is not published).
- `../tools/sound/elevenlabs_gen.js`: makes the files. Resumes safely, stops at a credit cap, writes `manifest.jsonl`
  (prompt, settings, sha256, request id) next to the files. Offline check: `node elevenlabs_gen_selftest.js`.
- Key: Ryan double-clicks `tools/pc/elevenlabs_api_key.bat` once. It saves `VOIDSWORN_ELEVENLABS_API_KEY` as a Windows
  user setting, never in a file. He should give the key only Sound Effects and Music access and a credit cap.
- The cloud cannot reach elevenlabs.io, so this runs on the PC through the Board's queue.
- Outputs are candidates, not game assets. They go to the job's out folder and are relayed for listening; none are
  committed into godot/ until Ryan picks. Licence: ElevenLabs paid plan, commercial; music under the Music Terms
  (Oct 9 2026) "Indie Game" rule; no attribution needed on paid plans. Record the plan and date in the credits when
  a pick is wired in.
- API output: sound effects as MP3 192 kbps (WAV over the API needs Pro); music MP3 44.1 kHz 192 kbps.
