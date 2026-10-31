> Subsequent verification: both proposed fixes now pass Godot 4.7.2 compilation and scoped runtime/parity. See [the current validation record](../godot_validation_2026_10_31/README.md). The unverified labels below describe this candidate's earlier preparation stage.

# Elite guarantee candidate for Opus

Prepared against main `17268efa081059a6923daa9e19e8b345a437714d`, October 31, 2026.

**The browser candidate repairs all 84 failing maps in the existing 4,500-map
sample, while preserving every previously valid map and its ending RNG state.**
It adopts the rest-node fallback already specified in Muse's patch pack section 4.
It does not redesign the map or add another random draw.

## Prepared files

| Candidate | Scope | Verification |
|---|---|---|
| `contrib/codex/proposed/core.js` | Prefer a battle, then an event, then a rest node for the guaranteed elite. One source-line change. | Node syntax check, full existing 80-assertion suite, 4,500-map and 1,920-battle setup sweep, full map/RNG comparison against original. |
| `contrib/codex/proposed/campaign_run.js` | Earlier uid-based shipwright second-repair fix. | Earlier isolated 80-assertion run and six focused browser edge cases; also tested together with this elite fix. |
| `contrib/codex/proposed/godot/campaign/campaign.gd` | Matching elite fallback and shipwright uid exclusion, combined in one full-file candidate. | Source preparation only. Godot is unavailable here, so compilation, behavior and parity are NOT VERIFIED. |

The Godot candidate combines the two browser fixes. Do not copy it as an elite-only
change. Apply only the relevant hunks if adopting the two jobs separately. All full
copies are based on the pin above; reconcile changes already landed by Muse or Opus
before adopting them. The browser baseline and original Godot file are untouched.

## Recorded results

| Check | Original | Elite only | Elite + shipwright |
|---|---|---|---|
| Findings suite, 80 assertions | 8 pass / 72 fail | 9 pass / 71 fail; exactly W3-1 changes | 10 pass / 70 fail; exactly W3-1 and TXT-2 change |
| Elite guarantee on 4,500 seeded sector maps | 84 failures | 0 failures | Not separately swept; campaign outcome repair does not change map generation |
| Other map guarantees, reachability and repeatability in the existing sweep | Previously recorded clean | 0 failures | Not separately swept |
| Battle setup grid | Previously recorded 1,920 setups, 0 failures | 1,920 setups, 0 failures | Not separately swept |
| Full output for previously valid maps | 4,416 maps | All 4,416 map serializations and ending RNG states identical | Not separately compared |

Recorded logs and scripts are beside this note:
`elite_softlock_sweep.txt`, `elite_suite.txt`, `combined_suite.txt`,
`elite_map_comparison.json`, and `verify_elite.js`. The comparison JSON records
every repaired seed/sector and both final column-type lists.

The map comparison resets the run and PRNG identically, generates original and
candidate maps, and compares complete map JSON plus the game's `RNG_S` for every
originally valid map. It also asserts that the candidate source differs only by
the exact fallback expression. This is stronger than comparing failure counts.

## One queue correction: the extra field-conversion guard is unnecessary here

The red-team QA synthesis item 7 says the later field conversion can undo this
patch. That premise does not hold for the current source. It selects events or
battle nodes; an elite is neither. The budgets loop also leaves elites alone.
Muse's original patch-pack rationale is correct on this point.

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Your fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | The proposed additional guard repairs no demonstrated elite-to-field path. | OBSERVED | core.js:277 | `n.type==='battle'&&fights.length>1` | The complete predicate admits events and battle nodes, not elites. All 84 repaired maps retain an elite through the complete generator in the original acceptance sample. | Adopt the minimal fallback, retain the end-to-end guarantee test, and remove the extra-guard requirement from the queue unless this predicate changes. | High |

The corresponding Godot predicate at `godot/campaign/campaign.gd:850` also excludes
elites. The candidate does not change either field-conversion block.

## Reproduction and adoption

Create an isolated checkout containing current root JS files with only the proposed
`core.js` substituted. Then run:

```sh
node contrib/codex/reviews/opus_ready_2026_10_31/verify_elite.js ORIGINAL_CHECKOUT CANDIDATE_CHECKOUT
node contrib/codex/proposed/contrib/muse/tools/harness/softlock_sweep.js CANDIDATE_CHECKOUT 1500 4
node contrib/codex/proposed/contrib/muse/tools/findings_tests/findings_tests.js CANDIDATE_CHECKOUT
```

The first two should exit 0; the suite still exits 1 for its unrelated expected
failures. For the combined candidate, additionally substitute the proposed
`campaign_run.js` and compare test identities with the recorded combined run.

One recommended next step: Opus adopts the selected browser/Godot hunks together,
then deliberately updates the affected JS oracle copies and runs the existing
campaign parity checks. Do not update oracle pins or expected records merely to
hide a divergence. Previously failing seeds can legitimately change their map and
following RNG state after the fallback changes the node-processing path.

## Source read proof and not checked

`elite_source_proof.json` records source/candidate blob hashes, file line counts,
last-line prefixes and the directly read semantic ranges. `core.js` was examined
through the complete map generator (245-310); the large Godot file was inspected
in the map and outcome ranges only, plus its end. No whole-file semantic review
of that port is claimed.

Not checked: Godot parsing/runtime/parity, Windows execution, live map presentation,
saved-map migration, human difficulty, Monte Carlo balance or seed sets beyond the
existing 1,500 seed values across three sectors. This is a candidate repair and
evidence packet, not an applied gameplay fix or release approval.
