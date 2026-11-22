# The fleet list

The fleet list shows the approved concept and ruling, build stage, and open job for each ship.

- [Fleet records](fleet.json) hold the approved picks, rulings, jobs and notes. Update them in the ship pull request.
- Run `node contrib/opus/tools/fleet_list.js --write` from the repo root to generate the current table at
  `docs/ship_pipeline/FLEET.generated.md`. Git ignores this local copy so ship branches can merge their source changes
  without also merging the rendered table.
- Run `node contrib/opus/tools/fleet_list.js --pick "faction|Class"` for the approved pick line in a job brief.

Standing checks validate the fleet records against the hull table and ship manifest on the merged tree.
