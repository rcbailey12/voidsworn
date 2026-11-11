# Playbook: screens

Issue 405. Written by the Board (Fable 5.2), Nov 11 2026. Format: docs/playbooks/PROGRAM.md. Use this to design or rebuild one
screen. The worked example is the campaign map's Briefing layout.

## 1. Target

- Ryan, Nov 10, on the first Lime Tactical map: "it's getting pretty busy and it also reads as AI generated still, rather than
  a clear and consistent human designer." His pick from three options: "Briefing is it but I want that merged with the
  graphical quality of the original map, minus clutter and noise of it."
- What he named as the tells of a machine-made screen: too many colours and glows, everything in a box or tag, uneven type and
  spacing. The cure is restraint and one system.

## 2. The system (what every screen shares)

- **Two colours over pale sage text.** Lime means the next action and what it acts on. Red is the Nemesis only. A third
  colour needs a ruling.
- **One filled button per screen**: the lime one that says what happens next, with its key cap.
- **One type ladder** (at the 1080 design height, scaled by the one scale law in contrib/opus/briefs/ui_spec.md): 40 display,
  22 row titles, 20 map labels and names, 15 body, 14 secondary, 13 small caps heads; numbers in the number face. Nothing
  under 12.
- **One spacing grid**: multiples of 8, column padding 40.
- **Boxes are earned.** A flat column with a quiet edge, hairlines between groups, and at most one floating card (a hover
  tip). No chamfers, brackets, scanlines, wells or left bars on a calm screen.
- **Hover, a key or a click holds the detail.** If a fact is not needed to make this screen's decision, it goes behind
  hover, "Map key" or a "Dossier" style overlay. Nothing is deleted from the game: every moved fact is listed with where it
  now lives.
- **Text over a 3D scene**: on the campaign map, plain text with a dark halo (R165); everywhere else it sits on a backing
  (contrib/opus/briefs/ui_style.md section 3).
- **The scene is part of the screen.** Dim it until nothing in the backdrop is brighter than the routes and labels.
- Palette, fonts, key caps, buttons and the focus ring come from godot/ui/theme/glass_shell.gd. A screen adds what is missing
  to the theme, never loose numbers of its own.

## 3. Steps

1. **Name the decision.** One sentence: what does the player decide on this screen? Everything is ranked by how much it
   helps that decision.
2. **Options.** Two or three flat mockups at 1920 by 1080 that differ on real choices (where the list sits, how much is in
   boxes, how many colours), with the same real content in each. The Board makes these on a Design canvas; the generator for
   the map's three is contrib/opus/ui_map_design/mockup_gen.py.
3. **Pick.** Ryan picks, or mixes. Ask what to keep from the present screen before building.
4. **Brief.** One file in contrib/opus/briefs/: his words, the layout with sizes, what stays, what leaves and where it goes,
   the done test. contrib/opus/briefs/campaign_map_briefing.md is the pattern.
5. **Build** in the game from the brief, theme first.
6. **Capture** on the PC at 1080 and 1440: the plain state, a busy state, each overlay, a hover, and a damaged or edge case.
   Look at them at full size against the mockup: alignment to the grid, no overlaps, lime only where it should be.
7. **One image to Ryan**: the new screen beside the old one.

## 4. The checks that prove it

- contrib/opus/tools/ui_spec_tests.js and the standing checks pass; the screen's own read-only test passes (opening a screen
  never changes the run or the save: test the property, not the spelling of a call).
- The "Godot game checks" job loads every script and scene and plays a bot battle.
- Captures exist for every state in step 6, from the final commit.
- The pull request lists every moved item and where it lives, and carries the impact sweep (callers, saves, twins, every UI
  path, which tests ran).

## 5. Traps

- A screen that only reads up close. Ryan, on the map's first in-game capture: "It's hard to read all the stops after the
  first. I'm okay with no text but it's hard to even see the icons right now." Quiet does not mean invisible: dimmed things
  still need an icon that reads (R170).
- A screen that never changes. Same capture: "There's no change when you're going to a new system or getting closer in round
  2 or 3 to the star?" A screen the player sees many times must show where they are in the run (issue 420).
- Cut-off sentences with dots. Give text its room or write it shorter.
- "Only reads" claims that are not true: a draw call that creates a record (Muse's check of PR 349). Use the read-only
  lookups (C.nemRead).
- Captures that are staged but never committed: the picture Ryan judged must be in docs/shots/ from the final commit.

## 6. Worked example

The campaign map: three options (contrib/opus/ui_map_design/), the brief (contrib/opus/briefs/campaign_map_briefing.md), the
build on opus/issue-344 (pull request 349), the finish (issue 418) and round 3 (issue 420: the approach to the star across
three sectors, and stops ahead readable by icon).

## 7. Job template (one screen from a brief)

```
Owner: codex (or an Opus helper at medium effort while Codex is busy)
Brief: contrib/opus/briefs/SCREEN.md; docs/playbooks/screens.md; contrib/opus/briefs/ui_style.md and ui_spec.md
Deliver to: godot/ui/SCREEN/, godot/ui/theme/ (only what the theme lacks), docs/shots/ui_redesign/SCREEN/
Branch: codex/issue-<number>
Effort (Codex): high
Done when: the checks pass with a read-only test for the screen; captures at 1080 and 1440 of every state the brief lists are committed from the final commit; the report lists every moved item and where it lives. What Ryan will see: the new screen beside the old one.
```

One screen is one or two build runs and one or two capture runs, plus one Ryan look.

## 8. Open question for Ryan

Whether the battle HUD takes the map's calmer treatment (program decision 8). Until he rules, the HUD keeps its slabs.

## 9. Seat

The Board designs the options, writes the brief and judges the captures. Codex or an Opus helper builds. DeepSeek does the
well-specified follow-ups (a string, a test, a moved fact). Muse checks from outside before or straight after the merge.
