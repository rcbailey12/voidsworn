# Council pack: what every seat reads and sees

## Build under review

One fresh playtest build from main after today's merges settle and the fleet-size fix (issue 1336) is merged. The Board pins
the commit; every picture is stamped "built from <commit>". The pack is not used before that commit exists.

## Pictures and clips (Board queues on the PC, LOOP.md recipes)

1. Playtest exe (LOOP.md "Playtest exe recipe"), then `g2_playtest_capture.bat capture` from it.
2. `tools/pc/jobs/player_path.bat`: two fresh Sunward runs through Battles 1 to 3, player default settings, isolated profile.
   Stamped clip plus the battle contact sheet. This is the first-time player's main evidence.
3. `tools/pc/jobs/frontend_ui_check.bat`: title, setup, faction desks, flagship pick, settings, help, lineage, progression,
   credits, at normal and larger text.
4. Extra stills the Board adds if the capture jobs allow: campaign map at the start of each sector, a reward screen, a shop
   or yard, an event card, a loss screen and a win screen; one battle each as Glasswrights, Hullbreakers, Chorus, Eclipse,
   Hegemony (first turn and mid fight, battle camera 170).
5. Commit all of it to contrib/opus/reviews/council_1120/pack/ on branch claude/project-thread-8hcjwy, stills as JPG at 720 px
   tall or less, clips as short MP4s, each named with its stage and commit. Muse and Fable both read it there.

Ship revisions in the build: B20_11 (Chorus C13 round G), I8_37 (Glasswright CD5) and V14_23 (Sunward S9) match publish
receipts. B19_11, B21_11 and H4_11 are a PC snapshot with no publish receipt, and B19_11 and B21_11 are mid Chorus rollout:
label them "PC snapshot, not an approved revision" in the pack, and no seat treats them as finished art (Artoo, PR 1343).
The Board checks the packaged files against the manifest at the final build pin before the pack goes out.

Sound is not reviewed. Clips go to Fable and Muse with the audio stripped.

## Text

- docs/RULEBOOK.md (rulings in force) and the last 40 rows of contrib/opus/FINDINGS.md (recent picks, so nobody reports a
  ruled choice as a bug).
- docs/playbooks/screens.md, factions.md, scale.md, effects.md, deaths_and_hits.md.
- godot/story/ (README.md, outlines.md, outlines_variants.md, data/), docs/words/ and the in-game help text.
- Faction names: contrib/opus/compute/rename_map_final.md (ids never change; display names do).
- What is already known, so nobody repeats it: contrib/opus/reviews/codebase_audit_1120.md on branch claude/project-thread-r8cctm, PR 1339 (bugs 1336 to 1338), the Neon
  audits in /mnt/project-files/audits/ (front-end UI, weapon fx readability, ship destruction, backdrops, codebase health,
  all Nov 19), Neon's Nov 20 reviews (PR 1380 late campaign balance, follow-ups issue 1384, including the Battle 2 spike:
  teachingBattle 2 forces a Hullbreaker fight with round 3 to 4 reinforcements before the first shipyard; PR 1383 faction
  death styles, follow-ups issue 1385, including five of six factions sharing one death look), and contrib/opus/OPEN_WORK.md. A finding already in one of these counts only if it adds new evidence or says
  the planned fix will not work.
- Godot dev seat also: godot/ (code), godot/project.godot, docs/skills/ (camera, game feel, performance, shaders).
