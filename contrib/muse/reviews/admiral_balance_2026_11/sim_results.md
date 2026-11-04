# Campaign Monte Carlo

Seed: 1 through 200 per faction. Runs per faction: 200. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| Sunward Crusade (voidsworn) | 200 | 64.0% | 57.1% to 70.3% | 37 | 24 | 11 | 128 | 11.17 |
|   Admiral Roderic Vex (vex) | 50 | 80.0% | 67.0% to 88.8% | 6 | 4 | 0 | 40 | 12.12 |
|   Oath-Captain Malek Draven (malek) | 50 | 50.0% | 36.6% to 63.4% | 14 | 9 | 2 | 25 | 10.16 |
|   Commodore Sera Ashgrove (ashgrove) | 50 | 42.0% | 29.4% to 55.8% | 16 | 8 | 5 | 21 | 9.52 |
|   High Admiral Oryn Thale (thale) | 50 | 84.0% | 71.5% to 91.7% | 1 | 3 | 4 | 42 | 12.88 |
| Overall | 200 | 64.0% | 57.1% to 70.3% | 37 | 24 | 11 | 128 | 11.17 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 3.
Run time: 246.30 seconds.

---

# Campaign Monte Carlo

Seed: 1 through 200 per faction. Runs per faction: 200. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| Hegemony Navy (hegemony) | 200 | 61.0% | 54.1% to 67.5% | 25 | 38 | 15 | 122 | 11.32 |
|   First Admiral Ilsa Kassar (kassar) | 50 | 74.0% | 60.4% to 84.1% | 5 | 3 | 5 | 37 | 12.32 |
|   Commodore Dace Vorn (vorn) | 50 | 52.0% | 38.5% to 65.2% | 8 | 14 | 2 | 26 | 10.62 |
|   Fleet Marshal Corin Reyes (reyes) | 50 | 68.0% | 54.2% to 79.2% | 6 | 9 | 1 | 34 | 11.26 |
|   Line Admiral Oskar Maren (maren) | 50 | 50.0% | 36.6% to 63.4% | 6 | 12 | 7 | 25 | 11.08 |
| Overall | 200 | 61.0% | 54.1% to 67.5% | 25 | 38 | 15 | 122 | 11.32 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 5.
Run time: 299.88 seconds.

---

# Campaign Monte Carlo

Seed: 1 through 200 per faction. Runs per faction: 200. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| Ashfall Hullbreakers (corsair) | 200 | 67.0% | 60.2% to 73.1% | 32 | 20 | 14 | 134 | 11.26 |
|   Warlord Grax Ironmaw (grax) | 50 | 58.0% | 44.2% to 70.6% | 12 | 6 | 3 | 29 | 10.68 |
|   Sable the Smiling Knife (sable) | 50 | 62.0% | 48.2% to 74.1% | 12 | 4 | 3 | 31 | 10.12 |
|   Old Mott (mott) | 50 | 64.0% | 50.1% to 75.9% | 5 | 8 | 5 | 32 | 11.58 |
|   Vesh the Collector (vesh) | 50 | 84.0% | 71.5% to 91.7% | 3 | 2 | 3 | 42 | 12.66 |
| Overall | 200 | 67.0% | 60.2% to 73.1% | 32 | 20 | 14 | 134 | 11.26 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 0.
Run time: 364.34 seconds.

---

# Campaign Monte Carlo

Seed: 1 through 200 per faction. Runs per faction: 200. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| The Chorus (chorus) | 200 | 64.0% | 57.1% to 70.3% | 36 | 24 | 12 | 128 | 11.05 |
|   The Matriarch of Nine Throats (matriarch) | 50 | 70.0% | 56.2% to 80.9% | 6 | 4 | 5 | 35 | 11.96 |
|   Razormaw (razormaw) | 50 | 74.0% | 60.4% to 84.1% | 7 | 3 | 3 | 37 | 11.52 |
|   Mending Throng (mending) | 50 | 58.0% | 44.2% to 70.6% | 9 | 11 | 1 | 29 | 10.50 |
|   Voice of the Deep (voice) | 50 | 54.0% | 40.4% to 67.0% | 14 | 6 | 3 | 27 | 10.22 |
| Overall | 200 | 64.0% | 57.1% to 70.3% | 36 | 24 | 12 | 128 | 11.05 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 2.
Run time: 274.37 seconds.

---

# Campaign Monte Carlo

Seed: 1 through 200 per faction. Runs per faction: 200. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| The Glasswrights (ithar) | 200 | 61.0% | 54.1% to 67.5% | 26 | 35 | 17 | 122 | 11.23 |
|   Tamsa of the Clear Aperture (aelith) | 50 | 78.0% | 64.8% to 87.2% | 2 | 4 | 5 | 39 | 12.52 |
|   Saro of Long Focus (vaelen) | 50 | 66.0% | 52.2% to 77.6% | 6 | 7 | 4 | 33 | 11.24 |
|   Vell of the Third Mirror (thorne) | 50 | 46.0% | 33.0% to 59.6% | 9 | 15 | 3 | 23 | 10.22 |
|   Brin of the Fourth Lens (mirelle) | 50 | 54.0% | 40.4% to 67.0% | 9 | 9 | 5 | 27 | 10.94 |
| Overall | 200 | 61.0% | 54.1% to 67.5% | 26 | 35 | 17 | 122 | 11.23 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 1.
Run time: 318.40 seconds.

---

# Campaign Monte Carlo

Seed: 1 through 200 per faction. Runs per faction: 200. AI: veteran. Policy: baseline. No tuning overrides.

Playtest everything unlocked state: NOT enabled. The browser has no such switch. The driver calls defaultMeta() before every run: renown 0, unlocked {}, admirals {vex:true}, mastery {}, favour {}, variants {}, heatBest {}, no previous wins. It directly selects any requested admiral, bypassing ownership selection. Standard starting fleet, default Command, Heat 0; progression earned within a run applies, but does not carry into the next run.

Admirals rotate in game-table order. --admiral alone selects its faction. The same seed range is reused for each faction. These are bot rates, not player win rates.

S1/S2/S3 are mutually exclusive counts of non-winning runs ending in that sector (including errors). Won is the full-run victory count.

| Faction / admiral (ID) | Runs | Full-run win | Binomial 95% CI | S1 | S2 | S3 | Won | Avg battles |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| Eclipse (deathless) | 200 | 68.0% | 61.2% to 74.1% | 32 | 26 | 6 | 136 | 11.24 |
|   Nadir Aurex, Ninth Frame (nekhet) | 50 | 84.0% | 71.5% to 91.7% | 4 | 4 | 0 | 42 | 12.00 |
|   Umbra Vessane, Third-Housed (sekhmar) | 50 | 68.0% | 54.2% to 79.2% | 11 | 4 | 1 | 34 | 11.34 |
|   Ostrel of the Long Copy (anuket) | 50 | 66.0% | 52.2% to 77.6% | 6 | 8 | 3 | 33 | 11.42 |
|   Seveth, Twice-Restored (khepra) | 50 | 54.0% | 40.4% to 67.0% | 11 | 10 | 2 | 27 | 10.22 |
| Overall | 200 | 68.0% | 61.2% to 74.1% | 32 | 26 | 6 | 136 | 11.24 |

Noise: Wilson binomial 95% intervals describe sampling uncertainty under this bot. Small admiral samples are noisy. Fixed seeds reproduce the sample; factions sharing seeds are not independent, and the pooled interval is descriptive.
Driver errors: 0 runs. Battle timeouts: 2.
Run time: 255.31 seconds.
