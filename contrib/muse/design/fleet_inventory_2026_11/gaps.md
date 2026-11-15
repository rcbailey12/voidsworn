# Fleet gaps, Nov 14, 2026

Issue 708, companion to inventory.md in this folder. Pinned to main at 00ce0417e63cae97173decf6f8fc584459dcc84a (Nov 14, 2026). Counts come from inventory.md; every claim cites its source there or below.

## The counts

- 30 faction base hulls. Of those: 5 built (c_boss, c_marauder, c_hulk, d_boss, d_harvester), 4 with build sheets awaiting their PC recipe runs (c_raider, c_reaver, b_boss, b_razor), 5 with accepted concepts and no sheet (b_drone, b_spitter, b_brood, d_scythe, d_jackal), 3 with shapes settled and no sheet (ascendant, h_dominion, i_boss), 12 with a design pack only (all Sunward and Glasswright classes below the flagship, plus the three Hegemony roster classes), and 1 with nothing (h_boss).
- Build sheets still needed: 21 of 30 base hulls (Sunward 6, Hegemony 5, Glasswrights 5, Chorus 3, Eclipse 2, Hullbreakers 0).
- Concept pictures still needed: 13 hulls (listed per faction below), plus pictures for d_totality once it exists in data.
- 18 variants: all kit swaps on their base hulls. No variant has its own concept or sheet, and no ruling asks for one yet.
- Squadron craft: 3 hulls (fighter, bomber, spore), all spec only.

## Per faction, in build order

The order inside each faction follows the Board's recorded next step where one exists: the finished battle is Sunward against Eclipse (R180), Sunward's flagship sheet is the named next job, and then a fleet brief per faction (docs/playbooks/factions.md, "Next"). The order of the factions after Eclipse is the chair's proposal, marked as such.

### Sunward Crusade (6 sheets, 5 pictures)

