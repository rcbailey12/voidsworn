# Campaign Monte Carlo

Seed: 1 through 200 per faction. Runs per faction: 200. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| Sunward Crusade (voidsworn) | 200 | 69.0% | 62.3% to 75.0% | 37 | 20 | 5 | 138 | 11.42 |
|   Admiral Roderic Vex (vex) | 50 | 80.0% | 67.0% to 88.8% | 6 | 4 | 0 | 40 | 12.12 |
|   Oath-Captain Malek Draven (malek) | 50 | 50.0% | 36.6% to 63.4% | 14 | 9 | 2 | 25 | 10.16 |
|   Commodore Sera Ashgrove (ashgrove) | 50 | 54.0% | 40.4% to 67.0% | 16 | 5 | 2 | 27 | 10.24 |
|   High Admiral Oryn Thale (thale) | 50 | 92.0% | 81.2% to 96.8% | 1 | 2 | 1 | 46 | 13.16 |
| Overall | 200 | 69.0% | 62.3% to 75.0% | 37 | 20 | 5 | 138 | 11.42 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 2.
Run time: 321.18 seconds.
