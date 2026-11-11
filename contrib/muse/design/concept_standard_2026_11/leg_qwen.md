# #398 leg: Qwen (writer)

Run record: Nov 10, 2026 09:22-09:25 CST, cloud browser, chat https://chat.qwen.ai/c/59728966-6293-4866-b706-e56500255586. Both model gates passed (selector showed Qwen3.8-Max before sending; header still showed it after generation). Single reply, no parallel responses. PACK.md attached via the grant only.

Chair screening notes: a clean, complete leg. One catch: section 1 describes the side camera as "dead-level with the waterline plane" while its own section 4 bans naval contamination; the word is a leftover and the synthesis will not carry it. Its drift figures (5 to 15 percent proportions, colour breaks sliding 10 to 20 percent) are plausible general claims, not measurements from this trial; the synthesis uses the trial's own observed failures instead. Adopted in large part: the fail-list structure, the disagreement table (side for length and height, top for beam and lateral, three-quarter for surface), the engine-end TO BE DESIGNED flag, and the missing-feature rule.

---

CONCEPT SHEET STANDARD - SPACE FLEET TACTICS (VOIDSWORN)
Standard ref: VS-CS-398 - Applies to all faction ship concepts - Trial: Hullbreaker cruiser C15s

1. THE THREE VIEWS
Every concept sheet shows the same design in exactly three views. No more, no fewer.
- View A, three-quarter: camera 30 deg above the horizontal plane, 45 deg off the ship's centreline to the port bow. Bow points to the viewer's left.
- View B, true side: camera at 0 deg elevation, 90 deg off the centreline, port side facing the viewer. Bow left. Orthographic projection; no perspective foreshortening.
- View C, true top: camera at 90 deg straight down, looking at the deck. Bow points up in the frame. Orthographic projection.
All three views sit on the same baseline and share the same orientation (bow left in A and B; bow up in C).

2. SHARED LIGHTING
One setup for all three views, no exceptions. Key light: single hard source, 45 deg up and 30 deg forward of the port bow, colour temperature 5500 K (neutral daylight). Fill: soft ambient at 20 percent of the key's intensity, from the opposite side, no colour tint. Background: flat matte black. No gradient, no stars, no grid. Shadows fall consistently across all three views; the key vector is the same in every view.

3. WHAT EACH VIEW MUST SHOW
Every view must let a builder answer these questions without guessing. If a view cannot answer one, the sheet fails.
- Scale: a drawn scale bar and the ship's length in world units taken from build data (e.g. "C15s, 24 wu"). Never let the reader estimate length from the drawing alone.
- Bow profile and prow overhang: the shape of the prow and how far the prow tip extends forward of the first structural station (the foredeck break). Mark the overhang with a dimension callout.
- Deck edge line: the visible upper edge of the hull on each side, drawn as a clear continuous line.
- Every gun mount: position along the length (as percent of LOA from the prow tip), which deck or housing it sits in, and the direction the barrel(s) point. Guns never point backward. If a barrel is trainable, mark the fixed rest position.
- The belly: the underside of the hull. In View B show the belly line and any keel blades, fins, or landing gear. In View C the belly is hidden; note "belly detail: see View B."
- The engine end: the stern face, nozzle count, nozzle shape, and any exhaust glow. If the existing concept does not pin these down, the sheet must state "ENGINE END, TO BE DESIGNED" in red text so the build side knows it is open.
View-specific additions:
- View A (three-quarter): shows volume and massing. Must show port-side detail, the foredeck slope, any superstructure height.
- View B (true side): shows the full profile. Hull steps, colour breaks, porthole rows, bridge height, mast, crane, keel blade all read here. Gun barrels must be drawn at their rest angle with a small arrow showing fire direction.
- View C (true top): shows the deck plan. Centreline weapons, deck-edge equipment (cylinder racks, walkways), bridge footprint, beam at the widest point. Keel blades and belly fins cannot appear here; if they do, the sheet fails.

