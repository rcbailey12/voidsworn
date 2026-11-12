# corsair_A16 build sheet: the Warlord's Pyre-Barge (round 3)

Ashfall Hullbreakers flagship, class Battle-barge, **26.0 world units** (godot/render/hull_table.gd CLS_LEN; data.js c_boss).
Version 3, 2026-11-11, after Ryan's review of round 2 (R217: tubes as circles, guns blocking the rockets and in front of an
engine, engines and guns plain tubes) and his scaling rule (R218: whole-ship fidelity), with turrets that turn (R219).
Designer of record: Opus (R205, R207). Rendered on Ryan's PC (Blender 4.5, GPU), blockout
`C:\Users\rcbai\Downloads\voidsworn_test\opus532\r3d\corsair_A16\corsair_A16_blockout.blend`.

![corsair_A16 preview](preview.jpg)

Start here: **[side_by_side.jpg](side_by_side.jpg)** (concept left, blockout right, same camera, full view then bow,
midships and stern at the same windows), then [fit_view.jpg](fit_view.jpg) and [cells.jpg](cells.jpg).

- [sheet.jpg](sheet.jpg): beauty and blockout, true side, top, underside, bow-on, engine end, INSIDE cutaway, feature table,
  changes, then the fit view and the nine cells.
- [inventory.md](inventory.md): the parts inventory written from the concept before modelling (R218), ticked per blob-sweep
  cell from the model: 41 lines, every one present, shaped by its kit part type and detailed (every sub-part modelled).
- [fit_report.md](fit_report.md): the fit check (RULEBOOK 5.15): 38 clashes on the round 2 layout (16 clash, 11 turret sweep,
  10 exhaust, 1 exit: the rack covered by the bunker turret), each fix, and **zero left** in round 3.
- [feature_table.md](feature_table.md), [manifest.json](manifest.json) (routes, the turret pivots and arcs), [checks.json](checks.json),
  views: [side](side.jpg), [top](top.jpg), [underside](underside.jpg), [bow-on](bow.jpg), [engine end](stern.jpg),
  [cutaway](cutaway.jpg), [three-quarter](threequarter.jpg), [outline overlay](outline_check.jpg).
- Design source: `tools/blender/build_sheets/ships/corsair_A16.py`; inventory `ships/corsair_A16_inv.py`; part shapes
  `tools/blender/kits/hullbreakers/parts.py`.

## What round 3 changed

1. **The front tubes** are deep tubes with hooded rolled lips, dark bores going back 2.5 units and clamp bands, jutting 1.3
   ahead of a shorter, faceted prow cap under a two-step brow, a ribbed spine between them (the concept's cluster).
2. **Every part is its real shape**, from the Hullbreakers kit: engines are bells with a throat, an ember lining, an inner
   cone, cooling rings, gimbal struts, a banded housing and a mount collar; turrets have a ring and bolt ring, a faceted
   housing with a glacis and bustle, a mantlet on trunnions, breeches, barrels with recoil sleeves, clamps, muzzle brakes and
   dark bores; casemates have an armour plate, a box sponson and a ball mantlet; the rack is a framed box of ten cells with
   rocket noses set back in them, side cheeks, a yoke and a slewing ring; dishes have ribbed backs, rims and feed horns on
   struts; claws have hinge drums, armoured segments, joints, rams and hooked fingers; chains are real links. Hull plates
   carry thickness steps, bevels and corner rivets and are cleared under every mount.
3. **No gun blocks the rockets**: the round 2 bunker turret is gone; the rack sits on a plinth, pitched 12 degrees, every cell
   clear over the deck boxes and dishes; the flak superfires from the castle front (T1) and a bridge barbette (T2).
4. **Turrets turn (R219)**: each turret is a pivot `<id>_turret` at its ring centre with `turret=1` and its data.js arc;
   the middle deck-edge turret on each side superfires on a barbette so neighbours never meet when trained aft.

## What still differs from the concept, and why

- **Surface density.** The concept is covered in small torn plates, rivet rows, grime and red glow. The blockout has plates
  with steps and rivets at a coarser size and flat colour: texture and wear are the paint stage (recipe 4 and 5), and the
  plate size is a kit setting the build can tighten.
- **The big port engine** in the concept is a short fat drum with many radial fins round a fire-filled bell; ours is a bell
  with three cooling rings and struts. Same part, plainer: the fin ring is a kit addition for the build.
- **The rack** in the concept is a bundle of round tubes; ours is a framed box of round cells. Same read from above; the
  bundle is a variant the kit can add.
- **The castle** in the concept is taller and busier (stacked boxes and sloped plates); ours keeps the concept's tiers with
  slits and hatches, fewer boxes.
- **Guns** are matched batteries by slot (R213) where the concept scatters them; barrels are a little shorter than the
  concept's so neighbours clear each other when they turn.
- **Tube lip notch**: the concept's lower-lip notch is left for the build's kit pass.
