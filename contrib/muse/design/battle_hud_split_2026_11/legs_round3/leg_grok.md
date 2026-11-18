# Issue 1006 round 3, Grok leg (iconography: silhouettes and glyph upgrade)

Model gate: Grok, free grok.com, Fast mode, verified in the picker before the pack was pasted and again after the answer completed. New chat, pack pasted as text. Run Nov 17, 2026. Filed verbatim below; the raw answer contained 0 em or en dashes, normalized to hyphens per the repo rule.

Ship silhouettes sit in side profile as pure black or ink-filled outlines with no internal shading. Each class carries one dominant mass and one secondary break so the shape remains legible when reduced.
    
    Frigate: short, low hull with a single sharp prow rake and a compact engine cluster flush to the stern. At 40 px the rake and the slight rise of the dorsal fin read clearly. At 16 px the whole form collapses to a short tapered bar with a notch at the bow; the fin disappears. Full ink for intact, muted damage colour creeps from the stern forward as hull sections fail, ember outline only when the ship is the active actor.
    
    Destroyer: longer hull than the frigate, pronounced midships break where the superstructure steps up, twin engine pods set slightly proud of the stern. The step and the twin pods survive at 40 px. At 16 px the shape becomes a longer tapered slab with a visible midships shoulder; pods merge into the stern mass. Same state rules: ink, damage colour from the rear, ember for active.
    
    Cruiser (Vigil reference): long continuous hull, raised central spine that runs most of the length, heavy engine block stepped out at the stern. Spine height and the stern block are the 40 px markers. At 16 px the form reads as a long thin bar with a thicker rear third and a faint central ridge; spine detail vanishes. State treatment identical.
    
    Carrier: broad flat deck line, tall island superstructure offset aft of centre, wide rectangular engine bay. The flat top and the offset island give the 40 px silhouette its identity. At 16 px it becomes a thick rectangle with a single vertical spike near the rear; deck width is the only remaining cue. State colour follows the same ink-to-damage-to-ember progression.
    
    Capital: massive slab hull, multiple stepped tiers, enormous rear drive array that occupies nearly a third of the length. The sheer bulk and the stepped profile survive at 40 px. At 16 px the shape is simply the largest, densest rectangle in the set with a blunt rear; finer steps are lost. Colour rules unchanged.
    
    Glyph upgrades stay inside the existing line discipline: off-white ink, one or two weights, square corners, no fills except the intentional solid masses required by the form.
    
    Battery: three short horizontal bars stacked with a thin vertical spine linking their centres. The spine is the signature; it stops the bars from reading as generic lines. Outer weight slightly heavier than the spine. At 32 px the spine is visible; at 20 px the bars alone remain.
    
    Lance: elongated isosceles triangle pointing forward, base thickened into a short rectangular breech. The breech block is the distinctive mark. Single weight. Survives cleanly to 16 px as a simple arrowhead with a stub.
    
    Torpedo: elongated capsule with a pointed nose and a pair of short horizontal fins near the tail. The fins supply the identity. Two weights: body heavier, fins lighter. At 12 px the fins drop and the form becomes a pure capsule.
    
    Point defence: small open circle crossed by four short radial ticks at the cardinal points. The ticks distinguish it from a plain target. Single weight. Reads at 16 px; below that the ticks vanish and the circle alone remains.
    
    Hull (keel plate): thick horizontal bar with a short vertical stem rising from its centre, like a capital T rotated ninety degrees. The stem is the signature. Solid fill allowed for the bar. Survives to 12 px as a simple heavy dash.
    
    Shield: regular hexagon, slightly taller than wide, with a thin inner concentric hexagon. The double outline is the only detail. Glacier blue only. At 12 px the inner hexagon drops.
    
    Brace: broad downward-pointing chevron nested inside a second, thinner chevron. Nested structure is the mark. Single weight. Holds to 16 px.
    
    Focus fire: three parallel horizontal bars of increasing length, stacked and centred, with a short vertical tick on the right of the longest bar. The tick and the length progression identify it. Outer bars heavier. At 20 px the tick remains; at 12 px only the three bars survive.
    
    Turn: open hexagon with a single curved arrow riding the upper right edge. The arrow is the signature. Single weight. At 16 px the arrow shortens but remains readable.
    
    Fire for effect: solid five-pointed star with a thin outer ring. The ring prevents it from reading as a generic star. Two weights. Ring drops at 16 px, leaving the solid star.
    
    End ship: heavy horizontal bar crossed by a second bar at forty-five degrees, forming a bold X that does not extend past the bar ends. The constrained X is the mark. Solid. Survives to 12 px.
    
    Command: solid five-pointed star, no ring. Pure and minimal. Holds at every size.
    
    Detail budget follows a strict drop order. Primary outer silhouette is always present. Signature secondary element (spine, fins, inner hexagon, tick, arrow) is retained down to 20 px and may thin or shorten at 16 px. Tertiary interior lines vanish below 20 px. No glyph ever relies on a mark smaller than two pixels at its design size. Builders test by rendering the entire set at 32, 20, 16 and 12 px on the actual dark veil colour and rejecting any form that becomes an undifferentiated blob or loses its class identity.
    
    Refusals are absolute. No faction-specific ornament, no metallic highlights, no gradients, no internal text or numbers, no circular or rounded outer containers, no background tiles or plates. Anything that requires a filled tile to remain legible is rejected on sight.
    
    Art cost in agent terms is low: a single focused pass of roughly forty vector constructions plus the five silhouettes, all drawn once at the largest size and then validated downward. The real risk is that the added signature details collapse into noise at shelf scale and the glyphs become harder to parse than the original simple set. Mitigation is a forced side-by-side test on a 1920 by 1080 mock of the bottom shelf with every glyph present at its final pixel size, viewed at actual device scale, before any assets are locked.
