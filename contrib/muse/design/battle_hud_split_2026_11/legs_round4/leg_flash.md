# Issue 1006 round 4, Flash leg (log relocation, faction silhouettes, odds clarity)

Model gate: Gemini, "Quick answers 3.5 Flash-Lite", picker verified before the pack was pasted and again after the answer completed, signed in. New chat, pack pasted as text. Run Nov 17, 2026. Filed verbatim below; the raw answer contained 0 em or en dashes, normalized to hyphens per the repo rule.

1. Log Verdict and Screen Share Accounting
    
    Option A wins cleanly. The log moves to a floating panel above the right side of the bottom shelf, and Option B (top-left cluster under the turn marker) is discarded.
    
    Why Option A Wins and Option B Fails
    
    Option B fails because the top-left quadrant already bears heavy cognitive load. It holds the phase indicator, the round counter, the action pool, and the active objective. Injecting a scrolling two-line battle log directly below that cluster creates severe reading interference. Players look to the top-left for strategic status (who is left to act, what is the win condition) and to the bottom shelf for tactical execution (what just happened, what weapon am I firing). Placing the log just above the bottom shelf keeps tactical feedback adjacent to the ship status and weapon checklist.
    
    The Loser's Cost (Option B)
    
    If Option B had been chosen, the top-left cluster would extend downward by roughly 60 design pixels, crowding the top edge of the playfield and forcing map UI, unit flags, and command pings downward. It would also break the clean separation between strategic status (top left) and tactical resolution (bottom right).
    
    Log Specifications (Option A)
    
    Position: Anchored 12 design pixels above the right edge of the bottom shelf, resting just below the rightmost elements of the fleet strip.
    
    Dimensions: 320 design pixels wide by 52 design pixels high (tall enough for two clear text lines).
    
    Background and Opacity: Rendered on a dark veil at 70 percent opacity with a subtle 1-pixel border in a muted white. This lighter veil makes it clearly secondary to the solid shelf below it, while still keeping text legible over the bright hex map.
    
    Default State: Expanded and active by default, showing the two most recent tactical events (such as damage dealt, a status effect applied, or a character taunt at contact). The player can collapse it to a single-line ticker by clicking a small chevron on its top-right edge. This satisfies the requirement for an optional log without hiding the log's core job of explaining recent events.
    
    Screen Share Accounting
    
    With the log relocated out of the shelf, the bottom shelf expands its height from 216 design pixels to 248 design pixels, allowing for a 32-pixel increase in internal breathing room.
    
    Shelf Share: The expanded shelf now occupies roughly 23 percent of total vertical screen height at 1920 by 1080 (248 divided by 1080).
    
    Total HUD Footprint: Combining the expanded shelf and the new floating log, the bottom operational zone occupies about 27 percent of the screen area (23 percent shelf, 0.8 percent floating log, plus top clusters).
    
    Top Clusters: The top-left turn cluster and top-right telemetry remain untouched, preserving their brevity.
    
    This is a net reduction in total obscured area compared to the current full-width rail design, which occupies roughly 33 percent of the screen. The additional 32 pixels of shelf height are offset by the removal of the log from the shelf itself, which frees up critical horizontal space for the glyphs and the fleet strip.
    
    2. Faction Silhouette Kit System and Cruiser Proofs
    
    To upgrade the ship icons with distinct faction identities while keeping class readability intact at 16 px, the design uses a silhouette kit system built on a shared structural armature.
    
    The Silhouette Kit System
    
    Every ship class (frigate, destroyer, cruiser, carrier, capital) is built on a shared structural armature that locks in overall proportion, hardpoint placement, and engine footprint. What swaps per faction is the contour language applied to four distinct zones:
    
    Fixed per Class: Overall hull length-to-width ratio, hardpoint anchor zones, and core engine block footprint.
    
    Zone 1 (Bow Treatment): Ram bows, split mandibles, blunt battering faces, or sweeping glass probes.
    
    Zone 2 (Spine and Superstructure): Stepped terraced blocks, recessed command bridges, open skeletal trusses, or bulbous glass domes.
    
    Zone 3 (Stern and Engines): Blocky exhaust cowlings, exposed ion rings, recessed thruster banks, or trailing light fins.
    
    Zone 4 (Signature Feature and Anchor-Size Detail Kit): Distinct negative cuts, prominent weapon housings, turret silhouettes, antennae, nozzle segmentation, and hangar mouths, rendered as contour detail and negative cuts only, never interior shading.
    
    The Cruiser Worked in Four Factions
    
    Iron Mandate (Terraced Fortress): The cruiser silhouette is blocky and heavy. The bow is a blunt, stepped battering face. The spine is a stepped terrace of three ascending rectangular blocks, each slightly narrower than the last. The stern features a wide, blocky exhaust cowling with segmented nozzle cuts. The signature detail is the terraced spine that reads as a fortress wall.
    
    Glasswright (Blown Glass Leaves): The cruiser is entirely un-angular. The hull forms a long, elegant, curved leaf with a smooth, continuous top line that tapers to a fine, sweeping glass probe at the bow. The superstructure is a low, integrated bulbous dome, and the stern trails a pair of thin, curved light fins. The signature detail is the absence of straight lines and the single, continuous curved contour, with a small negative cut forming a glass vein along the hull.
    
    Dominion (Heavy Ion Focus): The cruiser features a broad, wedged hull dominated by a massive, protruding ion cannon running along the centerline from the mid-hull to the bow. The bow is split into two mandibles flanking the cannon's muzzle. The spine is a low, armored housing for the cannon's power conduits. The stern is a heavy, armored block with a prominent circular ion ring at its center. The signature detail is the unmistakable, oversized ion cannon barrel that defines the ship's silhouette.
    
    Hegemony (Angular Naval Standard): The cruiser follows the standard military wedge. The bow is a sharp, angled naval prow. The spine is a raised central ridge with a recessed command bridge and two small turret silhouettes. The stern is a flat, angular transom with segmented thruster nozzles. The signature detail is the balanced, symmetrical angular wedge, close to the round 3 baseline.
    
    16 Pixel Fleet Strip Readout and Fallback
    
    At the 16 px fleet strip scale, complex silhouette details like turret mounts and bridge towers dissolve into the hull mass. Faction identification at this size relies on the macro-contour alone.
    
    What Survives: The macro-contour remains the primary identifier. The terraced blocky profile of the Mandate, the smooth curved leaf of the Glasswright, the protruding central cannon of the Dominion, and the sharp wedge of the Hegemony are all distinct at 16 px.
    
    Fallback: If a factional silhouette loses distinction at 16 px due to extreme miniaturization, a subtle 1 px ember or faction-tinted underline beneath the silhouette is used as a secondary identifier, avoiding the need for color-coded hulls that would violate the discipline.
    
    Cost and Shipping Order
    
    Cost in Agent/Design Terms: Moderate asset generation overhead and strict geometry rules to ensure negative cuts remain legible at 40 px anchor size. Each new faction requires a distinct contour pass across all five classes, but the kit system reduces per-ship cost by locking in fixed hardpoints.
    
    Shipping Order:
    
    Hegemony (establishes the baseline angular standard).
    
    Iron Mandate (tests heavy stepped geometry and negative trench cuts).
    
    Dominion (tests asymmetrical weapon integration like the ion cannon).
    
    Glasswright (tests curved, non-metal organic silhouettes).
    
    Remaining faction variants follow in subsequent sprints.
    
    3. Odds Clarity Presentation
    
    The odds split is restructured to eliminate arithmetic confusion while preserving honesty and fitting inside the existing grammar. The new presentation uses glyphs, figures, and short word labels, with no hover-only meaning.
    
    The Proposed Display Format
    
    Inside the weapon checklist row, when a player targets an enemy ship, the odds display formats as follows:
    
    [Glacier Shield Icon] 7  [Hull Icon] 9  |  About 16 Dmg  [85%]
    
    Mechanics of the Display
    
    Honesty Marker: The word "About" remains upfront, affirming that this is an expected value based on current hit probability, not a guaranteed outcome.
    
    Total and Split Breakdown: The total expected damage (16) appears clearly. Immediately preceding it, the split is shown as two labeled figures: 7 points allocated to the pooled prow shield (Glacier blue, with a shield icon), and 9 points allocated to hull (off-white, with a hull icon). The arithmetic is now self-evident: 7 plus 9 equals 16.
    
    Hit Chance: The percentage chance to hit remains anchored at the far right of the readout string in high-contrast ember, ensuring it is the last thing the eye reads before the FIRE action.
    
    Grammar Compliance: No new panels or hover requirements are introduced. All values use the approved fonts and colors: mono figures for numbers, Glacier blue for shields, off-white for hull, and ember for the hit chance.
    
    4. Refusals and Rationale
    
    Refusal 1: Placing the battle log in the top-left turn cluster (Option B). Refused because it violates the separation of strategic status and tactical feedback, creating reading interference in a critical area.
    
    Refusal 2: Introducing interior hull shading or gradient fills for faction silhouettes. Refused because it breaks the flat, single-weight line work discipline and the no-boxes, no-gradient rule. Faction identity must come from contour and negative cuts only.
    
    Refusal 3: Hiding damage breakdowns behind a hover tooltip or secondary click. Refused because combat decisions require immediate, standing visibility of the damage split. The player should not have to open a tooltip to understand whether their shot will crack shields or damage hull.
