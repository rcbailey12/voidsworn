# Steam readiness checklist: Embers of the Hollow Sun (draft, Oct 27, 2026)

Status: preparation draft for Ryan and Opus. This is not a store submission. Nothing here has been sent to Valve.
Pinned to repo HEAD 68b42ce406286eb95ea7df6aaf3f683c1231b51d (rcbailey12/voidsworn, fresh clone).
Sources read for this draft: godot/project.godot, godot/export_presets.cfg, godot/ui/battle/brand.gd, godot/main/FEATURES.md, HANDOFF.md, godot/music/CREDITS.md, the font licence files under godot/ui, and the Oct 27 audit and program records. Anything not grounded in those sources is marked TODO.

Game facts used below: title "Embers of the Hollow Sun" (brand.gd TITLE, project.godot config/name). In-game tagline (brand.gd TAGLINE): "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain." PC only, Windows build, Godot 4.7, turn-based fleet tactics roguelite, six factions, campaign runs across three sectors, Nemesis system, 45 hulls and 24 admirals in the Oct 23 content census (TODO: re-count at the shipping build before the page goes live).

## 1. Store text draft

### Short description (about 300 characters)

Embers of the Hollow Sun is a turn-based fleet tactics roguelite. Command one of six factions across a three-sector campaign, refit your ships between battles, capture what you can, and face the Nemesis who remembers you. Every hull you lose stays lost, and so does its captain.

### Long description (draft)

The Hollow Sun is going out, and six fleets are fighting over what it leaves behind. Yours is one of them.

Embers of the Hollow Sun is a turn-based tactics game about capital ships on a hex board. Ships have facings, firing arcs and sections that take damage one by one, so a battle is won by position as much as by firepower: cross a broadside, guard a crippled flank, and decide which ship you can afford to lose. Losses are permanent. A hull that dies in sector one is gone for the whole run, and its captain dies with it.

Between battles you spend salvage on refits, modules and new hulls, and you choose the route through three sectors toward the Hollow Sun. Six factions sail those sectors, each with its own hulls, weapons, admirals and doctrine: the Sunward Crusade, the Hegemony, the Ashfall Hullbreakers, the Chorus, the Glasswrights and Eclipse. One enemy admiral is your Nemesis. Survive them once and they come back stronger, with a grudge and a fleet built to counter yours.

Draft feature list for the page:

- Turn-based hex fleet battles with facings, arcs and per-section damage
- Six playable factions with distinct hulls, weapons and admirals (45 hulls, 24 admirals in the current data)
- A three-sector campaign run with permanent loss of hulls and captains
- Refits, modules, perks and capture between battles, paid for in salvage
- A Nemesis rival who returns across the run and adapts to your fleet
- Every admiral has a doctrine and a Command that match how they fight

### Tag proposal (ordered by fit, all proposals)

Turn-Based Tactics, Turn-Based Strategy, Roguelite, Sci-fi, Space, Spaceships, Hex Grid, Permadeath, Singleplayer, Strategy, Tactical, Indie, Difficult, Replay Value, War

## 2. Capsule and art brief

What the capsule art must show:

- One capital ship at broadside range of another, firing, with the Hollow Sun in frame: the spectacle read has to land at small sizes, silhouette first.
- The title set in the game's display face (Michroma, per brand.gd) and fitted to one line, the way the title screen already handles it.
- A six-faction colour motif is tempting and risky. The Oct 27 palette check found that three factions (Hegemony, the Glasswrights and Eclipse) sit in a pale cluster whose colours separate weakly under normal vision and worse under colour-vision deficiency. So faction identity in key art must ride on silhouette and shape, with colour as support only, never colour alone.
- Screenshots for the page should come from the current Godot build, not the retired browser build, and should include one campaign map shot, one 20-ship battle shot and one refit or shipyard shot. TODO: pick the final set after the effects pass.

Sizes: TODO for every asset. Confirm each current Steamworks size at setup time rather than trusting memory: header capsule, small capsule, main capsule, library capsule, vertical library capsule, page background, and the screenshot minimum size and count.

Verdict rule: Ryan's eye is the verdict on key art, as on all visual work in this project. No capsule ships on a reviewer's say-so.

## 3. Technical checklist

