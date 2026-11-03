# Campaign Monte Carlo

Seed: 1 through 50 per faction. Runs per faction: 50. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| Sunward Crusade (voidsworn) | 50 | 64.0% | 50.1% to 75.9% | 8 | 8 | 2 | 32 | 11.24 |
|   Admiral Roderic Vex (vex) | 13 | 69.2% | 42.4% to 87.3% | 1 | 3 | 0 | 9 | 11.54 |
|   Oath-Captain Malek Draven (malek) | 13 | 53.8% | 29.1% to 76.8% | 3 | 3 | 0 | 7 | 10.77 |
|   Commodore Sera Ashgrove (ashgrove) | 12 | 33.3% | 13.8% to 60.9% | 4 | 2 | 2 | 4 | 9.08 |
|   High Admiral Oryn Thale (thale) | 12 | 100.0% | 75.7% to 100.0% | 0 | 0 | 0 | 12 | 13.58 |
| Hegemony Navy (hegemony) | 50 | 70.0% | 56.2% to 80.9% | 4 | 10 | 1 | 35 | 11.78 |
|   First Admiral Ilsa Kassar (kassar) | 13 | 92.3% | 66.7% to 98.6% | 1 | 0 | 0 | 12 | 12.69 |
|   Commodore Dace Vorn (vorn) | 13 | 61.5% | 35.5% to 82.3% | 2 | 3 | 0 | 8 | 11.08 |
|   Fleet Marshal Corin Reyes (reyes) | 12 | 75.0% | 46.8% to 91.1% | 1 | 2 | 0 | 9 | 11.75 |
|   Line Admiral Oskar Maren (maren) | 12 | 50.0% | 25.4% to 74.6% | 0 | 5 | 1 | 6 | 11.58 |
| Ashfall Hullbreakers (corsair) | 50 | 58.0% | 44.2% to 70.6% | 12 | 5 | 4 | 29 | 10.42 |
|   Warlord Grax Ironmaw (grax) | 13 | 46.2% | 23.2% to 70.9% | 4 | 1 | 2 | 6 | 9.62 |
|   Sable the Smiling Knife (sable) | 13 | 38.5% | 17.7% to 64.5% | 7 | 0 | 1 | 5 | 8.15 |
|   Old Mott (mott) | 12 | 66.7% | 39.1% to 86.2% | 0 | 4 | 0 | 8 | 11.33 |
|   Vesh the Collector (vesh) | 12 | 83.3% | 55.2% to 95.3% | 1 | 0 | 1 | 10 | 12.83 |
| The Chorus (chorus) | 50 | 64.0% | 50.1% to 75.9% | 8 | 6 | 4 | 32 | 11.20 |
|   The Matriarch of Nine Throats (matriarch) | 13 | 61.5% | 35.5% to 82.3% | 0 | 2 | 3 | 8 | 12.69 |
|   Razormaw (razormaw) | 13 | 76.9% | 49.7% to 91.8% | 2 | 0 | 1 | 10 | 11.54 |
|   Mending Throng (mending) | 12 | 66.7% | 39.1% to 86.2% | 2 | 2 | 0 | 8 | 10.58 |
|   Voice of the Deep (voice) | 12 | 50.0% | 25.4% to 74.6% | 4 | 2 | 0 | 6 | 9.83 |
| The Glasswrights (ithar) | 50 | 68.0% | 54.2% to 79.2% | 5 | 10 | 1 | 34 | 11.70 |
|   Tamsa of the Clear Aperture (aelith) | 13 | 84.6% | 57.8% to 95.7% | 0 | 2 | 0 | 11 | 12.15 |
|   Saro of Long Focus (vaelen) | 13 | 69.2% | 42.4% to 87.3% | 2 | 1 | 1 | 9 | 12.00 |
|   Vell of the Third Mirror (thorne) | 12 | 50.0% | 25.4% to 74.6% | 2 | 4 | 0 | 6 | 10.42 |
|   Brin of the Fourth Lens (mirelle) | 12 | 66.7% | 39.1% to 86.2% | 1 | 3 | 0 | 8 | 12.17 |
| Eclipse (deathless) | 50 | 72.0% | 58.3% to 82.5% | 9 | 4 | 1 | 36 | 11.42 |
|   Nadir Aurex, Ninth Frame (nekhet) | 13 | 92.3% | 66.7% to 98.6% | 1 | 0 | 0 | 12 | 12.23 |
|   Umbra Vessane, Third-Housed (sekhmar) | 13 | 76.9% | 49.7% to 91.8% | 2 | 1 | 0 | 10 | 11.92 |
|   Ostrel of the Long Copy (anuket) | 12 | 58.3% | 32.0% to 80.7% | 3 | 2 | 0 | 7 | 10.75 |
|   Seveth, Twice-Restored (khepra) | 12 | 58.3% | 32.0% to 80.7% | 3 | 1 | 1 | 7 | 10.67 |
| Overall | 300 | 66.0% | 60.5% to 71.1% | 46 | 43 | 13 | 198 | 11.29 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 4.
Run time: 442.00 seconds.
