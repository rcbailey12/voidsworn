# Issue 1144: Truth pass

- `godot/scenes/battle/battle.gd` and `godot/rules/rules.gd`: The target card, hull ghost, hover and activation card all estimate the bearing guns against one declining shield pool. The preview uses hit odds and average damage, with each shot using the current side coverage and routing. Travelling torpedoes are estimated after direct fire at current defenses; movement, recharge and point defense can change the impact. Individual weapon tips show that gun by itself.
- `godot/campaign/campaign.gd` and `campaign3d.js`: Emergency reinforcements use the faction's existing cheapest eligible hull rule, also used for a win with no ships left. This yields the Warden-class frigate, Hullbreaker raider, Glasswright sliver, Eclipse mote, Chorus drone-spawn and Hegemony picket. Campaign parity invokes the browser's `battleScreen` in `campaign3d.js`; `campaign_run.js` and `data.js` do not own this grant.
- `godot/ui/campaign/campaign_ui.gd` and `godot/campaign/campaign.gd`: Hide unfinished capstone effect lines in lineage and the debrief tooltip. Keep the Nemesis banner only when the same surviving hunter has a remaining sector in which they can appear. The hunter still learns as before, and the screen says the effect is for a rematch.
- `tools/onboarding_cards.json` and `tools/test_onboarding.js`: Refresh the stale Brace, shield pool and clock expectations. Keep one intentional copy difference: the browser describes shield arcs while Godot describes the KEEL HUD bars. Both are checked, alongside the onboarding behavior and data hashes.

## Board-applied workflow patch

Apply this one-line addition after the import in the Godot game job. `--quick` covers the card text and focused checks; the existing parity job already runs the full suites. The script sets `XDG_DATA_HOME` on Linux and `APPDATA` on Windows for its isolated test profile.

```diff
--- a/.github/workflows/checks.yml
+++ b/.github/workflows/checks.yml
@@ -206,6 +206,7 @@
       - name: Headless Godot checks from the list (godot/tools/ci/godot_checks.txt)
         if: ${{ !cancelled() && steps.load.outcome == 'success' }}
         run: |
           sh godot/tools/ci/run_checks.sh 2>&1 | tee "$RUNNER_TEMP/run_checks.log"; code=${PIPESTATUS[0]}
           { echo '### Godot checks from the list'; echo '```'; grep -E '^  [a-z0-9_]+: |^  list: |^Ran |^PASS|^FAIL' "$RUNNER_TEMP/run_checks.log"; echo '```'; } >> "$GITHUB_STEP_SUMMARY"
+          node tools/test_onboarding.js "$GODOT" --quick || code=1
           exit $code
```

## Regression checks

- `godot/scenes/battle/test/volley_preview_test.gd` fires 128 seeded volleys per setup through the battle API and compares hit events with the numbers on the target card. It covers 1, 2 and 3 guns into bare hull and a low shield pool, plus a planned move with multiple shots, ion and piercing damage. The HUD estimate leaves the live ships and RNG alone. On main, the 3-gun low-pool preview said 15 shield and 21 hull; the rolls averaged 6.98 shield and 27.44 hull.
- `godot/campaign/test/truth_pass_test.gd` starts fights from reloaded one-ship saves for all six factions, checks that old Warden grants are kept without duplication, and builds the real mastery and Nemesis controls.
- `godot/tools/ci/godot_checks.txt` registers both checks with the Godot game job. The Node standing job has no Godot executable; the patch above adds the Node onboarding driver to the Godot game job, where one is already installed.

## Run 2: shield routing only on landed hits

Run 1 averaged the shield drain over the hit odds, so the preview spent the pool on shots that never landed. Combat only routes on a real hit. The preview now carries the pool as a small branch tree: each shot has a hit branch that removes a real pool amount and a miss branch that leaves the pool alone, and both branches keep their own chance. The result is the exact expectation over the hit and miss branches, using the same coverage, routing boost and routing loss as combat. The branch keys merge when two paths leave the same pool, so a normal volley stays small. Combat is unchanged.

- `godot/rules/rules.gd`: `previewVolley` and `_estimate_gun` now carry the pool branches in firing order, including the delayed torpedo pass. `_spend_shield` and `applyHit` are untouched.
- `godot/scenes/battle/test/volley_preview_test.gd`: adds Artoo's worked case beside the 85 percent cases. Four 30 percent shots, each strong enough to fill the facing, into a 60 point pool at 25 percent coverage. It fires 1024 seeded volleys through the battle API.

Before and after on that case:

- Run 1 code: preview said **23 shield**, seeded volleys averaged **19.25** (tolerance 1.87). The test failed.
- Fixed code: preview says **19 shield**, the same seeded floor averages **19.25**. The test passes, and the 1-, 2- and 3-gun bare, shielded and planned cases still pass.

Artoo's long-run numbers are 23.4 from the old preview and 19.14 from combat; the card rounds those to 23 and 19.