Build and export (grounded in godot/export_presets.cfg):

- [x] One export preset exists: "Windows Desktop", x86_64, output ../export/Voidsworn.exe relative to the godot folder (on the PC that lands in build/export/Voidsworn.exe). The exe file name stays Voidsworn.exe on purpose; the product name and file description inside it already read "Embers of the Hollow Sun".
- [ ] The preset has embed_pck off, so the depot must carry Voidsworn.exe and Voidsworn.pck side by side, plus any other files the export writes. TODO: list the exact export output set from the first shipping-candidate export and check the depot against it.
- [x] Test folders are excluded from the package by the preset exclude filter, and FEATURES.md records a --check-export check for that.
- [ ] Version fields: file_version and product_version both read 0.9.0.0. TODO: Opus to set the release version and a bump rule before the store build.
- [ ] The preset copyright field is empty. TODO: fill it before release.
- [ ] Code signing is off in the preset. An unsigned build will draw Windows SmartScreen warnings for direct downloads; Steam delivery softens this but does not remove it. TODO: Ryan and Opus to decide whether to sign.
- [ ] Export templates: the preset names no custom templates, so the exporting PC needs the stock Godot 4.7 templates installed and matched to the editor version. TODO: verify on the PC at export time.

Exe smoke test status (checked for this draft):

- The Oct 27 full audit flagged "the Windows exe has never been smoke-tested" as an open item. That has since landed. FEATURES.md (godot/main/FEATURES.md, Windows build row) records the launch test done at fa8106d: the exe opened through play_godot.bat to the title screen and into a quick battle, and the console exe ran 2 bot campaigns with 0 errors and 0 softlocks. HANDOFF.md's G2 row independently records an exe launch test at ef5cab2.
- [ ] Still owed: the same launch test on the actual shipping build, after the final export, since both recorded tests ran on test builds. A store build that has only been bot-tested in the editor is not a tested build.

Steamworks setup (nothing below exists in the repo; all TODO):

- [ ] TODO: Steamworks partner account, app creation, app id and depot id.
- [ ] TODO: depot build steps (SteamPipe or the Steamworks build tooling), install directory name, and a launch option pointing at Voidsworn.exe.
- [ ] TODO: Steam content survey and any rating questionnaires Steamworks asks for at page setup.
- [ ] TODO: minimum and recommended system requirements. These cannot be written yet. The project renders Forward Plus at a 1920 by 1080 viewport (project.godot), which is a hint, not a spec. HANDOFF.md's G4 row records that the 20-ship bench found a 1 percent low of 15 fps and a 4.3 second freeze on a death at 20 ships, that the fix landed in 2aac0ca, and that a re-bench is still needed to confirm it. Requirements wait on that re-bench plus a pass on a genuinely low-end machine.
- [ ] TODO: Steam features scope. If achievements or cloud saves are wanted, HANDOFF.md already flags the precondition: "check X18, the GodotSteam licence" before Steam work starts. Saves currently live in the pinned user folder (project.godot custom_user_dir_name keeps the old Voidsworn folder, so test-build saves carry over); a Steam Cloud path mapping is a TODO only if cloud is in scope.
- [ ] TODO: Steam Deck. Nothing in the repo tests it. Ryan's call whether to test, claim compatibility, or ignore it at launch.

## 4. Licence credits draft

Ready to paste, with the source of each line. The in-game credits screen already has its data source: godot/music/music.json stores a credit.attribution string per track, and godot/music/CREDITS.md is the full table (generated by tools/music/process.py from tools/music/selection.json; edit the selection, not the generated file).

Game and engine:

