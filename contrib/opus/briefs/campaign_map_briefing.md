# Campaign map: the Briefing build (Ryan's pick, Nov 10 2026, FINDINGS R165)

Ryan on the Lime Tactical map of PR 349 (R164): "I really like the concept but it's getting pretty busy and it also reads as AI
generated still, rather than a clear and consistent human designer." He was shown three options and picked C: "Briefing is it
but I want that merged with the graphical quality of the original map, minus clutter and noise of it."

The picture of the layout is contrib/opus/ui_map_design/map_option_C_briefing.jpg (a flat mockup; its generator is
mockup_gen.py beside it, with every size and colour as plain numbers). The picture of the scene quality to keep is
docs/shots/ui_redesign/rollout1/1080/01_map.jpg. This build is the mockup's layout over the real 3D scene.

## What Ryan chose (his answers, word for word where quoted)

- Keep from the original: "3D models at the stops, The black hole itself, Curved glowing routes, Nebula and starfield".
- Backdrop: "Dimmed about half": still clearly the same scene, but it stops fighting the routes and the text.
- Stops you cannot jump to yet: "Small dim models": every stop keeps its 3D model, smaller and darker; names only on hover.
- Names and danger only on your stop and the next jumps; the rest on hover.
- The Nemesis block is a portrait, a name and two or three lines; details on a click.
- The tells to remove: too many colours and glows, everything in a box or tag, uneven type and spacing.
- Reference feel: BattleTech's star map for the briefing column, EVE Online and Sins of a Solar Empire for the map.

## The screen

All sizes are at the 1080 design height and follow the one scale law (ui_spec.md). Use the theme (godot/ui/theme/glass_shell.gd)
for palette, fonts, key caps, buttons and the focus ring; add what is missing to the theme (a flat column, a plain text button,
a map label with a dark halo, the danger pips), never as loose numbers in the screen.

### Left: the briefing column (480 wide, full height)

One flat solid column (INK-like fill, a 1 px quiet edge on its right). No chamfers, brackets, scanline, wells or left bars on
this screen. Padding 40. Spacing on an 8 px grid. Top to bottom:

1. One line in the number face, 13: "SECTOR I OF III" and "JUMP 1 OF 8" (real values).
2. The sector name, display face, 40.
3. One or two lines, 15, secondary colour: who holds the sector and the sector condition in one sentence each
   ("Held by Ashfall Hullbreakers. Ion season: shields recharge 25% slower on both sides.").
4. A small caps head "ROUTES FROM <the stop you are on>", then one row per next jump, numbered 1, 2, 3 in the number face (30):
   - the stop's name (22, semibold); at the right the danger as four pips and its word (Easy, Even, Hard, Deadly), or
     "No fight";
   - one line (15): what it is and against whom ("Fight against a Glasswrights picket", "Event: anything can happen");
   - one line (14): "Reward <reward>" and "Then <the stops this route leads to>", from the real map edges.
   The picked row has a slightly lighter fill and a lime number. Pick by clicking a row, pressing its number key, or clicking
   or hovering its stop on the map. The first route is picked when the screen opens. Everything the old fight card said that
   is not on the row (the long objective text, the archetype line) shows under the list for the picked row only, two lines at
   most; nothing a player needs to choose a route may be lost.
5. The one filled lime button: "JUMP TO <NAME>" with the Enter key cap. It is the only filled lime thing on the screen.
6. The Nemesis: portrait (88), the red caps word NEMESIS, the name (20), one line (faction, and the persona in one sentence),
   the hunt clock as four pips and "0/4". A plain "Dossier" text button opens everything the old long block said (strengths,
   the patient or cruel text, comeback, weaknesses, the meeting rule), unchanged in wording, in an overlay or a slide-over.
   Red is used here and on the map's Nemesis marks, nowhere else.
7. Bottom of the column: the fleet, one row per ship (flagship star, name, class, a short hull bar, hull numbers in the
   number face), a plain "Fleet and refits" text button (the existing page), and one line for the faction action with its
   cost. A full hull bar is pale sage; a damaged one uses the HULL colours.

### Right: the map (the real 3D scene)

- The scene stays: the black hole and its disc, the nebula and starfield, the 3D models at the stops, the curved routes.
- Backdrop (nebula, stars, dust, embers) at about half its present strength. The orbit rings drop to a faint hint (a few
  rings at about 5 percent), or go if they still read as noise in the capture.
- Your stop: its model at full size and brightness, a label under it: the name (18) and "Your fleet is here" (14).
- Next jumps: full models; a square lime number marker (34, the same 1, 2, 3 as the list; the picked one filled lime with dark
  text, the others outlined) and the name beside it (20, semibold). No danger tag on the map: the list carries it.
- Stops further on: the model at about 70 percent size and about half brightness. No label, no tag, no ring. On hover or
  keyboard focus, one small tip card (name, kind, danger pips and word or the one-line note, and "The Nemesis meets you here"
  in red where true). The tip is the only box on the map.
- Stops behind you or cut off: dimmer still.
- Nemesis meeting stops: one small red diamond above the model. Nothing else.
- Routes: the routes to the next jumps are lime, solid, no bloom or glow halo. Every other route is one thin pale line (about
  20 percent), and cut-off routes fainter. No blue routes.
- Text on the map is plain with a dark halo, no strip or tag behind it. This is a campaign map exception to ui_style.md
  section 3; write it into ui_style.md in the same pull request.
- Top right of the map, plain text buttons: "Map key" and "Save and quit". Bottom right: Credits and Command points in the
  number face (28).

### What leaves the screen (and where it goes)

- The four top cards (hostile presence, rival raiders, sector condition, cores in range): holder and condition move to the
  header lines; rival raiders and cores in range move into the Map key overlay under "This sector".
- The legend row and the bottom help line: into the Map key overlay.
- "Map detail" and "Tips": into the Map key overlay.
- The bottom-left fight card: replaced by the route rows.
- All danger tags and name strips on far stops: on hover only.
- Faction-coloured names in body text: plain text colour.

Nothing is deleted from the game: every fact that was on the old screen is one click or one hover away, and the brief's list
above says where. The pull request text lists each moved item and where it now lives.

## Also in this pull request (Muse's check of PR 349, contrib/muse/reviews/opus_check_349.md)

1. campaign_view.gd must only read: use C.nemRead (merged in PR 399) wherever the map, the route rows or the old fight cards
   asked nemNodeIs or nemActive, and make the test check the property (opening the map never creates or changes the Nemesis
   record or the save), not the spelling.
2. The three map detail lines Muse found with no backing (map3d.gd 717, 727, 736 at the time): each is either gone in this
   layout or carries the halo. Say which.
3. Add the missing ui_style.md section 5 rows (DANGER, STOP, BLUE, ROUTE, SHADE), or remove the names that this build retires.

## Done when

- The checks pass (node contrib/opus/tools/run_all_checks.js, parity, the campaign UI tests), with a read-only test as above.
- PC captures at 1080 and 1440 from tools/pc/jobs/ui344_rollout_shots.bat (extended as needed), in
  docs/shots/ui_redesign/briefing/: the map at jump 0; the map mid-run with three next jumps; a far stop hovered; the Dossier
  open; the Map key open; a damaged fleet. One before and after sheet: 01_map.jpg of rollout1 beside the new map at 1080.
- What Ryan will see: the Briefing layout over his real 3D map, calmer, with one lime button.
