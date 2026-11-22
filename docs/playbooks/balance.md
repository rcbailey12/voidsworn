# Balance

Run [the headless Godot balance simulator](../../godot/rules/sim/README.md) for campaign, campaign with rewards, and faction matrix measurements.

Use `campaign` or `campaignrewards` to measure a player ability. Set `PFACTION` to the faction id you want to field,
such as `deathless` for Eclipse or `chorus` for the Chorus. Leave it unset for a row per faction in each cell.
Set `ONLY_BOSS=1` for the boss cells and the elite comparison.

Use matching `PAIRSEED`, cell filters, and battles per cell for both arms. Report the ability id and its fired count
with the result. A row supports a balance number for that ability only if the player fleet fired it at least once.
