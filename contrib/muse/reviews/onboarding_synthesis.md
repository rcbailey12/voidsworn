# Onboarding lens synthesis: DeepSeek + Qwen 3.8-Max (chair: Rey)

Job: reconstruct the first ten minutes from campaign_run.js + battle.js + ui3d.js, critique each step, rank stuck points, propose file-by-file fixes. Both legs filed under contrib/deepseek/reviews/onboarding_lens_deepseek.md and contrib/qwen/reviews/onboarding_lens_qwen38max.md. Screening notes in the goal hidden_files folder.

Chair verdict: GO WITH CONDITIONS. The merged fix list below is small, concrete, and mostly one-line-class changes. Nothing here redesigns the game, and nothing touches per-activation decision weight.

## The one big resolution: the cold open exists, and it is the campaign

Both lenses were granted only three code files, so both treated the skirmish intro as the visible cold open and flagged "skirmish first, campaign unreachable" as a top problem (DeepSeek Critical #1, Qwen stuck #4). Verified against code outside the pack, that framing is wrong:

- Boot ends with titleScreen() (main3d.js). The title screen offers Continue run / New run (primary), Progression, and How to play (campaign_meta.js:27), with "3D skirmish" and "Settings" added as secondary buttons (campaign3d.js:34).
- Run creation (admiralScreen, campaign_meta.js) already shows faction picks, admiral cards with doctrine, starting fleet, and Command description before launch.

So the campaign IS the primary path and Qwen's campaign reconstruction (map onward) stands as the intended first ten minutes. The skirmish intro's nine-row choice overload is real but demoted to a secondary-entry issue. The remaining genuine unknown is the "How to play" screen's content, not whether teaching surfaces exist.

## Consensus (both lenses, all verified by grep)

1. First fight defaults to Veteran AI. battle.js:993: aiVet() returns true when AI_LEVEL is undefined, and main3d.js only sets AI_LEVEL from saved opts. A fresh profile faces focus fire (aiFocus, corner brackets, "Targeted" tag) before it can read why. Chair rank: the top fix.
2. The motion rule is invisible. battle.js:390 MOVE_BASE still:10, evadeAt:3, evade:5; motionHit returns +10 to hit for sitting still, -5 at 3+ hexes. It surfaces only in small panel text (driveLine/motionNote), never in a tip. New players park their ships, get hit more, and never learn why.
3. Reward jargon at first contact. The victory chain (salvage, refit, boon, relic, promotion) defines none of its terms at point of use. The roguelite's core loop teaches nothing on first contact.
4. Alternating activation is taught late. One tip after the first shot (TIPS.fired); the intro picker's one-liner is long forgotten by then.
5. Dense first-ship panel, rescued by the action-strip hint. Both lenses agree the strip hint ("Tap a gold hex to move, or a red-ringed enemy to fire") is what saves the panel, and the move/fire tooltips, cantFireReason, attackTip, and strip hint are the strongest onboarding in the codebase. Do not touch them.
6. Threat is never prompted. The best defensive tool (R) is a tooltip only.
7. The objective tip cannot fire on the first battle. ui3d.js:635: TIPS.objective requires B.obj.type!=='rout', and the first column is always rout.
8. One click fires every bearing weapon. ui3d.js:410 onBoardClick fires the whole firingSet with no confirmation. DeepSeek rated this High, Qwen minor; chair splits it: the behavior is real, the 1-6 arming keys already exist as the precise alternative, so the fix is a confirm option or better arming discoverability, not a forced confirmation.
9. Touch wording on PC. actionStrip calls touchWords; whether "Tap" becomes "Click" on PC is unverified in both lenses.

## Contested, resolved by grep

- Enemy-turn signal: Qwen states an "Enemy turn" banner as part of the enemy turn; DeepSeek states aiStep has no banner. Both are half right. banner('Enemy turn') exists only in endTurn() (ui3d.js:538), the Classic path. aiStep() (ui3d.js:555), the default Alternating path, has no banner call. In the default mode, enemy activations arrive with no signal beyond the camera moving. Chair finding: alternating mode needs an enemy-activation signal (a first-time toast is enough; a banner every activation would be noise).

## DeepSeek-only, carried

- ACT.pick rebuilds the battle on every picker click (ui3d.js:618: setupBattle then showIntro). Verified. Performance wart, low priority, but free to fix if the intro is touched anyway.
- Tip cascade: tips are condition-gated, not sequenced, so a player can miss or misorder them. The deeper reading of the tip system; Qwen's tip inventory corroborates the ids but not the cascade analysis.
- ACT.begin auto-selects the first ship before the start tip tells the player to select one (ui3d.js:619). Plausible ordering wart; carried as an observation for Opus to confirm against tip trigger conditions.
- Naval-copy audit, scoped: purge only ship-shape naval language, not vocabulary. The standing fiction rule bans naval ships, not the word admiral (the game has 24 admirals by design), and boarding is an adopted verb.

## Qwen-only, carried

- Fix 1 mechanism: initialize AI_LEVEL to standard for a fresh profile via META.opts/saveOpts, keeping ACT.aiLevel as the toggle; or change the aiVet default. Either is one-line class.
- Boon legend on the map: append one sentence to the mapScreen bottom hint ("A node marked with a coloured sigil pays a boon from that patron when you win it").
- Shield dial clause: "The dial's Prow points where the ship's nose faces."
- Skirmish intro encounter descriptions: render ENCOUNTERS[k].d under each OBJS name. Free, since the strings already exist.

## Merged fix list, in chair order

1. First battle Standard AI (ui3d.js/battle.js aiVet path), with the Veteran toggle kept. Optional reinforcement: a one-time toast the first time aiFocus lands on a player ship.
2. Rewrite the move tip to carry the motion rule (+10 still, -5 at 3+ hexes) plus the shield/hull legend.
3. Explain Alternating in the empty right panel at battle start (one sentence), keeping tip fired as reinforcement.
4. One-line definitions at first reward contact: refit (salvageStep), boon (boonStep), relic (relicStep, on the first elite not only the boss).
5. Enemy-activation signal in alternating mode (first-time toast) plus a Threat prompt on the first enemy activation of a run. Qwen's proposed trigger (round 1 and enemy side) needs adapting to alternating mode, where side flips per activation.
6. Map boon legend (mapScreen hint append) and shield dial prow clause.
7. Objective tip: add a rout-specific line so it fires on the first battle.
8. Skirmish intro (secondary entry): collapse Battlefield/Deployment/Arena/Board into an Advanced disclosure for new profiles; add encounter descriptions under OBJS names.
9. ACT.pick: stop rebuilding the battle on every picker change (only rebuild on Begin, or debounce).
10. First-shot: surface the 1-6 arming keys in the firing tip, or add an opt-in confirm for firing all weapons. Do not force a confirmation on experienced players.

## Not checked

- "How to play" screen content (exists on the title screen; neither lens saw it).
- Tip trigger conditions in full (whether ACT.begin's auto-select genuinely precedes the start tip).
- battleScreen as a campaign pre-battle briefing: campaign battles in campaign3d.js go straight to startBattle + prepBattle, which suggests no briefing screen, but the function itself was not in either pack. Opus to confirm.
- touchWords output on PC.
- Whether the Veteran default is intentional (a deliberate "learn by losing" stance would change Fix 1 from a default change to a first-time callout). This is the one judgment call in the list, and it is Opus's or Ryan's, not the chair's.

## Recommended next step

Opus verifies the merged top 5 (Fixes 1-5) against code, all already grep-verified here except tip trigger conditions, and implements them as the onboarding pass. They are the highest-damage, lowest-cost changes in either lens, and none of them waits on the mega sim or any other pending work.
