# Fleet inventory, Nov 14, 2026

Issue 708. Pinned to main at 00ce0417e63cae97173decf6f8fc584459dcc84a (Nov 14, 2026). One row per hull in data.js HULLS at the pin: 51 entries, being 30 faction base hulls, 18 variants, and the 3 squadron craft (fighter, bomber, spore). With the spore counted as the Chorus's own craft, that is the brief's "49 faction hulls plus fighter and bomber". One ruled hull is not in data.js yet and gets its own row at the end (d_totality).

Status words used in the table:

- **Built**: a build sheet exists and the sheet records a PC-side build or render of the model, or a later ruling records the ship in game. The five, with their evidence: c_boss (rendered on Ryan's PC; its A16 fixture is the one CI guards), c_marauder (the sheet records the PC recipe build path for A17.blend), c_hulk (painted in game, R244), d_boss (painted in game, R243), d_harvester (rendered on Ryan's PC). The contrast the sheets themselves draw: chorus_C10 and chorus_C11 say "nothing ran on Ryan's PC", and corsair_A18 and corsair_A19 say "no PC run yet"; those four are Build sheet, below.
- **Build sheet**: a build sheet exists; the PC recipe run is still to come on the sheet's own wording.
- **Concept accepted**: a picture Ryan accepted; no build sheet yet.
- **Shape settled**: the shape is accepted and the route is a shape-locked build sheet (R204 (3), R206 (2)); the style pass failed in image rounds, so no picture is a build reference yet and there is no sheet.
- **Design pack only**: the issue 622 pack and its ruled answers govern the class; no accepted picture.
- **Kit swap**: a data.js variant (HULL_VARIANTS): the base hull's model with changed weapons and stats. No variant has its own concept or sheet anywhere in the repo.
- **Spec only**: a text design exists; no pictures and no recorded acceptance.
- **Nothing yet**: no concept, no pack governs the design, no sheet. Used once (h_boss), where the only record is Ryan's ruling that the ship gets its own design.
- **Not in data**: a ruled hull with no data.js entry at the pin, so it cannot enter the pipeline. Used once (d_totality).

Concept paths are relative to the repo root. Build sheets live under docs/ship_pipeline/build_sheets/.