- Embers of the Hollow Sun, a game by Ryan Bailey. (Source: export_presets.cfg company_name "Ryan Bailey". The store page developer name is Ryan's decision, section 5.)
- Made with the Godot Engine (godotengine.org), MIT licence. TODO: paste the engine copyright and licence text from the licence file that ships with the Godot 4.7 export at build time, rather than retyping it.

Music: 24 tracks, all from OpenGameArt.org, all edited for looping and level (source: godot/music/CREDITS.md). Licence split: 16 CC0 1.0, 4 CC BY 3.0, 4 CC BY 4.0. The CREDITS.md licence check records that all 17 source pages were read on Oct 26, 2026 and read again on Oct 27, 2026, and matched. The full audit spot-checked five OpenGameArt pages live and all matched.

The eight CC BY tracks are the mandatory credit lines (exact attribution strings live in CREDITS.md and music.json; short forms here):

- "Tactical Thinking", "Dark Times" and "Heat of the Battle" by NorthFantasyMusic, CC BY 3.0
- "Chapel of Hate" by FoxSynergy, CC BY 3.0
- "Dark Ambient Drone" by Tsorthan Grove, CC BY 4.0
- "VICTORY (Fanfares)", "WIN AGAINST CHAMPION (Fanfares)" and "LOSE (Fanfares)" by Spring Spring, CC BY 4.0 (the Fanfares page offers several licences; these tracks are used under CC BY 4.0 only, per CREDITS.md)

The 16 CC0 tracks need no credit by licence; the game credits them anyway in CREDITS.md and music.json, including the courtesy mentions authors asked for (SRG774 appreciates a mention; skrjablin appreciates credit by name). Keep those courtesy lines.

Fonts (all SIL Open Font License 1.1; licence texts ship in the repo):

- Michroma: godot/ui/campaign/fonts/OFL_Michroma.txt
- Oxanium: godot/ui/campaign/fonts/OFL_Oxanium.txt
- Barlow Semi Condensed: godot/ui/battle/fonts/OFL_Barlow.txt

Sound effects: synthesized in project (godot/audio/build/render_synth.js and render_ambient_bed.py). No third-party licence file for audio effects was found in the repo.

Art: ship models and portraits are produced inside this project and its tools. No third-party art licence file was found in the repo. TODO: one explicit sweep before launch confirming no stock or marketplace asset is in the shipping build without a licence line. This check is not a formality: project research on Oct 24, 2026 found Quaternius packs are licensed QAL v1.0, not CC0, so any pack sourced there needs its licence honoured or the asset replaced.

Not a game credit: docs/skills/LICENSE-apache-2.0 covers a skills document, not game content, and does not belong on the page.

## 5. Decisions Ryan still owns (open fields, deliberately not filled in)

- Price: ______
- Release timing relative to the Godot cutover (HANDOFF phase G5) and to Ryan's playthrough sign-off of the Godot build: ______
- Demo: yes or no ______
- Early Access or full release: ______
- Developer and publisher name as it should appear on the page: ______
- Steam features in scope (achievements, cloud saves, neither): ______
- Capsule and key art final approval: Ryan's eye, no delegate ______

## 6. Pre-launch risk list (open items verified for this draft)

1. Shipping-build smoke test still owed. The exe launch test is proven on test builds (fa8106d, ef5cab2) but the store build gets its own final export, and that exact build has to be launched, played into a battle, and run clean before upload. See section 3.
2. Performance floor unproven. The 20-ship bench fix (2aac0ca) has no confirming re-bench yet (HANDOFF.md G4 row), so minimum system requirements cannot be honestly written and a low-end player experience is unmeasured.
3. Data re-pins land before the shipping export, or the store build ships stale names. HANDOFF.md's G1 row lists the post-strings-step work as still to do: re-pin, re-export, update the godot/rules rows, re-run parity. The rollout renamed the game and half its vocabulary on Oct 27; the shipping export must be cut after those re-pins, not before.
4. Cutover and sign-off still ahead. The Steam build is the Godot build, and the Godot version becomes the game only at the cutover, with Ryan's play-through as the sign-off for the playable battle. A store page can be drafted now; a release date cannot be promised off the test builds.
5. Audit FIX disposition pending. The Oct 27 program's own audits (text, kit, admirals, events, HUD) were still landing when this draft was written. Their FIX-level findings are Opus's to disposition before the build freezes; none found so far blocks testing on Ryan's return, but the freeze should not happen ahead of the disposition pass.
6. Colour-only faction reads. The palette finding in section 2 applies to screenshots and capsule art as much as to the game itself: marketing art that tells factions apart by colour alone will mislead roughly the players the game itself would.
7. Shared save folder. The shipping exe deliberately keeps the old Voidsworn save folder so Ryan's saves carry over. That is the right call for testing; note it means a Steam install and the PC test build read the same saves, which matters for any future cloud-save mapping.
