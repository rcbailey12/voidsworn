# Weapon kit masks, issue 367

`make_kit.py` is the complete source. Run it with Python and Pillow.
Both tools are free. The game loads the PNG files; Ryan needs no Python.

| File | Use | Source and licence |
|---|---|---|
| hot_tail.png | Separate hot head, cooling particle history and soft halo | Original project work, same licence as the game. No downloaded sprite. |
| beam_flow.png | Independently scrolling core and turbulent sheath | Original project work, same licence as the game. No downloaded sprite. |
| lit_flake.png | Small filled facets with a lit edge, without cross arms | Original project work, same licence as the game. No downloaded sprite. |

The tail is a fixed-seed particle bake. Beam flow is a periodic painted mask.
The flake is a five-sided painted mask. These are masks rather than colour
palettes; runtime faction colours still come from faction_looks.json.
