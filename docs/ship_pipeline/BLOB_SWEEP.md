# Blob sweep: the "done" check for every AI ship

Owner (Ryan, Oct 21 2026): "ensure we catch all of those for all other ships." A ship is not shown to Ryan until it passes this.

## 1. Review grid (9 cells)

Render the ship (studio, `render_multi.py`) and put each render next to the same region of the concept painting and the generated views:

|            | top | side | below |
|------------|-----|------|-------|
| **bow**    |     |      |       |
| **midship**|     |      |       |
| **stern**  |     |      |       |

Each cell gets a verdict: **clean** or **rebuild by hand**, with the part named. Write the grid into the ship's row in `SHIP_QUEUE.md`.

## 2. Rebuilt by default (the AI reliably mangles these)

- Guns of any size: turrets, casemates, long cannons, bow chasers, stern guns. Also rocket racks and launchers.
- Bridge and superstructure tiers, masts, funnels, antennas, rails.
- Tanks, drums, torpedo or fuel cylinders, lamps and light rows.
- The bow: usually wavy. Rebuild it as a faired loft from the AI hull's own measured sections.
- Engine nozzles and ventral thrusters.
- Armour plate stacks and side sponson blocks.
- Thin spiky or crossed sticks: AI wire debris. Delete them, or replace them with the real part.
- Leftovers: when a part is rebuilt, check that the AI original is fully gone. On the Pyre-Barge an old gun barrel survived next to each
  new one, which broke the matched pairs.

## 3. Placement rules

- Snapped onto the real hull surface: never floating, never sunk.
- On a visible mount: plate, ball, saddle or column.
- Guns aim out and away from the hull. Bow guns may face forward along the prow, stern guns aft. Never aimed back into the ship.
- Matched, symmetric pairs at sensible hard points.
- **Corsair exception:** haphazard and junky is on-brand, and paint mismatches between parts are fine there.

## 4. Paint

- Parts the pictures show clearly are painted by projection.
- Parts the pictures barely show keep hand paint with grime (`project_paint.py` `KEEP` boxes). This covers tops, undersides, and racks
  seen end-on. On the Pyre-Barge the projected rocket rack came out "a grey blob, like an unpainted tabletop model".
- Colours are sampled from the concept by eye, in linear values.

## 4b. One level of detail across the ship

Owner, Oct 21: "the level of texture and details seem to vary wildly". Hand-built parts must carry the same density of surface detail as
the AI hull: panel seams, fine grit, worn edges (project_paint.py adds these to every kit part by default). Check the seam between a
rebuilt part and the AI hull at close zoom: neither should look smoother or busier than the other.

## 5. In-game check

- Shots on desktop and phone, at zoom 1.0 and 0.5, on at least two maps.
- Look for:
  - black faces (lighting or normals);
  - parts missing (load errors in the log);
  - the ship's size against the old one (bounds);
  - brightness against the hull;
  - the seam between rebuilt parts and the AI hull.