| Hull id | Name (data.js) | Faction | Class | Kind | Accepted concept (code, path) | Accepted by | Build sheet | Status |
|---|---|---|---|---|---|---|---|---|
| warden | Warden-class frigate | Sunward Crusade | Frigate | base | none | n/a | none | Design pack only |
| harrow | Harrow-class destroyer | Sunward Crusade | Destroyer | base | none | n/a | none | Design pack only |
| penitent | Vigil-class cruiser | Sunward Crusade | Cruiser | base | none | n/a | none | Design pack only |
| reliquary | Hearth-class carrier | Sunward Crusade | Carrier | base | none (flank bays tentative until seen, ruled Nov 12, 2026) | n/a | none | Design pack only |
| cathedral | Bastion-class battleship | Sunward Crusade | Battleship | base | none | n/a | none | Design pack only |
| ascendant | Daybreak-class dreadnought | Sunward Crusade | Dreadnought | boss | S8 shape: contrib/codex/design/concept_round5_2026_11/voidsworn_S8_sheet.jpg (copy in contrib/muse/design/faction_packs_2026_11/sunward/) | R185 (1); style passes S9 and S10 failed (R201, R206) | none | Shape settled |
| vs_harrow_t | Harrow torpedo-destroyer | Sunward Crusade | Destroyer | variant of harrow | rides harrow | n/a | none | Kit swap |
| vs_penitent_g | Vigil gun-cruiser | Sunward Crusade | Cruiser | variant of penitent | rides penitent | n/a | none | Kit swap |
| vs_penitent_l | Vigil lance-cruiser | Sunward Crusade | Cruiser | variant of penitent | rides penitent | n/a | none | Kit swap |
| h_picket | Hegemony picket | Hegemony | Frigate | base | none | n/a | none | Design pack only |
| h_interdictor | Cordon destroyer | Hegemony | Destroyer | base | none | n/a | none | Design pack only |
| h_vanguard | Vanguard cruiser | Hegemony | Cruiser | base | none | n/a | none | Design pack only |
| h_dominion | Dominion dreadnought | Hegemony | Battleship | base | H10 shape: contrib/muse/design/concept_round7_2026_11/hegemony_H10_sheet.jpg and hegemony_H10_beauty.jpg | Picked by R198 (1); style pass H12 failed (R204) | none | Shape settled |
| h_boss | The Iron Mandate | Hegemony | Super-dreadnought | boss | none: Ryan ruled Nov 12, 2026 that the Iron Mandate gets its own design, not a scaled Dominion | n/a | none | Nothing yet |
| h_picket_i | Picket interceptor | Hegemony | Frigate | variant of h_picket | rides h_picket | n/a | none | Kit swap |
| h_interdictor_e | Cordon column escort | Hegemony | Destroyer | variant of h_interdictor | rides h_interdictor | n/a | none | Kit swap |
| h_vanguard_g | Vanguard gunship | Hegemony | Cruiser | variant of h_vanguard | rides h_vanguard | n/a | none | Kit swap |
| c_raider | Hullbreaker raider (the Sniffer) | Ashfall Hullbreakers | Frigate | base | A18: contrib/muse/design/class_family_corsair_2026_11/corsair_A18_beauty.jpg (v3) | Ryan, Nov 12, 2026, 19:37 CST | corsair_A18 | Build sheet |
| c_reaver | Hullbreaker gutship (the Mauler) | Ashfall Hullbreakers | Destroyer | base | A19: contrib/muse/design/class_family_corsair_2026_11/corsair_A19_beauty.jpg (v6) | Ryan, Nov 12, 2026, 19:37 CST | corsair_A19 | Build sheet |
| c_marauder | Hullbreaker wrecker (the Pack Hunter) | Ashfall Hullbreakers | Cruiser | base | A17: contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg | R201 | corsair_A17 | Built |
| c_hulk | Hullbreaker hulk-carrier (the Den) | Ashfall Hullbreakers | Carrier | base | A20: contrib/muse/design/class_family_corsair_2026_11/corsair_A20_beauty.jpg (v2s) | Ryan, Nov 12, 2026, 19:37 CST | corsair_A20 | Built |
| c_boss | Warlord's Pyre-Barge | Ashfall Hullbreakers | Battle-barge | boss | A16: contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg | R201 | corsair_A16 | Built |
| c_reaver_t | Turret gutship | Ashfall Hullbreakers | Destroyer | variant of c_reaver | rides c_reaver | n/a | none | Kit swap |
| c_hulk_g | Gun-hulk | Ashfall Hullbreakers | Carrier | variant of c_hulk | rides c_hulk | n/a | none | Kit swap |
| c_marauder_g | Trophy wrecker | Ashfall Hullbreakers | Cruiser | variant of c_marauder | rides c_marauder | n/a | none | Kit swap |
| b_drone | Chorus drone-spawn | The Chorus | Frigate | base | C12: contrib/muse/design/class_family_chorus_2026_11/chorus_C12_drone_spawn_v10.jpg and chorus_C12_drone_spawn_sheet_v2.jpg | Ryan, Nov 13, 2026 | none | Concept accepted |
| b_spitter | Chorus spitter | The Chorus | Destroyer | base | C13: contrib/muse/design/class_family_chorus_2026_11/chorus_C13_spitter_v7.jpg and chorus_C13_spitter_sheet_v1.jpg | Ryan, Nov 13, 2026 | none | Concept accepted |
| b_razor | Chorus bladeback | The Chorus | Cruiser | base | C11: contrib/muse/design/concept_round8b_2026_11/chorus_C11_beauty.jpg and chorus_C11_sheet.jpg | R204 | chorus_C11 | Build sheet |
| b_brood | Chorus brood-sac | The Chorus | Carrier | base | C14: contrib/muse/design/class_family_chorus_2026_11/chorus_C14_brood_sac_v11.jpg and chorus_C14_brood_sac_sheet_v5.jpg | Ryan, Nov 13, 2026 | none | Concept accepted |
| b_boss | The Ninefold Maw | The Chorus | Bio-titan | boss | C10: contrib/muse/design/concept_round8b_2026_11/chorus_C10_beauty.jpg and chorus_C10_sheet.jpg | R204 | chorus_C10 | Build sheet |
| b_spitter_s | Spitter stinger | The Chorus | Destroyer | variant of b_spitter | rides b_spitter | n/a | none | Kit swap |
| b_razor_s | Bladeback stalker | The Chorus | Cruiser | variant of b_razor | rides b_razor | n/a | none | Kit swap |
| b_razor_e | Sun-eater bladeback | The Chorus | Cruiser | variant of b_razor | rides b_razor | n/a | none | Kit swap |
| i_wisp | Glasswright sliver | The Glasswrights | Frigate | base | none | n/a | none | Design pack only |
| i_blade | Glasswright lancet | The Glasswrights | Destroyer | base | none | n/a | none | Design pack only |
| i_song | Glasswright prism | The Glasswrights | Cruiser | base | none | n/a | none | Design pack only |
| i_carrier | Glasswright aperture | The Glasswrights | Carrier | base | none (lens bays approved Nov 12, 2026 only if they read differently from weapon lenses at battle distance) | n/a | none | Design pack only |
| i_boss | The Unfinished | The Glasswrights | Ark | boss | G15 shape: contrib/muse/design/concept_round7_2026_11/ithar_G15_sheet.jpg and ithar_G15_beauty.jpg | R196 ("I really like g15"); lens passes G17 and G18 failed (R201, R206) | none | Shape settled |
| i_wisp_l | Sliver lancer | The Glasswrights | Frigate | variant of i_wisp | rides i_wisp | n/a | none | Kit swap |
| i_song_w | Warded prism | The Glasswrights | Cruiser | variant of i_song | rides i_song | n/a | none | Kit swap |
| i_carrier_a | Ringing aperture | The Glasswrights | Carrier | variant of i_carrier | rides i_carrier | n/a | none | Kit swap |
| d_scythe | Eclipse mote | Eclipse | Frigate | base | E13, the Fan: contrib/muse/design/class_family_deathless_2026_11/deathless_E13_mote.jpg and deathless_E13_mote_sheet.jpg (v6) | Ryan, Nov 12, 2026 | none | Concept accepted |
| d_jackal | Eclipse flare | Eclipse | Destroyer | base | E14, the Annulus: contrib/muse/design/class_family_deathless_2026_11/deathless_E14_flare.jpg and deathless_E14_flare_sheet.jpg | Ryan, Nov 12, 2026 | none | Concept accepted |
| d_harvester | Eclipse zenith | Eclipse | Cruiser | base | E12: contrib/muse/design/concept_round8c_2026_11/deathless_E12_beauty.jpg and deathless_E12_sheet.jpg | R206 | deathless_E12 | Built |
| d_boss | The Unsetting | Eclipse | Tomb-ark | boss | E11: contrib/muse/design/concept_round8c_2026_11/deathless_E11_beauty.jpg and deathless_E11_sheet.jpg | R206 | deathless_E11 | Built |
| d_scythe_s | Mote sentinel | Eclipse | Frigate | variant of d_scythe | rides d_scythe | n/a | none | Kit swap |
| d_harvester_t | Turreted zenith | Eclipse | Cruiser | variant of d_harvester | rides d_harvester | n/a | none | Kit swap |
| d_jackal_h | Archive guard flare | Eclipse | Destroyer | variant of d_jackal | rides d_jackal | n/a | none | Kit swap |
| fighter | Fighter wing | shared (Hegemony and Glasswright rosters; Sunward falls through to the default, see gaps.md) | Squadron | squadron | none: per-faction fighter-role designs are text only in contrib/muse/design/squadrons_2026_11/synthesis.md | not recorded | none | Spec only |
| bomber | Bomber wing | shared (Hullbreaker roster; bomber role for the other launching factions) | Squadron | squadron | none: per-faction bomber-role designs are text only in contrib/muse/design/squadrons_2026_11/synthesis.md | not recorded | none | Spec only |
| spore | Spore swarm | The Chorus | Squadron | squadron | none: the Bile-Cyst Spore design is text only in contrib/muse/design/squadrons_2026_11/synthesis.md | not recorded | none | Spec only |
| d_totality | Eclipse totality | Eclipse | Battleship | ruled, not in data.js | none: contrib/muse/design/eclipse_battleship_2026_11/synthesis.md is text and prompts only, no pictures | Ruled by R63 (Eclipse gets a battleship class hull and no carrier); picture acceptance not recorded | none | Not in data |

