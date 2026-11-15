# Flash leg, issue 794 (Gemini, Quick answers 3.5 Flash-Lite, verified in the picker before and after)

Chat: https://gemini.google.com/app/193ac5a141b0edc1
Ran Nov 15, 2026, 09:31 to 09:34 CST (runtime measured). Pack attached as design_pack_794.txt and confirmed in the composer before the prompt was sent. Account showed as Pro in the browser report; the seat run was Flash-Lite as gated.

## Full answer, verbatim

1. THE AUDIT

Screens ranked from worst to best by text reliance and decision friction:

Fleet and refits (campaign)
Decision: Which ships to repair, refit, and ready before the next battle.
Why: Fifteen lines of small text per card overload the player with weapon and perk sentences.
Visual solution: Ship renders, hull bars, and weapon icons.

After-run screen
Decision: Confirm the heir, spend renown, and choose the next run.
Why: A massive two-viewport scroll of unformatted text hides the permanent heir choice.
Visual solution: Portraits for heirs, ship picture for the standout ship, run timeline, and big headline numbers.

Career screen
Decision: None in the moment, as it is a browsable archive.
Why: Outdated filled panels and sentences per card clash with the orders sheet system.
Visual solution: Crest art and faction badge icons.

Nemesis dossier (campaign side)
Decision: Review enemy status and weaknesses outside of battle.
Why: It repeats battle data in text panels instead of using compact intel blocks.
Visual solution: Nemesis portrait and adaptation meters.

Settings
Decision: Adjust display, audio, and gameplay preferences.
Why: The UI scale option lacks a visual preview, forcing guesswork.
Visual solution: Live preview thumbnail.

Campaign event and result screens
Decision: Choose story paths and review resource outcomes.
Why: Outcomes are buried inside story paragraphs.
Visual solution: Event portraits and resource gain icons.

Title screen
Decision: Start, continue, or configure the game.
Why: The credits dialog is a scrolling text list.
Visual solution: Fleet faction crest art and title typography.

Dossier screen
Decision: Read lore about a stop or faction.
Why: It is a dense text page with limited interaction.
Visual solution: Faction crests and location art.

Battle log overlay
Decision: Review past actions during or after combat.
Why: It relies on plain text lines, but works well behind a key.
Visual solution: Status icons for damage types.

Load screen and rename dialog
Decision: Enter a name or wait for loading.
Why: Each holds only one field and requires minimal reading.
Visual solution: Ship silhouette loading meter.

Battle HUD
Decision: Execute immediate fleet tactical orders.
Why: It follows the orders sheet perfectly with minimal text and clear odds.
Visual solution: Existing ship pictures, meters, and the ember action box.

Campaign map
Decision: Plot the fleet route across sectors.
Why: It is already built to the system as the worked example.
Visual solution: Fleet token and sector node icons.

2. THE AFTER-RUN SCREEN

A flat 1920 by 1080 layout split into two vertical columns over a 94 percent black scene darkening.

Layout and Visuals

Top Left Headline: Big Shoulders Display capital text reading THE CRUSADE ENDURES in 34 px size. Barlow supporting text underneath reads Admiral Roderic Vex brings the Sunward Crusade home across three broken sectors.

Center Left Timeline: A horizontal run timeline graphic showing sectors one through three, marking elite encounters and flagship destructions as distinct icons.

Lower Left Key Items (The Heir Choice): Portraits of the three candidate heirs (Malek Draven, Sera Ashgrove, Oryn Thale) rendered in a row. Below them, Azeret Mono figures show their shadow experience. The active selection box sits around the current heir. Confirming the heir unlocks the final action.

Top Right Big Headline Numbers: Four large Azeret Mono figures showing 6 battles won, 1 flagship destroyed, 24 enemy ships destroyed, and 47 minutes played.

Center Right Standout Ship: A ship render of the Judgement Bell paired with its stats: 7 kills and 612 damage.

Bottom Right Action Box: A 2 px square ember outline 56 px tall. Inside, Barlow text reads Play as Ashfall Hullbreakers with the Space key on the right. This box remains inactive until the heir choice is confirmed.

Relocation List (Nothing Deleted)

Doctrine and Renown details: Moved to a hover state over the renown figure.
Admiral XP gains and line level: Moved to a hover state over the admiral portrait.
Core sync protocol counts: Moved to a hover state over the ship picture.
Nemesis lesson and weakness: Moved to a hover state over the nemesis icon.
Full list of lost captains and victors: Moved behind a history key.
Faction picking options and title screen link: Placed behind a secondary menu hover accessible from the top corner.

3. RISKS

Risk One: Heir confirmation deadlock. Players might miss that the run cannot end until an heir is confirmed.
Answer: The final action box remains dimmed with an ember warning indicator until the player clicks one of the heir portraits, and pressing the confirmation key highlights the requirement.

Risk Two: Information density on lower resolutions. Consolidating paragraphs into portraits and hover states might crowd smaller displays.
Answer: Strict adherence to the 17 px font floor and utilizing hover tooltips for all secondary numbers keeps the base layout clean and readable.

Verdict: Fleet and refits: Fleet management needs visual overhaul.

## Chair notes on this leg (not part of the leg)

- Ranking slip: Flash ranks Fleet and refits first and the after-run screen second. R260 fixes the working order (audit all, fix worst first, starting with the after-run screen), so the chair does not adopt the swap; the disagreement is recorded. Its second-place verdict (Fleet next) matches the chair's ranking.
- Design slips: an "ember warning indicator" on a dimmed box spends the one accent on a non-action; heir "portraits" assume paintings that do not exist for these three (the game holds crests for them, per godot/portraits and the Sunward sheet); the relocation list lumps unlike items ("Full list of lost captains and victors") and parks exits behind a "secondary menu hover", weaker than the pack's standard of naming each sentence's home.
- Sound parts the chair may adopt: the two-column split with numbers top right, and the deadlock risk (the player must know the heir gates the exit), which the mockups answer by keeping CONFIRM HEIR as the one box until the heir is named.
