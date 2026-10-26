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

## Nemesis (R42, for stream B)

- Pool: 6 per faction, ids `nem_<faction>_<1..6>` (36 in all), the same painted style as the admirals but lit from below with a red rim light, and a red-black thorned frame (`nemesis/frame_<faction>.png`) so a Nemesis never looks like a named admiral.
- Scars: `scar_<kind>` with kinds `burn` (every faction), `cyber` and `eye` (Voidsworn, Hegemony, Corsair), `carapace` (Chorus), `porcelain` (Ithar), `machine` (Deathless). `nemesis/scars/scars.json` lists which faction takes which kind.
- Call `Portraits.nemesis("corsair", 3, ["burn", "eye"])`: base portrait, then the scars, then the frame. The first scar uses a painted version of that Nemesis with the scar when one has been made (`index.json` nemesis.<id>.baked); further scars are overlays placed at the portrait's face anchor. Add one scar each time a Nemesis survives a fight with you.
- `Portraits.nemesis_ids("corsair")` lists the pool for a faction.
