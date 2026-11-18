# Issue 1006 round 4, DeepSeek leg (log relocation, faction silhouettes, odds clarity)

Model gate: DeepSeek, DeepThink ON and Search OFF, verified before the pack was pasted and again after the answer completed (a 92 second thinking block ran). New chat, pack pasted as text (paste-original used). Run Nov 17, 2026. Filed verbatim below; the raw answer contained 0 em or en dashes, normalized to hyphens per the repo rule.

1. Log verdict and share accounting
    
    Verdict: A. Move the log to a floating, collapsible veil above the shelf on the right. Default state is expanded, not auto-hidden. It collapses to a 28 px header by toggle and remembers that state per session. A keeps outcome explanation near the shelf and fleet strip and leaves the top-left cluster as command status.
    
    B loses. B cost: the same log patch added under the turn cluster grows the top-left stack from about 2.6 percent to about 6.4 percent of screen area, competes with Round number, Your turn, ships to act, and Objective, and still needs a collapse control. A cost: the floating patch covers right-side battlefield at 3.8 percent of screen area and at 56 percent veil, so a toggle is required.
    
    Accounting at 1920 by 1080:
    
    - Shelf today at 216 px: 20.0 percent of screen area and height.
    - Shelf proposed at 248 px: 22.96 percent of screen area and height. The 32 px increase is 2.96 percent of screen area.
    - Top clusters unchanged: reserve about 440 by 124 px, or 2.63 percent, for the top-left turn and objective stack. No new top-right cluster.
    - Log patch A: 520 by 152 px, or 3.81 percent. Veil is 56 percent black alpha, so 44 percent of the scene remains visible through it. The shelf veil is 86 percent black for comparison. No fill beyond the veil.
    - Proposed persistent chrome: 22.96 plus 3.81 plus 2.63 equals 29.40 percent with the log open. With the log collapsed to a 28 px header it is 26.29 percent.
    - I treat Ryan's roughly 33 percent as combined old chrome shorthand, not shelf height. The old 216 px shelf alone was 20.0 percent, so 33 cannot be the shelf. The proposed open log is about 3.6 points under that 33 shorthand and about 6.7 points under when collapsed. If 33 is meant as an exact bound, I need its measured bounds before claiming a win.
    
    2. Faction silhouette kit
    
    Kit system:
    
    Fixed per class: bounding box and baseline, length to height ratio, mass distribution, engine count, and one class notch or negative cut. These carry class at 16 px.
    
    Swapped per faction: bow treatment, spine and superstructure, stern and engines, signature feature, and anchor detail kit.
    
    All faction changes are contour steps, contour bumps, or negative cuts. No interior shading, no glow fill, no painted windows.
    
    Anchor detail kit: turret silhouettes, antennae, nozzle segmentation, hangar mouths. These appear at selected-ship anchor size and above, not at fleet 16 px. They are contour add-ons or negative cuts.
    
    The kit is a token set over a shared class master. Glasswright may need a curved base override because it is not a metal hull family.
    
    Cruiser proof. Class constants: length 100, height 24, waist at 55 percent, two engine blocks, one dorsal mass, bow taper.
    
    Iron Mandate: two-step blunt glacis bow. Three terraced citadel blocks, aft taller. Squared twin engine blocks with rectangular nozzles. Signature is stepped fortress terrace and buttress notch. Detail kit adds crenellated turret bumps, block antennae, rectangular nozzle segmentation. Negative cuts are square embrasures between terraces. At 16 px the stepped top line and blunt bow survive.
    
    Glasswright: long leaf point bow. Smooth curved leaf ridge with pinched waist. Twin trailing leaf lobes around rounded engine mouths. Signature is a long lens-shaped negative cut along the spine to stand for lit interior without interior shading. Detail kit adds leaf tip fins, thin contour antennae, rounded nozzle segmentation. Negative cuts are the lens slit and lobe gaps. At 16 px the curve and point survive only if the curved base is allowed. If not, fallback.
    
    Dominion: forward cannon yoke bow. Long ion cannon barrel projects past the bow. Heavy armored cannon housing with low bridge behind. Twin block engines. Signature is cannon barrel with muzzle ring and negative gap under barrel. Detail kit adds muzzle ring segments, heavy turret silhouettes, square antennae. At 16 px the cannon must project at least 4 to 5 px beyond the bow or it is not a Dominion read.
    
    Hegemony: chisel wedge bow. Clean stepped naval bridge. Twin angled nozzles. Signature is the angular naval standard with bridge. Detail kit adds turret silhouettes, mast antennae, segmented nozzles. Negative cuts are angular bridge notches. At 16 px this is the baseline and may read as generic.
    
    16 px honesty: class silhouette is primary. One faction cue per faction can survive. Iron stepped top, Glasswright curve and point, Dominion cannon projection, Hegemony angular standard. Hegemony is weakest and will often fall back. Fallback is class-only silhouette plus faction text or grouping in the fleet strip, with full faction detail on the selected anchor. I will not fake faction detail with extra pixels or color. Color is not the faction carrier.
    
    Cost and shipping order:
    
    One agent pass for kit schema and five class masters.
    
    Hegemony swap set: one pass. Ship first because it is baseline and low risk.
    
    Iron Mandate swap set: one pass. Ship second because terraces read at small size.
    
    Dominion swap set: two passes because the cannon needs exaggeration and negative-gap QA.
    
    Glasswright swap set: two to three passes because the curved base override and lens cut are the hardest and least metal.
    
    Anchor detail kit: one pass per faction after silhouettes.
    
    16 px and anchor QA: one pass across all shipped factions.
    
    Order: Hegemony, Iron Mandate, Dominion, Glasswright, then remaining factions. Do not ship unique full silhouette art per class per faction before the kit is proven.
    
    3. Odds presentation
    
    Standing presentation:
    
    ABOUT 16 DAMAGE HIT 72%
    [shield glyph] 7 TO SHIELDS [hull glyph] 9 TO HULL
    
    First line carries total and hit chance. Second line carries the split with glyph plus figure plus short word label. Shield figure is Glacier. Hull figure is ink. Total is white. Hit chance may take the single ember accent. "About" survives and applies to the damage line. No bare figures. No hover-only meaning. The 8 is corrected to 9. "Prow" is removed under the pooled shield ruling. If the shield pool is zero, show [shield glyph] 0 TO SHIELDS rather than hiding the lane so the split still sums to the total. This fits the existing glyph plus word grammar and adds no panel.
    
    4. Refusals
    
    I refuse B as default. It doubles top-left stack weight and competes with turn and objective.
    
    I refuse an auto-hidden default log. The log's job is explanation without opening anything.
    
    I refuse bare two-figure odds, the 8 error, and "prow shield" after the pooled ruling.
    
    I refuse interior shading or glow fill for faction silhouettes, including Glasswright lit-from-within. Use negative cuts and anchor detail only.
    
    I refuse color-only faction reading and Glacier outside shield readouts.
    
    I refuse unique per-faction detail at 16 px if it becomes fake pixels.
    
    I refuse shelf growth beyond about 248 px without a new accounting.
    
    I refuse hover-only meaning and keyboard labels on the HUD face.
