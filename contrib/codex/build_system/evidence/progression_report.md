# Progression sensitivity, not a player forecast

Native loss XP is variable. The source formula is `battles + 2*elites + 5*bosses + victory*10`; a flat 10-XP loss is a proposal assumption. Example outcomes below are specified inputs, not measured campaign data.

| Stated outcome cycle | Heat | First tree pick (75 XP) | Third pick (160 XP) | Capstone (230 XP) |
|---|---:|---:|---:|---:|
| all victories | 0 | 2 | 4 | 6 |
| all early losses | 0 | 75 | not within 100 runs | not within 100 runs |
| four sector-1 losses then victory | 0 | 5 | 10 | 15 |
| four midrun losses then victory | 0 | 5 | 9 | 11 |
| four sector-1 losses then victory, Heat 4 | 4 | 4 | 7 | 10 |
| no battles completed | 0 | not within 100 runs | not within 100 runs | not within 100 runs |

The proposal’s “43 win / 10 loss / 20% wins” has mean XP 16.6 per run. Dividing a threshold by 16.6 is not the expected first-passage time. The JSON provides exact finite-horizon crossing distributions, medians, 90th percentiles, residual mass, and explicitly restricted means for 20%, 50%, and 80% assumed wins. No combat simulations were rerun.

Policy notes: exact quarter-XP avoids silent rounding; ordinary shadow includes the proposed Heat payout; Heat’s additional faction pool is banked, not silently paid to every benched admiral. Overflow is retained per line above 600. These implementation policies are marked for adoption in the contract; they are not new owner rulings.