1. ascendant (flagship): build sheet from the settled S8 shape. This is the single named next step in factions.md. No new picture is wanted: S9 and S10 both failed the style (R201, R206), and the route is the shape-locked sheet (R206 (2)).
2. The five classes (warden, harrow, penitent, reliquary, cathedral): each needs its own concept inside the S8 language (family, not copies: Ryan's standing principle, Nov 12, 2026), then a sheet. The issue 622 Sunward pack already carries the ruled answers: bows and spire profiles vary by class, the lance recess appears only on lance classes, and the carrier's flank bays stay tentative until Ryan sees them on the reliquary.

### Eclipse (2 sheets, 0 pictures, 1 data gap)

1. d_boss and d_harvester are built; d_scythe's E13 and d_jackal's E14 concepts are accepted (Nov 12, 2026) and need build sheets. With those two sheets the whole faction is sheeted, which completes the Eclipse half of the finished battle.
2. d_totality: R63 ruled that Eclipse gets a battleship class hull and no carrier. The hull is not in data.js at the pin, so it cannot enter the pipeline at all. contrib/muse/design/eclipse_battleship_2026_11/synthesis.md holds a text look and three image prompts; no picture was drawn or accepted. Needs, in order: a data.js entry (the Board's), concept pictures, Ryan's acceptance, a build sheet.

### The Chorus (3 sheets, 0 pictures)

b_drone (C12), b_spitter (C13) and b_brood (C14) were accepted Nov 13, 2026 and need build sheets; b_boss and b_razor are sheeted and awaiting PC runs. The Chorus is the closest faction to done after the Hullbreakers. One data note, already closed: the frigate's spine volley is in data.js at the pin (PR 693), so the C12 sheet can be written against the real fit.

### Ashfall Hullbreakers (0 sheets, 0 pictures)

Complete. All five base hulls have accepted concepts and build sheets; c_raider and c_reaver await their PC recipe runs, the other three are built. Nothing is owed here except those two runs, which are Board work, not concept work.

### Hegemony (5 sheets, 4 pictures)

1. h_boss (The Iron Mandate): the faction's largest gap. Ryan ruled Nov 12, 2026 that it gets its own design rather than a scaled Dominion. No concept exists. It needs a concept of its own, then a sheet.
2. h_dominion: build sheet from the settled H10 shape (the S8 route: no more image rounds, H12 failed, R204).
3. h_picket, h_interdictor, h_vanguard: own concepts inside the H10 language, then sheets. The issue 622 Hegemony pack governs the classes.

### The Glasswrights (5 sheets, 4 pictures)

1. i_boss: build sheet from the settled G15 shape, with the lens work R196 (2) specifies (grown in, no pod, bracket, ring or seam, still able to rotate). G17 and G18 both failed on exactly this (R201, R206), so the sheet, not another image round, carries it.
2. i_wisp, i_blade, i_song, i_carrier: own concepts inside the G15 language (ruled Nov 12, 2026: family but unique, each class its own concept), then sheets. Ruled answers already in hand from the issue 622 pack: twin bow apertures (R183 (1), confirmed Nov 12, 2026), and the carrier's grown lens bays are approved only if they read differently from weapon lenses at battle distance.

## Squadron craft: what is needed, and the shared-or-per-faction answer

The three squadron hulls (fighter, bomber, spore) are shared data entries today, and in game they fly as three shared meshes (per contrib/muse/design/squadrons_2026_11/synthesis.md, citing hull_table.gd). The spec in that folder answers the shared-or-per-faction question at the design level: build both a fighter-role and a bomber-role mesh for all five launching factions, 10 meshes, each in its faction's language; the Chorus spore role rides the Chorus bomber-role mesh (the Bile-Cyst Spore). That answer is a chair synthesis with a GO WITH CONDITIONS verdict and one owner question left open in the folder; no Ryan acceptance of the craft designs is recorded anywhere in the repo, and there are no pictures, only text designs.

So what is actually needed:

1. A ruling that the per-faction answer stands (or that shared meshes with faction paint are enough). Until then the 10-mesh build has no accepted basis.
2. Concept pictures per craft, or a ruling that craft are sheet-only work like the S8 route. Craft are small and numerous; the concept rounds never drew them (the round 2 to 5 escorts are background dressing in hero pictures, not craft concepts).
3. Two data facts to settle: the Sunward roster entry has no sq key and falls through to the default (flagged in the synthesis; it needs an explicit sq: 'fighter' if Sunward wings are intended), and Eclipse fields no wings (sq null) with its two craft designs fenced in the synthesis until someone rules whether Eclipse gets wings at all. Eclipse's carriers do not exist (no carrier class, R63), so the fenced designs may simply stay fenced; this file records them so the question is visible. The synthesis's named designs, for the record: Sunward Ember Dart and Pyre-Lance; Hegemony Grid-7 Interceptor Drone and Grid-12 Strike Drone; Hullbreakers Shrike Gun-Cutter and Gaff-Skiff Breacher; Chorus Chitin-Mite Hunter and Bile-Cyst Spore; Glasswrights Starling Shard and Heliograph Prism; Eclipse Oculus Automaton and Corona Singularity Node (the two fenced ones).

## Variants: the open question

All 18 variants are kit swaps in data (HULL_VARIANTS changes weapons and stats on a copy of the base entry). No variant has a concept, a sheet, or a ruling about its look. Most read fine that way (a gun-cruiser is the cruiser with different guns, and R241 makes the guns themselves the visible difference). Two names suggest more than a weapon change and are worth one Board question rather than silent assumption: b_razor_e (Sun-eater bladeback) and i_carrier_a (Ringing aperture). The inventory takes no position; it records that the question has never been asked.

## What this file does not cover

The station (Vesper Reach T2) is a board object, not a hull; its build is PR 700, open at the pin. Admiral portraits, Nemesis ships as dressed variants of existing hulls, and campaign-only craft are outside data.js HULLS and outside this inventory.
