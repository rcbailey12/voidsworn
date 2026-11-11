# Campaign map: the left rail as an orders sheet (R2, picked by Ryan Nov 10 2026)

Written by the Board (Fable 5.2), Nov 11 2026. FINDINGS R174 and R176. The reference picture is
contrib/opus/ui_map_design/rail_options/R2b_orders_sheet_readable_1080.png (a mockup over the real round 3 capture, after the
readability pass Ryan asked for). Build to the picture and to the rules below; where they differ, the rules win.

## What Ryan said

- "there's still something that reads as very much AI generated about the UI."
- "I don't want to stray TOO far from here. I like the actual map itself and where we're going. It's more the lefthand rail, the
  text, etc."
- On the three options: "R2, let's just do a readability pass on it as well. But I like the direction."
- Scope: "Map first, then all": this look is proven on the campaign map, then every other screen follows it in later jobs.

## What made the old rail read as AI-made (do not bring any of it back)

One neon lime accent on near-black slate. A big rounded button with a key badge. Every row the same size, padding and weight.
Tiny grey capitals with wide spacing as labels. A rounded portrait card. Thin progress bars. A filled panel with a hairline edge.

## What stays exactly as it is

The 3D map and everything round 4a builds on it. Every piece of information the rail shows today, and its order. Every behaviour:
hover and keyboard selection, the number keys, Enter to jump, the Map key, the Dossier, Fleet and refits, Save and quit, tips.
The campaign, its saves and its random streams are not touched.

## The look

**Colour (campaign map screen only for now; add these beside the old names in glass_shell.gd, do not remove the old ones yet).**

| Name | Value | Use |
|---|---|---|
| EMBER | #ff8a3a | the one accent: the chosen route's numeral, the action, routes you can take, the current leg |
| TEXT | #f0eade | anything the player must read: names, sentences that state a rule, figures |
| TEXT2 | #c4beb0 | supporting sentences |
| TEXT3 | #969084 | words of one or two syllables that only join things ("Pays", "then", "Dossier"); never a sentence |
| NEM | #ff6050 | the Nemesis only |

The ember is the Hollow Sun's own light: it replaces lime on this screen, on the map too (route ribbons you can take, number
boxes). Nothing else is orange: stop models keep their own fire and light.

**Type.** Three faces, each with one job.
- Big Shoulders Display (OFL; variable weight; google/fonts ofl/bigshouldersdisplay): NAMES only, in capitals: the region, route
  names, the Nemesis, ship names, the action. Weight 700 to 800. Never below 28 px at 1080.
- Barlow Regular and Medium (OFL; google/fonts ofl/barlow): every sentence and every joining word. Sentence case.
- Azeret Mono (already in the game): figures.
Add the font files and their OFL licence texts to godot/ui/theme/fonts/. Chakra Petch stays for the screens not yet moved.

**No panel.** The rail has no filled rectangle and no edge line. The left of the scene is darkened by a smooth gradient: about
92% black at the left edge, fading to nothing at about 43% of the screen width. The words sit on that.

**Square.** Every corner is square. No pills, no rounded cards, no key badges, no drop shadows, no glows on text.

## The layout, top to bottom (sizes at 1080; scale with the UI scale as today)

1. **Approach strip.** Three short bars marked I, II, III and a ring for the star. The current leg is ember and thicker. Beside
   it "Jump 1 of 7" (Barlow Medium 19, TEXT2). This replaces "SECTOR I OF III".
2. **Region.** The region name, Big Shoulders 70, weight 800, TEXT. Under it "Held by the Ashfall Hullbreakers" (Barlow Medium 21,
   TEXT), then the sector condition as a sentence (Barlow 19, TEXT2).
3. **The chosen route, large.** The route under the cursor (keyboard, number key or hover; route 1 by default) is expanded IN
   PLACE; the list always stays in number order. Its numeral in ember (Big Shoulders 132), its name (54), "Fight a ..." or the
   event line (Barlow Medium 20, TEXT), danger as four square pips and the word (never a bar), the objective as a sentence
   (Barlow 20, TEXT), then "Pays X then Y" (19; the joining words in TEXT3, the things in TEXT).
4. **The action**, directly under the chosen route: a square ember outline 2 px, 56 px tall, "JUMP TO RELAY" in ember (Big
   Shoulders 34) on the left, "Enter" and a small solid arrow on the right. On hover or focus it fills ember with near-black
   words. This is the only box on the rail.
5. **The other routes**, two lines each: numeral and name (Big Shoulders 36 and 32, TEXT), then one summary sentence (Barlow 18,
   TEXT2), for example "Fight, easy. Pays Signal of Astra".
6. A hairline, then **the Nemesis**: square portrait 64 px with a 2 px NEM edge; "Nemesis, hunting you" (Barlow Medium 17, NEM);
   the name (Big Shoulders 32); one sentence (Barlow 18, TEXT2); the hunt clock as four square pips with the words "Hunt clock
   0.5 of 4". "Dossier" at the right (TEXT3).
7. At the foot, a hairline, then **the fleet**: one line per ship: name (Big Shoulders 28), class (Barlow 17, TEXT2), "flagship"
   in ember on the flagship's line, hull as a figure with its word ("135 hull"; when damaged "98 of 135 hull" with the first
   figure in the game's existing damage colour). No bars. Then the faction action line and its price.
8. **On the map:** the number boxes and the routes you can take are ember; route and stop labels are Barlow Medium 21 with the
   dark halo; "Your fleet is here" in Barlow 17.
9. **Bottom right:** credits and command points keep their place: labels Barlow, figures Azeret.

## The readability pass (Ryan asked for it; these are checks, not wishes)

- Nothing the player reads is smaller than 17 px at 1080, or lighter than TEXT2. TEXT3 is for joining words only.
- Every sentence and figure on the rail has a contrast of 4.5 to 1 or better against what is behind it, measured on a capture in
  sector III (the brightest backdrop) as well as sector I. If the gradient is not enough there, strengthen the gradient, do not
  add a panel.
- Big Shoulders is never used for a sentence and never below 28 px. No text is set in capitals except names in Big Shoulders.
- Long cases fit without overlap or cut-off words: four routes; the longest route and region names in the game; a Nemesis with
  the longest name; a fleet of the largest size the rail must show (say how many lines fit, and what happens beyond that).
- Captured at 1920x1080 and 2560x1440.

## Deliver

- The build, on the campaign map screen only.
- contrib/opus/briefs/ui_style.md: a new section "Orders sheet (campaign map; other screens follow)" with the table and rules
  above, so the next screens are built from one page.
- contrib/opus/tools/ui_spec_tests.js: checks for the ember accent on this screen, the three faces and their jobs, the minimum
  size, no lime, no rounded corners on the rail.
- Captures into docs/shots/ui_redesign/briefing/rail_r2_1080/ and rail_r2_1440/: sector I, II and III; a four-route stop; each
  route chosen in turn at one stop; hover on the action; the long cases above. A before and after pair for Ryan.
- A report (contrib/opus/reviews/rail_orders_sheet_report.md): what was built, the contrast figures, how many fleet lines fit,
  and anything the Board should rule on.
