# Faction theme sheets (ships)

Issue 405, the ships track of docs/playbooks/PROGRAM.md. Written by the Board (Fable 5.2), Nov 10 2026, from the approved lore
(contrib/opus/compute/lore_bible_r8.md, the Look section of each faction), the 36 concepts in docs/ship_pipeline/concepts/, and
the owner's ship rulings in AGENTS.md. One sheet per faction. A concept, a three-view sheet (contrib/muse/design/concept_standard_2026_11/standard.md),
a hull build and a blob sweep are all judged against the sheet for that faction.

Ryan, Nov 10 2026 (R164), on hard points: "It should vary by size of ship, faction, etc. We want things to be on theme."

## Rules for every faction

- Space ships, not sea ships (owner, Oct 22 and Oct 24). No keels or keel fins, raked stems, porthole rows, lattice masts,
  cranes, crossbar masts, funnels, railings or stepped yacht decks. Use the space version: flat armoured bellies with chines,
  sensor housings, antenna arrays, heat radiators, engine bells, docking hatches.
- No gun ever faces backward. Bow guns face forward, side guns face out.
- Matched symmetric pairs at sensible hard points, on visible mounts. The Hullbreakers are the one exception.
- The ship must read at the battle camera (camera 170): one clear silhouette, one main colour, one accent light. Detail that
  only shows up close is a bonus, never the identity.
- Every hull has real thickness, a few decks and bulkheads inside, and authored break lines with matching inner faces (R98).
- Hard points are not a fixed count (R164). Gun and engine points come from the hull's own weapon slots and engines. Breach
  anchors (where the hull opens when it dies) scale with class and follow the faction's own way of breaking, below.

### Breach anchors by class (the base count; each faction's sheet says how they are placed)

| Class | Base breach anchors | Authored break lines |
|---|---|---|
| Escort, frigate | 2 | 1 |
| Destroyer | 3 | 2 |
| Cruiser | 4 | 2 |
| Capital, carrier, barge | 6 | 3 |
| Flagship, station | 8 | 3 or 4 |

A faction may add or remove one where its sheet says so. tools/recipe/check_export.py reads the expected count from the hull's
class and faction (issue 363), never from a constant.

---

## Sunward Crusade (`voidsworn`)

**In one line:** a black iron blade with burning spires.

- **Silhouette:** long, narrow dagger or spearhead, widest at the stern third. A row of tall radiator spires along the spine,
  tallest amidships. Symmetric.
- **Shape language:** forged, heavy, vertical. Broadside gun decks in long straight rows. Big engine bells. Plate with rivet
  lines, never rust.
