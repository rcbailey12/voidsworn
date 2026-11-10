# Issue 271: three identities for the battle screen

Opus worker thread, Nov 9 2026. Brief: FINDINGS R148 (Ryan, 10:41 CST: the layout is right, but "it still feels very
similar but maybe that's just the font and colors"). Same C Glass Shell bold layout as the build (PR #314); each identity
changes all three of the typeface, the palette and the panel material. Nothing in the game theme changes until Ryan picks.

**Start with identity_sheet.jpg** (all three, labeled, with close-ups at 1.4x that read on a phone).

| # | Name | The feel in one line | File |
|---|---|---|---|
| 1 | Graphite Signal | A quiet flight-deck instrument: graphite and white, colour only where the data is. | 1_graphite_signal.png |
| 2 | **Lime Tactical (Opus's pick)** | A combat targeting computer: black-olive slabs, cut corners, lime marks what to do next. | 2_lime_tactical.png |
| 3 | White Frost | Bright near-future glass: white frosted cards, ink text, cobalt for the next action. | 3_white_frost.png |

Each also has a 20-ship version (`*_20_ships.jpg`): all 20 fleet rows fit at 1080 with no scroll in all three.

All mockups are 1920x1080 over the same battle capture round 2 used (docs/shots/ship_pipeline/bench207/scene_engagement.webp,
old HUD painted out), in the same moment: round 3, the Move step, Long Watch up with a planned move, the Fire block reading
odds from the planned hex, a Nemesis fight at Heat 3.

## What each one changes

| | 1 Graphite Signal | 2 Lime Tactical | 3 White Frost |
|---|---|---|---|
| Body type | Saira Semi Condensed | Chakra Petch | Exo 2 |
| Display type (round title) | Saira, widest cut, caps | Chakra Petch Bold, caps, wide tracking | Exo 2 ExtraBold |
| Numbers (odds, hull, keys) | JetBrains Mono | Azeret Mono | Red Hat Mono |
| Backgrounds | neutral graphite #0b0c0e to #2e3238, no blue | black-olive #090c09 to #283228 | frosted white panels, white wells |
| Text | cool white #eef0f2, greys #a9aeb5 and #757b83 | pale sage #e8eee0, #a7b09d, #7c8674 | ink #0f1722, #3d4a5a, #627083 |
| The one accent | white #f4f6f8 (End ship is a white slab with black text) | neon lime #c8f53a (black text on lime) | cobalt #2453ff (white text on cobalt) |
| Reserved red (Nemesis only) | #ff4b45 | #ff4433 | #e0261b |
| Friend / foe | spring green #72f0a6 / lavender #bba2ff | green #5ff0a0 / lavender #c4a4ff | dark green #0b8446 / violet #6a3ff0 on panels; the board's labels keep the light set |
| Glass | smoked, untinted, blur and desaturate behind | near-solid matte (80%) with a fine lime scanline | frosted white (72%), strong blur, brightened |
| Edges and corners | 1 px hairline, square, a 28 px white index bar on each frame's top edge | 14 px chamfers on two corners with a lime bevel, lime corner brackets | 10 px rounded frames, 7 px rounded wells, soft drop shadow |
| Backing strips (board labels) | solid graphite, 3 px side bar, square | solid black-olive, 3 px side bar, slanted right end | dark ink strips with 5 px rounding (panels light, board labels dark) |

None of the three uses navy, gold, bone, verdigris, Barlow, Oxanium or Michroma.

## Rules that still hold (ui_spec.md)

- No text under 12 px at 1080. The roster names drop from 15 to 14 because all three faces are wider than Barlow.
- Contrast: every text colour on its own backing is 4.5:1 or better (the dimmest is Graphite Signal's #757b83 on
  its well, 4.55:1; White Frost's cobalt on white is 5.6:1). The bars are graphics, not text.
- Every line of text sits on a solid well or strip; the glass only frames.
- Faction colour stays on the crests (top bar, Nemesis portrait); the friend and foe channel stays green and lavender.
- Focus ring: the menu is not in these stills; each identity's ring would be its text colour (white, sage or ink), 2 px,
  3 px outside the button, as ui_spec.md 6 says.

## Opus's pick: 2, Lime Tactical

It is the furthest from the old look while staying a dark game screen: one loud colour that only ever means "do this
next" (End ship, the armed weapon, the lit step, the ship that is up), angular type that reads as a weapons console, and
near-solid panels that hold up over the brightest nebula. Graphite Signal is the calmest and most legible but risks
reading as a plain dark app again. White Frost is the boldest break, but light panels pull the eye off the board in a
long fight.

Risk to watch on 2: lime and friend green are both green. The friend channel is pushed to a cooler spring green here; if
they blur in play, the friend colour moves toward mint-teal (a palette change only).

## When Ryan picks

The board turns the pick into the theme: glass_shell.gd's palette and boxes, the fonts in godot/ui/theme/fonts/ (the files
and their OFL licences are already in contrib/opus/ui271_mockups/identity/fonts/), and ui_style.md sections 2 to 5. Then
the PC captures in docs/shots/ui_redesign/build/CAPTURES.md run again.

## Rebuild

`sh contrib/opus/ui271_mockups/identity/make_id.sh` from the repo root (python3 with Pillow, OpenCV and Playwright). The
pages are round 2's mockup code fixed to C bold (mock_id.js, base.css) with the identity layer on top (identity.css).
All fonts are SIL Open Font License 1.1 (Google Fonts), licence texts beside them.
