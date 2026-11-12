# UI style guide: the orders sheet (issue #271)

Lime Tactical on the Glass Shell layout (sections 1 to 8 of this file until Nov 11 2026) is retired (Ryan, R191: "Retire
lime"; RULEBOOK 9.1). Those sections, with their numbers unchanged, are in docs/archive/briefs/ui_style_lime_tactical.md:
code comments that cite "ui_style.md 2" to "ui_style.md 8" mean that file. The live look for every screen is the section
below and docs/playbooks/screens.md section 2.

## Theme names still in glass_shell.gd from the Lime build

Screens not yet rebuilt in the orders sheet still draw these names from godot/ui/theme/glass_shell.gd; a new screen does not
use them. Their values and the rest of the old palette are in the archived file, section 5. The standing UI checks
(contrib/opus/tools/ui_spec_tests.js) read this table.

| Name | Kept for |
|---|---|
| BLUE | B4 blue event options (the event dialog only) |
| SHADE | the dim layer behind a dialog and behind the map's two slide-overs |
| COLUMN, HAIR | the campaign map's flat column, its slide-overs and the hover tip; their quiet edge and rules |
| ROW_LIT, ROW_HOVER | the picked route row; a route row under the pointer |
| HALO | the dark halo under plain words on the campaign map |
| PALE, PALE_CUT | a route on the map you cannot fly yet; a route cut off or already flown |

The campaign map exception (Ryan's pick of the Briefing layout, R165) still holds: words on the map are plain text with a
dark halo (`halo_text`), with no strip or tag behind them. The orders sheet below keeps it ("with the existing dark halo").

## Orders sheet (campaign map; other screens follow)

Ryan picked R2 (FINDINGS R174, R176) for the campaign map, then the same look for the battle screen (E1 Ledger, R210), and retired lime everywhere (R191). Screens not yet rebuilt still show Lime Tactical in code until their own job (including the Fleet screen that holds the moved faction purchase); every screen built from now on follows this section.

| Name | Value | Use |
|---|---|---|
| EMBER (GS.MAP_EMBER) | #ff8a3a | Chosen route numeral, jump action, available routes, number boxes, current approach leg |
| TEXT | #f0eade | Names, rules, figures |
| TEXT2 | #c4beb0 | Supporting sentences |
| TEXT3 | #969084 | Joining words only, such as Pays; empty pip outlines |
| NEM | #ff6050 | The Nemesis only |

The older GS.EMBER token remains unchanged for other screens. The map uses GS.MAP_EMBER. Stop models retain their own light and faction colors.

- Big Shoulders Display variable, weight 800: capitalized names, route numerals and the action only. Region 70, chosen route name 54 and numeral 132, other route names 32 and numerals 36, Nemesis 32, ship names 28, action 34. Names wrap whole words and fit down to 28, never below it.
- Barlow Regular and Medium: sentences, labels and joining words, in sentence case. Body 18 to 21, never below 17 at the 1080 design height. Azeret Mono: hull, hunt clock and purse figures. Fonts and their OFL texts live in godot/ui/theme/fonts/.
- No rail panel or edge. A smooth black veil covers the scene below the words, 96% black at the left edge, 94% under the rail, fading to clear by 43% of the window. The stronger veil is the readability pass. Map words sit above it, with the existing dark halo.
- Every corner is square. No pills, key badges, rounded portraits, text glow or text shadow. The action is the only rail box: a 2 px ember outline, 56 px high, filled ember with dark words on hover or keyboard focus.
- The approach strip uses three bars and I, II, III, a ring for the star and a sentence case jump count. Region, holder and one short condition follow. The Map key keeps every condition's full wording.
- Routes always stay in number order. The picked route expands in place with its danger pips and word, one objective sentence, Pays and the reward, then its action. Other routes take two lines. Future stops are shown by the map, without a then line on the rail.
- The square 64 px Nemesis portrait has a 2 px NEM edge. Name and hunt pips remain on the rail. Traits, persona and the longer status explanations live in the Dossier.
- Fleet names and hull figures occupy separate columns, without classes or bars. An ember diamond marks the flagship. Damaged hull uses the existing damage color. Up to seven standard 36 px rows fit at the foot. The rail reserves the full route group first, then fits whole fleet rows into the space left. Extra rows, and names wrapping to multiple lines, scroll in the fleet area. The upper route group can scroll for extreme combinations without moving the fleet off screen.
- The faction purchase lives at the top of Fleet and refits: name, effect sentence, price or Used this sector. The same factionVerb action and affordability check govern it; its explanation remains in the Map key.
- Route and stop labels use Barlow Medium 21 with the dark halo, and Your fleet is here uses Barlow 17. Purse labels use Barlow and figures use Azeret Mono.
- Every sentence and figure on the rail must measure at least 4.5:1 against captured backgrounds from sectors I and III. Capture at 1920x1080 and 2560x1440, with four routes, each selection, action hover/focus, long names and an overflowing fleet. Use res://ui/campaign/rail_orders_shots.gd to repeat those captures. The fixture names explicitly distinguish long-name and fleet stress states from the real seeded run.
