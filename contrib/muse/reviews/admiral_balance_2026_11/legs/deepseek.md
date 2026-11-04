DeepSeek leg (reader) - independent screen and report

I have not read the other reader legs; this screen is from PACK.md alone.

1. Outlier screen

Test applied exactly as stated: a clear outlier is an admiral whose Wilson 95% interval does not overlap its own faction's Wilson 95% interval at all. Near misses with only a few points of overlap are reported as leaning, not clear outliers.

Clear outliers

Faction / admiral Admiral 95% CI Faction 95% CI Why clear
Crusade / Ashgrove 29.4% to 55.8% 57.1% to 70.3% Entirely below; gap 1.3 pp
Crusade / Thale 71.5% to 91.7% 57.1% to 70.3% Entirely above; gap 1.2 pp

These are the only two clear outliers under the stated test. Both are marginal clear outliers: they clear the test by only about one percentage point.

Leaning near misses

Faction / admiral Direction Overlap with faction CI
Crusade / Vex high 3.3 pp
Crusade / Malek low 6.3 pp
Hullbreakers / Vesh high 1.6 pp
Glasswrights / Aelith high 2.7 pp
Glasswrights / Vell low 5.5 pp
Eclipse / Nekhet high 2.6 pp
Eclipse / Khepra low 5.8 pp

I used roughly 6 pp overlap or less as "a few points." Hegemony / Kassar is a weak high lean with 7.1 pp overlap; I do not count it as a near miss under that threshold. All other admirals overlap their faction CI by more than that and are not leaning near misses.

Important caveat: the faction CI includes the admiral's own runs, so this test is somewhat conservative/circular, and with 24 admiral comparisons some marginal clear results are expected. Ashgrove and Thale should be treated as confirmed signals only after a larger per-admiral sample.

2. Clear-outlier kit drivers
Crusade / Commodore Sera Ashgrove - clear low, 42.0% (21/50), CI 29.4 to 55.8

Sector death split: S1 16, S2 8, S3 5 = 29 losses. Shares: S1 55.2%, S2 27.6%, S3 17.2%. Crusade faction loss shares are S1 51.4%, S2 33.3%, S3 15.3%. Ashgrove's deaths are somewhat more front-loaded into S1, and her average battle count is the lowest in Crusade: 9.52 vs faction 11.17. That points to early collapse rather than late-game attrition.

Kit drivers from the excerpts:

Ashgrove is the carrier/scramble kit: sqPct .4, hangar 1, sqHp .25 at data.js:207.

Start: reliquary, harrow, warden; Command scramble at data.js:214: extra wing per launch ship, then all squadrons strike again at +50% this round.

Relevant hull anchors: warden at data.js:63 (Frigate, hp 50, sh 10, cost 70), harrow at data.js:64 (Destroyer, hp 85, torp + turret, cost 130), reliquary at data.js:66 (Carrier, hp 130, sh 22, sp 2, ev 0, hangar 2, turret + flak only, cost 260).

Template-family comparison: the scramble/carrier family is ashgrove, reyes, mott, matriarch, aelith. Their full-run wins are Ashgrove 42.0%, Reyes 68.0%, Mott 64.0%, Matriarch 70.0%, Aelith 78.0%. Ashgrove has the highest sqPct in that family (.4) but the worst result. That weakens a simple "carrier doctrine is weak" story and sharpens the driver toward the reliquary start plus scramble timing: the reliquary is a fragile, zero-evasion carrier, and Ashgrove's S1-heavy deaths and shortest average battle count fit a kit that loses its launch platform before scramble can convert. Aelith's high result in the same broad family is evidence against carrier doctrine alone being the cause.

Crusade / High Admiral Oryn Thale - clear high, 84.0% (42/50), CI 71.5 to 91.7

Sector death split: S1 1, S2 3, S3 4 = 8 losses. Shares: S1 12.5%, S2 37.5%, S3 50.0%. Crusade faction S3 loss share is only 15.3%. Thale's losses are heavily late-sector, and her average battle count is the highest in Crusade: 12.88 vs faction 11.17. That is a survival/tank pattern, not an early snowball pattern.

Kit drivers from the excerpts:

Iron doctrine: hpPct .15, shPct .1 at data.js:208.

Start: cathedral, warden; Command iron at data.js:215: shields refill, 40% less hull damage this round.

Relevant hull anchors: warden at data.js:63, cathedral at data.js:67 (Battleship, hp 220, sh 30, ar .3, two hbattery + lance + flak, cost 340).

