# Issue 1006 round 3, Flash leg (iconography: silhouettes and glyph upgrade)

Model gate: Gemini, "Quick answers 3.5 Flash-Lite", picker verified before the pack was pasted and again after the answer completed, signed in. New chat, pack pasted as text. Run Nov 17, 2026. Filed verbatim below; the raw answer contained 0 em or en dashes, normalized to hyphens per the repo rule.

1. Hull Silhouette Construction
    
    The ship silhouettes are drawn in strict side profile facing right. They maintain a consistent visual weight and height relative to their class, using a flat off-white ink with an inner block silhouette and precise negative-space cutouts.
    
    Frigate (Fast Interceptor, ~22 px long by 10 px high at 40 px canvas scale)
    
    Proportions: Dart-like, low profile, needle bow.
    
    Bow and Stern: Acute angled bow tapering straight into the keel; clipped or recessed engine block at the stern.
    
    Spine and Superstructure: Flat, flush spine with zero raised superstructure to emphasize speed and small cross-section.
    
    Engine Block: Twin flush ion nozzles at the rear.
    
    Signature Feature: A ventral weapon fin beneath the midsection.
    
    At 16 px: Reads as a sharp dart with a tiny fin bump.
    
    At 40 px: The ventral fin and clipped stern nozzle details become fully crisp.
    
    Destroyer (Escort / Hunter, ~30 px long by 12 px high)
    
    Proportions: Balanced, aggressive wedge, moderate length.
    
    Bow and Stern: Ram-bow front angled upward; flat vertical transom stern housing the primary thruster array.
    
    Spine and Superstructure: Central angular command bridge block rising just above the spine line.
    
    Engine Block: Rectangular block flush with the transom.
    
    Signature Feature: Forward-sloping sensor mast or forward gun turret hump on the deck.
    
    At 16 px: Reads as a chunky wedge with a distinct bridge hump.
    
    At 40 px: The sensor mast and transom edge separation are clean.
    
    Cruiser (Vigil-class standard hull, ~40 px long by 14 px high)
    
    Proportions: Long hull, balanced heavy weight, authoritative silhouette.
    
    Bow and Stern: Blocky, sloped prow with a flat chin plate; stepped multi-tier stern housing heavy drives.
    
    Spine and Superstructure: Raised central spine running two-thirds the ship length, surmounted by an arched dorsal bridge.
    
    Engine Block: Heavy, protruding dual-square engine block at the stern.
    
    Signature Feature: The stepped dorsal superstructure and distinct engine block separation.
    
    At 16 px: Reads as an elongated block with a noticeable spine hump and stern block.
    
    At 40 px: The stepped superstructure tiers and chin plate cutouts resolve clearly.
    
    Carrier (Flight Deck Hull, ~46 px long by 13 px high)
    
    Proportions: Long, flat-backed, heavy-decked vessel.
    
    Bow and Stern: Blunt, rounded bow designed for internal hangar egress; wide, square flat stern.
    
    Spine and Superstructure: Offset starboard or central flattened flight deck running the upper plane, with a minimal offset island tower.
    
    Engine Block: Recessed quad-engine strip across the bottom stern.
    
    Signature Feature: The long unbroken flight deck plane along the upper contour.
    
    At 16 px: Reads as a long rectangle with a flat top and slightly squared front.
    
    At 40 px: The flat flight deck profile and island tower silhouette are unmistakable.
    
    Capital (Dreadnought / Flagship Hull, ~56 px long by 18 px high)
    
    Proportions: Massive, heavy, blocky, dominating mass.
    
    Bow and Stern: Massive wedge prow with heavy armored plating; sheer, fortress-like multi-level stern block.
    
    Spine and Superstructure: Terraced, mountainous superstructure rising across the central hull like a citadel.
    
    Engine Block: Massive multi-tier reactor/engine cluster spanning the entire lower stern.
    
    Signature Feature: The towering terraced citadel superstructure and heavy prow ram.
    
    At 16 px: Reads as a massive, heavy, jagged block that dwarfs the frigate and cruiser shapes.
    
    At 40 px: Every terraced tier of the citadel and the heavy reactor block geometry resolves.
    
    State Application on Silhouettes:
    
    Full Ink: Default off-white silhouette at full opacity.
    
    Damage Colour: Muted grey-red or dark rust coloration creeps inward from the stern or ventral side based on hull percentage. At 50% hull, the rear third turns muted rust. At 25% hull, the rust covers up to the midsection.
    
    Active State: A crisp ember orange underscore line sits directly beneath the 16 px or 40 px silhouette, 2 px thick, spanning the hull length.
    
    Unavailable and Cooldown: The silhouette dims to about 35% opacity. A thin ember arc (2 px stroke) sweeps around the top-right edge of the silhouette area to indicate cooldown progress.
    
    2. Upgraded Glyph Constructions
    
    Each glyph is built as a vector line drawing in off-white ink on the dark veil, using single-weight (2 px) or two-weight (2 px primary, 1 px detail) line work. No fills, no boxes, no gradients.
    
    Weapon Glyphs (~20 px)
    
    Battery: A 2 px horizontal base line crossed by three 1 px vertical turret barrels of staggered heights. The signature detail is the staggered barrel heights (short, tall, short) with tiny 1 px muzzle caps on the tallest barrel, creating a recognizable battery cluster rather than a generic set of lines.
    
    Lance: A sharp, open-backed triangle pointing right, outlined in 2 px weight, enclosing a thin 1 px converging inner line that terminates in a 2 px ember accent dot at the tip when ready. The signature detail is the inner converging line that suggests a focused beam channel.
    
    Torpedo: A stout 2 px rounded-front missile profile shell outline with two short 1 px tail fins at the rear and a 1 px central guidance line running through the body. The signature detail is the distinct bulbous warhead front that separates it from the sharp lance.
    
    Point Defence: A central 2 px crosshair diamond surrounded by a ring of six short outward-pointing 1 px spokes. The signature detail is the ring of spokes, which reads as an interception burst without requiring a full circle.
    
    Integrity Glyphs (~16 to 20 px)
    
    Hull (Keel Plate): A heavy 2 px horizontal foundational bar representing the keel, with three vertical 1 px ribs rising from it at regular intervals, capped by a thin 1 px deck line. The signature detail is the ribbed keel structure that reads as a ship's spine, not a generic bar.
    
    Shield (Hexagon): A crisp 2 px regular hexagon outline with an interior concentric 1 px inner hexagon offset by 2 px, rendered in Glacier blue only. The signature detail is the double-hexagon layering that suggests a layered energy field rather than a flat geometric shape.
    
    Order and Command Glyphs (~32 px design size)
    
    Brace: Two nested chevron brackets facing left and right (concave inward) in 2 px weight, braced by a central 2 px vertical spine line. The signature detail is the central spine that visually locks the two chevrons together.
    
    Focus Fire (Order): A target reticle composed of four open corner L-brackets in 2 px weight, framing a central 1 px filled ember dot. The signature detail is the open-corner construction that distinguishes it from a closed box.
    
    Turn: A smooth 2 px curved arc arrow sweeping through 90 degrees with a squared arrowhead pointing down-right. The signature detail is the squared arrowhead (matching the game's square-corner discipline) rather than a pointed triangle.
    
    Fire for Effect: Three stacked diagonal slash lines in 2 px weight, crossed by a perpendicular horizontal 1 px line at the midpoint. The signature detail is the perpendicular cross-line that converts a generic slash into a deliberate barrage mark.
    
    End Ship: A square container outline in 2 px weight enclosing a central filled square stop block, signalling a hard stop. The signature detail is the filled inner square that creates a strong stop-signal read at 32 px.
    
    Command (Star): A four-pointed stellar cross in 2 px weight with sharp square tips, featuring an inner 1 px smaller cross at its centre. The signature detail is the double-cross construction that reads as a command insignia rather than a generic star.
    
    3. The Detail Budget and Graceful Degradation Rules
    
    As display scaling shrinks glyphs from 32 px down to 20 px, 16 px, and 12 px, detail must vanish predictably in layers:
    
    Layer 3 (Primary Shell / Macro Shape, survives down to 12 px): The overall bounding silhouette, primary 2 px outline, and signature shape. This is the only layer that matters at fleet strip size (16 px).
    
    Layer 2 (Functional Geometry, drops below 20 px): Internal secondary vectors like inner nested lines, arc wedges, and guidance lines. These survive at 20 px and 32 px but are removed below 20 px to prevent clutter.
    
    Layer 1 (Micro Detail, drops below 32 px): Tiny muzzle caps, detached guidance chevrons, emitter squares, and inner concentric shapes. These exist only at the full 32 px action glyph size.
    
    The Builder Rule: Every glyph must be designed inside-out. Start by drawing the 12 px core silhouette; if it does not read at 12 px, the glyph fails. Then add Layer 2 detail only where it strengthens the 20 px read, and Layer 1 detail only where it adds richness at 32 px without merging into a blob. Never add detail that depends on a 1 px gap to remain legible at 16 px.
    
    4. What We Refuse
    
    To preserve the clean tactical readability and austere aesthetic of Voidsworn, the design council strictly refuses the following forms of richness:
    
    Faction Chrome and Skewomorphic Metal: No brushed steel textures, riveted armor plates, carbon fiber weaves, or engraved faction sigils inside glyphs. These require gradients and shading that violate the flat vector discipline.
    
    Gradients and Shading: No internal linear or radial gradients, drop shadows, or glow blooms within the glyph itself. Glow is reserved for the ember active underline only, never inside the icon.
    
    Tiny Text or Numeric Labels Inside Glyphs: No weapon caliber numbers, ammo counts, or tiny acronyms crammed into a 20 px icon. Text belongs in tooltips and labels beside the glyph, never inside it.
    
    Boxed or Tiled Containers: No rounded cards, background square fills, colored pills, or drop-in tiles behind the glyphs. Icons must read on the dark veil alone, using negative space as the container.
    
    Complex Organic Curves: No flowing, organic, or biological creature-like contours in ship silhouettes or glyphs. All curves are limited to functional arcs (turn arrows, cooldown arcs) with square-cornered terminations.
    
    5. Honest Costs, Risks, and Testing Protocol
    
    Art Pass Cost: In agent generation and validation terms, this is a 2-hour procedural vector-compilation pass plus a 1-hour integration pass in Godot. The cost is not in drawing the glyphs but in building the layered SVG export system that automatically drops Layer 1 detail below 32 px and Layer 2 detail below 20 px. That system must be tested before the glyph set ships.
    
    Readability Risk: Richer glyphs risk visual clutter at 16 px fleet strip view, where complex icons can merge into indistinguishable blobs. The highest risk is the Point Defence and Battery glyphs, which share a similar radial/spoke structure at small sizes.
    
    Testing Protocol:
    
    Render the entire glyph set and ship silhouettes at exact native shelf resolutions (16 px, 20 px, 32 px, and 40 px for the integrity anchor) on the actual dark veil background, not on white.
    
    Apply a Gaussian blur test equivalent to viewing distance degradation on standard 1080p and 1440p displays.
    
    Verify that a neutral observer can correctly distinguish a frigate silhouette from a cruiser silhouette at 16 px, and a Battery glyph from a Lance glyph at 20 px, with no labels present. If accuracy falls below 90%, the offending glyph returns to Layer 3 only.