Notes on rows a reader might trip on:

- The Hegemony flagship question: H10's mounts as drawn are h_dominion's (concept_round7_2026_11 README: h_dominion, hangar 1), and the issue 622 Hegemony pack names H10's class "Dominion dreadnought, battleship, 21.0". The boss hull h_boss (The Iron Mandate, super-dreadnought) is a different ship, and Ryan's Nov 12, 2026 ruling gives it its own design. Earlier shorthand that calls H10 "the Hegemony flagship" means the fleet's hero ship, not the boss hull.
- The Chorus frigate's guns now match its concept: the accepted C12 picture carries a spine volley (bioplasma F) that data.js did not have when the concept was accepted; the delivery flagged the data change as the Board's to make, Ryan ruled the fit on Nov 13, 2026 (b_drone back on guns, spine volley added to the tendril fit; spun out as issue 649), and at the pin data.js b_drone reads w: [['bioplasma','F'],['tendril','T']] (the change landed via PR 693, merged Nov 14, 2026).
- Sunward's S8 shape reference lives in the Codex tree (contrib/codex/design/concept_round5_2026_11/), with a copy in the issue 622 pack folder. Both are cited so the sheet designer finds it either way.
- The station (Vesper Reach, T2 damaged, accepted R206) is not a hull and is not in this table; its build is PR 700, open at the pin.
- Hull ids come from data.js itself. The issue 622 packs print class names, not ids; the id for each pack-governed class is the data.js entry of that name, matched by the chair and re-checked by the legs.
- Failed or dropped pictures (S9 and S10, H11 and H12, G10, G17 and G18) are history, not targets (factions.md); they are recorded in the issue 622 packs and are not rows here.

Sources: data.js HULLS, HULL_VARIANTS and FACTIONS at the pin (extracted and counted by the chair); the nine build sheet READMEs under docs/ship_pipeline/build_sheets/; docs/playbooks/factions.md (the concept redo table, Nov 11, 2026); the design folders' own READMEs, designs.md files and the issue 622 pack.md files under contrib/muse/design/; FINDINGS rulings as cited per row. Re-checked independently by DeepSeek and Qwen against an evidence pack (both PASS WITH CORRECTIONS; every count re-verified). Citations the pack did not carry (R183 (1), R204 (3), R206 (2), R241, the Nov 13, 2026 b_drone ruling, PR 693, PR 700) were verified by the chair against the pinned tree, FINDINGS and the live board before delivery.
