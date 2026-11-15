# Portraits: Eclipse restoration frames (issue 43, R78 Q17)

What to look at:
- `eclipse_restoration.webp`: the four Eclipse admirals at mastery levels 0 (fresh) through 8, then
  level 8 with capstone mastery 3, exactly as `Portraits.face(id, level, capstone)` composits them.

What changed:
- Each Eclipse restoration level (mastery level) now shows on the portrait frame: one white-gold ring
  piece lights per level around the inside of the frame (clockwise from the top), a dark plate layer
  with a gold edge stacks in each corner every two levels, and the white-gold visor slit at the bottom
  frame edge widens and brightens per level.
- Capstone mastery (the lineage cap, up to 3 more levels) adds a thin outer hairline in brighter gold.
- Level 0 is unchanged: a fresh admiral looks exactly as before. Other factions ignore the level.
- The marks are drawn in code from the Eclipse crest palette (white-gold `#f0d690` on violet-black),
  so no new paintings were needed; painted admirals and crest admirals both take the frame.
- Hook: `campaign_ui.gd _face()` passes `masteryLevel` and `capstoneMasteryLevel` for Eclipse
  admirals and caches per admiral, level and capstone, so the pick screen shows the current frame.

Calls Ryan can veto:
- The mark layout (ring radius 0.452 of the portrait, plates tangential in the corners, visor on the
  bottom edge) and the per-level pacing: ring 1/level, plates 1 per 2 levels, visor width per level.
