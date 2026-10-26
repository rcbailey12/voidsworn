# godot/portraits: admiral portraits and crests (owner: music and portraits helper)

R37 and R40: finish the Chorus set first, then one painted poster admiral per remaining faction, crests for every other admiral; Mending Choir as the Living Suture-Hive. Drafts are made with the AI image tools on Ryan's PC (`tools/portraits/`), reviewed on his phone.

## Files

- `crests/<admiral>.svg`: a crest for all 24 admirals (faction frame and colours, glyph for the admiral's Command: barrage, hunt, scramble, iron, surge, restore). No text. Built by `tools/portraits/crests.py`.
- `painted/<admiral>.webp`: the picked painting (1024 px, thin faction-trim frame).
- `alts/<admiral>_altN.webp`: the other candidates, kept for Ryan to swap.
- `index.json`: per painted admiral, the pick and its alternates. To swap, change `pick` to one of the `alts` paths.
- `sheets/*.webp`: contact sheets per faction (for Ryan's phone) and `crests_all.webp`.
- `portraits.gd`: lookup for any screen.

## For G3 and the story helper

```gdscript
const Portraits := preload("res://portraits/portraits.gd")
var tex := Portraits.face("vex")    # painting when one exists, else the crest
var small := Portraits.crest("vex") # always the crest
```

Where faces belong (Sheet 3 of the decision packs): the admiral pick screen, the rival boss fight intro, the story beat cards, the Career tab. Crests everywhere else (map tokens, lists, the battle HUD). Admiral ids are the `data.js` ADMIRALS keys.
