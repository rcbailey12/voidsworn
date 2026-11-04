# Campaign Monte Carlo

Seed: 1 through 200 per faction. Runs per faction: 200. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| Sunward Crusade (voidsworn) | 200 | 56.5% | 49.6% to 63.2% | 50 | 27 | 10 | 113 | 10.46 |
|   Commodore Sera Ashgrove (ashgrove) | 200 | 56.5% | 49.6% to 63.2% | 50 | 27 | 10 | 113 | 10.46 |
| Overall | 200 | 56.5% | 49.6% to 63.2% | 50 | 27 | 10 | 113 | 10.46 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 1.
Run time: 364.50 seconds.
