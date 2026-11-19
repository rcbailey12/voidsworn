# Issue 1077: flagship death prototype, PC evidence

## Rerun at 1236bbc3 (main after PR 1171), Nov 19 2026

PC run OPUS1077_RERUN.bat, RTX 5080, Godot 4.7.2, forward_plus, installed A16 (C19_51.glb sha256 6611595b...),
all steps exit 0. Pictures: /mnt/project-files/pc/1077/review/ (code names FLAGSHIP1077_A16_c26_* and _c170_*).

What it showed:
- Fragments stay grouped: 0.53 L from the break's middle with strain against 2.44 L today (12 fragments both).
- The main pieces did not: 1.93 L apart with strain against 1.35 L today. The physics pieces (quality above low) kept
  their speed because Jolt ignored their damping, and touching neighbours shoved them apart. The headless check only
  covered quality low (kinematic pieces), so it passed. Fixed in pass 3: update() slows a strained physics piece itself,
  strained pieces no longer collide with each other, and the check now also kills A16 at quality high in a
  --fixed-fps 60 child process (off 1.00 L, strain 0.22 L; before the fix 1.46 L).
- The strain tell did not read at either camera. Pass 3 doubles the bulge (0.0045 to 0.010 of the length), doubles the
  hairline width, raises its brightness (1.6 to 3.0) and the band glow (0.05 to 0.12). Needs the pass 3 clip to judge.
- The side-by-side AVIs came out at half size, cropped (the project's stretch settings on a 1920x1080 window). compose.gd
  now draws one to one.
- The prepared timing JSONs were overwritten by the cold run (a misplaced write); the numbers below come from the logs.
  Fixed in pass 3, which reruns the timing.

Frame times, solo GPU, three sessions (median of the session medians; worst is the worst of all three), ms:

| deaths | path | frame p50 | p95 | worst | GPU p50 | p95 | worst |
|---|---|---|---|---|---|---|---|
| 1 (first in process) | off | 2.5 | 3.1 | 10.6 | 1.82 | 2.12 | 2.41 |
| 1 (first in process) | strain | 3.7 | 5.7 | 13.4 | 1.83 | 2.24 | 2.55 |
| 1 | off | 2.5 | 3.2 | 9.1 | 1.79 | 2.09 | 2.48 |
| 1 | strain | 4.4 | 6.5 | 17.4 | 1.80 | 2.13 | 2.47 |
| 2 | off | 3.1 | 5.0 | 14.8 | 1.74 | 2.03 | 2.41 |
| 2 | strain | 5.5 | 8.1 | 17.5 | 1.77 | 2.14 | 2.61 |
| 3 | off | 5.2 | 8.2 | 23.6 | 2.10 | 2.53 | 3.02 |
| 3 | strain | 7.6 | 11.6 | 26.9 | 2.09 | 2.56 | 2.94 |

GPU cost is flat. The strain costs CPU: about 1 to 2.5 ms more per frame at the median and 2.5 to 3.5 ms at p95 while a
capital dies. Not yet traced; it would need a profile before the prototype could be installed.

Cold case (fresh process, no warm-up, no prepared cut), both paths alike, so these are today's problems, not the
prototype's: the worst frame is 3.1 to 6.9 s (a freeze at the kill), and 2 of 3 sessions per path ended in the
no-pieces fallback (hull hidden at 2.68 s with 0 pieces); session 1 fractured (4 pieces, 11 fragments, hidden at 2.02 s).
The game warms and cuts every ship under the loading cover, so a real battle should not hit this; it is the worst case.
