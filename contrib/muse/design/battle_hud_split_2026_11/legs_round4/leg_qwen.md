# Issue 1006 round 4, Qwen leg (log relocation, faction silhouettes, odds clarity)

Model gate: Qwen, selector confirmed Qwen3.8-Max before the pack was pasted and the chat header confirmed Qwen3.8-Max after generation; new chat, pack pasted as text, no A/B choice appeared. Run Nov 17, 2026. Filed verbatim below; the raw answer contained 0 em or en dashes, normalized to hyphens per the repo rule. Its costs are stated in illustrator-days, which the chair restates in agent passes in design.md, and its 16 px faction colour pip is rejected there on colour discipline grounds.

1. Log verdict, shelf expansion, and screen share accounting
    
    Verdict: option A. The log floats above the shelf on the right side.
    
    The log's job is to narrate what just happened: damage numbers, effect procs, a reinforcement ping, the occasional spoken taunt from an enemy fleet marshal at contact. That is reactive reading. You look at it after something resolves. The turn cluster in the top left (Round number, Your turn, ships to act, Objective) is proactive reading. You look at it to decide what to do next. Stacking reactive narration under proactive instruction, option B, merges two cognitive modes in one vertical column and forces the player to context-switch inside the same eye path. It also means that in quiet turns, when the log has nothing new to say, you carry dead space under the turn cluster for no reason. Option A keeps the two reading modes in separate regions of the screen and lets the log breathe or collapse without disturbing the decision cluster.
    
    Default state. The log is visible by default, showing the three most recent lines, at a lighter veil than the shelf. It is collapsible to a single-line ticker (the most recent entry only) via a small glyph toggle at its top-right corner, and it can be expanded to show up to six lines. Collapsed is not the same as hidden. The log must be readable without opening a menu, per its stated job. Fully hiding it by default would violate that job, so I will not recommend it.
    
    Veil and opacity. The shelf sits on the standard dark veil, which I will call the shelf veil, roughly 82 percent opaque black. The floating log patch sits on a lighter veil at roughly 55 percent opaque black. In practical terms the play field behind the log is legible as shapes and color but not as fine detail. The player can see that a ship is there and roughly what is happening, but the log text remains the readable layer. If the player wants full sightlines, they collapse the log to the single-line ticker, which at one line of 17 px text plus 6 px padding above and below is about 29 px tall and 320 px wide, a negligible patch.
    
    Loser's cost (option B, not chosen). Had we gone top left, the turn cluster would grow downward by roughly 110 to 130 px to hold three log lines beneath the Objective line. The cost: the upper-left quadrant of the play area loses that strip of open hex field. On engagements where the player is maneuvering near the top-left edge of the map, ships would slide under the text. More importantly, the turn cluster becomes a mixed document, half instruction, half narration, and the player must parse "what should I do" and "what just happened" in the same vertical stack. That is a persistent cognitive tax on every turn. I am glad to not pay it.
    
    Shelf expansion. With the log removed from the shelf's right end, roughly 340 px of shelf width is freed. The shelf grows from 216 to 248 design px tall. The specific gains:
    
    Row height inside the shelf increases by about 3 px per row, giving the weapon checklist and the order glyph row more vertical air.
    
    Order glyphs render at their full 32 px spec size. In the 216 px shelf they were being squeezed to 28 px to fit. At 248 they sit at spec without crowding the label text beneath them.
    
    The integrity unit (the stacked hull and shield bar with the ship silhouette anchor) widens by roughly 40 px, giving the hull and shield segments more room to show proportional damage without the bar looking like a sliver.
    
    The range band markings on the weapon checklist widen by about 20 px, making the drawn band intervals easier to distinguish at a glance.
    
    The fleet strip at the shelf's far left is unchanged in layout but benefits from the extra 3 px of row height for its 16 px ship glyphs.
    
    Screen share accounting at 1920 by 1080 (2,073,600 total px).
    
    Current state, as accepted through round 3:
    
    Full-width rail (shelf plus the thin top strip carrying the turn cluster): roughly 33 percent of the screen, per the working figure Ryan and the council have been using. The shelf alone at 216 px is 20.0 percent of screen height. The top strip and its padding account for the remaining roughly 13 percent.
    
    The log occupied the rightmost ~340 px of the shelf, so it was part of that 20 percent shelf figure.
    
    New state after this round:
    
    Shelf at 248 px: 1920 x 248 = 476,160 px, which is 23.0 percent of screen height. That is a gain of 3.0 percentage points over the old shelf.
    
    Top clusters: unchanged. Still roughly 13 percent.
    
    Log patch at expanded (three lines): 320 px wide, 87 px tall (three lines of 17 px text plus 6 px padding between lines plus 6 px top and bottom). Area: 27,840 px, or 1.3 percent of the screen. At 55 percent veil opacity, the effective visual weight is roughly 0.7 percent of equivalent solid coverage.
    
    Log patch at collapsed (one line): 320 px wide, 29 px tall. Area: 9,280 px, or 0.4 percent of the screen.
    
    The 340 px of shelf width formerly held by the log is now distributed to the integrity unit, range bands, and order glyphs. No element is added; existing elements simply breathe.
    
    Net: the persistent HUD chrome moves from roughly 33 percent to roughly 36 percent of the screen (shelf up 3 points, top strip flat, log patch adds ~1.3 points at expanded, ~0.4 at collapsed). The shelf interior is less cluttered despite the height gain because the log's content is no longer competing for the same row. The player can recover the 1.3 percent by collapsing the log. The play field retains roughly 64 percent of the screen at expanded log, 64.6 percent at collapsed.
    
    I consider 36 percent an honest ceiling for a tactics HUD at this density. I would not push past 38 without a compelling reason.
    
    2. Faction silhouette kit, cruiser proof, 16 px honesty, cost, shipping order
    
    The kit system.
    
    Every ship silhouette in Voidsworn is built from two layers: a class skeleton and a faction skin.
    
    The class skeleton is fixed. It owns the overall proportions, the mass distribution, and the role-reading outline. The five skeletons, carried from round 3:
    
    Frigate: small, single-axis, fast-looking. Length-to-beam ratio roughly 4:1. One engine cluster, one visible weapon mount.
    
    Destroyer: slightly larger, weapon-forward. The bow third carries the armament mass. Two engine clusters.
    
    Cruiser: mid-size, balanced. The workhorse. Roughly 30 percent of the fleet in a typical engagement. Symmetrical mass distribution, two visible weapon stations, one superstructure block.
    
    Carrier: large, with flat or recessed areas that read as hangar mouths. Asymmetric mass: the flight deck or bay dominates one face.
    
    Capital: largest, dominant mass, reads as a single unavoidable object. Multiple superstructure tiers.
    
    The faction skin swaps five features onto that skeleton. The skeleton's proportions and role-reading outline do not change. The five swappable features:
    
    Bow treatment. The shape of the forward 20 percent. Examples: stepped ram (Iron Mandate), tapered leaf tip (Glasswright), cannon housing (Dominion), clean angular wedge (Hegemony).
    
    Spine and superstructure. The dorsal line and any raised structures along it. Terraced blocks, a smooth curved ridge, a heavy gun housing, or a clean angular bridge.
    
    Stern and engines. The aft 20 percent. Fortress buttresses, a tapered glass tail with internal glow lines, heavy thruster housings, or standard angular nozzles.
    
    Signature feature. The one element that makes the faction readable at a glance, even at small sizes. For Iron Mandate: the stepped terracing itself. For Glasswright: the overall curvature, since they are the one non-angular family. For Dominion: the prominent ion cannon. For Hegemony: the angular naval profile, which is close to the round 3 baseline and needs the least deviation.
    
    Anchor-size detail kit. Small contour additions that enrich the silhouette at 32 px and above: turret silhouettes, antennae, nozzle segmentation, hangar mouths. These are expressed strictly as contour detail and negative cuts (notches, slots, recesses in the outline). No interior shading, no fill gradients, no interior line work. The silhouette is a single filled shape; all detail is carved into or added onto its edge.
    
    Cruiser in four languages. The proof.
    
    All four share the cruiser skeleton: balanced mass, two weapon stations, one superstructure block, length-to-beam ratio roughly 3:1.
    
    Iron Mandate cruiser. The bow is a stepped ram, three terraces climbing back from the tip. The spine is a ziggurat: three stacked blocks, each narrower than the one below, giving a terraced fortress profile. The stern is buttressed, two angular haunches flanking a broad engine block. Signature: the terracing is the identity; every horizontal break in the outline reads as a step. Detail kit: turret silhouettes are square and recessed into the terrace faces as negative cuts. Antennae are short, thick posts. Nozzle segmentation is three rectangular slots cut into the stern face.
    
    Glasswright cruiser. The bow tapers to a long, narrow leaf tip, gently curved upward. The spine is a smooth, shallow arc, no hard angles anywhere. The stern tapers symmetrically to a point, like the tail of a blown-glass leaf. Signature: curvature. This is the one faction that uses curves instead of angles, and at any size the curved outline reads against the angular field. Detail kit: no turrets; weapon ports are oval negative cuts flush with the hull curve. Antennae are thin, trailing filaments. Engine glow is suggested by two elongated negative cuts at the stern (the "lit from within" quality, expressed as negative space, not as interior shading). Hangar mouths, if present on carrier-class Glasswrights, are curved recesses.
    
    Dominion cruiser. The bow is dominated by the ion cannon housing: a heavy, forward-projecting barrel shape that extends the bow line by roughly 15 percent beyond the hull. The cannon must read as a cannon, not as a generic protrusion. The spine is low and heavy, one thick ridge. The stern is broad, industrial, two heavy thruster blocks. Signature: the cannon. At any size, the forward projection reads as a weapon. Detail kit: turret silhouettes are cylindrical and thick. Antennae are minimal, one stub. Nozzle segmentation is two large circular cuts. The cannon barrel has one negative cut ring near the muzzle to suggest a focusing array.
    
    Hegemony cruiser. The bow is a clean angular wedge, close to the round 3 baseline. The spine carries one angular bridge block, slightly forward of center. The stern has two angular nozzles, standard naval layout. Signature: the angular naval profile itself. This is the least modified of the four because the round 3 language was already close to Hegemony. The changes here are refinement, not reinvention. Detail kit: turrets are small angular shapes on the dorsal line. Antennae are two thin masts. Nozzle segmentation is a single rectangular slot per engine.
    
    16 px honesty.
    
    At 16 px tall (the fleet strip glyph size), faction-specific contour detail does not survive. The turret silhouettes, antennae, nozzle segmentation, and negative cuts are all sub-pixel or single-pixel features at that size. They become noise or vanish.
    
    What survives at 16 px: the overall mass distribution and the broadest outline shape. In practice, that means the class skeleton reads clearly (frigate vs. destroyer vs. cruiser vs. carrier vs. capital). The faction signature survives only in two cases: Glasswright, because the curved outline is a fundamentally different shape language from every angular faction, and Dominion, because the forward cannon projection changes the bow profile enough to notice. Iron Mandate terracing and Hegemony angular detail collapse into a generic angular blob at 16 px.
    
    Fallback for the fleet strip: class silhouette plus a 3 px faction color pip at the glyph's base. The pip uses the faction's designated color (outside the ember/Glacier/red accent rules, since those govern the HUD, not faction identity). The player reads class from shape and faction from color. At 32 px and above (the selected-ship anchor in the integrity unit, the orders panel), the full faction skin and detail kit are visible.
    
    I will not pretend otherwise. The detail kit is a 32 px and above feature. At 16 px it is class shape plus color pip, and that is the honest answer.
    
    Cost in agent terms and shipping order.
    
    Each faction skin requires five class silhouettes, each drawn as a vector path with the faction's five swappable features applied. The detail kit (turrets, antennae, nozzles, hangar mouths) adds contour variants per class. I estimate each faction at roughly 2 to 3 illustrator-days for the five silhouettes plus detail variants, assuming the class skeletons are already locked from round 3. The kit specification document itself, the one that defines the five swap points and the contour-only rule, is about 1 day to write and review.
    
    Four factions: 8 to 12 illustrator-days, plus 1 day for the spec. Call it 9 to 13 total.
    
    Shipping order, based on delta from the existing round 3 baseline and system validation:
    
    Hegemony first. Closest to the round 3 angular baseline. Smallest delta, maybe 1.5 days. Ships fastest and validates that the kit system works without requiring the team to solve hard problems on the first pass.
    
    Iron Mandate second. The terracing is a strong geometric departure but still angular, so it stays within the existing rendering and animation pipeline. The stepped forms test the contour-detail and negative-cut rules rigorously. About 2.5 days.
    
    Dominion third. The cannon signature is a single bold feature, but it changes the bow profile enough to require rethinking the front quarter of every class. About 2.5 days.
    
    Glasswright last. The curved family is the hardest departure. Every other faction is angular; Glasswright introduces curves, tapered forms, and a fundamentally different outline grammar. It may require the rendering pipeline to handle bezier outlines where everything else is polygonal. It also has the most risk of looking inconsistent with the rest of the fleet if done carelessly. Ship it last so the team has three factions of experience before attempting the curve. About 3 days.
    
    Remaining factions beyond these four follow the same kit spec and slot in as production allows.
    
    3. Odds presentation
    
    The round 2 and 3 mockups showed two bare figures beside glyphs, a Glacier 7 and an ink 8, with "of 16 damage." The 8 was wrong (it should be 9), and more critically, Ryan could not tell what the numbers meant. Two digits beside two colored glyphs, with no words, is not a presentation. It is a riddle.
    
    The fix is words. Short ones.
    
    Proposed standing layout, within the existing glyph-plus-figure-plus-short-word grammar:
    
    Line 1 (the prominent line, larger text, 17 px):
    
    About 16 dmg · 72% to hit
    
    Line 2 (the split, 14 px mono, the accepted readout size):
    
    [Glacier glyph] 7 shield [ink glyph] 9 hull
    
    That is the entire presentation. No panel, no hover.
    
    What this does:
    
    "About" survives as the honesty marker. These are expected values, not certainties. The word "About" tells the player the number is a statistical estimate. I considered a tilde mark (~16) but "About" is plainer and Ryan's original text used it. Keep the word.
    
    The total (16) and the hit chance (72%) share line 1 and are the most prominent elements. The player reads the headline first: roughly 16 damage, roughly 72 percent chance to land it.
    
    Line 2 splits the total. The word "shield" follows the 7. The word "hull" follows the 9. The Glacier glyph is on the shield side because Glacier is the shield readout color by standing rule. The ink glyph is on the hull side. The words make the split self-evident without any hover, tooltip, or panel.
    
    The pooled shield ruling is respected: the text says "shield," singular, one pool. Not "prow shield," not "port shield." Just "shield."
    
    The arithmetic is correct: 7 plus 9 equals 16. The round 3 error (8 instead of 9) is fixed.
    
    "dmg" is the short word label for the damage glyph. It is 3 characters, mono, at 17 px on line 1. It sits next to the total. If the council prefers the full word "damage," it fits at 17 px on a 1920 px wide shelf, but "dmg" saves 40 px and reads fine in context.
    
    What I will not do: I will not make the split hover-only. I will not put the split behind a click or a panel. The player must be able to glance at the shelf during their turn and see, without interaction, that the expected damage is about 16, that roughly 7 goes to the shield pool and roughly 9 to hull, and that the hit chance is about 72 percent. Two lines. Words on the numbers. Done.
    
    4. Refusals
    
    I refuse to make the log hidden by default. Ryan asked for an "optional log," and I have honored that with a collapse toggle and a lighter veil. But the log's stated job is to explain what just happened without the player opening anything. If it defaults to hidden, the player must remember to open it after every engagement, and the first time they forget, they miss a reinforcement arrival or a fleet marshal's taunt and feel blindsided. Optional means the player can dismiss it. It does not mean the game hides it by default.
    
    I refuse interior shading on the faction silhouettes. The brief already says "contour detail and negative cuts, never interior shading," and I agree. Interior shading breaks the silhouette language, creates rendering cost at small sizes, and muddies the single-fill shape that makes the glyphs read as icons rather than illustrations. I will not soften this rule even for Glasswright's "lit from within" quality. That quality is expressed through negative cuts at the stern, not through a gradient fill.
    
    I refuse to add more than six lines to the expanded log. The log is a ticker, not a chat window. Six lines at 17 px plus padding is about 145 px tall. Beyond that, the patch starts to eat into the play field meaningfully and the player is reading a novel instead of a battle summary. If the player wants a full history, that lives in a pause-screen log, not on the HUD.
    
    I refuse to put keyboard shortcut labels on the log toggle glyph or anywhere else on the HUD face. Round 1 ruled that shortcuts live under Menu, Controls. The log toggle is a small glyph, not a labeled button. The player learns it once. If they forget, they find it in Controls. I will not add a "press L to toggle" label next to it.
    
    I will not design more than four faction skins in this round. The brief says "there are more factions than four; the system matters more than exhaustiveness." I agree. The kit spec is the deliverable. Four factions prove the system. The rest follow in production. Trying to spec every faction now would stall the round and produce guesses instead of designs.
    
    That is my leg for round 4.
