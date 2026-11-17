# FL5, The Manifest (issue 868, R285)

The Fleet and refits page follows Ryan's settled FL5: a damage-first manifest, a selected ship workspace, and a narrow specification sheet. Twelve ships fit without scrolling at 1920x1080 and 3840x2160. Larger fleets and long names scroll at the same readable type size. Only Done has an ember box.

The pictures use the installed game models through ShipView. Each template renders once per page and shares its texture between the large picture and the manifest strips. No concept art or new hull assets are shipped. A missing or unloadable model says Model unavailable; capture runs fail if a required model is absent or any placeholder was drawn.

## Review pictures

- [FL5 beside the 1080 build](FL5_compare_1080.jpg)
- [FL5 beside the 2160 build](FL5_compare_2160.jpg)
- [Damaged ship](FL5_damaged.jpg), [hold](FL5_hold.jpg), [doctrine](FL5_doctrine.jpg), [hover](FL5_hover.jpg), [20 ships and a long name](FL5_busy.jpg)

Every review picture is labelled FL5 and at most 720 pixels high. The full-size GPU originals and copies of every review sheet are in `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-868\shots`.

The pictures use the test's seeded twelve-ship campaign fixture, with two ships at 30 percent hull. The large-fleet state has twenty ships. These are isolated test runs, not Ryan's saved profile.

## Where the old card content lives

| Content | FL5 home |
|---|---|
| Ship picture, name, class, CP | Each manifest row; selected workspace and sheet |
| Damaged state, exact hull figures and bar | Damaged group first; selected sheet; row hover |
| Whole ship hull figures and bar, mark | Selected sheet; row hover |
| Shields, regeneration, armor, speed, turns, evasion | Selected sheet |
| Ability name and full rule | Row hover and selected sheet |
| Every weapon, arc, shots, damage, range, reload | Selected sheet, wrapping and scrolling when needed |
| Captain name, rank, XP, next rank, progress and perks | Selected sheet; pending promotion opens the existing perk dialog |
| Refit slots, fitted refit description, Remove | Selected workspace; description and move instruction on the slot hover |
| Inventory and fitting to a compatible free slot | Select a ship, then In the hold H, or click an empty slot |
| Moving a fitted refit | Click its slot, then a ship with a compatible free slot; Esc cancels without changing anything |
| Free refit movement rule | Beside the selected ship's slots and in the hold |
| Repair and mark upgrade location | Selected sheet, ending with the original shipyard and drydock sentence |
| Captured prize with links ripped out | Selected sheet |
| Rename flagship | Selected flagship sheet, when the story layer supplies the original action |
| Faction action name and cost | Header; the full cost is also on hover |
| Faction action effect, availability and purchase | Change C opens the central doctrine view; Use doctrine calls the unchanged factionVerb action |
| Done | Bottom right; Enter or Esc returns to the original map or shipyard |

The game's faction action is fixed by the run's faction. The doctrine view exposes that existing action, effect and cost. It does not add a new doctrine selection rule. Selection and a held refit stay in local UI state. Equip, unequip, promotions, faction purchases and return routes still call the campaign's existing actions. There are no browser, balance, save-format or faction-id changes.

The one campaign correction splits the existing `regen` return field out of an inline comment that had accidentally hidden it. Its formula is unchanged from the browser oracle. This restores the shield regeneration readout and prevents the existing shipyard card from throwing a missing-key error.

## Reproduce

Run the registered test with Godot 4.7.2:

```
godot --headless --path godot --script res://ui/campaign/test/fleet_manifest_test.gd
```

It opens the real page, verifies read-only drawing and inspection, fits a real refit, cancels a move, rejects a full target, moves and removes the refit, checks an incompatible refit, promotes a captain, uses the faction action and returns through both Done routes. It checks twelve-ship fit, twenty-ship access, all six factions, long names, type floors, row glyph overlap and contrast over black and white at 1080, 1440 and 2160. Player UI scales 0.8 and 1.4 are also checked at 1080.

For GPU captures, install the current game cache and its texture dependencies, then queue the same script through `tools/pc/tmo.bat` with `-- --shots DIR`. The test takes 1920x1080 and 3840x2160 originals plus damaged, hold, doctrine, hover and large-fleet states. GPU claims and gpu_go.txt remain enforced by the watchdog. Run `python docs/shots/ui/fleet_fl5/make_sheets.py DIR` to reproduce these comparison sheets.

The source changes are `godot/ui/campaign/fleet_manifest.gd`, `fleet_portrait.gd`, their host in `campaign_ui.gd`, the regeneration return in `godot/campaign/campaign.gd`, the new `fleet_manifest_test.gd`, its CI registration and the two superseded Fleet structure assertions in `contrib/opus/tools/ui_spec_tests.js`.

## Validation on Ryan's PC

- `node contrib/opus/tools/run_all_checks.js`: exit 0. The recorded baseline remains seven findings and twelve constant differences; no new failures.
- All 23 campaign and campaign UI checks passed, including the new FL5 test. The onboarding check ran in an isolated TEMP copy to satisfy both its workspace guard and the task's scratch-output rule. Six fixture generators passed.
- Thirty seeded campaign runs matched the live browser oracle at every recorded step. Cross-twin save handoff and the Nemesis scenarios passed.
- `load_all.gd`: 201 scripts and 11 scenes, zero failed. The campaign bot battle at seed 359 passed.
- FL5 GPU capture run: exit 0, Vulkan Forward+ on the RTX 5080, through the queue and watchdog's shared GPU claim. Originals are exactly 1920x1080 and 3840x2160. All seven capture states and all nine labelled review sheets passed their checks.
- `git diff --check` and the changed-text em-dash check passed. No requested check was skipped. No commit or push was made.
