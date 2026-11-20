# Issue 1268: nebula colour sheet (r1, Nov 20 2026)

Stage: capture-only option sheet. No game default changed.

- `NEB1268_overview_r1.jpg`: all five regions (rows) by five colours (columns); the yellow box is Opus's pick.
- `NEB1268_<region>_r1.jpg`: one region at camera 170 plus camera 26 crops of every option.
- Options: A violet (today, R82), B smoky slate, C dust gold, D steel blue (the Hegemony share from faction_looks.json), E rose. No indigo to purple gradient (RULEBOOK 10.9).
- Same generated storm-map battle per region (Hegemony enemies, first seed from 1268 with a 5+ hex nebula within 4 hexes of the ion storm; seed 1269 in every region). Storm bolts are today's (issue 1269 not merged).
- Drawn in a cloud thread with Godot 4.7.2 Forward+ on the lavapipe software Vulkan driver, quality high, 1280x720. Ships are hidden: the cloud copy has no built hulls. `capture_rows.json` has each run's region, seed and colour values.
- Rerun: `VS_SHEET_HIDE_SHIPS=1 VS_NEBULA_LIT=r,g,b VS_NEBULA_GLOW=r,g,b VS_NEBULA_SHADOW=r,g,b godot --path godot --resolution 1280x720 --script res://world/sky_sheet_shots.gd -- --out DIR --region nebula --tag C_gold`.

Opus's picks: nebula C gold (violet sinks into the violet-pink sky there), frontier C gold, boneyard E rose, deep A violet, world A violet. D steel blue is the one to rule out: it is too close to the teal ion storm.

## r2 (Nov 20 2026): Ryan picked rose everywhere

Ryan: "shouldn't we have nebulas be one color? ... I want it to be semi realistic", then "Yes agree on rose". world_living.gd now
draws the battle nebula in one rose colour (NEBULA_LIT, NEBULA_GLOW, NEBULA_SHADOW, NEBULA_DARK) in every region and against
every faction; the R82 violet clamp and the faction tint share are gone. RULEBOOK 10.9 is rewritten in the same PR.
`NEB1268_rose_default_r2.jpg` is the game default with no override (nebula and boneyard regions, c170 and c26; cloud render,
ships hidden). The capture-only VS_NEBULA_* override stays for later sheets.
