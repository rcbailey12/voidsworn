# Pack E (first-run onboarding) audit, as pasted by the owner, Oct 23, 2026

Model: DeepSeek (confirmed by the owner, Oct 23, 2026). Preserved in full below (lightly formatted). Screened by Rey in council/packDE_screening.md. Unverified; Opus owns code truth.

## Reconstructed first-run sequence (text-only, per the audit)

Boot: loading veil "Assembling the fleet..." (head.html:308); boot calls titleScreen() (main3d.js:14). Title: campaign subline plus New run, Progression, How to play (campaign_meta.js:34-36); campaign3d.js:34 adds 3D skirmish and Settings, with no explanation of the difference. New run with no save goes to admiralScreen(): faction name buttons only (campaign_meta.js:63-65), admiral cards with doctrine, starting fleet, mastery bar and Command text (66-68), run options including locked Heat (86-89), Launch. Launch runs newRun then aspectScreen(): a flagship aspect that lasts the whole run (96), only action Take this aspect (97), patron names/themes below (99). Then introModal over the map: Sector I, faction blurb, route instruction (patron sigils pay boons, flagship at far end) (105-106). Map node choice (original mapScreen not in pack). Battle via battleScreen() (campaign3d.js:47-59), HUD from buildHud(), one-at-a-time tutorial tips (ui3d.js:622-640). Endcard: Victory/Defeat, kills/losses/captures, Continue the campaign (ui3d.js:583-593). rewardFlow is called but not present in the pack (campaign3d.js:90).

## Findings (source order)

1. OBSERVED. The first forced permanent choice has no Back/cancel and is jargon-heavy. aspectScreen says the aspect lasts the whole run (campaign_meta.js:96) and offers only Take this aspect (campaign_meta.js:97), before any battle explains prow, squadron, Command or ram. Most plausible quit point.

2. OBSERVED. The first fork is ambiguous: New run vs 3D skirmish (campaign3d.js:34 beside campaign_meta.js:34), and the title subline describes only the campaign.

3. OBSERVED. Faction choice is names-only at the moment of permanent choice (campaign_meta.js:65); the faction blurb appears only later in the Sector I modal (campaign_meta.js:105).

4. OBSERVED/INFERRED. All admirals are unlocked by boot default (main3d.js:11 sets META.admirals[k]=true when unlockAll is not false), undermining progression and adding choice overload while mastery/Heat/renown chrome is still shown (campaign_meta.js:60, 81, 88).

5. OBSERVED. Command, Mastery, Heat and renown are shown before definition (campaign_meta.js:60 "Gets stronger each round you hold it"; :81 Mastery; :88 "Win a run to unlock Heat"). Definitions live in optional Help/Progression text.

6. OBSERVED. The first battle tip contradicts the auto-selected ship: battleScreen calls selectUnit on the first player ship (campaign3d.js:57), then the first tip says "Select one of your ships" (ui3d.js:623).

7. OBSERVED. Patrons and boons shape route choice before being explained: aspect screen lists patron names/themes (campaign_meta.js:99); the route modal says battles pay out that patron's boons (campaign_meta.js:106) without defining boon.

8. OBSERVED. The battle HUD dumps undefined numbers and terms before the tips explain them: Armor in the ship panel (ui3d.js:140), "Admiral's Command: a fleet-wide signature move" as a top-bar tooltip (ui3d.js:61). Early tips cover shields/hull and moving/firing, not armor, evasion, turns or Command timing.

9. OBSERVED. Touch control requires a double-tap not stated in the first tip: touchWords can say "Tap a gold hex twice to move" (ui3d.js:14) but the first tip only says gold hexes show where the ship can move (ui3d.js:623).

10. INFERRED. Reading burden before the first tactical decision is high: faction and admiral ledes, four admiral cards, run options, three aspect cards, patron list and the Sector I modal all precede the first move or shot.

## The audit's revised first-ten-minutes sequence (summary)

Boot unchanged. Title: New run primary with How to play and Settings; hide 3D skirmish and Progression until after the first battle or run (UI CHANGE, conditional menu, existing text only). First-run intro modal reusing the existing Help paragraphs on runs and carry-over (campaign_meta.js:143-144) before any permanent choice (UI CHANGE, existing text). Faction choice: show the selected faction's existing FACTIONS blurb beside the buttons, Voidsworn preselected (UI CHANGE, existing text). Admiral choice: Vex preselected, inline Command definition reusing Help text (campaign_meta.js:158), Mastery/Heat/run options collapsed for the first run (UI CHANGE). Aspect screen: add a Back button and show the flagship name/hull (UI CHANGE). Sector I modal: insert the existing patron/boon Help paragraph (campaign_meta.js:160) before the route instruction (UI CHANGE, existing text). First battle: stop auto-selecting before the first tip or change the tip wording; add the existing touch double-tap string to the first move tip (UI CHANGE). HUD: progressive disclosure of Command/Threat/Armor/Evasion/Turns (UI CHANGE). Post-battle: endcard kept; reward flow not auditable from the pack.

## Not checked (per the audit)

head.html CSS beyond loading/title/HUD; main3d cache, persistence, telemetry; original mapScreen, newRun, startBattle, prepBattle, startSideTurn and rewardFlow (referenced, absent from pack); Progression tab contents; combat internals (AI, overlays, input, watchdog); most data.js content beyond cited terms; the 3D skirmish setup screen beyond title ambiguity.