4. CONSISTENCY RULES, HOW A SHEET FAILS
A sheet fails the standard if any of the following are true. These are reject conditions, not suggestions.
- Length mismatch: the distance from prow tip to stern face differs by more than 2 percent between any two views, or differs from the stated build-data length.
- Beam mismatch: the widest point measured in View C does not equal the widest point visible in View A or the hull width implied in View B.
- Gun conflict: a gun appears in one view at a position or direction that contradicts another view. A gun pointing aft in any view is an automatic fail.
- Feature ghost: a feature (mast, crane, cylinder rack, casemate, fin) appears in one view but is absent from another view where it must be visible.
- Colour break drift: the station where the hull colour changes sits at a different percentage of LOA in different views.
- Lighting contradiction: shadow direction or highlight placement implies a different key-light position across views.
- Missing scale or length: no scale bar, or no stated length in world units.
- Naval contamination: any element that reads as a naval or sea vessel. These are space ships.
If a sheet fails on any one of these, it goes back. There is no "close enough."

5. DISAGREEMENT PROTOCOL
When the three views disagree, the listed view wins and the other views must be corrected to match.
- Overall length, prow overhang, position along the length axis: View B (true side) wins. Orthographic; View A compresses the length axis.
- Heights (bridge, mast, superstructure, hull depth): View B wins. Only the true side gives unprojected vertical measurement.
- Beam and lateral placement of deck items: View C (true top) wins.
- Gun placement: View C for lateral, View B for longitudinal. If both are needed, state both.
- Gun direction: View B for elevation, View C for traverse. View A is advisory only for direction.
- Colour and colour-break station: View B for the break station; View A for confirming the colour under the shared key light.
- Surface detail (panel lines, rivets, rust patches, portholes): View A wins. Three-quarter reveals surface modelling; flat views flatten it out.
Missing-feature rule: if a feature appears in one view but is absent from another view where it should be visible, the sheet is flagged, not silently corrected. The concept artist must add the feature to the missing view or remove it from the view where it appears, and annotate the change. Belly-only elements (keel blade, ventral fin) are exempt from View C and must carry a note: "Visible in View B only; no top-view footprint." Deck elements must still appear on the deck edge or superstructure in View B. Unresolved: the sheet fails under rule 4 and returns to the artist.

6. HONEST NOTE, IMAGE MODELS AND THREE-VIEW CONSISTENCY
How well do today's image models hold one design across three generated views? Not well enough to trust without checking. Generation models treat each image as a fresh sample; even with a detailed shared prompt, a reference image, or a character-sheet LoRA, the model re-invents geometry every generation. In practice:
- Typical drift (leg's general figures, not measured from this trial): hull proportions shift 5 to 15 percent between views; gun counts change; colour breaks slide forward or aft by 10 to 20 percent of LOA.
- Worst drift points: the engine end (models invent nozzles freely), belly detail (keel blades vanish or multiply), and small deck items (cylinder racks, cranes), which the model treats as optional decoration.
- What holds reasonably well: overall silhouette family, dominant colour palette, and broad massing. Fine geometry does not survive.
What the build side should do about it:
1. Never accept generated views as a final sheet. Treat them as a fast sketch for layout and mood. Every dimension the build needs must be checked against the build-data numbers and the disagreement table above.
2. Overlay and measure: drop all three views into a CAD viewport or image editor at the same scale; check length, beam, and gun positions with a ruler before modelling starts.
3. Pin what the model won't: write explicit dimension callouts on the sheet. If it is not written, it is not fixed, and it will become an argument at the build table.
4. Flag the engine end: if the existing concept does not define nozzles, say so in red. Do not let a generated image silently invent them and then treat them as canon.
5. Keep the C15s chair-verified inventory as the ground truth for this trial. The generated views are candidates judged against that inventory, not the other way round.

Standard drafted for the Voidsworn concept-redo pipeline, first applied to Hullbreaker cruiser C15s. Build side: if a sheet does not pin it down, it is not agreed. Ask before you assume.
