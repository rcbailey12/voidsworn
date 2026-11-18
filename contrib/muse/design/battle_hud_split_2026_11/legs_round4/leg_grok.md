# Issue 1006 round 4, Grok leg (log relocation, faction silhouettes, odds clarity)

Model gate: Grok, free grok.com, Fast mode, verified in the picker before the pack was pasted and again after the answer completed. New chat, pack pasted as text. Run Nov 17, 2026. Filed verbatim below; the raw answer contained 0 em or en dashes, normalized to hyphens per the repo rule.

Log verdict and share accounting
    
    Default home for the log is candidate A: a floating patch above the right end of the shelf. It sits on a lighter veil than the shelf itself (roughly 40 to 50 percent opacity versus the shelf's denser 70 to 80 percent, so the map and fleet strip remain readable through it). The log is optional by toggle or collapse; when closed it leaves only a thin residual strip or a single glyph cue so the player can reopen it. Content stays outcome lines plus the rare spoken taunt. Default state is open for the first few engagements of a session, then remembers the player's last preference.
    
    Candidate B (top left, extending the turn cluster downward) is the loser. Its cost is vertical pressure on the turn cluster and objective line, plus the need to reflow or truncate those elements when the log grows; it also competes with any future top-left status or warning text and forces the log into a denser, less transparent treatment that fights the existing cluster's readability.
    
    With the log removed, the shelf expands from 216 design px to 248 design px. Order glyphs reach their full 32 px size, the integrity unit and range bands widen, and internal row heights increase enough to reduce the previous crowding. Screen share at 1920 by 1080 becomes approximately: expanded shelf 23 percent, top clusters (turn plus objective) 8 to 9 percent, floating log patch when open about 4 to 5 percent of screen area at the lighter veil, residual closed state under 1 percent. Total persistent HUD rail and clusters remain under the prior 33 percent once the log is optional.
    
    Faction silhouette kit
    
    Fixed per class: overall length-to-beam ratio, mass distribution (frigate lean and short, destroyer mid, cruiser balanced, carrier bulk-aft, capital long and heavy), and the silhouette's anchor bounding box so the same class always occupies the same footprint at both shelf and fleet-strip sizes. Everything else swaps by faction.
    
    Swappable elements, expressed only as contour and negative cuts:
    
    Bow treatment (blunt terraced, leaf-point, cannon-forward mass, angular cutwater).
    Spine and superstructure (stepped fortresses, continuous glass curve, ion-cannon spine, standard naval bridge and decks).
    Stern and engines (blocky exhaust banks, tapered glass nozzles, heavy ion flare, angular thruster clusters).
    Signature feature (fortress towers, internal light slits, the cannon itself, antenna or sensor arrays).
    Anchor-size detail kit: turret silhouettes, antennae, nozzle segmentation, hangar mouths. These are contour notches and negative cuts only; no interior shading or fill variation.
    
    Cruiser proof in the four languages:
    
    Iron Mandate: stepped terrace hull, massive forward and mid towers, blunt prow, blocky stern exhaust banks, turret notches along the upper edge.
    Glasswright: continuous long leaf curve, pointed bow, tapered glass nozzles, hangar mouths as smooth oval cuts, lit-edge contour only.
    Dominion: heavy form built around a prominent forward ion cannon that reads as a single large cylindrical mass, thick spine, wide stern flare.
    Hegemony: angular naval standard, sharp cutwater, mid-bridge superstructure, segmented thruster cluster, clean turret and antenna cuts.
    
    At 16 px fleet-strip size, class identity (length and mass) remains reliable. Faction identity survives only as the strongest one or two contour cues: Iron Mandate terrace steps or tower height, Glasswright overall curve, Dominion cannon mass, Hegemony angular cutwater. Finer detail (nozzles, hangars, antennae) collapses. Fallback is the class silhouette plus a single faction accent mark (a one-pixel notch or bar) when the contour alone is insufficient; never rely on color alone.
    
    Agent cost is moderate: one shared class master per size, then faction overlay masks or parametric swaps for the five elements above. Shipping order: Hegemony first (already closest to the current language), then Iron Mandate and Dominion (both metal and readable at small size), Glasswright third (curve requires clean anti-aliased edges), remaining factions afterward once the kit is proven.
    
    Odds presentation
    
    Keep the existing grammar of glyph plus figure plus short word labels. Standing form:
    
    About 16 damage
    7 shields · 9 hull
    
    The honesty marker "About" stays. The total remains the largest figure. The two splits sit on the same line, each preceded by its glyph (Glacier for shields, ink for hull), with the short labels "shields" and "hull" so the numbers never float without meaning. No new panels, no hover dependence. When the ruling is pure pooled shields the second line collapses to a single "to shields" entry if needed, but the dual form remains the default when both pools are hit.
    
    Refusals
    
    I refuse any return of boxed tiles or colored backgrounds behind the log or the integrity unit; the standing veil-and-glyph rule is non-negotiable. I refuse interior shading or color fills inside the silhouettes; contour and negative cuts only. I refuse keyboard shortcut labels on the HUD face. I refuse any odds treatment that drops the honesty marker or hides the split behind a hover or secondary panel.
