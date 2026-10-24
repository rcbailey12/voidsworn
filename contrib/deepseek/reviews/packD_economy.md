# Pack D (campaign economy) audit, as pasted by the owner, Oct 23, 2026

Model: DeepSeek (confirmed by the owner, Oct 23, 2026). The paste included a long reasoning trace before the findings; the findings are preserved below. Screened by Rey in council/packDE_screening.md. Unverified; Opus owns code truth.

Findings (source numbering):

1. OBSERVED. The Legacy/admiral unlock economy is dead UI: renown can only buy hull variants. LEGACY is defined at data.js:236 and ACT.buyLegacy exists at campaign_meta.js:136, but the Legacy screen tabs (campaign_meta.js:113) list only variants, mastery, favour, heat and fallen, and no button invokes buyLegacy; ACT.buyAdmiral (campaign_meta.js:137) is likewise not invoked by any button in the pack. War chests, command points, veteran officers, founder relic, shipwright discount, salvage protocols, carrier/battleship/dreadnought unlocks and the non-default admiral unlocks cannot be purchased. buyLegacy also ignores the req prerequisite fields.

2. OBSERVED. Corsair salvage tow bypasses the command-point cap and dominates scrap. campaign_run.js:264 sets tow eligibility (cp<=2, intact, cause not dark); campaign_run.js:272 pushes the ship with no fleetCP check, unlike ACT.buyHull. Scrap for the same wreck is 10+9*cp credits (19 for CP1, 28 for CP2) versus a 70/130 credit hull at 35% hull. Tow is strictly better when available.

3. OBSERVED (pack-limited). Base renown accrual is not defined in the pack: campaign_meta.js:187 falls back to runRenown() if defined, else 0. Only the Heat multiplier (+10% per level) is visible. Favour accrues to thresholds and is never spent (campaign_meta.js:289).

4. OBSERVED/INFERRED. Battle pay is fixed by sector, column and kind, not kills: campaign_run.js:237 (25+12*s+3*col)*kindMult. S1 col-1 normal pays 40; S1 boss 165. Repairs cost 1 credit per 2 hull (campaign_run.js:164). A Vex start fleet (243 max hull) at the sim's S1 boss 35% hull left costs about 79 to repair. S2 elite pays about 93 to 98 while repair from 23% hull costs about 94, before replacing 3.8 lost ships (replacement of 3.8 cheapest hulls costs over 266). Kills do not enter the credit formula; only one wreck can be salvaged.

5. OBSERVED/INFERRED. Sector pressure rises through enemy CP and losses while player CP barely moves: core.js:278 starts cpCap 10; campaign_run.js:312 adds 3 per sector (10/13/16); sim enemy budget reaches about 19.8 CP. Sim S3 elite: 53% win, 40% hull left, 3.2 ships lost.

6. OBSERVED. High-cost hull sinks are unreachable because their unlocks are unreachable: campaign_run.js:139 gates the reliquary behind META.unlocked.u_carrier, which no provided UI can set. Default stock is warden/harrow/penitent only.

7. OBSERVED (pack-limited). Capture exists in rules text (campaign_meta.js:158, boarding can capture for your fleet) and in the sim annex (0.20 captures per battle) but no campaign reward/outcome code in the pack prices it. NOTE from screening: DeepSeek's council cites campaign3d.js:81 pushing captured ships into RUN.fleet; campaign3d.js was not in Pack D, so this finding is a pack artifact in part. See screening doc.

8. INFERRED. The cache event choice "Crack it open" (data.js:307, random module) strictly dominates the +45 credit alternative: every module costs at least 55 (census_modules.csv), inventory is uncapped and refits move freely.

9. OBSERVED/INFERRED. The Scarce sector condition is net punitive to repair-heavy fleets: data.js:373 cred:.25, price:1.2, repair:.75. Effective repair cost per hull restored is 1.2/0.75 = 1.6x baseline while pay rises only 1.25x.

10. OBSERVED. Decommission refunds 35% of base cost regardless of damage or Mark (campaign_run.js:181), so repairing a ship you intend to sell is pure waste. Mk upgrades cost round((40*cp*mk+30)*priceMult) (core.js:184): Mk2 70 to 230 by CP, Mk3 110 to 430.

Not checked (per the audit): battle.js and capture implementation; the runRenown definition; map/encounter generation; boon/aspect effects; human play (all sim evidence bot vs bot); Heat above 0.