- **Colours:** black iron, frost-white markings, bright ember (windows, engines, and the spires, which glow because they shed
  the reactor's heat).
- **Guns sit:** in broadside rows along both flanks, plus one heavy pair at the bow. Old manual gun decks: many small ports,
  evenly spaced.
- **Engines:** two to four large bells, ember orange, deep-set.
- **How it breaks:** along the gun decks. The hull splits lengthwise between deck rows, and the spire line snaps off as one
  piece. Inside: iron decks, ember-lit, gun crews' galleries. Breach anchors sit on the broadside deck line, evenly spaced.
- **Never:** rust (that is the Hullbreakers), blue light, a ram prow shaped like a ship's stem, cathedral windows so literal
  that it reads as another game's ship. The spires are radiators, not steeples: no crosses, no statues.
- **What the present concepts get wrong:** V1b_r_23 is a cathedral on a boat hull (stem bow, stepped decks): keep its mass and
  spire cluster, redraw the hull as a blade. V14_23 has wheel-like pods and red light: ember orange, and pods become radiator
  blocks.

## Hegemony Navy (`hegemony`)

**In one line:** a pale wedge with a line of blue light.

- **Silhouette:** clean flat wedge, sharp bow, low profile. One low sensor fin, not a tower. Symmetric and identical across the
  fleet: the same parts repeated at different sizes.
- **Shape language:** machined, modular, horizontal. Flush panels, straight seams, repeated modules. Ion prongs at the bow.
- **Colours:** pale grey, steel-blue trim, implant-blue light strips that pulse in time across the whole fleet.
- **Guns sit:** in rows of identical turrets on the upper deck, evenly pitched, plus the bow prongs. Small drone bays in the
  flanks.
- **Engines:** a flat row of rectangular blue-white nozzles.
- **How it breaks:** in modules. It parts cleanly at the bulkhead rings between modules, like a spine coming apart. Inside:
  white corridors, blue emergency light, racks of identical equipment. Breach anchors sit on the module joints.
- **Never:** rust, asymmetry, ornament, warm light. No yacht decks, no conning tower, no tall mast.
- **What the present concepts get wrong:** H7 to H10 read as yachts or submarines (a tall sail-like tower, stepped cabin
  tiers); H4_11 is a sea battleship with a mast tower. Keep the wedge and the blue lines; flatten the superstructure into one
  low fin and turret rows.

## Ashfall Hullbreakers (`corsair`)

**In one line:** a lopsided brick of rust and stolen plate that runs dark.

- **Silhouette:** blunt, heavy-bowed, uneven. Bigger on one side than the other. Listening dishes and wake-sniffer scoops at
  the bow, boarding claws under it. The one faction allowed to be junky.
- **Shape language:** bolted, patched, chained. Hull plates torn from every other faction, kept in their old colours. Chains
  between hull sections.
- **Colours:** soot black, rust, dried-blood red, patches of trophy colour (pale Hegemony grey, a shard of Glasswright
  crystal, violet Eclipse plate), dim red running lights.
- **Guns sit:** wherever they could be bolted: mismatched calibres, off-centre, still never facing backward. Casemates in the
  bow, tube racks on the deck.
- **Engines:** mismatched bells with a red-orange glow, one often larger than the rest.
- **How it breaks:** at the seams. Patch plates tear off first, then the hull parts where sections are chained together, and
  the chains hold the pieces for a moment. Inside: scavenged frames, loot holds, kennel decks. One more breach anchor than
  the base count, placed unevenly.
- **Never:** clean symmetry, bright light, fresh paint. And still no sea-ship parts: junk is allowed, a boat is not.
- **What the present concepts get wrong:** all five carry lattice masts, cranes, porthole rows and keel fins (Muse's C15s trial
  shows them plainly). The masts become listening dishes and antenna clusters, the cranes become boarding claws and grapple
  arms, portholes go, and the keel fin becomes a ventral scoop or goes.

## The Glasswrights (`ithar`)

**In one line:** a silver needle carrying sails of light.

- **Silhouette:** a slender spindle hull with two to four huge crystal vanes, like fans or petals. The vanes are most of the
  ship's outline. Symmetric.
- **Shape language:** grown crystal and drawn silver. Facets, lenses, mirrors that turn to catch light. No plates, no rivets.
- **Colours:** clear crystal, silver, a rainbow fringe on every edge, and a stored light glowing deep inside the hull.
- **Guns sit:** in the lens bays along the spindle. The prism lance is the hull's own stored light let out through a bow
  lens: a white core with a rainbow fringe. Vanes carry no guns.
- **Engines:** no flame. A soft white bloom at the stern lens.
- **How it breaks:** it shatters. Vanes shear off first as whole panes, then the spindle snaps at a lens bay and the stored
  light spills out. Inside: crystal lattice and light, no decks to speak of. One fewer breach anchor than the base count, all
  on the spindle; each vane is its own break piece.
- **Never:** rust, smoke, armour plate, flame. No rigging, no masts: a vane is a crystal pane, not a sail on a spar.
- **What the present concepts get wrong:** the vanes are drawn as cloth sails (soft folds, I16_11 has a mast), and several are
  lopsided. Make them rigid faceted panes in matched pairs. The vanes are the hardest material in the game to build: see the
  note on the finished battle below.

## Eclipse (`deathless`)

**In one line:** a black sunshade with a ring of pale fire behind it.

- **Silhouette:** a broad layered fan, half-disc or ring, with the ship sheltering behind it. Seen from the front it is a dark
  disc with a thin bright corona. Symmetric.
- **Shape language:** shield plates in overlapping bands, eclipse rings around the engines. The old carved-bone ribs become
  shield-plate bands and rings on the next dressing pass; the shapes stay.
- **Colours:** dark violet-black plates, a white-gold corona, violet-white inner glow.
- **Guns sit:** behind the shade's rim, firing through gaps between plates, and in the central spire.
- **Engines:** no flaming bells. A ring of white-gold light, like the sun behind a moon.
- **How it breaks:** in layers. The shade's plates peel away band by band, then the ring separates from the core. Inside:
  archive vaults, dark stone-like decks, violet light. Breach anchors sit on the shade's bands, spaced around the arc.
- **Never:** green light (the present concepts are all green: that is the retired look), bone and skulls, flame.
- **What the present concepts get wrong:** every one glows green, and D9_23 is a ribcage. Recolour to violet and white-gold;
  turn ribs into plate bands. D21_23 (the half-disc) and D22_23 (the ring) are the shapes to build the fleet around.

## The Chorus (`chorus`)

**In one line:** a grown thing with lit sacs, hungry.

- **Silhouette:** a segmented grub or a swollen sac trailing tendrils. Rounded, never straight-edged. Symmetric where a body
  would be.
- **Shape language:** grown, not built: ridges, pores, veins, glowing sacs, scar tissue that regrows. No panels, no pipes, no
  metal at all.
- **Colours:** dark olive-brown flesh, ochre chitin, bile yellow-green light from inside the sacs.
- **Guns sit:** in mouths, spines and sacs: a weapon is an organ. Brood sacs along the flanks for the wings.
- **Engines:** no nozzles. Pulsing vents or trailing tendrils with a yellow-green glow.
- **How it breaks:** it bursts and tears. Sacs rupture first, then the body tears between segments. Inside: flesh and bone
  (R98), wet and lit from within. Breach anchors sit on the sacs and segment joins; one more than the base count on the big
  ones, because every sac is a place to burst.
- **Never:** metal masts, antennas, conning towers, hull plates, red or magenta flesh.
- **What the present concepts get wrong:** B20, B21 and B16 carry small metal towers and antennas on their backs: remove them.
  B16_23 is magenta-red: bring it to olive and ochre. B22_11 is cut off by its own shadow and needs a full redraw.

---

## The finished battle: which fleet faces the Hullbreakers

The Hullbreakers are one side (their barge and cruiser are the furthest along). The other side is Ryan's pick (program
decision 2). The Board's order of preference, with the reason:

1. **Hegemony Navy.** Pale grey and blue against soot and rust is the strongest contrast in the game at the battle camera, so
   every hit, shield and death reads. Hard, flat, repeated shapes are what the ship recipe already does well, and one module
   set makes three hulls. Lowest risk, fastest proof.
2. **Sunward Crusade.** The game's own name-bearers and a strong look, but black iron against rust on a dark sky is dark on
   dark: the battle would lean on the ember light alone to be read.
3. **The Glasswrights.** The most beautiful result if it works. Clear crystal with a light inside is a new material and a
   new way of breaking, so it is the riskiest first proof. Better as the second battle, once the recipe is proven.

Eclipse and the Chorus are not offered for the first battle: Eclipse needs its whole colour redo first, and the Chorus needs
a flesh pipeline the recipe does not have yet.
