# Campaign Monte Carlo

Seed: 1 through 200 per faction. Runs per faction: 200. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| Sunward Crusade (voidsworn) | 200 | 75.5% | 69.1% to 80.9% | 17 | 21 | 11 | 151 | 12.06 |
|   High Admiral Oryn Thale (thale) | 200 | 75.5% | 69.1% to 80.9% | 17 | 21 | 11 | 151 | 12.06 |
| Overall | 200 | 75.5% | 69.1% to 80.9% | 17 | 21 | 11 | 151 | 12.06 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 4.
Run time: 170.68 seconds.