Template-family comparison: the iron/passive-tank family is thale, maren, and mirelle (variant). Maren is 50.0% and Mirelle/Brin is 54.0%, while Thale is 84.0%. Maren shares the same hpPct .15 / shPct .1 / iron command package in the pack's summary, so Thale's high result is not explained by those doctrine numbers alone. The sharper driver is the cathedral battleship start at data.js:67 combined with iron's shield refill / 40% hull-damage reduction at data.js:215. The late S3 death concentration and highest average battle count support that read.

3. Owner questions: small number changes

These are owner questions, not decisions. No data.js edits are proposed as actions in this job. Expected shifts are estimates, not measured.

Ashgrove - at most two small changes

Owner question: raise Ashgrove's sqHp from .25 to .35 at data.js:207.
Expected shift: +4 to +7 pp full-run win, estimate. Reasoning: S1-heavy deaths and the fragile reliquary start suggest squadron durability may let scramble survive to pay off. This is the more targeted lever than a command buff.

Owner question: raise scramble's strike bonus from +50% to +65% at data.js:214.
Expected shift: +3 to +6 pp full-run win, estimate. Reasoning: if Ashgrove reaches the scramble round, a larger strike conversion could close games; but because her losses are early, this is likely smaller and less reliable than the sqHp change.

Thale - at most two small changes

Owner question: reduce iron's hull-damage reduction from 40% to 30% at data.js:215.
Expected shift: -5 to -8 pp full-run win, estimate. Reasoning: Thale's late-sector survival and highest average battle count point at iron's damage mitigation as the main outlier driver.

Owner question: reduce Thale's hpPct from .15 to .12 at data.js:208.
Expected shift: -3 to -5 pp full-run win, estimate. Reasoning: a smaller passive HP bump is a second, less interactive tank lever; because Maren shares the same passive numbers but sits at 50%, this alone is unlikely to explain Thale's full outlier gap.

Cost is not a useful Monte Carlo lever here: the driver directly selects the requested admiral and bypasses ownership, so changing cost would not move these win rates in this harness.

4. Faction-level movement: signal or noise?

Current 200-run faction CIs are roughly plus or minus 6.5 pp. The baselines are 50-run samples, with roughly plus or minus 13 pp Wilson half-widths. So the observed movements are not statistically clear:

Hegemony 70.0 to 61.0, down 9 pp. Difference SE vs a 50-run baseline is about 7.3 pp; 95% interval on the difference is roughly -23 to +5. Includes zero.

Glasswrights 68.0 to 61.0, down 7 pp. Difference SE about 7.4 pp; 95% interval roughly -22 to +8. Includes zero.

Hullbreakers 58.0/60.0 to 67.0, up 7 to 9 pp. Difference SE about 7.7 pp; 95% interval roughly -6 to +24 vs #87. Includes zero.

At these sample sizes, these are best read as noise-compatible movements, not established faction shifts. They are also not attributable to a single clear admiral outlier: Hegemony has no clear outlier; Glasswrights has Aelith leaning high and Vell leaning low but no clear outlier; Hullbreakers has only Vesh leaning high. The code is the same as #87, so a real code-driven faction shift is less likely than sampling variation.

What would settle it: a pre-registered larger run, e.g. 1,000 runs per faction, would give a faction CI half-width near 3 pp and a difference CI near plus or minus 4 pp for p around .65. Better still, use paired seed-level comparisons against the baseline if raw per-seed outputs exist, and report difference CIs explicitly. Per-admiral n should also rise from 50 to at least 200 for outlier confirmation.

5. Other flags

The same seed range is reused for each faction, so factions are not independent samples. The pooled "770/1,200 = 64.2%" is descriptive only; a naive pooled CI would be too narrow.

Battle timeouts were 13/1,200 total, small but nonzero; they should be noted as a minor source of run attrition.

Ashgrove and Thale are clear only by about 1.2 to 1.3 pp gaps. Given 24 admiral comparisons, they need confirmation at larger per-admiral n before being treated as strong balance facts.

The #87 extremes have regressed sensibly: Thale was 100% over 12 and is now 84% over 50; Ashgrove was 33% over 12 and is now 42% over 50; Vesh was 83% over 12 and is now 84% over 50; Sable was 39% over 12 and is now 62% over 50. That supports the chair's larger-sample approach and argues against overreacting to the remaining marginal outliers.

Eclipse kits are not fully excerpted in the pack. There is no Eclipse clear outlier, so no line-level Eclipse kit claim is needed here.

Sector death splits are conditional on losses; raw S1/S2/S3 counts should not be compared across admirals without normalizing by losses or runs.
